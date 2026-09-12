# Tiến độ dự án Kính

## Trạng thái: Bước 6 hoàn thiện + Polish + Signing

### Polish
- [x] Sidebar ẩn/hiện (Theme settings)
- [x] Theme blur áp dụng BentoCard
- [x] Thêm preset nền / accent
- [x] Browser chrome dùng `Theme.of(context)` (không hard-code màu)
- [x] Wallpaper: dùng preset nền (không xin quyền thư viện)

### Signing / OTA cài đè
- [x] CI inject `signingConfigs.release` từ GitHub Secrets (`KEYSTORE_*`)
- [x] `tool/ci_inject_signing.py`
- [x] `SIGNING.md` hướng dẫn tạo keystore + secrets
- **Lần đổi key đầu** vẫn cần gỡ app cũ một lần; sau đó cài đè bình thường

### Version
- `0.7.1+12`
