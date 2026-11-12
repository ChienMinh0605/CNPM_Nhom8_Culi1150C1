#include "controllers/HealthController.h"

#include <drogon/drogon.h>

#include <memory>

#include "utils/ApiResponse.h"

using drogon::HttpRequestPtr;
using drogon::HttpResponse;
using drogon::HttpResponsePtr;

void HealthController::health(
    const HttpRequestPtr &,
    std::function<void(const HttpResponsePtr &)> &&callback) {
  Json::Value body;
  body["status"] = "ok";
  body["service"] = "dcsv-backend";
  callback(HttpResponse::newHttpJsonResponse(body));
}

void HealthController::database(
    const HttpRequestPtr &,
    std::function<void(const HttpResponsePtr &)> &&callback) {
  auto cb = std::make_shared<std::function<void(const HttpResponsePtr &)>>(
      std::move(callback));
  auto db = drogon::app().getDbClient();
  db->execSqlAsync(
      "SELECT 1",
      [cb](const drogon::orm::Result &) {
        Json::Value body;
        body["database"] = "ok";
        (*cb)(HttpResponse::newHttpJsonResponse(body));
      },
      [cb](const drogon::orm::DrogonDbException &e) {
        LOG_ERROR << "Không kết nối được CSDL: " << e.base().what();
        (*cb)(dcsv::makeError(drogon::k503ServiceUnavailable, "DB_UNAVAILABLE",
                              "Không kết nối được cơ sở dữ liệu"));
      });
}
