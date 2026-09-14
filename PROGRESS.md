# Chat v2 — ID, danh hiệu tên, TTL 30 ngày, rate-limit

## Sửa đăng nhập
- Hiện rõ trạng thái ✅ đã login / lỗi Auth cụ thể (SHA-1, hủy, token)
- storageBucket sửa `kinh-7713d.appspot.com`
- databaseURL không trailing slash lạ

## Tính năng mới
- Public ID 6 ký tự + tìm + DM
- Danh hiệu tên #1, #2… + chip glow trong chat + trang cá nhân
- Rank field (member/mod/admin) — admin gán tay trên RTDB `users/{uid}/rank`
- Rate limit 2 tin/giây, 20/phút
- Page/topic inactive 30 ngày → purge khi mở Cộng đồng

## Không làm (kỹ thuật / an toàn)
- Mesh “không WiFi/BT/4G, không dấu vết”: không khả thi hợp pháp trên ĐT consumer
- Bluetooth chỉ-bật-trong-app + quên máy: có thể làm sau cho tính năng gần; không phải kênh ẩn
- Dịch “như người bản xứ” + call dịch realtime: cần model/API + WebRTC, làm giai riêng
