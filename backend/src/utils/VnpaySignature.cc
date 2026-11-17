#include "utils/VnpaySignature.h"

#include <openssl/crypto.h>
#include <openssl/evp.h>
#include <openssl/hmac.h>

#include <algorithm>
#include <cctype>
#include <cstdio>

namespace dcsv {

namespace {

// Giống urlencode của PHP (mã mẫu VNPay): dấu cách thành '+'.
std::string urlEncode(const std::string &text) {
  std::string out;
  for (const unsigned char c : text) {
    if (std::isalnum(c) || c == '-' || c == '_' || c == '.') {
      out += static_cast<char>(c);
    } else if (c == ' ') {
      out += '+';
    } else {
      char buf[4];
      std::snprintf(buf, sizeof(buf), "%%%02X", c);
      out += buf;
    }
  }
  return out;
}

}  // namespace

std::string vnpayQuery(const VnpayParams &params) {
  std::string query;
  for (const auto &[name, value] : params) {
    if (value.empty()) continue;
    if (!query.empty()) query += '&';
    query += urlEncode(name) + '=' + urlEncode(value);
  }
  return query;
}

std::string vnpaySign(const VnpayParams &params, const std::string &hashSecret) {
  const std::string data = vnpayQuery(params);
  unsigned char digest[EVP_MAX_MD_SIZE];
  unsigned int length = 0;
  HMAC(EVP_sha512(), hashSecret.data(), static_cast<int>(hashSecret.size()),
       reinterpret_cast<const unsigned char *>(data.data()), data.size(), digest,
       &length);
  std::string hex;
  for (unsigned int i = 0; i < length; ++i) {
    char buf[3];
    std::snprintf(buf, sizeof(buf), "%02x", digest[i]);
    hex += buf;
  }
  return hex;
}

bool vnpayVerify(VnpayParams params, const std::string &hashSecret) {
  std::string received = params["vnp_SecureHash"];
  params.erase("vnp_SecureHash");
  params.erase("vnp_SecureHashType");
  std::transform(received.begin(), received.end(), received.begin(),
                 [](unsigned char c) { return std::tolower(c); });
  const std::string expected = vnpaySign(params, hashSecret);
  // So sánh thời gian cố định để không lộ chữ ký qua thời gian phản hồi.
  return received.size() == expected.size() &&
         CRYPTO_memcmp(received.data(), expected.data(), expected.size()) == 0;
}

}  // namespace dcsv
