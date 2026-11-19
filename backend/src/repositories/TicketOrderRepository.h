#pragma once

#include <drogon/orm/DbClient.h>
#include <drogon/utils/coroutine.h>
#include <json/json.h>

#include <string>

namespace dcsv {

// Bảng ticket_orders và order_items (FR38–FR41).
// Các hàm nhận db để chạy được trong cùng một giao dịch.
class TicketOrderRepository {
 public:
  // { inRange, closed, reason }: ngày có nằm trong 30 ngày tới không (theo giờ
  // Việt Nam) và có phải ngày đóng cửa không.
  static drogon::Task<Json::Value> dayStatus(drogon::orm::DbClientPtr db,
                                             std::string date);

  // Các khung giờ còn bán được của ngày, mỗi khung
  // { id, startTime, endTime, capacity, remaining }. Khung giờ đã qua của hôm
  // nay không có trong danh sách.
  static drogon::Task<Json::Value> findSlots(drogon::orm::DbClientPtr db,
                                             std::string date);

  // Khóa dòng khung giờ tới hết giao dịch để hai người mua cùng lúc phải xếp
  // hàng (NFR07), rồi trả số chỗ còn lại; -1 nếu khung giờ không bán được
  // cho ngày này.
  static drogon::Task<int> lockSlotAndCountRemaining(drogon::orm::DbClientPtr db,
                                                     long slotId,
                                                     std::string date);

  // itemsJson: [{ "ticketTypeId": 1, "quantity": 2 }, ...].
  // Trả [{ ticketTypeId, quantity, price }] của các loại vé đang bán và khóa
  // giá của chúng tới hết giao dịch.
  static drogon::Task<Json::Value> priceItems(drogon::orm::DbClientPtr db,
                                              std::string itemsJson);

  // Lưu đơn Chờ thanh toán, giữ chỗ holdMinutes phút. Trả
  // { code, visitDate, timeSlotId, status, totalAmount, expiresAt }.
  static drogon::Task<Json::Value> insert(drogon::orm::DbClientPtr db,
                                          std::string date, long slotId,
                                          int totalAmount, std::string itemsJson,
                                          int holdMinutes);

  // { code, status, visitDate, startTime, endTime, totalAmount, checkedInAt,
  //   items: [{ name, quantity, unitPrice }] }; null nếu không có đơn này.
  // checkedInAt là giờ Việt Nam dạng ISO 8601, null nếu chưa soát.
  static drogon::Task<Json::Value> findByCode(drogon::orm::DbClientPtr db,
                                              std::string code);

  // Chuyển đơn sang Đã thanh toán nếu còn Chờ thanh toán và chưa hết giữ chỗ.
  // Trả false nếu không đổi được.
  static drogon::Task<bool> markPaid(drogon::orm::DbClientPtr db,
                                     std::string code);

  // Soát vé: chuyển đơn Đã thanh toán của hôm nay (giờ Việt Nam) sang Đã sử
  // dụng và ghi giờ vào (FR45). Trả false nếu không đổi được.
  static drogon::Task<bool> markUsed(drogon::orm::DbClientPtr db,
                                     std::string code);

  // Hủy các đơn Chờ thanh toán đã hết giữ chỗ (FR41). Trả số đơn đã hủy.
  static drogon::Task<int> cancelExpired(drogon::orm::DbClientPtr db);
};

}  // namespace dcsv
