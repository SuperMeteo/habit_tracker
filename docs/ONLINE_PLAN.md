# Habit Tracker — แผนงาน Online + Gamification

> เอกสารออกแบบสถาปัตยกรรมและแผนงาน สำหรับยกระดับแอปจาก **offline-only** → **offline-first + online (Supabase)**
> พร้อมระบบ **login / คะแนน / แต้ม+แรงค์ / leaderboard** และ **backoffice**
>
> อัปเดต: 2026-07-25

---

## 1. เป้าหมาย (Scope จากผู้ใช้)

| # | ฟีเจอร์ | ต้อง online? | ฐานเดิม |
|---|---------|-------------|---------|
| 1 | ระบบล๊อคอิน (Auth) | ✅ | ยังไม่มี |
| 2 | แสดงความคืบหน้า (Progress) | ❌ | **มีแล้ว** (analytics/heatmap/streak) |
| 3 | ระบบเก็บคะแนน (Score) | บางส่วน | ยังไม่มี |
| 4 | ระบบแต้ม + แรงค์ (Points & Tier) | ✅ | ยังไม่มี |
| 5 | ดูอันดับ (Leaderboard) | ✅ | ยังไม่มี |
| + | **Backoffice / Admin** | ✅ | ยังไม่มี |

**หลักการ:** *offline-first* — แอปยังใช้ได้เต็มรูปแบบแม้ไม่มีเน็ต (local SQLite เป็น source of truth) แล้ว sync ขึ้น Supabase เมื่อ login + ออนไลน์

---

## 2. สถาปัตยกรรมรวม

```
┌─────────────────────────── Flutter App (มือถือ) ───────────────────────────┐
│  UI (screens/widgets)                                                       │
│        │  riverpod providers                                                │
│        ▼                                                                    │
│  Repository Layer  ◄── หัวใจ: ตัวกลางระหว่าง UI กับ data 2 แหล่ง            │
│        ├── LocalDataSource   → drift / SQLite  (source of truth, offline)   │
│        └── RemoteDataSource  → Supabase        (auth + sync + leaderboard)  │
│        ▲                                                                    │
│        │  Sync Engine (background, เมื่อมีเน็ต)                              │
└────────┼────────────────────────────────────────────────────────────────────┘
         │  HTTPS / Realtime
         ▼
┌──────────────────────── Supabase (Backend as a Service) ────────────────────┐
│  Auth (email/password, OAuth)                                               │
│  Postgres DB   → profiles, habits, habit_logs, point_events                 │
│  RLS Policies  → user เห็น/แก้ได้เฉพาะข้อมูลตัวเอง                          │
│  Postgres Functions / Triggers → คำนวณแต้ม (กัน cheat), จัดอันดับ           │
│  Edge Functions (option) → งาน server-side หนักๆ / cron reset weekly       │
└─────────────────────────────────────────────────────────────────────────────┘
         ▲
         │  role = 'admin'
┌────────┴──────── Backoffice (Flutter Web target แยก / หรือ Supabase Studio) ─┐
│  จัดการ user, ปรับแต้ม, ดูสถิติ, จัดการ template/category, ban user          │
└─────────────────────────────────────────────────────────────────────────────┘
```

**ทำไมเลือก Supabase:** leaderboard/rank เป็นงาน SQL (`RANK() OVER (ORDER BY points)`, aggregate) ที่ Postgres ทำได้สวยกว่า NoSQL + มี Auth + RLS + free tier ในตัว ไม่ต้องเขียน server เอง

---

## 3. โครงสร้างโฟลเดอร์ใหม่ (Repository Pattern)

เพิ่ม layer `data/` คั่นระหว่าง `features/` (UI) กับแหล่งข้อมูล เพื่อให้ UI ไม่รู้ว่าข้อมูลมาจาก local หรือ cloud

