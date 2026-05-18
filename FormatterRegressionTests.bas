''
'' Formatter regression tests for SmartMath_Format.bas (link with FormatterTest_Globals.bas + SmartMath_Format.bas).
''
#include once "SmartMath_Globals.bi"

#ifndef LOCALE_SDECIMAL
const LOCALE_SDECIMAL = &h0000000E
#endif

'' Primary Win32 LCIDs for Format()/locale decimal smoke.
private const LCID_EN_US as DWORD = &h0409
private const LCID_DE_DE as DWORD = &h0407
private const LCID_FR_FR as DWORD = &h040C

'' Mirror SmartMath_Format.bas UI labels (not exported from formatter module).
private const FMT_NAN as String = "NaN"
private const FMT_INF as String = "Inf"
private const FMT_NEGINF as String = "-Inf"

private sub ApplySeparatorDefaults()
  g_sDecimalSeparator = SMARTMATH_DECIMAL_SEPARATOR_DEFAULT
  g_sThousandsSeparator = SMARTMATH_THOUSANDS_SEPARATOR_DEFAULT
  g_sArrayOutputSeparator = SMARTMATH_ARRAY_OUTPUT_SEPARATOR_DEFAULT
end sub

private sub FormatterTestSetup()
  g_nDecimals = -1
  g_bUseThousandsSeparator = FALSE
  ApplySeparatorDefaults()
  ResetSmartMathFormatLocaleCache()
end sub

private function ThreadLocaleDecimalA() as String
  dim buf as zstring * 8 = any
  buf = ""
  if GetLocaleInfoA(GetThreadLocale(), LOCALE_SDECIMAL, @buf, 8) = 0 then return "."
  return Trim(buf)
end function

private sub AssertEq(byref caseName as String, byref got as String, byref wantVal as String, byref failCount as Integer)
  if got = wantVal then
    print !"[PASS] "; caseName
  else
    print !"[FAIL] "; caseName
    print !"  expected: ["; wantVal; !"]"
    print !"  got:      ["; got; !"]"
    failCount += 1
  end if
end sub

private sub AssertTrue(byref caseName as String, byval cond as Boolean, byref failCount as Integer)
  if cond then
    print !"[PASS] "; caseName
  else
    print !"[FAIL] "; caseName
    failCount += 1
  end if
end sub

private sub AssertNoSubstr(byref caseName as String, byref haystack as String, byref bad as String, byref failCount as Integer)
  if Len(bad) = 0 then
    print !"[PASS] "; caseName; !" (skip empty needle)"
    exit sub
  end if
  if InStr(1, haystack, bad) = 0 then
    print !"[PASS] "; caseName
  else
    print !"[FAIL] "; caseName; !" — unexpected substring ["; bad; !"] in ["; haystack; !"]"
    failCount += 1
  end if
end sub

private function CountCharAsc(byref s as String, byval chAsc as Integer) as Integer
  dim c as Integer = 0
  dim i as Integer
  for i = 1 to Len(s)
    if Asc(Mid(s, i, 1)) = chAsc then c += 1
  next i
  return c
end function

private sub FormatterTestInitRawScalarFloat(byref s as RawScalar, byval v as Double)
  s.kind = RSK_FLOATING
  s.floatValue = v
  s.renderBase = 0
  s.renderUnsigned = FALSE
end sub

private sub FormatterTestInitRawScalarInt64(byref s as RawScalar, byval v as LongInt)
  s.kind = RSK_INT64
  s.intValue = v
  s.renderBase = 0
  s.renderUnsigned = FALSE
end sub

private sub FormatterTestSetRawFloatArray(byref r as RawResult, vals() as Double)
  RawResultClear(r)
  r.kind = RRK_ARRAY
  dim lb as Integer = lbound(vals)
  dim ub as Integer = ubound(vals)
  redim r.arr(0 to ub - lb)
  dim i as Integer
  for i = lb to ub
    FormatterTestInitRawScalarFloat r.arr(i - lb), vals(i)
  next i
end sub

private sub FormatterTestSetRawInt64Array(byref r as RawResult, vals() as LongInt)
  RawResultClear(r)
  r.kind = RRK_ARRAY
  dim lb as Integer = lbound(vals)
  dim ub as Integer = ubound(vals)
  redim r.arr(0 to ub - lb)
  dim i as Integer
  for i = lb to ub
    FormatterTestInitRawScalarInt64 r.arr(i - lb), vals(i)
  next i
end sub

private function FormatTestRawArray(byref r as RawResult) as String
  return FormatRawResultForDisplay(r)
end function

