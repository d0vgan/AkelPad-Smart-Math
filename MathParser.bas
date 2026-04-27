#include once "crt.bi"
#include once "Inc\MathParser.bi"

enum ValueKind
  VK_SCALAR = 0
  VK_ARRAY = 1
end enum

enum ScalarStorageKind
  SSK_FLOATINGPOINT = 0
  SSK_INT64 = 1
  SSK_UINT64 = 2
end enum

enum ScalarFlags
  SVF_EXACT_INT64_VALID = &h01
  SVF_EXACT_UINT64_VALID = &h02
  SVF_DEC_SCI_POW63_HIGH = &h10
end enum

enum EvalFlags
  EVF_EXPAND_ARGS = &h01
  EVF_RENDER_UNSIGNED = &h02
  EVF_RENDER_BASE_SHIFT = 8
  EVF_RENDER_BASE_MASK = &h0000FF00
end enum

type ScalarValue
  scalarStorageKind as ScalarStorageKind
  flags as UInteger
  scalar as Double
  exactInt64 as LongInt
  exactUInt64 as ULongInt
  declare property exactInt64Valid() as Boolean
  declare property exactInt64Valid(byval v as Boolean)
  declare property exactUInt64Valid() as Boolean
  declare property exactUInt64Valid(byval v as Boolean)
  declare property decScientificPow63High() as Boolean
  declare property decScientificPow63High(byval v as Boolean)
end type

type EvalValue
  kind as ValueKind
  flags as UInteger
  scalarValue as ScalarValue
  arr(any) as ScalarValue
  declare property renderBase() as Integer ' 0=decimal, 16=hex, 8=octal, 2=binary
  declare property renderBase(byval v as Integer)
  ' uhex/uoct/ubin: two's complement as unsigned; hex/oct/bin: signed magnitude for negatives
  declare property scalarStorageKind() as Integer
  declare property scalarStorageKind(byval v as Integer)
  declare property scalar() byref as Double
  declare property scalar(byval v as Double)
  declare property exactInt64Valid() as Boolean
  declare property exactInt64Valid(byval v as Boolean)
  declare property exactInt64() byref as LongInt
  declare property exactInt64(byval v as LongInt)
  declare property exactUInt64Valid() as Boolean
  declare property exactUInt64Valid(byval v as Boolean)
  declare property exactUInt64() byref as ULongInt
  declare property exactUInt64(byval v as ULongInt)
  declare property expandArgs() as Boolean
  declare property expandArgs(byval v as Boolean)
  declare property renderUnsigned() as Boolean
  declare property renderUnsigned(byval v as Boolean)
end type

type DoubleBits
  union
    d as Double
    u as ULongInt
  end union
end type

property ScalarValue.exactInt64Valid() as Boolean
  return (this.flags and SVF_EXACT_INT64_VALID) <> 0
end property

property ScalarValue.exactInt64Valid(byval v as Boolean)
  if v then
    this.flags or= SVF_EXACT_INT64_VALID
  else
    this.flags and= not CUInt(SVF_EXACT_INT64_VALID)
  end if
end property

property ScalarValue.exactUInt64Valid() as Boolean
  return (this.flags and SVF_EXACT_UINT64_VALID) <> 0
end property

property ScalarValue.exactUInt64Valid(byval v as Boolean)
  if v then
    this.flags or= SVF_EXACT_UINT64_VALID
  else
    this.flags and= not CUInt(SVF_EXACT_UINT64_VALID)
  end if
end property

property ScalarValue.decScientificPow63High() as Boolean
  return (this.flags and SVF_DEC_SCI_POW63_HIGH) <> 0
end property

property ScalarValue.decScientificPow63High(byval v as Boolean)
  if v then
    this.flags or= SVF_DEC_SCI_POW63_HIGH
  else
    this.flags and= not CUInt(SVF_DEC_SCI_POW63_HIGH)
  end if
end property

property EvalValue.scalarStorageKind() as Integer
  return CInt(this.scalarValue.scalarStorageKind)
end property

property EvalValue.scalarStorageKind(byval v as Integer)
  this.scalarValue.scalarStorageKind = v
end property

property EvalValue.scalar() byref as Double
  return this.scalarValue.scalar
end property

property EvalValue.scalar(byval v as Double)
  this.scalarValue.scalar = v
end property

property EvalValue.exactInt64Valid() as Boolean
  return this.scalarValue.exactInt64Valid
end property

property EvalValue.exactInt64Valid(byval v as Boolean)
  this.scalarValue.exactInt64Valid = v
end property

property EvalValue.exactInt64() byref as LongInt
  return this.scalarValue.exactInt64
end property

property EvalValue.exactInt64(byval v as LongInt)
  this.scalarValue.exactInt64 = v
end property

property EvalValue.exactUInt64Valid() as Boolean
  return this.scalarValue.exactUInt64Valid
end property

property EvalValue.exactUInt64Valid(byval v as Boolean)
  this.scalarValue.exactUInt64Valid = v
end property

property EvalValue.exactUInt64() byref as ULongInt
  return this.scalarValue.exactUInt64
end property

property EvalValue.exactUInt64(byval v as ULongInt)
  this.scalarValue.exactUInt64 = v
end property

property EvalValue.renderBase() as Integer
  dim raw as UInteger = (this.flags and EVF_RENDER_BASE_MASK) shr EVF_RENDER_BASE_SHIFT
  if raw = 0 then return 10
  return CInt(raw)
end property

property EvalValue.renderBase(byval v as Integer)
  this.flags and= not CUInt(EVF_RENDER_BASE_MASK)
  this.flags or= (CUInt(v and &hFF) shl EVF_RENDER_BASE_SHIFT)
end property

property EvalValue.expandArgs() as Boolean
  return (this.flags and EVF_EXPAND_ARGS) <> 0
end property

property EvalValue.expandArgs(byval v as Boolean)
  if v then
    this.flags or= EVF_EXPAND_ARGS
  else
    this.flags and= not CUInt(EVF_EXPAND_ARGS)
  end if
end property

property EvalValue.renderUnsigned() as Boolean
  return (this.flags and EVF_RENDER_UNSIGNED) <> 0
end property

property EvalValue.renderUnsigned(byval v as Boolean)
  if v then
    this.flags or= EVF_RENDER_UNSIGNED
  else
    this.flags and= not CUInt(EVF_RENDER_UNSIGNED)
  end if
end property

type VarEntry
  name as String
  value as EvalValue
end type

type FuncEntry
  name as String
  params(any) as String
  expr as String
end type

dim shared variables() as VarEntry
dim shared userFunctions() as FuncEntry
dim shared pStream as ZString ptr
dim shared parseError as Integer
dim shared wasPercentage as Boolean
dim shared lastErrorText as String
dim shared unknownVarsText as String
dim shared unknownFuncsText as String
dim shared evalDepth as Integer
dim shared exprStart as ZString ptr
dim shared errorBaseCol as Integer
dim shared rootInputExpr as String
dim shared Parser_ShowErrorLine as Boolean = FALSE

private function BuildErrorSnippet(byval col as Integer) as String
  if len(rootInputExpr) = 0 then return ""

  dim exprLen as Integer = len(rootInputExpr)
  if col < 1 then col = 1
  if col > exprLen + 1 then col = exprLen + 1

  dim leftSpan as Integer = 18
  dim rightSpan as Integer = 18
  dim startPos as Integer = col - leftSpan
  dim endPos as Integer = col + rightSpan
  if startPos < 1 then startPos = 1
  if endPos > exprLen then endPos = exprLen
  if endPos < startPos then endPos = startPos

  dim snippet as String = mid(rootInputExpr, startPos, endPos - startPos + 1)
  dim markerPos as Integer = col - startPos + 1
  if markerPos < 1 then markerPos = 1
  if markerPos > len(snippet) + 1 then markerPos = len(snippet) + 1
  return left(snippet, markerPos - 1) & "|" & mid(snippet, markerPos)
end function

private sub SetParseError(byref msg as String)
  if parseError = 0 then parseError = 1
  if lastErrorText = "" then
    if (exprStart <> 0) andalso (pStream <> 0) andalso (pStream >= exprStart) then
      dim col as Integer = errorBaseCol + (pStream - exprStart)
      dim locationPart as String = " at "
      if Parser_ShowErrorLine then locationPart = locationPart & "line 1, "
      locationPart = locationPart & "col " & ltrim(str(col)) & ":  "
      lastErrorText = msg & locationPart & BuildErrorSnippet(col)
    else
      lastErrorText = msg
    end if
  end if
end sub

private sub AppendUniqueName(byref listText as String, byref n as String)
  dim token as String = "," & listText & ","
  if instr(token, "," & n & ",") > 0 then exit sub
  if listText = "" then
    listText = n
  else
    listText &= ", " & n
  end if
end sub

enum BuiltinFunctionId
  FUNC_RAND = 0
  FUNC_RANDOM
  FUNC_BIN
  FUNC_HEX
  FUNC_OCT
  FUNC_POW
  FUNC_ATAN2
  FUNC_SIN
  FUNC_COS
  FUNC_TAN
  FUNC_ASIN
  FUNC_ARCSIN
  FUNC_ACOS
  FUNC_ARCCOS
  FUNC_ATAN
  FUNC_ARCTAN
  FUNC_SINH
  FUNC_COSH
  FUNC_TANH
  FUNC_EXP
  FUNC_LOG
  FUNC_LN
  FUNC_LOG10
  FUNC_SQRT
  FUNC_SQR
  FUNC_INT
  FUNC_FRAC
  FUNC_FRACT
  FUNC_ABS
  FUNC_FLOOR
  FUNC_CEIL
  FUNC_TRUNC
  FUNC_ROUND
  FUNC_SIGN
  FUNC_DEG
  FUNC_RAD
  FUNC_SUM
  FUNC_MEDIAN
  FUNC_VARIANCE
  FUNC_STDDEV
  FUNC_SORT
  FUNC_SORTED
  FUNC_REVERSE
  FUNC_REVERSED
  FUNC_UNIQUE
  FUNC_UNPACK
  FUNC_FACT
  FUNC_FACTORIAL
  FUNC_AVG
  FUNC_MEAN
  FUNC_MOD
  FUNC_CLAMP
  FUNC_HYPOT
  FUNC_GCD
  FUNC_LCM
  FUNC_PRODUCT
  FUNC_PROD
  FUNC_MIN
  FUNC_MAX
  FUNC_UHEX
  FUNC_UOCT
  FUNC_UBIN
  FUNC__COUNT
end enum

enum OperatorNameId
  OP_NOT = 0
  OP_AND
  OP_OR
  OP_MOD
  OP__COUNT
end enum

enum BuiltinConstId
  CONST_PI = 0
  CONST_E
  CONST__COUNT
end enum

dim shared FunctionNames(0 to FUNC__COUNT - 1) as String
dim shared OperatorNames(0 to OP__COUNT - 1) as String
dim shared ConstNames(0 to CONST__COUNT - 1) as String
dim shared FunctionNamesInitialized as Boolean = FALSE
dim shared OperatorNamesInitialized as Boolean = FALSE
dim shared ConstNamesInitialized as Boolean = FALSE

private sub EnsureFunctionNames()
  if FunctionNamesInitialized then exit sub
  FunctionNames(FUNC_RAND) = "rand"
  FunctionNames(FUNC_RANDOM) = "random"
  FunctionNames(FUNC_BIN) = "bin"
  FunctionNames(FUNC_HEX) = "hex"
  FunctionNames(FUNC_OCT) = "oct"
  FunctionNames(FUNC_POW) = "pow"
  FunctionNames(FUNC_ATAN2) = "atan2"
  FunctionNames(FUNC_SIN) = "sin"
  FunctionNames(FUNC_COS) = "cos"
  FunctionNames(FUNC_TAN) = "tan"
  FunctionNames(FUNC_ASIN) = "asin"
  FunctionNames(FUNC_ARCSIN) = "arcsin"
  FunctionNames(FUNC_ACOS) = "acos"
  FunctionNames(FUNC_ARCCOS) = "arccos"
  FunctionNames(FUNC_ATAN) = "atan"
  FunctionNames(FUNC_ARCTAN) = "arctan"
  FunctionNames(FUNC_SINH) = "sinh"
  FunctionNames(FUNC_COSH) = "cosh"
  FunctionNames(FUNC_TANH) = "tanh"
  FunctionNames(FUNC_EXP) = "exp"
  FunctionNames(FUNC_LOG) = "log"
  FunctionNames(FUNC_LN) = "ln"
  FunctionNames(FUNC_LOG10) = "log10"
  FunctionNames(FUNC_SQRT) = "sqrt"
  FunctionNames(FUNC_SQR) = "sqr"
  FunctionNames(FUNC_INT) = "int"
  FunctionNames(FUNC_FRAC) = "frac"
  FunctionNames(FUNC_FRACT) = "fract"
  FunctionNames(FUNC_ABS) = "abs"
  FunctionNames(FUNC_FLOOR) = "floor"
  FunctionNames(FUNC_CEIL) = "ceil"
  FunctionNames(FUNC_TRUNC) = "trunc"
  FunctionNames(FUNC_ROUND) = "round"
  FunctionNames(FUNC_SIGN) = "sign"
  FunctionNames(FUNC_DEG) = "deg"
  FunctionNames(FUNC_RAD) = "rad"
  FunctionNames(FUNC_SUM) = "sum"
  FunctionNames(FUNC_MEDIAN) = "median"
  FunctionNames(FUNC_VARIANCE) = "variance"
  FunctionNames(FUNC_STDDEV) = "stddev"
  FunctionNames(FUNC_SORT) = "sort"
  FunctionNames(FUNC_SORTED) = "sorted"
  FunctionNames(FUNC_REVERSE) = "reverse"
  FunctionNames(FUNC_REVERSED) = "reversed"
  FunctionNames(FUNC_UNIQUE) = "unique"
  FunctionNames(FUNC_UNPACK) = "unpack"
  FunctionNames(FUNC_FACT) = "fact"
  FunctionNames(FUNC_FACTORIAL) = "factorial"
  FunctionNames(FUNC_AVG) = "avg"
  FunctionNames(FUNC_MEAN) = "mean"
  FunctionNames(FUNC_MOD) = "mod"
  FunctionNames(FUNC_CLAMP) = "clamp"
  FunctionNames(FUNC_HYPOT) = "hypot"
  FunctionNames(FUNC_GCD) = "gcd"
  FunctionNames(FUNC_LCM) = "lcm"
  FunctionNames(FUNC_PRODUCT) = "product"
  FunctionNames(FUNC_PROD) = "prod"
  FunctionNames(FUNC_MIN) = "min"
  FunctionNames(FUNC_MAX) = "max"
  FunctionNames(FUNC_UHEX) = "uhex"
  FunctionNames(FUNC_UOCT) = "uoct"
  FunctionNames(FUNC_UBIN) = "ubin"
  FunctionNamesInitialized = TRUE
end sub

private sub EnsureOperatorNames()
  if OperatorNamesInitialized then exit sub
  OperatorNames(OP_NOT) = "not"
  OperatorNames(OP_AND) = "and"
  OperatorNames(OP_OR) = "or"
  OperatorNames(OP_MOD) = "mod"
  OperatorNamesInitialized = TRUE
end sub

'' Spelling for each BuiltinConstId; keep TryGetConstant in sync when adding constants.
private sub EnsureConstNames()
  if ConstNamesInitialized then exit sub
  ConstNames(CONST_PI) = "pi"
  ConstNames(CONST_E) = "e"
  ConstNamesInitialized = TRUE
end sub

private function TryFindBuiltinConstId(byref n as String) as Integer
  EnsureConstNames()
  dim low as String = lcase(n)
  dim i as Integer
  for i = 0 to CONST__COUNT - 1
    if low = ConstNames(i) then return i
  next i
  return -1
end function

private function GetFunctionName(byval id as BuiltinFunctionId) as String
  EnsureFunctionNames()
  return FunctionNames(id)
end function

private function OpName(byval id as OperatorNameId) as String
  EnsureOperatorNames()
  return OperatorNames(id)
end function

private function IsFn(byref nameText as String, byval id as BuiltinFunctionId) as Boolean
  return lcase(nameText) = GetFunctionName(id)
end function

private function IsOpKeyword(byref nameText as String, byval id as OperatorNameId) as Boolean
  return lcase(nameText) = OpName(id)
end function

