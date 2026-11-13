#pragma once

#include <cstdlib>
#include <string>

namespace dcsv {

// Đọc biến môi trường, trả về giá trị mặc định nếu chưa đặt.
inline std::string env(const char *name, const std::string &fallback = "") {
  const char *value = std::getenv(name);
  return (value != nullptr && *value != '\0') ? std::string(value) : fallback;
}

inline int envInt(const char *name, int fallback) {
  const std::string value = env(name);
  if (value.empty()) return fallback;
  try {
    return std::stoi(value);
  } catch (...) {
    return fallback;
  }
}

}  // namespace dcsv
