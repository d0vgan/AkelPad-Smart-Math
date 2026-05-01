#include once "SmartMath_Globals.bi"

' --- Shared global variables definitions ---
dim shared lpEditProcData as WNDPROCDATA ptr = 0
dim shared lpMainProcData as WNDPROCDATA ptr = 0
dim shared lpFrameProcData as WNDPROCDATA ptr = 0
dim shared bSmartMathActive as BOOL = FALSE
dim shared g_bOldRichEdit as BOOL = FALSE

dim shared rcOldMargin as RECT
dim shared nOldFirstLine as Integer = -1
dim shared nOldCaretLine as Integer = -1
dim shared nLastNavSelStart as Integer = -1
dim shared nLastNavSelEnd as Integer = -1
dim shared nOldMargin as Integer = 0
dim shared dwOldAkelOptions as DWORD = 0

dim shared g_nDecimals as Integer = -1
dim shared g_crResultColor as COLORREF = &H008000
dim shared g_bUseThousandsSeparator as BOOL = FALSE
dim shared g_bLogParsedLines as BOOL = FALSE
dim shared g_sDecimalSeparator as String
dim shared g_sThousandsSeparator as String
dim shared g_sArrayOutputSeparator as String
dim shared hSmartMathMenu as HMENU = 0
dim shared hSubMenuDecimals as HMENU = 0
dim shared hSubMenuColor as HMENU = 0
dim shared g_hMainWnd as HWND = 0
dim shared g_hMainMenu as HMENU = 0
dim shared g_hWndEdit as HWND = 0
dim shared g_bShuttingDown as BOOL = FALSE
dim shared g_cacheLineCount as Integer = -1
dim shared g_cacheReady as BOOL = FALSE
redim shared g_cachedLineText(0 to 0) as String
redim shared g_cachedRenderText(0 to 0) as String

' -----------------------------------------------------------------------------
'  Debug logging
' -----------------------------------------------------------------------------
sub LogInfo(byref sMsg as String)
  dim sOut as String = "[SmartMath] " & sMsg
  OutputDebugString(strptr(sOut))
end sub

private sub InvalidateRenderCache()
  g_cacheReady = FALSE
  g_cacheLineCount = -1
end sub

private function IsVolatilePureExpressionLine(byref sLine as String) as BOOL
  dim t as String = lcase(trim(sLine))
  if len(t) = 0 then return FALSE
  if instr(t, "=") > 0 then return FALSE
  if instr(t, ";") > 0 then return FALSE
  if instr(t, "rand(") > 0 then return TRUE
  if instr(t, "random(") > 0 then return TRUE
  return FALSE
end function

private function IsLikelyCodeLine(byref sLine as String) as BOOL
  dim t as String = lcase(trim(sLine))
  if len(t) = 0 then return FALSE
  if left(t, 1) = "'" orelse left(t, 1) = "#" orelse left(t, 2) = "//" then return TRUE
  if left(t, 8) = "#include" then return TRUE
  if left(t, 4) = "dim " orelse left(t, 6) = "const " orelse left(t, 5) = "type " _
     orelse left(t, 5) = "enum " orelse left(t, 4) = "sub " orelse left(t, 9) = "function " _
     orelse left(t, 8) = "private " orelse left(t, 7) = "public " orelse left(t, 8) = "declare " _
     orelse left(t, 7) = "extern " orelse left(t, 4) = "end " orelse left(t, 7) = "return " then
    return TRUE
  end if

  ' Defensive skip for source-like call chains that are not typical math input.
  if instr(t, "_") > 0 andalso instr(t, "(") > 0 andalso instr(t, ")") > 0 _
     andalso instr(t, "=") = 0 andalso instr(t, ";") = 0 andalso instr(t, ",") = 0 then
    dim hasDigit as BOOL = FALSE
    for i as Integer = 1 to len(t)
      dim ch as String = mid(t, i, 1)
      if ch >= "0" andalso ch <= "9" then
        hasDigit = TRUE
        exit for
      end if
    next i
    if hasDigit = FALSE then return TRUE
  end if
  return FALSE
end function

private sub RestoreAnsFromCachedRender(byref sRender as String)
  if left(sRender, Len(SMARTMATH_RESULT_PREFIX)) <> SMARTMATH_RESULT_PREFIX then exit sub
  dim sExpr as String = mid(sRender, Len(SMARTMATH_RESULT_PREFIX) + 1)
  if len(trim(sExpr)) = 0 then exit sub

  dim dResult as Double
  dim sResult as String
  dim bIsArray as Boolean
  Parser_TryEvaluateEx(sExpr, dResult, sResult, bIsArray)
end sub

' FIX: Use a plain Win32 WNDPROC pointer instead of AKD_SETMAINPROC / WNDPROCDATA.
dim shared g_pfnOldMainProc as WNDPROC = 0
dim shared g_wszIniPath as WString * 260
dim shared g_bSmartMathDocActive as BOOL = FALSE
dim shared g_lastDocModeFrame as FRAMEDATA ptr = 0
dim shared g_lastDocModeEdit as HWND = 0
dim shared SMARTMATH_CODER_HIGHLIGHT_FUNC as WString * 32 = WStr("Coder::HighLight")
dim shared SMARTMATH_CODER_SETTINGS_FUNC as WString * 32 = WStr("Coder::Settings")
dim shared SMARTMATH_CODER_ALIAS as WString * 32 = WStr(".smartmath")

const DLLA_CODER_SETALIAS = 6

type DLLECCODERSETTINGS_SETALIAS
  dwStructSize as UINT_PTR
  nAction as INT_PTR
  pszAlias as const UByte ptr
end type

#if sizeof(DLLECCODERSETTINGS_SETALIAS) <> (sizeof(UINT_PTR) + sizeof(INT_PTR) + sizeof(any ptr))
  #error "DLLECCODERSETTINGS_SETALIAS layout mismatch"
#endif

private sub CallPluginFuncW(byval pFunctionName as WString ptr, byval params as any ptr)
  dim pcsW as PLUGINCALLSENDW
  pcsW.pFunction = pFunctionName
  pcsW.lParam = cast(LPARAM, params)
  pcsW.dwSupport = 0
  pcsW.nResult = 0
  SendMessageW(g_hMainWnd, AKD_DLLCALLW, 0, cast(LPARAM, @pcsW))
end sub

private sub SetCoderAliasW(byval pAliasName as WString ptr)
  dim stParams as DLLECCODERSETTINGS_SETALIAS
  stParams.dwStructSize = sizeof(DLLECCODERSETTINGS_SETALIAS)
  stParams.nAction = DLLA_CODER_SETALIAS
  stParams.pszAlias = cast(UByte ptr, pAliasName)
  CallPluginFuncW(strptr(SMARTMATH_CODER_SETTINGS_FUNC), @stParams)
end sub

private sub TryApplySmartMathCoderTheme()
  ' "Coder::HighLight" function must be running to apply the SmartMath coder theme.
  dim pf as PLUGINFUNCTION ptr = cast(PLUGINFUNCTION ptr, SendMessageW(g_hMainWnd, AKD_DLLFINDW, cast(WPARAM, strptr(SMARTMATH_CODER_HIGHLIGHT_FUNC)), 0))
  ' LogInfo("TryApplySmartMathCoderTheme: pf=" & pf & ", bRunning=" & pf->bRunning)
  if pf = 0 orelse pf->bRunning = FALSE then exit sub

  ' LogInfo("TryApplySmartMathCoderTheme: calling SetCoderAliasW")

  ' Set the SmartMath coder alias.
  SetCoderAliasW(strptr(SMARTMATH_CODER_ALIAS))
