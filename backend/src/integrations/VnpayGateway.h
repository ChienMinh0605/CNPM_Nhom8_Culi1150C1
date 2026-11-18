#pragma once

#include <string>

#include "utils/VnpaySignature.h"

namespace dcsv {

// Cổng thanh toán VNPay Sandbox. Cấu hình lấy từ biến môi trường VNPAY_*.
class VnpayGateway {
 public:
  // Đường dẫn chuyển khách sang VNPay để trả amount VNĐ cho đơn orderCode.
  // Giao dịch hết hạn sau holdMinutes phút, cùng lúc với thời gian giữ chỗ.
  static std::string createPaymentUrl(const std::string &orderCode, int amount,
                                      const std::string &clientIp,
                                      int holdMinutes);

  // Chữ ký VNPay gửi về (IPN, trang kết quả) có khớp khóa của mình không.
  static bool verify(const VnpayParams &params);
};

}  // namespace dcsv
