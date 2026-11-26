#include once "SmartMath_Globals.bi"

' -----------------------------------------------------------------------------
'  Live settings storage + Config_Get / Config_Set (NPP-aligned names)
' -----------------------------------------------------------------------------
dim shared storedDecimalPlaces as Integer = -1
dim shared storedResultColor as COLORREF = &H008000
dim shared storedUseThousandsSep as Boolean = FALSE
dim shared storedSupportComplexNumbers as Boolean = FALSE
dim shared storedShowErrors as Boolean = TRUE
dim shared storedSyntaxHighlight as Boolean = TRUE
dim shared storedLogParsedLines as Boolean = FALSE
dim shared storedDecimalSep as String
dim shared storedThousandsSep as String
dim shared storedArrayOutputSep as String

sub Config_SetDecimalPlaces(byval p as Integer)
  if (p = -1) orelse (p >= 0 andalso p <= SMARTMATH_DECIMALS_MAX) then
    storedDecimalPlaces = p
  end if
end sub

function Config_GetDecimalPlaces() as Integer
  return storedDecimalPlaces
end function

sub Config_SetUseThousandsSep(byval enabled as Boolean)
  storedUseThousandsSep = enabled
end sub

function Config_GetUseThousandsSep() as Boolean
  return storedUseThousandsSep
end function

sub Config_SetSupportComplexNumbers(byval enabled as Boolean)
  storedSupportComplexNumbers = enabled
end sub

function Config_GetSupportComplexNumbers() as Boolean
  return storedSupportComplexNumbers
end function

sub Config_SetShowErrors(byval enabled as Boolean)
  storedShowErrors = enabled
end sub

function Config_GetShowErrors() as Boolean
  return storedShowErrors
end function

sub Config_SetSyntaxHighlight(byval enabled as Boolean)
  storedSyntaxHighlight = enabled
end sub

function Config_GetSyntaxHighlight() as Boolean
  return storedSyntaxHighlight
end function

sub Config_SetDecimalSep(byref s as String)
  storedDecimalSep = s
end sub

function Config_GetDecimalSep() as String
  return storedDecimalSep
end function

sub Config_SetThousandsSep(byref s as String)
  storedThousandsSep = s
end sub

function Config_GetThousandsSep() as String
  return storedThousandsSep
end function

sub Config_SetArrayOutputSep(byref s as String)
  storedArrayOutputSep = s
end sub

function Config_GetArrayOutputSep() as String
  return storedArrayOutputSep
end function

sub Config_SetResultColor(byval c as COLORREF)
  storedResultColor = c
end sub

function Config_GetResultColor() as COLORREF
  return storedResultColor
end function

sub Config_SetLogParsedLines(byval enabled as Boolean)
  storedLogParsedLines = enabled
end sub

function Config_GetLogParsedLines() as Boolean
  return storedLogParsedLines
end function

' -----------------------------------------------------------------------------
'  Settings Loading & Saving
' -----------------------------------------------------------------------------
#define SMARTMATH_OPTIONS_PLUGIN_NAME             WStr("SmartMath")
#define SMARTMATH_OPT_DECIMALS                    WStr("Decimals")
#define SMARTMATH_OPT_COLOR                       WStr("Color")
#define SMARTMATH_OPT_THOUSANDS_SEPARATOR         WStr("ThousandsSeparator")
#define SMARTMATH_OPT_COMPLEX_NUMBERS             WStr("ComplexNumbers")
#define SMARTMATH_OPT_SHOW_ERRORS                 WStr("ShowErrors")
#define SMARTMATH_OPT_SYNTAX_HIGHLIGHT            WStr("SyntaxHighlight")
#define SMARTMATH_OPT_LOG_PARSED_LINES            WStr("LogParsedLines")
#define SMARTMATH_OPT_DECIMAL_SEPARATOR_CHAR      WStr("DecimalSeparatorChar")
#define SMARTMATH_OPT_THOUSANDS_SEPARATOR_CHAR    WStr("ThousandsSeparatorChar")
#define SMARTMATH_OPT_ARRAY_OUTPUT_SEPARATOR_CHAR WStr("ArrayOutputSeparatorChar")
#define SMARTMATH_ACTIVE_FRAMES_OPTION_NAME       WStr("ActiveSmartMathFrames")
const SMARTMATH_OPT_STR_MAX_CHARS = 32
const SMARTMATH_ACTIVE_FRAME_FILE_SEPARATOR as UShort = 10 '' LF

