# Privacy: every connection Fennek OS makes

Fennek OS has **no telemetry**: no usage statistics, automatic crash uploads, install counting or tracking.
This page lists **every** network connection that Fennek OS itself makes, your local network included, so you can check
that claim. Where a part made by someone else sends an ID that could tell your computer apart, its row says so.
Programs you install and websites you visit are separate and follow their own policies.

If you find a connection that isn't listed here, please [report it](https://github.com/Olexify/FennekOS/issues):
we treat it as a bug.

## Automatic connections

| What | Contacts | When | What is sent | How to turn it off |
|---|---|---|---|---|
| **System updates** | `ghcr.io` and `pkg-containers.githubusercontent.com` (GitHub) | About once a day, or at the time you set; downloads when there's a new version. Waits on metered connections. | The update request. Nothing about you or your files. | Settings → Update & Recovery → Updates → **Download updates by themselves** |
| **App updates** (Flatpak) | `dl.flathub.org` and, for a few apps, their maker's servers | Daily, and a few minutes after start-up. Waits on metered connections. | A request for Flathub's list of current versions, then a download request for each app with a new version. | Settings → Update & Recovery → Updates → **Store apps** |
| **Store's update check** | `dl.flathub.org` | 20 seconds after you sign in, and after waking from sleep if the last check is over a day old | The same request for the list of current versions | `mkdir -p ~/.config/autostart; printf '[Desktop Entry]\nHidden=true\n' > ~/.config/autostart/org.kde.discover.notifier.desktop` |
| **Everyday apps** (photos, PDF, video, music, calculator, notepad, archives, paint, scanning, camera, alarms & clock) | `dl.flathub.org` | Once, after the first start (retried until done) | Download requests for those apps | `sudo systemctl disable fennek-essential-apps.service` before connecting to the internet |
| **Virus definitions** (ClamAV) | `database.clamav.net` (Cisco) | Daily, and 15 minutes after start-up | Download request, with ClamAV's version, the system type and a random ID ClamAV made for this computer. Nothing about you or your files. | `sudo systemctl disable --now clamav-freshclam-once.timer` (new downloads are then no longer scanned against fresh definitions) |
| **Clock** | `2.fedora.pool.ntp.org` (NTP), and any time server your network names | Regularly | The time request | Settings → Time & Language → Date & time |
| **"Is there internet?" check** | `fedoraproject.org` | When connecting to a network, then every 5 minutes | A plain, unencrypted web request | `printf '[connectivity]\nenabled=false\n' \| sudo tee /etc/NetworkManager/conf.d/99-no-check.conf` (then restart; Wi-Fi sign-in pages are no longer detected) |
| **Currency rates** (for conversions in search) | `www.ecb.europa.eu` (European Central Bank) | The first time you search after signing in (Start, the taskbar, Alt+F2), then once a day; never twice within 24 hours | Download request only. Nothing you type. | Settings → Apps → Search → **Unit Converter** (conversions in search stop too) |
| **Joining a network** | Your router and the name servers your network names | When connecting, and each time something looks up a name | This computer's name to the router, and the names being looked up to the name servers. Each Wi-Fi network sees its own made-up hardware address. | Part of using any network |

## Automatic, on your local network only

These stay on your own network. They also happen on public Wi-Fi: the firewall's public profile closes incoming
connections, not these.

| What | Contacts | When | What is sent | How to turn it off |
|---|---|---|---|---|
| **Device discovery** (Avahi) | Your local network | All the time while connected | This computer's name and network addresses. Apps use it to find printers and phones. | `sudo systemctl disable --now avahi-daemon.service avahi-daemon.socket` (printers and phones are no longer found by themselves) |
| **Phone link** (KDE Connect) | Your local network | At sign-in and whenever the network changes | This computer's name and type, a random ID for KDE Connect, and a list of what it can do | Start → Phone → Settings → untick **LAN** |

## Connections only when you use a feature

