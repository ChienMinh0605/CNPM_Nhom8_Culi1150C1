-- Lược đồ bảng. Mỗi mảng thêm bảng của mình vào đúng phần bên dưới.

-- ===== E05 – Bán vé và soát vé =====

-- Loại vé (FR34). Loại vé bị tắt không hiện ở trang mua vé (FR35).
CREATE TABLE ticket_types (
  id       BIGSERIAL PRIMARY KEY,
  name     TEXT    NOT NULL,
  audience TEXT    NOT NULL,                      -- đối tượng áp dụng
  price    INTEGER NOT NULL CHECK (price >= 0),   -- VNĐ
  active   BOOLEAN NOT NULL DEFAULT TRUE
);

-- Khung giờ tham quan, áp dụng cho mọi ngày mở cửa (FR36).
-- Ràng buộc EXCLUDE chặn hai khung giờ chồng nhau, kể cả khi tạo cùng lúc;
-- hai khung liền nhau (08:00–10:00 và 10:00–12:00) thì được.
CREATE TYPE timerange AS RANGE (subtype = time);
CREATE TABLE time_slots (
  id         BIGSERIAL PRIMARY KEY,
  start_time TIME    NOT NULL,
  end_time   TIME    NOT NULL,
  capacity   INTEGER NOT NULL CHECK (capacity > 0),
  CHECK (start_time < end_time),
  CONSTRAINT time_slots_no_overlap
    EXCLUDE USING gist (timerange(start_time, end_time) WITH &&)
);

-- Ngày đóng cửa: không bán vé cho những ngày này (FR37).
CREATE TABLE closed_days (
  day    DATE PRIMARY KEY,
  reason TEXT NOT NULL DEFAULT ''
);