private function IsUnaryBuiltin(byref fn as String) as Boolean
  return IsFn(fn, FUNC_SIN) orelse IsFn(fn, FUNC_COS) orelse IsFn(fn, FUNC_TAN) orelse _
         IsFn(fn, FUNC_ASIN) orelse IsFn(fn, FUNC_ARCSIN) orelse IsFn(fn, FUNC_ACOS) orelse _
         IsFn(fn, FUNC_ARCCOS) orelse IsFn(fn, FUNC_ATAN) orelse IsFn(fn, FUNC_ARCTAN) orelse _
         IsFn(fn, FUNC_SINH) orelse IsFn(fn, FUNC_COSH) orelse IsFn(fn, FUNC_TANH) orelse _
         IsFn(fn, FUNC_EXP) orelse IsFn(fn, FUNC_LN) orelse IsFn(fn, FUNC_LOG10) orelse _
         IsFn(fn, FUNC_SQRT) orelse IsFn(fn, FUNC_SQR) orelse IsFn(fn, FUNC_INT) orelse _
         IsFn(fn, FUNC_FRAC) orelse IsFn(fn, FUNC_FRACT) orelse IsFn(fn, FUNC_ABS) orelse _
         IsFn(fn, FUNC_FLOOR) orelse IsFn(fn, FUNC_CEIL) orelse IsFn(fn, FUNC_TRUNC) orelse _
         IsFn(fn, FUNC_ROUND) orelse IsFn(fn, FUNC_SIGN) orelse IsFn(fn, FUNC_DEG) orelse _
         IsFn(fn, FUNC_RAD)
end function

private function TryGetBuiltinSignatureHint(byref fn as String, byref hint as String) as Boolean
  if IsFn(fn, FUNC_RAND) then
    hint = GetFunctionName(FUNC_RAND) & "()"
  elseif IsFn(fn, FUNC_RANDOM) then
    hint = GetFunctionName(FUNC_RANDOM) & "(min, max)"
  elseif IsFn(fn, FUNC_BIN) orelse IsFn(fn, FUNC_HEX) orelse IsFn(fn, FUNC_OCT) orelse _
         IsFn(fn, FUNC_UBIN) orelse IsFn(fn, FUNC_UHEX) orelse IsFn(fn, FUNC_UOCT) then
    hint = lcase(fn) & "(...)"
  elseif IsFn(fn, FUNC_POW) then
    hint = GetFunctionName(FUNC_POW) & "(value, power)"
  elseif IsFn(fn, FUNC_ATAN2) then
    hint = GetFunctionName(FUNC_ATAN2) & "(y, x)"
  elseif IsFn(fn, FUNC_SIN) orelse IsFn(fn, FUNC_COS) orelse IsFn(fn, FUNC_TAN) then
    hint = lcase(fn) & "(angle)"
  elseif IsFn(fn, FUNC_ASIN) orelse IsFn(fn, FUNC_ARCSIN) then
    hint = GetFunctionName(FUNC_ASIN) & "(value)"
  elseif IsFn(fn, FUNC_ACOS) orelse IsFn(fn, FUNC_ARCCOS) then
    hint = GetFunctionName(FUNC_ACOS) & "(value)"
  elseif IsFn(fn, FUNC_ATAN) orelse IsFn(fn, FUNC_ARCTAN) then
    hint = GetFunctionName(FUNC_ATAN) & "(value)"
  elseif IsFn(fn, FUNC_SINH) orelse IsFn(fn, FUNC_COSH) orelse IsFn(fn, FUNC_TANH) orelse _
         IsFn(fn, FUNC_EXP) orelse IsFn(fn, FUNC_LN) orelse IsFn(fn, FUNC_LOG10) orelse _
         IsFn(fn, FUNC_SQRT) orelse IsFn(fn, FUNC_SQR) orelse IsFn(fn, FUNC_INT) orelse _
         IsFn(fn, FUNC_ABS) orelse IsFn(fn, FUNC_FLOOR) orelse IsFn(fn, FUNC_CEIL) orelse _
         IsFn(fn, FUNC_TRUNC) orelse IsFn(fn, FUNC_ROUND) orelse IsFn(fn, FUNC_SIGN) then
    hint = lcase(fn) & "(value)"
  elseif IsFn(fn, FUNC_FRAC) orelse IsFn(fn, FUNC_FRACT) then
    hint = GetFunctionName(FUNC_FRAC) & "(value)"
  elseif IsFn(fn, FUNC_LOG) then
    hint = GetFunctionName(FUNC_LOG) & "(value, base)"
  elseif IsFn(fn, FUNC_DEG) orelse IsFn(fn, FUNC_RAD) orelse IsFn(fn, FUNC_SUM) orelse _
         IsFn(fn, FUNC_MEDIAN) orelse IsFn(fn, FUNC_VARIANCE) orelse IsFn(fn, FUNC_STDDEV) orelse _
         IsFn(fn, FUNC_UNIQUE) orelse IsFn(fn, FUNC_UNPACK) orelse IsFn(fn, FUNC_AVG) orelse IsFn(fn, FUNC_MEAN) orelse _
         IsFn(fn, FUNC_PRODUCT) orelse IsFn(fn, FUNC_PROD) orelse IsFn(fn, FUNC_MIN) orelse IsFn(fn, FUNC_MAX) then
    hint = lcase(fn) & "(...)"
  elseif IsFn(fn, FUNC_SORT) orelse IsFn(fn, FUNC_SORTED) then
    hint = GetFunctionName(FUNC_SORT) & "(...)"
  elseif IsFn(fn, FUNC_REVERSE) orelse IsFn(fn, FUNC_REVERSED) then
    hint = GetFunctionName(FUNC_REVERSE) & "(...)"
  elseif IsFn(fn, FUNC_FACT) orelse IsFn(fn, FUNC_FACTORIAL) then
    hint = GetFunctionName(FUNC_FACT) & "(n)"
  elseif IsFn(fn, FUNC_MOD) then
    hint = GetFunctionName(FUNC_MOD) & "(value, divisor)"
  elseif IsFn(fn, FUNC_CLAMP) then
    hint = GetFunctionName(FUNC_CLAMP) & "(value, min, max)"
  elseif IsFn(fn, FUNC_HYPOT) then
    hint = GetFunctionName(FUNC_HYPOT) & "(x, y)"
  elseif IsFn(fn, FUNC_GCD) orelse IsFn(fn, FUNC_LCM) then
    hint = lcase(fn) & "(a, b)"
  else
    return FALSE
  end if
  return TRUE
end function

private function IsReservedOperatorKeyword(byref nameText as String) as Boolean
  return IsOpKeyword(nameText, OP_NOT) orelse IsOpKeyword(nameText, OP_AND) orelse IsOpKeyword(nameText, OP_OR)
end function

private function IsBuiltinFunctionName(byref nameText as String) as Boolean
  EnsureFunctionNames()
  dim lowName as String = lcase(nameText)
  dim i as Integer
  for i = lbound(FunctionNames) to ubound(FunctionNames)
    if lowName = FunctionNames(i) then return TRUE
  next i
  return FALSE
end function

private function IsReservedUserFunctionName(byref nameText as String) as Boolean
  if IsBuiltinFunctionName(nameText) then return TRUE
  if IsReservedOperatorKeyword(nameText) then return TRUE
  return FALSE
end function

private function IsTrailingFormatterFunctionName(byref nameText as String) as Boolean
  return IsFn(nameText, FUNC_HEX) orelse IsFn(nameText, FUNC_OCT) orelse IsFn(nameText, FUNC_BIN) orelse _
         IsFn(nameText, FUNC_UHEX) orelse IsFn(nameText, FUNC_UOCT) orelse IsFn(nameText, FUNC_UBIN)
end function

private function TryRewriteTrailingFormatterStmt(byref stmt as String, byref rewritten as String) as Boolean
  dim s as String = trim(stmt)
  if len(s) = 0 then return FALSE
  dim i as Integer = 1
  dim ch as String = mid(s, i, 1)
  if not ((ch >= "A" andalso ch <= "Z") orelse (ch >= "a" andalso ch <= "z") orelse ch = "_") then return FALSE
  while i <= len(s)
    ch = mid(s, i, 1)
    if (ch >= "A" andalso ch <= "Z") orelse (ch >= "a" andalso ch <= "z") orelse (ch >= "0" andalso ch <= "9") orelse ch = "_" then
      i += 1
    else
      exit while
    end if
  wend
  dim fnName as String = left(s, i - 1)
  if IsTrailingFormatterFunctionName(fnName) = FALSE then return FALSE
  dim rest as String = ltrim(mid(s, i))
  if len(rest) = 0 then
    rewritten = lcase(fnName) & "(ans)"
    return TRUE
  end if
  if left(rest, 1) <> "(" then return FALSE
  dim p as Integer = 2
  while p <= len(rest)
    ch = mid(rest, p, 1)
    if ch = " " orelse ch = chr(9) then
      p += 1
    else
      exit while
    end if
  wend
  if p > len(rest) orelse mid(rest, p, 1) <> ")" then return FALSE
  p += 1
  while p <= len(rest)
    ch = mid(rest, p, 1)
    if ch = " " orelse ch = chr(9) then
      p += 1
    else
      return FALSE
    end if
  wend
  rewritten = lcase(fnName) & "(ans)"
  return TRUE
end function

private sub ValueSetScalar(byref v as EvalValue, byval n as Double)
  v.kind = VK_SCALAR
  v.scalarStorageKind = SSK_FLOATINGPOINT
  v.scalar = n
  v.expandArgs = FALSE
  v.renderBase = 0
  v.renderUnsigned = FALSE
  v.exactInt64Valid = FALSE
  v.exactInt64 = 0
  v.exactUInt64Valid = FALSE
  v.exactUInt64 = 0
  erase v.arr
end sub

private function ScalarValueFromEvalScalar(byref v as EvalValue) as ScalarValue
  dim outV as ScalarValue
  outV.scalarStorageKind = v.scalarStorageKind
  outV.scalar = v.scalar
  outV.exactInt64Valid = v.exactInt64Valid
  outV.exactInt64 = v.exactInt64
  outV.exactUInt64Valid = v.exactUInt64Valid
  outV.exactUInt64 = v.exactUInt64
  return outV
end function

private sub EvalScalarFromScalarValue(byref s as ScalarValue, byref outV as EvalValue)
  ValueSetScalar(outV, s.scalar)
  outV.scalarStorageKind = s.scalarStorageKind
  outV.exactInt64Valid = s.exactInt64Valid
  outV.exactInt64 = s.exactInt64
  outV.exactUInt64Valid = s.exactUInt64Valid
  outV.exactUInt64 = s.exactUInt64
end sub

private sub ValueSetArray(byref v as EvalValue, a() as Double)
  v.kind = VK_ARRAY
  v.scalarStorageKind = SSK_FLOATINGPOINT
  v.scalar = 0
  v.expandArgs = FALSE
  v.renderBase = 0
  v.renderUnsigned = FALSE
  v.exactInt64Valid = FALSE
  v.exactInt64 = 0
  v.exactUInt64Valid = FALSE
  v.exactUInt64 = 0
  if ubound(a) >= lbound(a) then
    redim v.arr(lbound(a) to ubound(a))
    dim i as Integer
    for i = lbound(a) to ubound(a)
      v.arr(i).scalarStorageKind = SSK_FLOATINGPOINT
      v.arr(i).scalar = a(i)
      dim t as LongInt = CLngInt(a(i))
      if a(i) = CDbl(t) then
        v.arr(i).scalarStorageKind = SSK_INT64
        v.arr(i).exactInt64Valid = TRUE
        v.arr(i).exactInt64 = t
        if t >= 0 then
          v.arr(i).exactUInt64Valid = TRUE
          v.arr(i).exactUInt64 = CULngInt(t)
        else
          v.arr(i).exactUInt64Valid = FALSE
          v.arr(i).exactUInt64 = 0
        end if
      else
        v.arr(i).exactInt64Valid = FALSE
        v.arr(i).exactInt64 = 0
        v.arr(i).exactUInt64Valid = FALSE
        v.arr(i).exactUInt64 = 0
      end if
    next i
  else
    erase v.arr
  end if
end sub

private sub ValueInitArrayLike(byref v as EvalValue, byval lb as Integer, byval ub as Integer)
  ValueSetScalar(v, 0)
  v.kind = VK_ARRAY
  if ub >= lb then
    redim v.arr(lb to ub)
  end if
end sub

private sub ValueSetArrayElemFromScalar(byref arrV as EvalValue, byval idx as Integer, byref scalarV as EvalValue)
  arrV.arr(idx) = ScalarValueFromEvalScalar(scalarV)
end sub

private sub ValueGetArrayElemAsScalar(byref arrV as EvalValue, byval idx as Integer, byref outV as EvalValue)
  EvalScalarFromScalarValue(arrV.arr(idx), outV)
end sub

private sub ValueGetElemOrScalar(byref v as EvalValue, byval idx as Integer, byref outV as EvalValue)
  if v.kind = VK_ARRAY then
    ValueGetArrayElemAsScalar(v, idx, outV)
  else
    outV = v
  end if
end sub

private function ValueArrayLen(byref v as EvalValue) as Integer
  if v.kind <> VK_ARRAY then return 0
  if ubound(v.arr) < lbound(v.arr) then return 0
  return ubound(v.arr) - lbound(v.arr) + 1
end function

private sub ValueSetInt64(byref v as EvalValue, byval n as LongInt)
  ValueSetScalar(v, CDbl(n))
  v.scalarStorageKind = SSK_INT64
  v.exactInt64Valid = TRUE
  v.exactInt64 = n
  if n >= 0 then
    v.exactUInt64Valid = TRUE
    v.exactUInt64 = CULngInt(n)
  end if
end sub

'' If n rounds to an exact LongInt in IEEE double, attach the same metadata as ValueSetInt64.
private sub ValueSetScalarPromoteExactInt64(byref v as EvalValue, byval n as Double)
  ValueSetScalar(v, n)
  dim t as LongInt = CLngInt(n)
  if n = CDbl(t) then
    v.scalarStorageKind = SSK_INT64
    v.exactInt64Valid = TRUE
    v.exactInt64 = t
    if t >= 0 then
      v.exactUInt64Valid = TRUE
      v.exactUInt64 = CULngInt(t)
    end if
  end if
end sub

private sub ValueSetUInt64(byref v as EvalValue, byval n as ULongInt)
  const I64_MAX_U as ULongInt = CULngInt(9223372036854775807)
  ValueSetScalar(v, CDbl(n))
  v.scalarStorageKind = SSK_UINT64
  v.exactUInt64Valid = TRUE
  v.exactUInt64 = n
  if n <= I64_MAX_U then
    v.exactInt64Valid = TRUE
    v.exactInt64 = CLngInt(n)
  end if
end sub

private function TryGetExactInt64(byref v as EvalValue, byref outV as LongInt) as Boolean
  const I64_MAX as LongInt = 9223372036854775807
  if v.kind <> VK_SCALAR then return FALSE
  if v.exactInt64Valid then
    outV = v.exactInt64
    return TRUE
  end if
  if v.exactUInt64Valid andalso v.exactUInt64 <= CULngInt(I64_MAX) then
    outV = CLngInt(v.exactUInt64)
    return TRUE
  end if
  dim t as LongInt = CLngInt(v.scalar)
  if v.scalar = CDbl(t) then
    outV = t
    return TRUE
  end if
  return FALSE
end function

private function TryGetExactInt64Scalar(byref s as ScalarValue, byref outV as LongInt) as Boolean
  const I64_MAX as LongInt = 9223372036854775807
  if s.exactInt64Valid then
    outV = s.exactInt64
    return TRUE
  end if
  if s.exactUInt64Valid andalso s.exactUInt64 <= CULngInt(I64_MAX) then
    outV = CLngInt(s.exactUInt64)
    return TRUE
  end if
  dim t as LongInt = CLngInt(s.scalar)
  if s.scalar = CDbl(t) then
    outV = t
    return TRUE
  end if
  return FALSE
end function

private function UniqueHashKeyFromDouble(byval v as Double) as ULongInt
  if v = 0 then return 0 ' Canonicalize +0/-0.
  dim bits as DoubleBits
  bits.d = v
  return bits.u
end function

private function NextPow2AtLeast(byval n as Integer) as Integer
  dim cap as Integer = 1
  while cap < n
    if cap > &h3FFFFFFF then return n
    cap = cap shl 1
  wend
  return cap
end function

private sub SwapDouble(byref a as Double, byref b as Double)
  dim t as Double = a
  a = b
  b = t
end sub

private function TryAddInt64(byval a as LongInt, byval b as LongInt, byref outV as LongInt) as Boolean
  const I64_MAX as LongInt = 9223372036854775807
  const I64_MIN as LongInt = -9223372036854775807 - 1
  if (b > 0 andalso a > I64_MAX - b) orelse (b < 0 andalso a < I64_MIN - b) then return FALSE
  outV = a + b
  return TRUE
