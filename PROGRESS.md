# 0.11.0 — Cộng đồng Chat (Firebase Spark)

## Có trong code
- Presence online (`.info/connected`)
- Kênh thế giới (max 100 tin)
- Chủ đề: góp ý / chia sẻ link / tâm sự
- Chat theo URL trang (max 60, dọn 48h)
- DM 1-1 (max 50)
- Google Sign-In

## Bắt buộc bạn làm
1. Tạo Firebase project
2. Điền `lib/firebase_options.dart`
3. Bật Auth Google + Realtime Database + rules (xem FIREBASE_CHAT_SETUP.md)

Chưa điền config → app báo lỗi cấu hình, không crash toàn app.