```
lib/
├── core/
│   ├── database/            # drift (local) — เดิม, จะปรับ schema
│   ├── supabase/            # ★ ใหม่: client, config, constants
│   │   ├── supabase_config.dart
│   │   └── supabase_client_provider.dart
│   ├── sync/                # ★ ใหม่: sync engine (local ⇄ remote)
│   │   ├── sync_service.dart
│   │   └── sync_queue.dart
│   ├── theme/  └── utils/   # เดิม
│
├── data/                    # ★ ใหม่ทั้งก้อน
│   ├── models/              # DTO / domain models (แยกจาก drift row)
│   │   ├── app_user.dart
│   │   ├── leaderboard_entry.dart
│   │   └── point_event.dart
│   ├── datasources/
│   │   ├── local/           # drift DAO wrappers
│   │   │   ├── habit_local_ds.dart
│   │   │   └── log_local_ds.dart
│   │   └── remote/          # Supabase queries
│   │       ├── auth_remote_ds.dart
│   │       ├── habit_remote_ds.dart
│   │       ├── points_remote_ds.dart
│   │       └── leaderboard_remote_ds.dart
│   └── repositories/        # ★ "repo" ที่ต้องทำ
│       ├── auth_repository.dart
│       ├── habit_repository.dart      # offline-first: เขียน local ก่อน แล้ว queue sync
│       ├── points_repository.dart
│       └── leaderboard_repository.dart
│
├── features/                # UI เดิม + ใหม่
│   ├── auth/                # ★ login / signup / profile
│   ├── leaderboard/         # ★ อันดับ + แรงค์
│   ├── analytics/  dashboard/  habits/  settings/   # เดิม
│
└── shared/
```

**กฎ:** provider → เรียก **repository** เท่านั้น ไม่เรียก drift/Supabase ตรงๆ
→ ทำให้ทดสอบง่าย + สลับ backend ได้ + offline-first อยู่ที่จุดเดียว

---

## 4. Data Model

### 4.1 ปรับ schema local (drift) ให้ "sync-ready"

ปัญหาเดิม: ใช้ `integer().autoIncrement()` เป็น PK → **id ชนกันเมื่อ sync หลายเครื่อง**

**เปลี่ยนทุกตารางเป็น:**
```dart
// ก่อน
IntColumn get id => integer().autoIncrement()();

// หลัง
TextColumn get id => text()();          // UUID (ใช้ package uuid ที่มีอยู่แล้ว)
@override Set<Column> get primaryKey => {id};

// เพิ่มทุกตาราง (สำหรับ sync):
TextColumn  get userId    => text().nullable()();   // null = guest, มีค่าเมื่อ login
DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete
TextColumn  get syncStatus => text().withDefault(const Constant('pending'))();
                                     // 'pending' | 'synced'
```

เพิ่มในตาราง `habit_logs`:
```dart
IntColumn get pointsAwarded => integer().withDefault(const Constant(0))();
```

> ⚠️ ต้องเขียน **drift migration** (bump `schemaVersion`) — ทำตอนนี้ถูกที่สุดเพราะข้อมูลยังน้อย

### 4.2 Supabase Postgres Schema

```sql
-- 1) โปรไฟล์ (ผูกกับ auth.users) ─ ใช้สำหรับ leaderboard
create table profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  username      text unique not null,
  display_name  text,
  avatar_url    text,
  total_points  int  not null default 0,   -- แต้มสะสมตลอดกาล (server เขียนเท่านั้น)
  weekly_points int  not null default 0,   -- แต้มสัปดาห์นี้ (reset ทุกจันทร์)
  tier          text not null default 'Bronze',
  role          text not null default 'user',   -- 'user' | 'admin'  (สำหรับ backoffice)
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

-- 2) habits (mirror ของ local)
create table habits (
  id          uuid primary key,
  user_id     uuid not null references auth.users(id) on delete cascade,
  name        text not null,
  category    text,
  color_hex   text,
  icon_code   int,
  frequency_type text default 'daily',
  target_days text,
  updated_at  timestamptz default now(),
  deleted_at  timestamptz          -- soft delete
);

-- 3) habit_logs (ธุรกรรมหลักที่ให้แต้ม)
create table habit_logs (
  id           uuid primary key,
  habit_id     uuid not null references habits(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  logged_date  date not null,
  is_done      boolean default false,
  value        real,
  points_awarded int not null default 0,  -- server คำนวณ ไม่เชื่อ client
  updated_at   timestamptz default now(),
  deleted_at   timestamptz,
  unique (habit_id, logged_date)
);

-- 4) point_events ─ ledger กัน cheat + ให้ backoffice ตรวจย้อนได้
create table point_events (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  source_log  uuid references habit_logs(id) on delete set null,
  points      int not null,
  reason      text not null,           -- 'habit_done' | 'streak_bonus' | 'admin_adjust'
  created_at  timestamptz default now()
);
```

