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
echo "sandbox test passed"
EOF
