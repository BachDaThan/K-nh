# 0.9.7 — Rollback Gecko

## Lỗi CI
`webview_flutter` không cho 2 implementation cùng lúc:
`webview_flutter_android` + `webview_flutter_geckoview`.

## Đã làm
- Gỡ dependency Gecko
- Gỡ bootstrap / radio chọn nhân
- Giữ Chromium / WebView2

## Nhân khác?
Xem phần trả lời: trên Flutter hiện **không có** nhân kiểu Firefox ổn định như GeckoView native.
