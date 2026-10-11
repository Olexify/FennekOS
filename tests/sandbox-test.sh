#!/usr/bin/env bash
# Integration test for fennek-run-exe auto-containment. Runs inside the Fennek OS image (privileged, for bwrap):
#   docker run --rm --privileged -v fennek-umu-test:/var/home -v <dir with probe.exe>:/fixtures:ro \
#     -v ./tests/sandbox-test.sh:/t.sh:ro fennek:dev bash /t.sh
# First run downloads the Proton runtime (~1-2 GB) into the volume.
set -euo pipefail
id tester >/dev/null 2>&1 || useradd -m -d /var/home/tester tester 2>/dev/null || useradd -M -d /var/home/tester tester
chown -R tester: /var/home/tester

su tester -c 'bash -s' <<'EOF'
set -euo pipefail
export XDG_RUNTIME_DIR=/tmp/xdg-tester; mkdir -p -m 700 "$XDG_RUNTIME_DIR"
win() { echo "Z:$(echo "$1" | tr / '\\')"; }   # Linux path -> Wine path
echo "top secret" > ~/secret.txt
mkdir -p ~/Downloads && cp /fixtures/probe.exe ~/Downloads/probe.exe
rm -f ~/Sandbox/probe/result.txt ~/trusted-result.txt

# Sandboxed: its $HOME/Shared is the real ~/Sandbox/probe; the real ~/secret.txt must be invisible.
fennek-run-exe --sandbox ~/Downloads/probe.exe "$(win "$HOME/Shared/result.txt")" "$(win "$HOME/secret.txt")" >/tmp/sandboxed.log 2>&1 || true
fennek-run-exe --trusted ~/Downloads/probe.exe "$(win "$HOME/trusted-result.txt")" "$(win "$HOME/secret.txt")" >/tmp/trusted.log 2>&1 || true

echo "== sandboxed =="; cat ~/Sandbox/probe/result.txt 2>/dev/null || { echo "FAIL: sandboxed run wrote no result"; tail -20 /tmp/sandboxed.log; exit 1; }
echo "== trusted ==";   cat ~/trusted-result.txt 2>/dev/null     || { echo "FAIL: trusted run wrote no result"; tail -20 /tmp/trusted.log; exit 1; }
grep -q "^BLOCKED " ~/Sandbox/probe/result.txt || { echo "FAIL: sandboxed program could read the secret"; exit 1; }
grep -q "^OK " ~/trusted-result.txt           || { echo "FAIL: trusted program couldn't read the secret"; exit 1; }
# Regression: a download named '...exe' once made "Shared" = ~/Sandbox/.. = the real home (sandbox escape).
cp ~/Downloads/probe.exe ~/Downloads/...exe; rm -f ~/escaped.txt
fennek-run-exe --sandbox ~/Downloads/...exe "$(win "$HOME/Shared/escaped.txt")" >/tmp/dots.log 2>&1 || true
[ ! -e ~/escaped.txt ]                    || { echo "FAIL: '...exe' wrote into the real home"; exit 1; }
[ -e ~/Sandbox/program/escaped.txt ]      || { echo "FAIL: '...exe' didn't run in ~/Sandbox/program"; tail -20 /tmp/dots.log; exit 1; }
# Network, with the launcher's exact pasta flags: internet + DNS work, host-loopback services don't.
python3 -m http.server 8765 --bind 127.0.0.1 >/dev/null 2>&1 & srv=$!
sleep 1
mapfile -d '' -t cfg < <(python3 - <<'PY'
import importlib.machinery, importlib.util, sys
loader = importlib.machinery.SourceFileLoader("fre", "/usr/bin/fennek-run-exe")
m = importlib.util.module_from_spec(importlib.util.spec_from_loader("fre", loader)); loader.exec_module(m)
sys.stdout.write("\0".join([m.SANDBOX_DNS, *m.PASTA]) + "\0")
PY
)
DNS=${cfg[0]}; PASTA=("${cfg[@]:1}")
echo "nameserver $DNS" > /tmp/resolv.test
outer=$(readlink /proc/self/ns/net)
net=$("${PASTA[@]}" -- bwrap --dev-bind / / --ro-bind /tmp/resolv.test /etc/resolv.conf env OUTER="$outer" bash -c '
    [ "$(readlink /proc/self/ns/net)" != "$OUTER" ] && echo OWN-NETNS
    gw=$(ip route | awk "/default/ {print \$3; exit}")
    curl -s -m 3 -o /dev/null "http://$gw:8765" && echo "LEAK-gateway"
    curl -s -m 3 -o /dev/null http://127.0.0.1:8765 && echo "LEAK-loopback"
    getent hosts example.com >/dev/null && echo DNS-OK
    [ "$(curl -s -m 15 -o /dev/null -w "%{http_code}" https://example.com)" = 200 ] && echo NET-OK' 2>&1)
kill $srv
echo "== network =="; echo "$net"
grep -q OWN-NETNS <<<"$net" || { echo "FAIL: network check didn't run inside pasta"; exit 1; }
! grep -q LEAK <<<"$net"   || { echo "FAIL: sandbox reached a host-loopback service"; exit 1; }
grep -q DNS-OK <<<"$net"   || { echo "FAIL: no DNS in the sandbox"; exit 1; }
grep -q NET-OK <<<"$net"   || { echo "FAIL: no internet in the sandbox"; exit 1; }
echo "sandbox test passed"
EOF
