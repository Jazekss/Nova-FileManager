# Nova File Manager

A fast, privacy-friendly file manager for **Android** with a companion
**Nova Transfer** desktop app for **Windows** — browse, search, vault,
and transfer files between your phone and PC over your local network.

![License](https://img.shields.io/badge/license-MIT-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Platform](https://img.shields.io/badge/Android%20%26%20Windows-3DDC84?logo=android&logoColor=white)

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20me%20a%20coffee-☕-FFDD00?logo=buymeacoffee&logoColor=black)](https://www.buymeacoffee.com/jazeks)

## Download

Get the latest Android APK and the Windows installer from
[**Releases**](https://github.com/Jazekss/Nova-FileManager/releases/latest).

- `NovaFileManager_…_android-arm64.apk` — almost every modern phone
- `NovaFileManager_…_android-armv7.apk` — older 32-bit phones
- `NovaTransfer_…_windows-setup.exe` — Windows 10/11 companion (also
  allows Nova Transfer through Windows Firewall)

## Features

### Nova File Manager (Android)

- **Storage dashboard** — used/free space for internal storage and SD card,
  plus quick stats at a glance.
- **Two storage volumes** — browse internal storage and SD card, switch
  via a dropdown (also exposes Vault and PC share when connected).
- **Three view modes** — detailed list (name, size, date+time), medium
  and large icon grids with real thumbnails: images, video first-frames
  (with a play badge) and the actual icon packaged inside `.apk` files.
- **File operations** — copy, move, rename, delete, multi-select,
  new folder — between folders and across storage volumes.
- **Recycle bin** — app-owned bin with metadata, restore and permanent
  delete, bin size on the Home page.
- **Vault** — PIN + biometric locked, AES-256-GCM encrypted `.nvx`
  items (Android Keystore); whole folders are zipped first.
- **Archives** — create ZIP; read ZIP / 7z / RAR.
- **Image viewer** — gallery navigation, overflow + long-press actions
  (move, copy, rename, Vault, convert, delete, share), PNG/JPG/WebP
  conversion.
- **Media** — built-in audio and video players, APK icon extraction,
  open-with via Android FileProvider.
- **Search** — filename text or Windows-style wildcards (`*.pdf`),
  storage/folder filters, a single date-range picker, smart skipping of
  system folders (`Android/data`, `lost+found`, trash dirs).
- **9 languages** — English, Latviešu, Lietuvių, Eesti, Norsk, Svenska,
  Polski, Deutsch, Русский — plus light/dark/system themes and KB/MB units.

### Nova Transfer (Windows companion)

- **Pair once** — scan the QR, or type the PC address + one-time code
  on the phone. After that the link heals itself: open Nova on the PC
  and on the phone and they find each other again (heartbeat, backup
  addresses, encrypted LAN discovery) — also after restarts, Wi-Fi drops
  or a new IP address.
- **My phone + other devices** — the header shows *My phone* and *Other
  devices*; every extra phone or PC gets its own renameable tab.
- **Per-folder sharing** — when adding a PC folder choose *Only my
  phone*, *All paired devices* or picked devices.
- **Firewall check** — detects when Windows Firewall blocks the phone
  and fixes it with one click.
- **Two-pane window** — PC folders shared *to* the phone on the left,
  files shared *from* the phone on the right (with refresh + download).
- **Share APK via QR** — pick an `.apk`, show a QR; the phone's camera
  downloads it straight into `Download/`.
- **Optional remote thumbnails** — image/video/APK previews over the LAN
  (toggle in Settings; off by default as it slows listing).

### Other devices (phones ↔ phones ↔ PCs)

Link any number of your own (or a friend's) phones and computers to move
files fast over Wi-Fi:

- Pair by scanning the other device's QR, or by typing its address and
  one-time code. Phone ↔ phone works the same way.
- Every device has a name; rename paired devices so you know who is who.
- Share folders/files with **all** paired devices or only **specific**
  ones; browse, download and upload in their shared folders.
- Paired devices are remembered and reconnect while Nova is open on both
  sides. Closing Nova ends the connection; reopening restores it.

## Security

All links are encrypted end-to-end on your LAN (shared code:
[`packages/nova_link`](packages/nova_link)):

- **Pairing** — X25519 key exchange authenticated with a single-use
  60-bit code (from the QR or typed). A passive listener never sees the
  key; an active attacker gets one online guess per attempt, attempts
  are capped and the code changes after every use. Each pair of devices
  gets its own 256-bit key that never travels the network.
- **Requests** — signed with `HMAC-SHA256` over method, path, query and
  timestamp with a per-request nonce; replays and forgeries are refused.
  Clock differences between devices are corrected automatically.
- **Data** — every request and response body is sealed with
  **AES-256-GCM**.
- **Access** — a device only sees folders shared with it. Paths are
  normalised and symlinks/junctions resolved, so `..` tricks can't
  escape a shared folder. Other devices can't delete or rename anything.
- **Discovery** — LAN broadcasts carry only HMAC tags, never device ids
  or keys.

## Build

```bash
# Android app
flutter pub get
flutter build apk --release --split-per-abi

# Windows companion
cd desktop/nova_transfer
flutter pub get
flutter build windows
ISCC installer.iss   # Inno Setup 6 → BUILDS/

# Tests
cd packages/nova_link && dart test
```

Android 8+ (API 26+) • Windows 10 64-bit+ • Flutter 3.47+

## Privacy

No analytics, no tracking, no ads. Files never leave your devices except
over your own local network — encrypted.

## Author

**JKdizains** — [jkdizains.lv](https://jkdizains.lv)
If Nova saves you time: [buy me a coffee](https://www.buymeacoffee.com/jazeks) ☕
