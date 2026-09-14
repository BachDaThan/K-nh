# Tiến độ dự án Kính

> Cập nhật: 2026-09-14 · version **0.10.0**

## Trạng thái thực tế (không còn dừng ở Bước 2)

Đã làm xa hơn PROGRESS cũ (Bước 2): trình duyệt, DoH, history/activity, AI Builder,
OTA, launcher, theme, Drive, reader/TTS, audio truyện, Plus edition, v.v.

### 0.10.0 — vừa làm
- [x] **Dashboard search** — ô tìm thẻ/app trên dashboard
- [x] **Ghi chú** — thẻ Notes hoạt động (local)
- [x] **Nhật ký bảo mật** — mở Activity Log
- [x] **Duyệt web an toàn** 3 mức (local, không Google API):
  - Không bảo vệ
  - Bảo vệ tiêu chuẩn (host độc hại đã biết)
  - Bảo vệ nâng cao (IP trần, TLD rủi ro, đuôi file nguy hiểm…)
- [x] **Chế độ máy yếu** — giảm tải (preference); không “tối ưu mọi SoC” ảo

### Engine
| Nền tảng | Engine |
|----------|--------|
| Android | System WebView (Chromium) |
| Windows | WebView2 |

GeckoView: đã thử — conflict plugin; giữ Chromium.

### Quyết định giữ nguyên
- Không commit `android/` / `windows/`
- `flutter create` mỗi CI build
- Không silent-install
- Client-side, GitHub Actions + Releases

### Ghi chú tối ưu phần cứng
Không thể một binary “tối ưu hoàn hảo mọi máy cũ→mới”. Đã có:
- Chế độ máy yếu (user bật)
- Tree-shake icons release
- Lazy WebView theo tab

Máy rất cũ: bật **Chế độ máy yếu** trong Cài đặt trình duyệt.

### Tiếp theo gợi ý
- Safe Browsing: cập nhật list host định kỳ (file trên repo)
- Foreground service TTS mạnh hơn khi khóa màn hình
- EPUB reader đầy đủ