end function

private function TrySubInt64(byval a as LongInt, byval b as LongInt, byref outV as LongInt) as Boolean
  const I64_MAX as LongInt = 9223372036854775807
  const I64_MIN as LongInt = -9223372036854775807 - 1
  if (b < 0 andalso a > I64_MAX + b) orelse (b > 0 andalso a < I64_MIN + b) then return FALSE
  outV = a - b
  return TRUE
end function

private function TryMulInt64(byval a as LongInt, byval b as LongInt, byref outV as LongInt) as Boolean
  const I64_MAX as LongInt = 9223372036854775807
  const I64_MIN as LongInt = -9223372036854775807 - 1
  if a = 0 orelse b = 0 then outV = 0: return TRUE
  if a = -1 then
    if b = I64_MIN then return FALSE
    outV = -b
    return TRUE
  end if
  if b = -1 then
    if a = I64_MIN then return FALSE
    outV = -a
    return TRUE
  end if
  if a > 0 then
    if b > 0 then
      if a > I64_MAX \ b then return FALSE
    else
      if b < I64_MIN \ a then return FALSE
    end if
  else
    if b > 0 then
      if a < I64_MIN \ b then return FALSE
    else
      if a <> 0 andalso b < I64_MAX \ a then return FALSE
    end if
  end if
  outV = a * b
  return TRUE
end function

private function TryPowInt64(byval baseV as LongInt, byval expV as LongInt, byref outV as LongInt) as Boolean
  if expV < 0 then return FALSE
  dim r as LongInt = 1
  dim b as LongInt = baseV
  dim e as LongInt = expV
  while e > 0
    if (e and 1) <> 0 then
      if TryMulInt64(r, b, r) = FALSE then return FALSE
    end if
    e = e shr 1
    if e > 0 then
      if TryMulInt64(b, b, b) = FALSE then return FALSE
    end if
  wend
  outV = r
  return TRUE
end function

private function FormatSignedMagnitudeBase(byval iv as LongInt, byval baseN as Integer, byval asUnsigned as Boolean) as String
  dim prefix as String
  select case baseN
    case 16: prefix = "0x"
    case 8: prefix = "0o"
    case else: prefix = "0b"
  end select

  if asUnsigned then
    select case baseN
      case 16: return prefix & Hex(CULngInt(iv))
      case 8: return prefix & Oct(CULngInt(iv))
      case else: return prefix & Bin(CULngInt(iv))
    end select
  end if

  if iv < 0 then
    select case baseN
      case 16: return "-" & prefix & Hex(CULngInt(-iv))
      case 8: return "-" & prefix & Oct(CULngInt(-iv))
      case else: return "-" & prefix & Bin(CULngInt(-iv))
    end select
  end if

  select case baseN
    case 16: return prefix & Hex(CULngInt(iv))
    case 8: return prefix & Oct(CULngInt(iv))
    case else: return prefix & Bin(CULngInt(iv))
  end select
end function

private function FormatHexScalar(byval n as Double, byref outText as String, byval asUnsigned as Boolean = FALSE) as Boolean
  dim iv as LongInt = CLngInt(n)
  if n <> CDbl(iv) then return FALSE
  outText = FormatSignedMagnitudeBase(iv, 16, asUnsigned)
  return TRUE
end function

private function FormatHexUInt64(byval u as ULongInt) as String
  return "0x" & Hex(u)
end function

private function FormatBinScalar(byval n as Double, byref outText as String, byval asUnsigned as Boolean = FALSE) as Boolean
  dim iv as LongInt = CLngInt(n)
  if n <> CDbl(iv) then return FALSE
  outText = FormatSignedMagnitudeBase(iv, 2, asUnsigned)
  return TRUE
end function

private function FormatBinUInt64(byval u as ULongInt) as String
  return "0b" & Bin(u)
end function

private function FormatOctScalar(byval n as Double, byref outText as String, byval asUnsigned as Boolean = FALSE) as Boolean
  dim iv as LongInt = CLngInt(n)
  if n <> CDbl(iv) then return FALSE
  outText = FormatSignedMagnitudeBase(iv, 8, asUnsigned)
  return TRUE
end function

private function FormatOctUInt64(byval u as ULongInt) as String
  return "0o" & Oct(u)
end function

private function ValueToString(byref v as EvalValue) as String
  if v.kind = VK_SCALAR then
    if v.renderBase = 16 then
      if v.exactUInt64Valid then return FormatHexUInt64(v.exactUInt64)
      dim fmtText as String
      if FormatHexScalar(v.scalar, fmtText, v.renderUnsigned) then return fmtText
    elseif v.renderBase = 8 then
      if v.exactUInt64Valid then return FormatOctUInt64(v.exactUInt64)
      dim fmtText as String
      if FormatOctScalar(v.scalar, fmtText, v.renderUnsigned) then return fmtText
    elseif v.renderBase = 2 then
      if v.exactUInt64Valid then return FormatBinUInt64(v.exactUInt64)
      dim fmtText as String
      if FormatBinScalar(v.scalar, fmtText, v.renderUnsigned) then return fmtText
    end if
    if v.exactInt64Valid then return ltrim(str(v.exactInt64))
    return ltrim(str(v.scalar))
  end if

  dim s as String = "("
  dim i as Integer
  for i = lbound(v.arr) to ubound(v.arr)
    if i > lbound(v.arr) then s &= ","
    dim sv as ScalarValue = v.arr(i)
    if v.renderBase = 16 then
      if sv.exactUInt64Valid then
        s &= FormatHexUInt64(sv.exactUInt64)
      else
        dim fmtText as String
        if FormatHexScalar(sv.scalar, fmtText, v.renderUnsigned) then
          s &= fmtText
        else
          if sv.exactInt64Valid then
            s &= ltrim(str(sv.exactInt64))
          else
            s &= ltrim(str(sv.scalar))
          end if
        end if
      end if
    elseif v.renderBase = 8 then
      if sv.exactUInt64Valid then
        s &= FormatOctUInt64(sv.exactUInt64)
      else
        dim fmtText as String
        if FormatOctScalar(sv.scalar, fmtText, v.renderUnsigned) then
          s &= fmtText
        else
          if sv.exactInt64Valid then
            s &= ltrim(str(sv.exactInt64))
          else
            s &= ltrim(str(sv.scalar))
          end if
        end if
      end if
    elseif v.renderBase = 2 then
      if sv.exactUInt64Valid then
        s &= FormatBinUInt64(sv.exactUInt64)
      else
        dim fmtText as String
        if FormatBinScalar(sv.scalar, fmtText, v.renderUnsigned) then
          s &= fmtText
        else
          if sv.exactInt64Valid then
            s &= ltrim(str(sv.exactInt64))
          else
            s &= ltrim(str(sv.scalar))
          end if
        end if
      end if
    else
      if sv.exactInt64Valid then
        s &= ltrim(str(sv.exactInt64))
      else
        s &= ltrim(str(sv.scalar))
      end if
    end if
  next i
  s &= ")"
  return s
end function

private sub SkipSpaces()
  while (pStream[0] = 32) orelse (pStream[0] = 9) orelse (pStream[0] = 10) orelse (pStream[0] = 13)
    pStream += 1
  wend
end sub

private function IsIdentChar(byval ch as UByte) as Boolean
  return ((ch >= 65 andalso ch <= 90) orelse (ch >= 97 andalso ch <= 122) orelse (ch >= 48 andalso ch <= 57) orelse (ch = 95))
end function

private function MatchKeywordOperator(byref kw as String) as Boolean
  dim kwLen as Integer = Len(kw)
  if kwLen <= 0 then return FALSE
  dim kwPtr as UByte Ptr = cast(UByte Ptr, strptr(kw))
  dim i as Integer
  for i = 0 to kwLen - 1
    dim c1 as UByte = pStream[i]
    dim c2 as UByte = kwPtr[i]
    if c1 >= 65 andalso c1 <= 90 then c1 += 32
    if c2 >= 65 andalso c2 <= 90 then c2 += 32
    if c1 <> c2 then return FALSE
  next i
  if IsIdentChar(CUByte(pStream[kwLen])) then return FALSE
  pStream += kwLen
  return TRUE
end function

private function StripLineComment(byref s as String) as String
  dim i as Integer
  for i = 1 to len(s)
    dim ch as String = mid(s, i, 1)
    if ch = "#" then
      return left(s, i - 1)
    end if
    if ch = "/" andalso i < len(s) then
      if mid(s, i + 1, 1) = "/" then
        return left(s, i - 1)
      end if
    end if
  next i
  return s
end function

private function IsBuiltinConstantName(byref n as String) as Boolean
  return TryFindBuiltinConstId(n) >= 0
end function

private function TryGetConstant(byref n as String, byref v as EvalValue) as Boolean
  dim cid as Integer = TryFindBuiltinConstId(n)
  if cid < 0 then return FALSE
  select case cast(BuiltinConstId, cid)
    case CONST_PI
      ValueSetScalar(v, 4.0 * atn(1.0))
    case CONST_E
      ValueSetScalar(v, exp(1.0))
    case else
      return FALSE
  end select
  return TRUE
end function

private function GetVariable(byref n as String, byref v as EvalValue) as Boolean
  if lcase(n) = "ans" then
    dim j as Integer
    for j = lbound(variables) to ubound(variables)
      if variables(j).name = "ans" then
        v = variables(j).value
        return TRUE
      end if
    next j
    return FALSE
  end if
  dim i as Integer
  for i = lbound(variables) to ubound(variables)
    if variables(i).name = n then
      v = variables(i).value
      return TRUE
    end if
  next i
  return FALSE
end function

private function FindVariableIndex(byref n as String) as Integer
  dim i as Integer
  for i = lbound(variables) to ubound(variables)
    if variables(i).name = n then return i
  next i
  return -1
end function

private sub SetVariable(byref n as String, byref v as EvalValue)
  dim i as Integer
  for i = lbound(variables) to ubound(variables)
    if variables(i).name = n then
      variables(i).value = v
      exit sub
    end if
  next i
  if ubound(variables) = -1 then
    redim variables(0)
  else
    redim preserve variables(ubound(variables) + 1)
  end if
  variables(ubound(variables)).name = n
  variables(ubound(variables)).value = v
end sub

private sub SetAnsValue(byref v as EvalValue)
  SetVariable("ans", v)
end sub

private function FindFunctionIndex(byref n as String) as Integer
  dim i as Integer
  for i = lbound(userFunctions) to ubound(userFunctions)
    if userFunctions(i).name = n then return i
  next i
  return -1
end function

private sub SetUserFunction(byref n as String, params() as String, byref expr as String)
  dim idx as Integer = FindFunctionIndex(n)
  if idx < 0 then
    if ubound(userFunctions) = -1 then
      redim userFunctions(0)
    else
      redim preserve userFunctions(ubound(userFunctions) + 1)
    end if
    idx = ubound(userFunctions)
  end if

  userFunctions(idx).name = n
  userFunctions(idx).expr = expr
  if ubound(params) >= lbound(params) then
    with userFunctions(idx)
      redim .params(lbound(params) to ubound(params))
      for i as Integer = lbound(params) to ubound(params)
        .params(i) = params(i)
      next i
    end with
  else
    erase userFunctions(idx).params
  end if
end sub

declare function ParseExpression() as EvalValue
declare function ParseLogicalOr() as EvalValue
declare function ParseLogicalAnd() as EvalValue
declare function ParseLogicalNot() as EvalValue
declare function ParseComparison() as EvalValue
declare function ParseBitwiseOr() as EvalValue
declare function ParseBitwiseXor() as EvalValue
declare function ParseBitwiseAnd() as EvalValue
declare function ParseShift() as EvalValue
declare function ParseAdditive() as EvalValue
declare function ParseMultiplicative() as EvalValue
declare function ParseUnary() as EvalValue
declare function ParsePower() as EvalValue
declare function ParseFactor() as EvalValue

private function TryParseArrayIndex(byref baseValue as EvalValue, byref outValue as EvalValue) as Boolean
  outValue = baseValue
  SkipSpaces()
  if pStream[0] <> 91 then return TRUE ' [

  if baseValue.kind <> VK_ARRAY then
    SetParseError("indexing requires an array value")
    return FALSE
  end if

  pStream += 1
  SkipSpaces()
  if pStream[0] = 93 then
    SetParseError("missing index")
    return FALSE
  end if

  dim idxValue as EvalValue = ParseExpression()
  if parseError then return FALSE
  if idxValue.kind <> VK_SCALAR then
    SetParseError("array index must be a scalar integer")
    return FALSE
  end if

  dim idxRaw as Double = idxValue.scalar
  dim idxInt as Integer = cint(idxRaw)
  if idxRaw <> idxInt then
    SetParseError("array index must be an integer")
    return FALSE
  end if
  SkipSpaces()
  if pStream[0] <> 93 then
    if pStream[0] = 41 then
      SetParseError("mismatched closing parenthesis")
    elseif pStream[0] = 125 then
      SetParseError("mismatched closing brace")
    else
      SetParseError("missing closing bracket")
    end if
    return FALSE
  end if
  pStream += 1

  dim arrLen as Integer = ValueArrayLen(baseValue)
  if idxInt < 0 then idxInt = arrLen + idxInt
  if idxInt < 0 orelse idxInt >= arrLen then
    SetParseError("array index is out of range")
    return FALSE
  end if

  dim rawIdx as Integer = lbound(baseValue.arr) + idxInt
  ValueGetArrayElemAsScalar(baseValue, rawIdx, outValue)
  return TRUE
end function

private function EvaluateUserFunction(byref fnName as String, args() as EvalValue, byref outV as EvalValue) as Boolean
  dim idx as Integer = FindFunctionIndex(fnName)
  if idx < 0 then return FALSE

  dim pCount as Integer = 0
  if ubound(userFunctions(idx).params) >= lbound(userFunctions(idx).params) then
    pCount = ubound(userFunctions(idx).params) - lbound(userFunctions(idx).params) + 1
  end if
  dim aCount as Integer = 0
  if ubound(args) >= lbound(args) then
    aCount = ubound(args) - lbound(args) + 1
  end if
  if pCount <> aCount then
    SetParseError(fnName & "() expects " & ltrim(str(pCount)) & " argument(s), " & ltrim(str(aCount)) & " given")
    return TRUE
  end if

  dim oldExists() as Integer
  dim oldValues() as EvalValue
  if pCount > 0 then
    redim oldExists(0 to pCount - 1)
    redim oldValues(0 to pCount - 1)
  end if

  dim i as Integer
  for i = 0 to pCount - 1
    dim pName as String = userFunctions(idx).params(i)
    dim vIdx as Integer = FindVariableIndex(pName)
    if vIdx >= 0 then
      oldExists(i) = 1
      oldValues(i) = variables(vIdx).value
    else
      oldExists(i) = 0
    end if
    SetVariable(pName, args(i))
  next i

  dim savedStream as ZString ptr = pStream
  dim savedParseError as Integer = parseError
  dim savedWasPercentage as Boolean = wasPercentage
  dim savedExprStart as ZString ptr = exprStart
  dim savedBaseCol as Integer = errorBaseCol

  dim body as String = userFunctions(idx).expr
  pStream = strptr(body)
  exprStart = pStream
  errorBaseCol = 1
  parseError = 0
  outV = ParseExpression()
  SkipSpaces()
  if pStream[0] <> 0 then parseError = 1
  dim evalError as Integer = parseError

  pStream = savedStream
  exprStart = savedExprStart
  errorBaseCol = savedBaseCol
  parseError = savedParseError
  wasPercentage = savedWasPercentage

  for i = 0 to pCount - 1
    dim pName as String = userFunctions(idx).params(i)
    if oldExists(i) = 1 then
      SetVariable(pName, oldValues(i))
    else
      dim vIdx as Integer = FindVariableIndex(pName)
      if vIdx >= 0 then
        if ubound(variables) = lbound(variables) then
          erase variables
        else
          dim j as Integer
          for j = vIdx to ubound(variables) - 1
            variables(j) = variables(j + 1)
          next j
          redim preserve variables(lbound(variables) to ubound(variables) - 1)
        end if
      end if
    end if
  next i

  if evalError <> 0 then parseError = 1
  return TRUE
end function

private function ApplyLogWithBaseScalars(byref valueS as ScalarValue, byref baseS as ScalarValue, byref outV as EvalValue) as Boolean
  if valueS.scalar <= 0 orelse baseS.scalar <= 0 orelse baseS.scalar = 1 then return FALSE
  ValueSetScalarPromoteExactInt64(outV, log(valueS.scalar) / log(baseS.scalar))
  return TRUE