| Feature | Contacts | What is sent |
|---|---|---|
| **Updates page** (check now, Show earlier versions, install an earlier version or the other edition) | `ghcr.io` and `pkg-containers.githubusercontent.com` (GitHub) | The update request, the request for the list of versions, and download requests for the build you pick. Only builds signed with Fennek's key install. |
| **Store** (when you open it) | `dl.flathub.org` (apps), `odrs.gnome.org` (ratings and reviews), `cdn.fwupd.org` (firmware), `autoconfig.kde.org` and `api.kde-look.org` (add-ons) | Download requests for those lists; the firmware one says your system type, kernel version and language. Opening an app's page sends `odrs.gnome.org` the app and its version, your language and system name, and a code that stays the same, made from your account name and this computer's ID (so your own reviews can be told apart). Searching among add-ons sends the words to `api.kde-look.org`. A new firmware list is also announced on your local network for other computers to share (Passim; `sudo systemctl mask passim.service` stops that). None of this runs in the background: the firmware list's own timer (`fwupd-refresh.timer`) stays off. |
| **"Get New" buttons** (themes, icons, wallpapers and other add-ons in Settings) | `autoconfig.kde.org`, `api.kde-look.org` and its download servers | What you search for, and download requests |
| **Your location** (the Day & Night look, Night light's sunset to sunrise setting, a wallpaper that changes at sunset, apps you allow) | `api.beacondb.net` | The Wi-Fi networks around you (hardware addresses and signal strength) and, with a mobile modem, the cell tower, to work out roughly where you are. A notice asks first. Night light's tile in the action center doesn't use it. |
| **Word definitions** (typing `define` and a word in search) | `dict.org` | That word, unencrypted. Settings → Apps → Search → **Dictionary** turns it off. |
| **Crash window** (if you open it after an app crashes) | `bugs.kde.org`, `autoconfig.kde.org`, `crash-reports.kde.org` (KDE) | Opening it looks the app up at KDE. Nothing about the crash is sent until you click **Send Automatic Report**: then where the app failed, versions and basic system details. **Automatically report crashes** starts off. |
| **Push messages for apps** (only if you install an app that asks for them) | `unifiedpush.kde.org` (KDE) | The service sits idle and connects nowhere until such an app signs up; then it keeps a connection open for that app's messages. |
| **KDE's usage statistics** (optional, in Files' settings and KDE's User Feedback page) | `telemetry.kde.org` | Nothing: they stay off unless you switch them on. |
| **Share menu, Online accounts** | The service you pick | What you choose to share, and your sign-in there |
| **Your local network**: Network in Files, adding a printer, scanning, Desktop Sharing, sharing a folder | Your local network | The first three look for what's on the network. Desktop Sharing and a shared folder announce this computer while they're on; the folder-sharing services (`smb`, `nmb`) stay off until then. |
| **Check with VirusTotal** (right-click a file) | `virustotal.com` (Google) | Only the file's **SHA-256 fingerprint**, never the file, plus your own API key. Only when you click. |
| **.exe programs** (Proton/umu): first use | `api.github.com`, `github.com`, `repo.steampowered.com` | Download of Proton and its runtime (a few hundred MB), once |
| **.exe programs**: later | the same | An update check **at most once a day**, and only for programs you trusted. **Never** for sandboxed ones. |
| **Sandboxed .exe programs** | whatever the program contacts | The program's own traffic. Block it with right-click → **Firewall → Block internet access**. |
| **Extra wallpapers and theme pictures** (Personalize, Fennek Live) | `raw.githubusercontent.com` (GitHub) | Small previews of the extra wallpapers (about 120 KB in all) the first time you open Personalize, and the picture you pick, once. Both are checked against fingerprints built into Fennek OS. An account that was already using one of these pictures fetches it by itself at sign-in. |
| **Get-it apps** (LibreOffice, MPV Player, Thunderbird, GPU Screen Recorder; NVIDIA edition: NV Broadcast) | `dl.flathub.org`; for MPV's setup and NV Broadcast `codeload.github.com`; for NV Broadcast's libraries `pypi.org` / `files.pythonhosted.org` | Download requests for that app, once, when you click it. MPV's setup and NV Broadcast are checked against built-in fingerprints. NV Broadcast, once installed, downloads its AI models the first time an effect is used (from `github.com`, `raw.githubusercontent.com` and Google's `storage.googleapis.com`); its own update check starts switched off. Extras you pick inside it come from `pypi.org`, `pypi.nvidia.com` and `huggingface.co`. The Leonote entry only opens its website. |
| **Start tile pictures** (editing the tile of a Steam or Lutris game) | `steamcdn-a.akamaihd.net`, `lutris.net` | A request for that game's pictures |
| **Widgets you add yourself** (Weather, Picture of the Day) | The service each one names | The place you set, or a request for the day's picture |

## Programs that come with Fennek OS

| Program | Notes |
|---|---|
| **Firefox** | Telemetry, "studies", Pocket and sponsored content are **switched off** system-wide (`/etc/firefox/policies/policies.json`). Firefox still makes its own browsing-related connections, for example Safe Browsing lists and extension updates, under [Mozilla's privacy notice](https://www.mozilla.org/privacy/firefox/). On first start it installs three add-ons from addons.mozilla.org (uBlock Origin and Privacy Badger, which block trackers, and Kitsumi); each can be switched off in Firefox's add-ons page, and they update through Mozilla like any add-on. |
| **GPU Control** (NVIDIA edition) | Makes no connections, unless you set up its metrics export yourself. |

## What Fennek OS turned off

- **Fedora's "countme"**: the weekly anonymous install counting is disabled (`rpm-ostree-countme.timer`
  masked, `countme=0` in the update sources).
- **Daily package-list download** (`dnf-makecache.timer`): off. Fennek updates as whole images, so the lists were
  never used.
- **DNSSEC root-anchor refresh** (`unbound-anchor.timer`): off. Fennek's DNS doesn't use it.
- **KDE file indexing (Baloo)**: off. Fennek's own search indexes file **names** only, stays on your computer,
  and never sends anything.
- **Clipboard history**: stays on your computer and is gone when you sign out, with pictures you copied in between.
- **Search history**: files you open from search are remembered **locally** to rank them first
  (`~/.local/share/fennek/search-history`). Delete that file to clear it.

## How this is enforced

The tests (`test.sh`) check that the telemetry switches stay off, and every pull request has to confirm that
nothing new contacts a server without being listed here.
