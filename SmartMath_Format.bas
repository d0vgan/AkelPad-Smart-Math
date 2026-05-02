#include once "SmartMath_Globals.bi"

#ifndef LOCALE_SDECIMAL
const LOCALE_SDECIMAL = &h0000000E
#endif
#ifndef LOCALE_USER_DEFAULT
const LOCALE_USER_DEFAULT = &h0400
#endif

'' IEEE-754 double masks (little-endian storage; same bit pattern as uint64).
'' Defined behavior on Win32/Win64 IEEE-754 double layout (plugin targets).
private const SM_DBL_EXP_MASK as ULongInt = &h7FF0000000000000
private const SM_DBL_FRAC_MASK as ULongInt = &h000FFFFFFFFFFFFF
private const SM_DBL_SIGN_MASK as ULongInt = &h8000000000000000

' UI spellings for non-finite values (parser ValueToString still uses nan/inf/-inf).
const SM_FMT_NAN as String = "NaN"
const SM_FMT_INF as String = "Inf"
const SM_FMT_NEGINF as String = "-Inf"

'' Format-mask fragments (skill: multi-char string literals as named constants).
private const SM_STR_ZERO_DOT as String = "0."
private const SM_STR_SCI_ZERO_PAD_EXP as String = "0E+00"
private const SM_STR_SCI_EXP_SUFFIX as String = "E+00"

'' Lowercase tokens from parser scalar strings (ValueToString / classification).
private const SM_TOK_NAN_LC as String = "nan"
private const SM_TOK_INF_LC as String = "inf"
private const SM_TOK_NEGINF_LC as String = "-inf"

'' LOCALE_SDECIMAL cache invalidation (incremented by ResetSmartMathFormatLocaleCache).
dim shared g_fmtLocaleCacheSerial as Integer = 0

' -----------------------------------------------------------------------------
'  Result Formatting
' -----------------------------------------------------------------------------

private function Pow10Cached(byval n as Integer) as Double
  static powTab(0 to 32) as Double
  static high as Integer = -1
  if n < 0 then return 1.0
  if n > 32 then
    dim pFallback as Double = 1.0
    dim j as Integer
    for j = 1 to n
      pFallback *= 10.0
    next j
    return pFallback
  end if
  while high < n
    high += 1
    if high = 0 then
      powTab(0) = 1.0
    else
      powTab(high) = powTab(high - 1) * 10.0
    end if
  wend
  return powTab(n)
end function

private function MaskFixedCached(byval n as Integer) as String
  static m(0 to SMARTMATH_DECIMALS_MAX) as String
  static ok(0 to SMARTMATH_DECIMALS_MAX) as BOOL
  if ok(n) = FALSE then
    if n = 0 then
      m(n) = "0"
    else
      m(n) = SM_STR_ZERO_DOT & String(n, 48)
    end if
    ok(n) = TRUE
  end if
  return m(n)
end function

private function MaskSciCached(byval n as Integer) as String
  static m(0 to SMARTMATH_DECIMALS_MAX) as String
  static ok(0 to SMARTMATH_DECIMALS_MAX) as BOOL
  if ok(n) = FALSE then
    if n = 0 then
      m(n) = SM_STR_SCI_ZERO_PAD_EXP
    else
      m(n) = SM_STR_ZERO_DOT & String(n, 48) & SM_STR_SCI_EXP_SUFFIX
    end if
    ok(n) = TRUE
  end if
  return m(n)
end function

private function IndexOfExponentLetter(byref s as String) as Integer
  dim n as Integer = Len(s)
  dim i as Integer
  for i = 1 to n
    select case Asc(s, i)
    case 69, 101
      return i
    end select
  next i
  return 0
end function

private function ReplaceSeparatorWith(byref s as String, byref sep as String, byref target as String) as String
  dim sepLen as Integer = Len(sep)
  if sepLen = 0 then return s
  if InStr(1, s, sep) = 0 then return s
  if sepLen = 1 andalso Len(target) = 1 then
    dim n as Integer = Len(s)
    dim r as String = Space(n)
    dim i as Integer
    dim sch as Integer = Asc(sep)
    dim tch as Integer = Asc(target)
    for i = 1 to n
      dim b as Integer = Asc(s, i)
      if b = sch then
        Mid(r, i, 1) = target
      else
        Mid(r, i, 1) = Chr(b)
      end if
    next i
    return r
  end if
  dim rMulti as String = s
  dim p as Integer = InStr(1, rMulti, sep)
  while p > 0
    rMulti = Left(rMulti, p - 1) & target & Mid(rMulti, p + sepLen)
    p = InStr(1, rMulti, sep)
  wend
  return rMulti
