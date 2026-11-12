# DCSV Digital CMS

**Phần mềm quản lý nội dung và tài nguyên số bảo tàng tích hợp (Museum Digital CMS)**, áp dụng cho
**Bảo tàng Dòng chảy Sử Việt (DCSV)** – một bảo tàng lịch sử Việt Nam giả định, trưng bày theo 5 khu:
Khởi nguồn, Giao thoa, Rồng bay, Vững nền, Hoàng triều.

Đồ án môn Công nghệ phần mềm – Nhóm 8 (Culi1150C1).

> **Trạng thái:** repo mới có khung dự án (backend trả `/api/health`, frontend có 4 trang giữ chỗ).
> Chức năng nghiệp vụ sẽ làm theo sprint, xem [docs/quan-ly/backlog.md](docs/quan-ly/backlog.md).

## Hệ thống làm gì

Một luồng hoàn chỉnh: **nhập hiện vật → viết mô tả → duyệt → khách xem → mua vé online → soát vé QR**.

| Epic | Nội dung | User Story |
|---|---|---|
| E01 | Quản lý người dùng | US01–US04 |
| E02 | Quản lý hiện vật và tài nguyên số | US05–US07 |
| E03 | Biên tập và duyệt nội dung | US08–US11 |
| E04 | Cổng thông tin công khai | US12–US16 |
| E05 | Bán vé và soát vé | US17–US21 |
| E06 | Thống kê và báo cáo | US22 |

Tác nhân: Quản trị viên, Quản lý bảo tàng, Chuyên viên sưu tập, Biên tập viên, Nhân viên quầy vé (nội bộ);
Khách tham quan, Thành viên (công chúng).

## Công nghệ

| Phần | Công nghệ |
|---|---|
| Giao diện | Flutter (Web): cổng công khai, trang quản trị, màn hình soát vé |
| Backend | C++20 + Drogon (REST API) |
| CSDL | PostgreSQL 17 (extension `unaccent`) |
| Triển khai | Docker Compose |
| Dịch vụ ngoài | VNPay Sandbox (thanh toán), Cloudinary (lưu ảnh), Brevo (email) |
| Kiểm thử | GoogleTest (backend), `flutter test` (frontend) |

## Cấu trúc thư mục

```
backend/            Máy chủ REST: C++20 + Drogon
  src/controllers   Nhận yêu cầu HTTP, trả JSON
  src/services      Quy tắc nghiệp vụ
  src/repositories  Truy vấn CSDL
  src/models        Thực thể và DTO
  src/filters       Kiểm tra đăng nhập và vai trò
  src/integrations  VNPay, Brevo, Cloudinary
  src/jobs          Việc chạy định kỳ (hủy đơn quá hạn)
  src/utils         Hàm dùng chung, logic thuần C++
  tests             Unit test (GoogleTest)
frontend/           Giao diện Flutter Web
  lib/core          Cấu hình, gọi API, định tuyến, định dạng
  lib/features      Mỗi nhóm chức năng một thư mục
database/init       File SQL chạy khi tạo CSDL mới
docs/               Đặc tả, thiết kế, sơ đồ UML, backlog
docker-compose.yml  PostgreSQL + backend
```

## Chạy dự án

### Cần cài trước

- Git
- Docker và Docker Compose (plugin `docker compose`)
- Flutter SDK bản stable, từ 3.47 trở lên (để chạy frontend)

### 1. Lấy mã nguồn và tạo file cấu hình

```bash
git clone https://github.com/ChienMinh0605/CNPM_Nhom8_Culi1150C1.git
```

```bash
cd CNPM_Nhom8_Culi1150C1
```

```bash
cp .env.example .env
```

Mở `.env` và đổi `POSTGRES_PASSWORD`, `JWT_SECRET`. Các khóa VNPay, Cloudinary, Brevo để trống cho tới khi làm tới phần đó.

### 2. Chạy CSDL và backend

```bash
docker compose up --build
```

Lần đầu sẽ tải image và biên dịch backend nên mất vài phút. Kiểm tra:

```bash
curl http://localhost:8080/api/health
```

```bash
curl http://localhost:8080/api/health/db
```

Kết quả mong đợi lần lượt là `{"service":"dcsv-backend","status":"ok"}` và `{"database":"ok"}`.

### 3. Chạy frontend

```bash
cd frontend
```

```bash
flutter pub get
```

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

Trang chủ sẽ báo «Đã kết nối backend» nếu bước 2 đang chạy.
Nếu Flutter báo thiếu file nền tảng web, chạy `flutter create --platforms web .` một lần trong thư mục `frontend/`.

### Chạy kiểm thử

Backend (không cần cài Drogon, chỉ cần CMake và g++):

```bash
cmake -S backend -B backend/build -DBUILD_SERVER=OFF -DBUILD_TESTS=ON
```

```bash
cmake --build backend/build
```

```bash
ctest --test-dir backend/build --output-on-failure
```

Frontend:

```bash
cd frontend && flutter test
```

## Tài liệu

- [Tài liệu đặc tả yêu cầu](docs/yeu-cau/DacTaYeuCau_DCSV_DigitalCMS.docx): 22 User Story, 46 FR, 13 NFR
- [Ma trận phân quyền v1.0](docs/yeu-cau/MaTranPhanQuyen_DCSV_DigitalCMS_v10.docx)
- [Kiến trúc và cách tổ chức mã nguồn](docs/thiet-ke/kien-truc.md)
- [Bản nháp API](docs/thiet-ke/api.md)
- [Sơ đồ UML và danh sách hình](docs/README.md)
- [Backlog theo sprint](docs/quan-ly/backlog.md)
- [Quy ước làm việc của nhóm](CONTRIBUTING.md)

## Kế hoạch

| Giai đoạn | Nội dung |
|---|---|
| Thiết kế chi tiết | ERD, wireframe, đặc tả API, khung dự án |
| Sprint 1 | E01 + E02: đăng nhập, phân quyền, hồ sơ hiện vật, ảnh |
| Sprint 2 | E03 + E04: biên tập, duyệt, cổng thông tin công khai |
| Sprint 3 | E05 + E06: bán vé, VNPay Sandbox, soát vé QR, báo cáo |
| Kiểm thử và hoàn thiện | Test case từ FR, 100–200 hiện vật mẫu, demo |

## Nhóm thực hiện

Nhóm 8 – Culi1150C1, môn Công nghệ phần mềm, Khoa Điện tử và Trí tuệ nhân tạo,
Trường Đại học Bách khoa – Đại học Đà Nẵng.

- Lê Minh Chiến
- Nguyễn Đức Hải
- Đinh Tiến Trung

Giảng viên hướng dẫn: TS. Đào Duy Tuấn
