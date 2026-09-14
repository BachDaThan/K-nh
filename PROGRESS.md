# Tiến độ & triết lý dự án Kính

> Repo: https://github.com/BachDaThan/K-nh  
> Version code gần nhất trên `main`: xem `pubspec.yaml` / `version.json`  
> **Đọc file này trước** khi dùng app hoặc nhờ AI làm tiếp — tránh hiểu lầm.

---

## 1. Triết lý gốc (không đổi)

1. **Ưu tiên trên máy (local-first):** lịch sử, bookmark, ghi chú, cài đặt, mesh offline lưu/xử lý trên thiết bị.
2. **Không server riêng của Kính:** không vận hành backend thu phí / thu thập hộ user.
3. **Hạ tầng build miễn phí:** GitHub Actions → Releases (`Kinh.apk`, `Kinh-Windows.zip`).
4. **Không silent-install:** chỉ tải bản mới + **hỏi user xác nhận cài**.
5. **Flutter native** Android + Windows — không đổi sang React/PWA wrapper thay app.
6. **Minh bạch:** tính năng nào **bắt buộc cloud / Google** phải ghi rõ (dưới đây + PRIVACY.md).

---

## 2. Phân loại tính năng (tránh hiểu nhầm)

### A. Local / offline — đúng triết lý gốc

| Tính năng | Ghi chú |
|-----------|---------|
| Trình duyệt (WebView), tab, Omnibox, bookmark | Dữ liệu local |
| DoH (chọn resolver), Search Diversity | Tuỳ cấu hình máy |
| History, Activity Log, ẩn danh | Local |
| Safe Browsing **danh sách local** (3 mức) | **Không** phải Google Safe Browsing API đầy đủ |
| Ad-block nhẹ, reader, find-in-page | Local |
| Reader / TTS / tủ sách | Local |
| Audio truyện + nhạc nền | Local |
| Notes, theme, launcher ghim app | Local |
| Backup file trên máy | Local |
| OTA: kiểm tra `version.json`, tải APK, **user bấm cài** | Không cài ngầm |
| **Chat gần (LAN/hotspot UDP)** | Cùng Wi‑Fi/hotspot, **không cần internet** |
| **Premium Mesh BLE + Wi‑Fi Direct + gọi 1-hop** | P2P; cần quyền BT/micro; **không** cam kết tầm km |

### B. Tuỳ chọn cloud — **không bắt buộc**, lệch “100% chỉ local”

| Tính năng | Phụ thuộc | Ghi chú quan trọng |
|-----------|-----------|-------------------|
| **Cộng đồng** (chat thế giới / chủ đề / theo trang / DM / online) | **Firebase + Google Sign-In** | Tin nhắn nằm trên Firebase **project của nhà phát triển**; cần SHA-1 + Web client ID |
| **Google Drive sync** | Tài khoản Google | User chủ động bật / chọn file |

→ App **vẫn dùng được** phần A nếu **không** đăng nhập Google / không bật Drive.

### C. Không làm / không hứa (để khỏi hiểu lầm marketing)

- Silent install / cài đè không hỏi  
- GeckoView production thay Chromium (đã thử, chưa chín trên pipeline này)  
- Mesh “2–4 km / 7 hop chỉ điện thoại” như cam kết sản phẩm  
- Gọi thoại **nhiều hop** mượt như 1-hop  
- Truyền tin qua máy **không cài app** / “không dấu vết”  
- Internet “ké” 4G của máy khác qua app (không có phần cứng LoRa/gateway)

---

## 3. Trạng thái 6 bước gốc

| Bước | Nội dung | Trạng thái |
|------|----------|------------|
| 1 | Dashboard, CI APK+EXE, Releases | ✅ |
| 2 | Browser, DoH, tab, bookmark… | ✅ |
| 3 | History, activity, ẩn danh, safe browse local | ✅ |
| 4 | AI Builder (key **của user**) | ✅ |
| 5 | Backup, Drive **tuỳ chọn**, OTA, Privacy | ✅ code — Drive/Auth cần user cấu hình |
| 6 | Launcher, sidebar, theme | ✅ |

**Edition:** Core (`com.bachdathan.kinh`) và Plus (`KINH_EDITION=plus`) — cùng triết lý; Plus không biến app thành sản phẩm “bắt buộc Google”.

---

## 4. Việc user cần tự làm (nếu muốn cloud)

1. Firebase: bật Google Sign-In, thêm **SHA-1** keystore, Web client ID → `lib/chat/google_auth_config.dart`  
2. Rules RTDB theo `FIREBASE_CHAT_SETUP.md`  
3. Secrets CI ký APK (nếu dùng release key)  
4. Quyền runtime: Bluetooth / Nearby / Micro (mesh & gọi)

Không làm các bước trên → **vẫn dùng browser + local + chat LAN/mesh (nếu APK có native inject)**.

---

## 5. Quy ước cập nhật tài liệu

Mỗi lần đổi tính năng lớn trên `main`, **bắt buộc** cập nhật:

- `PROGRESS.md` (bảng local vs cloud + không hứa gì)  
- `PRIVACY.md` (dữ liệu nào rời máy)  
- `version.json` + `pubspec.yaml` version  

---

## 6. Lấy bản cài

GitHub → **Actions** (xanh) → **Releases** → `Kinh.apk` / `Kinh-Windows.zip` (và Plus nếu có).
