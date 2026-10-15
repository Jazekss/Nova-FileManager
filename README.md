# Nova File Manager

A fast, privacy-friendly file manager for **Android** with a companion
**Nova Transfer** desktop app for **Windows** — browse, search, vault,
and transfer files between your phone and PC over your local network.

![License](https://img.shields.io/badge/license-MIT-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Platform](https://img.shields.io/badge/Android%20%26%20Windows-3DDC84?logo=android&logoColor=white)

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20me%20a%20coffee-☕-FFDD00?logo=buymeacoffee&logoColor=black)](https://www.buymeacoffee.com/jazeks)

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

- **Pair once** — scan the QR (or enter the link manually); a fixed port
  and persisted token mean the phone reconnects automatically.
- **Two-pane window** — PC folders shared *to* the phone on the left,
  files shared *from* the phone on the right (with refresh + download).
- **Share APK via QR** — pick an `.apk`, show a QR; the phone's camera
  downloads it straight into `Download/`.
- **Optional remote thumbnails** — image/video/APK previews over the LAN
  (toggle in Settings; off by default as it slows listing).

## Security

The phone↔PC link is encrypted end-to-end on your LAN:

- The pairing token lives only inside the QR code — it never travels
  the network.
- Every request is signed with `HMAC-SHA256(token, method|path|ts)`
  (±10 min window) — replay and forgery are rejected.
- All request/response bodies are sealed with **AES-256-GCM**
  (key = `SHA-256(token)`).
- File access is confined to explicitly shared folders — path traversal
  (`../`) is rejected server-side.

## Build

```bash
# Android app
flutter pub get
flutter build apk --release --split-per-abi

# Windows companion
cd desktop/nova_transfer
flutter pub get
flutter build windows
```

Android 8+ (API 26+) • Windows 10 64-bit+ • Flutter 3.47+

## Privacy

No analytics, no tracking, no ads. Files never leave your devices except
over your own local network — encrypted.

## Author

**JKdizains** — [jkdizains.lv](https://jkdizains.lv)
If Nova saves you time: [buy me a coffee](https://www.buymeacoffee.com/jazeks) ☕
