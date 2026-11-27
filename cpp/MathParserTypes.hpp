#pragma once

// =============================================================================
//  MathParser numeric type configuration (single place for every width-specific fact)
//
//  ONE-CLICK RETARGET: change the three macros below (or pass /D... on the command line).
//    SMARTMATH_FLOAT_TYPE  floating-point type            default: double
//    SMARTMATH_INT_TYPE    signed integer type            default: long long
//    SMARTMATH_UINT_TYPE   unsigned type, same size       default: unsigned long long
//  Example (128-bit ints, extended floats, GCC/Clang):
//    -DSMARTMATH_FLOAT_TYPE="long double" -DSMARTMATH_INT_TYPE=__int128 \
//    "-DSMARTMATH_UINT_TYPE=unsigned __int128"
//  Everything else (limits, 2^N bounds, power-of-ten and factorial tables, digit counts, shift
//  limits, display digits, tolerances) is computed from these types below.
//
//  Supported float types: float, double, long double (std:: math overloads must exist).
//  Types without a std::numeric_limits specialization need the SMARTMATH_FLOAT_* macros below.
//  Integer limits never use std::numeric_limits (not specialized for __int128 in strict mode).
//  factorint keeps its own explicit 64-bit domain (see MathParserFactorInt.cpp).
// =============================================================================

#include <cassert>
#include <climits>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <limits>
#include <string>
#include <type_traits>

#ifndef SMARTMATH_FLOAT_TYPE
#define SMARTMATH_FLOAT_TYPE double
#endif
#ifndef SMARTMATH_INT_TYPE
#define SMARTMATH_INT_TYPE long long
#endif
#ifndef SMARTMATH_UINT_TYPE
#define SMARTMATH_UINT_TYPE unsigned long long
#endif

// Optional float profile overrides for a type that has no usable std::numeric_limits.
//   SMARTMATH_FLOAT_MANT_DIG     mantissa digits in base 2 (double: 53)
//   SMARTMATH_FLOAT_DIGITS10     decimal digits that always round-trip (double: 15)
//   SMARTMATH_FLOAT_MAX_EXP2     numeric_limits::max_exponent (double: 1024)
//   SMARTMATH_FLOAT_MAX_EXP10    numeric_limits::max_exponent10 (double: 308)

