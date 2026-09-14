# Chính sách quyền riêng tư — ứng dụng Kính

**Ứng dụng:** Kính (`com.bachdathan.kinh`; bản Plus: `com.bachdathan.kinh.plus` nếu có)  
**Cập nhật:** 2026-09-14  
**Repo:** https://github.com/BachDaThan/K-nh  

Triết lý: **ưu tiên xử lý trên thiết bị**. Google / Firebase / Drive **chỉ khi bạn chủ động dùng**.

---

## 1. Tóm tắt một phút

| Loại dữ liệu | Lưu ở đâu | Khi nào |
|--------------|-----------|---------|
| Lịch sử duyệt, bookmark, ghi chú, cài đặt, low-end | **Chỉ trên máy** | Khi bạn dùng tính năng tương ứng |
| File xuất (HTML / MD / CSV) | Thư mục export trên máy | Khi bạn bấm Xuất dữ liệu |
| Tin LAN mesh / Premium Mesh / SOS | Máy bạn + máy peer (P2P) | Khi bật mesh/LAN/SOS |
| Chat **Cộng đồng** | **Firebase** (cloud Google, project gắn app) | Khi đăng nhập Google và nhắn tin |
| Backup Drive | **Google Drive của bạn** | Khi bạn bật sync và chọn |
| API key AI | Trên máy (bạn nhập) | Khi dùng AI Builder |

- **Không** bán dữ liệu cho mạng quảng cáo bên thứ ba.  
- **Không** cài đặt ứng dụng khác ngầm.  
- Cập nhật app: tải file → **bạn xác nhận cài**.

---

## 2. Hai nhóm người với Cộng đồng (tránh hiểu nhầm)

### Người chỉ cài APK từ Releases
Bạn **không** phải tạo project Firebase hay gửi SHA-1.  
Đăng nhập Google (nếu muốn chat Cộng đồng) dùng cấu hình **nhà phát hành** đã gắn sẵn.  
Dữ liệu chat Cộng đồng vẫn nằm trên **Firebase của project app**, không phải “chỉ offline trên máy”.

### Người tự build từ mã nguồn
Bạn (hoặc org của bạn) chịu trách nhiệm cấu hình Firebase / SHA-1 / Web client ID cho **chữ ký APK của bạn**.  
Web client ID có thể lưu local trên máy (SharedPreferences) qua màn hình trong app — chỉ phục vụ Google Sign-In, không phải kênh gửi chat cho tác giả ngoài luồng Firebase.

---

## 3. Dữ liệu trên thiết bị

- Trang web do **System WebView** (Android) / **WebView2** (Windows) tải — hành vi gần trình duyệt hệ thống.  
- DoH, ad-block nhẹ, reader: cấu hình và chạy phía client (WebView hệ thống có giới hạn inject DNS toàn OS).  
- “Duyệt web an toàn” trong app: **heuristic / danh sách local**, không đồng nghĩa mọi URL được gửi lên Google Safe Browsing API.  
- Nhật ký hoạt động, ẩn danh: theo thiết kế local của từng phiên bản.  
- **Xuất dữ liệu:** bạn tạo file trên máy; app không tự upload file export lên server Kính.

---

## 4. Firebase & Google (tuỳ chọn)

### 4.1 Cộng đồng
Khi đăng nhập và chat: có thể lưu UID Google, tên/ảnh hiển thị, nội dung tin, trạng thái online trên **Firebase Realtime Database**.  
**Ai có quyền Firebase Console của project đó** (thường chủ phát hành) *về nguyên tắc kỹ thuật* có thể truy cập dữ liệu database — giống hầu hết app dùng Firebase.  
Không muốn → **không dùng Cộng đồng**; vẫn dùng chat LAN/Mesh.

### 4.2 Google Drive
Chỉ khi bạn ủy quyền và bật sync. Phạm vi theo OAuth đã xin (file backup bạn chọn), không mô tả là “đọc cả Drive” nếu không được cấp.

### 4.3 AI Builder
Key và nội dung gửi model thuộc nhà cung cấp **bạn** cấu hình. Kính không vận hành server model riêng (trừ sandbox chạy trên máy nếu có).

---

## 5. Mesh, Bluetooth, Wi‑Fi Direct, SOS, gọi offline

- Chỉ chạy khi bạn mở tính năng.  
- Peer có thể thấy ID/tên mesh bạn chọn và tín hiệu radio gần.  
- SOS gửi **tin văn bản** (và thông tin kèm theo nếu bạn cho phép) tới máy Kính đang ở gần — **không** qua server Kính.  
- Gọi 1-hop: micro → truyền P2P. **Không cam kết** khoảng cách kilomet chỉ bằng điện thoại thường; gọi ổn định nhất ở **một hop**.

---

## 6. Quyền hệ thống (Android) — khi nào cần

| Quyền | Mục đích |
|-------|----------|
| Internet | Duyệt web, OTA, Firebase/Drive nếu bật |
| Bluetooth / thiết bị lân cận | Mesh / quét peer |
| Micro | Gọi mesh 1-hop |
| Vị trí (một số máy) | Hệ thống có thể yêu cầu kèm quét BLE/WFD — app không dùng theo dõi bản đồ nếu không có tính năng bản đồ |

---

## 7. Trẻ em

App không nhắm đối tượng trẻ em dưới độ tuổi theo chính sách khu vực / cửa hàng. Không cố ý thu thập dữ liệu trẻ em.

---

## 8. Quyền của bạn

- Xóa dữ liệu local: Cài đặt hệ thống → Ứng dụng → Kính → Xóa dữ liệu / gỡ cài đặt.  
- Thu hồi Google / Drive: tài khoản Google → quyền ứng dụng bên thứ ba.  
- Ngừng Cộng đồng: đăng xuất / không mở tính năng; yêu cầu xóa dữ liệu cloud theo chủ project Firebase nếu cần.

---

## 9. Liên hệ

Repo / nhà phát triển: **https://github.com/BachDaThan/K-nh** · **BachDaThan**  

Bản mới nhất của chính sách: file `PRIVACY.md` trên nhánh `main`. Xem thêm `FAQ.md`.
