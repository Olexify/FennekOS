# Fennek OS

A comfy, Windows-10-like, no-telemetry Linux desktop with strong built-in security and long battery life.
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

```bash
docker build -f Containerfile -t fennek:dev .
docker run --rm -v ./test.sh:/t.sh fennek:dev bash /t.sh
```

Test VM on Windows (Hyper-V):

1. `vm-disk.ps1` builds and tests the image, then writes `E:\Fennek-build\vm\fennek-next.vhdx`.
2. `vm.ps1`, run as admin, creates the VM and boots it.
