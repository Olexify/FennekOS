# Fennek OS — Scope

A comfy, classic, no-telemetry, very secure Linux OS with best-in-class laptop battery life.

## Decisions
- **Base:** Linux kernel, immutable image (Fedora Atomic), Wayland only (X11 can't be sandboxed).
- **Windows apps:** Proton/Wine via umu-launcher; double-click `.exe` just works (auto runner, auto deps, community fix DB).
- **Battery:** 15h on 100 Wh = milestone 1; 30h = marketing goal. Claims always state the test workload. Certify 1–2 reference laptops first.
- **No telemetry.** Anything that leaves the device is opt-in.

## Security (Comodo-style, kernel-native, ~zero idle cost)
- **Mark of origin:** files arriving from browsers/USB/chat get a `user.fennek.trust=unknown` xattr (a mark-of-the-web flag).
- **Auto-containment:** unknown executables (`.exe`, AppImage, scripts) run automatically in a sandbox:
  bubblewrap namespaces + Landlock + seccomp, overlay filesystem (writes are throwaway), own shared folder only,
  network via firewall policy, camera/mic/screen via portal prompts.
- **Trust levels:** Trusted (Fennek OS repo, verified Flathub, user-approved) / Unknown (contained) / Malicious (blocked).
- **Sandbox as built (fennek-run-exe):** bwrap inside its own pasta network namespace (internet yes, host-only
  abstract sockets/X11/D-Bus no); Wayland display via Wine-Wayland when Proton supports it, X11 only as fallback;
  sound (= microphone) only on explicit choice; file names sanitized (a `...exe` once escaped to the real home).
  Known limits: X11 fallback can read other Xwayland windows/clipboard; no seccomp filter yet; kernel bugs.
- **Native apps:** Flatpak by default (already sandboxed).
- **Ransomware undo:** hourly Btrfs snapshots of home (copy-on-write, near free), one-click restore.
- **Behavior guard (later):** eBPF watcher for mass renames/encryption, autostart writes, process injection.
- **Scanning:** ClamAV on new downloads + on demand only. VirusTotal: hash lookup by default, upload only on explicit opt-in, user's own API key.

## Reliability & recovery
- **Atomic updates:** each update is a new system image (bootc/rpm-ostree); previous one kept in the boot menu.
- **Auto-rollback:** boot health checks (greenboot + systemd boot counting); failed boot → previous image boots itself.
- **Updates never nag:** downloaded and staged in background, applied on next normal reboot. Firmware via fwupd.
- **Snapshots:** system before every update/change; home hourly (Btrfs/snapper, auto-pruned). Restore from Settings or boot menu.
- **No freezes:** zram + systemd-oomd kill the runaway app instead of the whole system locking up.
- **Crash reports stay local:** app crash → friendly dialog + restart; kernel panic → log saved (pstore/kdump),
  shown on next boot as "why it crashed" (AI can explain). Nothing sent anywhere.
- **Encryption:** LUKS2 full-disk, TPM2 unlock, recovery key shown at install. Secure Boot signed images.
- **Backups (snapshots ≠ backups):** one-click encrypted backup to USB drive / NAS / cloud (restic).
- **Reset this PC:** factory reset keeping files (trivial on an image-based system). Safe-mode boot entry + recovery USB.
- **Critical battery:** save session and hibernate. Open problem: hibernation vs Secure Boot lockdown.

## Dual boot with Windows (no conflicts)
- **Installer "Install next to Windows":** shrink Windows partition with a size slider. Detects BitLocker →
  shows how to get the recovery key and shrink from Windows first (Linux can't resize BitLocker volumes).
- **Bootloader:** shim + GRUB on the existing EFI partition (kernels live in /boot, so a small 100 MB Windows ESP is fine).
  Boot menu remembers last choice; firmware Windows entry left untouched.
- **Secure Boot stays on:** Microsoft-signed shim. Secured-core laptops (e.g. Lenovo) need "Allow Microsoft 3rd Party
  UEFI CA" in BIOS → installer detects and explains. Keep shim current (SBAT revocations broke dual boot in 2024).
  Verify our shim against the 2023 Microsoft UEFI CA (2011 CA expired June 2026).
- **Clock:** Windows detected → hardware clock in local time (Linux side), so the time doesn't jump between OSes.
- **Windows Fast Startup/hibernation:** Windows drive auto-mounts **read-only** when Windows isn't fully shut down,
  with a plain explanation (writing to it would corrupt data). Installer offers how to turn Fast Startup off.
- **Shared files:** Windows drive appears as "Windows (C:)" in the file manager (ntfs3). Optional shared NTFS/exFAT partition.
- **"Restart to Windows"** in the power menu (one-time BootNext, no menu needed).
- **Disk encryption:** BitLocker and LUKS independent. TPM unlock bound to Secure Boot state (PCR 7) so Windows/BIOS
  updates don't constantly trigger the recovery key.
- **Disk space (no fixed partition sizes):** one Btrfs partition with subvolumes for system and home, so there's no
  "system drive full while home has space". Grows/shrinks while running. Free space that isn't adjacent (or a second
  disk) can be added to the same pool (`btrfs device add`), with a clear warning if it spans two physical disks.
- **"Rebalance space with Windows" tool:** slider between Windows and Fennek OS. Moves partitions (incl. the Recovery
  partition that usually blocks extending C:) from an offline boot step. Requires AC power, Windows fully shut down,
  backup offered first. BitLocker volumes: Fennek OS frees the space right next to C:, then Windows' own "Extend Volume"
  finishes the job. Recovery partition moves need careful testing (WinRE registration).
- **Clean removal:** "Remove Fennek OS" guide/tool that restores Windows boot and frees the partitions.
- **Test matrix:** an older and the current Windows version (BitLocker on), each next to Fennek OS, in VMs and on reference laptops.

## Firewall
Not in Fedora repos: upstream RPM v1.8.0 (pin + sha256, like umu): daemon
`e06e9119daf764e56455b61c319e496274c0274bb53bb94a0ff1ab72967fea7d`, needs only libnetfilter_queue; rules = JSON in
/etc/opensnitchd/rules. Upstream UI (~50 MB PyQt6 + pip, prompts on every connection) → don't ship; build our own.
**v1 done:** default zone `FennekOS` (in: dhcpv6, mdns, kdeconnect only; Fedora's default opened 1025-65535) and
`FennekOS-Public` (in: dhcpv6 only) to pick per Wi-Fi network. `fennek-firewall block|allow|list PROGRAM` +
Dolphin right-click → Firewall: OpenSnitch reject rule (native by path, Windows by .exe in command line);
sandboxed .exe → no network namespace at all. opensnitchd runs only while ≥1 program is blocked.
Verified: blocked curl can't connect, python can. Next: GUI with live connections + Process Explorer.
OpenSnitch daemon + our own friendly UI: per-app allow/block, ask-or-silent modes, network profiles
(Home / Public / Offline), DNS tracker blocking, temporary rules, live connection view.

## Search ("Everything", but comfier)
**v1 done (fennek-search):** per-user service, home + /run/media drives, live via inotify (no rescans), hidden
dirs/caches/sandboxes skipped, served to Start menu + KRunner over D-Bus (org.kde.krunner1), filters ext: type:
path:, opened-files history ranks first, "Open containing folder" action. Python, linear scan (~10 ms/100k
files). Next: Everything-style window with columns/sort, Explorer search integration, size:/dm: filters,
whole-disk index (needs a root helper with per-user permission filtering), Rust if homes get huge.
- Own Rust daemon: fast parallel initial scan, compact in-memory filename index, live updates via fanotify
  filesystem marks (no periodic re-indexing, ~zero idle cost). Results filtered by the asking user's permissions.
- Filters: `ext:` `size:` `dm:` (date) `path:` `type:audio|video|doc|image|exe` + regex; clickable filter chips.
- History: recent searches + recently opened files, local only, one-click clear, can be disabled.
- UI: Win-key popup (apps, settings, files) + full Everything-style window with sortable columns.
- File contents search: optional, off by default (battery). KDE Baloo disabled.

## File Explorer (Dolphin, configured to behave like the classic desktop)
- Defaults: opens on a "This PC"-style page (drives + user folders), Details view with Name / Date modified /
  Type / Size, folders first, status bar, Quick access = pinned Places, breadcrumb that turns editable on click.
- Explorer shortcuts: Backspace = back, Alt+Up = up, F2 rename, Ctrl+F search, Ctrl+Shift+N new folder,
  Alt+Enter properties, Super+E opens it.
- Name in menus: "File Explorer".
- Buffs (Dolphin already has, keep visible): tabs, split view, terminal panel, batch rename, folder sizes,
  previews, per-folder view memory, group-by.
- Sorting: name (natural) / date / type / size / extension, folders first, group by; one-click presets.
- Fast search: wired to the Everything-style index (see Search), filters as chips.

## Terminal
- Linux commands underneath (zsh with autosuggestions + syntax highlighting; bash snippets from the web work).
- familiar layer: `dir cls copy move del type where ipconfig tasklist taskkill` work as aliases,
  and unknown commands get "In Fennek OS this is `x` — run it?" (command-not-found handler).
- Tabbed terminal with profiles: Fennek OS shell, PowerShell (`pwsh`, optional), CMD (via Wine).
- AI: `?? <what you want>` → suggested command shown, runs only on confirm; "explain this command".

## Process Explorer ("what runs what")
- **Grouped by app, not a flat list:** systemd already puts each app/service in its own cgroup → one row per app,
  expand for its process tree.
- **"Who started this?"** chain for every process: you clicked it / autostart / system service / timer / another app,
  with time. Plain-language names and descriptions for system processes (`kworker` → "Kernel background work").
- **Columns:** CPU, RAM, disk, network (from firewall daemon), GPU (DRM fdinfo), **battery impact** (CPU time +
  wakeups + GPU, RAPL-weighted), plus trust/sandbox status.
- **Actions:** End, **Freeze** (cgroup freezer, resumable), **Limit CPU**, Block internet, Check with VirusTotal,
  Open file location, Explain (AI).
- **History:** 24h per-app timeline → "what drained my battery overnight". Sampled from cgroup stats every 30–60s (cheap).
- **Startup tab (Autoruns, but clear):** login apps, services, timers, scheduled tasks, with impact + one-click disable.
- **Light:** reads per-cgroup stats instead of walking all of /proc; slows refresh when unfocused, stops when hidden.

## AI assistant
Off until chosen: local (llama.cpp, small model) or cloud (user's own key). Acts through OS tools
(firewall, power, settings, VirusTotal, sandbox) with a confirm button on every action.

## Build order
1. Base image: Proton integration, power tuning, classic desktop (KDE Plasma)
2. Auto-containment + VirusTotal check + snapshots
3. Firewall UI + Process Explorer (share per-app network/energy data)
4. AI assistant
5. Own Rust shell (only if Plasma limits us)

## Audience (decided 2026-10-13)
**People who want a familiar, classic desktop.** Not developers (that's Omarchy's niche: Arch + tiling). Every feature is judged
by: familiar, safe and private, long battery life, Windows programs work.

## Open source + updates (decided 2026-10-13)
- GPL-3.0; CONTRIBUTING, SECURITY (private reporting), issue + PR templates. Maintainer merges; CI must pass.
- CI builds daily (05:30 UTC) + on every push to main: verifies the signed Universal Blue base, builds, tests,
  publishes `ghcr.io/olexify/fennekos:latest` + `:YYYYMMDD`, signs with Fennek's cosign key (secrets
  COSIGN_PRIVATE_KEY / COSIGN_PASSWORD; backup in E:\Fennek-build\keys, never in the repo).
- Installed systems only accept updates signed with that key (/etc/containers/policy.json).
- 2026-10-15 repo public. Done: private vulnerability reporting, secret scanning + push protection, Dependabot
  alerts + weekly action-pin updates, ruleset "Protect main" (no force-push/deletion, PRs + `image` check
  required; repo admins bypass), image labels link the package to the repo. Package visibility must be set
  to public by hand (no API).
- Live ISO session runs SELinux permissive (enforcing=0, unlabeled live rootfs); installed systems enforce.
  To do: label the live rootfs and drop enforcing=0.
- Signed updates need a signature-enforcing origin. Never use bib `--target-imgref` (= unverified registry).
  Test VMs: `sudo bootc switch --enforce-container-sigpolicy ghcr.io/olexify/fennekos:latest` once.
  Installer (to do): Anaconda `ostreecontainer` verifies by default; never pass --no-signature-verification.
- Ceiling: our single build layer is re-downloaded on every update (~hundreds of MB). Rechunking (like
  Universal Blue) would cut daily updates to the changed parts.

## Base choice (reviewed 2026-10-11)
Fedora atomic/bootc beats Ubuntu/Debian on: current kernels (Panther Lake needs ≥6.19), atomic updates + rollback,
current Plasma, proven stack (Bazzite/Aurora). Proton is identical on any base. Gaps: countme telemetry (masked),
H.264/HEVC hardware decode disabled in Fedora mesa (battery! → RPM Fusion freeworld drivers), NVIDIA (separate
variant), rebase to new Fedora twice a year. Proposal: build FROM ublue-os kinoite-main (covers codecs + NVIDIA).

## Reference laptops (research 2026-10-11, pending decision)
- **Primary candidate:** Lenovo IdeaPad Pro 5i Gen 11 16", Panther Lake, 99.9 Wh, **no dGPU**. Measured 30h 34m
  (web loop, 150 nits, vendor OS). Linux status unverified; risks: IPU 7.5 webcam, SoundWire audio.
- **Secondary / control:** Framework Laptop 13 Pro, Panther Lake, 74 Wh, Ubuntu-certified, from $1,199 DIY.
- Fallbacks: Dell XPS 14/16 2026 (70 Wh, 1.5 W idle, Linux audio/webcam issues), ThinkPad T16 Gen 4 (86 Wh, Lunar Lake).
- Snapdragon X / X2: not usable on Linux yet (no power metrics). Revisit mid-2027.
- ARM plan (when ready): aarch64 build of the same image + FEX (x86→ARM translation, Valve-funded, in Fedora via
  Asahi) + ARM64 Proton. Same stack Valve uses on the Steam Frame; umu-launcher already ships aarch64 RPMs.
- Need kernel ≥ 6.19; pin known-good kernels per reference device. Measure s0ix ourselves (turbostat, S0ixSelftestTool).

## Build
Everything stays on E:. Source: `E:\Projects\LexOS`. Docker data: `E:\Docker\WSL` (Docker Desktop disk image location).
Big outputs: `E:\Fennek-build\` → `iso\`, `vm\`, `tmp\` (never inside the project folder).
Build with **podman** (the base has ~256 layers; docker's overlay limit is ~127), FROM the signature-verified digest:
```bash
base=$(bash verify-base.sh)          # cosign check with keys/ublue-cosign.pub → image@sha256:...
podman build --build-arg BASE_IMAGE=$base -f Containerfile -t fennek:dev .
podman run --rm -v ./test.sh:/t.sh:ro fennek:dev bash /t.sh
```
On Windows, `vm-disk.ps1` does all of this with podman inside a Docker container.
Test VM (Hyper-V). No pre-made user: the first-boot setup wizard creates the account (like a real install).
- `vm-disk.ps1` (normal PowerShell): build + test image → `E:\Fennek-build\vm\fennek-next.vhdx`
- `vm.ps1` (admin PowerShell): recreate the VM, swap in the new disk, boot.

Sandbox integration test (privileged container, downloads Proton once into volume `fennek-umu-test`):
```bash
docker run --rm -v ./tests:/src:ro -v E:/Fennek-build/tmp:/out registry.fedoraproject.org/fedora:44 bash -c "dnf -y -q install mingw64-gcc && x86_64-w64-mingw32-gcc -O2 -static -o /out/probe.exe /src/probe.c"
podman run --rm --privileged -v fennek-umu-test:/var/home -v E:/Fennek-build/tmp:/fixtures:ro -v ./tests/sandbox-test.sh:/t.sh:ro fennek:dev bash /t.sh
```

## Status
- 2026-10-11: first boot in a Hyper-V VM works (VM only, no dual boot), Secure Boot on with Hyper-V's MS UEFI CA
  template. Plasma first-run wizard runs. Real-laptop firmware, Windows coexistence and BitLocker still untested.
- Done: Fennek OS name/logo/wallpaper, classic taskbar, familiar terminal aliases, staged updates, Baloo off,
  VirusTotal right-click (hash only), hourly home snapshots (snapper, if /var/home is a subvolume),
  **auto-containment for .exe** (bwrap around Proton: private home, ~/Sandbox/<app> shared, Proton/runtime via
  throwaway overlay; verified: sandboxed probe can't read ~/secret.txt, trusted one can).
- Done: Fennek OS boot splash watermark (initramfs rebuilt with dracut) + login screen wallpaper.
- Done: ClamAV download guard (user service, inotify on Downloads, clamscan only on arrival → no resident
  daemon; threats → ~/.local/share/fennek/quarantine, chmod 000, notification). Definitions: daily + 15 min after boot.
- To do: check /var/home subvolume layout in VM; sandbox UX in a real desktop session (dialogs, sound, GPU);
  per-app network block (firewall step); quarantine restore UI.
- To do (no-telemetry promise): PRIVACY.md listing every outbound connection. Known so far: VirusTotal (hash +
  user's key, only on click), umu → repo.steampowered.com + GitHub update checks (fixed: patched umu + fennek-run-exe
  allow it at most once a day for trusted runs, never for sandboxed ones; verified with networking off), GitHub on first Proton download, Fedora update checks, ClamAV definitions (database.clamav.net, daily + after boot).

## Comfort fixes (user feedback)
- Taskbar right-click menu like the classic desktop: Search / Show Task View button / Cascade, stacked, side by side /
  Show the desktop / Task Manager / Lock the taskbar / Taskbar settings (Plasma's panel menu is edit-mode
  oriented). Needs a patch or own containment action plugin.
- Start tile right-click like the classic desktop: Unpin from Start / Resize / More → Pin to taskbar, Run as
  administrator, Open file location / Uninstall (check Tiled Menu's configurable menu first).
- "Type here to search" box + Task View button on the taskbar.
- Mouse wheel over sliders/dropdowns/spin boxes must scroll the page, not change the value (KDE default does).
  Done for QML apps (System Settings etc.): build-time patch of qqc2-desktop-style (ComboBox/SpinBox/
  DoubleSpinBox wheelEnabled false, Slider wheel passes through). To do: QtWidgets apps (Breeze, C++).
- VM-only: 1920x1080 VM screen is bigger than the host window; real hardware uses native resolution + auto scaling.

## Open questions
- Hibernation on critical battery vs Secure Boot lockdown.
- Make the reference-laptop decision (see above).
