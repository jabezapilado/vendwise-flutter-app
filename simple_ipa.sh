#!/bin/bash

echo "🎯 Simple IPA Creator for VendWise (No Simulator Required)"
echo "=========================================================="

# Navigate to project
cd "/Users/jabezapilado_/Downloads/Vendwise projects/Vendwise 2/Vendwise"

echo "📱 Method 1: Using connected iPhone directly..."

# Try to build and run on connected device to get the app bundle
flutter run -d "00008120-000675A03C09A01E" --release &
FLUTTER_PID=$!

echo "⏳ Starting app on iPhone (this will create the necessary build files)..."
echo "💡 You can press Ctrl+C after you see 'Flutter run key commands' to stop"
echo "   The build files will remain and we'll use them to create the IPA"

# Wait for user to stop the process
wait $FLUTTER_PID

echo ""
echo "📦 Checking for build artifacts..."

# Check if we have build outputs
if [ -d "build/ios/iphoneos" ]; then
    echo "✅ Found iOS build directory!"
    
    # Create IPA structure
    mkdir -p build/ios/ipa/Payload
    
    # Find the .app bundle
    APP_BUNDLE=$(find build/ios/iphoneos -name "*.app" | head -1)
    
    if [ -n "$APP_BUNDLE" ]; then
        echo "📱 Found app bundle: $(basename "$APP_BUNDLE")"
        
        # Copy app to Payload
        cp -R "$APP_BUNDLE" build/ios/ipa/Payload/
        
        # Create IPA
        cd build/ios/ipa
        zip -r ../../../vendwise.ipa Payload/ > /dev/null 2>&1
        cd ../../..
        
        echo ""
        echo "🎉 SUCCESS! IPA created successfully!"
        echo "📂 Location: $(pwd)/vendwise.ipa"
        echo "📱 Size: $(du -h vendwise.ipa 2>/dev/null | cut -f1 || echo 'Unknown')"
        echo ""
        echo "📲 To install on iPhone:"
        echo "1. AirDrop vendwise.ipa to your iPhone"
        echo "2. Use AltStore, Sideloadly, or TrollStore to install"
        echo ""
        
    else
        echo "❌ No app bundle found in build directory"
    fi
    
else
    echo "❌ No build directory found. The app may not have built successfully."
    echo "💡 Try connecting your iPhone via USB and run the script again"
fi

echo ""
echo "🔧 Alternative: Manual IPA creation via Xcode"
echo "1. Open: open ios/Runner.xcworkspace"
echo "2. Select your iPhone as target device"
echo "3. Product → Archive"
echo "4. Distribute App → Ad Hoc → Export"