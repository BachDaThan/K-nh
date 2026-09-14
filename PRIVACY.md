# Chính sách quyền riêng tư — ứng dụng Kính

**Ứng dụng:** Kính (`com.bachdathan.kinh`, bản Plus: `com.bachdathan.kinh.plus` nếu có)  
**Cập nhật:** 2026-09-14  
**Triết lý:** ưu tiên xử lý trên thiết bị; dịch vụ Google/Firebase **chỉ khi bạn chủ động bật / đăng nhập**.

---

## 1. Tóm tắt một phút

| Loại dữ liệu | Ở đâu | Khi nào |
|--------------|--------|---------|
| Lịch sử duyệt, bookmark, ghi chú, cài đặt | **Chỉ trên máy** | Luôn (trừ khi bạn xóa dữ liệu app) |
| Tin nhắn chat **LAN / Mesh offline** | Máy bạn + máy peer (P2P) | Khi bật chat gần / mesh |
| Chat **Cộng đồng** | **Firebase** (cloud Google) | Chỉ khi đăng nhập Google & dùng Cộng đồng |
| Backup Drive | **Google Drive** của bạn | Chỉ khi bạn bật sync & chọn |
| API key AI | Trên máy (do bạn nhập) | Khi dùng AI Builder |

**Không** bán dữ liệu cho mạng quảng cáo bên thứ ba.  
**Không** cài đặt ứng dụng khác ngầm.

---

## 2. Dữ liệu xử lý trên thiết bị

- Nội dung trang web do **System WebView / WebView2** tải (giống trình duyệt hệ thống).
- DoH, bộ lọc quảng cáo nhẹ, reader mode: cấu hình và chạy local (WebView hệ thống có giới hạn inject DNS tầng OS).
- “Duyệt web an toàn” trong app: **heuristic / danh sách local**, **không** đồng nghĩa với việc gửi mọi URL lên Google Safe Browsing API.
- Nhật ký hoạt động, chế độ ẩn danh: theo thiết kế local (ẩn danh không ghi bền khi đóng phiên, tùy phiên bản code).

---

## 3. Dữ liệu khi dùng tính năng Google (tuỳ chọn)

### 3.1 Đăng nhập Google + Cộng đồng (Firebase)

- **Thu thập / lưu trên Firebase Realtime Database (project do nhà phát triển cấu hình):**  
  UID Google, tên hiển thị, ảnh đại diện (nếu có), tin nhắn chat, trạng thái online, định danh công khai trong app.
- **Mục đích:** chat cộng đồng, danh sách online, DM.
- **Cơ sở:** bạn bấm đăng nhập và gửi tin.
- **Không dùng Cộng đồng / không đăng nhập** → không phát sinh dữ liệu chat cloud này.

### 3.2 Google Drive sync

- Chỉ khi bạn bật và ủy quyền.
- App đọc/ghi **file backup bạn chọn**, không được cấp quyền “toàn bộ Drive” ngoài phạm vi OAuth đã xin.

### 3.3 AI Builder

- API key và nội dung gửi model: theo nhà cung cấp **bạn** cấu hình (OpenAI/Gemini/…); Kính không vận hành model riêng trừ khi chạy sandbox trên máy (Pyodide/WebView).

---

## 4. Mesh / Bluetooth / Wi‑Fi Direct / gọi offline

- Chỉ chạy khi bạn mở tính năng tương ứng.
- Peer thấy **ID/tên bạn chọn trên mesh**, tín hiệu radio gần (BLE/WFD).
- Cuộc gọi 1-hop: micro thu âm → truyền P2P; **không** đi qua server Kính.
- **Giới hạn công khai:** không cam kết khoảng cách kilomet chỉ bằng điện thoại thường; gọi ổn định nhất ở **1 hop**.

---

## 5. Cập nhật ứng dụng (OTA)

- App có thể tải file cài từ GitHub Releases / URL trong `version.json`.
- **Cài đặt** chỉ sau khi bạn xác nhận (không silent-install).

---

## 6. Quyền hệ thống (Android) — khi nào cần

| Quyền | Lý do |
|-------|--------|
| Internet | Duyệt web, OTA, Firebase/Drive nếu bật |
| Bluetooth / thiết bị lân cận | Mesh / quét peer |
| Micro | Gọi thoại mesh 1-hop |
| Vị trí (một số máy) | Hệ thống gắn với quét BLE/WFD — app **không** dùng để theo dõi bản đồ nếu không có tính năng bản đồ |

---

## 7. Trẻ em

App không nhắm đối tượng trẻ em dưới độ tuổi cho phép theo chính sách cửa hàng / khu vực. Không cố ý thu thập dữ liệu trẻ em.

---

## 8. Quyền của bạn

- Xóa dữ liệu local: Cài đặt hệ thống → Ứng dụng → Kính → Xóa dữ liệu / gỡ cài đặt.
- Chat Firebase: ngừng dùng + có thể yêu cầu xóa dữ liệu trên project (liên hệ nhà phát triển / tự xóa trên Console nếu bạn là chủ project).
- Thu hồi Drive / Google: tài khoản Google → quyền ứng dụng bên thứ ba.

---

## 9. Liên hệ

Nhà phát triển / repo: **https://github.com/BachDaThan/K-nh**  
Tài khoản: **BachDaThan**

Chính sách này có thể cập nhật cùng phiên bản app; bản mới nhất nằm tại file `PRIVACY.md` trên nhánh `main` của repo.