end function

private function ApplyLogWithBase(byref valueV as EvalValue, byref baseV as EvalValue, byref outV as EvalValue) as Boolean
  if valueV.kind = VK_SCALAR andalso baseV.kind = VK_SCALAR then
    return ApplyLogWithBaseScalars(valueV.scalarValue, baseV.scalarValue, outV)
  end if

  dim i as Integer, lb as Integer, ub as Integer
  if valueV.kind = VK_ARRAY andalso baseV.kind = VK_ARRAY andalso ValueArrayLen(valueV) <> ValueArrayLen(baseV) then return FALSE
  if valueV.kind = VK_ARRAY then
    lb = lbound(valueV.arr): ub = ubound(valueV.arr)
  else
    lb = lbound(baseV.arr): ub = ubound(baseV.arr)
  end if
  ValueInitArrayLike(outV, lb, ub)
  dim valueScalarPtr as ScalarValue ptr = 0
  dim baseScalarPtr as ScalarValue ptr = 0
  if valueV.kind = VK_SCALAR then valueScalarPtr = @valueV.scalarValue
  if baseV.kind = VK_SCALAR then baseScalarPtr = @baseV.scalarValue
  for i = lb to ub
    dim r as EvalValue
    dim a as ScalarValue ptr
    dim b as ScalarValue ptr
    if valueV.kind = VK_ARRAY then
      a = @valueV.arr(i)
    else
      a = valueScalarPtr
    end if
    if baseV.kind = VK_ARRAY then
      b = @baseV.arr(i)
    else
      b = baseScalarPtr
    end if
    if ApplyLogWithBaseScalars(*a, *b, r) = FALSE then return FALSE
    ValueSetArrayElemFromScalar(outV, i, r)
  next i
  return TRUE
end function

private function ApplyClamp(byref valueV as EvalValue, byref minV as EvalValue, byref maxV as EvalValue, byref outV as EvalValue) as Boolean
  if minV.kind <> VK_SCALAR orelse maxV.kind <> VK_SCALAR then return FALSE
  if valueV.kind = VK_SCALAR andalso minV.kind = VK_SCALAR andalso maxV.kind = VK_SCALAR then
    dim v as Double = valueV.scalar
    if v < minV.scalar then v = minV.scalar
    if v > maxV.scalar then v = maxV.scalar
    ValueSetScalarPromoteExactInt64(outV, v)
    return TRUE
  end if

  if valueV.kind <> VK_ARRAY then return FALSE
  ValueInitArrayLike(outV, lbound(valueV.arr), ubound(valueV.arr))
  for i as Integer = lbound(valueV.arr) to ubound(valueV.arr)
    dim v as Double = valueV.arr(i).scalar
    if v < minV.scalar then v = minV.scalar
    if v > maxV.scalar then v = maxV.scalar
    dim r as EvalValue
    ValueSetScalarPromoteExactInt64(r, v)
    ValueSetArrayElemFromScalar(outV, i, r)
  next i
  return TRUE
end function

private function GcdInt64(byval a as LongInt, byval b as LongInt) as LongInt
  dim x as ULongInt = CULngInt(abs(a))
  dim y as ULongInt = CULngInt(abs(b))
  while y <> 0
    dim t as ULongInt = x mod y
    x = y
    y = t
  wend
  return CLngInt(x)
end function

private function ApplyGcdLcm(byref aV as EvalValue, byref bV as EvalValue, byval doLcm as Boolean, byref outV as EvalValue) as Boolean
  if aV.kind = VK_SCALAR andalso bV.kind = VK_SCALAR then
    dim a as LongInt, b as LongInt
    if TryGetExactInt64(aV, a) = FALSE orelse TryGetExactInt64(bV, b) = FALSE then return FALSE
    dim g as LongInt = GcdInt64(a, b)
    if doLcm = FALSE then
      ValueSetInt64(outV, g)
      return TRUE
    end if
    if g = 0 then
      ValueSetInt64(outV, 0)
      return TRUE
    end if
    dim q as LongInt = a \ g
    dim l as LongInt
    if TryMulInt64(q, b, l) = FALSE then return FALSE
    if l < 0 then
      if l = -9223372036854775807 - 1 then return FALSE
      l = -l
    end if
    ValueSetInt64(outV, l)
    return TRUE
  end if

  dim i as Integer
  if aV.kind = VK_ARRAY then
    ValueInitArrayLike(outV, lbound(aV.arr), ubound(aV.arr))
    for i = lbound(aV.arr) to ubound(aV.arr)
      dim a as EvalValue, r as EvalValue
      ValueGetArrayElemAsScalar(aV, i, a)
      if ApplyGcdLcm(a, bV, doLcm, r) = FALSE then return FALSE
      ValueSetArrayElemFromScalar(outV, i, r)
    next i
    return TRUE
  end if
  ValueInitArrayLike(outV, lbound(bV.arr), ubound(bV.arr))
  for i = lbound(bV.arr) to ubound(bV.arr)
    dim b as EvalValue, r as EvalValue
    ValueGetArrayElemAsScalar(bV, i, b)
    if ApplyGcdLcm(aV, b, doLcm, r) = FALSE then return FALSE
    ValueSetArrayElemFromScalar(outV, i, r)
  next i
  return TRUE
end function

private function Atan2Compat(byval y as Double, byval x as Double) as Double
  dim piVal as Double = 4.0 * atn(1.0)
  if x > 0 then return atn(y / x)
  if x < 0 then
    if y >= 0 then
      return atn(y / x) + piVal
    else
      return atn(y / x) - piVal
    end if
  end if
  if y > 0 then return piVal / 2.0
  if y < 0 then return -piVal / 2.0
  return 0
end function

private function ApplyUnaryScalarFunction(byref fn as String, byval scalarV as Double, byref outV as EvalValue) as Boolean
  if IsFn(fn, FUNC_SIN) then
    ValueSetScalarPromoteExactInt64(outV, sin(scalarV))
  elseif IsFn(fn, FUNC_COS) then
    ValueSetScalarPromoteExactInt64(outV, cos(scalarV))
  elseif IsFn(fn, FUNC_TAN) then
    ValueSetScalarPromoteExactInt64(outV, tan(scalarV))
  elseif IsFn(fn, FUNC_ASIN) orelse IsFn(fn, FUNC_ARCSIN) then
    ValueSetScalarPromoteExactInt64(outV, asin(scalarV))
  elseif IsFn(fn, FUNC_ACOS) orelse IsFn(fn, FUNC_ARCCOS) then
    ValueSetScalarPromoteExactInt64(outV, acos(scalarV))
  elseif IsFn(fn, FUNC_ATAN) orelse IsFn(fn, FUNC_ARCTAN) then
    ValueSetScalarPromoteExactInt64(outV, atn(scalarV))
  elseif IsFn(fn, FUNC_SINH) then
    ValueSetScalarPromoteExactInt64(outV, sinh(scalarV))
  elseif IsFn(fn, FUNC_COSH) then
    ValueSetScalarPromoteExactInt64(outV, cosh(scalarV))
  elseif IsFn(fn, FUNC_TANH) then
    ValueSetScalarPromoteExactInt64(outV, tanh(scalarV))
  elseif IsFn(fn, FUNC_EXP) then
    ValueSetScalarPromoteExactInt64(outV, exp(scalarV))
  elseif IsFn(fn, FUNC_LN) then
    ValueSetScalarPromoteExactInt64(outV, log(scalarV))
  elseif IsFn(fn, FUNC_LOG10) then
    ValueSetScalarPromoteExactInt64(outV, log(scalarV) / log(10.0))
  elseif IsFn(fn, FUNC_SQRT) then
    ValueSetScalarPromoteExactInt64(outV, sqr(scalarV))
  elseif IsFn(fn, FUNC_SQR) then
    ValueSetScalarPromoteExactInt64(outV, scalarV * scalarV)
  elseif IsFn(fn, FUNC_INT) then
    ValueSetInt64(outV, CLngInt(Fix(scalarV)))
  elseif IsFn(fn, FUNC_FRAC) orelse IsFn(fn, FUNC_FRACT) then
    ValueSetScalarPromoteExactInt64(outV, scalarV - Fix(scalarV))
  elseif IsFn(fn, FUNC_ABS) then
    ValueSetScalarPromoteExactInt64(outV, abs(scalarV))
  elseif IsFn(fn, FUNC_FLOOR) then
    ValueSetInt64(outV, CLngInt(Int(scalarV)))
  elseif IsFn(fn, FUNC_CEIL) then
    ValueSetInt64(outV, CLngInt(-Int(-scalarV)))
  elseif IsFn(fn, FUNC_TRUNC) then
    ValueSetInt64(outV, CLngInt(Fix(scalarV)))
  elseif IsFn(fn, FUNC_ROUND) then
    if scalarV >= 0 then
      ValueSetInt64(outV, CLngInt(Int(scalarV + 0.5)))
    else
      ValueSetInt64(outV, CLngInt(-Int(-scalarV + 0.5)))
    end if
  elseif IsFn(fn, FUNC_SIGN) then
    if scalarV > 0 then
      ValueSetInt64(outV, 1)
    elseif scalarV < 0 then
      ValueSetInt64(outV, -1)
    else
      ValueSetInt64(outV, 0)
    end if
  elseif IsFn(fn, FUNC_DEG) then
    ValueSetScalarPromoteExactInt64(outV, scalarV * 180.0 / (4.0 * atn(1.0)))
  elseif IsFn(fn, FUNC_RAD) then
    ValueSetScalarPromoteExactInt64(outV, scalarV * (4.0 * atn(1.0)) / 180.0)
  else
    return FALSE
  end if
  return TRUE
end function

private function ApplyUnaryFunction(byref fn as String, byref v as EvalValue, byref outV as EvalValue) as Boolean
  dim i as Integer
  if v.kind = VK_SCALAR then
    return ApplyUnaryScalarFunction(fn, v.scalar, outV)
  end if

  if ubound(v.arr) < lbound(v.arr) then
    parseError = 1
    return FALSE
  end if
  ValueInitArrayLike(outV, lbound(v.arr), ubound(v.arr))
  for i = lbound(v.arr) to ubound(v.arr)
    dim tmpOut as EvalValue
    if ApplyUnaryScalarFunction(fn, v.arr(i).scalar, tmpOut) = FALSE then return FALSE
    ValueSetArrayElemFromScalar(outV, i, tmpOut)
  next i
  return TRUE
end function

private function ValueApplyBinaryScalars(byref leftS as ScalarValue, byref rightS as ScalarValue, byval op as UByte, byref outV as EvalValue) as Boolean
  dim li as LongInt, ri as LongInt, ro as LongInt
  dim hasIntL as Boolean = TryGetExactInt64Scalar(leftS, li)
  dim hasIntR as Boolean = TryGetExactInt64Scalar(rightS, ri)
  if hasIntL andalso hasIntR then
    select case op
      case 42
        if TryMulInt64(li, ri, ro) then ValueSetInt64(outV, ro): return TRUE
      case 43
        if TryAddInt64(li, ri, ro) then ValueSetInt64(outV, ro): return TRUE
      case 45
        if TrySubInt64(li, ri, ro) then ValueSetInt64(outV, ro): return TRUE
      case 94
        if TryPowInt64(li, ri, ro) then ValueSetInt64(outV, ro): return TRUE
    end select
  end if

  select case op
    case 42: ValueSetScalarPromoteExactInt64(outV, leftS.scalar * rightS.scalar)
    case 47
      ValueSetScalarPromoteExactInt64(outV, leftS.scalar / rightS.scalar)
    case 43: ValueSetScalarPromoteExactInt64(outV, leftS.scalar + rightS.scalar)
    case 45: ValueSetScalarPromoteExactInt64(outV, leftS.scalar - rightS.scalar)
    case 94: ValueSetScalarPromoteExactInt64(outV, leftS.scalar ^ rightS.scalar)
    case else: return FALSE
  end select
  return TRUE
end function

private function ValueApplyBinary(byref leftV as EvalValue, byref rightV as EvalValue, byval op as UByte, byref outV as EvalValue) as Boolean
  dim i as Integer
  if leftV.kind = VK_SCALAR andalso rightV.kind = VK_SCALAR then
    return ValueApplyBinaryScalars(leftV.scalarValue, rightV.scalarValue, op, outV)
  end if

  dim lb as Integer, ub as Integer
  if leftV.kind = VK_ARRAY andalso rightV.kind = VK_ARRAY then
    if ValueArrayLen(leftV) <> ValueArrayLen(rightV) then return FALSE
    lb = lbound(leftV.arr): ub = ubound(leftV.arr)
    ValueInitArrayLike(outV, lb, ub)
    for i = lb to ub
      dim r as EvalValue
      if ValueApplyBinaryScalars(leftV.arr(i), rightV.arr(i), op, r) = FALSE then return FALSE
      ValueSetArrayElemFromScalar(outV, i, r)
    next i
    return TRUE
  end if

  if leftV.kind = VK_ARRAY then
    lb = lbound(leftV.arr): ub = ubound(leftV.arr)
    ValueInitArrayLike(outV, lb, ub)
    for i = lb to ub
      dim r as EvalValue
      if ValueApplyBinaryScalars(leftV.arr(i), rightV.scalarValue, op, r) = FALSE then return FALSE
      ValueSetArrayElemFromScalar(outV, i, r)
    next i
    return TRUE
  end if

  lb = lbound(rightV.arr): ub = ubound(rightV.arr)
  ValueInitArrayLike(outV, lb, ub)
  for i = lb to ub
    dim r as EvalValue
    if ValueApplyBinaryScalars(leftV.scalarValue, rightV.arr(i), op, r) = FALSE then return FALSE
    ValueSetArrayElemFromScalar(outV, i, r)
  next i
  return TRUE
end function

private function ValueApplyBinaryInt64Scalars(byref leftS as ScalarValue, byref rightS as ScalarValue, byref op as String, byref outV as EvalValue) as Boolean
  dim requiresIntegers as Boolean = (op = "<<" orelse op = ">>" orelse op = "&" orelse op = "^" orelse op = "|" orelse op = OpName(OP_MOD))
  dim l as LongInt, r as LongInt

  if requiresIntegers then
    if (TryGetExactInt64Scalar(leftS, l) = FALSE) orelse (TryGetExactInt64Scalar(rightS, r) = FALSE) then
      if op = OpName(OP_MOD) then
        SetParseError("modulo operands must be integer values")
      else
        SetParseError("bitwise operands must be integer values")
      end if
      return FALSE
    end if
  end if

  select case op
    case "<<"
      if r < 0 orelse r > 63 then return FALSE
      ValueSetInt64(outV, l shl r)
    case ">>"
      if r < 0 orelse r > 63 then return FALSE
      ValueSetInt64(outV, l shr r)
    case "&"
      ValueSetInt64(outV, l and r)
    case "^"
      ValueSetInt64(outV, l xor r)
    case "|"
      ValueSetInt64(outV, l or r)
    case OpName(OP_MOD)
      if r = 0 then return FALSE
      ValueSetInt64(outV, l mod r)
    case else
      return FALSE
  end select
  return TRUE
end function

private function ValueApplyBinaryInt64(byref leftV as EvalValue, byref rightV as EvalValue, byref op as String, byref outV as EvalValue) as Boolean
  dim i as Integer
  if leftV.kind = VK_SCALAR andalso rightV.kind = VK_SCALAR then
    return ValueApplyBinaryInt64Scalars(leftV.scalarValue, rightV.scalarValue, op, outV)
  end if

  dim lb as Integer, ub as Integer
  if leftV.kind = VK_ARRAY andalso rightV.kind = VK_ARRAY then
    if ValueArrayLen(leftV) <> ValueArrayLen(rightV) then return FALSE
    lb = lbound(leftV.arr): ub = ubound(leftV.arr)
    ValueInitArrayLike(outV, lb, ub)
    for i = lb to ub
      dim r as EvalValue
      if ValueApplyBinaryInt64Scalars(leftV.arr(i), rightV.arr(i), op, r) = FALSE then return FALSE
      ValueSetArrayElemFromScalar(outV, i, r)
    next i
    return TRUE
  end if

  if leftV.kind = VK_ARRAY then
    lb = lbound(leftV.arr): ub = ubound(leftV.arr)
    ValueInitArrayLike(outV, lb, ub)
    for i = lb to ub
      dim r as EvalValue
      if ValueApplyBinaryInt64Scalars(leftV.arr(i), rightV.scalarValue, op, r) = FALSE then return FALSE
      ValueSetArrayElemFromScalar(outV, i, r)
    next i
    return TRUE
  end if

  lb = lbound(rightV.arr): ub = ubound(rightV.arr)
  ValueInitArrayLike(outV, lb, ub)
  for i = lb to ub
    dim r as EvalValue
    if ValueApplyBinaryInt64Scalars(leftV.scalarValue, rightV.arr(i), op, r) = FALSE then return FALSE
    ValueSetArrayElemFromScalar(outV, i, r)
  next i
  return TRUE