end sub

declare function GetLineText(byval hWnd as HWND, byval lineIdx as Integer, byval lineLen as Integer) as String

private sub SetSmartMathDocActiveState(byval hWndEdit as HWND, byval bActive as BOOL, byval bApplyTheme as BOOL = TRUE)
  if (hWndEdit = 0) orelse (IsWindow(hWndEdit) = FALSE) then
    g_hWndEdit = 0
    g_bSmartMathDocActive = FALSE
    exit sub
  end if

  g_hWndEdit = hWndEdit
  g_bSmartMathDocActive = bActive
  InvalidateRenderCache()

  if bActive then
    if bApplyTheme then
      TryApplySmartMathCoderTheme()
    end if
    dim bVisible as BOOL
    UpdateMarginAndState(hWndEdit, bVisible)
    InvalidateRect(hWndEdit, 0, TRUE)
  else
    SendMessage(hWndEdit, EM_SETMARGINS, EC_RIGHTMARGIN, 0)
    nOldMargin = 0
    rcOldMargin.left = 0 : rcOldMargin.right = 0
    rcOldMargin.top = 0  : rcOldMargin.bottom = 0
    nOldFirstLine = -1
    nOldCaretLine = -1
    nLastNavSelStart = -1
    nLastNavSelEnd = -1
    InvalidateRect(hWndEdit, 0, TRUE)
  end if
end sub

private function GetWndEdit(byval hMainWnd as HWND) as HWND
  dim ei as EDITINFO
  ei.hWndEdit = 0
  SendMessage(hMainWnd, AKD_GETEDITINFO, 0, cast(LPARAM, @ei))
  return ei.hWndEdit
end function

private function IsSpaceOrTabAfterHash(byval ch as String) as BOOL
  if Len(ch) <> 1 then return FALSE
  select case Asc(ch)
    case 9, 32  '' HT, space
      return TRUE
    case else
      return FALSE
  end select
end function

'' First line: '#' then only spaces/tabs, then exactly SmartMath | smartmath | SMARTMATH; rest of line ignored.
private function FirstLineHasSmartMathMarker(byref sLine0 as String) as BOOL
  if Len(sLine0) = 0 then return FALSE
  if Left(sLine0, 1) <> "#" then return FALSE

  dim i as Integer = 2
  while i <= Len(sLine0)
    if IsSpaceOrTabAfterHash(Mid(sLine0, i, 1)) = FALSE then exit while
    i += 1
  wend

  dim rest as String = Mid(sLine0, i)
  const MARKER_LEN as Integer = 9  '' Len("SmartMath") etc.
  if Len(rest) < MARKER_LEN then return FALSE
  dim head as String = Left(rest, MARKER_LEN)
  return (head = "SmartMath") orelse (head = "smartmath") orelse (head = "SMARTMATH")
end function

private function IsSmartMathDocument(byval hWndEdit as HWND) as BOOL
  ' First line: "#" ... optional spaces/tabs ... SmartMath | smartmath | SMARTMATH.
  if hWndEdit = 0 then return FALSE
  if IsWindow(hWndEdit) = FALSE then return FALSE
  dim nLineCount as Integer = SendMessage(hWndEdit, EM_GETLINECOUNT, 0, 0)
  if nLineCount <= 0 then return FALSE
  dim nLineIndex as Integer = SendMessage(hWndEdit, EM_LINEINDEX, 0, 0)
  if nLineIndex < 0 then return FALSE
  dim nLineLen as Integer = SendMessage(hWndEdit, EM_LINELENGTH, nLineIndex, 0)
  if nLineLen <= 0 then return FALSE
  dim sLine0 as String = LTrim(GetLineText(hWndEdit, 0, nLineLen))
  return FirstLineHasSmartMathMarker(sLine0)
end function

private sub RefreshSmartMathDocMode(byval hWndEdit as HWND)
  ' LogInfo("RefreshSmartMathDocMode: entering")

  dim pFrameCurrent as FRAMEDATA ptr = cast(FRAMEDATA ptr, SendMessage(g_hMainWnd, AKD_FRAMEFIND, FWF_CURRENT, 0))
  dim hWndEditCurrent as HWND = hWndEdit

  if (pFrameCurrent = g_lastDocModeFrame) andalso (hWndEditCurrent = g_lastDocModeEdit) then
    exit sub
  end if

  g_lastDocModeFrame = pFrameCurrent
  g_lastDocModeEdit = hWndEditCurrent

  if hWndEditCurrent = 0 then
    g_bSmartMathDocActive = FALSE
    g_hWndEdit = 0
    exit sub
  end if
  if IsWindow(hWndEditCurrent) = FALSE then
    g_bSmartMathDocActive = FALSE
    g_hWndEdit = 0
    exit sub
  end if

  dim bNewActive as BOOL = IsSmartMathDocument(hWndEditCurrent)
  ' LogInfo("RefreshSmartMathDocMode: bNewActive=" & bNewActive)
  SetSmartMathDocActiveState(hWndEditCurrent, bNewActive, TRUE)
end sub

private sub TryRefreshSmartMathDocMarker(byval pHdr as AENMHDR ptr)
  dim hEditFromNotify as HWND = pHdr->hwndFrom
  if (hEditFromNotify = 0) orelse (IsWindow(hEditFromNotify) = FALSE) then exit sub

  dim bNowSmartMath as BOOL = IsSmartMathDocument(hEditFromNotify)
  ' LogInfo("TryRefreshSmartMathDocMarker: bNowSmartMath=" & bNowSmartMath & ", g_bSmartMathDocActive=" & g_bSmartMathDocActive)

  if (g_bSmartMathDocActive = FALSE) andalso bNowSmartMath then
    SetSmartMathDocActiveState(hEditFromNotify, TRUE, TRUE)
  elseif g_bSmartMathDocActive andalso bNowSmartMath then
    g_hWndEdit = hEditFromNotify
    ' TryApplySmartMathCoderTheme()
  elseif g_bSmartMathDocActive andalso (bNowSmartMath = FALSE) then
    SetSmartMathDocActiveState(hEditFromNotify, FALSE, FALSE)
  end if
end sub

private sub CheckEditNotifications(byval hWnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM)
  if (uMsg <> WM_NOTIFY) orelse (wParam <> ID_EDIT) orelse (lParam = 0) orelse (g_bShuttingDown) then exit sub

  dim pHdr as AENMHDR ptr = cast(AENMHDR ptr, lParam)

  if pHdr->code = AEN_TEXTCHANGED then
    dim pChange as AENTEXTCHANGE ptr = cast(AENTEXTCHANGE ptr, lParam)
    dim nChangedLine as Integer = pChange->ciCaret.nLine
    if nChangedLine >= 0 then
      nOldCaretLine = nChangedLine
    end if
    ' LogInfo("AEN_TEXTCHANGED: ciCaret.nLine=" & nChangedLine)
    if nChangedLine = 0 then
      TryRefreshSmartMathDocMarker(pHdr)
    end if
    exit sub
  end if

  if pHdr->code = AEN_TEXTINSERTEND then
    dim pIns as AENTEXTINSERT ptr = cast(AENTEXTINSERT ptr, lParam)
    ' LogInfo("AEN_TEXTINSERTEND: ciMin.nLine=" & pIns->crAkelRange.ciMin.nLine)
    if pIns->crAkelRange.ciMin.nLine = 0 then
      TryRefreshSmartMathDocMarker(pHdr)
    end if
    exit sub
  end if
