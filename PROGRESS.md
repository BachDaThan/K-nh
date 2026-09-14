# 0.13.0 — Premium Hybrid Mesh (scaffold)

## Đã giao
- Kiến trúc BLE discovery + Wi‑Fi Direct bulk/call (docs)
- Flutter: PremiumMeshScreen, mode Auto/Sinh tồn, MethodChannel
- Kotlin: MeshForegroundService, BleDiscovery, WifiDirectTransport (stub logic đầy đủ API)
- CI script `tool/ci_inject_mesh.sh` copy native sau flutter create
- Fallback: Chat gần LAN nếu native chưa inject

## Thẳng thắn
- Call offline: thiết kế **1-hop WFD**; multi-hop voice không ổn định
- Tầm 2–4 km chỉ ĐT: **không cam kết** (cần LoRa/Meshtastic)
- E2E Noise + audio Opus pipeline: phase tiếp

## Giữ nguyên
- Bản chuẩn/Plus: browser, Firebase chat, LAN mesh, reader…