type SMARTMATH_SETTINGS_CACHE
  isInitialized as Boolean
  hasDecimals as Boolean
  hasColor as Boolean
  hasThousandsSeparator as Boolean
  hasComplexNumbers as Boolean
  hasShowErrors as Boolean
  hasSyntaxHighlight as Boolean
  hasLogParsedLines as Boolean
  hasDecimalSeparator as Boolean
  hasThousandsSeparatorChar as Boolean
  hasArrayOutputSeparator as Boolean
  nDecimals as Integer
  crResultColor as COLORREF
  bUseThousandsSeparator as Boolean
  bSupportComplexNumbers as Boolean
  bShowErrors as Boolean
  bSyntaxHighlight as Boolean
  bLogParsedLines as Boolean
  sDecimalSeparator as String
  sThousandsSeparator as String
  sArrayOutputSeparator as String
  nActiveFrameFilesLen as Integer
  activeFrameFiles(any) as UShort
end type

' note: all the fields are 0-initialized by default, so no need to initialize them manually
dim shared g_settingsCache as SMARTMATH_SETTINGS_CACHE

private sub ResetSettingsCacheReadState()
  g_settingsCache.hasDecimals = FALSE
  g_settingsCache.hasColor = FALSE
  g_settingsCache.hasThousandsSeparator = FALSE
  g_settingsCache.hasComplexNumbers = FALSE
  g_settingsCache.hasShowErrors = FALSE
  g_settingsCache.hasSyntaxHighlight = FALSE
  g_settingsCache.hasLogParsedLines = FALSE
  g_settingsCache.hasDecimalSeparator = FALSE
  g_settingsCache.hasThousandsSeparatorChar = FALSE
  g_settingsCache.hasArrayOutputSeparator = FALSE
end sub

private sub CacheSetInt(byref hasValue as Boolean, byref cacheValue as Integer, byval value as Integer)
  hasValue = TRUE
  cacheValue = value
end sub

private sub CacheSetDword(byref hasValue as Boolean, byref cacheValue as DWORD, byval value as DWORD)
  hasValue = TRUE
  cacheValue = value
end sub

private sub CacheSetBool(byref hasValue as Boolean, byref cacheValue as Boolean, byval value as Boolean)
  hasValue = TRUE
  cacheValue = value
end sub

private sub CacheSetString(byref hasValue as Boolean, byref cacheValue as String, byval value as String)
  hasValue = TRUE
  cacheValue = value
end sub

private sub CacheSetActiveFrameFiles(wszActiveFrameFiles() as UShort, byval nLen as Integer)
  erase g_settingsCache.activeFrameFiles
  g_settingsCache.nActiveFrameFilesLen = 0

  if nLen <= 0 then exit sub

  redim g_settingsCache.activeFrameFiles(0 to nLen)
  for i as Integer = 0 to nLen - 1
    g_settingsCache.activeFrameFiles(i) = wszActiveFrameFiles(i)
  next i
  g_settingsCache.activeFrameFiles(nLen) = 0
  g_settingsCache.nActiveFrameFilesLen = nLen
end sub

private function ActiveFrameFilesSegmentCount(buf() as UShort, byval nLen as Integer) as Integer
  if nLen <= 0 then return 0

  dim nSegments as Integer = 1
  for i as Integer = 0 to nLen - 1
    if buf(i) = SMARTMATH_ACTIVE_FRAME_FILE_SEPARATOR then nSegments += 1
  next i

  return nSegments
end function

private function ActiveFrameFileSegmentHash(buf() as UShort, byval nStart as Integer, byval nLen as Integer) as UInteger
  dim h as UInteger = &h811C9DC5

  for i as Integer = 0 to nLen - 1
    h = h xor cast(UInteger, buf(nStart + i))
    h *= &h01000193
  next i

  return h
end function

