# Tiến độ dự án Kính

> File này để bất kỳ phiên chat mới nào với Claude/Grok cũng biết đang làm
> đến đâu. Mở chat mới, dán link repo này + nói "đọc PROGRESS.md rồi
> làm tiếp" là đủ, không cần upload lại gì.

## Trạng thái hiện tại: Bước 2/6 — Trình duyệt lõi & DoH ✅

### Đã làm xong

#### Bước 1
- [x] Khung project Flutter cơ bản (`lib/main.dart`, dark theme #121212)
- [x] Màn hình Dashboard với Bento Grid responsive (2 cột mobile / 4 cột desktop)
- [x] Widget `BentoCard` hiệu ứng Glassmorphism (kính mờ)
- [x] Icon app "Kính" — thiết kế gốc, viên kính đa giác trong suốt (`assets/icon.svg`)
- [x] GitHub Actions (`.github/workflows/build.yml`):
  - Build APK (Android) tự động khi push lên `main`
  - Build EXE (Windows) tự động khi push lên `main`
  - Tự động publish cả 2 file vào GitHub Releases (tag `latest`), đè bản cũ

#### Bước 2
- [x] **Abstraction `BrowserEngine`** (`lib/browser/engine/browser_engine.dart`)
  - Interface chung: loadUrl, tab lifecycle, zoom, print PDF, cookie/cache,
    evaluateJavascript, user-agent...
  - **Implementation hiện tại:** `ChromiumBrowserEngine`
    (Android = System WebView / Chromium, Windows = WebView2)
    qua package `webview_flutter + webview_win_floating`.
  - **Kiến trúc đã chuẩn bị sẵn** để sau này thêm `GeckoBrowserEngine`
    mà không phải sửa lại tầng UI / Omnibox / Tab / Bookmark / DoH...
- [x] Trình duyệt chuẩn:
  - Omnibox (nhập URL / từ khóa, gợi ý cơ bản qua submit)
  - Quản lý Tab (thêm / đóng / chuyển tab, IndexedStack giữ state)
  - Bookmark Bar + lưu bookmark local (SharedPreferences)
  - Download Manager UI (Pause / Resume / Cancel state)
  - Lưu mật khẩu local (PasswordService — MVP, chưa mã hóa mạnh)
  - Zoom + In PDF (qua API engine)
- [x] DoH (DNS-over-HTTPS):
  - 1-click preset: Cloudflare 1.1.1.1, AdGuard DNS, Google 8.8.8.8, Cloudflare Family
  - Nhập link DoH tùy chỉnh (NextDNS, AdGuard Home...)
  - Preference được lưu; ghi chú rõ System WebView chưa inject DoH tầng network
    như GeckoView — khi swap engine sẽ dùng preference này.
- [x] Search Diversity Index (0.0 → 2.0):
  - 0.0 = chỉ nguồn chính thống (.gov/.edu/Wikipedia/báo lớn)
  - 0.5 = tiêu chuẩn
  - >1.0 = mở rộng blog / forum / trang ngách
  - Áp dụng bằng cách biến đổi query trước khi gửi search engine.
- [x] Hiển thị web qua WebView thật (không iframe giả lập).
- [x] Dashboard có nút "Mở trình duyệt" + card Tìm kiếm dẫn vào BrowserScreen.

### Package / Định danh
- Tên hiển thị: **Kính**
- Package Android: `com.bachdathan.kinh`
- Repo: `BachDaThan/K-nh`
- Version hiện tại: `0.2.1+3`

### Nhân trình duyệt (quan trọng)

| Nền tảng | Engine hiện tại              | Ghi chú |
|----------|------------------------------|---------|
| Android  | System WebView (Chromium)    | Tạm thời. Mục tiêu dài hạn: GeckoView khi plugin Flutter chín. |
| Windows  | WebView2 (Chromium)          | Chấp nhận được; GeckoView không có binding ổn định trên Windows Flutter. |

**Lý do chưa dùng GeckoView thật trên Android:**
- Plugin Flutter GeckoView hiện là WIP / thiếu API quan trọng / APK size lớn.
- Xung đột với quy tắc "không commit thư mục `android/`" (GeckoView đòi hỏi
  Maven Mozilla + dependency theo ABI + proguard đặc biệt).
- Kiến trúc `BrowserEngine` đã tách biệt để sau này chỉ cần viết
  `GeckoBrowserEngine` implement cùng interface.

### Cách lấy file cài đặt
Sau khi push code lên `main` và Actions chạy xong (xem tab Actions trên
GitHub) → vào tab **Releases** của repo → tải `Kinh.apk` hoặc
`Kinh-Windows.zip`.

## Các bước tiếp theo (chưa làm)

- [ ] **Bước 3** — Bảo mật & Lịch sử: dọn dẹp theo domain, Visual
      Activity Log, chế độ ẩn danh RAM-only
- [ ] **Bước 4** — AI Builder & Code Runner: Monaco Editor, Pyodide/WASM
      sandbox, Xterm.js, kết nối API key AI cá nhân
- [ ] **Bước 5** — Cloud Sync & Chia sẻ: Google Drive backup, QR/link
      chia sẻ qua Gist/Pastebin, cơ chế OTA update có chữ ký Ed25519
- [ ] **Bước 6** — App Launcher (quét & ghim app hệ thống), Sidebar,
      Theme system tùy biến

## Quyết định quan trọng đã chốt (đừng hỏi lại)

- **KHÔNG viết tay các file Gradle** (`android/build.gradle`,
  `settings.gradle`, `app/build.gradle`, `gradle-wrapper.properties`).
  Workflow tự chạy `flutter create --platforms=android .` mỗi lần build.
  Không giữ thư mục `android/` (và `windows/`) trong repo/git.
- Không làm silent-install.
- Nền tảng: Android (.apk) + Windows (.exe). Không làm iOS native.
- Engine tạm thời: Chromium/WebView2 qua abstraction `BrowserEngine`.
  Mục tiêu dài hạn vẫn là GeckoView trên Android khi điều kiện kỹ thuật cho phép.
- Triết lý: xử lý 100% client-side, không server riêng, hạ tầng miễn phí
  (GitHub Actions, GitHub Releases).
