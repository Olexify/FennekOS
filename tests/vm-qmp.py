#!/usr/bin/python3
"""One command to QEMU's control socket: vm-qmp.py SOCKET JSON"""
import json, socket, sys

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


cmd({"execute": "qmp_capabilities"})
r = cmd(json.loads(sys.argv[2]))
print(r)
sys.exit("error" in r)
