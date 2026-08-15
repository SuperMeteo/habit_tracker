# 📱 Habit Tracker — คู่มือติดตั้งสำหรับเพื่อน

## สิ่งที่ต้องติดตั้งก่อน (ทำครั้งเดียว)

### 1. Flutter SDK
- ดาวน์โหลดที่ → https://docs.flutter.dev/get-started/install/windows
- เลือก **Windows** → ดาวน์โหลด Flutter SDK (zip)
- แตกไฟล์ไปที่ `C:\flutter`
- เพิ่ม `C:\flutter\bin` ใน Environment Variables > PATH

ตรวจสอบว่าติดตั้งสำเร็จ:
```powershell
flutter --version
```

---

### 2. Android Studio
- ดาวน์โหลดที่ → https://developer.android.com/studio
- ติดตั้งตามปกติ
- เปิด Android Studio → SDK Manager → ติดตั้ง **Android SDK**
- ตั้งค่า `ANDROID_HOME` ใน Environment Variables:
  - Variable: `ANDROID_HOME`
  - Value: `C:\Users\ชื่อคุณ\AppData\Local\Android\Sdk`

---

### 3. Java JDK (ใช้ของ Android Studio ได้เลย)
ตั้งค่า JAVA_HOME ใน Environment Variables:
- Variable: `JAVA_HOME`
- Value: `C:\Program Files\Android\Android Studio\jbr`

---

### 4. Git
- ดาวน์โหลดที่ → https://git-scm.com/download/win
- ติดตั้งตามปกติ (กด Next ไปเรื่อยๆ)

---

### 5. Visual Studio Code (Editor)
- ดาวน์โหลดที่ → https://code.visualstudio.com
- ติดตั้ง Extension: **Flutter** (จะติดตั้ง Dart ให้อัตโนมัติ)

---

### 6. เปิด Developer Mode บน Windows
- กด Start → พิมพ์ "Developer settings"
- เปิด **Developer Mode** → Yes
- (จำเป็นสำหรับ Flutter บน Windows)

---

## รับโปรเจกต์จากเพื่อน

### วิธีที่ 1 — ผ่าน GitHub
```powershell
git clone https://github.com/SuperMeteo/habit_tracker.git
cd habit_tracker
```

### วิธีที่ 2 — รับไฟล์ zip มาตรง
- แตกไฟล์ zip
- เปิด folder ด้วย VS Code หรือ Terminal

---

## ขั้นตอนรันโปรเจกต์

### Step 1 — ติดตั้ง packages
```powershell
cd d:\habit_tracker
flutter pub get
```

### Step 2 — Generate database code
```powershell
dart run build_runner build --delete-conflicting-outputs
```
> จำเป็น! ไฟล์ `*.g.dart` ถูก generate จากโค้ด ไม่ได้เก็บครบใน git

### Step 3 — เปิด Emulator
```powershell
flutter emulators --launch Pixel_6
```
> รอ ~30 วินาที ให้ emulator บูตก่อน

### Step 4 — รันแอป

**แบบ Offline** (ง่ายสุด ใช้ได้เลย ไม่มี login/อันดับ)
```powershell
flutter run -d emulator-5554
```

**แบบ Online** (ครบทุกฟีเจอร์) → ทำ Step 5 ก่อน

---

## Step 5 — ตั้งค่า Supabase (เฉพาะโหมด Online)

> ข้ามได้ถ้าจะใช้แค่โหมด offline · คู่มือละเอียด: [docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md)

### 5.1 สร้าง project
1. สมัคร https://supabase.com (login ด้วย GitHub)
2. **New project** → ตั้งชื่อ → **จดรหัสผ่าน DB ไว้** → region เลือก **Singapore**
3. รอ ~2 นาที ให้สถานะเป็น **Healthy**

### 5.2 สร้างตาราง
1. เมนูซ้าย ไอคอน **`>_`** (SQL Editor) → **New query**
2. เปิดไฟล์ [supabase/schema.sql](supabase/schema.sql) ในโปรเจกต์ → **Ctrl+A** → **Ctrl+C**
3. วางในช่อง SQL → กด **Run**
4. ต้องขึ้น `Success. No rows returned` ✅

### 5.3 ปิดการยืนยันอีเมล (ช่วงพัฒนา)
```
Authentication → Sign In / Providers → Email → ปิด "Confirm email" → Save
```
> ถ้าไม่ปิด: สมัครแล้ว login ไม่ได้จนกว่าจะกดลิงก์ในอีเมล และจะติด rate limit (ส่งได้ ~2-3 ฉบับ/ชม.)

### 5.4 คัดลอก key
```
⚙️ Project Settings → API Keys → copy "publishable key" (ขึ้นต้น sb_publishable_...)
```
> ⛔ **ห้ามใช้ `service_role` / `secret` key** ในแอปเด็ดขาด — มันข้าม RLS ทั้งหมด

### 5.5 สร้างไฟล์ `run_dev.ps1`

สร้างที่รากโปรเจกต์ (ไฟล์นี้อยู่ใน `.gitignore` แล้ว จะไม่ถูก push ขึ้น git)

```powershell
param([string]$d = "")

$url  = "https://<project-ref>.supabase.co"      # จาก Project URL
$key  = "sb_publishable_xxxxxxxxxxxxxxxx"        # จาก 5.4

$deviceArg = if ($d) { @("-d", $d) } else { @() }

flutter run @deviceArg `
  "--dart-define=SUPABASE_URL=$url" `
  "--dart-define=SUPABASE_ANON_KEY=$key"
```

