package com.example.translation_app

import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.view.KeyEvent
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity: FlutterActivity() {
    private val BT_CHANNEL = "bluetooth_devices"
    private val EVENT_CHANNEL = "volume_button_events"
    private var eventSink: EventChannel.EventSink? = null

    private var lastVolumeDownTime: Long = 0
    private val DOUBLE_PRESS_DELAY = 500L // 500ms between presses
    private val handler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BT_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getConnectedDevices") {
                    try {
                        val devices = getConnectedBluetoothDevices()
                        result.success(devices)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            val currentTime = System.currentTimeMillis()
            if (currentTime - lastVolumeDownTime <= DOUBLE_PRESS_DELAY) {
                // Double press detected!
                handler.post {
                    eventSink?.success("volume_double_press")
                }
                lastVolumeDownTime = 0
            } else {
                lastVolumeDownTime = currentTime
            }
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            return true
        }
        return super.onKeyUp(keyCode, event)
    }

    private fun getConnectedBluetoothDevices(): List<Map<String, String>> {
        val bluetoothManager =
            getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val adapter = bluetoothManager.adapter

        if (ActivityCompat.checkSelfPermission(
                this,
                android.Manifest.permission.BLUETOOTH_CONNECT
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(android.Manifest.permission.BLUETOOTH_CONNECT),
                1
            )
            return emptyList()
        }

        val deviceList = mutableListOf<Map<String, String>>()
        val bondedDevices = adapter.bondedDevices
        bondedDevices?.forEach { device ->
            deviceList.add(
                mapOf(
                    "name" to (device.name ?: "Unknown Device"),
                    "address" to device.address
                )
            )
        }
        return deviceList
    }
}