---

## 5. กติกาคะแนน / แต้ม / แรงค์  (ค่าเริ่มต้น — ปรับได้)

> ตรงนี้ยังไม่มีในของเดิม ผมเสนอค่า default ไว้ให้เพื่อนปรับ

### 5.1 การคิดคะแนน (server-side เท่านั้น)
| เหตุการณ์ | แต้ม |
|-----------|------|
| ทำ habit สำเร็จ 1 ครั้ง (`is_done = true`) | **+10** |
| โบนัส streak ต่อเนื่อง | **+2 ต่อวันที่ต่อเนื่อง** (cap +20/วัน) |
| ทำครบทุก habit ในวันนั้น (perfect day) | **+15** |
| ยกเลิก log (`is_done = false`) | หัก points_awarded คืน |

- `total_points` = สะสมตลอดกาล → ใช้จัด tier
- `weekly_points` = แต้มสัปดาห์นี้ → ใช้ leaderboard รายสัปดาห์ (reset จันทร์ 00:00)

### 5.2 แรงค์ / Tier (ตามช่วง total_points)
| Tier | ช่วงแต้ม |
|------|----------|
| 🥉 Bronze | 0 – 499 |
| 🥈 Silver | 500 – 1,499 |
| 🥇 Gold | 1,500 – 3,999 |
| 💎 Platinum | 4,000 – 9,999 |
| 🔷 Diamond | 10,000+ |

### 5.3 Leaderboard
- **2 โหมด:** All-time (total_points) และ Weekly (weekly_points)
- **ขอบเขต:** เริ่มจาก Global (ทุกคน) — เพิ่ม "เฉพาะเพื่อน" ทีหลังได้
- อันดับคำนวณด้วย Postgres:
```sql
create or replace function get_leaderboard(mode text, lim int default 100)
returns table(rank bigint, user_id uuid, username text, points int, tier text)
language sql stable as $$
  select rank() over (order by
           case when mode = 'weekly' then weekly_points else total_points end desc),
         id, username,
         case when mode = 'weekly' then weekly_points else total_points end,
         tier
  from profiles
  order by points desc
  limit lim;
$$;
```

---

## 6. Sync Strategy (offline-first)

**โมเดล:** last-write-wins ต่อ record (พอสำหรับ user คนเดียวใช้หลายเครื่อง)

1. ทุกการเขียน → เขียน **local ก่อน** ตั้ง `syncStatus = 'pending'`, อัปเดต `updatedAt`
2. Sync engine (ทำงานเมื่อออนไลน์ + login):
   - **Push:** ส่ง record ที่ `pending` ขึ้น Supabase (upsert ตาม `updatedAt`)
   - **Pull:** ดึง record ที่ `updated_at > lastSyncAt` ลง local
   - ชนกัน → ตัวที่ `updated_at` ใหม่กว่าชนะ
3. ลบ = soft delete (`deletedAt`) ไม่ลบจริง เพื่อ sync การลบข้ามเครื่องได้
4. **แต้ม:** client ส่งแค่ `is_done` → **Postgres trigger คำนวณ `points_awarded` เอง** แล้ว sync กลับ (กัน cheat)

---

## 7. Security & Anti-cheat

