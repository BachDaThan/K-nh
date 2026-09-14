# Fix 0.11.2 — Dashboard trống
Ô "Tìm trên dashboard" bị chèn nhầm vào `Row` (cùng hàng sidebar) → constraint rộng vô hạn, lưới Bento không vẽ.
Đã chuyển ô tìm vào `CustomScrollView` (sliver đầu).
