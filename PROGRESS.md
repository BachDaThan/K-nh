# Tiến độ dự án Kính

> File này để bất kỳ phiên chat mới nào với Claude/Grok cũng biết đang làm
> đến đâu. Mở chat mới, dán link repo này + nói "đọc PROGRESS.md rồi
> làm tiếp" là đủ, không cần upload lại gì.

## Trạng thái hiện tại: Bước 3/6 — Bảo mật & Lịch sử ✅

### Bước 3 — Đã làm
- [x] **Lịch sử duyệt** (`HistoryService`): lưu local, tìm kiếm, xóa từng mục / theo domain / xóa hết
- [x] **UI Lịch sử** (`HistorySheet`): filter domain, mở lại URL, xóa
- [x] **Visual Activity Log** (`ActivityLogService` + `ActivityLogSheet`): navigation, page finished, clear, ẩn danh…
- [x] **Chế độ ẩn danh**: tab `isIncognito` — không ghi lịch sử ra đĩa; activity log ephemeral (RAM only); nút mắt trên TabStrip
- [x] **Dọn dẹp** (`PrivacySheet`): xóa lịch sử / cookie / cache / tất cả; xóa lịch sử theo domain
- [x] Menu ⋮ → Bảo mật & Lịch sử

### Bước 2 — Đã làm (tóm tắt)
- BrowserEngine abstraction + ChromiumBrowserEngine (webview_flutter)
- Omnibox full-width, Tab, Bookmark, Download, DoH UI, Search Diversity
- Hybrid Composition, INTERNET permission trong CI, system Back thông minh

### Bước 1 — Đã làm
- Dashboard Bento Grid, icon, GitHub Actions APK + Windows

### Package
- Version: `0.3.0+6`
- Package Android: `com.bachdathan.kinh`

### Các bước tiếp theo
- [ ] **Bước 4** — AI Builder & Code Runner
- [ ] **Bước 5** — Cloud Sync & Chia sẻ / OTA
- [ ] **Bước 6** — App Launcher, Sidebar, Theme

### Quyết định đã chốt
- Không commit `android/` / `windows/` — workflow `flutter create`
- Không silent-install
- Engine tạm: Chromium/WebView2; dài hạn GeckoView khi chín
- 100% client-side

