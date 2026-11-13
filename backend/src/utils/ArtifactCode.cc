#include "utils/ArtifactCode.h"

#include <cctype>
#include <iomanip>
#include <sstream>
#include <stdexcept>

namespace dcsv {

std::string formatArtifactCode(const std::string &zoneCode, int sequence) {
  if (zoneCode.empty()) {
    throw std::invalid_argument("zoneCode rỗng");
  }
  if (sequence < 1 || sequence > 9999) {
    throw std::invalid_argument("sequence phải trong khoảng 1..9999");
  }
  std::string zone;
  for (unsigned char c : zoneCode) {
    zone.push_back(static_cast<char>(std::toupper(c)));
  }
  std::ostringstream out;
  out << "DCSV-" << zone << '-' << std::setw(4) << std::setfill('0') << sequence;
  return out.str();
}

}  // namespace dcsv
