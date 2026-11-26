#include "MathParser.hpp"

#include <cmath>

void MathParser::RawResult::CartesianScalar::clear() {
  kind = ScalarKind::SmFloatingPoint;
  floatingPoint = 0.0;
}

bool MathParser::RawResult::CartesianScalar::isZero() const {
  switch (kind) {
  case ScalarKind::SmInt:
  case ScalarKind::Time:
    return intValue == 0;
  case ScalarKind::SmUInt:
    return uintValue == 0;
  case ScalarKind::Rational:
#if SMARTMATH_FACTORINT
  case ScalarKind::IntPower:
#endif
    return rational.numerator == 0;
  case ScalarKind::SmFloatingPoint:
  case ScalarKind::Complex:
    break;
  }
  if (std::isnan(floatingPoint)) {
    return false;
  }
  return floatingPoint == 0.0;
}

void MathParser::RawResult::clear() {
  kind = Kind::None;
  scalar.kind = ScalarKind::SmFloatingPoint;
  scalar.real.clear();
  scalar.imag.clear();
  array.clear();
}
