package git.shin.koreader_remote_turner

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

object EventBus {
    var methodChannel: MethodChannel? = null
    var eventSink: EventChannel.EventSink? = null
        set(value) {
            field = value
            if (value != null) {
                flushEventQueue()
            }
        }
    private val eventQueue = mutableListOf<String>()

    fun sendEvent(event: String) {
        methodChannel?.invokeMethod("volumeKeyPressed", event)
    }

    private fun flushEventQueue() {
        synchronized(eventQueue) {
            for (event in eventQueue) {
                eventSink?.success(event)
            }
            eventQueue.clear()
        }
    }
}
