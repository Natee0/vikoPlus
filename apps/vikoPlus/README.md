# vikoPlus Android

This is the Flutter Android client for vikoPlus.

## Requirements

- Flutter SDK installed and available on `PATH`
- Android Studio or Android SDK command line tools
- An Android emulator or physical Android device with USB/wireless debugging

## Setup

From the repository root:

```bash
npm run android:get
```

Or directly from this app folder:

```bash
flutter pub get
```

## Run On Android

The backend base URL is configured in:

```text
lib/src/core/config/app_config.dart
```

Update `VIKOPLUS_API_BASE_URL` there when the API host changes.

From the repository root:

```bash
cd apps/vikoPlus
flutter run
```

Or directly from this app folder:

```bash
flutter run
```

To run on a specific connected device:

```bash
flutter devices
flutter run -d <device-id>
```

The Android project is optimized for physical ARM64 phones. If you need to run
an x86 emulator later, update the ABI filter in `android/app/build.gradle.kts`.

## Quality Checks

```bash
npm run android:analyze
npm run android:test
```

## Debug APK

```bash
npm run android:build:debug
```

The APK is generated under:

```text
apps/vikoPlus/build/app/outputs/flutter-apk/app-debug.apk
```

## Android Identity

- App display name: `vikoPlus`
- Dart package name: `vikoplus`
- Android application id: `com.vikoplus`
