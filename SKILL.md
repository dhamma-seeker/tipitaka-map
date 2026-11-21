---
name: tipitaka-map-research
description: >-
  ระเบียบวิธีวิจัย "root/สารบัญของพระไตรปิฎก" — ทดสอบว่าพระสูตร X ใช้เป็นโครงสร้าง/สารบัญเชื่อมครอบคลุม
  พระไตรปิฎก 3 ปิฎกได้หรือไม่ จากตัวบทภาษาบาลีโรมันเท่านั้น (ห้ามวิเคราะห์/แปลจากภาษาอังกฤษหรือภาษาอื่น)
  ผ่าน tripitaka-mcp (local + online) ด้วย survey_corpus แบบ exhaustive แล้วสร้างแผนที่ node–edge + รายงาน IMRaD + แผนภาพ
  Use when researching whether a sutta or concept can serve as a structure / table-of-contents of the Tipitaka,
  or when surveying a Pali term's distribution across the whole canon exhaustively.
---

# ระเบียบวิธีวิจัย: root/สารบัญของพระไตรปิฎก (Tipiṭaka Map Research)

## นี่คืออะไร และไม่ใช่อะไร

**เป็น:** ขั้นตอนซ้ำได้ (reproducible) สำหรับทดสอบสมมติฐาน *"พระสูตร X ใช้เป็นโครงสร้าง/สารบัญเชื่อมครอบคลุมพระไตรปิฎกทั้ง 3 ปิฎกได้หรือไม่"* และสำหรับสำรวจการกระจายของศัพท์บาลีทั่วพระไตรปิฎกแบบ exhaustive
**ไม่ใช่:** การแปลพระสูตร หรือการสรุปเนื้อหาธรรมะโดยไม่ผูกกับหลักฐานตัวเลข

**ใช้เมื่อ:** ต้องการหา "root" (พระสูตร/มโนทัศน์ที่ทำหน้าที่เป็นสารบัญ) · เทียบ root หลายตัว · สำรวจว่าศัพท์ใดเข้าถึง 3 ปิฎก · ทำแผนที่พระไตรปิฎก
**ไม่ใช้เมื่อ:** ต้องการแปล/อ่านพระสูตรเพื่อความเข้าใจทั่วไป (งานนี้เป็นงานเชิงปริมาณ + เชิงโครงสร้าง)

---

## 1. ข้อกำหนดเข้มงวด (Hard Constraints)

1. **ภาษาบาลีโรมันเท่านั้น** — `get_sutta` และ `survey_corpus` ต้องใช้ `language="pali"` เสมอ; **ห้ามวิเคราะห์/แปลจากภาษาอังกฤษหรือภาษาไทย/ภาษาอื่น** คำแปลไทย (ถ้ามีในรายงาน) ต้องแปลจากตัวบทบาลีตรง ไม่ใช่ relay ผ่านอังกฤษ
2. **แหล่งข้อมูล:** tripitaka-mcp **ทั้ง local และ online** (ฐานข้อมูล SuttaCentral `bilara-data` CC0) — ผลสอง server ต้องตรงกัน (cross-check)
3. **ตัวเลขทุกตัวสืบย้อนได้** — มาจาก `survey_corpus` (`complete:true`) หรือ `get_sutta`; ห้ามใช้ตัวเลขจากความจำ
4. **อ้างอิงลิงก์ทุกพระสูตร** — ทุกครั้งที่เอ่ยชื่อพระสูตร ต้องแนบลิงก์ markdown `https://tripitaka-mcp.com/read/<sutta_id>` และ deep-link `#<segment_id>` เมื่ออ้างข้อความเฉพาะ
5. **ห้าม fabricate** — ถ้าตัวเลข/ศัพท์ไม่แน่ชัด ให้ระบุว่าเป็น "ขอบเขตบน" (over-match) หรือ "ไม่พบ" ตรง ๆ

---

## 2. ขั้นตอนการวิจัย (Procedure — 9 ขั้น)

### ขั้น 1 · ดึงโครงสร้าง (outline)
```
get_sutta(<sutta_id>, language="pali", mode="outline")
```
→ ได้รายการหมวด (section titles เป็นตัวบทบาลี) + จำนวนข้อความ + segment ids
→ **สำคัญ:** สำหรับพระสูตรยาว (> ~400 ข้อความ เช่น DN 16 = 1664, DN 33 = 1167) **ห้าม fetch ตัวบทเต็ม** ให้ใช้ outline แล้ว fetch เฉพาะส่วนสำคัญด้วย `offset`/`limit` หรือ `segment_range`/`around`

