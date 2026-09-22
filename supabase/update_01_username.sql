-- ============================================================================
-- อัปเดตที่ 1 — แก้ปัญหาชื่อผู้ใช้ซ้ำแล้วสมัครไม่ได้
--
-- อาการเดิม: สมัครด้วยชื่อที่มีคนใช้แล้ว → ขึ้น 500
--            "Database error saving new user" ซึ่งไม่บอกอะไรเลย
-- สาเหตุ:    profiles.username เป็น unique · trigger insert ตรง ๆ เลยชน
--            constraint แล้วพัง ลากให้ auth.signUp ล้มทั้งรายการ
--
-- วิธีใช้: Supabase Dashboard → SQL Editor → New query → วางทั้งไฟล์ → Run
-- รันซ้ำได้ (ใช้ create or replace ทั้งหมด ไม่แตะข้อมูลเดิม)
-- ============================================================================

-- 1) trigger สร้างโปรไฟล์: วนหาชื่อว่างแทนที่จะพัง
--    "test" ที่ซ้ำ จะกลายเป็น "test1" → "test2" ตามลำดับ
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
declare
  base  text := coalesce(
                  nullif(trim(new.raw_user_meta_data->>'username'), ''),
                  'user_' || substr(new.id::text, 1, 8));
  uname text := base;
  n     int  := 0;
begin
  while exists (select 1 from public.profiles where lower(username) = lower(uname)) loop
    n := n + 1;
    uname := base || n::text;
  end loop;

  insert into public.profiles (id, username, display_name)
  values (
    new.id,
    uname,
    coalesce(nullif(trim(new.raw_user_meta_data->>'display_name'), ''), base)
  );
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- 2) ให้แอปเช็กได้ก่อนกดสมัคร ว่าชื่อนี้ว่างไหม
--    เทียบแบบไม่สนตัวพิมพ์เล็กใหญ่ กัน "Test" กับ "test" ที่คนสับสน
--    ใช้ function ไม่ให้ query ตาราง profiles ตรง ๆ
--    เพื่อไม่เปิดช่องให้ไล่ดึงรายชื่อผู้ใช้ทั้งระบบ
create or replace function username_available(name text)
returns boolean language sql stable security definer as $$
  select length(trim(coalesce(name, ''))) >= 3
     and not exists (
       select 1 from public.profiles
       where lower(username) = lower(trim(name))
     );
$$;

-- ตรวจว่าใช้ได้: ควรได้ false (มีคนใช้แล้ว) กับ true (ยังว่าง)
-- select username_available('test'), username_available('ชื่อที่ไม่มีใครใช้');
