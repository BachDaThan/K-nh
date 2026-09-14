package com.bachdathan.kinh.mesh

import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter plugin bridge — đăng ký trong MainActivity khi CI gắn mesh.
 * Channel: com.bachdathan.kinh/mesh
 */
class MeshPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
  private lateinit var channel: MethodChannel
  private lateinit var events: EventChannel
  private var eventSink: EventChannel.EventSink? = null
  private var appContext: android.content.Context? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    appContext = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "com.bachdathan.kinh/mesh")
    channel.setMethodCallHandler(this)
    events = EventChannel(binding.binaryMessenger, "com.bachdathan.kinh/mesh_events")
    events.setStreamHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    events.setStreamHandler(null)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    val ctx = appContext
    when (call.method) {
      "isAvailable" -> result.success(true)
      "start" -> {
        if (ctx == null) {
          result.error("ctx", "no context", null)
          return
        }
        val id = call.argument<String>("publicId") ?: "X"
        val name = call.argument<String>("displayName") ?: "User"
        val i = Intent(ctx, MeshForegroundService::class.java).apply {
          action = MeshForegroundService.ACTION_START
          putExtra("publicId", id)
          putExtra("displayName", name)
        }
        ctx.startForegroundService(i)
        MeshForegroundService.eventSink = eventSink
        result.success(null)
      }
      "stop" -> {
        ctx?.stopService(Intent(ctx, MeshForegroundService::class.java))
        result.success(null)
      }
      "broadcastText" -> {
        val text = call.argument<String>("text") ?: ""
        MeshForegroundService.instance?.broadcastText(text)
        result.success(null)
      }
      "sendText" -> {
        val peer = call.argument<String>("peerId") ?: ""
        val text = call.argument<String>("text") ?: ""
        MeshForegroundService.instance?.sendText(peer, text)
        result.success(null)
      }
      "startCall" -> {
        val peer = call.argument<String>("peerId") ?: ""
        MeshForegroundService.instance?.startCall(peer)
        result.success(null)
      }
      "endCall" -> {
        MeshForegroundService.instance?.endCall()
        result.success(null)
      }
      else -> result.notImplemented()
    }
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
    MeshForegroundService.eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }
}
