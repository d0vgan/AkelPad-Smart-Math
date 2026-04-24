#include once "crt.bi"
#include once "Inc\MathParser.bi"

enum ValueKind
  VK_SCALAR = 0
  VK_ARRAY = 1
end enum

type EvalValue
  kind as ValueKind
  scalar as Double
  arr(any) as Double
end type

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

private function BuildInlineCaretPreview(byval col as Integer) as String
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
  dim caretPos as Integer = col - startPos + 1
  if caretPos < 1 then caretPos = 1
  if caretPos > len(snippet) + 1 then caretPos = len(snippet) + 1

  return " | " & snippet & " | " & String(caretPos - 1, " ") & "^"
end function

private sub SetParseError(byref msg as String)
  if parseError = 0 then parseError = 1
  if lastErrorText = "" then
    dim posText as String = ""
    dim col as Integer = 1
    if (exprStart <> 0) andalso (pStream <> 0) andalso (pStream >= exprStart) then
      col = errorBaseCol + (pStream - exprStart)
      posText = " at line 1, col " & ltrim(str(col))
    end if
    lastErrorText = msg & posText & BuildInlineCaretPreview(col)
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

private function IsUnaryBuiltin(byref fn as String) as Boolean
  select case lcase(fn)
    case "sin", "cos", "tan", "asin", "arcsin", "acos", "arccos", "atan", "arctan", _
         "sinh", "cosh", "tanh", "exp", "log", "ln", "log10", "sqrt", "abs"
      return TRUE
  end select
  return FALSE
end function

private sub ValueSetScalar(byref v as EvalValue, byval n as Double)
  v.kind = VK_SCALAR
  v.scalar = n
  erase v.arr
end sub

private sub ValueSetArray(byref v as EvalValue, a() as Double)
  v.kind = VK_ARRAY
  v.scalar = 0
  if ubound(a) >= lbound(a) then
    redim v.arr(lbound(a) to ubound(a))
    dim i as Integer
    for i = lbound(a) to ubound(a)
      v.arr(i) = a(i)
    next i
  else
    erase v.arr
  end if
end sub

private function ValueArrayLen(byref v as EvalValue) as Integer
  if v.kind <> VK_ARRAY then return 0
  if ubound(v.arr) < lbound(v.arr) then return 0
  return ubound(v.arr) - lbound(v.arr) + 1
end function

private function ValueToString(byref v as EvalValue) as String
  if v.kind = VK_SCALAR then
    return ltrim(str(v.scalar))
  end if

  dim s as String = "("
  dim i as Integer
  for i = lbound(v.arr) to ubound(v.arr)
    if i > lbound(v.arr) then s &= ","
    s &= ltrim(str(v.arr(i)))
  next i
  s &= ")"
  return s
end function

private sub SkipSpaces()
  while (pStream[0] = 32) orelse (pStream[0] = 9) orelse (pStream[0] = 10) orelse (pStream[0] = 13)
    pStream += 1
  wend
end sub

private function TryGetConstant(byref n as String, byref v as EvalValue) as Boolean
  select case lcase(n)
    case "pi"
      ValueSetScalar(v, 4.0 * atn(1.0))
      return TRUE
    case "e"
      ValueSetScalar(v, exp(1.0))
      return TRUE
  end select
  return FALSE
end function

private function GetVariable(byref n as String, byref v as EvalValue) as Boolean
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
  if idxInt < 0 then
    SetParseError("array index must be non-negative")
    return FALSE
  end if

  SkipSpaces()
  if pStream[0] <> 93 then
    if pStream[0] = 41 orelse pStream[0] = 125 then
      SetParseError("mismatched closing bracket")
    else
      SetParseError("missing closing bracket")
    end if
    return FALSE
  end if
  pStream += 1

  dim arrLen as Integer = ValueArrayLen(baseValue)
  if idxInt >= arrLen then
    SetParseError("array index is out of range")
    return FALSE
  end if

  ValueSetScalar(outValue, baseValue.arr(lbound(baseValue.arr) + idxInt))
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

