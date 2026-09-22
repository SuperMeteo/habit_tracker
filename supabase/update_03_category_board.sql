-- ============================================================================
-- อัปเดตที่ 3 — บอร์ด "ใครที่ 1 ในแต่ละด้าน"
--
-- ส่งกลับแค่ "รหัสหมวด + อันดับ" ไม่ส่งชื่อหมวด
--   เพราะผู้ใช้เปลี่ยนชื่อหมวดเองได้ (id เดิม แต่ชื่อต่างกันในแต่ละเครื่อง)
--   ถ้าเซิร์ฟเวอร์เลือกชื่อให้ จะกลายเป็นบังคับให้ทุกคนเห็นชื่อของคนอื่น
--   → ให้แอปเอาชื่อจากเครื่องตัวเองมาแสดงแทน ทุกคนอ่านในภาษาของตัวเอง
--
-- ⚠️ ไม่ส่งชื่อ habit ออกไปเด็ดขาด — habit เป็นเรื่องส่วนตัวมาก
--    ("เลิกเหล้า" "กินยาความดัน") ส่งแต่ยอดแต้มรวมของด้านนั้น
--
-- วิธีใช้: Supabase Dashboard → SQL Editor → New query → วางทั้งไฟล์ → Run
-- รันซ้ำได้ ไม่แตะข้อมูลเดิม
-- ============================================================================

create or replace function get_category_leaders(
  mode         text default 'alltime',  -- 'weekly' | 'alltime'
  per_category int  default 3,          -- เอาอันดับ 1..N ของแต่ละด้าน
  min_players  int  default 2           -- ด้านที่มีคนน้อยกว่านี้ ไม่นับเป็นการแข่ง
)
returns table(
  category_id uuid,
  players     bigint,
  rank        bigint,
  user_id     uuid,
  username    text,
  tier        text,
  points      bigint
)
language sql stable security definer as $$
  with scoped as (
    select l.user_id, h.category_id, l.points_awarded
    from habit_logs l
    join habits h on h.id = l.habit_id
    where l.deleted_at is null
      and h.deleted_at is null
      and h.category_id is not null
      -- date_trunc('week') ของ Postgres เริ่มวันจันทร์ ตรงกับที่แอปใช้
      and (mode <> 'weekly'
           or l.logged_date >= date_trunc('week', now())::date)
  ),
  totals as (
    select category_id, user_id, sum(points_awarded)::bigint as pts
    from scoped
    group by category_id, user_id
    having sum(points_awarded) > 0
  ),
  counted as (
    select t.category_id,
           t.user_id,
           t.pts,
           count(*) over (partition by t.category_id)               as players,
           rank()   over (partition by t.category_id
                          order by t.pts desc)                      as rnk
    from totals t
  )
  select c.category_id, c.players, c.rnk, c.user_id, p.username, p.tier, c.pts
  from counted c
  join profiles p on p.id = c.user_id
  where c.rnk <= greatest(per_category, 1)
    and c.players >= greatest(min_players, 1)
  order by c.players desc, c.category_id, c.rnk;
$$;

-- ตรวจว่าใช้ได้ (ตอนมีคนน้อยให้ลด min_players ลงเป็น 1 จะเห็นข้อมูล):
-- select * from get_category_leaders('alltime', 3, 1);
