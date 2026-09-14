package com.bachdathan.kinh.mesh

import android.content.Context
import android.net.wifi.p2p.WifiP2pManager
import android.os.Looper

/**
 * Wi‑Fi Direct: bulk text/file + 1-hop voice socket.
 * Kích hoạt khi cần, teardown để tiết kiệm pin.
 */
class WifiDirectTransport(private val context: Context) {
  private val manager = context.getSystemService(Context.WIFI_P2P_SERVICE) as? WifiP2pManager
  private val channel: WifiP2pManager.Channel? =
    manager?.initialize(context, Looper.getMainLooper(), null)

  fun init() {
    // Register broadcast receivers in full implementation
  }

  fun ensureGroupThen(block: () -> Unit) {
    // createGroup / connect — simplified: invoke callback
    block()
  }

  fun broadcastPayload(payload: String) {
    // ServerSocket on group owner — phase 1 stub
  }

  fun sendTo(peerId: String, payload: String) {
    // Connect + socket write
  }

  fun teardownCall() {
    // close audio sockets
  }

  fun close() {
    try {
      manager?.removeGroup(channel, null)
    } catch (_: Exception) {
    }
  }
}
