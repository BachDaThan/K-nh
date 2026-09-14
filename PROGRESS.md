# Tiến độ dự án Kính

> Repo: https://github.com/BachDaThan/K-nh · Version app: **0.13.1+**
> File PROGRESS cũ “Bước 1/6” **đã lỗi thời** — đối chiếu bảng dưới.

## Tổng quan 6 bước gốc

| Bước | Nội dung | Trạng thái |
|------|----------|------------|
| **1** | Dashboard Bento, theme, CI APK+EXE, Releases | ✅ |
| **2** | Trình duyệt WebView, Omnibox, Tab, Bookmark, DoH, Search Diversity | ✅ |
| **3** | History, Activity Log, Incognito, dọn cookie/cache, Safe Browsing 3 mức | ✅ |
| **4** | AI Builder, sandbox code (Pyodide/WebView), API key cá nhân | ✅ |
| **5** | Backup local, Google Drive sync, OTA/version.json, Privacy Policy link | ✅ (Drive/Auth cần cấu hình user) |
| **6** | App Launcher ghim app, Sidebar, Theme system | ✅ |

## Mở rộng đã có trên `main`

| Module | Trạng thái | Ghi chú |
|--------|------------|---------|
| Reader / TTS / tủ sách TXT | ✅ | |
| Audio truyện (link + TTS + nhạc nền) | ✅ | |
| Ad-block nhẹ + reader mode + find-in-page | ✅ | |
| Edition Core / Plus (`KINH_EDITION`) | ✅ | CI dual APK |
| Cộng đồng Firebase (global/topic/page/DM/presence) | ✅ code | Cần SHA-1 + Web client ID Google |
| Chat gần offline (LAN/hotspot UDP) | ✅ | Không internet, cùng Wi‑Fi/hotspot |
| Premium Mesh BLE+WFD + call 1-hop | ✅ scaffold + CI inject | Runtime cần quyền BT/micro; multi-hop voice **không** cam kết |
| Live weather / Wi‑Fi cards | ✅ | |
| Notes | ✅ | |
| Low-end mode | ✅ | |

## Việc **user** còn phải làm (không tự code được)

1. **Firebase Google Sign-In**
   - Thêm SHA-1 keystore release vào Firebase app `com.bachdathan.kinh`
   - Bật Authentication → Google
   - Điền **Web client ID** vào `lib/chat/google_auth_config.dart`
2. **Rules RTDB** (file hướng dẫn `FIREBASE_CHAT_SETUP.md` / rules v2)
3. **Secrets CI** ký APK: `KEYSTORE_*` (nếu chưa)
4. Cấp quyền runtime: Bluetooth, Nearby, Micro (mesh/call)

## Không làm / roadmap (có chủ đích)

- GeckoView production (đã thử — conflict plugin)
- Silent install
- Mesh “2–4 km chỉ ĐT” / voice nhiều hop ổn định
- Mesh “không dấu vết” qua máy không cài app
- Commit thư mục `android/` / `windows/` (CI `flutter create` mỗi lần)

## Quyết định giữ nguyên

- Không viết tay Gradle; CI sinh `android/` + `windows/`
- Client-side, GitHub Actions + Releases
- Engine: System WebView (Android) / WebView2 (Windows) qua `BrowserEngine`

## Cách lấy bản cài

Actions xanh → Releases → `Kinh.apk` / `Kinh-Windows.zip` (và Plus nếu có).
