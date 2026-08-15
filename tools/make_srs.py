# -*- coding: utf-8 -*-
"""สร้างเอกสาร SRS ของ Habit_Tracker เป็นไฟล์ .docx ตามฟอร์แมตตัวอย่าง Training Reserve"""
from docx import Document
from docx.shared import Pt, RGBColor, Cm
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

THAI_FONT = "TH Sarabun New"

def set_run_font(run, size=16, bold=False, color=None, font=THAI_FONT):
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.name = font
    if color is not None:
        run.font.color.rgb = color
    rpr = run._element.get_or_add_rPr()
    rfonts = rpr.find(qn('w:rFonts'))
    if rfonts is None:
        rfonts = OxmlElement('w:rFonts')
        rpr.append(rfonts)
    rfonts.set(qn('w:ascii'), font)
    rfonts.set(qn('w:hAnsi'), font)
    rfonts.set(qn('w:cs'), font)
    # complex-script size
    szcs = OxmlElement('w:szCs')
    szcs.set(qn('w:val'), str(int(size * 2)))
    rpr.append(szcs)
    if bold:
        bcs = OxmlElement('w:bCs')
        rpr.append(bcs)

def add_para(doc, text="", size=16, bold=False, align=None, color=None, space_after=6, indent=None):
    p = doc.add_paragraph()
    if align is not None:
        p.alignment = align
    pf = p.paragraph_format
    pf.space_after = Pt(space_after)
    pf.space_before = Pt(0)
    if indent is not None:
        pf.left_indent = Cm(indent)
    if text:
        r = p.add_run(text)
        set_run_font(r, size=size, bold=bold, color=color)
    return p

def add_heading(doc, text, size=18, space_before=10, space_after=6):
    p = doc.add_paragraph()
    pf = p.paragraph_format
    pf.space_before = Pt(space_before)
    pf.space_after = Pt(space_after)
    r = p.add_run(text)
    set_run_font(r, size=size, bold=True)
    return p

def add_bullet(doc, text, indent=1.0, bold_prefix=None):
    p = doc.add_paragraph(style=None)
    pf = p.paragraph_format
    pf.left_indent = Cm(indent)
    pf.space_after = Pt(3)
    r0 = p.add_run("•  ")
    set_run_font(r0, size=16)
    if bold_prefix:
        rb = p.add_run(bold_prefix)
        set_run_font(rb, size=16, bold=True)
    r = p.add_run(text)
    set_run_font(r, size=16)
    return p

def shade_cell(cell, fill="D9D9D9"):
    tcpr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear')
    shd.set(qn('w:fill'), fill)
    tcpr.append(shd)

def set_cell_text(cell, segments, size=13, align=WD_ALIGN_PARAGRAPH.LEFT):
    """segments: list of (text, bold, color) or a plain string"""
    cell.text = ""
    p = cell.paragraphs[0]
    p.alignment = align
    p.paragraph_format.space_after = Pt(0)
    if isinstance(segments, str):
        segments = [(segments, False, None)]
    for text, bold, color in segments:
        r = p.add_run(text)
        set_run_font(r, size=size, bold=bold, color=color)

# ---------- Header (repeats every page) ----------
def build_header(section):
    header = section.header
    header.is_linked_to_previous = False
    # clear default empty paragraph
    tbl = header.add_table(rows=3, cols=2, width=Cm(17))
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl.style = 'Table Grid'
    # widths
    for row in tbl.rows:
        row.cells[0].width = Cm(12.5)
        row.cells[1].width = Cm(4.5)
    set_cell_text(tbl.cell(0, 0), [("Application : ", False, None), ("Habit_Tracker", False, RGBColor(0xC0, 0x00, 0x00))])
    set_cell_text(tbl.cell(0, 1), [("เวอร์ชัน:  2.0", False, None)])
    set_cell_text(tbl.cell(1, 0), "รายวิชา 29-40901-2104 การเขียนโปรแกรมประยุกต์บนอุปกรณ์เคลื่อนที่")
    set_cell_text(tbl.cell(1, 1), "วันที่: 13 มิถุนายน 2569")
    set_cell_text(tbl.cell(2, 0), [("ผู้จัดทำ  1.ภูตะวัน ทองวิลาศ   2.ยศนันทน์ กันทาทิพย์", True, None)])
    set_cell_text(tbl.cell(2, 1), "")
    # spacer paragraph after table
    sp = header.add_paragraph()
    sp.paragraph_format.space_after = Pt(2)

