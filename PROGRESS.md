# Tiến độ & triết lý dự án Kính

> Repo: https://github.com/BachDaThan/K-nh  
> Version gần nhất: xem `pubspec.yaml` / `version.json` trên nhánh `main`  
> Đọc file này + `PRIVACY.md` + `FAQ.md` trước khi dùng app hoặc nhờ AI làm tiếp.

---

## 1. Triết lý gốc (không đổi)

1. **Ưu tiên trên máy (local-first):** lịch sử, bookmark, ghi chú, cài đặt, mesh/LAN offline lưu và xử lý trên thiết bị.
2. **Không server riêng của “Kính Inc.”:** không vận hành backend thu phí hay thu thập hộ toàn bộ user.
3. **Hạ tầng build miễn phí:** GitHub Actions → GitHub Releases (`Kinh.apk`, `Kinh-Windows.zip`, bản Plus nếu có).
4. **Không silent-install:** có bản mới → tải → **user xác nhận cài**.
5. **Flutter native** Android + Windows — không thay app bằng React/PWA wrapper.
6. **Minh bạch:** tính năng nào đụng **Google / Firebase / Drive** phải ghi rõ là **tuỳ chọn**, không bắt buộc để duyệt web.

**Quy ước tài liệu:** mỗi lần sửa code lớn **không được** thay `PROGRESS.md` / `PRIVACY.md` / `FAQ.md` bằng bản chỉ vài dòng. Chỉ **bổ sung** mục version mới trên nền bản đầy đủ.

---

## 2. Phân loại tính năng (tránh hiểu nhầm)

### A. Local / offline — đúng triết lý gốc

| Tính năng | Ghi chú |
|-----------|---------|
| Trình duyệt (System WebView / WebView2), tab, Omnibox, bookmark | Dữ liệu local |
| DoH (chọn resolver), Search Diversity | Tuỳ cấu hình trên máy |
| History, Activity Log, chế độ ẩn danh | Local |
| Safe Browsing **danh sách / heuristic local** (3 mức) | **Không** đồng nghĩa Google Safe Browsing API đầy đủ |
| Ad-block nhẹ, reader mode, find-in-page | Local |
| Reader / TTS / tủ sách | Local |
| Audio truyện + nhạc nền | Local |
| Notes, theme, launcher ghim app hệ thống | Local |
| Backup file trên máy | Local |
| **Xuất dữ liệu** (bookmark HTML, notes MD, history CSV) | `Documents/kinh_export` — không nhốt data |
| OTA / kiểm tra version | Tải APK + hỏi cài |
| **Chat gần (LAN / hotspot UDP)** | Cùng Wi‑Fi hoặc hotspot, **không cần internet** |
| **Premium Mesh BLE + Wi‑Fi Direct + gọi 1-hop** | P2P; cần quyền BT / micro; **không** cam kết tầm km |
| **SOS nhanh** | Broadcast tin cố định tới máy Kính gần (LAN ± native mesh) |
| **Low-end mode** | Tối đa ~3 tab trình duyệt, giảm animation, mô tả rõ trong Cài đặt |
| **FAQ trong app** | Giải thích riêng tư / 2 nhóm user Cộng đồng |

### B. Tuỳ chọn cloud — **không bắt buộc**

| Tính năng | Phụ thuộc | Ai phải cấu hình gì |
|-----------|-----------|---------------------|
| **Cộng đồng** (chat thế giới / chủ đề / theo trang / DM / online) | Firebase + Google Sign-In | Xem mục 4 — **2 nhóm user** |
| **Google Drive sync** | Tài khoản Google | User chủ động bật |

App **vẫn dùng được** toàn bộ nhóm A nếu **không** đăng nhập Google.

### C. Không làm / không hứa sản phẩm

- Silent install / cài đè không hỏi  
- GeckoView production thay Chromium trên pipeline hiện tại  
- Mesh “2–4 km / 7 hop chỉ điện thoại” như cam kết  
- Gọi thoại **nhiều hop** mượt như 1-hop  
- Relay qua máy **không cài app** / “không dấu vết”  
- “Internet ké” 4G máy khác thuần phần mềm không gateway/LoRa  

---

## 3. Sáu bước gốc

| Bước | Nội dung | Trạng thái |
|------|----------|------------|
| 1 | Dashboard Bento, theme, CI APK+EXE, Releases | ✅ |
| 2 | Browser, DoH, tab, bookmark, Search Diversity | ✅ |
| 3 | History, activity log, ẩn danh, safe browse local | ✅ |
| 4 | AI Builder (API key **của user**) | ✅ |
| 5 | Backup, Drive **tuỳ chọn**, OTA, Privacy Policy | ✅ code |
| 6 | App launcher, sidebar, theme system | ✅ |

