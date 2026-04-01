# Genesis Project Standards

Adopted on: March 31, 2026

## 1. Environment & Dependencies
- **SDK**: Always use the latest Flutter Stable channel and Dart SDK.
- **Packages**: Only use reputable, high-performance plugins. Run `flutter pub outdated` regularly to ensure we are on the latest versions.
- **Platform Parity**: The app must compile and run flawlessly on macOS (Arm64), iOS (Physical & Simulator), Android, and Web.

## 2. Engineering Excellence
- **Static Analysis**: Maintain a clean `flutter analyze` report at all times.
- **State Management**: Use **Riverpod** for all business logic and state persistence.
- **Persistence**: Utilize `SharedPreferences` or `Hive` for local data caching to ensure a "resume-where-you-left-off" experience.
- **Type Safety**: Avoid `dynamic` types. Enforce strict null-safety and robust model definitions.

## 3. UI/UX & Aesthetics (The "Genesis Standard")
- **Typography**: Standardize on the **Outfit** font family for a premium feel.
- **Visuals**: Use modern aesthetics (Gradients, Glassmorphism, Rounded corners (R20+)).
- **Responsiveness**: Use `LayoutBuilder` and `AdaptiveScaffold` patterns to ensure the UI looks professional on both an iPhone 14 Pro and a 27-inch Mac Studio.
- **Feedback**: Every interactive element must provide clear visual haptic or visual feedback.

## 4. Deployment & Production
- **Build Checks**: Perform `flutter clean` before any production-grade distribution.
- **Signing**: Ensure Xcode signing identities are maintained for physical iOS deployment.
- **Versioning**: Follow Semantic Versioning (SemVer) for all releases.
