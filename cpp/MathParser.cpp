#include "MathParser.hpp"

#include <algorithm>
#include <cassert>
#include <cmath>
#include <cctype>
#include <cstring>
#include <cstdlib>
#include <limits>
#include <numeric>
#include <unordered_set>
#include <utility>

namespace {
constexpr double kPi = 3.1415926535897932384626433832795;
constexpr int kMaxEvalDepth = 128;

constexpr const char* STR_NAN = "nan";
constexpr const char* STR_NEG_INF = "-inf";
constexpr const char* STR_INF = "inf";
constexpr const char* STR_NEG_ZERO = "-0";
constexpr const char* STR_HEX_DIGITS_LOWER = "0123456789abcdef";
constexpr const char* STR_HEX_DIGITS_UPPER = "0123456789ABCDEF";
constexpr const char* STR_COMMA = ", ";
constexpr const char* STR_PI = "pi";
constexpr const char* STR_E = "e";
constexpr const char* STR_ANS = "ans";
constexpr const char* STR_FORMAL_VALIDATION_PROBE = "_";
constexpr const char* STR_RAND = "rand";
constexpr const char* STR_RANDOM = "random";
constexpr const char* STR_BIN = "bin";
constexpr const char* STR_HEX = "hex";
constexpr const char* STR_OCT = "oct";
constexpr const char* STR_POW = "pow";
constexpr const char* STR_ATAN2 = "atan2";
constexpr const char* STR_SIN = "sin";
constexpr const char* STR_COS = "cos";
constexpr const char* STR_TAN = "tan";
constexpr const char* STR_ASIN = "asin";
constexpr const char* STR_ARCSIN = "arcsin";
constexpr const char* STR_ACOS = "acos";
constexpr const char* STR_ARCCOS = "arccos";
constexpr const char* STR_ATAN = "atan";
constexpr const char* STR_ARCTAN = "arctan";
constexpr const char* STR_SINH = "sinh";
constexpr const char* STR_COSH = "cosh";
constexpr const char* STR_TANH = "tanh";
constexpr const char* STR_ACOSH = "acosh";
constexpr const char* STR_ASINH = "asinh";
constexpr const char* STR_ATANH = "atanh";
constexpr const char* STR_EXP = "exp";
constexpr const char* STR_LOG = "log";
constexpr const char* STR_LN = "ln";
constexpr const char* STR_LOG10 = "log10";
constexpr const char* STR_SQRT = "sqrt";
constexpr const char* STR_SQR = "sqr";
constexpr const char* STR_INT = "int";
constexpr const char* STR_FRAC = "frac";
constexpr const char* STR_FRACT = "fract";
constexpr const char* STR_ABS = "abs";
constexpr const char* STR_FLOOR = "floor";
constexpr const char* STR_CEIL = "ceil";
constexpr const char* STR_TRUNC = "trunc";
constexpr const char* STR_ROUND = "round";
constexpr const char* STR_SIGN = "sign";
constexpr const char* STR_DEG = "deg";
constexpr const char* STR_RAD = "rad";
constexpr const char* STR_SUM = "sum";
constexpr const char* STR_MEDIAN = "median";
constexpr const char* STR_VARIANCE = "variance";
constexpr const char* STR_STDDEV = "stddev";
constexpr const char* STR_SORT = "sort";
constexpr const char* STR_SORTED = "sorted";
constexpr const char* STR_REVERSE = "reverse";
constexpr const char* STR_REVERSED = "reversed";
constexpr const char* STR_UNIQUE = "unique";
constexpr const char* STR_UNPACK = "unpack";
constexpr const char* STR_FACT = "fact";
constexpr const char* STR_FACTORIAL = "factorial";
constexpr const char* STR_AVG = "avg";
constexpr const char* STR_MEAN = "mean";
constexpr const char* STR_MOD = "mod";
constexpr const char* STR_CLAMP = "clamp";
constexpr const char* STR_HYPOT = "hypot";
constexpr const char* STR_GCD = "gcd";
constexpr const char* STR_LCM = "lcm";
constexpr const char* STR_NCR = "ncr";
constexpr const char* STR_NPR = "npr";
constexpr const char* STR_PRODUCT = "product";
constexpr const char* STR_PROD = "prod";
constexpr const char* STR_MIN = "min";
constexpr const char* STR_MAX = "max";
constexpr const char* STR_UHEX = "uhex";
constexpr const char* STR_UOCT = "uoct";
constexpr const char* STR_UBIN = "ubin";
constexpr const char* STR_NOT = "not";
constexpr const char* STR_AND = "and";
constexpr const char* STR_OR = "or";
constexpr const char* STR_HINT_PREFIX = "function: ";
constexpr const char* STR_PAR_EMPTY = "()";
constexpr const char* STR_PAR_MIN_COMMA_MAX = "(min, max)";
constexpr const char* STR_PAR_VALUE_COMMA_POWER = "(value, power)";
constexpr const char* STR_PAR_Y_COMMA_X = "(y, x)";
constexpr const char* STR_PAR_ANGLE = "(angle)";
constexpr const char* STR_PAR_VALUE = "(value)";
constexpr const char* STR_PAR_VALUE_COMMA_BASE = "(value, base)";
constexpr const char* STR_PAR_N = "(n)";
constexpr const char* STR_PAR_VALUE_COMMA_DIVISOR = "(value, divisor)";
constexpr const char* STR_PAR_VALUE_COMMA_MIN_COMMA_MAX = "(value, min, max)";
constexpr const char* STR_PAR_X_COMMA_Y = "(x, y)";
constexpr const char* STR_PAR_A_COMMA_B = "(a, b)";
constexpr const char* STR_PAR_N_COMMA_R = "(n, r)";
constexpr const char* STR_PAR_DOTDOTDOT = "(...)";
constexpr const char* STR_UNEXPECTED_TOKEN = "unexpected token";
constexpr const char* STR_INCOMPATIBLE_OPERANDS = "incompatible operands";
constexpr const char* STR_POS_POW63_DEC_TEXT = "9.223372036854778e+018";
constexpr const char* STR_NEG_POW63_DEC_TEXT = "-9.223372036854778e+018";
constexpr double K_MAX_EXACT_INT_FROM_DOUBLE = 9007199254740992.0;  // 2^53
constexpr const char* STR_PREFIX_HEX = "0x";
constexpr const char* STR_PREFIX_OCT = "0o";
constexpr const char* STR_PREFIX_BIN = "0b";
constexpr const char* STR_UNEXPECTED_COMMA = "unexpected comma";
constexpr const char* STR_MISSING_CLOSING_PARENTHESIS = "missing closing parenthesis";
constexpr const char* STR_INVALID_HEX_LITERAL = "invalid hex literal";
constexpr const char* STR_INVALID_BINARY_LITERAL = "invalid binary literal";
constexpr const char* STR_INVALID_OCTAL_LITERAL = "invalid octal literal";
constexpr const char* STR_INVALID_NUMERIC_LITERAL = "invalid numeric literal";
constexpr const char* STR_MISSING_INDEX = "missing index";
constexpr const char* STR_MISSING_CLOSING_BRACKET = "missing closing bracket";
constexpr const char* STR_LT_EQ = "<=";
constexpr const char* STR_GT_EQ = ">=";
constexpr const char* STR_EQ_EQ = "==";
constexpr const char* STR_NOT_EQ = "!=";
constexpr const char* STR_LT_GT = "<>";
constexpr const char* STR_DUPLICATE_PARAMETER_NAME = "duplicate parameter name";
constexpr const char* STR_RESERVED_CONSTANT_NAME = "reserved constant name";
constexpr const char* STR_RESERVED_FUNCTION_NAME = "reserved function name";
constexpr const char* STR_RECURSIVE_USER_FUNCTION_CALL_COLON = "recursive function call: ";
constexpr const char* STR_UNEXPECTED_TOKEN_AFTER_EXPRESSION = "unexpected token after expression";
constexpr const char* STR_SCALAR_ONLY_EXPRESSION_ENCOUNTERED_NON = "scalar-only expression encountered non-scalar value";
constexpr const char* STR_BITWISE_OPERANDS_MUST_BE_INTEGER_VALUES = "bitwise operands must be integer values";
constexpr const char* STR_INTERNAL_UNARY_OP = "internal unary op";
constexpr const char* STR_MODULO_OPERANDS_MUST_BE_INTEGER_VALUES = "modulo operands must be integer values";
constexpr const char* STR_NUMERIC_ERROR_IN_POWER_OPERATION = "numeric error in power operation";
constexpr const char* STR_NUMERIC_ERROR_IN_EXPRESSION = "numeric error in expression";
constexpr const char* STR_INTERNAL_BINARY_OP = "internal binary op";
constexpr const char* STR_INTERNAL_EVAL_ERROR = "internal eval error";
constexpr const char* STR_PERCENTAGE_REQUIRES_SCALAR_VALUE = "percentage requires scalar value";
constexpr const char* STR_FAILED_TO_BUILD_ARRAY_LITERAL = "failed to build array literal";
constexpr const char* STR_INDEXING_REQUIRES_AN_ARRAY_VALUE = "indexing requires an array value";
constexpr const char* STR_ARRAY_INDEX_MUST_BE_A_SCALAR = "array index must be a scalar integer";
constexpr const char* STR_ARRAY_INDEX_MUST_BE_AN_INTEGER = "array index must be an integer";
constexpr const char* STR_ARRAY_INDEX_IS_OUT_OF_RANGE = "array index is out of range";
constexpr const char* STR_PAR_EXPECTS_AT_LEAST_1 = "() expects at least 1 argument";
constexpr const char* STR_INTERNAL_ERROR_IN_AGGREGATE_BUILTIN = "internal error in aggregate builtin";
constexpr const char* STR_UNEXPECTED_DOUBLE_SIZE = "unexpected double size";
constexpr const char* STR_PAR_EXPECTS_INTEGER_VALUES = "() expects integer values";
constexpr const char* STR_NUMERIC_ERROR_IN = "numeric error in ";
constexpr const char* STR_PAR = "()";
constexpr const char* STR_PAR_EXPECTS_SCALAR_MIN_SLASH = "() expects scalar min/max";
constexpr const char* STR_PAR_EXPECTS_SCALAR_VALUES = "() expects scalar values";
constexpr const char* STR_INTERNAL_ERROR_IN_SCALAR_BINARY_BUILTIN = "internal error in scalar binary builtin";
constexpr const char* STR_PAR_EXPECTS_A_NON_DASH = "() expects a non-negative integer";
constexpr const char* STR_INTERNAL_ERROR_IN_UNARY_MATH_BUILTIN = "internal error in unary math builtin";
constexpr const char* STR_PAR_EXPECTS = "() expects ";
constexpr const char* STR_ARGUMENT_PAR_S = " argument(s)";
constexpr const char* STR_MAX_EVALUATION_DEPTH_REACHED = "max evaluation depth reached";
constexpr const char* STR_USER_FUNCTION_CALL_STACK_OVERFLOW = "function call stack overflow";
constexpr const char* STR_FAILED_TO_PARSE_USER_FUNCTION_BODY = "failed to parse user function body";
constexpr const char* STR_UNEXPECTED_INPUT = "unexpected characters";
constexpr const char* STR_PARSE_FAILED = "parse failed";
constexpr const char* STR_NOTHING_COMPILED_SEMICOLON_CALL_COMPILE_PAR = "nothing compiled; call compile() first";
constexpr const char* STR_UNKNOWN_VARIABLE_COLON = "unknown variable: ";
constexpr const char* STR_SEMICOLON_UNKNOWN_FUNCTION_COLON = "; unknown function: ";
constexpr const char* STR_UNKNOWN_FUNCTION_COLON = "unknown function: ";
constexpr const char* STR_INVALID_USER_FUNCTION_EXPRESSION = "invalid user function expression";
constexpr const char* STR_UNEXPECTED_CONTENT_AFTER_FUNCTION_DEFINITION = "unexpected content after function definition";

inline int quickMult10(int x) {
  // x*10 = x*(8+2) = x*8 + x*2 = (x<<3) + (x<<1)
  return ((x << 3) + (x << 1));
}

inline std::uint64_t quickMult10(std::uint64_t x) {
  // x*10 = x*(8+2) = x*8 + x*2 = (x<<3) + (x<<1)
  return ((x << 3) + (x << 1));
}

std::uint64_t mult10_N_times(std::uint64_t x, int N) {
  for (;N > 0; --N) {
    x = quickMult10(x);
  }
  return x;
}

bool identAsciiEqualsLower(const std::string& body, std::size_t i0, std::size_t len, const std::string& bLower) {
  if (len != bLower.size()) {
    return false;
  }
  for (std::size_t k = 0; k < bLower.size(); ++k) {
    if (std::tolower(static_cast<unsigned char>(body[i0 + k])) != static_cast<unsigned char>(bLower[k])) {
      return false;
    }
  }
  return true;
}

bool udfBodyCallsDefinedFunction(const std::string& body, const std::string& fnNameLower) {
  if (fnNameLower.empty()) {
    return false;
  }
  const std::size_t n = body.size();
  std::size_t i = 0;
  while (i < n) {
    unsigned char ch = static_cast<unsigned char>(body[i]);
    const bool identStart = std::isalpha(ch) != 0 || ch == '_';
    if (!identStart) {
      ++i;
      continue;
    }
    const std::size_t i0 = i;
    ++i;
    while (i < n) {
      ch = static_cast<unsigned char>(body[i]);
      if (std::isalnum(ch) != 0 || ch == '_') {
        ++i;
      } else {
        break;
      }
    }
    if (identAsciiEqualsLower(body, i0, i - i0, fnNameLower)) {
      std::size_t j = i;
      while (j < n && std::isspace(static_cast<unsigned char>(body[j])) != 0) {
        ++j;
      }
      if (j < n && body[j] == '(') {
        return true;
      }
    }
  }
  return false;
}

double clampDouble(double x, double lo, double hi) {
  return std::max(lo, std::min(hi, x));
}

double randomUnitScalar() {
  return static_cast<double>(std::rand()) / static_cast<double>(RAND_MAX);
}

double squareScalar(double x) {
  return x * x;
}

double fracScalar(double x) {
  return x - std::trunc(x);
}

int parseDigitForRadix(char c, unsigned int radix) {
  int d = -1;
  if (c >= '0' && c <= '9') d = c - '0';
  else if (c >= 'a' && c <= 'f') d = 10 + (c - 'a');
  else if (c >= 'A' && c <= 'F') d = 10 + (c - 'A');
  if (d < 0 || static_cast<unsigned int>(d) >= radix) {
    return -1;
  }
  return d;
}

bool tryParsePrefixedUIntLiteral(const char* p, char prefixLower, unsigned int radix, const char*& outEnd, std::uint64_t& outValue) {
  if (p[0] != '0') {
    return false;
  }
  const char px = static_cast<char>(std::tolower(static_cast<unsigned char>(p[1])));
  if (px != prefixLower) {
    return false;
  }

  const char* cur = p + 2;
  std::uint64_t u = 0;
  int digits = 0;
  while (*cur) {
    const int d = parseDigitForRadix(*cur, radix);
    if (d < 0) {
      break;
    }
    const std::uint64_t ud = static_cast<std::uint64_t>(d);
    const std::uint64_t base = static_cast<std::uint64_t>(radix);
    if (u > (((std::numeric_limits<std::uint64_t>::max)() - ud) / base)) {
      return false;
    }
    u = (u * base) + ud;
    ++cur;
    ++digits;
  }
  if (digits == 0) {
    return false;
  }
  outEnd = cur;
  outValue = u;
  return true;
}

// Helper: Convert a digit array to uint64_t with overflow checking
inline bool digitsToUint64(const unsigned char* digits, int digitCount, std::uint64_t& outValue) {
  std::uint64_t value = 0;
  for (int i = 0; i < digitCount; ++i) {
    const unsigned char digit = digits[i];
    if (value > ((std::numeric_limits<std::uint64_t>::max)() - digit) / 10u) {
      return false;
    }
    value = value * 10 + digit;
  }
  outValue = value;
  return true;
}

bool tryParseInputNumberAsInteger(const char* numStart, const char* numEnd, std::uint64_t& outValue) {
  static constexpr std::uint64_t pow10_u64[20] = {
    1ull,
    10ull,
    100ull,
    1000ull,
    10000ull,
    100000ull,
    1000000ull,
    10000000ull,
    100000000ull,
    1000000000ull,
    10000000000ull,
    100000000000ull,
    1000000000000ull,
    10000000000000ull,
    100000000000000ull,
    1000000000000000ull,
    10000000000000000ull,
    100000000000000000ull,
    1000000000000000000ull,
    10000000000000000000ull
  };

  if (!numStart || !numEnd || numStart >= numEnd) {
    return false;
  }

  const char* p = numStart;
  if (*p == '+') {
    ++p;
  }
  if (p >= numEnd || *p == '-') {
    return false;
  }

  constexpr int MaxDigits = 128;
  unsigned char digits[MaxDigits];
  int storedDigitCount = 0;
  int intDigitCount = 0;
  int fracDigits = 0;
  bool intPartStarted = false;
  bool hasDigit = false;

  while (p < numEnd && *p >= '0' && *p <= '9') {
    const int digit = *p - '0';
    hasDigit = true;
    if (digit != 0) {
      intPartStarted = true;
    }
    if (intPartStarted) {
      if (storedDigitCount < MaxDigits) {
        digits[storedDigitCount++] = static_cast<unsigned char>(digit);
      } else {
        return false;
      }
      ++intDigitCount;
    }
    ++p;
  }

  if (p < numEnd && *p == '.') {
    ++p;
    intPartStarted = true;
    while (p < numEnd && *p >= '0' && *p <= '9') {
      const int digit = *p - '0';
      hasDigit = true;
      if (storedDigitCount < MaxDigits) {
        digits[storedDigitCount++] = static_cast<unsigned char>(digit);
      } else if (digit != 0) {
        return false;
      }
      ++fracDigits;
      ++p;
    }
  }

  if (!hasDigit) {
    return false;
  }

  if (storedDigitCount == 0) {
    outValue = 0;
    return true;
  }

  int exponent = 0;
  bool exponentNegative = false;
  if (p < numEnd && (*p == 'e' || *p == 'E')) {
    ++p;
    if (p < numEnd && (*p == '+' || *p == '-')) {
      exponentNegative = (*p == '-');
      ++p;
    }
    if (p >= numEnd || *p < '0' || *p > '9') {
      return false;
    }

    int exponentDigits = 0;
    while (p < numEnd && *p >= '0' && *p <= '9') {
      const int digit = *p - '0';
      if (digit != 0 || exponentDigits != 0) {
        if (++exponentDigits > 2) {
          return false; // exponent is too large
        }
        exponent = exponent * 10 + digit;
      }
      ++p;
    }
    if (exponentNegative) {
      exponent = -exponent;
    }
  }

  if (p != numEnd) {
    return false;
  }

  const int significantDigits = intDigitCount + fracDigits;
  const int adjust = exponent - fracDigits;

  if (adjust >= 0) {
    if (significantDigits + adjust > 20) {
      return false;
    }

    std::uint64_t value = 0;
    if (!digitsToUint64(digits, storedDigitCount, value)) {
      return false;
    }

    if (adjust > 0) {
      if (value > (std::numeric_limits<std::uint64_t>::max)() / pow10_u64[adjust]) {
        return false;
      }
      value *= pow10_u64[adjust];
    }

    outValue = value;
    return true;
  }

  const int divisor = -adjust;
  if (divisor > storedDigitCount) {
    return false;
  }
  for (int i = storedDigitCount - divisor; i < storedDigitCount; ++i) {
    if (digits[i] != 0) {
      return false;
    }
  }

  const int resultDigitCount = storedDigitCount - divisor;
  if (resultDigitCount == 0) {
    outValue = 0;
    return true;
  }

  std::uint64_t value = 0;
  if (!digitsToUint64(digits, resultDigitCount, value)) {
    return false;
  }

  outValue = value;
  return true;
}

long long gcdInt64(long long a, long long b) {
  if (a < 0) a = -a;
  if (b < 0) b = -b;
  while (b != 0) {
    const long long t = a % b;
    a = b;
    b = t;
  }
  return a;
}

std::uint64_t gcdUInt64(std::uint64_t a, std::uint64_t b) {
  while (b != 0u) {
    const std::uint64_t t = a % b;
    a = b;
    b = t;
  }
  return a;
}

bool tryLcmUInt64(std::uint64_t a, std::uint64_t b, std::uint64_t& out) {
  if (a == 0u || b == 0u) {
    out = 0u;
    return true;
  }
  const std::uint64_t g = gcdUInt64(a, b);
  const std::uint64_t a1 = a / g;
  if (a1 > ((std::numeric_limits<std::uint64_t>::max)() / b)) {
    return false;
  }
  out = a1 * b;
  return true;
}

bool tryAddUInt64Checked(std::uint64_t a, std::uint64_t b, std::uint64_t& out) {
  const std::uint64_t s = a + b;
  if (s < a) {
    return false;
  }
  out = s;
  return true;
}

bool tryMulUInt64Checked(std::uint64_t a, std::uint64_t b, std::uint64_t& out) {
  if (b != 0u && a > ((std::numeric_limits<std::uint64_t>::max)() / b)) {
    return false;
  }
  out = a * b;
  return true;
}

bool tryPowUInt64Checked(std::uint64_t base, std::uint64_t exp, std::uint64_t& out) {
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

bool tryAddInt64Checked(long long a, long long b, long long& out) {
  if ((b > 0 && a > (std::numeric_limits<long long>::max)() - b) ||
      (b < 0 && a < (std::numeric_limits<long long>::min)() - b)) {
    return false;
  }
  out = a + b;
  return true;
}

bool tryMulInt64Checked(long long a, long long b, long long& out) {
  if (a == 0 || b == 0) {
    out = 0;
    return true;
  }
  if (a == -1) {
    if (b == (std::numeric_limits<long long>::min)()) return false;
    out = -b;
    return true;
  }
  if (b == -1) {
    if (a == (std::numeric_limits<long long>::min)()) return false;
    out = -a;
    return true;
  }
  if (a > 0) {
    if (b > 0) {
      if (a > (std::numeric_limits<long long>::max)() / b) return false;
    } else {
      if (b < (std::numeric_limits<long long>::min)() / a) return false;
    }
  } else {
    if (b > 0) {
      if (a < (std::numeric_limits<long long>::min)() / b) return false;
    } else {
      if (a != 0 && b < (std::numeric_limits<long long>::max)() / a) return false;
    }
  }
  out = a * b;
  return true;
}

bool tryComputeNprInt64(long long n, long long r, long long& out) {
  if (n < 0 || r < 0 || r > n) return false;
  long long acc = 1;
  for (long long i = 0; i < r; ++i) {
    long long term = n - i;
    if (!tryMulInt64Checked(acc, term, acc)) return false;
  }
  out = acc;
  return true;
}

bool tryComputeNcrInt64(long long n, long long r, long long& out) {
  if (n < 0 || r < 0 || r > n) return false;
  if (r == 0) {
    out = 1;
    return true;
  }
  long long rEff = r;
  if ((n - rEff) < rEff) rEff = (n - rEff);
  long long acc = 1;
  for (long long i = 1; i <= rEff; ++i) {
    long long num = (n - rEff) + i;
    long long den = i;
    long long g1 = gcdInt64(num, den);
    if (g1 > 1) {
      num /= g1;
      den /= g1;
    }
    long long g2 = gcdInt64(acc, den);
    if (g2 > 1) {
      acc /= g2;
      den /= g2;
    }
    if (den != 1) return false;
    if (!tryMulInt64Checked(acc, num, acc)) return false;
  }
  out = acc;
  return true;
}

bool isMultipleOf(double x, double x_mult)
{
  const double abs_x = std::fabs(x);
  const double y = abs_x/x_mult + abs_x/1e+15;
  return ((y >= 1.0) && (y/std::trunc(y) - 1.0 < 1e-14));
}

double calcSin(double x)
{
  if (x == 0.0)
    return 0.0;

  if (std::isfinite(x))
  {
    if (isMultipleOf(x, kPi))
      return 0.0; // sin(N*pi), N = 1,2,3,4,...
  }

  return std::sin(x);
}

double calcCos(double x)
{
  if (std::isfinite(x))
  {
    if ((!isMultipleOf(x, kPi)) && isMultipleOf(x, kPi/2))
      return 0.0; // cos(N*pi/2), N = 1,3,5,7,...
  }

  return std::cos(x);
}

double calcTan(double x)
{
  if (x == 0.0)
    return 0.0;

  if (std::isfinite(x))
  {
    if (isMultipleOf(x, kPi))
      return 0.0; // tan(N*pi), N = 1,2,3,4,...

    if (isMultipleOf(x, kPi/2))
      return ((std::tan(x) > 0.0) ? std::numeric_limits<double>::infinity() : -std::numeric_limits<double>::infinity()); // tan(N*pi/2), N = 1,3,5,7,...
  }

  return std::tan(x);
}

std::string formatDoubleFast(double v) {
  // Custom "general" formatter: 16 significant digits in fixed mode, 16 in scientific (smoke parity).
  // Uses only direct character-buffer operations.
  if (std::isnan(v)) return STR_NAN;
  if (std::isinf(v)) return (v < 0.0) ? STR_NEG_INF : STR_INF;
  if (v == 0.0) return "0";

  constexpr int kGenDigits = 17;
  constexpr int kSciOutDigits = 16;
  constexpr int kFixedOutDigits = 16;
  long double x = static_cast<long double>(v);
  bool neg = (x < 0.0L);
  if (neg) x = -x;

  int exp10 = static_cast<int>(std::floor(std::log10(x)));
  long double p10 = std::pow(10.0L, exp10);
  if (p10 == 0.0L) {
    return neg ? STR_NEG_ZERO : "0";
  }

  long double norm = x / p10;
  if (norm >= 10.0L) {
    norm /= 10.0L;
    ++exp10;
  } else if (norm < 1.0L) {
    norm *= 10.0L;
    --exp10;
  }

  constexpr int kExtraDigits = 4;
  int digits[kGenDigits + kExtraDigits] = {0};
  for (int i = 0; i < kGenDigits + kExtraDigits; ++i) {
    int d = static_cast<int>(norm);
    if (d < 0) d = 0;
    if (d > 9) d = 9;
    digits[i] = d;
    norm = (norm - static_cast<long double>(d)) * 10.0L;
  }

  // Round last kept digit using the extra digit.
  bool roundUp = false;
  if (digits[kGenDigits] > 5) {
    roundUp = true;
  } else if (digits[kGenDigits] == 5) {
    for (int i = kGenDigits + 1; i < kGenDigits + kExtraDigits; ++i) {
      if (digits[i] != 0) {
        roundUp = true;
        break;
      }
    }
    if (!roundUp && (digits[kGenDigits - 1] % 2 != 0)) {
      roundUp = true;
    }
  }
  if (roundUp) {
    int i = kGenDigits - 1;
    for (; i >= 0; --i) {
      if (digits[i] < 9) {
        ++digits[i];
        break;
      }
      digits[i] = 0;
    }
    if (i < 0) {
      // 9.999... rounded -> 1.000... and bump exponent.
      digits[0] = 1;
      for (int j = 1; j < kGenDigits; ++j) {
        digits[j] = 0;
      }
      ++exp10;
    }
  }

  // Match "general": fixed for [-4, 15), scientific otherwise.
  const bool useScientific = (exp10 < -4 || exp10 >= kSciOutDigits);
  int sciDigits = kGenDigits;
  if (useScientific) {
    bool sciRound = false;
    if (digits[kSciOutDigits] > 5) {
      sciRound = true;
    } else if (digits[kSciOutDigits] == 5) {
      // There are no fractional digits beyond digits[kSciOutDigits] in the
      // scientific output window (kGenDigits == kSciOutDigits + 1).
      if (!sciRound && (digits[kSciOutDigits - 1] % 2 != 0)) {
        sciRound = true;
      }
    }
    if (sciRound) {
      int i = kSciOutDigits - 1;
      for (; i >= 0; --i) {
        if (digits[i] < 9) {
          ++digits[i];
          break;
        }
        digits[i] = 0;
      }
      if (i < 0) {
        digits[0] = 1;
        for (int j = 1; j < kSciOutDigits; ++j) {
          digits[j] = 0;
        }
        ++exp10;
      }
    }
    sciDigits = kSciOutDigits;
  }
  char out[128] = {0};
  int pos = 0;

  if (neg) out[pos++] = '-';

  if (useScientific) {
    out[pos++] = static_cast<char>('0' + digits[0]);
    // Fractional part
    int fracEnd = sciDigits - 1;
    while (fracEnd > 0 && digits[fracEnd] == 0) {
      --fracEnd;
    }
    if (fracEnd > 0) {
      out[pos++] = '.';
      for (int i = 1; i <= fracEnd; ++i) {
        out[pos++] = static_cast<char>('0' + digits[i]);
      }
    }
    out[pos++] = 'e';
    out[pos++] = (exp10 >= 0) ? '+' : '-';
    int e = (exp10 >= 0) ? exp10 : -exp10;
    char eb[16];
    int ep = 0;
    do {
      eb[ep++] = static_cast<char>('0' + (e % 10));
      e /= 10;
    } while (e > 0);
    while (ep < 3) {
      eb[ep++] = '0';
    }
    for (int i = ep - 1; i >= 0; --i) {
      out[pos++] = eb[i];
    }
  } else {
    // Fixed notation: place decimal point after exp10+1 digits.
    int intDigits = exp10 + 1;
    if (intDigits <= 0) {
      out[pos++] = '0';
      out[pos++] = '.';
      for (int i = 0; i < -intDigits; ++i) {
        out[pos++] = '0';
      }
      for (int i = 0; i < kFixedOutDigits; ++i) {
        out[pos++] = static_cast<char>('0' + digits[i]);
      }
    } else {
      int i = 0;
      for (; i < intDigits; ++i) {
        out[pos++] = (i < kGenDigits) ? static_cast<char>('0' + digits[i]) : '0';
      }
      if (intDigits < kFixedOutDigits) {
        out[pos++] = '.';
        for (; i < kFixedOutDigits; ++i) {
          out[pos++] = static_cast<char>('0' + digits[i]);
        }
      }
    }
    // Trim trailing zeros/dot in fixed mode.
    while (pos > 0 && out[pos - 1] == '0') {
      --pos;
    }
    if (pos > 0 && out[pos - 1] == '.') {
      --pos;
    }
  }

  if (pos <= 0) return "0";
  return std::string(out, static_cast<std::size_t>(pos));
}

std::string formatUnsignedBase(std::uint64_t u, unsigned base, const char* prefix, bool uppercase) {
  static constexpr const char* kDigitsLo = STR_HEX_DIGITS_LOWER;
  static constexpr const char* kDigitsHi = STR_HEX_DIGITS_UPPER;
  const char* digits = uppercase ? kDigitsHi : kDigitsLo;

  char tmp[65];
  int pos = 0;
  if (u == 0) {
    tmp[pos++] = '0';
  } else {
    while (u > 0) {
      tmp[pos++] = digits[u % base];
      u /= base;
    }
  }

  std::string out(prefix);
  out.reserve(out.size() + static_cast<std::size_t>(pos));
  const std::size_t digitsCount = static_cast<std::size_t>(pos);
  for (std::size_t i = 0; i < digitsCount; ++i) {
    out.push_back(tmp[digitsCount - 1 - i]);
  }
  return out;
}

unsigned renderBaseRadix(int baseCode) {
  if (baseCode == 16) return 16U;
  if (baseCode == 8) return 8U;
  return 2U;
}

const char* renderBasePrefix(int baseCode) {
  if (baseCode == 16) return STR_PREFIX_HEX;
  if (baseCode == 8) return STR_PREFIX_OCT;
  return STR_PREFIX_BIN;
}

bool renderBaseUppercase(int baseCode) {
  return baseCode == 16;
}

std::string formatUnsignedForRenderBase(std::uint64_t u, int baseCode) {
  return formatUnsignedBase(u, renderBaseRadix(baseCode), renderBasePrefix(baseCode), renderBaseUppercase(baseCode));
}

std::string formatSignedMagnitudeForRenderBase(
    long long iv,
    int baseCode,
    bool asUnsigned) {
  if (asUnsigned) {
    return formatUnsignedForRenderBase(static_cast<std::uint64_t>(iv), baseCode);
  }
  std::uint64_t mag = 0;
  if (iv < 0) {
    if (iv == (std::numeric_limits<long long>::min)()) {
      mag = (1ull << 63);
    } else {
      mag = static_cast<std::uint64_t>(-iv);
    }
    return "-" + formatUnsignedForRenderBase(mag, baseCode);
  }
  return formatUnsignedForRenderBase(static_cast<std::uint64_t>(iv), baseCode);
}

std::string stripLineComments(const std::string& s) {
  for (std::size_t i = 0; i < s.size(); ++i) {
    if (s[i] == '#') {
      return s.substr(0, i);
    }
    if (s[i] == '/' && (i + 1) < s.size() && s[i + 1] == '/') {
      return s.substr(0, i);
    }
  }
  return s;
}

bool checkedAddLL(long long a, long long b, long long& out) {
  if ((b > 0 && a > (std::numeric_limits<long long>::max)() - b) ||
      (b < 0 && a < (std::numeric_limits<long long>::min)() - b)) {
    return false;
  }
  out = a + b;
  return true;
}

bool checkedSubLL(long long a, long long b, long long& out) {
  if ((b < 0 && a > (std::numeric_limits<long long>::max)() + b) ||
      (b > 0 && a < (std::numeric_limits<long long>::min)() + b)) {
    return false;
  }
  out = a - b;
  return true;
}

bool checkedMulLL(long long a, long long b, long long& out) {
  if (a == 0 || b == 0) {
    out = 0;
    return true;
  }
  if (a > 0) {
    if (b > 0) {
      if (a > (std::numeric_limits<long long>::max)() / b) return false;
    } else {
      if (b < (std::numeric_limits<long long>::min)() / a) return false;
    }
  } else {
    if (b > 0) {
      if (a < (std::numeric_limits<long long>::min)() / b) return false;
    } else {
      if (a != 0 && b < (std::numeric_limits<long long>::max)() / a) return false;
    }
  }
  out = a * b;
  return true;
}

long long bitwiseShiftLeftDefined(long long value, unsigned int shiftCount) {
  const std::uint64_t u = static_cast<std::uint64_t>(value);
  const std::uint64_t shifted = u << shiftCount;
  if (shifted <= static_cast<std::uint64_t>((std::numeric_limits<long long>::max)())) {
    return static_cast<long long>(shifted);
  }
  const std::uint64_t magnitude = (~shifted) + 1u;
  if (magnitude == (1ull << 63)) {
    return (std::numeric_limits<long long>::min)();
  }
  return -static_cast<long long>(magnitude);
}

long long bitwiseShiftRightDefined(long long value, unsigned int shiftCount) {
  const std::uint64_t u = static_cast<std::uint64_t>(value);
  std::uint64_t shifted = 0;
  if (value >= 0) {
    shifted = u >> shiftCount;
  } else {
    shifted = ~((~u) >> shiftCount);
  }
  if (shifted <= static_cast<std::uint64_t>((std::numeric_limits<long long>::max)())) {
    return static_cast<long long>(shifted);
  }
  const std::uint64_t magnitude = (~shifted) + 1u;
  if (magnitude == (1ull << 63)) {
    return (std::numeric_limits<long long>::min)();
  }
  return -static_cast<long long>(magnitude);
}

bool parseUInt64FromDecimalLiteral(const char* begin, const char* end, std::uint64_t& out) {
  if (!begin || !end || begin >= end) {
    return false;
  }
  std::uint64_t v = 0;
  for (const char* p = begin; p < end; ++p) {
    const char c = *p;
    if (c < '0' || c > '9') {
      return false;
    }
    const std::uint64_t digit = static_cast<std::uint64_t>(c - '0');
    if (v > ((std::numeric_limits<std::uint64_t>::max)() - digit) / 10u) {
      return false;
    }
    v = quickMult10(v) + digit;
  }
  out = v;
  return true;
}

void appendUniqueName(std::string& listText, const std::string& n) {
  const std::string token = std::string(",") + listText + ",";
  const std::string needle = std::string(",") + n + ",";
  if (token.find(needle) != std::string::npos) {
    return;
  }
  if (listText.empty()) {
    listText = n;
  } else {
    listText += STR_COMMA;
    listText += n;
  }
}

void mergeUnknownNameList(std::string& dest, const std::string& src) {
  if (src.empty()) {
    return;
  }
  std::size_t i = 0;
  while (i < src.size()) {
    while (i < src.size() && (src[i] == ' ' || src[i] == ',')) {
      ++i;
    }
    if (i >= src.size()) {
      break;
    }
    std::size_t j = i;
    while (j < src.size() && src[j] != ',') {
      ++j;
    }
    std::string token = src.substr(i, j - i);
    while (!token.empty() && std::isspace(static_cast<unsigned char>(token.front()))) {
      token.erase(token.begin());
    }
    while (!token.empty() && std::isspace(static_cast<unsigned char>(token.back()))) {
      token.pop_back();
    }
    if (!token.empty()) {
      appendUniqueName(dest, token);
    }
    i = j;
  }
}
}  // namespace

MathParser::MathParser() {
  assert(functionNames().size() == static_cast<std::size_t>(BuiltinFunctionId::Count));
  assert(operatorNames().size() == static_cast<std::size_t>(OperatorNameId::Count));
  addConst(STR_PI, kPi);
  addConst(STR_E, std::exp(1.0));
  addConst(STR_INF, std::numeric_limits<double>::infinity());
  addConst(STR_NAN, std::numeric_limits<double>::quiet_NaN());
  setVariable(STR_ANS, makeScalarInt(0));
  setVariable(STR_FORMAL_VALIDATION_PROBE, makeScalarInt(1));
}

std::string MathParser::toLower(std::string s) {
  std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
  return s;
}

const std::vector<std::string>& MathParser::functionNames() {
  static const std::vector<std::string> kNames = {
      STR_RAND,   STR_RANDOM, STR_BIN,   STR_HEX,    STR_OCT,      STR_POW,  STR_ATAN2, STR_SIN,      STR_COS,  STR_TAN,
      STR_ASIN,   STR_ARCSIN, STR_ACOS,  STR_ARCCOS, STR_ATAN,     STR_ARCTAN, STR_SINH, STR_COSH,     STR_TANH, STR_ACOSH, STR_ASINH, STR_ATANH, STR_EXP,
      STR_LOG,    STR_LN,     STR_LOG10, STR_SQRT,   STR_SQR,      STR_INT,  STR_FRAC,  STR_FRACT,    STR_ABS,  STR_FLOOR,
      STR_CEIL,   STR_TRUNC,  STR_ROUND, STR_SIGN,   STR_DEG,      STR_RAD,  STR_SUM,   STR_MEDIAN,   STR_VARIANCE, STR_STDDEV,
      STR_SORT,   STR_SORTED, STR_REVERSE, STR_REVERSED, STR_UNIQUE, STR_UNPACK, STR_FACT, STR_FACTORIAL, STR_AVG, STR_MEAN,
      STR_MOD,    STR_CLAMP,  STR_HYPOT, STR_GCD,    STR_LCM,      STR_NCR, STR_NPR, STR_PRODUCT, STR_PROD, STR_MIN, STR_MAX,
      STR_UHEX,   STR_UOCT,   STR_UBIN};
  return kNames;
}

const std::unordered_map<std::string, MathParser::BuiltinFunctionId>& MathParser::functionNameToId() {
  static const std::unordered_map<std::string, BuiltinFunctionId> kByName = [] {
    std::unordered_map<std::string, BuiltinFunctionId> m;
    m.reserve(functionNames().size());
    for (std::size_t i = 0; i < functionNames().size(); ++i) {
      m.emplace(functionNames()[i], static_cast<BuiltinFunctionId>(i));
    }
    return m;
  }();
  return kByName;
}

const std::vector<std::string>& MathParser::operatorNames() {
  static const std::vector<std::string> kNames = {STR_NOT, STR_AND, STR_OR};
  return kNames;
}

const std::string& MathParser::getFunctionName(BuiltinFunctionId id) {
  return functionNames().at(static_cast<std::size_t>(id));
}

const std::string& MathParser::opName(OperatorNameId id) {
  return operatorNames().at(static_cast<std::size_t>(id));
}

bool MathParser::tryGetBuiltinFunctionId(const std::string& nameText, BuiltinFunctionId& outId) {
  const auto& byName = functionNameToId();
  auto it = byName.find(nameText);
  if (it == byName.end()) {
    return false;
  }
  outId = it->second;
  return true;
}

MathParser::BuiltinHintKind MathParser::getBuiltinHintKind(BuiltinFunctionId id) {
  switch (id) {
    case BuiltinFunctionId::Rand: return BuiltinHintKind::EmptyPar;
    case BuiltinFunctionId::Random: return BuiltinHintKind::MinMax;
    case BuiltinFunctionId::Bin:
    case BuiltinFunctionId::Hex:
    case BuiltinFunctionId::Oct:
    case BuiltinFunctionId::Ubin:
    case BuiltinFunctionId::Uhex:
    case BuiltinFunctionId::Uoct: return BuiltinHintKind::DotDotDot;
    case BuiltinFunctionId::Pow: return BuiltinHintKind::ValuePower;
    case BuiltinFunctionId::Atan2: return BuiltinHintKind::YX;
    case BuiltinFunctionId::Sin:
    case BuiltinFunctionId::Cos:
    case BuiltinFunctionId::Tan: return BuiltinHintKind::Angle;
    case BuiltinFunctionId::Asin:
    case BuiltinFunctionId::Arcsin:
    case BuiltinFunctionId::Acos:
    case BuiltinFunctionId::Arccos:
    case BuiltinFunctionId::Atan:
    case BuiltinFunctionId::Arctan:
    case BuiltinFunctionId::Sinh:
    case BuiltinFunctionId::Cosh:
    case BuiltinFunctionId::Tanh:
    case BuiltinFunctionId::Acosh:
    case BuiltinFunctionId::Asinh:
    case BuiltinFunctionId::Atanh:
    case BuiltinFunctionId::Exp:
    case BuiltinFunctionId::Ln:
    case BuiltinFunctionId::Log10:
    case BuiltinFunctionId::Sqrt:
    case BuiltinFunctionId::Sqr:
    case BuiltinFunctionId::Int:
    case BuiltinFunctionId::Abs:
    case BuiltinFunctionId::Floor:
    case BuiltinFunctionId::Ceil:
    case BuiltinFunctionId::Trunc:
    case BuiltinFunctionId::Round:
    case BuiltinFunctionId::Sign:
    case BuiltinFunctionId::Frac:
    case BuiltinFunctionId::Fract: return BuiltinHintKind::Value;
    case BuiltinFunctionId::Log: return BuiltinHintKind::ValueBase;
    case BuiltinFunctionId::Deg:
    case BuiltinFunctionId::Rad:
    case BuiltinFunctionId::Sum:
    case BuiltinFunctionId::Median:
    case BuiltinFunctionId::Variance:
    case BuiltinFunctionId::Stddev:
    case BuiltinFunctionId::Unique:
    case BuiltinFunctionId::Unpack:
    case BuiltinFunctionId::Avg:
    case BuiltinFunctionId::Mean:
    case BuiltinFunctionId::Product:
    case BuiltinFunctionId::Prod:
    case BuiltinFunctionId::Min:
    case BuiltinFunctionId::Max:
    case BuiltinFunctionId::Sort:
    case BuiltinFunctionId::Sorted:
    case BuiltinFunctionId::Reverse:
    case BuiltinFunctionId::Reversed: return BuiltinHintKind::DotDotDot;
    case BuiltinFunctionId::Fact:
    case BuiltinFunctionId::Factorial: return BuiltinHintKind::N;
    case BuiltinFunctionId::Mod: return BuiltinHintKind::ValueDivisor;
    case BuiltinFunctionId::Clamp: return BuiltinHintKind::ValueMinMax;
    case BuiltinFunctionId::Hypot: return BuiltinHintKind::XY;
    case BuiltinFunctionId::Gcd:
    case BuiltinFunctionId::Lcm: return BuiltinHintKind::AB;
    case BuiltinFunctionId::Ncr:
    case BuiltinFunctionId::Npr: return BuiltinHintKind::AB;
    default: return BuiltinHintKind::None;
  }
}

MathParser::BuiltinFunctionId MathParser::getBuiltinHintDisplayId(BuiltinFunctionId id) {
  switch (id) {
    case BuiltinFunctionId::Arcsin: return BuiltinFunctionId::Asin;
    case BuiltinFunctionId::Arccos: return BuiltinFunctionId::Acos;
    case BuiltinFunctionId::Arctan: return BuiltinFunctionId::Atan;
    case BuiltinFunctionId::Fract: return BuiltinFunctionId::Frac;
    case BuiltinFunctionId::Sorted: return BuiltinFunctionId::Sort;
    case BuiltinFunctionId::Reversed: return BuiltinFunctionId::Reverse;
    default: return id;
  }
}

std::string MathParser::getBuiltinFunctionMissingCallHint(BuiltinFunctionId id) {
  const MathParser::BuiltinHintKind kind = getBuiltinHintKind(id);
  if (kind == BuiltinHintKind::None) return "";
  const std::string& fnName = getFunctionName(getBuiltinHintDisplayId(id));
  switch (kind) {
    case BuiltinHintKind::EmptyPar: return fnName + STR_PAR_EMPTY;
    case BuiltinHintKind::MinMax: return fnName + STR_PAR_MIN_COMMA_MAX;
    case BuiltinHintKind::DotDotDot: return fnName + STR_PAR_DOTDOTDOT;
    case BuiltinHintKind::ValuePower: return fnName + STR_PAR_VALUE_COMMA_POWER;
    case BuiltinHintKind::YX: return fnName + STR_PAR_Y_COMMA_X;
    case BuiltinHintKind::Angle: return fnName + STR_PAR_ANGLE;
    case BuiltinHintKind::Value: return fnName + STR_PAR_VALUE;
    case BuiltinHintKind::ValueBase: return fnName + STR_PAR_VALUE_COMMA_BASE;
    case BuiltinHintKind::N: return fnName + STR_PAR_N;
    case BuiltinHintKind::ValueDivisor: return fnName + STR_PAR_VALUE_COMMA_DIVISOR;
    case BuiltinHintKind::ValueMinMax: return fnName + STR_PAR_VALUE_COMMA_MIN_COMMA_MAX;
    case BuiltinHintKind::XY: return fnName + STR_PAR_X_COMMA_Y;
    case BuiltinHintKind::AB:
      if (id == BuiltinFunctionId::Ncr || id == BuiltinFunctionId::Npr) return fnName + STR_PAR_N_COMMA_R;
      return fnName + STR_PAR_A_COMMA_B;
    default: return "";
  }
}

bool MathParser::isOpKeyword(const std::string& nameText, OperatorNameId id) {
  return nameText == opName(id);
}

bool MathParser::isLogicalBinaryOperatorKeyword(const std::string& nameText) {
  return isOpKeyword(nameText, OperatorNameId::And) || isOpKeyword(nameText, OperatorNameId::Or);
}

bool MathParser::isReservedFunctionName(const std::string& nameText) {
  BuiltinFunctionId id = BuiltinFunctionId::Count;
  return tryGetBuiltinFunctionId(nameText, id)
      || isOpKeyword(nameText, OperatorNameId::Not)
      || isLogicalBinaryOperatorKeyword(nameText);
}

const char* MathParser::getReservedIdentifierError(const std::string& ident) {
  if (isReservedFunctionName(ident)) {
    return STR_RESERVED_FUNCTION_NAME;
  }
  if (ident == STR_PI || ident == STR_E || ident == STR_INF || ident == STR_NAN) {
    return STR_RESERVED_CONSTANT_NAME;
  }
  return nullptr;
}

bool MathParser::isTrailingFormatterFunctionName(const std::string& nameText) {
  BuiltinFunctionId id = BuiltinFunctionId::Count;
  if (!tryGetBuiltinFunctionId(nameText, id)) {
    return false;
  }
  return id == BuiltinFunctionId::Hex || id == BuiltinFunctionId::Oct || id == BuiltinFunctionId::Bin
      || id == BuiltinFunctionId::Uhex || id == BuiltinFunctionId::Uoct || id == BuiltinFunctionId::Ubin
      || id == BuiltinFunctionId::Rad || id == BuiltinFunctionId::Deg;
}

bool MathParser::trySetMissingFunctionCallError(EvalContext& ctx, const std::string& ident) const {
  BuiltinFunctionId bid = BuiltinFunctionId::Count;
  if (!tryGetBuiltinFunctionId(ident, bid)) {
    return false;
  }
  std::string hint = getBuiltinFunctionMissingCallHint(bid);
  if (!hint.empty()) setFunctionHintError(ctx, hint);
  else setFunctionHintError(ctx, ident + STR_PAR_DOTDOTDOT);
  return true;
}

bool MathParser::handleUnknownIdentifier(EvalContext& ctx, const std::string& ident, std::string& unknownList) const {
  if (isLogicalBinaryOperatorKeyword(ident)) {
    setUnexpectedTokenError(ctx);
    return true;
  }
  if (trySetMissingFunctionCallError(ctx, ident)) {
    return true;
  }
  appendUniqueName(unknownList, ident);
  return false;
}

bool MathParser::tryResolveVariableValue(
    const Expr& e,
    const std::unordered_map<std::string, EvalValue>* scopedVars,
    EvalValue& out) const {
  if (scopedVars) {
    auto it = scopedVars->find(e.name);
    if (it != scopedVars->end()) {
      if (it->second.kind == ValueKind::UdfFormalValidationDummy) {
        auto pit = variables_.find(STR_FORMAL_VALIDATION_PROBE);
        if (pit != variables_.end() && pit->second.kind == ValueKind::Scalar) {
          out = pit->second;
        } else {
          out = makeScalarInt(1);
        }
      } else {
        out = it->second;
      }
      return true;
    }
  }
  if (e.boundVariable != nullptr) {
    out = *e.boundVariable;
    return true;
  }
  auto it = variables_.find(e.name);
  if (it != variables_.end()) {
    out = it->second;
    return true;
  }
  return false;
}

MathParser::EvalValue MathParser::makeUdfFormalValidationDummy() {
  EvalValue v;
  v.kind = ValueKind::UdfFormalValidationDummy;
  return v;
}

static bool isReservedBuiltinConstantName(const std::string& nameText) {
  return nameText == STR_PI || nameText == STR_E || nameText == STR_INF || nameText == STR_NAN;
}

const char* MathParser::validateUserFunctionDefinitionNames(
    const std::string& fnName,
    const std::vector<std::string>& fnParams) {
  if (const char* reservedErr = getReservedIdentifierError(fnName)) {
    return reservedErr;
  }
  std::unordered_map<std::string, bool> seen;
  for (const auto& p : fnParams) {
    if (seen.find(p) != seen.end()) {
      return STR_DUPLICATE_PARAMETER_NAME;
    }
    if (isReservedBuiltinConstantName(p)) {
      return STR_RESERVED_CONSTANT_NAME;
    }
    seen[p] = true;
  }
  return nullptr;
}

std::string MathParser::getUserFunctionDefinitionErrorText(
    const std::string& fnName,
    const std::vector<std::string>& fnParams,
    const std::string& fnExpr,
    const bool evaluateBody) {
  if (const char* udfNameErr = validateUserFunctionDefinitionNames(fnName, fnParams)) {
    return udfNameErr;
  }
  if (udfBodyCallsDefinedFunction(fnExpr, fnName)) {
    return STR_RECURSIVE_USER_FUNCTION_CALL_COLON + fnName;
  }
  EvalContext bodyCtx;
  bodyCtx.sourceExpr = fnExpr;
  bodyCtx.p = fnExpr.c_str();
  bodyCtx.start = bodyCtx.p;
  std::unique_ptr<Expr> ex = parseExpression(bodyCtx);
  if (bodyCtx.parseError || !ex) {
    if (!bodyCtx.errorText.empty()) {
      return bodyCtx.errorText;
    }
    return STR_FAILED_TO_PARSE_USER_FUNCTION_BODY;
  }
  skipSpaces(bodyCtx);
  if (*bodyCtx.p != '\0') {
    return STR_UNEXPECTED_INPUT;
  }

  if (!evaluateBody) {
    return "";
  }

  std::unordered_map<std::string, EvalValue> formalScoped;
  formalScoped.reserve(fnParams.size());
  for (const auto& p : fnParams) {
    formalScoped.emplace(p, makeUdfFormalValidationDummy());
  }

  bodyCtx.parseError = false;
  bodyCtx.errorText.clear();
  bodyCtx.unknownVarsText.clear();
  bodyCtx.unknownFuncsText.clear();

  (void)evalExpr(*ex, bodyCtx, &formalScoped);

  if (bodyCtx.parseError) {
    if (!bodyCtx.errorText.empty()) {
      return bodyCtx.errorText;
    }
    return STR_FAILED_TO_PARSE_USER_FUNCTION_BODY;
  }
  // Like Basic TryValidateUserFunctionBodyExpression: do not treat accumulated unknown
  // identifiers as definition errors (late-bound UDFs may appear only after later statements).
  return "";
}

bool MathParser::trySetUserFunctionDefinitionError(
    EvalContext& ctx,
    const std::string& fnName,
    const std::vector<std::string>& fnParams,
    const std::string& fnExpr) {
  // Parse-only here: formal-probe evaluation needs variables from earlier statements in the
  // same program, which are not applied until runCompiledProgram (Basic evaluates top-level
  // statements sequentially before the next).
  const std::string err = getUserFunctionDefinitionErrorText(fnName, fnParams, fnExpr, false);
  if (err.empty()) {
    return false;
  }
  setValidationError(ctx, err.c_str());
  return true;
}

const char* MathParser::validateAssignmentTargetName(const std::string& ident) {
  return getReservedIdentifierError(ident);
}

std::string MathParser::buildUnknownVariableErrorText(const std::string& unknownVarsText) {
  return STR_UNKNOWN_VARIABLE_COLON + unknownVarsText;
}

std::string MathParser::buildUnknownFunctionErrorText(const std::string& unknownFuncsText) {
  return STR_UNKNOWN_FUNCTION_COLON + unknownFuncsText;
}

void MathParser::appendUnknownFunctionErrorText(std::string& errorText, const std::string& unknownFuncsText) {
  errorText += STR_SEMICOLON_UNKNOWN_FUNCTION_COLON + unknownFuncsText;
}

void MathParser::setValidationError(EvalContext& ctx, const char* errorText) const {
  setError(ctx, errorText);
}

bool MathParser::trySetUnknownNameError(const EvalContext& ctx) {
  lastError_ = buildUnknownNameErrorText(ctx.unknownVarsText, ctx.unknownFuncsText);
  return !lastError_.empty();
}

std::string MathParser::buildUnknownNameErrorText(
    const std::string& unknownVarsText,
    const std::string& unknownFuncsText) {
  if (!unknownVarsText.empty()) {
    std::string errorText = buildUnknownVariableErrorText(unknownVarsText);
    if (!unknownFuncsText.empty()) {
      appendUnknownFunctionErrorText(errorText, unknownFuncsText);
    }
    return errorText;
  }
  if (!unknownFuncsText.empty()) {
    return buildUnknownFunctionErrorText(unknownFuncsText);
  }
  return "";
}

bool MathParser::tryAppendParsedExpressionStatement(
    EvalContext& ctx,
    std::vector<AstStatement>& out) {
  auto ex = parseExpression(ctx);
  if (ctx.parseError || !ex) {
    return false;
  }
  AstStatement st;
  st.kind = AstStatement::Kind::Expr;
  st.expr = std::move(ex);
  out.emplace_back(std::move(st));
  return true;
}

bool MathParser::tryAppendFunctionDefinitionStatement(EvalContext& ctx, std::vector<AstStatement>& out) {
  std::string fnName;
  std::vector<std::string> fnParams;
  std::string fnExpr;
  if (!parseFunctionDefinition(ctx, fnName, fnParams, fnExpr)) {
    return false;
  }
  if (trySetUserFunctionDefinitionError(ctx, fnName, fnParams, fnExpr)) {
    return false;
  }
  AstStatement st;
  st.kind = AstStatement::Kind::FunDef;
  st.fun = UserFunction{fnName, fnParams, fnExpr};
  out.emplace_back(std::move(st));
  return true;
}

bool MathParser::tryAppendAssignOrExpressionStatement(EvalContext& ctx, std::vector<AstStatement>& out) {
  const char* assignSave = ctx.p;
  if (isIdentStart(*ctx.p)) {
    std::string ident = consumeLowerIdentToken(ctx);
    skipSpaces(ctx);
    // Single '=' is assignment; '==' is equality (do not steal first '=').
    if (*ctx.p == '=' && ctx.p[1] != '=') {
      if (const char* assignNameErr = validateAssignmentTargetName(ident)) {
        setValidationError(ctx, assignNameErr);
        return false;
      }
      ++ctx.p;
      auto ex = parseExpression(ctx);
      if (ctx.parseError || !ex) {
        return false;
      }
      AstStatement st;
      st.kind = AstStatement::Kind::Assign;
      st.assignName = std::move(ident);
      st.expr = std::move(ex);
      out.emplace_back(std::move(st));
      return true;
    }
    ctx.p = assignSave;
  }
  return tryAppendParsedExpressionStatement(ctx, out);
}

bool MathParser::consumeProgramStatementSeparator(EvalContext& ctx) {
  skipSpaces(ctx);
  if (*ctx.p == ';') {
    ++ctx.p;
    return true;
  }
  if (*ctx.p == '\0') {
    return false;
  }
  setUnexpectedTokenAfterExpressionError(ctx);
  return false;
}

bool MathParser::hasExprParseFailure(const EvalContext& ctx, const std::unique_ptr<Expr>& node) {
  return ctx.parseError || !node;
}

void MathParser::setNumericErrorInFunction(EvalContext& ctx, const std::string& fnName) const {
  setError(ctx, STR_NUMERIC_ERROR_IN + fnName + STR_PAR);
}

void MathParser::setAtLeastOneArgError(EvalContext& ctx, const std::string& fnName) const {
  setError(ctx, fnName + STR_PAR_EXPECTS_AT_LEAST_1);
}

void MathParser::setExactArgCountError(
    EvalContext& ctx,
    const std::string& fnName,
    size_t expectedCount) const {
  setError(ctx, fnName + STR_PAR_EXPECTS + std::to_string(expectedCount) + STR_ARGUMENT_PAR_S);
}

void MathParser::setScalarValuesError(EvalContext& ctx, const std::string& fnName) const {
  setError(ctx, fnName + STR_PAR_EXPECTS_SCALAR_VALUES);
}

void MathParser::setIntegerValuesError(EvalContext& ctx, const std::string& fnName) const {
  setError(ctx, fnName + STR_PAR_EXPECTS_INTEGER_VALUES);
}

void MathParser::setScalarMinMaxError(EvalContext& ctx, const std::string& fnName) const {
  setError(ctx, fnName + STR_PAR_EXPECTS_SCALAR_MIN_SLASH);
}

void MathParser::setNonNegativeIntegerError(EvalContext& ctx, const std::string& fnName) const {
  setError(ctx, fnName + STR_PAR_EXPECTS_A_NON_DASH);
}

void MathParser::setBitwiseIntegerOperandsError(EvalContext& ctx) const {
  setError(ctx, STR_BITWISE_OPERANDS_MUST_BE_INTEGER_VALUES);
}

void MathParser::setModuloIntegerOperandsError(EvalContext& ctx) const {
  setError(ctx, STR_MODULO_OPERANDS_MUST_BE_INTEGER_VALUES);
}

void MathParser::setIncompatibleOperandsError(EvalContext& ctx) const {
  setError(ctx, STR_INCOMPATIBLE_OPERANDS);
}

void MathParser::setUnexpectedCommaError(EvalContext& ctx) const {
  setError(ctx, STR_UNEXPECTED_COMMA);
}

void MathParser::setIndexingRequiresArrayError(EvalContext& ctx) const {
  setError(ctx, STR_INDEXING_REQUIRES_AN_ARRAY_VALUE);
}

void MathParser::setMissingIndexError(EvalContext& ctx) const {
  setError(ctx, STR_MISSING_INDEX);
}

void MathParser::setArrayIndexMustBeScalarError(EvalContext& ctx) const {
  setError(ctx, STR_ARRAY_INDEX_MUST_BE_A_SCALAR);
}

void MathParser::setArrayIndexMustBeIntegerError(EvalContext& ctx) const {
  setError(ctx, STR_ARRAY_INDEX_MUST_BE_AN_INTEGER);
}

void MathParser::setArrayIndexOutOfRangeError(EvalContext& ctx) const {
  setError(ctx, STR_ARRAY_INDEX_IS_OUT_OF_RANGE);
}

void MathParser::setMissingClosingBracketError(EvalContext& ctx) const {
  setError(ctx, STR_MISSING_CLOSING_BRACKET);
}

void MathParser::setMissingClosingParenthesisError(EvalContext& ctx) const {
  setError(ctx, STR_MISSING_CLOSING_PARENTHESIS);
}

void MathParser::setFunctionHintError(EvalContext& ctx, const std::string& hintText) const {
  setError(ctx, STR_HINT_PREFIX + hintText);
}

void MathParser::setInvalidHexLiteralError(EvalContext& ctx) const {
  setStaticError(ctx, STR_INVALID_HEX_LITERAL);
}

void MathParser::setInvalidBinaryLiteralError(EvalContext& ctx) const {
  setStaticError(ctx, STR_INVALID_BINARY_LITERAL);
}

void MathParser::setInvalidOctalLiteralError(EvalContext& ctx) const {
  setStaticError(ctx, STR_INVALID_OCTAL_LITERAL);
}

void MathParser::setInvalidPrefixedLiteralError(EvalContext& ctx, char prefixChar) const {
  switch (prefixChar) {
    case 'x':
    case 'X':
      setInvalidHexLiteralError(ctx);
      return;
    case 'b':
    case 'B':
      setInvalidBinaryLiteralError(ctx);
      return;
    case 'o':
    case 'O':
      setInvalidOctalLiteralError(ctx);
      return;
    default:
      setInvalidNumericLiteralError(ctx);
      return;
  }
}

void MathParser::setInternalUnaryOpError(EvalContext& ctx) const {
  setStaticError(ctx, STR_INTERNAL_UNARY_OP);
}

void MathParser::setInternalBinaryOpError(EvalContext& ctx) const {
  setStaticError(ctx, STR_INTERNAL_BINARY_OP);
}

void MathParser::setInternalEvalError(EvalContext& ctx) const {
  setStaticError(ctx, STR_INTERNAL_EVAL_ERROR);
}

void MathParser::setNumericErrorInPowerOperation(EvalContext& ctx) const {
  setStaticError(ctx, STR_NUMERIC_ERROR_IN_POWER_OPERATION);
}

void MathParser::setNumericErrorInExpression(EvalContext& ctx) const {
  setStaticError(ctx, STR_NUMERIC_ERROR_IN_EXPRESSION);
}

void MathParser::setUserFunctionCallStackOverflowError(EvalContext& ctx) const {
  setStaticError(ctx, STR_USER_FUNCTION_CALL_STACK_OVERFLOW);
}

void MathParser::setRecursiveUserFunctionCallError(EvalContext& ctx, const std::string& fnName) const {
  setError(ctx, STR_RECURSIVE_USER_FUNCTION_CALL_COLON + fnName);
}

void MathParser::setMaxEvaluationDepthReachedError(EvalContext& ctx) const {
  setStaticError(ctx, STR_MAX_EVALUATION_DEPTH_REACHED);
}

void MathParser::setInvalidNumericLiteralError(EvalContext& ctx) const {
  setStaticError(ctx, STR_INVALID_NUMERIC_LITERAL);
}

void MathParser::setPercentageRequiresScalarValueError(EvalContext& ctx) const {
  setStaticError(ctx, STR_PERCENTAGE_REQUIRES_SCALAR_VALUE);
}

void MathParser::setFailedToBuildArrayLiteralError(EvalContext& ctx) const {
  setStaticError(ctx, STR_FAILED_TO_BUILD_ARRAY_LITERAL);
}

void MathParser::setInternalAggregateBuiltinError(EvalContext& ctx) const {
  setStaticError(ctx, STR_INTERNAL_ERROR_IN_AGGREGATE_BUILTIN);
}

void MathParser::setInternalScalarBinaryBuiltinError(EvalContext& ctx) const {
  setStaticError(ctx, STR_INTERNAL_ERROR_IN_SCALAR_BINARY_BUILTIN);
}

void MathParser::setInternalUnaryMathBuiltinError(EvalContext& ctx) const {
  setStaticError(ctx, STR_INTERNAL_ERROR_IN_UNARY_MATH_BUILTIN);
}

void MathParser::setUnexpectedTokenAfterExpressionError(EvalContext& ctx) const {
  setStaticError(ctx, STR_UNEXPECTED_TOKEN_AFTER_EXPRESSION);
}

void MathParser::setScalarOnlyExpressionEncounteredNonError(EvalContext& ctx) const {
  setStaticError(ctx, STR_SCALAR_ONLY_EXPRESSION_ENCOUNTERED_NON);
}

void MathParser::setParseFailedError(EvalContext& ctx) const {
  setStaticError(ctx, STR_PARSE_FAILED);
}

void MathParser::setStaticError(EvalContext& ctx, const char* errorText) const {
  setError(ctx, errorText);
}

bool MathParser::isIdentStart(char c) {
  return std::isalpha(static_cast<unsigned char>(c)) || c == '_';
}

bool MathParser::isIdentChar(char c) {
  return std::isalnum(static_cast<unsigned char>(c)) || c == '_';
}

bool MathParser::isNumericLiteralStart(char c) {
  return std::isdigit(static_cast<unsigned char>(c)) || c == '.';
}

std::string MathParser::consumeLowerIdentToken(EvalContext& ctx) {
  const char* start = ctx.p++;
  while (isIdentChar(*ctx.p)) {
    ++ctx.p;
  }
  return toLower(std::string(start, static_cast<std::size_t>(ctx.p - start)));
}

bool MathParser::tryConsumeCommaArgSeparator(EvalContext& ctx, bool& hasComma) const {
  hasComma = false;
  if (*ctx.p != ',') {
    return true;
  }
  hasComma = true;
  ++ctx.p;
  skipSpaces(ctx);
  if (*ctx.p == ')' || *ctx.p == ',') {
    setUnexpectedCommaError(ctx);
    return false;
  }
  return true;
}

void MathParser::skipSpaces(EvalContext& ctx) {
  while (*ctx.p && std::isspace(static_cast<unsigned char>(*ctx.p))) {
    ++ctx.p;
  }
}

void MathParser::setUnexpectedTokenError(EvalContext& ctx) const {
  setError(ctx, STR_UNEXPECTED_TOKEN);
}

void MathParser::setUnexpectedInputError(EvalContext& ctx) const {
  setError(ctx, STR_UNEXPECTED_INPUT);
}

void MathParser::setMissingClosingParenLikeError(EvalContext& ctx) const {
  if (isIdentStart(*ctx.p) || isNumericLiteralStart(*ctx.p)) {
    setUnexpectedTokenError(ctx);
  } else {
    setMissingClosingParenthesisError(ctx);
  }
}

bool MathParser::consumeKeyword(EvalContext& ctx, const char* kw) {
  skipSpaces(ctx);
  std::size_t n = 0;
  while (kw[n] != '\0') {
    const unsigned char a = static_cast<unsigned char>(ctx.p[n]);
    const unsigned char b = static_cast<unsigned char>(kw[n]);
    if (a == '\0' || std::tolower(a) != std::tolower(b)) return false;
    ++n;
  }
  if (isIdentChar(ctx.p[n])) return false;
  ctx.p += n;
  return true;
}

static bool isPercentPostfixContext(const char* p) {
  if (*p != '%') {
    return false;
  }
  const char* q = p + 1;
  while (*q && std::isspace(static_cast<unsigned char>(*q))) {
    ++q;
  }
  if (*q == '\0') return true;
  if (*q == ')' || *q == ',' || *q == ';') return true;
  if (*q == '+' || *q == '-' || *q == '*' || *q == '/' || *q == '^') return true;
  if (*q == '<' || *q == '>' || *q == '=' || *q == '!') return true;
  if (*q == '&' || *q == '|') return true;
  return false;
}

bool MathParser::tryConsumeLogicalBinaryOperator(EvalContext& ctx, OperatorNameId keywordId, char symbol) const {
  skipSpaces(ctx);
  if (ctx.p[0] == symbol && ctx.p[1] == symbol) {
    ctx.p += 2;
    return true;
  }
  return consumeKeyword(ctx, opName(keywordId).c_str());
}

bool MathParser::parseParenthesizedExprList(
    EvalContext& ctx,
    std::vector<std::unique_ptr<Expr>>& outValues) {
  skipSpaces(ctx);
  if (*ctx.p == ')') {
    return true;
  }
  while (true) {
    outValues.emplace_back(parseExpression(ctx));
    if (ctx.parseError) {
      return false;
    }
    skipSpaces(ctx);
    bool hasComma = false;
    if (!tryConsumeCommaArgSeparator(ctx, hasComma)) {
      return false;
    }
    if (!hasComma) {
      return true;
    }
  }
}

std::unique_ptr<MathParser::Expr> MathParser::makeBinaryExpr(
    std::unique_ptr<Expr> left,
    std::unique_ptr<Expr> right,
    Expr::BinaryOp op,
    bool setPercentFlag) {
  auto out = std::make_unique<Expr>();
  out->tag = Expr::Tag::Binary;
  out->binaryOp = op;
  out->left = std::move(left);
  out->right = std::move(right);
  if (setPercentFlag) {
    out->rhsIsDirectPostfixPercent = exprIsDirectPostfixPercent(*out->right);
  }
  return out;
}

std::unique_ptr<MathParser::Expr> MathParser::parseLeftAssocBinary(
    EvalContext& ctx,
    std::unique_ptr<Expr> (MathParser::*parseOperand)(EvalContext&),
    bool (MathParser::*tryConsumeOp)(EvalContext&, Expr::BinaryOp&),
    bool setPercentFlag) {
  auto left = (this->*parseOperand)(ctx);
  if (ctx.parseError || !left) {
    return nullptr;
  }
  while (true) {
    Expr::BinaryOp op = Expr::BinaryOp::None;
    if (!(this->*tryConsumeOp)(ctx, op)) {
      break;
    }
    auto right = (this->*parseOperand)(ctx);
    if (ctx.parseError || !right) {
      return nullptr;
    }
    left = makeBinaryExpr(std::move(left), std::move(right), op, setPercentFlag);
  }
  return left;
}

bool MathParser::tryConsumeBitAndOp(EvalContext& ctx, Expr::BinaryOp& outOp) {
  skipSpaces(ctx);
  if (*ctx.p != '&' || ctx.p[1] == '&') {
    return false;
  }
  ++ctx.p;
  outOp = Expr::BinaryOp::BitAnd;
  return true;
}

bool MathParser::tryConsumeBitXorOp(EvalContext& ctx, Expr::BinaryOp& outOp) {
  skipSpaces(ctx);
  if (*ctx.p != '^') {
    return false;
  }
  ++ctx.p;
  outOp = Expr::BinaryOp::BitXor;
  return true;
}

bool MathParser::tryConsumeBitOrOp(EvalContext& ctx, Expr::BinaryOp& outOp) {
  skipSpaces(ctx);
  if (*ctx.p != '|' || ctx.p[1] == '|') {
    return false;
  }
  ++ctx.p;
  outOp = Expr::BinaryOp::BitOr;
  return true;
}

bool MathParser::tryConsumeShiftOp(EvalContext& ctx, Expr::BinaryOp& outOp) {
  skipSpaces(ctx);
  if (ctx.p[0] == '<' && ctx.p[1] == '<') {
    ctx.p += 2;
    outOp = Expr::BinaryOp::ShiftLeft;
    return true;
  }
  if (ctx.p[0] == '>' && ctx.p[1] == '>') {
    ctx.p += 2;
    outOp = Expr::BinaryOp::ShiftRight;
    return true;
  }
  return false;
}

bool MathParser::tryConsumeAddSubOp(EvalContext& ctx, Expr::BinaryOp& outOp) {
  skipSpaces(ctx);
  if (*ctx.p == '+') {
    ++ctx.p;
    outOp = Expr::BinaryOp::Add;
    return true;
  }
  if (*ctx.p == '-') {
    ++ctx.p;
    outOp = Expr::BinaryOp::Sub;
    return true;
  }
  return false;
}

bool MathParser::tryConsumeMulDivModOp(EvalContext& ctx, Expr::BinaryOp& outOp) {
  skipSpaces(ctx);
  if (*ctx.p == '*') {
    ++ctx.p;
    outOp = Expr::BinaryOp::Mul;
    return true;
  }
  if (*ctx.p == '/') {
    ++ctx.p;
    outOp = Expr::BinaryOp::Div;
    return true;
  }
  if (*ctx.p == '%') {
    ++ctx.p;
    outOp = Expr::BinaryOp::Modulo;
    return true;
  }
  if (*ctx.p == '(') {
    outOp = Expr::BinaryOp::Mul;
    return true;
  }
  return false;
}

bool MathParser::tryConsumeCompareOp(EvalContext& ctx, Expr::BinaryOp& outOp) {
  skipSpaces(ctx);
  if (std::strncmp(ctx.p, STR_LT_EQ, 2) == 0) {
    ctx.p += 2;
    outOp = Expr::BinaryOp::CmpLe;
    return true;
  }
  if (std::strncmp(ctx.p, STR_GT_EQ, 2) == 0) {
    ctx.p += 2;
    outOp = Expr::BinaryOp::CmpGe;
    return true;
  }
  if (std::strncmp(ctx.p, STR_EQ_EQ, 2) == 0) {
    ctx.p += 2;
    outOp = Expr::BinaryOp::CmpEq;
    return true;
  }
  if (std::strncmp(ctx.p, STR_NOT_EQ, 2) == 0 || std::strncmp(ctx.p, STR_LT_GT, 2) == 0) {
    ctx.p += 2;
    outOp = Expr::BinaryOp::CmpNe;
    return true;
  }
  if (*ctx.p == '=') {
    ++ctx.p;
    outOp = Expr::BinaryOp::CmpEq;
    return true;
  }
  if (*ctx.p == '<') {
    ++ctx.p;
    outOp = Expr::BinaryOp::CmpLt;
    return true;
  }
  if (*ctx.p == '>') {
    ++ctx.p;
    outOp = Expr::BinaryOp::CmpGt;
    return true;
  }
  return false;
}

bool MathParser::tryConsumeLogicalAndOp(EvalContext& ctx, Expr::BinaryOp& outOp) {
  if (!tryConsumeLogicalBinaryOperator(ctx, OperatorNameId::And, '&')) {
    return false;
  }
  outOp = Expr::BinaryOp::LogicalAnd;
  return true;
}

bool MathParser::tryConsumeLogicalOrOp(EvalContext& ctx, Expr::BinaryOp& outOp) {
  if (!tryConsumeLogicalBinaryOperator(ctx, OperatorNameId::Or, '|')) {
    return false;
  }
  outOp = Expr::BinaryOp::LogicalOr;
  return true;
}

bool MathParser::isTruthy(const EvalValue& v) {
  if (v.kind == ValueKind::Array) {
    return !v.arr.empty();
  }
  const double s = v.scalarValue.scalar;
  if (std::isnan(s)) {
    return false;
  }
  return std::fabs(s) > 0.0;
}

std::string MathParser::trim(const std::string& s) {
  std::size_t l = 0;
  while (l < s.size() && std::isspace(static_cast<unsigned char>(s[l]))) {
    ++l;
  }
  std::size_t r = s.size();
  while (r > l && std::isspace(static_cast<unsigned char>(s[r - 1]))) {
    --r;
  }
  return s.substr(l, r - l);
}

bool MathParser::nearlyInt(double v, long long& out) {
  if (!std::isfinite(v)) {
    return false;
  }
  if (std::fabs(v) > 9007199254740992.0) {
    return false;
  }
  const long double lv = static_cast<long double>(v);
  const long double r = std::round(lv);
  if (std::fabs(lv - r) > 1e-12L) {
    return false;
  }
  if (r < static_cast<long double>((std::numeric_limits<long long>::min)()) ||
      r > static_cast<long double>((std::numeric_limits<long long>::max)())) {
    return false;
  }
  out = static_cast<long long>(r);
  return true;
}

bool isWithinExactIntFromDoubleRange(double v) {
  return std::isfinite(v) && std::fabs(v) <= K_MAX_EXACT_INT_FROM_DOUBLE;
}

bool tryExtractExactInt64FromDoubleStrict(double v, long long& out) {
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

bool MathParser::tryGetExactSignedInt64FromScalar(const EvalValue::ScalarValue& s, long long& outI) {
  if (s.hasExactInt()) {
    outI = s.exactInt;
    return true;
  }
  if (s.hasExactUInt64()) {
    static_assert(sizeof(long long) == sizeof(std::uint64_t), "int64/uint64 size mismatch");
    std::uint64_t bits = s.exactUInt64;
    std::memcpy(&outI, &bits, sizeof(bits));
    return true;
  }
  return false;
}

bool MathParser::tryGetExactSignedInt64NoUIntWrapFromScalar(const EvalValue::ScalarValue& s, long long& outI) {
  if (s.hasExactInt()) {
    outI = s.exactInt;
    return true;
  }
  if (s.hasExactUInt64() &&
      s.exactUInt64 <= static_cast<std::uint64_t>((std::numeric_limits<long long>::max)())) {
    outI = static_cast<long long>(s.exactUInt64);
    return true;
  }
  return false;
}

bool MathParser::tryGetExactNonNegativeUInt64FromScalar(const EvalValue::ScalarValue& s, std::uint64_t& outU) {
  if (s.hasExactUInt64()) {
    outU = s.exactUInt64;
    return true;
  }
  if (s.hasExactInt() && s.exactInt >= 0) {
    outU = static_cast<std::uint64_t>(s.exactInt);
    return true;
  }
  return false;
}

bool MathParser::tryGetBothExactSignedInt64NoUIntWrapFromScalars(
    const EvalValue::ScalarValue& a,
    const EvalValue::ScalarValue& b,
    long long& outA,
    long long& outB) {
  return tryGetExactSignedInt64NoUIntWrapFromScalar(a, outA) &&
         tryGetExactSignedInt64NoUIntWrapFromScalar(b, outB);
}

bool MathParser::tryGetBothExactNonNegativeUInt64FromScalars(
    const EvalValue::ScalarValue& a,
    const EvalValue::ScalarValue& b,
    std::uint64_t& outA,
    std::uint64_t& outB) {
  return tryGetExactNonNegativeUInt64FromScalar(a, outA) &&
         tryGetExactNonNegativeUInt64FromScalar(b, outB);
}

bool MathParser::tryShiftLeftU64ExactOrMaybe(
    std::uint64_t aU,
    std::uint64_t bU,
    EvalValue& outV) {
  if (bU > 63u) return false;
  if (bU > 0u && aU > ((std::numeric_limits<std::uint64_t>::max)() >> bU)) {
    outV = makeScalarMaybeExact(std::ldexp(static_cast<double>(aU), static_cast<int>(bU)));
    return true;
  }
  outV = makeScalarUInt(aU << bU);
  return true;
}

bool MathParser::tryGetSignedInt64FromScalar(const EvalValue::ScalarValue& s, long long& outI) {
  if (tryGetExactSignedInt64FromScalar(s, outI)) {
    return true;
  }
  return tryExtractExactInt64FromDoubleStrict(s.scalar, outI);
}

bool MathParser::isPureFloatingScalarPair(const EvalValue::ScalarValue& a, const EvalValue::ScalarValue& b) {
  return (a.scalarKind == ScalarKind::FloatingPoint) && (b.scalarKind == ScalarKind::FloatingPoint) &&
      !a.hasExactInt() && !a.hasExactUInt64() && !b.hasExactInt() && !b.hasExactUInt64();
}

bool MathParser::parseUInt64FromDouble(double v, std::uint64_t& out) {
  if (!isWithinExactIntFromDoubleRange(v) || v < 0.0) {
    return false;
  }
  if (v > static_cast<double>(std::numeric_limits<std::uint64_t>::max())) {
    return false;
  }
  const std::uint64_t u = static_cast<std::uint64_t>(v);
  if (v != static_cast<double>(u)) {
    return false;
  }
  out = u;
  return true;
}

std::string MathParser::formatScalar(const EvalValue& v, RenderBase base) {
  const int baseCode = static_cast<int>(base);
  const double dval = v.scalarValue.scalar;
  if (base == RenderBase::Dec) {
    if (v.scalarValue.hasExactInt()) {
      return std::to_string(v.scalarValue.exactInt);
    }
    if (v.scalarValue.hasExactUInt64()) {
      return std::to_string(v.scalarValue.exactUInt64);
    }
    const double p63 = std::ldexp(1.0, 63);
    if (v.scalarValue.hasDecScientificPow63High()) {
      if (dval == p63) {
        return STR_POS_POW63_DEC_TEXT;
      }
      if (dval == -p63) {
        return STR_NEG_POW63_DEC_TEXT;
      }
    }
    long long iv = 0;
    if (nearlyInt(dval, iv)) {
      return std::to_string(iv);
    }
    return formatDoubleFast(dval);
  }

  std::uint64_t u = 0;
  if (v.scalarValue.hasExactUInt64()) {
    u = v.scalarValue.exactUInt64;
  } else if (v.scalarValue.hasExactInt() && v.scalarValue.exactInt >= 0) {
    u = static_cast<std::uint64_t>(v.scalarValue.exactInt);
  } else if (v.scalarValue.hasExactInt() && v.scalarValue.exactInt < 0) {
    const long long iv = v.scalarValue.exactInt;
    return formatSignedMagnitudeForRenderBase(iv, baseCode, v.hasRenderUnsigned());
  } else if (!parseUInt64FromDouble(dval, u)) {
    return formatScalar(v, RenderBase::Dec);
  }

  return formatUnsignedForRenderBase(u, baseCode);
}

std::string MathParser::valueToString(const EvalValue& v, RenderBase forcedBase) {
  if (v.kind == ValueKind::Scalar) {
    return formatScalar(v, forcedBase);
  }
  std::string out = "(";
  for (std::size_t i = 0; i < v.arr.size(); ++i) {
    if (i) out += ",";
    EvalValue e = makeScalar(v.arr[i].scalar);
    e.scalarValue.scalarKind = v.arr[i].scalarKind;
    e.scalarValue.setExactIntValid(v.arr[i].hasExactInt());
    e.scalarValue.exactInt = v.arr[i].exactInt;
    e.scalarValue.setExactUInt64Valid(v.arr[i].hasExactUInt64());
    e.scalarValue.exactUInt64 = v.arr[i].exactUInt64;
    e.scalarValue.setDecScientificPow63High(v.arr[i].hasDecScientificPow63High());
    e.setRenderUnsigned(v.hasRenderUnsigned());
    out += formatScalar(e, forcedBase);
  }
  out += ")";
  return out;
}

std::string MathParser::valueToString(const EvalValue& v) {
  return valueToString(v, v.getRenderBase());
}

std::string MathParser::getError() const {
  return lastError_;
}

std::string MathParser::getResult() const {
  if (!lastError_.empty() || !hasResult_) {
    return "";
  }
  return valueToString(lastResult_);
}

std::string MathParser::getResultAsHex() const {
  if (!lastError_.empty() || !hasResult_) {
    return "";
  }
  return valueToString(lastResult_, RenderBase::Hex);
}

std::string MathParser::getResultAsDec() const {
  if (!lastError_.empty() || !hasResult_) {
    return "";
  }
  return valueToString(lastResult_, RenderBase::Dec);
}

std::string MathParser::getResultAsOct() const {
  if (!lastError_.empty() || !hasResult_) {
    return "";
  }
  return valueToString(lastResult_, RenderBase::Oct);
}

std::string MathParser::getResultAsBin() const {
  if (!lastError_.empty() || !hasResult_) {
    return "";
  }
  return valueToString(lastResult_, RenderBase::Bin);
}

MathParser::RawResult MathParser::getRawResult() const {
  if (!lastError_.empty() || !hasResult_) {
    return RawResult{};
  }
  return toRawResult(lastResult_);
}

void MathParser::addConst(const std::string& constName, long long intValue) {
  EvalValue v = makeScalarInt(intValue);
  setVariable(toLower(constName), v);
}

void MathParser::addConst(const std::string& constName, double dblValue) {
  EvalValue v = makeScalar(dblValue);
  setVariable(toLower(constName), v);
}

MathParser::EvalValue MathParser::makeScalar(double v) {
  EvalValue out;
  out.kind = ValueKind::Scalar;
  out.scalarValue.scalarKind = ScalarKind::FloatingPoint;
  out.scalarValue.scalar = v;
  out.scalarValue.setExactIntValid(false);
  out.scalarValue.exactInt = 0;
  out.scalarValue.setExactUInt64Valid(false);
  out.scalarValue.exactUInt64 = 0;
  out.scalarValue.setDecScientificPow63High(false);
  return out;
}

MathParser::EvalValue MathParser::makeScalarMaybeExact(double v) {
  EvalValue out = makeScalar(v);
  long long asInt = 0;
  if (tryExtractExactInt64FromDoubleStrict(v, asInt)) {
    out.scalarValue.scalarKind = ScalarKind::Int64;
    out.scalarValue.setExactIntValid(true);
    out.scalarValue.exactInt = asInt;
    if (asInt >= 0) {
      out.scalarValue.setExactUInt64Valid(true);
      out.scalarValue.exactUInt64 = static_cast<std::uint64_t>(asInt);
    }
  }
  return out;
}

MathParser::EvalValue MathParser::makeScalarInt(long long v) {
  EvalValue out;
  out.kind = ValueKind::Scalar;
  out.scalarValue.scalarKind = ScalarKind::Int64;
  out.scalarValue.scalar = static_cast<double>(v);
  out.scalarValue.setExactIntValid(true);
  out.scalarValue.exactInt = v;
  out.scalarValue.setExactUInt64Valid(v >= 0);
  out.scalarValue.exactUInt64 = (v >= 0) ? static_cast<std::uint64_t>(v) : 0;
  out.scalarValue.setDecScientificPow63High(false);
  return out;
}

MathParser::EvalValue MathParser::makeScalarUInt(std::uint64_t v) {
  EvalValue out;
  out.kind = ValueKind::Scalar;
  out.scalarValue.scalarKind = ScalarKind::UInt64;
  out.scalarValue.scalar = static_cast<double>(v);
  out.scalarValue.setExactUInt64Valid(true);
  out.scalarValue.exactUInt64 = v;
  if (v <= static_cast<std::uint64_t>((std::numeric_limits<long long>::max)())) {
    out.scalarValue.setExactIntValid(true);
    out.scalarValue.exactInt = static_cast<long long>(v);
  } else {
    out.scalarValue.setExactIntValid(false);
    out.scalarValue.exactInt = 0;
  }
  out.scalarValue.setDecScientificPow63High(false);
  return out;
}

MathParser::EvalValue MathParser::makeArray(const std::vector<double>& v) {
  EvalValue out;
  out.kind = ValueKind::Array;
  out.scalarValue.scalarKind = ScalarKind::FloatingPoint;
  out.arr.resize(v.size());
  for (std::size_t i = 0; i < v.size(); ++i) {
    out.arr[i].scalarKind = ScalarKind::FloatingPoint;
    out.arr[i].scalar = v[i];
  }
  return out;
}

MathParser::EvalValue MathParser::makeArrayFromScalars(const std::vector<EvalValue>& v) {
  EvalValue out;
  out.kind = ValueKind::Array;
  out.scalarValue.scalarKind = ScalarKind::FloatingPoint;
  out.arr.resize(v.size());
  for (std::size_t i = 0; i < v.size(); ++i) {
    out.arr[i].scalarKind = v[i].scalarValue.scalarKind;
    out.arr[i].scalar = v[i].scalarValue.scalar;
    out.arr[i].setExactIntValid(v[i].scalarValue.hasExactInt());
    out.arr[i].exactInt = v[i].scalarValue.exactInt;
    out.arr[i].setExactUInt64Valid(v[i].scalarValue.hasExactUInt64());
    out.arr[i].exactUInt64 = v[i].scalarValue.exactUInt64;
    out.arr[i].setDecScientificPow63High(v[i].scalarValue.hasDecScientificPow63High());
  }
  return out;
}

MathParser::RawResult::Scalar MathParser::toRawScalar(const EvalValue::ScalarValue& v) {
  RawResult::Scalar out;
  if (v.scalarKind == ScalarKind::Int64) {
    out.kind = RawResult::ScalarKind::Int64;
    out.intValue = v.exactInt;
    return out;
  }
  if (v.scalarKind == ScalarKind::UInt64) {
    out.kind = RawResult::ScalarKind::UInt64;
    out.uintValue = v.exactUInt64;
    return out;
  }
  out.kind = RawResult::ScalarKind::FloatingPoint;
  out.floatingPoint = v.scalar;
  return out;
}

MathParser::RawResult MathParser::toRawResult(const EvalValue& v) {
  RawResult out;
  if (v.kind == ValueKind::Scalar) {
    out.kind = RawResult::Kind::Scalar;
    out.scalar = toRawScalar(v.scalarValue);
    return out;
  }

  out.kind = RawResult::Kind::Array;
  out.array.reserve(v.arr.size());
  for (std::size_t i = 0; i < v.arr.size(); ++i) {
    out.array.push_back(toRawScalar(v.arr[i]));
  }
  return out;
}

MathParser::EvalValue MathParser::scalarFromScalarValue(const EvalValue::ScalarValue& sv) {
  EvalValue out = makeScalar(sv.scalar);
  out.scalarValue.scalarKind = sv.scalarKind;
  out.scalarValue.setExactIntValid(sv.hasExactInt());
  out.scalarValue.exactInt = sv.exactInt;
  out.scalarValue.setExactUInt64Valid(sv.hasExactUInt64());
  out.scalarValue.exactUInt64 = sv.exactUInt64;
  out.scalarValue.setDecScientificPow63High(sv.hasDecScientificPow63High());
  return out;
}

MathParser::EvalValue MathParser::scalarFromArrayAt(const EvalValue& arrV, std::size_t idx) {
  return scalarFromScalarValue(arrV.arr[idx]);
}

void MathParser::setError(EvalContext& ctx, const std::string& msg) const {
  if (!ctx.parseError) {
    ctx.parseError = true;
    ctx.errorText = msg;
  }
}

bool MathParser::flattenArgs(const std::vector<EvalValue>& args, std::vector<double>& out) {
  out.clear();
  const std::size_t totalCount = countFlattenedScalars(args);
  out.reserve(totalCount);
  for (const auto& a : args) {
    if (a.kind == ValueKind::Scalar) {
      out.emplace_back(a.scalarValue.scalar);
    } else {
      for (const auto& item : a.arr) {
        out.emplace_back(item.scalar);
      }
    }
  }
  return !out.empty();
}

bool MathParser::flattenArgsToScalars(const std::vector<EvalValue>& args, std::vector<EvalValue>& out) {
  out.clear();
  const std::size_t totalCount = countFlattenedScalars(args);
  out.reserve(totalCount);
  for (const auto& a : args) {
    if (a.kind == ValueKind::Scalar) {
      out.emplace_back(a);
    } else {
      for (const auto& item : a.arr) {
        out.emplace_back(scalarFromScalarValue(item));
      }
    }
  }
  return !out.empty();
}

std::size_t MathParser::countFlattenedScalars(const std::vector<EvalValue>& args) {
  std::size_t totalCount = 0;
  for (const auto& a : args) {
    totalCount += (a.kind == ValueKind::Scalar) ? 1U : a.arr.size();
  }
  return totalCount;
}

int MathParser::expandUnpackedArgs(const std::vector<EvalValue>& in, std::vector<EvalValue>& out) {
  out.clear();
  std::size_t reserveCount = 0;
  bool hasExpandMarkers = false;
  for (const auto& arg : in) {
    if (arg.hasExpandArgs()) hasExpandMarkers = true;
    if (arg.hasExpandArgs() && arg.kind == ValueKind::Array) reserveCount += arg.arr.size();
    else reserveCount += 1;
  }
  if (!hasExpandMarkers) {
    return 0;
  }
  out.reserve(reserveCount);

  for (const auto& arg : in) {
    if (!arg.hasExpandArgs()) {
      out.emplace_back(arg);
      continue;
    }
    if (arg.kind == ValueKind::Array) {
      for (const auto& item : arg.arr) {
        out.emplace_back(scalarFromScalarValue(item));
      }
    } else {
      EvalValue copy = arg;
      copy.setExpandArgs(false);
      out.emplace_back(std::move(copy));
    }
  }
  return static_cast<int>(out.size());
}

void MathParser::setVariable(const std::string& name, const EvalValue& value) {
  auto it = variables_.find(name);
  if (it != variables_.end()) {
    it->second = value;
    return;
  }
  variables_.emplace(name, value);
  ++variablesVersion_;
}

void MathParser::normalizeCallArgs(std::vector<EvalValue>& args) {
  scratchExpandedArgs_.clear();
  if (expandUnpackedArgs(args, scratchExpandedArgs_) > 0) {
    args.swap(scratchExpandedArgs_);
    scratchExpandedArgs_.clear();
  }
}

bool MathParser::applyBinary(double a, double b, char op, double& out) {
  switch (op) {
    case '+': out = a + b; return true;
    case '-': out = a - b; return true;
    case '*': out = a * b; return true;
    case '/':
      if (std::fabs(b) < 1e-15) {
        return false;
      }
      out = a / b;
      return true;
    case '^': out = std::pow(a, b); return true;
    default: break;
  }
  return false;
}

MathParser::EvalValue MathParser::mapUnaryFn(const EvalValue& in, double (*fn)(double)) {
  if (in.kind == ValueKind::Scalar) {
    return makeScalarMaybeExact(fn(in.scalarValue.scalar));
  }
  std::vector<EvalValue> outVals;
  outVals.reserve(in.arr.size());
  for (const auto& e : in.arr) {
    outVals.emplace_back(makeScalarMaybeExact(fn(e.scalar)));
  }
  return makeArrayFromScalars(outVals);
}

MathParser::EvalValue MathParser::negateEvalValue(const EvalValue& v) {
  if (v.kind == ValueKind::Array) {
    std::vector<EvalValue> elems;
    elems.reserve(v.arr.size());
    for (std::size_t i = 0; i < v.arr.size(); ++i) {
      EvalValue elem = scalarFromArrayAt(v, i);
      elems.emplace_back(negateEvalValue(elem));
    }
    return makeArrayFromScalars(elems);
  }
  if (v.scalarValue.hasDecScientificPow63High()) {
    const double p63 = std::ldexp(1.0, 63);
    if (v.scalarValue.scalar == p63) {
      return makeScalarInt((std::numeric_limits<long long>::min)());
    }
    if (v.scalarValue.scalar == -p63) {
      return makeScalarUInt(1ull << 63);
    }
  }
  if (v.scalarValue.hasExactInt()) {
    const long long x = v.scalarValue.exactInt;
    if (x == (std::numeric_limits<long long>::min)()) {
      return makeScalarUInt(1ull << 63);
    }
    return makeScalarInt(-x);
  }
  if (v.scalarValue.hasExactUInt64()) {
    const std::uint64_t u = v.scalarValue.exactUInt64;
    if (u == 0) {
      return makeScalarInt(0);
    }
    if (u == (1ull << 63)) {
      return makeScalarInt((std::numeric_limits<long long>::min)());
    }
    if (u <= static_cast<std::uint64_t>((std::numeric_limits<long long>::max)())) {
      return makeScalarInt(-static_cast<long long>(u));
    }
    return makeScalar(-static_cast<double>(u));
  }
  return makeScalar(-v.scalarValue.scalar);
}

template <typename ScalarFn>
MathParser::EvalValue MathParser::mapBinaryBroadcast(
    const EvalValue& left,
    const EvalValue& right,
    ScalarFn&& scalarFn,
    bool& ok) const {
  if (left.kind == ValueKind::Scalar && right.kind == ValueKind::Scalar) {
    EvalValue outS;
    ok = scalarFn(left.scalarValue, right.scalarValue, outS);
    return ok ? outS : makeScalar(0);
  }
  if (left.kind == ValueKind::Array && right.kind == ValueKind::Array) {
    if (left.arr.size() != right.arr.size()) {
      ok = false;
      return makeScalar(0);
    }
    scratchBinaryOut_.clear();
    scratchBinaryOut_.reserve(left.arr.size());
    for (std::size_t i = 0; i < left.arr.size(); ++i) {
      EvalValue outS;
      if (!scalarFn(left.arr[i], right.arr[i], outS)) {
        ok = false;
        scratchBinaryOut_.clear();
        return makeScalar(0);
      }
      scratchBinaryOut_.emplace_back(std::move(outS));
    }
    EvalValue ret = makeArrayFromScalars(scratchBinaryOut_);
    scratchBinaryOut_.clear();
    return ret;
  }
  if (left.kind == ValueKind::Array) {
    scratchBinaryOut_.clear();
    scratchBinaryOut_.reserve(left.arr.size());
    for (std::size_t i = 0; i < left.arr.size(); ++i) {
      EvalValue outS;
      if (!scalarFn(left.arr[i], right.scalarValue, outS)) {
        ok = false;
        scratchBinaryOut_.clear();
        return makeScalar(0);
      }
      scratchBinaryOut_.emplace_back(std::move(outS));
    }
    EvalValue ret = makeArrayFromScalars(scratchBinaryOut_);
    scratchBinaryOut_.clear();
    return ret;
  }
  scratchBinaryOut_.clear();
  scratchBinaryOut_.reserve(right.arr.size());
  for (std::size_t i = 0; i < right.arr.size(); ++i) {
    EvalValue outS;
    if (!scalarFn(left.scalarValue, right.arr[i], outS)) {
      ok = false;
      scratchBinaryOut_.clear();
      return makeScalar(0);
    }
    scratchBinaryOut_.emplace_back(std::move(outS));
  }
  EvalValue ret = makeArrayFromScalars(scratchBinaryOut_);
  scratchBinaryOut_.clear();
  return ret;
}

MathParser::EvalValue MathParser::mapBinary(const EvalValue& a, const EvalValue& b, char op, bool& ok) const {
  ok = true;
  auto makePow63 = [&]() -> EvalValue {
    EvalValue ov = makeScalar(std::ldexp(1.0, 63));
    ov.scalarValue.setDecScientificPow63High(true);
    return ov;
  };
  auto makeNegPow63 = [&]() -> EvalValue {
    EvalValue u = makeScalar(-std::ldexp(1.0, 63));
    u.scalarValue.setDecScientificPow63High(true);
    return u;
  };
  auto tryCombineScalarValues = [&](const EvalValue::ScalarValue& lv, const EvalValue::ScalarValue& rv, EvalValue& outS)
      -> bool {
    if (isPureFloatingScalarPair(lv, rv)) {
      double outD = 0.0;
      if (!applyBinary(lv.scalar, rv.scalar, op, outD)) {
        return false;
      }
      outS = makeScalarMaybeExact(outD);
      return true;
    }

    if (lv.hasExactUInt64() && rv.hasExactUInt64() && (!lv.hasExactInt() || !rv.hasExactInt())) {
      if (op == '+') {
        std::uint64_t outU = 0;
        if (tryAddUInt64Checked(lv.exactUInt64, rv.exactUInt64, outU)) {
          outS = makeScalarUInt(outU);
          return true;
        }
      } else if (op == '-') {
        if (lv.exactUInt64 >= rv.exactUInt64) {
          outS = makeScalarUInt(lv.exactUInt64 - rv.exactUInt64);
          return true;
        }
      } else if (op == '*') {
        std::uint64_t outU = 0;
        if (tryMulUInt64Checked(lv.exactUInt64, rv.exactUInt64, outU)) {
          outS = makeScalarUInt(outU);
          return true;
        }
      }
    }

    long long li = 0;
    long long ri = 0;
    const bool leftExactInt64 = tryGetExactSignedInt64NoUIntWrapFromScalar(lv, li);
    const bool rightExactInt64 = tryGetExactSignedInt64NoUIntWrapFromScalar(rv, ri);
    std::uint64_t lu = 0;
    std::uint64_t ru = 0;
    if (op == '^' && tryGetBothExactNonNegativeUInt64FromScalars(lv, rv, lu, ru)) {
      std::uint64_t outU = 0;
      if (tryPowUInt64Checked(lu, ru, outU)) {
        outS = makeScalarUInt(outU);
        return true;
      }
    }
    if (op == '^' && leftExactInt64 && li < 0 && tryGetExactNonNegativeUInt64FromScalar(rv, ru)) {
      const std::uint64_t baseMag = (li == (std::numeric_limits<long long>::min)())
        ? (1ull << 63)
        : static_cast<std::uint64_t>(-li);
      std::uint64_t powMag = 0;
      if (tryPowUInt64Checked(baseMag, ru, powMag)) {
        if ((ru & 1u) == 0u) {
          outS = makeScalarUInt(powMag);
          return true;
        }
        if (powMag <= (1ull << 63)) {
          outS = (powMag == (1ull << 63))
            ? makeScalarInt((std::numeric_limits<long long>::min)())
            : makeScalarInt(-static_cast<long long>(powMag));
          return true;
        }
      }
    }
    if (leftExactInt64 && rightExactInt64) {
      if (op == '-' && li == (std::numeric_limits<long long>::min)() && ri == 1LL) {
        outS = makeNegPow63();
        return true;
      }
      long long outI = 0;
      if (op == '+' && checkedAddLL(li, ri, outI)) {
        outS = makeScalarInt(outI);
        return true;
      }
      if (op == '-' && checkedSubLL(li, ri, outI)) {
        outS = makeScalarInt(outI);
        return true;
      }
      if (op == '*' && checkedMulLL(li, ri, outI)) {
        outS = makeScalarInt(outI);
        return true;
      }
      if (li >= 0 && ri >= 0) {
        const std::uint64_t lu = static_cast<std::uint64_t>(li);
        const std::uint64_t ru = static_cast<std::uint64_t>(ri);
        if (op == '+') {
          std::uint64_t outU = 0;
          if (tryAddUInt64Checked(lu, ru, outU)) {
            outS = makeScalarUInt(outU);
            return true;
          }
        } else if (op == '*') {
          std::uint64_t outU = 0;
          if (tryMulUInt64Checked(lu, ru, outU)) {
            outS = makeScalarUInt(outU);
            return true;
          }
        }
      }
    }

    lu = 0;
    ru = 0;
    if (tryGetBothExactNonNegativeUInt64FromScalars(lv, rv, lu, ru)) {
      if (op == '+') {
        std::uint64_t outU = 0;
        if (tryAddUInt64Checked(lu, ru, outU)) {
          outS = makeScalarUInt(outU);
          return true;
        }
      } else if (op == '*') {
        std::uint64_t outU = 0;
        if (tryMulUInt64Checked(lu, ru, outU)) {
          outS = makeScalarUInt(outU);
          return true;
        }
      }
    }
    if (op == '+' && lv.hasExactInt() && lv.exactInt == (std::numeric_limits<long long>::max)() && !rv.hasExactInt() &&
        !rv.hasExactUInt64() && std::fabs(rv.scalar - 0.5) < 1e-12) {
      outS = makePow63();
      return true;
    }
    if (op == '+' && rv.hasExactInt() && rv.exactInt == (std::numeric_limits<long long>::max)() && !lv.hasExactInt() &&
        !lv.hasExactUInt64() && std::fabs(lv.scalar - 0.5) < 1e-12) {
      outS = makePow63();
      return true;
    }
    double outD = 0;
    if (!applyBinary(lv.scalar, rv.scalar, op, outD)) {
      return false;
    }
    outS = makeScalarMaybeExact(outD);
    return true;
  };

  return mapBinaryBroadcast(a, b, tryCombineScalarValues, ok);
}

MathParser::EvalValue MathParser::mapBinaryBuiltinMathFunction(
    const EvalValue& left,
    const EvalValue& right,
    BuiltinFunctionId id,
    bool& ok) const {
  ok = true;
  const bool isLog = (id == BuiltinFunctionId::Log);
  double (*binaryFn)(double, double) = nullptr;
  if (!isLog) {
    if (id == BuiltinFunctionId::Atan2) {
      binaryFn = std::atan2;
    } else if (id == BuiltinFunctionId::Hypot) {
      binaryFn = [](double l, double r) {
        return std::sqrt((l * l) + (r * r));
      };
    } else {
      ok = false;
      return makeScalar(0);
    }
  }

  auto applyScalarValue = [&](const EvalValue::ScalarValue& l, const EvalValue::ScalarValue& r, EvalValue& outS) -> bool {
    double outD = 0.0;
    if (isLog) {
      if (l.scalar <= 0.0 || r.scalar <= 0.0 || r.scalar == 1.0) {
        return false;
      }
      outD = std::log(l.scalar) / std::log(r.scalar);
    } else {
      outD = binaryFn(l.scalar, r.scalar);
    }
    outS = makeScalarMaybeExact(outD);
    return true;
  };

  return mapBinaryBroadcast(left, right, applyScalarValue, ok);
}

bool MathParser::parseFunctionDefinition(
    EvalContext& ctx,
    std::string& outName,
    std::vector<std::string>& outParams,
    std::string& outExpr) const {
  const char* save = ctx.p;
  skipSpaces(ctx);

  if (!isIdentStart(*ctx.p)) {
    ctx.p = save;
    return false;
  }
  std::string fnName = consumeLowerIdentToken(ctx);
  skipSpaces(ctx);
  if (*ctx.p != '(') {
    ctx.p = save;
    return false;
  }
  ++ctx.p;
  skipSpaces(ctx);

  std::vector<std::string> params;
  if (*ctx.p != ')') {
    while (true) {
      if (!isIdentStart(*ctx.p)) {
        ctx.p = save;
        return false;
      }
      params.emplace_back(consumeLowerIdentToken(ctx));
      skipSpaces(ctx);
      if (*ctx.p == ',') {
        ++ctx.p;
        skipSpaces(ctx);
        continue;
      }
      break;
    }
  }

  if (*ctx.p != ')') {
    ctx.p = save;
    return false;
  }
  ++ctx.p;
  skipSpaces(ctx);
  // UDF: name(params)=body — single '=' only; do not treat first '=' of '==' as UDF starter.
  if (*ctx.p != '=') {
    ctx.p = save;
    return false;
  }
  // Safe: *ctx.p is '=' here, so ctx.p[1] is at worst the terminating '\0' on a c_str() buffer.
  if (ctx.p[1] == '=') {
    ctx.p = save;
    return false;
  }
  ++ctx.p;
  skipSpaces(ctx);

  outName = fnName;
  outParams = std::move(params);
  const char* exprStart = ctx.p;
  while (*ctx.p && *ctx.p != ';') {
    ++ctx.p;
  }
  outExpr = trim(std::string(exprStart, static_cast<std::size_t>(ctx.p - exprStart)));
  if (outExpr.empty()) {
    ctx.p = save;
    return false;
  }
  return true;
}

std::unique_ptr<MathParser::Expr> MathParser::parsePrimary(EvalContext& ctx) {
  skipSpaces(ctx);
  if (*ctx.p == '(') {
    return parsePrimaryParenthesized(ctx);
  }
  if (isNumericLiteralStart(*ctx.p)) {
    return parsePrimaryNumericLiteral(ctx);
  }
  if (isIdentStart(*ctx.p)) {
    return parsePrimaryIdentifierOrCall(ctx);
  }
  setUnexpectedTokenError(ctx);
  return nullptr;
}

std::unique_ptr<MathParser::Expr> MathParser::parsePrimaryParenthesized(EvalContext& ctx) {
  ++ctx.p;
  skipSpaces(ctx);
  if (*ctx.p == ')') {
    setUnexpectedTokenError(ctx);
    return nullptr;
  }
  std::vector<std::unique_ptr<Expr>> values;
  if (!parseParenthesizedExprList(ctx, values) || values.empty()) {
    return nullptr;
  }
  if (*ctx.p != ')') {
    setMissingClosingParenLikeError(ctx);
    return nullptr;
  }
  ++ctx.p;
  if (values.size() == 1) {
    return std::move(values[0]);
  }
  auto arr = std::make_unique<Expr>();
  arr->tag = Expr::Tag::ArrayOrParens;
  arr->elements = std::move(values);
  return arr;
}

std::unique_ptr<MathParser::Expr> MathParser::parsePrimaryNumericLiteral(EvalContext& ctx) {
  const char* parsedEnd = nullptr;
  std::uint64_t parsedUInt = 0;
  if (ctx.p[0] == '0') {
    const char px = static_cast<char>(std::tolower(static_cast<unsigned char>(ctx.p[1])));
    unsigned int radix = 0U;
    if (px == 'x') {
      radix = 16U;
    } else if (px == 'b') {
      radix = 2U;
    } else if (px == 'o') {
      radix = 8U;
    }
    if (radix != 0U) {
      if (!tryParsePrefixedUIntLiteral(ctx.p, px, radix, parsedEnd, parsedUInt)) {
        setInvalidPrefixedLiteralError(ctx, px);
        return nullptr;
      }
      ctx.p = parsedEnd;
      auto lit = std::make_unique<Expr>();
      lit->tag = Expr::Tag::Literal;
      lit->literalValue = makeScalarUInt(parsedUInt);
      return lit;
    }
  }
  const char* numStart = ctx.p;
  char* end = nullptr;
  const double d = std::strtod(ctx.p, &end);
  if (end == ctx.p) {
    if (*ctx.p == '.') {
      setUnexpectedTokenError(ctx);
    } else {
      setInvalidNumericLiteralError(ctx);
    }
    return nullptr;
  }
  if ((*end == 'e' || *end == 'E')) {
    const char* pExp = end + 1;
    if (*pExp == '+' || *pExp == '-') {
      ++pExp;
    }
    if (!std::isdigit(static_cast<unsigned char>(*pExp))) {
      setUnexpectedTokenError(ctx);
      return nullptr;
    }
  }
  ctx.p = end;
  auto lit = std::make_unique<Expr>();
  lit->tag = Expr::Tag::Literal;
  lit->literalValue = makeScalar(d);

  if (tryParseInputNumberAsInteger(numStart, end, parsedUInt)) {
    lit->literalValue = (parsedUInt <= static_cast<std::uint64_t>((std::numeric_limits<long long>::max)()))
      ? makeScalarInt(static_cast<long long>(parsedUInt))
      : makeScalarUInt(parsedUInt);
  }
  return lit;
}

std::unique_ptr<MathParser::Expr> MathParser::parsePrimaryIdentifierOrCall(EvalContext& ctx) {
  std::string ident = consumeLowerIdentToken(ctx);
  skipSpaces(ctx);
  if (*ctx.p != '(') {
    auto v = std::make_unique<Expr>();
    v->tag = Expr::Tag::Variable;
    v->name = std::move(ident);
    return v;
  }
  ++ctx.p;
  std::vector<std::unique_ptr<Expr>> args;
  if (!parseParenthesizedExprList(ctx, args)) {
    return nullptr;
  }
  if (*ctx.p != ')') {
    setMissingClosingParenLikeError(ctx);
    return nullptr;
  }
  ++ctx.p;
  auto call = std::make_unique<Expr>();
  call->tag = Expr::Tag::Call;
  call->name = std::move(ident);
  BuiltinFunctionId id = BuiltinFunctionId::Count;
  if (tryGetBuiltinFunctionId(call->name, id)) {
    call->builtinFunctionId = id;
  }
  call->elements = std::move(args);
  return call;
}

std::unique_ptr<MathParser::Expr> MathParser::parseUnary(EvalContext& ctx) {
  skipSpaces(ctx);
  if (*ctx.p == '+') {
    ++ctx.p;
    return parseUnary(ctx);
  }
  if (*ctx.p == '-') {
    ++ctx.p;
    auto inner = parseUnary(ctx);
    if (hasExprParseFailure(ctx, inner)) {
      return nullptr;
    }
    auto u = std::make_unique<Expr>();
    u->tag = Expr::Tag::Unary;
    u->unaryOp = '-';
    u->child = std::move(inner);
    return u;
  }
  if (consumeKeyword(ctx, opName(OperatorNameId::Not).c_str())) {
    auto inner = parseLogicalNot(ctx);
    if (hasExprParseFailure(ctx, inner)) {
      return nullptr;
    }
    auto u = std::make_unique<Expr>();
    u->tag = Expr::Tag::Unary;
    u->unaryOp = 'N';
    u->child = std::move(inner);
    return u;
  }
  if (*ctx.p == '!') {
    ++ctx.p;
    auto inner = parseUnary(ctx);
    if (hasExprParseFailure(ctx, inner)) {
      return nullptr;
    }
    auto u = std::make_unique<Expr>();
    u->tag = Expr::Tag::Unary;
    u->unaryOp = 'N';
    u->child = std::move(inner);
    return u;
  }
  if (*ctx.p == '~') {
    ++ctx.p;
    auto inner = parseUnary(ctx);
    if (hasExprParseFailure(ctx, inner)) {
      return nullptr;
    }
    auto u = std::make_unique<Expr>();
    u->tag = Expr::Tag::Unary;
    u->unaryOp = '~';
    u->child = std::move(inner);
    return u;
  }
  auto prim = parsePrimary(ctx);
  if (hasExprParseFailure(ctx, prim)) {
    return nullptr;
  }
  while (true) {
    skipSpaces(ctx);
    if (*ctx.p == '[') {
      ++ctx.p;
      skipSpaces(ctx);
      if (*ctx.p == ']') {
        setMissingIndexError(ctx);
        return nullptr;
      }
      auto idx = parseExpression(ctx);
      if (ctx.parseError || !idx) return nullptr;
      skipSpaces(ctx);
      if (*ctx.p != ']') {
        setMissingClosingBracketError(ctx);
        return nullptr;
      }
      ++ctx.p;
      auto w = std::make_unique<Expr>();
      w->tag = Expr::Tag::Index;
      w->left = std::move(prim);
      w->right = std::move(idx);
      prim = std::move(w);
      continue;
    }
    if (isPercentPostfixContext(ctx.p)) {
      ++ctx.p;
      auto w = std::make_unique<Expr>();
      w->tag = Expr::Tag::PostfixPercent;
      w->child = std::move(prim);
      prim = std::move(w);
      continue;
    }
    break;
  }
  return prim;
}

std::unique_ptr<MathParser::Expr> MathParser::parsePower(EvalContext& ctx) {
  auto left = parseUnary(ctx);
  if (ctx.parseError || !left) {
    return nullptr;
  }
  skipSpaces(ctx);
  // AST parser uses '**' for exponentiation.
  if (ctx.p[0] == '*' && ctx.p[1] == '*') {
    ctx.p += 2;
    auto right = parsePower(ctx);
    if (ctx.parseError || !right) {
      return nullptr;
    }
    auto out = std::make_unique<Expr>();
    out->tag = Expr::Tag::Binary;
    out->binaryOp = Expr::BinaryOp::Pow;
    out->left = std::move(left);
    out->right = std::move(right);
    return out;
  }
  return left;
}

std::unique_ptr<MathParser::Expr> MathParser::parseMulDivMod(EvalContext& ctx) {
  return parseLeftAssocBinary(ctx, &MathParser::parsePower, &MathParser::tryConsumeMulDivModOp);
}

std::unique_ptr<MathParser::Expr> MathParser::parseShift(EvalContext& ctx) {
  return parseLeftAssocBinary(ctx, &MathParser::parseAddSub, &MathParser::tryConsumeShiftOp);
}

std::unique_ptr<MathParser::Expr> MathParser::parseBitAnd(EvalContext& ctx) {
  return parseLeftAssocBinary(ctx, &MathParser::parseShift, &MathParser::tryConsumeBitAndOp);
}

std::unique_ptr<MathParser::Expr> MathParser::parseBitXor(EvalContext& ctx) {
  return parseLeftAssocBinary(ctx, &MathParser::parseBitAnd, &MathParser::tryConsumeBitXorOp);
}

std::unique_ptr<MathParser::Expr> MathParser::parseBitOr(EvalContext& ctx) {
  return parseLeftAssocBinary(ctx, &MathParser::parseBitXor, &MathParser::tryConsumeBitOrOp);
}

std::unique_ptr<MathParser::Expr> MathParser::parseAddSub(EvalContext& ctx) {
  return parseLeftAssocBinary(ctx, &MathParser::parseMulDivMod, &MathParser::tryConsumeAddSubOp, true);
}

std::unique_ptr<MathParser::Expr> MathParser::parseCompare(EvalContext& ctx) {
  return parseLeftAssocBinary(ctx, &MathParser::parseBitOr, &MathParser::tryConsumeCompareOp);
}

std::unique_ptr<MathParser::Expr> MathParser::parseLogicalNot(EvalContext& ctx) {
  skipSpaces(ctx);
  if (consumeKeyword(ctx, opName(OperatorNameId::Not).c_str())) {
    auto inner = parseLogicalNot(ctx);
    if (ctx.parseError || !inner) {
      return nullptr;
    }
    auto u = std::make_unique<Expr>();
    u->tag = Expr::Tag::Unary;
    u->unaryOp = 'N';
    u->child = std::move(inner);
    return u;
  }
  return parseCompare(ctx);
}

std::unique_ptr<MathParser::Expr> MathParser::parseAnd(EvalContext& ctx) {
  return parseLeftAssocBinary(ctx, &MathParser::parseLogicalNot, &MathParser::tryConsumeLogicalAndOp);
}

std::unique_ptr<MathParser::Expr> MathParser::parseOr(EvalContext& ctx) {
  return parseLeftAssocBinary(ctx, &MathParser::parseAnd, &MathParser::tryConsumeLogicalOrOp);
}

std::unique_ptr<MathParser::Expr> MathParser::parseExpression(EvalContext& ctx) {
  return parseOr(ctx);
}

bool MathParser::tryAppendTrailingFormatterSugarStatement(
    EvalContext& ctx,
    std::vector<AstStatement>& out,
    bool& handled) {
  handled = false;
  if (out.empty() || !isIdentStart(*ctx.p)) {
    return true;
  }
  const char* sugarStart = ctx.p;
  const char* q = ctx.p + 1;
  while (isIdentChar(*q)) {
    ++q;
  }
  const std::string ident = toLower(std::string(sugarStart, static_cast<std::size_t>(q - sugarStart)));
  if (!isTrailingFormatterFunctionName(ident)) {
    return true;
  }
  const char* sugarEnd = q;
  while (*sugarEnd != '\0' && std::isspace(static_cast<unsigned char>(*sugarEnd))) {
    ++sugarEnd;
  }
  bool sugarOk = false;
  if (*sugarEnd == ';' || *sugarEnd == '\0') {
    sugarOk = true;
  } else if (*sugarEnd == '(') {
    const char* r = sugarEnd + 1;
    while (*r != '\0' && std::isspace(static_cast<unsigned char>(*r))) {
      ++r;
    }
    if (*r == ')') {
      ++r;
      while (*r != '\0' && std::isspace(static_cast<unsigned char>(*r))) {
        ++r;
      }
      if (*r == ';' || *r == '\0') {
        sugarOk = true;
        sugarEnd = r;
      }
    }
  }
  if (!sugarOk) {
    return true;
  }
  auto callExpr = std::make_unique<Expr>();
  callExpr->tag = Expr::Tag::Call;
  callExpr->name = ident;
  BuiltinFunctionId id = BuiltinFunctionId::Count;
  if (tryGetBuiltinFunctionId(callExpr->name, id)) {
    callExpr->builtinFunctionId = id;
  }
  auto ansExpr = std::make_unique<Expr>();
  ansExpr->tag = Expr::Tag::Variable;
  ansExpr->name = STR_ANS;
  callExpr->elements.emplace_back(std::move(ansExpr));
  AstStatement st;
  st.kind = AstStatement::Kind::Expr;
  st.expr = std::move(callExpr);
  out.emplace_back(std::move(st));
  ctx.p = sugarEnd;
  handled = true;
  return true;
}

bool MathParser::parseProgram(EvalContext& ctx, std::vector<AstStatement>& out) {
  out.clear();
  while (true) {
    skipSpaces(ctx);
    if (*ctx.p == '\0') {
      break;
    }
    const char* save = ctx.p;
    if (tryAppendFunctionDefinitionStatement(ctx, out)) {
      // handled above
    } else {
      ctx.p = save;
      skipSpaces(ctx);
      bool statementHandled = false;
      if (!tryAppendTrailingFormatterSugarStatement(ctx, out, statementHandled)) {
        return false;
      }
      if (!statementHandled) {
        if (!tryAppendAssignOrExpressionStatement(ctx, out)) {
          return false;
        }
      }
    }
    if (consumeProgramStatementSeparator(ctx)) continue;
    if (*ctx.p == '\0') break;
    return false;
  }
  return true;
}

bool MathParser::exprIsDirectPostfixPercent(const Expr& e) {
  if (e.tag == Expr::Tag::PostfixPercent) {
    return true;
  }
  if (e.tag == Expr::Tag::Unary && e.child) {
    return exprIsDirectPostfixPercent(*e.child);
  }
  if (e.tag == Expr::Tag::ArrayOrParens && e.elements.size() == 1U && e.elements[0]) {
    return exprIsDirectPostfixPercent(*e.elements[0]);
  }
  return false;
}

bool MathParser::exprIsScalarOnly(const Expr& e) const {
  switch (e.tag) {
    case Expr::Tag::Literal:
    case Expr::Tag::Variable:
      return true;
    case Expr::Tag::Unary:
    case Expr::Tag::PostfixPercent:
      return e.child ? exprIsScalarOnly(*e.child) : false;
    case Expr::Tag::Binary:
      return e.left && e.right && exprIsScalarOnly(*e.left) && exprIsScalarOnly(*e.right);
    case Expr::Tag::ArrayOrParens:
      if (e.elements.size() != 1U) return false;
      return exprIsScalarOnly(*e.elements[0]);
    case Expr::Tag::Call:
    case Expr::Tag::Index:
      return false;
    default:
      return false;
  }
}

bool MathParser::programIsScalarOnly(const std::vector<AstStatement>& program) const {
  for (const auto& st : program) {
    if (st.kind == AstStatement::Kind::FunDef) {
      return false;
    }
    if (!st.expr || !exprIsScalarOnly(*st.expr)) {
      return false;
    }
  }
  return true;
}

void MathParser::bindExprVariableRefs(Expr& e) {
  if (e.tag == Expr::Tag::Variable) {
    if (compiledHasAssignments_) {
      e.boundVariable = nullptr;
      return;
    }
    auto it = variables_.find(e.name);
    e.boundVariable = (it != variables_.end()) ? &it->second : nullptr;
    return;
  }
  if (e.child) {
    bindExprVariableRefs(*e.child);
  }
  if (e.left) {
    bindExprVariableRefs(*e.left);
  }
  if (e.right) {
    bindExprVariableRefs(*e.right);
  }
  for (auto& item : e.elements) {
    if (item) {
      bindExprVariableRefs(*item);
    }
  }
}

void MathParser::bindCompiledVariableRefs() {
  for (auto& st : compiledProgram_) {
    if (st.expr) {
      bindExprVariableRefs(*st.expr);
    }
  }
  boundVariablesVersion_ = variablesVersion_;
}

MathParser::EvalValue MathParser::evalUnaryExpr(
    const Expr& e,
    EvalContext& ctx,
    const std::unordered_map<std::string, EvalValue>* scopedVars,
    bool scalarOnlyMode) {
  const auto evalChild = [&](const Expr& childExpr) -> EvalValue {
    return scalarOnlyMode ? evalExprScalar(childExpr, ctx, scopedVars) : evalExpr(childExpr, ctx, scopedVars);
  };

  if (e.unaryOp == '+') {
    return evalChild(*e.child);
  }

  EvalValue v = evalChild(*e.child);
  if (ctx.parseError) {
    return v;
  }

  if (e.unaryOp == '-') {
    return negateEvalValue(v);
  }
  if (e.unaryOp == 'N') {
    return makeScalarInt(isTruthy(v) ? 0LL : 1LL);
  }
  if (e.unaryOp == '~') {
    if (!scalarOnlyMode && v.kind != ValueKind::Scalar) {
      setBitwiseIntegerOperandsError(ctx);
      return makeScalar(0);
    }
    long long iv = 0;
    if (!tryGetSignedInt64FromScalar(v.scalarValue, iv)) {
      setBitwiseIntegerOperandsError(ctx);
      return makeScalar(0);
    }
    return makeScalarInt(~iv);
  }

  setInternalUnaryOpError(ctx);
  return makeScalar(0);
}

MathParser::EvalValue MathParser::evalMappedBinaryOp(
    EvalContext& ctx,
    Expr::BinaryOp op,
    const EvalValue& left,
    const EvalValue& right) const {
  const char opChar = (op == Expr::BinaryOp::Pow) ? '^' :
                      (op == Expr::BinaryOp::Mul) ? '*' :
                      (op == Expr::BinaryOp::Div) ? '/' :
                      (op == Expr::BinaryOp::Add) ? '+' : '-';
  bool ok = false;
  EvalValue out = mapBinary(left, right, opChar, ok);
  if (ok) {
    return out;
  }

  if (op == Expr::BinaryOp::Pow) {
    setNumericErrorInPowerOperation(ctx);
  } else if (left.kind == ValueKind::Array && right.kind == ValueKind::Array && left.arr.size() != right.arr.size()) {
    setIncompatibleOperandsError(ctx);
  } else {
    setNumericErrorInExpression(ctx);
  }
  return makeScalar(0);
}

MathParser::EvalValue MathParser::evalInt64BinaryOp(
    EvalContext& ctx,
    const EvalValue& left,
    const EvalValue& right,
    Expr::BinaryOp op) const {
  const bool isModulo = (op == Expr::BinaryOp::Modulo);
  const auto setIntegerOperandError = [&]() {
    if (isModulo) setModuloIntegerOperandsError(ctx);
    else setBitwiseIntegerOperandsError(ctx);
  };
  const auto applyOp = [&](const EvalValue::ScalarValue& lv, const EvalValue::ScalarValue& rv, EvalValue& outS) -> bool {
    if (op == Expr::BinaryOp::ShiftLeft) {
      std::uint64_t aU = 0;
      std::uint64_t bU = 0;
      if (tryGetBothExactNonNegativeUInt64FromScalars(lv, rv, aU, bU)) {
        if (!tryShiftLeftU64ExactOrMaybe(aU, bU, outS)) {
          setIncompatibleOperandsError(ctx);
          return false;
        }
        return true;
      }
    }

    if (lv.hasExactUInt64() && rv.hasExactUInt64() && (!lv.hasExactInt() || !rv.hasExactInt())) {
      const std::uint64_t aU = lv.exactUInt64;
      const std::uint64_t bU = rv.exactUInt64;
      if (isModulo) {
        if (bU == 0) {
          setIncompatibleOperandsError(ctx);
          return false;
        }
        outS = makeScalarUInt(aU % bU);
        return true;
      }
      if ((op == Expr::BinaryOp::ShiftLeft || op == Expr::BinaryOp::ShiftRight) && bU > 63u) {
        setIncompatibleOperandsError(ctx);
        return false;
      }
      if (op == Expr::BinaryOp::ShiftLeft) {
        if (!tryShiftLeftU64ExactOrMaybe(aU, bU, outS)) {
          setIncompatibleOperandsError(ctx);
          return false;
        }
        return true;
      }
      if (op == Expr::BinaryOp::ShiftRight) {
        outS = makeScalarUInt(aU >> bU);
        return true;
      }
      if (op == Expr::BinaryOp::BitAnd) {
        outS = makeScalarUInt(aU & bU);
        return true;
      }
      if (op == Expr::BinaryOp::BitOr) {
        outS = makeScalarUInt(aU | bU);
        return true;
      }
      if (op == Expr::BinaryOp::BitXor) {
        outS = makeScalarUInt(aU ^ bU);
        return true;
      }
    }

    long long a = 0, b = 0;
    if (!tryGetSignedInt64FromScalar(lv, a) || !tryGetSignedInt64FromScalar(rv, b)) return false;
    if (isModulo) {
      if (b == 0) {
        setIncompatibleOperandsError(ctx);
        return false;
      }
      outS = makeScalarInt(a % b);
      return true;
    }
    if ((op == Expr::BinaryOp::ShiftLeft || op == Expr::BinaryOp::ShiftRight) && (b < 0 || b > 63)) {
      setIncompatibleOperandsError(ctx);
      return false;
    }
    const long long out = (op == Expr::BinaryOp::BitAnd) ? (a & b) :
                          (op == Expr::BinaryOp::BitOr) ? (a | b) :
                          (op == Expr::BinaryOp::BitXor) ? (a ^ b) :
                          (op == Expr::BinaryOp::ShiftLeft) ? bitwiseShiftLeftDefined(a, static_cast<unsigned int>(b)) :
                                                               bitwiseShiftRightDefined(a, static_cast<unsigned int>(b));
    outS = makeScalarInt(out);
    return true;
  };
  if (left.kind == ValueKind::Array && right.kind == ValueKind::Array && left.arr.size() != right.arr.size()) {
    setIncompatibleOperandsError(ctx);
    return makeScalar(0);
  }
  bool ok = true;
  EvalValue out = mapBinaryBroadcast(left, right, applyOp, ok);
  if (!ok && !ctx.parseError) {
    setIntegerOperandError();
    return makeScalar(0);
  }
  return out;
}

bool MathParser::isComparisonBinaryOp(Expr::BinaryOp op) {
  return op == Expr::BinaryOp::CmpLt || op == Expr::BinaryOp::CmpGt ||
         op == Expr::BinaryOp::CmpLe || op == Expr::BinaryOp::CmpGe ||
         op == Expr::BinaryOp::CmpEq || op == Expr::BinaryOp::CmpNe;
}

bool MathParser::evalComparisonByOp(Expr::BinaryOp op, int cmp) {
  switch (op) {
    case Expr::BinaryOp::CmpLt: return cmp < 0;
    case Expr::BinaryOp::CmpGt: return cmp > 0;
    case Expr::BinaryOp::CmpLe: return cmp <= 0;
    case Expr::BinaryOp::CmpGe: return cmp >= 0;
    case Expr::BinaryOp::CmpEq: return cmp == 0;
    case Expr::BinaryOp::CmpNe: return cmp != 0;
    default: return false;
  }
}

bool MathParser::evalComparisonTruthWhenUnorderedNan(Expr::BinaryOp op) {
  switch (op) {
    case Expr::BinaryOp::CmpNe:
      return true;
    default:
      return false;
  }
}

MathParser::EvalValue MathParser::evalExprScalar(
    const Expr& e,
    EvalContext& ctx,
    const std::unordered_map<std::string, EvalValue>* scopedVars) {
  switch (e.tag) {
    case Expr::Tag::Literal:
      return e.literalValue;
    case Expr::Tag::Variable: {
      EvalValue out = makeScalar(0);
      if (!tryResolveVariableValue(e, scopedVars, out)) {
        if (handleUnknownIdentifier(ctx, e.name, ctx.unknownVarsText)) {
          return makeScalar(0);
        }
        return makeScalar(0);
      }
      if (out.kind != ValueKind::Scalar) {
        setScalarOnlyExpressionEncounteredNonError(ctx);
        return makeScalar(0);
      }
      return out;
    }
    case Expr::Tag::Unary:
      return evalUnaryExpr(e, ctx, scopedVars, true);
    case Expr::Tag::PostfixPercent: {
      EvalValue v = evalExprScalar(*e.child, ctx, scopedVars);
      if (ctx.parseError) return v;
      v.scalarValue.scalar /= 100.0;
      v.scalarValue.setExactIntValid(false);
      v.scalarValue.setExactUInt64Valid(false);
      return v;
    }
    case Expr::Tag::ArrayOrParens:
      return evalExprScalar(*e.elements[0], ctx, scopedVars);
    case Expr::Tag::Binary: {
      EvalValue l = evalExprScalar(*e.left, ctx, scopedVars);
      if (ctx.parseError) return l;
      EvalValue r = evalExprScalar(*e.right, ctx, scopedVars);
      if (ctx.parseError) return r;
      switch (e.binaryOp) {
        case Expr::BinaryOp::LogicalOr:
          return makeScalarInt((isTruthy(l) || isTruthy(r)) ? 1LL : 0LL);
        case Expr::BinaryOp::LogicalAnd:
          return makeScalarInt((isTruthy(l) && isTruthy(r)) ? 1LL : 0LL);
        case Expr::BinaryOp::Modulo: {
          if (l.scalarValue.hasExactUInt64() && r.scalarValue.hasExactUInt64() &&
              (!l.scalarValue.hasExactInt() || !r.scalarValue.hasExactInt())) {
            if (r.scalarValue.exactUInt64 == 0u) {
              setIncompatibleOperandsError(ctx);
              return makeScalar(0);
            }
            return makeScalarUInt(l.scalarValue.exactUInt64 % r.scalarValue.exactUInt64);
          }
          long long a = 0, b = 0;
          if (!tryGetSignedInt64FromScalar(l.scalarValue, a) || !tryGetSignedInt64FromScalar(r.scalarValue, b)) {
            setModuloIntegerOperandsError(ctx);
            return makeScalar(0);
          }
          if (b == 0) {
            setIncompatibleOperandsError(ctx);
            return makeScalar(0);
          }
          return makeScalarInt(a % b);
        }
        case Expr::BinaryOp::BitAnd:
        case Expr::BinaryOp::BitOr:
        case Expr::BinaryOp::BitXor:
        case Expr::BinaryOp::ShiftLeft:
        case Expr::BinaryOp::ShiftRight: {
          if (e.binaryOp == Expr::BinaryOp::ShiftLeft) {
            std::uint64_t aU = 0;
            std::uint64_t bU = 0;
            if (tryGetBothExactNonNegativeUInt64FromScalars(l.scalarValue, r.scalarValue, aU, bU)) {
              EvalValue outS;
              if (!tryShiftLeftU64ExactOrMaybe(aU, bU, outS)) {
                setIncompatibleOperandsError(ctx);
                return makeScalar(0);
              }
              return outS;
            }
          }
          if (l.scalarValue.hasExactUInt64() && r.scalarValue.hasExactUInt64() &&
              (!l.scalarValue.hasExactInt() || !r.scalarValue.hasExactInt())) {
            const std::uint64_t aU = l.scalarValue.exactUInt64;
            const std::uint64_t bU = r.scalarValue.exactUInt64;
            if (bU > 63u) {
              setIncompatibleOperandsError(ctx);
              return makeScalar(0);
            }
            if (e.binaryOp == Expr::BinaryOp::BitAnd) return makeScalarUInt(aU & bU);
            if (e.binaryOp == Expr::BinaryOp::BitOr) return makeScalarUInt(aU | bU);
            if (e.binaryOp == Expr::BinaryOp::BitXor) return makeScalarUInt(aU ^ bU);
            if (e.binaryOp == Expr::BinaryOp::ShiftLeft) {
              EvalValue outS;
              if (!tryShiftLeftU64ExactOrMaybe(aU, bU, outS)) {
                setIncompatibleOperandsError(ctx);
                return makeScalar(0);
              }
              return outS;
            }
            return makeScalarUInt(aU >> bU);
          }
          long long a = 0, b = 0;
          if (!tryGetSignedInt64FromScalar(l.scalarValue, a) || !tryGetSignedInt64FromScalar(r.scalarValue, b)) {
            setBitwiseIntegerOperandsError(ctx);
            return makeScalar(0);
          }
          if ((e.binaryOp == Expr::BinaryOp::ShiftLeft || e.binaryOp == Expr::BinaryOp::ShiftRight) &&
              (b < 0 || b > 63)) {
            setIncompatibleOperandsError(ctx);
            return makeScalar(0);
          }
          if (e.binaryOp == Expr::BinaryOp::BitAnd) return makeScalarInt(a & b);
          if (e.binaryOp == Expr::BinaryOp::BitOr) return makeScalarInt(a | b);
          if (e.binaryOp == Expr::BinaryOp::BitXor) return makeScalarInt(a ^ b);
          if (e.binaryOp == Expr::BinaryOp::ShiftLeft) return makeScalarInt(bitwiseShiftLeftDefined(a, static_cast<unsigned int>(b)));
          return makeScalarInt(bitwiseShiftRightDefined(a, static_cast<unsigned int>(b)));
        }
        case Expr::BinaryOp::CmpLt:
        case Expr::BinaryOp::CmpGt:
        case Expr::BinaryOp::CmpLe:
        case Expr::BinaryOp::CmpGe:
        case Expr::BinaryOp::CmpEq:
        case Expr::BinaryOp::CmpNe: {
          const double ls = l.scalarValue.scalar;
          const double rs = r.scalarValue.scalar;
          if (std::isnan(ls) || std::isnan(rs)) {
            return makeScalarInt(evalComparisonTruthWhenUnorderedNan(e.binaryOp) ? 1LL : 0LL);
          }
          const int cmp = (ls < rs) ? -1 : (ls > rs) ? 1 : 0;
          return makeScalarInt(evalComparisonByOp(e.binaryOp, cmp) ? 1LL : 0LL);
        }
        case Expr::BinaryOp::Pow:
          return evalMappedBinaryOp(ctx, e.binaryOp, l, r);
        case Expr::BinaryOp::Mul:
        case Expr::BinaryOp::Div:
        case Expr::BinaryOp::Add:
        case Expr::BinaryOp::Sub: {
          if ((e.binaryOp == Expr::BinaryOp::Add || e.binaryOp == Expr::BinaryOp::Sub) &&
              e.rhsIsDirectPostfixPercent) {
            r.scalarValue.scalar = l.scalarValue.scalar * r.scalarValue.scalar;
          }

          if ((e.binaryOp == Expr::BinaryOp::Mul || e.binaryOp == Expr::BinaryOp::Add ||
               e.binaryOp == Expr::BinaryOp::Sub)) {
            long long li = 0, ri = 0;
            if (tryGetBothExactSignedInt64NoUIntWrapFromScalars(l.scalarValue, r.scalarValue, li, ri)) {
              long long outI = 0;
              const bool okInt =
                  (e.binaryOp == Expr::BinaryOp::Mul) ? checkedMulLL(li, ri, outI) :
                  (e.binaryOp == Expr::BinaryOp::Add) ? checkedAddLL(li, ri, outI) :
                                                         checkedSubLL(li, ri, outI);
              if (okInt) {
                return makeScalarInt(outI);
              }
              if (li >= 0 && ri >= 0) {
                const std::uint64_t lu = static_cast<std::uint64_t>(li);
                const std::uint64_t ru = static_cast<std::uint64_t>(ri);
                if (e.binaryOp == Expr::BinaryOp::Add) {
                  std::uint64_t outU = 0;
                  if (tryAddUInt64Checked(lu, ru, outU)) {
                    return makeScalarUInt(outU);
                  }
                } else if (e.binaryOp == Expr::BinaryOp::Mul) {
                  std::uint64_t outU = 0;
                  if (tryMulUInt64Checked(lu, ru, outU)) {
                    return makeScalarUInt(outU);
                  }
                }
              }
            }
            std::uint64_t lu = 0;
            std::uint64_t ru = 0;
            if (tryGetBothExactNonNegativeUInt64FromScalars(l.scalarValue, r.scalarValue, lu, ru)) {
              if (e.binaryOp == Expr::BinaryOp::Add) {
                std::uint64_t outU = 0;
                if (tryAddUInt64Checked(lu, ru, outU)) {
                  return makeScalarUInt(outU);
                }
              } else if (e.binaryOp == Expr::BinaryOp::Mul) {
                std::uint64_t outU = 0;
                if (tryMulUInt64Checked(lu, ru, outU)) {
                  return makeScalarUInt(outU);
                }
              }
            }
          }

          return evalMappedBinaryOp(ctx, e.binaryOp, l, r);
        }
        default:
          setInternalBinaryOpError(ctx);
          return makeScalar(0);
      }
    }
    default:
      setInternalEvalError(ctx);
      return makeScalar(0);
  }
}

MathParser::EvalValue MathParser::evalExpr(
    const Expr& e,
    EvalContext& ctx,
    const std::unordered_map<std::string, EvalValue>* scopedVars) {
  switch (e.tag) {
    case Expr::Tag::Literal:
      return e.literalValue;
    case Expr::Tag::Variable: {
      EvalValue out = makeScalar(0);
      if (tryResolveVariableValue(e, scopedVars, out)) {
        return out;
      }
      if (handleUnknownIdentifier(ctx, e.name, ctx.unknownVarsText)) {
        return makeScalar(0);
      }
      return makeScalar(0);
    }
    case Expr::Tag::Unary:
      return evalUnaryExpr(e, ctx, scopedVars, false);
    case Expr::Tag::PostfixPercent: {
      EvalValue v = evalExpr(*e.child, ctx, scopedVars);
      if (ctx.parseError) {
        return v;
      }
      if (v.kind != ValueKind::Scalar) {
        setPercentageRequiresScalarValueError(ctx);
        return makeScalar(0);
      }
      v.scalarValue.scalar /= 100.0;
      v.scalarValue.setExactIntValid(false);
      v.scalarValue.setExactUInt64Valid(false);
      return v;
    }
    case Expr::Tag::ArrayOrParens: {
      std::vector<EvalValue> flatVals;
      flatVals.reserve(e.elements.size());
      for (const auto& ch : e.elements) {
        EvalValue a = evalExpr(*ch, ctx, scopedVars);
        if (ctx.parseError) {
          return makeScalar(0);
        }
        if (a.kind == ValueKind::Scalar) {
          flatVals.emplace_back(std::move(a));
        } else {
          if (a.arr.empty()) {
            continue;
          }
          const std::size_t oldSize = flatVals.size();
          flatVals.reserve(oldSize + a.arr.size());
          for (const auto& item : a.arr) {
            flatVals.emplace_back(scalarFromScalarValue(item));
          }
        }
      }
      if (flatVals.empty()) {
        setFailedToBuildArrayLiteralError(ctx);
        return makeScalar(0);
      }
      return makeArrayFromScalars(flatVals);
    }
    case Expr::Tag::Call: {
      std::vector<EvalValue> args;
      args.reserve(e.elements.size());
      for (const auto& ch : e.elements) {
        args.emplace_back(evalExpr(*ch, ctx, scopedVars));
        if (ctx.parseError) {
          return makeScalar(0);
        }
      }
      return evalFunctionCall(ctx, e.name, std::move(args), e.builtinFunctionId, scopedVars);
    }
    case Expr::Tag::Index: {
      EvalValue base = evalExpr(*e.left, ctx, scopedVars);
      if (ctx.parseError) return base;
      if (base.kind != ValueKind::Array) {
        setIndexingRequiresArrayError(ctx);
        return makeScalar(0);
      }
      EvalValue idxv = evalExpr(*e.right, ctx, scopedVars);
      if (ctx.parseError) return idxv;
      if (idxv.kind != ValueKind::Scalar) {
        setArrayIndexMustBeScalarError(ctx);
        return makeScalar(0);
      }
      long long idx = 0;
      if (!nearlyInt(idxv.scalarValue.scalar, idx)) {
        setArrayIndexMustBeIntegerError(ctx);
        return makeScalar(0);
      }
      const long long n = static_cast<long long>(base.arr.size());
      long long realIdx = (idx >= 0) ? idx : (n + idx);
      if (realIdx < 0 || realIdx >= n) {
        setArrayIndexOutOfRangeError(ctx);
        return makeScalar(0);
      }
      return scalarFromArrayAt(base, static_cast<std::size_t>(realIdx));
    }
    case Expr::Tag::Binary: {
      auto compareValues = [](const EvalValue& a, const EvalValue& b) -> int {
        if (a.kind == ValueKind::Scalar && b.kind == ValueKind::Scalar) {
          if (a.scalarValue.scalar < b.scalarValue.scalar) return -1;
          if (a.scalarValue.scalar > b.scalarValue.scalar) return 1;
          return 0;
        }
        auto valAt = [](const EvalValue& v, std::size_t i) -> double {
          return (v.kind == ValueKind::Scalar) ? v.scalarValue.scalar : v.arr[i].scalar;
        };
        const std::size_t na = (a.kind == ValueKind::Scalar) ? 1U : a.arr.size();
        const std::size_t nb = (b.kind == ValueKind::Scalar) ? 1U : b.arr.size();
        const std::size_t n = (na < nb) ? na : nb;
        for (std::size_t i = 0; i < n; ++i) {
          const double va = valAt(a, i);
          const double vb = valAt(b, i);
          if (va < vb) return -1;
          if (va > vb) return 1;
        }
        if (na < nb) return -1;
        if (na > nb) return 1;
        return 0;
      };
      const auto returnIntegerOperandError = [&](const char* msg) -> EvalValue {
        setValidationError(ctx, msg);
        return makeScalar(0);
      };
      enum class BinaryEvalStatus {
        Ok,
        LeftError,
        RightError
      };
      const auto evalBinaryOperands = [&](EvalValue& leftOut, EvalValue& rightOut) -> BinaryEvalStatus {
        leftOut = evalExpr(*e.left, ctx, scopedVars);
        if (ctx.parseError) {
          return BinaryEvalStatus::LeftError;
        }
        rightOut = evalExpr(*e.right, ctx, scopedVars);
        return ctx.parseError ? BinaryEvalStatus::RightError : BinaryEvalStatus::Ok;
      };
      if (e.binaryOp == Expr::BinaryOp::LogicalOr) {
        EvalValue l = makeScalar(0), r = makeScalar(0);
        const BinaryEvalStatus evalStatus = evalBinaryOperands(l, r);
        if (evalStatus != BinaryEvalStatus::Ok) {
          return (evalStatus == BinaryEvalStatus::LeftError) ? l : r;
        }
        return makeScalarInt((isTruthy(l) || isTruthy(r)) ? 1LL : 0LL);
      }
      if (e.binaryOp == Expr::BinaryOp::LogicalAnd) {
        EvalValue l = makeScalar(0), r = makeScalar(0);
        const BinaryEvalStatus evalStatus = evalBinaryOperands(l, r);
        if (evalStatus != BinaryEvalStatus::Ok) {
          return (evalStatus == BinaryEvalStatus::LeftError) ? l : r;
        }
        return makeScalarInt((isTruthy(l) && isTruthy(r)) ? 1LL : 0LL);
      }
      if (e.binaryOp == Expr::BinaryOp::Modulo || e.binaryOp == Expr::BinaryOp::BitAnd ||
          e.binaryOp == Expr::BinaryOp::BitOr || e.binaryOp == Expr::BinaryOp::BitXor ||
          e.binaryOp == Expr::BinaryOp::ShiftLeft || e.binaryOp == Expr::BinaryOp::ShiftRight) {
        EvalValue l = makeScalar(0), r = makeScalar(0);
        if (evalBinaryOperands(l, r) != BinaryEvalStatus::Ok) {
          return makeScalar(0);
        }
        return evalInt64BinaryOp(ctx, l, r, e.binaryOp);
      }
      if (isComparisonBinaryOp(e.binaryOp)) {
        EvalValue l = evalExpr(*e.left, ctx, scopedVars);
        if (ctx.parseError) return makeScalar(0);
        EvalValue r = evalExpr(*e.right, ctx, scopedVars);
        if (ctx.parseError) return makeScalar(0);
        if (l.kind == ValueKind::Scalar && r.kind == ValueKind::Scalar) {
          const double ls = l.scalarValue.scalar;
          const double rs = r.scalarValue.scalar;
          if (std::isnan(ls) || std::isnan(rs)) {
            return makeScalarInt(evalComparisonTruthWhenUnorderedNan(e.binaryOp) ? 1LL : 0LL);
          }
        }
        const int cmp = compareValues(l, r);
        return makeScalarInt(evalComparisonByOp(e.binaryOp, cmp) ? 1LL : 0LL);
      }
      EvalValue l = evalExpr(*e.left, ctx, scopedVars);
      if (ctx.parseError) {
        return l;
      }
      EvalValue r = evalExpr(*e.right, ctx, scopedVars);
      if (ctx.parseError) {
        return r;
      }
      if ((e.binaryOp == Expr::BinaryOp::Add || e.binaryOp == Expr::BinaryOp::Sub) &&
          e.rhsIsDirectPostfixPercent &&
          l.kind == ValueKind::Scalar && r.kind == ValueKind::Scalar) {
        r.scalarValue.scalar = l.scalarValue.scalar * r.scalarValue.scalar;
      }
      if (e.binaryOp == Expr::BinaryOp::Pow) {
        return evalMappedBinaryOp(ctx, e.binaryOp, l, r);
      }
      if (e.binaryOp == Expr::BinaryOp::Mul || e.binaryOp == Expr::BinaryOp::Div ||
          e.binaryOp == Expr::BinaryOp::Add || e.binaryOp == Expr::BinaryOp::Sub) {
        return evalMappedBinaryOp(ctx, e.binaryOp, l, r);
      }
      setInternalBinaryOpError(ctx);
      return makeScalar(0);
    }
    default:
      break;
  }
  setInternalEvalError(ctx);
  return makeScalar(0);
}

MathParser::EvalValue MathParser::runCompiledProgram(
    EvalContext& ctx,
    const std::vector<AstStatement>& program,
    const std::unordered_map<std::string, EvalValue>* scopedVars,
    bool scalarOnlyMode) {
  EvalValue out = makeScalarInt(0);
  const auto evalIntoOut = [&](const Expr& ex) {
    out = scalarOnlyMode ? evalExprScalar(ex, ctx, scopedVars) : evalExpr(ex, ctx, scopedVars);
  };
  for (const auto& st : program) {
    if (st.kind == AstStatement::Kind::FunDef) {
      const std::string udfErr =
          getUserFunctionDefinitionErrorText(st.fun.name, st.fun.params, st.fun.expr, true);
      if (!udfErr.empty()) {
        setError(ctx, udfErr);
        return out;
      }
      upsertUserFunction(UserFunction{st.fun.name, st.fun.params, st.fun.expr});
      out = makeScalarInt(0);
      setVariable(STR_ANS, out);
    } else if (st.kind == AstStatement::Kind::Assign) {
      evalIntoOut(*st.expr);
      if (ctx.parseError) {
        return out;
      }
      setVariable(st.assignName, out);
      setVariable(STR_ANS, out);
    } else {
      evalIntoOut(*st.expr);
      if (ctx.parseError) {
        return out;
      }
      setVariable(STR_ANS, out);
    }
  }
  return out;
}

bool MathParser::argsContainNonFinite(const std::vector<EvalValue>& args) {
  for (const auto& a : args) {
    if (a.kind == ValueKind::Scalar) {
      if (!std::isfinite(a.scalarValue.scalar)) return true;
      continue;
    }
    for (const auto& item : a.arr) {
      if (!std::isfinite(item.scalar)) return true;
    }
  }
  return false;
}

bool MathParser::isFormatBuiltin(BuiltinFunctionId id) {
  return id == BuiltinFunctionId::Hex || id == BuiltinFunctionId::Oct || id == BuiltinFunctionId::Bin ||
      id == BuiltinFunctionId::Uhex || id == BuiltinFunctionId::Uoct || id == BuiltinFunctionId::Ubin;
}

bool MathParser::isIntegerOnlyBuiltin(BuiltinFunctionId id) {
  return id == BuiltinFunctionId::Gcd || id == BuiltinFunctionId::Lcm || id == BuiltinFunctionId::Ncr ||
      id == BuiltinFunctionId::Npr || id == BuiltinFunctionId::Mod ||
      id == BuiltinFunctionId::Fact || id == BuiltinFunctionId::Factorial;
}

bool MathParser::isNonCalculatingBuiltin(BuiltinFunctionId id) {
  return id == BuiltinFunctionId::Unpack || id == BuiltinFunctionId::Sort || id == BuiltinFunctionId::Sorted ||
      id == BuiltinFunctionId::Reverse || id == BuiltinFunctionId::Reversed || id == BuiltinFunctionId::Unique ||
      id == BuiltinFunctionId::Rand || isFormatBuiltin(id);
}

bool MathParser::isFiniteRequiredBuiltin(BuiltinFunctionId id) {
  return id == BuiltinFunctionId::Random;
}

bool MathParser::validateIntegerRepresentableArgs(
    EvalContext& ctx,
    const std::string& fnName,
    const std::vector<EvalValue>& args,
    bool allowNonFiniteForFormat) const {
  for (const auto& a : args) {
    const auto validateScalar = [&](const EvalValue::ScalarValue& s) -> bool {
      if (!std::isfinite(s.scalar)) {
        return allowNonFiniteForFormat;
      }
      if (s.hasExactInt() || s.hasExactUInt64()) {
        return true;
      }
      long long signedV = 0;
      return tryGetSignedInt64FromScalar(s, signedV);
    };
    if (a.kind == ValueKind::Scalar) {
      if (!validateScalar(a.scalarValue)) {
        setIntegerValuesError(ctx, fnName);
        return false;
      }
      continue;
    }
    for (const auto& item : a.arr) {
      if (!validateScalar(item)) {
        setIntegerValuesError(ctx, fnName);
        return false;
      }
    }
  }
  return true;
}

bool MathParser::validateBuiltinArgs(
    EvalContext& ctx,
    const std::string& fnName,
    BuiltinFunctionId id,
    const std::vector<EvalValue>& args) const {
  if (isFormatBuiltin(id)) {
    return validateIntegerRepresentableArgs(ctx, fnName, args, true);
  }
  if (isIntegerOnlyBuiltin(id)) {
    return validateIntegerRepresentableArgs(ctx, fnName, args, false);
  }
  if (isNonCalculatingBuiltin(id)) {
    return true;
  }
  if (isFiniteRequiredBuiltin(id) && argsContainNonFinite(args)) {
    setNumericErrorInFunction(ctx, fnName);
    return false;
  }
  return true;
}

MathParser::EvalValue MathParser::builtinUnpack(EvalContext& ctx, const std::vector<EvalValue>& args) const {
  const std::string fnName = getFunctionName(BuiltinFunctionId::Unpack);
  if (args.empty()) {
    setAtLeastOneArgError(ctx, fnName);
    return makeScalar(0);
  }
  const auto markExpanded = [](EvalValue v) {
    v.setExpandArgs(true);
    return v;
  };
  if (args.size() == 1) {
    return markExpanded(args[0]);
  }
  std::vector<EvalValue> elems;
  if (!flattenArgsToScalars(args, elems)) {
    setAtLeastOneArgError(ctx, fnName);
    return makeScalar(0);
  }
  return markExpanded(makeArrayFromScalars(elems));
}

MathParser::EvalValue MathParser::builtinAggregateFamily(
    EvalContext& ctx,
    const std::string& fnName,
    BuiltinFunctionId id,
    const std::vector<EvalValue>& args) const {
  const auto forEachArgScalar = [&](const auto& fn) -> std::size_t {
    std::size_t count = 0;
    for (const auto& a : args) {
      if (a.kind == ValueKind::Scalar) {
        fn(a.scalarValue.scalar);
        ++count;
      } else {
        for (const auto& item : a.arr) {
          fn(item.scalar);
          ++count;
        }
      }
    }
    return count;
  };
  const auto forEachArgScalarValue = [&](const auto& fn) -> std::size_t {
    std::size_t count = 0;
    for (const auto& a : args) {
      if (a.kind == ValueKind::Scalar) {
        fn(a.scalarValue);
        ++count;
      } else {
        for (const auto& item : a.arr) {
          fn(item);
          ++count;
        }
      }
    }
    return count;
  };
  if (id == BuiltinFunctionId::Sum || id == BuiltinFunctionId::Product || id == BuiltinFunctionId::Prod ||
      id == BuiltinFunctionId::Min || id == BuiltinFunctionId::Max || id == BuiltinFunctionId::Avg ||
      id == BuiltinFunctionId::Mean) {
    if (args.empty()) {
      setAtLeastOneArgError(ctx, fnName);
      return makeScalar(0);
    }
    if (args.size() == 1 && args[0].kind == ValueKind::Scalar) {
      return args[0];
    }
    if (id == BuiltinFunctionId::Sum || id == BuiltinFunctionId::Product || id == BuiltinFunctionId::Prod ||
        id == BuiltinFunctionId::Min || id == BuiltinFunctionId::Max) {
      bool allNnU = true;
      bool allSwI = true;
      bool anyNonInteger = false;
      const auto classify = [&](const EvalValue::ScalarValue& s) {
        std::uint64_t u = 0;
        long long i = 0;
        const bool nnU = tryGetExactNonNegativeUInt64FromScalar(s, u);
        const bool swI = tryGetExactSignedInt64NoUIntWrapFromScalar(s, i);
        if (!nnU && !swI) {
          anyNonInteger = true;
          return;
        }
        if (!nnU) {
          allNnU = false;
        }
        if (!swI) {
          allSwI = false;
        }
      };
      const std::size_t nn = forEachArgScalarValue(classify);
      if (nn == 0U) {
        setAtLeastOneArgError(ctx, fnName);
        return makeScalar(0);
      }
      if (!anyNonInteger && (id == BuiltinFunctionId::Product || id == BuiltinFunctionId::Prod)) {
        bool ok = true;
        std::uint64_t productMag = 1;
        bool isNegativeProduct = false;
        forEachArgScalarValue([&](const EvalValue::ScalarValue& s) {
          if (!ok) {
            return;
          }
          std::uint64_t termMag = 0;
          if (!tryGetExactNonNegativeUInt64FromScalar(s, termMag)) {
            long long termI = 0;
            if (!tryGetExactSignedInt64NoUIntWrapFromScalar(s, termI)) {
              ok = false;
              return;
            }
            if (termI < 0) {
              isNegativeProduct = !isNegativeProduct;
              termMag = (termI == (std::numeric_limits<long long>::min)())
                ? (1ull << 63)
                : static_cast<std::uint64_t>(-termI);
            } else {
              termMag = static_cast<std::uint64_t>(termI);
            }
          }
          std::uint64_t next = 0;
          if (!tryMulUInt64Checked(productMag, termMag, next)) {
            ok = false;
            return;
          }
          productMag = next;
        });
        if (ok) {
          if (isNegativeProduct) {
            if (productMag <= (1ull << 63)) {
              return (productMag == (1ull << 63))
                ? makeScalarInt((std::numeric_limits<long long>::min)())
                : makeScalarInt(-static_cast<long long>(productMag));
            }
          } else {
            return makeScalarUInt(productMag);
          }
        }
      } else if (!anyNonInteger && allNnU) {
        bool ok = true;
        std::uint64_t accU = 0;
        bool hasMm = false;
        std::uint64_t mmU = 0;
        const bool wantMin = (id == BuiltinFunctionId::Min);
        forEachArgScalarValue([&](const EvalValue::ScalarValue& s) {
          std::uint64_t u = 0;
          (void)tryGetExactNonNegativeUInt64FromScalar(s, u);
          if (id == BuiltinFunctionId::Sum) {
            std::uint64_t next = 0;
            if (!tryAddUInt64Checked(accU, u, next)) {
              ok = false;
            }
            accU = next;
          } else if (!hasMm || (wantMin ? u < mmU : u > mmU)) {
            mmU = u;
            hasMm = true;
          }
        });
        if (ok) {
          if (id == BuiltinFunctionId::Sum) {
            return makeScalarUInt(accU);
          }
          return makeScalarUInt(mmU);
        }
      } else if (!anyNonInteger && allSwI) {
        bool ok = true;
        long long accI = 0;
        bool hasMm = false;
        long long mmI = 0;
        const bool wantMin = (id == BuiltinFunctionId::Min);
        forEachArgScalarValue([&](const EvalValue::ScalarValue& s) {
          long long i = 0;
          (void)tryGetExactSignedInt64NoUIntWrapFromScalar(s, i);
          if (id == BuiltinFunctionId::Sum) {
            long long next = 0;
            if (!tryAddInt64Checked(accI, i, next)) {
              ok = false;
            }
            accI = next;
          } else if (!hasMm || (wantMin ? i < mmI : i > mmI)) {
            mmI = i;
            hasMm = true;
          }
        });
        if (ok) {
          if (id == BuiltinFunctionId::Sum) {
            return makeScalarInt(accI);
          }
          return makeScalarInt(mmI);
        }
      }
    }
    double acc = 0.0;
    bool hasValue = false;
    std::size_t n = 0;
    if (id == BuiltinFunctionId::Product || id == BuiltinFunctionId::Prod) {
      acc = 1.0;
      n = forEachArgScalar([&](double v) { acc *= v; });
    } else if (id == BuiltinFunctionId::Sum || id == BuiltinFunctionId::Avg || id == BuiltinFunctionId::Mean) {
      acc = 0.0;
      n = forEachArgScalar([&](double v) { acc += v; });
    } else if (id == BuiltinFunctionId::Min) {
      n = forEachArgScalar([&](double v) {
        if (!hasValue || v < acc) acc = v;
        hasValue = true;
      });
    } else {
      n = forEachArgScalar([&](double v) {
        if (!hasValue || v > acc) acc = v;
        hasValue = true;
      });
    }

    if (n == 0) {
      setAtLeastOneArgError(ctx, fnName);
        return makeScalar(0);
    }
    if (id == BuiltinFunctionId::Avg || id == BuiltinFunctionId::Mean) {
      acc /= static_cast<double>(n);
    }
    return makeScalarMaybeExact(acc);
  }

  switch (id) {
    case BuiltinFunctionId::Median: {
      if (args.size() == 1U) {
        const EvalValue& single = args.front();
        if (single.kind == ValueKind::Scalar) {
          return single;
        }
        if (single.arr.size() == 1U) {
          return scalarFromArrayAt(single, 0);
        }
      }
      std::vector<double> flat;
      if (!flattenArgs(args, flat)) {
        setAtLeastOneArgError(ctx, fnName);
        return makeScalar(0);
      }
      const std::size_t n = flat.size();
      const std::size_t mid = n / 2U;
      std::nth_element(flat.begin(), flat.begin() + static_cast<std::ptrdiff_t>(mid), flat.end());
      const double upper = flat[mid];
      if (n % 2U == 1U) {
        return makeScalar(upper);
      }
      const double lower = *std::max_element(flat.begin(), flat.begin() + static_cast<std::ptrdiff_t>(mid));
      return makeScalar((lower + upper) / 2.0);
    }
    case BuiltinFunctionId::Variance:
    case BuiltinFunctionId::Stddev: {
      // Welford single-pass accumulation for better stability and fewer passes.
      double mean = 0.0;
      double m2 = 0.0;
      std::size_t n = 0;
      forEachArgScalar([&](double v) {
        ++n;
        const double delta = v - mean;
        mean += delta / static_cast<double>(n);
        const double delta2 = v - mean;
        m2 += delta * delta2;
      });
      if (n == 0) {
        setAtLeastOneArgError(ctx, fnName);
        return makeScalar(0);
      }
      double var = m2 / static_cast<double>(n);
      if (id == BuiltinFunctionId::Variance) {
        return makeScalar(var);
      }
      return makeScalar(std::sqrt(var));
    }
    default:
      break;
  }
  setInternalAggregateBuiltinError(ctx);
  return makeScalar(0);
}

MathParser::EvalValue MathParser::builtinSortFamily(
    EvalContext& ctx,
    const std::string& fnName,
    BuiltinFunctionId id,
    const std::vector<EvalValue>& args) const {
  auto keyForUnique = [](double v) -> std::uint64_t {
    std::uint64_t bits = 0;
    static_assert(sizeof(bits) == sizeof(v));
    std::memcpy(&bits, &v, sizeof(bits));
    // Canonicalize signed zero to preserve equality semantics of (0 == -0).
    if ((bits << 1) == 0) bits = 0;
    return bits;
  };
  auto dedupUniqueInPlace = [&](std::vector<EvalValue>& values) {
    std::unordered_set<std::uint64_t> seen;
    seen.reserve(values.size() * 2 + 1);
    std::size_t writePos = 0;
    for (std::size_t readPos = 0; readPos < values.size(); ++readPos) {
      const double v = values[readPos].scalarValue.scalar;
      if (std::isnan(v)) {
        values[writePos++] = values[readPos]; // NaN never equals NaN in existing semantics; keep all.
        continue;
      }
      if (seen.insert(keyForUnique(v)).second) {
        values[writePos++] = values[readPos];
      }
    }
    values.resize(writePos);
  };

  if (args.empty()) {
    setAtLeastOneArgError(ctx, fnName);
    return makeScalar(0);
  }
  const auto copyArrayScalars = [&](const EvalValue& a, std::vector<EvalValue>& out) {
    out.clear();
    out.reserve(a.arr.size());
    for (const auto& item : a.arr) {
      out.emplace_back(scalarFromScalarValue(item));
    }
  };
  const auto copySingleArgToFlat = [&](const EvalValue& a, std::vector<EvalValue>& out) {
    out.clear();
    if (a.kind == ValueKind::Scalar) {
      out.emplace_back(a);
      return;
    }
    copyArrayScalars(a, out);
  };
  const auto sortScalarsInPlace = [](std::vector<EvalValue>& values) {
    std::sort(
        values.begin(),
        values.end(),
        [](const EvalValue& lhs, const EvalValue& rhs) {
          const bool lhsNan = std::isnan(lhs.scalarValue.scalar);
          const bool rhsNan = std::isnan(rhs.scalarValue.scalar);
          if (lhsNan) return !rhsNan;
          if (rhsNan) return false;
          return lhs.scalarValue.scalar < rhs.scalarValue.scalar;
        });
  };
  if (args.size() == 1) {
    const EvalValue& a = args[0];
    if (a.kind == ValueKind::Scalar) {
      return makeArrayFromScalars(std::vector<EvalValue>{a});
    }
    std::vector<EvalValue> out;
    copySingleArgToFlat(a, out);
    if (out.empty()) {
      setAtLeastOneArgError(ctx, fnName);
      return makeScalar(0);
    }
    if (id == BuiltinFunctionId::Sort || id == BuiltinFunctionId::Sorted) {
      sortScalarsInPlace(out);
      return makeArrayFromScalars(out);
    }
    if (id == BuiltinFunctionId::Reverse || id == BuiltinFunctionId::Reversed) {
      std::reverse(out.begin(), out.end());
      return makeArrayFromScalars(out);
    }
    if (id == BuiltinFunctionId::Unique) {
      dedupUniqueInPlace(out);
      return makeArrayFromScalars(out);
    }
  }

  std::vector<EvalValue> flat;
  if (!flattenArgsToScalars(args, flat)) {
    setAtLeastOneArgError(ctx, fnName);
    return makeScalar(0);
  }
  if (id == BuiltinFunctionId::Sort || id == BuiltinFunctionId::Sorted) {
    sortScalarsInPlace(flat);
  } else if (id == BuiltinFunctionId::Reverse || id == BuiltinFunctionId::Reversed) {
    std::reverse(flat.begin(), flat.end());
  } else {
    dedupUniqueInPlace(flat);
  }
  return makeArrayFromScalars(flat);
}

MathParser::EvalValue MathParser::builtinBaseFormat(
    EvalContext& ctx,
    const std::string& fnName,
    BuiltinFunctionId id,
    const std::vector<EvalValue>& args) const {
  if (args.empty()) {
    setAtLeastOneArgError(ctx, fnName);
    return makeScalar(0);
  }
  EvalValue out;
  if (args.size() == 1) {
    out = args[0];
  } else {
    std::vector<EvalValue> elems;
    if (!flattenArgsToScalars(args, elems)) {
      setAtLeastOneArgError(ctx, fnName);
      return makeScalar(0);
    }
    out = makeArrayFromScalars(elems);
  }
  switch (id) {
    case BuiltinFunctionId::Hex:
    case BuiltinFunctionId::Uhex:
      out.setRenderBase(RenderBase::Hex);
      break;
    case BuiltinFunctionId::Oct:
    case BuiltinFunctionId::Uoct:
      out.setRenderBase(RenderBase::Oct);
      break;
    default:
      out.setRenderBase(RenderBase::Bin);
      break;
  }
  out.setRenderUnsigned(
      id == BuiltinFunctionId::Uhex || id == BuiltinFunctionId::Uoct || id == BuiltinFunctionId::Ubin);
  return out;
}

MathParser::EvalValue MathParser::builtinPow(EvalContext& ctx, const std::vector<EvalValue>& args) const {
  const std::string fnName = getFunctionName(BuiltinFunctionId::Pow);
  if (args.size() != 2) {
    setExactArgCountError(ctx, fnName, 2);
    return makeScalar(0);
  }
  if (args[0].kind == ValueKind::Scalar && args[1].kind == ValueKind::Scalar) {
    const EvalValue::ScalarValue& a = args[0].scalarValue;
    const EvalValue::ScalarValue& b = args[1].scalarValue;
    if (isPureFloatingScalarPair(a, b)) {
      double out = 0.0;
      if (!applyBinary(a.scalar, b.scalar, '^', out)) {
        setNumericErrorInFunction(ctx, fnName);
        return makeScalar(0);
      }
      return makeScalarMaybeExact(out);
    }
  }
  bool ok = false;
  EvalValue out = mapBinary(args[0], args[1], '^', ok);
  if (!ok) {
    setNumericErrorInFunction(ctx, fnName);
    return makeScalar(0);
  }
  return out;
}

MathParser::EvalValue MathParser::builtinScalarBinaryFamily(
    EvalContext& ctx,
    const std::string& fnName,
    BuiltinFunctionId id,
    const std::vector<EvalValue>& args) const {
  if (id == BuiltinFunctionId::Atan2) {
    if (args.size() != 2) {
      setExactArgCountError(ctx, fnName, 2);
      return makeScalar(0);
    }
    bool ok = false;
    EvalValue out = mapBinaryBuiltinMathFunction(args[0], args[1], id, ok);
    if (!ok) {
      setIncompatibleOperandsError(ctx);
      return makeScalar(0);
    }
    return out;
  }

  if (id == BuiltinFunctionId::Hypot) {
    if (args.size() != 2) {
      setExactArgCountError(ctx, fnName, 2);
      return makeScalar(0);
    }
    bool ok = false;
    EvalValue out = mapBinaryBuiltinMathFunction(args[0], args[1], id, ok);
    if (!ok) {
      setNumericErrorInFunction(ctx, fnName);
      return makeScalar(0);
    }
    return out;
  }

  if (id == BuiltinFunctionId::Clamp) {
    if (args.size() != 3) {
      setExactArgCountError(ctx, fnName, 3);
      return makeScalar(0);
    }
    if (args[1].kind != ValueKind::Scalar || args[2].kind != ValueKind::Scalar) {
      setScalarMinMaxError(ctx, fnName);
      return makeScalar(0);
    }
    return builtinApplyClamp(ctx, args[0], args[1], args[2]);
  }

  if (args.size() != 2) {
    setExactArgCountError(ctx, fnName, 2);
    return makeScalar(0);
  }
  const bool hasNonScalarArg = std::any_of(args.begin(), args.end(), [](const EvalValue& v) {
    return v.kind != ValueKind::Scalar;
  });
  if (hasNonScalarArg) {
    setScalarValuesError(ctx, fnName);
    return makeScalar(0);
  }
  switch (id) {
    case BuiltinFunctionId::Atan2:
      return makeScalar(std::atan2(args[0].scalarValue.scalar, args[1].scalarValue.scalar));
    case BuiltinFunctionId::Hypot:
      return makeScalar(std::hypot(args[0].scalarValue.scalar, args[1].scalarValue.scalar));
    case BuiltinFunctionId::Random:
      return makeScalar(
          args[0].scalarValue.scalar + (args[1].scalarValue.scalar - args[0].scalarValue.scalar) *
              randomUnitScalar());
    case BuiltinFunctionId::Gcd:
    case BuiltinFunctionId::Lcm: {
      std::uint64_t aU = 0, bU = 0;
      if (tryGetExactNonNegativeUInt64FromScalar(args[0].scalarValue, aU) &&
          tryGetExactNonNegativeUInt64FromScalar(args[1].scalarValue, bU)) {
        if (id == BuiltinFunctionId::Gcd) {
          return makeScalarUInt(gcdUInt64(aU, bU));
        }
        std::uint64_t lU = 0;
        if (!tryLcmUInt64(aU, bU, lU)) {
          setNumericErrorInFunction(ctx, fnName);
          return makeScalar(0);
        }
        return makeScalarUInt(lU);
      }
      long long a = 0, b = 0;
      if (!tryGetSignedInt64FromScalar(args[0].scalarValue, a) ||
          !tryGetSignedInt64FromScalar(args[1].scalarValue, b)) {
        setIntegerValuesError(ctx, fnName);
        return makeScalar(0);
      }
      if (id == BuiltinFunctionId::Gcd) {
        return makeScalarInt(gcdInt64(a, b));
      }
      long long g = gcdInt64(a, b);
      if (g == 0) {
        return makeScalarInt(0);
      }
      long long l = 0;
      if (!tryMulInt64Checked(a / g, b, l)) {
        setNumericErrorInFunction(ctx, fnName);
        return makeScalar(0);
      }
      if (l < 0) {
        if (l == (std::numeric_limits<long long>::min)()) {
          setNumericErrorInFunction(ctx, fnName);
          return makeScalar(0);
        }
        l = -l;
      }
      return makeScalarInt(l);
    }
    case BuiltinFunctionId::Ncr:
    case BuiltinFunctionId::Npr: {
      long long n = 0, r = 0;
      if (!tryGetSignedInt64FromScalar(args[0].scalarValue, n) ||
          !tryGetSignedInt64FromScalar(args[1].scalarValue, r)) {
        setIntegerValuesError(ctx, fnName);
        return makeScalar(0);
      }
      long long out = 0;
      const bool ok = (id == BuiltinFunctionId::Npr) ? tryComputeNprInt64(n, r, out) : tryComputeNcrInt64(n, r, out);
      if (!ok) {
        setNumericErrorInFunction(ctx, fnName);
        return makeScalar(0);
      }
      return makeScalarInt(out);
    }
    default:
      break;
  }
  setInternalScalarBinaryBuiltinError(ctx);
  return makeScalar(0);
}

MathParser::EvalValue MathParser::builtinRand(EvalContext& ctx, const std::vector<EvalValue>& args) const {
  const std::string fnName = getFunctionName(BuiltinFunctionId::Rand);
  if (!args.empty()) {
    setExactArgCountError(ctx, fnName, 0);
    return makeScalar(0);
  }
  return makeScalar(randomUnitScalar());
}

MathParser::EvalValue MathParser::builtinModCall(EvalContext& ctx, const std::vector<EvalValue>& args) const {
  const std::string fnName = getFunctionName(BuiltinFunctionId::Mod);
  if (args.size() != 2) {
    setExactArgCountError(ctx, fnName, 2);
    return makeScalar(0);
  }
  auto applyModScalar = [&](const EvalValue::ScalarValue& aS, const EvalValue::ScalarValue& bS, EvalValue& outS) -> bool {
    if (aS.hasExactUInt64() && bS.hasExactUInt64() && (!aS.hasExactInt() || !bS.hasExactInt())) {
      if (bS.exactUInt64 == 0u) {
        setNumericErrorInFunction(ctx, fnName);
        return false;
      }
      outS = makeScalarUInt(aS.exactUInt64 % bS.exactUInt64);
      return true;
    }
    long long a = 0, b = 0;
    if (!tryGetSignedInt64FromScalar(aS, a) || !tryGetSignedInt64FromScalar(bS, b)) {
      setIntegerValuesError(ctx, fnName);
      return false;
    }
    if (b == 0) {
      setNumericErrorInFunction(ctx, fnName);
      return false;
    }
    outS = makeScalarInt(a % b);
    return true;
  };

  if (args[0].kind == ValueKind::Scalar && args[1].kind == ValueKind::Scalar) {
    EvalValue outS;
    if (!applyModScalar(args[0].scalarValue, args[1].scalarValue, outS)) {
      return makeScalar(0);
    }
    return outS;
  }

  if (args[0].kind == ValueKind::Array && args[1].kind == ValueKind::Array &&
      args[0].arr.size() != args[1].arr.size()) {
    setNumericErrorInFunction(ctx, fnName);
    return makeScalar(0);
  }

  const std::size_t outCount = (args[0].kind == ValueKind::Array) ? args[0].arr.size() : args[1].arr.size();
  scratchBinaryOut_.clear();
  scratchBinaryOut_.reserve(outCount);
  for (std::size_t i = 0; i < outCount; ++i) {
    const EvalValue::ScalarValue& aItem = (args[0].kind == ValueKind::Array) ? args[0].arr[i] : args[0].scalarValue;
    const EvalValue::ScalarValue& bItem = (args[1].kind == ValueKind::Array) ? args[1].arr[i] : args[1].scalarValue;
    EvalValue outS;
    if (!applyModScalar(aItem, bItem, outS)) {
      scratchBinaryOut_.clear();
      return makeScalar(0);
    }
    scratchBinaryOut_.emplace_back(std::move(outS));
  }
  EvalValue ret = makeArrayFromScalars(scratchBinaryOut_);
  scratchBinaryOut_.clear();
  return ret;
}

MathParser::EvalValue MathParser::builtinFactorial(
    EvalContext& ctx,
    const std::string& fnName,
    const std::vector<EvalValue>& args) const {
  static constexpr long long kFactorialTable[21] = {
      1LL,
      1LL,
      2LL,
      6LL,
      24LL,
      120LL,
      720LL,
      5040LL,
      40320LL,
      362880LL,
      3628800LL,
      39916800LL,
      479001600LL,
      6227020800LL,
      87178291200LL,
      1307674368000LL,
      20922789888000LL,
      355687428096000LL,
      6402373705728000LL,
      121645100408832000LL,
      2432902008176640000LL};
  if (args.size() != 1) {
    setExactArgCountError(ctx, fnName, 1);
    return makeScalar(0);
  }
  long long n = 0;
  if (args[0].kind != ValueKind::Scalar || !nearlyInt(args[0].scalarValue.scalar, n) || n < 0) {
    setNonNegativeIntegerError(ctx, fnName);
    return makeScalar(0);
  }
  if (n <= 20) {
    return makeScalarInt(kFactorialTable[n]);
  }
  double d = static_cast<double>(kFactorialTable[20]);
  for (long long i = 21; i <= n; ++i) {
    d *= static_cast<double>(i);
  }
  return makeScalar(d);
}

MathParser::EvalValue MathParser::builtinDegRad(
    EvalContext& ctx,
    const std::string& fnName,
    BuiltinFunctionId id,
    const std::vector<EvalValue>& args) const {
  if (args.empty()) {
    setAtLeastOneArgError(ctx, fnName);
    return makeScalar(0);
  }
  const bool toDeg = (id == BuiltinFunctionId::Deg);
  if (args.size() == 1) {
    if (args[0].kind == ValueKind::Scalar) {
      const double x = args[0].scalarValue.scalar;
      return makeScalarMaybeExact(toDeg ? (x * 180.0 / kPi) : (x * kPi / 180.0));
    }
    std::vector<EvalValue> outVals;
    outVals.reserve(args[0].arr.size());
    for (const auto& item : args[0].arr) {
      const double x = item.scalar;
      outVals.emplace_back(makeScalarMaybeExact(toDeg ? (x * 180.0 / kPi) : (x * kPi / 180.0)));
    }
    return makeArrayFromScalars(outVals);
  }
  std::vector<EvalValue> inVals;
  if (!flattenArgsToScalars(args, inVals)) {
    setAtLeastOneArgError(ctx, fnName);
    return makeScalar(0);
  }
  std::vector<EvalValue> outVals;
  outVals.reserve(inVals.size());
  for (const auto& item : inVals) {
    const double x = item.scalarValue.scalar;
    outVals.emplace_back(makeScalarMaybeExact(toDeg ? (x * 180.0 / kPi) : (x * kPi / 180.0)));
  }
  return makeArrayFromScalars(outVals);
}

MathParser::EvalValue MathParser::calcRoundingFn(BuiltinFunctionId id, const EvalValue::ScalarValue& s)
{
  const double x = s.scalar;
  if (!std::isfinite(x))
    return makeScalar(x);

  if (s.hasExactUInt64())
    return makeScalarUInt(s.exactUInt64);

  if (s.hasExactInt())
    return makeScalarInt(s.exactInt);

  if (x > K_MAX_EXACT_INT_FROM_DOUBLE || x < -K_MAX_EXACT_INT_FROM_DOUBLE)
  {
    if (x <= (std::numeric_limits<long long>::max)() && x >= (std::numeric_limits<long long>::min)())
      return makeScalarInt(static_cast<long long>(x));

    const double p64 = std::ldexp(1.0, 64);
    if (x >= 0.0 && x < p64 && x == std::trunc(x)) {
      const std::uint64_t u = static_cast<std::uint64_t>(x);
      if (static_cast<double>(u) == x)
        return makeScalarUInt(u);
    }

    switch (id) {
      case BuiltinFunctionId::Floor: return makeScalar(std::floor(x));
      case BuiltinFunctionId::Ceil: return makeScalar(std::ceil(x));
      case BuiltinFunctionId::Trunc:
      case BuiltinFunctionId::Int: return makeScalar(std::trunc(x));
      case BuiltinFunctionId::Round: return makeScalar(std::round(x));
      default: return makeScalar(x);
    }
  }

  long long rounded = 0;
  switch (id) {
    case BuiltinFunctionId::Floor:
      rounded = static_cast<long long>(std::floor(x));
      break;
    case BuiltinFunctionId::Ceil:
      rounded = static_cast<long long>(std::ceil(x));
      break;
    case BuiltinFunctionId::Trunc:
    case BuiltinFunctionId::Int:
      rounded = static_cast<long long>(std::trunc(x));
      break;
    case BuiltinFunctionId::Round:
      rounded = static_cast<long long>(std::round(x));
      break;
    default:
      break;
  }
  return makeScalarInt(rounded);
}

MathParser::EvalValue MathParser::builtinUnaryMath(
    EvalContext& ctx,
    const std::string& fnName,
    BuiltinFunctionId id,
    const std::vector<EvalValue>& args) const {
  if (args.size() != 1) {
    setExactArgCountError(ctx, fnName, 1);
    return makeScalar(0);
  }
  if (args[0].kind == ValueKind::Scalar) {
    const EvalValue::ScalarValue& s = args[0].scalarValue;
    const double x = s.scalar;
    switch (id) {
      case BuiltinFunctionId::Sin: return makeScalarMaybeExact(calcSin(x));
      case BuiltinFunctionId::Cos: return makeScalarMaybeExact(calcCos(x));
      case BuiltinFunctionId::Tan: return makeScalarMaybeExact(calcTan(x));
      case BuiltinFunctionId::Asin:
      case BuiltinFunctionId::Arcsin: return makeScalarMaybeExact(std::asin(x));
      case BuiltinFunctionId::Acos:
      case BuiltinFunctionId::Arccos: return makeScalarMaybeExact(std::acos(x));
      case BuiltinFunctionId::Atan:
      case BuiltinFunctionId::Arctan: return makeScalarMaybeExact(std::atan(x));
      case BuiltinFunctionId::Sinh: return makeScalarMaybeExact(std::sinh(x));
      case BuiltinFunctionId::Cosh: return makeScalarMaybeExact(std::cosh(x));
      case BuiltinFunctionId::Tanh: return makeScalarMaybeExact(std::tanh(x));
      case BuiltinFunctionId::Acosh: return makeScalarMaybeExact(std::acosh(x));
      case BuiltinFunctionId::Asinh: return makeScalarMaybeExact(std::asinh(x));
      case BuiltinFunctionId::Atanh: return makeScalarMaybeExact(std::atanh(x));
      case BuiltinFunctionId::Exp: return makeScalarMaybeExact(std::exp(x));
      case BuiltinFunctionId::Log10: return makeScalarMaybeExact(std::log10(x));
      case BuiltinFunctionId::Ln: return makeScalarMaybeExact(std::log(x));
      case BuiltinFunctionId::Sqrt: return makeScalarMaybeExact(std::sqrt(x));
      case BuiltinFunctionId::Sqr: return makeScalarMaybeExact(x * x);
      case BuiltinFunctionId::Abs: return makeScalarMaybeExact(std::fabs(x));
      case BuiltinFunctionId::Floor:
      case BuiltinFunctionId::Ceil:
      case BuiltinFunctionId::Trunc:
      case BuiltinFunctionId::Int:
      case BuiltinFunctionId::Round: return calcRoundingFn(id, s);
      case BuiltinFunctionId::Sign:
        if (s.hasExactInt()) return makeScalarInt((s.exactInt > 0) ? 1LL : ((s.exactInt < 0) ? -1LL : 0LL));
        if (s.hasExactUInt64()) return makeScalarInt((s.exactUInt64 == 0u) ? 0LL : 1LL);
        return makeScalarInt((x > 0.0) ? 1LL : ((x < 0.0) ? -1LL : 0LL));
      case BuiltinFunctionId::Frac:
      case BuiltinFunctionId::Fract: return makeScalarMaybeExact(x - std::trunc(x));
      default: break;
    }
  }
  switch (id) {
    case BuiltinFunctionId::Sin:
      return mapUnaryFn(args[0], calcSin);
    case BuiltinFunctionId::Cos:
      return mapUnaryFn(args[0], calcCos);
    case BuiltinFunctionId::Tan:
      return mapUnaryFn(args[0], calcTan);
    case BuiltinFunctionId::Asin:
    case BuiltinFunctionId::Arcsin:
      return mapUnaryFn(args[0], std::asin);
    case BuiltinFunctionId::Acos:
    case BuiltinFunctionId::Arccos:
      return mapUnaryFn(args[0], std::acos);
    case BuiltinFunctionId::Atan:
    case BuiltinFunctionId::Arctan:
      return mapUnaryFn(args[0], std::atan);
    case BuiltinFunctionId::Sinh:
      return mapUnaryFn(args[0], std::sinh);
    case BuiltinFunctionId::Cosh:
      return mapUnaryFn(args[0], std::cosh);
    case BuiltinFunctionId::Tanh:
      return mapUnaryFn(args[0], std::tanh);
    case BuiltinFunctionId::Acosh:
      return mapUnaryFn(args[0], std::acosh);
    case BuiltinFunctionId::Asinh:
      return mapUnaryFn(args[0], std::asinh);
    case BuiltinFunctionId::Atanh:
      return mapUnaryFn(args[0], std::atanh);
    case BuiltinFunctionId::Exp:
      return mapUnaryFn(args[0], std::exp);
    case BuiltinFunctionId::Log10:
      return mapUnaryFn(args[0], std::log10);
    case BuiltinFunctionId::Ln:
      return mapUnaryFn(args[0], std::log);
    case BuiltinFunctionId::Sqrt:
      return mapUnaryFn(args[0], std::sqrt);
    case BuiltinFunctionId::Sqr:
      return mapUnaryFn(args[0], squareScalar);
    case BuiltinFunctionId::Abs:
      {
        std::vector<EvalValue> outVals;
        outVals.reserve(args[0].arr.size());
        for (const auto& e : args[0].arr) {
          if (e.hasExactUInt64()) {
            outVals.emplace_back(makeScalarUInt(e.exactUInt64));
          } else {
            outVals.emplace_back(makeScalarMaybeExact(std::fabs(e.scalar)));
          }
        }
        return makeArrayFromScalars(outVals);
      }
    case BuiltinFunctionId::Floor:
    case BuiltinFunctionId::Ceil:
    case BuiltinFunctionId::Trunc:
    case BuiltinFunctionId::Int:
    case BuiltinFunctionId::Round:
    case BuiltinFunctionId::Sign: {
      auto applyIntLikeUnaryToScalar = [&](const EvalValue::ScalarValue& sItem) -> EvalValue {
        const double x = sItem.scalar;
        if (id == BuiltinFunctionId::Sign) {
          if (sItem.hasExactInt()) return makeScalarInt((sItem.exactInt > 0) ? 1LL : ((sItem.exactInt < 0) ? -1LL : 0LL));
          if (sItem.hasExactUInt64()) return makeScalarInt((sItem.exactUInt64 == 0u) ? 0LL : 1LL);
          return makeScalarInt((x > 0.0) ? 1LL : ((x < 0.0) ? -1LL : 0LL));
        }
        return calcRoundingFn(id, sItem);
      };
      if (args[0].kind == ValueKind::Scalar) {
        return applyIntLikeUnaryToScalar(args[0].scalarValue);
      }
      std::vector<EvalValue> outVals;
      outVals.reserve(args[0].arr.size());
      for (const auto& e : args[0].arr) {
        outVals.emplace_back(applyIntLikeUnaryToScalar(e));
      }
      return makeArrayFromScalars(outVals);
    }
    case BuiltinFunctionId::Frac:
    case BuiltinFunctionId::Fract:
      return mapUnaryFn(args[0], fracScalar);
    default:
      break;
  }
  setInternalUnaryMathBuiltinError(ctx);
  return makeScalar(0);
}

MathParser::EvalValue MathParser::builtinApplyClamp(
    EvalContext& ctx,
    const EvalValue& valueV,
    const EvalValue& minV,
    const EvalValue& maxV) const {
  if (minV.kind != ValueKind::Scalar || maxV.kind != ValueKind::Scalar) {
    setScalarMinMaxError(ctx, getFunctionName(BuiltinFunctionId::Clamp));
    return makeScalar(0);
  }
  if (valueV.kind == ValueKind::Scalar) {
    return makeScalar(clampDouble(valueV.scalarValue.scalar, minV.scalarValue.scalar, maxV.scalarValue.scalar));
  }
  if (valueV.kind == ValueKind::Array) {
    const double minS = minV.scalarValue.scalar;
    const double maxS = maxV.scalarValue.scalar;
    scratchClampOut_.clear();
    scratchClampOut_.reserve(valueV.arr.size());
    for (const auto& item : valueV.arr) {
      scratchClampOut_.emplace_back(makeScalar(clampDouble(item.scalar, minS, maxS)));
    }
    EvalValue ret = makeArrayFromScalars(scratchClampOut_);
    scratchClampOut_.clear();
    return ret;
  }
  setNumericErrorInFunction(ctx, getFunctionName(BuiltinFunctionId::Clamp));
  return makeScalar(0);
}

MathParser::EvalValue MathParser::builtinLog(EvalContext& ctx, const std::vector<EvalValue>& args) const {
  const std::string fnName = getFunctionName(BuiltinFunctionId::Log);
  if (args.size() != 2) {
    setExactArgCountError(ctx, fnName, 2);
    return makeScalar(0);
  }
  bool ok = false;
  EvalValue out = mapBinaryBuiltinMathFunction(args[0], args[1], BuiltinFunctionId::Log, ok);
  if (!ok) {
    setNumericErrorInFunction(ctx, fnName);
    return makeScalar(0);
  }
  return out;
}

MathParser::EvalValue MathParser::evalUserFunctionCall(
    EvalContext& ctx,
    const std::string& fnName,
    const std::vector<EvalValue>& args,
    const std::unordered_map<std::string, EvalValue>* /*scopedVars*/) {
  UserFunction* uf = findUserFunction(fnName);
  if (!uf) {
    appendUniqueName(ctx.unknownFuncsText, fnName);
    return makeScalar(0);
  }
  if (args.size() != uf->params.size()) {
    setExactArgCountError(ctx, fnName, uf->params.size());
    return makeScalar(0);
  }
  if (ctx.evalDepth >= kMaxEvalDepth) {
    setMaxEvaluationDepthReachedError(ctx);
    return makeScalar(0);
  }

  for (const std::string& active : userFunctionCallStack_) {
    if (active == fnName) {
      setRecursiveUserFunctionCallError(ctx, fnName);
      return makeScalar(0);
    }
  }
  if (userFunctionCallStack_.size() >= static_cast<std::size_t>(kMaxEvalDepth)) {
    setUserFunctionCallStackOverflowError(ctx);
    return makeScalar(0);
  }
  userFunctionCallStack_.push_back(fnName);
  struct UserFnCallPopGuard {
    std::vector<std::string>& stack;
    explicit UserFnCallPopGuard(std::vector<std::string>& s) : stack(s) {}
    ~UserFnCallPopGuard() { stack.pop_back(); }
  } popGuard{userFunctionCallStack_};

  std::unordered_map<std::string, EvalValue> localVars;
  localVars.reserve(uf->params.size());
  for (std::size_t i = 0; i < uf->params.size(); ++i) {
    localVars.emplace(uf->params[i], args[i]);
  }

  if (!uf->compiledProgramReady) {
    EvalContext parseCtx;
    parseCtx.p = uf->expr.c_str();
    parseCtx.start = parseCtx.p;
    parseCtx.sourceExpr = uf->expr;
    std::vector<AstStatement> compiledBody;
    if (!parseProgram(parseCtx, compiledBody)) {
      setError(ctx, parseCtx.errorText.empty() ? STR_FAILED_TO_PARSE_USER_FUNCTION_BODY : parseCtx.errorText);
      return makeScalar(0);
    }
    skipSpaces(parseCtx);
    if (!parseCtx.parseError && *parseCtx.p != '\0') {
      setUnexpectedInputError(ctx);
      return makeScalar(0);
    }
    uf->compiledProgram = std::move(compiledBody);
    uf->compiledProgramReady = true;
  }

  EvalContext sub;
  sub.evalDepth = ctx.evalDepth + 1;
  EvalValue v = runCompiledProgram(sub, uf->compiledProgram, &localVars, false);
  if (sub.parseError) {
    setError(ctx, sub.errorText);
    return makeScalar(0);
  }
  mergeUnknownNameList(ctx.unknownVarsText, sub.unknownVarsText);
  mergeUnknownNameList(ctx.unknownFuncsText, sub.unknownFuncsText);
  return v;
}

MathParser::EvalValue MathParser::evalFunctionCall(
    EvalContext& ctx,
    const std::string& fnName,
    std::vector<EvalValue>&& args,
    BuiltinFunctionId preboundId,
    const std::unordered_map<std::string, EvalValue>* scopedVars) {
  normalizeCallArgs(args);

  BuiltinFunctionId id = preboundId;
  if (id == BuiltinFunctionId::Count && !tryGetBuiltinFunctionId(fnName, id)) {
    return evalUserFunctionCall(ctx, fnName, args, scopedVars);
  }
  if (!validateBuiltinArgs(ctx, fnName, id, args)) {
    return makeScalar(0);
  }

  switch (id) {
    case BuiltinFunctionId::Unpack:
      return builtinUnpack(ctx, args);
    case BuiltinFunctionId::Sum:
    case BuiltinFunctionId::Product:
    case BuiltinFunctionId::Prod:
    case BuiltinFunctionId::Min:
    case BuiltinFunctionId::Max:
    case BuiltinFunctionId::Avg:
    case BuiltinFunctionId::Mean:
    case BuiltinFunctionId::Median:
    case BuiltinFunctionId::Variance:
    case BuiltinFunctionId::Stddev:
      return builtinAggregateFamily(ctx, fnName, id, args);
    case BuiltinFunctionId::Sort:
    case BuiltinFunctionId::Sorted:
    case BuiltinFunctionId::Reverse:
    case BuiltinFunctionId::Reversed:
    case BuiltinFunctionId::Unique:
      return builtinSortFamily(ctx, fnName, id, args);
    case BuiltinFunctionId::Hex:
    case BuiltinFunctionId::Oct:
    case BuiltinFunctionId::Bin:
    case BuiltinFunctionId::Uhex:
    case BuiltinFunctionId::Uoct:
    case BuiltinFunctionId::Ubin:
      return builtinBaseFormat(ctx, fnName, id, args);
    case BuiltinFunctionId::Pow:
      return builtinPow(ctx, args);
    case BuiltinFunctionId::Atan2:
    case BuiltinFunctionId::Hypot:
    case BuiltinFunctionId::Gcd:
    case BuiltinFunctionId::Lcm:
    case BuiltinFunctionId::Ncr:
    case BuiltinFunctionId::Npr:
    case BuiltinFunctionId::Random:
    case BuiltinFunctionId::Clamp:
      return builtinScalarBinaryFamily(ctx, fnName, id, args);
    case BuiltinFunctionId::Rand:
      return builtinRand(ctx, args);
    case BuiltinFunctionId::Mod:
      return builtinModCall(ctx, args);
    case BuiltinFunctionId::Fact:
    case BuiltinFunctionId::Factorial:
      return builtinFactorial(ctx, fnName, args);
    case BuiltinFunctionId::Deg:
    case BuiltinFunctionId::Rad:
      return builtinDegRad(ctx, fnName, id, args);
    case BuiltinFunctionId::Log:
      return builtinLog(ctx, args);
    case BuiltinFunctionId::Sin:
    case BuiltinFunctionId::Cos:
    case BuiltinFunctionId::Tan:
    case BuiltinFunctionId::Asin:
    case BuiltinFunctionId::Arcsin:
    case BuiltinFunctionId::Acos:
    case BuiltinFunctionId::Arccos:
    case BuiltinFunctionId::Atan:
    case BuiltinFunctionId::Arctan:
    case BuiltinFunctionId::Sinh:
    case BuiltinFunctionId::Cosh:
    case BuiltinFunctionId::Tanh:
    case BuiltinFunctionId::Acosh:
    case BuiltinFunctionId::Asinh:
    case BuiltinFunctionId::Atanh:
    case BuiltinFunctionId::Exp:
    case BuiltinFunctionId::Log10:
    case BuiltinFunctionId::Ln:
    case BuiltinFunctionId::Sqrt:
    case BuiltinFunctionId::Sqr:
    case BuiltinFunctionId::Abs:
    case BuiltinFunctionId::Floor:
    case BuiltinFunctionId::Ceil:
    case BuiltinFunctionId::Trunc:
    case BuiltinFunctionId::Int:
    case BuiltinFunctionId::Frac:
    case BuiltinFunctionId::Fract:
    case BuiltinFunctionId::Round:
    case BuiltinFunctionId::Sign:
      return builtinUnaryMath(ctx, fnName, id, args);
    case BuiltinFunctionId::Count:
      break;
  }
  appendUniqueName(ctx.unknownFuncsText, fnName);
  return makeScalar(0);
}

bool MathParser::compile(const std::string& mathExpression) {
  resetCompileState();

  EvalContext ctx;
  ctx.sourceExpr = stripLineComments(mathExpression);
  ctx.p = ctx.sourceExpr.c_str();
  ctx.start = ctx.p;

  std::vector<AstStatement> program;
  if (!parseProgram(ctx, program)) {
    if (!ctx.parseError) {
      setParseFailedError(ctx);
    }
    lastError_ = ctx.errorText;
    return false;
  }
  skipSpaces(ctx);
  if (!ctx.parseError && *ctx.p != '\0') {
    setUnexpectedInputError(ctx);
  }
  if (ctx.parseError) {
    lastError_ = ctx.errorText;
    compiledProgram_.clear();
    return false;
  }
  compiledProgram_ = std::move(program);
  compiledHasAssignments_ = std::any_of(
      compiledProgram_.begin(),
      compiledProgram_.end(),
      [](const AstStatement& st) { return st.kind == AstStatement::Kind::Assign; });
  bindCompiledVariableRefs();
  compiledScalarOnly_ = programIsScalarOnly(compiledProgram_);
  hasCompiledProgram_ = true;
  return true;
}

void MathParser::evaluate() {
  resetEvaluateState();

  EvalContext ctx;
  if (!prepareEvaluate(ctx)) {
    return;
  }
  EvalValue out = runCompiledProgram(ctx, compiledProgram_, nullptr, compiledScalarOnly_);
  finalizeEvaluate(ctx, std::move(out));
}

void MathParser::resetCompileState() {
  hasResult_ = false;
  lastError_.clear();
  compiledProgram_.clear();
  hasCompiledProgram_ = false;
  compiledScalarOnly_ = false;
  compiledHasAssignments_ = false;
  boundVariablesVersion_ = static_cast<std::size_t>(-1);
}

void MathParser::resetEvaluateState() {
  hasResult_ = false;
  lastError_.clear();
  lastResult_ = makeScalar(0);
  userFunctionCallStack_.clear();
}

bool MathParser::prepareEvaluate(EvalContext& ctx) {
  ctx.start = nullptr;
  ctx.p = nullptr;
  if (!hasCompiledProgram_) {
    lastError_ = STR_NOTHING_COMPILED_SEMICOLON_CALL_COMPILE_PAR;
    return false;
  }
  if (boundVariablesVersion_ != variablesVersion_) {
    bindCompiledVariableRefs();
  }
  if (compiledProgram_.empty()) {
    return false;
  }
  return true;
}

bool MathParser::finalizeEvaluate(EvalContext& ctx, EvalValue&& out) {
  if (ctx.parseError) {
    lastError_ = ctx.errorText;
    return false;
  }
  if (trySetUnknownNameError(ctx)) {
    return false;
  }
  lastResult_ = std::move(out);
  hasResult_ = true;
  return true;
}

void MathParser::parseAndEvaluate(const std::string& mathExpression) {
  if (!compile(mathExpression)) {
    return;
  }
  evaluate();
}

MathParser::RawResult MathParser::parseAndEvaluateRaw(const std::string& mathExpression) {
  if (!compile(mathExpression)) {
    return RawResult{};
  }
  evaluate();
  if (!lastError_.empty() || !hasResult_) {
    return RawResult{};
  }
  return toRawResult(lastResult_);
}

std::string MathParser::addUserFunction(const std::string& mathExpression) {
  EvalContext ctx;
  ctx.sourceExpr = stripLineComments(mathExpression);
  ctx.p = ctx.sourceExpr.c_str();
  ctx.start = ctx.p;

  std::string fnName;
  std::vector<std::string> fnParams;
  std::string fnExpr;
  if (!parseFunctionDefinition(ctx, fnName, fnParams, fnExpr)) {
    return STR_INVALID_USER_FUNCTION_EXPRESSION;
  }

  skipSpaces(ctx);
  if (*ctx.p != '\0') {
    return STR_UNEXPECTED_CONTENT_AFTER_FUNCTION_DEFINITION;
  }

  const std::string udfErr = getUserFunctionDefinitionErrorText(fnName, fnParams, fnExpr, true);
  if (!udfErr.empty()) return udfErr;

  upsertUserFunction(UserFunction{fnName, fnParams, fnExpr});
  return "";
}

MathParser::UserFunction* MathParser::findUserFunction(const std::string& fnName) {
  auto it = userFunctionIndex_.find(fnName);
  if (it == userFunctionIndex_.end()) {
    return nullptr;
  }
  return &userFunctions_[it->second];
}

const MathParser::UserFunction* MathParser::findUserFunction(const std::string& fnName) const {
  auto it = userFunctionIndex_.find(fnName);
  if (it == userFunctionIndex_.end()) {
    return nullptr;
  }
  return &userFunctions_[it->second];
}

void MathParser::upsertUserFunction(UserFunction uf) {
  uf.compiledProgram.clear();
  uf.compiledProgramReady = false;
  auto it = userFunctionIndex_.find(uf.name);
  if (it != userFunctionIndex_.end()) {
    userFunctions_[it->second] = std::move(uf);
    return;
  }
  userFunctions_.push_back(std::move(uf));
  userFunctionIndex_[userFunctions_.back().name] = userFunctions_.size() - 1;
}
