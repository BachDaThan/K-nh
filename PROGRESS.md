# Tiến độ dự án Kính

> File này phản ánh **repo thật** (không dùng bản Bước 1 cũ).
> Repo: https://github.com/BachDaThan/K-nh — version hiện tại xem `pubspec.yaml` / `version.json`.

## Trạng thái: ~Bước 1–6 + polish — **gần hoàn thiện roadmap gốc**

### Bước 1 — Khung UI + Build pipeline ✅
- Dashboard Bento, dark theme, GitHub Actions APK + Windows EXE, Releases `latest`

### Bước 2 — Trình duyệt & DoH ✅
- `BrowserEngine` abstraction + Chromium/WebView2
- Omnibox, Tab, Bookmark, Download, Search Diversity, DoH preference (System WebView **không** đổi DNS OS thật)

### Bước 3 — Bảo mật & Lịch sử ✅
- History, Activity Log, Incognito RAM-oriented flows
- API key trong `flutter_secure_storage`

### Bước 4 — AI Builder & Code Runner ✅
- Editor + Pyodide/JS runner trong WebView

### Bước 5 — Sync & OTA ✅ (một phần theo triết lý 0 server)
- [x] Binary OTA qua `version.json` + jsDelivr/raw GitHub
- [x] Hot patch Ed25519
- [x] **Local Backup/Sync JSON** (export/import clipboard) — thay Drive khi chưa OAuth
- [ ] Google Drive OAuth đầy đủ — **chưa** (cần client ID, phức tạp hơn, tùy chọn sau)
- [ ] Gist API tự động — **chưa** (user có thể dán JSON thủ công)

### Bước 6 — Launcher / Sidebar / Theme ✅
- App Launcher **chỉ Android** (`installed_apps`)
- Sidebar + Theme (màu, preset, blur, ẩn/hiện sidebar)
- Live Weather (Open-Meteo HCM) + Network status trên thẻ
- Icon launcher glass/aurora + adaptive (Android)

### Ký APK / cài đè
- CI inject signing cho `build.gradle.kts` + secrets `KEYSTORE_*`
- Lần đầu đổi keystore: **gỡ app cũ một lần**

## PC / Windows có gì — không có gì?

| Có trên Windows | Không / hạn chế |
|-----------------|-----------------|
| `Kinh-Windows.zip` trong Releases (giải nén chạy EXE) | App Launcher quét app Android |
| Browser WebView2, AI Builder, Theme, Backup JSON | Adaptive icon Android; ký APK chỉ Android |
| OTA check (tải EXE) | DoH thật tầng OS |

**PC không “thiếu build”** nếu Actions xanh và Release có `Kinh-Windows.zip`.  
Tải: https://github.com/BachDaThan/K-nh/releases/tag/latest

## Quyết định giữ nguyên
- Không commit `android/` / `windows/`; CI `flutter create` mỗi lần
- Không silent-install
- 100% client-side, 0 server riêng

## Việc nên làm tiếp (ưu tiên)
1. Ổn định cài đè Android (keystore base64 đúng + 1 lần gỡ app)
2. Splash screen theo theme
3. Windows `.ico` trong CI
4. (Tuỳ chọn) Google Drive OAuth nếu thật sự cần

## File tiến độ cũ (Bước 1/6 only)
Bản `PROGRESS.md` chỉ Bước 1 là **lỗi thời** — không dùng để đánh giá repo hiện tại.