end sub

' On plugin activation: ensure the active document starts with "# SmartMath" marker line.
private sub EnsureSmartMathFirstLineOnActivate(byval hWndEdit as HWND)
  if (hWndEdit = 0) orelse (IsWindow(hWndEdit) = FALSE) then exit sub
  if IsSmartMathDocument(hWndEdit) then exit sub

  dim selStart as Integer = 0
  dim selEnd as Integer = 0
  SendMessage(hWndEdit, EM_GETSEL, cast(WPARAM, @selStart), cast(LPARAM, @selEnd))

  dim nCaretLine as Integer = SendMessage(hWndEdit, EM_EXLINEFROMCHAR, 0, -1)
  if nCaretLine < 0 then nCaretLine = 0

  dim nLineStart as Integer = SendMessage(hWndEdit, EM_LINEINDEX, nCaretLine, 0)
  if nLineStart < 0 then nLineStart = 0

  dim colOffset as Integer = selStart - nLineStart
  if colOffset < 0 then colOffset = 0

  dim nLineCount as Integer = SendMessage(hWndEdit, EM_GETLINECOUNT, 0, 0)
  dim idxFirst as Integer = SendMessage(hWndEdit, EM_LINEINDEX, 0, 0)
  dim lenFirstLine as Integer = 0
  if idxFirst >= 0 then
    lenFirstLine = SendMessage(hWndEdit, EM_LINELENGTH, idxFirst, 0)
  end if
  dim bEmpty as BOOL = ((nLineCount <= 1) andalso (lenFirstLine = 0))

  dim insertLen as Integer = 0

  SendMessage(hWndEdit, EM_SETSEL, 0, 0)

  if IsWindowUnicode(hWndEdit) then
    dim ins as WString * 64 = WStr("# SmartMath") & wchr(13, 10)
    SendMessageW(hWndEdit, EM_REPLACESEL, cast(WPARAM, TRUE), cast(LPARAM, strptr(ins)))
    insertLen = Len(ins)
  else
    dim insA as String = "# SmartMath" & Chr(13) & Chr(10)
    SendMessageA(hWndEdit, EM_REPLACESEL, cast(WPARAM, TRUE), cast(LPARAM, strptr(insA)))
    insertLen = Len(insA)
  end if

  if bEmpty then
    SendMessage(hWndEdit, EM_SETSEL, insertLen, insertLen)
  else
    dim newLine as Integer = nCaretLine + 1
    dim newLineStart as Integer = SendMessage(hWndEdit, EM_LINEINDEX, newLine, 0)
    if newLineStart < 0 then newLineStart = insertLen
    dim newLineLen as Integer = SendMessage(hWndEdit, EM_LINELENGTH, newLineStart, 0)
    dim colUse as Integer = colOffset
    if colUse > newLineLen then colUse = newLineLen
    dim newPos as Integer = newLineStart + colUse
    SendMessage(hWndEdit, EM_SETSEL, newPos, newPos)
  end if

  SendMessage(hWndEdit, EM_SCROLLCARET, 0, 0)
end sub

' -----------------------------------------------------------------------------
'  Text safety (universal ANSI/Unicode support for AkelPad)
' -----------------------------------------------------------------------------
function GetLineText(byval hWnd as HWND, byval lineIdx as Integer, byval lineLen as Integer) as String
  if lineLen <= 0 then return ""
  const MAX_EM_GETLINE_CHARS as Integer = 32760
  dim safeLen as Integer = lineLen
  if safeLen > MAX_EM_GETLINE_CHARS then safeLen = MAX_EM_GETLINE_CHARS
  dim as String sRet = ""

  if IsWindowUnicode(hWnd) then
    dim wBuf as WString ptr = cast(WString ptr, callocate((safeLen + 2) * 2))
    cast(Short ptr, wBuf)[0] = safeLen
    dim lenRead as Integer = SendMessageW(hWnd, EM_GETLINE, lineIdx, cast(LPARAM, wBuf))
    if lenRead > 0 then sRet = Left(*wBuf, lenRead)
    deallocate(wBuf)
  else
    dim zBuf as ZString ptr = cast(ZString ptr, callocate(safeLen + 2))
    cast(Short ptr, zBuf)[0] = safeLen
    dim lenRead as Integer = SendMessageA(hWnd, EM_GETLINE, lineIdx, cast(LPARAM, zBuf))
    if lenRead > 0 then sRet = Left(*zBuf, lenRead)
    deallocate(zBuf)
  end if

  return sRet
end function

private sub BuildRenderedResultText(byref sLine as String, byref sRes as String, byref bIsError as Boolean, byval lineIdx as Integer = -1)
  sRes = ""
  bIsError = FALSE
  if IsLikelyCodeLine(sLine) then exit sub

  if g_bLogParsedLines then
    const MAX_LOG_LINE_LEN as Integer = 220
    dim logLine as String = sLine
    if len(logLine) > MAX_LOG_LINE_LEN then
      logLine = left(logLine, MAX_LOG_LINE_LEN) & " ...[truncated]"
    end if
    if lineIdx >= 0 then
      LogInfo("parse-line begin [" & ltrim(str(lineIdx)) & "]: " & logLine)
    else
      LogInfo("parse-line begin: " & logLine)
    end if
  end if

  dim dResult as Double
  dim sResult as String
  dim bIsArray as Boolean

  if Parser_TryEvaluateEx(sLine, dResult, sResult, bIsArray) then
    dim sTrimResult as String = lcase(trim(sResult))
    dim bPrefixedScalar as Boolean = (left(sTrimResult, 2) = "0x") orelse (left(sTrimResult, 3) = "-0x") _
                                  orelse (left(sTrimResult, 2) = "0b") orelse (left(sTrimResult, 3) = "-0b") _
                                  orelse (left(sTrimResult, 2) = "0o") orelse (left(sTrimResult, 3) = "-0o")
    if lcase(left(trim(sResult), 8)) = "defined " then
      sRes = ""
    elseif bIsArray then
      sRes = FormatArrayResultText(sResult)
    elseif bPrefixedScalar then
      sRes = SMARTMATH_RESULT_PREFIX & sResult
    else
      '' Non-finite: use parser classification but formatter display (NaN/Inf/-Inf).
      dim sNf as String = FormatNonFiniteDisplayFromParserScalar(sResult)
      if Len(sNf) > 0 then
        sRes = SMARTMATH_RESULT_PREFIX & sNf
      else
        sRes = FormatResult(dResult)
      end if
    end if
  else
    dim sErr as String = Parser_GetLastError()
    if len(sErr) > 0 then
      sRes = SMARTMATH_ERROR_PREFIX & sErr
      bIsError = TRUE
    end if
  end if

  if g_bLogParsedLines then
    if lineIdx >= 0 then
      LogInfo("parse-line end [" & ltrim(str(lineIdx)) & "]")
    else
      LogInfo("parse-line end")
    end if
  end if
