#pragma once

#include <drogon/utils/coroutine.h>
#include <json/json.h>

#include <string>

namespace dcsv {

// Bảng time_slots và closed_days (FR36, FR37).
// Khung giờ: { id, startTime, endTime, capacity }, giờ dạng HH:MM.
// Ngày đóng cửa: { date, reason }, ngày dạng YYYY-MM-DD.
class TimeSlotRepository {
 public:
  static drogon::Task<Json::Value> findAll();
  // insert và update ném lỗi EXCLUDE nếu chồng khung giờ khác.
  static drogon::Task<Json::Value> insert(std::string startTime,
                                          std::string endTime, int capacity);
  // Trả null nếu không có khung giờ này.
  static drogon::Task<Json::Value> update(long id, std::string startTime,
                                          std::string endTime, int capacity);
  // Trả false nếu không có khung giờ này. Ném lỗi khóa ngoại nếu đã có đơn vé.
  static drogon::Task<bool> remove(long id);

  static drogon::Task<Json::Value> findClosedDays();
  // Ngày đã đánh dấu rồi thì chỉ cập nhật lý do.
  static drogon::Task<Json::Value> saveClosedDay(std::string date,
                                                 std::string reason);
  static drogon::Task<bool> removeClosedDay(std::string date);
};

}  // namespace dcsv
