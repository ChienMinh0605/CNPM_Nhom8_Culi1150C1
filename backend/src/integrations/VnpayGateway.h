#pragma once

#include <string>

namespace dcsv {

// Cổng thanh toán VNPay Sandbox. Cấu hình lấy từ biến môi trường VNPAY_*.
class VnpayGateway {
 public:
  // Đường dẫn chuyển khách sang VNPay để trả amount VNĐ cho đơn orderCode.
  // Giao dịch hết hạn sau holdMinutes phút, cùng lúc với thời gian giữ chỗ.
  static std::string createPaymentUrl(const std::string &orderCode, int amount,
                                      const std::string &clientIp,
                                      int holdMinutes);
};

}  // namespace dcsv
