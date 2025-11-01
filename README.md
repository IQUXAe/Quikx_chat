# QuikxChat

Modern Matrix messenger based on [FluffyChat](https://github.com/krille-chan/fluffychat) codebase.

## About

QuikxChat is a fork of FluffyChat with redesigned UI and additional features. Built with Flutter, it provides secure messaging through the Matrix protocol with end-to-end encryption.

## Status

**Beta** - Active development, expect bugs and breaking changes.

## Key Features

- **Security**: End-to-end encryption (E2EE) by default
- **Communication**: Text messages, voice/video calls (experimental), file sharing
- **AI Features**: Voice-to-text transcription for voice messages (optional)
- **Customization**: Custom themes, wallpapers, color schemes, font sizes
- **Translation**: Built-in message translation (beta)
- **Multi-account**: Support for multiple Matrix accounts
- **Notifications**: UnifiedPush integration for privacy-focused notifications
- **Cross-platform**: Android, Linux, Windows, Web support

## Platform Support

- ✅ Android (5.0+)
- ✅ Linux (AppImage, tar.gz)
- ✅ Windows (tested)
- ✅ [Web](https://quikxchat.vercel.app/app/)
- ❌ iOS/macOS (removed)

## Installation

### Android
Download APK from [Releases](https://github.com/IQUXAe/Quikx_chat/releases)

### Linux

**Requirements:**
- MPV player (for audio/video playback)
  ```bash
  # Ubuntu/Debian
  sudo apt install mpv
  
  # Fedora
  sudo dnf install mpv
  
  # Arch
  sudo pacman -S mpv
  ```

Download AppImage from [Releases](https://github.com/IQUXAe/Quikx_chat/releases)

```bash
chmod +x QuikxChat-x86_64.AppImage
./QuikxChat-x86_64.AppImage
```

### Windows
Download installer or portable version from [Releases](https://github.com/IQUXAe/Quikx_chat/releases)

### Web
[Here](https://quikxchat.vercel.app/app/)

## Building from Source

### Requirements
- Flutter SDK
- Android Studio (for Android)
- CMake (for Linux)
- MPV player (for Linux audio/video)

### Linux Dependencies
```bash
# Ubuntu/Debian
sudo apt install cmake ninja-build libgtk-3-dev pkg-config clang mpv

# Fedora  
sudo dnf install cmake ninja-build gtk3-devel pkgconfig clang mpv

# Arch
sudo pacman -S cmake ninja gtk3 pkgconfig clang mpv
```

### AI Features Configuration (Optional)

To enable AI-powered voice-to-text transcription:

1. Create a `.env` file in the project root:
```bash
V2T_SECRET_KEY=your_secret_key
V2T_SERVER_URL=https://your-server.com
```

2. Build with environment variables:
```bash
# The build scripts automatically load .env file
./scripts/build_apk_release.sh
./scripts/build_linux_release.sh
./scripts/build_appimage.sh
```

Or run in development:
```bash
./run_linux.sh
```

### Build Commands
```bash
# Install dependencies
flutter pub get

# Android (with AI features if .env exists)
./scripts/build_apk_release.sh

# Linux AppImage
./scripts/build_appimage.sh

# Linux tar.gz
./scripts/build_linux_release.sh

# Web
./scripts/build_web.sh
```

## Development

```bash
# Run with AI features (loads .env automatically)
./run_linux.sh

# Or run manually
flutter run -d linux
flutter run -d chrome
flutter run -d android

# Run with AI features manually
source .env
flutter run -d linux \
  --dart-define=V2T_SECRET_KEY="$V2T_SECRET_KEY" \
  --dart-define=V2T_SERVER_URL="$V2T_SERVER_URL"
```

## What's Different from FluffyChat?

### UI/UX Improvements
- Redesigned UI with Material Design 3
- Modern back button design across all pages
- Card-based settings layout
- Two-column desktop layout (chat list + content)
- Improved voice message player with smooth animations
- Better reply display with overflow handling

### New Features
- **AI-powered voice-to-text** transcription (optional)
- Voice message transcription with show/hide animation
- Improved voice message stability on Linux
- Better audio playback progress tracking

### Technical Improvements
- Performance optimizations
- Optimized HTTP client for all platforms
- Updated dependencies to latest stable versions
- Removed iOS/macOS support (focus on Android/Linux/Windows/Web)

## Credits

Based on [FluffyChat](https://github.com/krille-chan/fluffychat) by Christian Pauly

Logo design by n9ntik ([@n9ntik](https://t.me/n9ntik))

## License

AGPL-3.0 - see [LICENSE](LICENSE)

## Feedback

All feedback is welcome! Feel free to:
- Report bugs
- Suggest features
- Ask questions
- Share your experience

Open an issue on [GitHub Issues](https://github.com/IQUXAe/Quikx_chat/issues)

## Links

- [Issues](https://github.com/IQUXAe/Quikx_chat/issues)
- [Matrix Protocol](https://matrix.org)
- [UnifiedPush](https://unifiedpush.org)
