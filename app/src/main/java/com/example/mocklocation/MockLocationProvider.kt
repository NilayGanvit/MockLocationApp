package com.example.mocklocation

import android.Manifest
import android.content.Context
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.SystemClock
import androidx.annotation.RequiresApi
import android.annotation.SuppressLint

@SuppressLint("MissingPermission")
@RequiresApi(Build.VERSION_CODES.S)
class MockLocationProvider(private val context: Context) {

    private val locationManager: LocationManager =
        context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

    // Country location presets (latitude, longitude, name)
    val countryPresets = listOf(
        Triple(28.6139, 77.2090, "India"),
        Triple(38.8936, -77.0146, "US"),
        Triple(51.5074, -0.1278, "UK"),
        Triple(24.4667, 54.3667, "UAE"),
        Triple(52.3740, 4.8897, "Netherlands")
    )

    private val providersToMock = listOf(
        LocationManager.GPS_PROVIDER,
        LocationManager.NETWORK_PROVIDER,
        LocationManager.FUSED_PROVIDER
    )

    fun setMockLocation(
        latitude: Double,
        longitude: Double,
        accuracy: Float = 25f,
        altitude: Double = 150.0,
        speed: Float = 0.0f,
        bearing: Float = 0.0f
    ) {
        val currentTime = System.currentTimeMillis()
        val elapsedRealtimeNanos = SystemClock.elapsedRealtimeNanos()

        for (provider in providersToMock) {
            try {
                // Create a mock location for this provider
                val mockLocation = Location(provider).apply {
                    this.latitude = latitude
                    this.longitude = longitude
                    this.accuracy = accuracy
                    this.altitude = altitude
                    this.speed = speed
                    this.bearing = bearing
                    this.time = currentTime
                    this.elapsedRealtimeNanos = elapsedRealtimeNanos
                    
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        this.elapsedRealtimeUncertaintyNanos = 0.0
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        this.verticalAccuracyMeters = 1.0f
                        this.speedAccuracyMetersPerSecond = 0.1f
                        this.bearingAccuracyDegrees = 1.0f
                    }
                }

                // Set the mock location
                locationManager.setTestProviderLocation(provider, mockLocation)
                android.util.Log.d("MockLocationProvider", "Successfully set mock location for $provider")
            } catch (e: Exception) {
                android.util.Log.e("MockLocationProvider", "Failed to set mock location for $provider: ${e.message}")
            }
        }
    }

    fun startMockProvider() {
        for (provider in providersToMock) {
            try {
                try {
                    locationManager.removeTestProvider(provider)
                } catch (e: Exception) {
                    // Ignore if it was not already a test provider
                }

                // Add the test provider
                locationManager.addTestProvider(
                    provider,
                    false, // requiresNetwork
                    false, // requiresSatellite
                    false, // requiresCell
                    false, // hasMonetaryCost
                    true,  // supportsAltitude
                    true,  // supportsSpeed
                    true,  // supportsBearing
                    android.location.provider.ProviderProperties.POWER_USAGE_LOW,
                    android.location.provider.ProviderProperties.ACCURACY_FINE
                )

                // Enable the test provider
                locationManager.setTestProviderEnabled(provider, true)
                android.util.Log.d("MockLocationProvider", "Successfully started test provider: $provider")
            } catch (e: Exception) {
                android.util.Log.e("MockLocationProvider", "Failed to start test provider $provider: ${e.message}")
            }
        }
    }

    fun stopMockProvider() {
        for (provider in providersToMock) {
            try {
                locationManager.setTestProviderEnabled(provider, false)
                locationManager.removeTestProvider(provider)
                android.util.Log.d("MockLocationProvider", "Successfully stopped test provider: $provider")
            } catch (e: Exception) {
                android.util.Log.e("MockLocationProvider", "Failed to stop test provider $provider: ${e.message}")
            }
        }
    }
}
