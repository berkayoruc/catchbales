#!/bin/bash

echo "🚀 Starting iOS Build..."

# Clean and get dependencies
flutter clean
flutter pub get

# Build iOS (without signing to speed up, as it will be opened in Xcode)
flutter build ios --no-codesign

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ iOS Build Successful!"
    # Open the Xcode workspace
    open ios/Runner.xcworkspace
else
    echo "❌ iOS Build Failed!"
    exit 1
fi
