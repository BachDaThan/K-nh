# Firebase Realtime Database — rules chặt

## Cách áp dụng (Console)

1. Firebase Console → project **kinh-7713d** (hoặc project của bạn)
2. **Realtime Database** → tab **Rules**
3. Dán nội dung file `tool/firebase_rtdb_rules.json`
4. **Publish**

Hoặc CLI (nếu đã `firebase login`):

```bash
firebase deploy --only database
```

(cần `database.rules` trỏ tới file rules trong `firebase.json`)

## Nguyên tắc

| Vùng | Đọc | Ghi |
|------|-----|-----|
| Gốc `/` | **cấm** | **cấm** |
| `presence` / `online` | user đã login | **chỉ đúng `auth.uid`** |
| `rooms/.../messages` | user đã login | tin mới: `uid == auth.uid`, text ≤ 2000 |
| `dm` | login + pair có liên quan uid (nới nếu app dùng scheme khác) |
| `users/$uid` | login | chỉ owner |

## Lưu ý với code chat hiện tại

- Mọi client **bắt buộc** `auth != null` → chưa login **không** đọc/ghi Cộng đồng (đúng ý tuỳ chọn).
- Nếu sau Publish mà app báo permission denied: kiểm tra path thực tế trong `chat_service.dart` (tên node `rooms` / `online` / `dm`) khớp rules.
- Rules **không** thay thế Application restriction trên **API key** (Google Cloud Credentials).

## API key (Secret scanning)

Client `apiKey` trong `firebase_options.dart` vẫn có thể public trong APK. Bảo vệ bằng:

1. Cloud Console → Credentials → key → **Android app** restriction (package + SHA-1)
2. **API restrictions** chỉ Firebase/Identity cần dùng
3. Rules RTDB như trên