end function

private function CompareScalarArrayLex(byval scalarV as Double, byref arrV as EvalValue) as Integer
  dim arrLen as Integer = ValueArrayLen(arrV)
  if arrLen <= 0 then return 1
  dim firstVal as Double = arrV.arr(lbound(arrV.arr)).scalar
  if scalarV < firstVal then return -1
  if scalarV > firstVal then return 1
  if arrLen = 1 then return 0
  return -1
end function

private function CompareEvalValues(byref leftV as EvalValue, byref rightV as EvalValue, byref cmp as Integer) as Boolean
  if leftV.kind = VK_SCALAR andalso rightV.kind = VK_SCALAR then
    if leftV.scalar < rightV.scalar then
      cmp = -1
    elseif leftV.scalar > rightV.scalar then
      cmp = 1
    else
      cmp = 0
    end if
    return TRUE
  end if

  if leftV.kind = VK_SCALAR then
    cmp = CompareScalarArrayLex(leftV.scalar, rightV)
    return TRUE
  end if
  if rightV.kind = VK_SCALAR then
    cmp = -CompareScalarArrayLex(rightV.scalar, leftV)
    return TRUE
  end if

  dim leftLen as Integer = ValueArrayLen(leftV)
  dim rightLen as Integer = ValueArrayLen(rightV)
  dim minLen as Integer = IIf(leftLen < rightLen, leftLen, rightLen)
  dim leftLb as Integer = lbound(leftV.arr)
  dim rightLb as Integer = lbound(rightV.arr)
  dim i as Integer
  for i = 0 to minLen - 1
    dim lv as Double = leftV.arr(leftLb + i).scalar
    dim rv as Double = rightV.arr(rightLb + i).scalar
    if lv < rv then
      cmp = -1
      return TRUE
    elseif lv > rv then
      cmp = 1
      return TRUE
    end if
  next i
  if leftLen < rightLen then
    cmp = -1
  elseif leftLen > rightLen then
    cmp = 1
  else
    cmp = 0
  end if
  return TRUE
end function

private function ApplyComparison(byref leftV as EvalValue, byref rightV as EvalValue, byref op as String, byref outV as EvalValue) as Boolean
  dim cmp as Integer = 0
  if CompareEvalValues(leftV, rightV, cmp) = FALSE then return FALSE
  dim isTrue as Boolean = FALSE
  select case op
    case "=", "=="
      isTrue = (cmp = 0)
    case "<>", "!="
      isTrue = (cmp <> 0)
    case "<"
      isTrue = (cmp < 0)
    case "<="
      isTrue = (cmp <= 0)
    case ">"
      isTrue = (cmp > 0)
    case ">="
      isTrue = (cmp >= 0)
    case else
      return FALSE
  end select
  if isTrue then
    ValueSetInt64(outV, 1)
  else
    ValueSetInt64(outV, 0)
  end if
  return TRUE
end function

private function EvalValueIsTruthy(byref v as EvalValue) as Boolean
  if v.kind = VK_ARRAY then
    return (ValueArrayLen(v) > 0)
  end if
  return (v.scalar <> 0)
end function

private sub ValueSetBoolResult(byval b as Boolean, byref outV as EvalValue)
  if b then
    ValueSetInt64(outV, 1)
  else
    ValueSetInt64(outV, 0)
  end if
end sub

private function ApplyInt64ParserOp(byref leftV as EvalValue, byref rightV as EvalValue, byref op as String, byref outV as EvalValue) as Boolean
  if ValueApplyBinaryInt64(leftV, rightV, op, outV) = FALSE then
    SetParseError("incompatible operands")
    return FALSE
  end if
  return TRUE
end function

private function EnsureExactArgCount(args() as EvalValue, byval expectedCount as Integer, byref fnName as String) as Boolean
  dim argc as Integer = ubound(args) + 1
  if argc <> expectedCount then
    SetParseError(fnName & "() expects " & ltrim(str(expectedCount)) & " argument(s), " & ltrim(str(argc)) & " given")
    return FALSE
  end if
  return TRUE
end function

private function IsPercentageTail() as Boolean
  dim p as ZString ptr = pStream
  while (p[0] = 32) orelse (p[0] = 9) orelse (p[0] = 10) orelse (p[0] = 13)
    p += 1
  wend

  dim ch as UByte = p[0]
  if (ch = 0) orelse (ch = 41) orelse (ch = 43) orelse (ch = 45) _
     orelse (ch = 44) orelse (ch = 59) orelse (ch = 93) orelse (ch = 125) then
    return TRUE
  end if
  return FALSE
end function

private function IsImplicitMulStart() as Boolean
  ' Allow implicit multiplication only for parenthesized expressions: x(y+z) => x*(y+z)
  if pStream[0] = 40 then return TRUE
  return FALSE
end function

declare function ArgScalarWalkNext(args() as EvalValue, byref argIdx as Integer, byref elemIdx as Integer, byref outV as Double) as Boolean
declare function ArgScalarValueWalkNext(args() as EvalValue, byref argIdx as Integer, byref elemIdx as Integer, byref outS as ScalarValue) as Boolean

private function CollectArgsAsFlat(args() as EvalValue, flat() as Double) as Integer
  dim count as Integer = 0
  dim i as Integer

  for i = lbound(args) to ubound(args)
    if args(i).kind = VK_SCALAR then
      count = count + 1
    else
      count += ValueArrayLen(args(i))
    end if
  next i

  if count <= 0 then return 0
  redim flat(0 to count - 1)

  dim flatPos as Integer = 0
  dim argIdx as Integer = lbound(args)
  dim elemIdx as Integer = -1
  dim item as Double
  while ArgScalarWalkNext(args(), argIdx, elemIdx, item)
    flat(flatPos) = item
    flatPos += 1
  wend
  return count
end function

private function CollectRequiredArgsAsFlat(args() as EvalValue, flat() as Double, byref fnName as String) as Integer
  dim count as Integer = CollectArgsAsFlat(args(), flat())
  if count <= 0 then
    SetParseError(fnName & "() expects at least 1 argument")
    return 0
  end if
  return count
end function

private function CopySingleArgToFlat(byref a as EvalValue, flat() as Double, byval reverseOrder as Boolean) as Integer
  if a.kind = VK_SCALAR then
    redim flat(0 to 0)
    flat(0) = a.scalar
    return 1
  end if
  dim c as Integer = ValueArrayLen(a)
  if c <= 0 then return 0
  redim flat(0 to c - 1)
  dim i as Integer
  if reverseOrder then
    for i = 0 to c - 1
      flat(i) = a.arr(ubound(a.arr) - i).scalar
    next i
  else
    for i = 0 to c - 1
      flat(i) = a.arr(lbound(a.arr) + i).scalar
    next i
  end if
  return c
end function

private function ArgScalarWalkNext(args() as EvalValue, byref argIdx as Integer, byref elemIdx as Integer, byref outV as Double) as Boolean
  if ubound(args) = -1 then return FALSE
  do while argIdx <= ubound(args)
    if args(argIdx).kind = VK_SCALAR then
      outV = args(argIdx).scalar
      argIdx += 1
      elemIdx = -1
      return TRUE
    else
      if elemIdx = -1 then elemIdx = lbound(args(argIdx).arr)
      if elemIdx <= ubound(args(argIdx).arr) then
        outV = args(argIdx).arr(elemIdx).scalar
        elemIdx += 1
        return TRUE
      end if
      argIdx += 1
      elemIdx = -1
    end if
  loop
  return FALSE
end function

private function ArgScalarValueWalkNext(args() as EvalValue, byref argIdx as Integer, byref elemIdx as Integer, byref outS as ScalarValue) as Boolean
  if ubound(args) = -1 then return FALSE
  do while argIdx <= ubound(args)
    if args(argIdx).kind = VK_SCALAR then
      outS = args(argIdx).scalarValue
      argIdx += 1
      elemIdx = -1
      return TRUE
    else
      if elemIdx = -1 then elemIdx = lbound(args(argIdx).arr)
      if elemIdx <= ubound(args(argIdx).arr) then
        outS = args(argIdx).arr(elemIdx)
        elemIdx += 1
        return TRUE
      end if
      argIdx += 1
      elemIdx = -1
    end if
  loop
  return FALSE
end function

private function ExpandUnpackedArgs(argsIn() as EvalValue, argsOut() as EvalValue) as Integer
  dim outCount as Integer = 0
  dim i as Integer, j as Integer
  dim hasExpandMarkers as Boolean = FALSE
  erase argsOut
  if ubound(argsIn) = -1 then return 0

  ' Pre-count once and allocate once to avoid repeated redim preserve.
  for i = lbound(argsIn) to ubound(argsIn)
    if argsIn(i).expandArgs then hasExpandMarkers = TRUE
    if argsIn(i).expandArgs andalso argsIn(i).kind = VK_ARRAY then
      outCount += ValueArrayLen(argsIn(i))
    else
      outCount += 1
    end if
  next i
  if hasExpandMarkers = FALSE then return 0
  if outCount <= 0 then return 0
  redim argsOut(0 to outCount - 1)

  dim outPos as Integer = 0
  for i = lbound(argsIn) to ubound(argsIn)
    if argsIn(i).expandArgs then
      if argsIn(i).kind = VK_ARRAY then
        for j = lbound(argsIn(i).arr) to ubound(argsIn(i).arr)
          EvalScalarFromScalarValue(argsIn(i).arr(j), argsOut(outPos))
          outPos += 1
        next j
      else
        argsOut(outPos) = argsIn(i)
        argsOut(outPos).expandArgs = FALSE
        outPos += 1
      end if
    else
      argsOut(outPos) = argsIn(i)
      outPos += 1
    end if
  next i

  return outPos
end function

private sub NormalizeCallArgs(args() as EvalValue)
  dim expandedArgs() as EvalValue
  dim expandedCount as Integer = ExpandUnpackedArgs(args(), expandedArgs())
  if expandedCount <= 0 then exit sub
  erase args
  redim args(0 to expandedCount - 1)
  for i as Integer = 0 to expandedCount - 1
    args(i) = expandedArgs(i)
  next i
end sub

private sub SortDoubleArray(a() as Double)
  dim lo as Integer = lbound(a)
  dim hi as Integer = ubound(a)
  if hi <= lo then exit sub

  ' Iterative quicksort with insertion-sort fallback for short ranges.
  dim leftStack(0 to 63) as Integer
  dim rightStack(0 to 63) as Integer
  dim sp as Integer = 0
  leftStack(0) = lo
  rightStack(0) = hi

  do while sp >= 0
    lo = leftStack(sp)
    hi = rightStack(sp)
    sp -= 1

    do while (hi - lo) > 16
      dim midIdx as Integer = lo + ((hi - lo) \ 2)
      dim pivot as Double = a(midIdx)
      dim i as Integer = lo
      dim j as Integer = hi
      do
        while a(i) < pivot
          i += 1
        wend
        while a(j) > pivot
          j -= 1
        wend
        if i <= j then
          dim t as Double = a(i)
          a(i) = a(j)
          a(j) = t
          i += 1
          j -= 1
        end if
      loop while i <= j

      ' Process smaller partition first (tail-recursive elimination).
      if (j - lo) < (hi - i) then
        if i < hi then
          sp += 1
          leftStack(sp) = i
          rightStack(sp) = hi
        end if
        hi = j
      else
        if lo < j then
          sp += 1
          leftStack(sp) = lo
          rightStack(sp) = j
        end if
        lo = i
      end if
    loop

    ' Insertion sort on small range.
    dim x as Integer
    for x = lo + 1 to hi
      dim v as Double = a(x)
      dim y as Integer = x - 1
      while y >= lo andalso a(y) > v
        a(y + 1) = a(y)
        y -= 1
      wend
      a(y + 1) = v
    next x
  loop
end sub

private sub ReverseDoubleArrayInPlace(a() as Double, byval count as Integer)
  dim i as Integer
  for i = 0 to (count \ 2) - 1
    dim t as Double = a(i)
    a(i) = a(count - 1 - i)
    a(count - 1 - i) = t
  next i
end sub

private sub ValueSetSingleScalarArray(byref outV as EvalValue, byval x as Double)
  dim tmp(0 to 0) as Double
  tmp(0) = x
  ValueSetArray(outV, tmp())
end sub

private function TryApplyFactorial(byref v as EvalValue, byref outV as EvalValue) as Boolean
  if v.kind = VK_ARRAY then return FALSE
  dim n as LongInt
  if TryGetExactInt64(v, n) = FALSE then return FALSE
  if n < 0 then return FALSE

  static factTable(0 to 20) as LongInt = { _
    1ll, 1ll, 2ll, 6ll, 24ll, 120ll, 720ll, 5040ll, 40320ll, 362880ll, _
    3628800ll, 39916800ll, 479001600ll, 6227020800ll, 87178291200ll, 1307674368000ll, _
    20922789888000ll, 355687428096000ll, 6402373705728000ll, 121645100408832000ll, 2432902008176640000ll }
  if n <= 20 then
    ValueSetInt64(outV, factTable(n))
    return TRUE
  end if

  dim d as Double = CDbl(factTable(20))
  for i as LongInt = 21 to n
    d *= CDbl(i)
  next i
  ValueSetScalar(outV, d)
  return TRUE
end function

