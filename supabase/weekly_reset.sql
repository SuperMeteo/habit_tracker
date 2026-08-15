-- ============================================================================
-- รีเซ็ตแต้มรายสัปดาห์ (weekly_points) ทุกวันจันทร์ 00:00
--
-- ไฟล์นี้แยกจาก schema.sql เพราะต้องเปิด extension pg_cron ก่อน
-- ซึ่งต้องทำผ่าน dashboard: Database → Extensions → ค้นหา "pg_cron" → เปิด
--
-- ทำไมต้องมี: leaderboard โหมด "สัปดาห์นี้" อ่านจาก profiles.weekly_points
-- ถ้าไม่รีเซ็ต ค่านี้จะสะสมไปเรื่อยๆ จนเท่ากับ total_points (โหมด weekly ไร้ความหมาย)
-- ============================================================================

-- ─── 1) ฟังก์ชันรีเซ็ต ──────────────────────────────────────────────────────
create or replace function reset_weekly_points()
returns void language sql security definer as $$
  update profiles set weekly_points = 0, updated_at = now()
   where weekly_points <> 0;
$$;

-- ─── 2) ตั้ง cron job (ต้องเปิด pg_cron ก่อน) ────────────────────────────────
-- '0 17 * * 0' = ทุกวันอาทิตย์ 17:00 UTC = วันจันทร์ 00:00 เวลาไทย (UTC+7)
--
-- ถ้ายังไม่ได้เปิด extension บรรทัดล่างจะ error — เปิดที่
-- Database → Extensions → pg_cron ก่อนแล้วค่อยรันไฟล์นี้ใหม่

create extension if not exists pg_cron;

-- ลบ job เดิมถ้ามี (กันซ้ำเวลารันไฟล์นี้หลายรอบ)
select cron.unschedule(jobid)
  from cron.job where jobname = 'reset_weekly_points';

select cron.schedule(
  'reset_weekly_points',
  '0 17 * * 0',
  $$select reset_weekly_points();$$
);

-- ─── ตรวจสอบ ────────────────────────────────────────────────────────────────
-- ดู job ที่ตั้งไว้:      select * from cron.job;
-- ดูประวัติการรัน:       select * from cron.job_run_details order by start_time desc limit 10;
-- สั่งรีเซ็ตเองทันที:     select reset_weekly_points();