private function ApplyUnaryFunction(byref fn as String, byref v as EvalValue, byref outV as EvalValue) as Boolean
  dim i as Integer
  if v.kind = VK_SCALAR then
    select case lcase(fn)
      case "sin":   ValueSetScalar(outV, sin(v.scalar))
      case "cos":   ValueSetScalar(outV, cos(v.scalar))
      case "tan":   ValueSetScalar(outV, tan(v.scalar))
      case "asin", "arcsin": ValueSetScalar(outV, asin(v.scalar))
      case "acos", "arccos": ValueSetScalar(outV, acos(v.scalar))
      case "atan", "arctan": ValueSetScalar(outV, atn(v.scalar))
      case "sinh":  ValueSetScalar(outV, sinh(v.scalar))
      case "cosh":  ValueSetScalar(outV, cosh(v.scalar))
      case "tanh":  ValueSetScalar(outV, tanh(v.scalar))
      case "exp":   ValueSetScalar(outV, exp(v.scalar))
      case "log", "ln"
        ValueSetScalar(outV, log(v.scalar))
      case "log10"
        ValueSetScalar(outV, log(v.scalar) / log(10.0))
      case "sqrt"
        ValueSetScalar(outV, sqr(v.scalar))
      case "abs":   ValueSetScalar(outV, abs(v.scalar))
      case else:    return FALSE
    end select
    return TRUE
  end if

  if ubound(v.arr) < lbound(v.arr) then
    parseError = 1
    return FALSE
  end if
  redim outV.arr(lbound(v.arr) to ubound(v.arr))
  outV.kind = VK_ARRAY
  for i = lbound(v.arr) to ubound(v.arr)
    dim tmpIn as EvalValue, tmpOut as EvalValue
    ValueSetScalar(tmpIn, v.arr(i))
    if ApplyUnaryFunction(fn, tmpIn, tmpOut) = FALSE then return FALSE
    outV.arr(i) = tmpOut.scalar
  next i
  return TRUE
end function

private function ValueApplyBinary(byref leftV as EvalValue, byref rightV as EvalValue, byval op as UByte, byref outV as EvalValue) as Boolean
  dim i as Integer
  if leftV.kind = VK_SCALAR andalso rightV.kind = VK_SCALAR then
    select case op
      case 42: ValueSetScalar(outV, leftV.scalar * rightV.scalar)
      case 47
        ValueSetScalar(outV, leftV.scalar / rightV.scalar)
      case 43: ValueSetScalar(outV, leftV.scalar + rightV.scalar)
      case 45: ValueSetScalar(outV, leftV.scalar - rightV.scalar)
      case else: return FALSE
    end select
    return TRUE
  end if

  dim lb as Integer, ub as Integer
  if leftV.kind = VK_ARRAY andalso rightV.kind = VK_ARRAY then
    if ValueArrayLen(leftV) <> ValueArrayLen(rightV) then return FALSE
    lb = lbound(leftV.arr): ub = ubound(leftV.arr)
    redim outV.arr(lb to ub)
    outV.kind = VK_ARRAY
    for i = lb to ub
      dim a as EvalValue, b as EvalValue, r as EvalValue
      ValueSetScalar(a, leftV.arr(i))
      ValueSetScalar(b, rightV.arr(i))
      if ValueApplyBinary(a, b, op, r) = FALSE then return FALSE
      outV.arr(i) = r.scalar
    next i
    return TRUE
  end if

  if leftV.kind = VK_ARRAY then
    lb = lbound(leftV.arr): ub = ubound(leftV.arr)
    redim outV.arr(lb to ub)
    outV.kind = VK_ARRAY
    for i = lb to ub
      dim a as EvalValue, b as EvalValue, r as EvalValue
      ValueSetScalar(a, leftV.arr(i))
      b = rightV
      if ValueApplyBinary(a, b, op, r) = FALSE then return FALSE
      outV.arr(i) = r.scalar
    next i
    return TRUE
  end if

  lb = lbound(rightV.arr): ub = ubound(rightV.arr)
  redim outV.arr(lb to ub)
  outV.kind = VK_ARRAY
  for i = lb to ub
    dim a as EvalValue, b as EvalValue, r as EvalValue
    a = leftV
    ValueSetScalar(b, rightV.arr(i))
    if ValueApplyBinary(a, b, op, r) = FALSE then return FALSE
    outV.arr(i) = r.scalar
  next i
  return TRUE
end function

private function CollectArgsAsFlat(args() as EvalValue, flat() as Double) as Integer
  dim count as Integer = 0
  dim i as Integer, j as Integer
  for i = lbound(args) to ubound(args)
    if args(i).kind = VK_SCALAR then
      if count = 0 then
        redim flat(0)
      else
        redim preserve flat(0 to count)
      end if
      flat(count) = args(i).scalar
      count += 1
    else
      for j = lbound(args(i).arr) to ubound(args(i).arr)
        if count = 0 then
          redim flat(0)
        else
          redim preserve flat(0 to count)
        end if
        flat(count) = args(i).arr(j)
        count += 1
      next j
    end if
  next i
  return count
