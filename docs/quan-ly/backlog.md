# Backlog và phân công

Nguồn: [Tài liệu đặc tả yêu cầu](../yeu-cau/DacTaYeuCau_DCSV_DigitalCMS.docx). Đánh dấu `[x]` khi User Story đã gộp vào `main`.

## Phân công theo mảng

Mỗi người làm trọn mảng của mình: bảng dữ liệu, API C++, màn hình Flutter và test.

| Người | Mảng | User Story | Số FR |
|---|---|---|---|
| **Trung** | Tài khoản, phân quyền và cổng công khai | US01–US04, US11–US16 | 17 |
| **Hải** | Hiện vật, biên tập và duyệt, báo cáo | US05–US10, US22 | 17 |
| **Chiến** | Bán vé và soát vé | US17–US21 | 12 |

## Thiết kế chi tiết (trước Sprint 1)

- [ ] ERD: mỗi người thiết kế bảng cho mảng mình, ghép thành `database/init/02_schema.sql`
- [ ] Wireframe màn hình của mảng mình
- [ ] Chốt đặc tả API
- [x] Khung dự án Flutter + Drogon + Docker

## Sprint 1

| Xong | US | Tên | Ưu tiên | FR | Phụ trách |
|---|---|---|---|---|---|
| [ ] | US01 | Đăng nhập và đăng xuất | Must | FR01–FR03 | Trung |
| [ ] | US03 | Quản lý tài khoản nhân viên và vai trò | Must | FR05–FR07 | Trung |
| [ ] | US04 | Đăng ký tài khoản Thành viên | Must | FR08 | Trung |
| [ ] | US05 | Quản lý hồ sơ hiện vật | Must | FR09–FR12 | Hải |
| [ ] | US06 | Quản lý ảnh và tài nguyên số | Must | FR13–FR15 | Hải |
| [ ] | US07 | Quản lý khu trưng bày | Should | FR16 | Hải |
| [ ] | US17 | Thiết lập loại vé và giá vé | Must | FR34–FR35 | Chiến |
| [ ] | US18 | Thiết lập khung giờ, sức chứa và ngày đóng cửa | Must | FR36–FR37 | Chiến |

Ưu tiên tuần đầu: Trung xong đăng nhập và bộ lọc vai trò (US01, US03) để Hải và Chiến khóa API theo vai trò.
Chiến làm thêm bản thử ký và kiểm tra chữ ký VNPay Sandbox.

## Sprint 2

| Xong | US | Tên | Ưu tiên | FR | Phụ trách |
|---|---|---|---|---|---|
| [ ] | US02 | Quên mật khẩu | Should | FR04 | Trung |
| [ ] | US12 | Xem trang chủ và thông tin tham quan | Must | FR28–FR29 | Trung |
| [ ] | US13 | Duyệt hiện vật theo khu trưng bày | Must | FR30 | Trung |
| [ ] | US14 | Tìm kiếm hiện vật | Must | FR31 | Trung |
| [ ] | US15 | Xem chi tiết hiện vật | Must | FR32 | Trung |
| [ ] | US08 | Viết mô tả công chúng cho hiện vật | Must | FR17–FR18 | Hải |
| [ ] | US09 | Gửi duyệt và chỉnh sửa nội dung | Must | FR19–FR21 | Hải |
| [ ] | US10 | Duyệt, xuất bản và gỡ nội dung | Must | FR22–FR24 | Hải |
| [ ] | US19 | Mua vé online | Must | FR38–FR41 | Chiến |
| [ ] | US20 | Xem vé của tôi | Must | FR42 | Chiến |

Hải viết luồng duyệt (Nháp → Chờ duyệt → Đã xuất bản → Đã gỡ) để dùng chung được cho triển lãm ở Sprint 3.

## Sprint 3

| Xong | US | Tên | Ưu tiên | FR | Phụ trách |
|---|---|---|---|---|---|
| [ ] | US11 | Tạo trang triển lãm | Must | FR25–FR27 | Trung |
| [ ] | US16 | Xem triển lãm trực tuyến | Must | FR33 | Trung |
| [ ] | US22 | Xem báo cáo doanh thu và lượt khách | Should | FR46 | Hải |
| [ ] | US21 | Soát vé bằng mã QR | Must | FR43–FR45 | Chiến |

Chiến kiểm tra thêm việc không bán vượt sức chứa khi nhiều người mua cùng lúc (NFR07).

## Kiểm thử và hoàn thiện

- [ ] Test case viết từ FR của mảng mình (mỗi người)
- [ ] Nhập 100–200 hiện vật mẫu, ảnh ghi nguồn và giấy phép: Trung 2 khu, Hải 2 khu, Chiến 1 khu
- [ ] Kiểm tra 13 NFR
- [ ] Chuẩn bị demo

## Quy ước phối hợp

- Duyệt PR chéo: Trung duyệt PR của Hải, Hải duyệt PR của Chiến, Chiến duyệt PR của Trung.
- File dùng chung (`backend/src/main.cc`, `frontend/lib/core/router.dart`, file schema): sửa nhỏ, báo nhóm trước khi sửa.
- Họp ngắn 15 phút mỗi tuần: đã xong gì, đang vướng gì.
