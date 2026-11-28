#include once "SmartMath_Globals.bi"
#include once "Inc\PtrArray.bi"

' --- Shared global variables definitions ---
dim shared lpEditProcData as WNDPROCDATA ptr = 0
dim shared lpMainProcData as WNDPROCDATA ptr = 0
dim shared lpFrameProcData as WNDPROCDATA ptr = 0
dim shared g_bSmartMathActive as BOOL = FALSE
dim shared g_bAkelPadReady as BOOL = FALSE
dim shared g_bOldRichEdit as BOOL = FALSE

dim shared rcOldMargin as RECT
dim shared nOldFirstLine as Integer = -1
dim shared nOldCaretLine as Integer = -1
dim shared nOldHScrollPos as Integer = -1
dim shared nLastNavSelStart as Integer = -1
dim shared nLastNavSelEnd as Integer = -1

dim shared hSmartMathMenu as HMENU = 0
dim shared hSubMenuDecimals as HMENU = 0
dim shared hSubMenuColor as HMENU = 0
dim shared g_hMainWnd as HWND = 0
dim shared g_hMainMenu as HMENU = 0
dim shared g_hWndEdit as HWND = 0
dim shared g_bShuttingDown as BOOL = FALSE
dim shared g_bActiveFramesSaved as BOOL = FALSE
dim shared g_cacheLineCount as Integer = -1
dim shared g_cacheReady as BOOL = FALSE
dim shared g_cacheDocGeneration as UInteger = 0
dim shared g_cacheSyncedGeneration as UInteger = 0
dim shared g_cacheDirtyFromLine as Integer = -1
dim shared g_documentationFilePath as WString * MAX_PATH
' While a content key is held, EnsureRenderCache only re-evals through the
' edited line and leaves g_cacheDirtyFromLine set so dependents stay dirty
' until key-up (results below are untrustworthy even when their text matches).
dim shared g_bContentKeyDown as BOOL = FALSE
redim shared g_cachedLineText(0 to 0) as String
redim shared g_cachedRenderText(0 to 0) as String

const ACTIVE_FRAME_FILE_SEPARATOR as UShort = 10 '' LF
type WStringPtr as WString ptr
redim shared g_frameFiles() as WStringPtr

type FrameItem
  declare constructor(byval pFrameInit as FRAMEDATA ptr)
  declare destructor()

  pFrame as FRAMEDATA ptr
  wszFile as WString ptr
  isWorking as BOOL
  dwOldAkelOptions as DWORD
  bHasSavedAkelOptions as BOOL
end type

constructor FrameItem(byval pFrameInit as FRAMEDATA ptr)
  pFrame = pFrameInit
  wszFile = 0
  isWorking = FALSE
  dwOldAkelOptions = 0
  bHasSavedAkelOptions = FALSE

  if pFrameInit <> 0 andalso pFrameInit->ei.wszFile <> 0 then
    dim pSrc as WString ptr = pFrameInit->ei.wszFile
    dim nFileChars as Integer = Len(*pSrc)
    wszFile = cast(WString ptr, Allocate((nFileChars + 1) * SizeOf(WString)))
    if wszFile <> 0 then
      *wszFile = *pSrc
    end if
  end if
end constructor

destructor FrameItem()
  if wszFile <> 0 then
    Deallocate(wszFile)
    wszFile = 0
  end if
  pFrame = 0
  bHasSavedAkelOptions = FALSE
end destructor

private sub FrameItemDeleter(byval p as Any Ptr)
  dim pFrameItem as FrameItem ptr = cast(FrameItem ptr, p)
  if pFrameItem <> 0 then
    Delete pFrameItem
  end if
end sub

private function FrameItemMatchesFrame(byval p as Any Ptr, byval key as Any Ptr) as Boolean
  dim pFrameItem as FrameItem ptr = cast(FrameItem ptr, p)
  if pFrameItem = 0 then return FALSE
  return pFrameItem->pFrame = cast(FRAMEDATA ptr, key)
end function

dim shared g_framesWithSmartMathEnabled as PtrArray = PtrArray(@FrameItemDeleter, @FrameItemMatchesFrame)

' Frame that currently owns the AECO_ACTIVELINE change. In PMDI several frames
' share one edit HWND, so at most one frame may hold the options snapshot.
dim shared g_pFrameItemAkelOptionsOwner as FrameItem ptr = 0

' SmartMath state always follows the active frame, so resolve items by the
' current FRAMEDATA pointer: in PMDI the edit HWND is shared by all frames.
private function FindCurrentFrameItem() as FrameItem ptr
  if g_hMainWnd = 0 then return 0
  dim pFrameCurrent as FRAMEDATA ptr = cast(FRAMEDATA ptr, SendMessage(g_hMainWnd, AKD_FRAMEFIND, FWF_CURRENT, 0))
  if pFrameCurrent = 0 then return 0
  dim idx as Integer = g_framesWithSmartMathEnabled.Find(pFrameCurrent)
  if idx < 0 then return 0
  return cast(FrameItem ptr, g_framesWithSmartMathEnabled[idx])
end function

private function FrameItemEditHwnd(byval pFrameItem as FrameItem ptr) as HWND
  if pFrameItem = 0 orelse pFrameItem->pFrame = 0 then return 0
  return pFrameItem->pFrame->ei.hWndEdit
end function

declare sub RestoreAkelOptionsIfSaved(byval pFrameItem as FrameItem ptr)

' Snapshot options once per FrameItem, then ensure AECO_ACTIVELINE is on.
private sub EnsureActiveLineOptionApplied(byval pFrameItem as FrameItem ptr)
  if g_bOldRichEdit orelse pFrameItem = 0 then exit sub
  dim hWndEdit as HWND = FrameItemEditHwnd(pFrameItem)
  if (hWndEdit = 0) orelse (IsWindow(hWndEdit) = FALSE) then exit sub

  if (g_pFrameItemAkelOptionsOwner <> 0) andalso (g_pFrameItemAkelOptionsOwner <> pFrameItem) then
    RestoreAkelOptionsIfSaved(g_pFrameItemAkelOptionsOwner)
  end if

  if pFrameItem->bHasSavedAkelOptions = FALSE then
    pFrameItem->dwOldAkelOptions = cast(DWORD, SendMessage(hWndEdit, AEM_GETOPTIONS, 0, 0))
    pFrameItem->bHasSavedAkelOptions = TRUE
  end if
  SendMessage(hWndEdit, AEM_SETOPTIONS, AECOOP_OR, AECO_ACTIVELINE)
  g_pFrameItemAkelOptionsOwner = pFrameItem
end sub

' Undo only AECO_ACTIVELINE if it was off in the saved snapshot.
sub RestoreAkelOptionsIfSaved(byval pFrameItem as FrameItem ptr)
  if pFrameItem = 0 then exit sub
  if g_pFrameItemAkelOptionsOwner = pFrameItem then g_pFrameItemAkelOptionsOwner = 0
  if g_bOldRichEdit orelse (pFrameItem->bHasSavedAkelOptions = FALSE) then exit sub

  dim hWndEdit as HWND = FrameItemEditHwnd(pFrameItem)
  if (hWndEdit <> 0) andalso (IsWindow(hWndEdit) <> 0) then
    if (pFrameItem->dwOldAkelOptions and AECO_ACTIVELINE) = 0 then
      dim dwClearActiveLine as DWORD = not cast(DWORD, AECO_ACTIVELINE)
      SendMessage(hWndEdit, AEM_SETOPTIONS, AECOOP_AND, cast(LPARAM, dwClearActiveLine))
    end if
  end if
  pFrameItem->bHasSavedAkelOptions = FALSE
end sub

' Drop the AECO_ACTIVELINE change made for a frame that is no longer rendered.
private sub RestoreAkelOptionsOfOwnerFrame()
  RestoreAkelOptionsIfSaved(g_pFrameItemAkelOptionsOwner)
end sub

private sub RestoreAllFrameAkelOptions()
  for i as Integer = 0 to g_framesWithSmartMathEnabled.Count() - 1
    RestoreAkelOptionsIfSaved(cast(FrameItem ptr, g_framesWithSmartMathEnabled[i]))
  next i
  g_pFrameItemAkelOptionsOwner = 0
end sub

' -----------------------------------------------------------------------------
'  Debug logging
' -----------------------------------------------------------------------------
sub LogInfo(byref sMsg as String)
  dim sOut as String = "[SmartMath] " & sMsg
  OutputDebugString(strptr(sOut))
end sub

private sub MarkRenderCacheDocumentDirty(byval dirtyFromLine as Integer = -1)
  g_cacheDocGeneration += 1u
  if dirtyFromLine >= 0 then
    if g_cacheDirtyFromLine < 0 orelse dirtyFromLine < g_cacheDirtyFromLine then
      g_cacheDirtyFromLine = dirtyFromLine
    end if
  else
    g_cacheDirtyFromLine = 0
  end if
end sub

declare sub EnsureRenderCache(byval hWnd as HWND)
declare sub InvalidateEditLine(byval hWnd as HWND, byval lineIdx as Integer)
declare sub InvalidateEditFromLineDown(byval hWnd as HWND, byval lineIdx as Integer)
declare sub InvalidateAfterContentEdit(byval hWnd as HWND, byval lineIdx as Integer, byval bSyncPaint as BOOL)

private function IsRenderCacheDocumentCurrent(byval hWnd as HWND) as BOOL
  if g_cacheReady = FALSE then return FALSE
  if g_cacheSyncedGeneration <> g_cacheDocGeneration then return FALSE
  if SendMessage(hWnd, EM_GETLINECOUNT, 0, 0) <> g_cacheLineCount then return FALSE
  return TRUE
end function

' Fully synced: document current and no deferred dirty dependents.
private function IsRenderCacheSyncedWithDocument(byval hWnd as HWND) as BOOL
  if g_cacheDirtyFromLine >= 0 then return FALSE
  return IsRenderCacheDocumentCurrent(hWnd)
end function

private sub InvalidateRenderCache()
  MarkRenderCacheDocumentDirty(0)
  g_cacheReady = FALSE
  g_cacheLineCount = -1
  g_bContentKeyDown = FALSE
end sub

private function IsNavigationVirtualKey(byval vk as WPARAM) as BOOL
  select case vk
    case VK_UP, VK_DOWN, VK_LEFT, VK_RIGHT, VK_HOME, VK_END, VK_PRIOR, VK_NEXT
      return TRUE
    case else
      return FALSE
  end select
end function

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

  dim dResult as SmFloat
  dim sResult as String
  dim bIsArray as Boolean
  Parser_TryEvaluateEx(sExpr, dResult, sResult, bIsArray)
end sub

dim shared g_bSmartMathDocActive as BOOL = FALSE
dim shared g_lastDocModeFrame as FRAMEDATA ptr = 0
dim shared g_lastDocModeEdit as HWND = 0
dim shared SMARTMATH_CODER_HIGHLIGHT_FUNC as WString * 32 = WStr("Coder::HighLight")
dim shared SMARTMATH_CODER_SETTINGS_FUNC as WString * 32 = WStr("Coder::Settings")
dim shared SMARTMATH_CODER_ALIAS as WString * 32 = WStr(".smartmath")
dim shared SMARTMATH_SPECIALCHAR_FUNC as WString * 32 = WStr("SpecialChar::Main")

