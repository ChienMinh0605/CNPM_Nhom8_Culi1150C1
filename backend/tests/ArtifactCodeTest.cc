#include <gtest/gtest.h>

#include <stdexcept>

#include "utils/ArtifactCode.h"

using dcsv::formatArtifactCode;

TEST(ArtifactCode, FormatsWithFourDigits) {
  EXPECT_EQ(formatArtifactCode("KN", 1), "DCSV-KN-0001");
  EXPECT_EQ(formatArtifactCode("HT", 9999), "DCSV-HT-9999");
}

TEST(ArtifactCode, UppercasesZoneCode) {
  EXPECT_EQ(formatArtifactCode("rb", 42), "DCSV-RB-0042");
}

TEST(ArtifactCode, RejectsInvalidInput) {
  EXPECT_THROW(formatArtifactCode("", 1), std::invalid_argument);
  EXPECT_THROW(formatArtifactCode("KN", 0), std::invalid_argument);
  EXPECT_THROW(formatArtifactCode("KN", 10000), std::invalid_argument);
}
