param (
    [string]$deviceIp = "192.168.1.6",
    [string]$connectPort = "45307"
)

# Set serial to ensure adb goes to the correct device
if ($connectPort) {
    $env:ANDROID_SERIAL = "${deviceIp}:${connectPort}"
    Write-Host "Connecting to watch..."
    adb connect "${deviceIp}:${connectPort}"
}

# Ensure we have correct active device
adb devices

function Tap-UiElement([string]$text) {
    adb shell uiautomator dump /data/local/tmp/uidump.xml > $null
    $dump = adb shell cat /data/local/tmp/uidump.xml
    
    # Regex to find bounds of matching text node
    if ($dump -match "text=`"$text`"[^>]*bounds=`"\[(\d+),(\d+)\]\[(\d+),(\d+)\]`"") {
        $x1 = [int]$Matches[1]
        $y1 = [int]$Matches[2]
        $x2 = [int]$Matches[3]
        $y2 = [int]$Matches[4]
        
        $centerX = [int](($x1 + $x2) / 2)
        $centerY = [int](($y1 + $y2) / 2)
        
        Write-Host "Found '$text' at ($centerX, $centerY). Tapping..."
        adb shell input tap $centerX $centerY
        return $true
    }
    return $false
}

function Set-UiTextField([string]$currentText, [string]$newText) {
    adb shell uiautomator dump /data/local/tmp/uidump.xml > $null
    $dump = adb shell cat /data/local/tmp/uidump.xml
    
    if ($dump -match "text=`"$currentText`"[^>]*bounds=`"\[(\d+),(\d+)\]\[(\d+),(\d+)\]`"") {
        $x1 = [int]$Matches[1]
        $y1 = [int]$Matches[2]
        $x2 = [int]$Matches[3]
        $y2 = [int]$Matches[4]
        
        $centerX = [int](($x1 + $x2) / 2)
        $centerY = [int](($y1 + $y2) / 2)
        
        adb shell input tap $centerX $centerY
        Start-Sleep -Milliseconds 500
        
        # Send backspaces to clear current text
        for ($i = 0; $i -lt 15; $i++) {
            adb shell input keyevent 67  # KEYCODE_DEL
        }
        
        adb shell input text "$newText"
        Start-Sleep -Milliseconds 500
        return $true
    }
    return $false
}

Write-Host "=== Building and Installing the app ==="
.\gradlew.bat assembleDebug
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed!"
    exit 1
}
adb install -g -r app/build/outputs/apk/debug/app-debug.apk
if ($LASTEXITCODE -ne 0) {
    Write-Error "Installation failed!"
    exit 1
}
adb shell appops set com.example.mocklocation android:mock_location allow

# Define the locations to test
$locations = @(
    @{ Name = "India"; Lat = 28.6139; Lon = 77.2090 },
    @{ Name = "US"; Lat = 38.8936; Lon = -77.0146 },
    @{ Name = "UK"; Lat = 51.5074; Lon = -0.1278 },
    @{ Name = "UAE"; Lat = 24.4667; Lon = 54.3667 },
    @{ Name = "Netherlands"; Lat = 52.3740; Lon = 4.8897 }
)

$allPassed = $true

foreach ($loc in $locations) {
    Write-Host "`n=========================================="
    Write-Host "Testing Location Preset: $($loc.Name) ($($loc.Lat), $($loc.Lon))"
    Write-Host "=========================================="
    
    # Force stop and start to reset UI fields to default
    adb shell am force-stop com.example.mocklocation
    Start-Sleep -Seconds 1
    adb shell am start -n com.example.mocklocation/.MainActivity
    Start-Sleep -Seconds 4
    
    # Try to tap the Preset button directly (by name)
    Write-Host "Attempting to tap Preset button for $($loc.Name)..."
    $tapped = Tap-UiElement $loc.Name
    
    # If not found, swipe down a bit to bring lower presets into view
    if (-not $tapped) {
        Write-Host "Preset button not found in initial view. Swiping down to scroll..."
        # Swipe from center-bottom to center-top to scroll down
        adb shell input swipe 200 300 200 100
        Start-Sleep -Milliseconds 500
        $tapped = Tap-UiElement $loc.Name
    }
    
    # If still not tapped, fallback to Manual Text Entry
    if (-not $tapped) {
        Write-Host "Preset button still not found. Falling back to manual entry fields..."
        # Re-launch to reset scroll if needed
        adb shell am force-stop com.example.mocklocation
        Start-Sleep -Seconds 1
        adb shell am start -n com.example.mocklocation/.MainActivity
        Start-Sleep -Seconds 4
        
        $defaultLat = "51.5074"
        $defaultLon = "-0.1278"
        
        if ($loc.Lat.ToString() -ne $defaultLat) {
            Write-Host "Updating Latitude field to $($loc.Lat)..."
            Set-UiTextField -currentText $defaultLat -newText $loc.Lat.ToString()
        }
        if ($loc.Lon.ToString() -ne $defaultLon) {
            Write-Host "Updating Longitude field to $($loc.Lon)..."
            Set-UiTextField -currentText $defaultLon -newText $loc.Lon.ToString()
        }
        
        Write-Host "Tapping the 'Set' button..."
        $setTapped = Tap-UiElement "Set"
        if (-not $setTapped) {
            Write-Host "Failed to tap 'Set' button via UI. Sending fallback broadcast intent..."
            adb shell am broadcast -a com.example.mocklocation.SET_LOCATION --es lat "$($loc.Lat)" --es lon "$($loc.Lon)"
        }
    }
    
    Write-Host "Waiting for location updates to propagate (3s)..."
    Start-Sleep -Seconds 3
    
    Write-Host "Verifying mocked location via dumpsys..."
    $locationDump = adb shell dumpsys location
    
    $latFormatted = "{0:F6}" -f $loc.Lat
    $lonFormatted = "{0:F6}" -f $loc.Lon
    
    $fusedMatch = $locationDump | Select-String -Pattern "last location=Location\[fused $latFormatted,$lonFormatted"
    $networkMatch = $locationDump | Select-String -Pattern "last location=Location\[network $latFormatted,$lonFormatted"
    $gpsMatch = $locationDump | Select-String -Pattern "last location=Location\[gps $latFormatted,$lonFormatted"
    
    Write-Host "`nVerification Results for $($loc.Name):"
    $locPassed = $true
    if ($fusedMatch) {
        Write-Host "[PASS] Fused Location Provider mocked successfully!"
    } else {
        Write-Host "[FAIL] Fused Location Provider verification failed!"
        $locPassed = $false
    }
    
    if ($networkMatch) {
        Write-Host "[PASS] Network Location Provider mocked successfully!"
    } else {
        Write-Host "[FAIL] Network Location Provider verification failed!"
        $locPassed = $false
    }
    
    if ($gpsMatch) {
        Write-Host "[PASS] GPS Location Provider mocked successfully!"
    } else {
        Write-Host "[FAIL] GPS Location Provider verification failed!"
        $locPassed = $false
    }
    
    if (-not $locPassed) {
        $allPassed = $false
    }
}

Write-Host "`n=========================================="
if ($allPassed) {
    Write-Host "[SUCCESS] All 5 country presets tested and verified successfully!"
    exit 0
} else {
    Write-Error "[FAILURE] Verification failed for one or more location presets!"
    exit 1
}
