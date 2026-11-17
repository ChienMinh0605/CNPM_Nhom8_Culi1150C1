#include "repositories/TicketOrderRepository.h"

namespace dcsv {

namespace {

// Giờ Việt Nam hiện tại, dùng để biết "hôm nay" và khung giờ nào đã qua.
const char *VN_NOW = "(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')";

// Số chỗ đang giữ của khung giờ s trong ngày $1.
const char *HELD_SEATS =
    "COALESCE((SELECT SUM(i.quantity) FROM ticket_orders o "
    "JOIN order_items i ON i.order_id = o.id "
    "WHERE o.time_slot_id = s.id AND o.visit_date = $1::date "
    "AND (o.status IN ('PAID', 'USED') "
    "OR (o.status = 'PENDING' AND o.expires_at > now()))), 0)";

std::string slotIsOver() {
  return std::string("($1::date = ") + VN_NOW + "::date AND s.end_time <= " +
         VN_NOW + "::time)";
}

const char *ITEMS =
    "jsonb_to_recordset($1::jsonb) AS r(\"ticketTypeId\" bigint, quantity int)";

}  // namespace

drogon::Task<Json::Value> TicketOrderRepository::dayStatus(
    drogon::orm::DbClientPtr db, std::string date) {
  const auto rows = co_await db->execSqlCoro(
      std::string("SELECT $1::date BETWEEN ") + VN_NOW + "::date AND " +
          VN_NOW +
          "::date + 30 AS in_range, "
          "(SELECT reason FROM closed_days WHERE day = $1::date) AS reason",
      date);
  Json::Value status;
  status["inRange"] = rows[0]["in_range"].as<bool>();
  status["closed"] = !rows[0]["reason"].isNull();
  status["reason"] = rows[0]["reason"].isNull()
                         ? ""
                         : rows[0]["reason"].as<std::string>();
  co_return status;
}

drogon::Task<Json::Value> TicketOrderRepository::findSlots(
    drogon::orm::DbClientPtr db, std::string date) {
  const auto rows = co_await db->execSqlCoro(
      std::string("SELECT s.id, to_char(s.start_time, 'HH24:MI') AS start_time, "
                  "to_char(s.end_time, 'HH24:MI') AS end_time, s.capacity, "
                  "GREATEST(s.capacity - ") +
          HELD_SEATS + ", 0) AS remaining FROM time_slots s WHERE NOT " +
          slotIsOver() + " ORDER BY s.start_time",
      date);
  Json::Value items(Json::arrayValue);
  for (const auto &row : rows) {
    Json::Value item;
    item["id"] = row["id"].as<Json::Int64>();
    item["startTime"] = row["start_time"].as<std::string>();
    item["endTime"] = row["end_time"].as<std::string>();
    item["capacity"] = row["capacity"].as<int>();
    item["remaining"] = row["remaining"].as<int>();
    items.append(item);
  }
  co_return items;
}

drogon::Task<int> TicketOrderRepository::lockSlotAndCountRemaining(
    drogon::orm::DbClientPtr db, long slotId, std::string date) {
  // Hai câu riêng: câu đếm phải chạy sau khi đã lấy được khóa thì mới thấy
  // đơn của người mua trước vừa lưu.
  const auto slot = co_await db->execSqlCoro(
      "SELECT s.capacity FROM time_slots s WHERE s.id = $2 AND NOT " +
          slotIsOver() + " FOR UPDATE",
      date, slotId);
  if (slot.empty()) co_return -1;
  const auto held = co_await db->execSqlCoro(
      std::string("SELECT ") + HELD_SEATS +
          " AS held FROM time_slots s WHERE s.id = $2",
      date, slotId);
  const int remaining =
      slot[0]["capacity"].as<int>() - held[0]["held"].as<int>();
  co_return remaining > 0 ? remaining : 0;
}

drogon::Task<Json::Value> TicketOrderRepository::priceItems(
    drogon::orm::DbClientPtr db, std::string itemsJson) {
  const auto rows = co_await db->execSqlCoro(
      std::string("SELECT t.id, r.quantity, t.price FROM ") + ITEMS +
          " JOIN ticket_types t ON t.id = r.\"ticketTypeId\" AND t.active "
          "FOR SHARE OF t",
      itemsJson);
  Json::Value items(Json::arrayValue);
  for (const auto &row : rows) {
    Json::Value item;
    item["ticketTypeId"] = row["id"].as<Json::Int64>();
    item["quantity"] = row["quantity"].as<int>();
    item["price"] = row["price"].as<int>();
    items.append(item);
  }
  co_return items;
}

drogon::Task<Json::Value> TicketOrderRepository::insert(
    drogon::orm::DbClientPtr db, std::string date, long slotId, int totalAmount,
    std::string itemsJson, int holdMinutes) {
  const auto rows = co_await db->execSqlCoro(
      "INSERT INTO ticket_orders "
      "(visit_date, time_slot_id, total_amount, expires_at) "
      "VALUES ($1::date, $2, $3, now() + make_interval(mins => $4)) "
      "RETURNING id, code, status, to_char(expires_at AT TIME ZONE 'UTC', "
      "'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"') AS expires_at",
      date, slotId, totalAmount, holdMinutes);
  co_await db->execSqlCoro(
      std::string("INSERT INTO order_items "
                  "(order_id, ticket_type_id, quantity, unit_price) "
                  "SELECT $2, t.id, r.quantity, t.price FROM ") +
          ITEMS + " JOIN ticket_types t ON t.id = r.\"ticketTypeId\"",
      itemsJson, rows[0]["id"].as<Json::Int64>());
  Json::Value order;
  order["code"] = rows[0]["code"].as<std::string>();
  order["visitDate"] = date;
  order["timeSlotId"] = static_cast<Json::Int64>(slotId);
  order["status"] = rows[0]["status"].as<std::string>();
  order["totalAmount"] = totalAmount;
  order["expiresAt"] = rows[0]["expires_at"].as<std::string>();
  co_return order;
}

}  // namespace dcsv
