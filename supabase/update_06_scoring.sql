-- ============================================================================
-- อัปเดตที่ 6 — คะแนนแบบแรงค์ คิดจากความต่อเนื่อง
--
-- กติกา (ต้องตรงกับ lib/core/scoring/score_calculator.dart เป๊ะ ๆ)
--   ผ่าน 1 หมวดใน 1 วัน = ทำ habit ในหมวดนั้นสำเร็จอย่างน้อย 1 อัน
--   ผ่าน  : +10 คูณด้วยตัวคูณต่อเนื่อง  (1-6 วัน ×1 · 7-13 ×1.25 · 14-29 ×1.5 · 30+ ×2)
--   ไม่ผ่าน: -5 และตัวนับต่อเนื่องกลับเป็น 0
--   คะแนนต่ำสุดคือ 0 ไม่ติดลบ
--   วันนี้ที่ยังไม่ได้ทำ ไม่ถือว่าขาด เพราะวันยังไม่จบ
--   ครบ 4 หมวดในวันเดียว = 40 คะแนน
--
-- ทำไมคิดสดจากประวัติ ไม่เก็บเป็นยอดสะสม:
--   ยอดสะสมไม่รู้ว่า "เมื่อวานไม่ได้ทำ" จึงหักคะแนนเองไม่ได้ ต้องตั้งงาน
--   อัตโนมัติมาไล่หัก ซึ่งจะทำให้เครื่องที่ใช้ออฟไลน์เห็นคะแนนไม่ตรงกับเซิร์ฟเวอร์
--   คิดสดแล้วสูตรเดียวกันรันได้ทั้งสองฝั่ง และแก้สูตรทีหลังได้โดยไม่ต้องล้างข้อมูล
--
-- as_of รับวันที่จากแอป ไม่ใช้ current_date เพราะเซิร์ฟเวอร์เดินเวลาแบบ UTC
-- ซึ่งช้ากว่าไทย 7 ชั่วโมง ตอนตี 1 ที่ไทยจะกลายเป็นเมื่อวาน
--
-- วิธีใช้: Supabase Dashboard → SQL Editor → New query → วางทั้งไฟล์ → Run
-- รันซ้ำได้ ไม่แตะข้อมูลเดิม
-- ============================================================================

create or replace function scored_category_ids()
returns uuid[] language sql immutable as $$
  select array[
    '11111111-1111-4111-8111-111111111101'::uuid,
    '11111111-1111-4111-8111-111111111106'::uuid,
    '11111111-1111-4111-8111-111111111107'::uuid,
    '11111111-1111-4111-8111-111111111108'::uuid
  ];
$$;

create or replace function streak_multiplier(s int)
returns numeric language sql immutable as $$
  select case
    when s >= 30 then 2.0
    when s >= 14 then 1.5
    when s >= 7  then 1.25
    else 1.0 end;
$$;

-- คะแนนของผู้ใช้ 1 คนในหมวด 1 หมวด
-- from_day = null → เริ่มนับจากวันแรกที่เคยทำ (โหมดตลอดกาล)
-- from_day มีค่า   → นับเฉพาะช่วงนั้น (ใช้ทำโหมดสัปดาห์นี้)
create or replace function calc_category_points(
  uid      uuid,
  cat      uuid,
  as_of    date,
  from_day date default null
)
returns table(points int, streak int, best_streak int)
language plpgsql stable as $$
declare
  d      date;
  start  date;
  hit    boolean;
  p      int := 0;
  s      int := 0;
  b      int := 0;
begin
  select min(l.logged_date) into start
    from habit_logs l
    join habits h on h.id = l.habit_id
   where l.user_id = uid
     and h.category_id = cat
     and l.is_done
     and l.deleted_at is null
     and h.deleted_at is null
     and l.logged_date <= as_of
     and (from_day is null or l.logged_date >= from_day);

  if start is null then
    points := 0; streak := 0; best_streak := 0;
    return next;
    return;
  end if;

  if from_day is not null and from_day > start then
    start := from_day;
  end if;

  d := start;
  while d <= as_of loop
    select exists (
      select 1
        from habit_logs l
        join habits h on h.id = l.habit_id
       where l.user_id = uid
         and h.category_id = cat
         and l.logged_date = d
         and l.is_done
         and l.deleted_at is null
         and h.deleted_at is null
    ) into hit;

    if hit then
      s := s + 1;
      if s > b then b := s; end if;
      p := p + round(10 * streak_multiplier(s));
    elsif d < as_of then
      p := p - 5;
      s := 0;
    end if;

    if p < 0 then p := 0; end if;
    d := d + 1;
  end loop;

  points := p; streak := s; best_streak := b;
  return next;
