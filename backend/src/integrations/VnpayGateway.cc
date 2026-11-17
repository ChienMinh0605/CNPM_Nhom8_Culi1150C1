#include "integrations/VnpayGateway.h"

#include <chrono>
#include <ctime>

#include "utils/Env.h"
#include "utils/VnpaySignature.h"

namespace dcsv {

namespace {

// VNPay nhận thời điểm theo giờ Việt Nam (GMT+7), dạng yyyyMMddHHmmss.
std::string vnpayTime(std::chrono::system_clock::time_point time) {
  const std::time_t seconds =
      std::chrono::system_clock::to_time_t(time + std::chrono::hours(7));
  std::tm parts{};
  gmtime_r(&seconds, &parts);
  char buf[15];
  std::strftime(buf, sizeof(buf), "%Y%m%d%H%M%S", &parts);
  return buf;
}

}  // namespace

std::string VnpayGateway::createPaymentUrl(const std::string &orderCode,
                                           int amount,
                                           const std::string &clientIp,
                                           int holdMinutes) {
  const auto now = std::chrono::system_clock::now();
  const VnpayParams params = {
      {"vnp_Version", "2.1.0"},
      {"vnp_Command", "pay"},
      {"vnp_TmnCode", env("VNPAY_TMN_CODE")},
      // VNPay tính theo đơn vị nhỏ hơn đồng 100 lần.
      {"vnp_Amount", std::to_string(static_cast<long long>(amount) * 100)},
      {"vnp_CurrCode", "VND"},
      {"vnp_TxnRef", orderCode},
      {"vnp_OrderInfo", "Thanh toan don ve " + orderCode},
      {"vnp_OrderType", "other"},
      {"vnp_Locale", "vn"},
      {"vnp_ReturnUrl", env("VNPAY_RETURN_URL")},
      {"vnp_IpAddr", clientIp},
      {"vnp_CreateDate", vnpayTime(now)},
      {"vnp_ExpireDate", vnpayTime(now + std::chrono::minutes(holdMinutes))},
  };
  return vnpayPaymentUrl(
      env("VNPAY_PAYMENT_URL",
          "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html"),
      params, env("VNPAY_HASH_SECRET"));
}

}  // namespace dcsv
