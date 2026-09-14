# Kính Premium — Hybrid Mesh (BLE + Wi‑Fi Direct) + Call

## Phạm vi thực tế (không phóng đại marketing)

| Liên kết | Tầm thực tế ĐT consumer | Phù hợp |
|----------|-------------------------|---------|
| BLE discovery | ~10–50 m trong nhà | Dò peer, tin ngắn, tiết kiệm pin |
| Wi‑Fi Direct 1 hop | ~30–100 m (hiếm khi 200–300 m thoáng) | Text dài, ảnh, **voice 1-hop** |
| Mesh nhiều hop (text) | Mở rộng theo số máy **cùng app** | Text/relay; **không** gọi voice ổn định |
| “2–4 km / 7 hop” chỉ ĐT | **Không đảm bảo** | Cần LoRa/Meshtastic + HW ngoài |

Gọi voice: **ưu tiên 1 hop WFD**. Multi-hop voice = lag/đứt — không ship như tính năng chính.

## Sơ đồ kiến trúc

```
                    ┌──────────────────────────────┐
                    │     Flutter UI (Premium)      │
                    │  Mode: Auto | Survival        │
                    └───────────┬──────────────────┘
                                │ MethodChannel "kinh_mesh"
              ┌─────────────────┴─────────────────┐
              ▼                                   ▼
     ┌────────────────┐                 ┌─────────────────────┐
     │ Firebase stack │                 │ Android Mesh Core   │
     │ (khi có net)   │                 │ Kotlin Service      │
     └────────────────┘                 │  BLE scanner        │
                                        │  WFD session        │
                                        │  Room DB offline    │
                                        │  RTP/Opus voice     │
                                        └──────────┬──────────┘
                                                   │
                              ┌────────────────────┼────────────────────┐
                              ▼                    ▼                    ▼
                         BLE ads/GATT          Wi‑Fi Direct          1-hop
                         peer map              bulk + call           audio
```

## Dual mode

| Mode | Hành vi |
|------|---------|
| **Auto** | Flutter + Firebase khi online; BLE quét nhẹ (optional); mesh text qua channel |
| **Survival** | Ẩn tab nặng (WebView/Firebase pause); UI mesh tối giản Flutter **hoặc** Activity native; dồn BLE+WFD |

“Đóng băng Flutter hoàn toàn” = Activity native riêng — phase 2b; phase 1 = Flutter shell nhẹ + native service.

## Module code

- `tool/android_mesh/` — Kotlin `MeshForegroundService`, `BleDiscovery`, `WifiDirectTransport`
- Flutter `KinhMeshChannel` — start/stop, peers, sendText, startCall
- CI: sau `flutter create`, copy `tool/android_mesh` vào `android/app/src/main/kotlin/...` + khai báo service trong Manifest (script)

## Bảo mật

- Ed25519 identity trên máy (đã có `MeshIdentity`)
- E2E full Noise/X25519 per session = phase 2; phase 1: payload ký + optional encrypt khi có pubkey peer
