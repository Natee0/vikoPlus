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

Set the backend base URL through `VIKOPLUS_API_BASE_URL`. The value must include
the API version path, for example `<backend-url>/v1`.

From the repository root:

```bash
cd apps/vikoPlus
flutter run --dart-define=VIKOPLUS_API_BASE_URL=<backend-url>/v1
```

Or directly from this app folder:

```bash
flutter run --dart-define=VIKOPLUS_API_BASE_URL=<backend-url>/v1
```

To run on a specific connected device:

```bash
flutter devices
flutter run -d <device-id> --dart-define=VIKOPLUS_API_BASE_URL=<backend-url>/v1
```

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
