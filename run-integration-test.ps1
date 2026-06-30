param (
    [string]$deviceIp = "192.168.1.6",
    [string]$pairPort = "",
    [string]$pairCode = "",
    [string]$connectPort = "",
    [double]$lat = 51.5074,
    [double]$lon = -0.1278
)

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

if ($pairPort -and $pairCode) {
    Write-Host "=== Step 1: Pairing watch (${deviceIp}:${pairPort}) ==="
    $pairCode | adb pair "${deviceIp}:${pairPort}"
} else {
    Write-Host "=== Step 1: Pairing skipped (no port/code provided) ==="
}

if ($connectPort) {
    Write-Host "=== Step 2: Connecting to watch (${deviceIp}:${connectPort}) ==="
    adb connect "${deviceIp}:${connectPort}"
} else {
    Write-Host "=== Step 2: Connection skipped (no connectPort provided) ==="
}

Write-Host "=== Step 3: Checking connected devices ==="
adb devices

Write-Host "=== Step 4: Building the app ==="
.\gradlew.bat assembleDebug
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed!"
    exit 1
}

Write-Host "=== Step 5: Installing the app ==="
adb install -g -r app/build/outputs/apk/debug/app-debug.apk
if ($LASTEXITCODE -ne 0) {
    Write-Error "Installation failed!"
    exit 1
}

# Ensure mock location permission is granted
adb shell appops set com.example.mocklocation android:mock_location allow

Write-Host "=== Step 6: Launching the app ==="
adb shell am start -n com.example.mocklocation/.MainActivity
# Wait for the app to initialize
Start-Sleep -Seconds 4

Write-Host "=== Step 7: Setting Mock Location via UI ==="
# If the values are different from defaults, update them
$defaultLat = "51.5074"
$defaultLon = "-0.1278"

if ($lat.ToString() -ne $defaultLat) {
    Write-Host "Updating Latitude to $lat..."
    Set-UiTextField -currentText $defaultLat -newText $lat.ToString()
}
if ($lon.ToString() -ne $defaultLon) {
    Write-Host "Updating Longitude to $lon..."
    Set-UiTextField -currentText $defaultLon -newText $lon.ToString()
}

Write-Host "Tapping the 'Set' button..."
$tapped = Tap-UiElement "Set"
if (-not $tapped) {
    Write-Host "Failed to click 'Set' button via UI hierarchy. Trying fallback coordinate tap..."
    # Fallback to keyevents or a default center tap if UI parsing fails on Wear OS round screen
    adb shell input keyevent KEYCODE_TAB
    adb shell input keyevent KEYCODE_ENTER
    
    Write-Host "Sending fallback broadcast intent to set location..."
    adb shell am broadcast -a com.example.mocklocation.SET_LOCATION --es lat "$lat" --es lon "$lon"
}

Write-Host "=== Step 8: Waiting for location updates to propagate ==="
Start-Sleep -Seconds 3

Write-Host "=== Step 9: Verifying mocked location via dumpsys ==="
$locationDump = adb shell dumpsys location

$latFormatted = "{0:F6}" -f $lat
$lonFormatted = "{0:F6}" -f $lon

$fusedMatch = $locationDump | Select-String -Pattern "last location=Location\[fused $latFormatted,$lonFormatted"
$networkMatch = $locationDump | Select-String -Pattern "last location=Location\[network $latFormatted,$lonFormatted"
$gpsMatch = $locationDump | Select-String -Pattern "last location=Location\[gps $latFormatted,$lonFormatted"

Write-Host "`nVerification Results:"
if ($fusedMatch) {
    Write-Host "[PASS] Fused Location Provider mocked successfully!" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Fused Location Provider verification failed!" -ForegroundColor Red
}

if ($networkMatch) {
    Write-Host "[PASS] Network Location Provider mocked successfully!" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Network Location Provider verification failed!" -ForegroundColor Red
}

if ($gpsMatch) {
    Write-Host "[PASS] GPS Location Provider mocked successfully!" -ForegroundColor Green
} else {
    Write-Host "[FAIL] GPS Location Provider verification failed!" -ForegroundColor Red
}
