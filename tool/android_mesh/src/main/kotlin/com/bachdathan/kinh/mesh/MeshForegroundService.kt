package com.bachdathan.kinh.mesh

import android.app.*
import android.content.Intent
import android.os.Build
import android.os.IBinder
import io.flutter.plugin.common.EventChannel

/**
 * Service quản lý BLE discovery (pin thấp) + Wi‑Fi Direct khi cần bulk/call.
 * Phase 1: khung + event giả lập peer local; BLE/WFD API đầy đủ gắn dần.
 */
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

  override fun onBind(intent: Intent?): IBinder? = null

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    if (intent?.action == ACTION_START) {
      publicId = intent.getStringExtra("publicId") ?: ""
      displayName = intent.getStringExtra("displayName") ?: ""
      startFg()
      instance = this
      ble = BleDiscovery(this) { peer ->
        eventSink?.success(
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
      wfd = WifiDirectTransport(this)
      wfd?.init()
    }
    return START_STICKY
  }

  private fun startFg() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val nm = getSystemService(NotificationManager::class.java)
      nm.createNotificationChannel(
        NotificationChannel(CH_ID, "Kính Mesh", NotificationManager.IMPORTANCE_LOW)
      )
    }
    val n = Notification.Builder(this, CH_ID)
      .setContentTitle("Kính Mesh")
      .setContentText("BLE đang dò peer · WFD khi cần")
      .setSmallIcon(android.R.drawable.stat_sys_data_bluetooth)
      .build()
    startForeground(42, n)
  }

  fun broadcastText(text: String) {
    // Phase 1: gửi qua WFD nếu có group, else BLE characteristic notify (stub)
    wfd?.broadcastPayload("T|$displayName|$text")
    ble?.advertiseMessage(text)
  }

  fun sendText(peerId: String, text: String) {
    wfd?.sendTo(peerId, "T|$displayName|$text")
  }

  fun startCall(peerId: String) {
    // 1-hop WFD + audio session placeholder
    wfd?.ensureGroupThen {
      eventSink?.success(mapOf("type" to "call", "state" to "active", "peerId" to peerId))
      // TODO: AudioRecord → encrypt → WFD socket; reverse play
    }
  }

  fun endCall() {
    wfd?.teardownCall()
    eventSink?.success(mapOf("type" to "call", "state" to "ended"))
  }

  override fun onDestroy() {
    ble?.stop()
    wfd?.close()
    instance = null
    super.onDestroy()
  }
}
