#include "repositories/TicketTypeRepository.h"

#include <drogon/drogon.h>

namespace dcsv {

namespace {

const char *COLUMNS = "id, name, audience, price, active";

Json::Value toJson(const drogon::orm::Row &row) {
  Json::Value item;
  item["id"] = row["id"].as<Json::Int64>();
  item["name"] = row["name"].as<std::string>();
  item["audience"] = row["audience"].as<std::string>();
  item["price"] = row["price"].as<int>();
  item["active"] = row["active"].as<bool>();
  return item;
}

}  // namespace

drogon::Task<Json::Value> TicketTypeRepository::findAll() {
  const auto rows = co_await drogon::app().getDbClient()->execSqlCoro(
      std::string("SELECT ") + COLUMNS + " FROM ticket_types ORDER BY id");
  Json::Value items(Json::arrayValue);
  for (const auto &row : rows) items.append(toJson(row));
  co_return items;
}

drogon::Task<Json::Value> TicketTypeRepository::insert(std::string name,
                                                       std::string audience,
                                                       int price, bool active) {
  const auto rows = co_await drogon::app().getDbClient()->execSqlCoro(
      std::string("INSERT INTO ticket_types (name, audience, price, active) "
                  "VALUES ($1, $2, $3, $4) RETURNING ") +
          COLUMNS,
      name, audience, price, active);
  co_return toJson(rows[0]);
}

drogon::Task<Json::Value> TicketTypeRepository::update(long id, std::string name,
                                                       std::string audience,
                                                       int price, bool active) {
  const auto rows = co_await drogon::app().getDbClient()->execSqlCoro(
      std::string("UPDATE ticket_types SET name = $1, audience = $2, "
                  "price = $3, active = $4 WHERE id = $5 RETURNING ") +
          COLUMNS,
      name, audience, price, active, id);
  co_return rows.empty() ? Json::Value() : toJson(rows[0]);
}

drogon::Task<bool> TicketTypeRepository::remove(long id) {
  const auto result = co_await drogon::app().getDbClient()->execSqlCoro(
      "DELETE FROM ticket_types WHERE id = $1", id);
  co_return result.affectedRows() > 0;
}

}  // namespace dcsv
