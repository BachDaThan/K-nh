# Tiến độ Kính

## 0.7.2 — UI lung linh + fix DoH custom

### Giao diện (chỉ ngoại hình, lõi giữ nguyên)
- BentoCard: viền gradient, glow theo accent, pulse nhẹ, scale khi bấm
- Theme preset aurora/neon + accent cyan/magenta
- Sidebar: glow khi chọn

### Fix DoH tùy chỉnh
- Trước: chỉ lưu nếu URL **bắt đầu bằng `https://`** — nhập thiếu thì bấm Lưu **im lặng không làm gì**
- Sau: tự thêm `https://`, báo lỗi rõ nếu URL sai, SnackBar hiện URL đã lưu
- System WebView **vẫn không đổi DNS OS** (giới hạn nền tảng) — preference được lưu đúng cho UI / Gecko sau này

### Lõi không đổi
- BrowserEngine, tab, history, AI Builder, launcher, OTA…
