#include "MathParser.hpp"

#include <cctype>
#include <cmath>
#include <cstdlib>
#include <limits>
#include <fstream>
#include <functional>
#include <iostream>
#include <set>
#include <string>
#include <unordered_map>
#include <vector>

namespace {

struct TestState {
  int total = 0;
  int passed = 0;
  int failed = 0;
};

struct TestCase {
  std::string name;
  std::function<bool(std::string&)> run;
};

struct ImportedSmokeCase {
  int idx = 0;
  std::string expr;
  std::string expected;
  std::string expectedErrContains;
  bool expectNoResult = false;
};

bool parseQuotedBasicString(const std::string& s, std::size_t quotePos, std::string& out, std::size_t& endPos) {
  if (quotePos >= s.size() || s[quotePos] != '"') {
    return false;
  }
  out.clear();
  std::size_t i = quotePos + 1;
  while (i < s.size()) {
    const char c = s[i];
    if (c == '"') {
      if ((i + 1) < s.size() && s[i + 1] == '"') {
        out.push_back('"');
        i += 2;
        continue;
      }
      endPos = i + 1;
      return true;
    }
    out.push_back(c);
    ++i;
  }
  return false;
}

bool parseOneAssignment(
    const std::string& line,
    std::size_t startPos,
    ImportedSmokeCase& outCase,
    std::size_t& nextPos) {
  const std::size_t testsPos = line.find("tests(", startPos);
  if (testsPos == std::string::npos) {
    return false;
  }
  const std::size_t idxStart = testsPos + 6;
  const std::size_t idxEnd = line.find(')', idxStart);
  if (idxEnd == std::string::npos || idxEnd <= idxStart) {
    return false;
  }
  for (std::size_t i = idxStart; i < idxEnd; ++i) {
    if (!std::isdigit(static_cast<unsigned char>(line[i]))) {
      return false;
    }
  }
  outCase.idx = std::stoi(line.substr(idxStart, idxEnd - idxStart));

  std::size_t dot = line.find('.', idxEnd);
  if (dot == std::string::npos) {
    return false;
  }
  const std::size_t eq = line.find('=', dot + 1);
  if (eq == std::string::npos) {
    return false;
  }
  std::string field = line.substr(dot + 1, eq - (dot + 1));
  while (!field.empty() && std::isspace(static_cast<unsigned char>(field.back()))) {
    field.pop_back();
  }

  std::size_t valPos = eq + 1;
  while (valPos < line.size() && std::isspace(static_cast<unsigned char>(line[valPos]))) {
    ++valPos;
  }

  if (field == "expectNoResult") {
    outCase.expectNoResult = (line.compare(valPos, 4, "TRUE") == 0);
    nextPos = valPos + 4;
    return true;
  }

  if (field == "expr" || field == "expected" || field == "expectedErrContains") {
    std::size_t q = line.find('"', valPos);
    if (q == std::string::npos) {
      return false;
    }
    std::string parsed;
    std::size_t end = 0;
    if (!parseQuotedBasicString(line, q, parsed, end)) {
      return false;
    }
    if (field == "expr") outCase.expr = std::move(parsed);
    else if (field == "expected") outCase.expected = std::move(parsed);
    else outCase.expectedErrContains = std::move(parsed);
    nextPos = end;
    return true;
  }

  return false;
}

bool loadBasicSmokeCases(
    const std::vector<std::string>& candidatePaths,
    std::vector<ImportedSmokeCase>& outCases,
    std::string& err) {
  std::ifstream in;
  std::string chosenPath;
  for (const auto& p : candidatePaths) {
    in.open(p.c_str());
    if (in.is_open()) {
      chosenPath = p;
      break;
    }
    in.clear();
  }
  if (!in.is_open()) {
    err = "cannot open SmokeTest_MathParser.bas from candidate paths";
    return false;
  }

  std::unordered_map<int, ImportedSmokeCase> byIdx;
  std::set<int> seenExpr;
  std::set<int> seenExpected;
  std::set<int> seenExpectedErr;
  std::set<int> seenExpectNoResult;
  std::string line;
  while (std::getline(in, line)) {
    std::size_t pos = 0;
    while (true) {
      ImportedSmokeCase partial;
      std::size_t next = 0;
      if (!parseOneAssignment(line, pos, partial, next)) {
        break;
      }
      auto& c = byIdx[partial.idx];
      c.idx = partial.idx;
      if (!partial.expr.empty()) {
        c.expr = std::move(partial.expr);
        seenExpr.insert(c.idx);
      }
      if (!partial.expected.empty()) {
        c.expected = std::move(partial.expected);
        seenExpected.insert(c.idx);
      }
      if (!partial.expectedErrContains.empty()) {
        c.expectedErrContains = std::move(partial.expectedErrContains);
        seenExpectedErr.insert(c.idx);
      }
      if (partial.expectNoResult) c.expectNoResult = true;
      if (partial.expectNoResult) seenExpectNoResult.insert(c.idx);
      pos = next;
    }
  }

  int maxIdx = 0;
  for (const auto& kv : byIdx) {
    if (kv.first > maxIdx) maxIdx = kv.first;
  }
  outCases.clear();
  outCases.reserve(static_cast<std::size_t>(maxIdx));
  for (int i = 1; i <= maxIdx; ++i) {
    auto it = byIdx.find(i);
    if (it == byIdx.end()) {
      err = "missing imported smoke case index " + std::to_string(i);
      return false;
    }
    outCases.push_back(it->second);
  }

  // Integrity checks: every case must have expression and one expectation mode.
  for (int i = 1; i <= maxIdx; ++i) {
    const auto& c = byIdx[i];
    if (c.expr.empty()) {
      err = "imported smoke case #" + std::to_string(i) + " has empty expr (source: " + chosenPath + ")";
      return false;
    }
    const bool hasExpected = !c.expected.empty();
    const bool hasErr = !c.expectedErrContains.empty();
    const bool hasNoResult = c.expectNoResult;
    const int modes = static_cast<int>(hasExpected) + static_cast<int>(hasErr) + static_cast<int>(hasNoResult);
    if (modes != 1) {
      err = "imported smoke case #" + std::to_string(i) + " has invalid expectation mode count=" + std::to_string(modes);
      return false;
    }
  }

  std::cout << "[INFO] Imported " << maxIdx << " Basic smoke cases from " << chosenPath << "\n";
  return true;
}

std::string trimSmokeToken(std::string s) {
  while (!s.empty() && std::isspace(static_cast<unsigned char>(s.back()))) {
    s.pop_back();
  }
  std::size_t i = 0;
  while (i < s.size() && std::isspace(static_cast<unsigned char>(s[i]))) {
    ++i;
  }
  return s.substr(i);
}

bool tryParseFullDouble(const std::string& s, double& out) {
  const char* p = s.c_str();
  char* e = nullptr;
  out = std::strtod(p, &e);
  if (e == p) {
    return false;
  }
  while (*e != '\0' && std::isspace(static_cast<unsigned char>(*e))) {
    ++e;
  }
  return *e == '\0';
}

std::vector<std::string> splitTopLevelCsvInParens(const std::string& s) {
  std::vector<std::string> parts;
  if (s.size() < 2U || s.front() != '(' || s.back() != ')') {
    return parts;
  }
  std::size_t start = 1;
  for (std::size_t i = 1; i + 1U < s.size(); ++i) {
    if (s[i] == ',') {
      parts.push_back(s.substr(start, i - start));
      start = i + 1;
    }
  }
  parts.push_back(s.substr(start, s.size() - 1U - start));
  return parts;
}

bool smokeScalarCloseEnough(const std::string& actual, const std::string& expected) {
  if (actual == expected) {
    return true;
  }
  double da = 0.0;
  double de = 0.0;
  if (!tryParseFullDouble(actual, da) || !tryParseFullDouble(expected, de)) {
    return false;
  }
  const double p63 = std::ldexp(1.0, 63);
  if (da == p63 || da == -p63 || de == p63 || de == -p63) {
    return false;
  }
  if (da == de) {
    return true;
  }
  if (std::nextafter(da, de) == de || std::nextafter(de, da) == da) {
    return true;
  }
  const double scale = std::max(1.0, std::max(std::fabs(da), std::fabs(de)));
  const double tol = 16.0 * std::numeric_limits<double>::epsilon() * scale;
  return std::fabs(da - de) <= tol;
}

bool smokeResultCloseEnough(const std::string& actual, const std::string& expected) {
  if (actual == expected) {
    return true;
  }
  if (actual.size() >= 2U && expected.size() >= 2U && actual.front() == '(' && expected.front() == '(' &&
      actual.back() == ')' && expected.back() == ')') {
    const std::vector<std::string> pa = splitTopLevelCsvInParens(actual);
    const std::vector<std::string> pe = splitTopLevelCsvInParens(expected);
    if (pa.size() != pe.size()) {
      return false;
    }
    for (std::size_t i = 0; i < pa.size(); ++i) {
      if (!smokeScalarCloseEnough(trimSmokeToken(pa[i]), trimSmokeToken(pe[i]))) {
        return false;
      }
    }
    return true;
  }
  return smokeScalarCloseEnough(actual, expected);
}

bool expectEval(
    MathParser& p,
    const std::string& expr,
    const std::string& expected,
    std::string& why) {
  p.parseAndEvaluate(expr);
  if (!p.getError().empty()) {
    why = "unexpected error: " + p.getError();
    return false;
  }
  const std::string actual = p.getResult();
  if (!smokeResultCloseEnough(actual, expected)) {
    why = "expected \"" + expected + "\", got \"" + actual + "\"";
    return false;
  }
  return true;
}

bool expectEvalErrorContains(
    MathParser& p,
    const std::string& expr,
    const std::string& expectedErrPart,
    std::string& why) {
  p.parseAndEvaluate(expr);
  const std::string err = p.getError();
  if (err.empty()) {
    why = "expected error containing \"" + expectedErrPart + "\", got success";
    return false;
  }
  if (err.find(expectedErrPart) == std::string::npos) {
    why = "expected error containing \"" + expectedErrPart + "\", got \"" + err + "\"";
    return false;
  }
  return true;
}

std::vector<TestCase> buildSmokeCases() {
  std::vector<TestCase> t;
  std::vector<ImportedSmokeCase> imported;
  std::string loadErr;
  const std::vector<std::string> candidates = {
      "SmokeTest_MathParser.bas",
      "..\\SmokeTest_MathParser.bas",
      "..\\..\\SmokeTest_MathParser.bas",
      ".\\SmokeTest_MathParser.bas"};
  if (!loadBasicSmokeCases(candidates, imported, loadErr)) {
    t.push_back({"smoke/import-failure", [loadErr](std::string& why) {
                   why = loadErr;
                   return false;
                 }});
    return t;
  }
  if (imported.empty()) {
    t.push_back({"smoke/import-count", [count = imported.size()](std::string& why) {
                   why = "expected at least 1 imported smoke case, got " + std::to_string(count);
                   return false;
                 }});
    return t;
  }

  for (const auto& c : imported) {
    t.push_back(
        {"smoke/basic#" + std::to_string(c.idx),
         [c](std::string& why) {
           MathParser p;
           p.parseAndEvaluate(c.expr);
           const std::string err = p.getError();
           const std::string result = p.getResult();

           if (c.expectNoResult) {
             if (!err.empty()) {
               why = "expected no error/no result, got error: " + err;
               return false;
             }
             if (!result.empty()) {
               why = "expected no result, got \"" + result + "\"";
               return false;
             }
             return true;
           }
           if (!c.expectedErrContains.empty()) {
             if (err.empty()) {
               why = "expected error containing \"" + c.expectedErrContains + "\", got success with \"" + result + "\"";
               return false;
             }
             if (err.find(c.expectedErrContains) == std::string::npos) {
               why = "expected error containing \"" + c.expectedErrContains + "\", got \"" + err + "\"";
               return false;
             }
             return true;
           }
           if (!err.empty()) {
             why = "unexpected error: " + err;
             return false;
           }
           if (!smokeResultCloseEnough(result, c.expected)) {
             why = "expected \"" + c.expected + "\", got \"" + result + "\"";
             return false;
           }
           return true;
         }});
  }

  return t;
}

std::vector<TestCase> buildUnitCases() {
  std::vector<TestCase> t;

  // C++ API unit tests.
  t.push_back({"unit/addConst int overload", [](std::string& why) {
                 MathParser p;
                 p.addConst("A", 42LL);
                 return expectEval(p, "a+1", "43", why);
               }});
  t.push_back({"unit/addConst double overload", [](std::string& why) {
                 MathParser p;
                 p.addConst("rate", 1.5);
                 return expectEval(p, "rate*8", "12", why);
               }});
  t.push_back({"unit/addUserFunction api", [](std::string& why) {
                 MathParser p;
                 const std::string err = p.addUserFunction("mul3(x)=x*3");
                 if (!err.empty()) {
                   why = "unexpected addUserFunction error: " + err;
                   return false;
                 }
                 return expectEval(p, "mul3(7)", "21", why);
               }});
  t.push_back({"unit/addUserFunction invalid", [](std::string& why) {
                 MathParser p;
                 const std::string err = p.addUserFunction("bad(x)");
                 if (err.empty()) {
                   why = "expected addUserFunction error";
                   return false;
                 }
                 return true;
               }});
  t.push_back({"unit/addUserFunction rejects reserved function name", [](std::string& why) {
                 MathParser p;
                 const std::string err = p.addUserFunction("hex(x)=x");
                 if (err != "reserved function name") {
                   why = "expected reserved function name, got: " + err;
                   return false;
                 }
                 return true;
               }});
  t.push_back({"unit/addUserFunction rejects reserved constant name", [](std::string& why) {
                 MathParser p;
                 const std::string err = p.addUserFunction("e(x)=x");
                 if (err != "reserved constant name") {
                   why = "expected reserved constant name, got: " + err;
                   return false;
                 }
                 return true;
               }});
  t.push_back({"unit/format getResultAsHexOctBinDec", [](std::string& why) {
                 MathParser p;
                 p.parseAndEvaluate("255");
                 if (!p.getError().empty()) {
                   why = p.getError();
                   return false;
                 }
                 if (p.getResultAsHex() != "0xFF") {
                   why = "hex mismatch: " + p.getResultAsHex();
                   return false;
                 }
                 if (p.getResultAsOct() != "0o377") {
                   why = "oct mismatch: " + p.getResultAsOct();
                   return false;
                 }
                 if (p.getResultAsBin() != "0b11111111") {
                   why = "bin mismatch: " + p.getResultAsBin();
                   return false;
                 }
                 if (p.getResultAsDec() != "255") {
                   why = "dec mismatch: " + p.getResultAsDec();
                   return false;
                 }
                 return true;
               }});
  t.push_back({"unit/array formatting in bases", [](std::string& why) {
                 MathParser p;
                 p.parseAndEvaluate("(1,2,5)");
                 if (!p.getError().empty()) {
                   why = p.getError();
                   return false;
                 }
                 if (p.getResultAsHex() != "(0x1,0x2,0x5)") {
                   why = "hex array mismatch: " + p.getResultAsHex();
                   return false;
                 }
                 if (p.getResultAsBin() != "(0b1,0b10,0b101)") {
                   why = "bin array mismatch: " + p.getResultAsBin();
                   return false;
                 }
                 return true;
               }});
  t.push_back({"unit/error clears result text", [](std::string& why) {
                 MathParser p;
                 p.parseAndEvaluate("2+3");
                 if (p.getResult() != "5") {
                   why = "setup failed";
                   return false;
                 }
                 p.parseAndEvaluate("unknownVar");
                 if (p.getError().empty()) {
                   why = "expected error";
                   return false;
                 }
                 if (!p.getResult().empty()) {
                   why = "result should be empty on error";
                   return false;
                 }
                 return true;
               }});
  t.push_back({"unit/getRawResult scalar int/float", [](std::string& why) {
                 MathParser p;
                 p.parseAndEvaluate("2+3");
                 if (!p.getError().empty()) {
                   why = p.getError();
                   return false;
                 }
                 MathParser::RawResult r = p.getRawResult();
                 if (!r.isScalar() || r.scalar.kind != MathParser::RawResult::ScalarKind::Int64 || r.scalar.intValue != 5LL) {
                   why = "expected scalar int64=5";
                   return false;
                 }

                 p.parseAndEvaluate("1/2");
                 if (!p.getError().empty()) {
                   why = p.getError();
                   return false;
                 }
                 r = p.getRawResult();
                 if (!r.isScalar() || r.scalar.kind != MathParser::RawResult::ScalarKind::FloatingPoint ||
                     std::fabs(r.scalar.floatingPoint - 0.5) > 1e-12) {
                   why = "expected scalar float=0.5";
                   return false;
                 }
                 return true;
               }});
  t.push_back({"unit/getRawResult array and error state", [](std::string& why) {
                 MathParser p;
                 p.parseAndEvaluate("(1,2.5,3)");
                 if (!p.getError().empty()) {
                   why = p.getError();
                   return false;
                 }
                 MathParser::RawResult r = p.getRawResult();
                 if (!r.isArray() || r.array.size() != 3) {
                   why = "expected array[3]";
                   return false;
                 }
                 if (r.array[0].kind != MathParser::RawResult::ScalarKind::Int64 || r.array[0].intValue != 1LL) {
                   why = "array[0] mismatch";
                   return false;
                 }
                 if (r.array[1].kind != MathParser::RawResult::ScalarKind::FloatingPoint ||
                     std::fabs(r.array[1].floatingPoint - 2.5) > 1e-12) {
                   why = "array[1] mismatch";
                   return false;
                 }
                 if (r.array[2].kind != MathParser::RawResult::ScalarKind::Int64 || r.array[2].intValue != 3LL) {
                   why = "array[2] mismatch";
                   return false;
                 }

                 p.parseAndEvaluate("unknownVar");
                 r = p.getRawResult();
                 if (r.hasValue()) {
                   why = "expected no raw value on error";
                   return false;
                 }
                 return true;
               }});
  t.push_back({"unit/parseAndEvaluateRaw returns raw and empty on error", [](std::string& why) {
                 MathParser p;
                 MathParser::RawResult r = p.parseAndEvaluateRaw("10+20");
                 if (!p.getError().empty()) {
                   why = p.getError();
                   return false;
                 }
                 if (!r.isScalar() || r.scalar.kind != MathParser::RawResult::ScalarKind::Int64 || r.scalar.intValue != 30LL) {
                   why = "expected scalar int64=30";
                   return false;
                 }

                 r = p.parseAndEvaluateRaw("unknownVar");
                 if (!r.hasValue()) {
                   return true;
                 }
                 why = "expected empty raw result on error";
                 return false;
               }});

  return t;
}

std::vector<TestCase> buildEdgeIntFloatCases() {
  std::vector<TestCase> t;
  const long long kLLMax = std::numeric_limits<long long>::max();
  const long long kLLMin = std::numeric_limits<long long>::min();
  const long long kPow53 = 9007199254740992LL;  // 2^53

  t.push_back({"edge/ll const 0 add and hex", [](std::string& why) {
                 MathParser p;
                 p.addConst("k", 0LL);
                 if (!expectEval(p, "k+0", "0", why)) {
                   return false;
                 }
                 return expectEval(p, "hex(k)", "0x0", why);
               }});
  t.push_back({"edge/ll const 1 square and hex", [](std::string& why) {
                 MathParser p;
                 p.addConst("k", 1LL);
                 if (!expectEval(p, "k*k", "1", why)) {
                   return false;
                 }
                 return expectEval(p, "hex(k)", "0x1", why);
               }});
  t.push_back({"edge/ll const 100 add and hex", [](std::string& why) {
                 MathParser p;
                 p.addConst("k", 100LL);
                 if (!expectEval(p, "k+1", "101", why)) {
                   return false;
                 }
                 return expectEval(p, "hex(k)", "0x64", why);
               }});
  t.push_back({"edge/ll const 1000000 add and hex", [](std::string& why) {
                 MathParser p;
                 p.addConst("k", 1000000LL);
                 if (!expectEval(p, "k+1", "1000001", why)) {
                   return false;
                 }
                 return expectEval(p, "hex(k)", "0xF4240", why);
               }});

  t.push_back({"edge/double const 0 rejects hex()", [](std::string& why) {
                 MathParser p;
                 p.addConst("k", 0.0);
                 return expectEvalErrorContains(p, "hex(k)", "hex() expects integer values", why);
               }});
  t.push_back({"edge/double const 1 rejects hex()", [](std::string& why) {
                 MathParser p;
                 p.addConst("k", 1.0);
                 return expectEvalErrorContains(p, "hex(k)", "hex() expects integer values", why);
               }});
  t.push_back({"edge/double const 100 rejects hex()", [](std::string& why) {
                 MathParser p;
                 p.addConst("k", 100.0);
                 return expectEvalErrorContains(p, "hex(k)", "hex() expects integer values", why);
               }});
  t.push_back({"edge/double const 1000000 rejects hex()", [](std::string& why) {
                 MathParser p;
                 p.addConst("k", 1000000.0);
                 return expectEvalErrorContains(p, "hex(k)", "hex() expects integer values", why);
               }});
  t.push_back({"edge/hex array with non-integer element rejects", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "hex((1,2.5,3))", "hex() expects integer values", why);
              }});

  t.push_back({"edge/double const 0 same add as ll", [](std::string& why) {
                 MathParser pD;
                 MathParser pI;
                 pD.addConst("k", 0.0);
                 pI.addConst("k", 0LL);
                 pD.parseAndEvaluate("k+1");
                 pI.parseAndEvaluate("k+1");
                 if (!pD.getError().empty() || pD.getResult() != "1") {
                   why = "double const: " + pD.getError() + " / " + pD.getResult();
                   return false;
                 }
                 if (!pI.getError().empty() || pI.getResult() != "1") {
                   why = "ll const: " + pI.getError() + " / " + pI.getResult();
                   return false;
                 }
                 return true;
               }});
  t.push_back({"edge/double const 1 same mul as ll", [](std::string& why) {
                 MathParser pD;
                 MathParser pI;
                 pD.addConst("k", 1.0);
                 pI.addConst("k", 1LL);
                 pD.parseAndEvaluate("k*42");
                 pI.parseAndEvaluate("k*42");
                 return pD.getResult() == pI.getResult() && pD.getResult() == "42" && pD.getError().empty() &&
                        pI.getError().empty();
               }});
  t.push_back({"edge/double const 100 same add1 as ll", [](std::string& why) {
                 MathParser pD;
                 MathParser pI;
                 pD.addConst("k", 100.0);
                 pI.addConst("k", 100LL);
                 pD.parseAndEvaluate("k+1");
                 pI.parseAndEvaluate("k+1");
                 if (pD.getResult() != "101" || pI.getResult() != "101") {
                   why = "mismatch double vs ll";
                   return false;
                 }
                 return pD.getError().empty() && pI.getError().empty();
               }});
  t.push_back({"edge/double const 1000000 same add1 as ll", [](std::string& why) {
                 MathParser pD;
                 MathParser pI;
                 pD.addConst("k", 1000000.0);
                 pI.addConst("k", 1000000LL);
                 pD.parseAndEvaluate("k+1");
                 pI.parseAndEvaluate("k+1");
                 if (pD.getResult() != "1000001" || pI.getResult() != "1000001") {
                   why = "mismatch double vs ll";
                   return false;
                 }
                 return pD.getError().empty() && pI.getError().empty();
               }});

  t.push_back({"edge/ll max plus zero", [kLLMax](std::string& why) {
                 MathParser p;
                 p.addConst("k", kLLMax);
                 return expectEval(p, "k+0", "9223372036854775807", why);
               }});
  t.push_back({"edge/ll min plus zero", [kLLMin](std::string& why) {
                 MathParser p;
                 p.addConst("k", kLLMin);
                 return expectEval(p, "k+0", "-9223372036854775808", why);
               }});
  t.push_back({"edge/ll max minus one plus one", [kLLMax](std::string& why) {
                 MathParser p;
                 p.addConst("k", kLLMax);
                 return expectEval(p, "(k-1)+1", "9223372036854775807", why);
               }});

  t.push_back({"edge/ll 2^53 plus 1 hex", [kPow53](std::string& why) {
                 MathParser p;
                 p.addConst("k", kPow53);
                 return expectEval(p, "hex(k+1)", "0x20000000000001", why);
               }});
  t.push_back({"edge/double 2^53 plus 1 rounds in IEEE double", [kPow53](std::string& why) {
                 MathParser p;
                 p.addConst("k", static_cast<double>(kPow53));
                 // 2^53+1 is not representable; +1 rounds back to 2^53.
                 return expectEval(p, "k+1", "9007199254740992", why);
               }});

  t.push_back({"edge/gcd ll const integer path", [](std::string& why) {
                 MathParser p;
                 p.addConst("a", 100LL);
                 return expectEval(p, "gcd(a,25)", "25", why);
               }});
  t.push_back({"edge/gcd uint64-above-signed-range rejects", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(
                    p, "gcd(18446744073709551615,3)", "gcd() expects integer values", why);
              }});
  t.push_back({"edge/gcd double const integer-valued", [](std::string& why) {
                 MathParser p;
                 p.addConst("a", 100.0);
                 return expectEval(p, "gcd(a,25)", "25", why);
               }});
  t.push_back({"edge/lcm uint64-above-signed-range rejects", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(
                    p, "lcm(18446744073709551615,3)", "lcm() expects integer values", why);
              }});
  t.push_back({"edge/mod ll const", [](std::string& why) {
                 MathParser p;
                 p.addConst("a", 100LL);
                 return expectEval(p, "mod(a,3)", "1", why);
               }});
  t.push_back({"edge/mod operator uint64-above-signed-range rejects", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(
                    p, "18446744073709551615%3", "modulo operands must be integer values", why);
              }});
  t.push_back({"edge/mod double const integer-valued", [](std::string& why) {
                 MathParser p;
                 p.addConst("a", 100.0);
                 return expectEval(p, "mod(a,3)", "1", why);
               }});
  t.push_back({"edge/mod double const fractional rejects", [](std::string& why) {
                 MathParser p;
                 p.addConst("a", 100.5);
                 return expectEvalErrorContains(p, "mod(a,3)", "mod() expects integer values", why);
               }});
  t.push_back({"edge/mod builtin uint64-above-signed-range rejects", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(
                    p, "mod(18446744073709551615,3)", "mod() expects integer values", why);
              }});

  t.push_back({"edge/bitand ll const", [](std::string& why) {
                 MathParser p;
                 p.addConst("a", 100LL);
                 return expectEval(p, "a&7", "4", why);
               }});
  t.push_back({"edge/bitand double const integer-valued ok", [](std::string& why) {
                 MathParser p;
                 p.addConst("a", 100.0);
                 return expectEval(p, "a&7", "4", why);
               }});
  t.push_back({"edge/bitand double const fractional rejects", [](std::string& why) {
                 MathParser p;
                 p.addConst("a", 100.5);
                 return expectEvalErrorContains(p, "a&7", "bitwise operands must be integer values", why);
               }});

  t.push_back({"edge/int() strips double const fraction", [](std::string& why) {
                 MathParser p;
                 p.addConst("x", 100.7);
                 return expectEval(p, "int(x)", "100", why);
               }});
  t.push_back({"edge/int() ll const still exact", [](std::string& why) {
                 MathParser p;
                 p.addConst("x", 100LL);
                 return expectEval(p, "int(x)", "100", why);
               }});

  t.push_back({"edge/double const 1e12 add matches literal", [](std::string& why) {
                 MathParser p;
                 p.addConst("k", 1e12);
                 p.parseAndEvaluate("k+1");
                 if (!p.getError().empty()) {
                   why = p.getError();
                   return false;
                 }
                 if (p.getResult() != "1000000000001") {
                   why = "got " + p.getResult();
                   return false;
                 }
                 return true;
               }});

  t.push_back({"edge/ll const near double int limit", [](std::string& why) {
                 MathParser p;
                 p.addConst("k", 9007199254740991LL);  // 2^53 - 1
                 return expectEval(p, "k+1", "9007199254740992", why);
               }});

  // --- LLONG_MAX / LLONG_MIN neighbors (exact int path) ---
  t.push_back({"edge/ll const max minus one plus one", [kLLMax](std::string& why) {
                 MathParser p;
                 p.addConst("k", kLLMax - 1);
                 return expectEval(p, "k+1", "9223372036854775807", why);
               }});
  t.push_back({"edge/ll const max minus one identity", [kLLMax](std::string& why) {
                 MathParser p;
                 p.addConst("k", kLLMax - 1);
                 return expectEval(p, "k+0", "9223372036854775806", why);
               }});
  t.push_back({"edge/ll const min plus one minus one", [kLLMin](std::string& why) {
                 MathParser p;
                 p.addConst("k", kLLMin + 1);
                 return expectEval(p, "k-1", "-9223372036854775808", why);
               }});
  t.push_back({"edge/ll const min plus one identity", [kLLMin](std::string& why) {
                 MathParser p;
                 p.addConst("k", kLLMin + 1);
                 return expectEval(p, "k+0", "-9223372036854775807", why);
               }});

  t.push_back({"edge/literal max minus one plus one", [](std::string& why) {
                 MathParser p;
                 return expectEval(p, "9223372036854775806+1", "9223372036854775807", why);
               }});
  t.push_back({"edge/literal min plus one minus one", [](std::string& why) {
                 MathParser p;
                 return expectEval(p, "-9223372036854775807-1", "-9223372036854775808", why);
               }});
  t.push_back({"edge/literal min plus one plus zero", [](std::string& why) {
                 MathParser p;
                 return expectEval(p, "-9223372036854775807+0", "-9223372036854775807", why);
               }});

  t.push_back({"edge/hex ll max minus one", [kLLMax](std::string& why) {
                 MathParser p;
                 p.addConst("k", kLLMax - 1);
                 return expectEval(p, "hex(k)", "0x7FFFFFFFFFFFFFFE", why);
               }});
  t.push_back({"edge/hex ll min plus one", [kLLMin](std::string& why) {
                 MathParser p;
                 p.addConst("k", kLLMin + 1);
                 return expectEval(p, "hex(k)", "-0x7FFFFFFFFFFFFFFF", why);
               }});
  t.push_back({"edge/uhex ll min plus one", [kLLMin](std::string& why) {
                 MathParser p;
                 p.addConst("k", kLLMin + 1);
                 return expectEval(p, "uhex(k)", "0x8000000000000001", why);
               }});

  // --- Double vs ll at 2^53: (2^53-1)+2 is 2^53+1, not representable in double; rounds to 2^53 ---
  t.push_back({"edge/double 2^53 minus 1 plus 2 rounds to 2^53", [kPow53](std::string& why) {
                 MathParser p;
                 p.addConst("k", static_cast<double>(kPow53 - 1));
                 return expectEval(p, "k+2", "9007199254740992", why);
               }});
  t.push_back({"edge/ll 2^53 minus 1 plus 2 exact", [kPow53](std::string& why) {
                 MathParser p;
                 p.addConst("k", kPow53 - 1);
                 return expectEval(p, "k+2", "9007199254740993", why);
               }});
  t.push_back({"edge/double 2^53 plus 2 no rounding loss", [kPow53](std::string& why) {
                 MathParser p;
                 p.addConst("k", static_cast<double>(kPow53));
                 return expectEval(p, "k+2", "9007199254740994", why);
               }});
  t.push_back({"edge/double vs ll 2^53 minus 1 plus 2 differ (IEEE)", [kPow53](std::string& why) {
                 MathParser pD;
                 MathParser pI;
                 pD.addConst("k", static_cast<double>(kPow53 - 1));
                 pI.addConst("k", kPow53 - 1);
                 pD.parseAndEvaluate("k+2");
                 pI.parseAndEvaluate("k+2");
                 if (!pD.getError().empty() || !pI.getError().empty()) {
                   why = pD.getError() + " / " + pI.getError();
                   return false;
                 }
                 if (pD.getResult() == pI.getResult()) {
                   why = "expected double path to round differently from exact ll";
                   return false;
                 }
                 if (pD.getResult() != "9007199254740992" || pI.getResult() != "9007199254740993") {
                   why = "double " + pD.getResult() + " vs ll " + pI.getResult();
                   return false;
                 }
                 return true;
               }});

  // LLONG_MAX as double loses precision vs ll const (platform IEEE round)
  t.push_back({"edge/double ll max const differs from ll max", [kLLMax](std::string& why) {
                 MathParser pLl;
                 MathParser pD;
                 pLl.addConst("k", kLLMax);
                 pD.addConst("k", static_cast<double>(kLLMax));
                 pLl.parseAndEvaluate("k+0");
                 pD.parseAndEvaluate("k+0");
                 if (pLl.getError().empty() && pD.getError().empty() && pLl.getResult() == pD.getResult()) {
                   why = "expected double const to differ from ll max (precision loss)";
                   return false;
                 }
                 return pLl.getResult() == "9223372036854775807" && pD.getError().empty();
               }});

  t.push_back({"edge/int double 2^53 minus 1", [kPow53](std::string& why) {
                 MathParser p;
                 p.addConst("k", static_cast<double>(kPow53 - 1));
                 return expectEval(p, "int(k)", "9007199254740991", why);
               }});
  t.push_back({"edge/int ll 2^53 minus 1", [kPow53](std::string& why) {
                 MathParser p;
                 p.addConst("k", kPow53 - 1);
                 return expectEval(p, "int(k)", "9007199254740991", why);
               }});

  // Exact-int recovery after float-path operations (scalar).
  t.push_back({"edge/scalar sqrt perfect square keeps int metadata for bitwise", [](std::string& why) {
                 MathParser p;
                 return expectEval(p, "sqrt(81)&7", "1", why);
               }});
  t.push_back({"edge/scalar sqrt perfect square keeps int metadata for hex", [](std::string& why) {
                 MathParser p;
                 return expectEval(p, "hex(sqrt(81))", "0x9", why);
               }});
  t.push_back({"edge/scalar abs keeps int metadata for modulo", [](std::string& why) {
                 MathParser p;
                 return expectEval(p, "mod(abs(-14),5)", "4", why);
               }});
  t.push_back({"edge/scalar pow exact int keeps metadata for bitwise", [](std::string& why) {
                 MathParser p;
                 return expectEval(p, "pow(3,2)&7", "1", why);
               }});
  t.push_back({"edge/scalar div-by-one keeps int metadata for hex", [kPow53](std::string& why) {
                 MathParser p;
                 p.addConst("k", kPow53 + 2);  // 2^53 + 2 is exactly representable in double
                 return expectEval(p, "hex(int(k/1))", "0x20000000000002", why);
               }});
  t.push_back({"edge/scalar int() after float path keeps metadata", [kPow53](std::string& why) {
                 MathParser p;
                 p.addConst("k", kPow53 + 2);
                 return expectEval(p, "hex(int((k/2)+0.0))", "0x10000000000001", why);
               }});

  // Exact-int recovery after float-path operations (arrays).
  t.push_back({"edge/array sqrt perfect squares index keeps bitwise int path", [](std::string& why) {
                 MathParser p;
                 return expectEval(p, "a=sqrt((81,16,25)); a[0]&3", "1", why);
               }});
  t.push_back({"edge/array sqrt perfect squares index keeps hex int path", [](std::string& why) {
                 MathParser p;
                 return expectEval(p, "a=sqrt((81,16,25)); hex(a[2])", "0x5", why);
               }});
  t.push_back({"edge/array int() on mixed signs keeps index bitwise int path", [](std::string& why) {
                 MathParser p;
                 return expectEval(p, "a=int((2.9,-2.9,7.1)); a[1]&1", "0", why);
               }});
  t.push_back({"edge/array int() on mixed signs keeps index hex int path", [](std::string& why) {
                 MathParser p;
                 return expectEval(p, "a=int((2.9,-2.9,7.1)); hex(a[0])", "0x2", why);
               }});
  t.push_back({"edge/array div-by-one keeps large-int metadata for indexed hex", [kPow53](std::string& why) {
                 MathParser p;
                 p.addConst("k", kPow53);
                 return expectEval(p, "a=int(((k+2),(k+6))/1); hex(a[0])", "0x20000000000002", why);
               }});
  t.push_back({"edge/array div-by-one keeps large-int metadata for indexed mod", [kPow53](std::string& why) {
                 MathParser p;
                 p.addConst("k", kPow53);
                 return expectEval(p, "a=int(((k+2),(k+6))/1); mod(a[1],4)", "2", why);
               }});
  t.push_back({"edge/array half-then-int keeps metadata for indexed bitwise", [kPow53](std::string& why) {
                 MathParser p;
                 p.addConst("k", kPow53);
                 return expectEval(p, "a=int(((k+2),(k+6))/2); a[0]&1", "1", why);
               }});
  t.push_back({"edge/array half-then-int keeps metadata for indexed hex", [kPow53](std::string& why) {
                 MathParser p;
                 p.addConst("k", kPow53);
                 return expectEval(p, "a=int(((k+2),(k+6))/2); hex(a[1])", "0x10000000000003", why);
               }});
  t.push_back({"edge/array int over arithmetic expression keeps metadata", [](std::string& why) {
                 MathParser p;
                 return expectEval(p, "a=int(((5.9+0.1),(9.2+0.8))); mod(a[1],4)", "2", why);
               }});
  t.push_back({"edge/array int over arithmetic expression keeps indexed hex", [](std::string& why) {
                 MathParser p;
                 return expectEval(p, "a=int(((5.9+0.1),(9.2+0.8))); hex(a[0])", "0x6", why);
               }});
  t.push_back({"edge/array left-shift keeps int64 exact near max then index hex", [](std::string& why) {
                 MathParser p;
                 return expectEval(p, "a=(4611686018427387903,5)<<1; hex(a[0])", "0x7FFFFFFFFFFFFFFE", why);
               }});
  t.push_back({"edge/array left-shift keeps int64 exact near max then index mod", [](std::string& why) {
                 MathParser p;
                 return expectEval(p, "a=(4611686018427387903,5)<<1; mod(a[0],7)", "6", why);
               }});
  t.push_back({"edge/array right-shift keeps int64 exact after big left-shift", [](std::string& why) {
                 MathParser p;
                 return expectEval(p, "a=(4611686018427387903,5)<<1; b=a>>1; hex(b[0])", "0x3FFFFFFFFFFFFFFF", why);
               }});
  t.push_back({"edge/array bitwise and keeps int64 exact near max", [](std::string& why) {
                 MathParser p;
                 return expectEval(p, "a=(9223372036854775806,15); b=a&7; hex(b[0])", "0x6", why);
               }});
  t.push_back({"edge/array bitwise or keeps int64 exact near max", [](std::string& why) {
                 MathParser p;
                 return expectEval(p, "a=(9223372036854775800,1); b=a|7; hex(b[0])", "0x7FFFFFFFFFFFFFFF", why);
               }});
  t.push_back({"edge/scalar-array modulo remains scalar-only contract", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "mod(7,(2,3))", "mod() expects scalar values", why);
              }});
  t.push_back({"edge/array-scalar modulo remains scalar-only contract", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "mod((7,8),3)", "mod() expects scalar values", why);
              }});
  t.push_back({"edge/array shift rejects out-of-range count", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "a=(1,2)<<64", "incompatible operands", why);
              }});
  t.push_back({"edge/array near-max stored then int-op preserves exactness", [](std::string& why) {
                 MathParser p;
                 return expectEval(p, "a=(9223372036854775806,9223372036854775805); mod(a[1],5)", "0", why);
               }});
  t.push_back({"edge/array near-max stored then shift preserves exactness", [](std::string& why) {
                 MathParser p;
                 return expectEval(p, "a=(9223372036854775806,9223372036854775805); b=a>>2; hex(b[0])", "0x1FFFFFFFFFFFFFFF", why);
               }});

  return t;
}

