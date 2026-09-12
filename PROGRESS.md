# Tiến độ dự án Kính

## Trạng thái hiện tại: Bước 6/6 — App Launcher + Sidebar + Theme ✅

### Bước 6 — Hoàn thiện
- [x] App Launcher (quét / ghim app Android)
- [x] **Sidebar** (`lib/widgets/app_sidebar.dart`): thanh lối tắt trái — Home, Web, AI, Theme, Update, app đã ghim
- [x] **Theme System** (`lib/theme/`):
  - Chế độ Tối / Sáng / Hệ thống
  - Màu nhấn (blue, purple, teal, amber, rose)
  - Preset nền Dashboard (midnight, ocean, forest, sunset, mono)
  - Slider blur kính (0–24) lưu local
  - `ThemeController` + `ListenableBuilder` rebuild toàn app

### Bước 1–5: đã xong (xem lịch sử commit)

### Package
- Version: `0.7.0+11`

### Ghi chú
- Theme không dùng custom CSS web — thuần Flutter Material 3.
- Sidebar rộng 72px, không che nội dung Bento trên mobile (nằm cạnh grid).