# ---------- Footer (repeats every page, with page number) ----------
def add_page_field(paragraph):
    run = paragraph.add_run()
    fldStart = OxmlElement('w:fldChar'); fldStart.set(qn('w:fldCharType'), 'begin')
    instr = OxmlElement('w:instrText'); instr.set(qn('xml:space'), 'preserve'); instr.text = ' PAGE '
    fldEnd = OxmlElement('w:fldChar'); fldEnd.set(qn('w:fldCharType'), 'end')
    run._element.append(fldStart); run._element.append(instr); run._element.append(fldEnd)
    set_run_font(run, size=14)

def build_footer(section):
    footer = section.footer
    footer.is_linked_to_previous = False
    tbl = footer.add_table(rows=1, cols=3, width=Cm(17))
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl.style = 'Table Grid'
    tbl.cell(0, 0).width = Cm(5.0)
    tbl.cell(0, 1).width = Cm(9.0)
    tbl.cell(0, 2).width = Cm(3.0)
    set_cell_text(tbl.cell(0, 0), "วิทยาลัยเทคนิคเชียงใหม่", size=14, align=WD_ALIGN_PARAGRAPH.CENTER)
    set_cell_text(tbl.cell(0, 1), "ครูประจำรายวิชา นางสาววราภรณ์ แผ่นฟ้า", size=14, align=WD_ALIGN_PARAGRAPH.CENTER)
    c = tbl.cell(0, 2)
    c.text = ""
    p = c.paragraphs[0]; p.alignment = WD_ALIGN_PARAGRAPH.CENTER; p.paragraph_format.space_after = Pt(0)
    r = p.add_run("หน้า "); set_run_font(r, size=14)
    add_page_field(p)

# ================= BUILD DOCUMENT =================
doc = Document()
section = doc.sections[0]
section.top_margin = Cm(2.2)
section.bottom_margin = Cm(2.0)
section.left_margin = Cm(2.2)
section.right_margin = Cm(2.0)
section.header_distance = Cm(1.0)
section.footer_distance = Cm(1.0)

# set Normal style default font
normal = doc.styles['Normal']
normal.font.name = THAI_FONT
normal.font.size = Pt(16)

build_header(section)
build_footer(section)

red = RGBColor(0xC0, 0x00, 0x00)

# ===== TITLE =====
add_para(doc, "เอกสารประกอบความต้องการของระบบ Habit_Tracker", size=20, bold=True,
         align=WD_ALIGN_PARAGRAPH.CENTER, space_after=14)

# ===== 1. บทนำ =====
add_heading(doc, "1.  บทนำ", size=18)
add_para(doc, "ปัจจุบันผู้คนให้ความสำคัญกับการดูแลสุขภาพและการพัฒนาตนเองมากขึ้น การสร้างนิสัยที่ดี "
              "เช่น การออกกำลังกาย การอ่านหนังสือ หรือการดื่มน้ำให้เพียงพอ จำเป็นต้องอาศัยความสม่ำเสมอ "
              "และการติดตามผลอย่างต่อเนื่อง แต่หลายคนมักลืมหรือขาดเครื่องมือที่ช่วยบันทึกความคืบหน้า"
              "ได้อย่างเป็นระบบ")
add_para(doc, "จากเหตุผลข้างต้น ทางคณะผู้จัดทำจึงพัฒนาแอพพลิเคชัน Habit_Tracker ขึ้น เพื่อช่วยให้ผู้ใช้"
              "สามารถสร้าง บันทึก และติดตามนิสัยประจำวันได้ พร้อมทั้งแสดงสถิติและกราฟความคืบหน้า "
              "ซึ่งเกิดประโยชน์ดังนี้")
add_bullet(doc, "ผู้ใช้สามารถบันทึกการทำนิสัยประจำวันได้ตลอด 24 ชั่วโมง")
add_bullet(doc, "แอพพลิเคชันแสดงสถิติ Streak และกราฟความคืบหน้าได้อย่างชัดเจน")
add_bullet(doc, "มีระบบแจ้งเตือนช่วยให้ผู้ใช้ไม่ลืมทำนิสัยที่ตั้งไว้")
add_bullet(doc, "ผู้ใช้สามารถเลือกนิสัยจาก Template สำเร็จรูป หรือสร้างเองได้")

add_heading(doc, "1.1  วัตถุประสงค์", size=17)
add_bullet(doc, "เพื่อให้ได้แอพพลิเคชันที่ช่วยติดตามและสร้างนิสัยที่ดี และสามารถนำไปพัฒนาต่อได้อย่างต่อเนื่อง")
add_bullet(doc, "เพื่อให้การจัดการข้อมูลการติดตามนิสัยเป็นปัจจุบัน ตั้งแต่ ประเภทนิสัย เป้าหมาย ความถี่ และความคืบหน้ารายวัน/รายสัปดาห์")
add_bullet(doc, "เพื่อให้เกิดต้นแบบในการพัฒนาซอฟต์แวร์เชิงอุตสาหกรรมขนาดเล็ก โดยใช้เอกสารที่ได้จากการวิเคราะห์และออกแบบระบบเชิงวัตถุด้วย UML")

