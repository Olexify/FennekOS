#!/usr/bin/python3
"""QEMU's control socket: vm-qmp.py SOCKET JSON | --key NAME | --type LOWERCASE_TEXT"""
import json, socket, sys, time

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
else:
    r = cmd(json.loads(sys.argv[2]))
print(r)
sys.exit("error" in r)
