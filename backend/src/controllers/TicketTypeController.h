#pragma once

#include <drogon/HttpController.h>
#include <drogon/utils/coroutine.h>

// US17 – Thiết lập loại vé và giá vé (FR34, FR35). Dành cho Quản lý bảo tàng.
class TicketTypeController : public drogon::HttpController<TicketTypeController> {
 public:
  // shortcut: chưa khóa vai trò Quản lý bảo tàng (NFR03), thêm bộ lọc vào
  // từng dòng dưới đây khi US01 có bộ lọc vai trò.
  METHOD_LIST_BEGIN
  ADD_METHOD_TO(TicketTypeController::list, "/api/v1/ticket-types", drogon::Get);
  ADD_METHOD_TO(TicketTypeController::create, "/api/v1/ticket-types",
                drogon::Post);
  ADD_METHOD_TO(TicketTypeController::update, "/api/v1/ticket-types/{1}",
                drogon::Put);
  ADD_METHOD_TO(TicketTypeController::remove, "/api/v1/ticket-types/{1}",
                drogon::Delete);
  METHOD_LIST_END

  drogon::Task<drogon::HttpResponsePtr> list(drogon::HttpRequestPtr req);
  drogon::Task<drogon::HttpResponsePtr> create(drogon::HttpRequestPtr req);
  drogon::Task<drogon::HttpResponsePtr> update(drogon::HttpRequestPtr req,
                                               long id);
  drogon::Task<drogon::HttpResponsePtr> remove(drogon::HttpRequestPtr req,
                                               long id);
};
