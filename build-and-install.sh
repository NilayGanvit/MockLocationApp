#!/bin/bash
echo "Building Mock Location App..."
./gradlew clean build
if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "Installing to device..."
    ./gradlew installDebug
    if [ $? -eq 0 ]; then
        echo "Installation successful!"
        echo "Launching app..."
        adb shell am start -n com.example.mocklocation/.MainActivity
    else
        echo "Installation failed!"
    fi
else
    echo "Build failed!"
fi
