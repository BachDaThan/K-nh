# 0.8.2 — Fix ký APK (cài đè)

## Nguyên nhân cài đè fail dù đã có secrets
Flutter 3.47 sinh `android/app/build.gradle.kts` (Kotlin DSL).
Script cũ chỉ patch `build.gradle` (Groovy) → **bỏ qua ký** → APK vẫn debug/default key → Android từ chối cài đè.

## Sửa
- `tool/ci_inject_signing.py` hỗ trợ **cả .kts và .gradle**
- CI fail nếu inject không OK
- CI fail nếu APK vẫn là "Android Debug" cert