' Cached SpecialChar EOL/wrap marker width past line-end X (0 when SpecialChar off).
' Remeasured when the edit font or SpecialChar running state changes — not per line.
dim shared g_eolMarkerReserve as Integer = 0
dim shared g_eolMarkerReserveFont as HFONT = 0
dim shared g_eolMarkerReserveScRunning as BOOL = FALSE
dim shared g_eolMarkerReserveValid as BOOL = FALSE

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

' View-relative paint trackers: they describe the last editor we painted into
' (first visible line, caret line, H-scroll, client margin). Reset whenever the
' active frame/edit changes or SmartMath turns off for a document, otherwise
' comparisons against a previous document can skip redraws or mis-validate the
' result gutter.
private sub ResetEditOverlayTrackers()
  rcOldMargin.left = 0 : rcOldMargin.right = 0
  rcOldMargin.top = 0  : rcOldMargin.bottom = 0
  nOldFirstLine = -1
  nOldCaretLine = -1
  nOldHScrollPos = -1
  nLastNavSelStart = -1
  nLastNavSelEnd = -1
end sub

private sub SetSmartMathDocActiveState(byval hWndEdit as HWND, byval bActive as BOOL, byval bApplyTheme as BOOL = TRUE)
  if (hWndEdit = 0) orelse (IsWindow(hWndEdit) = FALSE) then
    g_hWndEdit = 0
    g_bSmartMathDocActive = FALSE
    ResetEditOverlayTrackers()
    exit sub
  end if

  g_hWndEdit = hWndEdit
  g_bSmartMathDocActive = bActive
  InvalidateRenderCache()
  ' Always drop previous-view trackers: activate and deactivate both change which
  ' document (or none) the next key/scroll event belongs to. PMDI can keep the
  ' same EditHwnd across frames, so HWND alone is not enough to keep them.
  ResetEditOverlayTrackers()

  if bActive then
    EnsureActiveLineOptionApplied(FindCurrentFrameItem())
    if (bApplyTheme <> FALSE) andalso Config_GetSyntaxHighlight() then
      TryApplySmartMathCoderTheme()
    end if
    dim bVisible as BOOL
    UpdateInternalState(hWndEdit, bVisible)
    InvalidateRect(hWndEdit, 0, TRUE)
  else
    RestoreAkelOptionsOfOwnerFrame()
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

declare function FindInActiveSmartMathFrameFiles(frameFiles() as WStringPtr, byval wszFile as WString ptr) as Integer

private sub RefreshSmartMathDocMode(byval hWndEdit as HWND, byval bJustOpened as Boolean = FALSE)
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
    ResetEditOverlayTrackers()
    exit sub
  end if
  if IsWindow(hWndEditCurrent) = FALSE then
    g_bSmartMathDocActive = FALSE
    g_hWndEdit = 0
    ResetEditOverlayTrackers()
    exit sub
  end if

  dim idx as Integer = g_framesWithSmartMathEnabled.Find(pFrameCurrent)
  if (idx < 0) andalso bJustOpened andalso (pFrameCurrent <> 0) then
    if FindInActiveSmartMathFrameFiles(g_frameFiles(), pFrameCurrent->ei.wszFile) >= 0 then
      dim pFrameItem as FrameItem ptr = New FrameItem(pFrameCurrent)
      if pFrameItem <> 0 then
        g_framesWithSmartMathEnabled.Append(pFrameItem)
        idx = g_framesWithSmartMathEnabled.Find(pFrameCurrent)
      end if
    end if
  end if
  if idx >= 0 then
    dim pFrameItem as FrameItem ptr = cast(FrameItem ptr, g_framesWithSmartMathEnabled[idx])
    if pFrameItem <> 0 then
      pFrameItem->isWorking = TRUE
    end if
  end if
  SetSmartMathDocActiveState(hWndEditCurrent, idx >= 0, TRUE)
  UpdateMenuActiveOnCurrTab(idx >= 0)
end sub

private sub SaveActiveSmartMathFrames()
  dim nTotalChars as Integer = 0
  dim nFiles as Integer = 0

  for i as Integer = 0 to g_framesWithSmartMathEnabled.Count() - 1
    dim pFrameItem as FrameItem ptr = cast(FrameItem ptr, g_framesWithSmartMathEnabled[i])
    if pFrameItem <> 0 andalso pFrameItem->wszFile <> 0 then
      dim nFileChars as Integer = Len(*(pFrameItem->wszFile))
      if nFileChars > 0 then
        if nFiles > 0 then nTotalChars += 1
        nTotalChars += nFileChars
        nFiles += 1
      end if
    end if
  next i

  ' LogInfo("SaveActiveSmartMathFrames: nTotalChars=" & nTotalChars & ", nFiles=" & nFiles)

  redim wszActiveFrameFiles(0 to nTotalChars) as UShort
  dim nPos as Integer = 0
  dim nWrittenFiles as Integer = 0

  for i as Integer = 0 to g_framesWithSmartMathEnabled.Count() - 1
    dim pFrameItem as FrameItem ptr = cast(FrameItem ptr, g_framesWithSmartMathEnabled[i])
    if pFrameItem <> 0 andalso pFrameItem->wszFile <> 0 then
      dim nFileChars as Integer = Len(*(pFrameItem->wszFile))
      if nFileChars > 0 then
        if nWrittenFiles > 0 then
          wszActiveFrameFiles(nPos) = ACTIVE_FRAME_FILE_SEPARATOR
          nPos += 1
        end if

        dim pSrc as UShort ptr = cast(UShort ptr, pFrameItem->wszFile)
        for j as Integer = 0 to nFileChars - 1
          wszActiveFrameFiles(nPos) = pSrc[j]
          nPos += 1
        next j

        nWrittenFiles += 1
      end if
    end if
  next i
  wszActiveFrameFiles(nPos) = 0

  SaveSettings_ActiveFrames(wszActiveFrameFiles(), nPos)
end sub

private function ActiveSmartMathFrameFilesCount(frameFiles() as WStringPtr) as Integer
  dim nLo as Integer = LBound(frameFiles)
  dim nHi as Integer = UBound(frameFiles)
  if nHi < nLo then return 0
  return nHi - nLo + 1
end function

private function FindInActiveSmartMathFrameFiles(frameFiles() as WStringPtr, byval wszFile as WString ptr) as Integer
  if wszFile = 0 then return -1

  dim nLo as Integer = LBound(frameFiles)
  dim nHi as Integer = UBound(frameFiles)
  if nHi < nLo then return -1

  for i as Integer = nLo to nHi
    if frameFiles(i) <> 0 then
      if *(frameFiles(i)) = *wszFile then return i
    end if
  next i

  return -1
end function

private sub FreeActiveSmartMathFrameFiles(frameFiles() as WStringPtr)
  dim nLo as Integer = LBound(frameFiles)
  dim nHi as Integer = UBound(frameFiles)
  if nHi >= nLo then
    for i as Integer = nLo to nHi
      if frameFiles(i) <> 0 then
        Deallocate(frameFiles(i))
        frameFiles(i) = 0
      end if
    next i
  end if

  erase frameFiles
end sub

private sub ResetActiveSmartMathFrameFiles()
  FreeActiveSmartMathFrameFiles(g_frameFiles())
end sub

private function LoadActiveSmartMathFrameFiles(frameFiles() as WStringPtr) as Integer
  FreeActiveSmartMathFrameFiles(frameFiles())

  dim wszActiveFrameFiles() as UShort
  dim nCharsRead as Integer = LoadSettings_ActiveFrames(wszActiveFrameFiles())
  if nCharsRead <= 0 then return 0

  dim nSegments as Integer = 0
  dim nSegmentChars as Integer = 0

  for i as Integer = 0 to nCharsRead - 1
    if wszActiveFrameFiles(i) = ACTIVE_FRAME_FILE_SEPARATOR then
      if nSegmentChars > 0 then nSegments += 1
      nSegmentChars = 0
    else
      nSegmentChars += 1
    end if
  next i
  if nSegmentChars > 0 then nSegments += 1

  if nSegments = 0 then return 0

  redim frameFiles(0 to nSegments - 1)
  for i as Integer = 0 to nSegments - 1
    frameFiles(i) = 0
  next i

  dim nItems as Integer = 0
  dim nSegmentStart as Integer = 0
  nSegmentChars = 0

  for i as Integer = 0 to nCharsRead
    if (i = nCharsRead) orelse (wszActiveFrameFiles(i) = ACTIVE_FRAME_FILE_SEPARATOR) then
      if nSegmentChars > 0 then
        dim pFile as WString ptr = cast(WString ptr, Allocate((nSegmentChars + 1) * SizeOf(WString)))
        if pFile <> 0 then
          dim pDst as UShort ptr = cast(UShort ptr, pFile)
          for j as Integer = 0 to nSegmentChars - 1
            pDst[j] = wszActiveFrameFiles(nSegmentStart + j)
          next j
          pDst[nSegmentChars] = 0
        end if

        if nItems <= UBound(frameFiles) then
          frameFiles(nItems) = pFile
          nItems += 1
        elseif pFile <> 0 then
          Deallocate(pFile)
        end if
      end if

      nSegmentStart = i + 1
      nSegmentChars = 0
    else
      nSegmentChars += 1
    end if
  next i

  return ActiveSmartMathFrameFilesCount(frameFiles())
end function

private sub ActivateSmartMathFiles()
  dim nFrameFiles as Integer = LoadActiveSmartMathFrameFiles(g_frameFiles())
  if nFrameFiles > 0 then
    dim pStartFrame as FRAMEDATA ptr = cast(FRAMEDATA ptr, SendMessage(g_hMainWnd, AKD_FRAMEFINDW, FWF_CURRENT, 0))
    dim pFrame as FRAMEDATA ptr = pStartFrame
    while pFrame <> 0
      if FindInActiveSmartMathFrameFiles(g_frameFiles(), pFrame->ei.wszFile) >= 0 andalso _
         g_framesWithSmartMathEnabled.Find(pFrame) < 0 then
        dim pFrameItem as FrameItem ptr = New FrameItem(pFrame)
        if pFrameItem <> 0 then
          g_framesWithSmartMathEnabled.Append(pFrameItem)
        end if
      end if

      pFrame = cast(FRAMEDATA ptr, SendMessage(g_hMainWnd, AKD_FRAMEFINDW, FWF_PREV, cast(LPARAM, pFrame)))
      if pFrame = pStartFrame then exit while
    wend

    dim hWndEditCurrent as HWND = GetWndEdit(g_hMainWnd)
    if hWndEditCurrent <> 0 then
      g_lastDocModeFrame = 0
      RefreshSmartMathDocMode(hWndEditCurrent)
    end if
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
    dim nDirtyFromLine as Integer = nChangedLine
    if pChange->crSel.ciMin.nLine >= 0 then
      if nDirtyFromLine < 0 orelse pChange->crSel.ciMin.nLine < nDirtyFromLine then
        nDirtyFromLine = pChange->crSel.ciMin.nLine
      end if
    end if
    MarkRenderCacheDocumentDirty(nDirtyFromLine)
    ' Dependent lines below can change results; lines above stay valid.
    dim hWndEdit as HWND = pHdr->hwndFrom
    if (hWndEdit = 0) orelse (IsWindow(hWndEdit) = FALSE) then hWndEdit = g_hWndEdit
    if (hWndEdit <> 0) andalso (IsWindow(hWndEdit) <> 0) andalso g_bSmartMathDocActive then
      InvalidateAfterContentEdit(hWndEdit, nDirtyFromLine, FALSE)
    end if
    exit sub
  end if

  'if pHdr->code = AEN_TEXTINSERTEND then
  '  dim pIns as AENTEXTINSERT ptr = cast(AENTEXTINSERT ptr, lParam)
  '  ' LogInfo("AEN_TEXTINSERTEND: ciMin.nLine=" & pIns->crAkelRange.ciMin.nLine)
  '  exit sub
  'end if
