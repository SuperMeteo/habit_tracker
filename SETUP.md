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
git clone https://github.com/username/habit-tracker.git
cd habit-tracker
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

### Step 3 — เปิด Emulator
```powershell
flutter emulators --launch Pixel_6
```
> รอ ~30 วินาที ให้ emulator บูตก่อน

### Step 4 — รันแอป
```powershell
flutter run -d emulator-5554
```

---

## คำสั่งที่ใช้บ่อย

| คำสั่ง | ทำอะไร |
|---|---|
| `flutter pub get` | ติดตั้ง packages |
| `flutter run` | รันแอป |
| `flutter run -d emulator-5554` | รันบน Android Emulator |
| `flutter run -d windows` | รันบน Windows Desktop |
| `flutter devices` | ดู devices ที่เชื่อมอยู่ |
| `flutter emulators` | ดูรายการ emulator ทั้งหมด |
| `flutter clean` | ล้าง build cache |
| `dart run build_runner build` | Generate .g.dart files |

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

---

## โครงสร้างโปรเจกต์ (สรุปสั้นๆ)

```
lib/
├── main.dart              ← จุดเริ่มต้นแอป
├── app.dart               ← ตั้งค่า theme + navigation
├── core/
│   ├── database/          ← ฐานข้อมูล SQLite (drift) — habits, categories, habit_logs
│   ├── theme/             ← สี, ฟอนต์, ธีม
│   ├── services/          ← notification_service.dart (แจ้งเตือนตามเวลา)
│   └── utils/             ← date_utils, streak_calculator, data_exporter (CSV/JSON)
└── features/
    ├── dashboard/         ← หน้าหลัก (เช็ค habit รายวัน)
    ├── habits/            ← เพิ่ม/แก้ไข habit, เลือก template/icon, จัดการหมวดหมู่
    ├── analytics/         ← กราฟรายสัปดาห์, calendar heatmap, streak card
    └── settings/          ← ตั้งค่าแอป, ส่งออกข้อมูล (export_sheet.dart)
```

## ฟีเจอร์ที่ทำเสร็จแล้ว

- ติ๊กเช็ค habit รายวัน + คำนวณ Streak
- ตั้งความถี่แบบ "N ครั้งต่อสัปดาห์"
- จัดการหมวดหมู่ (เพิ่ม/แก้ไข/ลบ)
- กราฟสถิติ + calendar heatmap ในหน้า Analytics
- ส่งออกข้อมูลเป็น CSV / JSON จากหน้าตั้งค่า (ใช้ share_plus)
- แจ้งเตือนตามเวลาที่ตั้งใน habit (flutter_local_notifications + flutter_timezone) — ทดสอบใช้งานได้จริงบน Android
- ชุดทดสอบอัตโนมัติ (`flutter test`) ครอบคลุม การ์ด habit และ Streak รายวัน/เลือกวัน

ที่ยังไม่ได้ทำ: ไอคอนแอป (ยังใช้ของ default) และ `applicationId` ยังเป็น `com.example` · ยังไม่ทดลองกับผู้ใช้จริง

---

> 💡 **แนะนำ:** รัน `flutter doctor` ก่อนเสมอ ถ้ายังมีปัญหาให้ส่ง output มาให้ดู
