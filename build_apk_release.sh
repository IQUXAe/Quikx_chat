#!/bin/bash
set -e

echo "🔒 Building obfuscated release..."

# Check Flutter availability
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Make sure Flutter is installed and added to PATH"
    exit 1
fi

# Check Flutter version
echo "📋 Flutter version: $(flutter --version | head -n 1)"

# Clean up
flutter clean || { echo "❌ Error during cleanup"; exit 1; }
flutter pub get || { echo "❌ Error getting dependencies"; exit 1; }

# Flutter obfuscation build
flutter build apk --release --obfuscate --split-debug-info=build/debug-info || { echo "❌ Build error"; exit 1; }

# Find APK path efficiently
APK_PATH=$(find build/app/outputs/flutter-apk -name "*.apk" -type f 2>/dev/null | head -n 1)
if [ -n "$APK_PATH" ]; then
    echo "✅ Release built: $APK_PATH"
else
    echo "✅ Release built in build/ directory"
fi
echo "Done"