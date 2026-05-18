#include "MathParser.hpp"

#include <chrono>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <algorithm>
#include <string>

namespace {

long long rawCartesianToInt64(const MathParser::RawResult::CartesianScalar& s) {
  switch (s.kind) {
    case MathParser::RawResult::ScalarKind::Int64:
      return s.intValue;
    case MathParser::RawResult::ScalarKind::UInt64:
      return static_cast<long long>(s.uintValue);
    case MathParser::RawResult::ScalarKind::Rational:
      return static_cast<long long>(static_cast<double>(s.rational.numerator) /
                                    static_cast<double>(s.rational.denominator));
    case MathParser::RawResult::ScalarKind::FloatingPoint:
    default:
      return static_cast<long long>(s.floatingPoint);
  }
}

long long rawScalarToInt64(const MathParser::RawResult::Scalar& s) {
  if (s.isComplex()) {
    return rawCartesianToInt64(s.real);
  }
  MathParser::RawResult::CartesianScalar cart;
  cart.kind = s.kind;
  switch (s.kind) {
    case MathParser::RawResult::ScalarKind::Int64:
      cart.intValue = s.intValue;
      break;
    case MathParser::RawResult::ScalarKind::UInt64:
      cart.uintValue = s.uintValue;
      break;
    case MathParser::RawResult::ScalarKind::Rational:
      cart.rational.numerator = s.rational.numerator;
      cart.rational.denominator = s.rational.denominator;
      break;
    case MathParser::RawResult::ScalarKind::FloatingPoint:
    default:
      cart.floatingPoint = s.floatingPoint;
      break;
  }
  return rawCartesianToInt64(cart);
}

} // namespace

int main(int argc, char** argv) {
  std::uint64_t iterations = 200000;
  std::uint64_t repeats = 1;
  std::uint64_t warmupRuns = 0;
  if (argc > 1) {
    const std::uint64_t parsed = static_cast<std::uint64_t>(_strtoui64(argv[1], nullptr, 10));
    if (parsed > 0) {
      iterations = parsed;
    }
  }
  if (argc > 2) {
    const std::uint64_t parsed = static_cast<std::uint64_t>(_strtoui64(argv[2], nullptr, 10));
    if (parsed > 0) {
      repeats = parsed;
    }
  }
  if (argc > 3) {
    warmupRuns = static_cast<std::uint64_t>(_strtoui64(argv[3], nullptr, 10));
  }

  double totalElapsedSec = 0.0;
  double totalOpsPerSec = 0.0;
  std::uint64_t totalErrors = 0;
  long long totalChecksum = 0;
  std::uint64_t totalFloatPathCount = 0;
  std::uint64_t totalIntLikePathCount = 0;
  std::vector<double> measuredOpsPerSec;
  measuredOpsPerSec.reserve(static_cast<std::size_t>(repeats));

  const std::uint64_t totalRuns = warmupRuns + repeats;

  for (std::uint64_t run = 0; run < totalRuns; ++run) {
    const bool isWarmup = (run < warmupRuns);
    MathParser parser;
    parser.addConst("myconst1", 123LL);
    parser.addConst("myconst2", 345LL);

    std::uint64_t errors = 0;
    long long checksum = 0;

    const auto t0 = std::chrono::steady_clock::now();
    for (std::uint64_t i = 0; i < iterations; ++i) {
      std::string expr;
      if ((i % 10) == 0) {
        ++totalFloatPathCount;
        expr = "myconst1 / (" + std::to_string(i) + " + 0.5)";
      } else if ((i % 3) == 0) {
        ++totalIntLikePathCount;
        expr = "myconst1 + " + std::to_string(i);
      } else if ((i % 4) == 0) {
        ++totalIntLikePathCount;
        expr = "myconst1 - " + std::to_string(i);
      } else if ((i % 5) == 0) {
        ++totalIntLikePathCount;
        expr = "myconst2 | " + std::to_string(i);
      } else if ((i % 7) == 0) {
        ++totalIntLikePathCount;
        expr = "myconst2 & " + std::to_string(i);
      } else if ((i % 11) == 0) {
        ++totalIntLikePathCount;
        expr = "myconst1 << (" + std::to_string(i) + "%63)";
      } else {
        ++totalIntLikePathCount;
        expr = "((myconst1 & 0xFFFF) + (myconst2 | 0x07)) << (2 + 3)";
      }

      const MathParser::RawResult r = parser.parseAndEvaluateRaw(expr);
      if (!r.hasValue() || !r.isScalar()) {
        ++errors;
        continue;
      }
      checksum += rawScalarToInt64(r.scalar);
    }
    const auto t1 = std::chrono::steady_clock::now();

    const auto elapsedNs = std::chrono::duration_cast<std::chrono::nanoseconds>(t1 - t0).count();
    const double elapsedSec = static_cast<double>(elapsedNs) / 1e9;
    const double opsPerSec = (elapsedSec > 0.0) ? (static_cast<double>(iterations) / elapsedSec) : 0.0;

    std::cout << "run: " << (run + 1) << "/" << totalRuns;
    if (isWarmup) {
      std::cout << " (warmup)";
    }
    std::cout << "\n";
    std::cout << "elapsed_sec: " << elapsedSec << "\n";
    std::cout << "ops_per_sec: " << opsPerSec << "\n";
    std::cout << "checksum: " << checksum << "\n";
    std::cout << "errors: " << errors << "\n";

    if (!isWarmup) {
      totalElapsedSec += elapsedSec;
      totalOpsPerSec += opsPerSec;
      totalChecksum += checksum;
      totalErrors += errors;
      measuredOpsPerSec.push_back(opsPerSec);
    }
  }

  std::cout << "iterations: " << iterations << "\n";
  std::cout << "repeats: " << repeats << "\n";
  std::cout << "warmup_runs: " << warmupRuns << "\n";
  std::cout << "avg_elapsed_sec: " << (totalElapsedSec / static_cast<double>(repeats)) << "\n";
  std::cout << "avg_ops_per_sec: " << (totalOpsPerSec / static_cast<double>(repeats)) << "\n";
  if (!measuredOpsPerSec.empty()) {
    std::sort(measuredOpsPerSec.begin(), measuredOpsPerSec.end());
    const std::size_t n = measuredOpsPerSec.size();
    const double medianOpsPerSec = (n % 2 == 1)
        ? measuredOpsPerSec[n / 2]
        : 0.5 * (measuredOpsPerSec[(n / 2) - 1] + measuredOpsPerSec[n / 2]);
    std::cout << "median_ops_per_sec: " << medianOpsPerSec << "\n";
    std::cout << "min_ops_per_sec: " << measuredOpsPerSec.front() << "\n";
    std::cout << "max_ops_per_sec: " << measuredOpsPerSec.back() << "\n";
  }
  std::cout << "total_checksum: " << totalChecksum << "\n";
  std::cout << "total_errors: " << totalErrors << "\n";
  const std::uint64_t totalOps = iterations * (repeats + warmupRuns);
  const double floatShare = (totalOps > 0) ? (100.0 * static_cast<double>(totalFloatPathCount) / static_cast<double>(totalOps)) : 0.0;
  const double intLikeShare = (totalOps > 0) ? (100.0 * static_cast<double>(totalIntLikePathCount) / static_cast<double>(totalOps)) : 0.0;
  std::cout << "float_path_count: " << totalFloatPathCount << "\n";
  std::cout << "int_like_path_count: " << totalIntLikePathCount << "\n";
  std::cout << "float_path_percent: " << floatShare << "\n";
  std::cout << "int_like_path_percent: " << intLikeShare << "\n";
  return 0;
}
