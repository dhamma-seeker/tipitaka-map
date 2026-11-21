-- ============================================================================
-- PostgreSQL schema สำหรับ "แผนที่พระธรรม" (Tipiṭaka Map) + embedded index
-- ใช้กับ pgvector (ฝังตัวในเครื่อง) — รองรับทั้ง full-text (ศัพท์ตรง) และ semantic (vector)
-- ข้อมูลต้นทาง: dhamma-map/dhamma-map.json
-- ============================================================================

-- 1) ส่วนขยาย
CREATE EXTENSION IF NOT EXISTS vector;          -- pgvector
CREATE EXTENSION IF NOT EXISTS pg_trgm;          -- ใช้ trigram สำหรับ fuzzy ค้น Pāli/ไทย

-- ============================================================================
-- 2) ตารางหลัก (โครงสร้างกราฟความรู้)
-- ============================================================================

-- พระสูตร / คัมภีร์
CREATE TABLE suttas (
    id          TEXT PRIMARY KEY,        -- 'sn56.11', 'pli-tv-kd1', 'vb4'
    num         TEXT,                    -- 'SN 56.11'
    pali_name   TEXT,                    -- Dhammacakkappavattanasutta
    th_name     TEXT,                    -- ธัมมจักกัปปวัตตนสูตร
    nikaya      TEXT,                    -- Dīgha / Majjhima / Saṃyutta / Aṅguttara / Khuddaka
    pitaka      TEXT,                    -- Vinaya / Suttanta / Abhidhamma
    role        TEXT                     -- WHAT / INDEX / AUTHORITY / HOW / BRIDGE
);

-- ศัพท์บาลี (index เชิงความหมาย)
CREATE TABLE terms (
    id             SERIAL PRIMARY KEY,
    pali           TEXT UNIQUE NOT NULL, -- 'ariyasacca'
    th             TEXT,                 -- 'อริยสัจ 4'
    sutta_count    INT,                  -- จำนวนข้อความในสุตตันตปิฎก
    vinaya_count   INT,                  -- ... วินัยปิฎก
    abhidhamma_count INT,                -- ... อภิธรรมปิฎก
    total          INT
);

-- ท่อนข้อความ (segment)
CREATE TABLE segments (
    id          SERIAL PRIMARY KEY,
    segment_id  TEXT UNIQUE NOT NULL,    -- 'sn56.11:4.1'
    sutta_id    TEXT REFERENCES suttas(id),
    pali_text   TEXT,                    -- ตัวบทบาลี (ท่อน)
    th_gloss    TEXT,                    -- คำแปลไทย
    term_pali   TEXT                     -- ศัพท์หลักของท่อนนี้
);

-- ความสัมพันธ์ "ศัพท์ ปรากฏใน พระสูตร" (the coverage — index หลัก)
CREATE TABLE term_sutta (
    term_pali  TEXT REFERENCES terms(pali),
    sutta_id   TEXT REFERENCES suttas(id),
    PRIMARY KEY (term_pali, sutta_id)
);

-- ขอบเชื่อม (edge) ของกราฟ
CREATE TABLE edges (
    id         SERIAL PRIMARY KEY,
    from_node  TEXT NOT NULL,
    to_node    TEXT NOT NULL,
    edge_type  TEXT,                     -- defines / contains / fulfills / maps_to_pitaka
    evidence   TEXT                      -- segment_id อ้างอิง เช่น 'mn44:11.3'
);
CREATE INDEX idx_edges_from ON edges(from_node);
CREATE INDEX idx_edges_to   ON edges(to_node);

-- ============================================================================
-- 3) Embedded model (vector embedding) — pgvector
-- ============================================================================

-- ฝัง vector ของ ข้อความ (ศัพท์ / ท่อน / ชื่อพระสูตร) ภาษาใดก็ได้ (pali / th)
CREATE TABLE embeddings (
    id          BIGSERIAL PRIMARY KEY,
    source_type TEXT NOT NULL,           -- 'term' | 'segment' | 'sutta'
    source_id   TEXT NOT NULL,           -- อ้างอิง id (เช่น pali term, segment_id, sutta id)
    lang        TEXT NOT NULL,           -- 'pali' | 'th'
    content     TEXT NOT NULL,           -- ข้อความที่ถูก embed
    model       TEXT,                    -- ชื่อโมเดลที่ใช้ (เช่น 'intfloat/multilingual-e5-base')
    dim         INT,                     -- มิติของ vector (768 / 384 / ...)
    embedding   vector                  -- vector จากโมเดล (กำหนด dim ตอน insert)
);
-- index แบบ HNSW (เร็วสำหรับ cosine similarity)
-- หมายเหตุ: vector ต้องกำหนดมิติให้ตรง เช่น vector(768) — แก้บรรทัดนี้ตามโมเดลจริง
-- CREATE INDEX ON embeddings USING hnsw (embedding vector_cosine_ops);

-- ============================================================================
-- 4) Full-text search (ศัพท์ตรง — แม่นยำ ไม่ต้องพึ่งโมเดล)
-- ============================================================================

-- ค้นศัพท์บาลี + คำไทย แบบ lexical (กันวรรณยุกต์ด้วย pg_trgm)
CREATE INDEX idx_terms_pali_trgm  ON terms   USING gin (pali gin_trgm_ops);
CREATE INDEX idx_terms_th_trgm    ON terms   USING gin (th   gin_trgm_ops);
CREATE INDEX idx_suttas_name_trgm ON suttas  USING gin (coalesce(pali_name,'') || ' ' || coalesce(th_name,'') gin_trgm_ops);
CREATE INDEX idx_segments_text_trgm ON segments USING gin (coalesce(pali_text,'') || ' ' || coalesce(th_gloss,'') gin_trgm_ops);

-- full-text แบบ tsvector (Pāli ใช้ 'simple' config)
CREATE INDEX idx_segments_pali_fts ON segments USING gin (to_tsvector('simple', coalesce(pali_text,'')));
CREATE INDEX idx_terms_pali_fts    ON terms    USING gin (to_tsvector('simple', pali));

-- ============================================================================
-- 5) ตัวอย่าง query ที่ใช้บ่อย
-- ============================================================================

-- (a) ค้นศัพท์ตรง (lexical — แม่นยำที่สุดสำหรับ Pāli)
-- SELECT * FROM terms WHERE pali ILIKE '%ariyasacc%';

-- (b) หาพระสูตรทั้งหมดที่มีศัพท์ (the coverage — index หลัก)
-- SELECT s.num, s.th_name
-- FROM term_sutta ts JOIN suttas s ON s.id = ts.sutta_id
-- WHERE ts.term_pali = 'ariyasacca'
-- ORDER BY s.id;

-- (c) ท่อนข้อความสำคัญของศัพท์
-- SELECT segment_id, pali_text, th_gloss
-- FROM segments WHERE term_pali = 'ariyasacca';

-- (d) ค้นหาเชิงความหมาย (semantic — ต้องมี embedding ก่อน)
-- SELECT content, 1 - (embedding <=> :query_vector) AS similarity
-- FROM embeddings
-- ORDER BY embedding <=> :query_vector
-- LIMIT 10;

-- (e) Hybrid (lexical + semantic) — ใช้ RRF รวมผล
-- ... (ทำในแอปพลิเคชันเลเยอร์ หรือ recursive CTE)