namespace smartmath {

using SmFloat = SMARTMATH_FLOAT_TYPE;
using SmInt = SMARTMATH_INT_TYPE;
using SmUInt = SMARTMATH_UINT_TYPE;

static_assert(sizeof(SmInt) == sizeof(SmUInt), "SmInt and SmUInt must have the same size");
static_assert(sizeof(SmInt) >= sizeof(int), "SmInt must be at least as wide as int");
static_assert(static_cast<SmInt>(-1) < static_cast<SmInt>(0), "SmInt must be signed");
static_assert(static_cast<SmUInt>(~static_cast<SmUInt>(0)) > static_cast<SmUInt>(0), "SmUInt must be unsigned");
static_assert(std::numeric_limits<SmFloat>::radix == 2, "SmFloat must be a binary floating-point type");
static_assert((static_cast<SmInt>(-1) >> 1) == static_cast<SmInt>(-1), "SmInt >> must be an arithmetic shift");

// ---- integer facts ----------------------------------------------------------------------------
constexpr int kIntBits = static_cast<int>(sizeof(SmInt) * CHAR_BIT);
constexpr SmUInt kUIntMax = static_cast<SmUInt>(~static_cast<SmUInt>(0));
/// 2^(kIntBits-1): the magnitude of the most negative SmInt.
constexpr SmUInt kIntMinMag = static_cast<SmUInt>(static_cast<SmUInt>(1) << (kIntBits - 1));
constexpr SmInt kIntMax = static_cast<SmInt>(kIntMinMag - 1);
constexpr SmInt kIntMin = static_cast<SmInt>(-kIntMax - 1);
/// Shift counts are valid in [0, kMaxShift].
constexpr int kMaxShift = kIntBits - 1;

// ---- float facts ------------------------------------------------------------------------------
#ifdef SMARTMATH_FLOAT_MANT_DIG
constexpr int kFloatMantDigits = SMARTMATH_FLOAT_MANT_DIG;
#else
constexpr int kFloatMantDigits = std::numeric_limits<SmFloat>::digits;
#endif
#ifdef SMARTMATH_FLOAT_DIGITS10
constexpr int kFloatDigits10 = SMARTMATH_FLOAT_DIGITS10;
#else
constexpr int kFloatDigits10 = std::numeric_limits<SmFloat>::digits10;
#endif
#ifdef SMARTMATH_FLOAT_MAX_EXP2
constexpr int kFloatMaxExp2 = SMARTMATH_FLOAT_MAX_EXP2;
#else
constexpr int kFloatMaxExp2 = std::numeric_limits<SmFloat>::max_exponent;
#endif
#ifdef SMARTMATH_FLOAT_MAX_EXP10
constexpr int kFloatMaxExp10 = SMARTMATH_FLOAT_MAX_EXP10;
#else
constexpr int kFloatMaxExp10 = std::numeric_limits<SmFloat>::max_exponent10;
#endif

constexpr bool kFloatIsBinary64 = std::is_same<SmFloat, double>::value;
/// True when SmFloat has a 53-bit mantissa, so the binary64-specific exact-product algorithm applies.
constexpr bool kFloatHasBinary64Mantissa = (kFloatMantDigits == 53);

/// Exact 2^n as SmFloat. +infinity when 2^n is beyond the finite range (so "v < bound" stays valid).
constexpr SmFloat pow2Float(int n) {
  if (n >= kFloatMaxExp2) {
    return std::numeric_limits<SmFloat>::infinity();
  }
  SmFloat r = static_cast<SmFloat>(1);
  if (n >= 0) {
    // Square-and-multiply: O(log n) steps. Every intermediate is a power of two below 2^n, so all products are exact.
    SmFloat base = static_cast<SmFloat>(2);
    for (int m = n; m > 0; m >>= 1) {
      if ((m & 1) != 0) {
        r *= base;
      }
      if (m > 1) {
        base *= base;
      }
    }
  } else {
    for (int i = 0; i < -n; ++i) {
      r /= static_cast<SmFloat>(2);
    }
  }
  return r;
}

/// 10^e as SmFloat by repeated multiplication (exact while 10^e is representable, otherwise nearest-ish).
/// A negative exponent is 1 / 10^-e, which is correctly rounded while 10^-e is exact.
constexpr SmFloat pow10Float(int e) {
  SmFloat r = static_cast<SmFloat>(1);
  const int n = (e < 0) ? -e : e;
  for (int i = 0; i < n; ++i) {
    r *= static_cast<SmFloat>(10);
  }
  return (e < 0) ? (static_cast<SmFloat>(1) / r) : r;
}

namespace detail {
// Chooses the historical literal when SmFloat is double (keeps default behavior bit-identical),
// otherwise the derived value. No conversion of the literal happens for other float types.
template <typename F, bool IsDouble>
struct BaselineOr {
  static constexpr F get(double, F derived) { return derived; }
};
template <typename F>
struct BaselineOr<F, true> {
  static constexpr F get(double baseline, F) { return baseline; }
};
}  // namespace detail

template <typename F>
constexpr F baselineOr(double baseline, F derived) {
  return detail::BaselineOr<F, std::is_same<F, double>::value>::get(baseline, derived);
}

/// 2^kFloatMantDigits: the largest magnitude at which every integer is exact (2^53 for double).
constexpr SmFloat kMaxExactIntFromFloat = pow2Float(kFloatMantDigits);
/// Bound H for float->exact promote (makeScalarMaybeExact): 2^min(|mant/2|, intBits-1). Exclusive |v|.
constexpr int kExactIntFromFloatOpExp =
    (kFloatMantDigits / 2 < kIntBits - 1) ? (kFloatMantDigits / 2) : (kIntBits - 1);
constexpr SmFloat kMaxExactIntFromFloatOp = pow2Float(kExactIntFromFloatOpExp);
/// Exclusive float bounds: SmInt covers [-kFloatSmIntBound, kFloatSmIntBound), SmUInt covers [0, kFloatSmUIntBound).
constexpr SmFloat kFloatSmIntBound = pow2Float(kIntBits - 1);
constexpr SmFloat kFloatSmUIntBound = pow2Float(kIntBits);
/// Veltkamp splitting constant 2^ceil(mantissa/2) + 1 (2^27 + 1 for double); computed once at compile time.
constexpr SmFloat kVeltkampSplitFactor = pow2Float((kFloatMantDigits + 1) / 2) + static_cast<SmFloat>(1);

/// True when 2^mantissa exceeds every SmUInt, so every integer magnitude is below the exact-float limit.
constexpr bool kExactLimitCoversSmUInt = (kFloatMantDigits >= kIntBits);
/// 2^mantissa as SmUInt (saturated to kUIntMax when kExactLimitCoversSmUInt; use isMagBelowExactFloatLimit).
constexpr SmUInt kExactLimitMag =
    kExactLimitCoversSmUInt ? kUIntMax : static_cast<SmUInt>(static_cast<SmUInt>(1) << (kExactLimitCoversSmUInt ? 0 : kFloatMantDigits));
/// mag < 2^mantissa: the integer magnitude is exactly representable as SmFloat.
inline bool isMagBelowExactFloatLimit(SmUInt mag) { return kExactLimitCoversSmUInt || mag < kExactLimitMag; }

/// True when v (finite) lies in the SmInt range, so static_cast<SmInt>(v) is defined (it truncates).
inline bool isFloatInSmIntRange(SmFloat v) {
  return v >= -kFloatSmIntBound && v < kFloatSmIntBound && v <= std::numeric_limits<SmFloat>::max();
}
/// True when v (finite) lies in the SmUInt range, so static_cast<SmUInt>(v) is defined (it truncates).
inline bool isFloatInSmUIntRange(SmFloat v) {
  return v >= static_cast<SmFloat>(0) && v < kFloatSmUIntBound && v <= std::numeric_limits<SmFloat>::max();
}

// ---- decimal digits of the integer type -------------------------------------------------------
namespace detail {
/// Largest n with 10^n <= kUIntMax (19 for 64-bit).
constexpr int maxPow10ExponentOfSmUInt() {
  int n = 0;
  SmUInt p = 1;
  while (p <= kUIntMax / 10u) {
    p *= 10u;
    ++n;
  }
  return n;
}
/// Largest n with 10^n <= kIntMax (18 for 64-bit).
constexpr int maxPow10ExponentOfInt() {
  int n = 0;
  SmInt p = 1;
  while (p <= kIntMax / 10) {
    p *= 10;
    ++n;
  }
  return n;
}
/// Largest n with n! <= kIntMax (20 for 64-bit).
constexpr int maxFactorialArgOfInt() {
  int n = 0;
  SmInt f = 1;
  while (f <= kIntMax / static_cast<SmInt>(n + 1)) {
    f *= static_cast<SmInt>(n + 1);
    ++n;
  }
  return n;
}
}  // namespace detail

/// Number of decimal digits of kUIntMax (20 for 64-bit).
constexpr int kUIntDigits10 = detail::maxPow10ExponentOfSmUInt() + 1;
/// Number of entries in kPow10SmUInt: 10^0 ... 10^(kUIntDigits10-1), all fit SmUInt.
constexpr int kPow10SmUIntCount = kUIntDigits10;
/// Largest n whose factorial fits SmInt.
constexpr int kMaxFactorialArg = detail::maxFactorialArgOfInt();
/// Largest n with 10^n <= kIntMax (18 for 64-bit): 10^n converts to SmInt without overflow.
constexpr int kMaxPow10ExponentOfInt = detail::maxPow10ExponentOfInt();

namespace detail {
struct Pow10SmUIntTable {
  SmUInt v[kPow10SmUIntCount];
  constexpr Pow10SmUIntTable() : v() {
    SmUInt p = 1;
    for (int i = 0; i < kPow10SmUIntCount; ++i) {
      v[i] = p;
      if (i + 1 < kPow10SmUIntCount) {
        p *= 10u;
      }
    }
  }
};
struct FactorialIntTable {
  SmInt v[kMaxFactorialArg + 1];
  constexpr FactorialIntTable() : v() {
    SmInt f = 1;
    for (int i = 0; i <= kMaxFactorialArg; ++i) {
      if (i > 0) {
        f *= static_cast<SmInt>(i);
      }
      v[i] = f;
    }
  }
};
constexpr Pow10SmUIntTable kPow10SmUIntTableData{};
constexpr FactorialIntTable kFactorialIntTableData{};
}  // namespace detail

/// 10^i as SmUInt. Precondition: 0 <= i < kPow10SmUIntCount (checked by assert only; Basic Pow10SmUInt returns 1 outside).
inline SmUInt pow10SmUInt(int i) {
  assert(i >= 0 && i < kPow10SmUIntCount);
  return detail::kPow10SmUIntTableData.v[i];
}
/// i! as SmInt. Precondition: 0 <= i <= kMaxFactorialArg (checked by assert only; callers range-check first).
inline SmInt factorialInt(int i) {
  assert(i >= 0 && i <= kMaxFactorialArg);
  return detail::kFactorialIntTableData.v[i];
}

// ---- integer text and float rounding helpers ------------------------------------------------------
// std::to_string has no __int128 overload, so integer text is produced here (same digits as to_string).
inline std::string uintToString(SmUInt v) {
  char buf[kUIntDigits10 + 1];
  int pos = kUIntDigits10 + 1;
  do {
    buf[--pos] = static_cast<char>('0' + static_cast<int>(v % 10u));
    v = static_cast<SmUInt>(v / 10u);
  } while (v != 0u);
  return std::string(buf + pos, static_cast<std::size_t>(kUIntDigits10 + 1 - pos));
}
inline std::string intToString(SmInt v) {
  if (v >= 0) {
    return uintToString(static_cast<SmUInt>(v));
  }
  // Magnitude via unsigned negation: kIntMin is never negated as a signed value.
  return "-" + uintToString(static_cast<SmUInt>(static_cast<SmUInt>(0) - static_cast<SmUInt>(v)));
}

/// Nearest integer (half away from zero) as SmInt. False (out untouched) for NaN, infinity or a rounded
/// value outside the SmInt range [-2^(b-1), 2^(b-1)).
inline bool tryRoundFloatToSmInt(SmFloat x, SmInt& out) {
  const SmFloat r = std::round(x);
  if (!isFloatInSmIntRange(r)) {
    return false;
  }
  out = static_cast<SmInt>(r);
  return true;
}
/// Nearest integer (half away from zero) as SmUInt. False (out untouched) for NaN, infinity or a rounded
/// value outside the SmUInt range [0, 2^b).
inline bool tryRoundFloatToSmUInt(SmFloat x, SmUInt& out) {
  const SmFloat r = std::round(x);
  if (!isFloatInSmUIntRange(r)) {
    return false;
  }
  out = static_cast<SmUInt>(r);
  return true;
}

// ---- radix output -----------------------------------------------------------------------------
/// Digit buffer large enough for SmUInt in base 2 (the widest rendering) plus a terminator.
constexpr int kRadixDigitBufLen = kIntBits + 1;

// ---- float display and parsing ----------------------------------------------------------------
/// Significant digits used when printing a non-exact float (digits10 + 1: 16 for double).
constexpr int kFloatDisplayDigits = kFloatDigits10 + 1;

inline int snprintfFloatG(char* buf, std::size_t n, int precision, float v) {
  return std::snprintf(buf, n, "%.*g", precision, static_cast<double>(v));
}
inline int snprintfFloatG(char* buf, std::size_t n, int precision, double v) {
  return std::snprintf(buf, n, "%.*g", precision, v);
}
inline int snprintfFloatG(char* buf, std::size_t n, int precision, long double v) {
  return std::snprintf(buf, n, "%.*Lg", precision, v);
}
inline int snprintfFloatE(char* buf, std::size_t n, int precision, float v) {
  return std::snprintf(buf, n, "%.*e", precision, static_cast<double>(v));
}
inline int snprintfFloatE(char* buf, std::size_t n, int precision, double v) {
  return std::snprintf(buf, n, "%.*e", precision, v);
}
inline int snprintfFloatE(char* buf, std::size_t n, int precision, long double v) {
  return std::snprintf(buf, n, "%.*Le", precision, v);
}

inline float strtoFloatPrefix(const char* s, char** end, float) { return std::strtof(s, end); }
inline double strtoFloatPrefix(const char* s, char** end, double) { return std::strtod(s, end); }
inline long double strtoFloatPrefix(const char* s, char** end, long double) { return std::strtold(s, end); }
/// Parses a decimal float prefix of s as SmFloat (strtof / strtod / strtold by type).
inline SmFloat parseFloatPrefix(const char* s, char** end) {
  return strtoFloatPrefix(s, end, SmFloat());
}

// ---- tolerances and thresholds (decimal-digit derived) ------------------------------------------
/// Most digits a tolerance may give up: at least 3/5 of kFloatDigits10 always stay significant, so every
/// tolerance stays well below 1 (double: 6 of 15, float: 3 of 6, long double: 8 of 18).
constexpr int kMaxLostDigits = kFloatDigits10 - (kFloatDigits10 * 3) / 5;
/// 10^-(kFloatDigits10 - lostDigits): an absolute tolerance that leaves lostDigits digits of noise room
/// (lostDigits is capped at kMaxLostDigits).
/// double: 0 -> 1e-15, 1 -> 1e-14, 2 -> 1e-13, 3 -> 1e-12, 6 -> 1e-9.
constexpr SmFloat floatTolerance(int lostDigits) {
  return pow10Float(-(kFloatDigits10 - (lostDigits < kMaxLostDigits ? lostDigits : kMaxLostDigits)));
}
constexpr SmFloat kTolLost0 = floatTolerance(0);
constexpr SmFloat kTolLost1 = floatTolerance(1);
constexpr SmFloat kTolLost2 = floatTolerance(2);
constexpr SmFloat kTolLost3 = floatTolerance(3);
constexpr SmFloat kTolLost6 = floatTolerance(6);

/// hypot switches to the scaled algorithm above this magnitude (1e150 for double) and below its inverse.
constexpr SmFloat kHypotDirectMax = baselineOr<SmFloat>(1e150, pow10Float(kFloatMaxExp10 / 2 - 4));
constexpr SmFloat kHypotDirectMin = baselineOr<SmFloat>(1e-150, pow10Float(-(kFloatMaxExp10 / 2 - 4)));
/// From this magnitude on, asinh and the complex asin/acos paths use their ln(2|z|) asymptotic form, because
/// z * z could overflow. Same value as kHypotDirectMax (squares stay finite below it).
constexpr SmFloat kLargeMagnitudeMin = kHypotDirectMax;

/// Start value for "smallest error so far" searches: larger than any real error, and still finite after
/// being multiplied by a denominator up to 1e7 (1e300 for double).
constexpr SmFloat kHugeSentinel = baselineOr<SmFloat>(1e300, pow10Float(kFloatMaxExp10 - 8));

/// acosh(z) is ln(2z) from this magnitude on (1e8 for double): the dropped term 1/(4 z^2) is then below the
/// float rounding noise, so ln(2z) is as accurate as the exact formula and cannot overflow.
constexpr SmFloat kAcoshLogMin = baselineOr<SmFloat>(1e8, pow10Float((kFloatDigits10 + 1) / 2));

static_assert(kTolLost0 > static_cast<SmFloat>(0) && kTolLost0 <= kTolLost1 && kTolLost1 <= kTolLost2 && kTolLost2 <= kTolLost3 &&
                  kTolLost3 <= kTolLost6 && kTolLost6 < static_cast<SmFloat>(1) / 100,
              "tolerances must grow with lost digits and stay well below 1");

// Baseline guards: the default config must reproduce the historical literals bit for bit.
static_assert(!kFloatIsBinary64 || kTolLost0 == 1e-15, "tolerance 1e-15 changed");
static_assert(!kFloatIsBinary64 || kTolLost1 == 1e-14, "tolerance 1e-14 changed");
static_assert(!kFloatIsBinary64 || kTolLost2 == 1e-13, "tolerance 1e-13 changed");
static_assert(!kFloatIsBinary64 || kTolLost3 == 1e-12, "tolerance 1e-12 changed");
static_assert(!kFloatIsBinary64 || kTolLost6 == 1e-9, "tolerance 1e-9 changed");
static_assert(!kFloatIsBinary64 || kMaxExactIntFromFloat == 9007199254740992.0, "2^53 changed");
static_assert(!kFloatIsBinary64 || kMaxExactIntFromFloatOp == 67108864.0, "Bound H 2^26 changed");
static_assert(!kFloatIsBinary64 || kFloatDisplayDigits == 16, "display digits changed");
static_assert(!kFloatIsBinary64 || kHypotDirectMax == 1e150, "hypot threshold changed");
static_assert(!kFloatIsBinary64 || kAcoshLogMin == 1e8, "acosh threshold changed");
static_assert(!std::is_same<SmInt, long long>::value ||
                  (kIntBits == 64 && kIntMax == 9223372036854775807LL && kUIntMax == 18446744073709551615ULL &&
                   kIntMinMag == 9223372036854775808ULL),
              "64-bit integer limits changed");
static_assert(!std::is_same<SmInt, long long>::value ||
                  (kUIntDigits10 == 20 && kPow10SmUIntCount == 20 && kMaxFactorialArg == 20 && kMaxShift == 63 &&
                   kMaxPow10ExponentOfInt == 18),
              "64-bit digit/factorial/shift limits changed");

}  // namespace smartmath
