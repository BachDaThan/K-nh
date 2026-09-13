# 0.9.9 — Audio truyện

## Có
- Thẻ **Audio truyện**: dán link chương → tải HTML → TTS
- Tự chuyển chương sau (heuristic link)
- Giọng **máy offline** (đổi giọng, free, không API key)
- Volume TTS / nhạc **tách**
- Playlist MP3: thêm, kéo sắp xếp, lặp list / 1 bài
- Catalog `vbookext.me/api/plugin.json` (mở nguồn — không chạy plugin.zip)

## Giới hạn thật
- Khóa màn hình: wakelock + TTS audio category — **máy/OS có thể vẫn cắt** nếu tối ưu pin mạnh; Android nên bỏ tối ưu pin cho Kính.
- Không phải foreground media service đầy đủ như Spotify.
- Không chạy plugin vBook zip; chỉ heuristic HTML + list nguồn.
- Site chặn bot có thể không lấy được chữ → dùng Reader/TTS trong trình duyệt Kính.
