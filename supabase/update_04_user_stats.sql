-- ============================================================================
-- อัปเดตที่ 4 — ดูสถิติของผู้ใช้คนอื่น (แตะชื่อในบอร์ดแล้วเปิดโปรไฟล์)
--
-- ส่งออกเฉพาะ "ตัวเลขรวม": ชื่อ · แรงค์ · แต้ม · แต้มแยกด้าน · วันต่อเนื่อง
-- ⛔ ไม่ส่งชื่อ habit · โน้ต · ค่าที่กรอก · ปฏิทินรายวัน
--    เพราะ habit เป็นเรื่องส่วนตัวมาก ("เลิกเหล้า" "กินยาความดัน")
--
-- as_of รับวันที่จากแอป ไม่ใช้ current_date ของเซิร์ฟเวอร์
--    เพราะ Supabase เดินเวลาเป็น UTC แต่ไทยเร็วกว่า 7 ชั่วโมง
--    ตอนตี 1 ที่ไทย เซิร์ฟเวอร์ยังเป็น "เมื่อวาน" → streak จะหายไป 1 วัน
--
-- ต้องล็อกอินก่อนถึงเรียกได้ (ต่างจาก get_leaderboard ที่เปิดให้ดูได้เลย)
--    ป้ายชื่อ+ตัวเลขในบอร์ดเป็นเรื่องหนึ่ง
--    แต่ภาพรวมพฤติกรรมของคนคนหนึ่งเป็นอีกเรื่อง
--
-- วิธีใช้: Supabase Dashboard → SQL Editor → New query → วางทั้งไฟล์ → Run
-- รันซ้ำได้ ไม่แตะข้อมูลเดิม
-- ============================================================================

create or replace function get_user_public_stats(
  target uuid,
  as_of  date default current_date
)
returns table(
  user_id        uuid,
  username       text,
  display_name   text,
  tier           text,
  total_points   int,
  weekly_points  int,
  done_days      bigint,
  current_streak bigint,
  best_streak    bigint,
  joined_at      timestamptz
)
language plpgsql stable security definer as $$
begin
  if auth.uid() is null then
    raise exception 'ต้องเข้าสู่ระบบก่อนดูโปรไฟล์ผู้อื่น';
  end if;

  return query
  with done as (
    select distinct l.logged_date as d
    from habit_logs l
    where l.user_id = target
      and l.is_done
      and l.deleted_at is null
      and l.logged_date <= as_of
  ),
  -- gaps and islands: วันที่ติดกันจะได้ค่า g เท่ากัน
  grouped as (
    select d, d - (row_number() over (order by d))::int as g
    from done
  ),
  runs as (
    select max(d) as last_day, count(*)::bigint as len
    from grouped
    group by g
  )
  select p.id,
         p.username,
         p.display_name,
         p.tier,
         p.total_points,
         p.weekly_points,
         (select count(*)::bigint from done),
         -- นับเป็น streak ปัจจุบันเฉพาะช่วงที่จบวันนี้หรือเมื่อวาน
         -- เมื่อวานยังนับ เพราะวันนี้อาจยังไม่ถึงเวลาที่เขาทำ
         coalesce((select r.len from runs r
                   where r.last_day >= as_of - 1
                   order by r.last_day desc
                   limit 1), 0),
         coalesce((select max(r.len) from runs r), 0),
         p.created_at
  from profiles p
  where p.id = target;
end; $$;

create or replace function get_user_category_points(
  target uuid,
  mode   text default 'alltime'
)
returns table(category_id uuid, points bigint)
language plpgsql stable security definer as $$
begin
  if auth.uid() is null then
    raise exception 'ต้องเข้าสู่ระบบก่อนดูโปรไฟล์ผู้อื่น';
  end if;

  return query
  select h.category_id, sum(l.points_awarded)::bigint
  from habit_logs l
  join habits h on h.id = l.habit_id
  where l.user_id = target
    and l.deleted_at is null
    and h.deleted_at is null
    and h.category_id is not null
    and (mode <> 'weekly'
         or l.logged_date >= date_trunc('week', now())::date)
  group by h.category_id
  having sum(l.points_awarded) > 0
  order by 2 desc;
end; $$;

-- ตรวจว่าใช้ได้ (ต้องรันในหน้า SQL Editor ซึ่งนับเป็น service role
-- auth.uid() จะเป็น null จึงจะติด exception — ปกติ ไม่ใช่บั๊ก
-- ให้ทดสอบจากในแอปแทน)
