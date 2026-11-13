# Quy ước làm việc của nhóm

## Nhánh

- `main`: luôn chạy được. Không commit thẳng vào `main`, chỉ gộp qua Pull Request.
- Mỗi việc một nhánh, tách từ `main`, đặt tên theo mã User Story hoặc Task:

| Loại | Mẫu tên | Ví dụ |
|---|---|---|
| Chức năng | `feature/<mã US>-<mô tả ngắn>` | `feature/US05-ho-so-hien-vat` |
| Sửa lỗi | `fix/<mô tả ngắn>` | `fix/sai-tong-tien-don-ve` |
| Tài liệu | `docs/<mô tả ngắn>` | `docs/erd` |
| Việc khác | `chore/<mô tả ngắn>` | `chore/cap-nhat-docker` |

## Commit

Viết theo mẫu `<loại>(<phạm vi>): <nội dung>`, nội dung bằng tiếng Việt, ngắn gọn.

- Loại: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`.
- Phạm vi: `backend`, `frontend`, `db`, `docs` hoặc mã Task.

Ví dụ:

```
feat(backend): thêm API tạo hồ sơ hiện vật (US05-T02)
fix(frontend): sửa định dạng tiền VNĐ ở trang mua vé
docs: bổ sung ERD
```

## Pull Request

1. Đẩy nhánh lên GitHub và mở Pull Request vào `main`.
2. Điền mẫu PR: mã US/Task, đã làm gì, cách kiểm tra.
3. Cần **ít nhất 1 thành viên khác** xem và đồng ý trước khi gộp.
4. Gộp bằng **Squash and merge**, sau đó xóa nhánh.

## Việc cần làm (Issues)

- Mỗi User Story là một Issue (dùng mẫu «User Story»), các Task là danh sách đánh dấu trong Issue đó.
- Lỗi phát hiện khi kiểm thử dùng mẫu «Báo lỗi».
- Danh sách 22 User Story theo sprint: [docs/quan-ly/backlog.md](docs/quan-ly/backlog.md).

## Quy ước mã nguồn

**Backend (C++20)**

- Tên lớp `PascalCase`, hàm và biến `camelCase`, hằng số `UPPER_SNAKE_CASE`; tên bằng tiếng Anh, khớp tên lớp ở Hình 10 và Hình 11.
- Mỗi lớp một cặp file `.h` / `.cc`, đặt đúng thư mục tầng (`controllers`, `services`, `repositories`…).
- Controller chỉ đọc yêu cầu và trả kết quả; quy tắc nghiệp vụ nằm ở service; SQL nằm ở repository.
- Mọi API (trừ phần công khai) phải kiểm tra quyền ở máy chủ (NFR03).
- Logic thuần (không dùng Drogon) đặt trong `src/utils` và có unit test trong `backend/tests`.

**Frontend (Flutter)**

- Chạy `dart format .` và `flutter analyze` trước khi commit.
- Tên file `snake_case.dart`, tên lớp `PascalCase`.
- Import giao diện Material từ `package:material_ui/material_ui.dart`, không dùng `package:flutter/material.dart` (đã lỗi thời từ Flutter 3.47, `flutter analyze` sẽ báo).
- Mỗi nhóm chức năng một thư mục trong `lib/features/`; phần dùng chung đặt ở `lib/core/`.
- Chữ hiển thị bằng tiếng Việt; ngày và tiền dùng hàm trong `lib/core/formatters.dart` (NFR10).

**Chung**

- Không commit file `.env`, khóa API hay mật khẩu.
- Ảnh hiện vật không đưa vào repo (lưu trên Cloudinary); luôn ghi nguồn và giấy phép (NFR13).