### ขั้น 2 · ดึงตัวบท (เฉพาะส่วนสำคัญ)
```
get_sutta(<sutta_id>, language="pali", offset=..., limit=...)  # หรือ around=<segment_id>
```
ดึงเฉพาะ: (ก) อุทเทส/บทนำ, (ข) หมวดที่เป็น "ลายเซ็น" ของพระสูตรนั้น

### ขั้น 3 · สกัดศัพท์/มโนทัศน์หลัก
จากตัวบทบาลี สกัดศัพท์แกน (เช่น อริยสัจ 4, มรรค 8, สติปัฏฐาน, มาติกา, มหาปเทส …) + ศัพท์ลายเซ็นเฉพาะตัว (เช่น tiparivaṭṭa ของ SN 56.11, paṭikūlamanasikāra ของ DN 22)

### ขั้น 4 · สำรวจการกระจายทั่วพระไตรปิฎก
```
survey_corpus(keyword=<ศัพท์>, language="pali", match_scope="stem", mode="fast", page_size=1)
```
- อ่านเฉพาะ `lexical.total_segments`, `total_suttas`, `by_pitaka` (ไม่ต้องอ่าน enumeration ทั้งหมด)
- `match_scope="stem"` = นับ inflection + compound (recall สูง, อาจ over-match — ดูข้อ 7)

### ขั้น 5 · ระบุและยืนยัน "พระสูตรสะพาน" (bridge suttas)
หา/ยืนยันพระสูตรที่บัญญัติความเชื่อมโยงเชิงมโนทัศน์ (ดูรายการในข้อ 5 ข้างล่าง) แล้ว `get_sutta` เพื่อยืนยันตัวบทบาลีตรง

### ขั้น 6 · Cross-check local vs online
survey ศัพท์แกนซ้ำบนทั้งสอง server → ผลต้อง identical (เช่น ariyasacca = 401 ทั้งคู่)

### ขั้น 7 · วิเคราะห์ "กลไกการเข้าถึง" (สำคัญที่สุด)
จำแนกว่า root เข้าถึง 3 ปิฎกด้วยกลไกใด:
- **เชิงศัพท์ (lexical reach):** ศัพท์แกนปรากฏซ้ำใน 3 ปิฎก (วัดด้วย survey_corpus)
- **เชิงมโนทัศน์ (conceptual reach):** ผ่าน "พระสูตรสะพาน" ที่บัญญัติความสัมพันธ์ (เช่น มรรค 8 ↔ ไตรสิกขา = MN 44)
- **วินัย มักเชื่อมเชิงมโนทัศน์** (ผ่าน ศีล/สิกขาบท/ปาติโมกข์) ไม่ใช่ศัพท์ตรง — ต้องอ่านผ่านสะพาน ไม่ใช่ค้นศัพท์

### ขั้น 8 · ทดสอบสมมติฐาน
- H1: ศัพท์แกนเข้าถึง 3 ปิฎก (สนับสนุน = เป็น root ได้)
- H0: กระจุกเฉพาะสุตตันตปิฎก (ปฏิเสธ H0 = root ได้)
- รายงานผลแบบ effect size (จำนวนข้อความต่อปิฎก) ไม่ใช่แค่ "มี/ไม่มี"

### ขั้น 9 · สร้างผลงาน (deliverables)
สร้างชุดไฟล์มาตรฐาน (ข้อ 3) + เขียนรายงาน IMRaD (ข้อ 4)

---

## 3. ผลงานมาตรฐานต่อ 1 พระสูตร (Standard Deliverables)

วางในโฟลเดอร์ `<ชื่อ>-mapping/` (เช่น `dhammacakka-mapping/`, `sangiti-dasuttara-mapping/`) ครบ 6 ไฟล์:

