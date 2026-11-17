#include "controllers/TicketTypeController.h"

#include "repositories/TicketTypeRepository.h"
#include "utils/ApiResponse.h"
#include "utils/DbError.h"

using dcsv::makeError;
using dcsv::TicketTypeRepository;
using drogon::HttpRequestPtr;
using drogon::HttpResponse;
using drogon::HttpResponsePtr;
using drogon::Task;

namespace {

bool isValid(const std::shared_ptr<Json::Value> &body) {
  if (!body || !body->isObject()) return false;
  const Json::Value &b = *body;
  return b["name"].isString() && !b["name"].asString().empty() &&
         b["audience"].isString() && b["price"].isInt() &&
         b["price"].asInt() >= 0 &&
         (!b.isMember("active") || b["active"].isBool());
}

HttpResponsePtr badRequest() {
  return makeError(drogon::k400BadRequest, "INVALID_INPUT",
                   "Cần có tên, đối tượng áp dụng và giá vé là số nguyên "
                   "không âm");
}

HttpResponsePtr notFound() {
  return makeError(drogon::k404NotFound, "NOT_FOUND",
                   "Không tìm thấy loại vé");
}

}  // namespace

Task<HttpResponsePtr> TicketTypeController::list(HttpRequestPtr) {
  Json::Value body;
  body["items"] = co_await TicketTypeRepository::findAll();
  body["total"] = body["items"].size();
  co_return HttpResponse::newHttpJsonResponse(body);
}

Task<HttpResponsePtr> TicketTypeController::create(HttpRequestPtr req) {
  const auto body = req->getJsonObject();
  if (!isValid(body)) co_return badRequest();
  const Json::Value &b = *body;
  auto resp = HttpResponse::newHttpJsonResponse(
      co_await TicketTypeRepository::insert(
          b["name"].asString(), b["audience"].asString(), b["price"].asInt(),
          b.get("active", true).asBool()));
  resp->setStatusCode(drogon::k201Created);
  co_return resp;
}

Task<HttpResponsePtr> TicketTypeController::update(HttpRequestPtr req, long id) {
  const auto body = req->getJsonObject();
  if (!isValid(body)) co_return badRequest();
  const Json::Value &b = *body;
  const Json::Value updated = co_await TicketTypeRepository::update(
      id, b["name"].asString(), b["audience"].asString(), b["price"].asInt(),
      b.get("active", true).asBool());
  if (updated.isNull()) co_return notFound();
  co_return HttpResponse::newHttpJsonResponse(updated);
}

Task<HttpResponsePtr> TicketTypeController::remove(HttpRequestPtr, long id) {
  bool removed = false;
  try {
    removed = co_await TicketTypeRepository::remove(id);
  } catch (const drogon::orm::DrogonDbException &e) {
    // Bảng dòng đơn vé (Sprint 2) tham chiếu loại vé nên CSDL tự chặn (FR35).
    if (dcsv::sqlState(e) != dcsv::SQL_FOREIGN_KEY_VIOLATION) throw;
    co_return makeError(drogon::k409Conflict, "TICKET_TYPE_IN_USE",
                        "Loại vé đã có người mua, chỉ có thể tắt");
  }
  if (!removed) co_return notFound();
  auto resp = HttpResponse::newHttpResponse();
  resp->setStatusCode(drogon::k204NoContent);
  co_return resp;
}