end function

private function ParseFunctionCall(byref fnName as String) as EvalValue
  dim outV as EvalValue
  if pStream[0] <> 40 then SetParseError("missing opening bracket"): return outV
  pStream += 1
  SkipSpaces()

  dim args() as EvalValue
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
      if ubound(args) = -1 then
        redim args(0)
      else
        redim preserve args(ubound(args) + 1)
      end if
      args(ubound(args)) = a
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
  elseif pStream[0] = 93 orelse pStream[0] = 125 then
    SetParseError("mismatched closing bracket")
  else
    SetParseError("missing closing bracket")
  end if
  if parseError then return outV

  dim fn as String = lcase(fnName)
  dim flat() as Double
  dim c as Integer = 0

  if fn = "sum" orelse fn = "product" orelse fn = "min" orelse fn = "max" then
    if ubound(args) = -1 then SetParseError(fnName & "() expects at least 1 argument"): return outV
    c = CollectArgsAsFlat(args(), flat())
    if c <= 0 then SetParseError(fnName & "() expects at least 1 argument"): return outV
    dim acc as Double = flat(0)
    dim i as Integer
    if fn = "sum" then
      acc = 0
      for i = 0 to c - 1: acc += flat(i): next i
    elseif fn = "product" then
      acc = 1
      for i = 0 to c - 1: acc *= flat(i): next i
    elseif fn = "min" then
      for i = 1 to c - 1
        if flat(i) < acc then acc = flat(i)
      next i
    else
      for i = 1 to c - 1
        if flat(i) > acc then acc = flat(i)
      next i
    end if
    ValueSetScalar(outV, acc)
    return outV
  end if

  if EvaluateUserFunction(fnName, args(), outV) then return outV

  if IsUnaryBuiltin(fnName) then
    if ubound(args) <> 0 then
      dim argc as Integer = ubound(args) + 1
      SetParseError(fnName & "() expects 1 argument(s), " & ltrim(str(argc)) & " given")
      return outV
    end if
    if ApplyUnaryFunction(fn, args(0), outV) = FALSE then SetParseError("numeric error in " & fnName & "()")
    return outV
  end if

  AppendUniqueName(unknownFuncsText, fnName)
  ValueSetScalar(outV, 0)
  return outV
end function

private function ParseFactor() as EvalValue
  dim n as EvalValue
  ValueSetScalar(n, 0)
  wasPercentage = FALSE

  SkipSpaces()
  if (pStream[0] >= 48 andalso pStream[0] <= 57) orelse (pStream[0] = 46) then
    dim dVal as Double = 0
    if pStream[0] = 48 andalso (pStream[1] = 120 orelse pStream[1] = 88) then
      ' hex number
      pStream += 2 ' Skip the "0x"
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
        pStream += 1
      wend
    else
      ' decimal number
      dim fract as Double = 1
      while pStream[0] >= 48 andalso pStream[0] <= 57
        dVal = dVal * 10 + (pStream[0] - 48)
        pStream += 1
      wend
      if pStream[0] = 46 then ' "."
        pStream += 1
        while pStream[0] >= 48 andalso pStream[0] <= 57
          fract /= 10
          dVal += (pStream[0] - 48) * fract
          pStream += 1
        wend
      end if
      ' exponent
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
          pStream = pExp
          while pStream[0] >= 48 andalso pStream[0] <= 57
            expVal = expVal * 10 + (pStream[0] - 48)
            pStream += 1
          wend
          dVal *= (10 ^ (expSign * expVal))
        end if
      end if
    end if

    ValueSetScalar(n, dVal)
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
          AppendUniqueName(unknownVarsText, nam)
          ValueSetScalar(n, 0)
          canIndex = FALSE
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
      dim vals() as Double
      redim vals(0)
      if firstVal.kind <> VK_SCALAR then SetParseError("array element must be scalar"): return n
      vals(0) = firstVal.scalar
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
        vals(ubound(vals)) = nextVal.scalar
        SkipSpaces()
      loop while pStream[0] = 44
      if pStream[0] = 41 then
        pStream += 1
      elseif pStream[0] = 93 orelse pStream[0] = 125 then
        SetParseError("mismatched closing bracket")
      else
        SetParseError("missing closing bracket")
      end if
      ValueSetArray(n, vals())
    else
      if pStream[0] = 41 then
        pStream += 1
      elseif pStream[0] = 93 orelse pStream[0] = 125 then
        SetParseError("mismatched closing bracket")
      else
        SetParseError("missing closing bracket")
      end if
      n = firstVal
    end if
  else
    SetParseError("unexpected token")
  end if

  SkipSpaces()
  if pStream[0] = 37 then ' %
    pStream += 1
    dim divV as EvalValue
    ValueSetScalar(divV, 100.0)
    dim outV as EvalValue
    if ValueApplyBinary(n, divV, 47, outV) = FALSE then parseError = 1 else n = outV
    wasPercentage = TRUE
  end if
  return n
