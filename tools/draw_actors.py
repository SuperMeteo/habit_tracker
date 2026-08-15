# -*- coding: utf-8 -*-
"""รูป Actor ของ Habit_Tracker สำหรับหัวข้อ 2.1.1 (พื้นขาว ใส่ในเอกสาร Word)"""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Circle

FG = "#222222"

def actor(ax, cx, cy, label, head_color):
    s = 1.0
    # head (filled สี)
    ax.add_patch(Circle((cx, cy + s*1.5), s*0.45, facecolor=head_color,
                        edgecolor=FG, lw=1.6, zorder=3))
    ax.plot([cx, cx], [cy + s*1.05, cy - s*0.4], color=FG, lw=1.8)        # body
    ax.plot([cx - s*0.85, cx + s*0.85], [cy + s*0.55, cy + s*0.55], color=FG, lw=1.8)  # arms
    ax.plot([cx, cx - s*0.7], [cy - s*0.4, cy - s*1.5], color=FG, lw=1.8) # left leg
    ax.plot([cx, cx + s*0.7], [cy - s*0.4, cy - s*1.5], color=FG, lw=1.8) # right leg
    ax.text(cx, cy - s*2.15, label, color=FG, ha="center", va="top",
            fontsize=12, fontweight="bold")

def make(filename, items, width):
    fig, ax = plt.subplots(figsize=(width, 3.2), dpi=150)
    fig.patch.set_facecolor("white")
    ax.set_facecolor("white")
    ax.set_xlim(0, len(items) * 3.2)
    ax.set_ylim(-3.5, 3.2)
    ax.axis("off")
    ax.set_aspect("equal")
    for i, (label, color) in enumerate(items):
        actor(ax, i * 3.2 + 1.6, 0.5, label, color)
    plt.tight_layout()
    out = rf"d:\habit_tracker\{filename}"
    plt.savefig(out, facecolor="white", bbox_inches="tight", pad_inches=0.2)
    print("SAVED:", out)
    plt.close(fig)

BLUE = "#5B9BD5"
RED  = "#E06666"

# กลุ่มที่ 1 : ฝั่งผู้ใช้ (น้ำเงิน)
make("Habit_Tracker_Actor_User.png",
     [("Member", BLUE), ("Guest", BLUE), ("New User", BLUE)], width=9.6)
# กลุ่มที่ 2 : ฝั่งระบบบริการ (แดง)
make("Habit_Tracker_Actor_System.png",
     [("Authentication\nService", RED), ("Notification\nService", RED)], width=6.4)