| ไฟล์ | เนื้อหา |
|---|---|
| `report.md` | รายงาน IMRaD ภาษาไทย, อ้างอิงลิงก์ทุกพระสูตร (โครงสร้างข้อ 4) |
| `survey_data.csv` | คอลัมน์: `term,sutta,vinaya,abhidhamma,total,suttas,note` |
| `map_edges.csv` | `from_node,to_node,edge_type,evidence` (หลักฐาน = sutta+segment) |
| `map_graph.json` | node–edge machine-readable (ใช้ต่อยอดกราฟ/เว็บ) |
| `map.svg` + `map.png` | แผนภาพต้นไม้ (SVG = บาลีเต็ม, PNG = ASCII ดูง่าย) |

**โครงสร้าง report.md (IMRaD ไทย):**
```
# [ชื่อพระสูตร] เป็นโครงสร้าง/สารบัญของพระไตรปิฎกได้หรือไม่
> ข้อกำหนดวิธีวิจัย (บาลีโรมันเท่านั้น...)
## บทคัดย่อ  (ตอบตรง: ได้/ไม่ได้ + root ชนิดใด)
## 1. บทนำและสมมติฐาน (H1/H0)
## 2. วิธีการ
## 3. ผล (โครงสร้างภายในจากบาลี + ตาราง survey + ข้อค้นพบชี้ขาด 3 ข้อ)
## 4. แผนที่ (ฝัง map + mermaid)
## 5. อภิปราย (กลไก 2 แบบ, ระบบปิด, เทียบกับ root อื่น)
## 6. ข้อจำกัดและการตรวจสอบตนเอง
## 7. สรุป + ไฟล์ส่งมอบ
```

---

## 4. อนุสัญญา (Conventions)

- **ลิงก์อ้างอิง:** `https://tripitaka-mcp.com/read/<sutta_id>`; deep-link `https://tripitaka-mcp.com/read/<sutta_id>#<segment_id>` (เช่น `#mn44:11.3`)
- **การตั้งชื่อโฟลเดอร์:** งานเชิงแผนที่ = `<sutta>-mapping/` · งานสำรวจศัพท์ = `<topic>-research/` (เช่น `metta-research/`)
- **survey_corpus พารามิเตอร์มาตรฐาน:** `language="pali"`, `match_scope="stem"`, `mode="fast"`, `page_size=1`
- **ศัพท์บาลีในเอกสาร:** ใช้รูปวรรณยุกต์ (ā ī ū ṅ ñ ṭ ḍ ṇ ḷ ṁ); ใน PNG ใช้ transliteration ASCII (ไม่มีวรรณยุกต์) เพราะ font ไม่รองรับ

---

## 5. พระสูตรสะพาน (Bridge Suttas — ใช้ซ้ำทุกงาน)

