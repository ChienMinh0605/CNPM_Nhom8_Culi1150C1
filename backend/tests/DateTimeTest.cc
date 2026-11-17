#include <gtest/gtest.h>

#include "utils/DateTime.h"

using dcsv::isValidDate;
using dcsv::isValidTime;

TEST(DateTime, AcceptsRealDates) {
  EXPECT_TRUE(isValidDate("2026-11-16"));
  EXPECT_TRUE(isValidDate("2028-02-29"));  // năm nhuận
}

TEST(DateTime, RejectsBadDates) {
  EXPECT_FALSE(isValidDate("2026-02-30"));
  EXPECT_FALSE(isValidDate("2027-02-29"));
  EXPECT_FALSE(isValidDate("2026-13-01"));
  EXPECT_FALSE(isValidDate("16/11/2026"));
  EXPECT_FALSE(isValidDate(""));
}

TEST(DateTime, ValidatesTimes) {
  EXPECT_TRUE(isValidTime("00:00"));
  EXPECT_TRUE(isValidTime("23:59"));
  EXPECT_FALSE(isValidTime("24:00"));
  EXPECT_FALSE(isValidTime("8:00"));
  EXPECT_FALSE(isValidTime("08:60"));
  EXPECT_FALSE(isValidTime("08:00:00"));
}