**Edition:** Core (`com.bachdathan.kinh`) và Plus (`KINH_EDITION=plus`) — cùng triết lý; Plus không biến app thành “bắt buộc Google”.

---

## 4. Cộng đồng online — **hai nhóm người** (quan trọng)

### Nhóm A — Chỉ cài APK có sẵn từ GitHub Releases

- **Không** tạo Firebase, **không** thêm SHA-1, **không** dán Web client ID.
- Chỉ: cài `Kinh.apk` → Cộng đồng → **Đăng nhập Google**.
- Firebase / SHA-1 / Web client ID do **nhà phát hành APK** cấu hình **một lần**.
- Lỗi `CONFIGURATION_NOT_FOUND` → thường là cấu hình phía phát hành (SHA-1 chưa khớp keystore ký APK), **không** phải user “chưa đăng ký”.

### Nhóm B — Clone repo / tự build APK

- Chữ ký APK (SHA-1) **khác** bản Releases công khai → Firebase dễ từ chối login.
- Cần: bật Google Sign-In, thêm **SHA-1 keystore của mình**, Web client ID (dán trong app **Hướng dẫn Cộng đồng** hoặc file config).
- Chi tiết từng bước nằm **trong app** (chọn đúng nhóm B).

---

## 5. Việc nhà phát hành (chủ repo) cần giữ đúng

1. Firebase project gắn `firebase_options.dart` còn sống, Google Sign-In bật.  
2. SHA-1 **keystore release** (và Plus nếu khác) có trên Firebase Android app.  
3. Web client ID đúng trong build / override.  
4. Secrets CI ký APK (`KEYSTORE_*`) nếu dùng release signing.  
5. Mỗi lần đổi tính năng lớn: cập nhật **PROGRESS.md**, **PRIVACY.md**, **FAQ.md**, `version.json` — **giữ bản đầy đủ**, chỉ thêm mục version.

---

## 6. Lịch sử phiên bản gần

| Version | Nội dung chính |
|---------|----------------|
| 0.13.x | Premium mesh scaffold, CI inject BLE/WFD, Survival UX radar |
| 0.14.0 | FAQ, export HTML/MD/CSV, SOS, community setup in-app, low-end rõ |
| 0.14.1 | Hướng dẫn Cộng đồng **tách 2 nhóm** |
| 0.14.2 | Khôi phục MD đầy đủ (tránh bản rút gọn) |
| **0.15.0** | Store-and-Forward **text** trên LAN mesh (TTL hop, hàng đợi local); SOS enqueue S&F. Không Briar/Nostr/voice multi-hop.
| 0.14.3 | **Fix build:** export notes `_${at}_` (hết lỗi getter `at_`); `settings_sheet` bỏ `subtitle` trùng trên Low-end. CMake Firebase Windows chỉ còn deprecation warning. |

---

## 7. Lấy bản cài

GitHub → **Actions** (build xanh) → **Releases** → `Kinh.apk` / `Kinh-Windows.zip`.

## 8. Quyết định kỹ thuật giữ nguyên

- Không commit `android/` / `windows/` — CI `flutter create` mỗi lần build.  
- Engine: System WebView (Android) / WebView2 (Windows) qua abstraction `BrowserEngine`.  
- Không silent-install.

---

## 0.15.0 — Store-and-Forward (phần Gemini làm được)

**Đã làm:** S&F **chỉ tin nhắn chữ** trên mesh LAN (và SOS).

**Cố ý không làm** (Gemini): CouchDB/Briar đầy đủ, Nostr, sóng âm, Li-Fi, DTN NASA đầy đủ, fractal compression, Edge AI routing, FEC/Codec2 multi-hop voice, Wi-Fi Aware sâu, PQC lattice, drone, quantum, bio-mesh.

---

## 0.15.1 — Rules Firebase chặt + dự phòng Android Key Rotation

- `tool/firebase_rtdb_rules.json`: root cấm; chat/presence chỉ `auth != null`; ghi đúng uid; text ≤ 2000.
- `docs/FIREBASE_RULES.md`: cách Publish rules + siết API key.
- `docs/ANDROID_KEY_ROTATION.md`: Signature v3/v4, lineage, SHA Firebase, secrets CI khi **đổi** keystore — **dự phòng**, không bắt buộc mỗi build.
