#pragma once

#include <drogon/utils/coroutine.h>
#include <json/json.h>

#include <stdexcept>
#include <string>

namespace dcsv {

// Lý do không xem được chỗ hoặc không tạo được đơn. code là mã lỗi trả cho
// giao diện: DATE_OUT_OF_RANGE, CLOSED_DAY, SLOT_UNAVAILABLE,
// TICKET_TYPE_UNAVAILABLE, SOLD_OUT.
struct OrderError : std::runtime_error {
  OrderError(std::string errorCode, const std::string &message)
      : std::runtime_error(message), code(std::move(errorCode)) {}
  std::string code;
};

// US19 – Mua vé online: quy tắc chọn ngày, giữ chỗ và tính tiền (FR38, FR39).
class TicketOrderService {
 public:
  static constexpr int HOLD_MINUTES = 15;
  static constexpr int MAX_TICKETS_PER_ORDER = 10;

  // { date, closed, reason, slots: [...] }. Ngày đóng cửa thì slots rỗng.
  static drogon::Task<Json::Value> availability(std::string date);

  // items: [{ ticketTypeId, quantity }], đã được controller kiểm tra dạng.
  // Trả đơn Chờ thanh toán kèm paymentUrl để chuyển sang VNPay.
  static drogon::Task<Json::Value> createOrder(std::string date, long slotId,
                                               Json::Value items,
                                               std::string clientIp);
};

}  // namespace dcsv