private function ActiveFrameFileSegmentsEqual( _
  lhs() as UShort, _
  byval lhsStart as Integer, _
  rhs() as UShort, _
  byval rhsStart as Integer, _
  byval nLen as Integer _
) as BOOL
  for i as Integer = 0 to nLen - 1
    if lhs(lhsStart + i) <> rhs(rhsStart + i) then return FALSE
  next i

  return TRUE
end function

private function CacheMatchesActiveFrameFiles(wszActiveFrameFiles() as UShort, byval nLen as Integer) as BOOL
  if nLen <> g_settingsCache.nActiveFrameFilesLen then return FALSE
  if nLen <= 0 then return TRUE

  dim bExactMatch as BOOL = TRUE
  for i as Integer = 0 to nLen - 1
    if g_settingsCache.activeFrameFiles(i) <> wszActiveFrameFiles(i) then
      bExactMatch = FALSE
      exit for
    end if
  next i
  if bExactMatch then return TRUE

  dim nCachedSegments as Integer = ActiveFrameFilesSegmentCount(g_settingsCache.activeFrameFiles(), g_settingsCache.nActiveFrameFilesLen)
  dim nInputSegments as Integer = ActiveFrameFilesSegmentCount(wszActiveFrameFiles(), nLen)
  if nInputSegments <> nCachedSegments then return FALSE

  redim cachedStarts(0 to nCachedSegments - 1) as Integer
  redim cachedLens(0 to nCachedSegments - 1) as Integer
  redim cachedHashes(0 to nCachedSegments - 1) as UInteger
  redim cachedMatched(0 to nCachedSegments - 1) as BOOL

  dim nSegmentIndex as Integer = 0
  dim nSegmentStart as Integer = 0
  for i as Integer = 0 to g_settingsCache.nActiveFrameFilesLen
    if (i = g_settingsCache.nActiveFrameFilesLen) orelse (g_settingsCache.activeFrameFiles(i) = SMARTMATH_ACTIVE_FRAME_FILE_SEPARATOR) then
      cachedStarts(nSegmentIndex) = nSegmentStart
      cachedLens(nSegmentIndex) = i - nSegmentStart
      cachedHashes(nSegmentIndex) = ActiveFrameFileSegmentHash(g_settingsCache.activeFrameFiles(), nSegmentStart, cachedLens(nSegmentIndex))
      cachedMatched(nSegmentIndex) = FALSE
      nSegmentIndex += 1
      nSegmentStart = i + 1
    end if
  next i

  nSegmentStart = 0
  for i as Integer = 0 to nLen
    if (i = nLen) orelse (wszActiveFrameFiles(i) = SMARTMATH_ACTIVE_FRAME_FILE_SEPARATOR) then
      dim nInputSegmentLen as Integer = i - nSegmentStart
      dim nInputSegmentHash as UInteger = ActiveFrameFileSegmentHash(wszActiveFrameFiles(), nSegmentStart, nInputSegmentLen)
      dim bFound as BOOL = FALSE

      for j as Integer = 0 to nCachedSegments - 1
        if cachedMatched(j) = FALSE _
           andalso cachedLens(j) = nInputSegmentLen _
           andalso cachedHashes(j) = nInputSegmentHash _
           andalso ActiveFrameFileSegmentsEqual(wszActiveFrameFiles(), nSegmentStart, g_settingsCache.activeFrameFiles(), cachedStarts(j), nInputSegmentLen) then
          cachedMatched(j) = TRUE
          bFound = TRUE
          exit for
        end if
      next j

      if bFound = FALSE then return FALSE
      nSegmentStart = i + 1
    end if
  next i

  return TRUE
end function

private sub EnsureSettingsCacheInitialized()
  if not g_settingsCache.isInitialized then
    ResetSettingsCacheReadState()
  end if
end sub

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
  dim n as Integer = CInt(SendMessage(g_hMainWnd, AKD_OPTIONW, cast(WPARAM, hOptions), cast(LPARAM, @poW)))
  ' OutputDebugString("[SmartMath] readStringW: optionName=" & optionName & ", n=" & n & ", outValue=" & outValue)
  ' PO_STRING: n is the number of bytes copied including the wide trailing L'\0' (2 bytes).
  if n < 2 then
    return 0
  end if
  return n - 2
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

