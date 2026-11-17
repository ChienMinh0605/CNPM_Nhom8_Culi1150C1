#pragma once

#include <map>
#include <string>

namespace dcsv {

// Tham số VNPay (vnp_*), giá trị chưa mã hóa URL. std::map tự xếp theo tên,
// đúng thứ tự VNPay yêu cầu khi ký.
using VnpayParams = std::map<std::string, std::string>;

// Chuỗi "a=1&b=2" đã mã hóa URL, bỏ tham số rỗng. Dùng làm dữ liệu ký và
// làm query của đường dẫn thanh toán.
std::string vnpayQuery(const VnpayParams &params);

// Chữ ký HMAC-SHA512 (hex thường) của vnpayQuery(params).
std::string vnpaySign(const VnpayParams &params, const std::string &hashSecret);

// Kiểm tra vnp_SecureHash trong tham số VNPay gửi về (return URL, IPN).
// Chỉ khi hàm này trả true mới được đổi trạng thái đơn (NFR06).
bool vnpayVerify(VnpayParams params, const std::string &hashSecret);

}  // namespace dcsv
