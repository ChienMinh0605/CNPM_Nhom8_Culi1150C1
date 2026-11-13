#pragma once

#include <string>

namespace dcsv {

// Mã hiện vật dạng DCSV-[mã khu]-[4 chữ số], ví dụ DCSV-KN-0001 (FR10).
// Ném std::invalid_argument nếu mã khu rỗng hoặc số thứ tự ngoài 1..9999.
std::string formatArtifactCode(const std::string &zoneCode, int sequence);

}  // namespace dcsv