'' Integer options are stored as strings. No validation here — apply limits at each call site.
private function readIntW( _
  byval hOptions as HANDLE, _
  byref optionName as WString, _
  byref outValue as Integer _
) as Integer
  dim sBuf as WString * SMARTMATH_OPT_STR_MAX_CHARS
  sBuf = WStr("")
  dim nBytes as Integer = readStringW(hOptions, optionName, sBuf, SMARTMATH_OPT_STR_MAX_CHARS)
  if nBytes <= 0 then return 0
  outValue = CInt(Val(Str(sBuf)))
  return nBytes
end function

private sub writeIntW( _
  byval hOptions as HANDLE, _
  byref optionName as WString, _
  byval value as Integer _
)
  dim sBuf as WString * SMARTMATH_OPT_STR_MAX_CHARS
  sBuf = WStr(Str(value))
  writeStringW(hOptions, optionName, sBuf)
end sub

private sub LoadIniSingleCharString( _
  byval hOptions as HANDLE, _
  byref optionName as WString, _
  byref defaultPlain as String, _
  byref target as String, _
  byref hasFlag as Boolean, _
  byref cacheStr as String _
)
  dim sLocal as WString * SMARTMATH_OPT_STR_MAX_CHARS
  sLocal = WStr(defaultPlain)
  if readStringW(hOptions, optionName, sLocal, SMARTMATH_OPT_STR_MAX_CHARS) > 0 then
    target = Left(sLocal, 1)
    CacheSetString(hasFlag, cacheStr, target)
  end if
end sub

sub LoadSettings()
  ' default values before reading the options
  storedDecimalPlaces = -1
  storedResultColor = &H008000 ' Green
  storedUseThousandsSep = FALSE
  storedSupportComplexNumbers = FALSE
  storedShowErrors = TRUE
  storedSyntaxHighlight = TRUE
  storedLogParsedLines = FALSE
  storedDecimalSep = SMARTMATH_DECIMAL_SEPARATOR_DEFAULT
  storedThousandsSep = SMARTMATH_THOUSANDS_SEPARATOR_DEFAULT
  storedArrayOutputSep = SMARTMATH_ARRAY_OUTPUT_SEPARATOR_DEFAULT

  EnsureSettingsCacheInitialized()
  ResetSettingsCacheReadState()
  ' Intentionally keep the has-value flags in the cache as FALSE when options can't be read,
  ' so the first SaveSettings writes current values.

  if g_hMainWnd = 0 then exit sub ' nothing to do

  dim hOptions as HANDLE = cast(HANDLE, SendMessage(g_hMainWnd, AKD_BEGINOPTIONSW, POB_READ, cast(LPARAM, strptr(SMARTMATH_OPTIONS_PLUGIN_NAME))))
  if hOptions = 0 then exit sub ' can not read options

  dim iVal as Integer

  if readIntW(hOptions, SMARTMATH_OPT_DECIMALS, iVal) > 0 then
    if (iVal = -1) orelse (iVal >= 0 andalso iVal <= SMARTMATH_DECIMALS_MAX) then
      storedDecimalPlaces = iVal
      CacheSetInt(g_settingsCache.hasDecimals, g_settingsCache.nDecimals, storedDecimalPlaces)
    end if
  end if

  if readIntW(hOptions, SMARTMATH_OPT_COLOR, iVal) > 0 then
    if iVal >= 0 andalso iVal <= &HFFFFFF then
      storedResultColor = cast(COLORREF, culng(iVal))
      CacheSetDword(g_settingsCache.hasColor, g_settingsCache.crResultColor, storedResultColor)
    end if
  end if

  if readIntW(hOptions, SMARTMATH_OPT_THOUSANDS_SEPARATOR, iVal) > 0 then
    if iVal >= 0 then
      storedUseThousandsSep = (iVal <> 0)
      CacheSetBool(g_settingsCache.hasThousandsSeparator, g_settingsCache.bUseThousandsSeparator, storedUseThousandsSep)
    end if
  end if

  if readIntW(hOptions, SMARTMATH_OPT_COMPLEX_NUMBERS, iVal) > 0 then
    if iVal >= 0 then
      storedSupportComplexNumbers = (iVal <> 0)
      CacheSetBool(g_settingsCache.hasComplexNumbers, g_settingsCache.bSupportComplexNumbers, storedSupportComplexNumbers)
    end if
  end if

  if readIntW(hOptions, SMARTMATH_OPT_SHOW_ERRORS, iVal) > 0 then
    if iVal >= 0 then
      storedShowErrors = (iVal <> 0)
      CacheSetBool(g_settingsCache.hasShowErrors, g_settingsCache.bShowErrors, storedShowErrors)
    end if
  end if

  if readIntW(hOptions, SMARTMATH_OPT_SYNTAX_HIGHLIGHT, iVal) > 0 then
    if iVal >= 0 then
      storedSyntaxHighlight = (iVal <> 0)
      CacheSetBool(g_settingsCache.hasSyntaxHighlight, g_settingsCache.bSyntaxHighlight, storedSyntaxHighlight)
    end if
  end if

  if readIntW(hOptions, SMARTMATH_OPT_LOG_PARSED_LINES, iVal) > 0 then
    if iVal >= 0 then
      storedLogParsedLines = (iVal <> 0)
      CacheSetBool(g_settingsCache.hasLogParsedLines, g_settingsCache.bLogParsedLines, storedLogParsedLines)
    end if
  end if

  LoadIniSingleCharString(hOptions, SMARTMATH_OPT_DECIMAL_SEPARATOR_CHAR, SMARTMATH_DECIMAL_SEPARATOR_DEFAULT, _
    storedDecimalSep, g_settingsCache.hasDecimalSeparator, g_settingsCache.sDecimalSeparator)
  LoadIniSingleCharString(hOptions, SMARTMATH_OPT_THOUSANDS_SEPARATOR_CHAR, SMARTMATH_THOUSANDS_SEPARATOR_DEFAULT, _
    storedThousandsSep, g_settingsCache.hasThousandsSeparatorChar, g_settingsCache.sThousandsSeparator)
  LoadIniSingleCharString(hOptions, SMARTMATH_OPT_ARRAY_OUTPUT_SEPARATOR_CHAR, SMARTMATH_ARRAY_OUTPUT_SEPARATOR_DEFAULT, _
    storedArrayOutputSep, g_settingsCache.hasArrayOutputSeparator, g_settingsCache.sArrayOutputSeparator)

  SendMessage(g_hMainWnd, AKD_ENDOPTIONS, cast(WPARAM, hOptions), 0) ' be sure to close the options handle

  g_settingsCache.isInitialized = TRUE
