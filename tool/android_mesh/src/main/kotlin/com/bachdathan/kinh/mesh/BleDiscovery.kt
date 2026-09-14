package com.bachdathan.kinh.mesh

import android.bluetooth.BluetoothAdapter
import android.bluetooth.le.*
import android.content.Context
import android.os.ParcelUuid
import java.util.UUID

data class BlePeer(val id: String, val name: String, val rssi: Int)

/**
 * BLE quét + advertise service UUID Kính — discovery tiết kiệm pin.
 * Truyền text lớn / call → bàn giao Wi‑Fi Direct.
 */
class BleDiscovery(
  private val context: Context,
  private val onPeer: (BlePeer) -> Unit,
) {
  companion object {
    val SERVICE_UUID: UUID = UUID.fromString("6ba7b810-9dad-11d1-80b4-00c04fd430c8")
  }

  private val adapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
  private var scanner: BluetoothLeScanner? = null
  private var advertiser: BluetoothLeAdvertiser? = null

  fun start(publicId: String, displayName: String) {
    val a = adapter ?: return
    if (!a.isEnabled) return
    scanner = a.bluetoothLeScanner
    advertiser = a.bluetoothLeAdvertiser
    val settings = ScanSettings.Builder()
      .setScanMode(ScanSettings.SCAN_MODE_LOW_POWER)
      .build()
    val filter = ScanFilter.Builder()
      .setServiceUuid(ParcelUuid(SERVICE_UUID))
      .build()
    try {
      scanner?.startScan(listOf(filter), settings, scanCb)
    } catch (_: SecurityException) {
    }
    val data = AdvertiseData.Builder()
      .addServiceUuid(ParcelUuid(SERVICE_UUID))
      .addServiceData(ParcelUuid(SERVICE_UUID), publicId.toByteArray(Charsets.UTF_8).copyOf(16))
      .setIncludeDeviceName(false)
      .build()
    val advSettings = AdvertiseSettings.Builder()
      .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
      .setConnectable(true)
      .setTimeout(0)
      .build()
    try {
      advertiser?.startAdvertising(advSettings, data, advCb)
    } catch (_: SecurityException) {
    }
  }

  fun advertiseMessage(text: String) {
    // Short beacon only — bulk via WFD
  }

  fun stop() {
    try {
      scanner?.stopScan(scanCb)
    } catch (_: Exception) {
    }
    try {
      advertiser?.stopAdvertising(advCb)
    } catch (_: Exception) {
    }
  }

  private val scanCb = object : ScanCallback() {
    override fun onScanResult(callbackType: Int, result: ScanResult) {
      val id = result.scanRecord?.serviceData?.values?.firstOrNull()
        ?.toString(Charsets.UTF_8)?.trim() ?: result.device.address
      val name = result.device.name ?: id.take(8)
      onPeer(BlePeer(id, name, result.rssi))
    }
  }

  private val advCb = object : AdvertiseCallback() {}
}
