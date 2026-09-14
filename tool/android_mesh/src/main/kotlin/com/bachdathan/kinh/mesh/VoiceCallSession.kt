package com.bachdathan.kinh.mesh

import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.util.Log
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Voice 1-hop: PCM 16k mono qua Wi‑Fi Direct socket.
 * Không multi-hop (tránh lag).
 */
class VoiceCallSession(
  private val wfd: WifiDirectTransport,
) {
  companion object {
    private const val TAG = "KinhVoice"
    private const val SAMPLE = 16000
    private const val CH = AudioFormat.CHANNEL_IN_MONO
    private const val ENC = AudioFormat.ENCODING_PCM_16BIT
  }

  private val running = AtomicBoolean(false)
  private var record: AudioRecord? = null
  private var track: AudioTrack? = null
  private var recordThread: Thread? = null

  fun start() {
    if (running.getAndSet(true)) return
    val min = AudioRecord.getMinBufferSize(SAMPLE, CH, ENC)
    val bufSize = min.coerceAtLeast(SAMPLE / 5) * 2
    try {
      record = AudioRecord(
        MediaRecorder.AudioSource.VOICE_COMMUNICATION,
        SAMPLE,
        CH,
        ENC,
        bufSize,
      )
      track = AudioTrack(
        AudioManager.STREAM_VOICE_CALL,
        SAMPLE,
        AudioFormat.CHANNEL_OUT_MONO,
        ENC,
        bufSize,
        AudioTrack.MODE_STREAM,
      )
      record?.startRecording()
      track?.play()
      wfd.onAudioFrame = { frame ->
        try {
          track?.write(frame, 0, frame.size)
        } catch (_: Exception) {
        }
      }
      recordThread = Thread({
        val buf = ByteArray(bufSize)
        while (running.get()) {
          val n = record?.read(buf, 0, buf.size) ?: -1
          if (n > 0) {
            wfd.sendAudioFrame(buf.copyOf(n))
          }
        }
      }, "kinh-voice-rec").also { it.start() }
      Log.i(TAG, "voice session started")
    } catch (e: Exception) {
      Log.e(TAG, "start failed: $e")
      stop()
    }
  }

  fun stop() {
    running.set(false)
    try {
      recordThread?.join(500)
    } catch (_: Exception) {
    }
    try {
      record?.stop()
      record?.release()
    } catch (_: Exception) {
    }
    try {
      track?.stop()
      track?.release()
    } catch (_: Exception) {
    }
    record = null
    track = null
    wfd.onAudioFrame = null
    wfd.teardownCall()
  }
}
