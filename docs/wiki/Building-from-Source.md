# Building QuikxChat from Source

Complete guide for building QuikxChat on different platforms.

## Prerequisites

### All Platforms
- **Flutter SDK** (latest stable)
  ```bash
  flutter --version
  ```
- **Git**
  ```bash
  git --version
  ```

### Android
- **Android Studio** or **Android SDK Command-line Tools**
- **Java JDK 17+**
- **Android SDK** (API 21+)

### Linux
- **CMake**
- **Ninja build**
- **GTK 3.0 development libraries**
  ```bash
  # Ubuntu/Debian
  sudo apt install cmake ninja-build libgtk-3-dev pkg-config clang
  
  # Fedora
  sudo dnf install cmake ninja-build gtk3-devel pkgconfig clang
  
  # Arch
  sudo pacman -S cmake ninja gtk3 pkgconfig clang
  ```

### Windows
- **Visual Studio** (latest, with C++ desktop development)
- **CMake** (included with VS)

---

## Clone Repository

```bash
git clone https://github.com/IQUXAe/Quikx_chat.git
cd Quikx_chat
```

---

## Install Dependencies

```bash
flutter pub get
```

---

## Building

### Android

#### Debug Build
```bash
flutter run -d android
```

#### Release APK (Split by ABI)
```bash
./scripts/build_apk_release.sh
```

Or manually:
```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols --split-per-abi
```

Output: `build/app/outputs/flutter-apk/`

#### Release APK (Universal)
```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

#### Signing APK

1. Create keystore:
```bash
keytool -genkey -v -keystore ~/quikxchat.jks -keyalg RSA -keysize 2048 -validity 10000 -alias quikxchat
```

2. Create `android/key.properties`:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=quikxchat
storeFile=/path/to/quikxchat.jks
```

3. Build signed APK:
```bash
./scripts/build_apk_release.sh
```

---

### Linux

#### Debug Build
```bash
flutter run -d linux
```

#### Release Build (tar.gz)
```bash
./scripts/build_linux_release.sh
```

Or manually:
```bash
flutter build linux --release
cd build/linux/x64/release/bundle
tar -czf QuikxChat-linux-x64.tar.gz *
```

#### AppImage
```bash
./scripts/build_appimage.sh
```

Requirements:
- `appimagetool` in project root
- Download from: https://github.com/AppImage/AppImageKit/releases

---

### Web

```bash
./scripts/build_web.sh
```

Or manually:
```bash
flutter build web --release --web-renderer canvaskit
```

Output: `build/web/`

Deploy to any static hosting (Vercel, Netlify, GitHub Pages, etc.)

---

### Windows

#### Debug Build
```bash
flutter run -d windows
```

#### Release Build
```bash
flutter build windows --release
```

Output: `build/windows/x64/runner/Release/`

---

## Troubleshooting

### "Invalid depfile" Error
```bash
flutter clean
flutter pub get
```

### Android Build Fails
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Linux Build Fails
Check GTK dependencies:
```bash
pkg-config --modversion gtk+-3.0
```

### Out of Memory (Android)
Edit `android/gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx4096m
```

---

## Build Outputs

| Platform | Location | File |
|----------|----------|------|
| Android | `build/app/outputs/flutter-apk/` | `QuikxChat-{version}-{abi}.apk` |
| Linux | Project root | `QuikxChat-{version}-linux-x64.tar.gz` |
| Linux | Project root | `QuikxChat-x86_64.AppImage` |
| Web | `build/web/` | Static files |
| Windows | `build/windows/x64/runner/Release/` | Executable + DLLs |

---

## Development Tips

### Hot Reload
```bash
flutter run
# Press 'r' for hot reload
# Press 'R' for hot restart
```

### Debug on Real Device
```bash
# Android
adb devices
flutter run -d <device-id>

# Linux
flutter run -d linux
```

### Check for Issues
```bash
flutter doctor -v
flutter analyze
```

### Update Dependencies
```bash
flutter pub upgrade
```

---

## Next Steps

- [Push Notifications Setup](Push-Notifications.md)
- [Translation Configuration](Translation-Setup.md)
- [Contributing Guidelines](../../CONTRIBUTING.md)
