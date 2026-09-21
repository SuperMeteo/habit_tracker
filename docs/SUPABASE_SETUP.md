# คู่มือใช้ Supabase (สำหรับคนไม่เคยใช้)

> Supabase = "Firebase เวอร์ชัน open-source บน Postgres" — ได้ Database + Auth + Storage + API อัตโนมัติ ฟรี (มี free tier)
> คู่มือนี้พาทำตั้งแต่ 0 จนแอป Flutter login + อ่าน/เขียนข้อมูลได้

---

## ขั้นที่ 1 — สมัคร + สร้าง Project

1. เข้า https://supabase.com → **Start your project** → login ด้วย GitHub
2. **New project**
   - Organization: สร้างใหม่ (ฟรี)
   - Name: `habit-tracker`
   - **Database Password:** ตั้งรหัสแล้ว **จดเก็บไว้** (ใช้ตอนเชื่อม DB ตรง)
   - Region: **Southeast Asia (Singapore)** ← ใกล้ไทยสุด
3. กด **Create** รอ ~2 นาที

---

## ขั้นที่ 2 — เอา Key มาใส่แอป

ไปที่ **Project Settings (⚙️) → API** จะเจอ 2 ค่าสำคัญ:

| ค่า | ใช้ทำอะไร | ความลับ? |
|-----|-----------|----------|
| **Project URL** | `https://xxxx.supabase.co` | ใส่ในแอปได้ |
| **anon public key** | key ฝั่ง client | ใส่ในแอปได้ (ปลอดภัยเพราะมี RLS คุม) |
| **service_role key** | ข้าม RLS ทั้งหมด | ⛔ **ห้ามใส่ในแอป** ใช้เฉพาะ server/backoffice |

---

## ขั้นที่ 3 — สร้างตาราง (SQL Editor)

ไปที่เมนูซ้าย **SQL Editor → New query** วางสคริปต์จาก
`docs/ONLINE_PLAN.md` หัวข้อ 4.2 แล้วกด **Run**

จากนั้นสร้างฟังก์ชัน leaderboard (หัวข้อ 5.3) และเปิด RLS:

```sql
-- เปิด RLS ทุกตาราง
alter table profiles   enable row level security;
alter table habits     enable row level security;
alter table habit_logs enable row level security;
alter table point_events enable row level security;

-- policy: user เห็น/แก้เฉพาะข้อมูลตัวเอง
create policy "own habits"     on habits     for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own logs"       on habit_logs for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- profiles: อ่านได้ทุกคน (สำหรับ leaderboard), แก้ได้เฉพาะแถวตัวเอง
create policy "read profiles"  on profiles for select using (true);
create policy "update own profile" on profiles for update
  using (id = auth.uid());
```

**Trigger สร้าง profile อัตโนมัติเมื่อสมัคร:**
```sql
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, username, display_name)
  values (new.id,
          coalesce(new.raw_user_meta_data->>'username', 'user_' || substr(new.id::text,1,8)),
          new.raw_user_meta_data->>'display_name');
  return new;
end; $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();
```

---

## ขั้นที่ 4 — ตั้งค่า Auth

**Authentication → Providers → Email** เปิดใช้งาน
- ช่วงพัฒนา: ปิด **Confirm email** (Authentication → Settings) เพื่อไม่ต้องยืนยันอีเมล
- ตอนขึ้น production ค่อยเปิดกลับ

---

## ขั้นที่ 5 — เชื่อมกับ Flutter

```bash
flutter pub add supabase_flutter
```

`lib/core/supabase/supabase_config.dart`:
```dart
class SupabaseConfig {
  static const url = 'https://xxxx.supabase.co';       // จากขั้นที่ 2
  static const anonKey = 'eyJhb....';                   // anon public key
}
```

`lib/main.dart` — init ก่อน runApp:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  await initializeDateFormatting('th', null);
  runApp(const ProviderScope(child: HabitTrackerApp()));
}

// ใช้ที่ไหนก็ได้:
final supabase = Supabase.instance.client;
```

> ⚠️ **อย่า commit key ลง git แบบ public repo** — ถ้าจะ commit ให้ใช้ `--dart-define` หรือไฟล์ config ที่ใส่ใน `.gitignore` (ดูขั้นที่ 8)

---

## ขั้นที่ 6 — ตัวอย่างใช้งาน (จำง่าย)

```dart
final supabase = Supabase.instance.client;

// สมัคร
await supabase.auth.signUp(email: e, password: p,
    data: {'username': 'meteo'});

// login
await supabase.auth.signInWithPassword(email: e, password: p);

// logout
await supabase.auth.signOut();

// user ปัจจุบัน
final user = supabase.auth.currentUser;

// อ่านข้อมูล (RLS กรองให้เห็นเฉพาะของเราอัตโนมัติ)
final rows = await supabase.from('habits').select();

// เขียน / upsert
await supabase.from('habits').upsert({'id': uuid, 'name': 'อ่านหนังสือ'});

// leaderboard (เรียก Postgres function)
final board = await supabase.rpc('get_leaderboard',
    params: {'mode': 'weekly', 'lim': 100});
```

---

## ขั้นที่ 7 — ทดสอบว่าเชื่อมติด

1. รันแอป → signUp ด้วยอีเมลทดสอบ
2. กลับไป Supabase → **Authentication → Users** ต้องเห็น user ใหม่
3. **Table Editor → profiles** ต้องมีแถวถูกสร้างอัตโนมัติ (จาก trigger ขั้นที่ 3)

ถ้าครบ 3 ข้อ = เชื่อมสำเร็จ ✅

---

## ขั้นที่ 8 — เก็บ key ให้ปลอดภัย (ก่อน commit)

**วิธีแนะนำ:** ใช้ `--dart-define` แทน hardcode
```dart
class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
```
รันด้วย:
```bash
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=eyJ....
```
(เก็บคำสั่งนี้ไว้ใน `run_dev.sh` ที่ `.gitignore` แล้ว)

---

## Backoffice: ใช้ Supabase Studio ก่อน

ระหว่างพัฒนา ยังไม่ต้องทำ admin UI เอง — ใช้ **Table Editor** และ **SQL Editor** ใน Supabase dashboard จัดการ user/แต้มได้เลย
เช่น ตั้งตัวเองเป็น admin:
```sql
update profiles set role = 'admin' where username = 'meteo';
```
แล้วค่อยทำ Flutter Web `/admin` (Phase 6 ในแผน) เมื่อพร้อม

---

## สรุป flow ที่ต้องจำ

```
สมัคร Supabase → เอา URL+anonKey → รัน SQL สร้างตาราง+RLS+trigger
   → เปิด Email auth → pub add supabase_flutter → init ใน main.dart
   → signUp/signIn → เช็คว่ามี user+profile → เก็บ key ด้วย dart-define
```
