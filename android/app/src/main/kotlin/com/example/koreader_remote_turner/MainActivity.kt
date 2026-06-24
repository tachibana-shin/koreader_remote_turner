package com.example.koreader_remote_turner

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.koreader_remote_turner/service"
    private val EVENT_CHANNEL = "com.example.koreader_remote_turner/events"
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        BackgroundService.methodChannel = methodChannel

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val intent = Intent(this, BackgroundService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    BackgroundService.eventSink = eventSink
                    result.success(true)
                }
                "stopService" -> {
                    val intent = Intent(this, BackgroundService::class.java)
                    stopService(intent)
                    BackgroundService.eventSink = null
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).apply {
            setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    eventSink = events
                    BackgroundService.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    BackgroundService.eventSink = null
                }
            })
        }
    }
}
