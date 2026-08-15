-- ============================================================================
-- Habit Tracker — Supabase schema (Phase 1)
-- วิธีใช้: เปิด Supabase Dashboard → SQL Editor → New query → วางทั้งไฟล์ → Run
-- รันซ้ำได้ (idempotent) — ใช้ if not exists / create or replace
-- ============================================================================

-- ─── 1) profiles (ผูกกับ auth.users, ใช้ทำ leaderboard) ─────────────────────
create table if not exists profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  username      text unique not null,
  display_name  text,
  avatar_url    text,
  total_points  int  not null default 0,   -- แต้มสะสมตลอดกาล (server เขียนเท่านั้น)
  weekly_points int  not null default 0,   -- แต้มสัปดาห์นี้ (reset ทุกจันทร์)
  tier          text not null default 'Bronze',
  role          text not null default 'user',  -- 'user' | 'admin'
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

-- ─── 2) habits (mirror ของ local drift) ─────────────────────────────────────
create table if not exists habits (
  id             uuid primary key,
  user_id        uuid not null references auth.users(id) on delete cascade,
  name           text not null,
  category_id    uuid,
  description    text default '',
  frequency_type text default 'daily',
  target_days    text default '[1,2,3,4,5,6,7]',
  target_value   real,
  unit           text,
  reminder_time  text,
  color_hex      text default '#6366F1',
  icon_code      int  default 58674,
  is_active      boolean default true,
  created_at     timestamptz default now(),
  updated_at     timestamptz default now(),
  deleted_at     timestamptz            -- soft delete
);
create index if not exists idx_habits_user on habits(user_id);

-- ─── 3) habit_logs (ธุรกรรมหลักที่ให้แต้ม) ──────────────────────────────────
create table if not exists habit_logs (
  id             uuid primary key,
  habit_id       uuid not null references habits(id) on delete cascade,
  user_id        uuid not null references auth.users(id) on delete cascade,
  logged_date    date not null,
  is_done        boolean default false,
  value          real,
  note           text,
  points_awarded int not null default 0,  -- server คำนวณ ไม่เชื่อ client
  created_at     timestamptz default now(),
  updated_at     timestamptz default now(),
  deleted_at     timestamptz,
  unique (habit_id, logged_date)
);
create index if not exists idx_logs_user on habit_logs(user_id);

-- ─── 4) point_events (ledger กัน cheat + ให้ backoffice ตรวจย้อน) ────────────
create table if not exists point_events (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  source_log  uuid references habit_logs(id) on delete set null,
  points      int not null,
  reason      text not null,     -- 'habit_done' | 'admin_adjust'
  created_at  timestamptz default now()
);

-- ============================================================================
-- สร้าง profile อัตโนมัติเมื่อสมัคร
-- ============================================================================
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, username, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', 'user_' || substr(new.id::text, 1, 8)),
    new.raw_user_meta_data->>'display_name'
  );
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ============================================================================
-- คิดแต้ม server-side (anti-cheat) — ทำสำเร็จ 1 ครั้ง = +10 แต้ม
--   BEFORE : กำหนด points_awarded เอง (ไม่เชื่อค่าจาก client)
--   AFTER  : ปรับ total/weekly ใน profiles + บันทึก ledger + อัปเดต tier
-- หมายเหตุ: streak bonus / perfect-day ค่อยเพิ่มภายหลัง
-- ============================================================================
create or replace function calc_tier(pts int)
returns text language sql immutable as $$
  select case
    when pts >= 10000 then 'Diamond'
    when pts >= 4000  then 'Platinum'
    when pts >= 1500  then 'Gold'
    when pts >= 500   then 'Silver'
    else 'Bronze' end;
$$;

create or replace function set_log_points()
returns trigger language plpgsql as $$
begin
  new.points_awarded := case
    when new.is_done and new.deleted_at is null then 10 else 0 end;
  return new;
end; $$;

drop trigger if exists trg_set_log_points on habit_logs;
create trigger trg_set_log_points
  before insert or update on habit_logs
  for each row execute function set_log_points();

create or replace function apply_points()
returns trigger language plpgsql security definer as $$
declare
  delta int;
begin
  delta := new.points_awarded - case when tg_op = 'UPDATE' then old.points_awarded else 0 end;
  if delta <> 0 then
    update profiles
       set total_points  = total_points  + delta,
           weekly_points = weekly_points + delta,
           tier          = calc_tier(total_points + delta),
           updated_at    = now()
     where id = new.user_id;

    insert into point_events (user_id, source_log, points, reason)
    values (new.user_id, new.id, delta, 'habit_done');
  end if;
  return new;
end; $$;

drop trigger if exists trg_apply_points on habit_logs;
create trigger trg_apply_points
  after insert or update on habit_logs
  for each row execute function apply_points();

