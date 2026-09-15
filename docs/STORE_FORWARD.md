# Store-and-Forward (text only)

## Làm được (đã code)
- Hàng đợi local JSON (`kinh_sf_queue.json`)
- Gói tin `t: sf` trên LAN UDP mesh
- TTL hop (mặc định 5), dedup `msgId`, hết hạn ~7 ngày
- Khi gặp peer: flush queue; máy trung gian giữ và relay
- UI: Chat gần → nút **outbox** = gửi S&F; SOS cũng enqueue S&F

## Không làm (Gemini overclaim)
- Briar đầy đủ / CouchDB sync
- Nostr internet relay
- Voice multi-hop, Codec2, FEC, ultrasonic, quantum, Li-Fi
- “Hàng chục km chắc chắn” — phụ thuộc người mang máy đi gặp nhau

## Cách thử
1. Máy A gửi S&F (nút outbox), có thể tắt mesh sau vài giây.
2. Máy B gặp A (cùng hotspot) nhận / mang hàng đợi.
3. Máy B gặp C → C có thể nhận nếu còn TTL.
