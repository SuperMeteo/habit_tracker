# 📱 Habit Tracker

แอปติดตามนิสัย (habit tracking) แบบ **offline-first + online** พร้อมระบบสะสมแต้ม แรงค์ และการจัดอันดับแข่งกับเพื่อน

สร้างด้วย **Flutter** + **Drift (SQLite)** + **Supabase (PostgreSQL)**

---

## 📖 สารบัญ

| หัวข้อ | อ่านเมื่อ |
|---|---|
| [แอปทำอะไรได้บ้าง](#-แอปทำอะไรได้บ้าง) | อยากรู้ฟีเจอร์ทั้งหมด |
| [วิธีใช้งานแอป](#-วิธีใช้งานแอป) | เป็นผู้ใช้ทั่วไป |
| [ติดตั้งบนเครื่องใหม่](#-ติดตั้งบนเครื่องใหม่) | ย้ายเครื่อง / เพื่อนมาช่วยพัฒนา |
| [โครงสร้างโปรเจกต์](#-โครงสร้างโปรเจกต์) | จะแก้โค้ด |
| [ระบบแต้มและแรงค์](#-ระบบแต้มและแรงค์) | อยากปรับกติกา |
| [ปัญหาที่พบบ่อย](#-ปัญหาที่พบบ่อย) | รันไม่ได้ |

เอกสารเพิ่มเติม: [SETUP.md](SETUP.md) (ติดตั้งละเอียด) · [docs/ONLINE_PLAN.md](docs/ONLINE_PLAN.md) (สถาปัตยกรรม) · [docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md) (ตั้งค่า backend)

---

## ✨ แอปทำอะไรได้บ้าง

### หลัก — ติดตามนิสัย
- **สร้าง Habit** ได้ทั้งแบบ *ทำ/ไม่ทำ* (เช่น "อ่านหนังสือ") และ *แบบนับค่า* (เช่น "ดื่มน้ำ 8 แก้ว")
- **เลือกความถี่** — ทุกวัน / เลือกวันในสัปดาห์ / กี่ครั้งต่อสัปดาห์
- **Template สำเร็จรูป** — เลือกจากรายการนิสัยยอดนิยมได้เลย ไม่ต้องพิมพ์เอง
- **ปรับแต่ง** สี ไอคอน หมวดหมู่ (สุขภาพ/ผลิตภาพ/การเงิน/การเรียนรู้/อื่นๆ)
- **ตั้งเวลาแจ้งเตือน** รายวัน

### สถิติและความคืบหน้า
- **Streak** — นับวันต่อเนื่องที่ทำสำเร็จ (ปัจจุบัน + สถิติสูงสุด)
- **Calendar heatmap** — ดูภาพรวมทั้งปีว่าวันไหนทำได้บ้าง
- **กราฟรายสัปดาห์** — เปรียบเทียบแต่ละวัน
- **อัตราความสำเร็จ** รายสัปดาห์

### ระบบเกม (ต้อง login)
- **สะสมแต้ม** — ทำ habit สำเร็จได้ **+10 แต้ม** ต่อครั้ง
- **แรงค์ (Tier)** — เลื่อนขั้นอัตโนมัติ 🥉 Bronze → 🥈 Silver → 🥇 Gold → 💎 Platinum → 🔷 Diamond
- **Leaderboard** — ดูอันดับตัวเองเทียบกับผู้ใช้คนอื่น มี 2 โหมด: **สัปดาห์นี้** และ **ตลอดกาล**

### ระบบบัญชีและ Sync
- **ใช้งานได้โดยไม่ต้องสมัคร** — กด "ข้ามก่อน (ใช้แบบออฟไลน์)" ใช้ได้ครบทุกฟีเจอร์หลัก
- **สมัคร/เข้าสู่ระบบ** เพื่อ backup ข้อมูลและแข่งขัน
- **Sync ข้ามเครื่อง** — ข้อมูลตรงกันทุกอุปกรณ์ (sync อัตโนมัติตอน login + กดเองได้ในหน้าตั้งค่า)
- **ข้อมูลตอนเป็น guest ไม่หาย** — พอ login ระบบจะผูกข้อมูลเดิมเข้าบัญชีให้อัตโนมัติ

### ระบบหลังบ้าน (Admin เท่านั้น)
- ดูสถิติรวมของระบบ (จำนวนผู้ใช้ / habit / แต้มรวม)
- จัดการผู้ใช้ — ปรับแต้ม (+10 / +50 / -10), ตั้ง/ถอดสิทธิ์ admin
- ทุกการปรับแต้มถูกบันทึกใน ledger ตรวจย้อนหลังได้

### อื่นๆ
- **ธีม** สว่าง / มืด / ตามระบบ
- **ภาษาไทย** เต็มรูปแบบ

---

## 📲 วิธีใช้งานแอป

### เริ่มต้นครั้งแรก

1. **เปิดแอป** → เจอหน้าเข้าสู่ระบบ
2. เลือกทางใดทางหนึ่ง:
   - **สมัครสมาชิก** — กรอกชื่อผู้ใช้ (≥3 ตัว), อีเมล, รหัสผ่าน (≥6 ตัว) → ได้ backup + แข่งขันได้
   - **ข้ามก่อน (ใช้แบบออฟไลน์)** — ใช้ทันทีไม่ต้องสมัคร (แต่ไม่มี backup/อันดับ)

### แท็บทั้ง 4

| แท็บ | ทำอะไร |
|---|---|
| 🏠 **หน้าหลัก** | เช็ค habit ประจำวัน, ดูความคืบหน้าวันนี้, เลื่อนดูย้อนหลัง 7 วัน |
| 📊 **สถิติ** | Streak, heatmap ทั้งปี, กราฟรายสัปดาห์ |
| 🏆 **อันดับ** | Leaderboard (สัปดาห์นี้ / ตลอดกาล) — แถวของเราจะถูกไฮไลต์ |
| ⚙️ **ตั้งค่า** | โปรไฟล์, ธีม, จัดการ habit, sync, ออกจากระบบ |

### งานที่ทำบ่อย

**เพิ่ม Habit**
> หน้าหลัก → ปุ่ม **+ เพิ่ม Habit** → เลือก Template หรือกรอกเอง → บันทึก

**เช็คว่าทำสำเร็จแล้ว**
> หน้าหลัก → แตะการ์ด habit → เครื่องหมายถูกจะขึ้น (ได้ +10 แต้มถ้า login อยู่)

**บันทึกค่าตัวเลข** (สำหรับ habit แบบนับค่า)
> แตะการ์ด → ใส่ตัวเลข เช่น จำนวนแก้ว → บันทึก

**แก้ไข/ลบ Habit**
> ตั้งค่า → จัดการ Habit → เลือกอันที่ต้องการ

**Sync ข้อมูลด้วยตัวเอง**
> ตั้งค่า → กด **ซิงค์ข้อมูล**

---

## 💻 ติดตั้งบนเครื่องใหม่

> ต้องการติดตั้งละเอียดกว่านี้ (Flutter SDK, Android Studio, JDK) ดู **[SETUP.md](SETUP.md)**

### ขั้นที่ 1 — เตรียมเครื่อง (ทำครั้งเดียว)

ต้องมี:
- **Flutter SDK** 3.5+ ([ดาวน์โหลด](https://docs.flutter.dev/get-started/install))
- **Android Studio** + Android SDK (สำหรับ emulator)
- **Git**
- **Developer Mode** เปิดบน Windows (Start → พิมพ์ "Developer settings" → เปิด)

ตรวจสอบ:
```bash
flutter doctor
```

### ขั้นที่ 2 — โคลนโปรเจกต์

```bash
git clone https://github.com/SuperMeteo/habit_tracker.git
cd habit_tracker
```

### ขั้นที่ 3 — ติดตั้ง dependencies + generate โค้ด

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

> ขั้นที่ 2 จำเป็น เพราะไฟล์ `*.g.dart` (โค้ดฐานข้อมูลที่ generate) ไม่ได้เก็บใน git บางส่วน

### ขั้นที่ 4 — เลือกโหมดการรัน

#### 🅰️ โหมด Offline (ง่ายสุด — ไม่ต้องตั้ง Supabase)

```bash
flutter run
```
ใช้ได้ครบทุกฟีเจอร์หลัก ยกเว้น login / อันดับ / sync

#### 🅱️ โหมด Online (ครบทุกฟีเจอร์)

**1. สร้าง Supabase project**
ทำตาม **[docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md)** (ใช้เวลา ~5 นาที) โดยสรุป:
- สมัคร supabase.com → New project → เลือก region **Singapore**
- SQL Editor → วางเนื้อหาจาก [supabase/schema.sql](supabase/schema.sql) → **Run**
- Authentication → Sign In/Providers → Email → **ปิด "Confirm email"** (ช่วง dev)
- Project Settings → API Keys → copy **publishable key**

**2. สร้างไฟล์ `run_dev.ps1`** ที่รากโปรเจกต์ (ไฟล์นี้ไม่อยู่ใน git เพราะมี key)

```powershell
# run_dev.ps1
param([string]$d = "")

$url  = "https://<project-ref>.supabase.co"
$key  = "sb_publishable_xxxxxxxxxxxx"

$deviceArg = if ($d) { @("-d", $d) } else { @() }

flutter run @deviceArg `
  "--dart-define=SUPABASE_URL=$url" `
  "--dart-define=SUPABASE_ANON_KEY=$key"
```

**3. รัน**
```powershell
.\run_dev.ps1
```

> ⚠️ ต้องรันจาก **Terminal** เท่านั้น (ห้ามดับเบิลคลิกไฟล์ใน File Explorer)

### ขั้นที่ 5 — เปิด emulator (ถ้ายังไม่เปิด)

```bash
flutter emulators --launch Pixel_6
```
รอ ~30 วินาที แล้วค่อยรันแอป

---

### 🔑 สรุปคำสั่งที่ใช้บ่อย

| คำสั่ง | ทำอะไร |
|---|---|
| `.\run_dev.ps1` | **รันแบบ online** (มี login) |
| `flutter run` | รันแบบ offline (ไม่มี login) |
| `.\run_dev.ps1 -d chrome` | รันบน Chrome |
| `flutter devices` | ดูอุปกรณ์ที่เชื่อมอยู่ |
| `flutter emulators --launch Pixel_6` | เปิด emulator |
| `dart run build_runner build --delete-conflicting-outputs` | generate โค้ด DB ใหม่ (หลังแก้ตาราง) |
| `flutter analyze` | ตรวจ error ในโค้ด |
| `flutter clean` | ล้าง cache เมื่อ build พัง |

**ระหว่างแอปรันอยู่** — พิมพ์ในเทอร์มินัล: `r` = hot reload · `R` = hot restart · `q` = ออก

---

## 📁 โครงสร้างโปรเจกต์

```
lib/
├── main.dart                  ← จุดเริ่มต้น (init Supabase ถ้ามี key)
├── app.dart                   ← routing + guard บังคับ login
│
├── core/                      ← โครงสร้างพื้นฐาน
│   ├── database/              ← Drift/SQLite (ตาราง + query)
│   ├── supabase/              ← ตั้งค่าเชื่อม Supabase
│   ├── sync/                  ← เครื่องยนต์ sync local ⇄ cloud
│   ├── theme/                 ← สี ธีม
│   └── utils/                 ← คำนวณ streak, จัดการวันที่
│
├── data/                      ← ชั้นข้อมูล (Repository Pattern)
│   ├── models/                ← AppUser, LeaderboardEntry
│   ├── datasources/remote/    ← คุยกับ Supabase
│   └── repositories/          ← ตัวกลางที่ UI เรียกใช้
│
└── features/                  ← แยกตามฟีเจอร์
    ├── auth/                  ← เข้าสู่ระบบ / สมัคร
    ├── dashboard/             ← หน้าหลัก
    ├── habits/                ← เพิ่ม/แก้ habit + template
    ├── analytics/             ← สถิติ + กราฟ
    ├── leaderboard/           ← อันดับ
    ├── admin/                 ← ระบบหลังบ้าน
    └── settings/              ← ตั้งค่า

supabase/
├── schema.sql                 ← ตาราง + trigger + RLS (รันใน SQL Editor)
└── weekly_reset.sql           ← cron รีเซ็ตแต้มรายสัปดาห์ (ต้องเปิด pg_cron)
```

### หลักการออกแบบ

**Offline-first** — SQLite ในเครื่องเป็นแหล่งข้อมูลหลัก แอปทำงานได้เต็มรูปแบบแม้ไม่มีเน็ต แล้วค่อย sync ขึ้น cloud

**Repository Pattern** — UI เรียก `repository` เท่านั้น ไม่แตะฐานข้อมูลตรงๆ ทำให้เปลี่ยน backend ได้โดยไม่ต้องแก้ UI

**แต้มคำนวณฝั่ง server** — client ส่งแค่ "ทำสำเร็จแล้ว" ส่วนแต้มคำนวณด้วย Postgres trigger เพื่อกันโกง

---

## 🏆 ระบบแต้มและแรงค์

### การได้แต้ม
| เหตุการณ์ | แต้ม |
|---|---|
| ทำ habit สำเร็จ 1 ครั้ง | **+10** |
| ยกเลิกการทำสำเร็จ | คืนแต้มที่ได้ไป |

### เกณฑ์แรงค์ (ตามแต้มสะสมตลอดกาล)
| Tier | ช่วงแต้ม |
|---|---|
| 🥉 Bronze | 0 – 499 |
| 🥈 Silver | 500 – 1,499 |
| 🥇 Gold | 1,500 – 3,999 |
| 💎 Platinum | 4,000 – 9,999 |
| 🔷 Diamond | 10,000+ |

### ปรับกติกาเอง
แก้ใน [supabase/schema.sql](supabase/schema.sql):
- ฟังก์ชัน **`set_log_points`** → เปลี่ยนจำนวนแต้มต่อครั้ง
- ฟังก์ชัน **`calc_tier`** → เปลี่ยนช่วงแต้มของแต่ละ tier

แล้วรัน SQL นั้นใหม่ใน Supabase SQL Editor

### ตั้งผู้ดูแลระบบ (admin) คนแรก
```sql
update profiles set role = 'admin' where username = 'ชื่อผู้ใช้ของคุณ';
```
รันใน SQL Editor แล้วเปิดแอปใหม่ → เมนู **ระบบหลังบ้าน** จะโผล่ในหน้าตั้งค่า

---

## 🔒 ความปลอดภัย

ระบบถูกทดสอบการโจมตีจริงแล้ว และป้องกันได้ทุกกรณี:

| การโจมตี | ผลลัพธ์ |
|---|---|
| เพิ่มข้อมูลโดยไม่ login | 🛡️ บล็อกด้วย RLS |
| ปั๊มแต้มตัวเองผ่าน API | 🛡️ บล็อก (403) |
| ตั้งตัวเองเป็น admin | 🛡️ บล็อก (403) |
| เรียกฟังก์ชัน admin โดยไม่มีสิทธิ์ | 🛡️ บล็อก |
| ส่งแต้มปลอมมากับข้อมูล | 🛡️ server เขียนทับด้วยค่าที่ถูกต้อง |

**หลักการ:** ข้อมูลของใครก็เห็นได้แค่ของตัวเอง (RLS), แต้ม/แรงค์/สิทธิ์แก้ได้เฉพาะฝั่ง server (column-level grant)

> ⚠️ **อย่า commit key ลง git** — `run_dev.ps1` ถูกใส่ใน `.gitignore` แล้ว
> และห้ามใช้ `service_role` key ในแอปเด็ดขาด (มันข้าม RLS ทั้งหมด)

---

## 🔧 ปัญหาที่พบบ่อย

**❌ เปิดแอปแล้วไม่เจอหน้า login**
→ คุณรัน `flutter run` เฉยๆ (โหมด offline) ให้ใช้ `.\run_dev.ps1` แทน

**❌ `Building with plugins requires symlink support`**
→ เปิด **Developer Mode** บน Windows

**❌ `email rate limit exceeded` ตอนสมัคร**
→ ปิด **Confirm email** ใน Supabase (Authentication → Sign In/Providers → Email)
→ free tier ส่งอีเมลได้แค่ ~2-3 ฉบับ/ชั่วโมง

**❌ `Failed host lookup: xxx.supabase.co`**
→ URL ผิด หรือโปรเจกต์ถูก pause (free tier จะ pause อัตโนมัติเมื่อไม่ใช้ ~1 สัปดาห์)
→ เข้า dashboard กด **Restore project**

**❌ พิมพ์ภาษาไทยใน emulator ไม่ได้**
→ เป็นข้อจำกัดของ emulator (ไม่มี layout ไทยสำหรับคีย์บอร์ดฮาร์ดแวร์)
→ **วิธีแก้:** คลิกคีย์บอร์ดบนจอด้วยเมาส์ หรือ copy จาก Notepad มาวาง (Ctrl+V)
→ เพิ่มคีย์บอร์ดไทยบนจอ: `adb shell settings put system system_locales "th-TH,en-US"`
→ **บนมือถือจริงไม่มีปัญหานี้**

**❌ `flutter run -d windows` ไม่ได้**
→ ต้องติดตั้ง Visual Studio + workload "Desktop development with C++"
→ หรือใช้ Android emulator แทน (แนะนำ เพราะเป็นแอปมือถือ)

**❌ แก้โค้ดแล้วแอปไม่เปลี่ยน**
→ กด `R` (hot restart) ในเทอร์มินัล

**❌ build พังหลังแก้ตารางฐานข้อมูล**
```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

---

## 🛠 เทคโนโลยีที่ใช้

| ส่วน | เทคโนโลยี |
|---|---|
| UI | Flutter + Material 3 |
| จัดการ State | Riverpod |
| ฐานข้อมูลในเครื่อง | Drift (SQLite) |
| Backend | Supabase (PostgreSQL + Auth + RLS) |
| Navigation | go_router |
| กราฟ | fl_chart |
| แจ้งเตือน | flutter_local_notifications |
