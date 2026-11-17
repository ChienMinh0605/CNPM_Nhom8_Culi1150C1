#pragma once

#include <drogon/orm/Exception.h>

#include <string>

namespace dcsv {

// Mã SQLSTATE của PostgreSQL, dùng để đổi lỗi ràng buộc thành HTTP 409.
inline constexpr const char *SQL_FOREIGN_KEY_VIOLATION = "23503";
inline constexpr const char *SQL_EXCLUSION_VIOLATION = "23P01";

// Trả chuỗi rỗng nếu lỗi không phải do câu SQL (ví dụ mất kết nối).
inline std::string sqlState(const drogon::orm::DrogonDbException &e) {
  const auto *sqlError = dynamic_cast<const drogon::orm::SqlError *>(&e.base());
  return sqlError != nullptr ? sqlError->sqlState() : "";
}

}  // namespace dcsv
