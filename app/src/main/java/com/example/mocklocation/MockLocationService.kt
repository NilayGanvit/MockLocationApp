package com.example.mocklocation

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.app.NotificationCompat
import kotlin.random.Random

class MockLocationService : Service() {

    private lateinit var mockLocationProvider: MockLocationProvider
    private val handler = Handler(Looper.getMainLooper())
    private var isMockingActive = false

    private val mockRunnable = object : Runnable {
        override fun run() {
            if (isMockingActive) {
                if (isJitterEnabled) {
                    // Add a tiny random offset to simulate natural GPS noise (approx. 0.5 to 1 meter)
                    val latJitter = (Random.nextDouble() - 0.5) * 0.00001
                    val lonJitter = (Random.nextDouble() - 0.5) * 0.00001
                    
                    // Keep the accuracy fluctuating slightly (e.g. 10m to 15m)
                    val accuracyJitter = 10f + Random.nextFloat() * 5f
                    
                    // Add minor variation to altitude (e.g. 148.0m to 152.0m)
                    val altitudeJitter = 150.0 + (Random.nextDouble() - 0.5) * 4.0
                    
                    // Speed: occasionally show tiny drift (e.g., 0 to 0.2 m/s), otherwise 0
                    val speedVal = if (Random.nextBoolean()) Random.nextFloat() * 0.2f else 0.0f
                    
                    // Bearing: random float from 0 to 360
                    val bearingVal = Random.nextFloat() * 360f

                    mockLocationProvider.setMockLocation(
                        currentLatitude + latJitter,
                        currentLongitude + lonJitter,
                        accuracyJitter,
                        altitudeJitter,
                        speedVal,
                        bearingVal
                    )
                } else {
                    mockLocationProvider.setMockLocation(
                        currentLatitude,
                        currentLongitude,
                        currentAccuracy,
                        150.0,
                        0.0f,
                        0.0f
                    )
                }
                handler.postDelayed(this, 1000)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        mockLocationProvider = MockLocationProvider(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            stopSelf()
            return START_NOT_STICKY
        }

        val action = intent.action
        if (action == ACTION_STOP) {
            stopMocking()
            stopSelf()
            return START_NOT_STICKY
        }

        val lat = intent.getDoubleExtra(EXTRA_LATITUDE, 51.5074)
        val lon = intent.getDoubleExtra(EXTRA_LONGITUDE, -0.1278)
        val acc = intent.getFloatExtra(EXTRA_ACCURACY, 25f)
        val label = intent.getStringExtra(EXTRA_LABEL) ?: "Set"

        startMocking(lat, lon, acc, label)

        return START_STICKY
    }

    private fun startMocking(lat: Double, lon: Double, acc: Float, label: String) {
        currentLatitude = lat
        currentLongitude = lon
        currentAccuracy = acc
        currentLabel = label
        isRunning = true

        mockLocationProvider.startMockProvider()

        val notification = createNotification(lat, lon)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        if (!isMockingActive) {
            isMockingActive = true
            handler.post(mockRunnable)
        } else {
            // Update immediately since location coordinates changed
            mockLocationProvider.setMockLocation(lat, lon, acc, 150.0, 0.0f, 0.0f)
            // Update the notification contents
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.notify(NOTIFICATION_ID, notification)
        }
    }

    private fun stopMocking() {
        isMockingActive = false
        handler.removeCallbacks(mockRunnable)
        mockLocationProvider.stopMockProvider()
        isRunning = false
        currentLabel = "Stop"
    }

    override fun onDestroy() {
        stopMocking()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotification(latitude: Double, longitude: Double): Notification {
        val channelId = "mock_location_channel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Mock Location Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows status of mock location"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("Mocking Location")
            .setContentText("Lat: $latitude, Lon: $longitude")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    companion object {
        private const val NOTIFICATION_ID = 1001
        
        const val ACTION_START = "com.example.mocklocation.action.START"
        const val ACTION_STOP = "com.example.mocklocation.action.STOP"
        
        const val EXTRA_LATITUDE = "latitude"
        const val EXTRA_LONGITUDE = "longitude"
        const val EXTRA_ACCURACY = "accuracy"
        const val EXTRA_LABEL = "label"

        var isJitterEnabled by mutableStateOf(false)
        
        var isRunning by mutableStateOf(false)
            private set
        var currentLatitude by mutableStateOf(51.5074)
            private set
        var currentLongitude by mutableStateOf(-0.1278)
            private set
        var currentAccuracy by mutableStateOf(25f)
            private set
        var currentLabel by mutableStateOf("Ready")
            private set

        fun start(context: Context, latitude: Double, longitude: Double, accuracy: Float, label: String) {
            val intent = Intent(context, MockLocationService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_LATITUDE, latitude)
                putExtra(EXTRA_LONGITUDE, longitude)
                putExtra(EXTRA_ACCURACY, accuracy)
                putExtra(EXTRA_LABEL, label)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, MockLocationService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }
    }
}
