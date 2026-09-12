# Tiến độ dự án Kính

## Trạng thái hiện tại: Bước 5/6 (một phần) — Binary OTA Update ✅

### Bước 5 — Đã làm (Binary Update, chưa làm Hot Update HTML/JS)
- [x] **UpdateService** (`lib/update/services/update_service.dart`): check bản mới qua GitHub Releases API (tag `latest`)
  - Chỉ check khi có Wi-Fi (hoãn nếu dùng data di động 3G/4G)
  - Giới hạn tối đa 1 lần / 6 giờ (trừ khi force check)
  - So sánh semver, không silent — chỉ trả về info nếu có bản mới hơn
- [x] **UpdateDialog** (`lib/update/widgets/update_dialog.dart`): thông báo có bản mới, nút "Tải bản mới" mở trình duyệt tải APK/EXE, nút "Để sau" — KHÔNG tự cài ngầm
- [x] Gắn vào `DashboardScreen` — check sau khi mở app (postFrameCallback, không chặn UI)
- [ ] Hot Update (HTML/JS/Mini-App) — chưa làm, để sau nếu cần
- [ ] Chữ ký Ed25519 cho gói update — CHƯA làm (hiện dựa vào HTTPS + GitHub Releases là đủ tin cậy cho Binary Update qua trình duyệt; Ed25519 sẽ cần thiết hơn nếu sau này làm Hot Update tự động áp dụng code mới mà không qua GitHub trực tiếp)

### Fix bảo mật (trước Bước 5)
- [x] API key AI chuyển từ SharedPreferences (plaintext) sang `flutter_secure_storage` (Android KeyStore), có migration tự động cho key cũ
- [x] Release signing: keystore thật (`kinh-release.jks`) qua GitHub Secrets (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEYSTORE_ALIAS`), không còn dùng debug key mặc định — workflow tự chèn `signingConfigs` vào `build.gradle` sau khi `flutter create` sinh lại thư mục `android/`

### Fix lỗi Bước 4
- [x] "Độ sáng tạo Search" không có tác dụng: nguyên nhân là cú pháp `site:*.blog`/`site:*.xyz` (wildcard TLD) không hợp lệ với Google Search, bị bỏ qua lặng lẽ. Sửa: dùng domain cụ thể (`site:medium.com`, `site:reddit.com`...) và giữ `site:.gov`/`site:.edu` (2 dạng Google thật sự hỗ trợ)
- [x] Pyodide `TypeError: loadPyodide is not a function`: nguyên nhân là `loadHtmlString()` khiến trang WebView có origin null/about:blank, khiến thẻ `<script src=...>` chèn động tới CDN bị fail âm thầm trên một số WebView Android (không luôn trigger `onerror`). Sửa: dùng `fetch()` + `eval()` thủ công (báo lỗi rõ qua try/catch) thay vì thẻ script động, và thêm `baseUrl: 'https://kinh.local/'` cho `loadHtmlString` để trang có origin HTTPS hợp lệ

### Bước 4 — Đã làm
- [x] **AI Builder** màn hình riêng (`lib/ai/screens/ai_builder_screen.dart`)
- [x] **Code editor** monospace (Python / JavaScript)
- [x] **Code Runner sandbox**: WebView ẩn
  - JavaScript: `eval` trong sandbox page
  - Python: **Pyodide WASM** (CDN, tải lần đầu khi chạy Python)
- [x] **AI API key cá nhân**: Settings trong app — Base URL OpenAI-compatible + model
- [x] **Chat / Generate code**: hỏi AI hoặc "AI sửa code vào editor"
- [x] **Snippets**: lưu / mở / xóa local (SharedPreferences)
- [x] Dashboard card **AI Builder**

### Bước 3 — Bảo mật & Lịch sử ✅
### Bước 2 — Trình duyệt lõi ✅
### Bước 1 — Dashboard ✅

### Package
- Version: `0.5.0+8`

### Tiếp theo
- [ ] **Bước 5 (tiếp)** — Cloud Sync (Google Drive backup), Chia sẻ 1-Click (QR/Rentry/Gist), Hot Update HTML/JS có chữ ký Ed25519
- [ ] **Bước 6** — App Launcher, Sidebar, Theme

### Ghi chú Bước 4
- Không nhúng full Monaco/Xterm.js native (tránh phình APK + phức tạp Windows); editor Flutter + runner WASM/JS đủ dùng.
- Pyodide cần mạng lần đầu; sau đó cache theo WebView.
- API key không bao giờ gửi server Kính (không có server).

### Ghi chú Bước 5 (Binary Update)
- Dùng GitHub Releases API công khai (`api.github.com/repos/.../releases/tags/latest`), không cần token, không cần server riêng — đúng triết lý "0 đồng".
- Link tải mở qua trình duyệt ngoài (`url_launcher`), Android tự xử lý tải + hỏi cài — app KHÔNG tự cài ngầm (không cần quyền `REQUEST_INSTALL_PACKAGES`).
- Vì tất cả bản build từ giờ đều ký cùng 1 keystore thật, người dùng có thể cài đè bản mới lên bản cũ mà không mất dữ liệu (khác với lần chuyển từ debug key sang release key trước đây, lần đó bắt buộc phải gỡ cài lại).