end function

private function ParseTerm() as EvalValue
  dim n as EvalValue = ParseFactor()
  dim termWasPercentage as Boolean = wasPercentage
  SkipSpaces()
  while (pStream[0] = 42) orelse (pStream[0] = 47)
    if parseError then exit while
    dim op as UByte = pStream[0]
    pStream += 1
    dim n2 as EvalValue = ParseFactor()
    dim outV as EvalValue
    if ValueApplyBinary(n, n2, op, outV) = FALSE then SetParseError("incompatible operands") else n = outV
    termWasPercentage = FALSE
    SkipSpaces()
  wend
  wasPercentage = termWasPercentage
  return n
end function

private function ParseExpression() as EvalValue
  dim zeroV as EvalValue
  ValueSetScalar(zeroV, 0)
  SkipSpaces()
  dim sign as Integer = 1
  if pStream[0] = 45 then ' "-"
    sign = -1
    pStream += 1
  elseif pStream[0] = 43 then ' "+"
    pStream += 1
  end if

  dim n as EvalValue = ParseTerm()
  if sign = -1 then
    dim minusOne as EvalValue, outSign as EvalValue
    ValueSetScalar(minusOne, -1)
    if ValueApplyBinary(n, minusOne, 42, outSign) = FALSE then SetParseError("incompatible operands") else n = outSign
  end if

  SkipSpaces()
  while (pStream[0] = 43) orelse (pStream[0] = 45)
    if parseError then exit while
    dim op as UByte = pStream[0]
    pStream += 1
    dim n2 as EvalValue = ParseTerm()

    if wasPercentage then
      SkipSpaces()
      if (pStream[0] = 0) orelse (pStream[0] = 41) orelse (pStream[0] = 43) orelse (pStream[0] = 45) then
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
  evalDepth += 1
  if evalDepth = 1 then
    lastErrorText = ""
    unknownVarsText = ""
    unknownFuncsText = ""
    errorBaseCol = 1
    rootInputExpr = sExpr
  end if
  if Len(sExpr) = 0 then
    evalDepth -= 1
    return FALSE
  end if

  if instr(sExpr, ";") > 0 then
    dim part as String = ""
    dim stmtStart as Integer = 1
    dim iStmt as Integer
    for iStmt = 1 to len(sExpr) + 1
      dim ch as String
      if iStmt <= len(sExpr) then
        ch = mid(sExpr, iStmt, 1)
      else
        ch = ";"
      end if
      if ch = ";" then
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
        if Parser_TryEvaluateEx(stmt, result, resultText, isArray) = FALSE then
          errorBaseCol = savedBaseCol
          evalDepth -= 1
          return FALSE
        end if
        errorBaseCol = savedBaseCol
        stmtStart = iStmt + 1
      else
        part &= ch
      end if
    next iStmt
    evalDepth -= 1
    return TRUE
  end if

  dim i as Integer, hasDigitOrVar as Integer = 0
  for i = 1 to Len(sExpr)
    dim c as Integer = Asc(Mid(sExpr, i, 1))
    if (c >= 48 andalso c <= 57) orelse (c >= 65 andalso c <= 90) orelse (c >= 97 andalso c <= 122) then
      hasDigitOrVar = 1
      exit for
    end if
  next i
  if hasDigitOrVar = 0 then
    evalDepth -= 1
    return FALSE
  end if

  pStream = StrPtr(sExpr)
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
          if ubound(fnParams) >= lbound(fnParams) then
            dim k as Integer
            for k = lbound(fnParams) to ubound(fnParams)
              if fnParams(k) = parName then
                SetParseError("duplicate parameter name: " & parName)
                evalDepth -= 1
                return FALSE
              end if
            next k
          end if
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

    if pStream[0] = 61 then ' =
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
        SetVariable(varName, exprV)
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

  pStream = StrPtr(sExpr)
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
    elseif pStream[0] = 41 orelse pStream[0] = 93 orelse pStream[0] = 125 then
      SetParseError("mismatched closing bracket")
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
  evalDepth -= 1
  return TRUE
end function

function Parser_GetLastError() as String
  if lastErrorText <> "" then return lastErrorText
  return ""
end function