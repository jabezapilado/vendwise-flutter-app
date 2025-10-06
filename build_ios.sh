#!/bin/bash

# Vendwise iOS Build Script for iPhone 15 (iOS 18.7)

echo "🍎 Building Vendwise for iOS..."
echo "Target: iPhone 15 with iOS 18.7"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Check for any issues
echo "🔍 Running analysis..."
flutter analyze

# Build for iOS
echo "🔨 Building iOS app..."
flutter build ios --release

echo ""
echo "✅ Build completed!"
echo ""
echo "📱 To install on your iPhone 15:"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Select your iPhone 15 as the target device"
echo "3. Make sure you're signed in with your Apple ID in Xcode"
echo "4. Click the Run button (▶️) to install on your device"
echo ""
echo "🔧 If you get signing errors:"
echo "1. In Xcode, go to Runner target > Signing & Capabilities"
echo "2. Change the Bundle Identifier to something unique (e.g., com.yourname.vendwise)"
echo "3. Select your Team (your Apple ID)"
echo "4. Try running again"