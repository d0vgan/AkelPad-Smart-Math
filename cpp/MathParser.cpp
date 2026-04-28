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
constexpr const char* STR_HINT_SIN = "function: sin(angle)";
constexpr const char* STR_HINT_POW = "function: pow(base, exp)";
constexpr const char* STR_HINT_SQR = "function: sqr(value)";
constexpr const char* STR_HINT_LN = "function: ln(value)";
constexpr const char* STR_HINT_HEX = "function: hex(...)";
constexpr const char* STR_HINT_BIN = "function: bin(...)";
constexpr const char* STR_HINT_OCT = "function: oct(...)";
constexpr const char* STR_HINT_UHEX = "function: uhex(...)";
constexpr const char* STR_HINT_UBIN = "function: ubin(...)";
constexpr const char* STR_HINT_UOCT = "function: uoct(...)";
constexpr const char* STR_HINT_SUM = "function: sum(...)";
constexpr const char* STR_HINT_SORT = "function: sort(...)";
constexpr const char* STR_HINT_REVERSE = "function: reverse(...)";
constexpr const char* STR_HINT_UNIQUE = "function: unique(...)";
constexpr const char* STR_HINT_UNPACK = "function: unpack(...)";
constexpr const char* STR_HINT_RAND = "function: rand()";
constexpr const char* STR_HINT_RANDOM = "function: random(min, max)";
constexpr const char* STR_HINT_MEAN = "function: mean(...)";
constexpr const char* STR_HINT_MEDIAN = "function: median(...)";
constexpr const char* STR_HINT_FLOOR = "function: floor(value)";
constexpr const char* STR_HINT_CEIL = "function: ceil(value)";
constexpr const char* STR_HINT_TRUNC = "function: trunc(value)";
constexpr const char* STR_HINT_ROUND = "function: round(value)";
constexpr const char* STR_HINT_SIGN = "function: sign(value)";
constexpr const char* STR_HINT_DEG = "function: deg(...)";
constexpr const char* STR_HINT_RAD = "function: rad(...)";
constexpr const char* STR_HINT_INT = "function: int(value)";
constexpr const char* STR_HINT_FRAC = "function: frac(value)";
constexpr const char* STR_HINT_PREFIX = "function: ";
constexpr const char* STR_PAR_DOTDOTDOT = "(...)";
constexpr const char* STR_UNEXPECTED_TOKEN = "unexpected token";
constexpr const char* STR_INCOMPATIBLE_OPERANDS = "incompatible operands";
constexpr const char* STR_POS_POW63_DEC_TEXT = "9.223372036854778e+018";
constexpr const char* STR_NEG_POW63_DEC_TEXT = "-9.223372036854778e+018";
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
constexpr const char* STR_RECURSIVE_USER_FUNCTION_CALL_COLON = "recursive user function call: ";
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
constexpr const char* STR_PAR_EXPECTS_2_ARGUMENT_PAR = "() expects 2 argument(s)";
constexpr const char* STR_NUMERIC_ERROR_IN = "numeric error in ";
constexpr const char* STR_PAR = "()";
constexpr const char* STR_PAR_EXPECTS_3_ARGUMENT_PAR = "() expects 3 argument(s)";
constexpr const char* STR_PAR_EXPECTS_SCALAR_MIN_SLASH = "() expects scalar min/max";
constexpr const char* STR_PAR_EXPECTS_SCALAR_VALUES = "() expects scalar values";
constexpr const char* STR_INTERNAL_ERROR_IN_SCALAR_BINARY_BUILTIN = "internal error in scalar binary builtin";
constexpr const char* STR_PAR_EXPECTS_0_ARGUMENT_PAR = "() expects 0 argument(s)";
constexpr const char* STR_PAR_EXPECTS_1_ARGUMENT_PAR = "() expects 1 argument(s)";
constexpr const char* STR_PAR_EXPECTS_A_NON_DASH = "() expects a non-negative integer";
constexpr const char* STR_INTERNAL_ERROR_IN_UNARY_MATH_BUILTIN = "internal error in unary math builtin";
constexpr const char* STR_NUMERIC_ERROR_IN_CLAMP_PAR = "numeric error in clamp()";
constexpr const char* STR_PAR_EXPECTS = "() expects ";
constexpr const char* STR_ARGUMENT_PAR_S = " argument(s)";
constexpr const char* STR_MAX_EVALUATION_DEPTH_REACHED = "max evaluation depth reached";
constexpr const char* STR_USER_FUNCTION_CALL_STACK_OVERFLOW = "user function call stack overflow";
constexpr const char* STR_FAILED_TO_PARSE_USER_FUNCTION_BODY = "failed to parse user function body";
constexpr const char* STR_UNEXPECTED_TRAILING_INPUT = "unexpected trailing input";
constexpr const char* STR_PARSE_FAILED = "parse failed";
constexpr const char* STR_NOTHING_COMPILED_SEMICOLON_CALL_COMPILE_PAR = "nothing compiled; call compile() first";
constexpr const char* STR_UNKNOWN_VARIABLE_COLON = "unknown variable: ";
constexpr const char* STR_SEMICOLON_UNKNOWN_FUNCTION_COLON = "; unknown function: ";
constexpr const char* STR_UNKNOWN_FUNCTION_COLON = "unknown function: ";
constexpr const char* STR_INVALID_USER_FUNCTION_EXPRESSION = "invalid user function expression";
constexpr const char* STR_UNEXPECTED_CONTENT_AFTER_FUNCTION_DEFINITION = "unexpected content after function definition";

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
    v = v * 10u + digit;
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
  setVariable(STR_ANS, makeScalarInt(0));
}

std::string MathParser::toLower(std::string s) {
  std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
  return s;
}

