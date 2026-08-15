# -*- coding: utf-8 -*-
"""3 UML - กรณีการใช้งานการเพิ่มนิสัย : รายละเอียดหน้า Add Habit ของ Habit_Tracker"""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Ellipse, FancyArrowPatch, Rectangle

BG = "#111111"
FG = "white"
HILITE = "#F2B441"   # use case หลัก / shared

fig, ax = plt.subplots(figsize=(13.5, 9.5), dpi=150)
fig.patch.set_facecolor(BG)
ax.set_facecolor(BG)
ax.set_xlim(0, 14)
ax.set_ylim(0, 10)
ax.axis("off")

ax.add_patch(Rectangle((0.4, 0.4), 13.2, 9.2, fill=False, edgecolor=FG, lw=1.0))

EW, EH = 2.3, 1.15

COL_X = 7.0
UC = {
    "Add Habit":            (2.9, 5.0, HILITE),    # base (กลางซ้าย)
    "Choose Template":      (COL_X, 8.35, FG),
    "Pick Icon\n& Color":   (COL_X, 6.93, FG),
    "Set Frequency":        (COL_X, 5.51, FG),
    "Set Target\nValue":    (COL_X, 4.09, FG),
    "Set Reminder":         (COL_X, 2.67, FG),
    "Save Habit":           (COL_X, 1.10, HILITE),  # include (บันทึกเสมอ)
}
def edge(name, side):
    x, y, _ = UC[name]
    if side == "left":   return (x - EW/2, y)
    if side == "right":  return (x + EW/2, y)

for name, (x, y, col) in UC.items():
    ax.add_patch(Ellipse((x, y), EW, EH, fill=False, edgecolor=col, lw=1.8 if col == HILITE else 1.4))
    ax.text(x, y, name, color=col if col == HILITE else FG, ha="center", va="center",
            fontsize=10, fontweight="bold")

# ---------- actor: Notification Service ----------
def actor(cx, cy, label):
    s = 0.34
    ax.add_patch(Ellipse((cx, cy + s*1.5), s*0.7, s*0.7, fill=False, edgecolor=FG, lw=1.4))
    ax.plot([cx, cx], [cy + s*1.1, cy - s*0.4], color=FG, lw=1.4)
    ax.plot([cx - s*0.95, cx + s*0.95], [cy + s*0.6, cy + s*0.6], color=FG, lw=1.4)
    ax.plot([cx, cx - s*0.85], [cy - s*0.4, cy - s*1.5], color=FG, lw=1.4)
    ax.plot([cx, cx + s*0.85], [cy - s*0.4, cy - s*1.5], color=FG, lw=1.4)
    ax.text(cx, cy - s*2.3, label, color=FG, ha="center", va="center", fontsize=10, fontweight="bold")

NOTIF = (12.6, 2.67)
actor(*NOTIF, "Notification\nService")

def dashed_arrow(p1, p2, label, lab_dy=0.26):
    ax.add_patch(FancyArrowPatch(p1, p2, arrowstyle="-|>", mutation_scale=15,
                                 color=FG, lw=1.1, linestyle=(0, (5, 3)),
                                 shrinkA=2, shrinkB=2))
    mx, my = (p1[0]+p2[0])/2, (p1[1]+p2[1])/2
    ax.text(mx, my + lab_dy, label, color="#9ecbff", ha="center", va="center", fontsize=9)

def solid_line(p1, p2):
    ax.add_patch(FancyArrowPatch(p1, p2, arrowstyle="-", color=FG, lw=1.1, shrinkA=0, shrinkB=0))

# ----- «extend» : ขั้นตอนตั้งค่าเสริม -> ชี้ไปที่ base (Add Habit) -----
for name in ["Choose Template", "Pick Icon\n& Color", "Set Frequency",
             "Set Target\nValue", "Set Reminder"]:
    dashed_arrow(edge(name, "left"), edge("Add Habit", "right"), "«extend»")

# ----- «include» : เพิ่มนิสัยต้องบันทึกเสมอ -> ชี้ไปที่ Save Habit -----
dashed_arrow(edge("Add Habit", "right"), edge("Save Habit", "left"), "«include»", lab_dy=-0.32)

# ----- Set Reminder เชื่อม Notification Service -----
solid_line(edge("Set Reminder", "right"), (NOTIF[0] - 0.4, NOTIF[1]))

plt.tight_layout()
out = r"d:\habit_tracker\Habit_Tracker_UseCase3.png"
plt.savefig(out, facecolor=BG, bbox_inches="tight", pad_inches=0.25)
print("SAVED:", out)
