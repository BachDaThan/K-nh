# Kiến trúc Chat: Online + Offline (chuẩn / Plus / Premium)

## Ba lớp

```
┌─────────────────────────────────────────────────────────┐
│  Flutter UI (Dashboard, Browser, Cộng đồng, Mesh…)      │
├──────────────────┬──────────────────────────────────────┤
│ Firebase online  │  Offline local (chuẩn+Plus)          │
│ Google Auth      │  Ed25519 identity + UDP LAN/hotspot  │
│ RTDB rooms       │  Không internet, cùng Wi‑Fi/hotspot  │
├──────────────────┴──────────────────────────────────────┤
│  Premium phase 2 (chưa ship): Kotlin BLE mesh multi-hop │
│  MethodChannel KinhMesh · optional Native UI “Sinh tồn” │
└─────────────────────────────────────────────────────────┘
```

## Vì sao chưa “đóng băng Flutter → Native 100%” ngay

- CI Kính **xóa `android/` mỗi build** (`flutter create`) → native BLE service phải inject từ `tool/android_mesh/`.
- Full Bitchat (GATT dual role + flood TTL + Noise) = dự án native riêng, nhiều tháng.
- **Chuẩn + Plus** giữ Firebase + browser + mesh LAN rút gọn (ship được ngay).

## Chế độ người dùng (hiện tại)

| Mode | Hành vi |
|------|---------|
| Online | Firebase như cũ |
| Chat gần offline | UDP broadcast LAN/hotspot, identity local, không Google |
| Premium Sinh tồn | Roadmap: Activity/Service Kotlin + UI tối giản |

## Sửa CONFIGURATION_NOT_FOUND

1. Firebase → Project settings → app Android `com.bachdathan.kinh` → **Add SHA-1** (keystore release + debug).
2. Authentication → Sign-in method → **Google → Enable**.
3. Cùng trang Google → copy **Web client ID** → `lib/chat/google_auth_config.dart`.
4. (Khuyến nghị) Tải `google-services.json` — CI có thể inject từ secret sau.

Lấy SHA-1 release:
`keytool -list -v -keystore kinh-release.jks -alias <alias>`
