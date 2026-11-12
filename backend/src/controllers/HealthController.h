#pragma once

#include <drogon/HttpController.h>

// Kiểm tra máy chủ và kết nối CSDL. Dùng để xác nhận môi trường chạy đúng.
class HealthController : public drogon::HttpController<HealthController> {
 public:
  METHOD_LIST_BEGIN
  ADD_METHOD_TO(HealthController::health, "/api/health", drogon::Get);
  ADD_METHOD_TO(HealthController::database, "/api/health/db", drogon::Get);
  METHOD_LIST_END

  void health(const drogon::HttpRequestPtr &req,
              std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void database(const drogon::HttpRequestPtr &req,
                std::function<void(const drogon::HttpResponsePtr &)> &&callback);
};
