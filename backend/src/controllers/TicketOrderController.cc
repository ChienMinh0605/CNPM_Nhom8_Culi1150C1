#include "controllers/TicketOrderController.h"

#include <set>

#include "repositories/TicketTypeRepository.h"
#include "services/TicketOrderService.h"
#include "utils/ApiResponse.h"
#include "utils/DateTime.h"

using dcsv::makeError;
using dcsv::OrderError;
using dcsv::TicketOrderService;
using drogon::HttpRequestPtr;
using drogon::HttpResponse;
using drogon::HttpResponsePtr;
using drogon::Task;

namespace {

HttpResponsePtr badDate() {
  return makeError(drogon::k400BadRequest, "INVALID_INPUT",
                   "Ngày phải có dạng YYYY-MM-DD");
}

// Hết chỗ là xung đột (409), không có đơn là 404; còn lại là dữ liệu vào
// sai (400).
HttpResponsePtr orderError(const OrderError &e) {
  const auto status = e.code == "SOLD_OUT"    ? drogon::k409Conflict
                      : e.code == "NOT_FOUND" ? drogon::k404NotFound
                                              : drogon::k400BadRequest;
  return makeError(status, e.code, e.what());
}

// Chỉ lấy tham số vnp_* để kiểm chữ ký.
dcsv::VnpayParams vnpayParams(const HttpRequestPtr &req) {
  dcsv::VnpayParams params;
  for (const auto &[name, value] : req->getParameters()) {
    if (name.rfind("vnp_", 0) == 0) params[name] = value;
  }
  return params;
}

// Mỗi dòng một loại vé khác nhau, số lượng dương, cả đơn tối đa 10 vé (FR38).
bool isValidItems(const Json::Value &items) {
  if (!items.isArray() || items.empty()) return false;
  std::set<Json::Int64> typeIds;
  int quantity = 0;
  for (const auto &item : items) {
    if (!item.isObject() || !item["ticketTypeId"].isInt64() ||
        !item["quantity"].isInt() || item["quantity"].asInt() <= 0 ||
        item["quantity"].asInt() > TicketOrderService::MAX_TICKETS_PER_ORDER ||
        !typeIds.insert(item["ticketTypeId"].asInt64()).second) {
      return false;
    }
    quantity += item["quantity"].asInt();
  }
  return quantity <= TicketOrderService::MAX_TICKETS_PER_ORDER;
}

}  // namespace

Task<HttpResponsePtr> TicketOrderController::ticketTypes(HttpRequestPtr) {
  Json::Value body;
  body["items"] = co_await dcsv::TicketTypeRepository::findActive();
  body["total"] = body["items"].size();
  co_return HttpResponse::newHttpJsonResponse(body);
}

Task<HttpResponsePtr> TicketOrderController::availability(HttpRequestPtr req) {
  const std::string date = req->getParameter("date");
  if (!dcsv::isValidDate(date)) co_return badDate();
  Json::Value result;
  try {
    result = co_await TicketOrderService::availability(date);
  } catch (const OrderError &e) {
    co_return orderError(e);
  }
  co_return HttpResponse::newHttpJsonResponse(result);
}

Task<HttpResponsePtr> TicketOrderController::create(HttpRequestPtr req) {
  const auto body = req->getJsonObject();
  if (!body || !body->isObject() || !(*body)["visitDate"].isString() ||
      !dcsv::isValidDate((*body)["visitDate"].asString())) {
    co_return badDate();
  }
  const Json::Value &b = *body;
  if (!b["timeSlotId"].isInt64() || !isValidItems(b["items"])) {
    co_return makeError(drogon::k400BadRequest, "INVALID_INPUT",
                        "Cần chọn khung giờ và từ 1 đến 10 vé, mỗi loại vé "
                        "một dòng");
  }
  // Chỉ chuyển hai trường cần dùng xuống dưới, bỏ mọi trường lạ khách gửi.
  Json::Value items(Json::arrayValue);
  for (const auto &item : b["items"]) {
    Json::Value clean;
    clean["ticketTypeId"] = item["ticketTypeId"].asInt64();
    clean["quantity"] = item["quantity"].asInt();
    items.append(clean);
  }
  Json::Value order;
  try {
    order = co_await TicketOrderService::createOrder(
        b["visitDate"].asString(), b["timeSlotId"].asInt64(), items,
        req->peerAddr().toIp());
  } catch (const OrderError &e) {
    co_return orderError(e);
  }
  auto resp = HttpResponse::newHttpJsonResponse(order);
  resp->setStatusCode(drogon::k201Created);
  co_return resp;
}

Task<HttpResponsePtr> TicketOrderController::paymentReturn(HttpRequestPtr req) {
  Json::Value order;
  try {
    order = co_await TicketOrderService::paymentResult(vnpayParams(req));
  } catch (const OrderError &e) {
    co_return orderError(e);
  }
  co_return HttpResponse::newHttpJsonResponse(order);
}

Task<HttpResponsePtr> TicketOrderController::paymentIpn(HttpRequestPtr req) {
  co_return HttpResponse::newHttpJsonResponse(
      co_await TicketOrderService::confirmPayment(vnpayParams(req)));
}
