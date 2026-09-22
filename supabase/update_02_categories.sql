-- ============================================================================
-- อัปเดตที่ 2 — ซิงก์หมวดหมู่ขึ้นคลาวด์
--
-- ทำไมต้องมี:
--   1) เดิมหมวดหมู่อยู่แต่ในเครื่อง ย้ายมือถือแล้ว habit จะตกไปอยู่หมวดแรก
--   2) บอร์ด "ใครที่ 1 ด้านไหน" ต้องให้เซิร์ฟเวอร์รู้จักชื่อหมวด
--      ตาราง habits มีแต่ category_id เป็นรหัส ไม่มีชื่อ
--
-- กุญแจหลักเป็นคู่ (user_id, id) ไม่ใช่ id เดี่ยว เพราะหมวดตั้งต้น 5 หมวด
-- ใช้ UUID เดียวกันทุกเครื่องทุกคน (ตั้งใจให้เหมือนกันเพื่อจับกลุ่มด้านได้)
-- ถ้าใช้ id เดี่ยว พอผู้ใช้เปลี่ยนชื่อหมวดตั้งต้นแล้วส่งขึ้นมา จะชนแถวของคนอื่น
-- แล้วซิงก์ล้มทั้งรอบ
--
-- วิธีใช้: Supabase Dashboard → SQL Editor → New query → วางทั้งไฟล์ → Run
-- รันซ้ำได้ ไม่แตะข้อมูลเดิม
-- ============================================================================

create table if not exists categories (
  id         uuid not null,
  user_id    uuid not null references auth.users(id) on delete cascade,
  name       text not null,
  color_hex  text default '#6366F1',
  icon_code  int  default 58674,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz,
  primary key (user_id, id)
);

create index if not exists idx_categories_user on categories(user_id);

-- ไม่ผูก foreign key จาก habits.category_id มาที่นี่โดยตั้งใจ
-- เพราะลำดับการซิงก์อาจสลับ (habit ขึ้นก่อนหมวด) ถ้าผูกไว้จะล้มทั้งรอบ
-- ฝั่งแอปมี resolveCategoryId รองรับกรณีหาหมวดไม่เจออยู่แล้ว

alter table categories enable row level security;

drop policy if exists "own categories" on categories;
create policy "own categories" on categories for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