add_heading(doc, "1.2  ขอบเขต", size=17)
add_para(doc, "ศึกษาปัญหาและความต้องการของแอพพลิเคชันจากผู้ใช้ที่ต้องการสร้างนิสัยที่ดี โดยใช้การวิเคราะห์"
              "และออกแบบระบบเชิงวัตถุด้วย UML ดำเนินการพัฒนาแอพพลิเคชัน Habit_Tracker ตามผลการศึกษา"
              "ความต้องการและความเป็นไปได้ และทดสอบปรับปรุงแก้ไขแอพพลิเคชันให้ทำงานได้อย่างถูกต้อง "
              "พร้อมจัดทำคู่มือการติดตั้งและการใช้งาน")

doc.add_page_break()

# ===== 2. รายละเอียดทั่วไปของระบบ =====
add_heading(doc, "2.  รายละเอียดทั่วไปของระบบ", size=18)
add_para(doc, "ระบบประกอบด้วย การติดตามและบันทึกนิสัยผ่านแอพพลิเคชัน และมีกระบวนการพื้นฐาน "
              "(Basic Process) ในการทำงานดังต่อไปนี้")
add_bullet(doc, "ผู้ใช้ ดูหน้า Dashboard และบันทึกการทำนิสัยประจำวัน (Log Progress)")
add_bullet(doc, "ผู้ใช้ เพิ่ม / แก้ไข / ลบ นิสัย (Add / Edit / Delete Habit)")
add_bullet(doc, "ผู้ใช้ ดูสถิติ Streak และกราฟความคืบหน้า (View Statistics)")
add_bullet(doc, "ระบบ แจ้งเตือนตามเวลาที่ผู้ใช้ตั้งไว้ (Notification Service)")

add_heading(doc, "2.1  ภาพรวมของระบบ (Use-Case Model Survey)", size=17)
add_para(doc, "จากการศึกษาความต้องการของระบบ การทำงานของระบบจะถูกนำเสนอผ่านยูสเคสและแอคเตอร์ "
              "ดังรายละเอียดต่อไปนี้")
add_para(doc, "1 UML – กรณีการใช้งานระดับสูงสุด (Top-Level Use Case)", bold=True,
         align=WD_ALIGN_PARAGRAPH.CENTER, color=red, space_after=4)
add_para(doc, "[ วาง Use Case Diagram ของ Habit_Tracker ตรงนี้ ]", align=WD_ALIGN_PARAGRAPH.CENTER,
         color=RGBColor(0x80, 0x80, 0x80), space_after=10)

# 2.1.1 Actor
add_heading(doc, "2.1.1  Actor", size=16, space_before=8)
add_para(doc, "Application Habit_Tracker ประกอบไปด้วยแอคเตอร์ดังต่อไปนี้:")
add_bullet(doc, "ผู้ใช้แอพพลิเคชัน เป็นผู้สร้าง บันทึก และติดตามนิสัยของตนเอง สามารถใช้งานทุกฟังก์ชันได้โดยไม่ต้องลงทะเบียนหรือเข้าสู่ระบบ (แอปทำงานแบบออฟไลน์ เก็บข้อมูลในเครื่อง)", bold_prefix="User (ผู้ใช้) : ")
add_bullet(doc, "ระบบแจ้งเตือนภายในเครื่อง (flutter_local_notifications) ทำหน้าที่ส่งการแจ้งเตือนให้ผู้ใช้ตามเวลาที่ตั้งไว้สำหรับแต่ละนิสัย", bold_prefix="Notification Service : ")

