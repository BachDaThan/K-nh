# Cài đè APK không cần gỡ app cũ

## Vì sao điện thoại báo "Ứng dụng chưa được cài đặt"?

Android **chỉ cho cài đè** khi **cùng applicationId** và **cùng chữ ký (keystore)**.

Nếu:
- Bản cũ ký bằng **debug key** (build sớm / thiếu secrets)
- Bản mới ký bằng **release key** (hoặc ngược lại)
→ Hệ thống **từ chối cài đè**. Phải gỡ bản cũ (mất dữ liệu app) rồi cài mới.

## Cách làm đúng (một lần)

1. Tạo keystore trên máy (giữ file + mật khẩu mãi mãi):

```bash
keytool -genkey -v -keystore kinh-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias kinh
```

2. Đưa lên GitHub Secrets (repo K-nh → Settings → Secrets → Actions):

| Secret | Nội dung |
|--------|----------|
| `KEYSTORE_BASE64` | `base64 -w0 kinh-release.jks` (Linux) |
| `KEYSTORE_PASSWORD` | mật khẩu store |
| `KEY_PASSWORD` | mật khẩu key (thường trùng store) |
| `KEYSTORE_ALIAS` | `kinh` |

3. Push code / chạy Actions → mọi APK sau này **cùng một chữ ký** → cài đè bình thường.

4. **Lần chuyển key đầu tiên** vẫn phải gỡ bản cũ một lần. Từ đó trở đi không cần.

## Kiểm tra hai APK có cùng chữ ký không

```bash
# Cần apksigner (Android build-tools)
apksigner verify --print-certs Kinh-cu.apk
apksigner verify --print-certs Kinh-moi.apk
# So SHA-256 certificate — phải giống nhau
```
