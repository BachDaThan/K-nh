# Chính sách quyền riêng tư — Kính

**Cập nhật:** 2026-09-14  
**Ứng dụng:** Kính (`com.bachdathan.kinh`)

## Dữ liệu thu thập

- **Trên thiết bị:** lịch sử duyệt, bookmark, ghi chú, cài đặt, tin nhắn offline mesh — lưu local.
- **Firebase (nếu bật Cộng đồng + đăng nhập Google):** ID tài khoản Google, tên/ảnh hiển thị, tin nhắn chat, trạng thái online — theo rules Realtime Database bạn cấu hình.
- **Google Drive (nếu bật sync):** file backup do bạn chọn đồng bộ.
- **Không** bán dữ liệu cho bên thứ ba quảng cáo.

## Mạng & DNS

- DoH (DNS-over-HTTPS) là tùy chọn; System WebView có thể không inject DNS tầng OS đầy đủ.
- Safe Browsing trong app là **danh sách local**, không gửi URL lên Google Safe Browsing API trừ khi bạn dùng dịch vụ Google khác (Đăng nhập/Drive).

## Mesh / Bluetooth / Wi‑Fi Direct

- Chỉ hoạt động khi bạn bật tính năng tương ứng.
- Peer gần cần cùng cài app (hoặc cùng LAN với chat gần).

## Liên hệ

Chủ sở hữu repo / nhà phát triển: tài khoản GitHub **BachDaThan**.

Bạn có quyền xóa dữ liệu local bằng xóa dữ liệu app; xóa tài khoản Firebase theo quy trình Google Account.
