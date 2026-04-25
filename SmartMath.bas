#include once "SmartMath_Globals.bi"

' --- Shared global variables definitions ---
dim shared lpEditProcData as WNDPROCDATA ptr = 0
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
dim shared hSmartMathMenu as HMENU = 0
dim shared hSubMenuDecimals as HMENU = 0
dim shared hSubMenuColor as HMENU = 0
dim shared g_hMainWnd as HWND = 0
dim shared g_hMainMenu as HMENU = 0
dim shared g_hWndEdit as HWND = 0
dim shared g_bShuttingDown as BOOL = FALSE

' FIX: Use a plain Win32 WNDPROC pointer instead of AKD_SETMAINPROC / WNDPROCDATA.
dim shared g_pfnOldMainProc as WNDPROC = 0
dim shared g_wszIniPath as WString * 260

' -----------------------------------------------------------------------------
'  Debug logging
' -----------------------------------------------------------------------------
sub LogInfo(byref sMsg as String)
  dim sOut as String = "[SmartMath] " & sMsg
  OutputDebugString(strptr(sOut))
end sub

' -----------------------------------------------------------------------------
'  Text safety (universal ANSI/Unicode support for AkelPad)
' -----------------------------------------------------------------------------
function GetLineText(byval hWnd as HWND, byval lineIdx as Integer, byval lineLen as Integer) as String
  if lineLen <= 0 then return ""
  dim as String sRet = ""

  if IsWindowUnicode(hWnd) then
    dim wBuf as WString ptr = cast(WString ptr, callocate((lineLen + 2) * 2))
    cast(Short ptr, wBuf)[0] = lineLen
    dim lenRead as Integer = SendMessageW(hWnd, EM_GETLINE, lineIdx, cast(LPARAM, wBuf))
    if lenRead > 0 then sRet = Left(*wBuf, lenRead)
    deallocate(wBuf)
  else
    dim zBuf as ZString ptr = cast(ZString ptr, callocate(lineLen + 2))
    cast(Short ptr, zBuf)[0] = lineLen
    dim lenRead as Integer = SendMessageA(hWnd, EM_GETLINE, lineIdx, cast(LPARAM, zBuf))
    if lenRead > 0 then sRet = Left(*zBuf, lenRead)
    deallocate(zBuf)
  end if

  return sRet
end function

function BuildLineRenderText(byval hWnd as HWND, byval lineIdx as Integer) as String
  dim nLineIndex as Integer = SendMessage(hWnd, EM_LINEINDEX, lineIdx, 0)
  dim nLineLen as Integer = SendMessage(hWnd, EM_LINELENGTH, nLineIndex, 0)
  dim sLine as String = GetLineText(hWnd, lineIdx, nLineLen)

  dim dResult as Double
  dim sResult as String
  dim bIsArray as Boolean

  if Parser_TryEvaluateEx(sLine, dResult, sResult, bIsArray) then
    dim sTrimResult as String = lcase(trim(sResult))
    dim bPrefixedScalar as Boolean = (left(sTrimResult, 2) = "0x") orelse (left(sTrimResult, 3) = "-0x") _
                                  orelse (left(sTrimResult, 2) = "0b") orelse (left(sTrimResult, 3) = "-0b")
    if lcase(left(trim(sResult), 8)) = "defined " then
      return ""
    elseif bIsArray orelse bPrefixedScalar then
      return " = " & sResult
    else
      return FormatResult(dResult)
    end if
  end if

  dim sErr as String = Parser_GetLastError()
  if len(sErr) > 0 then return " ! " & sErr
  return ""
end function

function BuildResultTextForLine(byval hWnd as HWND, byval targetLine as Integer) as String
  dim nLineCount as Integer = SendMessage(hWnd, EM_GETLINECOUNT, 0, 0)
  if targetLine < 0 orelse targetLine >= nLineCount then return ""

  Parser_ClearVariables()
  dim i as Integer
  for i = 0 to targetLine
    dim sRes as String = BuildLineRenderText(hWnd, i)
    if i = targetLine then return sRes
  next i
  return ""
end function

function NormalizeCopiedResult(byref sRes as String) as String
  if left(sRes, 3) = " = " orelse left(sRes, 3) = " ! " then
    return mid(sRes, 4)
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

  Parser_ClearVariables()

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

    dim sLine as String = GetLineText(hWnd, i, nLineLen)
    dim dResult as Double
    dim sResult as String
    dim bIsArray as Boolean

    dim sRes as String = ""
    if Parser_TryEvaluateEx(sLine, dResult, sResult, bIsArray) then
      dim sTrimResult as String = lcase(trim(sResult))
      dim bPrefixedScalar as Boolean = (left(sTrimResult, 2) = "0x") orelse (left(sTrimResult, 3) = "-0x") _
                                    orelse (left(sTrimResult, 2) = "0b") orelse (left(sTrimResult, 3) = "-0b")
      if lcase(left(trim(sResult), 8)) = "defined " then
        ' Function definition line: keep margin clean (no "= 0").
        sRes = ""
      elseif bIsArray orelse bPrefixedScalar then
        sRes = " = " & sResult
      else
        sRes = FormatResult(dResult)
      end if
    else
      dim sErr as String = Parser_GetLastError()
      if len(sErr) > 0 then sRes = " ! " & sErr
    end if

    if len(sRes) > 0 andalso i >= nFirstVisible andalso ptClient_y > -10000 then
      bVisible = TRUE
      dim sz as SIZE
      GetTextExtentPoint32(hDC, strptr(sRes), Len(sRes), @sz)
      if sz.cx > maxTextWidth then maxTextWidth = sz.cx
    end if
  next i

  if hFont then SelectObject(hDC, hOldFont)
  ReleaseDC(hWnd, hDC)

  dim nRequiredMargin as Integer = maxTextWidth + 30
  if maxTextWidth = 0 then nRequiredMargin = 0

  if nRequiredMargin <> nOldMargin then
    SendMessage(hWnd, EM_SETMARGINS, EC_RIGHTMARGIN, nRequiredMargin shl 16)
    nOldMargin = nRequiredMargin
  end if
