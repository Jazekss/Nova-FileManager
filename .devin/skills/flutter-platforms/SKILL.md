---
name: flutter-platforms
description: Use when a Flutter task touches platform-specific code, permissions, builds, emulator testing or release for Android, Windows, iOS or macOS.
---

- Keep platform code behind an abstraction (interface plus per-platform implementation).
- Before using a plugin, check on pub.dev that it supports the target platforms. If not, say so and propose an alternative.
- Android: permissions in AndroidManifest, minSdk/targetSdk in build.gradle, signing config via key.properties (never commit keystores or passwords).
- Test on the target platform with `flutter run -d <device>` (for example the Android Studio emulator). Report exactly what was run and what was not.
- iOS and macOS builds need macOS and Xcode. Never claim they were built or tested unless they actually ran; give the exact commands instead.
- Never claim a feature works on a device or emulator unless it was actually run there.
