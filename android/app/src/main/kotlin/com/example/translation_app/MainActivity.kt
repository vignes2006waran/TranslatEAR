package com.example.translation_app

import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
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

    private var micType     = "phone"   // "phone" or "bluetooth"
    private var speakerType = "phone"   // "phone" or "bluetooth"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Audio config channel ─────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL)
            .setMethodCallHandler { call, result ->
                val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                try {
                    when (call.method) {

                        "setMic" -> {
                            micType = call.argument<String>("type") ?: "phone"
                            result.success(true)
                        }

                        "setSpeaker" -> {
                            speakerType = call.argument<String>("type") ?: "phone"
                            result.success(true)
                        }

                        // ── Called just before speech recognition starts ──────
                        "prepareForListening" -> {
                            prepareForListening(audio)
                            result.success(true)
                        }

                        // ── Called just before TTS speaks ────────────────────
                        "prepareForSpeaking" -> {
                            prepareForSpeaking(audio)
                            result.success(true)
                        }

                        // ── Called after TTS finishes, back to listening ──────
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

        // ── Volume button event channel ──────────────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })

        // ── Bluetooth devices channel ────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BT_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getConnectedDevices") {
                    getConnectedBluetoothDevices { devices -> result.success(devices) }
                } else {
                    result.notImplemented()
                }
            }
    }

    // ── Prepare audio for LISTENING ──────────────────────────────────────────
    //
    //  mic=phone  → stop BT SCO completely so Android uses phone mic
    //  mic=bt     → start BT SCO so earbud mic is active
    //
    private fun prepareForListening(audio: AudioManager) {
        when (micType) {
            "phone" -> {
                // Stop ALL Bluetooth SCO — this forces Android to use phone mic
                audio.stopBluetoothSco()
                audio.isBluetoothScoOn = false
                audio.mode = AudioManager.MODE_NORMAL
                audio.isSpeakerphoneOn = false
            }
            "bluetooth" -> {
                // Start BT SCO so earbud mic is captured
                audio.mode = AudioManager.MODE_IN_COMMUNICATION
                audio.startBluetoothSco()
                audio.isBluetoothScoOn = true
                audio.isSpeakerphoneOn = false
            }
        }
    }

    // ── Prepare audio for SPEAKING (TTS) ────────────────────────────────────
    //
    //  mic=phone,  speaker=phone  → speakerphone, no SCO
    //  mic=phone,  speaker=bt     → A2DP output (MODE_NORMAL, no SCO)
    //                               Android auto-routes media audio to A2DP
    //                               without activating BT mic at all
    //  mic=bt,     speaker=phone  → stop SCO, use speakerphone for output
    //  mic=bt,     speaker=bt     → SCO active, earbud handles both
    //
    private fun prepareForSpeaking(audio: AudioManager) {
        when {
            // ── Phone mic + Phone speaker ────────────────────────────────────
            micType == "phone" && speakerType == "phone" -> {
                audio.stopBluetoothSco()
                audio.isBluetoothScoOn = false
                audio.mode = AudioManager.MODE_NORMAL
                audio.isSpeakerphoneOn = true
            }

            // ── Phone mic + Earbud speaker ───────────────────────────────────
            // KEY: Use A2DP (MODE_NORMAL, no SCO). A2DP plays audio to earbuds
            // as a media stream WITHOUT activating the earbud microphone.
            // This is the only way to have phone mic + earbud speaker.
            micType == "phone" && speakerType == "bluetooth" -> {
                audio.stopBluetoothSco()
                audio.isBluetoothScoOn = false
                audio.mode = AudioManager.MODE_NORMAL
                audio.isSpeakerphoneOn = false
                // A2DP handles output automatically in MODE_NORMAL
                // when earbuds are connected — no extra call needed
            }

            // ── Earbud mic + Phone speaker ───────────────────────────────────
            // SCO was active for mic. For TTS output we want phone speaker.
            // Stop SCO (releases earbud mic), switch to speakerphone.
            // Note: mic won't capture during TTS anyway, so this is fine.
            micType == "bluetooth" && speakerType == "phone" -> {
                audio.stopBluetoothSco()
                audio.isBluetoothScoOn = false
                audio.mode = AudioManager.MODE_NORMAL
                audio.isSpeakerphoneOn = true
            }

            // ── Earbud mic + Earbud speaker ──────────────────────────────────
            // Full SCO: mic + speaker both through earbuds
            micType == "bluetooth" && speakerType == "bluetooth" -> {
                audio.mode = AudioManager.MODE_IN_COMMUNICATION
                audio.startBluetoothSco()
                audio.isBluetoothScoOn = true
                audio.isSpeakerphoneOn = false
            }
        }
    }

    // ── Volume double press ──────────────────────────────────────────────────
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

    // ── Get connected Bluetooth devices ─────────────────────────────────────
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