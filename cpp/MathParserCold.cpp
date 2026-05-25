#include "MathParser.hpp"

#include <algorithm>
#include <cmath>
#include <limits>

bool MathParser::cmpScalarValuesForCompare(
    EvalContext* ctx,
    const EvalValue::ScalarValue& sa,
    const EvalValue::ScalarValue& sb,
    int& cmpOut,
    CmpScalarIncompatiblePolicy policy) const {
  const bool ta = scalarValueIsTime(sa);
  const bool tb = scalarValueIsTime(sb);
  const bool ha = supportComplexNumbers_ && scalarHasNonzeroImaginaryPart(sa);
  const bool hb = supportComplexNumbers_ && scalarHasNonzeroImaginaryPart(sb);
  if ((ha || hb) && (ta || tb)) {
    if (policy == CmpScalarIncompatiblePolicy::SetError && ctx != nullptr) {
      setIncompatibleOperandsError(*ctx);
    }
    cmpOut = (policy == CmpScalarIncompatiblePolicy::SortUniqueReturnOne) ? 1 : 0;
    return policy == CmpScalarIncompatiblePolicy::SortUniqueReturnOne;
  }
  if (ta || tb) {
    long long ams = 0;
    long long bms = 0;
    if (ta) {
      ams = timeTotalMsFromScalarValue(sa);
    } else if (!scalarMsForCompare(sa, ams)) {
      ams = 0;
    }
    if (tb) {
      bms = timeTotalMsFromScalarValue(sb);
    } else if (!scalarMsForCompare(sb, bms)) {
      bms = 0;
    }
    if (ams < bms) {
      cmpOut = -1;
    } else if (ams > bms) {
      cmpOut = 1;
    } else {
      cmpOut = 0;
    }
    return true;
  }
  if (ha || hb) {
    double ar = 0.0;
    double ai = 0.0;
    double br = 0.0;
    double bi = 0.0;
    scalarLoadCartesian(sa, ar, ai);
    scalarLoadCartesian(sb, br, bi);
    if (std::isnan(ar) || std::isnan(ai) || std::isnan(br) || std::isnan(bi)) {
      cmpOut = 1;
      return true;
    }
    if (ar < br) {
      cmpOut = -1;
    } else if (ar > br) {
      cmpOut = 1;
    } else if (ai < bi) {
      cmpOut = -1;
    } else if (ai > bi) {
      cmpOut = 1;
    } else {
      cmpOut = 0;
    }
    return true;
  }
  if (policy == CmpScalarIncompatiblePolicy::SortLess || policy == CmpScalarIncompatiblePolicy::SortGreater) {
    const bool aNan = std::isnan(sa.scalar);
    const bool bNan = std::isnan(sb.scalar);
    if (policy == CmpScalarIncompatiblePolicy::SortLess) {
      if (aNan) {
        cmpOut = bNan ? 0 : -1;
        return true;
      }
      if (bNan) {
        cmpOut = 1;
        return true;
      }
    } else {
      if (bNan) {
        cmpOut = aNan ? 0 : 1;
        return true;
      }
      if (aNan) {
        cmpOut = -1;
        return true;
      }
    }
  }
  if (sa.scalar < sb.scalar) {
    cmpOut = -1;
  } else if (sa.scalar > sb.scalar) {
    cmpOut = 1;
  } else {
    cmpOut = 0;
  }
  return true;
}
