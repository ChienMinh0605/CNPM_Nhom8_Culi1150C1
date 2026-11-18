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

drogon::Task<Json::Value> TicketOrderService::confirmPayment(
    VnpayParams params) {
  const auto reply = [](const char *code, const char *message) {
    Json::Value body;
    body["RspCode"] = code;
    body["Message"] = message;
    return body;
  };
  if (!VnpayGateway::verify(params)) co_return reply("97", "Invalid signature");

  const auto db = drogon::app().getDbClient();
  const std::string code = params["vnp_TxnRef"];
  const Json::Value order = co_await TicketOrderRepository::findByCode(db, code);
  if (order.isNull()) co_return reply("01", "Order not found");
  // VNPay tính theo đơn vị nhỏ hơn đồng 100 lần.
  if (params["vnp_Amount"] !=
      std::to_string(order["totalAmount"].asInt64() * 100)) {
    co_return reply("04", "Invalid amount");
  }
  const std::string status = order["status"].asString();
  // Đơn đã thanh toán: VNPay gửi lại IPN, không làm gì thêm.
  if (status == "PAID" || status == "USED") {
    co_return reply("02", "Order already confirmed");
  }
  // Thanh toán thất bại thì đơn vẫn Chờ thanh toán tới khi hết giữ chỗ.
  if (params["vnp_ResponseCode"] != "00" ||
      params["vnp_TransactionStatus"] != "00") {
    co_return reply("00", "Confirm Success");
  }
  const bool paid = co_await TicketOrderRepository::markPaid(db, code);
  if (!paid) {
    // shortcut: khách đã bị trừ tiền nhưng đơn đã hết giữ chỗ hoặc đã hủy thì
    // chỉ ghi log để hoàn tiền tay; VNPay chặn bằng vnp_ExpireDate nên hiếm.
    LOG_ERROR << "Cần hoàn tiền: đơn " << code << " đã trả "
              << order["totalAmount"].asInt() << " đồng (giao dịch VNPay "
              << params["vnp_TransactionNo"] << ") nhưng đã hết giữ chỗ";
    co_return reply("02", "Order already confirmed");
  }
  co_return reply("00", "Confirm Success");
}

drogon::Task<Json::Value> TicketOrderService::paymentResult(VnpayParams params) {
  if (!VnpayGateway::verify(params)) {
    throw OrderError("INVALID_SIGNATURE", "Kết quả thanh toán không hợp lệ");
  }
  Json::Value order = co_await TicketOrderRepository::findByCode(
      drogon::app().getDbClient(), params["vnp_TxnRef"]);
  if (order.isNull()) throw OrderError("NOT_FOUND", "Không tìm thấy đơn vé");
  order["responseCode"] = params["vnp_ResponseCode"];
  co_return order;
}

drogon::Task<int> TicketOrderService::cancelExpiredOrders() {
  co_return co_await TicketOrderRepository::cancelExpired(
      drogon::app().getDbClient());
}

}  // namespace dcsv