const std::vector<std::string>& MathParser::functionNames() {
  static const std::vector<std::string> kNames = {
      STR_RAND,   STR_RANDOM, STR_BIN,   STR_HEX,    STR_OCT,      STR_POW,  STR_ATAN2, STR_SIN,      STR_COS,  STR_TAN,
      STR_ASIN,   STR_ARCSIN, STR_ACOS,  STR_ARCCOS, STR_ATAN,     STR_ARCTAN, STR_SINH, STR_COSH,     STR_TANH, STR_EXP,
      STR_LOG,    STR_LN,     STR_LOG10, STR_SQRT,   STR_SQR,      STR_INT,  STR_FRAC,  STR_FRACT,    STR_ABS,  STR_FLOOR,
      STR_CEIL,   STR_TRUNC,  STR_ROUND, STR_SIGN,   STR_DEG,      STR_RAD,  STR_SUM,   STR_MEDIAN,   STR_VARIANCE, STR_STDDEV,
      STR_SORT,   STR_SORTED, STR_REVERSE, STR_REVERSED, STR_UNIQUE, STR_UNPACK, STR_FACT, STR_FACTORIAL, STR_AVG, STR_MEAN,
      STR_MOD,    STR_CLAMP,  STR_HYPOT, STR_GCD,    STR_LCM,      STR_PRODUCT, STR_PROD, STR_MIN, STR_MAX,
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

const char* MathParser::tryGetBuiltinFunctionMissingCallHint(const std::string& nameText) {
  static const std::unordered_map<std::string, const char*> kHints = {
      {STR_SIN, STR_HINT_SIN},
      {STR_POW, STR_HINT_POW},
      {STR_SQR, STR_HINT_SQR},
      {STR_LN, STR_HINT_LN},
      {STR_HEX, STR_HINT_HEX},
      {STR_BIN, STR_HINT_BIN},
      {STR_OCT, STR_HINT_OCT},
      {STR_UHEX, STR_HINT_UHEX},
      {STR_UBIN, STR_HINT_UBIN},
      {STR_UOCT, STR_HINT_UOCT},
      {STR_SUM, STR_HINT_SUM},
      {STR_SORT, STR_HINT_SORT},
      {STR_SORTED, STR_HINT_SORT},
      {STR_REVERSE, STR_HINT_REVERSE},
      {STR_REVERSED, STR_HINT_REVERSE},
      {STR_UNIQUE, STR_HINT_UNIQUE},
      {STR_UNPACK, STR_HINT_UNPACK},
      {STR_RAND, STR_HINT_RAND},
      {STR_RANDOM, STR_HINT_RANDOM},
      {STR_MEAN, STR_HINT_MEAN},
      {STR_MEDIAN, STR_HINT_MEDIAN},
      {STR_FLOOR, STR_HINT_FLOOR},
      {STR_CEIL, STR_HINT_CEIL},
      {STR_TRUNC, STR_HINT_TRUNC},
      {STR_ROUND, STR_HINT_ROUND},
      {STR_SIGN, STR_HINT_SIGN},
      {STR_DEG, STR_HINT_DEG},
      {STR_RAD, STR_HINT_RAD},
      {STR_INT, STR_HINT_INT},
      {STR_FRAC, STR_HINT_FRAC},
      {STR_FRACT, STR_HINT_FRAC},
  };
  auto it = kHints.find(nameText);
  return (it != kHints.end()) ? it->second : nullptr;
}

bool MathParser::isOpKeyword(const std::string& nameText, OperatorNameId id) {
  return nameText == opName(id);
}

bool MathParser::isReservedFunctionName(const std::string& nameText) {
  BuiltinFunctionId id = BuiltinFunctionId::Count;
  return tryGetBuiltinFunctionId(nameText, id)
      || isOpKeyword(nameText, OperatorNameId::Not)
      || isOpKeyword(nameText, OperatorNameId::And)
      || isOpKeyword(nameText, OperatorNameId::Or);
}

bool MathParser::isTrailingFormatterFunctionName(const std::string& nameText) {
  BuiltinFunctionId id = BuiltinFunctionId::Count;
  if (!tryGetBuiltinFunctionId(nameText, id)) {
    return false;
  }
  return id == BuiltinFunctionId::Hex || id == BuiltinFunctionId::Oct || id == BuiltinFunctionId::Bin
      || id == BuiltinFunctionId::Uhex || id == BuiltinFunctionId::Uoct || id == BuiltinFunctionId::Ubin;
}

bool MathParser::trySetMissingFunctionCallError(EvalContext& ctx, const std::string& ident) const {
  BuiltinFunctionId bid = BuiltinFunctionId::Count;
  if (!tryGetBuiltinFunctionId(ident, bid)) {
    return false;
  }
  const char* hint = tryGetBuiltinFunctionMissingCallHint(ident);
  if (hint != nullptr) setError(ctx, hint);
  else setError(ctx, STR_HINT_PREFIX + ident + STR_PAR_DOTDOTDOT);
  return true;
}

bool MathParser::handleUnknownIdentifier(EvalContext& ctx, const std::string& ident, std::string& unknownList) const {
  if (isOpKeyword(ident, OperatorNameId::And) || isOpKeyword(ident, OperatorNameId::Or)) {
    setError(ctx, STR_UNEXPECTED_TOKEN);
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
      out = it->second;
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

static bool isReservedBuiltinConstantName(const std::string& nameText) {
  return nameText == STR_PI || nameText == STR_E;
}

bool MathParser::isIdentStart(char c) {
  return std::isalpha(static_cast<unsigned char>(c)) || c == '_';
}

bool MathParser::isIdentChar(char c) {
  return std::isalnum(static_cast<unsigned char>(c)) || c == '_';
}

void MathParser::skipSpaces(EvalContext& ctx) {
  while (*ctx.p && std::isspace(static_cast<unsigned char>(*ctx.p))) {
    ++ctx.p;
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

bool MathParser::isTruthy(const EvalValue& v) {
  if (v.kind == ValueKind::Array) {
    return !v.arr.empty();
  }
  return std::fabs(v.scalarValue.scalar) > 0.0;
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

bool MathParser::tryGetExactSignedInt64FromScalar(const EvalValue::ScalarValue& s, long long& outI) {
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

bool MathParser::tryGetSignedInt64FromScalar(const EvalValue::ScalarValue& s, long long& outI) {
  if (tryGetExactSignedInt64FromScalar(s, outI)) {
    return true;
  }
  return nearlyInt(s.scalar, outI);
}

bool MathParser::isPureFloatingScalarPair(const EvalValue::ScalarValue& a, const EvalValue::ScalarValue& b) {
  return (a.scalarKind == ScalarKind::FloatingPoint) && (b.scalarKind == ScalarKind::FloatingPoint) &&
      !a.hasExactInt() && !a.hasExactUInt64() && !b.hasExactInt() && !b.hasExactUInt64();
}

MathParser::EvalValue MathParser::makeBinaryNumericError(
    EvalContext& ctx,
    const EvalValue& left,
    const EvalValue& right,
    const char* numericErrorText) {
  if (left.kind == ValueKind::Array && right.kind == ValueKind::Array && left.arr.size() != right.arr.size()) {
    setError(ctx, STR_INCOMPATIBLE_OPERANDS);
  } else {
    setError(ctx, numericErrorText);
  }
  return makeScalar(0);
}

bool MathParser::parseUInt64FromDouble(double v, std::uint64_t& out) {
  if (!std::isfinite(v) || v < 0.0) {
    return false;
  }
  double r = std::round(v);
  if (std::fabs(v - r) > 1e-12) {
    return false;
  }
  if (r > static_cast<double>(std::numeric_limits<std::uint64_t>::max())) {
    return false;
  }
  out = static_cast<std::uint64_t>(r);
  return true;
}

std::string MathParser::formatScalar(const EvalValue& v, RenderBase base) {
  const double dval = v.scalarValue.scalar;
  if (base == RenderBase::Dec) {
    if (v.scalarValue.hasExactInt()) {
      return std::to_string(v.scalarValue.exactInt);
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
    if (v.scalarValue.hasExactUInt64() && v.scalarValue.exactUInt64 == (1ull << 63)) {
      return STR_POS_POW63_DEC_TEXT;
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
    if (v.hasRenderUnsigned()) {
      if (base == RenderBase::Hex) {
        return formatUnsignedBase(static_cast<std::uint64_t>(iv), 16, STR_PREFIX_HEX, true);
      }
      if (base == RenderBase::Oct) {
        return formatUnsignedBase(static_cast<std::uint64_t>(iv), 8, STR_PREFIX_OCT, false);
      }
      return formatUnsignedBase(static_cast<std::uint64_t>(iv), 2, STR_PREFIX_BIN, false);
    }
    std::uint64_t mag = 0;
    if (iv == (std::numeric_limits<long long>::min)()) {
      mag = (1ull << 63);
    } else {
      mag = static_cast<std::uint64_t>(-iv);
    }
    if (base == RenderBase::Hex) {
      return "-" + formatUnsignedBase(mag, 16, STR_PREFIX_HEX, true);
    }
    if (base == RenderBase::Oct) {
      return "-" + formatUnsignedBase(mag, 8, STR_PREFIX_OCT, false);
    }
    return "-" + formatUnsignedBase(mag, 2, STR_PREFIX_BIN, false);
  } else if (!parseUInt64FromDouble(dval, u)) {
    return formatScalar(v, RenderBase::Dec);
  }

  if (base == RenderBase::Hex) {
    return formatUnsignedBase(u, 16, STR_PREFIX_HEX, true);
  }
  if (base == RenderBase::Oct) {
    return formatUnsignedBase(u, 8, STR_PREFIX_OCT, false);
  }
  return formatUnsignedBase(u, 2, STR_PREFIX_BIN, false);
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
  if (nearlyInt(v, asInt)) {
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

MathParser::EvalValue MathParser::scalarFromArrayAt(const EvalValue& arrV, std::size_t idx) {
  EvalValue out = makeScalar(arrV.arr[idx].scalar);
  out.scalarValue.scalarKind = arrV.arr[idx].scalarKind;
  out.scalarValue.setExactIntValid(arrV.arr[idx].hasExactInt());
  out.scalarValue.exactInt = arrV.arr[idx].exactInt;
  out.scalarValue.setExactUInt64Valid(arrV.arr[idx].hasExactUInt64());
  out.scalarValue.exactUInt64 = arrV.arr[idx].exactUInt64;
  out.scalarValue.setDecScientificPow63High(arrV.arr[idx].hasDecScientificPow63High());
  return out;
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
      for (std::size_t i = 0; i < arg.arr.size(); ++i) {
        out.emplace_back(scalarFromArrayAt(arg, i));
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
    case '^': out = std::pow(a, b); return std::isfinite(out);
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
    if (v.scalarValue.scalar == p63 || v.scalarValue.scalar == -p63) {
      EvalValue out = makeScalar(-v.scalarValue.scalar);
      out.scalarValue.setDecScientificPow63High(true);
      return out;
    }
  }
  if (v.scalarValue.hasExactInt()) {
    const long long x = v.scalarValue.exactInt;
    if (x == (std::numeric_limits<long long>::min)()) {
      return makeScalar(-static_cast<double>(x));
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

    if (lv.hasExactInt() && rv.hasExactInt()) {
      if (op == '+' && lv.exactInt == (std::numeric_limits<long long>::max)() && rv.exactInt == 1LL) {
        outS = makePow63();
        return true;
      }
      if (op == '-' && lv.exactInt == (std::numeric_limits<long long>::min)() && rv.exactInt == 1LL) {
        outS = makeNegPow63();
        return true;
      }
      long long outI = 0;
      if (op == '+' && checkedAddLL(lv.exactInt, rv.exactInt, outI)) {
        outS = makeScalarInt(outI);
        return true;
      }
      if (op == '-' && checkedSubLL(lv.exactInt, rv.exactInt, outI)) {
        outS = makeScalarInt(outI);
        return true;
      }
      if (op == '*' && checkedMulLL(lv.exactInt, rv.exactInt, outI)) {
        outS = makeScalarInt(outI);
        return true;
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

  if (a.kind == ValueKind::Scalar && b.kind == ValueKind::Scalar) {
    EvalValue outS;
    ok = tryCombineScalarValues(a.scalarValue, b.scalarValue, outS);
    return ok ? outS : makeScalar(0);
  }

  if (a.kind == ValueKind::Array && b.kind == ValueKind::Array) {
    if (a.arr.size() != b.arr.size()) {
      ok = false;
      return makeScalar(0);
    }
    scratchBinaryOut_.clear();
    scratchBinaryOut_.reserve(a.arr.size());
    for (std::size_t i = 0; i < a.arr.size(); ++i) {
      EvalValue outS;
      if (!tryCombineScalarValues(a.arr[i], b.arr[i], outS)) {
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

  if (a.kind == ValueKind::Array) {
    scratchBinaryOut_.clear();
    scratchBinaryOut_.reserve(a.arr.size());
    for (std::size_t i = 0; i < a.arr.size(); ++i) {
      EvalValue outS;
      if (!tryCombineScalarValues(a.arr[i], b.scalarValue, outS)) {
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
  scratchBinaryOut_.reserve(b.arr.size());
  for (std::size_t i = 0; i < b.arr.size(); ++i) {
    EvalValue outS;
    if (!tryCombineScalarValues(a.scalarValue, b.arr[i], outS)) {
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
  const char* nameStart = ctx.p++;
  while (isIdentChar(*ctx.p)) {
    ++ctx.p;
  }
  std::string fnName(nameStart, static_cast<std::size_t>(ctx.p - nameStart));
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
      const char* pStart = ctx.p++;
      while (isIdentChar(*ctx.p)) {
        ++ctx.p;
      }
      params.emplace_back(toLower(std::string(pStart, static_cast<std::size_t>(ctx.p - pStart))));
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
  if (*ctx.p != '=') {
    ctx.p = save;
    return false;
  }
  ++ctx.p;
  skipSpaces(ctx);

  outName = toLower(fnName);
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
    ++ctx.p;
    skipSpaces(ctx);
    if (*ctx.p == ')') {
      setError(ctx, STR_UNEXPECTED_TOKEN);
      return nullptr;
    }
    std::vector<std::unique_ptr<Expr>> values;
    values.emplace_back(parseExpression(ctx));
    if (ctx.parseError) {
      return nullptr;
    }
    skipSpaces(ctx);
    while (*ctx.p == ',') {
      ++ctx.p;
      skipSpaces(ctx);
      if (*ctx.p == ')') {
        setError(ctx, STR_UNEXPECTED_COMMA);
        return nullptr;
      }
      values.emplace_back(parseExpression(ctx));
      if (ctx.parseError) {
        return nullptr;
      }
      skipSpaces(ctx);
    }
    if (*ctx.p != ')') {
      if (isIdentStart(*ctx.p) || std::isdigit(static_cast<unsigned char>(*ctx.p)) || *ctx.p == '.') {
        setError(ctx, STR_UNEXPECTED_TOKEN);
      } else {
        setError(ctx, STR_MISSING_CLOSING_PARENTHESIS);
      }
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
  if (std::isdigit(static_cast<unsigned char>(*ctx.p)) || *ctx.p == '.') {
    if (ctx.p[0] == '0' && (ctx.p[1] == 'x' || ctx.p[1] == 'X')) {
      const char* p = ctx.p + 2;
      unsigned long long u = 0;
      int digits = 0;
      while (*p) {
        const char c = *p;
        int d = -1;
        if (c >= '0' && c <= '9') d = c - '0';
        else if (c >= 'a' && c <= 'f') d = 10 + (c - 'a');
        else if (c >= 'A' && c <= 'F') d = 10 + (c - 'A');
        else break;
        u = (u * 16ULL) + static_cast<unsigned long long>(d);
        ++p;
        ++digits;
      }
      if (digits == 0) {
        setError(ctx, STR_INVALID_HEX_LITERAL);
        return nullptr;
      }
      ctx.p = p;
      auto lit = std::make_unique<Expr>();
      lit->tag = Expr::Tag::Literal;
      lit->literalValue = makeScalarUInt(static_cast<std::uint64_t>(u));
      return lit;
    }
    if (ctx.p[0] == '0' && (ctx.p[1] == 'b' || ctx.p[1] == 'B')) {
      const char* p = ctx.p + 2;
      unsigned long long u = 0;
      int digits = 0;
      while (*p == '0' || *p == '1') {
        u = (u << 1ULL) | static_cast<unsigned long long>(*p - '0');
        ++p;
        ++digits;
      }
      if (digits == 0) {
        setError(ctx, STR_INVALID_BINARY_LITERAL);
        return nullptr;
      }
      ctx.p = p;
      auto lit = std::make_unique<Expr>();
      lit->tag = Expr::Tag::Literal;
      lit->literalValue = makeScalarUInt(static_cast<std::uint64_t>(u));
      return lit;
    }
    if (ctx.p[0] == '0' && (ctx.p[1] == 'o' || ctx.p[1] == 'O')) {
      const char* p = ctx.p + 2;
      unsigned long long u = 0;
      int digits = 0;
      while (*p >= '0' && *p <= '7') {
        u = (u * 8ULL) + static_cast<unsigned long long>(*p - '0');
        ++p;
        ++digits;
      }
      if (digits == 0) {
        setError(ctx, STR_INVALID_OCTAL_LITERAL);
        return nullptr;
      }
      ctx.p = p;
      auto lit = std::make_unique<Expr>();
      lit->tag = Expr::Tag::Literal;
      lit->literalValue = makeScalarUInt(static_cast<std::uint64_t>(u));
      return lit;
    }
    const char* numStart = ctx.p;
    char* end = nullptr;
    double d = std::strtod(ctx.p, &end);
    if (end == ctx.p) {
      setError(ctx, STR_INVALID_NUMERIC_LITERAL);
      return nullptr;
    }
    ctx.p = end;
    auto lit = std::make_unique<Expr>();
    lit->tag = Expr::Tag::Literal;
    lit->literalValue = makeScalar(d);
    bool looksInt = true;
    for (const char* q = numStart; q < end; ++q) {
      if (*q == '.' || *q == 'e' || *q == 'E') {
        looksInt = false;
        break;
      }
    }
    if (looksInt) {
      std::uint64_t uv = 0;
      if (parseUInt64FromDecimalLiteral(numStart, end, uv)) {
        if (uv <= static_cast<std::uint64_t>((std::numeric_limits<long long>::max)())) {
          lit->literalValue = makeScalarInt(static_cast<long long>(uv));
        } else {
          lit->literalValue = makeScalarUInt(uv);
        }
      }
    }
    return lit;
  }
  if (isIdentStart(*ctx.p)) {
    const char* n0 = ctx.p++;
    while (isIdentChar(*ctx.p)) {
      ++ctx.p;
    }
    std::string ident = toLower(std::string(n0, static_cast<std::size_t>(ctx.p - n0)));
    skipSpaces(ctx);
    if (*ctx.p == '(') {
      ++ctx.p;
      std::vector<std::unique_ptr<Expr>> args;
      skipSpaces(ctx);
      if (*ctx.p != ')') {
        while (true) {
          args.emplace_back(parseExpression(ctx));
          if (ctx.parseError) {
            return nullptr;
          }
          skipSpaces(ctx);
          if (*ctx.p == ',') {
            ++ctx.p;
            skipSpaces(ctx);
            if (*ctx.p == ')') {
              setError(ctx, STR_UNEXPECTED_COMMA);
              return nullptr;
            }
            continue;
          }
          break;
        }
      }
      if (*ctx.p != ')') {
        if (isIdentStart(*ctx.p) || std::isdigit(static_cast<unsigned char>(*ctx.p)) || *ctx.p == '.') {
          setError(ctx, STR_UNEXPECTED_TOKEN);
        } else {
          setError(ctx, STR_MISSING_CLOSING_PARENTHESIS);
        }
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
    auto v = std::make_unique<Expr>();
    v->tag = Expr::Tag::Variable;
    v->name = std::move(ident);
    return v;
  }
  setError(ctx, STR_UNEXPECTED_TOKEN);
  return nullptr;
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
    if (ctx.parseError) {
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
    if (ctx.parseError) {
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
    if (ctx.parseError) {
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
    if (ctx.parseError) {
      return nullptr;
    }
    auto u = std::make_unique<Expr>();
    u->tag = Expr::Tag::Unary;
    u->unaryOp = '~';
    u->child = std::move(inner);
    return u;
  }
  auto prim = parsePrimary(ctx);
  if (ctx.parseError || !prim) {
    return nullptr;
  }
  while (true) {
    skipSpaces(ctx);
    if (*ctx.p == '[') {
      ++ctx.p;
      skipSpaces(ctx);
      if (*ctx.p == ']') {
        setError(ctx, STR_MISSING_INDEX);
        return nullptr;
      }
      auto idx = parseExpression(ctx);
      if (ctx.parseError || !idx) return nullptr;
      skipSpaces(ctx);
      if (*ctx.p != ']') {
        setError(ctx, STR_MISSING_CLOSING_BRACKET);
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
  auto left = parsePower(ctx);
  if (ctx.parseError || !left) {
    return nullptr;
  }
  while (true) {
    skipSpaces(ctx);
    Expr::BinaryOp op = Expr::BinaryOp::None;
    if (*ctx.p == '*' || *ctx.p == '/' || *ctx.p == '%') {
      const char opCh = *ctx.p++;
      if (opCh == '*') op = Expr::BinaryOp::Mul;
      else if (opCh == '/') op = Expr::BinaryOp::Div;
      else op = Expr::BinaryOp::Modulo;
    } else if (*ctx.p == '(') {
      op = Expr::BinaryOp::Mul;  // implicit multiplication: 2(3+4), (1+2)(3+4)
    } else {
      break;
    }
    auto right = parsePower(ctx);
    if (ctx.parseError || !right) {
      return nullptr;
    }
    auto out = std::make_unique<Expr>();
    out->tag = Expr::Tag::Binary;
    out->binaryOp = op;
    out->left = std::move(left);
    out->right = std::move(right);
    left = std::move(out);
  }
  return left;
}

std::unique_ptr<MathParser::Expr> MathParser::parseShift(EvalContext& ctx) {
  auto left = parseAddSub(ctx);
  if (ctx.parseError || !left) return nullptr;
  while (true) {
    skipSpaces(ctx);
    Expr::BinaryOp op = Expr::BinaryOp::None;
    if (ctx.p[0] == '<' && ctx.p[1] == '<') {
      op = Expr::BinaryOp::ShiftLeft;
      ctx.p += 2;
    } else if (ctx.p[0] == '>' && ctx.p[1] == '>') {
      op = Expr::BinaryOp::ShiftRight;
      ctx.p += 2;
    } else {
      break;
    }
    auto right = parseAddSub(ctx);
    if (ctx.parseError || !right) return nullptr;
    auto out = std::make_unique<Expr>();
    out->tag = Expr::Tag::Binary;
    out->binaryOp = op;
    out->left = std::move(left);
    out->right = std::move(right);
    left = std::move(out);
  }
  return left;
}

std::unique_ptr<MathParser::Expr> MathParser::parseBitAnd(EvalContext& ctx) {
  auto left = parseShift(ctx);
  if (ctx.parseError || !left) return nullptr;
  while (true) {
    skipSpaces(ctx);
    if (*ctx.p != '&' || ctx.p[1] == '&') break;
    ++ctx.p;
    auto right = parseShift(ctx);
    if (ctx.parseError || !right) return nullptr;
    auto out = std::make_unique<Expr>();
    out->tag = Expr::Tag::Binary;
    out->binaryOp = Expr::BinaryOp::BitAnd;
    out->left = std::move(left);
    out->right = std::move(right);
    left = std::move(out);
  }
  return left;
}

std::unique_ptr<MathParser::Expr> MathParser::parseBitXor(EvalContext& ctx) {
  auto left = parseBitAnd(ctx);
  if (ctx.parseError || !left) return nullptr;
  while (true) {
    skipSpaces(ctx);
    // Operator contract: '^' is bitwise XOR; exponentiation uses '**'.
    if (*ctx.p != '^') break;
    ++ctx.p;
    auto right = parseBitAnd(ctx);
    if (ctx.parseError || !right) return nullptr;
    auto out = std::make_unique<Expr>();
    out->tag = Expr::Tag::Binary;
    out->binaryOp = Expr::BinaryOp::BitXor;
    out->left = std::move(left);
    out->right = std::move(right);
    left = std::move(out);
  }
  return left;
}

std::unique_ptr<MathParser::Expr> MathParser::parseBitOr(EvalContext& ctx) {
  auto left = parseBitXor(ctx);
  if (ctx.parseError || !left) return nullptr;
  while (true) {
    skipSpaces(ctx);
    if (*ctx.p != '|' || ctx.p[1] == '|') break;
    ++ctx.p;
    auto right = parseBitXor(ctx);
    if (ctx.parseError || !right) return nullptr;
    auto out = std::make_unique<Expr>();
    out->tag = Expr::Tag::Binary;
    out->binaryOp = Expr::BinaryOp::BitOr;
    out->left = std::move(left);
    out->right = std::move(right);
    left = std::move(out);
  }
  return left;
}

std::unique_ptr<MathParser::Expr> MathParser::parseAddSub(EvalContext& ctx) {
  auto left = parseMulDivMod(ctx);
  if (ctx.parseError || !left) {
    return nullptr;
  }
  while (true) {
    skipSpaces(ctx);
    if (*ctx.p != '+' && *ctx.p != '-') {
      break;
    }
    const char opCh = *ctx.p++;
    auto right = parseMulDivMod(ctx);
    if (ctx.parseError || !right) {
      return nullptr;
    }
    auto out = std::make_unique<Expr>();
    out->tag = Expr::Tag::Binary;
    out->binaryOp = (opCh == '+') ? Expr::BinaryOp::Add : Expr::BinaryOp::Sub;
    out->left = std::move(left);
    out->right = std::move(right);
    out->rhsContainsPostfixPercent = exprContainsPostfixPercent(*out->right);
    left = std::move(out);
  }
  return left;
}

std::unique_ptr<MathParser::Expr> MathParser::parseCompare(EvalContext& ctx) {
  auto left = parseBitOr(ctx);
  if (ctx.parseError || !left) {
    return nullptr;
  }
  while (true) {
    skipSpaces(ctx);
    Expr::BinaryOp op = Expr::BinaryOp::None;
    if (std::strncmp(ctx.p, STR_LT_EQ, 2) == 0 || std::strncmp(ctx.p, STR_GT_EQ, 2) == 0 ||
        std::strncmp(ctx.p, STR_EQ_EQ, 2) == 0 || std::strncmp(ctx.p, STR_NOT_EQ, 2) == 0 ||
        std::strncmp(ctx.p, STR_LT_GT, 2) == 0) {
      if (ctx.p[0] == '<' && ctx.p[1] == '=') op = Expr::BinaryOp::CmpLe;
      else if (ctx.p[0] == '>' && ctx.p[1] == '=') op = Expr::BinaryOp::CmpGe;
      else if (ctx.p[0] == '=' && ctx.p[1] == '=') op = Expr::BinaryOp::CmpEq;
      else op = Expr::BinaryOp::CmpNe;
      ctx.p += 2;
    } else if (*ctx.p == '=') {
      op = Expr::BinaryOp::CmpEq;
      ++ctx.p;
    } else if (*ctx.p == '<' || *ctx.p == '>') {
      const char opCh = *ctx.p++;
      op = (opCh == '<') ? Expr::BinaryOp::CmpLt : Expr::BinaryOp::CmpGt;
    } else {
      break;
    }
    auto right = parseBitOr(ctx);
    if (ctx.parseError || !right) {
      return nullptr;
    }
    auto out = std::make_unique<Expr>();
    out->tag = Expr::Tag::Binary;
    out->binaryOp = op;
    out->left = std::move(left);
    out->right = std::move(right);
    left = std::move(out);
  }
  return left;
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
  auto left = parseLogicalNot(ctx);
  if (ctx.parseError || !left) {
    return nullptr;
  }
  while (true) {
    if (!consumeKeyword(ctx, opName(OperatorNameId::And).c_str())) {
      skipSpaces(ctx);
      if (ctx.p[0] == '&' && ctx.p[1] == '&') {
        ctx.p += 2;
      } else {
        break;
      }
    }
    auto right = parseLogicalNot(ctx);
    if (ctx.parseError || !right) {
      return nullptr;
    }
    auto out = std::make_unique<Expr>();
    out->tag = Expr::Tag::Binary;
    out->binaryOp = Expr::BinaryOp::LogicalAnd;
    out->left = std::move(left);
    out->right = std::move(right);
    left = std::move(out);
  }
  return left;
}

std::unique_ptr<MathParser::Expr> MathParser::parseOr(EvalContext& ctx) {
  auto left = parseAnd(ctx);
  if (ctx.parseError || !left) {
    return nullptr;
  }
  while (true) {
    if (!consumeKeyword(ctx, opName(OperatorNameId::Or).c_str())) {
      skipSpaces(ctx);
      if (ctx.p[0] == '|' && ctx.p[1] == '|') {
        ctx.p += 2;
      } else {
        break;
      }
    }
    auto right = parseAnd(ctx);
    if (ctx.parseError || !right) {
      return nullptr;
    }
    auto out = std::make_unique<Expr>();
    out->tag = Expr::Tag::Binary;
    out->binaryOp = Expr::BinaryOp::LogicalOr;
    out->left = std::move(left);
    out->right = std::move(right);
    left = std::move(out);
  }
  return left;
}

std::unique_ptr<MathParser::Expr> MathParser::parseExpression(EvalContext& ctx) {
  return parseOr(ctx);
}

bool MathParser::parseProgram(EvalContext& ctx, std::vector<AstStatement>& out) {
  out.clear();
  while (true) {
    skipSpaces(ctx);
    if (*ctx.p == '\0') {
      break;
    }
    std::string fnName;
    std::vector<std::string> fnParams;
    std::string fnExpr;
    const char* save = ctx.p;
    if (parseFunctionDefinition(ctx, fnName, fnParams, fnExpr)) {
      {
        std::unordered_map<std::string, bool> seen;
        for (const auto& p : fnParams) {
          if (seen.find(p) != seen.end()) {
            setError(ctx, STR_DUPLICATE_PARAMETER_NAME);
            return false;
          }
          if (isReservedBuiltinConstantName(p)) {
            setError(ctx, STR_RESERVED_CONSTANT_NAME);
            return false;
          }
          seen[p] = true;
        }
      }
      {
        if (isReservedBuiltinConstantName(fnName)) {
          setError(ctx, STR_RESERVED_CONSTANT_NAME);
          return false;
        }
        if (isReservedFunctionName(fnName)) {
          setError(ctx, STR_RESERVED_FUNCTION_NAME);
          return false;
        }
      }
      if (udfBodyCallsDefinedFunction(fnExpr, fnName)) {
        setError(ctx, STR_RECURSIVE_USER_FUNCTION_CALL_COLON + fnName);
        return false;
      }
      AstStatement st;
      st.kind = AstStatement::Kind::FunDef;
      st.fun = UserFunction{fnName, fnParams, fnExpr};
      out.emplace_back(std::move(st));
    } else {
      ctx.p = save;
      skipSpaces(ctx);
      if (!out.empty() && isIdentStart(*ctx.p)) {
        const char* sugarStart = ctx.p;
        const char* q = ctx.p + 1;
        while (isIdentChar(*q)) {
          ++q;
        }
        const std::string ident = toLower(std::string(sugarStart, static_cast<std::size_t>(q - sugarStart)));
        if (isTrailingFormatterFunctionName(ident)) {
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
          if (sugarOk) {
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
            goto parse_program_statement_done;
          }
        }
      }
      const char* assignSave = ctx.p;
      if (isIdentStart(*ctx.p)) {
        const char* id0 = ctx.p++;
        while (isIdentChar(*ctx.p)) {
          ++ctx.p;
        }
        std::string ident = toLower(std::string(id0, static_cast<std::size_t>(ctx.p - id0)));
        skipSpaces(ctx);
        // Single '=' is assignment; '==' is equality (do not steal first '=').
        if (*ctx.p == '=' && ctx.p[1] != '=') {
          if (isReservedFunctionName(ident)) {
            setError(ctx, STR_RESERVED_FUNCTION_NAME);
            return false;
          }
          if (isReservedBuiltinConstantName(ident)) {
            setError(ctx, STR_RESERVED_CONSTANT_NAME);
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
        } else {
          ctx.p = assignSave;
          auto ex = parseExpression(ctx);
          if (ctx.parseError || !ex) {
            return false;
          }
          AstStatement st;
          st.kind = AstStatement::Kind::Expr;
          st.expr = std::move(ex);
          out.emplace_back(std::move(st));
        }
      } else {
        auto ex = parseExpression(ctx);
        if (ctx.parseError || !ex) {
          return false;
        }
        AstStatement st;
        st.kind = AstStatement::Kind::Expr;
        st.expr = std::move(ex);
        out.emplace_back(std::move(st));
      }
    }
parse_program_statement_done:
    skipSpaces(ctx);
    if (*ctx.p == ';') {
      ++ctx.p;
      continue;
    }
    if (*ctx.p == '\0') {
      break;
    }
    setError(ctx, STR_UNEXPECTED_TOKEN_AFTER_EXPRESSION);
    return false;
  }
  return true;
}

bool MathParser::exprContainsPostfixPercent(const Expr& e) {
  if (e.tag == Expr::Tag::PostfixPercent) {
    return true;
  }
  if (e.tag == Expr::Tag::Unary && e.child) {
    return exprContainsPostfixPercent(*e.child);
  }
  if (e.tag == Expr::Tag::Binary) {
    return (e.left && exprContainsPostfixPercent(*e.left)) || (e.right && exprContainsPostfixPercent(*e.right));
  }
  if (e.tag == Expr::Tag::Call) {
    for (const auto& ch : e.elements) {
      if (exprContainsPostfixPercent(*ch)) {
        return true;
      }
    }
  }
  if (e.tag == Expr::Tag::ArrayOrParens) {
    for (const auto& ch : e.elements) {
      if (exprContainsPostfixPercent(*ch)) {
        return true;
      }
    }
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
        setError(ctx, STR_SCALAR_ONLY_EXPRESSION_ENCOUNTERED_NON);
        return makeScalar(0);
      }
      return out;
    }
    case Expr::Tag::Unary: {
      if (e.unaryOp == '+') return evalExprScalar(*e.child, ctx, scopedVars);
      EvalValue v = evalExprScalar(*e.child, ctx, scopedVars);
      if (ctx.parseError) return v;
      if (e.unaryOp == '-') return negateEvalValue(v);
      if (e.unaryOp == 'N') return makeScalarInt(isTruthy(v) ? 0LL : 1LL);
      if (e.unaryOp == '~') {
        long long iv = 0;
        if (!tryGetSignedInt64FromScalar(v.scalarValue, iv)) {
          setError(ctx, STR_BITWISE_OPERANDS_MUST_BE_INTEGER_VALUES);
          return makeScalar(0);
        }
        return makeScalarInt(~iv);
      }
      setError(ctx, STR_INTERNAL_UNARY_OP);
      return makeScalar(0);
    }
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
      const auto returnIntegerOperandError = [&](const char* msg) -> EvalValue {
        setError(ctx, msg);
        return makeScalar(0);
      };
      switch (e.binaryOp) {
        case Expr::BinaryOp::LogicalOr:
          return makeScalarInt((isTruthy(l) || isTruthy(r)) ? 1LL : 0LL);
        case Expr::BinaryOp::LogicalAnd:
          return makeScalarInt((isTruthy(l) && isTruthy(r)) ? 1LL : 0LL);
        case Expr::BinaryOp::Modulo: {
          long long a = 0, b = 0;
          if (!tryGetSignedInt64FromScalar(l.scalarValue, a) || !tryGetSignedInt64FromScalar(r.scalarValue, b)) {
            return returnIntegerOperandError(STR_MODULO_OPERANDS_MUST_BE_INTEGER_VALUES);
          }
          if (b == 0) {
            return returnIntegerOperandError(STR_INCOMPATIBLE_OPERANDS);
          }
          return makeScalarInt(a % b);
        }
        case Expr::BinaryOp::BitAnd:
        case Expr::BinaryOp::BitOr:
        case Expr::BinaryOp::BitXor:
        case Expr::BinaryOp::ShiftLeft:
        case Expr::BinaryOp::ShiftRight: {
          long long a = 0, b = 0;
          if (!tryGetSignedInt64FromScalar(l.scalarValue, a) || !tryGetSignedInt64FromScalar(r.scalarValue, b)) {
            return returnIntegerOperandError(STR_BITWISE_OPERANDS_MUST_BE_INTEGER_VALUES);
          }
          if ((e.binaryOp == Expr::BinaryOp::ShiftLeft || e.binaryOp == Expr::BinaryOp::ShiftRight) &&
              (b < 0 || b > 63)) {
            return returnIntegerOperandError(STR_INCOMPATIBLE_OPERANDS);
          }
          if (e.binaryOp == Expr::BinaryOp::BitAnd) return makeScalarInt(a & b);
          if (e.binaryOp == Expr::BinaryOp::BitOr) return makeScalarInt(a | b);
          if (e.binaryOp == Expr::BinaryOp::BitXor) return makeScalarInt(a ^ b);
          if (e.binaryOp == Expr::BinaryOp::ShiftLeft) return makeScalarInt(bitwiseShiftLeftDefined(a, static_cast<unsigned int>(b)));
          return makeScalarInt(bitwiseShiftRightDefined(a, static_cast<unsigned int>(b)));
        }
        case Expr::BinaryOp::CmpLt:
          return makeScalarInt(((l.scalarValue.scalar < r.scalarValue.scalar) ? -1 : (l.scalarValue.scalar > r.scalarValue.scalar ? 1 : 0)) < 0 ? 1LL : 0LL);
        case Expr::BinaryOp::CmpGt:
          return makeScalarInt(((l.scalarValue.scalar < r.scalarValue.scalar) ? -1 : (l.scalarValue.scalar > r.scalarValue.scalar ? 1 : 0)) > 0 ? 1LL : 0LL);
        case Expr::BinaryOp::CmpLe:
          return makeScalarInt(((l.scalarValue.scalar < r.scalarValue.scalar) ? -1 : (l.scalarValue.scalar > r.scalarValue.scalar ? 1 : 0)) <= 0 ? 1LL : 0LL);
        case Expr::BinaryOp::CmpGe:
          return makeScalarInt(((l.scalarValue.scalar < r.scalarValue.scalar) ? -1 : (l.scalarValue.scalar > r.scalarValue.scalar ? 1 : 0)) >= 0 ? 1LL : 0LL);
        case Expr::BinaryOp::CmpEq:
          return makeScalarInt(((l.scalarValue.scalar < r.scalarValue.scalar) ? -1 : (l.scalarValue.scalar > r.scalarValue.scalar ? 1 : 0)) == 0 ? 1LL : 0LL);
        case Expr::BinaryOp::CmpNe:
          return makeScalarInt(((l.scalarValue.scalar < r.scalarValue.scalar) ? -1 : (l.scalarValue.scalar > r.scalarValue.scalar ? 1 : 0)) != 0 ? 1LL : 0LL);
        case Expr::BinaryOp::Pow: {
          bool ok = false;
          EvalValue out = mapBinary(l, r, '^', ok);
          if (!ok) {
            setError(ctx, STR_NUMERIC_ERROR_IN_POWER_OPERATION);
            return makeScalar(0);
          }
          return out;
        }
        case Expr::BinaryOp::Mul:
        case Expr::BinaryOp::Div:
        case Expr::BinaryOp::Add:
        case Expr::BinaryOp::Sub: {
          if ((e.binaryOp == Expr::BinaryOp::Add || e.binaryOp == Expr::BinaryOp::Sub) &&
              e.rhsContainsPostfixPercent) {
            r.scalarValue.scalar = l.scalarValue.scalar * r.scalarValue.scalar;
          }

          if ((e.binaryOp == Expr::BinaryOp::Mul || e.binaryOp == Expr::BinaryOp::Add ||
               e.binaryOp == Expr::BinaryOp::Sub)) {
            long long li = 0, ri = 0;
            if (tryGetExactSignedInt64FromScalar(l.scalarValue, li) &&
                tryGetExactSignedInt64FromScalar(r.scalarValue, ri)) {
              long long outI = 0;
              const bool okInt =
                  (e.binaryOp == Expr::BinaryOp::Mul) ? checkedMulLL(li, ri, outI) :
                  (e.binaryOp == Expr::BinaryOp::Add) ? checkedAddLL(li, ri, outI) :
                                                         checkedSubLL(li, ri, outI);
              if (okInt) {
                return makeScalarInt(outI);
              }
            }
          }

          const char opChar = (e.binaryOp == Expr::BinaryOp::Mul) ? '*' :
                              (e.binaryOp == Expr::BinaryOp::Div) ? '/' :
                              (e.binaryOp == Expr::BinaryOp::Add) ? '+' : '-';
          bool ok = false;
          EvalValue out = mapBinary(l, r, opChar, ok);
          if (!ok) {
            setError(ctx, STR_NUMERIC_ERROR_IN_EXPRESSION);
            return makeScalar(0);
          }
          return out;
        }
        default:
          setError(ctx, STR_INTERNAL_BINARY_OP);
          return makeScalar(0);
      }
    }
    default:
      setError(ctx, STR_INTERNAL_EVAL_ERROR);
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
      if (e.unaryOp == '+') {
        return evalExpr(*e.child, ctx, scopedVars);
      }
      if (e.unaryOp == '-') {
        EvalValue v = evalExpr(*e.child, ctx, scopedVars);
        if (ctx.parseError) {
          return v;
        }
        return negateEvalValue(v);
      }
      if (e.unaryOp == 'N') {
        EvalValue v = evalExpr(*e.child, ctx, scopedVars);
        if (ctx.parseError) {
          return v;
        }
        return makeScalarInt(isTruthy(v) ? 0LL : 1LL);
      }
      if (e.unaryOp == '~') {
        EvalValue v = evalExpr(*e.child, ctx, scopedVars);
        if (ctx.parseError) return v;
        if (v.kind != ValueKind::Scalar) {
          setError(ctx, STR_BITWISE_OPERANDS_MUST_BE_INTEGER_VALUES);
          return makeScalar(0);
        }
        long long iv = 0;
        if (!tryGetSignedInt64FromScalar(v.scalarValue, iv)) {
          setError(ctx, STR_BITWISE_OPERANDS_MUST_BE_INTEGER_VALUES);
          return makeScalar(0);
        }
        return makeScalarInt(~iv);
      }
      setError(ctx, STR_INTERNAL_UNARY_OP);
      return makeScalar(0);
    case Expr::Tag::PostfixPercent: {
      EvalValue v = evalExpr(*e.child, ctx, scopedVars);
      if (ctx.parseError) {
        return v;
      }
      if (v.kind != ValueKind::Scalar) {
        setError(ctx, STR_PERCENTAGE_REQUIRES_SCALAR_VALUE);
        return makeScalar(0);
      }
      v.scalarValue.scalar /= 100.0;
      v.scalarValue.setExactIntValid(false);
      v.scalarValue.setExactUInt64Valid(false);
      return v;
    }
    case Expr::Tag::ArrayOrParens: {
      std::vector<EvalValue> values;
      values.reserve(e.elements.size());
      for (const auto& ch : e.elements) {
        values.emplace_back(evalExpr(*ch, ctx, scopedVars));
        if (ctx.parseError) {
          return makeScalar(0);
        }
      }
      std::vector<EvalValue> flatVals;
      std::size_t flatCount = 0;
      for (const auto& a : values) {
        flatCount += (a.kind == ValueKind::Scalar) ? 1 : a.arr.size();
      }
      flatVals.reserve(flatCount);
      for (const auto& a : values) {
        if (a.kind == ValueKind::Scalar) {
          flatVals.emplace_back(a);
        } else {
          for (std::size_t i = 0; i < a.arr.size(); ++i) {
            EvalValue elem = scalarFromArrayAt(a, i);
            flatVals.emplace_back(std::move(elem));
          }
        }
      }
      if (flatVals.empty()) {
        setError(ctx, STR_FAILED_TO_BUILD_ARRAY_LITERAL);
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
        setError(ctx, STR_INDEXING_REQUIRES_AN_ARRAY_VALUE);
        return makeScalar(0);
      }
      EvalValue idxv = evalExpr(*e.right, ctx, scopedVars);
      if (ctx.parseError) return idxv;
      if (idxv.kind != ValueKind::Scalar) {
        setError(ctx, STR_ARRAY_INDEX_MUST_BE_A_SCALAR);
        return makeScalar(0);
      }
      long long idx = 0;
      if (!nearlyInt(idxv.scalarValue.scalar, idx)) {
        setError(ctx, STR_ARRAY_INDEX_MUST_BE_AN_INTEGER);
        return makeScalar(0);
      }
      const long long n = static_cast<long long>(base.arr.size());
      long long realIdx = (idx >= 0) ? idx : (n + idx);
      if (realIdx < 0 || realIdx >= n) {
        setError(ctx, STR_ARRAY_INDEX_IS_OUT_OF_RANGE);
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
        setError(ctx, msg);
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
      if (e.binaryOp == Expr::BinaryOp::Modulo) {
        EvalValue l = makeScalar(0), r = makeScalar(0);
        if (evalBinaryOperands(l, r) != BinaryEvalStatus::Ok) {
          return makeScalar(0);
        }
        auto applyModuloScalars = [&](const EvalValue::ScalarValue& lv, const EvalValue::ScalarValue& rv, EvalValue& outS) -> bool {
          long long a = 0, b = 0;
          if (!tryGetSignedInt64FromScalar(lv, a) || !tryGetSignedInt64FromScalar(rv, b)) return false;
          if (b == 0) {
            setError(ctx, STR_INCOMPATIBLE_OPERANDS);
            return false;
          }
          outS = makeScalarInt(a % b);
          return true;
        };
        auto applyModuloOverOperands = [&](const EvalValue& lv, const EvalValue& rv) -> EvalValue {
          const auto returnModuloOperandError = [&]() -> EvalValue {
            setError(ctx, STR_MODULO_OPERANDS_MUST_BE_INTEGER_VALUES);
            scratchBinaryOut_.clear();
            return makeScalar(0);
          };
          if (lv.kind == ValueKind::Scalar && rv.kind == ValueKind::Scalar) {
            EvalValue outS;
            if (!applyModuloScalars(lv.scalarValue, rv.scalarValue, outS)) {
              if (ctx.parseError) return makeScalar(0);
              return returnIntegerOperandError(STR_MODULO_OPERANDS_MUST_BE_INTEGER_VALUES);
            }
            return outS;
          }
          if (lv.kind == ValueKind::Array && rv.kind == ValueKind::Array && lv.arr.size() != rv.arr.size()) {
            setError(ctx, STR_INCOMPATIBLE_OPERANDS);
            return makeScalar(0);
          }
          const std::size_t outCount = (lv.kind == ValueKind::Array) ? lv.arr.size() : rv.arr.size();
          scratchBinaryOut_.clear();
          scratchBinaryOut_.reserve(outCount);
          for (std::size_t i = 0; i < outCount; ++i) {
            const EvalValue::ScalarValue& lItem = (lv.kind == ValueKind::Array) ? lv.arr[i] : lv.scalarValue;
            const EvalValue::ScalarValue& rItem = (rv.kind == ValueKind::Array) ? rv.arr[i] : rv.scalarValue;
            EvalValue outS;
            if (!applyModuloScalars(lItem, rItem, outS)) {
              if (ctx.parseError) {
                scratchBinaryOut_.clear();
                return makeScalar(0);
              }
              return returnModuloOperandError();
            }
            scratchBinaryOut_.emplace_back(std::move(outS));
          }
          EvalValue ret = makeArrayFromScalars(scratchBinaryOut_);
          scratchBinaryOut_.clear();
          return ret;
        };
        return applyModuloOverOperands(l, r);
      }
      if (e.binaryOp == Expr::BinaryOp::BitAnd || e.binaryOp == Expr::BinaryOp::BitOr ||
          e.binaryOp == Expr::BinaryOp::BitXor || e.binaryOp == Expr::BinaryOp::ShiftLeft ||
          e.binaryOp == Expr::BinaryOp::ShiftRight) {
        EvalValue l = makeScalar(0), r = makeScalar(0);
        if (evalBinaryOperands(l, r) != BinaryEvalStatus::Ok) {
          return makeScalar(0);
        }
        auto applyBitwiseScalars = [&](const EvalValue::ScalarValue& lv, const EvalValue::ScalarValue& rv, EvalValue& outS) -> bool {
          long long a = 0, b = 0;
          if (!tryGetSignedInt64FromScalar(lv, a) || !tryGetSignedInt64FromScalar(rv, b)) return false;
          if ((e.binaryOp == Expr::BinaryOp::ShiftLeft || e.binaryOp == Expr::BinaryOp::ShiftRight) &&
              (b < 0 || b > 63)) {
            setError(ctx, STR_INCOMPATIBLE_OPERANDS);
            return false;
          }
          long long out = 0;
          if (e.binaryOp == Expr::BinaryOp::BitAnd) out = (a & b);
          else if (e.binaryOp == Expr::BinaryOp::BitOr) out = (a | b);
          else if (e.binaryOp == Expr::BinaryOp::BitXor) out = (a ^ b);
          else if (e.binaryOp == Expr::BinaryOp::ShiftLeft) out = bitwiseShiftLeftDefined(a, static_cast<unsigned int>(b));
          else out = bitwiseShiftRightDefined(a, static_cast<unsigned int>(b));
          outS = makeScalarInt(out);
          return true;
        };
        auto applyBitwiseOverOperands = [&](const EvalValue& lv, const EvalValue& rv) -> EvalValue {
          const auto returnBitwiseOperandError = [&]() -> EvalValue {
            setError(ctx, STR_BITWISE_OPERANDS_MUST_BE_INTEGER_VALUES);
            scratchBinaryOut_.clear();
            return makeScalar(0);
          };
          if (lv.kind == ValueKind::Scalar && rv.kind == ValueKind::Scalar) {
            EvalValue outS;
            if (!applyBitwiseScalars(lv.scalarValue, rv.scalarValue, outS)) {
              if (ctx.parseError) return makeScalar(0);
              return returnIntegerOperandError(STR_BITWISE_OPERANDS_MUST_BE_INTEGER_VALUES);
            }
            return outS;
          }
          if (lv.kind == ValueKind::Array && rv.kind == ValueKind::Array && lv.arr.size() != rv.arr.size()) {
            setError(ctx, STR_INCOMPATIBLE_OPERANDS);
            return makeScalar(0);
          }
          const std::size_t outCount = (lv.kind == ValueKind::Array) ? lv.arr.size() : rv.arr.size();
          scratchBinaryOut_.clear();
          scratchBinaryOut_.reserve(outCount);
          for (std::size_t i = 0; i < outCount; ++i) {
            const EvalValue::ScalarValue& lItem = (lv.kind == ValueKind::Array) ? lv.arr[i] : lv.scalarValue;
            const EvalValue::ScalarValue& rItem = (rv.kind == ValueKind::Array) ? rv.arr[i] : rv.scalarValue;
            EvalValue outS;
            if (!applyBitwiseScalars(lItem, rItem, outS)) {
              if (ctx.parseError) {
                scratchBinaryOut_.clear();
                return makeScalar(0);
              }
              return returnBitwiseOperandError();
            }
            scratchBinaryOut_.emplace_back(std::move(outS));
          }
          EvalValue ret = makeArrayFromScalars(scratchBinaryOut_);
          scratchBinaryOut_.clear();
          return ret;
        };
        return applyBitwiseOverOperands(l, r);
      }
      const auto evalComparison = [&](int& outCmp) -> bool {
        EvalValue l = evalExpr(*e.left, ctx, scopedVars);
        if (ctx.parseError) return false;
        EvalValue r = evalExpr(*e.right, ctx, scopedVars);
        if (ctx.parseError) return false;
        outCmp = compareValues(l, r);
        return true;
      };
      const auto evalComparisonByOp = [&](int cmp) -> bool {
        switch (e.binaryOp) {
          case Expr::BinaryOp::CmpLt: return cmp < 0;
          case Expr::BinaryOp::CmpGt: return cmp > 0;
          case Expr::BinaryOp::CmpLe: return cmp <= 0;
          case Expr::BinaryOp::CmpGe: return cmp >= 0;
          case Expr::BinaryOp::CmpEq: return cmp == 0;
          case Expr::BinaryOp::CmpNe: return cmp != 0;
          default: return false;
        }
      };
      if (e.binaryOp == Expr::BinaryOp::CmpLe || e.binaryOp == Expr::BinaryOp::CmpGe ||
          e.binaryOp == Expr::BinaryOp::CmpEq || e.binaryOp == Expr::BinaryOp::CmpNe) {
        int cmp = 0;
        if (!evalComparison(cmp)) return makeScalar(0);
        return makeScalarInt(evalComparisonByOp(cmp) ? 1LL : 0LL);
      }
      if (e.binaryOp == Expr::BinaryOp::CmpLt || e.binaryOp == Expr::BinaryOp::CmpGt) {
        int cmp = 0;
        if (!evalComparison(cmp)) return makeScalar(0);
        return makeScalarInt(evalComparisonByOp(cmp) ? 1LL : 0LL);
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
          e.rhsContainsPostfixPercent &&
          l.kind == ValueKind::Scalar && r.kind == ValueKind::Scalar) {
        r.scalarValue.scalar = l.scalarValue.scalar * r.scalarValue.scalar;
      }
      if (e.binaryOp == Expr::BinaryOp::Pow) {
        bool ok = false;
        EvalValue out = mapBinary(l, r, '^', ok);
        if (!ok) {
          setError(ctx, STR_NUMERIC_ERROR_IN_POWER_OPERATION);
          return makeScalar(0);
        }
        return out;
      }
      if (e.binaryOp == Expr::BinaryOp::Mul || e.binaryOp == Expr::BinaryOp::Div ||
          e.binaryOp == Expr::BinaryOp::Add || e.binaryOp == Expr::BinaryOp::Sub) {
        const char opChar = (e.binaryOp == Expr::BinaryOp::Mul) ? '*' :
                            (e.binaryOp == Expr::BinaryOp::Div) ? '/' :
                            (e.binaryOp == Expr::BinaryOp::Add) ? '+' : '-';
        bool ok = false;
        EvalValue out = mapBinary(l, r, opChar, ok);
        if (!ok) {
          if (l.kind == ValueKind::Array && r.kind == ValueKind::Array && l.arr.size() != r.arr.size()) {
            setError(ctx, STR_INCOMPATIBLE_OPERANDS);
          } else {
            setError(ctx, STR_NUMERIC_ERROR_IN_EXPRESSION);
          }
          return makeScalar(0);
        }
        return out;
      }
      setError(ctx, STR_INTERNAL_BINARY_OP);
      return makeScalar(0);
    }
    default:
      break;
  }
  setError(ctx, STR_INTERNAL_EVAL_ERROR);
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

bool MathParser::flattenRequired(
    EvalContext& ctx,
    const std::string& fnName,
    const std::vector<EvalValue>& args,
    std::vector<double>& flat) const {
  if (args.empty() || !flattenArgs(args, flat)) {
    setError(ctx, fnName + STR_PAR_EXPECTS_AT_LEAST_1);
    return false;
  }
  return true;
}

MathParser::EvalValue MathParser::builtinUnpack(EvalContext& ctx, const std::vector<EvalValue>& args) const {
  const std::string fnName = getFunctionName(BuiltinFunctionId::Unpack);
  if (args.empty()) {
    setError(ctx, fnName + STR_PAR_EXPECTS_AT_LEAST_1);
    return makeScalar(0);
  }
  const auto markExpanded = [](EvalValue v) {
    v.setExpandArgs(true);
    return v;
  };
  if (args.size() == 1) {
    return markExpanded(args[0]);
  }
  const std::size_t totalCount = countFlattenedScalars(args);
  if (totalCount == 0) {
    setError(ctx, fnName + STR_PAR_EXPECTS_AT_LEAST_1);
    return makeScalar(0);
  }
  std::vector<EvalValue> elems;
  elems.reserve(totalCount);
  for (const auto& a : args) {
    if (a.kind == ValueKind::Scalar) {
      elems.emplace_back(a);
    } else {
      for (std::size_t i = 0; i < a.arr.size(); ++i) {
        elems.emplace_back(scalarFromArrayAt(a, i));
      }
    }
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
  if (id == BuiltinFunctionId::Sum || id == BuiltinFunctionId::Product || id == BuiltinFunctionId::Prod ||
      id == BuiltinFunctionId::Min || id == BuiltinFunctionId::Max || id == BuiltinFunctionId::Avg ||
      id == BuiltinFunctionId::Mean) {
    if (args.empty()) {
      setError(ctx, fnName + STR_PAR_EXPECTS_AT_LEAST_1);
      return makeScalar(0);
    }
    if (args.size() == 1 && args[0].kind == ValueKind::Scalar) {
      return makeScalar(args[0].scalarValue.scalar);
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
      setError(ctx, fnName + STR_PAR_EXPECTS_AT_LEAST_1);
      return makeScalar(0);
    }
    if (id == BuiltinFunctionId::Avg || id == BuiltinFunctionId::Mean) {
      acc /= static_cast<double>(n);
    }
    return makeScalar(acc);
  }

  switch (id) {
    case BuiltinFunctionId::Median: {
      if (args.size() == 1U) {
        const EvalValue& single = args.front();
        if (single.kind == ValueKind::Scalar) {
          return makeScalar(single.scalarValue.scalar);
        }
        if (single.arr.size() == 1U) {
          return makeScalar(single.arr.front().scalar);
        }
      }
      std::vector<double> flat;
      if (!flattenArgs(args, flat)) {
        setError(ctx, fnName + STR_PAR_EXPECTS_AT_LEAST_1);
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
        setError(ctx, fnName + STR_PAR_EXPECTS_AT_LEAST_1);
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
  setError(ctx, STR_INTERNAL_ERROR_IN_AGGREGATE_BUILTIN);
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
  auto dedupUniqueInPlace = [&](std::vector<double>& values) {
    std::unordered_set<std::uint64_t> seen;
    seen.reserve(values.size() * 2 + 1);
    std::size_t writePos = 0;
    for (std::size_t readPos = 0; readPos < values.size(); ++readPos) {
      const double v = values[readPos];
      if (std::isnan(v)) {
        values[writePos++] = v; // NaN never equals NaN in existing semantics; keep all.
        continue;
      }
      if (seen.insert(keyForUnique(v)).second) {
        values[writePos++] = v;
      }
    }
    values.resize(writePos);
  };

  if (args.empty()) {
    setError(ctx, fnName + STR_PAR_EXPECTS_AT_LEAST_1);
    return makeScalar(0);
  }
  const auto copyArrayScalars = [&](const EvalValue& a, std::vector<double>& out) {
    out.clear();
    out.reserve(a.arr.size());
    for (const auto& item : a.arr) {
      out.emplace_back(item.scalar);
    }
  };
  const auto copySingleArgToFlat = [&](const EvalValue& a, std::vector<double>& out) {
    out.clear();
    if (a.kind == ValueKind::Scalar) {
      out.emplace_back(a.scalarValue.scalar);
      return;
    }
    copyArrayScalars(a, out);
  };
  if (args.size() == 1) {
    const EvalValue& a = args[0];
    if (a.kind == ValueKind::Scalar) {
      return makeArray(std::vector<double>{a.scalarValue.scalar});
    }
    std::vector<double> out;
    copySingleArgToFlat(a, out);
    if (out.empty()) {
      setError(ctx, fnName + STR_PAR_EXPECTS_AT_LEAST_1);
      return makeScalar(0);
    }
    if (id == BuiltinFunctionId::Sort || id == BuiltinFunctionId::Sorted) {
      std::sort(out.begin(), out.end());
      return makeArray(out);
    }
    if (id == BuiltinFunctionId::Reverse || id == BuiltinFunctionId::Reversed) {
      std::reverse(out.begin(), out.end());
      return makeArray(out);
    }
    if (id == BuiltinFunctionId::Unique) {
      dedupUniqueInPlace(out);
      return makeArray(out);
    }
  }

  std::vector<double> flat;
  if (!flattenRequired(ctx, fnName, args, flat)) {
    return makeScalar(0);
  }
  if (id == BuiltinFunctionId::Sort || id == BuiltinFunctionId::Sorted) {
    std::sort(flat.begin(), flat.end());
  } else if (id == BuiltinFunctionId::Reverse || id == BuiltinFunctionId::Reversed) {
    std::reverse(flat.begin(), flat.end());
  } else {
    dedupUniqueInPlace(flat);
  }
  return makeArray(flat);
}

MathParser::EvalValue MathParser::builtinBaseFormat(
    EvalContext& ctx,
    const std::string& fnName,
    BuiltinFunctionId id,
    const std::vector<EvalValue>& args) const {
  if (args.empty()) {
    setError(ctx, fnName + STR_PAR_EXPECTS_AT_LEAST_1);
    return makeScalar(0);
  }
  auto ensureIntegerScalarValue = [&](const EvalValue::ScalarValue& s) {
    return s.hasExactInt() || s.hasExactUInt64();
  };
  auto ensureIntegerScalar = [&](const EvalValue& s) {
    return ensureIntegerScalarValue(s.scalarValue);
  };
  auto validateIntegerArg = [&](const EvalValue& v) -> bool {
    if (v.kind == ValueKind::Scalar) {
      return ensureIntegerScalar(v);
    }
    for (const auto& item : v.arr) {
      if (!ensureIntegerScalarValue(item)) {
        return false;
      }
    }
    return true;
  };
  for (const auto& a : args) {
    if (!validateIntegerArg(a)) {
      setError(ctx, fnName + STR_PAR_EXPECTS_INTEGER_VALUES);
      return makeScalar(0);
    }
  }

  EvalValue out;
  if (args.size() == 1) {
    out = args[0];
  } else {
    const std::size_t totalCount = countFlattenedScalars(args);
    if (totalCount == 0) {
      setError(ctx, fnName + STR_PAR_EXPECTS_AT_LEAST_1);
      return makeScalar(0);
    }
    std::vector<EvalValue> elems;
    elems.reserve(totalCount);
    for (const auto& a : args) {
      if (a.kind == ValueKind::Scalar) {
        elems.emplace_back(a);
      } else {
        for (std::size_t i = 0; i < a.arr.size(); ++i) {
          elems.emplace_back(scalarFromArrayAt(a, i));
        }
      }
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
    setError(ctx, fnName + STR_PAR_EXPECTS_2_ARGUMENT_PAR);
    return makeScalar(0);
  }
  if (args[0].kind == ValueKind::Scalar && args[1].kind == ValueKind::Scalar) {
    const EvalValue::ScalarValue& a = args[0].scalarValue;
    const EvalValue::ScalarValue& b = args[1].scalarValue;
    if (isPureFloatingScalarPair(a, b)) {
      double out = 0.0;
      if (!applyBinary(a.scalar, b.scalar, '^', out)) {
        setError(ctx, STR_NUMERIC_ERROR_IN + fnName + STR_PAR);
        return makeScalar(0);
      }
      return makeScalarMaybeExact(out);
    }
  }
  bool ok = false;
  EvalValue out = mapBinary(args[0], args[1], '^', ok);
  if (!ok) {
    setError(ctx, STR_NUMERIC_ERROR_IN + fnName + STR_PAR);
    return makeScalar(0);
  }
  return out;
}

MathParser::EvalValue MathParser::builtinScalarBinaryFamily(
    EvalContext& ctx,
    const std::string& fnName,
    BuiltinFunctionId id,
    const std::vector<EvalValue>& args) const {
  if (id == BuiltinFunctionId::Clamp) {
    if (args.size() != 3) {
      setError(ctx, fnName + STR_PAR_EXPECTS_3_ARGUMENT_PAR);
      return makeScalar(0);
    }
    if (args[1].kind != ValueKind::Scalar || args[2].kind != ValueKind::Scalar) {
      setError(ctx, fnName + STR_PAR_EXPECTS_SCALAR_MIN_SLASH);
      return makeScalar(0);
    }
    return builtinApplyClamp(ctx, args[0], args[1], args[2]);
  }

  if (args.size() != 2) {
    setError(ctx, fnName + STR_PAR_EXPECTS_2_ARGUMENT_PAR);
    return makeScalar(0);
  }
  const bool hasNonScalarArg = std::any_of(args.begin(), args.end(), [](const EvalValue& v) {
    return v.kind != ValueKind::Scalar;
  });
  if (hasNonScalarArg) {
    const bool numericErrorForNonScalar =
        (id == BuiltinFunctionId::Atan2 || id == BuiltinFunctionId::Hypot);
    setError(
        ctx,
        numericErrorForNonScalar ? (STR_NUMERIC_ERROR_IN + fnName + STR_PAR) : (fnName + STR_PAR_EXPECTS_SCALAR_VALUES));
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
      long long a = 0, b = 0;
      if (!tryGetSignedInt64FromScalar(args[0].scalarValue, a) ||
          !tryGetSignedInt64FromScalar(args[1].scalarValue, b)) {
        setError(ctx, fnName + STR_PAR_EXPECTS_INTEGER_VALUES);
        return makeScalar(0);
      }
      if (id == BuiltinFunctionId::Gcd) {
        return makeScalarInt(gcdInt64(a, b));
      }
      long long g = gcdInt64(a, b);
      if (g == 0) {
        return makeScalarInt(0);
      }
      return makeScalarInt((a / g) * b);
    }
    default:
      break;
  }
  setError(ctx, STR_INTERNAL_ERROR_IN_SCALAR_BINARY_BUILTIN);
  return makeScalar(0);
}

MathParser::EvalValue MathParser::builtinRand(EvalContext& ctx, const std::vector<EvalValue>& args) const {
  const std::string fnName = getFunctionName(BuiltinFunctionId::Rand);
  if (!args.empty()) {
    setError(ctx, fnName + STR_PAR_EXPECTS_0_ARGUMENT_PAR);
    return makeScalar(0);
  }
  return makeScalar(randomUnitScalar());
}

MathParser::EvalValue MathParser::builtinModCall(EvalContext& ctx, const std::vector<EvalValue>& args) const {
  const std::string fnName = getFunctionName(BuiltinFunctionId::Mod);
  if (args.size() != 2) {
    setError(ctx, fnName + STR_PAR_EXPECTS_2_ARGUMENT_PAR);
    return makeScalar(0);
  }
  if (args[0].kind != ValueKind::Scalar || args[1].kind != ValueKind::Scalar) {
    setError(ctx, fnName + STR_PAR_EXPECTS_SCALAR_VALUES);
    return makeScalar(0);
  }
  long long a = 0, b = 0;
  if (!tryGetSignedInt64FromScalar(args[0].scalarValue, a) ||
      !tryGetSignedInt64FromScalar(args[1].scalarValue, b)) {
    setError(ctx, fnName + STR_PAR_EXPECTS_INTEGER_VALUES);
    return makeScalar(0);
  }
  if (b == 0) {
    setError(ctx, STR_NUMERIC_ERROR_IN + fnName + STR_PAR);
    return makeScalar(0);
  }
  return makeScalarInt(a % b);
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
    setError(ctx, fnName + STR_PAR_EXPECTS_1_ARGUMENT_PAR);
    return makeScalar(0);
  }
  long long n = 0;
  if (args[0].kind != ValueKind::Scalar || !nearlyInt(args[0].scalarValue.scalar, n) || n < 0) {
    setError(ctx, fnName + STR_PAR_EXPECTS_A_NON_DASH);
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
    setError(ctx, fnName + STR_PAR_EXPECTS_AT_LEAST_1);
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
  const std::size_t totalCount = countFlattenedScalars(args);
  if (totalCount == 0) {
    setError(ctx, fnName + STR_PAR_EXPECTS_AT_LEAST_1);
    return makeScalar(0);
  }

  std::vector<double> out;
  out.reserve(totalCount);
  for (const auto& a : args) {
    if (a.kind == ValueKind::Scalar) {
      const double x = a.scalarValue.scalar;
      out.emplace_back(toDeg ? (x * 180.0 / kPi) : (x * kPi / 180.0));
    } else {
      for (const auto& item : a.arr) {
        const double x = item.scalar;
        out.emplace_back(toDeg ? (x * 180.0 / kPi) : (x * kPi / 180.0));
      }
    }
  }
  return makeArray(out);
}

MathParser::EvalValue MathParser::builtinUnaryMath(
    EvalContext& ctx,
    const std::string& fnName,
    BuiltinFunctionId id,
    const std::vector<EvalValue>& args) const {
  if (args.size() != 1) {
    setError(ctx, fnName + STR_PAR_EXPECTS_1_ARGUMENT_PAR);
    return makeScalar(0);
  }
  if (args[0].kind == ValueKind::Scalar) {
    const EvalValue::ScalarValue& s = args[0].scalarValue;
    const double x = args[0].scalarValue.scalar;
    switch (id) {
      case BuiltinFunctionId::Sin: return makeScalarMaybeExact(std::sin(x));
      case BuiltinFunctionId::Cos: return makeScalarMaybeExact(std::cos(x));
      case BuiltinFunctionId::Tan: return makeScalarMaybeExact(std::tan(x));
      case BuiltinFunctionId::Asin:
      case BuiltinFunctionId::Arcsin: return makeScalarMaybeExact(std::asin(x));
      case BuiltinFunctionId::Acos:
      case BuiltinFunctionId::Arccos: return makeScalarMaybeExact(std::acos(x));
      case BuiltinFunctionId::Atan:
      case BuiltinFunctionId::Arctan: return makeScalarMaybeExact(std::atan(x));
      case BuiltinFunctionId::Sinh: return makeScalarMaybeExact(std::sinh(x));
      case BuiltinFunctionId::Cosh: return makeScalarMaybeExact(std::cosh(x));
      case BuiltinFunctionId::Tanh: return makeScalarMaybeExact(std::tanh(x));
      case BuiltinFunctionId::Exp: return makeScalarMaybeExact(std::exp(x));
      case BuiltinFunctionId::Log10: return makeScalarMaybeExact(std::log10(x));
      case BuiltinFunctionId::Ln: return makeScalarMaybeExact(std::log(x));
      case BuiltinFunctionId::Sqrt: return makeScalarMaybeExact(std::sqrt(x));
      case BuiltinFunctionId::Sqr: return makeScalarMaybeExact(x * x);
      case BuiltinFunctionId::Abs: return makeScalarMaybeExact(std::fabs(x));
      case BuiltinFunctionId::Floor:
        if (s.hasExactInt()) return makeScalarInt(s.exactInt);
        if (s.hasExactUInt64() && s.exactUInt64 <= static_cast<std::uint64_t>((std::numeric_limits<long long>::max)())) {
          return makeScalarInt(static_cast<long long>(s.exactUInt64));
        }
        return makeScalarInt(static_cast<long long>(std::floor(x)));
      case BuiltinFunctionId::Ceil:
        if (s.hasExactInt()) return makeScalarInt(s.exactInt);
        if (s.hasExactUInt64() && s.exactUInt64 <= static_cast<std::uint64_t>((std::numeric_limits<long long>::max)())) {
          return makeScalarInt(static_cast<long long>(s.exactUInt64));
        }
        return makeScalarInt(static_cast<long long>(std::ceil(x)));
      case BuiltinFunctionId::Trunc:
      case BuiltinFunctionId::Int:
        if (s.hasExactInt()) return makeScalarInt(s.exactInt);
        if (s.hasExactUInt64() && s.exactUInt64 <= static_cast<std::uint64_t>((std::numeric_limits<long long>::max)())) {
          return makeScalarInt(static_cast<long long>(s.exactUInt64));
        }
        return makeScalarInt(static_cast<long long>(std::trunc(x)));
      case BuiltinFunctionId::Round:
        if (s.hasExactInt()) return makeScalarInt(s.exactInt);
        if (s.hasExactUInt64() && s.exactUInt64 <= static_cast<std::uint64_t>((std::numeric_limits<long long>::max)())) {
          return makeScalarInt(static_cast<long long>(s.exactUInt64));
        }
        return makeScalarInt(static_cast<long long>(std::round(x)));
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
      return mapUnaryFn(args[0], std::sin);
    case BuiltinFunctionId::Cos:
      return mapUnaryFn(args[0], std::cos);
    case BuiltinFunctionId::Tan:
      return mapUnaryFn(args[0], std::tan);
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
      return mapUnaryFn(args[0], std::fabs);
    case BuiltinFunctionId::Floor:
    case BuiltinFunctionId::Ceil:
    case BuiltinFunctionId::Trunc:
    case BuiltinFunctionId::Int:
    case BuiltinFunctionId::Round:
    case BuiltinFunctionId::Sign: {
      auto intFunc = [&](double x) -> long long {
        if (id == BuiltinFunctionId::Floor) return static_cast<long long>(std::floor(x));
        if (id == BuiltinFunctionId::Ceil) return static_cast<long long>(std::ceil(x));
        if (id == BuiltinFunctionId::Round) return static_cast<long long>(std::round(x));
        if (id == BuiltinFunctionId::Sign) return (x > 0.0) ? 1LL : ((x < 0.0) ? -1LL : 0LL);
        return static_cast<long long>(std::trunc(x)); // trunc/int
      };
      if (args[0].kind == ValueKind::Scalar) {
        return makeScalarInt(intFunc(args[0].scalarValue.scalar));
      }
      std::vector<EvalValue> outVals;
      outVals.reserve(args[0].arr.size());
      for (const auto& e : args[0].arr) {
        outVals.emplace_back(makeScalarInt(intFunc(e.scalar)));
      }
      return makeArrayFromScalars(outVals);
    }
    case BuiltinFunctionId::Frac:
    case BuiltinFunctionId::Fract:
      return mapUnaryFn(args[0], fracScalar);
    default:
      break;
  }
  setError(ctx, STR_INTERNAL_ERROR_IN_UNARY_MATH_BUILTIN);
  return makeScalar(0);
}

MathParser::EvalValue MathParser::builtinApplyLogWithBase(
    EvalContext& ctx,
    const EvalValue& valueV,
    const EvalValue& baseV) const {
  const std::string errFn = getFunctionName(BuiltinFunctionId::Log);
  const auto failNumericError = [&]() -> EvalValue {
    setError(ctx, STR_NUMERIC_ERROR_IN + errFn + STR_PAR);
    return makeScalar(0);
  };
  const auto evalLogScalar = [&](double value, double base, EvalValue& out) -> bool {
    if (value <= 0.0 || base <= 0.0 || base == 1.0) {
      return false;
    }
    out = makeScalar(std::log(value) / std::log(base));
    return true;
  };
  if (valueV.kind == ValueKind::Scalar && baseV.kind == ValueKind::Scalar) {
    EvalValue out;
    if (!evalLogScalar(valueV.scalarValue.scalar, baseV.scalarValue.scalar, out)) {
      return failNumericError();
    }
    return out;
  }
  scratchLogOut_.clear();
  if (valueV.kind == ValueKind::Array && baseV.kind == ValueKind::Array) {
    if (valueV.arr.size() != baseV.arr.size()) {
      return failNumericError();
    }
    scratchLogOut_.reserve(valueV.arr.size());
    for (std::size_t i = 0; i < valueV.arr.size(); ++i) {
      EvalValue out;
      if (!evalLogScalar(valueV.arr[i].scalar, baseV.arr[i].scalar, out)) {
        scratchLogOut_.clear();
        return failNumericError();
      }
      scratchLogOut_.emplace_back(std::move(out));
    }
    EvalValue ret = makeArrayFromScalars(scratchLogOut_);
    scratchLogOut_.clear();
    return ret;
  }
  if (valueV.kind == ValueKind::Array) {
    if (baseV.kind == ValueKind::Scalar) {
      const double base = baseV.scalarValue.scalar;
      if (base <= 0.0 || base == 1.0) {
        return failNumericError();
      }
      const double logBase = std::log(base);
      scratchLogOut_.reserve(valueV.arr.size());
      for (const auto& item : valueV.arr) {
        if (item.scalar <= 0.0) {
          scratchLogOut_.clear();
          return failNumericError();
        }
        scratchLogOut_.emplace_back(makeScalar(std::log(item.scalar) / logBase));
      }
      EvalValue ret = makeArrayFromScalars(scratchLogOut_);
      scratchLogOut_.clear();
      return ret;
    }
    return failNumericError();
  }
  if (baseV.kind == ValueKind::Array) {
    scratchLogOut_.reserve(baseV.arr.size());
    for (std::size_t i = 0; i < baseV.arr.size(); ++i) {
      EvalValue out;
      if (!evalLogScalar(valueV.scalarValue.scalar, baseV.arr[i].scalar, out)) {
        scratchLogOut_.clear();
        return failNumericError();
      }
      scratchLogOut_.emplace_back(std::move(out));
    }
    EvalValue ret = makeArrayFromScalars(scratchLogOut_);
    scratchLogOut_.clear();
    return ret;
  }
  return failNumericError();
}

MathParser::EvalValue MathParser::builtinApplyClamp(
    EvalContext& ctx,
    const EvalValue& valueV,
    const EvalValue& minV,
    const EvalValue& maxV) const {
  if (minV.kind != ValueKind::Scalar || maxV.kind != ValueKind::Scalar) {
    setError(ctx, getFunctionName(BuiltinFunctionId::Clamp) + STR_PAR_EXPECTS_SCALAR_MIN_SLASH);
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
  setError(ctx, STR_NUMERIC_ERROR_IN_CLAMP_PAR);
  return makeScalar(0);
}

MathParser::EvalValue MathParser::builtinLog(EvalContext& ctx, const std::vector<EvalValue>& args) const {
  const std::string fnName = getFunctionName(BuiltinFunctionId::Log);
  if (args.size() != 2) {
    setError(ctx, fnName + STR_PAR_EXPECTS_2_ARGUMENT_PAR);
    return makeScalar(0);
  }
  return builtinApplyLogWithBase(ctx, args[0], args[1]);
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
    setError(ctx, fnName + STR_PAR_EXPECTS + std::to_string(uf->params.size()) + STR_ARGUMENT_PAR_S);
    return makeScalar(0);
  }
  if (ctx.evalDepth >= kMaxEvalDepth) {
    setError(ctx, STR_MAX_EVALUATION_DEPTH_REACHED);
    return makeScalar(0);
  }

  for (const std::string& active : userFunctionCallStack_) {
    if (active == fnName) {
      setError(ctx, STR_RECURSIVE_USER_FUNCTION_CALL_COLON + fnName);
      return makeScalar(0);
    }
  }
  if (userFunctionCallStack_.size() >= static_cast<std::size_t>(kMaxEvalDepth)) {
    setError(ctx, STR_USER_FUNCTION_CALL_STACK_OVERFLOW);
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
      setError(ctx, STR_UNEXPECTED_TRAILING_INPUT);
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
    std::vector<EvalValue> args,
    BuiltinFunctionId preboundId,
    const std::unordered_map<std::string, EvalValue>* scopedVars) {
  normalizeCallArgs(args);

  BuiltinFunctionId id = preboundId;
  if (id == BuiltinFunctionId::Count && !tryGetBuiltinFunctionId(fnName, id)) {
    return evalUserFunctionCall(ctx, fnName, args, scopedVars);
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
  hasResult_ = false;
  lastError_.clear();
  compiledProgram_.clear();
  hasCompiledProgram_ = false;
  compiledScalarOnly_ = false;
  compiledHasAssignments_ = false;
  boundVariablesVersion_ = static_cast<std::size_t>(-1);

  EvalContext ctx;
  ctx.sourceExpr = stripLineComments(mathExpression);
  ctx.p = ctx.sourceExpr.c_str();
  ctx.start = ctx.p;

  std::vector<AstStatement> program;
  if (!parseProgram(ctx, program)) {
    if (!ctx.parseError) {
      setError(ctx, STR_PARSE_FAILED);
    }
    lastError_ = ctx.errorText;
    return false;
  }
  skipSpaces(ctx);
  if (!ctx.parseError && *ctx.p != '\0') {
    setError(ctx, STR_UNEXPECTED_TRAILING_INPUT);
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
  hasResult_ = false;
  lastError_.clear();
  lastResult_ = makeScalar(0);
  userFunctionCallStack_.clear();

  if (!hasCompiledProgram_) {
    lastError_ = STR_NOTHING_COMPILED_SEMICOLON_CALL_COMPILE_PAR;
    return;
  }
  if (boundVariablesVersion_ != variablesVersion_) {
    bindCompiledVariableRefs();
  }
  if (compiledProgram_.empty()) {
    // Mirrors Basic smoke behavior for comment-only / empty input: no result, no error.
    return;
  }

  EvalContext ctx;
  ctx.start = nullptr;
  ctx.p = nullptr;
  EvalValue out = runCompiledProgram(ctx, compiledProgram_, nullptr, compiledScalarOnly_);
  if (ctx.parseError) {
    lastError_ = ctx.errorText;
    return;
  }
  if (!ctx.unknownVarsText.empty()) {
    lastError_ = STR_UNKNOWN_VARIABLE_COLON + ctx.unknownVarsText;
    if (!ctx.unknownFuncsText.empty()) {
      lastError_ += STR_SEMICOLON_UNKNOWN_FUNCTION_COLON + ctx.unknownFuncsText;
    }
    return;
  }
  if (!ctx.unknownFuncsText.empty()) {
    lastError_ = STR_UNKNOWN_FUNCTION_COLON + ctx.unknownFuncsText;
    return;
  }
  lastResult_ = out;
  hasResult_ = true;
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

  {
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
  }

  {
    if (isReservedBuiltinConstantName(fnName)) {
      return STR_RESERVED_CONSTANT_NAME;
    }
    if (isReservedFunctionName(fnName)) {
      return STR_RESERVED_FUNCTION_NAME;
    }
  }

  if (udfBodyCallsDefinedFunction(fnExpr, fnName)) {
    return STR_RECURSIVE_USER_FUNCTION_CALL_COLON + fnName;
  }

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