end function

'' FB Format() follows the user default locale; SetThreadLocale affects GetThreadLocale only.
'' Cache both LOCALE_SDECIMAL values so we normalize whatever Format actually emitted.
private sub RefreshCachedLocaleDecimals(byref threadDec as String, byref userDec as String)
  static lastLocaleSerial as Integer = -1
  static cachedThread as String
  static cachedUser as String
  if lastLocaleSerial = g_fmtLocaleCacheSerial andalso lastLocaleSerial >= 0 then
    threadDec = cachedThread
    userDec = cachedUser
    exit sub
  end if
  dim buf as zstring * 8 = any
  buf = ""
  if GetLocaleInfoA(GetThreadLocale(), LOCALE_SDECIMAL, @buf, 8) = 0 then
    cachedThread = ""
  else
    cachedThread = Trim(buf)
  end if
  buf = ""
  if GetLocaleInfoA(LOCALE_USER_DEFAULT, LOCALE_SDECIMAL, @buf, 8) = 0 then
    cachedUser = ""
  else
    cachedUser = Trim(buf)
  end if
  lastLocaleSerial = g_fmtLocaleCacheSerial
  threadDec = cachedThread
  userDec = cachedUser
end sub

private sub ApplyLocaleDecimalToAsciiDot(byref s as String, byref locDec as String)
  dim locLen as Integer = Len(locDec)
  if locLen = 0 orelse locDec = "." then exit sub
  s = ReplaceSeparatorWith(s, locDec, ".")
  if locLen > 1 then
    s = ReplaceSeparatorWith(s, Left(locDec, 1), ".")
  end if
end sub

'' Bumps LOCALE_SDECIMAL memo generation (e.g. after SetThreadLocale in formatter regression tests).
sub ResetSmartMathFormatLocaleCache()
  g_fmtLocaleCacheSerial += 1
end sub

'' Format() takes the decimal symbol from the user default locale (FB rtlib fb_hStrFormat / fb_IntlGet).
'' Normalize thread and user LOCALE_SDECIMAL so SetThreadLocale tests and mixed-locale hosts agree.
'' The runtime stores it as a single C char in the output, so multi-byte LOCALE_SDECIMAL values
'' may appear only as their first byte in s; normalize both the full string and that byte.
'' Downstream logic assumes a single ASCII "." in the mantissa before g_sDecimalSeparator.
private function FormatWithAsciiDecimal(byval d as Double, byref fmtExpr as String) as String
  dim s as String = Format(d, fmtExpr)
  dim threadDec as String
  dim userDec as String
  RefreshCachedLocaleDecimals(threadDec, userDec)
  ApplyLocaleDecimalToAsciiDot(s, threadDec)
  if userDec <> threadDec then ApplyLocaleDecimalToAsciiDot(s, userDec)
  return s
end function

'' Str() uses ASCII "."; FormatWithAsciiDecimal ensures "." after locale-aware Format().
'' ini may set g_sDecimalSeparator to ",". Detect either.
private function PositionOfNumericDecimal(byref s as String) as Integer
  dim p as Integer = InStr(1, s, g_sDecimalSeparator)
  if p > 0 then return p
  return InStr(1, s, ".")
end function

private function TrimTrailingFractionZeros(byref s as String) as String
  dim decPos as Integer = PositionOfNumericDecimal(s)
  if decPos = 0 andalso InStr(1, s, ",") = 0 then return s
  dim n as Integer = Len(s)
  while n > 0
    if Asc(s, n) <> 48 then exit while
    n -= 1
  wend
  if n = 0 then return ""
  dim lastCh as String = Mid(s, n, 1)
  if lastCh = g_sDecimalSeparator orelse lastCh = "," orelse lastCh = "." then
    n -= 1
  end if
  dim slen as Integer = Len(s)
  if n = slen then return s
  return Left(s, n)
end function

private function AddArrayCommaSpacing(byref s as String) as String
  dim n as Integer = Len(s)
  if n = 0 then return ""
  dim outText as String = ""
  dim i as Integer
  for i = 1 to n
    if Asc(s, i) = 44 then
      outText &= g_sArrayOutputSeparator & " "
    else
      outText &= Mid(s, i, 1)
    end if
  next i
  return outText
end function

