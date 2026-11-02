#!/usr/bin/python3
"""QEMU's control socket: vm-qmp.py SOCKET JSON | --key NAME | --type LOWERCASE_TEXT | --wait-blue FILE.ppm SECONDS
--wait-blue: until a screenshot shows the firmware's blue key screen (shim's MokManager).
  vm-qmp.py --selftest
"""
import json, socket, sys, time

BLUE = b"\0\0\x98"   # the firmware console's blue background, one pixel of a P6 PPM


def blue_screen(ppm):
    """On a tenth of the picture at least: the firmware's text area can be much smaller than the screen."""
    return ppm.count(BLUE) * 30 >= len(ppm)


def selftest():
    pixels = 1600 * 900
    head = b"P6\n1600 900\n255\n"
    assert not blue_screen(head + bytes(3 * pixels)), "black"
    assert blue_screen(head + bytes(3 * (pixels - 300000)) + BLUE * 300000), "80x25 text on a big screen"
    assert not blue_screen(head + bytes((40, 30, 80)) * pixels), "dark wallpaper"
    assert not blue_screen(head + bytes((0, 0, 0x90)) * pixels), "some other blue"
    print("selftest ok")


if sys.argv[1:] == ["--selftest"]:
    sys.exit(selftest())

s = socket.socket(socket.AF_UNIX)
s.connect(sys.argv[1])
f = s.makefile("rw")
f.readline()


def cmd(o):
    f.write(json.dumps(o) + "\n")
    f.flush()
    while True:
        r = json.loads(f.readline())
        if "return" in r or "error" in r:
            return r


def key(name):
    return cmd({"execute": "send-key", "arguments": {"keys": [{"type": "qcode", "data": name}]}})


cmd({"execute": "qmp_capabilities"})
if sys.argv[2] == "--key":
    r = key(sys.argv[3])
elif sys.argv[2] == "--type":
    for c in sys.argv[3]:
        r = key(c)
        time.sleep(0.08)
elif sys.argv[2] == "--wait-blue":
    r = {"error": "no blue screen"}
    for _ in range(int(sys.argv[4]) // 3):
        time.sleep(3)
        shot = cmd({"execute": "screendump", "arguments": {"filename": sys.argv[3]}})
        if "return" in shot and blue_screen(open(sys.argv[3], "rb").read()):
            r = shot
            break
else:
    r = cmd(json.loads(sys.argv[2]))
print(r)
sys.exit("error" in r)
