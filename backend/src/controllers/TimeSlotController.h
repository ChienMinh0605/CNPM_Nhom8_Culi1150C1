#pragma once

#include <drogon/HttpController.h>
#include <drogon/utils/coroutine.h>

#include <string>

// US18 – Thiết lập khung giờ, sức chứa và ngày đóng cửa (FR36, FR37).
// Dành cho Quản lý bảo tàng.
class TimeSlotController : public drogon::HttpController<TimeSlotController> {
 public:
  // shortcut: chưa khóa vai trò Quản lý bảo tàng (NFR03), thêm bộ lọc vào
  // từng dòng dưới đây khi US01 có bộ lọc vai trò.
  METHOD_LIST_BEGIN
  ADD_METHOD_TO(TimeSlotController::list, "/api/v1/time-slots", drogon::Get);
  ADD_METHOD_TO(TimeSlotController::create, "/api/v1/time-slots", drogon::Post);
  ADD_METHOD_TO(TimeSlotController::update, "/api/v1/time-slots/{1}",
                drogon::Put);
  ADD_METHOD_TO(TimeSlotController::remove, "/api/v1/time-slots/{1}",
                drogon::Delete);
  ADD_METHOD_TO(TimeSlotController::listClosedDays, "/api/v1/closed-days",
                drogon::Get);
  ADD_METHOD_TO(TimeSlotController::saveClosedDay, "/api/v1/closed-days",
                drogon::Post);
  ADD_METHOD_TO(TimeSlotController::removeClosedDay, "/api/v1/closed-days/{1}",
                drogon::Delete);
  METHOD_LIST_END

  drogon::Task<drogon::HttpResponsePtr> list(drogon::HttpRequestPtr req);
  drogon::Task<drogon::HttpResponsePtr> create(drogon::HttpRequestPtr req);
  drogon::Task<drogon::HttpResponsePtr> update(drogon::HttpRequestPtr req,
                                               long id);
  drogon::Task<drogon::HttpResponsePtr> remove(drogon::HttpRequestPtr req,
                                               long id);

  drogon::Task<drogon::HttpResponsePtr> listClosedDays(
      drogon::HttpRequestPtr req);
  drogon::Task<drogon::HttpResponsePtr> saveClosedDay(drogon::HttpRequestPtr req);
  drogon::Task<drogon::HttpResponsePtr> removeClosedDay(
      drogon::HttpRequestPtr req, std::string date);
};
