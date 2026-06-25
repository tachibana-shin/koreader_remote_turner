package git.shin.koreader_remote_turner

import io.flutter.app.FlutterApplication
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.EventChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class RemoteTurnerApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()

        val engine = FlutterEngine(this)
        GeneratedPluginRegistrant.registerWith(engine)

        EventChannel(
            engine.dartExecutor.binaryMessenger,
            "git.shin.koreader_remote_turner/events",
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(
                arguments: Any?,
                events: EventChannel.EventSink,
            ) {
                EventBus.eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                EventBus.eventSink = null
            }
        })

        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )

        FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
    }

    companion object {
        const val ENGINE_ID = "remote_turner_engine"
    }
}
