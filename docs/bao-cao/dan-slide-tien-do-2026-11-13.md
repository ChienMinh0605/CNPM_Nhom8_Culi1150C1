# Dàn slide báo cáo tiến độ – DCSV Digital CMS

> **Đề tài:** Phần mềm quản lý nội dung và tài nguyên số bảo tàng tích hợp (Museum Digital CMS)
> **Bảo tàng giả định:** Bảo tàng Dòng chảy Sử Việt (DCSV)
> **Buổi báo cáo:** Thứ Sáu, 13/11/2026
> **Quy mô:** 12 slide nội dung + bìa, mục lục, cảm ơn · khoảng 12–15 phút · 3 người trình bày

---

## 0. Những gì nhóm đã chốt (đọc trước khi làm slide)

### 0.1. Phạm vi và tài liệu đã có

| Hạng mục | Kết quả | File |
|---|---|---|
| Đề tài và bảo tàng | DCSV, 5 khu trưng bày: Khởi nguồn, Giao thoa, Rồng bay, Vững nền, Hoàng triều | – |
| Tác nhân | 7 tác nhân: Quản trị viên, Quản lý bảo tàng, Chuyên viên sưu tập, Biên tập viên, Nhân viên quầy vé (nội bộ); Khách tham quan, Thành viên (công chúng) | – |
| Tài liệu đặc tả | 6 Epic, **22 User Story** (19 Must, 3 Should), **46 FR**, **13 NFR** (rút gọn từ 45 story / 104 FR / 28 NFR) | `DacTaYeuCau_DCSV_DigitalCMS.docx` |
| Ma trận phân quyền | **v1.0**, đã chốt toàn bộ, không còn ô đề xuất | `MaTranPhanQuyen_DCSV_DigitalCMS_v10.docx` |
| Sơ đồ tổng quan | Hình 1 – High-level System Overview | `HighLevel_SystemOverview_DCSV.png` / `.drawio` |
| Sơ đồ UML | 12 sơ đồ: 3 Use case, 3 Activity, 2 State, 2 Class, 2 Sequence  

### 0.2. Quyết định phân quyền (ma trận v1.0)

1. **Quản lý bảo tàng** được **đọc** dữ liệu nội bộ (hồ sơ, ảnh nội bộ, tình trạng bảo quản) để kiểm tra khi duyệt, **không được sửa**.
2. **Biên tập viên** chỉ sửa, gửi duyệt, xem trước và xóa nội dung **do mình tạo**; danh sách hồ sơ hiện vật thì xem được tất cả ở dạng chỉ đọc.
3. **Tài khoản nhân viên không dùng để mua vé**: mỗi tài khoản có đúng 1 vai trò (FR05); nhân viên muốn mua vé thì dùng tài khoản Thành viên riêng.
4. **Quản trị tài khoản Thành viên** (khóa, mở khóa) **chuyển sang phần Phát triển sau**.

Các quy tắc đã có từ trước: sửa nội dung Đã xuất bản hoặc Đã gỡ thì quay về Nháp và phải duyệt lại (FR11, FR20, Hình 8); soát vé chỉ kiểm tra đúng ngày, không kiểm tra khung giờ (FR44).

### 0.3. Công nghệ đã chốt (bản gọn)

| Phần | Công nghệ | Ghi chú |
|---|---|---|
| **Giao diện** | **Flutter (Web)** | Một mã nguồn cho cổng công khai, trang quản trị, màn hình soát vé; quét QR bằng `mobile_scanner` |
| **Backend** | **C++20 + Drogon** | REST API, ORM, bộ hẹn giờ hủy đơn quá hạn, OpenSSL ký VNPay. Đáp ứng yêu cầu dùng C++ của thầy |
| **CSDL** | **PostgreSQL** | Extension `unaccent` cho tìm kiếm không dấu |
| **Triển khai** | **Docker Compose** | Môi trường backend + CSDL giống nhau trên máy cả nhóm |
| Dịch vụ ngoài | VNPay Sandbox · Cloudinary · Brevo (email) | Gọi qua HTTP, không cần SDK |
| Thư viện nhỏ (chỉ ghi chú) | `jwt-cpp`, bcrypt, `libqrencode` | Đăng nhập, băm mật khẩu, sinh QR gửi email |
| Kiểm thử | GoogleTest (C++), `flutter test` | Có sẵn theo từng công nghệ |

Thiết kế lớp Hình 11 giữ nguyên: Controller / Service / Repository thành lớp C++; `PaymentGateway`, `EmailSender` thành **lớp trừu tượng có hàm thuần ảo**. Việc còn lại: đổi kiểu dữ liệu ở Hình 11 sang C++ (`std::string`, `std::vector<…>`).

---

## 1. Cấu trúc bộ slide

