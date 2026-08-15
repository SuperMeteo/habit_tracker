# -*- coding: utf-8 -*-
"""1 UML - กรณีการใช้งานระดับสูงสุด (ฉบับระบบสมาชิก) ของ Habit_Tracker"""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Ellipse, FancyArrowPatch, Rectangle, Circle

BG = "#111111"
FG = "white"
BLUE = "#5B9BD5"
RED = "#E06666"

fig, ax = plt.subplots(figsize=(14, 10), dpi=150)
fig.patch.set_facecolor(BG)
ax.set_facecolor(BG)
ax.set_xlim(0, 14)
ax.set_ylim(0, 10)
ax.axis("off")

# ---------- subsystem box ----------
ax.add_patch(Rectangle((3.3, 0.4), 6.9, 9.2, fill=False, edgecolor=FG, lw=1.2))
ax.text(6.75, 9.35, "«Subsystem»", color=FG, ha="center", va="center", fontsize=11, style="italic", fontweight="bold")
ax.text(6.75, 9.05, "Habit_Tracker", color=FG, ha="center", va="center", fontsize=11, fontweight="bold")

EW, EH = 2.1, 1.05
COL_X = 6.75
UC = {
    "View Dashboard":  (COL_X, 8.2),
    "Log Progress":    (COL_X, 7.0),
    "Add Habit":       (COL_X, 5.8),
    "Set Reminder":    (COL_X, 4.6),
    "View Statistics": (COL_X, 3.4),
    "Login":           (COL_X, 2.2),
    "Register":        (COL_X, 1.0),
}
def edge(name, side):
    x, y = UC[name]
    return (x - EW/2, y) if side == "left" else (x + EW/2, y)

for name, (x, y) in UC.items():
    ax.add_patch(Ellipse((x, y), EW, EH, fill=False, edgecolor=FG, lw=1.4))
    ax.text(x, y, name, color=FG, ha="center", va="center", fontsize=9.5, fontweight="bold")

# ---------- actor ----------
def actor(cx, cy, label, head_color):
    s = 0.30
    ax.add_patch(Circle((cx, cy + s*1.5), s*0.62, facecolor=head_color, edgecolor=FG, lw=1.4, zorder=3))
    ax.plot([cx, cx], [cy + s*1.0, cy - s*0.4], color=FG, lw=1.4)
    ax.plot([cx - s*0.9, cx + s*0.9], [cy + s*0.55, cy + s*0.55], color=FG, lw=1.4)
    ax.plot([cx, cx - s*0.8], [cy - s*0.4, cy - s*1.45], color=FG, lw=1.4)
    ax.plot([cx, cx + s*0.8], [cy - s*0.4, cy - s*1.45], color=FG, lw=1.4)
    ax.text(cx, cy - s*2.2, label, color=FG, ha="center", va="center", fontsize=9.5, fontweight="bold")

MEMBER  = (1.2, 7.2)
GUEST   = (0.75, 4.6)
NEWUSER = (1.2, 1.9)
AUTH    = (12.95, 1.7)
NOTIF   = (12.95, 4.6)
actor(*MEMBER,  "Member",   BLUE)
actor(*GUEST,   "Guest",    BLUE)
actor(*NEWUSER, "New User", BLUE)
actor(*AUTH,    "Authentication\nService", RED)
actor(*NOTIF,   "Notification\nService",   RED)

def line(p1, p2):
    ax.add_patch(FancyArrowPatch(p1, p2, arrowstyle="-", color=FG, lw=1.0, shrinkA=0, shrinkB=0))

# Member -> ฟังก์ชันหลัก
msrc = (MEMBER[0] + 0.35, MEMBER[1])
for name in ["View Dashboard", "Log Progress", "Add Habit", "Set Reminder", "View Statistics", "Login"]:
    line(msrc, edge(name, "left"))
# Guest -> View Dashboard (ดู demo)
line((GUEST[0] + 0.35, GUEST[1]), edge("View Dashboard", "left"))
# New User -> Register
line((NEWUSER[0] + 0.35, NEWUSER[1]), edge("Register", "left"))

# use case -> ระบบบริการ (ขวา)
line(edge("Set Reminder", "right"), (NOTIF[0] - 0.35, NOTIF[1]))
line(edge("Login", "right"),    (AUTH[0] - 0.35, AUTH[1]))
line(edge("Register", "right"), (AUTH[0] - 0.35, AUTH[1]))

plt.tight_layout()
out = r"d:\habit_tracker\Habit_Tracker_UseCase.png"
plt.savefig(out, facecolor=BG, bbox_inches="tight", pad_inches=0.25)
print("SAVED:", out)
