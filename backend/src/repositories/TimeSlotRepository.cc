#include "repositories/TimeSlotRepository.h"

#include <drogon/drogon.h>

namespace dcsv {

namespace {

const char *SLOT_COLUMNS =
    "id, to_char(start_time, 'HH24:MI') AS start_time, "
    "to_char(end_time, 'HH24:MI') AS end_time, capacity";
const char *DAY_COLUMNS = "to_char(day, 'YYYY-MM-DD') AS day, reason";

Json::Value slotToJson(const drogon::orm::Row &row) {
  Json::Value item;
  item["id"] = row["id"].as<Json::Int64>();
  item["startTime"] = row["start_time"].as<std::string>();
  item["endTime"] = row["end_time"].as<std::string>();
  item["capacity"] = row["capacity"].as<int>();
  return item;
}

Json::Value dayToJson(const drogon::orm::Row &row) {
  Json::Value item;
  item["date"] = row["day"].as<std::string>();
  item["reason"] = row["reason"].as<std::string>();
  return item;
}

}  // namespace

drogon::Task<Json::Value> TimeSlotRepository::findAll() {
  const auto rows = co_await drogon::app().getDbClient()->execSqlCoro(
      std::string("SELECT ") + SLOT_COLUMNS +
      " FROM time_slots ORDER BY time_slots.start_time");
  Json::Value items(Json::arrayValue);
  for (const auto &row : rows) items.append(slotToJson(row));
  co_return items;
}

drogon::Task<Json::Value> TimeSlotRepository::insert(std::string startTime,
                                                     std::string endTime,
                                                     int capacity) {
  const auto rows = co_await drogon::app().getDbClient()->execSqlCoro(
      std::string("INSERT INTO time_slots (start_time, end_time, capacity) "
                  "VALUES ($1::time, $2::time, $3) RETURNING ") +
          SLOT_COLUMNS,
      startTime, endTime, capacity);
  co_return slotToJson(rows[0]);
}

drogon::Task<Json::Value> TimeSlotRepository::update(long id,
                                                     std::string startTime,
                                                     std::string endTime,
                                                     int capacity) {
  const auto rows = co_await drogon::app().getDbClient()->execSqlCoro(
      std::string("UPDATE time_slots SET start_time = $1::time, "
                  "end_time = $2::time, capacity = $3 WHERE id = $4 "
                  "RETURNING ") +
          SLOT_COLUMNS,
      startTime, endTime, capacity, id);
  co_return rows.empty() ? Json::Value() : slotToJson(rows[0]);
}

drogon::Task<bool> TimeSlotRepository::remove(long id) {
  const auto result = co_await drogon::app().getDbClient()->execSqlCoro(
      "DELETE FROM time_slots WHERE id = $1", id);
  co_return result.affectedRows() > 0;
}

drogon::Task<Json::Value> TimeSlotRepository::findClosedDays() {
  const auto rows = co_await drogon::app().getDbClient()->execSqlCoro(
      std::string("SELECT ") + DAY_COLUMNS +
      " FROM closed_days ORDER BY closed_days.day");
  Json::Value items(Json::arrayValue);
  for (const auto &row : rows) items.append(dayToJson(row));
  co_return items;
}

drogon::Task<Json::Value> TimeSlotRepository::saveClosedDay(std::string date,
                                                            std::string reason) {
  const auto rows = co_await drogon::app().getDbClient()->execSqlCoro(
      std::string("INSERT INTO closed_days (day, reason) "
                  "VALUES ($1::date, $2) ON CONFLICT (day) "
                  "DO UPDATE SET reason = EXCLUDED.reason RETURNING ") +
          DAY_COLUMNS,
      date, reason);
  co_return dayToJson(rows[0]);
}

drogon::Task<bool> TimeSlotRepository::removeClosedDay(std::string date) {
  const auto result = co_await drogon::app().getDbClient()->execSqlCoro(
      "DELETE FROM closed_days WHERE day = $1::date", date);
  co_return result.affectedRows() > 0;
}

}  // namespace dcsv
