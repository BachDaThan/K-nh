# Câu hỏi thường gặp — Kính

Ngôn ngữ đời thường. Chi tiết kỹ thuật xem `PRIVACY.md` và `PROGRESS.md`.

## 1. Tôi không biết code — có dùng được app không?

**Có.** Duyệt web, ghi chú, bookmark, sao lưu trên máy, chat gần (LAN/hotspot), đọc sách/TTS… **không cần** viết code.

Chỉ khi bạn muốn **Cộng đồng online (Firebase)** hoặc **Drive** thì cần làm vài bước trên trang Google/Firebase (hoặc dán Web client ID trong app — mục Hướng dẫn Cộng đồng).

## 2. Bắt buộc đăng nhập Google không?

**Không.** Không đăng nhập vẫn dùng gần như toàn bộ phần local.

Đăng nhập Google **chỉ** để: chat Cộng đồng, đồng bộ Drive (nếu bật).

## 3. Tác giả app có đọc được tin nhắn của tôi không?

- **Chat gần / Mesh offline:** tin đi máy ↔ máy, **không** qua server Kính. Tác giả **không** nhận được nội dung đó.
- **Cộng đồng (Firebase):** tin nằm trên **Firebase project** gắn app. Người **có quyền Console** project đó (thường là chủ repo) *về mặt kỹ thuật* có thể xem dữ liệu database — giống mọi app dùng Firebase. Đây **không** phải “chỉ trên máy”. Không muốn vậy thì **đừng dùng Cộng đồng**.

## 4. Mesh / “kiểu Bitchat” có gửi tin đi internet không?

**Không bắt buộc.** LAN mesh và Premium Mesh thiết kế **P2P / local**.  
App **không** cam kết tầm vài km chỉ bằng điện thoại; gọi thoại ổn định nhất **1 máy gần (1-hop)**.

## 5. “Duyệt an toàn” có gửi URL cho Google không?

Mức trong app là **lọc/heuristic local**. **Không** đồng nghĩa mọi URL được gửi lên Google Safe Browsing API.

## 6. Cập nhật app có tự cài ngầm không?

**Không.** Có bản mới → tải → **bạn bấm xác nhận cài**.

## 7. Low-end mode là gì?

Chế độ máy yếu: giảm animation, hạn chế tab, ưu tiên nhẹ hơn. Bật trong Cài đặt trình duyệt / hiệu năng.

## 8. SOS nhanh là gì?

Một nút gửi tin cố định (“cần hỗ trợ / đang ổn…”) tới **mọi máy Kính gần** trên mesh/LAN — không cần gõ từng peer. Có thể kèm GPS **chỉ khi bạn cho phép**.

## 9. Xuất dữ liệu để làm gì?

Export bookmark (HTML mở được bằng Chrome/Firefox), ghi chú (Markdown), lịch sử (CSV) — **không nhốt data** trong app.
