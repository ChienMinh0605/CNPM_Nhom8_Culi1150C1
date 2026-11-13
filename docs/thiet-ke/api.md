# API – bản nháp

> **Đây là bản nháp** để nhóm bàn ở giai đoạn thiết kế chi tiết. Đường dẫn và dữ liệu có thể đổi.
> Hiện backend mới cài `GET /api/health` và `GET /api/health/db`.

## Quy ước chung

- Tiền tố: `/api/v1`. Dữ liệu vào và ra là JSON, UTF-8.
- Đăng nhập trả về JWT; các yêu cầu sau gửi kèm header `Authorization: Bearer <token>`.
- Ngày dạng `YYYY-MM-DD`, thời điểm dạng ISO 8601; tiền là số nguyên VNĐ. Giao diện tự định dạng lại (NFR10).
- Danh sách có phân trang: tham số `page` (từ 1) và `pageSize`; kết quả `{ "items": [...], "total": n }`.
- Lỗi trả về cùng một dạng:

```json
{ "error": { "code": "FORBIDDEN", "message": "Bạn không có quyền thực hiện thao tác này" } }
```

| Mã HTTP | Khi nào |
|---|---|
| 400 | Dữ liệu vào sai |
| 401 | Chưa đăng nhập hoặc token hết hạn |
| 403 | Không đúng vai trò (NFR03) |
| 404 | Không tìm thấy, hoặc nội dung chưa xuất bản khi gọi từ cổng công khai (NFR04) |
| 409 | Xung đột: email trùng, hết chỗ, khung giờ chồng nhau |

## Danh sách endpoint dự kiến

Vai trò: QTV = Quản trị viên, QL = Quản lý bảo tàng, CV = Chuyên viên sưu tập, BTV = Biên tập viên,
NV = Nhân viên quầy vé, TV = Thành viên.

### E01 – Người dùng

| Phương thức | Đường dẫn | Ai gọi | FR |
|---|---|---|---|
| POST | `/auth/login` | mọi người | FR01, FR02 |
| POST | `/auth/logout` | đã đăng nhập | FR03 |
| POST | `/auth/forgot-password` | mọi người | FR04 |
| POST | `/auth/reset-password` | mọi người | FR04 |
| POST | `/auth/register` | khách | FR08 |
| GET, POST | `/accounts` | QTV | FR05 |
| PUT | `/accounts/{id}` | QTV | FR06 |
| POST | `/accounts/{id}/lock`, `/accounts/{id}/unlock` | QTV | FR06 |

### E02 – Hiện vật và tài nguyên số

| Phương thức | Đường dẫn | Ai gọi | FR |
|---|---|---|---|
| GET | `/artifacts` | nhân viên | FR12 |
| POST | `/artifacts` | CV | FR09, FR10 |
| GET | `/artifacts/{id}` | nhân viên | FR12, FR18 |
| PUT, DELETE | `/artifacts/{id}` | CV | FR11 |
| POST | `/artifacts/{id}/media` | CV | FR13, FR14 |
| PUT, DELETE | `/media/{id}` | CV | FR14, FR15 |
| GET | `/zones` | nhân viên | FR16 |
| PUT | `/zones/{id}` | CV | FR16 |

### E03 – Biên tập và duyệt

| Phương thức | Đường dẫn | Ai gọi | FR |
|---|---|---|---|
| PUT | `/artifacts/{id}/public-description` | BTV | FR17 |
| GET | `/contents/mine` | BTV | FR21 |
| POST | `/contents/{type}/{id}/submit` | BTV | FR19, FR20 |
| GET | `/contents/pending` | QL | FR22 |
| POST | `/contents/{type}/{id}/approve` | QL | FR23 |
| POST | `/contents/{type}/{id}/reject` | QL | FR23 |
| POST | `/contents/{type}/{id}/unpublish` | QL | FR24 |
| GET, POST | `/exhibitions` | BTV | FR25 |
| PUT, DELETE | `/exhibitions/{id}` | BTV | FR25, FR26 |

`{type}` là `artifact` hoặc `exhibition`.

### E04 – Cổng công khai (không cần đăng nhập, chỉ trả nội dung Đã xuất bản)

| Phương thức | Đường dẫn | FR |
|---|---|---|
| GET | `/public/home` | FR28 |
| GET | `/public/visit-info` | FR29 |
| GET | `/public/zones` | FR30 |
| GET | `/public/artifacts?zone=&q=&page=` | FR30, FR31 |
| GET | `/public/artifacts/{code}` | FR32 |
| GET | `/public/exhibitions`, `/public/exhibitions/{id}` | FR33 |

### E05 – Bán vé và soát vé

| Phương thức | Đường dẫn | Ai gọi | FR |
|---|---|---|---|
| GET, POST | `/ticket-types` | QL | FR34 |
| PUT, DELETE | `/ticket-types/{id}` | QL | FR34, FR35 |
| GET, POST | `/time-slots` | QL | FR36 |
| PUT, DELETE | `/time-slots/{id}` | QL | FR36 |
| GET, POST, DELETE | `/closed-days` | QL | FR37 |
| GET | `/public/availability?date=` | mọi người | FR38 |
| POST | `/orders` | TV | FR38, FR39 |
| GET | `/orders/mine` | TV | FR42 |
| GET | `/payment/return` | trình duyệt (VNPay chuyển về) | FR40 |
| GET | `/payment/ipn` | máy chủ VNPay | FR40, NFR06 |
| POST | `/check-in` | NV | FR43–FR45 |

### E06 – Báo cáo

| Phương thức | Đường dẫn | Ai gọi | FR |
|---|---|---|---|
| GET | `/reports/revenue?from=&to=` | QL | FR46 |
