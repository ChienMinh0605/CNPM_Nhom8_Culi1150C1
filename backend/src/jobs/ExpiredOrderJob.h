#pragma once

namespace dcsv {

// Mỗi phút hủy các đơn quá 15 phút chưa thanh toán (FR41). Gọi một lần
// trong main trước khi máy chủ chạy.
void startExpiredOrderJob();

}  // namespace dcsv
