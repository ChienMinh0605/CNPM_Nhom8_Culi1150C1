#pragma once

#include <drogon/HttpController.h>
#include <drogon/utils/coroutine.h>

// US19 – Mua vé online (FR38, FR39).
class TicketOrderController
    : public drogon::HttpController<TicketOrderController> {
 public:
  // shortcut: POST /orders chưa bắt đăng nhập Thành viên nên đơn chưa gắn
  // người mua, thêm bộ lọc và lưu member_id khi US01, US04 xong.
  METHOD_LIST_BEGIN
  ADD_METHOD_TO(TicketOrderController::ticketTypes,
                "/api/v1/public/ticket-types", drogon::Get);
  ADD_METHOD_TO(TicketOrderController::availability,
                "/api/v1/public/availability", drogon::Get);
  ADD_METHOD_TO(TicketOrderController::create, "/api/v1/orders", drogon::Post);
  METHOD_LIST_END

  drogon::Task<drogon::HttpResponsePtr> ticketTypes(drogon::HttpRequestPtr req);
  drogon::Task<drogon::HttpResponsePtr> availability(drogon::HttpRequestPtr req);
  drogon::Task<drogon::HttpResponsePtr> create(drogon::HttpRequestPtr req);
};
