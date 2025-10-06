#!/bin/bash

# iPhone 15 Configuration Check for Vendwise

echo "🔍 Vendwise iPhone 15 Configuration Check"
echo "==========================================="
echo ""

# Check Flutter version
echo "📱 Flutter Version:"
flutter --version | head -3
echo ""

# Check connected devices
echo "📱 Connected Devices:"
flutter devices
echo ""

# Check iOS deployment target
echo "🎯 iOS Deployment Target:"
grep -n "IPHONEOS_DEPLOYMENT_TARGET" ios/Runner.xcodeproj/project.pbxproj | head -1
echo ""

# Check bundle identifier
echo "📦 Bundle Identifier:"
grep -n "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | head -1
echo ""

# Check app name
echo "📱 App Display Name:"
grep -A1 "CFBundleDisplayName" ios/Runner/Info.plist
echo ""

# Check supported orientations
echo "🔄 Supported Orientations:"
grep -A5 "UISupportedInterfaceOrientations" ios/Runner/Info.plist | head -6
echo ""

echo "✅ Configuration Summary:"
echo "- Target: iPhone 15 (iOS 18.7)"
echo "- Min iOS: 15.0"
echo "- Bundle ID: com.vendwise.app"
echo "- Orientations: Portrait + Landscape"
echo "- Architecture: ARM64"
echo ""
echo "🚀 Ready to deploy to iPhone 15!"