end sub

private sub EnsureRenderCache(byval hWnd as HWND)
  dim nLineCount as Integer = SendMessage(hWnd, EM_GETLINECOUNT, 0, 0)
  if nLineCount <= 0 then
    g_cacheLineCount = 0
    erase g_cachedLineText
    erase g_cachedRenderText
    g_cacheReady = TRUE
    exit sub
  end if

  dim hasChanges as BOOL = IIf(g_cacheReady = FALSE orelse nLineCount <> g_cacheLineCount, TRUE, FALSE)
  dim firstChanged as Integer = -1
  dim minCount as Integer = IIf(nLineCount < g_cacheLineCount, nLineCount, g_cacheLineCount)

  redim currentLineText(0 to nLineCount - 1) as String
  dim i as Integer
  for i = 0 to nLineCount - 1
    dim nLineIndex as Integer = SendMessage(hWnd, EM_LINEINDEX, i, 0)
    dim nLineLen as Integer = SendMessage(hWnd, EM_LINELENGTH, nLineIndex, 0)
    currentLineText(i) = GetLineText(hWnd, i, nLineLen)
  next i

  if g_cacheReady andalso (nLineCount = g_cacheLineCount) then
    for i = 0 to nLineCount - 1
      if currentLineText(i) <> g_cachedLineText(i) then
        hasChanges = TRUE
        firstChanged = i
        exit for
      end if
    next i
  end if

  if hasChanges = FALSE then exit sub
  if firstChanged < 0 then
    if g_cacheReady = FALSE then
      firstChanged = 0
    else
      firstChanged = minCount
    end if
  end if

  redim oldLineText(0 to 0) as String
  redim oldRenderText(0 to 0) as String
  dim oldCount as Integer = g_cacheLineCount
  if g_cacheReady andalso oldCount > 0 then
    redim oldLineText(0 to oldCount - 1)
    redim oldRenderText(0 to oldCount - 1)
    for i = 0 to oldCount - 1
      oldLineText(i) = g_cachedLineText(i)
      oldRenderText(i) = g_cachedRenderText(i)
    next i
  end if

  redim g_cachedLineText(0 to nLineCount - 1)
  redim g_cachedRenderText(0 to nLineCount - 1)
  for i = 0 to nLineCount - 1
    g_cachedLineText(i) = currentLineText(i)
  next i

  g_cacheLineCount = nLineCount

  Parser_ClearVariables()
  for i = 0 to nLineCount - 1
    dim sRes as String = ""
    dim bIsError as Boolean = FALSE
  BuildRenderedResultText(g_cachedLineText(i), sRes, bIsError, i)

    if (i < firstChanged) andalso g_cacheReady andalso (i < oldCount) andalso (g_cachedLineText(i) = oldLineText(i)) then
      g_cachedRenderText(i) = oldRenderText(i)
      if IsVolatilePureExpressionLine(g_cachedLineText(i)) then
        ' Keep ans chain consistent with frozen rendered output for volatile pure expressions.
        RestoreAnsFromCachedRender(g_cachedRenderText(i))
      end if
    else
      g_cachedRenderText(i) = sRes
    end if
  next i

  g_cacheReady = TRUE
end sub

function BuildLineRenderText(byval hWnd as HWND, byval lineIdx as Integer) as String
  EnsureRenderCache(hWnd)
  if lineIdx < 0 orelse lineIdx >= g_cacheLineCount then return ""
  return g_cachedRenderText(lineIdx)
end function

function BuildResultTextForLine(byval hWnd as HWND, byval targetLine as Integer) as String
  dim nLineCount as Integer = SendMessage(hWnd, EM_GETLINECOUNT, 0, 0)
  if targetLine < 0 orelse targetLine >= nLineCount then return ""
  EnsureRenderCache(hWnd)
  return BuildLineRenderText(hWnd, targetLine)
end function

'' Margin uses g_sArrayOutputSeparator & " " between elements; split on that so decimal commas stay intact.
private function SplitCopyArrayInner(byref inner as String, elems() as String) as Integer
  erase elems
  dim s as String = inner
  dim n as Integer = Len(s)
  if n = 0 then return 0
  dim delim as String = Trim(g_sArrayOutputSeparator) & " "
  dim dlen as Integer = Len(delim)
  if dlen < 1 then return 0
  dim depth as Integer = 0
  dim start as Integer = 1
  dim partCount as Integer = 0
  dim i as Integer = 1
  while i <= n
    dim ch as String = Mid(s, i, 1)
    if ch = "(" then
      depth += 1
      i += 1
    elseif ch = ")" then
      if depth > 0 then depth -= 1
      i += 1
    elseif depth = 0 andalso i + dlen - 1 <= n andalso Mid(s, i, dlen) = delim then
      dim seg as String = Trim(Mid(s, start, i - start))
      if partCount = 0 then
        redim elems(0 to 0)
      else
        redim preserve elems(0 to partCount)
      end if
      elems(partCount) = seg
      partCount += 1
      i += dlen
      start = i
    else
      i += 1
    end if
  wend
  dim segLast as String = Trim(Mid(s, start, n - start + 1))
  if partCount = 0 then
    redim elems(0 to 0)
  else
    redim preserve elems(0 to partCount)
  end if
  elems(partCount) = segLast
  return partCount + 1
end function

'' Clipboard: ASCII "." decimals (parser-friendly); skip base-prefixed literals.
private function ElemToCanonicalCopy(byref seg as String) as String
  dim t as String = Trim(seg)
  if Len(t) = 0 then return t
  dim tl as String = LCase(Left(t, 2))
  if tl = "0x" orelse tl = "0b" orelse tl = "0o" then return t
  if g_sDecimalSeparator = "." then return t
  dim u as String = ""
  dim j as Integer
  for j = 1 to Len(t)
    dim c as String = Mid(t, j, 1)
    if c = g_sDecimalSeparator then
      u &= "."
    else
      u &= c
    end if
  next j
  return u
end function

function NormalizeCopiedResult(byref sRes as String) as String
  if left(sRes, Len(SMARTMATH_RESULT_PREFIX)) = SMARTMATH_RESULT_PREFIX then
    dim sOut as String = mid(sRes, Len(SMARTMATH_RESULT_PREFIX) + 1)
    if g_bUseThousandsSeparator then
      dim i as Integer
      dim sNoSep as String = ""
      for i = 1 to len(sOut)
        dim ch as String = mid(sOut, i, 1)
        if ch <> g_sThousandsSeparator then sNoSep &= ch
      next i
      sOut = sNoSep
    end if

    sOut = Trim(sOut)
    if Len(sOut) >= 2 andalso Left(sOut, 1) = "(" andalso Right(sOut, 1) = ")" then
      dim inner as String = Trim(Mid(sOut, 2, Len(sOut) - 2))
      dim elems() as String
      dim cnt as Integer = SplitCopyArrayInner(inner, elems())
      if cnt <= 0 then return "()"
      dim acc as String = "("
      dim ei as Integer
      for ei = 0 to cnt - 1
        if ei > 0 then acc &= ", "
        acc &= ElemToCanonicalCopy(elems(ei))
      next ei
      acc &= ")"
      return acc
    end if

    return ElemToCanonicalCopy(sOut)
  elseif left(sRes, Len(SMARTMATH_ERROR_PREFIX)) = SMARTMATH_ERROR_PREFIX then
    return mid(sRes, Len(SMARTMATH_ERROR_PREFIX) + 1)
  end if
  return sRes
