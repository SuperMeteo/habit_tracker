# -*- coding: utf-8 -*-
"""วาด Use Case Diagram ของ Habit_Tracker (ฉบับแก้ถูกตามหลัก UML)"""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Ellipse, FancyArrowPatch, Rectangle

BG = "#111111"
FG = "white"

fig, ax = plt.subplots(figsize=(13, 10), dpi=150)
fig.patch.set_facecolor(BG)
ax.set_facecolor(BG)
ax.set_xlim(0, 14)
ax.set_ylim(0, 11)
ax.axis("off")

# ---------- subsystem box ----------
ax.add_patch(Rectangle((3.2, 0.4), 7.6, 9.6, fill=False, edgecolor=FG, lw=1.2))
ax.text(7.0, 9.75, "«Subsystem»", color=FG, ha="center", va="center", fontsize=11, style="italic", fontweight="bold")
ax.text(7.0, 9.45, "Habit_Tracker", color=FG, ha="center", va="center", fontsize=11, fontweight="bold")

EW, EH = 2.1, 1.15

# ---------- use cases ----------
# คอลัมน์เดียว: ทุกอันที่ User กดเอง
COL_X = 5.2
UC = {
    "Edit / Delete\nHabit": (COL_X, 8.7),
    "Add Habit":            (COL_X, 7.45),
    "Set Reminder":         (COL_X, 6.20),
    "Log Progress":         (COL_X, 4.95),
    "View Dashboard":       (COL_X, 3.70),
    "View Statistics":      (COL_X, 2.45),
    "Change Theme":         (COL_X, 1.20),
    # คอลัมน์ขวา: เฉพาะ use case ที่เป็นเป้าความสัมพันธ์
    "Choose Template":      (9.1, 7.45),
}
def edge(name, side):
    x, y = UC[name]
    if side == "left":   return (x - EW/2, y)
    if side == "right":  return (x + EW/2, y)

for name, (x, y) in UC.items():
    ax.add_patch(Ellipse((x, y), EW, EH, fill=False, edgecolor=FG, lw=1.4))
    ax.text(x, y, name, color=FG, ha="center", va="center", fontsize=10, fontweight="bold")

# ---------- stick-figure actor ----------
def actor(cx, cy, label):
    s = 0.34
    ax.add_patch(Ellipse((cx, cy + s*1.5), s*0.7, s*0.7, fill=False, edgecolor=FG, lw=1.4))
    ax.plot([cx, cx], [cy + s*1.1, cy - s*0.4], color=FG, lw=1.4)
    ax.plot([cx - s*0.95, cx + s*0.95], [cy + s*0.6, cy + s*0.6], color=FG, lw=1.4)
    ax.plot([cx, cx - s*0.85], [cy - s*0.4, cy - s*1.5], color=FG, lw=1.4)
    ax.plot([cx, cx + s*0.85], [cy - s*0.4, cy - s*1.5], color=FG, lw=1.4)
    ax.text(cx, cy - s*2.3, label, color=FG, ha="center", va="center", fontsize=10, fontweight="bold")

USER = (1.1, 4.95)
NOTIF = (12.9, 6.20)
actor(*USER, "User")
actor(*NOTIF, "Notification\nService")

# ---------- association lines (solid) ----------
def line(p1, p2):
    ax.add_patch(FancyArrowPatch(p1, p2, arrowstyle="-", color=FG, lw=1.1,
                                 shrinkA=0, shrinkB=0))

# User -> 7 use cases (fan ออกจากจุดเดียว ไม่ทับวงรีอื่น)
src = (USER[0] + 0.4, USER[1])
for name in ["Edit / Delete\nHabit", "Add Habit", "Set Reminder",
             "Log Progress", "View Dashboard", "View Statistics", "Change Theme"]:
    line(src, edge(name, "left"))

# Set Reminder -> Notification Service
line(edge("Set Reminder", "right"), (NOTIF[0] - 0.4, NOTIF[1]))

# ---------- extend (dashed arrow) ----------
def dashed_arrow(p1, p2, label):
    ax.add_patch(FancyArrowPatch(p1, p2, arrowstyle="-|>", mutation_scale=15,
                                 color=FG, lw=1.1, linestyle=(0, (5, 3)),
                                 shrinkA=2, shrinkB=2))
    mx, my = (p1[0]+p2[0])/2, (p1[1]+p2[1])/2
    ax.text(mx, my + 0.26, "«extend»", color="#9ecbff", ha="center", va="center", fontsize=9)

# Choose Template ..extend..> Add Habit (หัวลูกศรชี้ไปที่ base = Add Habit)
dashed_arrow(edge("Choose Template", "left"), edge("Add Habit", "right"), "«extend»")

plt.tight_layout()
out = r"d:\habit_tracker\Habit_Tracker_UseCase.png"
plt.savefig(out, facecolor=BG, bbox_inches="tight", pad_inches=0.25)
print("SAVED:", out)
