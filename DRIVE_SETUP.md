# Google Drive Sync — cấu hình OAuth (một lần)

App **chỉ đọc** file JSON bạn upload lên Drive (scope `drive.readonly`).

## 1. Google Cloud Console

1. Tạo project (hoặc chọn project có sẵn)
2. **APIs & Services → Enable APIs** → bật **Google Drive API**
3. **OAuth consent screen** → External (hoặc Internal nếu Workspace) → thêm scope:
   - `.../auth/drive.readonly`
4. **Credentials → Create credentials → OAuth client ID**
   - Application type: **Android**
   - Package name: `com.bachdathan.kinh`
   - SHA-1: lấy từ keystore release:

```bash
keytool -list -v -keystore kinh-release.jks -alias kinh
# copy SHA1
```

5. (Tuỳ chọn) Client type **Web** nếu cần Client ID dán vào ô trong app

## 2. Trong app Kính

1. Upload file backup: Dashboard → **Backup / Sync** → Export JSON → tải file đó lên Google Drive
2. Mở thẻ **Google Drive**
3. Đăng nhập Google
4. **Chọn file** → chọn đúng file JSON
5. Bật **Tự động đồng bộ** nếu muốn mỗi lần mở app tự kéo
6. Hoặc chỉ bấm **Đồng bộ ngay** (thủ công)

## 3. Đổi file / tắt tự động

- **Đổi / bỏ file** rồi chọn file khác
- Tắt switch tự động → chỉ sync khi bấm nút

## Windows

`google_sign_in` chưa ổn định trên Windows — dùng Export/Import JSON (Backup / Sync).
