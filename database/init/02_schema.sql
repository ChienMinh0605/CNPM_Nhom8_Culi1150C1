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

-- Đơn vé (FR39–FR41). Chỗ được tính là đang giữ khi đơn đã thanh toán, đã sử
-- dụng, hoặc còn chờ thanh toán và chưa quá expires_at.
CREATE TABLE ticket_orders (
  id            BIGSERIAL PRIMARY KEY,
  -- Mã đơn ngẫu nhiên, khó đoán: dùng làm mã giao dịch VNPay và nội dung QR.
  code          TEXT NOT NULL UNIQUE
                DEFAULT upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12)),
  -- shortcut: chưa có bảng tài khoản (US04) nên chưa có khóa ngoại và còn cho
  -- NULL; khi có bảng đó thì thêm NOT NULL REFERENCES.
  member_id     BIGINT,
  visit_date    DATE    NOT NULL,
  time_slot_id  BIGINT  NOT NULL REFERENCES time_slots (id),
  status        TEXT    NOT NULL DEFAULT 'PENDING'
                CHECK (status IN ('PENDING', 'PAID', 'USED', 'CANCELLED')),
  total_amount  INTEGER NOT NULL CHECK (total_amount >= 0),  -- VNĐ
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at    TIMESTAMPTZ NOT NULL,
  paid_at       TIMESTAMPTZ,
  checked_in_at TIMESTAMPTZ
);
CREATE INDEX ticket_orders_slot_day ON ticket_orders (time_slot_id, visit_date);

-- Dòng vé của đơn. unit_price giữ giá lúc mua (NFR08).
CREATE TABLE order_items (
  order_id       BIGINT  NOT NULL REFERENCES ticket_orders (id) ON DELETE CASCADE,
  ticket_type_id BIGINT  NOT NULL REFERENCES ticket_types (id),
  quantity       INTEGER NOT NULL CHECK (quantity > 0),
  unit_price     INTEGER NOT NULL CHECK (unit_price >= 0),
  PRIMARY KEY (order_id, ticket_type_id)
);
