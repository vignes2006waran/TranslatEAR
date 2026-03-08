package com.example.translation_app

import android.media.AudioManager
import android.media.AudioDeviceInfo
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.KeyEvent
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val BT_CHANNEL    = "bluetooth_devices"
    private val EVENT_CHANNEL = "volume_button_events"
    private val AUDIO_CHANNEL = "audio_config"

    private var eventSink: EventChannel.EventSink? = null
    private var lastVolumeDownTime: Long = 0
    private val DOUBLE_PRESS_DELAY = 500L
    private val handler = Handler(Looper.getMainLooper())

    private var micType     = "phone"
    private var speakerType = "phone"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL)
            .setMethodCallHandler { call, result ->
                val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                try {
                    when (call.method) {
                        "setMic" -> {
                            micType = call.argument<String>("type") ?: "phone"
                            applyAudioRouting(audio)
                            result.success(true)
                        }
                        "setSpeaker" -> {
                            speakerType = call.argument<String>("type") ?: "phone"
                            applyAudioRouting(audio)
                            result.success(true)
                        }
                        "prepareForListening" -> {
                            prepareForListening(audio)
                            result.success(true)
                        }
                        "prepareForSpeaking" -> {
                            prepareForSpeaking(audio)
                            result.success(true)
                        }
                        "restoreAfterSpeaking" -> {
                            prepareForListening(audio)
                            result.success(true)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BT_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getConnectedDevices") {
                    getConnectedBluetoothDevices { devices -> result.success(devices) }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun forcePhoneSpeaker(audio: AudioManager) {
        audio.stopBluetoothSco()
        audio.isBluetoothScoOn = false
        audio.mode = AudioManager.MODE_NORMAL
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val devices = audio.availableCommunicationDevices
            val speaker = devices.firstOrNull {
                it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER
            }
            if (speaker != null) {
                audio.setCommunicationDevice(speaker)
            } else {
                audio.isSpeakerphoneOn = true
            }
        } else {
            audio.isSpeakerphoneOn = true
        }
    }

    private fun forceBluetoothSpeaker(audio: AudioManager) {
        audio.mode = AudioManager.MODE_IN_COMMUNICATION
        audio.startBluetoothSco()
        audio.isBluetoothScoOn = true
        audio.isSpeakerphoneOn = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val devices = audio.availableCommunicationDevices
            val btDevice = devices.firstOrNull {
                it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                        it.type == AudioDeviceInfo.TYPE_BLE_HEADSET
            }
            if (btDevice != null) {
                audio.setCommunicationDevice(btDevice)
            }
        }
    }

    private fun applyAudioRouting(audio: AudioManager) {
        when {
            micType == "phone" && speakerType == "phone" -> {
                forcePhoneSpeaker(audio)
            }
            micType == "phone" && speakerType == "bluetooth" -> {
                audio.stopBluetoothSco()
                audio.isBluetoothScoOn = false
                audio.mode = AudioManager.MODE_NORMAL
                audio.isSpeakerphoneOn = false
            }
            micType == "bluetooth" && speakerType == "phone" -> {
                audio.mode = AudioManager.MODE_IN_COMMUNICATION
                audio.startBluetoothSco()
                audio.isBluetoothScoOn = true
                forcePhoneSpeaker(audio)
            }
            micType == "bluetooth" && speakerType == "bluetooth" -> {
                forceBluetoothSpeaker(audio)
            }
        }
    }

    private fun prepareForListening(audio: AudioManager) {
        when (micType) {
            "phone" -> {
                audio.stopBluetoothSco()
                audio.isBluetoothScoOn = false
                audio.mode = AudioManager.MODE_NORMAL
                audio.isSpeakerphoneOn = false
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    audio.clearCommunicationDevice()
                }
            }
            "bluetooth" -> {
                audio.mode = AudioManager.MODE_IN_COMMUNICATION
                audio.startBluetoothSco()
                audio.isBluetoothScoOn = true
                audio.isSpeakerphoneOn = false
            }
        }
    }

    private fun prepareForSpeaking(audio: AudioManager) {
        applyAudioRouting(audio)
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            val now = System.currentTimeMillis()
            if (now - lastVolumeDownTime <= DOUBLE_PRESS_DELAY) {
                handler.post { eventSink?.success("volume_double_press") }
                lastVolumeDownTime = 0
            } else {
                lastVolumeDownTime = now
            }
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) return true
        return super.onKeyUp(keyCode, event)
    }

    private fun getConnectedBluetoothDevices(callback: (List<Map<String, String>>) -> Unit) {
        val btManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val adapter = btManager.adapter

        if (ActivityCompat.checkSelfPermission(
                this, android.Manifest.permission.BLUETOOTH_CONNECT
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this, arrayOf(android.Manifest.permission.BLUETOOTH_CONNECT), 1
            )
            callback(emptyList())
            return
        }

        val deviceList = mutableListOf<Map<String, String>>()
        var profilesChecked = 0

        fun checkDone() {
            profilesChecked++
            if (profilesChecked >= 2) callback(deviceList)
        }

        listOf(BluetoothProfile.A2DP, BluetoothProfile.HEADSET).forEach { profile ->
            adapter.getProfileProxy(this, object : BluetoothProfile.ServiceListener {
                override fun onServiceConnected(p: Int, proxy: BluetoothProfile) {
                    proxy.connectedDevices.forEach { device ->
                        if (deviceList.none { it["address"] == device.address }) {
                            deviceList.add(mapOf(
                                "name"    to (device.name ?: "Unknown Device"),
                                "address" to device.address
                            ))
                        }
                    }
                    adapter.closeProfileProxy(p, proxy)
                    checkDone()
                }
                override fun onServiceDisconnected(p: Int) { checkDone() }
            }, profile)
        }
    }
}