std::vector<TestCase> buildNanInfCases() {
  std::vector<TestCase> t;
  const double kQNaN = std::numeric_limits<double>::quiet_NaN();
  const double kPosInf = std::numeric_limits<double>::infinity();
  const double kNegInf = -std::numeric_limits<double>::infinity();

  t.push_back({"naninf/quiet NaN dec identity", [kQNaN](std::string& why) {
                 MathParser p;
                 p.addConst("x", kQNaN);
                 return expectEval(p, "x+0", "nan", why);
               }});
  t.push_back({"naninf/+inf dec identity", [kPosInf](std::string& why) {
                 MathParser p;
                 p.addConst("x", kPosInf);
                 return expectEval(p, "x+0", "inf", why);
               }});
  t.push_back({"naninf/-inf dec identity", [kNegInf](std::string& why) {
                 MathParser p;
                 p.addConst("x", kNegInf);
                 return expectEval(p, "x+0", "-inf", why);
               }});

  t.push_back({"naninf/inf plus finite", [kPosInf](std::string& why) {
                 MathParser p;
                 p.addConst("x", kPosInf);
                 return expectEval(p, "x+1", "inf", why);
               }});
  t.push_back({"naninf/-inf minus finite", [kNegInf](std::string& why) {
                 MathParser p;
                 p.addConst("x", kNegInf);
                 return expectEval(p, "x-1", "-inf", why);
               }});
  t.push_back({"naninf/nan plus finite stays nan", [kQNaN](std::string& why) {
                 MathParser p;
                 p.addConst("x", kQNaN);
                 return expectEval(p, "x+1", "nan", why);
               }});

  t.push_back({"naninf/abs -inf", [kNegInf](std::string& why) {
                 MathParser p;
                 p.addConst("x", kNegInf);
                 return expectEval(p, "abs(x)", "inf", why);
               }});
  t.push_back({"naninf/abs nan", [kQNaN](std::string& why) {
                 MathParser p;
                 p.addConst("x", kQNaN);
                 return expectEval(p, "abs(x)", "nan", why);
               }});
  t.push_back({"naninf/sign +inf", [kPosInf](std::string& why) {
                 MathParser p;
                 p.addConst("x", kPosInf);
                 return expectEval(p, "sign(x)", "1", why);
               }});
  t.push_back({"naninf/sign -inf", [kNegInf](std::string& why) {
                 MathParser p;
                 p.addConst("x", kNegInf);
                 return expectEval(p, "sign(x)", "-1", why);
               }});
  t.push_back({"naninf/sign nan", [kQNaN](std::string& why) {
                 MathParser p;
                 p.addConst("x", kQNaN);
                 return expectEval(p, "sign(x)", "0", why);
               }});

  t.push_back({"naninf/ln nan", [kQNaN](std::string& why) {
                 MathParser p;
                 p.addConst("x", kQNaN);
                 return expectEval(p, "ln(x)", "nan", why);
               }});
  t.push_back({"naninf/ln +inf", [kPosInf](std::string& why) {
                 MathParser p;
                 p.addConst("x", kPosInf);
                 return expectEval(p, "ln(x)", "inf", why);
               }});
  t.push_back({"naninf/ln zero to -inf", [](std::string& why) {
                 MathParser p;
                 p.addConst("z", 0.0);
                 return expectEval(p, "ln(z)", "-inf", why);
               }});
  t.push_back({"naninf/sqrt nan", [kQNaN](std::string& why) {
                 MathParser p;
                 p.addConst("x", kQNaN);
                 return expectEval(p, "sqrt(x)", "nan", why);
               }});
  t.push_back({"naninf/sin +inf", [kPosInf](std::string& why) {
                 MathParser p;
                 p.addConst("x", kPosInf);
                 return expectEval(p, "sin(x)", "nan", why);
               }});

  t.push_back({"naninf/frac +inf", [kPosInf](std::string& why) {
                 MathParser p;
                 p.addConst("x", kPosInf);
                 return expectEval(p, "frac(x)", "nan", why);
               }});
  t.push_back({"naninf/frac nan", [kQNaN](std::string& why) {
                 MathParser p;
                 p.addConst("x", kQNaN);
                 return expectEval(p, "frac(x)", "nan", why);
               }});

  t.push_back({"naninf/hex NaN rejects", [kQNaN](std::string& why) {
                 MathParser p;
                 p.addConst("x", kQNaN);
                 return expectEvalErrorContains(p, "hex(x)", "hex() expects integer values", why);
               }});
  t.push_back({"naninf/hex +inf rejects", [kPosInf](std::string& why) {
                 MathParser p;
                 p.addConst("x", kPosInf);
                 return expectEvalErrorContains(p, "hex(x)", "hex() expects integer values", why);
               }});
  t.push_back({"naninf/oct -inf rejects", [kNegInf](std::string& why) {
                 MathParser p;
                 p.addConst("x", kNegInf);
                 return expectEvalErrorContains(p, "oct(x)", "oct() expects integer values", why);
               }});
  t.push_back({"naninf/mod NaN rejects", [kQNaN](std::string& why) {
                 MathParser p;
                 p.addConst("x", kQNaN);
                 return expectEvalErrorContains(p, "mod(x,3)", "mod() expects integer values", why);
               }});
  t.push_back({"naninf/mod +inf rejects", [kPosInf](std::string& why) {
                 MathParser p;
                 p.addConst("x", kPosInf);
                 return expectEvalErrorContains(p, "mod(x,3)", "mod() expects integer values", why);
               }});
  t.push_back({"naninf/gcd NaN rejects", [kQNaN](std::string& why) {
                 MathParser p;
                 p.addConst("x", kQNaN);
                 return expectEvalErrorContains(p, "gcd(x,1)", "gcd() expects integer values", why);
               }});
  t.push_back({"naninf/bitand NaN rejects", [kQNaN](std::string& why) {
                 MathParser p;
                 p.addConst("x", kQNaN);
                 return expectEvalErrorContains(p, "x&1", "bitwise operands must be integer values", why);
               }});
  t.push_back({"naninf/bitand +inf rejects", [kPosInf](std::string& why) {
                 MathParser p;
                 p.addConst("x", kPosInf);
                 return expectEvalErrorContains(p, "x&1", "bitwise operands must be integer values", why);
               }});

  t.push_back({"naninf/not NaN is true (non-truthy)", [kQNaN](std::string& why) {
                 MathParser p;
                 p.addConst("x", kQNaN);
                 return expectEval(p, "not x", "1", why);
               }});
  t.push_back({"naninf/not +inf is false", [kPosInf](std::string& why) {
                 MathParser p;
                 p.addConst("x", kPosInf);
                 return expectEval(p, "not x", "0", why);
               }});
  t.push_back({"naninf/NaN and 1", [kQNaN](std::string& why) {
                 MathParser p;
                 p.addConst("x", kQNaN);
                 return expectEval(p, "x&&1", "0", why);
               }});
  t.push_back({"naninf/NaN or 1", [kQNaN](std::string& why) {
                 MathParser p;
                 p.addConst("x", kQNaN);
                 return expectEval(p, "x||1", "1", why);
               }});

  // Comparator treats incomparable scalars as "equal" (cmp==0); documents current behavior.
  t.push_back({"naninf/NaN == NaN compares equal (cmp tie)", [kQNaN](std::string& why) {
                 MathParser p;
                 p.addConst("x", kQNaN);
                 return expectEval(p, "x==x", "1", why);
               }});
  t.push_back({"naninf/+inf == +inf", [kPosInf](std::string& why) {
                 MathParser p;
                 p.addConst("x", kPosInf);
                 return expectEval(p, "x==x", "1", why);
               }});

  return t;
}

