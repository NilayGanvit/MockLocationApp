# Mock Location App - Wear OS

## Project Overview
Android Wear OS app for injecting mock GPS locations. Designed for testing location-dependent features on smartwatches.

## Technology Stack
- Language: Kotlin
- Target: Wear OS 10+
- SDK: Android 34 (API 34)
- Build System: Gradle

## Build & Deploy
- `./gradlew build` - Build the app
- `./gradlew installDebug` - Install on connected device
- `adb shell am start -n com.example.mocklocation/.MainActivity` - Launch app
