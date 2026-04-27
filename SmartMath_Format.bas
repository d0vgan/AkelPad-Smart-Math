#include once "SmartMath_Globals.bi"

' -----------------------------------------------------------------------------
'  Result Formatting
' -----------------------------------------------------------------------------
private function Pow10(byval n as Integer) as Double
  dim p as Double = 1.0
  if n > 0 then
    for i as Integer = 1 to n
      p *= 10.0
    next i
  end if
  return p
end function

'' Format() / Str() use ASCII "."; ini may set g_sDecimalSeparator to ",". Detect either.
private function PositionOfNumericDecimal(byref s as String) as Integer
  dim p as Integer = InStr(s, g_sDecimalSeparator)
  if p > 0 then return p
  return InStr(s, ".")
end function

private function TrimTrailingFractionZeros(byref s as String) as String
  dim outText as String = s
  if PositionOfNumericDecimal(outText) > 0 orelse InStr(outText, ",") > 0 then
    while Right(outText, 1) = "0"
      outText = Left(outText, Len(outText) - 1)
    wend
    dim lastCh as String = Right(outText, 1)
    if lastCh = g_sDecimalSeparator orelse lastCh = "," orelse lastCh = "." then
      outText = Left(outText, Len(outText) - 1)
    end if
  end if
  return outText
end function

private function AddArrayCommaSpacing(byref s as String) as String
  dim outText as String = ""
  dim i as Integer
  for i = 1 to Len(s)
    dim ch as String = Mid(s, i, 1)
    if ch = "," then
      outText &= g_sArrayOutputSeparator & " "
    else
      outText &= ch
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
    dim ch as String = Mid(s, i, 1)
    if ch = "(" then
      depth += 1
    elseif ch = ")" then
      if depth > 0 then depth -= 1
    elseif ch = "," andalso depth = 0 then
      if partCount = 0 then
        redim elems(0 to 0)
      else
        redim preserve elems(0 to partCount)
      end if
      elems(partCount) = Trim(Mid(s, start, i - start))
      partCount += 1
      start = i + 1
    end if
  next i
  if partCount = 0 then
    redim elems(0 to 0)
  else
    redim preserve elems(0 to partCount)
  end if
  elems(partCount) = Trim(Mid(s, start, n - start + 1))
  return partCount + 1
end function

private function FormatNumericValue(byval d as Double) as String
  dim sRes as String

  ' Non-finite values must bypass all normal formatting logic.
  dim rawText as String = UCase(LTrim(Str(d)))
  if InStr(rawText, "NAN") > 0 orelse InStr(rawText, "IND") > 0 then return "NaN"
  if InStr(rawText, "INF") > 0 then
    if Left(rawText, 1) = "-" then
      return "-INF"
    else
      return "INF"
    end if
  end if

  if g_nDecimals < 0 then
    sRes = LTrim(Str(d))
  else
    dim useScientific as Boolean = FALSE
    dim ad as Double = Abs(d)

    if ad > 0 then
      ' Small-value switch rule:
      ' If first int(N/2) digits after decimal point are zero, switch to scientific.
      dim leadingZeroDigits as Integer = g_nDecimals \ 2
      if leadingZeroDigits > 0 then
        dim smallThreshold as Double = 1.0 / Pow10(leadingZeroDigits)
        if ad < smallThreshold then useScientific = TRUE
      end if

      ' For large values, keep plain notation for exact signed int64 range integers.
      dim isInt64Like as Boolean = FALSE
      const I64_MAX_D as Double = 9223372036854775807.0
      const I64_MIN_D as Double = -9223372036854775808.0
      if d >= I64_MIN_D andalso d <= I64_MAX_D then
        if d = Fix(d) then isInt64Like = TRUE
      end if

      if isInt64Like = FALSE then
        dim largeThreshold as Double = Pow10(g_nDecimals + 6)
        if ad >= largeThreshold then useScientific = TRUE
      end if
    end if

    if useScientific then
      dim sSciFmt as String
      if g_nDecimals = 0 then
        sSciFmt = "0E+00"
      else
        sSciFmt = "0." & String(g_nDecimals, "0") & "E+00"
      end if
      sRes = Format(d, sSciFmt)
    else
      dim sFmt as String
      if g_nDecimals = 0 then
        sFmt = "0"
      else
        sFmt = "0." & String(g_nDecimals, "0")
      end if
      sRes = Format(d, sFmt)
    end if

    if InStr(UCase(sRes), "E") = 0 then
      sRes = TrimTrailingFractionZeros(sRes)
    end if
  end if

  ' Trim trailing zeros in mantissa (also for scientific notation).
  dim eScanPos as Integer = InStr(UCase(sRes), "E")
  if eScanPos > 0 then
    dim m as String = TrimTrailingFractionZeros(Left(sRes, eScanPos - 1))
    dim eTail as String = Mid(sRes, eScanPos)
    sRes = m & eTail
  end if

  ' Normalize scientific exponent style to e+N/e-N (no leading zeroes).
  dim ePos as Integer = InStr(UCase(sRes), "E")
  if ePos > 0 then
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
  end if

  if g_bUseThousandsSeparator then
    dim oldEPos as Integer = InStr(UCase(sRes), "E")
    if oldEPos = 0 then oldEPos = InStr(sRes, "e")
    dim expPart as String = ""
    if oldEPos > 0 then
      expPart = Mid(sRes, oldEPos)
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
    if Left(intPart, 1) = "-" then
      isNeg = True
      intPart = Mid(intPart, 2)
    end if

    dim withCommas as String = ""
    dim count as Integer = 0
    for i as Integer = Len(intPart) to 1 step -1
      count += 1
      withCommas = Mid(intPart, i, 1) & withCommas
      if count = 3 andalso i > 1 then
        withCommas = localThouSep & withCommas
        count = 0
      end if
    next i

    if isNeg then withCommas = "-" & withCommas
    sRes = withCommas & decPart & expPart
  end if

  return sRes
end function

function FormatResult(byval d as Double) as String
  return SMARTMATH_RESULT_PREFIX & FormatNumericValue(d)
end function

function FormatArrayResultText(byref sArrayText as String) as String
  if g_nDecimals < 0 andalso g_bUseThousandsSeparator = FALSE then
    return SMARTMATH_RESULT_PREFIX & AddArrayCommaSpacing(sArrayText)
  end if

  dim t as String = LCase(sArrayText)
  if InStr(t, "0x") > 0 orelse InStr(t, "0b") > 0 orelse InStr(t, "0o") > 0 then
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
    dim ei as Integer
    for ei = 0 to cnt - 1
      if ei > 0 then outText &= g_sArrayOutputSeparator & " "
      outText &= FormatNumericValue(Val(elems(ei)))
    next ei
    outText &= ")"
    return SMARTMATH_RESULT_PREFIX & outText
  end if

  return SMARTMATH_RESULT_PREFIX & AddArrayCommaSpacing(sArrayText)
end function