# Fennek OS

A Linux desktop for **people leaving Windows 10**. It feels familiar, has no telemetry, comes with strong
built-in security, and aims for long battery life.
Built as a [bootc](https://containers.github.io/bootc/) image on Fedora Kinoite (KDE Plasma).

What's in it so far:

- **Windows programs:** double-click any `.exe`, which runs it through Proton (umu-launcher).
- **Auto-containment:** unknown programs run in a sandbox. They see only `~/Sandbox/<program>` and never your real home.
- **VirusTotal check:** right-click any file. Only the file's hash is sent, never the file.
- **Download guard:** ClamAV scans new files in Downloads, and threats go to quarantine. No always-on scanner daemon.
- **Hourly home snapshots:** Btrfs and snapper, as an undo for ransomware.
- **Atomic updates:** updates are staged in the background and applied on the next reboot. They are never forced.
- **Windows-familiar:** Windows 10-style taskbar, and `dir`, `cls`, `ipconfig` work in the terminal.

Plans, decisions and status: [SCOPE.md](SCOPE.md).

## Build

Base: Universal Blue's Kinoite, signature-verified and pinned by digest. Build with podman (the base has
~256 layers, more than docker supports):

```bash
base=$(bash verify-base.sh)
podman build --build-arg BASE_IMAGE=$base -f Containerfile -t fennek:dev .
podman run --rm -v ./test.sh:/t.sh:ro fennek:dev bash /t.sh
```

Test VM on Windows (Hyper-V):

1. `vm-disk.ps1` builds and tests the image, then writes `E:\Fennek-build\vm\fennek-next.vhdx`.
2. `vm.ps1`, run as admin, creates the VM and boots it.

## Contributing, security, license

- Want to help? See [CONTRIBUTING.md](CONTRIBUTING.md).
- Found a security problem? Report it privately; see [SECURITY.md](SECURITY.md).
- Fennek OS's own code is licensed under [GPL-3.0](LICENSE). Bundled components keep their own licenses.
- The name "Fennek OS" and the fox logo are not covered by the GPL; forks must rename. See [TRADEMARKS.md](TRADEMARKS.md).