end sub

' After hooks are live: sync doc mode, margins, AkelEdit options.
private sub SyncSmartMathActiveEditorState(byval hWndEdit as HWND)
  ' LogInfo("SyncSmartMathActiveEditorState: entering, hWndEdit=" & hWndEdit)
  if (hWndEdit = 0) orelse (IsWindow(hWndEdit) = FALSE) then exit sub
  g_hWndEdit = hWndEdit
  RefreshSmartMathDocMode(hWndEdit)
  dim bInitialVis as BOOL
  UpdateInternalState(hWndEdit, bInitialVis)
  InvalidateRect(hWndEdit, 0, TRUE)
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

private function RawCartesianScalarToString(byref scalar as RawCartesianScalar) as String
  dim s as String = "kind=" & ltrim(str(scalar.kind))
  select case scalar.kind
    case RSK_SMINT: s &= " int=" & ltrim(str(scalar.intValue))
    case RSK_SMUINT: s &= " uint=" & ltrim(str(scalar.uintValue))
    case RSK_SMFLOATING: s &= " float=" & ltrim(str(scalar.floatValue))
    case RSK_RATIONAL: s &= " ratio=" & ltrim(str(scalar.ratNum)) & "/" & ltrim(str(scalar.ratDen))
    case else: s &= " ..."
  end select
  return s
end function

private sub LogInfo_InputAndResult(byref sLine as String, byref sRes as String, byref raw as RawResult)
  dim rawDbg as String = "; "
  if RawScalarIsComplex(raw.scalar) then
    rawDbg &= "real: " & RawCartesianScalarToString(raw.scalar.real)
    rawDbg &= ", imag: " & RawCartesianScalarToString(raw.scalar.imag)
  else
    rawDbg &= "real: " & RawCartesianScalarToString(raw.scalar.real)
  end if
  LogInfo("`" & sLine & "` -> `" & sRes & "`" & rawDbg)
end sub

private sub BuildRenderedResultText(byref sLine as String, byref sRes as String, byref bIsError as Boolean, byval lineIdx as Integer = -1)
  sRes = ""
  bIsError = FALSE
  if IsLikelyCodeLine(sLine) then exit sub

  if Config_GetLogParsedLines() then
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

  dim raw as RawResult

  if Parser_TryEvaluateExRaw(sLine, raw) then
    sRes = FormatRawEvaluationResult(raw)
    if Config_GetLogParsedLines() then
      LogInfo_InputAndResult(sLine, sRes, raw)
    end if
  else
    dim sErr as String = Parser_GetLastError()
    if len(sErr) > 0 then
      if Config_GetShowErrors() orelse Parser_IsFunctionHintError(sErr) then
        sRes = SMARTMATH_ERROR_PREFIX & sErr
        bIsError = TRUE
      end if
    end if
  end if

  if Config_GetLogParsedLines() then
    if lineIdx >= 0 then
      LogInfo("parse-line end [" & ltrim(str(lineIdx)) & "]")
    else
      LogInfo("parse-line end")
    end if
  end if
end sub

' AkelEdit word wrap: physical EM_ lines are wrap rows. Old RichEdit: treat as off.
private function IsWordWrapOn(byval hWnd as HWND) as BOOL
  if g_bOldRichEdit then return FALSE
  dim dwWrap as DWORD = cast(DWORD, SendMessage(hWnd, AEM_GETWORDWRAP, 0, 0))
  if (dwWrap and (AEWW_WORD or AEWW_SYMBOL)) <> 0 then return TRUE
  return FALSE
end function

' Soft-wrap group containing physical lineIdx: first..last share one unwrapped line.
' Pass nLineCount / bWrapOn when the caller already resolved them for the pass.
private sub GetSoftWrapGroupBoundsEx(byval hWnd as HWND, byval lineIdx as Integer, byref firstIdx as Integer, byref lastIdx as Integer, byval nLineCount as Integer, byval bWrapOn as BOOL)
  firstIdx = lineIdx
  lastIdx = lineIdx
  if lineIdx < 0 then exit sub
  if bWrapOn = FALSE then exit sub
  if lineIdx >= nLineCount then exit sub

  dim nUnwrap as Integer = cast(Integer, SendMessage(hWnd, AEM_GETUNWRAPLINE, lineIdx, 0))
  firstIdx = cast(Integer, SendMessage(hWnd, AEM_GETWRAPLINE, nUnwrap, 0))
  if firstIdx < 0 then firstIdx = lineIdx
  if firstIdx >= nLineCount then firstIdx = lineIdx

  lastIdx = firstIdx
  dim j as Integer
  for j = firstIdx + 1 to nLineCount - 1
    if cast(Integer, SendMessage(hWnd, AEM_GETUNWRAPLINE, j, 0)) <> nUnwrap then exit for
    lastIdx = j
  next j
end sub

private sub GetSoftWrapGroupBounds(byval hWnd as HWND, byval lineIdx as Integer, byref firstIdx as Integer, byref lastIdx as Integer)
  dim nLineCount as Integer = SendMessage(hWnd, EM_GETLINECOUNT, 0, 0)
  GetSoftWrapGroupBoundsEx(hWnd, lineIdx, firstIdx, lastIdx, nLineCount, IsWordWrapOn(hWnd))
end sub

private sub InvalidateEolMarkerReserve()
  g_eolMarkerReserveValid = FALSE
end sub

private function IsSpecialCharRunning() as BOOL
  if g_hMainWnd = 0 then return FALSE
  dim pf as PLUGINFUNCTION ptr = cast(PLUGINFUNCTION ptr, SendMessageW(g_hMainWnd, AKD_DLLFINDW, cast(WPARAM, strptr(SMARTMATH_SPECIALCHAR_FUNC)), 0))
  if pf = 0 orelse pf->bRunning = FALSE then return FALSE
  return TRUE
end function

' Pixels to leave after physical line-end X so SpecialChar's "rn"/wrap marker is not
' erased by the result-gutter FillRect. Cached; call once per paint pass.
private function EnsureEolMarkerReserve(byval hWnd as HWND, byval hDC as HDC = 0) as Integer
  dim hFont as HFONT = cast(HFONT, SendMessage(hWnd, WM_GETFONT, 0, 0))
  dim bScRunning as BOOL = IsSpecialCharRunning()

  if g_eolMarkerReserveValid andalso _
     (hFont = g_eolMarkerReserveFont) andalso _
     (bScRunning = g_eolMarkerReserveScRunning) then
    return g_eolMarkerReserve
  end if

  g_eolMarkerReserveFont = hFont
  g_eolMarkerReserveScRunning = bScRunning
  g_eolMarkerReserveValid = TRUE

  if bScRunning = FALSE then
    g_eolMarkerReserve = 0
    return 0
  end if

  dim nReserve as Integer = 0
  dim bOwnDC as BOOL = FALSE
  dim hMeasureDC as HDC = hDC
  if hMeasureDC = 0 then
    hMeasureDC = GetDC(hWnd)
    bOwnDC = TRUE
  end if

  if hMeasureDC <> 0 then
    dim hOldFont as HFONT
    if hFont then hOldFont = cast(HFONT, SelectObject(hMeasureDC, hFont))
    dim szRrn as SIZE
    dim szEof as SIZE
    GetTextExtentPoint32(hMeasureDC, strptr("rrn"), 3, @szRrn)
    GetTextExtentPoint32(hMeasureDC, strptr("eof"), 3, @szEof)
    nReserve = szRrn.cx
    if szEof.cx > nReserve then nReserve = szEof.cx
    ' SpecialChar: badge right ≈ endX + textExtent + 4 (margins + sel fill).
    nReserve += 4
    if hFont then SelectObject(hMeasureDC, hOldFont)
    if bOwnDC then ReleaseDC(hWnd, hMeasureDC)
  end if

  if not g_bOldRichEdit then
    dim nAve as Integer = cast(Integer, SendMessage(hWnd, AEM_GETCHARSIZE, AECS_AVEWIDTH, 0))
    if nAve > nReserve then nReserve = nAve
  end if

  g_eolMarkerReserve = nReserve
  return nReserve
end function

' Pixels after line-end X before the result gutter. SpecialChar reserve already
' includes its badge width — do not stack SMARTMATH_RESULT_GUTTER_GAP on top.
private function GetOverlayGutterPad(byval hWnd as HWND, byval hDC as HDC = 0) as Integer
  dim nReserve as Integer = EnsureEolMarkerReserve(hWnd, hDC)
  if nReserve > 0 then return nReserve
  return SMARTMATH_RESULT_GUTTER_GAP
end function

' Right-aligned result drawX and gutter minDrawX (shared by paint and dblclick hit-test).
private sub GetResultOverlayDrawX(byval nClientLeft as Integer, byval nClientRight as Integer, byval nLineEndX as Integer, byval nTextWidth as Integer, byval nGutterPad as Integer, byref outDrawX as Integer, byref outMinDrawX as Integer)
  outDrawX = nClientRight - nTextWidth - SMARTMATH_RESULT_RIGHT_MARGIN
  outMinDrawX = nLineEndX + nGutterPad
  if outMinDrawX < nClientLeft then outMinDrawX = nClientLeft
end sub

' Copy a range of frozen render strings from an old snapshot into g_cachedRenderText.
private sub CopyCachedRenderRange(byval firstIdx as Integer, byval lastIdx as Integer, byval oldCount as Integer, oldRenderText() as String)
  dim k as Integer
  for k = firstIdx to lastIdx
    if k < oldCount then
      g_cachedRenderText(k) = oldRenderText(k)
    else
      g_cachedRenderText(k) = ""
    end if
  next k
end sub

