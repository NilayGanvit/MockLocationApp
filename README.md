# Mock Location App - Wear OS

A lightweight Android Wear OS app for injecting mock GPS locations on smartwatches. Useful for testing location-dependent applications without physically moving.

## Features

- **Manual Coordinate Entry**: Set any latitude and longitude manually
- **UK Presets**: Quick buttons for 4 major UK cities:
  - London (51.5074, -0.1278)
  - Manchester (53.4808, -2.2426)
  - Edinburgh (55.9533, -3.1883)
  - Cardiff (51.4816, -3.1791)
- **Accuracy Control**: Adjustable accuracy (in meters) for realistic testing
- **Simple Toggle**: Easy Start/Stop buttons for mock location injection

## Requirements

- Wear OS 10+ (API 26+)
- Android device/watch with location services
- Android SDK 34 installed
- JDK 11+
- Gradle 7.0+

## Building

### Prerequisites
1. Install Android SDK (API 34) via Android Studio or command line
2. Install JDK 11 or higher
3. Set ANDROID_HOME environment variable

### Build APK
```bash
./gradlew assembleDebug
```

### Build and Install
```bash
./gradlew installDebug
```

## Installation

### Via ADB (Direct)
```bash
adb connect 192.168.1.6:40741
adb install app/build/outputs/apk/debug/app-debug.apk
```

### Launch App
```bash
adb shell am start -n com.example.mocklocation/.MainActivity
```

## Usage

1. Open the app on your Wear OS device
2. Choose one of these options:
   - **Quick Presets**: Tap a UK city button to instantly set location
   - **Manual Entry**: Edit latitude, longitude, and accuracy fields, then tap "Set"
3. Tap "Stop" to disable mock location when done

## How It Works

The app uses Android's LocationManager test provider API to inject mock GPS locations. This is a system-level feature that allows test/debug applications to override the device's real GPS location for development and testing purposes.

### Required Permissions
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_MOCK_LOCATION`

## Building from Source

```bash
# Clone or extract the project
cd MockLocationApp

# Build debug APK
./gradlew clean build

# Install on connected device
./gradlew installDebug
```

## Troubleshooting

### "Permission denied" or "Unable to set location"
- Ensure the app has location permissions granted
- Check that the device is in Developer mode
- Verify that no other app is claiming mock location provider

### App not visible on watch
- Device may not recognize the app as a Wear OS app
- Ensure manifest specifies `android.hardware.type.watch`

### Location not updating
- Some apps cache location; restart them after setting mock location
- Check logcat: `adb logcat | grep -i location`

## Development Notes

- Built with Jetpack Compose and Wear Compose Material library
- Targets Android 14+ (API 34)
- Kotlin-based with proper exception handling
- Test provider compatibility with both Wear OS and standard Android

## License

MIT License - Use freely for testing and development purposes.
