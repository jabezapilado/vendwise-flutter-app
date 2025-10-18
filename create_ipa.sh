#!/bin/bash

echo "🔨 Building VendWise IPA without iOS Simulator..."
echo "=================================================="

# Navigate to project directory
cd "/Users/jabezapilado_/Downloads/Vendwise projects/Vendwise 2/Vendwise"

# Clean and prepare
echo "🧹 Cleaning project..."
flutter clean > /dev/null 2>&1
flutter pub get > /dev/null 2>&1

echo "📱 Building iOS app bundle..."

# Build the iOS app for release (without code signing)
flutter build ios --release --no-codesign

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ iOS app bundle built successfully!"
    
    # Create Payload directory for IPA
    echo "📦 Creating IPA structure..."
    mkdir -p build/ios/ipa/Payload
    
    # Copy the app bundle to Payload
    cp -R build/ios/iphoneos/Runner.app build/ios/ipa/Payload/
    
    # Create the IPA file
    echo "🗜️ Creating IPA file..."
    cd build/ios/ipa
    zip -r ../../../vendwise.ipa Payload/
    cd ../../..
    
    echo ""
    echo "🎉 SUCCESS! IPA file created:"
    echo "📂 Location: $(pwd)/vendwise.ipa"
    echo "📱 Size: $(du -h vendwise.ipa | cut -f1)"
    echo ""
    echo "📲 To install on iPhone:"
    echo "1. AirDrop vendwise.ipa to your iPhone"
    echo "2. Install using AltStore, Sideloadly, or similar"
    echo "3. Or use: iOS App Installer (if available)"
    
else
    echo "❌ Build failed. Trying alternative method..."
    
    # Alternative: Build for debug mode
    echo "🔄 Trying debug build..."
    flutter build ios --debug --no-codesign
    
    if [ $? -eq 0 ]; then
        echo "✅ Debug build successful!"
        mkdir -p build/ios/ipa/Payload
        cp -R build/ios/iphoneos/Runner.app build/ios/ipa/Payload/
        cd build/ios/ipa
        zip -r ../../../vendwise-debug.ipa Payload/
        cd ../../..
    echo "🎉 Debug IPA created: vendwise-debug.ipa"
    else
        echo "❌ Both builds failed. Please check Xcode configuration."
    fi
fi