private function ParseFunctionCall(byref fnName as String) as EvalValue
  dim outV as EvalValue
  if pStream[0] <> 40 then SetParseError("missing opening bracket"): return outV
  pStream += 1
  SkipSpaces()

  dim args() as EvalValue
  dim argsCount as Integer = 0
  dim argsCap as Integer = 0
  if pStream[0] = 44 then
    SetParseError("unexpected comma")
    return outV
  end if
  if pStream[0] <> 41 then
    do
      if pStream[0] = 44 then
        SetParseError("unexpected comma")
        return outV
      end if
      dim a as EvalValue = ParseExpression()
      if parseError then return outV
      if argsCount >= argsCap then
        if argsCap = 0 then
          argsCap = 4
        else
          argsCap = argsCap * 2
        end if
        if argsCount = 0 then
          redim args(0 to argsCap - 1)
        else
          redim preserve args(0 to argsCap - 1)
        end if
      end if
      args(argsCount) = a
      argsCount += 1
      SkipSpaces()
      if pStream[0] = 44 then
        pStream += 1
        SkipSpaces()
        if pStream[0] = 41 orelse pStream[0] = 44 then
          SetParseError("unexpected comma")
          return outV
        end if
      else
        exit do
      end if
    loop
  end if

  if pStream[0] = 41 then
    pStream += 1
  elseif pStream[0] = 93 then
    SetParseError("mismatched closing bracket")
  elseif pStream[0] = 125 then
    SetParseError("mismatched closing brace")
  else
    SetParseError("missing closing parenthesis")
  end if
  if parseError then return outV

  if argsCount = 0 then
    erase args
  elseif argsCap <> argsCount then
    redim preserve args(0 to argsCount - 1)
  end if

  dim fn as String = lcase(fnName)
  dim flat() as Double
  dim c as Integer = 0
  NormalizeCallArgs(args())

  if IsFn(fn, FUNC_SUM) orelse IsFn(fn, FUNC_PRODUCT) orelse IsFn(fn, FUNC_PROD) orelse IsFn(fn, FUNC_MIN) orelse IsFn(fn, FUNC_MAX) _
     orelse IsFn(fn, FUNC_AVG) orelse IsFn(fn, FUNC_MEAN) orelse IsFn(fn, FUNC_MEDIAN) orelse IsFn(fn, FUNC_VARIANCE) orelse IsFn(fn, FUNC_STDDEV) then
    if ubound(args) = -1 then SetParseError(fnName & "() expects at least 1 argument"): return outV
    if ubound(args) = 0 andalso args(0).kind = VK_SCALAR then
      if IsFn(fn, FUNC_SUM) orelse IsFn(fn, FUNC_PRODUCT) orelse IsFn(fn, FUNC_PROD) _
         orelse IsFn(fn, FUNC_MIN) orelse IsFn(fn, FUNC_MAX) orelse IsFn(fn, FUNC_AVG) orelse IsFn(fn, FUNC_MEAN) then
        ValueSetScalarPromoteExactInt64(outV, args(0).scalar)
        return outV
      end if
    end if
    dim acc as Double = 0
    dim i as Integer
    if IsFn(fn, FUNC_SUM) orelse IsFn(fn, FUNC_PRODUCT) orelse IsFn(fn, FUNC_PROD) _
       orelse IsFn(fn, FUNC_MIN) orelse IsFn(fn, FUNC_MAX) orelse IsFn(fn, FUNC_AVG) orelse IsFn(fn, FUNC_MEAN) then
      dim itemCount as Integer = 0
      dim hasValue as Boolean = FALSE
      dim aggMode as Integer = 0 '1=sum/avg/mean, 2=product, 3=min, 4=max
      if IsFn(fn, FUNC_PRODUCT) orelse IsFn(fn, FUNC_PROD) then
        aggMode = 2
        acc = 1
      elseif IsFn(fn, FUNC_MIN) then
        aggMode = 3
      elseif IsFn(fn, FUNC_MAX) then
        aggMode = 4
      else
        aggMode = 1
      end if
      dim argIdx as Integer = lbound(args)
      dim elemIdx as Integer = -1
      dim v as Double
      while ArgScalarWalkNext(args(), argIdx, elemIdx, v)
        if aggMode = 1 then
          acc += v
        elseif aggMode = 2 then
          acc *= v
        elseif aggMode = 3 then
          if (hasValue = FALSE) orelse (v < acc) then acc = v
          hasValue = TRUE
        else
          if (hasValue = FALSE) orelse (v > acc) then acc = v
          hasValue = TRUE
        end if
        itemCount += 1
      wend
      if itemCount <= 0 then SetParseError(fnName & "() expects at least 1 argument"): return outV
      if IsFn(fn, FUNC_AVG) orelse IsFn(fn, FUNC_MEAN) then acc /= itemCount
    elseif IsFn(fn, FUNC_MEDIAN) then
      if ubound(args) = lbound(args) then
        dim onlyIdx as Integer = lbound(args)
        if args(onlyIdx).kind = VK_SCALAR then
          acc = args(onlyIdx).scalar
          ValueSetScalarPromoteExactInt64(outV, acc)
          return outV
        end if
        c = ValueArrayLen(args(onlyIdx))
        if c = 1 then
          acc = args(onlyIdx).arr(lbound(args(onlyIdx).arr)).scalar
          ValueSetScalarPromoteExactInt64(outV, acc)
          return outV
        end if
      end if
      c = CollectRequiredArgsAsFlat(args(), flat(), fnName)
      if c <= 0 then return outV
      dim midIdx as Integer = c \ 2
      dim leftIdx as Integer = 0
      dim rightIdx as Integer = c - 1
      dim kIdx as Integer = midIdx
      do while leftIdx < rightIdx
        dim pivot as Double = flat((leftIdx + rightIdx) \ 2)
        i = leftIdx
        dim j as Integer = rightIdx
        do
          while flat(i) < pivot
            i += 1
          wend
          while flat(j) > pivot
            j -= 1
          wend
          if i <= j then
            SwapDouble(flat(i), flat(j))
            i += 1
            j -= 1
          end if
        loop while i <= j
        if kIdx <= j then
          rightIdx = j
        elseif kIdx >= i then
          leftIdx = i
        else
          exit do
        end if
      loop
      dim upper as Double = flat(kIdx)
      if (c and 1) = 1 then
        acc = upper
      else
        dim lower as Double = flat(0)
        for i = 1 to midIdx - 1
          if flat(i) > lower then lower = flat(i)
        next i
        acc = (lower + upper) / 2
      end if
    elseif IsFn(fn, FUNC_VARIANCE) orelse IsFn(fn, FUNC_STDDEV) then
      ' Welford single-pass accumulation for better stability and fewer passes.
      dim meanVal as Double = 0
      dim m2 as Double = 0
      dim n as Integer = 0
      dim argIdxVar as Integer = lbound(args)
      dim elemIdxVar as Integer = -1
      dim vVar as Double
      while ArgScalarWalkNext(args(), argIdxVar, elemIdxVar, vVar)
        n += 1
        dim delta as Double = vVar - meanVal
        meanVal += delta / n
        dim delta2 as Double = vVar - meanVal
        m2 += delta * delta2
      wend
      if n <= 0 then SetParseError(fnName & "() expects at least 1 argument"): return outV
      acc = m2 / n
      if IsFn(fn, FUNC_STDDEV) then acc = sqr(acc)
    else
      c = CollectRequiredArgsAsFlat(args(), flat(), fnName)
      if c <= 0 then return outV
      acc = flat(0)
      for i = 1 to c - 1
        if flat(i) > acc then acc = flat(i)
      next i
    end if
    ValueSetScalarPromoteExactInt64(outV, acc)
    return outV
  end if

  if IsFn(fn, FUNC_SORT) orelse IsFn(fn, FUNC_SORTED) then
    if ubound(args) = -1 then SetParseError(fnName & "() expects at least 1 argument"): return outV
    if ubound(args) = 0 then
      if args(0).kind = VK_SCALAR then
        ValueSetSingleScalarArray(outV, args(0).scalar)
        return outV
      end if
      c = CopySingleArgToFlat(args(0), flat(), FALSE)
      if c <= 0 then SetParseError(fnName & "() expects at least 1 argument"): return outV
      SortDoubleArray(flat())
      ValueSetArray(outV, flat())
      return outV
    end if
    c = CollectRequiredArgsAsFlat(args(), flat(), fnName)
    if c <= 0 then return outV
    SortDoubleArray(flat())
    ValueSetArray(outV, flat())
    return outV
  end if

  if IsFn(fn, FUNC_REVERSE) orelse IsFn(fn, FUNC_REVERSED) then
    if ubound(args) = -1 then SetParseError(fnName & "() expects at least 1 argument"): return outV
    if ubound(args) = 0 then
      if args(0).kind = VK_SCALAR then
        ValueSetSingleScalarArray(outV, args(0).scalar)
        return outV
      end if
      c = CopySingleArgToFlat(args(0), flat(), TRUE)
      if c <= 0 then SetParseError(fnName & "() expects at least 1 argument"): return outV
      ValueSetArray(outV, flat())
      return outV
    end if
    c = CollectRequiredArgsAsFlat(args(), flat(), fnName)
    if c <= 0 then return outV
    ReverseDoubleArrayInPlace(flat(), c)
    ValueSetArray(outV, flat())
    return outV
  end if

  if IsFn(fn, FUNC_UNPACK) then
    if ubound(args) = -1 then
      SetParseError(fnName & "() expects at least 1 argument")
      return outV
    end if
    if ubound(args) = 0 then
      outV = args(0)
    else
      c = CollectRequiredArgsAsFlat(args(), flat(), fnName)
      if c <= 0 then return outV
      ValueSetArray(outV, flat())
    end if
    outV.expandArgs = TRUE
    return outV
  end if

  if IsFn(fn, FUNC_UNIQUE) then
    if ubound(args) = -1 then SetParseError(fnName & "() expects at least 1 argument"): return outV
    if ubound(args) = 0 then
      if args(0).kind = VK_SCALAR then
        ValueSetSingleScalarArray(outV, args(0).scalar)
        return outV
      end if
      c = CopySingleArgToFlat(args(0), flat(), FALSE)
      if c <= 0 then SetParseError(fnName & "() expects at least 1 argument"): return outV
    else
      c = CollectRequiredArgsAsFlat(args(), flat(), fnName)
      if c <= 0 then return outV
    end if
    dim tmp() as Double, keys() as ULongInt, used() as UByte
    redim tmp(0 to c - 1)
    dim cap as Integer = NextPow2AtLeast(c * 2)
    if cap < 4 then cap = 4
    redim keys(0 to cap - 1)
    redim used(0 to cap - 1)
    dim outCount as Integer = 0
    dim i as Integer
    for i = 0 to c - 1
      dim v as Double = flat(i)
      dim seen as Boolean = FALSE
      if v <> v then
        tmp(outCount) = v
        outCount += 1
        continue for
      end if
      dim key as ULongInt = UniqueHashKeyFromDouble(v)
      dim idx as Integer = CInt(key and CULngInt(cap - 1))
      do
        if used(idx) = 0 then exit do
        if keys(idx) = key then
          seen = TRUE
          exit do
        end if
        idx = (idx + 1) and (cap - 1)
      loop
      if seen = FALSE then
        used(idx) = 1
        keys(idx) = key
        tmp(outCount) = v
        outCount += 1
      end if
    next i

    redim preserve tmp(0 to outCount - 1)
    ValueSetArray(outV, tmp())
    return outV
  end if

  if IsFn(fn, FUNC_LOG) then
    if EnsureExactArgCount(args(), 2, fnName) = FALSE then return outV
    if ApplyLogWithBase(args(0), args(1), outV) = FALSE then SetParseError("numeric error in " & fnName & "()")
    return outV
  end if

  if IsFn(fn, FUNC_ATAN2) then
    if EnsureExactArgCount(args(), 2, fnName) = FALSE then return outV
    if args(0).kind = VK_SCALAR andalso args(1).kind = VK_SCALAR then
      ValueSetScalarPromoteExactInt64(outV, Atan2Compat(args(0).scalar, args(1).scalar))
    else
      SetParseError("numeric error in " & fnName & "()")
    end if
    return outV
  end if

  if IsFn(fn, FUNC_HYPOT) then
    if EnsureExactArgCount(args(), 2, fnName) = FALSE then return outV
    dim a2 as EvalValue, b2 as EvalValue, s2 as EvalValue
    if ValueApplyBinary(args(0), args(0), 42, a2) = FALSE then SetParseError("numeric error in " & fnName & "()"): return outV
    if ValueApplyBinary(args(1), args(1), 42, b2) = FALSE then SetParseError("numeric error in " & fnName & "()"): return outV
    if ValueApplyBinary(a2, b2, 43, s2) = FALSE then SetParseError("numeric error in " & fnName & "()"): return outV
    if ApplyUnaryFunction(GetFunctionName(FUNC_SQRT), s2, outV) = FALSE then SetParseError("numeric error in " & fnName & "()")
    return outV
  end if

  if IsFn(fn, FUNC_MOD) then
    if EnsureExactArgCount(args(), 2, fnName) = FALSE then return outV
    dim opMod as String = OpName(OP_MOD)
    if ValueApplyBinaryInt64(args(0), args(1), opMod, outV) = FALSE andalso parseError = 0 then SetParseError("numeric error in " & fnName & "()")
    return outV
  end if

  if IsFn(fn, FUNC_FACT) orelse IsFn(fn, FUNC_FACTORIAL) then
    if ubound(args) <> 0 then
      dim argc as Integer = ubound(args) + 1
      SetParseError(fnName & "() expects 1 argument(s), " & ltrim(str(argc)) & " given")
      return outV
    end if
    if TryApplyFactorial(args(0), outV) = FALSE then
      SetParseError(fnName & "() expects a non-negative integer")
    end if
    return outV
  end if

  if IsFn(fn, FUNC_RAND) then
    if ubound(args) <> -1 then
      dim argc as Integer = ubound(args) + 1
      SetParseError(fnName & "() expects 0 argument(s), " & ltrim(str(argc)) & " given")
      return outV
    end if
    ValueSetScalarPromoteExactInt64(outV, rnd)
    return outV
  end if

  if IsFn(fn, FUNC_RANDOM) then
    if ubound(args) <> 1 then
      dim argc as Integer = ubound(args) + 1
      SetParseError(fnName & "() expects 2 argument(s), " & ltrim(str(argc)) & " given")
      return outV
    end if
    if args(0).kind <> VK_SCALAR orelse args(1).kind <> VK_SCALAR then
      SetParseError(fnName & "() expects scalar values")
      return outV
    end if
    ValueSetScalarPromoteExactInt64(outV, args(0).scalar + (args(1).scalar - args(0).scalar) * rnd)
    return outV
  end if

  if IsFn(fn, FUNC_CLAMP) then
    if ubound(args) <> 2 then
      dim argc as Integer = ubound(args) + 1
      SetParseError(fnName & "() expects 3 argument(s), " & ltrim(str(argc)) & " given")
      return outV
    end if
    if args(1).kind <> VK_SCALAR orelse args(2).kind <> VK_SCALAR then
      SetParseError(fnName & "() expects scalar min/max")
      return outV
    end if
    if ApplyClamp(args(0), args(1), args(2), outV) = FALSE then SetParseError("numeric error in " & fnName & "()")
    return outV
  end if

  if IsFn(fn, FUNC_GCD) orelse IsFn(fn, FUNC_LCM) then
    if ubound(args) <> 1 then
      dim argc as Integer = ubound(args) + 1
      SetParseError(fnName & "() expects 2 argument(s), " & ltrim(str(argc)) & " given")
      return outV
    end if
    if args(0).kind <> VK_SCALAR orelse args(1).kind <> VK_SCALAR then
      SetParseError(fnName & "() expects scalar values")
      return outV
    end if
    if ApplyGcdLcm(args(0), args(1), IsFn(fn, FUNC_LCM), outV) = FALSE then
      SetParseError(fnName & "() expects integer values")
    end if
    return outV
  end if

  if IsFn(fn, FUNC_HEX) orelse IsFn(fn, FUNC_OCT) orelse IsFn(fn, FUNC_BIN) orelse _
     IsFn(fn, FUNC_UHEX) orelse IsFn(fn, FUNC_UOCT) orelse IsFn(fn, FUNC_UBIN) then
    if ubound(args) = -1 then
      SetParseError(fnName & "() expects at least 1 argument")
      return outV
    end if
    if ubound(args) = 0 then
      outV = args(0)
    else
      c = 0
      for i as Integer = lbound(args) to ubound(args)
        if args(i).kind = VK_SCALAR then
          c += 1
        else
          c += ValueArrayLen(args(i))
        end if
      next i
      if c <= 0 then
        SetParseError(fnName & "() expects at least 1 argument")
        return outV
      end if
      redim flat(0 to c - 1)
      dim argIdxFmt as Integer = lbound(args)
      dim elemIdxFmt as Integer = -1
      dim vFmt as Double
      dim outPosFmt as Integer = 0
      while ArgScalarWalkNext(args(), argIdxFmt, elemIdxFmt, vFmt)
        flat(outPosFmt) = vFmt
        outPosFmt += 1
      wend
      ValueSetArray(outV, flat())
    end if
    dim fmtBase as Integer = IIf(IsFn(fn, FUNC_HEX) orelse IsFn(fn, FUNC_UHEX), 16, _
                                 IIf(IsFn(fn, FUNC_OCT) orelse IsFn(fn, FUNC_UOCT), 8, 2))
    dim asUnsigned as Boolean = (IsFn(fn, FUNC_UHEX) orelse IsFn(fn, FUNC_UOCT) orelse IsFn(fn, FUNC_UBIN))
    if outV.kind = VK_SCALAR then
      if outV.exactUInt64Valid = FALSE then
        dim fmtText as String
        dim okFmt as Boolean
        if fmtBase = 16 then
          okFmt = FormatHexScalar(outV.scalar, fmtText, asUnsigned)
        elseif fmtBase = 8 then
          okFmt = FormatOctScalar(outV.scalar, fmtText, asUnsigned)
        else
          okFmt = FormatBinScalar(outV.scalar, fmtText, asUnsigned)
        end if
        if okFmt = FALSE then
          SetParseError(fnName & "() expects integer values")
          return outV
        end if
      end if
    else
      for i as Integer = lbound(outV.arr) to ubound(outV.arr)
        dim elemOk as Boolean = FALSE
        if outV.arr(i).exactInt64Valid then
          elemOk = TRUE
        elseif outV.arr(i).exactUInt64Valid then
          elemOk = TRUE
        else
          dim fmtText as String
          if fmtBase = 16 then
            elemOk = FormatHexScalar(outV.arr(i).scalar, fmtText, asUnsigned)
          elseif fmtBase = 8 then
            elemOk = FormatOctScalar(outV.arr(i).scalar, fmtText, asUnsigned)
          else
            elemOk = FormatBinScalar(outV.arr(i).scalar, fmtText, asUnsigned)
          end if
        end if
        if elemOk = FALSE then
          SetParseError(fnName & "() expects integer values")
          return outV
        end if
      next i
    end if
    outV.renderBase = fmtBase
    outV.renderUnsigned = asUnsigned
    return outV
  end if

  if IsFn(fn, FUNC_POW) then
    if ubound(args) <> 1 then
      dim argc as Integer = ubound(args) + 1
      SetParseError(fnName & "() expects 2 argument(s), " & ltrim(str(argc)) & " given")
      return outV
    end if
    if ValueApplyBinary(args(0), args(1), 94, outV) = FALSE then SetParseError("numeric error in " & fnName & "()")
    return outV
  end if

  if IsFn(fn, FUNC_DEG) orelse IsFn(fn, FUNC_RAD) then
    if ubound(args) = -1 then
      SetParseError(fnName & "() expects at least 1 argument")
      return outV
    end if
    if ubound(args) = 0 then
      if ApplyUnaryFunction(fn, args(0), outV) = FALSE then SetParseError("numeric error in " & fnName & "()")
      return outV
    end if

    c = 0
    for i as Integer = lbound(args) to ubound(args)
      if args(i).kind = VK_SCALAR then
        c += 1
      else
        c += ValueArrayLen(args(i))
      end if
    next i
    if c <= 0 then
      SetParseError(fnName & "() expects at least 1 argument")
      return outV
    end if

    ValueInitArrayLike(outV, 0, c - 1)
    dim argIdxDeg as Integer = lbound(args)
    dim elemIdxDeg as Integer = -1
    dim vDeg as Double
    dim outPosDeg as Integer = 0
    while ArgScalarWalkNext(args(), argIdxDeg, elemIdxDeg, vDeg)
      dim tmpOut as EvalValue
      if ApplyUnaryScalarFunction(fn, vDeg, tmpOut) = FALSE then
        SetParseError("numeric error in " & fnName & "()")
        return outV
      end if
      ValueSetArrayElemFromScalar(outV, outPosDeg, tmpOut)
      outPosDeg += 1
    wend
    return outV
  end if

  if IsUnaryBuiltin(fnName) then
    if ubound(args) <> 0 then
      dim argc as Integer = ubound(args) + 1
      SetParseError(fnName & "() expects 1 argument(s), " & ltrim(str(argc)) & " given")
      return outV
    end if
    if ApplyUnaryFunction(fn, args(0), outV) = FALSE then SetParseError("numeric error in " & fnName & "()")
    return outV
  end if

  if EvaluateUserFunction(fnName, args(), outV) then return outV

  AppendUniqueName(unknownFuncsText, fnName)
  ValueSetInt64(outV, 0)
  return outV
