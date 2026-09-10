# Tiến độ dự án Kính

> File này để bất kỳ phiên chat mới nào với Claude cũng biết đang làm
> đến đâu. Mở chat mới, dán link repo này + nói "đọc PROGRESS.md rồi
> làm tiếp" là đủ, không cần upload lại gì.

## Trạng thái hiện tại: Bước 1/6 — Khung UI + Build pipeline ✅

### Đã làm xong
- [x] Khung project Flutter cơ bản (`lib/main.dart`, dark theme #121212)
- [x] Màn hình Dashboard với Bento Grid responsive (2 cột mobile / 4 cột desktop)
- [x] Widget `BentoCard` hiệu ứng Glassmorphism (kính mờ)
- [x] Cấu hình Android đầy đủ (`build.gradle`, `AndroidManifest`, `MainActivity.kt`)
- [x] Icon app "Kính" — thiết kế gốc, viên kính đa giác trong suốt (`assets/icon.svg`)
- [x] GitHub Actions (`.github/workflows/build.yml`):
  - Build APK (Android) tự động khi push lên `main`
  - Build EXE (Windows) tự động khi push lên `main`
  - Tự động publish cả 2 file vào GitHub Releases (tag `latest`), đè bản cũ

### Package / Định danh
- Tên hiển thị: **Kính**
- Package Android: `com.bachdathan.kinh`
- Repo: `BachDaThan/K-nh`

### Cách lấy file cài đặt
Sau khi push code lên `main` và Actions chạy xong (xem tab Actions trên
GitHub) → vào tab **Releases** của repo → tải `Kinh.apk` hoặc
`Kinh-Windows.zip`.

## Các bước tiếp theo (chưa làm)

- [ ] **Bước 2** — Trình duyệt & DoH: nhúng WebView thật, Omnibox, quản
      lý Tab, Bookmark, chọn DNS-over-HTTPS
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
  Đã thử và liên tục lệch version giữa Flutter/AGP/Kotlin/Gradle, gây
  lỗi build lặp đi lặp lại. Cách đúng: workflow tự chạy
  `flutter create --platforms=android .` mỗi lần build để Flutter CLI
  tự sinh cấu hình Gradle khớp đúng với bản Flutter đang cài — không
  còn giữ thư mục `android/` (và `windows/`) trong repo/git nữa, chỉ
  giữ `assets/icon_*.png` (các icon đã sinh sẵn) để workflow tự copy
  vào sau khi `flutter create` chạy xong.
- Không làm silent-install / cài ngầm không xác nhận — đây là hành
  vi bị chặn ở tầng OS (Android/Windows) và giống hành vi malware. Cơ
  chế update sẽ là: tự tải bản mới về nền + hiện thông báo "Có bản mới,
  bấm để cài" (1 chạm, không cần tự tìm file).
- Nền tảng: Android (.apk) + Windows (.exe). Không làm iOS app native
  (dùng PWA thay thế nếu cần sau này). macOS/Linux: chưa xác nhận có
  cần không.
- Ký APK release tạm thời bằng debug key (để cài trực tiếp được ngay).
  Khi cần phát hành chính thức lên rộng rãi, cần tạo keystore riêng.
- Triết lý: xử lý 100% client-side, không server riêng, hạ tầng miễn
  phí (GitHub Actions, GitHub Releases).

## Cách push code này lên GitHub (nếu chưa làm)

```bash
cd kinh
git init
git remote add origin https://github.com/BachDaThan/K-nh.git
git add .
git commit -m "Bước 1: khung Dashboard + build pipeline APK/EXE"
git branch -M main
git push -u origin main
```

Sau khi push, vào tab **Actions** trên GitHub xem quá trình build
(mất khoảng 5–10 phút cho cả APK lẫn EXE). Xong thì file nằm ở tab
**Releases**.
