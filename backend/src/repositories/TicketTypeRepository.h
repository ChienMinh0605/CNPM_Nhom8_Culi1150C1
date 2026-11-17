#pragma once

#include <drogon/utils/coroutine.h>
#include <json/json.h>

#include <string>

namespace dcsv {

// Bảng ticket_types (FR34, FR35). Mỗi loại vé trả về dạng
// { id, name, audience, price, active }.
class TicketTypeRepository {
 public:
  static drogon::Task<Json::Value> findAll();
  static drogon::Task<Json::Value> insert(std::string name, std::string audience,
                                          int price, bool active);
  // Trả null nếu không có loại vé này.
  static drogon::Task<Json::Value> update(long id, std::string name,
                                          std::string audience, int price,
                                          bool active);
  // Trả false nếu không có loại vé này. Ném lỗi khóa ngoại nếu đã có người mua.
  static drogon::Task<bool> remove(long id);
};

}  // namespace dcsv
