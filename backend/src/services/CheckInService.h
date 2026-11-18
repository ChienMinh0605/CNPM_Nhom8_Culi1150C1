#pragma once

#include <drogon/utils/coroutine.h>
#include <json/json.h>

#include <string>

namespace dcsv {

// US21 – Soát vé bằng mã QR (FR44, FR45).
class CheckInService {
 public:
  // { valid, reason, order }. Vé hợp lệ được chuyển sang Đã sử dụng.
  // reason rỗng khi hợp lệ; order là null khi không có mã này.
  static drogon::Task<Json::Value> checkIn(std::string code);
};

}  // namespace dcsv