end sub

sub SaveSettings()
  EnsureSettingsCacheInitialized()

  if g_hMainWnd = 0 then exit sub ' nothing to do

  dim shouldSaveDecimals as Boolean = (not g_settingsCache.hasDecimals) orElse (g_settingsCache.nDecimals <> storedDecimalPlaces)
  dim shouldSaveColor as Boolean = (not g_settingsCache.hasColor) orElse (g_settingsCache.crResultColor <> storedResultColor)
  dim shouldSaveThousandsFlag as Boolean = (not g_settingsCache.hasThousandsSeparator) orElse (g_settingsCache.bUseThousandsSeparator <> storedUseThousandsSep)
  dim shouldSaveComplexNumbersFlag as Boolean = (not g_settingsCache.hasComplexNumbers) orElse (g_settingsCache.bSupportComplexNumbers <> storedSupportComplexNumbers)
  dim shouldSaveShowErrorsFlag as Boolean = (not g_settingsCache.hasShowErrors) orElse (g_settingsCache.bShowErrors <> storedShowErrors)
  dim shouldSaveSyntaxHighlightFlag as Boolean = (not g_settingsCache.hasSyntaxHighlight) orElse (g_settingsCache.bSyntaxHighlight <> storedSyntaxHighlight)
  dim shouldSaveLogFlag as Boolean = (not g_settingsCache.hasLogParsedLines) orElse (g_settingsCache.bLogParsedLines <> storedLogParsedLines)
  dim shouldSaveDecimalSep as Boolean = (not g_settingsCache.hasDecimalSeparator) orElse (g_settingsCache.sDecimalSeparator <> storedDecimalSep)
  dim shouldSaveThousandsSep as Boolean = (not g_settingsCache.hasThousandsSeparatorChar) orElse (g_settingsCache.sThousandsSeparator <> storedThousandsSep)
  dim shouldSaveArraySep as Boolean = (not g_settingsCache.hasArrayOutputSeparator) orElse (g_settingsCache.sArrayOutputSeparator <> storedArrayOutputSep)

  if (not shouldSaveDecimals) _
     andalso (not shouldSaveColor) _
     andalso (not shouldSaveThousandsFlag) _
     andalso (not shouldSaveComplexNumbersFlag) _
     andalso (not shouldSaveShowErrorsFlag) _
     andalso (not shouldSaveSyntaxHighlightFlag) _
     andalso (not shouldSaveLogFlag) _
     andalso (not shouldSaveDecimalSep) _
     andalso (not shouldSaveThousandsSep) _
     andalso (not shouldSaveArraySep) then
    exit sub ' nothing to save
  end if

  dim hOptions as HANDLE = cast(HANDLE, SendMessage(g_hMainWnd, AKD_BEGINOPTIONSW, POB_SAVE, cast(LPARAM, strptr(SMARTMATH_OPTIONS_PLUGIN_NAME))))
  if hOptions = 0 then exit sub ' can not save options
  dim sVal as WString * SMARTMATH_OPT_STR_MAX_CHARS

  if shouldSaveDecimals then
    writeIntW(hOptions, SMARTMATH_OPT_DECIMALS, storedDecimalPlaces)
    CacheSetInt(g_settingsCache.hasDecimals, g_settingsCache.nDecimals, storedDecimalPlaces)
  end if

  if shouldSaveColor then
    writeIntW(hOptions, SMARTMATH_OPT_COLOR, CInt(clngint(culng(storedResultColor))))
    CacheSetDword(g_settingsCache.hasColor, g_settingsCache.crResultColor, storedResultColor)
  end if

  if shouldSaveThousandsFlag then
    writeIntW(hOptions, SMARTMATH_OPT_THOUSANDS_SEPARATOR, IIf(storedUseThousandsSep, 1, 0))
    CacheSetBool(g_settingsCache.hasThousandsSeparator, g_settingsCache.bUseThousandsSeparator, storedUseThousandsSep)
  end if

  if shouldSaveComplexNumbersFlag then
    writeIntW(hOptions, SMARTMATH_OPT_COMPLEX_NUMBERS, IIf(storedSupportComplexNumbers, 1, 0))
    CacheSetBool(g_settingsCache.hasComplexNumbers, g_settingsCache.bSupportComplexNumbers, storedSupportComplexNumbers)
  end if

  if shouldSaveShowErrorsFlag then
    writeIntW(hOptions, SMARTMATH_OPT_SHOW_ERRORS, IIf(storedShowErrors, 1, 0))
    CacheSetBool(g_settingsCache.hasShowErrors, g_settingsCache.bShowErrors, storedShowErrors)
  end if

  if shouldSaveSyntaxHighlightFlag then
    writeIntW(hOptions, SMARTMATH_OPT_SYNTAX_HIGHLIGHT, IIf(storedSyntaxHighlight, 1, 0))
    CacheSetBool(g_settingsCache.hasSyntaxHighlight, g_settingsCache.bSyntaxHighlight, storedSyntaxHighlight)
  end if

  if shouldSaveLogFlag then
    writeIntW(hOptions, SMARTMATH_OPT_LOG_PARSED_LINES, IIf(storedLogParsedLines, 1, 0))
    CacheSetBool(g_settingsCache.hasLogParsedLines, g_settingsCache.bLogParsedLines, storedLogParsedLines)
  end if

  if shouldSaveDecimalSep then
    sVal = WStr(storedDecimalSep)
    writeStringW(hOptions, SMARTMATH_OPT_DECIMAL_SEPARATOR_CHAR, sVal)
    CacheSetString(g_settingsCache.hasDecimalSeparator, g_settingsCache.sDecimalSeparator, storedDecimalSep)
  end if

  if shouldSaveThousandsSep then
    sVal = WStr(storedThousandsSep)
    writeStringW(hOptions, SMARTMATH_OPT_THOUSANDS_SEPARATOR_CHAR, sVal)
    CacheSetString(g_settingsCache.hasThousandsSeparatorChar, g_settingsCache.sThousandsSeparator, storedThousandsSep)
  end if

  if shouldSaveArraySep then
    sVal = WStr(storedArrayOutputSep)
    writeStringW(hOptions, SMARTMATH_OPT_ARRAY_OUTPUT_SEPARATOR_CHAR, sVal)
    CacheSetString(g_settingsCache.hasArrayOutputSeparator, g_settingsCache.sArrayOutputSeparator, storedArrayOutputSep)
  end if

  SendMessage(g_hMainWnd, AKD_ENDOPTIONS, cast(WPARAM, hOptions), 0) ' be sure to close the options handle

  g_settingsCache.isInitialized = TRUE