'' Split inner text of "( ... )" on commas that are not inside nested parentheses.
'' MathParser array text always uses ASCII comma between elements; decimals use "." from Str().
private function SplitTopLevelArrayCsvInner(byref inner as String, elems() as String) as Integer
  erase elems
  dim s as String = Trim(inner)
  dim n as Integer = Len(s)
  if n = 0 then return 0
  dim depth as Integer = 0
  dim start as Integer = 1
  dim partCount as Integer = 0
  dim i as Integer
  for i = 1 to n
    select case Asc(s, i)
    case 40
      depth += 1
    case 41
      if depth > 0 then depth -= 1
    case 44
      if depth <> 0 then continue for
      if partCount = 0 then
        redim elems(0 to 0)
      else
        redim preserve elems(0 to partCount)
      end if
      elems(partCount) = Trim(Mid(s, start, i - start))
      partCount += 1
      start = i + 1
    case else
    end select
  next i
  if partCount = 0 then
    redim elems(0 to 0)
  else
    redim preserve elems(0 to partCount)
  end if
  elems(partCount) = Trim(Mid(s, start, n - start + 1))
  return partCount + 1
end function

'' Map parser scalar token to formatter display; empty if not non-finite.
function FormatNonFiniteDisplayFromParserScalar(byref s as String) as String
  dim t as String = LCase(Trim(s))
  if t = SM_TOK_NAN_LC then return SM_FMT_NAN
  if t = SM_TOK_INF_LC then return SM_FMT_INF
  if t = SM_TOK_NEGINF_LC then return SM_FMT_NEGINF
  return ""
end function

'' Normalize ...E+03 / ...e-04 to lowercase e and trim leading zeros in exponent.
private sub NormalizeScientificExponentTail(byref sRes as String)
  dim ePos as Integer = IndexOfExponentLetter(sRes)
  if ePos = 0 then exit sub
  dim mantissa as String = Left(sRes, ePos - 1)
  dim expPart as String = Mid(sRes, ePos + 1)
  dim expSign as String = "+"
  if Left(expPart, 1) = "-" then
    expSign = "-"
    expPart = Mid(expPart, 2)
  elseif Left(expPart, 1) = "+" then
    expPart = Mid(expPart, 2)
  end if
  while Len(expPart) > 1 andalso Left(expPart, 1) = "0"
    expPart = Mid(expPart, 2)
  wend
  sRes = mantissa & "e" & expSign & expPart
end sub

'' Same grouping as legacy right-to-left loop; builds left-to-right (fewer allocations).
private function InsertThousandsIntPart(byref intPart as String, byref localThouSep as String) as String
  dim n as Integer = Len(intPart)
  if n <= 3 then return intPart
  dim lead as Integer = n mod 3
  if lead = 0 then lead = 3
  dim outText as String = Mid(intPart, 1, lead)
  dim p as Integer = lead + 1
  while p <= n
    outText &= localThouSep & Mid(intPart, p, 3)
    p += 3
  wend
  return outText
end function

private function FormatNumericValue(byval d as Double) as String
  dim sRes as String
  dim eScanPos as Integer

  '' Non-finite: IEEE-754 first (all NaN payloads: exp all-1, nonzero fraction), then ordered checks.
  dim bits as ULongInt = *cast(ULongInt ptr, @d)
  if (bits and SM_DBL_EXP_MASK) = SM_DBL_EXP_MASK then
    if (bits and SM_DBL_FRAC_MASK) <> 0 then return SM_FMT_NAN
    if (bits and SM_DBL_SIGN_MASK) <> 0 then return SM_FMT_NEGINF
    return SM_FMT_INF
  end if
  if d <> d then return SM_FMT_NAN
  if Not (d <= d) then return SM_FMT_NAN

  if g_nDecimals < 0 then
    sRes = LTrim(Str(d))
    eScanPos = IndexOfExponentLetter(sRes)
  else
    dim useScientific as Boolean = FALSE
    dim ad as Double = Abs(d)

    if ad > 0 then
      dim leadingZeroDigits as Integer = g_nDecimals \ 2
      if leadingZeroDigits > 0 then
        if ad < 1.0 / Pow10Cached(leadingZeroDigits) then useScientific = TRUE
      end if

      dim isInt64Like as Boolean = FALSE
      const I64_MAX_D as Double = 9223372036854775807.0
      const I64_MIN_D as Double = -9223372036854775808.0
      if d >= I64_MIN_D andalso d <= I64_MAX_D then
        if d = Fix(d) then isInt64Like = TRUE
      end if

      if isInt64Like = FALSE then
        if ad >= Pow10Cached(g_nDecimals + 6) then useScientific = TRUE
      end if
    end if

    if useScientific then
      sRes = FormatWithAsciiDecimal(d, MaskSciCached(g_nDecimals))
    else
      sRes = FormatWithAsciiDecimal(d, MaskFixedCached(g_nDecimals))
    end if

    eScanPos = IndexOfExponentLetter(sRes)
    if eScanPos = 0 then
      sRes = TrimTrailingFractionZeros(sRes)
    end if
  end if

  if eScanPos > 0 then
    dim m as String = TrimTrailingFractionZeros(Left(sRes, eScanPos - 1))
    dim eTail as String = Mid(sRes, eScanPos)
    sRes = m & eTail
  end if

  NormalizeScientificExponentTail(sRes)

  if g_bUseThousandsSeparator then
    dim oldEPos as Integer = IndexOfExponentLetter(sRes)
    dim expPart2 as String = ""
    if oldEPos > 0 then
      expPart2 = Mid(sRes, oldEPos)
      sRes = Left(sRes, oldEPos - 1)
    end if

    dim decPos as Integer = PositionOfNumericDecimal(sRes)
    dim localThouSep as String = g_sThousandsSeparator

    dim intPart as String
    dim decPart as String

    if decPos > 0 then
      intPart = Left(sRes, decPos - 1)
      decPart = Mid(sRes, decPos)
      if Left(decPart, 1) = "." andalso g_sDecimalSeparator <> "." then
        decPart = g_sDecimalSeparator & Mid(decPart, 2)
      end if
    else
      intPart = sRes
      decPart = ""
    end if

    dim isNeg as Boolean = False
    if Len(intPart) > 0 andalso Left(intPart, 1) = "-" then
      isNeg = True
      intPart = Mid(intPart, 2)
    end if

    dim withCommas as String = InsertThousandsIntPart(intPart, localThouSep)

    if isNeg then withCommas = "-" & withCommas
    sRes = withCommas & decPart & expPart2
  end if

  return sRes
