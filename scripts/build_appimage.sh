#!/bin/bash
set -e

echo "🔨 Building AppImage for QuikxChat..."

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

# Build Linux version
echo "🔍 Building Linux release..."
flutter build linux --release

# Check if build was successful
if [ ! -f "build/linux/x64/release/bundle/quikxchat" ]; then
    echo "❌ Flutter build failed or executable not found"
    exit 1
fi

# Clean and prepare AppDir
echo "📦 Preparing AppDir structure..."
rm -rf QuikxChat.AppDir/usr/bin/*
mkdir -p QuikxChat.AppDir/usr/bin
mkdir -p QuikxChat.AppDir/usr/share/applications
mkdir -p QuikxChat.AppDir/usr/share/icons/hicolor/256x256/apps

# Copy built application
echo "📋 Copying application files..."
cp -r build/linux/x64/release/bundle/* QuikxChat.AppDir/usr/bin/

# Copy desktop file and AppRun
echo "📋 Copying AppImage metadata..."
cp appimage/quikxchat.desktop QuikxChat.AppDir/
cp appimage/quikxchat.desktop QuikxChat.AppDir/usr/share/applications/
cp appimage/AppRun QuikxChat.AppDir/
chmod +x QuikxChat.AppDir/AppRun

# Copy icon if exists
if [ -f "assets/logo.png" ]; then
    echo "🎨 Copying application icon..."
    cp assets/logo.png QuikxChat.AppDir/quikxchat.png
    cp assets/logo.png QuikxChat.AppDir/usr/share/icons/hicolor/256x256/apps/quikxchat.png
else
    echo "⚠️ Warning: Application icon not found at assets/logo.png"
fi

# Make executable
chmod +x QuikxChat.AppDir/usr/bin/quikxchat

# Build AppImage
echo "🔨 Building AppImage..."
if [ -f "./appimagetool" ]; then
    ./appimagetool QuikxChat.AppDir QuikxChat-x86_64.AppImage
    echo "✅ AppImage built successfully: QuikxChat-x86_64.AppImage"
elif command -v appimagetool &> /dev/null; then
    appimagetool QuikxChat.AppDir QuikxChat-x86_64.AppImage
    echo "✅ AppImage built successfully: QuikxChat-x86_64.AppImage"
else
    echo "❌ appimagetool not found. Please install AppImageKit or download appimagetool"
    echo "You can download it from: https://github.com/AppImage/AppImageKit/releases"
    exit 1
fi

# Show file info
if [ -f "QuikxChat-x86_64.AppImage" ]; then
    echo "📊 AppImage size: $(du -h QuikxChat-x86_64.AppImage | cut -f1)"
    echo "📁 Location: $(pwd)/QuikxChat-x86_64.AppImage"
fi
