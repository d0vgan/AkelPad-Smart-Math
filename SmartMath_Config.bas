#include once "SmartMath_Globals.bi"

' -----------------------------------------------------------------------------
'  Settings Loading & Saving
' -----------------------------------------------------------------------------
#define SMARTMATH_OPTIONS_PLUGIN_NAME          WStr("SmartMath")
#define SMARTMATH_OPT_DECIMALS                 WStr("Decimals")
#define SMARTMATH_OPT_COLOR                    WStr("Color")
#define SMARTMATH_OPT_THOUSANDS_SEPARATOR      WStr("ThousandsSeparator")
#define SMARTMATH_OPT_LOG_PARSED_LINES         WStr("LogParsedLines")
#define SMARTMATH_OPT_DECIMAL_SEPARATOR_CHAR   WStr("DecimalSeparatorChar")
#define SMARTMATH_OPT_THOUSANDS_SEPARATOR_CHAR WStr("ThousandsSeparatorChar")
#define SMARTMATH_OPT_ARRAY_OUTPUT_SEPARATOR_CHAR WStr("ArrayOutputSeparatorChar")
const SMARTMATH_OPT_STR_MAX_CHARS = 32

type SMARTMATH_SETTINGS_CACHE
  isInitialized as BOOL
  hasDecimals as BOOL
  hasColor as BOOL
  hasThousandsSeparator as BOOL
  hasLogParsedLines as BOOL
  hasDecimalSeparator as BOOL
  hasThousandsSeparatorChar as BOOL
  hasArrayOutputSeparator as BOOL
  nDecimals as Integer
  crResultColor as COLORREF
  bUseThousandsSeparator as BOOL
  bLogParsedLines as BOOL
  sDecimalSeparator as String
  sThousandsSeparator as String
  sArrayOutputSeparator as String
end type

' note: all the fields are 0-initialized by default, so no need to initialize them manually
dim shared g_settingsCache as SMARTMATH_SETTINGS_CACHE

private sub ResetSettingsCacheReadState()
  g_settingsCache.hasDecimals = FALSE
  g_settingsCache.hasColor = FALSE
  g_settingsCache.hasThousandsSeparator = FALSE
  g_settingsCache.hasLogParsedLines = FALSE
  g_settingsCache.hasDecimalSeparator = FALSE
  g_settingsCache.hasThousandsSeparatorChar = FALSE
  g_settingsCache.hasArrayOutputSeparator = FALSE
end sub

private sub CacheSetInt(byref hasValue as BOOL, byref cacheValue as Integer, byval value as Integer)
  hasValue = TRUE
  cacheValue = value
end sub

private sub CacheSetDword(byref hasValue as BOOL, byref cacheValue as DWORD, byval value as DWORD)
  hasValue = TRUE
  cacheValue = value
end sub

private sub CacheSetBool(byref hasValue as BOOL, byref cacheValue as BOOL, byval value as BOOL)
  hasValue = TRUE
  cacheValue = value
end sub

private sub CacheSetString(byref hasValue as BOOL, byref cacheValue as String, byval value as String)
  hasValue = TRUE
  cacheValue = value
end sub

private sub EnsureSettingsCacheInitialized()
  if g_settingsCache.isInitialized = FALSE then
    ResetSettingsCacheReadState()
  end if
end sub

private function readDwordW( _
  byval hOptions as HANDLE, _
  byref optionName as WString, _
  byref outValue as DWORD _
) as Integer
  dim poW as PLUGINOPTIONW
  poW.pOptionName = strptr(optionName)
  poW.dwType = PO_DWORD
  poW.lpData = cast(UByte ptr, @outValue)
  poW.dwData = sizeof(DWORD)
  return CInt(SendMessage(g_hMainWnd, AKD_OPTIONW, cast(WPARAM, hOptions), cast(LPARAM, @poW))) ' returns the number of bytes copied
end function

private function readStringW( _
  byval hOptions as HANDLE, _
  byref optionName as WString, _
  byref outValue as WString, _
  byval outChars as DWORD _
) as Integer
  dim poW as PLUGINOPTIONW
  poW.pOptionName = strptr(optionName)
  poW.dwType = PO_STRING
  poW.lpData = cast(UByte ptr, strptr(outValue))
  poW.dwData = outChars * 2
  return CInt(SendMessage(g_hMainWnd, AKD_OPTIONW, cast(WPARAM, hOptions), cast(LPARAM, @poW))) ' returns the number of bytes copied
