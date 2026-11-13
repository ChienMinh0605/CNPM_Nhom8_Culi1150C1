# database

- `init/`: các file `.sql` chạy **một lần** khi PostgreSQL tạo CSDL mới, theo thứ tự tên file.
  Hiện chỉ có `01_extensions.sql` (bật `unaccent`).
- Lược đồ bảng (schema) chưa có: sẽ viết sau khi nhóm chốt ERD ở giai đoạn thiết kế chi tiết,
  dựa trên mô hình khái niệm Hình 10 (`docs/thiet-ke/uml/Class/CD01_MoHinhKhaiNiem.png`).
  Dự kiến đặt tên `02_schema.sql`, `03_seed.sql` (5 khu trưng bày, 4 loại vé mẫu).

Các file trong `init/` chỉ chạy khi volume dữ liệu còn trống. Muốn chạy lại thì dừng các
container và xóa volume `db_data` (lệnh `docker compose down` kèm tùy chọn `-v`); thao tác này
xóa toàn bộ dữ liệu trong CSDL phát triển.