# 2.1.2 Use Cases
add_heading(doc, "2.1.2  Use Cases", size=16, space_before=8)
add_para(doc, "Application Habit_Tracker สนับสนุนการทำงานดังต่อไปนี้:")
add_para(doc, "1) การทำงานหลัก (หน้า Dashboard และการจัดการนิสัย)", bold=True, space_after=3, indent=0.5)
add_bullet(doc, "แสดงรายการนิสัยของวันที่เลือก พร้อมสถานะการทำในแต่ละวัน", bold_prefix="View Dashboard : ")
add_bullet(doc, "บันทึกการทำนิสัย (ติ๊กว่าทำแล้ว หรือกรอกค่าตัวเลข เช่น กม. นาที แก้ว)", bold_prefix="Log Progress : ")
add_bullet(doc, "เพิ่มนิสัยใหม่ พร้อมตั้งชื่อ ไอคอน สี ความถี่ และเป้าหมาย", bold_prefix="Add Habit : ")
add_bullet(doc, "แก้ไขรายละเอียดหรือลบนิสัยที่มีอยู่", bold_prefix="Edit / Delete Habit : ")
add_para(doc, "2) การทำงานเสริมของ Add Habit", bold=True, space_after=3, indent=0.5)
add_bullet(doc, "เลือกนิสัยจาก Template สำเร็จรูป 3 หมวด (กีฬา / ชีวิต / การศึกษา) — «extend» Add Habit", bold_prefix="Choose Template : ")
add_bullet(doc, "ตั้งเวลาแจ้งเตือนของนิสัย ซึ่งจะส่งคำสั่งไปยัง Notification Service", bold_prefix="Set Reminder : ")
add_para(doc, "3) การทำงานหน้าสถิติ", bold=True, space_after=3, indent=0.5)
add_bullet(doc, "แสดงภาพรวมสถิติของทุกนิสัย ประกอบด้วยจำนวนวันที่ทำต่อเนื่อง (Streak) และกราฟแท่งความคืบหน้ารายสัปดาห์ของนิสัยแบบตัวเลข", bold_prefix="View Statistics : ")
add_para(doc, "4) การตั้งค่า", bold=True, space_after=3, indent=0.5)
add_bullet(doc, "เปลี่ยนธีมแอป สว่าง / มืด / ตามระบบ", bold_prefix="Change Theme : ")

doc.add_page_break()

# 2.2
add_heading(doc, "2.2  คุณลักษณะของผู้ใช้ (User Characteristics)", size=17)
add_para(doc, "Application Habit_Tracker ถูกออกแบบมาเพื่อใช้สำหรับผู้ใช้ชาวไทยโดยเฉพาะ ผู้ใช้ระบบมีเพียง"
              "ประเภทเดียว คือ ผู้ใช้ทั่วไป (User) ที่ต้องการสร้างและติดตามนิสัยของตนเอง ผู้ใช้สามารถเข้าถึง"
              "ทุกฟังก์ชันได้ทันทีโดยไม่ต้องลงทะเบียนหรือเข้าสู่ระบบ เนื่องจากแอพพลิเคชันทำงานแบบออฟไลน์ "
              "และจัดเก็บข้อมูลทั้งหมดไว้ภายในเครื่องของผู้ใช้ ทำให้ใช้งานได้สะดวก รวดเร็ว และเป็นส่วนตัว")

# 2.3
add_heading(doc, "2.3  กฎเกณฑ์หรือข้อบังคับโดยทั่วไป (General Constraints)", size=17)
add_para(doc, "Application Habit_Tracker ถูกออกแบบขึ้นโดยใช้การวิเคราะห์และออกแบบเชิงวัตถุ ได้แก่ UML "
              "(Unified Modeling Language) ซึ่งช่วยให้เข้าใจปัญหาและออกแบบระบบได้อย่างเป็นระบบ ลดเวลา"
              "ในการพัฒนา สะดวกต่อการบำรุงรักษาและแก้ไข ส่วนการพัฒนาแอพพลิเคชันใช้เทคโนโลยี Flutter "
              "(ภาษา Dart) ในการสร้างแอปบนอุปกรณ์เคลื่อนที่ และใช้ฐานข้อมูล SQLite ผ่านไลบรารี Drift "
              "ในการจัดเก็บข้อมูลภายในเครื่อง")

# 2.4
add_heading(doc, "2.4  สมมุติฐานและเงื่อนไขของระบบ (Assumptions and Dependencies)", size=17)
add_para(doc, "Application Habit_Tracker จะถูกติดตั้งบนอุปกรณ์เคลื่อนที่ของผู้ใช้ (ระบบปฏิบัติการ Android "
              "หรือ iOS) โดยไม่จำเป็นต้องเชื่อมต่อเซิร์ฟเวอร์หรืออินเทอร์เน็ต ข้อมูลทั้งหมดถูกจัดเก็บใน"
              "ฐานข้อมูล SQLite ภายในเครื่อง และระบบแจ้งเตือนทำงานผ่านบริการแจ้งเตือนของระบบปฏิบัติการ "
              "(Local Notification) บนตัวเครื่องโดยตรง")

out = r"d:\habit_tracker\Habit_Tracker_SRS.docx"
doc.save(out)
print("SAVED:", out)
