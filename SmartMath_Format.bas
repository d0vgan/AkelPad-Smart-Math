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

private function TrimTrailingFractionZeros(byref s as String) as String
  dim outText as String = s
  if InStr(outText, SMARTMATH_DECIMAL_SEPARATOR) > 0 orelse InStr(outText, ",") > 0 then
    while Right(outText, 1) = "0"
      outText = Left(outText, Len(outText) - 1)
    wend
    if Right(outText, 1) = SMARTMATH_DECIMAL_SEPARATOR orelse Right(outText, 1) = "," then
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
      outText &= ", "
    else
      outText &= ch
    end if
  next i
  return outText
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

    dim decPos as Integer = InStr(sRes, SMARTMATH_DECIMAL_SEPARATOR)
    dim localThouSep as String = SMARTMATH_THOUSANDS_SEPARATOR

    dim intPart as String
    dim decPart as String

    if decPos > 0 then
      intPart = Left(sRes, decPos - 1)
      decPart = Mid(sRes, decPos)
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
  if InStr(t, "0x") > 0 orelse InStr(t, "0b") > 0 then
    return SMARTMATH_RESULT_PREFIX & AddArrayCommaSpacing(sArrayText)
  end if

  dim outText as String = ""
  dim i as Integer = 1
  while i <= Len(sArrayText)
    dim ch as String = Mid(sArrayText, i, 1)
    dim isNumStart as Boolean = FALSE
    if (ch >= "0" andalso ch <= "9") orelse ch = SMARTMATH_DECIMAL_SEPARATOR then
      isNumStart = TRUE
    elseif (ch = "-" orelse ch = "+") andalso i < Len(sArrayText) then
      dim nextCh as String = Mid(sArrayText, i + 1, 1)
      if (nextCh >= "0" andalso nextCh <= "9") orelse nextCh = SMARTMATH_DECIMAL_SEPARATOR then isNumStart = TRUE
    end if

    if isNumStart then
      dim j as Integer = i
      while j <= Len(sArrayText)
        dim c as String = Mid(sArrayText, j, 1)
        if (c >= "0" andalso c <= "9") orelse c = SMARTMATH_DECIMAL_SEPARATOR orelse c = "e" orelse c = "E" orelse c = "+" orelse c = "-" then
          j += 1
        else
          exit while
        end if
      wend
      dim token as String = Mid(sArrayText, i, j - i)
      dim v as Double = Val(token)
      outText &= FormatNumericValue(v)
      i = j
    else
      outText &= ch
      i += 1
    end if
  wend

  return SMARTMATH_RESULT_PREFIX & AddArrayCommaSpacing(outText)
end function