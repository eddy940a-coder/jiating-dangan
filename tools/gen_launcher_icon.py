"""
重新生成 Android 启动图标（蓝色圆角 + 白色文档图标）。
运行：python tools/gen_launcher_icon.py
依赖：仅使用 Python 3 标准库。
"""
import zlib
import struct
import os

PRIMARY = (0x1E, 0x4E, 0xD8)
WHITE = (255, 255, 255, 255)


def make(size: int):
    img = [[(0, 0, 0, 0) for _ in range(size)] for _ in range(size)]
    s = size / 108.0

    def rect(x0, y0, x1, y1, color, radius=0.0):
        ax0, ay0, ax1, ay1 = x0 * s, y0 * s, x1 * s, y1 * s
        for py in range(size):
            for px in range(size):
                cx = px + 0.5
                cy = py + 0.5
                if cx < ax0 or cx > ax1 or cy < ay0 or cy > ay1:
                    continue
                ok = True
                if radius > 0:
                    rr = radius * s
                    for ccx, ccy in (
                        (ax0 + rr, ay0 + rr),
                        (ax1 - rr, ay0 + rr),
                        (ax0 + rr, ay1 - rr),
                        (ax1 - rr, ay1 - rr),
                    ):
                        inx = cx < ax0 + rr or cx > ax1 - rr
                        iny = cy < ay0 + rr or cy > ay1 - rr
                        if inx and iny:
                            dx = cx - ccx
                            dy = cy - ccy
                            if dx * dx + dy * dy > rr * rr:
                                ok = False
                if ok:
                    img[py][px] = color

    rect(0, 0, 108, 108, PRIMARY + (255,), radius=24)
    rect(28, 20, 80, 90, WHITE, radius=8)
    rect(38, 33, 70, 38, PRIMARY + (255,), radius=2)
    rect(38, 47, 70, 52, PRIMARY + (255,), radius=2)
    rect(38, 61, 70, 66, PRIMARY + (255,), radius=2)
    rect(38, 75, 58, 80, PRIMARY + (255,), radius=2)
    return img


def write_png(path, img):
    size = len(img)
    raw = bytearray()
    for row in img:
        raw.append(0)
        for r, g, b, a in row:
            raw += bytes((r, g, b, a))

    def chunk(typ, data):
        c = struct.pack('>I', len(data)) + typ + data
        c += struct.pack('>I', zlib.crc32(typ + data) & 0xffffffff)
        return c

    png = b'\x89PNG\r\n\x1a\n'
    png += chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0))
    png += chunk(b'IDAT', zlib.compress(bytes(raw), 9))
    png += chunk(b'IEND', b'')
    with open(path, 'wb') as f:
        f.write(png)


if __name__ == '__main__':
    base = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        'android', 'app', 'src', 'main', 'res',
    )
    for folder, size in (
        ('mipmap-mdpi', 48),
        ('mipmap-hdpi', 72),
        ('mipmap-xhdpi', 96),
        ('mipmap-xxhdpi', 144),
        ('mipmap-xxxhdpi', 192),
    ):
        d = os.path.join(base, folder)
        os.makedirs(d, exist_ok=True)
        write_png(os.path.join(d, 'ic_launcher.png'), make(size))
        print('written', folder, size)
