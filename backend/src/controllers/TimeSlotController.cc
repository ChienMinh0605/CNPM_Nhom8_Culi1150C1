#include "controllers/TimeSlotController.h"

#include "repositories/TimeSlotRepository.h"
#include "utils/ApiResponse.h"
#include "utils/DateTime.h"
#include "utils/DbError.h"

using dcsv::makeError;
using dcsv::TimeSlotRepository;
using drogon::HttpRequestPtr;
using drogon::HttpResponse;
using drogon::HttpResponsePtr;
using drogon::Task;

namespace {

// Giờ dạng HH:MM nên so sánh chuỗi cũng là so sánh giờ.
bool isValidSlot(const std::shared_ptr<Json::Value> &body) {
  if (!body || !body->isObject()) return false;
  const Json::Value &b = *body;
  return b["startTime"].isString() && b["endTime"].isString() &&
         dcsv::isValidTime(b["startTime"].asString()) &&
         dcsv::isValidTime(b["endTime"].asString()) &&
         b["startTime"].asString() < b["endTime"].asString() &&
         b["capacity"].isInt() && b["capacity"].asInt() > 0;
}

HttpResponsePtr badSlot() {
  return makeError(drogon::k400BadRequest, "INVALID_INPUT",
                   "Giờ dạng HH:MM, giờ bắt đầu phải trước giờ kết thúc và "
                   "sức chứa phải lớn hơn 0");
}

HttpResponsePtr badDate() {
  return makeError(drogon::k400BadRequest, "INVALID_INPUT",
                   "Ngày phải có dạng YYYY-MM-DD");
}

HttpResponsePtr overlap() {
  return makeError(drogon::k409Conflict, "TIME_SLOT_OVERLAP",
                   "Khung giờ chồng với khung giờ đã có");
}

HttpResponsePtr notFound(const char *what) {
  return makeError(drogon::k404NotFound, "NOT_FOUND",
                   std::string("Không tìm thấy ") + what);
}

HttpResponsePtr noContent() {
  auto resp = HttpResponse::newHttpResponse();
  resp->setStatusCode(drogon::k204NoContent);
  return resp;
}

HttpResponsePtr listOf(Json::Value items) {
  Json::Value body;
  body["total"] = items.size();
  body["items"] = std::move(items);
  return HttpResponse::newHttpJsonResponse(body);
}

}  // namespace

Task<HttpResponsePtr> TimeSlotController::list(HttpRequestPtr) {
  co_return listOf(co_await TimeSlotRepository::findAll());
}

Task<HttpResponsePtr> TimeSlotController::create(HttpRequestPtr req) {
  const auto body = req->getJsonObject();
  if (!isValidSlot(body)) co_return badSlot();
  const Json::Value &b = *body;
  Json::Value created;
  try {
    created = co_await TimeSlotRepository::insert(
        b["startTime"].asString(), b["endTime"].asString(),
        b["capacity"].asInt());
  } catch (const drogon::orm::DrogonDbException &e) {
    if (dcsv::sqlState(e) != dcsv::SQL_EXCLUSION_VIOLATION) throw;
    co_return overlap();
  }
  auto resp = HttpResponse::newHttpJsonResponse(created);
  resp->setStatusCode(drogon::k201Created);
  co_return resp;
}

Task<HttpResponsePtr> TimeSlotController::update(HttpRequestPtr req, long id) {
  const auto body = req->getJsonObject();
  if (!isValidSlot(body)) co_return badSlot();
  const Json::Value &b = *body;
  Json::Value updated;
  try {
    updated = co_await TimeSlotRepository::update(
        id, b["startTime"].asString(), b["endTime"].asString(),
        b["capacity"].asInt());
  } catch (const drogon::orm::DrogonDbException &e) {
    if (dcsv::sqlState(e) != dcsv::SQL_EXCLUSION_VIOLATION) throw;
    co_return overlap();
  }
  if (updated.isNull()) co_return notFound("khung giờ");
  co_return HttpResponse::newHttpJsonResponse(updated);
}

Task<HttpResponsePtr> TimeSlotController::remove(HttpRequestPtr, long id) {
  bool removed = false;
  try {
    removed = co_await TimeSlotRepository::remove(id);
  } catch (const drogon::orm::DrogonDbException &e) {
    // Bảng đơn vé (Sprint 2) tham chiếu khung giờ nên CSDL tự chặn.
    if (dcsv::sqlState(e) != dcsv::SQL_FOREIGN_KEY_VIOLATION) throw;
    co_return makeError(drogon::k409Conflict, "TIME_SLOT_IN_USE",
                        "Khung giờ đã có đơn vé, không xóa được");
  }
  co_return removed ? noContent() : notFound("khung giờ");
}

Task<HttpResponsePtr> TimeSlotController::listClosedDays(HttpRequestPtr) {
  co_return listOf(co_await TimeSlotRepository::findClosedDays());
}

Task<HttpResponsePtr> TimeSlotController::saveClosedDay(HttpRequestPtr req) {
  const auto body = req->getJsonObject();
  if (!body || !body->isObject() || !(*body)["date"].isString() ||
      !dcsv::isValidDate((*body)["date"].asString()) ||
      (body->isMember("reason") && !(*body)["reason"].isString())) {
    co_return badDate();
  }
  auto resp = HttpResponse::newHttpJsonResponse(
      co_await TimeSlotRepository::saveClosedDay(
          (*body)["date"].asString(), body->get("reason", "").asString()));
  resp->setStatusCode(drogon::k201Created);
  co_return resp;
}

Task<HttpResponsePtr> TimeSlotController::removeClosedDay(HttpRequestPtr,
                                                          std::string date) {
  if (!dcsv::isValidDate(date)) co_return badDate();
  // Không đặt co_await trong toán tử ?: — bản GCC trong image sinh mã làm sập
  // máy chủ.
  const bool removed = co_await TimeSlotRepository::removeClosedDay(date);
  co_return removed ? noContent() : notFound("ngày đóng cửa");
}