std::vector<TestCase> buildRegressionCases() {
  std::vector<TestCase> t;

  // compile/evaluate lifecycle and AST reuse regressions.
  t.push_back({"regression/compile then evaluate", [](std::string& why) {
                 MathParser p;
                 if (!p.compile("a=10; a*2")) {
                   why = "compile failed: " + p.getError();
                   return false;
                 }
                 p.evaluate();
                 if (!p.getError().empty()) {
                   why = "evaluate failed: " + p.getError();
                   return false;
                 }
                 if (p.getResult() != "20") {
                   why = "expected 20, got " + p.getResult();
                   return false;
                 }
                 return true;
               }});
  t.push_back({"regression/evaluate without compile", [](std::string& why) {
                 MathParser p;
                 p.evaluate();
                 if (p.getError().find("compile") == std::string::npos) {
                   why = "expected compile-first error, got: " + p.getError();
                   return false;
                 }
                 return true;
               }});
  t.push_back({"regression/re-evaluate after const update", [](std::string& why) {
                 MathParser p;
                 p.addConst("k", 3LL);
                 if (!p.compile("k*10")) {
                   why = "compile failed";
                   return false;
                 }
                 p.evaluate();
                 if (p.getResult() != "30") {
                   why = "expected 30, got " + p.getResult();
                   return false;
                 }
                 p.addConst("k", 9LL);
                 p.evaluate();
                 if (p.getResult() != "90") {
                   why = "expected 90 after const update, got " + p.getResult();
                   return false;
                 }
                 return true;
               }});
  t.push_back({"regression/re-evaluate keeps compiled function definition", [](std::string& why) {
                 MathParser p;
                 if (!p.compile("f(x)=x*2; f(10)")) {
                   why = p.getError();
                   return false;
                 }
                 p.evaluate();
                 if (p.getResult() != "20") {
                   why = "expected 20, got " + p.getResult();
                   return false;
                 }
                 const std::string err = p.addUserFunction("f(x)=x*3");
                 if (!err.empty()) {
                   why = err;
                   return false;
                 }
                 p.evaluate();
                 if (p.getResult() != "20") {
                   why = "expected compiled definition to win (20), got " + p.getResult();
                   return false;
                 }
                 return true;
               }});
  t.push_back({"regression/function override affects call-only compiled expression", [](std::string& why) {
                 MathParser p;
                 const std::string err1 = p.addUserFunction("f(x)=x*2");
                 if (!err1.empty()) {
                   why = err1;
                   return false;
                 }
                 if (!p.compile("f(10)")) {
                   why = p.getError();
                   return false;
                 }
                 p.evaluate();
                 if (p.getResult() != "20") {
                   why = "expected 20, got " + p.getResult();
                   return false;
                 }
                 const std::string err2 = p.addUserFunction("f(x)=x*3");
                 if (!err2.empty()) {
                   why = err2;
                   return false;
                 }
                 p.evaluate();
                 if (p.getResult() != "30") {
                   why = "expected 30 after override, got " + p.getResult();
                   return false;
                 }
                 return true;
               }});
  t.push_back({"regression/failed compile drops old program", [](std::string& why) {
                 MathParser p;
                 if (!p.compile("2+3")) {
                   why = p.getError();
                   return false;
                 }
                 p.evaluate();
                 if (p.getResult() != "5") {
                   why = "setup result mismatch";
                   return false;
                 }
                 if (p.compile("pow(2,")) {
                   why = "compile unexpectedly succeeded";
                   return false;
                 }
                 p.evaluate();
                 if (p.getError().find("compile") == std::string::npos) {
                   why = "expected evaluate compile-first after failed compile, got: " + p.getError();
                   return false;
                 }
                 return true;
               }});
  t.push_back({"regression/percentage additive semantics", [](std::string& why) {
                 MathParser p;
                 return expectEval(p, "200 + 2*15%", "260", why);
               }});
  t.push_back({"regression/unpack requires at least one argument", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "unpack()", "unpack() expects at least 1 argument", why);
              }});
  t.push_back({"regression/unpack single argument is passthrough", [](std::string& why) {
                MathParser p;
                return expectEval(p, "unpack(5)", "5", why);
              }});
  t.push_back({"regression/unpack flattens multi-argument values", [](std::string& why) {
                MathParser p;
                return expectEval(p, "unpack((1,2),3)", "(1,2,3)", why);
              }});
  t.push_back({"regression/unpack preserves left-to-right flatten order", [](std::string& why) {
                MathParser p;
                return expectEval(p, "unpack(1,(2,3))", "(1,2,3)", why);
              }});
  t.push_back({"regression/unpack single array keeps array value", [](std::string& why) {
                MathParser p;
                return expectEval(p, "unpack((1,2))", "(1,2)", why);
              }});
  t.push_back({"regression/deg requires at least one argument", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "deg()", "deg() expects at least 1 argument", why);
              }});
  t.push_back({"regression/deg array preserves elementwise conversion", [](std::string& why) {
                MathParser p;
                return expectEval(p, "deg((pi,pi/2))", "(180,90)", why);
              }});
  t.push_back({"regression/rad requires at least one argument", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "rad()", "rad() expects at least 1 argument", why);
              }});
  t.push_back({"regression/rad array preserves elementwise conversion", [](std::string& why) {
                MathParser p;
                return expectEval(p, "rad((180,90))", "(3.141592653589793,1.570796326794896)", why);
              }});
  t.push_back({"regression/rad zero array stays zero", [](std::string& why) {
                MathParser p;
                return expectEval(p, "rad((0,0))", "(0,0)", why);
              }});
  t.push_back({"regression/clamp requires exactly three arguments", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "clamp(1,2)", "clamp() expects 3 argument(s)", why);
              }});
  t.push_back({"regression/clamp rejects extra arguments", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "clamp(1,2,3,4)", "clamp() expects 3 argument(s)", why);
              }});
  t.push_back({"regression/clamp scalar stays scalar result", [](std::string& why) {
                MathParser p;
                return expectEval(p, "clamp(9,0,7)", "7", why);
              }});
  t.push_back({"regression/clamp array value with scalar bounds stays elementwise", [](std::string& why) {
                MathParser p;
                return expectEval(p, "clamp((1,9),0,7)", "(1,7)", why);
              }});
  t.push_back({"regression/clamp rejects non-scalar min", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "clamp((1,2),(3,4),4)", "clamp() expects scalar min/max", why);
              }});
  t.push_back({"regression/clamp rejects non-scalar max", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "clamp(5,1,(4,7))", "clamp() expects scalar min/max", why);
              }});
  t.push_back({"regression/atan2 non-scalar keeps numeric-error contract", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "atan2((1,2),3)", "numeric error in atan2()", why);
              }});
  t.push_back({"regression/hypot non-scalar keeps numeric-error contract", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "hypot((3,4),5)", "numeric error in hypot()", why);
              }});
  t.push_back({"regression/random non-scalar keeps scalar-values contract", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "random((1,2),3)", "random() expects scalar values", why);
              }});
  t.push_back({"regression/random requires exactly two arguments", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "random(1)", "random() expects 2 argument(s)", why);
              }});
  t.push_back({"regression/random equal bounds returns that bound", [](std::string& why) {
                MathParser p;
                return expectEval(p, "random(5,5)", "5", why);
              }});
  t.push_back({"regression/rand requires zero arguments", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "rand(1)", "rand() expects 0 argument(s)", why);
              }});
  t.push_back({"regression/factorial rejects non-scalar input", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "fact((3,4))", "fact() expects a non-negative integer", why);
              }});
  t.push_back({"regression/factorial rejects negative input", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "fact(-1)", "fact() expects a non-negative integer", why);
              }});
  t.push_back({"regression/factorial above 20 switches to floating output", [](std::string& why) {
                MathParser p;
                return expectEval(p, "fact(21)", "5.109094217170944e+019", why);
              }});
  t.push_back({"regression/factorial zero equals one", [](std::string& why) {
                MathParser p;
                return expectEval(p, "fact(0)", "1", why);
              }});
  t.push_back({"regression/comparison operators keep boolean semantics", [](std::string& why) {
                MathParser p;
                return expectEval(p, "(2<3)+(2>=3)+(5==5)+(5<>4)", "3", why);
              }});
  t.push_back({"regression/comparison <> alias matches !=", [](std::string& why) {
                MathParser p;
                return expectEval(p, "(7<>8)+(7!=8)", "2", why);
              }});
  t.push_back({"regression/comparison strict and non-strict mix", [](std::string& why) {
                MathParser p;
                return expectEval(p, "(9>8)+(9<=8)+(8>=8)", "2", why);
              }});
  t.push_back({"regression/comparison equality and inequality mix", [](std::string& why) {
                MathParser p;
                return expectEval(p, "(3==3)+(3!=4)+(3<>3)", "2", why);
              }});
  t.push_back({"regression/sum requires at least one argument", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "sum()", "sum() expects at least 1 argument", why);
              }});
  t.push_back({"regression/hex requires at least one argument", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "hex()", "hex() expects at least 1 argument", why);
              }});
  t.push_back({"regression/ubin formats scalar as unsigned binary", [](std::string& why) {
                MathParser p;
                return expectEval(p, "ubin(5)", "0b101", why);
              }});
  t.push_back({"regression/mod requires exactly two arguments", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "mod(5)", "mod() expects 2 argument(s)", why);
              }});
  t.push_back({"regression/pow requires exactly two arguments", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "pow(5)", "pow() expects 2 argument(s)", why);
              }});
  t.push_back({"regression/operator caret is bitwise xor in compiled path", [](std::string& why) {
                MathParser p;
                return expectEval(p, "2^3", "1", why);
              }});
  t.push_back({"regression/operator double-star is power in compiled path", [](std::string& why) {
                MathParser p;
                return expectEval(p, "2**3", "8", why);
              }});
  t.push_back({"regression/operator caret is not power (3^2)", [](std::string& why) {
                MathParser p;
                return expectEval(p, "3^2", "1", why);
              }});
  t.push_back({"regression/operator double-star power (3**2)", [](std::string& why) {
                MathParser p;
                return expectEval(p, "3**2", "9", why);
              }});
  t.push_back({"regression/log requires exactly two arguments", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "log(5)", "log() expects 2 argument(s)", why);
              }});
  t.push_back({"regression/log array with scalar base stays elementwise", [](std::string& why) {
                MathParser p;
                return expectEval(p, "log((8,64),2)", "(3,6)", why);
              }});
  t.push_back({"regression/multiplicative mismatched arrays keep incompatible-operands error", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "(1,2)*(3,4,5)", "incompatible operands", why);
              }});
  t.push_back({"regression/additive mismatched arrays keep incompatible-operands error", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "(1,2)+(3,4,5)", "incompatible operands", why);
              }});
  t.push_back({"regression/formatter stability large integers", [](std::string& why) {
                 MathParser p;
                 p.parseAndEvaluate("9223372036854775807");
                 if (!p.getError().empty()) {
                   why = p.getError();
                   return false;
                 }
                 const std::string d = p.getResultAsDec();
                 if (d.empty()) {
                   why = "empty decimal result";
                   return false;
                 }
                 return true;
               }});
  t.push_back({"regression/unary minus on LLONG_MIN (overflow-safe)", [](std::string& why) {
                 MathParser p;
                 if (!p.compile("-((-9223372036854775807)-1)")) {
                   why = "compile failed: " + p.getError();
                   return false;
                 }
                 p.evaluate();
                 if (!p.getError().empty()) {
                   why = p.getError();
                   return false;
                 }
                 if (p.getResultAsHex() != "0x8000000000000000") {
                   why = "expected 0x8000000000000000, got " + p.getResultAsHex();
                   return false;
                 }
                 return true;
               }});
  t.push_back({"regression/ans exact after user function call", [](std::string& why) {
                 MathParser p;
                 if (!p.compile("f(x)=9007199254740993+x; f(0); hex(ans)")) {
                   why = "compile failed: " + p.getError();
                   return false;
                 }
                 p.evaluate();
                 if (!p.getError().empty()) {
                   why = p.getError();
                   return false;
                 }
                 if (p.getResult() != "0x20000000000001") {
                   why = "expected 0x20000000000001, got " + p.getResult();
                   return false;
                 }
                 return true;
               }});
  t.push_back({"regression/ans exact across program statements", [](std::string& why) {
                 MathParser p;
                 if (!p.compile("9007199254740992+1; hex(ans)")) {
                   why = "compile failed: " + p.getError();
                   return false;
                 }
                 p.evaluate();
                 if (!p.getError().empty()) {
                   why = p.getError();
                   return false;
                 }
                 if (p.getResult() != "0x20000000000001") {
                   why = "expected 0x20000000000001, got " + p.getResult();
                   return false;
                 }
                 return true;
               }});
  t.push_back({"regression/statement expression updates ans", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=1; 2; ans", "2", why);
              }});
  t.push_back({"regression/ans resets to zero after failed evaluation", [](std::string& why) {
                MathParser p;
                if (!expectEval(p, "10+5", "15", why)) {
                  return false;
                }
                p.parseAndEvaluate("unknownFunc(1)");
                if (p.getError().empty()) {
                  why = "expected failure for unknownFunc(1)";
                  return false;
                }
                return expectEval(p, "ans", "0", why);
              }});
  t.push_back({"regression/exact scalar metadata survives variable copy", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=9007199254740992+1; b=a; hex(b)", "0x20000000000001", why);
              }});
  t.push_back({"regression/uhex array keeps unsigned formatting", [](std::string& why) {
                MathParser p;
                return expectEval(p, "uhex((1,-1))", "(0x1,0xFFFFFFFFFFFFFFFF)", why);
              }});
  t.push_back({"regression/sum unpack mixed inputs keeps flatten order", [](std::string& why) {
                MathParser p;
                return expectEval(p, "sum(unpack((1,2),(3,4),5))", "15", why);
              }});
  t.push_back({"regression/array-array add keeps second element", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(1,2)+(3,4); hex(a[1])", "0x6", why);
              }});
  t.push_back({"regression/not keyword remains case-insensitive", [](std::string& why) {
                MathParser p;
                return expectEval(p, "NoT 0", "1", why);
              }});
  t.push_back({"regression/comparison chain remains left-associative", [](std::string& why) {
                MathParser p;
                return expectEval(p, "(5>=4)<2", "1", why);
              }});
  t.push_back({"regression/round array keeps integer exactness on index", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=round((1.2,2.8)); hex(a[1])", "0x3", why);
              }});
  t.push_back({"regression/array-array multiply keeps second element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(5,6)*(7,8); hex(a[1])", "0x30", why);
              }});
  t.push_back({"regression/array-array subtraction keeps second element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(10,20)-(3,4); hex(a[1])", "0x10", why);
              }});
  t.push_back({"regression/array-array modulo keeps second element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(20,21)%(3,4); hex(a[1])", "0x1", why);
              }});
  t.push_back({"regression/log scalar value with array bases stays elementwise", [](std::string& why) {
                MathParser p;
                return expectEval(p, "log(8,(2,4))", "(3,1.5)", why);
              }});
  t.push_back({"regression/lcm scalar pair remains exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "lcm(21,6)", "42", why);
              }});
  t.push_back({"regression/array-array bitwise or keeps second element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(1,2)|(4,8); hex(a[1])", "0xA", why);
              }});
  t.push_back({"regression/array-array bitwise xor keeps second element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(1,2)^(4,8); hex(a[1])", "0xA", why);
              }});
  t.push_back({"regression/array literal expression keeps second element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(1,(2+3),7); hex(a[1])", "0x5", why);
              }});
  t.push_back({"regression/abs array keeps second element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=abs((-1,-2)); hex(a[1])", "0x2", why);
              }});
  t.push_back({"regression/unary minus array keeps second element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=-(-1,-2); hex(a[1])", "0x2", why);
              }});
  t.push_back({"regression/array shift-right keeps second element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(8,9)>>1; hex(a[1])", "0x4", why);
              }});
  t.push_back({"regression/array shift-left keeps second element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(8,9)<<1; hex(a[1])", "0x12", why);
              }});
  t.push_back({"regression/array bitand pair keeps second element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(9,10)&(3,12); hex(a[1])", "0x8", why);
              }});
  t.push_back({"regression/array bitor pair keeps second element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(9,10)|(3,12); hex(a[1])", "0xE", why);
              }});
  t.push_back({"regression/array bitxor pair keeps first element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(9,10)^(3,12); hex(a[0])", "0xA", why);
              }});
  t.push_back({"regression/abs array keeps first element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=abs((-3,-4)); hex(a[0])", "0x3", why);
              }});
  t.push_back({"regression/array literal expression keeps third element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(1,(2+3),4); hex(a[2])", "0x4", why);
              }});
  t.push_back({"regression/int array keeps second element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=int((7.9,8.1)); hex(a[1])", "0x8", why);
              }});
  t.push_back({"regression/array modulo keeps first element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(20,21)%(6,4); hex(a[0])", "0x2", why);
              }});
  t.push_back({"regression/array add keeps second element exact 2", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(2,3)+(4,5); hex(a[1])", "0x8", why);
              }});
  t.push_back({"regression/array subtract keeps first element exact 2", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(9,7)-(4,5); hex(a[0])", "0x5", why);
              }});
  t.push_back({"regression/array multiply keeps first element exact 2", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(3,4)*(5,6); hex(a[0])", "0xF", why);
              }});
  t.push_back({"regression/array divide-by-one keeps second element exact 2", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(8,9)/1; hex(a[1])", "0x9", why);
              }});
  t.push_back({"regression/array int keeps first element exact 2", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=int((8.9,9.1)); hex(a[0])", "0x8", why);
              }});
  t.push_back({"regression/array round keeps first element exact 2", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=round((8.2,9.8)); hex(a[0])", "0x8", why);
              }});
  t.push_back({"regression/array unary minus keeps first element exact 2", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=-(-5,-6); hex(a[0])", "0x5", why);
              }});
  t.push_back({"regression/array abs keeps third element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=abs((-1,-2,-3)); hex(a[2])", "0x3", why);
              }});
  t.push_back({"regression/array bitor scalar keeps first element exact 2", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(8,9)|1; hex(a[0])", "0x9", why);
              }});
  t.push_back({"regression/array bitand scalar keeps first element exact 2", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(8,9)&7; hex(a[0])", "0x0", why);
              }});
  t.push_back({"regression/array shift-left keeps first element exact 2", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(8,9)<<1; hex(a[0])", "0x10", why);
              }});
  t.push_back({"regression/array shift-right keeps first element exact 2", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(8,9)>>1; hex(a[0])", "0x4", why);
              }});
  t.push_back({"regression/array modulo keeps second element exact 2", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(20,21)%(6,4); hex(a[1])", "0x1", why);
              }});
  t.push_back({"regression/array int keeps third element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=int((5.9,6.1,7.2)); hex(a[2])", "0x7", why);
              }});
  t.push_back({"regression/array round keeps third element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=round((5.2,6.8,7.1)); hex(a[2])", "0x7", why);
              }});
  t.push_back({"regression/array abs keeps second element exact 2", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=abs((-5,-6,-7)); hex(a[1])", "0x6", why);
              }});
  t.push_back({"regression/array bitor scalar keeps second element exact 2", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(8,9)|2; hex(a[1])", "0xB", why);
              }});
  t.push_back({"regression/array bitand scalar keeps second element exact 2", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(8,9)&3; hex(a[1])", "0x1", why);
              }});
  t.push_back({"regression/array xor scalar keeps second element exact 2", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(8,9)^3; hex(a[1])", "0xA", why);
              }});
  t.push_back({"regression/array add keeps first element exact 3", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(10,11)+(1,2); hex(a[0])", "0xB", why);
              }});
  t.push_back({"regression/array subtract keeps second element exact 3", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(10,11)-(1,2); hex(a[1])", "0x9", why);
              }});
  t.push_back({"regression/array multiply keeps second element exact 3", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(10,11)*(2,3); hex(a[1])", "0x21", why);
              }});
  t.push_back({"regression/array divide-by-one keeps first element exact 3", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(10,11)/1; hex(a[0])", "0xA", why);
              }});
  t.push_back({"regression/array int keeps second element exact 3", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=int((10.9,11.1)); hex(a[1])", "0xB", why);
              }});
  t.push_back({"regression/array round keeps second element exact 3", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=round((10.2,11.8)); hex(a[1])", "0xC", why);
              }});
  t.push_back({"regression/array abs keeps first element exact 3", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=abs((-10,-11)); hex(a[0])", "0xA", why);
              }});
  t.push_back({"regression/array unary minus keeps second element exact 3", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=-(-10,-11); hex(a[1])", "0xB", why);
              }});
  t.push_back({"regression/array bitor scalar keeps third element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(8,9,10)|1; hex(a[2])", "0xB", why);
              }});
  t.push_back({"regression/array bitand scalar keeps third element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(8,9,10)&3; hex(a[2])", "0x2", why);
              }});
  t.push_back({"regression/array xor scalar keeps third element exact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(8,9,10)^3; hex(a[2])", "0x9", why);
              }});
  t.push_back({"regression/array shift-right keeps second element exact 3", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(10,11)>>1; hex(a[1])", "0x5", why);
              }});
  t.push_back({"regression/unique keeps first-seen order 1", [](std::string& why) {
                MathParser p;
                return expectEval(p, "unique((5,3,5,2,3))", "(5,3,2)", why);
              }});
  t.push_back({"regression/unique keeps first-seen order 2", [](std::string& why) {
                MathParser p;
                return expectEval(p, "unique((2,1,2,1,3,2))", "(2,1,3)", why);
              }});
  t.push_back({"regression/unique scalar returns single-item array", [](std::string& why) {
                MathParser p;
                return expectEval(p, "unique(7)", "(7)", why);
              }});
  t.push_back({"regression/unique mixed args flatten in order", [](std::string& why) {
                MathParser p;
                return expectEval(p, "unique((1,2),2,1,3)", "(1,2,3)", why);
              }});
  t.push_back({"regression/unique zeros collapse", [](std::string& why) {
                MathParser p;
                return expectEval(p, "unique((0,-0,0,0))", "(0)", why);
              }});
  t.push_back({"regression/unique preserves first negative sign representative", [](std::string& why) {
                MathParser p;
                return expectEval(p, "unique((-0,0,1))", "(0,1)", why);
              }});
  t.push_back({"regression/unique decimal duplicates collapse", [](std::string& why) {
                MathParser p;
                return expectEval(p, "unique((1.5,1.5,2.5,1.5))", "(1.5,2.5)", why);
              }});
  t.push_back({"regression/unique integer-valued doubles collapse", [](std::string& why) {
                MathParser p;
                return expectEval(p, "unique((2.0,2,2.000,3))", "(2,3)", why);
              }});
  t.push_back({"regression/unique with unpack keeps order", [](std::string& why) {
                MathParser p;
                return expectEval(p, "unique(unpack((4,1),(4,2),1))", "(4,1,2)", why);
              }});
  t.push_back({"regression/unique long run keeps first occurrence", [](std::string& why) {
                MathParser p;
                return expectEval(p, "unique((9,8,7,9,8,7,6,5,6))", "(9,8,7,6,5)", why);
              }});
  t.push_back({"regression/unique repeated clusters keep order", [](std::string& why) {
                MathParser p;
                return expectEval(p, "unique((3,3,3,3,2,2,1))", "(3,2,1)", why);
              }});
  t.push_back({"regression/median odd unsorted stays stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "median((9,1,5,3,7))", "5", why);
              }});
  t.push_back({"regression/median even unsorted stays stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "median((10,1,7,3))", "5", why);
              }});
  t.push_back({"regression/variance mixed signs stays stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "variance((-3,0,3,6))", "11.25", why);
              }});
  t.push_back({"regression/stddev mixed signs stays stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "stddev((-3,0,3,6))", "3.354101966249684", why);
              }});
  t.push_back({"regression/factorial 20 keeps exact integer formatting", [](std::string& why) {
                MathParser p;
                return expectEval(p, "hex(fact(20))", "0x21C3677C82B40000", why);
              }});
  t.push_back({"regression/factorial 30 remains available in floating mode", [](std::string& why) {
                MathParser p;
                return expectEval(p, "factorial(30)", "2.65252859812191e+032", why);
              }});
  t.push_back({"regression/sort keeps duplicates and order contract", [](std::string& why) {
                MathParser p;
                return expectEval(p, "sort((5,1,5,2,2,9,1))", "(1,1,2,2,5,5,9)", why);
              }});
  t.push_back({"regression/sorted alias keeps duplicates and order contract", [](std::string& why) {
                MathParser p;
                return expectEval(p, "sorted((4,4,3,2,2,1))", "(1,2,2,3,4,4)", why);
              }});
  t.push_back({"regression/aggregate avg mixed scalars-arrays stays stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "avg((2,4),6,8)", "5", why);
              }});
  t.push_back({"regression/aggregate min mixed scalars-arrays stays stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "min((5,7),3,9)", "3", why);
              }});
  t.push_back({"regression/long call argument list parses and evaluates", [](std::string& why) {
                MathParser p;
                return expectEval(p, "sum(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)", "136", why);
              }});
  t.push_back({"regression/aggregate max mixed scalars-arrays stays stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "max((5,7),3,9)", "9", why);
              }});
  t.push_back({"regression/unpack-heavy call list keeps evaluation order", [](std::string& why) {
                MathParser p;
                return expectEval(p, "sum(unpack((1,2,3),(4,5),6,7))", "28", why);
              }});
  t.push_back({"regression/sorted single-array duplicates stays stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "sorted((3,3,1,2,1))", "(1,1,2,3,3)", why);
              }});
  t.push_back({"regression/reversed single-array alias stays stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "reversed((1,2,3,4,5))", "(5,4,3,2,1)", why);
              }});
  t.push_back({"regression/call without unpack keeps args intact", [](std::string& why) {
                MathParser p;
                return expectEval(p, "f(x,y)=x+y; f(2,3)", "5", why);
              }});
  t.push_back({"regression/late binding unresolved referenced UDF reports unknown function", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "f(x)=x*p(x); f(2)", "unknown functions", why);
              }});
  t.push_back({"regression/late binding resolves after referenced UDF definition", [](std::string& why) {
                MathParser p;
                return expectEval(p, "f(x)=x*p(x); p(x)=x+5; f(10)", "150", why);
              }});
  t.push_back({"regression/late binding with nonlinear referenced UDF", [](std::string& why) {
                MathParser p;
                return expectEval(p, "f(x)=x*p(x); p(x)=x**(1/3); f(8)", "16", why);
              }});
  t.push_back({"regression/late binding uses latest referenced UDF definition", [](std::string& why) {
                MathParser p;
                return expectEval(p, "f(x)=x*p(x); p(x)=x+5; p(x)=x**(1/3); f(8)", "16", why);
              }});
  t.push_back({"regression/UDF body cannot call defined name (self-reference)", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "x(a)=x(a); x(1)", "body cannot call 'x'", why);
              }});
  t.push_back({"regression/mutual recursion y<->g rejected at runtime", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(
                    p, "g(a)=y(a)+1; y(a)=g(a)+2; y(5)", "recursive user function call", why);
              }});
  t.push_back({"regression/mutual recursion cycle a..d rejected at runtime", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(
                    p,
                    "a(x)=b(x); b(x)=c(x); c(x)=d(x); d(x)=b(x); a(1)",
                    "recursive user function call",
                    why);
              }});
  t.push_back({"regression/unique single-array variable keeps order", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(5,2,5,9,2); unique(a)", "(5,2,9)", why);
              }});
  t.push_back({"regression/aggregate single scalar sum stays stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "sum(42)", "42", why);
              }});
  t.push_back({"regression/sorted single-array variable stays stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(3,1,2); sorted(a)", "(1,2,3)", why);
              }});
  t.push_back({"regression/unique clustered duplicates stays stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "unique((1,1,2,2,3,3))", "(1,2,3)", why);
              }});
  t.push_back({"regression/aggregate unpack stream traversal stays stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "avg(unpack((1,2),(3,4)),10)", "4", why);
              }});
  t.push_back({"regression/reverse mixed flatten traversal stays stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "reverse((1,2),3,(4,5))", "(5,4,3,2,1)", why);
              }});
  t.push_back({"regression/user function unpack args normalization stays stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "f(a,b)=a*b; f(unpack((3,4)))", "12", why);
              }});
  t.push_back({"regression/unpack expansion keeps exact integer metadata", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=(9007199254740993); hex(unpack(a))", "0x20000000000001", why);
              }});
  t.push_back({"regression/unary minus array keeps large exact integer metadata", [](std::string& why) {
                MathParser p;
                return expectEval(p, "a=-(9007199254740991,5); uhex(a[0])", "0xFFE0000000000001", why);
              }});
  t.push_back({"regression/hex array rejects non-integer element contract", [](std::string& why) {
                MathParser p;
                return expectEvalErrorContains(p, "hex((1,2.5))", "hex() expects integer values", why);
              }});
  t.push_back({"regression/unique single-array fast path clustered order stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "unique((9,9,8,8,7))", "(9,8,7)", why);
              }});
  t.push_back({"regression/reverse single-array fast path order stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "reverse((9,8,7,6))", "(6,7,8,9)", why);
              }});
  t.push_back({"regression/deg variadic mixed args order stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "deg((pi/2),pi)", "(90,180)", why);
              }});
  t.push_back({"regression/uhex variadic array-scalar order stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "uhex((1,-1),2)", "(0x1,0xFFFFFFFFFFFFFFFF,0x2)", why);
              }});
  t.push_back({"regression/uhex unpack variadic array-scalar order stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "uhex(unpack((1,-1),2))", "(0x1,0xFFFFFFFFFFFFFFFF,0x2)", why);
              }});
  t.push_back({"regression/variance mixed variadic array-scalar stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "variance((1,2),3,4)", "1.25", why);
              }});
  t.push_back({"regression/stddev mixed variadic array-scalar stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "stddev((1,2),3,4)", "1.118033988749894", why);
              }});
  t.push_back({"regression/median single scalar fast path stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "median(42)", "42", why);
              }});
  t.push_back({"regression/median single array item fast path stable", [](std::string& why) {
                MathParser p;
                return expectEval(p, "median((42))", "42", why);
              }});

  return t;
}

