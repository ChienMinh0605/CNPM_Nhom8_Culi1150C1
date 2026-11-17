#include "utils/DateTime.h"

#include <chrono>
#include <regex>

namespace dcsv {

bool isValidDate(const std::string &text) {
  static const std::regex pattern(R"(\d{4}-\d{2}-\d{2})");
  if (!std::regex_match(text, pattern)) return false;
  const std::chrono::year_month_day date{
      std::chrono::year{std::stoi(text.substr(0, 4))},
      std::chrono::month{static_cast<unsigned>(std::stoi(text.substr(5, 2)))},
      std::chrono::day{static_cast<unsigned>(std::stoi(text.substr(8, 2)))}};
  return date.ok();
}

bool isValidTime(const std::string &text) {
  static const std::regex pattern(R"(([01]\d|2[0-3]):[0-5]\d)");
  return std::regex_match(text, pattern);
}

}  // namespace dcsv
