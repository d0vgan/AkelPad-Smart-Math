#pragma once

#include <cmath>
#include <cstdint>
#include <limits>

namespace smartmath_internal {

constexpr double kMaxExactIntFromDouble = 9007199254740992.0;  // 2^53

inline bool isWithinExactIntFromDoubleRange(double v) {
  return std::isfinite(v) && std::fabs(v) <= kMaxExactIntFromDouble;
}

inline bool tryExtractExactInt64FromDoubleStrict(double v, long long& out) {
  if (!isWithinExactIntFromDoubleRange(v)) {
    return false;
  }
  const double kI64MinD = static_cast<double>((std::numeric_limits<long long>::min)());
  const double kI64MaxD = static_cast<double>((std::numeric_limits<long long>::max)());
  if (v < kI64MinD || v > kI64MaxD) {
    return false;
  }
  const long long asInt = static_cast<long long>(v);
  if (v != static_cast<double>(asInt)) {
    return false;
  }
  out = asInt;
  return true;
}

inline std::uint64_t gcdUInt64(std::uint64_t a, std::uint64_t b) {
  while (b != 0u) {
    const std::uint64_t t = a % b;
    a = b;
    b = t;
  }
  return a;
}

inline bool tryMulUInt64Checked(std::uint64_t a, std::uint64_t b, std::uint64_t& out) {
  if (b != 0u && a > ((std::numeric_limits<std::uint64_t>::max)() / b)) {
    return false;
  }
  out = a * b;
  return true;
}

inline bool tryPowUInt64Checked(std::uint64_t base, std::uint64_t exp, std::uint64_t& out) {
  std::uint64_t r = 1;
  std::uint64_t b = base;
  std::uint64_t e = exp;
  while (e > 0u) {
    if ((e & 1u) != 0u && !tryMulUInt64Checked(r, b, r)) {
      return false;
    }
    e >>= 1;
    if (e > 0u && !tryMulUInt64Checked(b, b, b)) {
      return false;
    }
  }
  out = r;
  return true;
}

}  // namespace smartmath_internal
