#pragma once

#include <drogon/utils/coroutine.h>
#include <json/json.h>

#include <stdexcept>
#include <string>

#include "utils/VnpaySignature.h"

namespace dcsv {

// Lý do không xem được chỗ hoặc không tạo được đơn. code là mã lỗi trả cho
// giao diện: DATE_OUT_OF_RANGE, CLOSED_DAY, SLOT_UNAVAILABLE,
// TICKET_TYPE_UNAVAILABLE, SOLD_OUT, INVALID_SIGNATURE, NOT_FOUND.
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

  // Xử lý IPN của VNPay (FR40, NFR06). Trả { RspCode, Message } theo quy ước
  // của VNPay để trả lại cho VNPay.
  static drogon::Task<Json::Value> confirmPayment(VnpayParams params);

  // Trang kết quả sau khi VNPay chuyển khách về: kiểm chữ ký rồi trả đơn kèm
  // responseCode của VNPay. Không đổi trạng thái đơn, việc đó chỉ IPN làm.
  static drogon::Task<Json::Value> paymentResult(VnpayParams params);

  // Chạy định kỳ: hủy đơn quá 15 phút chưa thanh toán (FR41).
  static drogon::Task<int> cancelExpiredOrders();
};

}  // namespace dcsv