- **RLS (Row Level Security)** เปิดทุกตาราง:
  - `habits`, `habit_logs`: `user_id = auth.uid()` (เห็น/แก้เฉพาะของตัวเอง)
  - `profiles`: อ่านได้ทุกคน (สำหรับ leaderboard) แต่แก้ได้เฉพาะแถวตัวเอง **ยกเว้น** คอลัมน์แต้ม/tier/role → แก้ผ่าน server function เท่านั้น

> ⚠️ **บทเรียนจากการทดสอบจริง (2026-08-15):** RLS policy จำกัดได้แค่ระดับ **แถว** ไม่ได้จำกัด **คอลัมน์**
> policy `update own profile using (id = auth.uid())` เพียงอย่างเดียว **ยังเปิดช่องให้ user ที่ login แล้ว
> PATCH แถวตัวเองเพื่อปั๊ม `total_points` หรือตั้ง `role='admin'` ได้**
> ต้องปิดด้วย **column-level grant** เพิ่ม:
> ```sql
> revoke update on public.profiles from anon, authenticated;
> grant  update (username, display_name, avatar_url) on public.profiles to authenticated;
> ```
> (function ที่เป็น `SECURITY DEFINER` ยังเขียนคอลัมน์แต้มได้ตามปกติ)
- **แต้มไม่เชื่อ client:** คำนวณด้วย Postgres trigger (`SECURITY DEFINER`) ตอน insert/update `habit_logs`
- **Backoffice:** ตรวจ `role = 'admin'` ทั้งฝั่ง RLS และฝั่ง UI

---

## 8. ระบบ Backoffice / Admin

**ทำอะไรได้:**
- ดูรายชื่อ user ทั้งหมด + สถิติ (จำนวน habit, แต้ม, active ล่าสุด)
- ปรับแต้ม / รีเซ็ต / แบน user (บันทึกลง `point_events` reason='admin_adjust')
- จัดการ template / category กลาง
- ดู dashboard ภาพรวม (DAU, แต้มรวม, top users)

**ทางเลือกการทำ (แนะนำไล่จากเร็ว → ครบ):**
| ตัวเลือก | ข้อดี | เหมาะเมื่อ |
|----------|-------|-----------|
| **A. Supabase Studio** (dashboard สำเร็จรูป) | ใช้ได้ทันที ไม่ต้องเขียน | ช่วงแรก / ยังไม่ต้องการ UI สวย |
| **B. Flutter Web target แยก** (guard ด้วย role) | ใช้ codebase เดียว, สวย, คุมได้เต็ม | **แนะนำสำหรับ product** |
| C. Retool / Appsmith / Refine | ลาก-วางเร็ว | ทีมโตขึ้น |

> แผนนี้: **เริ่มด้วย A ระหว่างพัฒนา → ทำ B (route `/admin` ใน Flutter Web) เป็น backoffice จริง**

---

## 9. แผนงานเป็นเฟส (Milestones)

| Phase | งาน | ผลลัพธ์ |
|-------|-----|---------|
| **0. Schema refactor** | เปลี่ยน drift PK → UUID, เพิ่ม userId/updatedAt/deletedAt/syncStatus, เขียน migration | โค้ดเดิมยังทำงาน offline ได้ พร้อม sync |
| **1. Repository layer** | สร้าง `data/` (datasources + repositories), ย้าย provider ให้เรียก repo | UI ไม่แตะ drift ตรงๆ อีก |
| **2. Supabase + Auth** | สร้าง project, ตาราง+RLS, ใส่ `supabase_flutter`, หน้า login/signup/guest | login ได้ |
| **3. Sync engine** | push/pull, conflict resolution, background sync | ข้อมูลข้ามเครื่องได้ |
| **4. Points system** | Postgres trigger คิดแต้ม, `point_events`, tier auto-update | มีแต้ม/แรงค์ |
| **5. Leaderboard UI** | หน้า leaderboard (all-time/weekly), การ์ดอันดับ+tier | ดูอันดับได้ |
| **6. Backoffice** | Flutter Web `/admin`, จัดการ user/แต้ม | admin ใช้งานได้ |
| **7. Hardening** | ทดสอบ RLS/anti-cheat, cron reset weekly, error/retry | พร้อมปล่อยจริง |

