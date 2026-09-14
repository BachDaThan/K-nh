# Firebase Chat (gói Free Spark) — thiết lập

## 1. Tạo project
1. https://console.firebase.google.com → Add project
2. Bật **Authentication** → Sign-in method → **Google**
3. Bật **Realtime Database** → Create (test mode tạm, rồi dán rules bên dưới)
4. Project settings → Your apps → thêm Android (`com.bachdathan.kinh`) + Web (cho Windows)

## 2. Điền `lib/firebase_options.dart`
Copy `apiKey`, `appId`, `messagingSenderId`, `projectId`, `databaseURL` vào file.

## 3. Google Cloud
OAuth consent + SHA-1 debug/release (Android) cho Google Sign-In.

## 4. Rules RTDB (dán trong Console)

```json
{
  "rules": {
    "presence": {
      "$uid": {
        ".read": true,
        ".write": "auth != null && auth.uid == $uid"
      }
    },
    "rooms": {
      "$room": {
        "messages": {
          ".read": "auth != null",
          ".write": "auth != null",
          ".indexOn": ["ts"],
          "$msg": {
            ".validate": "newData.hasChildren(['uid','name','text','ts']) && newData.child('text').isString() && newData.child('text').val().length <= 500 && newData.child('uid').val() === auth.uid"
          }
        }
      }
    }
  }
}
```

## 5. Giới hạn Free Spark
- ~100 kết nối RTDB đồng thời
- App tự cắt tin: global 100, topic 80, page 60, DM 50
- Page chat dọn tin > 48h phía client
- Chỉ text/emoji (không upload ảnh)

## 6. CI / không commit android/
Dùng `Firebase.initializeApp(options: DefaultFirebaseOptions...)` trong Dart — không bắt buộc `google-services.json` nếu options đủ (Android Google Sign-In vẫn cần SHA đúng).
