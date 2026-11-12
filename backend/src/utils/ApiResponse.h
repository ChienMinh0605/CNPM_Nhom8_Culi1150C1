#pragma once

#include <drogon/HttpResponse.h>
#include <json/json.h>

#include <string>

namespace dcsv {

// Định dạng lỗi chung của API (xem docs/thiet-ke/api.md):
//   { "error": { "code": "FORBIDDEN", "message": "..." } }
inline drogon::HttpResponsePtr makeError(drogon::HttpStatusCode status,
                                         const std::string &code,
                                         const std::string &message) {
  Json::Value body;
  body["error"]["code"] = code;
  body["error"]["message"] = message;
  auto resp = drogon::HttpResponse::newHttpJsonResponse(body);
  resp->setStatusCode(status);
  return resp;
}

}  // namespace dcsv
