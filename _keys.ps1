# ค่าเชื่อมต่อเซิร์ฟเวอร์ Habit Tracker
#
# กุญแจตัวนี้ชื่อขึ้นต้นว่า publishable = Supabase ออกแบบมาให้ฝังในแอปฝั่งผู้ใช้
# มันจะติดไปกับไฟล์ APK และเว็บที่ build ออกไปอยู่แล้ว การซ่อนไว้จึงไม่ช่วยอะไร
# ของจริงที่ปกป้องข้อมูลคือ Row Level Security บนเซิร์ฟเวอร์
# ซึ่งล็อกไว้ว่า habit และบันทึกการติ๊ก เห็นได้เฉพาะเจ้าของเท่านั้น
#
# ถ้าวันหนึ่งต้องเปลี่ยนกุญแจ: Supabase Dashboard > Project Settings > API Keys

$SUPABASE_URL = 'https://nfeijwnoxokvtfsjhzdg.supabase.co'
$SUPABASE_ANON_KEY = 'sb_publishable_gM9lmxe1CcLjcZU3MJcWSg_fPYL72jD'