| สะพาน | บัญญัติว่า | ตำแหน่ง |
|---|---|---|
| [SN 45.8](https://tripitaka-mcp.com/read/sn45.8) วิภังคสูตร | นิยามมรรค 8 แต่ละองค์; สัมมาทิฏฐิ = ญาณในอริยสัจ 4; สัมมาสติ = สติปัฏฐาน 4 | `sn45.8:3.2`, `sn45.8:9.2` |
| [MN 44](https://tripitaka-mcp.com/read/mn44) จูฬเวทัลลสูตร | **ไตรสิกขา = มรรค 8** (ศีล/สมาธิ/ปัญญา); สติปัฏฐาน = สมาธินิมิตต์ | `mn44:11.3-11.5`, `mn44:12.3` |
| [AN 3.89](https://tripitaka-mcp.com/read/an3.89) สิกขัตตยสูตร | นิยามไตรสิกขา (อธิศีล/อธิจิต/อธิปัญญา); อธิปัญญา = อริยสัจ 4 | `an3.89:1.3`, `an3.89:4.2` |
| [DN 16](https://tripitaka-mcp.com/read/dn16) มหาปรินิพพาน | โพธิปักขิยธรรม 37; จตุมหาปเทส (เกณฑ์พุทธวจนะ) | `dn16:3.50.5`, `dn16:4.8` |

---

## 6. ข้อค้นพบสะสม (Accumulated Findings — กันลืม)

### 6.1 กลไกการเข้าถึง 2 แบบ
1. **lexical reach** — ศัพท์แกนปรากฏซ้ำในปิฎกนั้น (survey_corpus นับได้)
2. **conceptual reach** — ผ่านพระสูตรสะพาน (วินัยมักเป็นแบบนี้)

### 6.2 ระบบปิด (closed loop)
สัมมาทิฏฐิ (องค์แรกของมรรค) = ญาณในอริยสัจ 4 → **ทุกเส้นทางวนกลับมาที่อริยสัจ 4** — แผนที่ไม่มีปลายตัน

### 6.3 อริยสัจ 4 ปรากฏใน 3 ปิฎก 3 รูปแบบ (หลักฐานชี้ขาดของ SN 56.11)
- สุตตันตะ: SN 56.11 (แสดงธรรม)
- วินัย: `pli-tv-kd1` มหาวรรค (บทปฐมเทศนา**คำต่อคำ**)
- อภิธรรม: `vb4` สัจจวิภังค์ (วิเคราะห์ *"ตตฺถ กตมํ ทุกฺขํ อริยสจฺจํ"*)

### 6.4 Taxonomy ของ root (4 แกน, 10 root)
| แกน | root |
|---|---|
| WHAT เนื้อหา | SN 56.11 (อริยสัจ 4), DN 2 (ไตรสิกขา) |
| INDEX สารบัญ | DN 33 (สังคีติ), DN 34 (ทสุตตร) — มาติกา 1–10 |
| AUTHORITY เกณฑ์ | DN 16 (จตุมหาปเทส + โพธิปักขิยธรรม 37) |
| HOW ปฏิบัติ | MN 117 (มรรค 8→10), DN 22 (สติปัฏฐาน), MN 118 (อานาปาน), MN 62 (หลักสูตรกรรมฐาน), MN 9 (สัมมาทิฏฐิ) |

### 6.5 ศัพท์ที่ over-match (ตัวเลขเป็นขอบเขตบน — ต้องหมายเหตุเสมอ)
| ศัพท์ | ติดคำพ้องรูป |
|---|---|
| sīla | silā (หิน) |
| paññā | paññatti/paññāpeti (บัญญัติ) |
| khandha | khandhaka (ชื่อหมวดวินัย) |
| jhāna | jhāyati (เพ่ง) |
| bala | bāla (คนโง่) |
| abhiññā | abhiññāta (มีชื่อเสียง) |
| upekkhā | upekkhā-เวทนา (ความรู้สึกเฉย) |
| paṭinissagga | กรรมวาจาในวินัย (สละทิฏฐิ) |

### 6.6 ข้อควรระวัง
- ศัพท์ "compound" อาจ survey ไม่เจอ แม้มโนทัศน์มีจริง (เช่น `aparihāniyadhamma` = 0 แต่ `อปริหานิยา ธมฺมา` = 28) — รายงานทั้งสองรูปอย่างโปร่งใส
- "วิชชาวิมุตติ/สัมมาญาณ/สัมมาวิมุตติ" อยู่เฉพาะสุตตันตะ (วินัย/อภิธรรม = 0) — คำ "ปลายทาง" เป็นคำของสุตตันตะ

---

## 7. ขั้นตอนเผยแพร่ (GitHub Publishing)

```bash
cd <repo-folder>
printf '.DS_Store\n__pycache__/\n*.pyc\n' > .gitignore
git init -b main
git add -A && git commit -m "<msg>"
gh repo create <name> --public --source=. --remote=origin --push
# ถ้า push แรกติด HTTP 400: ให้ repack + push --force
git repack -a -d -q
git -c http.postBuffer=157286400 push -u origin main --force
# เปิด GitHub Pages
gh api -X POST repos/<owner>/<name>/pages -f "source[branch]=main" -f "source[path]=/"
```

---

## 8. รูปแบบการมอบงาน subagent (Delegation Pattern)

เมื่อมี root หลายตัว ต้องวิจัยเชิงลึกพร้อมกัน → ใช้ `subagent_fork` (สืบทอดบทสนทนา) ตัวละ 1 root โดย prompt ต้องระบุ:
1. พระสูตร + ชนิด root + บริบทที่รู้แล้ว (outline + survey ที่เก็บแล้ว — บอกว่า "ห้าม survey ซ้ำ")
2. ข้อกำหนดเข้มงวด (บาลีล้วน, ห้าม fetch ตัวบทเต็มของพระสูตรยาว, อ้างอิงลิงก์)
3. ผลงาน 6 ไฟล์ + โฟลเดอร์เป้าหมาย
4. คำถามวิจัยที่ต้องตอบ
5. ข้อห้าม (อย่า git commit/push — lead เป็นคน push; อย่าใช้ภาษาอังกฤษวิเคราะห์)
6. ให้คืน "สรุป 3–5 บรรทัด"

---

## 9. แม่แบบ (Templates)

### 9.1 โครงสร้าง survey_data.csv
```csv
term,sutta,vinaya,abhidhamma,total,suttas,note
ariyasacca,344,23,34,401,88,อริยสัจ 4 — ครบ 3 ปิฎก
```

### 9.2 แผนภาพต้นไม้ (SVG + PNG) — โครง Python มาตรฐาน
```python
import os, html, textwrap
tree = ("ROOT", "ROOT-ascii", [   # (pali, ascii, children, note_pali, note_ascii)
  ("ลูก 1", "child1", [], "หมายเหตุ", "note-ascii"),
])
CHAR_W=6.0; LINE_H=15; PAD_X=14; PAD_Y=10; ROW_H=150; MARGIN=30
def wrap(t, maxc=26):
    lines=[]
    for w in t.split():
        if not lines or len(lines[-1])+1+len(w)>maxc: lines.append(w)
        else: lines[-1]+=" "+w
    out=[]
    for ln in lines: out += textwrap.wrap(ln,maxc) or [ln]
    return out
def bsize(lines,nl):
    w=max(max(len(l) for l in lines), max((len(l) for l in nl), default=0))*CHAR_W+PAD_X*2
    return w, len(lines)*LINE_H+len(nl)*11+PAD_Y*2
def assign(node,depth,x,y,gap,out):
    _,label,ch,note,_=node
    lines=wrap(label); nl=wrap(note) if note else []
    w,h=bsize(lines,nl)
    if not ch:
        cx=x+w/2; out[id(node)]=(cx,y,w,h,lines,nl); return w+gap
    cx_cur=x; cxs=[]
    for c in ch:
        cw=assign(c,depth+1,cx_cur,y+ROW_H,gap,out); cxs.append(cx_cur+cw/2); cx_cur+=cw
    cx=(cxs[0]+cxs[-1])/2; out[id(node)]=(cx,y,w,h,lines,nl); return cx_cur-x
# ... แล้ววาด rect+text+edge (SVG) / rounded_rectangle+text (Pillow PNG) — ดูตัวอย่างเต็มในไฟล์เดิม
```

### 9.3 ตัวอย่าง prompt สำเร็จรูป (สำหรับ subagent)
ดูตัวอย่างจริงได้ในโฟลเดอร์ `*/mapping/report.md` ใด ๆ ใน repo นี้ และ `combined-map/combined_graph.json`

---

## 10. ตัวอย่างผลงานที่เสร็จแล้ว (ใช้เป็น reference)

| งาน | โฟลเดอร์ | root ชนิด |
|---|---|---|
| ธัมมจักกัปปวัตตนสูตร (SN 56.11) | `dhammacakka-mapping/` | WHAT |
| สามัญญผลสูตร (DN 2) | `samannaphala-mapping/` | PATH |
| มหาสติปัฏฐานสูตร (DN 22) | `mahasatipatthana-mapping/` | WHO |
| อานาปานสติสูตร (MN 118) | `anapanasati-mapping/` | HOW |
| มหาจัตตารีสกสูตร (MN 117) | `mahacattarisaka-mapping/` | WHICH |
| สังคีติ+ทสุตตร (DN 33/34) | `sangiti-dasuttara-mapping/` | INDEX |
| มหาปรินิพพานสูตร (DN 16) | `mahaparinibbana-mapping/` | AUTHORITY |
| ราหุโลวาทสูตร (MN 62) | `rahulovada-mapping/` | CURRICULUM |
| สัมมาทิฏฐิสูตร (MN 9) | `sammaditthi-mapping/` | สัมมาทิฏฐิ |
| แผนที่รวม | `combined-map/` | — (28 โหนด/31 ขอบ) |

---

*ระเบียบวิธีนี้ใช้ข้อมูลเพื่อการศึกษา (Dhamma Dāna) เท่านั้น; โปรดสอบทานกับฉบับพิมพ์ล่าสุดก่อนอ้างอิงทางวิชาการ*
