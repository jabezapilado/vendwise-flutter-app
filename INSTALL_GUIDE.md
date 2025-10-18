## 📱 How to Install VendWise on Your iPhone 15

### 🎯 **Quick Install Guide:**

#### **Option 1: Direct Install (Recommended)**
```bash
# Make sure your iPhone is connected and trusted
flutter devices  # Verify your iPhone appears
flutter install -d "00008120-000675A03C09A01E"
```

#### **Option 2: Using Xcode**
1. **Open Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **In Xcode:**
   - Select your iPhone 15 from the device dropdown
   - Click the ▶️ Run button
   - The app will build and install automatically

#### **Option 3: Build & Install via Xcode**
1. **Build the project:**
   ```bash
   flutter build ios
   ```

2. **Open in Xcode:**
   - Open `ios/Runner.xcworkspace`
   - Select "Any iOS Device (arm64)" or your iPhone
   - Go to Product → Archive
   - Choose "Distribute App" → "Development"
   - Install via Xcode Organizer

### 🔧 **If You Get Code Signing Errors:**

1. **Change Bundle Identifier:**
   - In Xcode: Runner target → Signing & Capabilities
   - Change Bundle Identifier to: `com.yourname.vendwise`
   - Make sure your Apple ID is selected as Team

2. **Enable Developer Mode on iPhone:**
   - Settings → Privacy & Security → Developer Mode → ON
   - Restart iPhone when prompted

### 📦 **Alternative: TestFlight (For Beta Testing)**
1. Upload to App Store Connect
2. Add yourself as a tester
3. Install via TestFlight app
4. Share with others easily

### ⚡ **Quick Commands:**
```bash
# Check if iPhone is connected
flutter devices

# Run directly on iPhone
flutter run -d "00008120-000675A03C09A01E"

# Build for iOS
flutter build ios --release

# Open in Xcode
open ios/Runner.xcworkspace
```

### 🚨 **Why AirDrop Doesn't Work:**
- iOS apps must be code-signed for security
- Apps need to be installed through Apple's verified methods
- Direct file transfer bypasses Apple's security model

### ✅ **Easiest Method Summary:**
1. Connect iPhone to Mac (USB or WiFi)
2. Run: `flutter run -d [device-id]`
3. App installs and launches automatically!