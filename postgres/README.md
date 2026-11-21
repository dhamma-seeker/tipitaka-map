# ใช้ index ไปเทรน/สร้าง embedded model ใน PostgreSQL ได้ไหม? — คำตอบ + การออกแบบ

## 1. คำตอบสั้น

**ได้ครับ — และเป็นแนวทางที่ถูกต้อง** index ที่เราสร้าง (`dhamma-map.json`) คือ "ชุดข้อมูลตั้งต้น" (seed data) ที่เหมาะจะโหลดเข้า PostgreSQL + pgvector เพื่อสร้าง **index ฝังตัว (embedded/local) แบบไฮบริด** = **ศัพท์ตรง (lexical, แม่นยำ) + ความหมาย (semantic, vector)**

จุดสำคัญ: **ส่วน "ศัพท์ตรง" เราแม่นยำอยู่แล้วโดยไม่ต้องพึ่งโมเดล** (นี่คือข้อได้เปรียบของคุณที่บอกว่า "ปัจจุบันยังไม่มี model แบบบาลี") — ใช้ full-text search ของ PostgreSQL + ข้อมูล Pāli ที่เรามี; ส่วน "ความหมาย" ค่อยต่อด้วย vector embedding

---

## 2. สถาปัตยกรรม (dhamma-map.json → PostgreSQL)

```
dhamma-map.json                     PostgreSQL (ตาราง)
─────────────────                   ─────────────────────
suttas[]            ──────────────▶  suttas
terms[]             ──────────────▶  terms
segments[]          ──────────────▶  segments
term.suttas[]       ──────────────▶  term_sutta   (index หลัก: ศัพท์ → พระสูตร)
edges[]             ──────────────▶  edges
(สร้างภายหลัง)       ──────────────▶  embeddings   (pgvector)
```

schema จริง: [`postgres/schema.sql`](postgres/schema.sql)

---

## 3. กลยุทธ์ embedding (โจทย์: ไม่มี model บาลีเฉพาะ)

สามชั้น ค่อยเป็นค่อยไป:

### ชั้น 1 — Lexical index (ทำได้เลย 100% แม่นยำ ไม่ต้องมีโมเดล)
ใช้ full-text + trigram ของ PostgreSQL:
- ค้นศัพท์ Pāli ตรง (`ariyasacca`) + กันวรรณยุกต์ (`anapanasati` เจอ `ānāpānassati`) ด้วย `pg_trgm`
- ค้นชื่อพระสูตร + หมายเลขท่อน
- **นี่คือ "embedded index เชิงความหมาย" เวอร์ชันที่ใช้ได้จริงทันที** — เพราะ index ด้วยศัพท์บาลีเอง ไม่ใช่ภาษาอังกฤษ

### ชั้น 2 — Semantic index (vector) — ต้องเลือกโมเดล
ไม่มีโมเดล Pāli เฉพาะ → ใช้ **multilingual embedding** ฝัง **คำแปลไทย + ตัวบทบาลี** คู่กัน:
| โมเดล | เหมาะกับ |
|---|---|
| `intfloat/multilingual-e5-base` (768d) | multilingual ครอบคลุม; ใช้กับไทยได้ดี |
| `sentence-transformers/paraphrase-multilingual-MiniLM` (384d) | เบา ฝังในเครื่อง (CPU) ได้ |
| `sentence-transformers/LaBSE` (768d) | แข็งแรงกับภาษา low-resource (รวม Pāli บางส่วน) |

- **ฝัง "ไทย" เป็นหลัก** (model เก่งกว่า) + ฝัง "บาลี" เป็นตัวช่วย
- เก็บลง `embeddings.embedding` (pgvector) → ค้น cosine similarity

### ชั้น 3 — Hybrid (lexical + semantic) — รวมผลด้วย RRF
แบบเดียวกับที่ tripitaka-mcp ทำ (`search_hybrid`): นำผล lexical + semantic มารวมคะแนนด้วย **Reciprocal Rank Fusion** → ได้ทั้ง "แม่น" (ศัพท์ตรง) และ "ครอบคลุม" (ความหมาย)

### ชั้น 4 (อนาคต) — Fine-tune โมเดล Pāli
เมื่อมีข้อมูล label พอ (ศัพท์ → ท่อนข้อความ ซึ่งเรามีโครงอยู่แล้ว) → fine-tune embedding ให้เก่งกับ Pāli โดยเฉพาะ → แก้ "ไม่มี model แบบบาลี" ได้ถาวร

---

## 4. ทำไม PostgreSQL + pgvector จึงใช่ (ไม่ใช่ Elasticsearch/FAISS ฯลฯ)

| เหตุผล | รายละเอียด |
|---|---|
| **ฝังในเครื่อง (local)** | รันเอง ไม่ต้องพึ่ง cloud — ตรงที่คุณต้องการ "ฝังใน" |
| **มีทั้งสองอย่างในตัว** | full-text (`tsvector`) + vector (`pgvector`) ในฐานเดียว |
| **โครงสร้าง relational ตรงกับกราฟ** | ตาราง + JOIN แทน graph-DB แยก (ข้อมูลเรามีขนาดพอเหมาะ) |
| **ทนทาน / ดูแลง่าย** | ภาษา SQL มาตรฐาน, backup/restore ง่าย |

---

## 5. ขั้นตอนโหลดข้อมูล (แผน)

```bash
# 1) สร้าง schema
psql "$DB" -f postgres/schema.sql

# 2) โหลด dhamma-map.json → ตาราง (สคริปต์ Python/loader ตัวถัดไป)
python3 postgres/load.py dhamma-map/dhamma-map.json

# 3) (ชั้น 2) สร้าง embedding + โหลดเข้า embeddings (เมื่อพร้อมมีโมเดล)
python3 postgres/embed.py --model intfloat/multilingual-e5-base --lang th,pali
```

---

## 6. สรุปตอบคำถาม

1. **ครอบคลุมทั้งพระไตรปิฎกหรือยัง?** → **ยังไม่ครบ** (ตอนนี้ ~21.3% = 1,558/7,321 section; วินัยต่ำสุด 5.2%) — เป็น "แกนกลาง" ที่ใช้ต่อยอดได้ ไม่ใช่ทั้งหมด
2. **เอา index ไปเทรน/สร้าง embedded model ใน PostgreSQL ได้ไหม?** → **ได้** โดยใช้ `pgvector` + full-text: เริ่มจาก **lexical index ที่แม่นยำอยู่แล้ว (ไม่ต้องมีโมเดล)** แล้วค่อยเพิ่ม **semantic (multilingual embedding)** และจบด้วย **hybrid** — และฐานข้อมูลนี้เองจะเป็นชุดข้อมูลสำหรับ fine-tune โมเดล Pāli ในอนาคต

---

*ไฟล์อ้างอิง: [`coverage-audit.md`](dhamma-map/coverage-audit.md) (ผลตรวจครอบคลุม) · [`schema.sql`](postgres/schema.sql)*
