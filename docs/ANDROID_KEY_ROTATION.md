# Android Key Rotation — dự phòng cài đè khi đổi keystore

## Mục tiêu

Android 9+ (Signature Scheme **v3** / **v4**) hỗ trợ **xoay khóa ký**: app đã cài bằng keystore **cũ** vẫn **cập nhật cài đè** bằng APK ký keystore **mới**, nếu APK mang **proof-of-rotation** (lineage) từ key cũ → key mới.

Dùng khi: keystore sắp hết hạn chính sách, bị lộ (cần đổi), hoặc tách key CI / key phát hành.

## Điều kiện

- Máy user: **Android 9 (API 28)+** (tốt nhất test trên máy thật ≥ 9)
- Tool: `apksigner` (Android build-tools)
- Bạn vẫn **giữ được keystore cũ** (file + mật khẩu + alias) để tạo lineage
- APK ký bằng **cùng scheme** phù hợp (v3 trở lên cho rotation)

## Quy trình tóm tắt (thủ công, an toàn)

### 1. Giữ keystore hiện tại an toàn

- File `.jks` / `.keystore` + mật khẩu → backup offline
- Đây là **key “cũ”** trong lineage

### 2. Tạo keystore mới

```bash
keytool -genkeypair -v \
  -keystore kinh-release-v2.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias kinh_release_v2
```

### 3. Xuất chứng chỉ (cert) cũ và mới

```bash
keytool -exportcert -keystore kinh-release.jks -alias <ALIAS_CU> -file old.cert
keytool -exportcert -keystore kinh-release-v2.jks -alias kinh_release_v2 -file new.cert
```

### 4. Ký APK với rotation (minh họa)

Sau khi `flutter build apk --release` ra `app-release-unsigned.apk` (hoặc APK đã align):

```bash
# Ví dụ — chỉnh path apksigner theo SDK
apksigner sign \
  --ks kinh-release-v2.jks \
  --ks-key-alias kinh_release_v2 \
  --next-signer \
  --ks kinh-release.jks \
  --ks-key-alias <ALIAS_CU> \
  --lineage lineage.bin \
  --out Kinh-rotated.apk \
  app-release.apk
```

**Lần đầu** tạo lineage có thể dùng:

```bash
apksigner rotate \
  --old-signer --ks kinh-release.jks --ks-key-alias <ALIAS_CU> \
  --new-signer --ks kinh-release-v2.jks --ks-key-alias kinh_release_v2 \
  --out lineage.bin
```

Sau đó các bản sau ký bằng key mới **kèm** `--lineage lineage.bin` (và tùy bản build-tools, cấu hình multi-signer đúng doc Google).

> Cú pháp `apksigner` có thể khác nhẹ theo version build-tools — luôn đối chiếu:  
> https://developer.android.com/studio/command-line/apksigner  
> mục *Signing using key rotation* / *lineage*.

### 5. Firebase / Google Sign-In

Mỗi keystore có **SHA-1/SHA-256 khác**. Sau rotation:

1. Firebase → Project settings → Android app  
2. **Thêm** SHA-1 (và SHA-256) của keystore **mới** (giữ SHA cũ trong thời gian chuyển tiếp nếu cần)  
3. Tải lại `google-services` nếu bạn dùng file đó (pipeline Kính chủ yếu dùng `firebase_options.dart`)

### 6. CI GitHub Actions (dự phòng, chưa bật mặc định)

Secrets gợi ý khi tới lúc xoay:

| Secret | Ý nghĩa |
|--------|---------|
| `KEYSTORE_BASE64` | Keystore **đang** dùng ký release (sau rotate = v2) |
| `KEYSTORE_PASSWORD` / `KEY_PASSWORD` / `KEYSTORE_ALIAS` | như hiện tại |
| `KEYSTORE_OLD_BASE64` | (tuỳ chọn) keystore cũ — chỉ khi job còn tạo lineage |
| `LINEAGE_BASE64` | file `lineage.bin` đã tạo offline |

**Khuyến nghị:** tạo `lineage.bin` **một lần trên máy tin cậy**, lưu secret `LINEAGE_BASE64`; CI chỉ:

1. Decode keystore mới + lineage  
2. `apksigner sign ... --lineage lineage.bin`  
3. Upload APK  

Không commit keystore / lineage / mật khẩu lên git.

## Việc **không** làm nhầm

- Đổi keystore **không** có lineage → user **bắt buộc gỡ app** mới cài được (mất data local trừ khi backup).
- Xóa SHA-1 key cũ trên Firebase quá sớm khi còn user bản cũ.
- Coi key rotation là cách “giấu” Firebase API key (hai chuyện khác nhau).

## Trạng thái repo Kính

- Pipeline hiện ký **một** keystore release (secrets CI).
- File này là **dự phòng**: khi cần xoay khóa, làm offline bước lineage → cập nhật secrets → (tuỳ chọn) thêm bước `apksigner` trong workflow.
- **Chưa** bắt buộc bật rotation trên mọi build hàng ngày (chỉ khi đổi key).
