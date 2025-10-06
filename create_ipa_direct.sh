#!/bin/bash

echo "🔨 Creating IPA file for iPhone without iOS 17.5 platform"
echo "========================================================"

cd "/Users/jabezapilado_/Downloads/Vendwise projects/Vendwise 2/Vendwise"

echo "📱 Method 1: Using available iOS SDK directly..."

# Check what iOS SDKs are actually available
echo "🔍 Available iOS SDKs:"
xcodebuild -showsdks | grep iphoneos

# Get the iOS SDK version that's installed
IOS_SDK=$(xcodebuild -showsdks | grep iphoneos | tail -1 | sed 's/.*-sdk //')
echo "📱 Using SDK: $IOS_SDK"

if [ -n "$IOS_SDK" ]; then
    echo "🔨 Building with $IOS_SDK..."
    
    # Build using the available SDK
    cd ios
    xcodebuild \
        -workspace Runner.xcworkspace \
        -scheme Runner \
        -configuration Release \
        -sdk "$IOS_SDK" \
        -archivePath "build/Runner.xcarchive" \
        archive \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_IDENTITY="" \
        PROVISIONING_PROFILE=""
    
    if [ $? -eq 0 ]; then
        echo "✅ Archive created successfully!"
        
        echo "📦 Creating IPA from archive..."
        
        # Create IPA structure
        mkdir -p build/ipa/Payload
        
        # Copy app from archive
        cp -R "build/Runner.xcarchive/Products/Applications/Runner.app" "build/ipa/Payload/"
        
        # Create IPA
        cd build/ipa
        zip -r "../../vendwise.ipa" Payload/
        cd ../..
        
        echo ""
        echo "🎉 SUCCESS! IPA file created!"
        echo "📂 Location: $(pwd)/vendwise.ipa"
        echo "📱 Size: $(du -h vendwise.ipa 2>/dev/null | cut -f1 || echo 'Unknown')"
        echo ""
        echo "📲 Transfer to iPhone:"
        echo "1. AirDrop vendwise.ipa to your iPhone"
        echo "2. Use AltStore/Sideloadly to install"
        echo "3. Or email to yourself and open on iPhone"
        
    else
        echo "❌ Archive build failed"
    fi
    
else
    echo "❌ No iOS SDK found"
    echo "💡 Alternative: Use online service like AppCenter or TestFlight"
fi

cd ..

echo ""
echo "🔧 Alternative methods if this fails:"
echo "1. Use Xcode GUI: Product → Archive → Distribute"
echo "2. Use online build services"
echo "3. Install iOS 17.5 platform in Xcode"