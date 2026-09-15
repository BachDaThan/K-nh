package com.bachdathan.kinh.mesh

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class MeshPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler,
  ActivityAware, PluginRegistry.RequestPermissionsResultListener {

  private lateinit var channel: MethodChannel
  private lateinit var events: EventChannel
  private var eventSink: EventChannel.EventSink? = null
  private var appContext: android.content.Context? = null
  private var activity: Activity? = null
  private var pendingStart: Pair<String, String>? = null

  companion object {
    private const val REQ_PERMS = 7713
  }

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

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
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
        if (!hasAllPerms(ctx)) {
          pendingStart = id to name
          requestPerms()
          result.success(mapOf("status" to "requesting_permissions"))
          return
        }
        startService(ctx, id, name)
        result.success(mapOf("status" to "started"))
      }
      "stop" -> {
        ctx?.stopService(Intent(ctx, MeshForegroundService::class.java))
        result.success(null)
      }
      "scan" -> {
        MeshForegroundService.instance?.rescan()
        result.success(null)
      }
      "broadcastText" -> {
        MeshForegroundService.instance?.broadcastText(call.argument<String>("text") ?: "")
        result.success(null)
      }
      "sendText" -> {
        MeshForegroundService.instance?.sendText(
          call.argument<String>("peerId") ?: "",
          call.argument<String>("text") ?: "",
        )
        result.success(null)
      }
      "startCall" -> {
        MeshForegroundService.instance?.startCall(call.argument<String>("peerId") ?: "")
        result.success(null)
      }
      "endCall" -> {
        MeshForegroundService.instance?.endCall()
        result.success(null)
      }
      else -> result.notImplemented()
    }
  }

  private fun startService(ctx: android.content.Context, id: String, name: String) {
    val i = Intent(ctx, MeshForegroundService::class.java).apply {
      action = MeshForegroundService.ACTION_START
      putExtra("publicId", id)
      putExtra("displayName", name)
    }
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      ctx.startForegroundService(i)
    } else {
      @Suppress("DEPRECATION")
      ctx.startService(i)
    }
    MeshForegroundService.eventSink = eventSink
  }

  private fun neededPerms(): Array<String> {
    val list = mutableListOf<String>()
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      list += Manifest.permission.BLUETOOTH_SCAN
      list += Manifest.permission.BLUETOOTH_CONNECT
      list += Manifest.permission.BLUETOOTH_ADVERTISE
    } else {
      list += Manifest.permission.ACCESS_FINE_LOCATION
      list += Manifest.permission.BLUETOOTH
      list += Manifest.permission.BLUETOOTH_ADMIN
    }
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      list += Manifest.permission.NEARBY_WIFI_DEVICES
      list += Manifest.permission.POST_NOTIFICATIONS
    }
    return list.toTypedArray()
  }

  private fun hasAllPerms(ctx: android.content.Context): Boolean {
    return neededPerms().all {
      ContextCompat.checkSelfPermission(ctx, it) == PackageManager.PERMISSION_GRANTED
    }
  }

  private fun requestPerms() {
    val act = activity ?: return
    ActivityCompat.requestPermissions(act, neededPerms(), REQ_PERMS)
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray,
  ): Boolean {
    if (requestCode != REQ_PERMS) return false
    val ctx = appContext ?: return true
    val ok = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
    val pending = pendingStart
    pendingStart = null
    if (ok && pending != null) {
      startService(ctx, pending.first, pending.second)
      eventSink?.success(mapOf("type" to "status", "state" to "started"))
    } else {
      eventSink?.success(
        mapOf(
          "type" to "error",
          "message" to "Thiếu quyền Bluetooth/Nearby — cấp trong Cài đặt ứng dụng",
        )
      )
    }
    return true
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
    MeshForegroundService.eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }
}
