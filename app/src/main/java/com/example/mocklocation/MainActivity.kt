package com.example.mocklocation

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.annotation.RequiresApi
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.Button
import androidx.compose.material.OutlinedTextField
import androidx.compose.material.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.dp
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.items
import android.annotation.SuppressLint
import androidx.wear.compose.material.*
import androidx.wear.compose.material.MaterialTheme

@SuppressLint("MissingPermission")
@RequiresApi(Build.VERSION_CODES.S)
class MainActivity : ComponentActivity() {
    private lateinit var mockLocationProvider: MockLocationProvider
    private val LOCATION_PERMISSION_REQUEST_CODE = 100

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        mockLocationProvider = MockLocationProvider(this)
        
        // Request permissions
        requestLocationPermissions()

        val filter = android.content.IntentFilter("com.example.mocklocation.SET_LOCATION")
        val receiver = object : android.content.BroadcastReceiver() {
            override fun onReceive(context: android.content.Context?, intent: android.content.Intent?) {
                if (intent != null) {
                    val lat = intent.getDoubleExtra("lat", 0.0).takeIf { it != 0.0 }
                        ?: intent.getStringExtra("lat")?.toDoubleOrNull()
                        ?: 51.5074
                    val lon = intent.getDoubleExtra("lon", 0.0).takeIf { it != 0.0 }
                        ?: intent.getStringExtra("lon")?.toDoubleOrNull()
                        ?: -0.1278
                    val acc = intent.getFloatExtra("acc", 0f).takeIf { it != 0f }
                        ?: intent.getStringExtra("acc")?.toFloatOrNull()
                        ?: 25f
                    try {
                        mockLocationProvider.startMockProvider()
                        mockLocationProvider.setMockLocation(lat, lon, acc)
                        android.util.Log.d("MockLocation", "Broadcast set location: $lat, $lon, $acc")
                    } catch (e: Exception) {
                        android.util.Log.e("MockLocation", "Error setting via broadcast: ${e.message}")
                    }
                }
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, filter, android.content.Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(receiver, filter)
        }

        setContent {
            MaterialTheme {
                MockLocationApp(mockLocationProvider, ::requestLocationPermissions)
            }
        }
    }

    private fun requestLocationPermissions() {
        val permissions = arrayOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION
        )

        val needsRequest = permissions.any {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (needsRequest) {
            ActivityCompat.requestPermissions(this, permissions, LOCATION_PERMISSION_REQUEST_CODE)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == LOCATION_PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                // Permissions granted
            }
        }
    }
}

@RequiresApi(Build.VERSION_CODES.S)
@Composable
fun MockLocationApp(
    mockLocationProvider: MockLocationProvider,
    onRequestPermissions: () -> Unit
) {
    var latitude by remember { mutableStateOf(TextFieldValue("51.5074")) }
    var longitude by remember { mutableStateOf(TextFieldValue("-0.1278")) }
    var accuracy by remember { mutableStateOf(TextFieldValue("25")) }
    var isMocking by remember { mutableStateOf(false) }
    var statusMessage by remember { mutableStateOf("Ready") }

    ScalingLazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        contentPadding = PaddingValues(8.dp)
    ) {
        item {
            Text("Mock Location", style = MaterialTheme.typography.title3)
        }

        item {
            OutlinedTextField(
                value = latitude,
                onValueChange = { latitude = it },
                label = { Text("Lat") },
                modifier = Modifier.width(120.dp)
            )
        }

        item {
            OutlinedTextField(
                value = longitude,
                onValueChange = { longitude = it },
                label = { Text("Lon") },
                modifier = Modifier.width(120.dp)
            )
        }

        item {
            OutlinedTextField(
                value = accuracy,
                onValueChange = { accuracy = it },
                label = { Text("Acc") },
                modifier = Modifier.width(120.dp)
            )
        }

        item {
            Button(
                onClick = {
                    try {
                        val lat = latitude.text.toDoubleOrNull() ?: 51.5074
                        val lon = longitude.text.toDoubleOrNull() ?: -0.1278
                        val acc = accuracy.text.toFloatOrNull() ?: 25f

                        mockLocationProvider.startMockProvider()
                        mockLocationProvider.setMockLocation(lat, lon, acc)
                        isMocking = true
                        statusMessage = "Location Set"
                    } catch (e: Exception) {
                        statusMessage = "Error: ${e.message}"
                    }
                },
                modifier = Modifier.size(width = 100.dp, height = 40.dp)
            ) {
                Text("Set")
            }
        }

        item {
            Button(
                onClick = {
                    mockLocationProvider.stopMockProvider()
                    isMocking = false
                    statusMessage = "Stopped"
                },
                modifier = Modifier.size(width = 100.dp, height = 40.dp)
            ) {
                Text("Stop")
            }
        }

        item {
            Text(statusMessage, style = MaterialTheme.typography.caption1)
        }

        item {
            Text("Country Presets", style = MaterialTheme.typography.caption1)
        }

        items(mockLocationProvider.countryPresets) { (lat, lon, name) ->
            Button(
                onClick = {
                    try {
                        mockLocationProvider.startMockProvider()
                        mockLocationProvider.setMockLocation(lat, lon, 25f)
                        latitude = TextFieldValue(lat.toString())
                        longitude = TextFieldValue(lon.toString())
                        isMocking = true
                        statusMessage = "$name Set"
                    } catch (e: Exception) {
                        statusMessage = "Error: ${e.message}"
                    }
                },
                modifier = Modifier.size(width = 100.dp, height = 40.dp)
            ) {
                Text(name, style = MaterialTheme.typography.caption2)
            }
        }
    }
}