-- ============================================================================
-- Leaderboard — จัดอันดับด้วย RANK() (mode = 'weekly' | 'alltime')
-- ============================================================================
create or replace function get_leaderboard(mode text default 'alltime', lim int default 100)
returns table(rank bigint, user_id uuid, username text, points int, tier text)
language sql stable as $$
  select rank() over (order by s.p desc), s.id, s.username, s.p, s.tier
  from (
    select id, username, tier,
           case when mode = 'weekly' then weekly_points else total_points end as p
    from profiles
  ) s
  order by s.p desc
  limit lim;
$$;

-- ============================================================================
-- Backoffice / Admin
-- ต้องทำผ่าน function (SECURITY DEFINER) เพราะ RLS ห้าม user แก้แถวคนอื่น
-- ============================================================================

-- เช็คว่าคนที่เรียกเป็น admin หรือไม่
create or replace function is_admin()
returns boolean language sql stable security definer as $$
  select coalesce((select role = 'admin' from profiles where id = auth.uid()), false);
$$;

-- รายชื่อผู้ใช้ทั้งหมด + สถิติ (เฉพาะ admin)
create or replace function admin_list_users(lim int default 200)
returns table(
  id uuid, username text, display_name text, total_points int,
  weekly_points int, tier text, role text, habit_count bigint, created_at timestamptz
)
language plpgsql stable security definer as $$
begin
  if not is_admin() then
    raise exception 'forbidden: admin only';
  end if;
  return query
    select p.id, p.username, p.display_name, p.total_points, p.weekly_points,
           p.tier, p.role,
           (select count(*) from habits h
             where h.user_id = p.id and h.deleted_at is null) as habit_count,
           p.created_at
    from profiles p
    order by p.total_points desc
    limit lim;
end; $$;

-- ปรับแต้มผู้ใช้ (บวก/ลบ) + บันทึกลง ledger
create or replace function admin_adjust_points(
  target_user uuid, delta int, note text default 'admin_adjust')
returns int language plpgsql security definer as $$
declare
  new_total int;
begin
  if not is_admin() then
    raise exception 'forbidden: admin only';
  end if;

  update profiles
     set total_points  = greatest(0, total_points + delta),
         weekly_points = greatest(0, weekly_points + delta),
         updated_at    = now()
   where id = target_user
  returning total_points into new_total;

  update profiles set tier = calc_tier(new_total) where id = target_user;

  insert into point_events (user_id, points, reason)
  values (target_user, delta, note);

  return new_total;
end; $$;

-- ตั้ง/ถอดสิทธิ์ admin
create or replace function admin_set_role(target_user uuid, new_role text)
returns void language plpgsql security definer as $$
begin
  if not is_admin() then
    raise exception 'forbidden: admin only';
  end if;
  if new_role not in ('user', 'admin') then
    raise exception 'invalid role';
  end if;
  update profiles set role = new_role, updated_at = now() where id = target_user;
end; $$;

-- สถิติภาพรวมสำหรับ dashboard หลังบ้าน
create or replace function admin_stats()
returns table(total_users bigint, total_habits bigint, total_logs bigint, points_sum bigint)
language plpgsql stable security definer as $$
begin
  if not is_admin() then
    raise exception 'forbidden: admin only';
  end if;
  return query
    select (select count(*) from profiles),
           (select count(*) from habits where deleted_at is null),
           (select count(*) from habit_logs where deleted_at is null and is_done),
           (select coalesce(sum(total_points), 0) from profiles);
end; $$;

-- ============================================================================
-- Row Level Security
-- ============================================================================
alter table profiles     enable row level security;
alter table habits       enable row level security;
alter table habit_logs   enable row level security;
alter table point_events enable row level security;

-- profiles: อ่านได้ทุกคน (leaderboard), แก้ได้เฉพาะแถวตัวเอง
drop policy if exists "read profiles"       on profiles;
drop policy if exists "update own profile"  on profiles;
create policy "read profiles"      on profiles for select using (true);
create policy "update own profile" on profiles for update using (id = auth.uid());

-- ⚠️ สำคัญ (anti-cheat): RLS จำกัดได้แค่ "แถว" ไม่ได้จำกัด "คอลัมน์"
-- ถ้าไม่ใส่ส่วนนี้ user ที่ login แล้วจะ PATCH แถวตัวเองเพื่อ
-- ปั๊ม total_points หรือตั้ง role='admin' ได้เลย
-- → ใช้ column-level grant ให้แก้ได้เฉพาะข้อมูลโปรไฟล์
-- (trigger/function ที่เป็น SECURITY DEFINER ยังเขียนแต้มได้ตามปกติ)
revoke update on public.profiles from anon, authenticated;
grant  update (username, display_name, avatar_url)
       on public.profiles to authenticated;

-- habits / habit_logs: เห็น+แก้ได้เฉพาะของตัวเอง
drop policy if exists "own habits" on habits;
create policy "own habits" on habits for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own logs" on habit_logs;
create policy "own logs" on habit_logs for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- point_events: อ่านได้เฉพาะของตัวเอง (server เขียนผ่าน trigger security definer)
drop policy if exists "read own points" on point_events;
create policy "read own points" on point_events for select
  using (user_id = auth.uid());
