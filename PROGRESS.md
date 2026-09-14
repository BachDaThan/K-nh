# 0.13.1 — Mesh native hoàn thiện bước 1–3

1. **CI**: job Android chạy `tool/ci_inject_mesh.sh` sau khi tạo `android/`
2. **MainActivity**: script tự `flutterEngine.plugins.add(MeshPlugin())`
3. **WFD**: ServerSocket text :47830 + audio :47831; group owner / client connect
4. **Call**: `VoiceCallSession` — AudioRecord 16k PCM → WFD → AudioTrack (1-hop)

Quyền: BLUETOOTH_*, NEARBY_WIFI_DEVICES, RECORD_AUDIO, FGS connectedDevice.

Runtime: user phải cấp quyền micro + nearby trên máy.
