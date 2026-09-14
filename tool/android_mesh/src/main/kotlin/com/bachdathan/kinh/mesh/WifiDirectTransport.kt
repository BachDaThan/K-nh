package com.bachdathan.kinh.mesh

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.p2p.WifiP2pConfig
import android.net.wifi.p2p.WifiP2pDevice
import android.net.wifi.p2p.WifiP2pInfo
import android.net.wifi.p2p.WifiP2pManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.io.DataInputStream
import java.io.DataOutputStream
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.net.Socket
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Wi‑Fi Direct: ServerSocket (group owner) / client socket.
 * Port TEXT=47830, AUDIO=47831.
 */
class WifiDirectTransport(private val context: Context) {
  companion object {
    private const val TAG = "KinhWfd"
    const val PORT_TEXT = 47830
    const val PORT_AUDIO = 47831
  }

  private val manager =
    context.getSystemService(Context.WIFI_P2P_SERVICE) as? WifiP2pManager
  private val channel: WifiP2pManager.Channel? =
    manager?.initialize(context, Looper.getMainLooper(), null)
  private val io = Executors.newCachedThreadPool()
  private val main = Handler(Looper.getMainLooper())

  @Volatile private var groupOwner = false
  @Volatile private var groupIp: String? = null
  private var textServer: ServerSocket? = null
  private var audioServer: ServerSocket? = null
  private var textSocket: Socket? = null
  private var audioSocket: Socket? = null

  var onText: ((String) -> Unit)? = null
  var onAudioFrame: ((ByteArray) -> Unit)? = null
  var onReady: (() -> Unit)? = null

  private val receiver = object : BroadcastReceiver() {
    override fun onReceive(ctx: Context?, intent: Intent?) {
      when (intent?.action) {
        WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION -> {
          manager?.requestConnectionInfo(channel) { info ->
            handleConnectionInfo(info)
          }
        }
      }
    }
  }

  fun init() {
    try {
      val f = IntentFilter().apply {
        addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
        addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
        addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION)
      }
      context.registerReceiver(receiver, f)
    } catch (e: Exception) {
      Log.w(TAG, "registerReceiver: $e")
    }
  }

  fun ensureGroupThen(block: () -> Unit) {
    val m = manager
    val c = channel
    if (m == null || c == null) {
      main.post(block)
      return
    }
    if (groupIp != null) {
      main.post(block)
      return
    }
    m.createGroup(c, object : WifiP2pManager.ActionListener {
      override fun onSuccess() {
        Log.i(TAG, "createGroup ok")
        m.requestConnectionInfo(c) { info ->
          handleConnectionInfo(info)
          main.post(block)
        }
      }

      override fun onFailure(reason: Int) {
        Log.w(TAG, "createGroup fail $reason — try request peers / connect")
        m.discoverPeers(c, object : WifiP2pManager.ActionListener {
          override fun onSuccess() {
            main.post(block)
          }

          override fun onFailure(r: Int) {
            main.post(block)
          }
        })
      }
    })
  }

  private fun handleConnectionInfo(info: WifiP2pInfo?) {
    if (info == null || !info.groupFormed) return
    groupOwner = info.isGroupOwner
    groupIp = info.groupOwnerAddress?.hostAddress
    Log.i(TAG, "group formed owner=$groupOwner ip=$groupIp")
    if (groupOwner) {
      startServers()
    }
    onReady?.invoke()
  }

  private fun startServers() {
    io.execute {
      try {
        textServer?.close()
        textServer = ServerSocket(PORT_TEXT)
        while (!textServer!!.isClosed) {
          val s = textServer!!.accept()
          textSocket = s
          pumpTextIn(s)
        }
      } catch (e: Exception) {
        Log.w(TAG, "textServer: $e")
      }
    }
    io.execute {
      try {
        audioServer?.close()
        audioServer = ServerSocket(PORT_AUDIO)
        while (!audioServer!!.isClosed) {
          val s = audioServer!!.accept()
          audioSocket = s
          pumpAudioIn(s)
        }
      } catch (e: Exception) {
        Log.w(TAG, "audioServer: $e")
      }
    }
  }

  fun connectToAddress(host: String, then: (() -> Unit)? = null) {
    io.execute {
      try {
        val ts = Socket()
        ts.connect(InetSocketAddress(host, PORT_TEXT), 8000)
        textSocket = ts
        pumpTextIn(ts)
        val asock = Socket()
        asock.connect(InetSocketAddress(host, PORT_AUDIO), 8000)
        audioSocket = asock
        pumpAudioIn(asock)
        main.post { then?.invoke() }
      } catch (e: Exception) {
        Log.w(TAG, "connectToAddress: $e")
        main.post { then?.invoke() }
      }
    }
  }

  private fun pumpTextIn(s: Socket) {
    io.execute {
      try {
        val input = DataInputStream(s.getInputStream())
        while (!s.isClosed) {
          val len = input.readInt()
          if (len <= 0 || len > 1_000_000) break
          val buf = ByteArray(len)
          input.readFully(buf)
          val msg = String(buf, Charsets.UTF_8)
          main.post { onText?.invoke(msg) }
        }
      } catch (e: Exception) {
        Log.w(TAG, "pumpTextIn: $e")
      }
    }
  }

  private fun pumpAudioIn(s: Socket) {
    io.execute {
      try {
        val input = DataInputStream(s.getInputStream())
        while (!s.isClosed) {
          val len = input.readInt()
          if (len <= 0 || len > 64_000) break
          val buf = ByteArray(len)
          input.readFully(buf)
          onAudioFrame?.invoke(buf)
        }
      } catch (e: Exception) {
        Log.w(TAG, "pumpAudioIn: $e")
      }
    }
  }

  fun broadcastPayload(payload: String) {
    sendRaw(textSocket, payload.toByteArray(Charsets.UTF_8))
  }

  fun sendTo(peerId: String, payload: String) {
    // peerId reserved for multi-peer map; phase1 single socket
    broadcastPayload(payload)
  }

  fun sendAudioFrame(frame: ByteArray) {
    sendRaw(audioSocket, frame)
  }

  private fun sendRaw(socket: Socket?, data: ByteArray) {
    val s = socket ?: return
    io.execute {
      try {
        val out = DataOutputStream(s.getOutputStream())
        synchronized(s) {
          out.writeInt(data.size)
          out.write(data)
          out.flush()
        }
      } catch (e: Exception) {
        Log.w(TAG, "sendRaw: $e")
      }
    }
  }

  fun teardownCall() {
    try {
      audioSocket?.close()
    } catch (_: Exception) {
    }
    audioSocket = null
  }

  fun close() {
    try {
      context.unregisterReceiver(receiver)
    } catch (_: Exception) {
    }
    try {
      textServer?.close()
      audioServer?.close()
      textSocket?.close()
      audioSocket?.close()
    } catch (_: Exception) {
    }
    try {
      manager?.removeGroup(channel, null)
    } catch (_: Exception) {
    }
  }
}