| Phần | Slide | Mục đích |
|---|---|---|
| Bìa + Mục lục | – | |
| **A. Bối cảnh** | 1–2 | Đề tài là gì, đã đi tới đâu |
| **B. Kết quả đã thực hiện** | 3–10 | Yêu cầu → kiến trúc → mô hình (chỉ 5 sơ đồ tiêu biểu) |
| **C. Giai đoạn tiếp theo** | 11–12 | Kế hoạch, công nghệ, rủi ro |
| Cảm ơn và Hỏi đáp | – | |

**Bìa:** tên đề tài, «Bảo tàng Dòng chảy Sử Việt – DCSV Digital CMS», môn Công nghệ phần mềm, GVHD, tên nhóm, thành viên, ngày 13/11/2026.
**Mục lục:** A. Bối cảnh · B. Kết quả đã thực hiện · C. Giai đoạn tiếp theo.

---

## A. Bối cảnh

### Slide 1 – Giới thiệu đề tài
- **Bài toán:** bảo tàng cần một hệ thống thống nhất để quản lý hiện vật, tài nguyên số, nội dung công khai và bán vé online.
- **Bảo tàng DCSV**: 5 khu trưng bày theo dòng lịch sử từ Tiền sử đến triều Nguyễn.
- **Mục tiêu bản cơ bản** – một luồng hoàn chỉnh:
  nhập hiện vật → viết mô tả → duyệt → khách xem → mua vé online → soát vé QR.
- *Hình:* sơ đồ luồng 6 bước nằm ngang (vẽ mới, đơn giản).

### Slide 2 – Tổng quan tiến độ
- 3 cột **Đã xong · Đang làm · Sắp làm**:
  - ✅ Đã xong: đề tài và tác nhân; đặc tả (22 US, 46 FR, 13 NFR); ma trận phân quyền v1.0; sơ đồ tổng quan + 12 sơ đồ UML (mỗi loại ≥ 2, đúng yêu cầu của thầy); chốt công nghệ.
  - 🔄 Đang làm: thiết kế chi tiết (CSDL, giao diện).
  - ⏳ Sắp làm: lập trình theo sprint, kiểm thử, demo.
- *Thanh tiến độ:* Phân tích và đặc tả yêu cầu ~90% · Thiết kế chi tiết ~30% · Lập trình 0%.

---

## B. Kết quả đã thực hiện

### Slide 3 – Tác nhân và phân quyền
- 7 tác nhân (5 nội bộ, 2 công chúng) – hình người có màu theo nhóm.
- Bảng phân quyền **rút gọn** từ ma trận v1.0 (vai trò × nhóm chức năng chính).
- 2 nguyên tắc: **mỗi tài khoản 1 vai trò**; **kiểm tra quyền ở phía máy chủ** (NFR03).

### Slide 4 – Product Backlog và phạm vi bản cơ bản
- 6 Epic E01–E06 kèm số User Story mỗi Epic.
- MoSCoW: **19 Must · 3 Should**.

### Slide 5 – Yêu cầu chức năng và phi chức năng
- Biểu đồ cột: số FR theo Epic (tổng 46).
- 13 NFR theo 7 nhóm: hiệu năng, bảo mật, tin cậy, khả dụng, tương thích, bảo trì, pháp lý.
- 3 NFR tiêu biểu: trang tải < 3 giây; không bán vượt sức chứa; mật khẩu băm bcrypt + HTTPS.

### Slide 6 – Kiến trúc tổng quan
- **Hình 1** chiếm gần hết slide.
- Thuyết minh theo số trên hình: ① Người dùng → ② Frontend → ③ REST API → ④⑤⑥ 3 module nghiệp vụ → ⑦ Thống kê, ⑧ CSDL → ⑨ Kênh giao tiếp → ⑩ Dịch vụ ngoài (VNPay, Email, Cloudinary).

### Slide 7 – Use case tổng quát
- **Hình 2**.
- Nhắc: còn 2 use case chi tiết (Hình 3 – lõi CMS, Hình 4 – bán vé) trong tài liệu.

### Slide 8 – Quy trình quản lý nội dung (trái tim của CMS)
- Ghép đôi **Hình 5** (Activity duyệt nội dung) + **Hình 8** (State vòng đời nội dung).
- Thông điệp: Nháp → Chờ duyệt → Đã xuất bản → Đã gỡ; từ chối phải có lý do; sửa nội dung đã công khai thì phải duyệt lại.

### Slide 9 – Quy trình bán vé (vẽ lại bản rút gọn cho slide) ⚠️ đã điều chỉnh
Không dùng nguyên Hình 12 (quá rộng). Vẽ **2 hình mới, gọn**:
- **Trái (~65%) – Sequence rút gọn, 4 lifeline:** Thành viên · Hệ thống DCSV · VNPay · Email
  1. Thành viên chọn ngày, khung giờ, loại vé
  2. Hệ thống kiểm tra chỗ trống – khung `break [hết chỗ]`
  3. Hệ thống tạo đơn «Chờ thanh toán», giữ chỗ 15 phút
  4. Hệ thống chuyển Thành viên sang VNPay
  5. Thành viên thanh toán trên VNPay
  6. VNPay gửi kết quả về hệ thống (IPN)
  7. Hệ thống kiểm tra chữ ký → «Đã thanh toán», sinh QR
  8. Hệ thống gửi vé QR qua email
  9. VNPay chuyển Thành viên về trang kết quả
