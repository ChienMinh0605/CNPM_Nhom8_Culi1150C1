#include "controllers/CheckInController.h"

#include <algorithm>
#include <cctype>

#include "services/CheckInService.h"
#include "utils/ApiResponse.h"

using drogon::HttpRequestPtr;
using drogon::HttpResponse;
using drogon::HttpResponsePtr;
using drogon::Task;

namespace {

// Mã nhập tay có thể thừa dấu cách hoặc viết thường.
std::string normalizeCode(std::string code) {
  code.erase(std::remove_if(code.begin(), code.end(),
                            [](unsigned char c) { return std::isspace(c); }),
             code.end());
  std::transform(code.begin(), code.end(), code.begin(),
                 [](unsigned char c) { return std::toupper(c); });
  return code;
}

}  // namespace

// Vé không hợp lệ vẫn trả 200: đó là kết quả soát, không phải lỗi gọi API.
Task<HttpResponsePtr> CheckInController::checkIn(HttpRequestPtr req) {
  const auto body = req->getJsonObject();
  const std::string code =
      body && body->isObject() && (*body)["code"].isString()
          ? normalizeCode((*body)["code"].asString())
          : "";
  if (code.empty() || code.size() > 64) {
    co_return dcsv::makeError(drogon::k400BadRequest, "INVALID_INPUT",
                              "Cần có mã vé");
  }
  co_return HttpResponse::newHttpJsonResponse(
      co_await dcsv::CheckInService::checkIn(code));
}
