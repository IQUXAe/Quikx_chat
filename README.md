# QuikxChat

Modern Matrix messenger based on FluffyChat codebase.

## About

QuikxChat is a fork of FluffyChat with redesigned UI and additional features. Built with Flutter, it provides secure messaging through the Matrix protocol with end-to-end encryption.

## Status

**Beta** - Active development, expect bugs and breaking changes.

## Key Features

- **Security**: End-to-end encryption (E2EE) by default
- **Communication**: Text messages, voice/video calls (experimental), file sharing
- **Customization**: Custom themes, wallpapers, color schemes, font sizes
- **Translation**: Built-in message translation (beta)
- **Multi-account**: Support for multiple Matrix accounts
- **Notifications**: UnifiedPush integration for privacy-focused notifications
- **Cross-platform**: Android, Linux, Web support

## Platform Support

- ✅ Android (5.0+)
- ✅ Linux (AppImage)
- ✅ Web (not deployed yet)
- ❌ iOS/macOS (removed, soon maybe)
- ✅ Windows (not tested yet)

## Installation

### Android
Download APK from [Releases](https://github.com/IQUXAe/Quikx_chat/releases)

### Linux
Download AppImage from [Releases](https://github.com/IQUXAe/Quikx_chat/releases)

```bash
chmod +x QuikxChat-x86_64.AppImage
./QuikxChat-x86_64.AppImage
```

### Web
Not deployed yet

### Windows
Not build yet

## Building from Source

### Requirements
- Flutter SDK
- Android Studio (for Android)
- CMake (for Linux)

### Build Commands
```bash
# Install dependencies
flutter pub get

# Android
./build_apk_release.sh

# Linux
./build_appimage.sh

# Web
./build_web.sh
```

## Development

```bash
# Run in debug mode
flutter run

# Run on specific platform
flutter run -d linux
flutter run -d chrome
flutter run -d android
```

## What's Different from FluffyChat?

- Redesigned UI with Material Design 3
- Improved settings layout with card-based design
- Performance optimizations
- Removed iOS/macOS support (focus on Android/Linux/Windows/Web)

## Credits

Based on [FluffyChat](https://github.com/krille-chan/fluffychat) by Christian Pauly

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
