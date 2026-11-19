#include "services/CheckInService.h"

#include <drogon/drogon.h>

#include "repositories/TicketOrderRepository.h"

namespace dcsv {

namespace {

// "2026-11-21" -> "21/11/2026".
std::string vnDate(const std::string &iso) {
  return iso.substr(8, 2) + '/' + iso.substr(5, 2) + '/' + iso.substr(0, 4);
}

// Lý do không hợp lệ theo thứ tự kiểm tra ở Hình 7: tồn tại, đã thanh toán,
// đúng ngày, chưa sử dụng. Gọi khi markUsed không đổi được đơn.
std::string invalidReason(const Json::Value &order) {
  if (order.isNull()) return "Mã vé không tồn tại";
  const std::string status = order["status"].asString();
  if (status == "PENDING") return "Vé chưa được thanh toán";
  if (status == "CANCELLED") return "Đơn đã bị hủy vì quá hạn thanh toán";
  if (status == "USED") {
    // checkedInAt dạng 2026-11-21T09:05:00+07:00.
    const std::string at = order["checkedInAt"].asString();
    return "Vé đã được sử dụng lúc " + at.substr(11, 5) + " ngày " +
           vnDate(at.substr(0, 10));
  }
  // Còn Đã thanh toán mà không soát được thì chỉ có thể là sai ngày.
  return "Vé dành cho ngày " + vnDate(order["visitDate"].asString()) +
         ", không phải hôm nay";
}

}  // namespace

drogon::Task<Json::Value> CheckInService::checkIn(std::string code) {
  const auto db = drogon::app().getDbClient();
  const bool used = co_await TicketOrderRepository::markUsed(db, code);
  // Đọc sau khi cập nhật để thấy đúng trạng thái mới nhất.
  const Json::Value order = co_await TicketOrderRepository::findByCode(db, code);
  Json::Value result;
  result["valid"] = used;
  result["reason"] = used ? "" : invalidReason(order);
  result["order"] = order;
  co_return result;
}

}  // namespace dcsv
