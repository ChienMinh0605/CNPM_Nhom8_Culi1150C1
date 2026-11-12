# Tài liệu dự án

| Thư mục | Nội dung |
|---|---|
| [yeu-cau/](yeu-cau/) | Tài liệu đặc tả yêu cầu (22 User Story, 46 FR, 13 NFR) và ma trận phân quyền v1.0 |
| [thiet-ke/](thiet-ke/) | Kiến trúc, bản nháp API, sơ đồ tổng quan (Hình 1) và 12 sơ đồ UML (Hình 2–13) |
| [quan-ly/](quan-ly/) | Backlog theo sprint |
| [bao-cao/](bao-cao/) | Dàn slide và hình dùng cho buổi báo cáo tiến độ 13/11/2026 |

## Danh sách hình

| Hình | Nội dung | File |
|---|---|---|
| 1 | Tổng quan hệ thống | `thiet-ke/HighLevel_SystemOverview_DCSV.png` |
| 2 | Use case tổng quát | `thiet-ke/uml/UseCase/UC01_TongQuat.png` |
| 3 | Use case quản lý nội dung (E02, E03) | `thiet-ke/uml/UseCase/UC02_QuanLyNoiDung_E02_E03.png` |
| 4 | Use case bán vé và soát vé (E05) | `thiet-ke/uml/UseCase/UC03_BanVe_SoatVe_E05.png` |
| 5 | Activity biên tập và duyệt nội dung | `thiet-ke/uml/Activity/AD01_BienTap_DuyetNoiDung_E03.png` |
| 6 | Activity mua vé online | `thiet-ke/uml/Activity/AD02_MuaVeOnline_E05.png` |
| 7 | Activity soát vé QR | `thiet-ke/uml/Activity/AD03_SoatVeQR_E05.png` |
| 8 | State vòng đời nội dung | `thiet-ke/uml/State/SM01_VongDoiNoiDung.png` |
| 9 | State vòng đời đơn vé | `thiet-ke/uml/State/SM02_VongDoiDonVe.png` |
| 10 | Class – mô hình khái niệm | `thiet-ke/uml/Class/CD01_MoHinhKhaiNiem.png` |
| 11 | Class – thiết kế phân hệ bán vé | `thiet-ke/uml/Class/CD02_ThietKe_BanVe_E05.png` |
| 12 | Sequence mua vé online qua VNPay | `thiet-ke/uml/Sequence/SD01_MuaVeOnline_VNPay.png` |
| 13 | Sequence soát vé QR | `thiet-ke/uml/Sequence/SD02_SoatVeQR.png` |

Mỗi sơ đồ UML có file `.drawio` (sửa bằng draw.io) và `.puml` (PlantUML) cùng thư mục.

## Việc còn lại ở giai đoạn thiết kế chi tiết

- [ ] ERD và lược đồ CSDL (`database/init/02_schema.sql`)
- [ ] Wireframe các màn hình chính
- [ ] Chốt đặc tả API (từ bản nháp [thiet-ke/api.md](thiet-ke/api.md))
- [ ] Đổi kiểu dữ liệu ở Hình 11 sang C++ (`std::string`, `std::vector<…>`)