end sub

function LoadSettings_ActiveFrames(wszActiveFrameFiles() as UShort) as Integer
  erase wszActiveFrameFiles
  CacheSetActiveFrameFiles(wszActiveFrameFiles(), 0)

  if g_hMainWnd = 0 then return 0 ' nothing to do

  dim hOptions as HANDLE = cast(HANDLE, SendMessage(g_hMainWnd, AKD_BEGINOPTIONSW, POB_READ, cast(LPARAM, strptr(SMARTMATH_OPTIONS_PLUGIN_NAME))))
  if hOptions = 0 then return 0 ' can not read options

  dim poW as PLUGINOPTIONW
  poW.pOptionName = strptr(SMARTMATH_ACTIVE_FRAMES_OPTION_NAME)
  poW.dwType = PO_BINARY
  poW.lpData = 0
  poW.dwData = 0

  dim nBytesRequired as Integer = CInt(SendMessage(g_hMainWnd, AKD_OPTIONW, cast(WPARAM, hOptions), cast(LPARAM, @poW)))
  if nBytesRequired <= 0 then
    SendMessage(g_hMainWnd, AKD_ENDOPTIONS, cast(WPARAM, hOptions), 0)
    return 0
  end if

  dim nCharsCapacity as Integer = (nBytesRequired + 1) \ 2
  redim wszActiveFrameFiles(0 to nCharsCapacity)

  poW.lpData = cast(UByte ptr, @wszActiveFrameFiles(0))
  poW.dwData = nBytesRequired

  dim nBytesRead as Integer = CInt(SendMessage(g_hMainWnd, AKD_OPTIONW, cast(WPARAM, hOptions), cast(LPARAM, @poW)))
  SendMessage(g_hMainWnd, AKD_ENDOPTIONS, cast(WPARAM, hOptions), 0)

  if nBytesRead <= 0 then
    erase wszActiveFrameFiles
    return 0
  end if

  dim nCharsRead as Integer = nBytesRead \ 2
  if nCharsRead > nCharsCapacity then nCharsRead = nCharsCapacity
  wszActiveFrameFiles(nCharsRead) = 0
  CacheSetActiveFrameFiles(wszActiveFrameFiles(), nCharsRead)

  return nCharsRead
