# Câu hỏi thường gặp — Kính

## Cộng đồng / đăng nhập Google — 2 nhóm người

### Nhóm A — Chỉ cài APK có sẵn từ Releases
**Không cần** tạo Firebase, **không cần** SHA-1, **không cần** dán Web client ID.  
Chỉ: cài APK → Cộng đồng → Đăng nhập Google.

Nếu lỗi cấu hình: thường do **nhà phát hành** chưa gắn đúng SHA-1 trên Firebase — bạn không “đăng ký thiếu”.

### Nhóm B — Clone repo / tự build APK
**Cần** cấu hình: bật Google Sign-In, thêm **SHA-1 keystore của bạn**, dán **Web client ID** trong app (Hướng dẫn Cộng đồng) hoặc trong code.  
APK tự build chữ ký khác bản phát hành → bắt buộc bước này.

Chi tiết từng bước: trong app → **Hướng dẫn Cộng đồng** (chọn đúng nhóm).

---

## Các câu hỏi khác

**Không biết code có dùng được không?**  
Có. Duyệt web, ghi chú, mesh/LAN không cần code. Cộng đồng online chỉ cần nếu bạn muốn chat cloud.

**Bắt buộc Google?**  
Không. Local-first: không đăng nhập vẫn dùng phần lớn tính năng.

**Tác giả có đọc tin nhắn?**  
LAN/Mesh: không qua server Kính. Cộng đồng: dữ liệu trên Firebase — người có quyền Console project có thể xem được; không muốn thì đừng dùng Cộng đồng.

**Cập nhật có cài ngầm?**  
Không. Bạn xác nhận cài.

Xem thêm `PRIVACY.md`, `PROGRESS.md`.