end function

function CopyTextToClipboard(byval hWndOwner as HWND, byref sText as String) as BOOL
  if len(sText) = 0 then return FALSE
  if OpenClipboard(hWndOwner) = FALSE then return FALSE
  EmptyClipboard()

  dim cbBytes as Integer = len(sText) + 1
  dim hMem as HGLOBAL = GlobalAlloc(GMEM_MOVEABLE, cbBytes)
  if hMem = 0 then
    CloseClipboard()
    return FALSE
  end if
  dim pMem as any ptr = GlobalLock(hMem)
  if pMem then
    memcpy(pMem, strptr(sText), cbBytes)
    GlobalUnlock(hMem)
    SetClipboardData(CF_TEXT, hMem)
    CloseClipboard()
    return TRUE
  end if
  GlobalFree(hMem)
  CloseClipboard()
  return FALSE
end function

' -----------------------------------------------------------------------------
'  Drawing Logic & Positioning
' -----------------------------------------------------------------------------
sub UpdateMarginAndState(byval hWnd as HWND, byref bVisible as BOOL)
  if g_bShuttingDown then
    bVisible = FALSE
    exit sub
  end if

  if g_bSmartMathDocActive = FALSE then
    bVisible = FALSE
    if nOldMargin <> 0 then
      SendMessage(hWnd, EM_SETMARGINS, EC_RIGHTMARGIN, 0)
      nOldMargin = 0
    end if
    exit sub
  end if

  bVisible = FALSE
  dim rcClient as RECT
  GetClientRect(hWnd, @rcClient)

  dim nFirstVisible as Integer = SendMessage(hWnd, EM_GETFIRSTVISIBLELINE, 0, 0)
  dim nLineCount as Integer = SendMessage(hWnd, EM_GETLINECOUNT, 0, 0)

  dim hDC as HDC = GetDC(hWnd)
  dim hFont as HFONT = cast(HFONT, SendMessage(hWnd, WM_GETFONT, 0, 0))
  dim hOldFont as HFONT
  if hFont then hOldFont = cast(HFONT, SelectObject(hDC, hFont))

  dim maxTextWidth as Integer = 0

  EnsureRenderCache(hWnd)

  dim i as Integer
  for i = 0 to nLineCount - 1
    dim nLineIndex as Integer = SendMessage(hWnd, EM_LINEINDEX, i, 0)
    dim nLineLen as Integer = SendMessage(hWnd, EM_LINELENGTH, nLineIndex, 0)

    dim ptClient_y as Integer = -10001

    if i >= nFirstVisible then
      dim ptClient as POINT
      dim res as LRESULT
      if g_bOldRichEdit then
        res = SendMessage(hWnd, EM_POSFROMCHAR, nLineIndex + nLineLen, 0)
        ptClient_y = cast(short, HiWord(res))
      else
        SendMessage(hWnd, EM_POSFROMCHAR, cast(WPARAM, @ptClient), nLineIndex + nLineLen)
        ptClient_y = ptClient.y
      end if

      if ptClient_y > rcClient.bottom then exit for
    end if

    dim sRes as String = ""
    if i >= 0 andalso i < g_cacheLineCount then sRes = g_cachedRenderText(i)

    if len(sRes) > 0 andalso i >= nFirstVisible andalso ptClient_y > -10000 then
      bVisible = TRUE
      dim sz as SIZE
      GetTextExtentPoint32(hDC, strptr(sRes), Len(sRes), @sz)
      if sz.cx > maxTextWidth then maxTextWidth = sz.cx
    end if
  next i

  if hFont then SelectObject(hDC, hOldFont)
  ReleaseDC(hWnd, hDC)

  ' Keep editor layout untouched to avoid soft-wrap side effects on long lines.
  ' Results are rendered as an overlay and clipped on the right side in drawing code.
  dim nRequiredMargin as Integer = 0

  if nRequiredMargin <> nOldMargin then
    SendMessage(hWnd, EM_SETMARGINS, EC_RIGHTMARGIN, nRequiredMargin shl 16)
    nOldMargin = nRequiredMargin
  end if
end sub

sub DrawDynamicMathResults(byval hWnd as HWND)
  if g_bShuttingDown then exit sub
  if g_bSmartMathDocActive = FALSE then exit sub

  dim hDC as HDC = GetDC(hWnd)
  if hDC = 0 then exit sub

  dim rcClient as RECT
  GetClientRect(hWnd, @rcClient)

  dim nFirstVisible as Integer = SendMessage(hWnd, EM_GETFIRSTVISIBLELINE, 0, 0)
  dim nLineCount as Integer = SendMessage(hWnd, EM_GETLINECOUNT, 0, 0)
  dim nCaretLine as Integer = SendMessage(hWnd, EM_EXLINEFROMCHAR, 0, -1)

  dim hFont as HFONT = cast(HFONT, SendMessage(hWnd, WM_GETFONT, 0, 0))
  dim hOldFont as HFONT
  if hFont then hOldFont = cast(HFONT, SelectObject(hDC, hFont))

  dim nCharHeight as Integer = 0
  if not g_bOldRichEdit then
    nCharHeight = SendMessage(hWnd, AEM_GETCHARSIZE, 0, 0)
  end if

  dim hBrushActive as HBRUSH = 0
  dim bFillActive as BOOL = FALSE
  if not g_bOldRichEdit then
    dim dwOptions as DWORD = SendMessage(hWnd, AEM_GETOPTIONS, 0, 0)
    if (dwOptions and AECO_ACTIVELINE) then
      dim aec as AECOLORS
      aec.dwFlags = AECLR_ACTIVELINEBK
      SendMessage(hWnd, AEM_GETCOLORS, 0, cast(LPARAM, @aec))
      hBrushActive = CreateSolidBrush(aec.crActiveLineBk)
      bFillActive = TRUE
    end if
  end if

  SetBkMode(hDC, TRANSPARENT)

  EnsureRenderCache(hWnd)

  dim i as Integer
  for i = 0 to nLineCount - 1
    dim nLineIndex as Integer = SendMessage(hWnd, EM_LINEINDEX, i, 0)
    dim nLineLen as Integer = SendMessage(hWnd, EM_LINELENGTH, nLineIndex, 0)

    dim ptClient_x as Integer = -10001
    dim ptClient_y as Integer = -10001

    if i >= nFirstVisible then
      dim ptClient as POINT
      dim res as LRESULT
      if g_bOldRichEdit then
        res = SendMessage(hWnd, EM_POSFROMCHAR, nLineIndex + nLineLen, 0)
        ptClient_x = cast(short, LoWord(res))
        ptClient_y = cast(short, HiWord(res))
      else
        SendMessage(hWnd, EM_POSFROMCHAR, cast(WPARAM, @ptClient), nLineIndex + nLineLen)
        ptClient_x = ptClient.x
        ptClient_y = ptClient.y
      end if

      if ptClient_y > rcClient.bottom then exit for
    end if

    dim sRes as String = ""
    if i >= 0 andalso i < g_cacheLineCount then sRes = g_cachedRenderText(i)
    dim bIsError as Boolean = (left(sRes, Len(SMARTMATH_ERROR_PREFIX)) = SMARTMATH_ERROR_PREFIX)

    if len(sRes) > 0 then
      if i >= nFirstVisible andalso ptClient_y > -10000 then
        dim sz as SIZE
        GetTextExtentPoint32(hDC, strptr(sRes), Len(sRes), @sz)

        if nCharHeight <= 0 then nCharHeight = sz.cy

        dim lineRect as RECT
        lineRect.left = IIf(nOldMargin > 0, rcClient.right - nOldMargin, rcClient.left)
        lineRect.right = rcClient.right
        lineRect.top = ptClient_y
        lineRect.bottom = ptClient_y + nCharHeight

        ' In overlay mode (nOldMargin = 0), never paint active-line background here:
        ' it can cover editor text because this drawing runs after editor paint.
        if bFillActive andalso (nOldMargin > 0) andalso (i = nCaretLine) andalso hBrushActive then
          FillRect(hDC, @lineRect, hBrushActive)
        end if

        if bIsError then
          SetTextColor(hDC, &H0000FF)
        else
          SetTextColor(hDC, g_crResultColor)
        end if
        dim drawX as Integer = rcClient.right - sz.cx - 10
        dim drawY as Integer = lineRect.top + ((lineRect.bottom - lineRect.top) - sz.cy) \ 2
        dim minDrawX as Integer = ptClient_x + 6
        if minDrawX < rcClient.left then minDrawX = rcClient.left
        if minDrawX < rcClient.right then
          dim clipRect as RECT
          clipRect.left = IIf(drawX > minDrawX, drawX, minDrawX)
          clipRect.top = lineRect.top
          clipRect.right = rcClient.right
          clipRect.bottom = lineRect.bottom
          if clipRect.left < clipRect.right then
            ExtTextOut(hDC, drawX, drawY, ETO_CLIPPED, @clipRect, strptr(sRes), Len(sRes), 0)
          end if
        end if
      end if
    end if
  next i

  if hBrushActive then DeleteObject(hBrushActive)
  if hFont then SelectObject(hDC, hOldFont)
  ReleaseDC(hWnd, hDC)