end function

sub SaveSettings_ActiveFrames(wszActiveFrameFiles() as UShort, byval nLen as Integer)
  if g_hMainWnd = 0 then exit sub ' nothing to do
  if CacheMatchesActiveFrameFiles(wszActiveFrameFiles(), nLen) then exit sub

  dim hOptions as HANDLE = cast(HANDLE, SendMessage(g_hMainWnd, AKD_BEGINOPTIONSW, POB_SAVE, cast(LPARAM, strptr(SMARTMATH_OPTIONS_PLUGIN_NAME))))
  if hOptions = 0 then exit sub ' can not save options

  dim poW as PLUGINOPTIONW
  poW.pOptionName = strptr(SMARTMATH_ACTIVE_FRAMES_OPTION_NAME)
  poW.dwType = PO_BINARY
  if nLen > 0 then
    poW.lpData = cast(UByte ptr, @wszActiveFrameFiles(0))
  else
    poW.lpData = 0
  end if
  poW.dwData = (nLen) * 2
  SendMessage(g_hMainWnd, AKD_OPTIONW, cast(WPARAM, hOptions), cast(LPARAM, @poW))

  SendMessage(g_hMainWnd, AKD_ENDOPTIONS, cast(WPARAM, hOptions), 0)
  CacheSetActiveFrameFiles(wszActiveFrameFiles(), nLen)
end sub