end; $$;

-- คะแนนแยก 4 ด้านของผู้ใช้คนหนึ่ง (แอปเรียกมาวาดหลอดคะแนน)
create or replace function get_user_scores(
  target_user uuid default null,
  as_of       date default current_date,
  mode        text default 'alltime'
)
returns table(category_id uuid, points int, streak int, best_streak int)
language plpgsql stable security definer as $$
declare
  uid  uuid := coalesce(target_user, auth.uid());
  fromd date := case when mode = 'weekly'
                     then date_trunc('week', as_of)::date
                     else null end;
  c    uuid;
  r    record;
begin
  if uid is null then return; end if;
  foreach c in array scored_category_ids() loop
    select * into r from calc_category_points(uid, c, as_of, fromd);
    category_id := c;
    points := r.points;
    streak := r.streak;
    best_streak := r.best_streak;
    return next;
  end loop;
end; $$;

create or replace function get_user_total_points(
  target_user uuid,
  as_of       date default current_date,
  mode        text default 'alltime'
)
returns int language sql stable security definer as $$
  select coalesce(sum(points), 0)::int
    from get_user_scores(target_user, as_of, mode);
$$;

-- ============================================================================
-- กระดานอันดับ — คะแนนรวม และเลือกดูเฉพาะด้านได้
-- category ว่าง = รวมทุกด้าน · มีค่า = เฉพาะด้านนั้น
-- ============================================================================
create or replace function get_leaderboard(
  mode  text default 'alltime',
  lim   int  default 100,
  as_of date default current_date,
  cat   uuid default null
)
returns table(rank bigint, user_id uuid, username text, points int, tier text)
language sql stable security definer as $$
  with scored as (
    select p.id,
           p.username,
           case
             when cat is null then get_user_total_points(p.id, as_of, mode)
             else (select gs.points
                     from get_user_scores(p.id, as_of, mode) gs
                    where gs.category_id = cat)
           end as pts
      from profiles p
  )
  select rank() over (order by coalesce(s.pts, 0) desc),
         s.id,
         s.username,
         coalesce(s.pts, 0),
         calc_tier(coalesce(s.pts, 0))
    from scored s
   order by coalesce(s.pts, 0) desc
   limit lim;
$$;

-- แชมป์แต่ละด้าน — ใช้คะแนนสูตรใหม่แทนการบวกแต้มดิบ
create or replace function get_category_leaders(
  mode         text default 'alltime',
  per_category int  default 3,
  min_players  int  default 2,
  as_of        date default current_date
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
  with all_scores as (
    select p.id as uid, p.username, gs.category_id, gs.points
      from profiles p
      cross join lateral get_user_scores(p.id, as_of, mode) gs
     where gs.points > 0
  ),
  counted as (
    select a.category_id,
           a.uid,
           a.username,
           a.points,
           count(*) over (partition by a.category_id)            as players,
           rank()   over (partition by a.category_id
                          order by a.points desc)                as rnk
      from all_scores a
  )
  select c.category_id,
         c.players,
         c.rnk,
         c.uid,
         c.username,
         calc_tier(c.points),
         c.points::bigint
    from counted c
   where c.rnk <= greatest(per_category, 1)
     and c.players >= greatest(min_players, 1)
   order by c.players desc, c.category_id, c.rnk;
$$;

-- ตรวจสอบ:
-- select * from get_user_scores(auth.uid(), current_date);
-- select * from get_leaderboard('alltime', 20, current_date);
-- select * from get_leaderboard('alltime', 20, current_date,
--        '11111111-1111-4111-8111-111111111101');