end function

private function ParseFactor() as EvalValue
  dim n as EvalValue
  ValueSetInt64(n, 0)
  wasPercentage = FALSE

  SkipSpaces()
  if (pStream[0] >= 48 andalso pStream[0] <= 57) orelse (pStream[0] = 46) then
    dim dVal as Double = 0
    dim keepExactInt as Boolean = FALSE
    dim keepInt as LongInt = 0
    dim keepExactUInt as Boolean = FALSE
    dim keepUInt as ULongInt = 0
    if pStream[0] = 48 andalso (pStream[1] = 120 orelse pStream[1] = 88) then
      ' hex number
      pStream += 2 ' Skip the "0x"
      dim hexDigits as Integer = 0
      dim hexVal as ULongInt = 0
      while true
        dim c as ubyte = pStream[0]
        dim digitValue as integer = -1
        if c >= 48 andalso c <= 57 then       ' 0-9
          digitValue = c - 48
        elseif c >= 65 andalso c <= 70 then   ' A-F
          digitValue = c - 55
        elseif c >= 97 andalso c <= 102 then  ' a-f
          digitValue = c - 87
        else
          exit while ' Not a hex digit
        end if
        dVal = dVal * 16 + digitValue
        hexVal = hexVal * 16 + culngint(digitValue)
        hexDigits += 1
        pStream += 1
      wend
      if hexDigits = 0 then
        SetParseError("invalid hex literal")
        return n
      end if
      if hexVal <= CULngInt(9223372036854775807) then
        keepExactInt = TRUE
        keepInt = CLngInt(hexVal)
      end if
      keepExactUInt = TRUE
      keepUInt = hexVal
    elseif pStream[0] = 48 andalso (pStream[1] = 98 orelse pStream[1] = 66) then
      ' binary number
      pStream += 2 ' Skip the "0b"
      dim binDigits as Integer = 0
      dim binVal as ULongInt = 0
      while true
        dim c as ubyte = pStream[0]
        if c = 48 orelse c = 49 then
          binVal = binVal shl 1
          if c = 49 then binVal += 1
          dVal = dVal * 2 + (c - 48)
          binDigits += 1
          pStream += 1
        else
          exit while
        end if
      wend
      if binDigits = 0 then
        SetParseError("invalid binary literal")
        return n
      end if
      if binVal <= CULngInt(9223372036854775807) then
        keepExactInt = TRUE
        keepInt = CLngInt(binVal)
      end if
      keepExactUInt = TRUE
      keepUInt = binVal
    elseif pStream[0] = 48 andalso (pStream[1] = 111 orelse pStream[1] = 79) then
      ' octal number
      pStream += 2 ' Skip the "0o"
      dim octDigits as Integer = 0
      dim octVal as ULongInt = 0
      while true
        dim c as ubyte = pStream[0]
        if c >= 48 andalso c <= 55 then
          octVal = octVal * 8 + CULngInt(c - 48)
          dVal = dVal * 8 + (c - 48)
          octDigits += 1
          pStream += 1
        else
          exit while
        end if
      wend
      if octDigits = 0 then
        SetParseError("invalid octal literal")
        return n
      end if
      if octVal <= CULngInt(9223372036854775807) then
        keepExactInt = TRUE
        keepInt = CLngInt(octVal)
      end if
      keepExactUInt = TRUE
      keepUInt = octVal
    else
      ' decimal number
      dim fract as Double = 1
      dim decIntAcc as ULongInt = 0
      dim decIntOverflow as Boolean = FALSE
      while pStream[0] >= 48 andalso pStream[0] <= 57
        dim digit as Integer = (pStream[0] - 48)
        dVal = dVal * 10 + digit
        if decIntOverflow = FALSE then
          if decIntAcc > CULngInt(922337203685477580) then
            decIntOverflow = TRUE
          elseif decIntAcc = CULngInt(922337203685477580) andalso digit > 7 then
            decIntOverflow = TRUE
          else
            decIntAcc = decIntAcc * 10 + CULngInt(digit)
          end if
        end if
        pStream += 1
      wend
      dim hasFraction as Boolean = FALSE
      if pStream[0] = 46 then ' "."
        hasFraction = TRUE
        pStream += 1
        while pStream[0] >= 48 andalso pStream[0] <= 57
          fract /= 10
          dVal += (pStream[0] - 48) * fract
          pStream += 1
        wend
      end if
      ' exponent
      dim hasExponent as Boolean = FALSE
      if pStream[0] = 101 orelse pStream[0] = 69 then ' "e" or "E"
        dim pExp as ZString ptr = pStream + 1
        dim expVal as integer = 0
        dim expSign as integer = 1
        if pExp[0] = 45 then     ' "e-"
          expSign = -1
          pExp += 1
        elseif pExp[0] = 43 then ' "e+"
          pExp += 1
        end if
        if pExp[0] >= 48 andalso pExp[0] <= 57 then ' at least one numeric char
          hasExponent = TRUE
          pStream = pExp
          while pStream[0] >= 48 andalso pStream[0] <= 57
            expVal = expVal * 10 + (pStream[0] - 48)
            pStream += 1
          wend
          dVal *= (10 ^ (expSign * expVal))
        end if
      end if
      if hasFraction = FALSE andalso hasExponent = FALSE andalso decIntOverflow = FALSE then
        keepExactInt = TRUE
        keepInt = CLngInt(decIntAcc)
        keepExactUInt = TRUE
        keepUInt = decIntAcc
      end if
    end if

    ValueSetScalar(n, dVal)
    n.exactInt64Valid = keepExactInt
    if keepExactInt then n.exactInt64 = keepInt
    n.exactUInt64Valid = keepExactUInt
    if keepExactUInt then n.exactUInt64 = keepUInt
  elseif (pStream[0] >= 65 andalso pStream[0] <= 90) orelse (pStream[0] >= 97 andalso pStream[0] <= 122) orelse (pStream[0] = 95) then
    dim pStart as ZString ptr = pStream
    while (pStream[0] >= 65 andalso pStream[0] <= 90) orelse (pStream[0] >= 97 andalso pStream[0] <= 122) orelse (pStream[0] >= 48 andalso pStream[0] <= 57) orelse (pStream[0] = 95)
      pStream += 1
    wend
    dim nam as String = Left(*pStart, pStream - pStart)
    SkipSpaces()
    if pStream[0] = 40 then
      n = ParseFunctionCall(nam)
      if parseError then return n
      dim indexed as EvalValue
      if TryParseArrayIndex(n, indexed) = FALSE then return n
      n = indexed
    else
      dim canIndex as Boolean = TRUE
      if TryGetConstant(nam, n) = FALSE then
        if GetVariable(nam, n) = FALSE then
          dim lowNam as String = lcase(nam)
          if IsOpKeyword(lowNam, OP_AND) orelse IsOpKeyword(lowNam, OP_OR) then
            SetParseError("unexpected token")
            return n
          end if
          dim fnHint as String
          if TryGetBuiltinSignatureHint(nam, fnHint) then
            SetParseError("function: " & fnHint)
            return n
          else
            AppendUniqueName(unknownVarsText, nam)
            ValueSetInt64(n, 0)
            canIndex = FALSE
          end if
        end if
      end if
      if canIndex then
        dim indexed as EvalValue
        if TryParseArrayIndex(n, indexed) = FALSE then return n
        n = indexed
      end if
    end if
  elseif pStream[0] = 40 then ' (
    pStream += 1
    if pStream[0] = 44 then
      SetParseError("unexpected comma")
      return n
    end if
    dim firstVal as EvalValue = ParseExpression()
    if parseError then return n
    SkipSpaces()
    if pStream[0] = 44 then
      dim vals() as EvalValue
      redim vals(0)
      if firstVal.kind <> VK_SCALAR then SetParseError("array element must be scalar"): return n
      vals(0) = firstVal
      do
        pStream += 1
        SkipSpaces()
        if pStream[0] = 41 orelse pStream[0] = 44 then
          SetParseError("unexpected comma")
          return n
        end if
        dim nextVal as EvalValue = ParseExpression()
        if parseError then return n
        if nextVal.kind <> VK_SCALAR then SetParseError("array element must be scalar"): return n
        redim preserve vals(0 to ubound(vals) + 1)
        vals(ubound(vals)) = nextVal
        SkipSpaces()
        if pStream[0] <> 44 andalso pStream[0] <> 41 then
          if pStream[0] = 93 then
            SetParseError("mismatched closing bracket")
          elseif pStream[0] = 125 then
            SetParseError("mismatched closing brace")
          else
            SetParseError("unexpected token")
          end if
          return n
        end if
      loop while pStream[0] = 44
      if pStream[0] = 41 then
        pStream += 1
      elseif pStream[0] = 93 then
        SetParseError("mismatched closing bracket")
      elseif pStream[0] = 125 then
        SetParseError("mismatched closing brace")
      else
        SetParseError("missing closing parenthesis")
      end if
      ValueInitArrayLike(n, 0, ubound(vals))
      dim arrI as Integer
      for arrI = 0 to ubound(vals)
        ValueSetArrayElemFromScalar(n, arrI, vals(arrI))
      next arrI
    else
      if pStream[0] = 41 then
        pStream += 1
      elseif pStream[0] = 93 then
        SetParseError("mismatched closing bracket")
      elseif pStream[0] = 125 then
        SetParseError("mismatched closing brace")
      else
        SetParseError("missing closing parenthesis")
      end if
      n = firstVal
    end if
  else
    SetParseError("unexpected token")
  end if

  return n
end function

private function ParsePower() as EvalValue
  dim n as EvalValue = ParseFactor()
  if parseError then return n
  SkipSpaces()

  if pStream[0] = 42 andalso pStream[1] = 42 then
    pStream += 2
    dim rhs as EvalValue = ParseUnary()
    dim outV as EvalValue
    if ValueApplyBinary(n, rhs, 94, outV) = FALSE then
      SetParseError("incompatible operands")
    else
      n = outV
    end if
  end if
  return n
end function

private function ParseUnary() as EvalValue
  SkipSpaces()
  if pStream[0] = 43 then
    pStream += 1
    return ParseUnary()
  elseif pStream[0] = 45 then
    pStream += 1
    dim v as EvalValue = ParseUnary()
    if parseError then return v
    dim minusOne as EvalValue, outV as EvalValue
    ValueSetInt64(minusOne, -1)
    if ValueApplyBinary(v, minusOne, 42, outV) = FALSE then SetParseError("incompatible operands")
    return outV
  elseif pStream[0] = 126 then
    pStream += 1
    dim v as EvalValue = ParseUnary()
    dim outV as EvalValue
    dim op as String = "^"
    dim minusOne as EvalValue
    ValueSetInt64(minusOne, -1)
    if ApplyInt64ParserOp(v, minusOne, op, outV) = FALSE then return outV
    return outV
  elseif pStream[0] = 33 andalso pStream[1] <> 61 then
    pStream += 1
    dim v as EvalValue = ParseUnary()
    if parseError then return v
    ValueSetBoolResult(not EvalValueIsTruthy(v), v)
    return v
  elseif MatchKeywordOperator(OpName(OP_NOT)) then
    dim v as EvalValue = ParseLogicalNot()
    if parseError then return v
    ValueSetBoolResult(not EvalValueIsTruthy(v), v)
    return v
  end if

  dim n as EvalValue = ParsePower()
  if parseError then return n

  SkipSpaces()
  while pStream[0] = 91 ' [
    dim indexed as EvalValue
    if TryParseArrayIndex(n, indexed) = FALSE then return n
    n = indexed
    SkipSpaces()
  wend

  SkipSpaces()
  if pStream[0] = 37 then ' "%" as postfix percentage
    pStream += 1
    if IsPercentageTail() then
      dim divV as EvalValue, outV as EvalValue
      ValueSetScalar(divV, 100.0)
      if ValueApplyBinary(n, divV, 47, outV) = FALSE then
        SetParseError("incompatible operands")
      else
        n = outV
        wasPercentage = TRUE
      end if
    else
      pStream -= 1
    end if
  end if
  return n
end function

private function ParseMultiplicative() as EvalValue
  dim n as EvalValue = ParseUnary()
  dim termWasPercentage as Boolean = wasPercentage
  SkipSpaces()
  while TRUE
    if parseError then exit while

    dim op as UByte = 0
    dim useInt64 as Integer = FALSE
    dim intOp as String = ""

    if pStream[0] = 42 andalso pStream[1] <> 42 then
      op = 42
      pStream += 1
    elseif pStream[0] = 47 then
      op = 47
      pStream += 1
    elseif pStream[0] = 37 then
      useInt64 = TRUE
      intOp = OpName(OP_MOD)
      pStream += 1
    elseif IsImplicitMulStart() then
      op = 42
    else
      exit while
    end if

    dim n2 as EvalValue = ParseUnary()
    dim outV as EvalValue
    if useInt64 then
      if ApplyInt64ParserOp(n, n2, intOp, outV) then n = outV
    else
      if ValueApplyBinary(n, n2, op, outV) = FALSE then SetParseError("incompatible operands") else n = outV
    end if
    termWasPercentage = FALSE
    SkipSpaces()
  wend
  wasPercentage = termWasPercentage
  return n
end function

private function ParseAdditive() as EvalValue
  dim n as EvalValue = ParseMultiplicative()
  SkipSpaces()
  while (pStream[0] = 43) orelse (pStream[0] = 45)
    if parseError then exit while
    dim op as UByte = pStream[0]
    pStream += 1
    dim n2 as EvalValue = ParseMultiplicative()

    if wasPercentage then
      SkipSpaces()
      if (pStream[0] = 0) orelse (pStream[0] = 41) orelse (pStream[0] = 43) orelse (pStream[0] = 45) orelse (pStream[0] = 44) orelse (pStream[0] = 59) _
         orelse (pStream[0] = 60) orelse (pStream[0] = 62) orelse (pStream[0] = 38) orelse (pStream[0] = 94) orelse (pStream[0] = 124) _
         orelse (pStream[0] = 93) orelse (pStream[0] = 125) then
        dim pctV as EvalValue
        if ValueApplyBinary(n, n2, 42, pctV) = FALSE then SetParseError("incompatible operands") else n2 = pctV
      end if
    end if

    dim outV as EvalValue
    if ValueApplyBinary(n, n2, op, outV) = FALSE then SetParseError("incompatible operands") else n = outV
    SkipSpaces()
  wend
  return n
end function

