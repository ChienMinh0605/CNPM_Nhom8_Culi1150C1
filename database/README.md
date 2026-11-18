# database

- `init/`: các file `.sql` chạy **một lần** khi PostgreSQL tạo CSDL mới, theo thứ tự tên file.
  - `01_extensions.sql`: bật `unaccent`.
  - `02_schema.sql`: lược đồ bảng, mỗi mảng một phần. Hiện có phần E05: `ticket_types`,
    `time_slots`, `closed_days`, `ticket_orders`, `order_items`.
  - `03_seed.sql`: dữ liệu mẫu. Hiện có 4 loại vé.

Các file trong `init/` chỉ chạy khi volume dữ liệu còn trống. Muốn chạy lại thì dừng các
container và xóa volume `db_data` (lệnh `docker compose down` kèm tùy chọn `-v`); thao tác này
xóa toàn bộ dữ liệu trong CSDL phát triển.
