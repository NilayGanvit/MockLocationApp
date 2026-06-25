package com.example.mocklocation

import android.Manifest
import android.content.Context
import android.location.Location
import android.location.LocationManager
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.annotation.RequiresPermission

@RequiresApi(Build.VERSION_CODES.S)
class MockLocationProvider(private val context: Context) {

    private val locationManager: LocationManager =
        context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

    // UK location presets (latitude, longitude, name)
    val ukPresets = listOf(
        Triple(51.5074, -0.1278, "London"),
        Triple(53.4808, -2.2426, "Manchester"),
        Triple(55.9533, -3.1883, "Edinburgh"),
        Triple(51.4816, -3.1791, "Cardiff")
    )

    @RequiresPermission(Manifest.permission.ACCESS_FINE_LOCATION)
    fun setMockLocation(latitude: Double, longitude: Double, accuracy: Float = 25f) {
        try {
            // Create a mock location
            val mockLocation = Location(LocationManager.GPS_PROVIDER).apply {
                this.latitude = latitude
                this.longitude = longitude
                this.accuracy = accuracy
                this.altitude = 0.0
                this.time = System.currentTimeMillis()
                this.elapsedRealtimeNanos = System.nanoTime()
            }

            // Set the mock location using the test provider
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                locationManager.setTestProviderLocation(LocationManager.GPS_PROVIDER, mockLocation)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun startMockProvider() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // Ensure the test provider exists
                if (!locationManager.getProviders(false).contains(LocationManager.GPS_PROVIDER)) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        locationManager.addTestProvider(
                            LocationManager.GPS_PROVIDER,
                            false,
                            false,
                            false,
                            false,
                            true,
                            true,
                            true,
                            android.location.Criteria.POWER_LOW,
                            android.location.Criteria.ACCURACY_FINE
                        )
                    }
                }
                // Enable the test provider
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    locationManager.setTestProviderEnabled(LocationManager.GPS_PROVIDER, true)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun stopMockProvider() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                locationManager.setTestProviderEnabled(LocationManager.GPS_PROVIDER, false)
                locationManager.removeTestProvider(LocationManager.GPS_PROVIDER)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