' Client position just past the last glyph of this physical wrap row (not the next row).
private function GetPhysicalLineEndClientPos(byval hWnd as HWND, byval lineIdx as Integer, byref outX as Integer, byref outY as Integer) as BOOL
  outX = -10001
  outY = -10001
  if lineIdx < 0 then return FALSE

  dim nLineStart as Integer = SendMessage(hWnd, EM_LINEINDEX, lineIdx, 0)
  if nLineStart < 0 then return FALSE
  dim nLineLen as Integer = SendMessage(hWnd, EM_LINELENGTH, nLineStart, 0)

  if g_bOldRichEdit = FALSE then
    dim ci as AECHARINDEX
    if SendMessage(hWnd, AEM_GETLINEINDEX, lineIdx, cast(LPARAM, @ci)) = 0 then return FALSE
    ci.nCharInLine = nLineLen
    dim pt as POINT
    pt.x = 0
    pt.y = 0
    SendMessage(hWnd, AEM_POSFROMCHAR, cast(WPARAM, @pt), cast(LPARAM, @ci))
    outX = pt.x
    outY = pt.y
    return TRUE
  end if

  if nLineLen <= 0 then
    dim resEmpty as LRESULT = SendMessage(hWnd, EM_POSFROMCHAR, nLineStart, 0)
    outX = cast(short, LoWord(resEmpty))
    outY = cast(short, HiWord(resEmpty))
    return TRUE
  end if

  dim resLast as LRESULT = SendMessage(hWnd, EM_POSFROMCHAR, nLineStart + nLineLen - 1, 0)
  outX = cast(short, LoWord(resLast))
  outY = cast(short, HiWord(resLast))
  dim sLine as String = GetLineText(hWnd, lineIdx, nLineLen)
  if Len(sLine) > 0 then
    dim hDC as HDC = GetDC(hWnd)
    if hDC <> 0 then
      dim hFont as HFONT = cast(HFONT, SendMessage(hWnd, WM_GETFONT, 0, 0))
      dim hOldFont as HFONT
      if hFont then hOldFont = cast(HFONT, SelectObject(hDC, hFont))
      dim sz as SIZE
      GetTextExtentPoint32(hDC, strptr(sLine) + (Len(sLine) - 1), 1, @sz)
      if hFont then SelectObject(hDC, hOldFont)
      ReleaseDC(hWnd, hDC)
      outX += sz.cx
    end if
  end if
  return TRUE
end function

private sub EnsureRenderCache(byval hWnd as HWND)
  dim nLineCount as Integer = SendMessage(hWnd, EM_GETLINECOUNT, 0, 0)
  if nLineCount <= 0 then
    g_cacheLineCount = 0
    erase g_cachedLineText
    erase g_cachedRenderText
    g_cacheReady = TRUE
    g_cacheSyncedGeneration = g_cacheDocGeneration
    g_cacheDirtyFromLine = -1
    exit sub
  end if

  if IsRenderCacheSyncedWithDocument(hWnd) then exit sub
  ' Held-key capped rebuild already applied for this document generation: keep
  ' deferred dirty-from-line and wait for key-up (or a new dirty mark).
  if g_bContentKeyDown andalso (g_cacheDirtyFromLine >= 0) _
     andalso IsRenderCacheDocumentCurrent(hWnd) then
    exit sub
  end if

  dim needsFullRebuild as BOOL = (g_cacheReady = FALSE) orelse (nLineCount <> g_cacheLineCount)
  dim firstChanged as Integer = -1
  dim minCount as Integer = IIf(nLineCount < g_cacheLineCount, nLineCount, g_cacheLineCount)
  dim bWrapOn as BOOL = IsWordWrapOn(hWnd)

  ' One pass: fetch every physical line once; discover firstChanged while scanning.
  dim scanFrom as Integer = 0
  if needsFullRebuild = FALSE then
    if g_cacheDirtyFromLine >= 0 and g_cacheDirtyFromLine < nLineCount then
      scanFrom = g_cacheDirtyFromLine
    end if
  end if

  redim currentLineText(0 to nLineCount - 1) as String
  dim i as Integer
  for i = 0 to nLineCount - 1
    dim nLineIndex as Integer = SendMessage(hWnd, EM_LINEINDEX, i, 0)
    dim nLineLen as Integer = SendMessage(hWnd, EM_LINELENGTH, nLineIndex, 0)
    currentLineText(i) = GetLineText(hWnd, i, nLineLen)
    if needsFullRebuild = FALSE andalso firstChanged < 0 andalso i >= scanFrom then
      if currentLineText(i) <> g_cachedLineText(i) then
        firstChanged = i
      end if
    end if
  next i

  if needsFullRebuild = FALSE then
    ' dirty-from-line: results from this line down are untrustworthy even when
    ' line text is unchanged (e.g. after a held-key capped rebuild).
    if g_cacheDirtyFromLine >= 0 then
      dim nDirty as Integer = g_cacheDirtyFromLine
      if nDirty >= nLineCount then nDirty = nLineCount - 1
      if nDirty < 0 then nDirty = 0
      if firstChanged < 0 orelse nDirty < firstChanged then
        firstChanged = nDirty
      end if
    elseif firstChanged < 0 then
      g_cacheSyncedGeneration = g_cacheDocGeneration
      g_cacheDirtyFromLine = -1
      exit sub
    end if
  end if

  if firstChanged < 0 then
    if g_cacheReady = FALSE then
      firstChanged = 0
    else
      firstChanged = minCount
    end if
  end if

  ' Soft-wrap: a change on any wrap row dirties the whole unwrapped line.
  if firstChanged >= 0 andalso firstChanged < nLineCount then
    dim fcFirst as Integer = firstChanged
    dim fcLast as Integer = firstChanged
    GetSoftWrapGroupBoundsEx(hWnd, firstChanged, fcFirst, fcLast, nLineCount, bWrapOn)
    firstChanged = fcFirst
  end if

  ' While a content key is held, only re-eval through the edited/caret line so
  ' key-repeat stays responsive. Leave dirty-from-line set for dependents.
  dim nEvalLast as Integer = nLineCount - 1
  dim bCappedEval as BOOL = FALSE
  if g_bContentKeyDown andalso (needsFullRebuild = FALSE) then
    dim nCaretEval as Integer = SendMessage(hWnd, EM_EXLINEFROMCHAR, 0, -1)
    nEvalLast = firstChanged
    if nCaretEval > nEvalLast then nEvalLast = nCaretEval
    if nEvalLast < 0 then nEvalLast = 0
    if nEvalLast >= nLineCount then nEvalLast = nLineCount - 1
    dim capFirst as Integer = nEvalLast
    dim capLast as Integer = nEvalLast
    GetSoftWrapGroupBoundsEx(hWnd, nEvalLast, capFirst, capLast, nLineCount, bWrapOn)
    nEvalLast = capLast
    bCappedEval = (nEvalLast < nLineCount - 1)
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
  Parser_SetSupportComplexNumbers(Config_GetSupportComplexNumbers())

  ' Evaluate one unwrapped logical line per soft-wrap group; store the result on
  ' the last physical row only so overlay paint never targets a wrap head.
  dim iGroup as Integer = 0
  do while iGroup < nLineCount
    dim groupFirst as Integer = iGroup
    dim groupLast as Integer = iGroup
    GetSoftWrapGroupBoundsEx(hWnd, iGroup, groupFirst, groupLast, nLineCount, bWrapOn)

    if groupFirst > nEvalLast then
      CopyCachedRenderRange(groupFirst, groupLast, oldCount, oldRenderText())
      iGroup = groupLast + 1
      continue do
    end if

    dim sLogical as String = ""
    dim k as Integer
    for k = groupFirst to groupLast
      sLogical &= g_cachedLineText(k)
    next k

    dim bGroupUnchanged as BOOL = TRUE
    if (groupLast >= firstChanged) orelse (g_cacheReady = FALSE) then
      bGroupUnchanged = FALSE
    else
      for k = groupFirst to groupLast
        if (k >= oldCount) orelse (g_cachedLineText(k) <> oldLineText(k)) then
          bGroupUnchanged = FALSE
          exit for
        end if
      next k
    end if

    ' Always evaluate through nEvalLast so assignments/UDFs replay into the
    ' parser after Parser_ClearVariables. Unchanged groups above firstChanged
    ' keep frozen display text (and restore ans for volatile pure lines).
    dim sRes as String = ""
    dim bIsError as Boolean = FALSE
    BuildRenderedResultText(sLogical, sRes, bIsError, groupFirst)

    if bGroupUnchanged andalso g_cacheReady then
      CopyCachedRenderRange(groupFirst, groupLast, oldCount, oldRenderText())
      if IsVolatilePureExpressionLine(sLogical) then
        RestoreAnsFromCachedRender(g_cachedRenderText(groupLast))
      end if
    else
      for k = groupFirst to groupLast - 1
        g_cachedRenderText(k) = ""
      next k
      g_cachedRenderText(groupLast) = sRes
    end if

    iGroup = groupLast + 1
  loop

  g_cacheReady = TRUE
  g_cacheSyncedGeneration = g_cacheDocGeneration
  if bCappedEval then
    ' Texts/results through nEvalLast are current; dependents below are not.
    g_cacheDirtyFromLine = firstChanged
  else
    g_cacheDirtyFromLine = -1
  end if
end sub

function BuildLineRenderText(byval hWnd as HWND, byval lineIdx as Integer) as String
  EnsureRenderCache(hWnd)
  if lineIdx < 0 orelse lineIdx >= g_cacheLineCount then return ""
  dim firstIdx as Integer = lineIdx
  dim lastIdx as Integer = lineIdx
  GetSoftWrapGroupBounds(hWnd, lineIdx, firstIdx, lastIdx)
  if lastIdx < 0 orelse lastIdx >= g_cacheLineCount then return ""
  return g_cachedRenderText(lastIdx)
end function

function BuildResultTextForLine(byval hWnd as HWND, byval targetLine as Integer) as String
  dim nLineCount as Integer = SendMessage(hWnd, EM_GETLINECOUNT, 0, 0)
  if targetLine < 0 orelse targetLine >= nLineCount then return ""
  return BuildLineRenderText(hWnd, targetLine)
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
sub UpdateInternalState(byval hWnd as HWND, byref bVisible as BOOL)
  if g_bShuttingDown orelse (g_bSmartMathDocActive = FALSE) then
    bVisible = FALSE
    exit sub
  end if

  bVisible = FALSE

  if IsRenderCacheSyncedWithDocument(hWnd) = FALSE then
    EnsureRenderCache(hWnd)
  end if

  if g_cacheLineCount > 0 then
    bVisible = TRUE
  end if
end sub

' Client-area strip for one edit line (full width). Soft-wrap groups span all wrap rows.
private function GetEditCharHeight(byval hWnd as HWND) as Integer
  dim nCharHeight as Integer = 0
  if not g_bOldRichEdit then
    nCharHeight = SendMessage(hWnd, AEM_GETCHARSIZE, 0, 0)
  end if
  if nCharHeight <= 0 then
    dim hDC as HDC = GetDC(hWnd)
    if hDC <> 0 then
      dim tm as TEXTMETRIC
      GetTextMetrics(hDC, @tm)
      nCharHeight = tm.tmHeight
      ReleaseDC(hWnd, hDC)
    end if
  end if
  if nCharHeight <= 0 then nCharHeight = 16
  return nCharHeight
end function

