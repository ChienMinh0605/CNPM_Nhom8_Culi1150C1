-- Dữ liệu mẫu. Giá vé là giá giả định, Quản lý bảo tàng sửa được ở trang quản trị.

-- 4 loại vé mẫu (FR34).
INSERT INTO ticket_types (name, audience, price) VALUES
  ('Người lớn',      'Khách từ 16 đến 59 tuổi',       40000),
  ('Sinh viên',      'Sinh viên có thẻ còn hạn',      20000),
  ('Trẻ em',         'Trẻ em từ 6 đến 15 tuổi',       10000),
  ('Người cao tuổi', 'Khách từ 60 tuổi',              20000);