end sub

' -----------------------------------------------------------------------------
'  Main-window subclass procedure
' -----------------------------------------------------------------------------
function SmartMathMainProc stdcall(byval hWnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM) as LRESULT
  if uMsg = WM_COMMAND then
    dim nCmd as Integer = LOWORD(wParam)

    if nCmd = IDM_DECIMAL_BASE then
      g_nDecimals = -1
      InvalidateRenderCache()
      SaveSettings()
      UpdateMenuChecks()
      if g_hWndEdit then
        dim bVis as BOOL
        UpdateMarginAndState(g_hWndEdit, bVis)
        InvalidateRect(g_hWndEdit, 0, TRUE)
      end if
      return 0

    elseif nCmd > IDM_DECIMAL_BASE andalso nCmd <= IDM_DECIMAL_BASE + 15 then
      g_nDecimals = nCmd - IDM_DECIMAL_BASE - 1
      InvalidateRenderCache()
      SaveSettings()
      UpdateMenuChecks()
      if g_hWndEdit then
        dim bVis as BOOL
        UpdateMarginAndState(g_hWndEdit, bVis)
        InvalidateRect(g_hWndEdit, 0, TRUE)
      end if
      return 0

    elseif nCmd >= IDM_COLOR_BASE andalso nCmd < IDM_COLOR_BASE + MAX_COLORS then
      select case nCmd
        case IDM_COLOR_GREEN:  g_crResultColor = &H008000
        case IDM_COLOR_BLUE:   g_crResultColor = &HFF0000
        case IDM_COLOR_RED:    g_crResultColor = &H0000FF
        case IDM_COLOR_YELLOW: g_crResultColor = &H00FFFF
        case IDM_COLOR_WHITE:  g_crResultColor = &HFFFFFF
        case IDM_COLOR_BLACK:  g_crResultColor = &H000000
      end select
      SaveSettings()
      UpdateMenuChecks()
      if g_hWndEdit then
        InvalidateRect(g_hWndEdit, 0, TRUE)
      end if
      return 0
      
    elseif nCmd = IDM_THOUSANDS_SEPARATOR then
      if g_bUseThousandsSeparator then
        g_bUseThousandsSeparator = FALSE
      else
        g_bUseThousandsSeparator = TRUE
      end if
      InvalidateRenderCache()
      SaveSettings()
      UpdateMenuChecks()
      if g_hWndEdit then
        dim bVis as BOOL
        UpdateMarginAndState(g_hWndEdit, bVis)
        InvalidateRect(g_hWndEdit, 0, TRUE)
      end if
      return 0

    elseif nCmd = IDM_ABOUT then
      ShowAboutDialog(hWnd)
      return 0
    end if

  elseif (uMsg = AKDN_FRAME_ACTIVATE) orelse (uMsg = AKDN_OPENDOCUMENT_FINISH) then
    dim hWndEditCurrent as HWND = GetWndEdit(g_hMainWnd)
    if hWndEditCurrent <> 0 then
      if uMsg = AKDN_OPENDOCUMENT_FINISH then
        ' clearing g_lastDocModeFrame to be sure IsSmartMathDocument() will be called
        g_lastDocModeFrame = 0
      end if
      RefreshSmartMathDocMode(hWndEditCurrent)
    end if

  elseif uMsg = AKDN_MAIN_ONFINISH then
    g_bShuttingDown = TRUE
    dim pfnOld as WNDPROC = g_pfnOldMainProc

    if bSmartMathActive then
      SendMessage(g_hMainWnd, AKD_SETEDITPROC, 0, cast(LPARAM, @lpEditProcData))
      SendMessage(g_hMainWnd, AKD_SETMAINPROC, 0, cast(LPARAM, @lpMainProcData))
      SendMessage(g_hMainWnd, AKD_SETFRAMEPROC, 0, cast(LPARAM, @lpFrameProcData))
      bSmartMathActive = FALSE
    end if

    UninitSmartMathMenu(TRUE)

    if pfnOld then
      return CallWindowProc(pfnOld, hWnd, uMsg, wParam, lParam)
    end if
    return 0
  end if

  if g_pfnOldMainProc then
    return CallWindowProc(g_pfnOldMainProc, hWnd, uMsg, wParam, lParam)
  end if
  return 0
end function