private function GetEditLineClientRect(byval hWnd as HWND, byval lineIdx as Integer, byref rcOut as RECT) as BOOL
  if lineIdx < 0 then return FALSE

  dim rcClient as RECT
  GetClientRect(hWnd, @rcClient)

  dim firstIdx as Integer = lineIdx
  dim lastIdx as Integer = lineIdx
  GetSoftWrapGroupBounds(hWnd, lineIdx, firstIdx, lastIdx)

  dim nFirstStart as Integer = SendMessage(hWnd, EM_LINEINDEX, firstIdx, 0)
  if nFirstStart < 0 then return FALSE

  dim ptTopY as Integer = -10001
  dim ptBotY as Integer = -10001
  if g_bOldRichEdit then
    dim res as LRESULT = SendMessage(hWnd, EM_POSFROMCHAR, nFirstStart, 0)
    ptTopY = cast(short, HiWord(res))
  else
    dim pt as POINT
    SendMessage(hWnd, EM_POSFROMCHAR, cast(WPARAM, @pt), nFirstStart)
    ptTopY = pt.y
  end if
  if ptTopY < -10000 then return FALSE

  dim nCharHeight as Integer = GetEditCharHeight(hWnd)
  dim endX as Integer = 0
  if GetPhysicalLineEndClientPos(hWnd, lastIdx, endX, ptBotY) = FALSE orelse ptBotY < -10000 then
    ptBotY = ptTopY
  end if

  rcOut.left = rcClient.left
  rcOut.right = rcClient.right
  rcOut.top = ptTopY
  rcOut.bottom = ptBotY + nCharHeight
  return TRUE
end function

private sub InvalidateEditLine(byval hWnd as HWND, byval lineIdx as Integer)
  dim rcLine as RECT
  if GetEditLineClientRect(hWnd, lineIdx, rcLine) then
    InvalidateRect(hWnd, @rcLine, TRUE)
  end if
end sub

' Content edits only affect the changed line and dependents below it. Invalidate
' from that line's top through the bottom of the client (leave lines above alone).
private sub InvalidateEditFromLineDown(byval hWnd as HWND, byval lineIdx as Integer)
  dim rcClient as RECT
  GetClientRect(hWnd, @rcClient)
  if lineIdx < 0 then
    InvalidateRect(hWnd, @rcClient, TRUE)
    exit sub
  end if

  dim rcLine as RECT
  if GetEditLineClientRect(hWnd, lineIdx, rcLine) = FALSE then
    InvalidateRect(hWnd, @rcClient, TRUE)
    exit sub
  end if

  dim rcInv as RECT = rcClient
  rcInv.top = rcLine.top
  if rcInv.top < rcClient.top then rcInv.top = rcClient.top
  if rcInv.top >= rcClient.bottom then exit sub
  InvalidateRect(hWnd, @rcInv, TRUE)
end sub

' While a content key is held, only the edited line; otherwise from-line-down.
private sub InvalidateAfterContentEdit(byval hWnd as HWND, byval lineIdx as Integer, byval bSyncPaint as BOOL)
  if g_bContentKeyDown then
    InvalidateEditLine(hWnd, lineIdx)
    if bSyncPaint then UpdateWindow(hWnd)
  else
    InvalidateEditFromLineDown(hWnd, lineIdx)
  end if
end sub

' Client x where the result gutter starts given a physical line-end X: past line
' text and any SpecialChar EOL marker.
private function GetResultGutterLeftFromEndX(byval hWnd as HWND, byval nLineEndX as Integer) as Integer
  dim rcClient as RECT
  GetClientRect(hWnd, @rcClient)
  dim nGutterLeft as Integer = nLineEndX + GetOverlayGutterPad(hWnd)
  if nGutterLeft < rcClient.left then nGutterLeft = rcClient.left
  return nGutterLeft
end function

' A caret-only move makes AkelEdit invalidate the whole caret line so it can
' repaint the caret and selection. That erases the result overlay, which we then
' redraw from WM_PAINT - visible as blinking while an arrow key auto-repeats.
' The gutter pixels are already correct here, so drop them from the pending
' update region and let the control repaint the text part alone.
private sub ValidateResultGutterForLine(byval hWnd as HWND, byval lineIdx as Integer)
  if g_bOldRichEdit then exit sub
  if IsRenderCacheSyncedWithDocument(hWnd) = FALSE then exit sub

  ' The active column is a full-height line that follows the caret and can be
  ' drawn across the gutter, so leave that repaint untouched.
  dim dwOptions as DWORD = SendMessage(hWnd, AEM_GETOPTIONS, 0, 0)
  if (dwOptions and AECO_ACTIVECOLUMN) then exit sub

  ' Result overlay lives on the last soft-wrap row of the logical line.
  dim firstIdx as Integer = lineIdx
  dim lastIdx as Integer = lineIdx
  GetSoftWrapGroupBounds(hWnd, lineIdx, firstIdx, lastIdx)

  dim rcClient as RECT
  GetClientRect(hWnd, @rcClient)
  dim endX as Integer = 0
  dim endY as Integer = 0
  if GetPhysicalLineEndClientPos(hWnd, lastIdx, endX, endY) = FALSE then exit sub

  dim nCharHeight as Integer = GetEditCharHeight(hWnd)
  dim rcLine as RECT
  rcLine.left = GetResultGutterLeftFromEndX(hWnd, endX)
  rcLine.right = rcClient.right
  rcLine.top = endY
  rcLine.bottom = endY + nCharHeight
  if rcLine.left >= rcLine.right then exit sub

  ValidateRect(hWnd, @rcLine)
end sub

' Newly exposed client strip after a vertical scroll of (nNewFirst - nOldFirst) lines.
private function BuildScrollExposedRect(byval hWnd as HWND, byval nOldFirst as Integer, byval nNewFirst as Integer, byref rcOut as RECT) as BOOL
  if nOldFirst = nNewFirst then return FALSE

  dim rcClient as RECT
  GetClientRect(hWnd, @rcClient)
  dim nCharHeight as Integer = GetEditCharHeight(hWnd)
  dim delta as Integer = nNewFirst - nOldFirst
  dim nLines as Integer = abs(delta)
  dim nStrip as Integer = nLines * nCharHeight
  if nStrip > (rcClient.bottom - rcClient.top) then nStrip = rcClient.bottom - rcClient.top
  if nStrip <= 0 then return FALSE

  rcOut.left = rcClient.left
  rcOut.right = rcClient.right
  if delta > 0 then
    ' Content moved up: new lines appear at the bottom.
    rcOut.bottom = rcClient.bottom
    rcOut.top = rcClient.bottom - nStrip
  else
    ' Content moved down: new lines appear at the top.
    rcOut.top = rcClient.top
    rcOut.bottom = rcClient.top + nStrip
  end if
  return TRUE
end function

declare sub DrawDynamicMathResults(byval hWnd as HWND, byval prcClip as RECT ptr = 0, byval bContentUnchanged as BOOL = FALSE)

' Union line strips and/or the scroll-exposed edge, then draw overlays immediately
' (key-repeat starves WM_PAINT, so InvalidateRect alone leaves blank result areas).
private sub DrawMathResultsForScroll(byval hWnd as HWND, byval nOldFirst as Integer, byval nNewFirst as Integer, byval nOldCaret as Integer, byval nNewCaret as Integer)
  dim rcClip as RECT
  dim bHaveClip as BOOL = FALSE
  dim rcPart as RECT

  if BuildScrollExposedRect(hWnd, nOldFirst, nNewFirst, rcPart) then
    rcClip = rcPart
    bHaveClip = TRUE
  end if
  if (nOldCaret >= 0) andalso GetEditLineClientRect(hWnd, nOldCaret, rcPart) then
    if bHaveClip then
      UnionRect(@rcClip, @rcClip, @rcPart)
    else
      rcClip = rcPart
      bHaveClip = TRUE
    end if
  end if
  if (nNewCaret >= 0) andalso GetEditLineClientRect(hWnd, nNewCaret, rcPart) then
    if bHaveClip then
      UnionRect(@rcClip, @rcClip, @rcPart)
    else
      rcClip = rcPart
      bHaveClip = TRUE
    end if
  end if

  if bHaveClip then
    DrawDynamicMathResults(hWnd, @rcClip, TRUE)
  else
    DrawDynamicMathResults(hWnd, 0, TRUE)
  end if
end sub

' prcClip: when non-null, only paint result glyphs that intersect this rect
' (typically the WM_PAINT update region). Avoids transparent overdraw on
' lines the edit control did not erase.
' Before text, fill drawClip with the line background: word-select / dblclick
' paints often report a tall update region while only erasing the clicked line,
' which would otherwise stack transparent glyphs on lines below.
' Client x of AkelEdit's column marker (the character-limit vertical line), or -1
' when there is no marker or it is scrolled out of the edit area. Mirrors
' AE_ColumnMarkerDraw so the overlay puts the line back exactly where AkelEdit
' painted it.
private function GetColumnMarkerClientX(byval hWnd as HWND) as Integer
  if g_bOldRichEdit then return -1

  dim dwMarkerType as DWORD = 0
  dim nMarkerPos as INT_PTR = SendMessage(hWnd, AEM_GETMARKER, cast(WPARAM, @dwMarkerType), 0)
  if nMarkerPos <= 0 then return -1

  if dwMarkerType = AEMT_SYMBOL then
    dim nAveCharWidth as INT_PTR = SendMessage(hWnd, AEM_GETCHARSIZE, AECS_AVEWIDTH, 0)
    if nAveCharWidth <= 0 then return -1
    nMarkerPos *= nAveCharWidth
  end if

  dim rcDraw as RECT
  SendMessage(hWnd, AEM_GETRECT, 0, cast(LPARAM, @rcDraw))

  dim ptScrollPos as POINT64
  SendMessage(hWnd, AEM_GETSCROLLPOS, 0, cast(LPARAM, @ptScrollPos))

  if nMarkerPos <= ptScrollPos.x then return -1
  if nMarkerPos >= ptScrollPos.x + (rcDraw.right - rcDraw.left) then return -1

  return rcDraw.left + cast(Integer, nMarkerPos - ptScrollPos.x)
end function

' Re-stroke the column marker over a rectangle the overlay has just erased.
private sub RepaintColumnMarkerInRect(byval hDC as HDC, byval hPen as HPEN, byval nMarkerX as Integer, byref rc as RECT)
  if hPen = 0 then exit sub
  if nMarkerX < rc.left orelse nMarkerX >= rc.right then exit sub

  dim hOldPen as HPEN = cast(HPEN, SelectObject(hDC, hPen))
  MoveToEx(hDC, nMarkerX, rc.top, 0)
  LineTo(hDC, nMarkerX, rc.bottom)
  SelectObject(hDC, hOldPen)
end sub

' Fill the overlay gutter (clipped) and restore the column marker. FALSE = no
' intersection with prcClip / nothing drawn.
private function ClearOverlayGutterRect(byval hDC as HDC, byref clearRect as RECT, byval prcClip as RECT ptr, byval hFill as HBRUSH, byval hMarkerPen as HPEN, byval nMarkerX as Integer) as BOOL
  dim drawClip as RECT = clearRect
  if prcClip <> 0 then
    if IntersectRect(@drawClip, @clearRect, prcClip) = 0 then return FALSE
  end if
  if hFill <> 0 then FillRect(hDC, @drawClip, hFill)
  RepaintColumnMarkerInRect(hDC, hMarkerPen, nMarkerX, drawClip)
  return TRUE