end function

function FormatResult(byval d as Double) as String
  return SMARTMATH_RESULT_PREFIX & FormatNumericValue(d)
end function

'' Shared by FormatArrayResultText tuple branches: rawTokens TRUE keeps parser scalars; FALSE runs FormatNumericValue(Val).
private sub AppendTupleBodyFromElems(byref outText as String, elems() as String, byval cnt as Integer, byval rawTokens as Boolean)
  dim j as Integer
  for j = 0 to cnt - 1
    if j > 0 then outText &= g_sArrayOutputSeparator & " "
    dim nf as String = FormatNonFiniteDisplayFromParserScalar(elems(j))
    if Len(nf) > 0 then
      outText &= nf
    elseif rawTokens then
      outText &= elems(j)
    else
      outText &= FormatNumericValue(Val(elems(j)))
    end if
  next j
end sub

function FormatArrayResultText(byref sArrayText as String) as String
  if g_nDecimals < 0 andalso g_bUseThousandsSeparator = FALSE then
    dim trimmedFast as String = Trim(sArrayText)
    if Len(trimmedFast) >= 2 andalso Left(trimmedFast, 1) = "(" andalso Right(trimmedFast, 1) = ")" then
      dim innerFast as String = Mid(trimmedFast, 2, Len(trimmedFast) - 2)
      dim elemsFast() as String
      dim cntFast as Integer = SplitTopLevelArrayCsvInner(innerFast, elemsFast())
      dim outFast as String = "("
      AppendTupleBodyFromElems(outFast, elemsFast(), cntFast, TRUE)
      outFast &= ")"
      return SMARTMATH_RESULT_PREFIX & outFast
    end if
    return SMARTMATH_RESULT_PREFIX & AddArrayCommaSpacing(sArrayText)
  end if

  dim t as String = LCase(sArrayText)
  if InStr(1, t, "0x") > 0 orelse InStr(1, t, "0b") > 0 orelse InStr(1, t, "0o") > 0 then
    return SMARTMATH_RESULT_PREFIX & AddArrayCommaSpacing(sArrayText)
  end if

  '' Parser uses comma only between elements; do not treat g_sDecimalSeparator as part of scan
  '' (European "," would merge "(40,50)" into one token). Join with ArrayOutputSeparator so
  '' formatted numbers may contain "," decimals without breaking.
  dim trimmed as String = Trim(sArrayText)
  if Len(trimmed) >= 2 andalso Left(trimmed, 1) = "(" andalso Right(trimmed, 1) = ")" then
    dim inner as String = Mid(trimmed, 2, Len(trimmed) - 2)
    dim elems() as String
    dim cnt as Integer = SplitTopLevelArrayCsvInner(inner, elems())
    dim outText as String = "("
    AppendTupleBodyFromElems(outText, elems(), cnt, FALSE)
    outText &= ")"
    return SMARTMATH_RESULT_PREFIX & outText
  end if

  return SMARTMATH_RESULT_PREFIX & AddArrayCommaSpacing(sArrayText)
end function
