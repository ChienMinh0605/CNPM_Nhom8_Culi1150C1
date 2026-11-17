#pragma once

#include <string>

namespace dcsv {

// Ngày dạng YYYY-MM-DD và có thật trên lịch (2026-02-30 là sai).
bool isValidDate(const std::string &text);

// Giờ dạng HH:MM, từ 00:00 đến 23:59.
bool isValidTime(const std::string &text);

}  // namespace dcsv
