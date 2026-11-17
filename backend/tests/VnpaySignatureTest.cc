#include <gtest/gtest.h>

#include <cctype>
#include <string>

#include "utils/VnpaySignature.h"

using dcsv::VnpayParams;
using dcsv::vnpayQuery;
using dcsv::vnpaySign;
using dcsv::vnpayVerify;

namespace {

const char *SECRET = "SECRETKEY";

// Giá trị đối chiếu tính bằng Python: hmac.new(b"SECRETKEY", query, sha512).
const char *EXPECTED_HASH =
    "c058e6bb4cedfcb7ea18d23ef81afcf410764d75a0f8a4e24a7073afb516fe36"
    "299a1e680834222328a22e451f830095144f90db2b3a86fa7e44067358a30bf6";

VnpayParams sampleParams() {
  return {{"vnp_TxnRef", "DV-0001"},
          {"vnp_Amount", "4000000"},
          {"vnp_OrderInfo", "Thanh toan don DV-0001"},
          {"vnp_BankCode", ""}};
}

}  // namespace

TEST(VnpaySignature, QueryIsSortedEncodedAndSkipsEmpty) {
  EXPECT_EQ(vnpayQuery(sampleParams()),
            "vnp_Amount=4000000&vnp_OrderInfo=Thanh+toan+don+DV-0001"
            "&vnp_TxnRef=DV-0001");
  EXPECT_EQ(vnpayQuery({{"a", "x&y=z/é"}}), "a=x%26y%3Dz%2F%C3%A9");
}

TEST(VnpaySignature, SignsWithHmacSha512) {
  EXPECT_EQ(vnpaySign(sampleParams(), SECRET), EXPECTED_HASH);
}

TEST(VnpaySignature, VerifyAcceptsValidHashInAnyCase) {
  auto params = sampleParams();
  params["vnp_SecureHashType"] = "HmacSHA512";
  params["vnp_SecureHash"] = EXPECTED_HASH;
  EXPECT_TRUE(vnpayVerify(params, SECRET));

  std::string upper = EXPECTED_HASH;
  for (auto &c : upper) c = static_cast<char>(std::toupper(c));
  params["vnp_SecureHash"] = upper;
  EXPECT_TRUE(vnpayVerify(params, SECRET));
}

TEST(VnpaySignature, VerifyRejectsTamperedOrMissingHash) {
  auto params = sampleParams();
  EXPECT_FALSE(vnpayVerify(params, SECRET));  // thiếu chữ ký

  params["vnp_SecureHash"] = EXPECTED_HASH;
  EXPECT_FALSE(vnpayVerify(params, "KHOA_KHAC"));

  params["vnp_Amount"] = "1000";  // sửa số tiền sau khi ký
  EXPECT_FALSE(vnpayVerify(params, SECRET));
}
