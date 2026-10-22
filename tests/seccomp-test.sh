#!/bin/bash
# Fennek seccomp filter check: a Windows program under Wine, a nested sandbox, and the blocked calls.
# Run: docker run --rm --privileged -v ./src/sandbox-seccomp:/src:ro -v ./tests/seccomp-test.sh:/t.sh:ro registry.fedoraproject.org/fedora:44 bash /t.sh
set -u
dnf -y -q install bubblewrap libseccomp-python wine-core mingw64-gcc >/dev/null 2>&1 || { echo "install failed"; exit 1; }
python3 /src/make-filter.py /tmp/f.bpf || exit 1
cat > /tmp/hello.c <<'EOF'
#include <stdio.h>
#include <windows.h>
int main(void) { HANDLE h = CreateFileA("C:\\hello.txt", GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, 0, NULL);
  DWORD n; WriteFile(h, "ok", 2, &n, NULL); CloseHandle(h); printf("hello from windows %lu\n", GetCurrentProcessId()); return 0; }
EOF
x86_64-w64-mingw32-gcc -O2 -o /tmp/hello.exe /tmp/hello.c || exit 1
sb() { sh -c 'exec "$@" 10<"$0"' /tmp/f.bpf bwrap --seccomp 10 --dev-bind / / --proc /proc --unshare-user --unshare-pid --die-with-parent "$@"; }
echo "== wine"
export WINEPREFIX=/tmp/wp WINEDEBUG=-all
sb wine /tmp/hello.exe 2>&1 | grep -a "hello from windows" || echo "WINE FAILED"
echo "== nested sandbox (like Proton's runtime container)"
sb bwrap --dev-bind / / --proc /proc --unshare-user --unshare-pid true && echo "nested ok" || echo "NESTED FAILED"
echo "== blocked calls"
sb python3 - <<'EOF'
import ctypes, errno, fcntl, os, termios
libc = ctypes.CDLL(None, use_errno=True)
def check(name, rc):
    e = ctypes.get_errno()
    print(name, "blocked" if rc == -1 and e == errno.EPERM else f"NOT BLOCKED (rc={rc}, errno={e})")
check("ptrace", libc.ptrace(16, 1, 0, 0))                       # PTRACE_ATTACH
check("keyctl", libc.syscall(250, 0, 0, 0, 0, 0))                # keyctl (x86_64)
check("add_key", libc.syscall(248, b"user", b"x", b"y", 1, -2))   # add_key
check("userfaultfd", libc.syscall(323, 0))
check("io_uring_setup", libc.syscall(425, 1, 0))
check("bpf", libc.syscall(321, 0, 0, 0))
fd = os.open("/dev/null", os.O_RDWR)
try:
    fcntl.ioctl(fd, termios.TIOCSTI, b"x"); print("TIOCSTI NOT BLOCKED")
except OSError as ex:
    print("TIOCSTI", "blocked" if ex.errno == errno.EPERM else f"other error {ex.errno}")
print("normal file write", open("/tmp/ok", "w").write("x") == 1)
EOF
