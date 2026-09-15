package com.bachdathan.kinh.mesh

import android.app.*
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import io.flutter.plugin.common.EventChannel

class MeshForegroundService : Service() {
  companion object {
    const val ACTION_START = "kinh.mesh.START"
    const val CH_ID = "kinh_mesh"
    var instance: MeshForegroundService? = null
    var eventSink: EventChannel.EventSink? = null
  }

  private var publicId: String = ""
  private var displayName: String = ""
  private var ble: BleDiscovery? = null
  private var wfd: WifiDirectTransport? = null
  private var voice: VoiceCallSession? = null

  override fun onBind(intent: Intent?): IBinder? = null

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    if (intent?.action == ACTION_START) {
      publicId = intent.getStringExtra("publicId") ?: ""
      displayName = intent.getStringExtra("displayName") ?: ""
      startFg()
      instance = this
      ble = BleDiscovery(this) { peer ->
        emit(
          mapOf(
            "type" to "peer",
            "id" to peer.id,
            "name" to peer.name,
            "rssi" to peer.rssi,
            "transport" to "ble",
          )
        )
      }
      ble?.start(publicId, displayName)
      wfd = WifiDirectTransport(this).also { t ->
        t.init()
        t.onText = { msg ->
          // format T|name|text
          val parts = msg.split("|", limit = 3)
          if (parts.size >= 3 && parts[0] == "T") {
            emit(
              mapOf(
                "type" to "text",
                "fromId" to parts[1],
                "fromName" to parts[1],
                "text" to parts[2],
              )
            )
          }
        }
      }
    }
    return START_STICKY
  }

  private fun emit(map: Map<String, Any?>) {
    try {
      eventSink?.success(map)
    } catch (e: Exception) {
      Log.w("KinhMesh", "emit: $e")
    }
  }

  private fun startFg() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val nm = getSystemService(NotificationManager::class.java)
      nm.createNotificationChannel(
        NotificationChannel(CH_ID, "Kính Mesh", NotificationManager.IMPORTANCE_LOW)
      )
    }
    val n = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      Notification.Builder(this, CH_ID)
    } else {
      @Suppress("DEPRECATION")
      Notification.Builder(this)
    }
      .setContentTitle("Kính Mesh")
      .setContentText("BLE dò peer · WFD khi chat/call")
      .setSmallIcon(android.R.drawable.stat_sys_data_bluetooth)
      .build()
    startForeground(42, n)
  }

  fun broadcastText(text: String) {
    val payload = "T|$displayName|$text"
    wfd?.ensureGroupThen {
      wfd?.broadcastPayload(payload)
    }
    ble?.advertiseMessage(text)
  }

  fun sendText(peerId: String, text: String) {
    val payload = "T|$displayName|$text"
    wfd?.ensureGroupThen {
      wfd?.sendTo(peerId, payload)
    }
  }

  fun startCall(peerId: String) {
    val t = wfd ?: return
    t.ensureGroupThen {
      voice?.stop()
      voice = VoiceCallSession(t)
      voice?.start()
      emit(mapOf("type" to "call", "state" to "active", "peerId" to peerId))
    }
  }

  fun endCall() {
    voice?.stop()
    voice = null
    emit(mapOf("type" to "call", "state" to "ended"))
  }

  fun rescan() {
    ble?.stop()
    ble?.start(publicId, displayName)
    emit(mapOf("type" to "status", "state" to "scanning"))
  }

  override fun onDestroy() {
    voice?.stop()
    ble?.stop()
    wfd?.close()
    instance = null
    super.onDestroy()
  }
}