end function

private sub writeStringW( _
  byval hOptions as HANDLE, _
  byref optionName as WString, _
  byref valueText as WString _
)
  dim poW as PLUGINOPTIONW
  poW.pOptionName = strptr(optionName)
  poW.dwType = PO_STRING
  poW.lpData = cast(UByte ptr, strptr(valueText))
  poW.dwData = (len(valueText) + 1) * 2
  SendMessage(g_hMainWnd, AKD_OPTIONW, cast(WPARAM, hOptions), cast(LPARAM, @poW))
end sub

private sub writeDwordW( _
  byval hOptions as HANDLE, _
  byref optionName as WString, _
  byval value as DWORD _
)
  dim poW as PLUGINOPTIONW
  poW.pOptionName = strptr(optionName)
  poW.dwType = PO_DWORD
  poW.lpData = cast(UByte ptr, @value)
  poW.dwData = sizeof(DWORD)
  SendMessage(g_hMainWnd, AKD_OPTIONW, cast(WPARAM, hOptions), cast(LPARAM, @poW))
end sub

sub LoadSettings()
  ' default values before reading the options
  g_nDecimals = -1
  g_crResultColor = &H008000 ' Green
  g_bUseThousandsSeparator = FALSE
  g_bLogParsedLines = FALSE
  g_sDecimalSeparator = SMARTMATH_DECIMAL_SEPARATOR_DEFAULT
  g_sThousandsSeparator = SMARTMATH_THOUSANDS_SEPARATOR_DEFAULT
  g_sArrayOutputSeparator = SMARTMATH_ARRAY_OUTPUT_SEPARATOR_DEFAULT

  EnsureSettingsCacheInitialized()
  ResetSettingsCacheReadState()
  ' Intentionally keep the has-value flags in the cache as FALSE when options can't be read,
  ' so the first SaveSettings writes current values.

  if g_hMainWnd = 0 then exit sub ' nothing to do

  dim hOptions as HANDLE = cast(HANDLE, SendMessage(g_hMainWnd, AKD_BEGINOPTIONSW, POB_READ, cast(LPARAM, strptr(SMARTMATH_OPTIONS_PLUGIN_NAME))))
  ' OutputDebugString("[SmartMath] hOptions=" & hOptions)
  if hOptions = 0 then exit sub ' can not read options

  dim dwVal as DWORD
  dim sVal as WString * SMARTMATH_OPT_STR_MAX_CHARS

  if readDwordW(hOptions, SMARTMATH_OPT_DECIMALS, dwVal) = sizeof(DWORD) then
    g_nDecimals = CInt(dwVal)
    CacheSetInt(g_settingsCache.hasDecimals, g_settingsCache.nDecimals, g_nDecimals)
  end if

  if readDwordW(hOptions, SMARTMATH_OPT_COLOR, dwVal) = sizeof(DWORD) then
    g_crResultColor = dwVal
    CacheSetDword(g_settingsCache.hasColor, g_settingsCache.crResultColor, g_crResultColor)
  end if

  if readDwordW(hOptions, SMARTMATH_OPT_THOUSANDS_SEPARATOR, dwVal) = sizeof(DWORD) then
    g_bUseThousandsSeparator = (dwVal <> 0u)
    CacheSetBool(g_settingsCache.hasThousandsSeparator, g_settingsCache.bUseThousandsSeparator, g_bUseThousandsSeparator)
  end if

  if readDwordW(hOptions, SMARTMATH_OPT_LOG_PARSED_LINES, dwVal) = sizeof(DWORD) then
    g_bLogParsedLines = (dwVal <> 0u)
    CacheSetBool(g_settingsCache.hasLogParsedLines, g_settingsCache.bLogParsedLines, g_bLogParsedLines)
  end if

  sVal = WStr(SMARTMATH_DECIMAL_SEPARATOR_DEFAULT)
  if readStringW(hOptions, SMARTMATH_OPT_DECIMAL_SEPARATOR_CHAR, sVal, SMARTMATH_OPT_STR_MAX_CHARS) > 0 then
    g_sDecimalSeparator = Left(sVal, 1)
    CacheSetString(g_settingsCache.hasDecimalSeparator, g_settingsCache.sDecimalSeparator, g_sDecimalSeparator)
  end if

  sVal = WStr(SMARTMATH_THOUSANDS_SEPARATOR_DEFAULT)
  if readStringW(hOptions, SMARTMATH_OPT_THOUSANDS_SEPARATOR_CHAR, sVal, SMARTMATH_OPT_STR_MAX_CHARS) > 0 then
    g_sThousandsSeparator = Left(sVal, 1)
    CacheSetString(g_settingsCache.hasThousandsSeparatorChar, g_settingsCache.sThousandsSeparator, g_sThousandsSeparator)
  end if

  sVal = WStr(SMARTMATH_ARRAY_OUTPUT_SEPARATOR_DEFAULT)
  if readStringW(hOptions, SMARTMATH_OPT_ARRAY_OUTPUT_SEPARATOR_CHAR, sVal, SMARTMATH_OPT_STR_MAX_CHARS) > 0 then
    g_sArrayOutputSeparator = Left(sVal, 1)
    CacheSetString(g_settingsCache.hasArrayOutputSeparator, g_settingsCache.sArrayOutputSeparator, g_sArrayOutputSeparator)
  end if

  ' OutputDebugString("[SmartMath] LoadSettings: g_nDecimals=" & g_nDecimals)
  ' OutputDebugString("[SmartMath] LoadSettings: g_crResultColor=" & g_crResultColor)
  ' OutputDebugString("[SmartMath] LoadSettings: g_bUseThousandsSeparator=" & g_bUseThousandsSeparator)
  ' OutputDebugString("[SmartMath] LoadSettings: g_bLogParsedLines=" & g_bLogParsedLines)
  ' OutputDebugString("[SmartMath] LoadSettings: g_sDecimalSeparator=" & g_sDecimalSeparator)
  ' OutputDebugString("[SmartMath] LoadSettings: g_sThousandsSeparator=" & g_sThousandsSeparator)
  ' OutputDebugString("[SmartMath] LoadSettings: g_sArrayOutputSeparator=" & g_sArrayOutputSeparator)

  SendMessage(g_hMainWnd, AKD_ENDOPTIONS, cast(WPARAM, hOptions), 0) ' be sure to close the options handle

  g_settingsCache.isInitialized = TRUE
