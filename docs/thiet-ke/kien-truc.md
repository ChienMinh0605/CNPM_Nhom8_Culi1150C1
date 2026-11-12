# Kiến trúc và cách tổ chức mã nguồn

Sơ đồ tổng quan: [HighLevel_SystemOverview_DCSV.png](HighLevel_SystemOverview_DCSV.png) (Hình 1).

## Tổng quan

```
Trình duyệt (Flutter Web)  ──HTTP/JSON──▶  Backend (C++20 + Drogon)  ──▶  PostgreSQL
  · cổng công khai                           · REST API /api/v1/...
  · trang quản trị                           · kiểm tra quyền ở máy chủ
  · màn hình soát vé                         · bộ hẹn giờ hủy đơn quá hạn
                                                   │
                                                   ├──▶ VNPay Sandbox (thanh toán, IPN)
                                                   ├──▶ Cloudinary (lưu ảnh)
                                                   └──▶ Brevo (gửi email)
```

Frontend và backend tách riêng, chỉ nói chuyện qua REST API (NFR12).

## Backend: chia theo tầng

Theo đúng Hình 11 (biểu đồ lớp thiết kế): mỗi yêu cầu đi qua Controller → Service → Repository.

| Thư mục | Vai trò | Quy tắc |
|---|---|---|
| `src/controllers` | Nhận HTTP, kiểm tra dữ liệu vào, trả JSON | Không chứa quy tắc nghiệp vụ, không viết SQL |
| `src/services` | Quy tắc nghiệp vụ | Không biết gì về HTTP |
| `src/repositories` | Đọc/ghi CSDL | Mọi câu SQL nằm ở đây |
| `src/models` | Thực thể (Hình 10) và DTO | |
| `src/filters` | Kiểm tra JWT và vai trò trước khi vào controller | Không có quyền trả 403 (NFR03) |
| `src/integrations` | Dịch vụ ngoài | Mỗi loại một lớp trừu tượng (hàm thuần ảo) + lớp cài đặt |
| `src/jobs` | Việc định kỳ | Dùng bộ hẹn giờ của Drogon |
| `src/utils` | Hàm dùng chung | Logic thuần C++ phải có unit test |

### Lớp dự kiến theo Epic

| Epic | Controller | Service | Repository |
|---|---|---|---|
| E01 Người dùng | `AuthController`, `AccountController` | `AuthService`, `AccountService` | `AccountRepository` |
| E02 Hiện vật | `ArtifactController`, `MediaController`, `ZoneController` | `ArtifactService`, `MediaService` | `ArtifactRepository`, `MediaAssetRepository`, `ZoneRepository` |
| E03 Biên tập, duyệt | `ContentController`, `ExhibitionController` | `ContentService`, `ExhibitionService` | `ExhibitionRepository` |
| E04 Cổng công khai | `PortalController` | dùng lại service của E02, E03 | – |
| E05 Bán vé, soát vé | `TicketTypeController`, `TimeSlotController`, `TicketOrderController`, `CheckInController` | `TicketOrderService`, `CheckInService` | `TicketOrderRepository`, `TimeSlotRepository`, `TicketTypeRepository` |
| E06 Báo cáo | `ReportController` | `ReportService` | dùng `TicketOrderRepository` |

Ngoài ra: `integrations/PaymentGateway` → `VnpayGateway`, `integrations/EmailSender` → `BrevoEmailSender`,
`jobs/ExpiredOrderJob` (FR41), `utils/QrCodeGenerator`.

Tên lớp ở trên là dự kiến, có thể đổi khi thiết kế chi tiết; khi đổi nhớ cập nhật Hình 11.

### Cấu hình

Backend đọc cấu hình từ biến môi trường (file `.env`, xem `.env.example`), không có file cấu hình riêng.

## Frontend: chia theo nhóm chức năng

| Thư mục | Nội dung |
|---|---|
| `lib/core` | `config.dart` (địa chỉ API), `api_client.dart`, `router.dart`, `theme.dart`, `formatters.dart` |
| `lib/features/portal` | Cổng công khai: trang chủ, khu trưng bày, tìm kiếm, chi tiết hiện vật, triển lãm, mua vé, vé của tôi |
| `lib/features/auth` | Đăng nhập, đăng ký, quên mật khẩu |
| `lib/features/admin` | Trang quản trị cho 4 vai trò nội bộ (tài khoản, hiện vật, biên tập, duyệt, vé, báo cáo) |
| `lib/features/checkin` | Màn hình soát vé cho Nhân viên quầy vé |

Đường dẫn hiện có: `/`, `/dang-nhap`, `/quan-tri`, `/soat-ve`.

Chưa chốt: thư viện quản lý trạng thái (Provider, Riverpod hay Bloc). Nhóm quyết định ở đầu Sprint 1.

## Quy tắc nghiệp vụ cần nhớ khi lập trình

- Mỗi tài khoản đúng 1 vai trò (FR05); tài khoản nhân viên không dùng để mua vé.
- Vòng đời nội dung: Nháp → Chờ duyệt → Đã xuất bản → Đã gỡ; sửa nội dung Đã xuất bản hoặc Đã gỡ thì quay về Nháp và phải duyệt lại (FR11, FR20, Hình 8).
- Biên tập viên chỉ sửa, gửi duyệt, xóa nội dung do mình tạo; Quản lý bảo tàng chỉ đọc dữ liệu nội bộ.
- Đơn vé: Chờ thanh toán → Đã thanh toán → Đã sử dụng; quá 15 phút chưa thanh toán thì Đã hủy và trả chỗ (FR41, Hình 9).
- Không bán vượt sức chứa kể cả khi nhiều người mua cùng lúc (NFR07); đơn giữ nguyên giá lúc mua (NFR08).
- Chỉ kết quả IPN có chữ ký hợp lệ mới được đổi trạng thái đơn (NFR06).
- Soát vé chỉ kiểm tra đúng ngày, không kiểm tra khung giờ; mỗi đơn 1 mã QR, soát 1 lần cho cả đoàn (FR44).
