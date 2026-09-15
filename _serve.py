# -*- coding: utf-8 -*-
"""เสิร์ฟแอปที่ build ไว้แล้วในโฟลเดอร์ build/web ให้เปิดผ่าน Chrome ได้

ใช้ผ่านไฟล์ เปิดแอป.bat  (ไม่ต้องรันไฟล์นี้ตรง ๆ)
"""
import http.server
import os
import socket
import socketserver
import sys

# หน้าต่างดำของ Windows ปกติไม่รองรับภาษาไทย ต้องบังคับเป็น UTF-8 ก่อน
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

PORT = 8000
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "build", "web")


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def end_headers(self):
        # สองบรรทัดนี้ทำให้ฐานข้อมูล SQLite บนเบราว์เซอร์ใช้โหมดเก็บถาวรที่ดีที่สุดได้
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, *args):
        pass  # ไม่ต้องพ่น log รก ๆ ในหน้าต่างดำ


def main():
    if not os.path.exists(os.path.join(ROOT, "index.html")):
        print("ยังไม่มีไฟล์แอป -- ให้กดไฟล์  อัปเดตแอป.bat  ก่อนหนึ่งครั้ง")
        input("กด Enter เพื่อปิด...")
        return 1

    port = PORT
    for _ in range(20):  # ถ้าพอร์ตชนก็เลื่อนไปพอร์ตถัดไป
        with socket.socket() as s:
            if s.connect_ex(("127.0.0.1", port)) != 0:
                break
        port += 1

    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("127.0.0.1", port), Handler) as httpd:
        url = "http://localhost:%d" % port
        print()
        print("  Habit Tracker เปิดอยู่ที่  " + url)
        print()
        print("  * ถ้าเบราว์เซอร์ไม่เด้งขึ้นมา ให้ก๊อป URL ข้างบนไปเปิดใน Chrome")
        print("  * ปิดแอป = ปิดหน้าต่างสีดำนี้")
        print()
        os.system('start "" "%s"' % url)
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
