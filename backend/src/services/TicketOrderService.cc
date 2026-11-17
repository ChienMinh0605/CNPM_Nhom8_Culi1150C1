#include "services/TicketOrderService.h"

#include <drogon/drogon.h>

#include "integrations/VnpayGateway.h"
#include "repositories/TicketOrderRepository.h"

namespace dcsv {

namespace {

// Ném lỗi nếu ngày không bán vé; trả trạng thái ngày nếu bán được hoặc đóng
// cửa (để trang mua vé hiện lý do).
drogon::Task<Json::Value> checkDay(drogon::orm::DbClientPtr db,
                                   std::string date) {
  Json::Value day = co_await TicketOrderRepository::dayStatus(db, date);
  if (!day["inRange"].asBool()) {
    throw OrderError("DATE_OUT_OF_RANGE",
                     "Chỉ bán vé cho hôm nay và 30 ngày tới");
  }
  co_return day;
}

}  // namespace

drogon::Task<Json::Value> TicketOrderService::availability(std::string date) {
  const auto db = drogon::app().getDbClient();
  const Json::Value day = co_await checkDay(db, date);
  Json::Value result;
  result["date"] = date;
  result["closed"] = day["closed"];
  result["reason"] = day["reason"];
  result["slots"] = Json::Value(Json::arrayValue);
  if (!day["closed"].asBool()) {
    result["slots"] = co_await TicketOrderRepository::findSlots(db, date);
  }
  co_return result;
}

drogon::Task<Json::Value> TicketOrderService::createOrder(std::string date,
                                                          long slotId,
                                                          Json::Value items,
                                                          std::string clientIp) {
  int quantity = 0;
  for (const auto &item : items) quantity += item["quantity"].asInt();
  const std::string itemsJson = Json::FastWriter().write(items);

  // Mọi lỗi nghiệp vụ bên dưới ném ra trước khi ghi gì vào CSDL, nên giao
  // dịch kết thúc mà không để lại dữ liệu.
  const auto tx = co_await drogon::app().getDbClient()->newTransactionCoro();
  const Json::Value day = co_await checkDay(tx, date);
  if (day["closed"].asBool()) {
    throw OrderError("CLOSED_DAY", "Bảo tàng đóng cửa ngày này");
  }
  const int remaining =
      co_await TicketOrderRepository::lockSlotAndCountRemaining(tx, slotId,
                                                                date);
  if (remaining < 0) {
    throw OrderError("SLOT_UNAVAILABLE",
                     "Khung giờ không tồn tại hoặc đã qua");
  }
  if (quantity > remaining) {
    throw OrderError("SOLD_OUT", "Khung giờ này chỉ còn " +
                                     std::to_string(remaining) + " chỗ");
  }
  const Json::Value priced =
      co_await TicketOrderRepository::priceItems(tx, itemsJson);
  if (priced.size() != items.size()) {
    throw OrderError("TICKET_TYPE_UNAVAILABLE",
                     "Có loại vé không tồn tại hoặc đã ngừng bán");
  }
  int total = 0;
  for (const auto &item : priced) {
    total += item["price"].asInt() * item["quantity"].asInt();
  }

  Json::Value order = co_await TicketOrderRepository::insert(
      tx, date, slotId, total, itemsJson, HOLD_MINUTES);
  order["paymentUrl"] = VnpayGateway::createPaymentUrl(
      order["code"].asString(), total, clientIp, HOLD_MINUTES);
  co_return order;
}

}  // namespace dcsv
