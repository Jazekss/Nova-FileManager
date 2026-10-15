---
name: flutter-standards
description: Use for any Flutter or Dart work such as new features, screens, state management, tests and refactors.
---

- Check pubspec.yaml and the existing architecture first; extend the state management and folder pattern already used. Do not mix approaches.
- Default structure if none exists: lib/features/<feature>/{data,domain,presentation}, shared code in lib/core. Split widgets that grow past ~150 lines into their own files.
- Prefer small const widgets; extract widgets instead of helper methods that return widgets. No business logic inside build().
- Before finishing run `dart format .`, `flutter analyze` and `flutter test`; fix all analyzer warnings.
- Use Theme/ColorScheme and one design-tokens file for colours, spacing and typography. No hard-coded colours or sizes in widgets.
- Every data screen needs loading, error and empty states. Dispose controllers; check `mounted` after awaits.
- File and storage operations run off the UI thread (isolates/compute) and report progress for long jobs.
- Add packages only when needed. Check the latest compatible version on pub.dev (or via Context7) and keep pubspec tidy.
- Secrets never in source.