'' Array display via RawResult (same output as former FormatArrayResultText parser-text path).
private sub RunArrayDisplayTests(byref failCount as Integer)
  dim savedLc as DWORD = GetThreadLocale()
  if SetThreadLocale(LCID_EN_US) = 0 then
    print !"[SKIP] RunArrayDisplayTests: SetThreadLocale en-US failed"
    exit sub
  end if
  ResetSmartMathFormatLocaleCache()
  print !"-- Array display (en-US for stable Format)"

  '' Auto decimals, no thousands — integer elements, custom array separator
  FormatterTestSetup()
  g_sArrayOutputSeparator = ";"
  dim rawFast as RawResult
  dim intsFast(0 to 1) as LongInt = {10, 20}
  FormatterTestSetRawInt64Array rawFast, intsFast()
  dim rFast as String = FormatTestRawArray(rawFast)
  AssertEq("arr/fast/semicolon elem sep", rFast, SMARTMATH_RESULT_PREFIX & "(10; 20)", failCount)

  '' Fixed decimals, dot decimal, comma as g_sArrayOutputSeparator (e.g. (12.345, 1.444, 7.890))
  g_nDecimals = 3
  g_bUseThousandsSeparator = FALSE
  g_sDecimalSeparator = "."
  g_sArrayOutputSeparator = ","
  '' Use values that keep a non-zero fractional part after rounding/trim (avoids all-integer tuple).
  dim rawDot as RawResult
  dim floatsDot(0 to 2) as Double = {12.345, 1.444, 7.890}
  FormatterTestSetRawFloatArray rawDot, floatsDot()
  dim rDot as String = FormatTestRawArray(rawDot)
  AssertTrue("arr/fixed/dot-dec/has prefix", Left(rDot, Len(SMARTMATH_RESULT_PREFIX)) = SMARTMATH_RESULT_PREFIX, failCount)
  AssertTrue("arr/fixed/dot-dec/parens", InStr(1, rDot, "(") > 0 andalso InStr(1, rDot, ")") > 0, failCount)
  AssertTrue("arr/fixed/dot-dec/elem gap uses array sep", InStr(1, rDot, ", ") > 0, failCount)
  AssertTrue("arr/fixed/dot-dec/first elt uses ascii dot", InStr(1, rDot, "12.345") > 0, failCount)

  '' Thousands + comma decimal + comma array sep: (1'024,333, 2'048,666, 4'096,999) style
  g_nDecimals = 3
  g_bUseThousandsSeparator = TRUE
  g_sThousandsSeparator = "'"
  g_sDecimalSeparator = ","
  g_sArrayOutputSeparator = ","
  dim rawThou as RawResult
  dim floatsThou(0 to 2) as Double = {1024.333, 2048.666, 4096.999}
  FormatterTestSetRawFloatArray rawThou, floatsThou()
  dim rThou as String = FormatTestRawArray(rawThou)
  AssertTrue("arr/thou-comma/thou marks", CountCharAsc(rThou, 39) >= 3, failCount)
  AssertTrue("arr/thou-comma/has 1'024", InStr(1, rThou, "1'024") > 0, failCount)
  AssertTrue("arr/thou-comma/has 2'048", InStr(1, rThou, "2'048") > 0, failCount)
  AssertTrue("arr/thou-comma/has 4'096", InStr(1, rThou, "4'096") > 0, failCount)
  AssertTrue("arr/thou-comma/dec comma in first elt", InStr(1, rThou, "1'024,") > 0, failCount)
  '' Element boundary: fraction ends then array sep ", " before next thousand group
  AssertTrue("arr/thou-comma/elt boundary", InStr(1, rThou, ",333, 2'048") > 0, failCount)

  '' Alternate array separator with same numeric styling
  g_sArrayOutputSeparator = "|"
  dim rawPipe as RawResult
  dim floatsPipe(0 to 1) as Double = {1024.333, 2048.666}
  FormatterTestSetRawFloatArray rawPipe, floatsPipe()
  dim rPipe as String = FormatTestRawArray(rawPipe)
  AssertTrue("arr/pipe-elem/has pipe-space", InStr(1, rPipe, "| ") > 0, failCount)
  AssertTrue("arr/pipe-elem/still thousands", InStr(1, rPipe, "1'024") > 0, failCount)

  SetThreadLocale(savedLc)
  ResetSmartMathFormatLocaleCache()
  FormatterTestSetup()
end sub

private sub RunLocaleBlock(byval lcid as DWORD, byref label as String, byref failCount as Integer)
  dim prev as DWORD = GetThreadLocale()
  if SetThreadLocale(lcid) = 0 then
    print !"[SKIP] SetThreadLocale failed for "; label
    exit sub
  end if
  ResetSmartMathFormatLocaleCache()
  print !"-- Locale block: "; label; !" (thread dec sep=["; ThreadLocaleDecimalA(); !"])"

  g_nDecimals = 2
  g_bUseThousandsSeparator = TRUE
  g_sDecimalSeparator = ","
  g_sThousandsSeparator = "'"

  dim r73 as String = FormatResult(73.5)
  AssertNoSubstr(label & !"/73.5 no mangled thou", r73, "7'3", failCount)

  dim r105 as String = FormatResult(10.5 * 7.0)
  AssertNoSubstr(label & !"/10.5*7 no mangled thou", r105, "7'3", failCount)

  dim r1k as String = FormatResult(12345.67)
  AssertTrue(label & !"/12345 has thou sep", InStr(1, r1k, "'") > 0, failCount)

  SetThreadLocale(prev)
  ResetSmartMathFormatLocaleCache()
end sub

private sub RunSeparatorMatrix(byref failCount as Integer)
  print !"-- Separator matrix (1-char ini-style, thousands on, 2 decimals)"

  dim decChars(0 to 2) as String
  decChars(0) = "."
  decChars(1) = ","
  decChars(2) = ";"
  dim thouChars(0 to 2) as String
  thouChars(0) = "'"
  thouChars(1) = "."
  thouChars(2) = ","
  dim arrayChars(0 to 2) as String
  arrayChars(0) = ";"
  arrayChars(1) = "|"
  arrayChars(2) = ":"

  dim di as Integer, ti as Integer, ai as Integer
  for di = 0 to 2
    for ti = 0 to 2
      for ai = 0 to 2
        dim dch as String = decChars(di)
        dim tch as String = thouChars(ti)
        dim ach as String = arrayChars(ai)
        if dch <> tch then
          FormatterTestSetup()
          g_nDecimals = 2
          g_bUseThousandsSeparator = TRUE
          g_sDecimalSeparator = dch
          g_sThousandsSeparator = tch
          g_sArrayOutputSeparator = ach

          dim tag as String = !"dec=" & dch & !"/thou=" & tch & !"/arr=" & ach
          dim r as String = FormatResult(8888.25)
          AssertTrue(tag & !"/len", Len(r) > Len(SMARTMATH_RESULT_PREFIX), failCount)
          AssertNoSubstr(tag & !"/no double-dec glitch", r, dch & dch, failCount)

          dim rawArr as RawResult
          dim intsArr(0 to 2) as LongInt = {1, 2, 3}
          FormatterTestSetRawInt64Array rawArr, intsArr()
          dim a as String = FormatTestRawArray(rawArr)
          AssertTrue(tag & !"/array has sep", InStr(1, a, ach) > 0, failCount)
        end if
      next ai
    next ti
  next di

  FormatterTestSetup()
end sub

'' --------- main ----------
dim failures as Integer = 0

print !"=== SmartMath formatter regression tests ==="
print !""

FormatterTestSetup()

'' --- Non-finite ---
dim nanv as Double
nanv = 0.0 / 0.0
dim pInf as Double = 1.0e200 * 1.0e200
dim nInf as Double = -pInf

AssertEq("NaN display", FormatResult(nanv), SMARTMATH_RESULT_PREFIX & FMT_NAN, failures)
AssertEq("+Inf display", FormatResult(pInf), SMARTMATH_RESULT_PREFIX & FMT_INF, failures)
AssertEq("-Inf display", FormatResult(nInf), SMARTMATH_RESULT_PREFIX & FMT_NEGINF, failures)

AssertEq("parser nan token", FormatNonFiniteDisplayFromParserScalar("nan"), FMT_NAN, failures)
AssertEq("parser inf token", FormatNonFiniteDisplayFromParserScalar("inf"), FMT_INF, failures)
AssertEq("parser -inf token", FormatNonFiniteDisplayFromParserScalar("-inf"), FMT_NEGINF, failures)
AssertEq("parser finite", FormatNonFiniteDisplayFromParserScalar("3.14"), "", failures)

'' --- Auto decimals (Str path, ASCII dot) ---
AssertTrue("auto decimals has prefix", Left(FormatResult(73.5), Len(SMARTMATH_RESULT_PREFIX)) = SMARTMATH_RESULT_PREFIX, failures)

'' --- Fixed decimals, no thousands ---
g_nDecimals = 2
dim rNorm as String = FormatResult(73.5)
AssertTrue("fixed73 no empty", Len(rNorm) > Len(SMARTMATH_RESULT_PREFIX), failures)
AssertNoSubstr("fixed73 no apostrophe glitch", rNorm, "7'3", failures)

'' --- Thousands grouping shape ---
FormatterTestSetup()
g_nDecimals = 1
g_bUseThousandsSeparator = TRUE
g_sThousandsSeparator = "'"
dim rBig as String = FormatResult(12345.6)
AssertTrue("thousands near 12k", InStr(1, rBig, "'") > 0, failures)

'' --- Scientific normalization lowercase e ---
FormatterTestSetup()
g_nDecimals = 3
g_bUseThousandsSeparator = FALSE
dim rSci as String = FormatResult(0.0000012)
AssertTrue("sci uses e", InStr(1, LCase(rSci), "e") > 0, failures)

RunArrayDisplayTests(failures)

private sub RunRawResultFormatTests(byref failCount as Integer)
  FormatterTestSetup()
  dim nanv as Double
  nanv = 0.0 / 0.0
  dim pInf as Double = 1.0e200 * 1.0e200
  dim r as RawResult
  RawResultClear(r)
  r.kind = RRK_SCALAR
  r.scalar.kind = RSK_RATIONAL
  r.scalar.ratNum = 1
  r.scalar.ratDen = 2
  AssertEq("raw format rational scalar", FormatRawResultForDisplay(r), SMARTMATH_RESULT_PREFIX & "1/2", failCount)

  RawResultClear(r)
  r.kind = RRK_SCALAR
  r.scalar.kind = RSK_COMPLEX
  r.scalar.real.kind = RSK_INT64
  r.scalar.real.intValue = 10
  r.scalar.imag.kind = RSK_INT64
  r.scalar.imag.intValue = 5
  AssertEq("raw format complex int", FormatRawResultForDisplay(r), SMARTMATH_RESULT_PREFIX & "10 + 5i", failCount)

  RawResultClear(r)
  r.kind = RRK_SCALAR
  r.scalar.kind = RSK_COMPLEX
  r.scalar.real.kind = RSK_FLOATING
  r.scalar.real.floatValue = -0.0
  r.scalar.imag.kind = RSK_FLOATING
  r.scalar.imag.floatValue = -0.22
  AssertEq("raw format pure imag neg zero real", FormatRawResultForDisplay(r), SMARTMATH_RESULT_PREFIX & "-0.22i", failCount)

  RawResultClear(r)
  r.kind = RRK_SCALAR
  r.scalar.kind = RSK_COMPLEX
  r.scalar.real.kind = RSK_FLOATING
  r.scalar.real.floatValue = pInf
  r.scalar.imag.kind = RSK_FLOATING
  r.scalar.imag.floatValue = pInf
  AssertEq("raw format complex inf inf*i", FormatRawResultForDisplay(r), SMARTMATH_RESULT_PREFIX & "Inf + Inf*i", failCount)

  RawResultClear(r)
  r.kind = RRK_SCALAR
  r.scalar.kind = RSK_COMPLEX
  r.scalar.real.kind = RSK_FLOATING
  r.scalar.real.floatValue = nanv
  r.scalar.imag.kind = RSK_FLOATING
  r.scalar.imag.floatValue = nanv
  AssertEq("raw format complex nan nan*i", FormatRawResultForDisplay(r), SMARTMATH_RESULT_PREFIX & "NaN", failCount)

  RawResultClear(r)
  r.kind = RRK_ARRAY
  redim r.arr(0 to 1)
  r.arr(0).kind = RSK_RATIONAL
  r.arr(0).ratNum = 1
  r.arr(0).ratDen = 2
  r.arr(1).kind = RSK_INT64
  r.arr(1).intValue = 3
  AssertEq("raw format array mix", FormatRawResultForDisplay(r), SMARTMATH_RESULT_PREFIX & "(1/2, 3)", failCount)
end sub

RunRawResultFormatTests(failures)

'' --- Locale emulation via SetThreadLocale ---
dim savedLc as DWORD = GetThreadLocale()
RunLocaleBlock(LCID_EN_US, "en-US", failures)
RunLocaleBlock(LCID_DE_DE, "de-DE", failures)
RunLocaleBlock(LCID_FR_FR, "fr-FR", failures)
if savedLc <> GetThreadLocale() then
  SetThreadLocale(savedLc)
  ResetSmartMathFormatLocaleCache()
end if

'' --- 1-char separator matrix ---
RunSeparatorMatrix(failures)
FormatterTestSetup()

print !""
print !"=== Result ==="
if failures = 0 then
  print !"All formatter tests passed."
  end 0
else
  print !"Failures: "; failures
  end 1
end if
