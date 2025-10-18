# VendWise iOS Setup (Example: iPhone 15 on iOS 18.7)

## 📱 Device Compatibility
- **Recommended Test Device**: iPhone 15 (works with any modern iPhone)
- **Supported iOS Versions**: 15.0 and newer
- **Architecture**: ARM64

## 🛠️ Development Setup

### Prerequisites
1. **Xcode 15.4+** (already installed ✅)
2. **Flutter 3.35.5+** (already installed ✅)
3. **Any supported iPhone** connected via USB or Wi-Fi

### Quick Start
1. **Connect your iPhone** to your Mac
2. **Trust the computer** on your iPhone when prompted
3. **Enable Developer Mode** on your iPhone:
   - Go to Settings > Privacy & Security > Developer Mode
   - Turn on Developer Mode
   - Restart your iPhone when prompted

## 🚀 Building and Running

### Option 1: Using VS Code (Recommended)
1. Open the project in VS Code
2. Press `Cmd+Shift+P` and type "Flutter: Select Device"
3. Choose your iPhone 15 from the list
4. Press `F5` or use the "Run and Debug" panel
5. Select the matching "Debug iOS" configuration for your device

### Option 2: Using Terminal
```bash
# Run the build script
./build_ios.sh

# Or manually:
flutter devices  # Check if your iPhone is detected
flutter run -d ios  # Run on connected iOS device
```

### Option 3: Using Xcode
1. Open `ios/Runner.xcworkspace` (NOT .xcodeproj!)
2. Select your iPhone 15 as the target device
3. Click the Run button (▶️)

## 🔧 Troubleshooting

### Code Signing Issues
If you get signing errors:
1. In Xcode, select the "Runner" target
2. Go to "Signing & Capabilities" tab
3. Change Bundle Identifier to something unique:
   - Example: `com.yourname.vendwise`
4. Select your Team (your Apple ID)
5. Make sure "Automatically manage signing" is checked

### Device Not Detected
1. Make sure your iPhone is unlocked
2. Trust the computer when prompted
3. Check USB cable connection
4. Try: `flutter doctor -v` to see device status

### Build Errors
1. Clean the project: `flutter clean`
2. Get dependencies: `flutter pub get`
3. Try building again

## 📋 Project Configuration

### Current iOS Settings
- **Deployment Target**: iOS 15.0
- **Bundle ID**: com.vendwise.app
- **Supported Orientations**: Portrait, Landscape Left & Right
- **Device Family**: iPhone & iPad
- **Architecture**: ARM64 only

### Features Optimized for iPhone 15
- ✅ High refresh rate support (120Hz ProMotion)
- ✅ Dynamic Island compatible
- ✅ Full screen layout
- ✅ Modern iOS appearance
- ✅ Optimized for ARM64 architecture

## 🎯 Next Steps

1. **Test on Device**: Run the app on your iPhone 15
2. **Update Bundle ID**: Change to your unique identifier
3. **Add App Icon**: Replace default icons in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
4. **App Store**: When ready, create provisioning profiles for distribution

## 💡 Tips for iPhone 15

- The app supports both Light and Dark mode
- Optimized for the 6.1" Super Retina XDR display
- Takes advantage of the A17 Pro chip performance
- Compatible with Face ID authentication (if implemented)

---

**Need help?** Check the Flutter documentation or ask for assistance!