' -----------------------------------------------------------------------------
'  Global Edit Window Subclass
' -----------------------------------------------------------------------------
function EditGlobalProc stdcall(byval hWnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM) as LRESULT
  if g_bShuttingDown then
    if lpEditProcData andalso lpEditProcData->NextProc then
      return lpEditProcData->NextProc(hWnd, uMsg, wParam, lParam)
    else
      return 0
    end if
  end if

  g_hWndEdit = hWnd

  dim lRes as LRESULT
  dim rcUpdate as RECT
  dim bNeedRedraw as BOOL = FALSE

  select case uMsg
    case WM_PAINT
      if g_bSmartMathDocActive then
        GetUpdateRect(hWnd, @rcUpdate, FALSE)
        dim rcIntersect as RECT
        if (rcOldMargin.right = 0) orelse IntersectRect(@rcIntersect, @rcUpdate, @rcOldMargin) then
          bNeedRedraw = TRUE
        end if
      end if

    case WM_SETFOCUS
      if nOldMargin > 0 then
        SendMessage(hWnd, EM_SETMARGINS, EC_RIGHTMARGIN, nOldMargin shl 16)
      end if
      if not g_bOldRichEdit then
        SendMessage(hWnd, AEM_SETOPTIONS, AECOOP_OR, AECO_ACTIVELINE)
      end if

    case WM_SIZE, WM_MOUSEWHEEL, WM_VSCROLL, WM_HSCROLL
      if rcOldMargin.right > 0 then InvalidateRect(hWnd, @rcOldMargin, TRUE)

    case WM_LBUTTONDBLCLK
      dim xPos as Integer = cast(short, loword(lParam))
      dim yPos as Integer = cast(short, hiword(lParam))
      dim rcClient as RECT
      GetClientRect(hWnd, @rcClient)

      dim charPos as Integer = -1
      if g_bOldRichEdit then
        dim posRes as LRESULT = SendMessage(hWnd, EM_CHARFROMPOS, 0, cast(LPARAM, MAKELPARAM(xPos, yPos)))
        charPos = cast(short, loword(posRes))
      else
        dim pt as POINT
        pt.x = xPos
        pt.y = yPos
        charPos = SendMessage(hWnd, EM_CHARFROMPOS, 0, cast(LPARAM, @pt))
      end if

      if charPos >= 0 then
        dim lineIdx as Integer = SendMessage(hWnd, EM_EXLINEFROMCHAR, 0, charPos)
        dim sRes as String = BuildResultTextForLine(hWnd, lineIdx)
        if len(sRes) > 0 then
          dim hitResultArea as BOOL = FALSE
          if nOldMargin > 0 then
            dim nMarginLeft as Integer = rcClient.right - nOldMargin
            if xPos >= nMarginLeft then hitResultArea = TRUE
          else
            dim nLineIndex as Integer = SendMessage(hWnd, EM_LINEINDEX, lineIdx, 0)
            dim nLineLen as Integer = SendMessage(hWnd, EM_LINELENGTH, nLineIndex, 0)
            dim ptLineEndX as Integer = rcClient.left
            if nLineIndex >= 0 then
              if g_bOldRichEdit then
                dim res as LRESULT = SendMessage(hWnd, EM_POSFROMCHAR, nLineIndex + nLineLen, 0)
                ptLineEndX = cast(short, LoWord(res))
              else
                dim ptLine as POINT
                SendMessage(hWnd, EM_POSFROMCHAR, cast(WPARAM, @ptLine), nLineIndex + nLineLen)
                ptLineEndX = ptLine.x
              end if
            end if

            dim hDC as HDC = GetDC(hWnd)
            if hDC <> 0 then
              dim hFont as HFONT = cast(HFONT, SendMessage(hWnd, WM_GETFONT, 0, 0))
              dim hOldFont as HFONT
              if hFont then hOldFont = cast(HFONT, SelectObject(hDC, hFont))
              dim sz as SIZE
              GetTextExtentPoint32(hDC, strptr(sRes), Len(sRes), @sz)
              if hFont then SelectObject(hDC, hOldFont)
              ReleaseDC(hWnd, hDC)

              dim drawX as Integer = rcClient.right - sz.cx - 10
              dim minDrawX as Integer = ptLineEndX + 6
              if minDrawX < rcClient.left then minDrawX = rcClient.left
              dim clipLeft as Integer = IIf(drawX > minDrawX, drawX, minDrawX)
              if xPos >= clipLeft andalso xPos <= rcClient.right then hitResultArea = TRUE
            end if
          end if

          if hitResultArea then
            dim sCopy as String = NormalizeCopiedResult(sRes)
            if CopyTextToClipboard(hWnd, sCopy) then
              return 0
            end if
          end if
        end if
      end if
  end select

  if lpEditProcData andalso lpEditProcData->NextProc then
    lRes = lpEditProcData->NextProc(hWnd, uMsg, wParam, lParam)
  else
    lRes = 0
  end if

  if uMsg = WM_PAINT then
    if bNeedRedraw then
      DrawDynamicMathResults(hWnd)
    end if
  else
    select case uMsg
      case WM_KEYDOWN, WM_KEYUP, WM_SYSKEYDOWN, WM_SYSKEYUP, _
           WM_LBUTTONDOWN, WM_LBUTTONUP, WM_MOUSEMOVE, _
           WM_MOUSEWHEEL, WM_HSCROLL, WM_VSCROLL, WM_CHAR, WM_SIZE
        if g_bSmartMathDocActive = FALSE then
          return lRes
        end if

        if (uMsg <> WM_MOUSEMOVE) orelse (wParam and MK_LBUTTON) then
          dim bVisible as BOOL
          UpdateMarginAndState(hWnd, bVisible)

          dim rcClient as RECT
          GetClientRect(hWnd, @rcClient)

          dim rcNewMargin as RECT
          if nOldMargin > 0 then
            rcNewMargin.left = rcClient.right - nOldMargin
            rcNewMargin.top = rcClient.top
            rcNewMargin.right = rcClient.right
            rcNewMargin.bottom = rcClient.bottom
          else
            rcNewMargin = rcClient
          end if

          dim nFirstVisible as Integer = SendMessage(hWnd, EM_GETFIRSTVISIBLELINE, 0, 0)
          dim nCaretLine as Integer = SendMessage(hWnd, EM_EXLINEFROMCHAR, 0, -1)

          dim bForceKeyRedraw as BOOL = ((uMsg = WM_KEYDOWN) orelse (uMsg = WM_KEYUP))
          if (uMsg = WM_KEYDOWN) orelse (uMsg = WM_SYSKEYDOWN) then
            if (wParam = VK_UP) orelse (wParam = VK_DOWN) orelse (wParam = VK_LEFT) orelse (wParam = VK_RIGHT) orelse _
               (wParam = VK_HOME) orelse (wParam = VK_END) orelse (wParam = VK_PRIOR) orelse (wParam = VK_NEXT) then
              dim selStart as Integer = 0, selEnd as Integer = 0
              SendMessage(hWnd, EM_GETSEL, cast(WPARAM, @selStart), cast(LPARAM, @selEnd))
              if (selStart = nLastNavSelStart) andalso (selEnd = nLastNavSelEnd) then
                bForceKeyRedraw = FALSE ' selection not changed -> no need to redraw
              else
                nLastNavSelStart = selStart
                nLastNavSelEnd = selEnd
              end if
            else
              nLastNavSelStart = -1
              nLastNavSelEnd = -1
            end if
          end if

          if bVisible then
            if (rcNewMargin.left <> rcOldMargin.left) or (rcNewMargin.right <> rcOldMargin.right) or _
               (nFirstVisible <> nOldFirstLine) or (nCaretLine <> nOldCaretLine) or _
               (uMsg = WM_CHAR) orelse bForceKeyRedraw then

              if rcOldMargin.right > 0 then InvalidateRect(hWnd, @rcOldMargin, TRUE)
              InvalidateRect(hWnd, @rcNewMargin, TRUE)

              rcOldMargin = rcNewMargin
              nOldFirstLine = nFirstVisible
              nOldCaretLine = nCaretLine
            end if
          else
            if rcOldMargin.right > 0 then
              InvalidateRect(hWnd, @rcOldMargin, TRUE)
              rcOldMargin.left = 0 : rcOldMargin.right = 0
              rcOldMargin.top = 0  : rcOldMargin.bottom = 0
              nOldFirstLine = -1
              nOldCaretLine = -1
              nLastNavSelStart = -1
              nLastNavSelEnd = -1
            end if
          end if
        end if
    end select
  end if

  return lRes