**ลำดับสำคัญ:** ทำ Phase 0 + 1 ให้เสร็จก่อนแตะ Supabase — เพราะเป็นการปรับโครงที่กระทบทั้งแอป

---

## 10. Dependencies ที่ต้องเพิ่ม (pubspec.yaml)

```yaml
dependencies:
  supabase_flutter: ^2.8.0     # auth + postgres + realtime
  # uuid: ^4.5.1               # มีอยู่แล้ว
  connectivity_plus: ^6.1.0    # เช็คสถานะเน็ตก่อน sync
```

---

## 10.5 สถานะการพัฒนา (อัปเดต 2026-08-14)

| Phase | สถานะ | หมายเหตุ |
|-------|-------|----------|
| 0. Schema refactor | ✅ เสร็จ | UUID PK + userId/updatedAt/deletedAt/syncStatus + soft delete, migration v2 |
| 1. Repository layer | ✅ เสร็จ | `lib/data/` (models / datasources / repositories) |
| 2. Supabase + Auth | ✅ เสร็จ | หน้า login/signup, `appUserProvider`, redirect guard, guest mode |
| 3. Sync engine | ✅ เสร็จ | `core/sync/sync_service.dart` — push/pull, last-write-wins, claimGuestData, auto-sync ตอน login + ปุ่ม sync ใน Settings |
| 4. Points system | ✅ เสร็จ (server) | trigger `set_log_points` + `apply_points` + `calc_tier` ใน `supabase/schema.sql` |
| 5. Leaderboard UI | ✅ เสร็จ | แท็บ "อันดับ" + โหมด weekly/alltime + highlight ตัวเอง |
| 6. Backoffice | ✅ เสร็จ | หน้า `/admin` — สถิติรวม, รายชื่อผู้ใช้, ปรับแต้ม, ตั้ง/ถอด admin (guard ด้วย `is_admin()` บน server) |
| 7. Hardening | 🔶 บางส่วน | ✅ อุดช่องโหว่ column-level grant, ✅ `supabase/weekly_reset.sql` (pg_cron รีเซ็ต weekly_points ทุกจันทร์ 00:00 ไทย) — ⬜ ยังไม่ได้ทดสอบ e2e กับ Supabase จริง (ติด Confirm email) |

**ไฟล์ที่เพิ่มในเฟส 3-6:**
```
lib/core/sync/sync_service.dart
lib/data/models/{app_user,leaderboard_entry,admin_user_row}.dart
lib/data/datasources/remote/{auth,habit,leaderboard}_remote_ds.dart
lib/data/repositories/{auth,leaderboard,admin}_repository.dart
lib/features/auth/screens/login_screen.dart
lib/features/leaderboard/screens/leaderboard_screen.dart
lib/features/admin/screens/admin_screen.dart
supabase/schema.sql   ← รันใน SQL Editor (มี admin function เพิ่มแล้ว ต้องรันซ้ำ)
```

> ⚠️ **ค้างอยู่:** โดเมนโปรเจกต์ Supabase resolve ไม่ได้ (`Non-existent domain`) — อาจถูก pause
> จาก free tier หรือ URL ที่ใช้สะกดผิด ต้องเอา Project URL ที่ถูกต้องมาใส่ใน `run_dev.ps1`
> ก่อนจึงจะทดสอบ auth/sync/leaderboard จริงได้

---

## 11. Next step

1. เคาะ **กติกาแต้ม/แรงค์** (หัวข้อ 5) กับเพื่อน — ปรับตัวเลขได้
2. เริ่ม **Phase 0** (schema refactor) — ผมช่วยเขียน drift migration + UUID ได้
3. ทำตาม **docs/SUPABASE_SETUP.md** สร้าง project (คู่มือ step-by-step สำหรับคนไม่เคยใช้)
```
