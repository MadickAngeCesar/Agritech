# Agritech

Agritech is a Flutter-based mobile application for agriculture-focused services and features. It includes modules for product marketplace, educational resources (ebooks, webinars), plant/disease detection, weather information, user profiles, admin management, and more. The app targets Android (mobile) and is organized with clear separation between `lib/` screens, models, services, and utilities.

This README explains how to set up the development environment on Windows, run the app, and produce an Android APK (signed or unsigned).

## Table of Contents

- Project overview
- Prerequisites
- Quick setup (dev machine)
- Running on a device or emulator
- Building an APK (debug & release)
- Signing (release) and recommended workflow
- Project structure (high level)
- Troubleshooting
- Contributing

## Project overview

Key features implemented in this repository (high level):

- Marketplace for agricultural products
- Educational library and ebooks
- Plant/disease detection and image capture
- Webinars and video resources
- User profiles, orders and cart functionality
- Admin screens for product/user/order management

See the `lib/` folder for the app code. Major folders include `screens/`, `models/`, `services/`, and `utils/`.

## Prerequisites

Before building or running the app, make sure you have the following installed on your Windows machine:

- Flutter SDK (stable channel) — https://docs.flutter.dev/get-started/install/windows
- Android SDK (via Android Studio) and Android platform tools
- Java JDK 11+ (OpenJDK is fine)
- Android Studio (recommended) for SDK/AVD management
- (Optional) A physical Android device with USB debugging enabled

Also make sure these environment variables are set (typical defaults):

- `PATH` contains the Flutter `bin` directory
- `ANDROID_HOME` or `ANDROID_SDK_ROOT` points to your Android SDK installation

Verify your environment with:

```powershell
flutter doctor
```

Fix any issues that `flutter doctor` reports before proceeding.

## Quick setup (development machine)

1. Clone the repository (if you haven't already):

```powershell
git clone <repo-url> Agritech
cd Agritech
```

2. Fetch dependencies:

```powershell
flutter pub get
```

3. (Optional) Open the project in Android Studio or VS Code to help with emulators and device management.

## Running on an emulator or device

1. Start an Android emulator (via Android Studio AVD Manager) or plug in a physical device and enable USB debugging.
2. Confirm device is visible:

```powershell
flutter devices
```

3. Run the app (debug build) on the selected device:

```powershell
flutter run
```

This runs the app in debug mode and connects the Dart VM with hot reload.

## Building an APK

There are two common APK build modes: debug (unsigned, for quick tests) and release (optimized). The commands below show the standard Flutter approach.

### Build debug APK (quick)

```powershell
flutter build apk --debug
# or run with target platform split
# flutter build apk --debug --target-platform android-arm,android-arm64,android-x64
```

The debug APK is not optimized and is unsigned. It is useful for quick device testing.

### Build release APK (recommended for distributing/testing)

1. (Optional but recommended) Configure app signing (see next section). If you do not sign the APK, Android will still allow installing on devices but Play Store requires signing.

2. Run:

```powershell
flutter build apk --release
```

By default, a release APK will be created at:

```
build\app\outputs\flutter-apk\app-release.apk
```

If you need an Android App Bundle for Play Store upload, build:

```powershell
flutter build appbundle --release
```

The bundle will be located under `build\app\outputs\bundle`.

## Signing the release APK (recommended for Play Store)

For Play Store and distribution you must sign the APK/bundle. The typical approach uses a keystore and stores credentials in `android/key.properties` (or environment variables). The steps below are a minimal guideline — adapt to your team's security practices.

1. Create a keystore (one-time):

```powershell
keytool -genkey -v -keystore C:\path\to\keystore.jks -alias your_key_alias -keyalg RSA -keysize 2048 -validity 10000
```

2. Create a `key.properties` file in the `android/` directory with contents similar to:

```
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=your_key_alias
storeFile=C:\path\to\keystore.jks
```

3. Configure `android/app/build.gradle` (or `build.gradle.kts`) to read `key.properties` and set the signing config. Many Flutter templates already include example code — adapt it to the Kotlin DSL if using `.kts` files.

4. Build the signed release:

```powershell
flutter clean; flutter pub get; flutter build apk --release
```

After signing, the resulting signed APK will be ready to distribute or sideload.

Note: Never commit keystores or passwords to source control. Use CI secrets or local environment variables.

## Project structure (high level)

- `lib/` — application source code
	- `main.dart` — app entry point
	- `screens/` — UI screens organized by feature
	- `models/` — domain models (product, order, user, etc.)
	- `services/` — API and provider services
	- `utils/` — shared utilities and constants
- `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` — platform projects

Look inside `lib/` to find feature folders such as `ebooks`, `market place`, `plant detection`, and `Admin` screens.

## Troubleshooting

- If `flutter doctor` reports missing Android SDK or licenses:

```powershell
flutter doctor --android-licenses
```

- If builds fail with Gradle or Java errors, make sure `JAVA_HOME` points to a compatible JDK and your Android SDK tools are installed.
- If you see dependency or package errors, run:

```powershell
flutter clean; flutter pub get
```

- For runtime crashes, run the app in debug with `flutter run` and inspect logs. Use `flutter logs` to stream device logs.

## Contributing

1. Open an issue describing the bug or enhancement.
2. Create a feature branch named `feature/<short-desc>` or a bugfix branch `fix/<short-desc>`.
3. Run `flutter pub get`, add tests if applicable, and ensure the app builds locally.
4. Submit a pull request with a clear description of changes.

## Contact / Maintainers

If you need help, open an issue in this repository or contact the maintainers listed in the repository settings.

## License

This project does not include a license file in the repository by default. Add a `LICENSE` file if you want to set a specific license.

---

If you'd like, I can also:

- Add a short `CONTRIBUTING.md` with command snippets
- Add a `flutter` `Makefile` or `scripts/` folder for common tasks (build, clean, sign)
- Create a sample `key.properties.example` with instructions (without secret data)

Tell me which of these extras you'd like and I'll add them.
