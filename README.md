# Kính

Dashboard / trình duyệt all-in-one, minh bạch và riêng tư.
Xử lý dữ liệu 100% trên máy người dùng, không server riêng, không chi phí ẩn.

Xem tiến độ và kế hoạch chi tiết trong [PROGRESS.md](PROGRESS.md).

## Tải bản build sẵn

Vào tab **Releases** của repo này để tải `Kinh.apk` (Android) hoặc
`Kinh-Windows.zip` (Windows) — được build tự động mỗi khi có cập nhật.

## Tính năng hiện tại (Bước 2)

- Trình duyệt thật (System WebView / Chromium trên Android, WebView2 trên Windows)
- Omnibox, quản lý Tab, Bookmark Bar
- Download Manager (Pause/Resume)
- DNS-over-HTTPS (preset + tùy chỉnh)
- Search Diversity Index
- Kiến trúc `BrowserEngine` sẵn sàng swap sang GeckoView sau này

## Chạy dự án (dev)

```bash
flutter pub get
flutter run
```

## Engine

| Platform | Engine hiện tại     | Ghi chú |
|----------|---------------------|---------|
| Android  | System WebView      | Tạm thời — mục tiêu dài hạn GeckoView |
| Windows  | WebView2            | Ổn định |

Xem chi tiết lý do và kiến trúc trong `PROGRESS.md` và
`lib/browser/engine/browser_engine.dart`.