- **Phải (~35%) – Vòng đời đơn vé (thu gọn Hình 9), xếp dọc:**
  Chờ thanh toán → Đã thanh toán → Đã sử dụng; nhánh *after(15 phút)* → Đã hủy.
- Chú thích nhỏ: «Tóm tắt từ Hình 12 và Hình 9; chi tiết các lớp xem trong tài liệu.»

### Slide 10 – Mô hình dữ liệu (Domain Model)
- **Hình 10** + 3 điểm nhấn:
  - `Content` là lớp trừu tượng dùng chung cho hiện vật và triển lãm.
  - Đơn vé lưu giá tại thời điểm mua (NFR08).
  - Enumeration trạng thái khớp biểu đồ State.
- Đây là cơ sở để thiết kế CSDL ở giai đoạn tới.

---

## C. Giai đoạn tiếp theo

### Slide 11 – Kế hoạch giai đoạn tiếp theo (vẽ dạng timeline)

| Giai đoạn | Công việc chính |
|---|---|
| **Thiết kế chi tiết** | Thiết kế CSDL (ERD từ domain model), wireframe các màn hình chính, đặc tả API, dựng khung dự án Flutter + Drogon + Docker |
| **Sprint 1** | E01 + E02: đăng nhập, phân quyền, hồ sơ hiện vật, ảnh |
| **Sprint 2** | E03 + E04: biên tập, duyệt, cổng thông tin công khai |
| **Sprint 3** | E05 + E06: bán vé, VNPay Sandbox, soát vé QR, báo cáo doanh thu |
| **Kiểm thử và hoàn thiện** | Test case từ FR, nhập 100–200 hiện vật mẫu, chuẩn bị demo |

Song song: thu thập dữ liệu hiện vật, mỗi người phụ trách 1–2 khu trưng bày.

### Slide 12 – Công nghệ, quyết định đã chốt 
3 khối, **không có dòng xin ý kiến thầy**:

**Khối 1 – Công nghệ đã chọn** (4 logo/ô lớn):
Flutter (Web) · C++20 + Drogon · PostgreSQL · Docker Compose
Dòng nhỏ bên dưới: dịch vụ ngoài VNPay Sandbox, Cloudinary, Brevo.

**Khối 2 – Quyết định phân quyền đã chốt (v1.0):**
QL chỉ đọc dữ liệu nội bộ · BTV chỉ thao tác nội dung của mình · tài khoản nhân viên không mua vé · quản trị Thành viên để sau.

**Khối 3 – Rủi ro và hướng xử lý:**

| Rủi ro | Hướng xử lý |
|---|---|
| Lập trình web bằng C++ ít tài liệu | Dựng khung dự án + Docker ngay giai đoạn thiết kế; theo ví dụ chính thức của Drogon |
| Tích hợp VNPay | Dùng sandbox, làm sớm ở đầu Sprint 3 (hoặc thử nghiệm từ Sprint 1) |
| Flutter Web tải lần đầu nặng (~2 MB) có thể vượt NFR01 | Bật cache, tối ưu build release, đo thử sớm trong Sprint 1 |
| Dữ liệu và bản quyền ảnh | Ưu tiên ảnh Wikimedia Commons, luôn ghi nguồn và giấy phép |
| Khối lượng việc với nhóm 3 người | Làm hết story Must trước, Should làm sau cùng |

---

**Cảm ơn và Hỏi đáp**

*(Tùy chọn) Slide phụ lục sau trang cảm ơn:* bảng liệt kê đủ 13 hình kèm tên file, phòng khi thầy hỏi.

---

## 2. Hình dùng trên slide

| Slide | Hình | File |
|---|---|---|
| 6 | Hình 1 – Tổng quan hệ thống | `HighLevel_SystemOverview_DCSV.png` |
| 7 | Hình 2 – Use case tổng quát | `UseCase/UC01_TongQuat.png` |
| 8 | Hình 5 – Activity duyệt nội dung | `Activity/AD01_BienTap_DuyetNoiDung_E03.png` |
| 8 | Hình 8 – State vòng đời nội dung | `State/SM01_VongDoiNoiDung.png` |
| 9 | Sequence rút gọn + vòng đời đơn vé | **vẽ mới cho slide** (tóm tắt Hình 12, Hình 9) |
| 10 | Hình 10 – Domain model | `Class/CD01_MoHinhKhaiNiem.png` |
| 1 | Luồng 6 bước | **vẽ mới cho slide** |
