-- Chạy một lần khi tạo CSDL mới (thư mục này được mount vào /docker-entrypoint-initdb.d).
-- unaccent: tìm kiếm không phân biệt có dấu hay không dấu (FR31).
CREATE EXTENSION IF NOT EXISTS unaccent;
