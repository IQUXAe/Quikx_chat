#!/bin/bash

set -e

echo "🚀 Building Android APKs..."

# Load .env variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Get version from pubspec.yaml
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')

# Build split APKs
echo "📦 Building split APKs..."
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols --split-per-abi \
  --dart-define=V2T_SECRET_KEY="$V2T_SECRET_KEY" \
  --dart-define=V2T_SERVER_URL="$V2T_SERVER_URL"

# Build universal APK
echo "📦 Building universal APK..."
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols \
  --dart-define=V2T_SECRET_KEY="$V2T_SECRET_KEY" \
  --dart-define=V2T_SERVER_URL="$V2T_SERVER_URL"

# Rename APK files
cd build/app/outputs/flutter-apk/

echo "✏️  Renaming APK files..."

# Rename split APKs
[ -f "app-armeabi-v7a-release.apk" ] && mv app-armeabi-v7a-release.apk QuikxChat-${VERSION}-armeabi-v7a.apk
[ -f "app-arm64-v8a-release.apk" ] && mv app-arm64-v8a-release.apk QuikxChat-${VERSION}-arm64-v8a.apk
[ -f "app-x86_64-release.apk" ] && mv app-x86_64-release.apk QuikxChat-${VERSION}-x86_64.apk

# Rename universal APK
[ -f "app-release.apk" ] && mv app-release.apk QuikxChat-${VERSION}-universal.apk

echo ""
echo "✅ Build complete! APKs:"
ls -lh QuikxChat-*.apk

cd ../../../../
