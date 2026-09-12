#!/usr/bin/env python3
"""
Script ký Hot Patch bằng Ed25519 — CHẠY THỦ CÔNG TRÊN MÁY BẠN.

KHÔNG đưa file này vào GitHub Actions / CI. KHÔNG đưa private key vào
repo hay GitHub Secrets. Private key CHỈ nằm trên máy bạn, offline.

Cài đặt (1 lần):
    pip install cryptography

Cách dùng:
    1. Sửa nội dung PATCH_CONTENT bên dưới (hoặc đọc từ file khác).
    2. Chạy: python3 sign_hotpatch.py
    3. File hotpatch.json được tạo ra, đã có chữ ký.
    4. Tự tay: git add hotpatch.json && git commit && git push
"""

import base64
import json
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

# ============================================================
# DÁN PRIVATE KEY (base64) CỦA BẠN VÀO ĐÂY — GIỮ FILE NÀY BÍ MẬT
# TUYỆT ĐỐI, KHÔNG COMMIT FILE NÀY LÊN GIT SAU KHI ĐIỀN KEY.
# ============================================================
PRIVATE_KEY_BASE64 = "DÁN_PRIVATE_KEY_CỦA_BẠN_VÀO_ĐÂY"

# Số patch tăng dần mỗi lần phát hành (không phải version app).
PATCH_VERSION = 1

# Nội dung cần vá — điền cái nào cần, để trống (None) cái không dùng.
PATCH_CONTENT = {
    "patch_version": PATCH_VERSION,
    "runner_html": None,       # dán HTML runner mới vào đây nếu muốn vá
    "dashboard_notice": None,  # vd: "Bảo trì server AI lúc 22h tối nay"
}


def build_canonical_payload(patch_version, runner_html, dashboard_notice):
    """
    PHẢI khớp CHÍNH XÁC với hàm _buildCanonicalPayload() trong
    lib/update/services/hot_update_service.dart — cùng thứ tự field,
    cùng cách nối chuỗi, cùng cách biểu diễn giá trị rỗng (chuỗi rỗng,
    không phải "None"/"null").
    """
    parts = [
        f"patch_version={patch_version}",
        f"runner_html={runner_html or ''}",
        f"dashboard_notice={dashboard_notice or ''}",
    ]
    return "\n".join(parts)


def sign_patch():
    if PRIVATE_KEY_BASE64 == "DÁN_PRIVATE_KEY_CỦA_BẠN_VÀO_ĐÂY":
        print("❌ Bạn chưa điền PRIVATE_KEY_BASE64. Dừng lại để tránh ký sai.")
        return

    private_key_bytes = base64.b64decode(PRIVATE_KEY_BASE64)
    private_key = Ed25519PrivateKey.from_private_bytes(private_key_bytes)

    runner_html = PATCH_CONTENT.get('runner_html')
    dashboard_notice = PATCH_CONTENT.get('dashboard_notice')

    canonical_payload = build_canonical_payload(
        PATCH_VERSION, runner_html, dashboard_notice
    )
    payload_bytes = canonical_payload.encode('utf-8')

    signature = private_key.sign(payload_bytes)
    signature_b64 = base64.b64encode(signature).decode()

    output = {
        "patch_version": PATCH_VERSION,
        "runner_html": runner_html,
        "dashboard_notice": dashboard_notice,
        "signature": signature_b64,
    }

    with open('hotpatch.json', 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print("✅ Đã tạo hotpatch.json, đã ký.")
    print("   Canonical payload đã ký (để đối chiếu, không phải nội dung file):")
    print("  ", repr(canonical_payload))
    print("   Tiếp theo: git add hotpatch.json && git commit -m 'hotpatch vN' && git push")


if __name__ == '__main__':
    sign_patch()
