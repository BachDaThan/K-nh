# Tiến độ Kính

Version: **0.14.0** — xem `PRIVACY.md`, `FAQ.md`.

## Triết lý
Local-first · Firebase/Drive **tuỳ chọn** · không silent-install · không overclaim mesh km.

## 0.14.0 — Đủ 5 đề xuất UX/minh bạch

1. **Hướng dẫn Cộng đồng trong app** — dán Web client ID (không sửa code); SHA-1 vẫn trên Firebase Console  
2. **SOS nhanh** — Dashboard + Premium Mesh: broadcast tin cố định qua LAN mesh (+ native nếu đang chạy)  
3. **Xuất dữ liệu** — bookmark `.html`, notes `.md`, history `.csv` → Documents/`kinh_export`  
4. **Low-end mode** — mô tả rõ: tối đa 3 tab, giảm animation (`PerformanceService.descriptionVi`)  
5. **FAQ.md + màn FAQ trong app** — Google / mesh / OTA bằng tiếng đời thường  

## Phân loại
- **Local:** browser, export, SOS, LAN/mesh, low-end, FAQ  
- **Tuỳ chọn cloud:** Cộng đồng, Drive  
- **Không hứa:** mesh vài km chỉ ĐT, silent install  

## 6 bước gốc
Đã có trên `main`. Cloud Auth: user tự SHA-1 nếu dùng Cộng đồng.
