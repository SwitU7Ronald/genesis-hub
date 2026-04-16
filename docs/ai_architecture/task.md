# Task List for Genesis Hub Stabilization

- [x] Verify and fix Windows platform compilation
  - [x] Add platform checks for unsupported plugins (`mobile_scanner`, `flutter_doc_scanner`) on Windows.
  - [x] Resolve any `flutter analyze` linting issues to ensure clean codebase.
- [x] Prepare Firebase Integration
  - [x] Update `main.dart` with `Firebase.initializeApp()`.
  - [x] Add graceful fallback / TODO for `firebase_options.dart` so it compiles before the user configures their project.
- [x] Refine Architecture & Desktop UI
  - [x] Update App Shell (Dashboard or Main screen) to use a responsive `NavigationRail` for Desktop vs `BottomNavigationBar` for Mobile.
  - [x] Ensure `GridView` and layouts are responsive on larger screens.
- [x] Validate stability
  - [x] Run `flutter build windows`.