end function

sub DrawDynamicMathResults(byval hWnd as HWND, byval prcClip as RECT ptr = 0, byval bContentUnchanged as BOOL = FALSE)
  if g_bShuttingDown then exit sub
  if g_bSmartMathDocActive = FALSE then exit sub
  if (prcClip <> 0) andalso (IsRectEmpty(prcClip) <> 0) then exit sub

  if bContentUnchanged = FALSE orelse IsRenderCacheSyncedWithDocument(hWnd) = FALSE then
    EnsureRenderCache(hWnd)
  end if

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

  dim nCharHeight as Integer = GetEditCharHeight(hWnd)
  dim crResult as COLORREF = Config_GetResultColor()
  dim nErrPrefixLen as Integer = Len(SMARTMATH_ERROR_PREFIX)

  dim crBk as COLORREF = GetSysColor(COLOR_WINDOW)
  dim crActiveBk as COLORREF = crBk
  dim crColumnMarker as COLORREF = crBk
  dim bUseActiveLineBk as BOOL = FALSE
  dim hBrushBk as HBRUSH = 0
  dim hBrushActive as HBRUSH = 0
  if not g_bOldRichEdit then
    dim aec as AECOLORS
    aec.dwFlags = AECLR_BASICBK or AECLR_ACTIVELINEBK or AECLR_COLUMNMARKER
    SendMessage(hWnd, AEM_GETCOLORS, 0, cast(LPARAM, @aec))
    crBk = aec.crBasicBk
    crActiveBk = aec.crActiveLineBk
    crColumnMarker = aec.crColumnMarker
    dim dwOptions as DWORD = SendMessage(hWnd, AEM_GETOPTIONS, 0, 0)
    if (dwOptions and AECO_ACTIVELINE) then bUseActiveLineBk = TRUE
  end if
  hBrushBk = CreateSolidBrush(crBk)
  if bUseActiveLineBk then hBrushActive = CreateSolidBrush(crActiveBk)

  ' The control paints its column marker before the overlay runs, so every
  ' gutter rectangle we erase below has to get the marker segment back.
  dim nMarkerX as Integer = GetColumnMarkerClientX(hWnd)
  dim hMarkerPen as HPEN = 0
  if nMarkerX >= 0 then hMarkerPen = CreatePen(PS_SOLID, 1, crColumnMarker)

  SetBkMode(hDC, TRANSPARENT)

  ' Once per paint: SpecialChar badge width, or the normal gutter gap if off.
  dim nGutterPad as Integer = GetOverlayGutterPad(hWnd, hDC)

  dim i as Integer
  for i = nFirstVisible to nLineCount - 1
    dim ptClient_x as Integer = -10001
    dim ptClient_y as Integer = -10001

    if GetPhysicalLineEndClientPos(hWnd, i, ptClient_x, ptClient_y) = FALSE then
      continue for
    end if

    if ptClient_y > rcClient.bottom then exit for
    if prcClip <> 0 then
      ' Below the clip: no further visible lines.
      if ptClient_y >= prcClip->bottom then exit for
      ' Above the clip: skip until the line intersects.
      if ptClient_y + nCharHeight <= prcClip->top then
        continue for
      end if
    end if

    dim sRes as String = ""
    if i >= 0 andalso i < g_cacheLineCount then sRes = g_cachedRenderText(i)
    dim bIsError as Boolean = (left(sRes, nErrPrefixLen) = SMARTMATH_ERROR_PREFIX)

    if len(sRes) > 0 then
      if ptClient_y > -10000 then
        dim sz as SIZE
        GetTextExtentPoint32(hDC, strptr(sRes), Len(sRes), @sz)

        dim lineRect as RECT
        lineRect.left = rcClient.left
        lineRect.right = rcClient.right
        lineRect.top = ptClient_y
        lineRect.bottom = ptClient_y + nCharHeight

        if bIsError then
          SetTextColor(hDC, &H0000FF)
        else
          SetTextColor(hDC, crResult)
        end if
        dim drawX as Integer = 0
        dim minDrawX as Integer = 0
        GetResultOverlayDrawX(rcClient.left, rcClient.right, ptClient_x, sz.cx, nGutterPad, drawX, minDrawX)
        ' Match AkelEdit: source glyphs sit at POSFROMCHAR Y (line top). Centering
        ' within AEM_GETCHARSIZE height leaves a visible gap above the result.
        dim drawY as Integer = lineRect.top
        if minDrawX < rcClient.right then
          ' Clear the full result gutter (after source text to client right), not
          ' only the new string width. Otherwise a shorter/recalculated result is
          ' drawn over leftover glyphs from the previous overlay (e.g. after paste
          ' that reshuffles rand/UDF-dependent lines).
          dim clearRect as RECT
          clearRect.left = minDrawX
          clearRect.top = lineRect.top
          clearRect.right = rcClient.right
          clearRect.bottom = lineRect.bottom
          ' Match AkelEdit: active-line bk only on the caret's physical wrap row,
          ' not on the result row when the caret is on another wrap segment.
          dim hFill as HBRUSH = hBrushBk
          if bUseActiveLineBk andalso (i = nCaretLine) andalso (hBrushActive <> 0) then
            hFill = hBrushActive
          end if
          if ClearOverlayGutterRect(hDC, clearRect, prcClip, hFill, hMarkerPen, nMarkerX) = FALSE then
            continue for
          end if
          dim clipRect as RECT
          clipRect.left = IIf(drawX > minDrawX, drawX, minDrawX)
          clipRect.top = lineRect.top
          clipRect.right = rcClient.right
          clipRect.bottom = lineRect.bottom
          dim textClip as RECT = clipRect
          if prcClip <> 0 then
            if IntersectRect(@textClip, @clipRect, prcClip) = 0 then continue for
          end if
          ExtTextOut(hDC, drawX, drawY, ETO_CLIPPED, @textClip, strptr(sRes), Len(sRes), 0)
        end if
      end if
    elseif ptClient_y > -10000 andalso (bContentUnchanged = FALSE) then
      ' Content changed but this line has no result now: still erase any old overlay.
      dim minClearX as Integer = ptClient_x + nGutterPad
      if minClearX < rcClient.left then minClearX = rcClient.left
      if minClearX < rcClient.right andalso ptClient_x > -10000 then
        dim clearEmpty as RECT
        clearEmpty.left = minClearX
        clearEmpty.top = ptClient_y
        clearEmpty.right = rcClient.right
        clearEmpty.bottom = ptClient_y + nCharHeight
        dim hFillEmpty as HBRUSH = hBrushBk
        if bUseActiveLineBk andalso (i = nCaretLine) andalso (hBrushActive <> 0) then
          hFillEmpty = hBrushActive
        end if
        if ClearOverlayGutterRect(hDC, clearEmpty, prcClip, hFillEmpty, hMarkerPen, nMarkerX) = FALSE then
          continue for
        end if
      end if
    end if
  next i

  if hMarkerPen then DeleteObject(hMarkerPen)
  if hBrushActive then DeleteObject(hBrushActive)
  if hBrushBk then DeleteObject(hBrushBk)
  if hFont then SelectObject(hDC, hOldFont)
  ReleaseDC(hWnd, hDC)
end sub

declare function EditGlobalProc stdcall(byval hWnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM) as LRESULT
declare function MainGlobalProc stdcall(byval hWnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM) as LRESULT
declare function FrameGlobalProc stdcall(byval hWnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM) as LRESULT

private sub SetSmartMathProcData(byval pd as PLUGINDATA ptr)
  SendMessage(pd->hMainWnd, AKD_SETEDITPROC, cast(WPARAM, @EditGlobalProc), cast(LPARAM, @lpEditProcData))
  SendMessage(pd->hMainWnd, AKD_SETMAINPROC, cast(WPARAM, @MainGlobalProc), cast(LPARAM, @lpMainProcData))
  if pd->nMDI = WMD_MDI then
    SendMessage(pd->hMainWnd, AKD_SETFRAMEPROC, cast(WPARAM, @FrameGlobalProc), cast(LPARAM, @lpFrameProcData))
  end if
end sub

private sub SetOriginalProcData()
  if lpEditProcData <> 0 then
    SendMessage(g_hMainWnd, AKD_SETEDITPROC, 0, cast(LPARAM, @lpEditProcData))
    lpEditProcData = 0
  end if
  if lpMainProcData <> 0 then
    SendMessage(g_hMainWnd, AKD_SETMAINPROC, 0, cast(LPARAM, @lpMainProcData))
    lpMainProcData = 0
  end if
  if lpFrameProcData <> 0 then
    SendMessage(g_hMainWnd, AKD_SETFRAMEPROC, 0, cast(LPARAM, @lpFrameProcData))
    lpFrameProcData = 0
  end if
end sub

private sub OpenFileInAkelPad(byval hMainWnd as HWND, byval pszFileName as WString Ptr)
  dim pFrame as FRAMEDATA ptr = cast(FRAMEDATA ptr, SendMessage(hMainWnd, AKD_FRAMEFINDW, FWF_BYFILENAME, cast(LPARAM, pszFileName)))
  if pFrame <> 0 then
    ' MessageBoxW(hMainWnd, WStr("File is already opened!"), WStr("SmartMath"), MB_OK)
    SendMessage(hMainWnd, AKD_FRAMEACTIVATE, 0, cast(LPARAM, pFrame))
    exit sub
  end if

  dim od as OPENDOCUMENTW
  od.pFile = pszFileName
  od.pWorkDir = 0
  od.dwFlags = OD_ADT_BINARYERROR or OD_ADT_DETECTCODEPAGE or OD_ADT_DETECTBOM
  od.nCodePage = 0
  od.bBOM = 0
  od.hDoc = 0
  SendMessage(hMainWnd, AKD_OPENDOCUMENTW, 0, cast(LPARAM, @od))
end sub

private sub ShowDocumentation(byval hMainWnd as HWND)
  dim sMsg as WString * (MAX_PATH + 64)
  if GetFileAttributesW(@g_documentationFilePath) = INVALID_FILE_ATTRIBUTES then
    sMsg = wstr("The file does not exist:") & wchr(13) & wchr(10) & g_documentationFilePath
    MessageBoxW(hMainWnd, @sMsg, WStr("SmartMath"), MB_OK or MB_ICONWARNING)
    exit sub
  end if

  OpenFileInAkelPad(hMainWnd, g_documentationFilePath)
end sub

