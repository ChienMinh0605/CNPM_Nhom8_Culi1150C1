#pragma once

#include <drogon/HttpController.h>
#include <drogon/utils/coroutine.h>

// US21 – Soát vé bằng mã QR (FR43–FR45). Dành cho Nhân viên quầy vé.
class CheckInController : public drogon::HttpController<CheckInController> {
 public:
  // shortcut: chưa khóa vai trò Nhân viên quầy vé (NFR03) và chưa ghi ai
  // soát, thêm bộ lọc vai trò khi US01 xong.
  METHOD_LIST_BEGIN
  ADD_METHOD_TO(CheckInController::checkIn, "/api/v1/check-in", drogon::Post);
  METHOD_LIST_END

  drogon::Task<drogon::HttpResponsePtr> checkIn(drogon::HttpRequestPtr req);
};