end function

' -----------------------------------------------------------------------------
'  Global Main Window Subclass
' -----------------------------------------------------------------------------
function MainGlobalProc stdcall(byval hWnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM) as LRESULT
  CheckEditNotifications(hWnd, uMsg, wParam, lParam)
  if lpMainProcData andalso lpMainProcData->NextProc then
    return lpMainProcData->NextProc(hWnd, uMsg, wParam, lParam)
  else
    return 0
  end if
end function

' -----------------------------------------------------------------------------
'  Global Frame Window Subclass
' -----------------------------------------------------------------------------
function FrameGlobalProc stdcall(byval hWnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM) as LRESULT
  CheckEditNotifications(hWnd, uMsg, wParam, lParam)
  if lpFrameProcData andalso lpFrameProcData->NextProc then
    return lpFrameProcData->NextProc(hWnd, uMsg, wParam, lParam)
  else
    return 0
  end if
end function

' -----------------------------------------------------------------------------
'  Exported Functions
' -----------------------------------------------------------------------------
extern "C"

sub DllAkelPadID alias "DllAkelPadID" (byval pv as PLUGINVERSION ptr) export
  pv->dwAkelDllVersion = AKELDLL
  pv->dwExeMinVersion3x = MAKE_IDENTIFIER(-1, -1, -1, -1)
  pv->dwExeMinVersion4x = MAKE_IDENTIFIER(4, 9, 7, 0)
  pv->pPluginName = @"SmartMath"
end sub

sub ToggleSmartMath alias "ToggleSmartMath" (byval pd as PLUGINDATA ptr) export
  if (pd->dwSupport and PDS_GETSUPPORT) then exit sub

  LogInfo("--- ToggleSmartMath Called ---")

  g_hMainWnd  = pd->hMainWnd
  g_hMainMenu = pd->hMainMenu
  g_hWndEdit  = pd->hWndEdit
  g_bOldRichEdit = pd->bOldRichEdit

  dim pf as PLUGINFUNCTION ptr

  if bSmartMathActive then
    LogInfo("Deactivating Global Edit Hook...")
    pd->nUnload = UD_UNLOAD

    UninitSmartMathMenu(FALSE)

    SendMessage(pd->hMainWnd, AKD_SETEDITPROC, 0, cast(LPARAM, @lpEditProcData))
    SendMessage(g_hMainWnd, AKD_SETMAINPROC, 0, cast(LPARAM, @lpMainProcData))
    SendMessage(g_hMainWnd, AKD_SETFRAMEPROC, 0, cast(LPARAM, @lpFrameProcData))
    bSmartMathActive = FALSE
    InvalidateRenderCache()

    if pd->hWndEdit then
      SendMessage(pd->hWndEdit, EM_SETMARGINS, EC_RIGHTMARGIN, 0)
      if not g_bOldRichEdit then
        SendMessage(pd->hWndEdit, AEM_SETOPTIONS, AECOOP_SET, dwOldAkelOptions)
      end if
      InvalidateRect(pd->hWndEdit, 0, TRUE)
    end if

    pf = cast(PLUGINFUNCTION ptr, SendMessageW(pd->hMainWnd, AKD_DLLFINDW, cast(WPARAM, @wstr("SmartMath::ToggleSmartMath")), 0))
    if pf <> 0 then
      pf->bAutoLoad = FALSE
      SendMessage(pd->hMainWnd, AKD_DLLSAVE, DLLSF_NOW, 0)
    end if

  else
    LogInfo("Activating Global Edit Hook...")
    pd->nUnload = UD_NONUNLOAD_ACTIVE

    if g_wszIniPath = "" andalso pd->wszAkelDir <> 0 then
      g_wszIniPath = *(pd->wszAkelDir) & wstr("\AkelFiles\Plugs\SmartMath.ini")
    end if
    LoadSettings()

    g_bShuttingDown = FALSE
    InvalidateRenderCache()

    rcOldMargin.left = 0 : rcOldMargin.right = 0
    rcOldMargin.top = 0  : rcOldMargin.bottom = 0
    nOldFirstLine = -1
    nOldCaretLine = -1
    nLastNavSelStart = -1
    nLastNavSelEnd = -1
    nOldMargin = 0

    SendMessage(pd->hMainWnd, AKD_SETEDITPROC, cast(WPARAM, @EditGlobalProc), cast(LPARAM, @lpEditProcData))
    SendMessage(pd->hMainWnd, AKD_SETMAINPROC, cast(WPARAM, @MainGlobalProc), cast(LPARAM, @lpMainProcData))
    SendMessage(pd->hMainWnd, AKD_SETFRAMEPROC, cast(WPARAM, @FrameGlobalProc), cast(LPARAM, @lpFrameProcData))
    bSmartMathActive = TRUE

    InitSmartMathMenu()

    dim hEditAct as HWND = pd->hWndEdit
    if hEditAct = 0 then hEditAct = GetWndEdit(pd->hMainWnd)

    if hEditAct <> 0 then
      EnsureSmartMathFirstLineOnActivate(hEditAct)
      g_hWndEdit = hEditAct
      RefreshSmartMathDocMode(hEditAct)
      if not g_bOldRichEdit then
        dwOldAkelOptions = SendMessage(hEditAct, AEM_GETOPTIONS, 0, 0)
        SendMessage(hEditAct, AEM_SETOPTIONS, AECOOP_OR, AECO_ACTIVELINE)
      end if

      dim bInitialVis as BOOL
      UpdateMarginAndState(hEditAct, bInitialVis)

      InvalidateRect(hEditAct, 0, TRUE)
    end if

    pf = cast(PLUGINFUNCTION ptr, SendMessageW(pd->hMainWnd, AKD_DLLFINDW, cast(WPARAM, @wstr("SmartMath::ToggleSmartMath")), 0))
    if pf <> 0 then
      pf->bAutoLoad = TRUE
      if pd->bOnStart = FALSE then
        SendMessage(pd->hMainWnd, AKD_DLLSAVE, DLLSF_NOW, 0)
      end if
    end if

  end if

  LogInfo("--- ToggleSmartMath Finished ---")
end sub

end extern

function DllMain(byval hinstDLL as HINSTANCE, byval fdwReason as DWORD, byval lpvReserved as LPVOID) as WINBOOL
  return TRUE
end function