' -----------------------------------------------------------------------------
'  Main-window subclass procedure
' -----------------------------------------------------------------------------
function MainGlobalProc stdcall(byval hWnd as HWND, byval uMsg as UINT, byval wParam as WPARAM, byval lParam as LPARAM) as LRESULT
  if uMsg = WM_COMMAND then
    dim nCmd as Integer = LOWORD(wParam)

    if nCmd = IDM_ACTIVE_ON_CURR_TAB then
      dim pFrameCurrent as FRAMEDATA ptr = cast(FRAMEDATA ptr, SendMessage(g_hMainWnd, AKD_FRAMEFIND, FWF_CURRENT, 0))
      dim idx as Integer = g_framesWithSmartMathEnabled.Find(pFrameCurrent)
      if idx >= 0 then
        ' Restore AEM options while the FrameItem is still alive in the list.
        SetSmartMathDocActiveState(pFrameCurrent->ei.hWndEdit, FALSE, FALSE)
        RestoreAkelOptionsIfSaved(cast(FrameItem ptr, g_framesWithSmartMathEnabled[idx]))
        g_framesWithSmartMathEnabled.RemoveAt(idx)
        UpdateMenuActiveOnCurrTab(FALSE)
      else
        dim pFrameItem as FrameItem ptr = New FrameItem(pFrameCurrent)
        if pFrameItem <> 0 then
          pFrameItem->isWorking = TRUE
          g_framesWithSmartMathEnabled.Append(pFrameItem)
          SetSmartMathDocActiveState(pFrameCurrent->ei.hWndEdit, TRUE, TRUE)
          UpdateMenuActiveOnCurrTab(TRUE)
        end if
      end if
      return 0

    elseif nCmd = IDM_DECIMAL_BASE then
      Config_SetDecimalPlaces(-1)
      InvalidateRenderCache()
      SaveSettings()
      UpdateMenuChecks()
      if g_hWndEdit then
        dim bVis as BOOL
        UpdateInternalState(g_hWndEdit, bVis)
        InvalidateRect(g_hWndEdit, 0, TRUE)
      end if
      return 0

    elseif nCmd > IDM_DECIMAL_BASE andalso nCmd <= IDM_DECIMAL_BASE + 1 + SMARTMATH_DECIMALS_MAX then
      Config_SetDecimalPlaces(nCmd - IDM_DECIMAL_BASE - 1)
      InvalidateRenderCache()
      SaveSettings()
      UpdateMenuChecks()
      if g_hWndEdit then
        dim bVis as BOOL
        UpdateInternalState(g_hWndEdit, bVis)
        InvalidateRect(g_hWndEdit, 0, TRUE)
      end if
      return 0

    elseif nCmd >= IDM_COLOR_BASE andalso nCmd < IDM_COLOR_BASE + MAX_COLORS then
      select case nCmd
        case IDM_COLOR_GREEN:  Config_SetResultColor(&H008000)
        case IDM_COLOR_BLUE:   Config_SetResultColor(&HFF0000)
        case IDM_COLOR_RED:    Config_SetResultColor(&H0000FF)
        case IDM_COLOR_YELLOW: Config_SetResultColor(&H00FFFF)
        case IDM_COLOR_WHITE:  Config_SetResultColor(&HFFFFFF)
        case IDM_COLOR_BLACK:  Config_SetResultColor(&H000000)
      end select
      SaveSettings()
      UpdateMenuChecks()
      if g_hWndEdit then
        InvalidateRect(g_hWndEdit, 0, TRUE)
      end if
      return 0

    elseif nCmd = IDM_THOUSANDS_SEPARATOR orelse nCmd = IDM_COMPLEX_NUMBERS orelse _
           nCmd = IDM_SHOW_ERRORS orelse nCmd = IDM_SYNTAX_HIGHLIGHT then
      if nCmd = IDM_THOUSANDS_SEPARATOR then
        if Config_GetUseThousandsSep() then
          Config_SetUseThousandsSep(FALSE)
        else
          Config_SetUseThousandsSep(TRUE)
        end if
      elseif nCmd = IDM_COMPLEX_NUMBERS then
        if Config_GetSupportComplexNumbers() then
          Config_SetSupportComplexNumbers(FALSE)
        else
          Config_SetSupportComplexNumbers(TRUE)
        end if
      elseif nCmd = IDM_SHOW_ERRORS then
        if Config_GetShowErrors() then
          Config_SetShowErrors(FALSE)
        else
          Config_SetShowErrors(TRUE)
        end if
      elseif nCmd = IDM_SYNTAX_HIGHLIGHT then
        if Config_GetSyntaxHighlight() then
          Config_SetSyntaxHighlight(FALSE)
        else
          Config_SetSyntaxHighlight(TRUE)
        end if
      end if

      InvalidateRenderCache()
      SaveSettings()
      UpdateMenuChecks()
      if g_hWndEdit then
        dim bVis as BOOL
        if nCmd = IDM_SYNTAX_HIGHLIGHT andalso Config_GetSyntaxHighlight() then
          if g_bSmartMathDocActive then TryApplySmartMathCoderTheme()
        end if
        UpdateInternalState(g_hWndEdit, bVis)
        InvalidateRect(g_hWndEdit, 0, TRUE)
      end if
      return 0

    elseif nCmd = IDM_DOCUMENTATION then
      ShowDocumentation(hWnd)
      return 0

    elseif nCmd = IDM_ABOUT then
      ShowAboutDialog(hWnd)
      return 0
    end if

  elseif (uMsg = AKDN_FRAME_ACTIVATE) orelse (uMsg = AKDN_OPENDOCUMENT_FINISH) then
    dim hWndEditCurrent as HWND = GetWndEdit(g_hMainWnd)
    if hWndEditCurrent <> 0 then
      dim bJustOpened as Boolean = (uMsg = AKDN_OPENDOCUMENT_FINISH)
      if bJustOpened then
        g_lastDocModeFrame = 0
      end if
      RefreshSmartMathDocMode(hWndEditCurrent, bJustOpened)
    end if

  elseif uMsg = AKDN_FRAME_DESTROY then
    dim pFrame as FRAMEDATA ptr = cast(FRAMEDATA ptr, lParam)
    if pFrame <> 0 then
      dim idxDestroy as Integer = g_framesWithSmartMathEnabled.Find(pFrame)
      if idxDestroy >= 0 then
        RestoreAkelOptionsIfSaved(cast(FrameItem ptr, g_framesWithSmartMathEnabled[idxDestroy]))
        g_framesWithSmartMathEnabled.RemoveAt(idxDestroy)
      end if
    end if

  elseif uMsg = AKDN_MAIN_ONSTART_FINISH then
    if g_bSmartMathActive then
      dim result as LRESULT = 0
      if lpMainProcData andalso lpMainProcData->NextProc then
        result = lpMainProcData->NextProc(hWnd, uMsg, wParam, lParam)
      end if

      ' LogInfo("MainGlobalProc: AKDN_MAIN_ONSTART_FINISH, g_bAkelPadReady=TRUE")
      g_bAkelPadReady = TRUE
      dim hEditStart as HWND = GetWndEdit(g_hMainWnd)
      if hEditStart <> 0 then
        SyncSmartMathActiveEditorState(hEditStart)
      end if

      return result
    end if

  elseif uMsg = AKDN_MAIN_ONSTART_SHOW then
    ' On AKDN_MAIN_ONSTART_SHOW, the Sessions plugin loads all the files
    dim result as LRESULT = 0
    if lpMainProcData andalso lpMainProcData->NextProc then
      result = lpMainProcData->NextProc(hWnd, uMsg, wParam, lParam)
    end if
    ' The Sessions plugin has loaded all the files at this point

    if hSmartMathMenu = 0 then
      InitSmartMathMenu()
      ActivateSmartMathFiles()
    end if

    return result

  elseif uMsg = WM_CLOSE orelse uMsg = WM_QUERYENDSESSION orelse (uMsg = WM_SYSCOMMAND andalso wParam = SC_CLOSE) then
    if g_bActiveFramesSaved = FALSE then
      SaveActiveSmartMathFrames()
      g_bActiveFramesSaved = TRUE
    end if

  elseif uMsg = AKDN_MAIN_ONFINISH then
    g_bShuttingDown = TRUE
    dim bWasSmartMathActive as BOOL = g_bSmartMathActive

    g_bSmartMathActive = FALSE

    dim result as LRESULT = 0
    if lpMainProcData andalso lpMainProcData->NextProc then
      result = lpMainProcData->NextProc(hWnd, uMsg, wParam, lParam)
    end if

    if bWasSmartMathActive then
      RestoreAllFrameAkelOptions()
      SetOriginalProcData()
    end if

    ResetActiveSmartMathFrameFiles()
    UninitSmartMathMenu(TRUE)

    return result
  end if

  CheckEditNotifications(hWnd, uMsg, wParam, lParam)

  if lpMainProcData andalso lpMainProcData->NextProc then
    return lpMainProcData->NextProc(hWnd, uMsg, wParam, lParam)
  end if
  return 0
end function

