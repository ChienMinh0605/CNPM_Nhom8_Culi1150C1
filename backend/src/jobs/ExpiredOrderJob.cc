#include "jobs/ExpiredOrderJob.h"

#include <drogon/drogon.h>

#include "services/TicketOrderService.h"

namespace dcsv {

namespace {

drogon::AsyncTask cancelExpired() {
  try {
    const int cancelled = co_await TicketOrderService::cancelExpiredOrders();
    if (cancelled > 0) LOG_INFO << "Đã hủy " << cancelled << " đơn quá hạn";
  } catch (const std::exception &e) {
    LOG_ERROR << "Không hủy được đơn quá hạn: " << e.what();
  }
}

}  // namespace

void startExpiredOrderJob() {
  // Chỗ đã tự được trả lại khi hết giữ chỗ (xem TicketOrderRepository); job
  // này chỉ đổi trạng thái để đơn hiện đúng là Đã hủy.
  drogon::app().getLoop()->runEvery(60.0, [] { cancelExpired(); });
}

}  // namespace dcsv
