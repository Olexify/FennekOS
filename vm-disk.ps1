# Builds the Fennek OS image, tests it, and turns it into a Hyper-V disk: E:\Fennek-build\vm\fennek-next.vhdx
# (no admin needed). Then run vm.ps1 as admin to swap it in and boot.
# Image builds run in podman (inside a container): the base has ~256 layers, beyond docker's ~127 limit.
# No $ErrorActionPreference='Stop': Windows PowerShell 5.1 turns docker's stderr progress into errors.
# Every step is checked by exit code instead.
$root = $PSScriptRoot
$vm   = 'E:\Fennek-build\vm'
$log  = 'E:\Fennek-build\tmp'
$tag  = 'ghcr.io/ublue-os/kinoite-main:44'
function Check($what) { if ($LASTEXITCODE -ne 0) { throw "$what failed (exit $LASTEXITCODE), see $log" } }
# Through cmd: Windows PowerShell 5.1 mangles long-running native commands whose output is redirected
# (it once reported success for a build that died mid-download).
function Podman([string]$podmanArgs, [string]$logFile) {
    cmd /c "docker run --rm --privileged -v fennek-podman:/var/lib/containers -v `"${root}:/src:ro`" quay.io/podman/stable:latest podman $podmanArgs > `"$logFile`" 2>&1"
}

# 1. Base image signature (Universal Blue's pinned key) -> build FROM exactly the signed digest.
$json = docker run --rm -v "$root\keys:/k:ro" ghcr.io/sigstore/cosign/cosign:v3.1.3 verify --key /k/ublue-cosign.pub $tag 2> "$log\verify.log"
Check 'base image signature'
$digest = (($json -join "`n") | ConvertFrom-Json)[0].critical.image.'docker-manifest-digest'   # 5.1 gets lines
if ($digest -notmatch '^sha256:[0-9a-f]{64}$') { throw "no signed digest in cosign output, see $log\verify.log" }
$base = "ghcr.io/ublue-os/kinoite-main@$digest"
"Base image (signature verified): $base"

# 2. Download the base (12 GB, slow links: podman retries failed layers; a few whole-pull retries on top).
for ($i = 1; $i -le 5; $i++) { Podman "pull --retry 10 $base" "$log\pull.log"; if ($LASTEXITCODE -eq 0) { break }; "pull attempt $i failed, retrying" }
Check 'base image download'

# 3. Build + test.
Podman "build --build-arg BASE_IMAGE=$base -f /src/Containerfile -t localhost/fennek:dev /src" "$log\build.log"; Check 'image build'
Podman "run --rm -v /src/test.sh:/t.sh:ro localhost/fennek:dev bash /t.sh" "$log\test.log"
Get-Content "$log\test.log" -Tail 3; Check 'image tests'
Podman "image prune -f" "$log\prune.log"

# 4. Disk image straight from podman storage, then VHDX for Hyper-V.
Remove-Item "$vm\qcow2", "$vm\manifest-qcow2.json" -Recurse -Force -ErrorAction SilentlyContinue
docker run --rm --privileged --security-opt label=type:unconfined_t `
    --mount type=volume,src=fennek-podman,dst=/var/lib/containers/storage,volume-subpath=storage `
    -v "${vm}:/output" -v "$vm\config.toml:/config.toml:ro" `
    quay.io/centos-bootc/bootc-image-builder:latest --type qcow2 --rootfs btrfs localhost/fennek:dev *> "$log\bib.log"
Check 'disk build'

docker run --rm -v "${vm}:/vm" alpine sh -c 'apk add -q qemu-img && qemu-img convert -O vhdx -o subformat=dynamic /vm/qcow2/disk.qcow2 /vm/fennek-next.vhdx && rm -r /vm/qcow2 /vm/manifest-qcow2.json'
Check 'vhdx convert'
Get-Item "$vm\fennek-next.vhdx" | Format-Table Name, LastWriteTime, @{n = 'GB'; e = { [math]::Round($_.Length / 1GB, 2) } }