### 5.6 รัน
```powershell
.\run_dev.ps1
```
> ⚠️ ต้องรันใน **Terminal** เท่านั้น — ห้ามดับเบิลคลิกไฟล์ใน File Explorer
> (Windows จะถามว่า "How do you want to open this file?" → กด Cancel)

### 5.7 ตั้งตัวเองเป็น admin (ถ้าอยากใช้ระบบหลังบ้าน)
สมัครสมาชิกในแอปก่อน แล้วรันใน SQL Editor:
```sql
update profiles set role = 'admin' where username = 'ชื่อผู้ใช้ของคุณ';
```

---

## คำสั่งที่ใช้บ่อย

| คำสั่ง | ทำอะไร |
|---|---|
| `.\run_dev.ps1` | **รันแบบ online** (มี login/อันดับ/sync) |
| `flutter run` | รันแบบ offline (ไม่มี login) |
| `flutter pub get` | ติดตั้ง packages |
| `flutter run -d emulator-5554` | รันบน Android Emulator |
| `flutter devices` | ดู devices ที่เชื่อมอยู่ |
| `flutter emulators` | ดูรายการ emulator ทั้งหมด |
| `flutter analyze` | ตรวจ error ในโค้ด |
| `flutter clean` | ล้าง build cache |
| `dart run build_runner build --delete-conflicting-outputs` | Generate .g.dart files |

### คำสั่งขณะรัน (พิมพ์ใน terminal)
| กด | ทำอะไร |
|---|---|
| `r` | Hot reload (เห็นผลทันที) |
| `R` | Hot restart (reset state) |
| `q` | ออกจากแอป |

---

## ตรวจสอบว่าพร้อมรันหรือยัง

```powershell
flutter doctor
```

ต้องเห็น ✅ ทุกข้อ หรืออย่างน้อย:
- ✅ Flutter
- ✅ Android toolchain
- ✅ Android Studio

---

## ปัญหาที่พบบ่อย

**❌ `Building with plugins requires symlink support`**
→ เปิด Developer Mode บน Windows (ดูขั้นตอนที่ 6)

**❌ `JAVA_HOME not set`**
→ ตั้งค่า JAVA_HOME ชี้ไปที่ `C:\Program Files\Android\Android Studio\jbr`

**❌ `flutter pub get` ล้มเหลว**
→ ตรวจสอบ internet แล้วลองใหม่

**❌ emulator ไม่ขึ้น**
→ เปิด Android Studio → Virtual Device Manager → กด ▶️ Pixel 6

**❌ แก้ code แล้วยังเห็นหน้าเดิม**
→ กด `R` (Hot Restart) ใน terminal

**❌ เปิดแอปแล้วไม่เจอหน้า login**
→ รัน `flutter run` เฉยๆ = โหมด offline · ต้องใช้ `.\run_dev.ps1` แทน

**❌ `email rate limit exceeded` ตอนสมัคร**
→ ยังไม่ได้ปิด "Confirm email" (ดู Step 5.3)

**❌ `Failed host lookup: xxx.supabase.co`**
→ URL ผิด หรือโปรเจกต์ถูก pause (free tier pause อัตโนมัติเมื่อไม่ใช้ ~1 สัปดาห์)
→ เข้า dashboard กด **Restore project**

**❌ พิมพ์ภาษาไทยใน emulator ไม่ได้**
→ emulator ไม่มี layout ไทยสำหรับคีย์บอร์ดฮาร์ดแวร์ (ข้อจำกัดของ emulator)
→ ใช้เมาส์คลิกคีย์บอร์ดบนจอ หรือ copy จาก Notepad มาวาง
→ เพิ่มคีย์บอร์ดไทยบนจอ: `adb shell settings put system system_locales "th-TH,en-US"`
→ บนมือถือจริงไม่มีปัญหานี้

**❌ `flutter run -d windows` ไม่ได้**
→ ต้องมี Visual Studio + workload "Desktop development with C++"
→ ใช้ Android emulator แทนดีกว่า (เป็นแอปมือถือ)

---

## โครงสร้างโปรเจกต์ (สรุปสั้นๆ)

```
lib/
├── main.dart              ← จุดเริ่มต้นแอป
├── app.dart               ← routing + guard บังคับ login
├── core/
│   ├── database/          ← ฐานข้อมูล SQLite (drift)
│   ├── supabase/          ← ตั้งค่าเชื่อม Supabase
│   ├── sync/              ← sync local ⇄ cloud
│   ├── theme/             ← สี, ฟอนต์, ธีม
│   └── utils/             ← streak, วันที่
├── data/                  ← Repository Pattern (models/datasources/repositories)
└── features/
    ├── auth/              ← เข้าสู่ระบบ / สมัคร
    ├── dashboard/         ← หน้าหลัก (เช็ค habit)
    ├── habits/            ← เพิ่ม/แก้ไข habit
    ├── analytics/         ← กราฟและสถิติ
    ├── leaderboard/       ← อันดับ
    ├── admin/             ← ระบบหลังบ้าน
    └── settings/          ← ตั้งค่าแอป

supabase/
├── schema.sql             ← ตาราง + trigger + RLS
└── weekly_reset.sql       ← cron รีเซ็ตแต้มรายสัปดาห์
```

---

> 💡 **แนะนำ:** รัน `flutter doctor` ก่อนเสมอ ถ้ายังมีปัญหาให้ส่ง output มาให้ดู
> 📖 ดูฟีเจอร์ทั้งหมดและวิธีใช้งานแอปที่ **[README.md](README.md)**
