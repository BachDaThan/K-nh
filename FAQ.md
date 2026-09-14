# Câu hỏi thường gặp — Kính

Trả lời bằng tiếng đời thường. Chi tiết pháp lý / kỹ thuật: `PRIVACY.md`, `PROGRESS.md`.  
Trong app: **FAQ riêng tư** và **Hướng dẫn Cộng đồng** (chọn đúng nhóm).

---

## A. Dùng app cơ bản

### 1. Không biết lập trình có dùng được không?
**Có.** Duyệt web, ghi chú, bookmark, xuất dữ liệu, đọc sách/TTS, chat gần (LAN/hotspot), mesh offline (nếu bản APK hỗ trợ) **không cần** viết code.

### 2. Bắt buộc đăng nhập Google không?
**Không.** Không đăng nhập vẫn dùng phần local (trình duyệt, ghi chú, mesh/LAN, SOS, export…).  
Google chỉ cần khi bạn muốn **Cộng đồng online** hoặc **Drive sync**.

### 3. Cập nhật có tự cài ngầm không?
**Không.** App có thể báo/tải bản mới; **cài đặt chỉ sau khi bạn xác nhận**.

### 4. Low-end mode là gì?
Chế độ máy yếu: giảm animation, giới hạn khoảng **3 tab** trình duyệt, ưu tiên nhẹ. Bật trong phần cài đặt / hiệu năng của app.

### 5. Xuất dữ liệu để làm gì?
Để **không bị nhốt trong app**: bookmark ra file HTML (mở/import Chrome/Firefox), ghi chú ra Markdown, lịch sử ra CSV. File nằm thư mục export trên máy.

### 6. SOS nhanh là gì?
Một nút gửi tin cố định (kiểu “cần hỗ trợ / đang kiểm tra liên lạc”) tới **các máy Kính đang ở gần** trên LAN/mesh — không cần gõ từng người. Không đi qua server Kính.

---

## B. Cộng đồng / Firebase — **hai nhóm**

### 7. Tôi chỉ tải Kinh.apk từ Releases — có phải tạo Firebase không?
**Không.**  
Bạn **không** cần SHA-1, **không** cần dán Web client ID.  
Chỉ: cài APK → Cộng đồng → **Đăng nhập Google**.

Nhà phát hành đã gắn Firebase/SHA-1/Web client cho **bản APK họ ký**. Bạn chỉ là người dùng cuối.

### 8. Vậy sao tôi vẫn lỗi CONFIGURATION_NOT_FOUND?
Thường **không phải** vì bạn “chưa đăng ký”.  
Hay gặp: bản APK chưa khớp SHA-1 trên Firebase phía **nhà phát hành**. Hãy báo họ / đợi bản build mới.  
Ô dán Web client ID trong app là **nâng cao**, user APK sẵn ít khi cần.

### 9. Tôi clone repo / tự build APK thì sao?
**Có** việc phải làm:

1. Firebase → bật Google Sign-In  
2. Thêm **SHA-1** của **keystore bạn dùng ký APK** (debug và/hoặc release)  
3. Copy **Web client ID** → dán trong app (**Hướng dẫn Cộng đồng** → nhóm “Tự build”) hoặc cấu hình trong source  
4. Cài lại APK → đăng nhập  

Tự build = chữ ký khác bản Releases → bỏ bước SHA-1 gần như chắc lỗi đăng nhập.

### 10. Tác giả app có đọc được tin nhắn Cộng đồng không?
Tin Cộng đồng nằm trên **Firebase project** gắn app.  
Người **có quyền Console** project đó (thường chủ phát hành) *về mặt kỹ thuật* có thể truy cập dữ liệu database — giống nhiều app dùng Firebase.  
**Không muốn** → đừng dùng Cộng đồng; dùng chat **LAN / Mesh** (P2P, không qua server Kính).

### 11. Chat gần / Mesh có lên internet không?
**Không bắt buộc.** Thiết kế local/P2P.  
App **không** cam kết khoảng cách vài km chỉ bằng điện thoại; gọi thoại ổn định nhất **1 hop** (hai máy kết nối trực tiếp).

---

## C. Duyệt web & an toàn

### 12. “Duyệt an toàn” có gửi URL cho Google không?
Mức trong app là **local**. **Không** đồng nghĩa mọi URL được gửi lên Google Safe Browsing API.

### 13. DoH / DNS trong app hoạt động thế nào?
Bạn chọn resolver DoH trong cài đặt trình duyệt. System WebView có giới hạn: không phải lúc nào cũng thay DNS toàn hệ điều hành như VPN DNS.

---

## D. Khác

### 14. Windows và Android có giống nhau không?
Cùng codebase Flutter; một số thứ (BLE mesh native, launcher app hệ thống, ký APK) **mạnh hơn / chỉ có trên Android**. Windows dùng WebView2 và pipeline EXE riêng.

### 15. Xem chính sách đầy đủ ở đâu?
File **PRIVACY.md** trên repo `main`, và link trong app (Privacy Policy).

---

**Liên hệ / mã nguồn:** https://github.com/BachDaThan/K-nh · BachDaThan
