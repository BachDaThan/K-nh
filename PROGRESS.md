# Tiến độ dự án Kính

## Trạng thái hiện tại: Bước 4/6 — AI Builder & Code Runner ✅

### Bước 4 — Đã làm
- [x] **AI Builder** màn hình riêng (`lib/ai/screens/ai_builder_screen.dart`)
- [x] **Code editor** monospace (Python / JavaScript)
- [x] **Code Runner sandbox**: WebView ẩn
  - JavaScript: `eval` trong sandbox page
  - Python: **Pyodide WASM** (CDN, tải lần đầu khi chạy Python)
- [x] **AI API key cá nhân**: Settings trong app — Base URL OpenAI-compatible + model
- [x] **Chat / Generate code**: hỏi AI hoặc “AI sửa code vào editor”
- [x] **Snippets**: lưu / mở / xóa local (SharedPreferences)
- [x] Dashboard card **AI Builder**

### Bước 3 — Bảo mật & Lịch sử ✅
### Bước 2 — Trình duyệt lõi ✅
### Bước 1 — Dashboard ✅

### Package
- Version: `0.4.0+7`

### Tiếp theo
- [ ] **Bước 5** — Cloud Sync & Chia sẻ / OTA (có chữ ký)
- [ ] **Bước 6** — App Launcher, Sidebar, Theme

### Ghi chú Bước 4
- Không nhúng full Monaco/Xterm.js native (tránh phình APK + phức tạp Windows); editor Flutter + runner WASM/JS đủ dùng.
- Pyodide cần mạng lần đầu; sau đó cache theo WebView.
- API key không bao giờ gửi server Kính (không có server).