end sub

sub DrawDynamicMathResults(byval hWnd as HWND)
  if g_bShuttingDown then exit sub

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

  Parser_ClearVariables()

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

    dim sLine as String = GetLineText(hWnd, i, nLineLen)
    dim dResult as Double
    dim sResult as String
    dim bIsArray as Boolean

    dim sRes as String = ""
    dim bIsError as Boolean = FALSE
    if Parser_TryEvaluateEx(sLine, dResult, sResult, bIsArray) then
      dim sTrimResult as String = lcase(trim(sResult))
      dim bPrefixedScalar as Boolean = (left(sTrimResult, 2) = "0x") orelse (left(sTrimResult, 3) = "-0x") _
                                    orelse (left(sTrimResult, 2) = "0b") orelse (left(sTrimResult, 3) = "-0b")
      if lcase(left(trim(sResult), 8)) = "defined " then
        ' Function definition line: keep margin clean (no "= 0").
        sRes = ""
      elseif bIsArray orelse bPrefixedScalar then
        sRes = " = " & sResult
      else
        sRes = FormatResult(dResult)
      end if
    else
      dim sErr as String = Parser_GetLastError()
      if len(sErr) > 0 then
        sRes = " ! " & sErr
        bIsError = TRUE
      end if
    end if

    if len(sRes) > 0 then
      if i >= nFirstVisible andalso ptClient_y > -10000 then
        dim sz as SIZE
        GetTextExtentPoint32(hDC, strptr(sRes), Len(sRes), @sz)

        if nCharHeight <= 0 then nCharHeight = sz.cy

        dim lineRect as RECT
        lineRect.left = rcClient.right - nOldMargin
        lineRect.right = rcClient.right
        lineRect.top = ptClient_y
        lineRect.bottom = ptClient_y + nCharHeight

        if bFillActive andalso (i = nCaretLine) andalso hBrushActive then
          FillRect(hDC, @lineRect, hBrushActive)
        end if

        if bIsError then
          SetTextColor(hDC, &H0000FF)
        else
          SetTextColor(hDC, g_crResultColor)
        end if
        dim drawX as Integer = rcClient.right - sz.cx - 10
        dim drawY as Integer = lineRect.top + ((lineRect.bottom - lineRect.top) - sz.cy) \ 2
        TextOut(hDC, drawX, drawY, strptr(sRes), Len(sRes))
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

  elseif uMsg = AKDN_MAIN_ONFINISH then
    g_bShuttingDown = TRUE
    dim pfnOld as WNDPROC = g_pfnOldMainProc

    if bSmartMathActive then
      SendMessage(g_hMainWnd, AKD_SETEDITPROC, 0, cast(LPARAM, @lpEditProcData))
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
      GetUpdateRect(hWnd, @rcUpdate, FALSE)
      dim rcIntersect as RECT
      if (rcOldMargin.right = 0) orelse IntersectRect(@rcIntersect, @rcUpdate, @rcOldMargin) then
        bNeedRedraw = TRUE
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
      if nOldMargin > 0 then
        dim xPos as Integer = cast(short, loword(lParam))
        dim yPos as Integer = cast(short, hiword(lParam))
        dim rcClient as RECT
        GetClientRect(hWnd, @rcClient)
        dim nMarginLeft as Integer = rcClient.right - nOldMargin
        if xPos >= nMarginLeft then
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
              dim sCopy as String = NormalizeCopiedResult(sRes)
              if CopyTextToClipboard(hWnd, sCopy) then
                return 0
              end if
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

        if (uMsg <> WM_MOUSEMOVE) orelse (wParam and MK_LBUTTON) then
          dim bVisible as BOOL
          UpdateMarginAndState(hWnd, bVisible)

          dim rcClient as RECT
          GetClientRect(hWnd, @rcClient)

          dim rcNewMargin as RECT
          rcNewMargin.left = rcClient.right - nOldMargin
          rcNewMargin.top = rcClient.top
          rcNewMargin.right = rcClient.right
          rcNewMargin.bottom = rcClient.bottom

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
    bSmartMathActive = FALSE

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

    rcOldMargin.left = 0 : rcOldMargin.right = 0
    rcOldMargin.top = 0  : rcOldMargin.bottom = 0
    nOldFirstLine = -1
    nOldCaretLine = -1
    nLastNavSelStart = -1
    nLastNavSelEnd = -1
    nOldMargin = 0

    SendMessage(pd->hMainWnd, AKD_SETEDITPROC, cast(WPARAM, @EditGlobalProc), cast(LPARAM, @lpEditProcData))
    bSmartMathActive = TRUE

    InitSmartMathMenu()

    if pd->hWndEdit then
      if not g_bOldRichEdit then
        dwOldAkelOptions = SendMessage(pd->hWndEdit, AEM_GETOPTIONS, 0, 0)
        SendMessage(pd->hWndEdit, AEM_SETOPTIONS, AECOOP_OR, AECO_ACTIVELINE)
      end if

      dim bInitialVis as BOOL
      UpdateMarginAndState(pd->hWndEdit, bInitialVis)

      InvalidateRect(pd->hWndEdit, 0, TRUE)
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