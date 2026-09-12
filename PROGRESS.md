# Tiến độ dự án Kính

## Trạng thái hiện tại: Bước 6/6 (một phần) — App Launcher ✅

### Bước 6 — App Launcher (mới)
- [x] **AppLauncherService** (`lib/launcher/services/app_launcher_service.dart`): quét app đã cài trên Android qua package `installed_apps` (không phải `device_apps` — package đó đã discontinued)
- [x] Cần quyền `QUERY_ALL_PACKAGES` — đã thêm tự động qua CI (chèn vào AndroidManifest cùng lúc với INTERNET)
- [x] **AppPickerSheet** (`lib/launcher/widgets/app_picker_sheet.dart`): bottom sheet tìm kiếm + ghim/bỏ ghim app, hiển thị icon thật của từng app
- [x] `BentoItem` mở rộng: `icon` giờ optional, thêm `iconBytes` (icon app thật) và `packageName` (đánh dấu đây là lối tắt app, không phải widget cố định)
- [x] Dashboard: app đã ghim hiện thành ô Bento Grid riêng, chèn trước ô "+ Thêm App" (luôn ở cuối); bấm vào app ghim → mở qua Intent hệ thống (`InstalledApps.startApp`), không chiếm RAM trình duyệt — đúng thiết kế gốc
- [x] Chỉ hỗ trợ Android (Windows chưa làm — cần registry/Start Menu, phức tạp hơn, để sau nếu cần)
- [ ] Sidebar (thanh lối tắt bên) — chưa làm
- [ ] Theme System (đổi màu, ảnh nền, blur, custom CSS) — chưa làm

### Bước 5 — Hot Update + Ed25519 (đã xong)
- [x] **HotUpdateService** (`lib/update/services/hot_update_service.dart`): tải `hotpatch.json` qua jsDelivr, verify chữ ký Ed25519 **bắt buộc** trước khi tin tưởng nội dung — không có chữ ký hoặc chữ ký sai → từ chối hoàn toàn, không áp dụng
- [x] Public key Ed25519 nhúng cứng trong app (an toàn khi công khai); private key **KHÔNG BAO GIỜ** vào repo/CI — chỉ tồn tại offline trên máy người ký
- [x] Ký bằng canonical string cố định (`patch_version=...\nrunner_html=...\ndashboard_notice=...`), KHÔNG dùng JSON string để verify (thứ tự key JSON sau decode không đảm bảo giống lúc ký → verify sẽ fail ngẫu nhiên nếu dùng JSON)
- [x] `tool/sign_hotpatch.py`: script ký thủ công, chạy offline trên máy người dùng, KHÔNG chạy trong GitHub Actions
- [x] Hot patch có thể vá: `runner_html` (trang chạy code trong AI Builder) và `dashboard_notice` (banner thông báo trên Dashboard) — không cần build lại APK/EXE, không cần cài lại
- [x] Đã test full luồng ký → verify bằng Python (mô phỏng logic Dart): verify pass với payload đúng, verify fail khi nội dung bị giả mạo
- [x] `hotpatch.json` placeholder (rỗng, đã ký hợp lệ) đặt sẵn ở gốc repo

### Bước 5 — Binary Update (trước đó)
- [x] **UpdateService** (`lib/update/services/update_service.dart`): check bản mới qua `version.json` tĩnh trong repo, đọc qua jsDelivr CDN (đổi từ GitHub API ban đầu, theo tư vấn Gemini — tránh giới hạn 60 request/giờ của api.github.com; jsDelivr không giới hạn, tự động cache CDN)
  - Chỉ check khi có Wi-Fi (hoãn nếu dùng data di động 3G/4G)
  - Giới hạn tối đa 1 lần / 6 giờ (trừ khi force check)
  - So sánh semver, không silent — chỉ trả về info nếu có bản mới hơn
- [x] **UpdateDialog** (`lib/update/widgets/update_dialog.dart`): thông báo có bản mới, nút "Tải bản mới" mở trình duyệt tải APK/EXE, nút "Để sau" — KHÔNG tự cài ngầm
- [x] Gắn vào `DashboardScreen` — check tự động sau khi mở app (postFrameCallback, im lặng nếu không có bản mới)
- [x] Nút "Kiểm tra cập nhật" thủ công (icon trên header Dashboard) — bỏ qua giới hạn 6h, thêm cache-buster `?t=<timestamp>` vào URL `version.json` để lấy dữ liệu mới nhất từ jsDelivr ngay lập tức, có SnackBar báo "Đang dùng bản mới nhất" nếu không có gì mới

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
- [ ] **Bước 6 (còn lại)** — Sidebar, Theme System
- [ ] **Bước 5 (còn lại)** — Cloud Sync (Google Drive backup), Chia sẻ 1-Click (QR/Rentry/Gist)

### Ghi chú Bước 4
- Không nhúng full Monaco/Xterm.js native (tránh phình APK + phức tạp Windows); editor Flutter + runner WASM/JS đủ dùng.
- Pyodide cần mạng lần đầu; sau đó cache theo WebView.
- API key không bao giờ gửi server Kính (không có server).

### Ghi chú Bước 5 (Binary Update)
- Đọc `version.json` tĩnh ở gốc repo qua jsDelivr CDN (`cdn.jsdelivr.net/gh/BachDaThan/K-nh@main/version.json`) — không gọi GitHub REST API, không giới hạn request, không cần token, không cần server riêng — đúng triết lý "0 đồng".
- `version.json` được GitHub Actions tự động cập nhật sau mỗi lần build/release thành công (commit `[skip ci]` để tránh vòng lặp build) — không cần sửa tay.
- jsDelivr cache theo CDN — sau khi push có thể mất vài phút tới vài giờ để phản ánh, chấp nhận được cho app cá nhân.
- Link tải mở qua trình duyệt ngoài (`url_launcher`), Android tự xử lý tải + hỏi cài — app KHÔNG tự cài ngầm (không cần quyền `REQUEST_INSTALL_PACKAGES`).
- Vì tất cả bản build từ giờ đều ký cùng 1 keystore thật, người dùng có thể cài đè bản mới lên bản cũ mà không mất dữ liệu (khác với lần chuyển từ debug key sang release key trước đây, lần đó bắt buộc phải gỡ cài lại).


### Fix OTA version.json (2026-09-12)
- **Triệu chứng:** Nút "Kiểm tra cập nhật" luôn báo "đang dùng bản mới nhất" dù đã push code mới.
- **Nguyên nhân thật:**
  1. `version.json` trên repo kẹt `0.5.0` trong khi `pubspec.yaml` = `0.6.0`.
  2. Workflow `build.yml` **không có** (hoặc step ghi file bị skip) bước cập nhật `version.json` sau release — CI ✓ xanh vì không lỗi, nhưng file không đổi.
  3. App đọc `version.json` → so sánh semver → latest (0.5.0) không > current → "mới nhất".
- **Cách sửa:**
  1. Ghi `version.json` = `0.6.0` khớp pubspec.
  2. Thêm step CI: Python ghi JSON sạch (không heredoc YAML), `git fetch` + checkout `origin/main` trước commit, push retry, message `[skip ci]`.
  3. `UpdateService` ưu tiên `raw.githubusercontent.com` + fallback jsDelivr, cache-buster khi force.
