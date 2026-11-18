#pragma once

#include <drogon/HttpController.h>
#include <drogon/utils/coroutine.h>

// US19 – Mua vé online (FR38–FR40).
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
  // Hai đường dẫn dưới tự kiểm chữ ký VNPay nên không cần đăng nhập.
  ADD_METHOD_TO(TicketOrderController::paymentReturn, "/api/v1/payment/return",
                drogon::Get);
  ADD_METHOD_TO(TicketOrderController::paymentIpn, "/api/v1/payment/ipn",
                drogon::Get);
  METHOD_LIST_END

  drogon::Task<drogon::HttpResponsePtr> ticketTypes(drogon::HttpRequestPtr req);
  drogon::Task<drogon::HttpResponsePtr> availability(drogon::HttpRequestPtr req);
  drogon::Task<drogon::HttpResponsePtr> create(drogon::HttpRequestPtr req);
  drogon::Task<drogon::HttpResponsePtr> paymentReturn(drogon::HttpRequestPtr req);
  drogon::Task<drogon::HttpResponsePtr> paymentIpn(drogon::HttpRequestPtr req);
};
