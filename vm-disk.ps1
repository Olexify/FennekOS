# Builds the Fennek OS image, tests it, and turns it into a Hyper-V disk: E:\Fennek-build\vm\fennek-next.vhdx
# (no admin needed). Then run vm.ps1 as admin to swap it in and boot.
# No $ErrorActionPreference='Stop': Windows PowerShell 5.1 turns docker's stderr progress into errors.
# Every step is checked by exit code instead.
$root = $PSScriptRoot
$vm   = 'E:\Fennek-build\vm'
$log  = 'E:\Fennek-build\tmp'
function Check($what) { if ($LASTEXITCODE -ne 0) { throw "$what failed (exit $LASTEXITCODE), see $log" } }

# Verify the base image's signature and build FROM that exact digest (helper image has skopeo + cosign).
"FROM registry.fedoraproject.org/fedora:44`nRUN dnf -y install skopeo cosign && dnf clean all" | docker build -q -t fennek-verify - *> "$log\verify.log"; Check 'verify helper'
$base = docker run --rm -v "${root}:/src:ro" fennek-verify bash /src/verify-base.sh; Check 'base image signature'
"Base image (signature verified): $base"
docker build --build-arg "BASE_IMAGE=$base" -f "$root\Containerfile" -t fennek:dev $root *> "$log\build.log"; Check 'image build'
docker run --rm -v "$root\test.sh:/t.sh:ro" fennek:dev bash /t.sh; Check 'image tests'

# bootc-image-builder reads podman storage, so copy the image there (dedupes unchanged layers).
# Pipe through cmd: Windows PowerShell 5.1 corrupts binary data piped between native programs.
cmd /c "docker save fennek:dev | docker run --rm -i --privileged -v fennek-podman:/var/lib/containers quay.io/podman/stable:latest podman load > `"$log\load.log`" 2>&1"; Check 'podman load'
docker run --rm --privileged -v fennek-podman:/var/lib/containers quay.io/podman/stable:latest podman image prune -f *>> "$log\load.log"

Remove-Item "$vm\qcow2", "$vm\manifest-qcow2.json" -Recurse -Force -ErrorAction SilentlyContinue
docker run --rm --privileged --security-opt label=type:unconfined_t `
    --mount type=volume,src=fennek-podman,dst=/var/lib/containers/storage,volume-subpath=storage `
    -v "${vm}:/output" -v "$vm\config.toml:/config.toml:ro" `
    quay.io/centos-bootc/bootc-image-builder:latest --type qcow2 --rootfs btrfs docker.io/library/fennek:dev *> "$log\bib.log"
Check 'disk build'

docker run --rm -v "${vm}:/vm" alpine sh -c 'apk add -q qemu-img && qemu-img convert -O vhdx -o subformat=dynamic /vm/qcow2/disk.qcow2 /vm/fennek-next.vhdx && rm -r /vm/qcow2 /vm/manifest-qcow2.json'
Check 'vhdx convert'
Get-Item "$vm\fennek-next.vhdx" | Format-Table Name, LastWriteTime, @{n = 'GB'; e = { [math]::Round($_.Length / 1GB, 2) } }