private function ParseShift() as EvalValue
  dim n as EvalValue = ParseAdditive()
  SkipSpaces()
  while (pStream[0] = 60 andalso pStream[1] = 60) orelse (pStream[0] = 62 andalso pStream[1] = 62)
    if parseError then exit while
    dim op as String
    if pStream[0] = 60 then op = "<<" else op = ">>"
    pStream += 2
    dim n2 as EvalValue = ParseAdditive()
    dim outV as EvalValue
    if ApplyInt64ParserOp(n, n2, op, outV) then n = outV
    SkipSpaces()
  wend
  return n
end function

private function ParseBitwiseAnd() as EvalValue
  dim n as EvalValue = ParseShift()
  SkipSpaces()
  while pStream[0] = 38 andalso pStream[1] <> 38
    if parseError then exit while
    pStream += 1
    dim n2 as EvalValue = ParseShift()
    dim outV as EvalValue
    dim op as String = "&"
    if ApplyInt64ParserOp(n, n2, op, outV) then n = outV
    SkipSpaces()
  wend
  return n
end function

private function ParseBitwiseXor() as EvalValue
  dim n as EvalValue = ParseBitwiseAnd()
  SkipSpaces()
  while pStream[0] = 94
    if parseError then exit while
    pStream += 1
    dim n2 as EvalValue = ParseBitwiseAnd()
    dim outV as EvalValue
    dim op as String = "^"
    if ApplyInt64ParserOp(n, n2, op, outV) then n = outV
    SkipSpaces()
  wend
  return n
end function

private function ParseBitwiseOr() as EvalValue
  dim n as EvalValue = ParseBitwiseXor()
  SkipSpaces()
  while pStream[0] = 124 andalso pStream[1] <> 124
    if parseError then exit while
    pStream += 1
    dim n2 as EvalValue = ParseBitwiseXor()
    dim outV as EvalValue
    dim op as String = "|"
    if ApplyInt64ParserOp(n, n2, op, outV) then n = outV
    SkipSpaces()
  wend
  return n
end function

private function ParseComparison() as EvalValue
  dim n as EvalValue = ParseBitwiseOr()
  SkipSpaces()
  while TRUE
    if parseError then exit while
    dim op as String = ""
    if pStream[0] = 61 then
      if pStream[1] = 61 then
        op = "=="
        pStream += 2
      else
        op = "="
        pStream += 1
      end if
    elseif pStream[0] = 60 then
      if pStream[1] = 62 then
        op = "<>"
        pStream += 2
      elseif pStream[1] = 61 then
        op = "<="
        pStream += 2
      elseif pStream[1] = 60 then
        exit while
      else
        op = "<"
        pStream += 1
      end if
    elseif pStream[0] = 62 then
      if pStream[1] = 61 then
        op = ">="
        pStream += 2
      elseif pStream[1] = 62 then
        exit while
      else
        op = ">"
        pStream += 1
      end if
    elseif pStream[0] = 33 then
      if pStream[1] = 61 then
        op = "!="
        pStream += 2
      else
        exit while
      end if
    else
      exit while
    end if

    dim n2 as EvalValue = ParseBitwiseOr()
    dim outV as EvalValue
    if ApplyComparison(n, n2, op, outV) = FALSE then SetParseError("incompatible operands") else n = outV
    SkipSpaces()
  wend
  return n
end function

private function ParseLogicalNot() as EvalValue
  SkipSpaces()
  if MatchKeywordOperator(OpName(OP_NOT)) then
    SkipSpaces()
    dim rhs as EvalValue = ParseLogicalNot()
    ValueSetBoolResult(not EvalValueIsTruthy(rhs), rhs)
    return rhs
  end if
  return ParseComparison()
end function

private function ParseLogicalAnd() as EvalValue
  dim n as EvalValue = ParseLogicalNot()
  SkipSpaces()
  while TRUE
    if parseError then exit while
    dim hasOp as Boolean = FALSE
    if pStream[0] = 38 andalso pStream[1] = 38 then
      pStream += 2
      hasOp = TRUE
    elseif MatchKeywordOperator(OpName(OP_AND)) then
      hasOp = TRUE
    end if
    if hasOp = FALSE then exit while

    dim n2 as EvalValue = ParseLogicalNot()
    ValueSetBoolResult(EvalValueIsTruthy(n) andalso EvalValueIsTruthy(n2), n)
    SkipSpaces()
  wend
  return n
end function

private function ParseLogicalOr() as EvalValue
  dim n as EvalValue = ParseLogicalAnd()
  SkipSpaces()
  while TRUE
    if parseError then exit while
    dim hasOp as Boolean = FALSE
    if pStream[0] = 124 andalso pStream[1] = 124 then
      pStream += 2
      hasOp = TRUE
    elseif MatchKeywordOperator(OpName(OP_OR)) then
      hasOp = TRUE
    end if
    if hasOp = FALSE then exit while

    dim n2 as EvalValue = ParseLogicalAnd()
    ValueSetBoolResult(EvalValueIsTruthy(n) orelse EvalValueIsTruthy(n2), n)
    SkipSpaces()
  wend
  return n
end function

private function ParseExpression() as EvalValue
  wasPercentage = FALSE
  return ParseLogicalOr()
end function

sub Parser_ClearVariables()
  erase variables
  erase userFunctions
  lastErrorText = ""
  unknownVarsText = ""
  unknownFuncsText = ""
end sub

function Parser_TryEvaluate(byref sExpr as String, byref result as Double) as Boolean
  dim textResult as String, isArray as Boolean
  return Parser_TryEvaluateEx(sExpr, result, textResult, isArray)
end function

function Parser_TryEvaluateEx(byref sExpr as String, byref result as Double, byref resultText as String, byref isArray as Boolean) as Boolean
  dim exprInput as String = StripLineComment(sExpr)
  const PARSER_MAX_EXPR_LEN as Integer = 32760
  evalDepth += 1
  if evalDepth = 1 then
    lastErrorText = ""
    unknownVarsText = ""
    unknownFuncsText = ""
    errorBaseCol = 1
    rootInputExpr = exprInput
  end if
  if Len(exprInput) = 0 then
    evalDepth -= 1
    return FALSE
  end if
  if Len(exprInput) > PARSER_MAX_EXPR_LEN then
    SetParseError("expression is too long")
    evalDepth -= 1
    return FALSE
  end if

  if instr(exprInput, ";") > 0 then
    dim hasTopLevelSep as Integer = 0
    dim scanParen as Integer = 0
    dim scanBracket as Integer = 0
    dim scanBrace as Integer = 0
    for i as Integer = 1 to len(exprInput)
      dim sch as String = mid(exprInput, i, 1)
      if sch = "(" then
        scanParen += 1
      elseif sch = ")" then
        if scanParen > 0 then scanParen -= 1
      elseif sch = "[" then
        scanBracket += 1
      elseif sch = "]" then
        if scanBracket > 0 then scanBracket -= 1
      elseif sch = "{" then
        scanBrace += 1
      elseif sch = "}" then
        if scanBrace > 0 then scanBrace -= 1
      elseif sch = ";" andalso scanParen = 0 andalso scanBracket = 0 andalso scanBrace = 0 then
        hasTopLevelSep = 1
        exit for
      end if
    next i

    if hasTopLevelSep then
      dim part as String = ""
      dim stmtStart as Integer = 1
      dim depthParen as Integer = 0
      dim depthBracket as Integer = 0
      dim depthBrace as Integer = 0
      dim hasPrevStmtResult as Boolean = FALSE
      dim iStmt as Integer
      for iStmt = 1 to len(exprInput) + 1
        dim ch as String
        if iStmt <= len(exprInput) then
          ch = mid(exprInput, iStmt, 1)
        else
          ch = ";"
        end if
        dim isStmtSep as Integer = 0
        if iStmt > len(exprInput) then
          isStmtSep = 1
        elseif ch = ";" andalso depthParen = 0 andalso depthBracket = 0 andalso depthBrace = 0 then
          isStmtSep = 1
        end if

        if isStmtSep then
          dim rawStmt as String = part
          dim stmt as String = trim(rawStmt)
          part = ""
          if stmt = "" then
            SetParseError("empty statement")
            evalDepth -= 1
            return FALSE
          end if
          dim leadWs as Integer = 0
          while leadWs < len(rawStmt)
            dim wsCh as String = mid(rawStmt, leadWs + 1, 1)
            if wsCh = " " orelse wsCh = chr(9) then
              leadWs += 1
            else
              exit while
            end if
          wend
          dim savedBaseCol as Integer = errorBaseCol
          errorBaseCol = stmtStart + leadWs
          dim stmtToEval as String = stmt
          if hasPrevStmtResult then
            dim rewrittenStmt as String
            if TryRewriteTrailingFormatterStmt(stmt, rewrittenStmt) then stmtToEval = rewrittenStmt
          end if
          if Parser_TryEvaluateEx(stmtToEval, result, resultText, isArray) = FALSE then
            errorBaseCol = savedBaseCol
            evalDepth -= 1
            return FALSE
          end if
          hasPrevStmtResult = TRUE
          errorBaseCol = savedBaseCol
          stmtStart = iStmt + 1
        else
          if ch = "(" then
            depthParen += 1
          elseif ch = ")" then
            if depthParen > 0 then depthParen -= 1
          elseif ch = "[" then
            depthBracket += 1
          elseif ch = "]" then
            if depthBracket > 0 then depthBracket -= 1
          elseif ch = "{" then
            depthBrace += 1
          elseif ch = "}" then
            if depthBrace > 0 then depthBrace -= 1
          end if
          part &= ch
        end if
      next iStmt
      evalDepth -= 1
      return TRUE
    end if
  end if

  dim i as Integer, hasNonSpace as Integer = 0
  for i = 1 to Len(exprInput)
    dim c as Integer = Asc(Mid(exprInput, i, 1))
    if not (c = 32 orelse c = 9 orelse c = 10 orelse c = 13) then
      hasNonSpace = 1
      exit for
    end if
  next i
  if hasNonSpace = 0 then
    evalDepth -= 1
    return FALSE
  end if

  pStream = StrPtr(exprInput)
  exprStart = pStream
  parseError = 0
  isArray = FALSE
  resultText = ""
  result = 0

  SkipSpaces()
  dim pStart as ZString ptr = pStream
  if (pStream[0] >= 65 andalso pStream[0] <= 90) orelse (pStream[0] >= 97 andalso pStream[0] <= 122) orelse (pStream[0] = 95) then
    while (pStream[0] >= 65 andalso pStream[0] <= 90) orelse (pStream[0] >= 97 andalso pStream[0] <= 122) orelse (pStream[0] >= 48 andalso pStream[0] <= 57) orelse (pStream[0] = 95)
      pStream += 1
    wend
    dim varName as String = Left(*pStart, pStream - pStart)
    SkipSpaces()
    if pStream[0] = 40 then
      dim savedPos as ZString ptr = pStream
      pStream += 1
      SkipSpaces()
      dim fnParams() as String
      dim parseParamsOk as Integer = 1

      if pStream[0] <> 41 then
        do
          if not ((pStream[0] >= 65 andalso pStream[0] <= 90) orelse (pStream[0] >= 97 andalso pStream[0] <= 122) orelse (pStream[0] = 95)) then
            parseParamsOk = 0
            exit do
          end if
          dim pParStart as ZString ptr = pStream
          while (pStream[0] >= 65 andalso pStream[0] <= 90) orelse (pStream[0] >= 97 andalso pStream[0] <= 122) orelse (pStream[0] >= 48 andalso pStream[0] <= 57) orelse (pStream[0] = 95)
            pStream += 1
          wend
          dim parName as String = Left(*pParStart, pStream - pParStart)
          if ubound(fnParams) = -1 then
            redim fnParams(0)
          else
            redim preserve fnParams(ubound(fnParams) + 1)
          end if
          fnParams(ubound(fnParams)) = parName
          SkipSpaces()
          if pStream[0] = 44 then
            pStream += 1
            SkipSpaces()
          else
            exit do
          end if
        loop
      end if

      if parseParamsOk andalso pStream[0] = 41 then
        pStream += 1
        SkipSpaces()
        if pStream[0] = 61 then
          pStream += 1
          SkipSpaces()
          if IsReservedUserFunctionName(varName) then
            SetParseError("reserved function name: " & varName)
            evalDepth -= 1
            return FALSE
          end if
          if ubound(fnParams) >= lbound(fnParams) then
            for iParam as Integer = lbound(fnParams) to ubound(fnParams)
              if IsBuiltinConstantName(fnParams(iParam)) then
                SetParseError("reserved constant name: " & fnParams(iParam))
                evalDepth -= 1
                return FALSE
              end if
              for jParam as Integer = iParam + 1 to ubound(fnParams)
                if fnParams(iParam) = fnParams(jParam) then
                  SetParseError("duplicate parameter name: " & fnParams(iParam))
                  evalDepth -= 1
                  return FALSE
                end if
              next jParam
            next iParam
          end if
          if IsBuiltinConstantName(varName) then
            SetParseError("reserved constant name: " & varName)
            evalDepth -= 1
            return FALSE
          end if
          dim body as String = *pStream
          if len(trim(body)) = 0 then
            SetParseError("function body is empty")
            evalDepth -= 1
            return FALSE
          end if
          SetUserFunction(varName, fnParams(), body)
          dim sig as String = varName & "("
          if ubound(fnParams) >= lbound(fnParams) then
            dim k as Integer
            for k = lbound(fnParams) to ubound(fnParams)
              if k > lbound(fnParams) then sig &= ", "
              sig &= fnParams(k)
            next k
          end if
          sig &= ")"
          resultText = "defined " & sig
          isArray = FALSE
          result = 0
          evalDepth -= 1
          return TRUE
        end if
      end if
      pStream = savedPos
    end if

    ' Single '=' is assignment; '==' is equality (do not consume the first '=' of '==').
    if pStream[0] = 61 andalso pStream[1] <> 61 then
      pStream += 1
      dim exprV as EvalValue = ParseExpression()
      SkipSpaces()
      if unknownVarsText <> "" then
        SetParseError("unknown variables: " & unknownVarsText)
      end if
      if unknownFuncsText <> "" then
        if lastErrorText = "" then
          SetParseError("unknown functions: " & unknownFuncsText)
        else
          lastErrorText &= "; unknown functions: " & unknownFuncsText
        end if
      end if
      if pStream[0] = 0 andalso parseError = 0 then
        if IsReservedUserFunctionName(varName) then
          SetParseError("reserved function name: " & varName)
          evalDepth -= 1
          return FALSE
        end if
        if IsBuiltinConstantName(varName) then
          SetParseError("reserved constant name: " & varName)
          evalDepth -= 1
          return FALSE
        end if
        SetVariable(varName, exprV)
        SetAnsValue(exprV)
        resultText = ValueToString(exprV)
        isArray = (exprV.kind = VK_ARRAY)
        if exprV.kind = VK_SCALAR then result = exprV.scalar
        evalDepth -= 1
        return TRUE
      end if
      if parseError = 0 then SetParseError("unexpected token")
      evalDepth -= 1
      return FALSE
    end if
  end if

  pStream = StrPtr(exprInput)
  exprStart = pStream
  parseError = 0
  dim outV as EvalValue = ParseExpression()
  SkipSpaces()

  if unknownVarsText <> "" then
    SetParseError("unknown variables: " & unknownVarsText)
  end if
  if unknownFuncsText <> "" then
    if lastErrorText = "" then
      SetParseError("unknown functions: " & unknownFuncsText)
    else
      lastErrorText &= "; unknown functions: " & unknownFuncsText
    end if
  end if

  if pStream[0] <> 0 andalso parseError = 0 then
    if pStream[0] = 44 then
      SetParseError("unexpected comma")
    elseif pStream[0] = 41 then
      SetParseError("mismatched closing parenthesis")
    elseif pStream[0] = 93 then
      SetParseError("mismatched closing bracket")
    elseif pStream[0] = 125 then
      SetParseError("mismatched closing brace")
    else
      SetParseError("unexpected token")
    end if
  end if
  if parseError = 1 then
    evalDepth -= 1
    return FALSE
  end if
  resultText = ValueToString(outV)
  isArray = (outV.kind = VK_ARRAY)
  if outV.kind = VK_SCALAR then result = outV.scalar
  SetAnsValue(outV)
  evalDepth -= 1
  return TRUE
end function

function Parser_GetLastError() as String
  if lastErrorText <> "" then return lastErrorText
  return ""
end function

sub Parser_SetShowErrorLine(byval showLine as Boolean)
  Parser_ShowErrorLine = showLine
end sub

function Parser_GetShowErrorLine() as Boolean
  return Parser_ShowErrorLine
end function