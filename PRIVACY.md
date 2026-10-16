# Privacy: every connection Fennek OS makes

Fennek OS has **no telemetry**: no usage statistics, crash uploads, install counting or tracking.
This page lists **every** network connection that Fennek OS itself makes, so you can check that claim.
Programs you install and websites you visit are separate and follow their own policies.

If you find a connection that isn't listed here, please [report it](https://github.com/Olexify/FennekOS/issues):
we treat it as a bug.

## Automatic connections

| What | Contacts | When | What is sent | How to turn it off |
|---|---|---|---|---|
| **System updates** | `ghcr.io` (GitHub) | Daily check, download when there's a new version | The update request. Nothing about you or your files. | `sudo systemctl disable --now rpm-ostreed-automatic.timer` |
| **App updates** (Flatpak) | `flathub.org` and the app's servers | Daily | The list of installed apps, to find updates | `sudo systemctl disable --now flatpak-system-update.timer`, plus `systemctl --user disable --now flatpak-user-update.timer` |
| **Everyday apps** (photos, PDF, video, music, calculator, notepad, archives) | `flathub.org` | Once, after the first start (retried until done) | Download requests for those apps | `sudo systemctl disable fennek-essential-apps.service` before connecting to the internet |
| **Virus definitions** (ClamAV) | `database.clamav.net` (Cisco) | Daily, and 15 minutes after start-up | Download request only | `sudo systemctl disable --now clamav-freshclam-once.timer` (new downloads are then no longer scanned against fresh definitions) |
| **Clock** | Fedora's time servers (NTP) | Regularly | The time request | System Settings → Date & Time |
| **Wi-Fi "is there internet?" check** | `fedoraproject.org` | When connecting to a network | A plain web request | `printf '[connectivity]\nenabled=false\n' \| sudo tee /etc/NetworkManager/conf.d/99-no-check.conf` (then restart; Wi-Fi sign-in pages are no longer detected) |

## Connections only when you use a feature

| Feature | Contacts | What is sent |
|---|---|---|
| **Check with VirusTotal** (right-click a file) | `virustotal.com` (Google) | Only the file's **SHA-256 fingerprint**, never the file, plus your own API key. Only when you click. |
| **.exe programs** (Proton/umu): first use | `github.com`, `repo.steampowered.com` | Download of Proton and its runtime (a few hundred MB), once |
| **.exe programs**: later | the same | An update check **at most once a day**, and only for programs you trusted. **Never** for sandboxed ones. |
| **Sandboxed .exe programs** | whatever the program contacts | The program's own traffic. Block it with right-click → **Firewall → Block internet access**. |

## Programs that come with Fennek OS

| Program | Notes |
|---|---|
| **Firefox** | Telemetry, "studies", Pocket and sponsored content are **switched off** system-wide (`/etc/firefox/policies/policies.json`). Firefox still makes its own browsing-related connections, for example Safe Browsing lists and extension updates, under [Mozilla's privacy notice](https://www.mozilla.org/privacy/firefox/). |

## What Fennek OS turned off

- **Fedora's "countme"**: the weekly anonymous install counting is disabled (`rpm-ostree-countme.timer`
  masked, `countme=0` in the update sources).
- **Daily package-list download** (`dnf-makecache.timer`): off. Fennek updates as whole images, so the lists were
  never used.
- **DNSSEC root-anchor refresh** (`unbound-anchor.timer`): off. Fennek's DNS doesn't use it.
- **KDE file indexing (Baloo)**: off. Fennek's own search indexes file **names** only, stays on your computer,
  and never sends anything.
- **Search history**: files you open from search are remembered **locally** to rank them first
  (`~/.local/share/fennek/search-history`). Delete that file to clear it.

## How this is enforced

The tests (`test.sh`) check that the telemetry switches stay off, and every pull request has to confirm that
nothing new contacts a server without being listed here.
