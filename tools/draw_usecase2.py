# -*- coding: utf-8 -*-
"""2 UML - ดูกรณีการใช้งานรายการ : รายละเอียดหน้า View Dashboard ของ Habit_Tracker"""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Ellipse, FancyArrowPatch, Rectangle

BG = "#111111"
FG = "white"
HILITE = "#F2B441"   # use case หลัก / shared (เหลืองแบบตัวอย่าง)

fig, ax = plt.subplots(figsize=(13.5, 9.5), dpi=150)
fig.patch.set_facecolor(BG)
ax.set_facecolor(BG)
ax.set_xlim(0, 14)
ax.set_ylim(0, 10)
ax.axis("off")

# กรอบรอบ diagram
ax.add_patch(Rectangle((0.4, 0.4), 13.2, 9.2, fill=False, edgecolor=FG, lw=1.0))

EW, EH = 2.2, 1.2

UC = {
    "View\nDashboard":      (2.9, 5.0, HILITE),   # base (กลางซ้าย)
    "View Daily\nSummary":  (7.0, 8.1, FG),
    "Select Date":          (7.0, 6.55, FG),
    "Toggle Habit\nDone":   (7.0, 5.0, FG),
    "Log Numeric\nValue":   (7.0, 3.45, FG),
    "Go to Today":          (7.0, 1.9, FG),
    "Save Progress":        (11.6, 4.2, HILITE),  # shared include (ขวา)
}
def edge(name, side):
    x, y, _ = UC[name]
    if side == "left":   return (x - EW/2, y)
    if side == "right":  return (x + EW/2, y)
    if side == "top":    return (x, y + EH/2)
    if side == "bottom": return (x, y - EH/2)

for name, (x, y, col) in UC.items():
    ax.add_patch(Ellipse((x, y), EW, EH, fill=False, edgecolor=col, lw=1.8 if col == HILITE else 1.4))
    ax.text(x, y, name, color=col if col == HILITE else FG, ha="center", va="center",
            fontsize=10, fontweight="bold")

def dashed_arrow(p1, p2, label, lab_dy=0.26, lab_dx=0.0):
    ax.add_patch(FancyArrowPatch(p1, p2, arrowstyle="-|>", mutation_scale=15,
                                 color=FG, lw=1.1, linestyle=(0, (5, 3)),
                                 shrinkA=2, shrinkB=2))
    mx, my = (p1[0]+p2[0])/2, (p1[1]+p2[1])/2
    ax.text(mx + lab_dx, my + lab_dy, label, color="#9ecbff", ha="center", va="center", fontsize=9)

# ----- «extend» : การกระทำเสริม -> ชี้ไปที่ base (View Dashboard) -----
for name in ["Select Date", "Toggle Habit\nDone", "Log Numeric\nValue", "Go to Today"]:
    dashed_arrow(edge(name, "left"), edge("View\nDashboard", "right"), "«extend»")

# ----- «include» : View Dashboard แสดงสรุปเสมอ -> ชี้ไปที่ included -----
dashed_arrow(edge("View\nDashboard", "top"), edge("View Daily\nSummary", "left"), "«include»", lab_dy=0.3)

# ----- «include» : บันทึกผลทุกครั้งต้อง Save Progress -----
dashed_arrow(edge("Toggle Habit\nDone", "right"), edge("Save Progress", "left"), "«include»", lab_dy=0.28)
dashed_arrow(edge("Log Numeric\nValue", "right"), edge("Save Progress", "left"), "«include»", lab_dy=-0.3)

plt.tight_layout()
out = r"d:\habit_tracker\Habit_Tracker_UseCase2.png"
plt.savefig(out, facecolor=BG, bbox_inches="tight", pad_inches=0.25)
print("SAVED:", out)
