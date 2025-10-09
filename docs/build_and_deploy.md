# Build & Deploy Guide

_Last updated: 2025-10-10_

## 1. Android builds

### Release APK (quick sideload)
```bash
flutter build apk --release
```
Result: `build/app/outputs/flutter-apk/app-release.apk`

Install on a connected device (USB debugging enabled):
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Play Store bundle
```bash
flutter build appbundle --release
```
Result: `build/app/outputs/bundle/release/app-release.aab`
Upload `.aab` to the Play Console for internal testing or production.

## 2. iOS builds

### Build for simulator (debug)
```bash
flutter build ios --simulator
```
Result: `build/ios/iphonesimulator/Runner.app` — deploy via Xcode or `flutter run -d <simulator-id>`.

### Build for device/Ad Hoc (no codesign)
```bash
flutter build ios --release --no-codesign
```
Result: Xcode workspace at `build/ios/iphoneos/Runner.xcarchive`.
Open the generated `.xcworkspace` in Xcode, select your team, and re-run **Product → Archive** to sign with your provisioning profile.

### Install on a physical iPhone
1. Open `ios/Runner.xcworkspace` in Xcode.
2. Connect the iPhone via USB and select it from the device picker.
3. In *Signing & Capabilities*, choose your Apple developer team (personal or organizational).
4. Update the bundle identifier if required by your team.
5. Press **Run** (⌘R) to deploy or **Product → Archive** for TestFlight/App Store distribution.
6. Alternatively, once codesigning is configured, deploy straight from the terminal:
	```bash
	flutter run -d <your-device-id>
	```

Refer to `FOOLPROOF_IPA_GUIDE.md` for the step-by-step IPA packaging walkthrough.

## 3. Post-build smoke tests
- Execute scenarios from `docs/device_checklist.md` on both Android and iOS builds.
- Run `flutter test` to confirm unit/integration tests remain green.
- Upload artifacts to the chosen distribution channel (Play Console, App Store Connect, Firebase App Distribution, etc.).
