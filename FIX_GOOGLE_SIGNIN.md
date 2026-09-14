# Fix: Auth unknown CONFIGURATION_NOT_FOUND

Lỗi này **không phải** bug UI — Google Play Services không tìm thấy OAuth client khớp **package name + SHA-1**.

## Làm lần lượt

### A. SHA-1
Firebase Console → Project settings (bánh răng) → Your apps → Android  
Package: `com.bachdathan.kinh` (và `com.bachdathan.kinh.plus` nếu Plus)

Thêm fingerprint:
```bash
keytool -list -v -keystore /path/to/kinh-release.jks -alias YOUR_ALIAS
```
Copy **SHA1** dán vào Firebase.

### B. Bật Google provider
Authentication → Sign-in method → Google → Enable → Support email → Save.

### C. Web client ID (bắt buộc cho Firebase Auth idToken)
Firebase → Authentication → Google → **Web client ID**  
(hoặc Google Cloud Console → APIs → Credentials → OAuth 2.0 Client → type Web)

Dán vào file:
`lib/chat/google_auth_config.dart`
```dart
const String kGoogleWebClientId = '886555523620-xxxx.apps.googleusercontent.com';
```

### D. Đợi 5–15 phút rồi cài lại APK (gỡ app cũ nếu cần)

## Vẫn lỗi?
- Package name APK ≠ Firebase app
- Chỉ thêm SHA debug mà APK release dùng SHA khác
- Google Sign-In bị tắt trên máy (hiếm)
