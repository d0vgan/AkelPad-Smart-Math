#include once "SmartMath_Globals.bi"

' -----------------------------------------------------------------------------
'  Settings Loading & Saving
' -----------------------------------------------------------------------------
sub LoadSettings()
  g_sDecimalSeparator = SMARTMATH_DECIMAL_SEPARATOR_DEFAULT
  g_sThousandsSeparator = SMARTMATH_THOUSANDS_SEPARATOR_DEFAULT
  g_sArrayOutputSeparator = SMARTMATH_ARRAY_OUTPUT_SEPARATOR_DEFAULT

  if g_wszIniPath <> "" then
    dim sVal as WString * 32
    GetPrivateProfileStringW(wstr("Settings"), wstr("Decimals"), wstr("-1"), @sVal, 32, g_wszIniPath)
    g_nDecimals = Val(sVal)

    ' 32768 corresponds to &H008000 (Green)
    GetPrivateProfileStringW(wstr("Settings"), wstr("Color"), wstr("32768"), @sVal, 32, g_wszIniPath)
    g_crResultColor = Val(sVal)
    
    GetPrivateProfileStringW(wstr("Settings"), wstr("ThousandsSeparator"), wstr("0"), @sVal, 32, g_wszIniPath)
    if Val(sVal) <> 0 then
      g_bUseThousandsSeparator = TRUE
    else
      g_bUseThousandsSeparator = FALSE
    end if

    GetPrivateProfileStringW(wstr("Settings"), wstr("LogParsedLines"), wstr("0"), @sVal, 32, g_wszIniPath)
    if Val(sVal) <> 0 then
      g_bLogParsedLines = TRUE
    else
      g_bLogParsedLines = FALSE
    end if

    GetPrivateProfileStringW(wstr("Settings"), wstr("DecimalSeparatorChar"), wstr(SMARTMATH_DECIMAL_SEPARATOR_DEFAULT), @sVal, 32, g_wszIniPath)
    if Len(sVal) > 0 then g_sDecimalSeparator = Left(sVal, 1)

    GetPrivateProfileStringW(wstr("Settings"), wstr("ThousandsSeparatorChar"), wstr(SMARTMATH_THOUSANDS_SEPARATOR_DEFAULT), @sVal, 32, g_wszIniPath)
    if Len(sVal) > 0 then g_sThousandsSeparator = Left(sVal, 1)

    GetPrivateProfileStringW(wstr("Settings"), wstr("ArrayOutputSeparatorChar"), wstr(SMARTMATH_ARRAY_OUTPUT_SEPARATOR_DEFAULT), @sVal, 32, g_wszIniPath)
    if Len(sVal) > 0 then g_sArrayOutputSeparator = Left(sVal, 1)
  end if
end sub

sub SaveSettings()
  if g_wszIniPath <> "" then
    dim sVal as WString * 32 = WStr(g_nDecimals)
    WritePrivateProfileStringW(wstr("Settings"), wstr("Decimals"), sVal, g_wszIniPath)

    sVal = WStr(g_crResultColor)
    WritePrivateProfileStringW(wstr("Settings"), wstr("Color"), sVal, g_wszIniPath)
    
    if g_bUseThousandsSeparator then sVal = wstr("1") else sVal = wstr("0")
    WritePrivateProfileStringW(wstr("Settings"), wstr("ThousandsSeparator"), sVal, g_wszIniPath)

    if g_bLogParsedLines then sVal = wstr("1") else sVal = wstr("0")
    WritePrivateProfileStringW(wstr("Settings"), wstr("LogParsedLines"), sVal, g_wszIniPath)

    sVal = WStr(g_sDecimalSeparator)
    WritePrivateProfileStringW(wstr("Settings"), wstr("DecimalSeparatorChar"), sVal, g_wszIniPath)

    sVal = WStr(g_sThousandsSeparator)
    WritePrivateProfileStringW(wstr("Settings"), wstr("ThousandsSeparatorChar"), sVal, g_wszIniPath)

    sVal = WStr(g_sArrayOutputSeparator)
    WritePrivateProfileStringW(wstr("Settings"), wstr("ArrayOutputSeparatorChar"), sVal, g_wszIniPath)
  end if
end sub