' Modifier and lock keys never change text, caret line or scroll position, but
' auto-repeat keeps sending WM_KEYDOWN while one is held. Repainting overlays on
' every repeat makes all visible results blink.
private function IsModifierOrLockVirtualKey(byval vk as WPARAM) as BOOL
  select case vk
    case VK_SHIFT, VK_CONTROL, VK_MENU, _
         VK_LSHIFT, VK_RSHIFT, VK_LCONTROL, VK_RCONTROL, VK_LMENU, VK_RMENU, _
         VK_LWIN, VK_RWIN, _
         VK_CAPITAL, VK_NUMLOCK, VK_SCROLL
      return TRUE
    case else
      return FALSE
  end select
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

  ' Mark content-key hold before NextProc so AEN_TEXTCHANGED (during insert/delete)
  ' only invalidates the current line while the key is held.
  if ((uMsg = WM_KEYDOWN) orelse (uMsg = WM_SYSKEYDOWN)) andalso _
     (IsModifierOrLockVirtualKey(wParam) = FALSE) andalso _
     (IsNavigationVirtualKey(wParam) = FALSE) then
    g_bContentKeyDown = TRUE
  end if

  dim lRes as LRESULT
  dim rcUpdate as RECT
  dim bNeedRedraw as BOOL = FALSE

  select case uMsg
    case WM_PAINT
      if g_bSmartMathDocActive then
        if GetUpdateRect(hWnd, @rcUpdate, FALSE) then
          dim rcIntersect as RECT
          if (rcOldMargin.right = 0) orelse IntersectRect(@rcIntersect, @rcUpdate, @rcOldMargin) then
            bNeedRedraw = TRUE
          end if
        end if
      end if

    case WM_SETFOCUS
      if (not g_bOldRichEdit) andalso g_bSmartMathDocActive then
        EnsureActiveLineOptionApplied(FindCurrentFrameItem())
      end if

    case WM_SETFONT
      ' SpecialChar EOL badge width depends on the edit font.
      InvalidateEolMarkerReserve()

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
        dim wrapFirst as Integer = lineIdx
        dim wrapLast as Integer = lineIdx
        GetSoftWrapGroupBounds(hWnd, lineIdx, wrapFirst, wrapLast)
        dim sRes as String = BuildResultTextForLine(hWnd, wrapLast)
        if len(sRes) > 0 then
          dim hitResultArea as BOOL = FALSE
          dim ptLineEndX as Integer = rcClient.left
          dim ptLineEndY as Integer = 0
          if GetPhysicalLineEndClientPos(hWnd, wrapLast, ptLineEndX, ptLineEndY) then
            dim hDC as HDC = GetDC(hWnd)
            if hDC <> 0 then
              dim hFont as HFONT = cast(HFONT, SendMessage(hWnd, WM_GETFONT, 0, 0))
              dim hOldFont as HFONT
              if hFont then hOldFont = cast(HFONT, SelectObject(hDC, hFont))
              dim sz as SIZE
              GetTextExtentPoint32(hDC, strptr(sRes), Len(sRes), @sz)
              ' Pad must be measured before ReleaseDC (hDC is invalid after).
              dim nGutterPadHit as Integer = GetOverlayGutterPad(hWnd, hDC)
              if hFont then SelectObject(hDC, hOldFont)
              ReleaseDC(hWnd, hDC)

              dim drawX as Integer = 0
              dim minDrawX as Integer = 0
              GetResultOverlayDrawX(rcClient.left, rcClient.right, ptLineEndX, sz.cx, nGutterPadHit, drawX, minDrawX)
              dim clipLeft as Integer = IIf(drawX > minDrawX, drawX, minDrawX)
              dim nCharHeightHit as Integer = GetEditCharHeight(hWnd)
              if xPos >= clipLeft andalso xPos <= rcClient.right andalso _
                 yPos >= ptLineEndY andalso yPos < ptLineEndY + nCharHeightHit then
                hitResultArea = TRUE
              end if
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
      ' Clip overlays to the pre-NextProc update region so partial paints
      ' (e.g. same-line click) do not transparently overdraw other lines.
      DrawDynamicMathResults(hWnd, @rcUpdate)
    end if
  else
    select case uMsg
      case WM_KEYDOWN, WM_KEYUP, WM_SYSKEYDOWN, WM_SYSKEYUP, _
           WM_LBUTTONDOWN, WM_LBUTTONUP, WM_MOUSEMOVE, _
           WM_MOUSEWHEEL, WM_HSCROLL, WM_VSCROLL, WM_CHAR, WM_SIZE
        if g_bSmartMathDocActive = FALSE then
          return lRes
        end if

        select case uMsg
          case WM_KEYDOWN, WM_KEYUP, WM_SYSKEYDOWN, WM_SYSKEYUP
            if IsModifierOrLockVirtualKey(wParam) then return lRes
        end select

        if (uMsg <> WM_MOUSEMOVE) orelse (wParam and MK_LBUTTON) then
          ' Track content-key hold before cache work so EnsureRenderCache can
          ' cap re-eval to the current line while the key is held.
          dim bIsNavKey as BOOL = FALSE
          dim bForceKeyRedraw as BOOL = FALSE
          dim nFlushFromLine as Integer = -1
          if (uMsg = WM_KEYDOWN) orelse (uMsg = WM_SYSKEYDOWN) orelse _
             (uMsg = WM_KEYUP) orelse (uMsg = WM_SYSKEYUP) then
            if IsNavigationVirtualKey(wParam) then
              bIsNavKey = TRUE
              if (uMsg = WM_KEYDOWN) orelse (uMsg = WM_SYSKEYDOWN) then
                dim selStart as Integer = 0, selEnd as Integer = 0
                SendMessage(hWnd, EM_GETSEL, cast(WPARAM, @selStart), cast(LPARAM, @selEnd))
                nLastNavSelStart = selStart
                nLastNavSelEnd = selEnd
              end if
            else
              if (uMsg = WM_KEYDOWN) orelse (uMsg = WM_SYSKEYDOWN) then
                ' Backspace/Delete/etc.: content may change without WM_CHAR.
                bForceKeyRedraw = TRUE
                nLastNavSelStart = -1
                nLastNavSelEnd = -1
              elseif g_bContentKeyDown then
                g_bContentKeyDown = FALSE
                nFlushFromLine = g_cacheDirtyFromLine
              end if
            end if
          end if

          dim bVisible as BOOL
          UpdateInternalState(hWnd, bVisible)
          ' Key-up: EnsureRenderCache (via UpdateInternalState) finished dependents
          ' because content-key cap is off; repaint from the dirty line down.
          if nFlushFromLine >= 0 then
            InvalidateEditFromLineDown(hWnd, nFlushFromLine)
          end if

          dim rcClient as RECT
          GetClientRect(hWnd, @rcClient)

          dim rcNewMargin as RECT = rcClient

          dim nFirstVisible as Integer = SendMessage(hWnd, EM_GETFIRSTVISIBLELINE, 0, 0)
          dim nCaretLine as Integer = SendMessage(hWnd, EM_EXLINEFROMCHAR, 0, -1)

          dim nHScrollPos as Integer = 0
          if not g_bOldRichEdit then
            dim ptScrollPos as POINT64
            SendMessage(hWnd, AEM_GETSCROLLPOS, 0, cast(LPARAM, @ptScrollPos))
            nHScrollPos = cast(Integer, ptScrollPos.x)
          end if

          ' Arrow/nav keys must not force a full-client erase (that flickers every
          ' visible result). Same-line moves need no SmartMath invalidate; caret
          ' line changes only refresh the old and new line strips.
          if bVisible then
            dim bSizeChanged as BOOL = (rcNewMargin.left <> rcOldMargin.left) orelse _
                                       (rcNewMargin.right <> rcOldMargin.right)
            dim bScrollChanged as BOOL = (nFirstVisible <> nOldFirstLine)
            dim bCaretLineChanged as BOOL = (nCaretLine <> nOldCaretLine)
            dim bHScrollChanged as BOOL = (nHScrollPos <> nOldHScrollPos)

            if bSizeChanged then
              if rcOldMargin.right > 0 then InvalidateRect(hWnd, @rcOldMargin, TRUE)
              InvalidateRect(hWnd, @rcNewMargin, TRUE)
            elseif (uMsg = WM_CHAR) orelse bForceKeyRedraw then
              ' Typing / Backspace / Delete: while key held, only the current line
              ' (characters stay visible); dirty-from-line + key-up refresh below.
              dim nFromLine as Integer = nCaretLine
              if nOldCaretLine >= 0 andalso (nFromLine < 0 orelse nOldCaretLine < nFromLine) then
                nFromLine = nOldCaretLine
              end if
              InvalidateAfterContentEdit(hWnd, nFromLine, TRUE)
            elseif bScrollChanged then
              ' Do not full-erase invalidate: key-repeat starves WM_PAINT and leaves
              ' blank result strips on newly exposed lines. Draw the edge (and caret
              ' lines) synchronously after the edit control has scrolled.
              DrawMathResultsForScroll(hWnd, nOldFirstLine, nFirstVisible, nOldCaretLine, nCaretLine)
            elseif bCaretLineChanged then
              ' Active-line background moved: refresh only those two lines.
              if nOldCaretLine >= 0 then InvalidateEditLine(hWnd, nOldCaretLine)
              InvalidateEditLine(hWnd, nCaretLine)
            elseif bIsNavKey andalso (bHScrollChanged = FALSE) then
              ' Left/Right/Home/End on the same line: the overlay is already correct
              ' on screen, so keep the control's caret/selection repaint out of it.
              ValidateResultGutterForLine(hWnd, nCaretLine)
            end if

            rcOldMargin = rcNewMargin
            nOldFirstLine = nFirstVisible
            nOldCaretLine = nCaretLine
            nOldHScrollPos = nHScrollPos
          else
            if rcOldMargin.right > 0 then
              InvalidateRect(hWnd, @rcOldMargin, TRUE)
            end if
            ResetEditOverlayTrackers()
          end if
        end if
    end select
  end if

  return lRes
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

  ' dim pf as PLUGINFUNCTION ptr

  if g_bSmartMathActive then
    LogInfo("Deactivating Global Edit Hook...")
    pd->nUnload = UD_UNLOAD

    SetOriginalProcData()
    UninitSmartMathMenu(FALSE)

    SaveActiveSmartMathFrames()
    RestoreAllFrameAkelOptions()
    g_framesWithSmartMathEnabled.Clear()
    g_bActiveFramesSaved = FALSE
    g_bSmartMathActive = FALSE
    g_bSmartMathDocActive = FALSE
    g_lastDocModeFrame = 0
    g_lastDocModeEdit = 0
    InvalidateRenderCache()
    ResetEditOverlayTrackers()

    if pd->hWndEdit then
      InvalidateRect(pd->hWndEdit, 0, TRUE)
    end if

    ResetActiveSmartMathFrameFiles()

    ' The code below leads to undesired effects;
    ' instead, use AkelPad's native way of auto-load
    ' by checking the plugin's function checkbox.
    'pf = cast(PLUGINFUNCTION ptr, SendMessageW(pd->hMainWnd, AKD_DLLFINDW, cast(WPARAM, @wstr("SmartMath::ToggleSmartMath")), 0))
    'if pf <> 0 then
    '  pf->bAutoLoad = FALSE
    '  SendMessage(pd->hMainWnd, AKD_DLLSAVE, DLLSF_NOW, 0)
    'end if

  else
    LogInfo("Activating Global Edit Hook...")
    pd->nUnload = UD_NONUNLOAD_ACTIVE

    g_documentationFilePath = *(pd->wszAkelDir)
    g_documentationFilePath &= WStr("\AkelFiles\Docs\SmartMath-Eng.md")

    LoadSettings()
    Parser_SetSupportComplexNumbers(Config_GetSupportComplexNumbers())

    g_bShuttingDown = FALSE
    InvalidateRenderCache()
    ResetEditOverlayTrackers()

    SetSmartMathProcData(pd)

    g_bSmartMathActive = TRUE

    ' if the plugin function is called on start,
    ' postpone the menu initialization until AKDN_MAIN_ONSTART_SHOW
    if pd->bOnStart = FALSE then
      InitSmartMathMenu()
      ActivateSmartMathFiles()
    end if

    dim hEditAct as HWND = pd->hWndEdit
    if hEditAct = 0 then hEditAct = GetWndEdit(pd->hMainWnd)

    ' LogInfo("ToggleSmartMath: hEditAct=" & hEditAct)
    if hEditAct <> 0 then
      SyncSmartMathActiveEditorState(hEditAct)
    end if

    ' The code below leads to undesired effects;
    ' instead, use AkelPad's native way of auto-load
    ' by checking the plugin's function checkbox .
    'pf = cast(PLUGINFUNCTION ptr, SendMessageW(pd->hMainWnd, AKD_DLLFINDW, cast(WPARAM, @wstr("SmartMath::ToggleSmartMath")), 0))
    'if pf <> 0 then
    '  pf->bAutoLoad = TRUE
    '  if pd->bOnStart = FALSE then
    '    SendMessage(pd->hMainWnd, AKD_DLLSAVE, DLLSF_NOW, 0)
    '  end if
    'end if

  end if

  LogInfo("--- ToggleSmartMath Finished ---")
end sub

end extern

function DllMain(byval hinstDLL as HINSTANCE, byval fdwReason as DWORD, byval lpvReserved as LPVOID) as WINBOOL
  return TRUE
end function
