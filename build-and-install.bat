@echo off
echo Building Mock Location App...
call gradlew.bat clean build
if %ERRORLEVEL% EQU 0 (
    echo Build successful!
    echo Installing to device...
    call gradlew.bat installDebug
    if %ERRORLEVEL% EQU 0 (
        echo Installation successful!
        echo Launching app...
        adb shell am start -n com.example.mocklocation/.MainActivity
    ) else (
        echo Installation failed!
    )
) else (
    echo Build failed!
)