end sub

sub SaveSettings()
  EnsureSettingsCacheInitialized()

  if g_hMainWnd = 0 then exit sub ' nothing to do

  dim shouldSaveDecimals as BOOL = (g_settingsCache.hasDecimals = FALSE) orElse (g_settingsCache.nDecimals <> g_nDecimals)
  dim shouldSaveColor as BOOL = (g_settingsCache.hasColor = FALSE) orElse (g_settingsCache.crResultColor <> g_crResultColor)
  dim shouldSaveThousandsFlag as BOOL = (g_settingsCache.hasThousandsSeparator = FALSE) orElse (g_settingsCache.bUseThousandsSeparator <> g_bUseThousandsSeparator)
  dim shouldSaveLogFlag as BOOL = (g_settingsCache.hasLogParsedLines = FALSE) orElse (g_settingsCache.bLogParsedLines <> g_bLogParsedLines)
  dim shouldSaveDecimalSep as BOOL = (g_settingsCache.hasDecimalSeparator = FALSE) orElse (g_settingsCache.sDecimalSeparator <> g_sDecimalSeparator)
  dim shouldSaveThousandsSep as BOOL = (g_settingsCache.hasThousandsSeparatorChar = FALSE) orElse (g_settingsCache.sThousandsSeparator <> g_sThousandsSeparator)
  dim shouldSaveArraySep as BOOL = (g_settingsCache.hasArrayOutputSeparator = FALSE) orElse (g_settingsCache.sArrayOutputSeparator <> g_sArrayOutputSeparator)

  ' OutputDebugString("[SmartMath] SaveSettings: shouldSaveDecimals=" & shouldSaveDecimals)
  ' OutputDebugString("[SmartMath] SaveSettings: shouldSaveColor=" & shouldSaveColor)
  ' OutputDebugString("[SmartMath] SaveSettings: shouldSaveThousandsFlag=" & shouldSaveThousandsFlag)
  ' OutputDebugString("[SmartMath] SaveSettings: shouldSaveLogFlag=" & shouldSaveLogFlag)
  ' OutputDebugString("[SmartMath] SaveSettings: shouldSaveDecimalSep=" & shouldSaveDecimalSep)
  ' OutputDebugString("[SmartMath] SaveSettings: shouldSaveThousandsSep=" & shouldSaveThousandsSep)
  ' OutputDebugString("[SmartMath] SaveSettings: shouldSaveArraySep=" & shouldSaveArraySep)

  ' OutputDebugString("[SmartMath] SaveSettings: cache: hasDecimalSeparator=" & g_settingsCache.hasDecimalSeparator & " sDecimalSeparator=" & g_settingsCache.sDecimalSeparator)
  ' OutputDebugString("[SmartMath] SaveSettings: cache: hasThousandsSeparatorChar=" & g_settingsCache.hasThousandsSeparatorChar & " sThousandsSeparator=" & g_settingsCache.sThousandsSeparator)
  ' OutputDebugString("[SmartMath] SaveSettings: cache: hasArrayOutputSeparator=" & g_settingsCache.hasArrayOutputSeparator & " sArrayOutputSeparator=" & g_settingsCache.sArrayOutputSeparator)

  if (shouldSaveDecimals = FALSE) _
     andalso (shouldSaveColor = FALSE) _
     andalso (shouldSaveThousandsFlag = FALSE) _
     andalso (shouldSaveLogFlag = FALSE) _
     andalso (shouldSaveDecimalSep = FALSE) _
     andalso (shouldSaveThousandsSep = FALSE) _
     andalso (shouldSaveArraySep = FALSE) then
    exit sub ' nothing to save
  end if

  dim hOptions as HANDLE = cast(HANDLE, SendMessage(g_hMainWnd, AKD_BEGINOPTIONSW, POB_SAVE, cast(LPARAM, strptr(SMARTMATH_OPTIONS_PLUGIN_NAME))))
  if hOptions = 0 then exit sub ' can not save options
  dim sVal as WString * SMARTMATH_OPT_STR_MAX_CHARS

  if shouldSaveDecimals then
    writeDwordW(hOptions, SMARTMATH_OPT_DECIMALS, g_nDecimals)
    CacheSetInt(g_settingsCache.hasDecimals, g_settingsCache.nDecimals, g_nDecimals)
  end if

  if shouldSaveColor then
    writeDwordW(hOptions, SMARTMATH_OPT_COLOR, g_crResultColor)
    CacheSetDword(g_settingsCache.hasColor, g_settingsCache.crResultColor, g_crResultColor)
  end if

  if shouldSaveThousandsFlag then
    writeDwordW(hOptions, SMARTMATH_OPT_THOUSANDS_SEPARATOR, IIf(g_bUseThousandsSeparator, 1u, 0u))
    CacheSetBool(g_settingsCache.hasThousandsSeparator, g_settingsCache.bUseThousandsSeparator, g_bUseThousandsSeparator)
  end if

  if shouldSaveLogFlag then
    writeDwordW(hOptions, SMARTMATH_OPT_LOG_PARSED_LINES, IIf(g_bLogParsedLines, 1u, 0u))
    CacheSetBool(g_settingsCache.hasLogParsedLines, g_settingsCache.bLogParsedLines, g_bLogParsedLines)
  end if

  if shouldSaveDecimalSep then
    sVal = WStr(g_sDecimalSeparator)
    writeStringW(hOptions, SMARTMATH_OPT_DECIMAL_SEPARATOR_CHAR, sVal)
    CacheSetString(g_settingsCache.hasDecimalSeparator, g_settingsCache.sDecimalSeparator, g_sDecimalSeparator)
  end if

  if shouldSaveThousandsSep then
    sVal = WStr(g_sThousandsSeparator)
    writeStringW(hOptions, SMARTMATH_OPT_THOUSANDS_SEPARATOR_CHAR, sVal)
    CacheSetString(g_settingsCache.hasThousandsSeparatorChar, g_settingsCache.sThousandsSeparator, g_sThousandsSeparator)
  end if

  if shouldSaveArraySep then
    sVal = WStr(g_sArrayOutputSeparator)
    writeStringW(hOptions, SMARTMATH_OPT_ARRAY_OUTPUT_SEPARATOR_CHAR, sVal)
    CacheSetString(g_settingsCache.hasArrayOutputSeparator, g_settingsCache.sArrayOutputSeparator, g_sArrayOutputSeparator)
  end if

  SendMessage(g_hMainWnd, AKD_ENDOPTIONS, cast(WPARAM, hOptions), 0) ' be sure to close the options handle

  g_settingsCache.isInitialized = TRUE
end sub