void runSuite(const std::string& title, const std::vector<TestCase>& cases, TestState& s) {
  std::cout << "=== " << title << " ===\n";
  for (const auto& tc : cases) {
    ++s.total;
    std::string why;
    bool ok = false;
    try {
      ok = tc.run(why);
    } catch (const std::exception& ex) {
      ok = false;
      why = std::string("exception: ") + ex.what();
    } catch (...) {
      ok = false;
      why = "unknown exception";
    }

    if (ok) {
      ++s.passed;
      std::cout << "[PASS] " << tc.name << "\n";
    } else {
      ++s.failed;
      std::cout << "[FAIL] " << tc.name << " -> " << why << "\n";
    }
  }
  std::cout << "\n";
}

}  // namespace

int main() {
  TestState s;

  const auto smoke = buildSmokeCases();
  const auto unit = buildUnitCases();
  const auto edgeIntFloat = buildEdgeIntFloatCases();
  const auto nanInf = buildNanInfCases();
  const auto regression = buildRegressionCases();

  runSuite("Smoke", smoke, s);
  runSuite("Unit", unit, s);
  runSuite("Edge/int-float", edgeIntFloat, s);
  runSuite("NaN/Inf", nanInf, s);
  runSuite("Regression", regression, s);

  std::cout << "TOTAL: " << s.total << ", PASSED: " << s.passed << ", FAILED: " << s.failed << "\n";
  return (s.failed == 0) ? 0 : 1;
}

