#include <drogon/drogon.h>

#include <string>

#include "utils/Env.h"

using dcsv::env;
using dcsv::envInt;

namespace {

// Cấu hình Drogon lấy từ biến môi trường (xem .env.example ở thư mục gốc).
Json::Value buildConfig() {
  Json::Value config;

  Json::Value listener;
  listener["address"] = "0.0.0.0";
  listener["port"] = envInt("BACKEND_PORT", 8080);
  config["listeners"].append(listener);

  Json::Value db;
  db["name"] = "default";
  db["rdbms"] = "postgresql";
  db["host"] = env("DB_HOST", "localhost");
  db["port"] = envInt("DB_PORT", 5432);
  db["dbname"] = env("POSTGRES_DB", "dcsv");
  db["user"] = env("POSTGRES_USER", "dcsv");
  db["passwd"] = env("POSTGRES_PASSWORD", "");
  db["connection_number"] = envInt("DB_CONNECTIONS", 4);
  config["db_clients"].append(db);

  config["app"]["number_of_threads"] = envInt("BACKEND_THREADS", 2);
  // Ảnh tải lên tối đa 10 MB mỗi ảnh (FR13); cho phép tải nhiều ảnh một lần.
  config["app"]["client_max_body_size"] = "64M";
  return config;
}

// Flutter Web chạy ở cổng khác khi phát triển nên cần CORS.
void setupCors(const std::string &allowedOrigin) {
  auto addHeaders = [allowedOrigin](const drogon::HttpResponsePtr &resp) {
    resp->addHeader("Access-Control-Allow-Origin", allowedOrigin);
    resp->addHeader("Access-Control-Allow-Methods",
                    "GET, POST, PUT, PATCH, DELETE, OPTIONS");
    resp->addHeader("Access-Control-Allow-Headers",
                    "Content-Type, Authorization");
  };

  drogon::app().registerSyncAdvice(
      [addHeaders](const drogon::HttpRequestPtr &req) -> drogon::HttpResponsePtr {
        if (req->method() != drogon::Options) return nullptr;
        auto resp = drogon::HttpResponse::newHttpResponse();
        resp->setStatusCode(drogon::k204NoContent);
        addHeaders(resp);
        return resp;
      });

  drogon::app().registerPostHandlingAdvice(
      [addHeaders](const drogon::HttpRequestPtr &,
                   const drogon::HttpResponsePtr &resp) { addHeaders(resp); });
}

}  // namespace

int main() {
  drogon::app().loadConfigJson(buildConfig());
  setupCors(env("CORS_ALLOWED_ORIGIN", "*"));

  LOG_INFO << "DCSV backend chạy ở cổng " << envInt("BACKEND_PORT", 8080);
  drogon::app().run();
  return 0;
}
