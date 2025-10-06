# 📱 AirDrop Installation Guide for Vendwise iOS App

## 🎯 **Method 1: IPA File + AltStore (Recommended)**

### **Step 1: Install AltStore on your iPhone**
1. Go to [altstore.io](https://altstore.io) on your computer
2. Download AltServer for Mac
3. Install AltStore on your iPhone via iTunes/Finder
4. Sign in with your Apple ID in AltStore

### **Step 2: Transfer & Install**
1. **AirDrop the IPA file** from Mac to iPhone
2. **Open the IPA** with AltStore
3. **Enter your Apple ID** when prompted
4. **App installs** and appears on home screen!

---

## 🍎 **Method 2: TestFlight (Official Apple)**

### **For Personal Use:**
1. **Upload to App Store Connect:**
   ```bash
   flutter build ipa --export-method=app-store
   xcrun altool --upload-app --type ios --file "build/ios/ipa/vendwise.ipa" --username "your-apple-id" --password "app-specific-password"
   ```

2. **Add yourself as tester** in App Store Connect
3. **Install TestFlight** from App Store
4. **Install your app** via TestFlight

### **For Sharing with Others:**
1. Add their email as external testers
2. They get invitation email
3. Install via TestFlight app

---

## ⚡ **Method 3: Enterprise/Ad-Hoc Distribution**

### **If you have Apple Developer Account ($99/year):**
1. **Create provisioning profile** for your device
2. **Build with ad-hoc method:**
   ```bash
   flutter build ipa --export-method=ad-hoc
   ```
3. **AirDrop IPA** to iPhone
4. **Install directly** by tapping the file

---

## 🔧 **Method 4: Sideloading (Free)**

### **Using Sideloadly:**
1. Download [Sideloadly](https://sideloadly.io)
2. Connect iPhone to Mac
3. Drag IPA file into Sideloadly
4. Enter Apple ID credentials
5. App installs automatically

### **Using Xcode (Free Developer Account):**
1. Open `ios/Runner.xcworkspace`
2. Connect iPhone via USB
3. Select iPhone as target
4. Click Run ▶️
5. App installs for 7 days (free account limit)

---

## 📂 **File Locations After Build:**

- **IPA File:** `build/ios/ipa/vendwise.ipa`
- **Archive:** `build/ios/archive/Runner.xcarchive`

## 🚨 **Important Notes:**

### **Free Apple ID Limitations:**
- Apps expire after **7 days**
- Must re-install weekly
- Limited to **3 apps** at once

### **Paid Developer Account Benefits:**
- Apps valid for **1 year**
- Unlimited apps
- Can distribute to others

### **AirDrop Requirements:**
- Both devices have Bluetooth/WiFi enabled
- Devices are near each other
- AirDrop set to "Everyone" or "Contacts Only"

---

## ✅ **Recommended Flow:**

1. **For personal use:** AltStore method
2. **For testing with others:** TestFlight
3. **For quick testing:** Direct Xcode install
4. **For distribution:** Enterprise/Ad-Hoc with Apple Developer Account

The IPA file will be ready shortly! 🎉