#include once "Inc\MathParser.bi"

type SmokeCase
  expr as String
  setup as String
  expected as String
  expectedErrContains as String
  expectNoResult as Boolean
end type

dim shared g_total as Integer = 0
dim shared g_passed as Integer = 0
dim shared g_failed as Integer = 0
dim shared g_idx as Integer = 0

private function IsDecimalNumberToken(byref sText as String) as Boolean
  dim s as String = trim(sText)
  if len(s) = 0 then return FALSE
  dim i as Integer = 1
  if mid(s, i, 1) = "+" orelse mid(s, i, 1) = "-" then i += 1
  if i > len(s) then return FALSE

  dim hasDigits as Boolean = FALSE
  dim hasDot as Boolean = FALSE
  dim hasExp as Boolean = FALSE
  dim expHasDigits as Boolean = FALSE

  while i <= len(s)
    dim ch as String = mid(s, i, 1)
    if ch >= "0" andalso ch <= "9" then
      hasDigits = TRUE
      if hasExp then expHasDigits = TRUE
      i += 1
      continue while
    end if
    if ch = "." then
      if hasDot orelse hasExp then return FALSE
      hasDot = TRUE
      i += 1
      continue while
    end if
    if ch = "e" orelse ch = "E" then
      if hasExp orelse hasDigits = FALSE then return FALSE
      hasExp = TRUE
      i += 1
      if i <= len(s) then
        dim signCh as String = mid(s, i, 1)
        if signCh = "+" orelse signCh = "-" then i += 1
      end if
      if i > len(s) then return FALSE
      continue while
    end if
    return FALSE
  wend

  if hasDigits = FALSE then return FALSE
  if hasExp andalso expHasDigits = FALSE then return FALSE
  return TRUE
end function

private function TryParseDecimalToken(byref sText as String, byref outV as Double) as Boolean
  if IsDecimalNumberToken(sText) = FALSE then return FALSE
  outV = val(trim(sText))
  return TRUE
end function

private function ScalarCloseEnough(byref actual as String, byref expected as String) as Boolean
  if actual = expected then return TRUE
  dim da as Double, de as Double
  if TryParseDecimalToken(actual, da) = FALSE then return FALSE
  if TryParseDecimalToken(expected, de) = FALSE then return FALSE
  if da = de then return TRUE
  dim scale as Double = abs(da)
  if abs(de) > scale then scale = abs(de)
  if scale < 1 then scale = 1
  dim tol as Double = 16.0 * 2.2204460492503131e-16 * scale
  return abs(da - de) <= tol
end function

private function SplitArrayElems(byref sText as String, elems() as String) as Integer
  erase elems
  dim s as String = trim(sText)
  if len(s) < 2 then return 0
  if left(s, 1) <> "(" orelse right(s, 1) <> ")" then return 0
  s = mid(s, 2, len(s) - 2)
  if len(trim(s)) = 0 then return 0

  dim count as Integer = 1
  for i as Integer = 1 to len(s)
    if mid(s, i, 1) = "," then count += 1
  next i
  redim elems(0 to count - 1)
  dim startPos as Integer = 1
  dim outIdx as Integer = 0
  for i as Integer = 1 to len(s)
    if mid(s, i, 1) = "," then
      elems(outIdx) = trim(mid(s, startPos, i - startPos))
      outIdx += 1
      startPos = i + 1
    end if
  next i
  elems(outIdx) = trim(mid(s, startPos))
  return count
end function

private function ResultCloseEnough(byref actual as String, byref expected as String) as Boolean
  if actual = expected then return TRUE
  dim aElems() as String, eElems() as String
  dim ac as Integer = SplitArrayElems(actual, aElems())
  dim ec as Integer = SplitArrayElems(expected, eElems())
  if ac > 0 orelse ec > 0 then
    if ac <> ec then return FALSE
    for i as Integer = 0 to ac - 1
      if ScalarCloseEnough(aElems(i), eElems(i)) = FALSE then return FALSE
    next i
    return TRUE
  end if
  return ScalarCloseEnough(actual, expected)
end function

private function SmokeCaseSignature(byref c as SmokeCase) as String
  dim kind as String
  dim payload as String
  if c.expectNoResult then
    kind = "noResult"
    payload = ""
  elseif len(c.expectedErrContains) > 0 then
    kind = "errorContains"
    payload = c.expectedErrContains
  else
    kind = "expected"
    payload = c.expected
  end if
  SmokeCaseSignature = kind & "|" & c.expr & "|" & payload
end function

sub RunCase(byref c as SmokeCase)
  g_idx += 1
  print "[" & g_idx & "/" & g_total & "] RUN  : " & c.expr

  dim evalExpr as String = c.expr
  if len(c.setup) > 0 then
    evalExpr = c.setup & "; " & c.expr
  end if

  dim result as Double
  dim resultText as String
  dim isArray as Boolean
  dim ok as Boolean = Parser_TryEvaluateEx(evalExpr, result, resultText, isArray)

  dim actual as String
  dim errText as String
  errText = Parser_GetLastError()
  if ok then
    actual = resultText
  else
    actual = "ERR: " & errText
  end if

  dim passCase as Boolean = FALSE
  if c.expectNoResult then
    if (ok = FALSE) andalso (len(errText) = 0) then
      passCase = TRUE
    end if
  elseif len(c.expectedErrContains) > 0 then
    if (len(errText) > 0) andalso (instr(lcase(errText), lcase(c.expectedErrContains)) > 0) then
      passCase = TRUE
    end if
  else
    if (len(errText) = 0) andalso ResultCloseEnough(actual, c.expected) then passCase = TRUE
  end if

  if passCase then
    g_passed += 1
    if c.expectNoResult then
      print "          PASS : no result (comment/empty line)"
    elseif len(c.expectedErrContains) > 0 then
      print "          PASS : got expected error """ & c.expectedErrContains & """"
    else
      print "          PASS : got """ & actual & """"
    end if
  else
    g_failed += 1
    print "          FAIL : got """ & actual & """"
    if c.expectNoResult then
      print "                 expected no result and no error"
    elseif len(c.expectedErrContains) > 0 then
      print "                 expected error containing """ & c.expectedErrContains & """"
    else
      print "                 expected """ & c.expected & """"
    end if
  end if
  print ""
end sub

sub Main()
  dim tests(1 to 951) as SmokeCase
  ' Inline tag legend:
  ' [spec] = intended language behavior (primary contract)
  ' [regression-lock] = current behavior intentionally locked for compatibility
  ' Default rule: unless explicitly marked [regression-lock], each test is [spec].
  ' [ok-core] [ok-func] [ok-array] [hint] [arity]
  ' [type-int-only] [shape] [shape/broadcast] [syntax] [edge] [overflow]

  ' === SPEC / intended behavior ===
  '
  ' === A) Operator precedence, core operators, and integer-only operator checks ===
  tests(1).expr = "16**-0.5":           tests(1).expected = "0.25" ' [spec][ok-core]
  tests(2).expr = "+5":                 tests(2).expected = "5" ' [spec][ok-core]
  tests(3).expr = "-5":                 tests(3).expected = "-5" ' [spec][ok-core]
  tests(4).expr = "~5":                 tests(4).expected = "-6" ' [spec][ok-core]
  tests(5).expr = "5%3":                tests(5).expected = "2" ' [spec][ok-core]
  tests(6).expr = "200 + 15%":          tests(6).expected = "230" ' [spec][ok-core]
  tests(7).expr = "200 - 15%":          tests(7).expected = "170" ' [spec][ok-core]
  tests(8).expr = "8>>1":               tests(8).expected = "4" ' [spec][ok-core]
  tests(9).expr = "3<<2":              tests(9).expected = "12" ' [spec][ok-core]
  tests(10).expr = "6&3":               tests(10).expected = "2" ' [spec][ok-core]
  tests(11).expr = "6^3":               tests(11).expected = "5" ' [spec][ok-core]
  tests(12).expr = "6|3":               tests(12).expected = "7" ' [spec][ok-core]
  tests(13).expr = "2(3+4)":            tests(13).expected = "14" ' [spec][ok-core]
  tests(14).expr = "2(3+4)**2":         tests(14).expected = "98" ' [spec][ok-core]
  tests(15).expr = "2+3<<1":            tests(15).expected = "10" ' [spec][ok-core]
  tests(16).expr = "1|2^3&6<<1":        tests(16).expected = "3" ' [spec][ok-core]
  tests(17).expr = "2(1+2)%4":          tests(17).expected = "2" ' [spec][ok-core]
  tests(18).expr = "5.5&1":             tests(18).expectedErrContains = "bitwise operands must be integer values" ' [spec][type-int-only]
  tests(19).expr = "5|1.1":             tests(19).expectedErrContains = "bitwise operands must be integer values" ' [spec][type-int-only]
  tests(20).expr = "3.2^1":             tests(20).expectedErrContains = "bitwise operands must be integer values" ' [spec][type-int-only]
  tests(21).expr = "8.1>>1":            tests(21).expectedErrContains = "bitwise operands must be integer values" ' [spec][type-int-only]
  tests(22).expr = "8<<1.2":            tests(22).expectedErrContains = "bitwise operands must be integer values" ' [spec][type-int-only]
  tests(23).expr = "~2.5":              tests(23).expectedErrContains = "bitwise operands must be integer values" ' [spec][type-int-only]
  tests(24).expr = "5.5%2":             tests(24).expectedErrContains = "modulo operands must be integer values" ' [spec][type-int-only]
  tests(25).expr = "5%2.2":             tests(25).expectedErrContains = "modulo operands must be integer values" ' [spec][type-int-only]
  tests(26).expr = "2(1+2.5)%4.2":      tests(26).expectedErrContains = "modulo operands must be integer values" ' [spec][type-int-only]

  ' === B) [spec] Function hints, comments, parser diagnostics, and literal parsing ===
  tests(27).expr = "pow(2,3)":          tests(27).expected = "8" ' [ok-func]
  tests(28).expr = "prod(2,3,4)":       tests(28).expected = "24" ' [ok-func]
  tests(29).expr = "pow":               tests(29).expectedErrContains = "function: pow(" ' [hint]
  tests(30).expr = "sin":               tests(30).expectedErrContains = "function: sin(angle)" ' [hint]
  tests(31).expr = "sum":               tests(31).expectedErrContains = "function: sum(...)" ' [hint]
  tests(32).expr = "sqr(5)":            tests(32).expected = "25" ' [ok-func]
  tests(33).expr = "sqr":               tests(33).expectedErrContains = "function: sqr(value)" ' [hint]
  tests(34).expr = "1 + 2 # calculates 1 + 2": tests(34).expected = "3" ' [syntax]
  tests(35).expr = "// this entire line is a comment": tests(35).expectNoResult = TRUE ' [syntax]
  tests(36).expr = "sin(pi/2) // calculates sin(pi/2)": tests(36).expected = "1" ' [syntax]
  tests(37).expr = "[]":                tests(37).expectedErrContains = "unexpected token" ' [syntax]
  tests(38).expr = "b=2; 2b":           tests(38).expectedErrContains = "unexpected token" ' [syntax]
  tests(39).expr = "(2;2b;3)":          tests(39).expectedErrContains = "missing closing parenthesis" ' [syntax]
  tests(40).expr = "(2,2b,3)":          tests(40).expectedErrContains = "unexpected token" ' [syntax]
  tests(41).expr = "hex(12)":           tests(41).expected = "0xC" ' [ok-func]
  tests(42).expr = "hex((12,255))":     tests(42).expected = "(0xC,0xFF)" ' [ok-array]
  tests(43).expr = "10 + hex(12) + 14": tests(43).expected = "36" ' [ok-func]
  tests(44).expr = "hex(12.5)":         tests(44).expectedErrContains = "hex() expects integer values" ' [type-int-only]
  tests(45).expr = "hex":               tests(45).expectedErrContains = "function: hex(...)" ' [hint]
  tests(46).expr = "0x":                tests(46).expectedErrContains = "invalid hex literal" ' [syntax]
  tests(47).expr = "0xG":               tests(47).expectedErrContains = "invalid hex literal" ' [syntax]
  tests(48).expr = "hex(0x7FFFFFFFFFFFFFFF)": tests(48).expected = "0x7FFFFFFFFFFFFFFF" ' [ok-func]
  tests(49).expr = "hex(0xFFFFFFFFFFFFFFFF)": tests(49).expected = "0xFFFFFFFFFFFFFFFF" ' [ok-func]
  tests(50).expr = "0b01110110011":     tests(50).expected = "947" ' [ok-core]
  tests(51).expr = "bin(13)":           tests(51).expected = "0b1101" ' [ok-func]
  tests(52).expr = "bin((1,2,5))":      tests(52).expected = "(0b1,0b10,0b101)" ' [ok-array]
  tests(53).expr = "10 + bin(12) + 14": tests(53).expected = "36" ' [ok-func]
  tests(54).expr = "0b":                tests(54).expectedErrContains = "invalid binary literal" ' [syntax]
  tests(55).expr = "bin(12.5)":         tests(55).expectedErrContains = "bin() expects integer values" ' [type-int-only]
  tests(56).expr = "bin":               tests(56).expectedErrContains = "function: bin(...)" ' [hint]

  ' === C) [spec] Integer-accuracy / overflow-path regression cases ===
  tests(57).expr = "9007199254740991+1": tests(57).expected = "9007199254740992" ' [overflow]
  tests(58).expr = "9007199254740992+1": tests(58).expected = "9007199254740993" ' [overflow]
  tests(59).expr = "3037000499*3037000499": tests(59).expected = "9223372030926249001" ' [overflow]
  tests(60).expr = "5/2":               tests(60).expected = "2.5" ' [edge]
  tests(61).expr = "2**10+1":           tests(61).expected = "1025" ' [ok-core]
  tests(62).expr = "2**-1":             tests(62).expected = "0.5" ' [edge]
  tests(63).expr = "9007199254740993&1": tests(63).expected = "1" ' [overflow]
  tests(64).expr = "9223372036854775807+1": tests(64).expected = "9223372036854775808" ' [overflow]
  tests(65).expr = "-9223372036854775808-1": tests(65).expected = "-9.223372036854778e+018" ' [overflow]
  tests(66).expr = "3037000500*3037000500": tests(66).expected = "9.223372037000249e+018" ' [overflow]
  tests(67).expr = "2**63":             tests(67).expected = "9.223372036854776e+018" ' [overflow]
  tests(68).expr = "2**64":             tests(68).expected = "1.844674407370955e+019" ' [overflow]
  tests(69).expr = "9223372036854775807+0.5": tests(69).expected = "9.223372036854778e+018" ' [overflow]
  tests(70).expr = "hex(9223372036854775807+1)": tests(70).expected = "0x8000000000000000" ' [overflow]

  ' === D) [spec] Built-ins and ans variable baseline behavior ===
  tests(71).expr = "log(8,2)":          tests(71).expected = "3" ' [ok-func]
  tests(72).expr = "log(100,10)":       tests(72).expected = "2" ' [ok-func]
  tests(73).expr = "log(8)":            tests(73).expectedErrContains = "log() expects 2 argument(s)" ' [arity]
  tests(74).expr = "ln":                tests(74).expectedErrContains = "function: ln(value)" ' [hint]
  tests(75).expr = "a=2;sum(a,a)":      tests(75).expected = "4" ' [ok-func]
  tests(76).expr = "f(a,a)=a":          tests(76).expectedErrContains = "duplicate parameter name" ' [syntax]
  tests(77).expr = "2+3;ans":           tests(77).expected = "5" ' [ok-func]
  tests(78).expr = "(1,2,3);ans":       tests(78).expected = "(1,2,3)" ' [ok-array]
  tests(79).expr = "hex(15);ans":       tests(79).expected = "0xF" ' [ok-func]
  tests(80).expr = "7; ans*2":          tests(80).expected = "14" ' [ok-func]
  tests(81).expr = "v=(10,20);sum(ans)": tests(81).expected = "30" ' [ok-array]
  tests(82).expr = "atan2(1,1)":        tests(82).expected = "0.7853981633974483" ' [ok-func]
  tests(83).expr = "floor(2.9)":        tests(83).expected = "2" ' [ok-func]
  tests(84).expr = "ceil(2.1)":         tests(84).expected = "3" ' [ok-func]
  tests(85).expr = "trunc(-2.9)":       tests(85).expected = "-2" ' [ok-func]
  tests(86).expr = "round(2.5)":        tests(86).expected = "3" ' [ok-func]
  tests(87).expr = "sign(-123)":        tests(87).expected = "-1" ' [ok-func]
  tests(88).expr = "mod(17,5)":         tests(88).expected = "2" ' [ok-func]
  tests(89).expr = "avg(1,2,3,4)":      tests(89).expected = "2.5" ' [ok-func]
  tests(90).expr = "mean((1,2,3),9)":   tests(90).expected = "3.75" ' [ok-array]
  tests(91).expr = "clamp(15,0,10)":    tests(91).expected = "10" ' [ok-func]
  tests(92).expr = "deg(pi)":           tests(92).expected = "180" ' [ok-func]
  tests(93).expr = "rad(180)":          tests(93).expected = "3.141592653589793" ' [ok-func]
  tests(94).expr = "hypot(3,4)":        tests(94).expected = "5" ' [ok-func]
  tests(95).expr = "gcd(84,30)":        tests(95).expected = "6" ' [ok-func]
  tests(96).expr = "lcm(6,8)":          tests(96).expected = "24" ' [ok-func]
  tests(97).expr = "median(1,8,3)":     tests(97).expected = "3" ' [ok-func]
  tests(98).expr = "median((1,9),3,7)": tests(98).expected = "5" ' [ok-array]
  tests(99).expr = "variance(1,2,3)":  tests(99).expected = "0.6666666666666666" ' [ok-func]
  tests(100).expr = "stddev(1,2,3)":    tests(100).expected = "0.816496580927726" ' [ok-func]
  tests(101).expr = "fact(0)":          tests(101).expected = "1" ' [ok-func]
  tests(102).expr = "fact(5)":          tests(102).expected = "120" ' [ok-func]
  tests(103).expr = "factorial(10)":    tests(103).expected = "3628800" ' [ok-func]
  tests(104).expr = "fact(-1)":         tests(104).expectedErrContains = "fact() expects a non-negative integer" ' [edge]
  tests(105).expr = "fact(2.5)":        tests(105).expectedErrContains = "fact() expects integer values" ' [type-int-only]
  tests(106).expr = "factorial(21)":    tests(106).expected = "5.109094217170944e+019" ' [float-over-20]
  tests(107).expr = "random(5,5)":      tests(107).expected = "5" ' [edge]
  tests(108).expr = "rand(1)":          tests(108).expectedErrContains = "rand() expects 0 argument(s)" ' [arity]
  tests(109).expr = "rand":             tests(109).expectedErrContains = "function: rand()" ' [hint]
  tests(110).expr = "random":           tests(110).expectedErrContains = "function: random(min, max)" ' [hint]
  tests(111).expr = "median":           tests(111).expectedErrContains = "function: median(...)" ' [hint]

  ' === E) [spec] sort/unique baseline behavior ===
  tests(112).expr = "sort((3,1,2))":    tests(112).expected = "(1,2,3)" ' [ok-array]
  tests(113).expr = "a=(5,2,9);sort(a)": tests(113).expected = "(2,5,9)" ' [ok-array]
  tests(114).expr = "sort(5)":          tests(114).expected = "(5)" ' [ok-func]
  tests(115).expr = "sort(2,5,1)":      tests(115).expected = "(1,2,5)" ' [ok-func]
  tests(116).expr = "sort":             tests(116).expectedErrContains = "function: sort(...)" ' [hint]
  tests(117).expr = "unique((3,1,3,2,1,2))": tests(117).expected = "(3,1,2)" ' [ok-array]
  tests(118).expr = "a=(5,2,5,9,2);unique(a)": tests(118).expected = "(5,2,9)" ' [ok-array]
  tests(119).expr = "unique(5)":        tests(119).expected = "(5)" ' [ok-func]
  tests(120).expr = "unique(1,2,1,2,3)": tests(120).expected = "(1,2,3)" ' [ok-func]
  tests(121).expr = "unique":           tests(121).expectedErrContains = "function: unique(...)" ' [hint]

  ' === F) [spec] Stress matrix: argument shape, arity, syntax, and edge-case validation ===
  tests(122).expr = "(1,2)+(3)":        tests(122).expected = "(4,5)" ' [shape/broadcast]
  tests(123).expr = "(1,2)*(3,4,5)":    tests(123).expectedErrContains = "incompatible operands" ' [shape]
  tests(124).expr = "1<<64":            tests(124).expectedErrContains = "incompatible operands" ' [edge]
  tests(125).expr = "1>>-1":            tests(125).expectedErrContains = "incompatible operands" ' [edge]
  tests(126).expr = "5%0":              tests(126).expectedErrContains = "incompatible operands" ' [edge]
  tests(127).expr = "1+":               tests(127).expectedErrContains = "unexpected token" ' [syntax]
  tests(128).expr = "pow()":            tests(128).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(129).expr = "pow(2,3,4)":       tests(129).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(130).expr = "log()":            tests(130).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(131).expr = "log(10,10,10)":    tests(131).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(132).expr = "atan2()":          tests(132).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(133).expr = "atan2(1,2,3)":     tests(133).expectedErrContains = "expects 2 argument(s)" ' [arity]
tests(134).expr = "atan2((1,2),3)":   tests(134).expected = "(0.3217505543966422,0.5880026035475675)" ' [shape]
  tests(135).expr = "hypot()":          tests(135).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(136).expr = "hypot(3,4,5)":     tests(136).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(137).expr = "mod()":            tests(137).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(138).expr = "mod(10,3,1)":      tests(138).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(139).expr = "mod(10,0)":        tests(139).expectedErrContains = "numeric error in mod()" ' [edge]
  tests(140).expr = "gcd()":            tests(140).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(141).expr = "gcd(6,8,10)":      tests(141).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(142).expr = "gcd(6.5,3)":       tests(142).expectedErrContains = "expects integer values" ' [type-int-only]
  tests(143).expr = "lcm(6,0)":         tests(143).expected = "0" ' [edge]
  tests(144).expr = "lcm(6.5,3)":       tests(144).expectedErrContains = "expects integer values" ' [type-int-only]
  tests(145).expr = "hex(1,2)":         tests(145).expected = "(0x1,0x2)" ' [ok-array]
  tests(146).expr = "bin()":            tests(146).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(147).expr = "bin(1,2)":         tests(147).expected = "(0b1,0b10)" ' [ok-array]
  tests(148).expr = "clamp()":          tests(148).expectedErrContains = "expects 3 argument(s)" ' [arity]
  tests(149).expr = "rand()*0":         tests(149).expected = "0" ' [edge]
  tests(150).expr = "random()":         tests(150).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(151).expr = "random(1,2,3)":    tests(151).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(152).expr = "sort()":           tests(152).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(153).expr = "sort((2,5,1),4,3)": tests(153).expected = "(1,2,3,4,5)" ' [ok-array]
  tests(154).expr = "unique()":         tests(154).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(155).expr = "product()":        tests(155).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(156).expr = "min()":            tests(156).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(157).expr = "max()":            tests(157).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(158).expr = "avg()":            tests(158).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(159).expr = "median()":         tests(159).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(160).expr = "variance()":       tests(160).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(161).expr = "stddev()":         tests(161).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(162).expr = "sin(1,2)":         tests(162).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(163).expr = "cos(1,2)":         tests(163).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(164).expr = "ln(1,2)":          tests(164).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(165).expr = "sqrt(1,2)":        tests(165).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(166).expr = "fact()":           tests(166).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(167).expr = "factorial(1,2)":   tests(167).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(168).expr = "pow(2,)":          tests(168).expectedErrContains = "unexpected comma" ' [syntax]
  tests(169).expr = "sum((1,2),)":      tests(169).expectedErrContains = "unexpected comma" ' [syntax]

  ' === G) [spec] Extended negative matrix: malformed syntax, aliases, and mismatch paths ===
  tests(170).expr = "1/":               tests(170).expectedErrContains = "unexpected token" ' [syntax]
  tests(171).expr = "1**":              tests(171).expectedErrContains = "unexpected token" ' [syntax]
  tests(172).expr = "1<<":              tests(172).expectedErrContains = "unexpected token" ' [syntax]
  tests(173).expr = "1>>":              tests(173).expectedErrContains = "unexpected token" ' [syntax]
  tests(174).expr = "1&":               tests(174).expectedErrContains = "unexpected token" ' [syntax]
  tests(175).expr = "1|":               tests(175).expectedErrContains = "unexpected token" ' [syntax]
  tests(176).expr = "1^":               tests(176).expectedErrContains = "unexpected token" ' [syntax]
  tests(177).expr = "1%":               tests(177).expected = "0.01" ' [edge]
  tests(178).expr = "pow(,2)":          tests(178).expectedErrContains = "unexpected" ' [syntax]
  tests(179).expr = "atan2(,2)":        tests(179).expectedErrContains = "unexpected" ' [syntax]
  tests(180).expr = "random(,2)":       tests(180).expectedErrContains = "unexpected" ' [syntax]
  tests(181).expr = "clamp(1,,3)":      tests(181).expectedErrContains = "unexpected" ' [syntax]
  tests(182).expr = "sum(,1)":          tests(182).expectedErrContains = "unexpected" ' [syntax]
  tests(183).expr = "sin()":            tests(183).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(184).expr = "tan()":            tests(184).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(185).expr = "asin()":           tests(185).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(186).expr = "acos()":           tests(186).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(187).expr = "atan()":           tests(187).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(188).expr = "sinh()":           tests(188).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(189).expr = "cosh()":           tests(189).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(190).expr = "tanh()":           tests(190).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(191).expr = "exp()":            tests(191).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(192).expr = "log10()":          tests(192).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(193).expr = "abs()":            tests(193).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(194).expr = "floor()":          tests(194).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(195).expr = "ceil()":           tests(195).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(196).expr = "trunc()":          tests(196).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(197).expr = "round()":          tests(197).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(198).expr = "sign()":           tests(198).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(199).expr = "ln((1,2))":        tests(199).expected = "(0,0.6931471805599453)" ' [ok-array]
  tests(200).expr = "sqrt((1,2))":      tests(200).expected = "(1,1.414213562373095)" ' [ok-array]
  tests(201).expr = "abs((1,2))":       tests(201).expected = "(1,2)" ' [ok-array]
  tests(202).expr = "arcsin(1)":        tests(202).expected = "1.570796326794897" ' [ok-func]
  tests(203).expr = "arccos(1)":        tests(203).expected = "0" ' [ok-func]
  tests(204).expr = "arctan(1)":        tests(204).expected = "0.7853981633974483" ' [ok-func]
  tests(205).expr = "prod()":           tests(205).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(206).expr = "mean()":           tests(206).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(207).expr = "variance(( ))":    tests(207).expectedErrContains = "unexpected token" ' [syntax]
  tests(208).expr = "stddev(( ))":      tests(208).expectedErrContains = "unexpected token" ' [syntax]
  tests(209).expr = "gcd(1)":           tests(209).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(210).expr = "lcm(1)":           tests(210).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(211).expr = "mod(1)":           tests(211).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(212).expr = "hypot(1)":         tests(212).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(213).expr = "atan2(1)":         tests(213).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(214).expr = "log((1,2),10)":    tests(214).expected = "(0,0.3010299956639812)" ' [ok-array]
  tests(215).expr = "log(10,(2,3))":    tests(215).expected = "(3.321928094887362,2.095903274289384)" ' [ok-array]
  tests(216).expr = "pow((2,3),2)":     tests(216).expected = "(4,9)" ' [ok-array]
  tests(217).expr = "pow(2,(2,3))":     tests(217).expected = "(4,8)" ' [ok-array]
  tests(218).expr = "hex((1,2,3),(4))": tests(218).expected = "(0x1,0x2,0x3,0x4)" ' [ok-array]
  tests(219).expr = "bin((1,2,3),(4))": tests(219).expected = "(0b1,0b10,0b11,0b100)" ' [ok-array]
  tests(220).expr = "random(10,10)":    tests(220).expected = "10" ' [edge]
  tests(221).expr = "random(1.5,1.5)":  tests(221).expected = "1.5" ' [edge]
  tests(222).expr = "random(3.5,3.5)":  tests(222).expected = "3.5" ' [edge]
  tests(223).expr = "fact((1,2))":      tests(223).expectedErrContains = "expects a non-negative integer" ' [shape]
  tests(224).expr = "factorial((1,2))": tests(224).expectedErrContains = "expects a non-negative integer" ' [shape]
  '
  ' === REGRESSION-LOCK / compatibility behavior ===
  ' These cases intentionally lock currently observed behavior that may look odd,
  ' but should not change accidentally without an explicit decision.
  tests(225).expr = "clamp((1,2,3),(4,5),6)": tests(225).expectedErrContains = "expects scalar min/max" ' [type]
  tests(226).expr = "sum((1,2),(3,4),5)": tests(226).expected = "15" ' [ok-array]
  tests(227).expr = "sort(( ))":        tests(227).expectedErrContains = "unexpected token" ' [syntax]
  tests(228).expr = "unique(( ))":      tests(228).expectedErrContains = "unexpected token" ' [syntax]
  tests(229).expr = "RestoreAnsFromCachedRender(g_cachedRenderText(i))": tests(229).expectedErrContains = "unknown function" ' [regression-lock]
  tests(230).expr = "deg(pi/2,pi/4)":   tests(230).expected = "(90,45)" ' [ok-array]
  tests(231).expr = "rad(180,90)":      tests(231).expected = "(3.141592653589793,1.570796326794897)" ' [ok-array]
  tests(232).expr = "mean":             tests(232).expectedErrContains = "function: mean(...)" ' [hint]
  tests(233).expr = "floor":            tests(233).expectedErrContains = "function: floor(value)" ' [hint]
  tests(234).expr = "ceil":             tests(234).expectedErrContains = "function: ceil(value)" ' [hint]
  tests(235).expr = "trunc":            tests(235).expectedErrContains = "function: trunc(value)" ' [hint]
  tests(236).expr = "round":            tests(236).expectedErrContains = "function: round(value)" ' [hint]
  tests(237).expr = "sign":             tests(237).expectedErrContains = "function: sign(value)" ' [hint]
  tests(238).expr = "deg":              tests(238).expectedErrContains = "function: deg(...)" ' [hint]
  tests(239).expr = "rad":              tests(239).expectedErrContains = "function: rad(...)" ' [hint]
  tests(240).expr = "int(2.9)":         tests(240).expected = "2" ' [ok-func]
  tests(241).expr = "int(-2.9)":        tests(241).expected = "-2" ' [ok-func]
  tests(242).expr = "frac(2.9)":        tests(242).expected = "0.8999999999999999" ' [ok-func]
  tests(243).expr = "frac(-2.9)":       tests(243).expected = "-0.8999999999999999" ' [ok-func]
  tests(244).expr = "int((2.9,-2.9))":  tests(244).expected = "(2,-2)" ' [ok-array]
  tests(245).expr = "frac((2.9,-2.9))": tests(245).expected = "(0.8999999999999999,-0.8999999999999999)" ' [ok-array]
  tests(246).expr = "int":              tests(246).expectedErrContains = "function: int(value)" ' [hint]
  tests(247).expr = "frac":             tests(247).expectedErrContains = "function: frac(value)" ' [hint]
  tests(248).expr = "fract(2.9)":       tests(248).expected = "0.8999999999999999" ' [ok-func]
  tests(249).expr = "fract((2.9,-2.9))": tests(249).expected = "(0.8999999999999999,-0.8999999999999999)" ' [ok-array]
  tests(250).expr = "fract":            tests(250).expectedErrContains = "function: frac(value)" ' [hint]
  tests(251).expr = "oct(12)":          tests(251).expected = "0o14" ' [ok-func]
  tests(252).expr = "oct((12,255))":    tests(252).expected = "(0o14,0o377)" ' [ok-array]
  tests(253).expr = "10 + oct(12) + 14": tests(253).expected = "36" ' [ok-func]
  tests(254).expr = "oct(12.5)":        tests(254).expectedErrContains = "oct() expects integer values" ' [type-int-only]
  tests(255).expr = "oct":              tests(255).expectedErrContains = "function: oct(...)" ' [hint]
  tests(256).expr = "oct()":            tests(256).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(257).expr = "oct(1,2)":         tests(257).expected = "(0o1,0o2)" ' [ok-array]
  tests(258).expr = "oct((1,2,3),(4))": tests(258).expected = "(0o1,0o2,0o3,0o4)" ' [ok-array]
  tests(259).expr = "oct(15);ans":      tests(259).expected = "0o17" ' [ok-func]
  tests(260).expr = "oct(9223372036854775807+1)": tests(260).expected = "0o1000000000000000000000" ' [overflow]
  tests(261).expr = "0O77":             tests(261).expected = "63" ' [ok-core]
  tests(262).expr = "0o123 + 1":        tests(262).expected = "84" ' [ok-core]
  tests(263).expr = "0o20 & 0xF":       tests(263).expected = "0" ' [ok-core]
  tests(264).expr = "oct((0o7,0o10))":  tests(264).expected = "(0o7,0o10)" ' [ok-array]
  tests(265).expr = "0o64":             tests(265).expected = "52" ' [ok-core]
  tests(266).expr = "0o":               tests(266).expectedErrContains = "invalid octal literal" ' [syntax]
  tests(267).expr = "oct(0o17)":        tests(267).expected = "0o17" ' [ok-func]
  tests(268).expr = "0o10 + 8":         tests(268).expected = "16" ' [ok-core]
  tests(269).expr = "0b110011 & 0x37 | 0o64": tests(269).expected = "55" ' [ok-core]
  tests(270).expr = "0o8":              tests(270).expectedErrContains = "invalid octal literal" ' [syntax]
  tests(271).expr = "5=5":              tests(271).expected = "1" ' [ok-core]
  tests(272).expr = "5==4":             tests(272).expected = "0" ' [ok-core]
  tests(273).expr = "5<>4":             tests(273).expected = "1" ' [ok-core]
  tests(274).expr = "5!=5":             tests(274).expected = "0" ' [ok-core]
  tests(275).expr = "5>4":              tests(275).expected = "1" ' [ok-core]
  tests(276).expr = "5>=5":             tests(276).expected = "1" ' [ok-core]
  tests(277).expr = "4<5":              tests(277).expected = "1" ' [ok-core]
  tests(278).expr = "4<=4":             tests(278).expected = "1" ' [ok-core]
  tests(279).expr = "1|2=3":            tests(279).expected = "1" ' [ok-core]
  tests(280).expr = "1|2<2":            tests(280).expected = "0" ' [ok-core]
  tests(281).expr = "(1,2,3)=(1,2,3)":  tests(281).expected = "1" ' [ok-array]
  tests(282).expr = "(1,2,3)!=(1,2,4)": tests(282).expected = "1" ' [ok-array]
  tests(283).expr = "(1,2)<(1,2,0)":    tests(283).expected = "1" ' [ok-array]
  tests(284).expr = "(1,2,9)>(1,2,3)":  tests(284).expected = "1" ' [ok-array]
  tests(285).expr = "(1,2,3)<=(1,2,3)": tests(285).expected = "1" ' [ok-array]
  tests(286).expr = "(1)<(1,0)":        tests(286).expected = "1" ' [ok-array]
  tests(287).expr = "(1,0)>(1)":        tests(287).expected = "1" ' [ok-array]
  tests(288).expr = "5<(5,1)":          tests(288).expected = "1" ' [ok-array]
  tests(289).expr = "(5,1)>5":          tests(289).expected = "1" ' [ok-array]
  tests(290).expr = "2<3<4":            tests(290).expected = "1" ' [ok-core]
  tests(291).expr = "!0":               tests(291).expected = "1" ' [ok-core]
  tests(292).expr = "!5":               tests(292).expected = "0" ' [ok-core]
  tests(293).expr = "not 0":            tests(293).expected = "1" ' [ok-core]
  tests(294).expr = "not 2":            tests(294).expected = "0" ' [ok-core]
  tests(295).expr = "1&&1":             tests(295).expected = "1" ' [ok-core]
  tests(296).expr = "1&&0":             tests(296).expected = "0" ' [ok-core]
  tests(297).expr = "1||0":             tests(297).expected = "1" ' [ok-core]
  tests(298).expr = "0||0":             tests(298).expected = "0" ' [ok-core]
  tests(299).expr = "1 and 1":          tests(299).expected = "1" ' [ok-core]
  tests(300).expr = "1 and 0":          tests(300).expected = "0" ' [ok-core]
  tests(301).expr = "1 or 0":           tests(301).expected = "1" ' [ok-core]
  tests(302).expr = "0 or 0":           tests(302).expected = "0" ' [ok-core]
  tests(303).expr = "!1=0":             tests(303).expected = "1" ' [ok-core]
  tests(304).expr = "1=1 && 0=1":       tests(304).expected = "0" ' [ok-core]
  tests(305).expr = "1|2==3 && 5>3":    tests(305).expected = "1" ' [ok-core]
  tests(306).expr = "1 || 0 && 0":      tests(306).expected = "1" ' [ok-core]
  tests(307).expr = "(0,0) && 1":       tests(307).expected = "1" ' [ok-array]
  tests(308).expr = "(0,0) || 0":       tests(308).expected = "1" ' [ok-array]
  tests(309).expr = "not (0,0)":        tests(309).expected = "0" ' [ok-array]
  tests(310).expr = "0 or (0,0)":       tests(310).expected = "1" ' [ok-array]
  tests(311).expr = "not 1<0":          tests(311).expected = "1" ' [ok-core]
  tests(312).expr = "!1<0":             tests(312).expected = "0" ' [ok-core]
  tests(313).expr = "reverse((3,1,2))": tests(313).expected = "(2,1,3)" ' [ok-array]
  tests(314).expr = "reverse(2,5,1)":   tests(314).expected = "(1,5,2)" ' [ok-func]
  tests(315).expr = "reverse((1,2,3),(4,5,6),(7,8,9))": tests(315).expected = "(9,8,7,6,5,4,3,2,1)" ' [ok-array]
  tests(316).expr = "reverse(5)":       tests(316).expected = "(5)" ' [ok-func]
  tests(317).expr = "reverse":          tests(317).expectedErrContains = "function: reverse(...)" ' [hint]
  tests(318).expr = "reverse()":        tests(318).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(319).expr = "reverse((2,5,1),4,3)": tests(319).expected = "(3,4,1,5,2)" ' [ok-array]
  tests(320).expr = "reverse(( ))":     tests(320).expectedErrContains = "unexpected token" ' [syntax]
  tests(321).expr = "(10,20,30)[0]":    tests(321).expected = "10" ' [ok-array]
  tests(322).expr = "(10,20,30)[2]":    tests(322).expected = "30" ' [ok-array]
  tests(323).expr = "(10,20,30)[-1]":   tests(323).expected = "30" ' [ok-array]
  tests(324).expr = "(10,20,30)[-2]":   tests(324).expected = "20" ' [ok-array]
  tests(325).expr = "(10,20,30)[-3]":   tests(325).expected = "10" ' [ok-array]
  tests(326).expr = "(10,20,30)[-4]":   tests(326).expectedErrContains = "array index is out of range" ' [edge]
  tests(327).expr = "(10,20,30)[3]":    tests(327).expectedErrContains = "array index is out of range" ' [edge]
  tests(328).expr = "sort((3,1,2,4))[-1]": tests(328).expected = "4" ' [ok-array]
  tests(329).expr = "reverse((1,2,3,4))[-1]": tests(329).expected = "1" ' [ok-array]
  tests(330).expr = "reverse((1,2,3,4))[0]": tests(330).expected = "4" ' [ok-array]
  tests(331).expr = "sorted((3,1,2))":  tests(331).expected = "(1,2,3)" ' [ok-array]
  tests(332).expr = "sorted(2,5,1)":    tests(332).expected = "(1,2,5)" ' [ok-func]
  tests(333).expr = "sorted":           tests(333).expectedErrContains = "function: sort(...)" ' [hint]
  tests(334).expr = "reversed((1,2,3),(4,5))": tests(334).expected = "(5,4,3,2,1)" ' [ok-array]
  tests(335).expr = "reversed":         tests(335).expectedErrContains = "function: reverse(...)" ' [hint]
  tests(336).expr = "reversed((1,2,3,4))[-1]": tests(336).expected = "1" ' [ok-array]
  tests(337).expr = "3 + not 4":        tests(337).expected = "3" ' [ok-core]
  tests(338).expr = "3 + not 4 + 5":    tests(338).expected = "3" ' [ok-core]
  tests(339).expr = "oct(80)":          tests(339).expected = "0o120" ' [ok-func]
  tests(340).expr = "oct(0)":           tests(340).expected = "0o0" ' [edge]
  tests(341).expr = "oct(-1)":          tests(341).expected = "-0o1" ' [edge]
  tests(342).expr = "sin(x)=x":         tests(342).expectedErrContains = "reserved function name" ' [syntax]
  tests(343).expr = "oct(x)=x":         tests(343).expectedErrContains = "reserved function name" ' [syntax]
  tests(344).expr = "not(x)=x":         tests(344).expectedErrContains = "reserved function name" ' [syntax]
  tests(345).expr = "f(x,y)=x*y; a=(2,3); f(unpack(a))": tests(345).expected = "6" ' [ok-func]
  tests(346).expr = "f(x,y,z)=x+y+z; f(unpack((1,2,3)))": tests(346).expected = "6" ' [ok-array]
  tests(347).expr = "unpack((1,2,3))":  tests(347).expected = "(1,2,3)" ' [ok-array]
  tests(348).expr = "unpack(5)":        tests(348).expected = "5" ' [ok-func]
  tests(349).expr = "unpack":           tests(349).expectedErrContains = "function: unpack(...)" ' [hint]
  tests(350).expr = "sum(unpack((1,2,3)))": tests(350).expected = "6" ' [ok-func]
  tests(351).expr = "f(x,y)=x*y; f(unpack((2,3,4)))": tests(351).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(352).expr = "f(x,y,z)=x+y+z; f(unpack(1,2,3))": tests(352).expected = "6" ' [ok-func]
  tests(353).expr = "f(a,b,c,d,t)=a+b+c+d+t; f(unpack((1,2),3,(4,5)))": tests(353).expected = "15" ' [ok-array]
  tests(354).expr = "unpack((1,2),3,(4,5))": tests(354).expected = "(1,2,3,4,5)" ' [ok-array]

  ' === Leading identifier: '=' assignment vs '==' equality (must not steal '=' from '==') ===
  tests(355).expr = "a=5; a==5":              tests(355).expected = "1" ' [syntax] single == after assign
  tests(356).expr = "b=3; b==4":              tests(356).expected = "0" ' [syntax]
  tests(357).expr = "7==7":                   tests(357).expected = "1" ' [ok-core] one ==, literals only
  tests(358).expr = "3==3 && 4==4 && 5==5":   tests(358).expected = "1" ' [ok-core] multiple ==
  tests(359).expr = "(1==1)==(0==0)":         tests(359).expected = "1" ' [ok-core] multiple ==
  tests(360).expr = "5==5==1":                tests(360).expected = "1" ' [ok-core] chained ==
  tests(361).expr = "u=2; v=2; u==v":         tests(361).expected = "1" ' [syntax] = and ==
  tests(362).expr = "k=9; k==9 && k==3+6":    tests(362).expected = "1" ' [syntax] = and multiple ==
  tests(363).expr = "a=1; b=1; a==b==1":      tests(363).expected = "1" ' [syntax] = and chained ==

  ' === [spec] Float-derived scalars promote to exact int64 when representable (bitwise/shift/metadata) ===
  tests(364).expr = "int(7/3) << 60":         tests(364).expected = "2305843009213693952" ' 2<<60, int from float
  tests(365).expr = "sqrt(9) << 2":          tests(365).expected = "12" ' sqrt via float, then shift
  tests(366).expr = "abs(-4) << 1":           tests(366).expected = "8"
  tests(367).expr = "sum(3,5) << 2":          tests(367).expected = "32" ' aggregate float path + shift
  tests(368).expr = "(7/3.5) << 3":           tests(368).expected = "16" ' pure float division, exact int

  ' === '=' assignment (leading identifier + single '=') vs '=' comparison in expressions ===
  tests(369).expr = "x=7; x=x":                tests(369).expected = "7" ' [syntax] leading x=x is assign, not compare
  tests(370).expr = "x=7; x==x":               tests(370).expected = "1" ' [syntax]
  tests(371).expr = "x=7; (x)=(x)":           tests(371).expected = "1" ' [syntax] paren => full expr; = is compare
  tests(372).expr = "x=5; x=x+1":             tests(372).expected = "6" ' [syntax] assign RHS uses +
  tests(373).expr = "z=0; (z)=(z)":           tests(373).expected = "1" ' [syntax] compare; z defined first
  tests(374).expr = "a=2; 1+a=3":             tests(374).expected = "1" ' [syntax] expr does not start with bare name; = compare
  tests(375).expr = "b=2; b+0=2":             tests(375).expected = "1" ' [syntax] leading term is not lone identifier assign form
  tests(376).expr = "c=1; c=2; c=c":           tests(376).expected = "2" ' [syntax] last c=c is assign
  tests(377).expr = "d=4; d = d":             tests(377).expected = "4" ' [syntax] spaces around assign =
  tests(378).expr = "t=3; (t=3)":             tests(378).expected = "1" ' [syntax] inner t=3 is compare ('e' is constant, not a var)
  tests(379).expr = "x=2;y=5;x+y=x":          tests(379).expected = "0" ' [syntax] (x+y)=x compare, not assign; 7=2 -> false
  tests(380).expr = "x=2;y=3;x*y=x*y":        tests(380).expected = "1" ' [syntax] (x*y)=(x*y) compare -> true

  ' === [spec] Built-in constants (pi, e) cannot be variable/function/param names ===
  tests(381).expr = "e=1":                    tests(381).expectedErrContains = "reserved constant name" ' [syntax]
  tests(382).expr = "PI=2":                   tests(382).expectedErrContains = "reserved constant name" ' [syntax] case-insensitive
  tests(383).expr = "f(e)=e+1":               tests(383).expectedErrContains = "reserved constant name" ' [syntax] param
  tests(384).expr = "pi(x)=x":                tests(384).expectedErrContains = "reserved constant name" ' [syntax] function name

  ' === hex() signed magnitude vs uhex/uoct/ubin (unsigned / two's complement) ===
  tests(385).expr = "hex(~0x0D)":             tests(385).expected = "-0xE" ' signed: -14
  tests(386).expr = "hex(-1)":                tests(386).expected = "-0x1"
  tests(387).expr = "uhex(~0x0D)":           tests(387).expected = "0xFFFFFFFFFFFFFFF2"
  tests(388).expr = "uhex(-1)":              tests(388).expected = "0xFFFFFFFFFFFFFFFF"
  tests(389).expr = "ubin(-1)":              tests(389).expected = "0b1111111111111111111111111111111111111111111111111111111111111111"
  tests(390).expr = "uoct(-1)":              tests(390).expected = "0o1777777777777777777777"
  tests(391).expr = "uhex()":                tests(391).expectedErrContains = "expects at least 1 argument"
  tests(392).expr = "uhex":                  tests(392).expectedErrContains = "function: uhex(...)"
  tests(393).expr = "uhex(1,2)":             tests(393).expected = "(0x1,0x2)"
  tests(394).expr = "bin(-2)":               tests(394).expected = "-0b10" ' bin/oct/hex still signed magnitude

  ' === int64 accuracy after float-path round-trip (scalar + array) ===
  tests(395).expr = "sqrt(81)&7":                                tests(395).expected = "1"
  tests(396).expr = "hex(sqrt(81))":                             tests(396).expected = "0x9"
  tests(397).expr = "mod(abs(-14),5)":                           tests(397).expected = "4"
  tests(398).expr = "pow(3,2)&7":                                tests(398).expected = "1"
  tests(399).expr = "hex(int((9007199254740992+2)/1))":          tests(399).expected = "0x20000000000002"
  tests(400).expr = "hex(int((9007199254740992+2)/2+0.0))":      tests(400).expected = "0x10000000000001"

  tests(401).expr = "a=sqrt((81,16,25)); a[0]&3":                tests(401).expected = "1"
  tests(402).expr = "a=sqrt((81,16,25)); hex(a[2])":             tests(402).expected = "0x5"
  tests(403).expr = "a=int((2.9,-2.9,7.1)); a[1]&1":             tests(403).expected = "0"
  tests(404).expr = "a=int((2.9,-2.9,7.1)); hex(a[0])":          tests(404).expected = "0x2"
  tests(405).expr = "a=int(((9007199254740992+2),(9007199254740992+6))/1); hex(a[0])": tests(405).expected = "0x20000000000002"
  tests(406).expr = "a=int(((9007199254740992+2),(9007199254740992+6))/1); mod(a[1],4)": tests(406).expected = "2"
  tests(407).expr = "a=int(((9007199254740992+2),(9007199254740992+6))/2); a[0]&1": tests(407).expected = "1"
  tests(408).expr = "a=int(((9007199254740992+2),(9007199254740992+6))/2); hex(a[1])": tests(408).expected = "0x10000000000003"
  tests(409).expr = "a=int(((5.9+0.1),(9.2+0.8))); mod(a[1],4)": tests(409).expected = "2"
  tests(410).expr = "a=int(((5.9+0.1),(9.2+0.8))); hex(a[0])":   tests(410).expected = "0x6"
  tests(411).expr = "a=(4611686018427387903,5)<<1; hex(a[0])":   tests(411).expected = "0x7FFFFFFFFFFFFFFE"
  tests(412).expr = "a=(4611686018427387903,5)<<1; mod(a[0],7)": tests(412).expected = "6"
  tests(413).expr = "a=(4611686018427387903,5)<<1; b=a>>1; hex(b[0])": tests(413).expected = "0x3FFFFFFFFFFFFFFF"
  tests(414).expr = "a=(9223372036854775806,15); b=a&7; hex(b[0])": tests(414).expected = "0x6"
  tests(415).expr = "a=(9223372036854775800,1); b=a|7; hex(b[0])": tests(415).expected = "0x7FFFFFFFFFFFFFFF"
  tests(416).expr = "a=(9223372036854775806,9223372036854775805); mod(a[1],5)": tests(416).expected = "0"
  tests(417).expr = "a=(9223372036854775806,9223372036854775805); b=a>>2; hex(b[0])": tests(417).expected = "0x1FFFFFFFFFFFFFFF"
  tests(418).expr = "-1>>1":                                     tests(418).expected = "-1"
  tests(419).expr = "uhex(1<<63)":                               tests(419).expected = "0x8000000000000000"
  tests(420).expr = "a=(-1,-2)>>1; a[0]":                        tests(420).expected = "-1"
  tests(421).expr = "a=(-1,3)<<1; uhex(a[0])":                   tests(421).expected = "0xFFFFFFFFFFFFFFFE"
  tests(422).expr = "a=(-1,-2)>>1; uhex(a[1])":                  tests(422).expected = "0xFFFFFFFFFFFFFFFF"
  tests(423).expr = "(1+2)(3+4)":                                tests(423).expected = "21"
  tests(424).expr = "2(1+pi)":                                   tests(424).expected = "8.283185307179586"
  tests(425).expr = "a=(3,4)+(5,6); hex(a[0])":                  tests(425).expected = "0x8"
  tests(426).expr = "a=(3,4)*2; hex(a[1])":                      tests(426).expected = "0x8"
  tests(427).expr = "a=2*(3,4); hex(a[1])":                      tests(427).expected = "0x8"
  tests(428).expr = "a=(1,2)&3; hex(a[1])":                      tests(428).expected = "0x2"
  tests(429).expr = "a=3&(1,2); hex(a[1])":                      tests(429).expected = "0x2"
  tests(430).expr = "a=(1,2)&(3,4); hex(a[1])":                  tests(430).expected = "0x0"
  tests(431).expr = "log((8,100),(2,10))":                       tests(431).expected = "(3,2)"
  tests(432).expr = "clamp((1,9),(0,10),(5,7))":                 tests(432).expectedErrContains = "expects scalar min/max"
  tests(433).expr = "clamp(5,(1,6),(4,7))":                      tests(433).expectedErrContains = "expects scalar min/max"
  tests(434).expr = "gcd((84,30),6)":                            tests(434).expectedErrContains = "expects scalar values"
  tests(435).expr = "gcd(6,(84,30))":                            tests(435).expectedErrContains = "expects scalar values"
  tests(436).expr = "lcm((6,8),3)":                              tests(436).expectedErrContains = "expects scalar values"
  tests(437).expr = "lcm((6,8),(3,5))":                          tests(437).expectedErrContains = "expects scalar values"
  tests(438).expr = "16>>1>>2":                                  tests(438).expected = "2"
  tests(439).expr = "7&3|8":                                     tests(439).expected = "11"
  tests(440).expr = "7^3^1":                                     tests(440).expected = "5"
  tests(441).expr = "hex(-2)":                                   tests(441).expected = "-0x2"
  tests(442).expr = "uhex(-2)":                                  tests(442).expected = "0xFFFFFFFFFFFFFFFE"
  tests(443).expr = "hex((15,-2))":                              tests(443).expected = "(0xF,-0x2)"
  tests(444).expr = "hypot(1,2,3,4)":                            tests(444).expectedErrContains = "expects 2 argument(s)"
  tests(445).expr = "a=9007199254740992+1; b=a; hex(b)":         tests(445).expected = "0x20000000000001"
  tests(446).expr = "uhex((1,-1))":                              tests(446).expected = "(0x1,0xFFFFFFFFFFFFFFFF)"
  tests(447).expr = "sum(unpack((1,2),(3,4),5))":                tests(447).expected = "15"
  tests(448).expr = "a=(1,2)+(3,4); hex(a[1])":                  tests(448).expected = "0x6"
  tests(449).expr = "NoT 0":                                     tests(449).expected = "1"
  tests(450).expr = "(5>=4)<2":                                  tests(450).expected = "1"
  tests(451).expr = "a=round((1.2,2.8)); hex(a[1])":             tests(451).expected = "0x3"
  tests(452).expr = "a=(5,6)*(7,8); hex(a[1])":                  tests(452).expected = "0x30"
  tests(453).expr = "a=(10,20)-(3,4); hex(a[1])":                tests(453).expected = "0x10"
  tests(454).expr = "a=(20,21)%(3,4); hex(a[1])":                tests(454).expected = "0x1"
  tests(455).expr = "log(8,(2,4))":                              tests(455).expected = "(3,1.5)"
  tests(456).expr = "lcm(21,6)":                                 tests(456).expected = "42"
  tests(457).expr = "a=(1,2)|(4,8); hex(a[1])":                 tests(457).expected = "0xA"
  tests(458).expr = "a=(1,2)^(4,8); hex(a[1])":                 tests(458).expected = "0xA"
  tests(459).expr = "a=(1,(2+3),7); hex(a[1])":                 tests(459).expected = "0x5"
  tests(460).expr = "a=abs((-1,-2)); hex(a[1])":                tests(460).expected = "0x2"
  tests(461).expr = "a=-(-1,-2); hex(a[1])":                    tests(461).expected = "0x2"
  tests(462).expr = "a=(8,9)>>1; hex(a[1])":                    tests(462).expected = "0x4"
  tests(463).expr = "a=(8,9)<<1; hex(a[1])":                    tests(463).expected = "0x12"
  tests(464).expr = "a=(9,10)&(3,12); hex(a[1])":               tests(464).expected = "0x8"
  tests(465).expr = "a=(9,10)|(3,12); hex(a[1])":               tests(465).expected = "0xE"
  tests(466).expr = "a=(9,10)^(3,12); hex(a[0])":               tests(466).expected = "0xA"
  tests(467).expr = "a=abs((-3,-4)); hex(a[0])":                tests(467).expected = "0x3"
  tests(468).expr = "a=(1,(2+3),4); hex(a[2])":                 tests(468).expected = "0x4"
  tests(469).expr = "a=int((7.9,8.1)); hex(a[1])":              tests(469).expected = "0x8"
  tests(470).expr = "a=(20,21)%(6,4); hex(a[0])":               tests(470).expected = "0x2"
  tests(471).expr = "a=(2,3)+(4,5); hex(a[1])":                 tests(471).expected = "0x8"
  tests(472).expr = "a=(9,7)-(4,5); hex(a[0])":                 tests(472).expected = "0x5"
  tests(473).expr = "a=(3,4)*(5,6); hex(a[0])":                 tests(473).expected = "0xF"
  tests(474).expr = "a=(8,9)/1; hex(a[1])":                     tests(474).expected = "0x9"
  tests(475).expr = "a=int((8.9,9.1)); hex(a[0])":              tests(475).expected = "0x8"
  tests(476).expr = "a=round((8.2,9.8)); hex(a[0])":            tests(476).expected = "0x8"
  tests(477).expr = "a=-(-5,-6); hex(a[0])":                    tests(477).expected = "0x5"
  tests(478).expr = "a=abs((-1,-2,-3)); hex(a[2])":             tests(478).expected = "0x3"
  tests(479).expr = "a=(8,9)|1; hex(a[0])":                     tests(479).expected = "0x9"
  tests(480).expr = "a=(8,9)&7; hex(a[0])":                     tests(480).expected = "0x0"
  tests(481).expr = "a=(8,9)<<1; hex(a[0])":                    tests(481).expected = "0x10"
  tests(482).expr = "a=(8,9)>>1; hex(a[0])":                    tests(482).expected = "0x4"
  tests(483).expr = "a=(20,21)%(6,4); hex(a[1])":               tests(483).expected = "0x1"
  tests(484).expr = "a=int((5.9,6.1,7.2)); hex(a[2])":          tests(484).expected = "0x7"
  tests(485).expr = "a=round((5.2,6.8,7.1)); hex(a[2])":        tests(485).expected = "0x7"
  tests(486).expr = "a=abs((-5,-6,-7)); hex(a[1])":             tests(486).expected = "0x6"
  tests(487).expr = "a=(8,9)|2; hex(a[1])":                     tests(487).expected = "0xB"
  tests(488).expr = "a=(8,9)&3; hex(a[1])":                     tests(488).expected = "0x1"
  tests(489).expr = "a=(8,9)^3; hex(a[1])":                     tests(489).expected = "0xA"
  tests(490).expr = "a=(10,11)+(1,2); hex(a[0])":               tests(490).expected = "0xB"
  tests(491).expr = "a=(10,11)-(1,2); hex(a[1])":               tests(491).expected = "0x9"
  tests(492).expr = "a=(10,11)*(2,3); hex(a[1])":               tests(492).expected = "0x21"
  tests(493).expr = "a=(10,11)/1; hex(a[0])":                   tests(493).expected = "0xA"
  tests(494).expr = "a=int((10.9,11.1)); hex(a[1])":            tests(494).expected = "0xB"
  tests(495).expr = "a=round((10.2,11.8)); hex(a[1])":          tests(495).expected = "0xC"
  tests(496).expr = "a=abs((-10,-11)); hex(a[0])":              tests(496).expected = "0xA"
  tests(497).expr = "a=-(-10,-11); hex(a[1])":                  tests(497).expected = "0xB"
  tests(498).expr = "a=(8,9,10)|1; hex(a[2])":                  tests(498).expected = "0xB"
  tests(499).expr = "a=(8,9,10)&3; hex(a[2])":                  tests(499).expected = "0x2"
  tests(500).expr = "a=(8,9,10)^3; hex(a[2])":                  tests(500).expected = "0x9"
  tests(501).expr = "a=(10,11)>>1; hex(a[1])":                  tests(501).expected = "0x5"
  tests(502).expr = "unique((5,3,5,2,3))":                      tests(502).expected = "(5,3,2)"
  tests(503).expr = "unique((2,1,2,1,3,2))":                    tests(503).expected = "(2,1,3)"
  tests(504).expr = "unique(7)":                                tests(504).expected = "(7)"
  tests(505).expr = "unique((0,-0,0,0))":                       tests(505).expected = "(0)"
  tests(506).expr = "unique((-0,0,1))":                         tests(506).expected = "(0,1)"
  tests(507).expr = "unique((1.5,1.5,2.5,1.5))":                tests(507).expected = "(1.5,2.5)"
  tests(508).expr = "unique((2.0,2,2.000,3))":                  tests(508).expected = "(2,3)"
  tests(509).expr = "unique(unpack((4,1),(4,2),1))":            tests(509).expected = "(4,1,2)"
  tests(510).expr = "unique((9,8,7,9,8,7,6,5,6))":              tests(510).expected = "(9,8,7,6,5)"
  tests(511).expr = "unique((3,3,3,3,2,2,1))":                  tests(511).expected = "(3,2,1)"
  tests(512).expr = "median((9,1,5,3,7))":                      tests(512).expected = "5"
  tests(513).expr = "median((10,1,7,3))":                       tests(513).expected = "5"
  tests(514).expr = "hex(fact(20))":                            tests(514).expected = "0x21C3677C82B40000"
  tests(515).expr = "factorial(30)":                            tests(515).expected = "2.65252859812191e+032"
  tests(516).expr = "sort((5,1,5,2,2,9,1))":                    tests(516).expected = "(1,1,2,2,5,5,9)"
  tests(517).expr = "sorted((4,4,3,2,2,1))":                    tests(517).expected = "(1,2,2,3,4,4)"
  tests(518).expr = "avg((2,4),6,8)":                           tests(518).expected = "5"
  tests(519).expr = "min((5,7),3,9)":                           tests(519).expected = "3"
  tests(520).expr = "sum(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)": tests(520).expected = "136"
  tests(521).expr = "max((5,7),3,9)":                           tests(521).expected = "9"
  tests(522).expr = "sum(unpack((1,2,3),(4,5),6,7))":          tests(522).expected = "28"
  tests(523).expr = "sorted((3,3,1,2,1))":                     tests(523).expected = "(1,1,2,3,3)"
  tests(524).expr = "reversed((1,2,3,4,5))":                   tests(524).expected = "(5,4,3,2,1)"
  tests(525).expr = "f(x,y)=x+y; f(2,3)":                      tests(525).expected = "5"
  tests(526).expr = "a=(5,2,5,9,2); unique(a)":                tests(526).expected = "(5,2,9)"
  tests(527).expr = "sum(42)":                                 tests(527).expected = "42"
  tests(528).expr = "a=(3,1,2); sorted(a)":                    tests(528).expected = "(1,2,3)"
  tests(529).expr = "unique((1,1,2,2,3,3))":                  tests(529).expected = "(1,2,3)"
  tests(530).expr = "avg(unpack((1,2),(3,4)),10)":            tests(530).expected = "4"
  tests(531).expr = "reverse((1,2),3,(4,5))":                 tests(531).expected = "(5,4,3,2,1)"
  tests(532).expr = "f(a,b)=a*b; f(unpack((3,4)))":           tests(532).expected = "12"
  tests(533).expr = "a=(9007199254740993); hex(unpack(a))":      tests(533).expected = "0x20000000000001"
  tests(534).expr = "a=-(9007199254740991,5); uhex(a[0])":    tests(534).expected = "0xFFE0000000000001"
  tests(535).expr = "hex((1,2.5))":                            tests(535).expectedErrContains = "hex() expects integer values"
  tests(536).expr = "unique((9,9,8,8,7))":                     tests(536).expected = "(9,8,7)"
  tests(537).expr = "reverse((9,8,7,6))":                      tests(537).expected = "(6,7,8,9)"
  tests(538).expr = "deg((pi/2),pi)":                          tests(538).expected = "(90,180)"
  tests(539).expr = "uhex((1,-1),2)":                          tests(539).expected = "(0x1,0xFFFFFFFFFFFFFFFF,0x2)"
  tests(540).expr = "uhex(unpack((1,-1),2))":                  tests(540).expected = "(0x1,0xFFFFFFFFFFFFFFFF,0x2)"
  tests(541).expr = "median(42)":                              tests(541).expected = "42"
  tests(542).expr = "median((42))":                            tests(542).expected = "42"
  tests(543).expr = "123":                                     tests(543).expected = "123"
  tests(544).expr = "unknownFunc(1)":                          tests(544).expectedErrContains = "unknown function"
  tests(545).expr = "2+3; ans":                                tests(545).expected = "5"
  tests(546).expr = "(e=3)":                                   tests(546).expected = "0"
  tests(547).expr = "(pi=3.141592653589793)":                  tests(547).expected = "1"
  tests(548).expr = "(1,2,3)[1.2]":                            tests(548).expectedErrContains = "array index must be an integer"
  tests(549).expr = "(1,2,3)[(1,2)]":                          tests(549).expectedErrContains = "array index must be a scalar integer"
  tests(550).expr = "1<<0":                                    tests(550).expected = "1"
  tests(551).expr = "8>>0":                                    tests(551).expected = "8"
  tests(552).expr = "1<<63":                                   tests(552).expected = "9223372036854775808"
  tests(553).expr = "-1>>63":                                  tests(553).expected = "-1"
  tests(554).expr = "a=(1,2)<<0; a":                           tests(554).expected = "(1,2)"
  tests(555).expr = "a=(8,9)>>0; a":                           tests(555).expected = "(8,9)"
  tests(556).expr = "a=(1,2)<<63; uhex(a[0])":                 tests(556).expected = "0x8000000000000000"
  tests(557).expr = "a=(-1,-2)>>63; a[1]":                     tests(557).expected = "-1"
  tests(558).expr = "0b102":                                   tests(558).expectedErrContains = "unexpected token"
  tests(559).expr = "0o89":                                    tests(559).expectedErrContains = "invalid octal literal"
  tests(560).expr = "0x1G":                                    tests(560).expectedErrContains = "unexpected token"
  tests(561).expr = "hex=1":                                   tests(561).expectedErrContains = "reserved function name"
  tests(562).expr = "HEX=1":                                   tests(562).expectedErrContains = "reserved function name"
  tests(563).expr = "random=1":                                tests(563).expectedErrContains = "reserved function name"
  tests(564).expr = "0xAA; hex":                               tests(564).expected = "0xAA"
  tests(565).expr = "0xAA; hex()":                             tests(565).expected = "0xAA"
  tests(566).expr = "(0x3C & 0x75, 0x01 | 0x30); hex":         tests(566).expected = "(0x34,0x31)"
  tests(567).expr = "(8,9); bin()":                            tests(567).expected = "(0b1000,0b1001)"
  tests(568).expr = "15; uhex":                                tests(568).expected = "0xF"
  tests(569).expr = "0xAA; foo()":                             tests(569).expectedErrContains = "unknown function"

  tests(570).expr = "x(a)=x(a); x(1)":                        tests(570).expectedErrContains = "recursive function call: x" ' [regression] direct self-call in UDF body
  tests(571).expr = "y(a)=g(a)+y(a)+4":                      tests(571).expectedErrContains = "recursive function call: y" ' [regression] self-call among other terms
  tests(572).expr = "g(a)=y(a)+1; y(a)=g(a)+2; y(5)":        tests(572).expectedErrContains = "recursive function call" ' [regression] mutual recursion y<->g
  tests(573).expr = "a(x)=b(x); b(x)=c(x); c(x)=d(x); d(x)=b(x); a(1)": tests(573).expectedErrContains = "recursive function call" ' [regression] longer cycle back to b
  tests(574).expr = "2^3":                                   tests(574).expected = "1" ' [regression] caret is bitwise XOR
  tests(575).expr = "3^2":                                   tests(575).expected = "1" ' [regression] caret is not power
  tests(576).expr = "3**2":                                  tests(576).expected = "9" ' [regression] double-star power
  tests(577).expr = "f(x)=x*p(x); f(2)":                     tests(577).expectedErrContains = "unknown function" ' [regression] late binding unresolved referenced UDF
  tests(578).expr = "f(x)=x*p(x); p(x)=x+5; f(10)":          tests(578).expected = "150" ' [regression] late binding resolved after referenced UDF definition
  tests(579).expr = "f(x)=x*p(x); p(x)=x**(1/3); f(8)":      tests(579).expected = "16" ' [regression] late binding with nonlinear referenced UDF
  tests(580).expr = "f(x)=x*p(x); p(x)=x+5; p(x)=x**(1/3); f(8)": tests(580).expected = "16" ' [regression] late binding uses latest referenced UDF definition

  ' --- Additional scalar-vs-array / precedence clarity checks (auto-loaded by C++ smoke runner) ---
  tests(581).expr = "((5))":        tests(581).expected = "5"   ' grouping only => scalar
  tests(582).expr = "!2==1":       tests(582).expected = "0"   ' (!2)==1 because ! has higher precedence
  tests(583).expr = "not 2==1":    tests(583).expected = "1"   ' not (2==1) because not is lower than ==

  ' Additional scalar-vs-array ambiguity locks:
  tests(584).expr = "!(0,0)":        tests(584).expected = "0" ' non-empty arrays are truthy, even if all elements are 0
  tests(585).expr = "0&&(0,0)":      tests(585).expected = "0" ' scalar 0 && truthy array => 0
  tests(586).expr = "((0))&((0))":   tests(586).expected = "0" ' scalar grouping for bitwise & => scalar
  tests(587).expr = "(0,0)&(0,0)":  tests(587).expected = "(0,0)" ' array & array => element-wise array

  ' Additional variants mirrored from C++ unit coverage:
  tests(588).expr = "NOT (0,0)":         tests(588).expected = "0"
  tests(589).expr = "0||(0,0)":          tests(589).expected = "1"
  tests(590).expr = "((0))|((0))":      tests(590).expected = "0"
  tests(591).expr = "(0,0)|(0,0)":     tests(591).expected = "(0,0)"

  tests(592).expr = "a=42; a+1": tests(592).expected = "43"
  tests(593).expr = "rate=1.5; rate*8": tests(593).expected = "12"
  tests(594).expr = "mul3(x)=x*3; mul3(7)": tests(594).expected = "21"
  tests(595).expr = "!(0)": tests(595).expected = "1"
  tests(596).expr = "((0))&&1": tests(596).expected = "0"
  tests(597).expr = "(0,0)&&1": tests(597).expected = "1"
  tests(598).expr = "(0,0)|1": tests(598).expected = "(1,1)"
  tests(599).expr = "k=0; k+0": tests(599).expected = "0"
  tests(600).expr = "k=0; hex(k)": tests(600).expected = "0x0"
  tests(601).expr = "k=1; k*k": tests(601).expected = "1"
  tests(602).expr = "k=1; hex(k)": tests(602).expected = "0x1"
  tests(603).expr = "k=100; k+1": tests(603).expected = "101"
  tests(604).expr = "k=100; hex(k)": tests(604).expected = "0x64"
  tests(605).expr = "k=1000000; k+1": tests(605).expected = "1000001"
  tests(606).expr = "k=1000000; hex(k)": tests(606).expected = "0xF4240"
  tests(607).expr = "k=9223372036854775807; k+0": tests(607).expected = "9223372036854775807"
  tests(608).expr = "k=-9223372036854775808; k+0": tests(608).expected = "-9223372036854775808"
  tests(609).expr = "k=9223372036854775807; (k-1)+1": tests(609).expected = "9223372036854775807"
  tests(610).expr = "k=9007199254740992; hex(k+1)": tests(610).expected = "0x20000000000001"
  tests(611).expr = "k=9007199254740991; k+1": tests(611).expected = "9007199254740992"
  tests(612).expr = "a=100; gcd(a,25)": tests(612).expected = "25"
  tests(613).expr = "a=100; mod(a,3)": tests(613).expected = "1"
  tests(614).expr = "a=100; a&7": tests(614).expected = "4"
  tests(615).expr = "x=100.7; int(x)": tests(615).expected = "100"
  tests(616).expr = "k=9223372036854775806; k+1": tests(616).expected = "9223372036854775807"
  tests(617).expr = "k=9223372036854775806; k+0": tests(617).expected = "9223372036854775806"
  tests(618).expr = "k=-9223372036854775807; k-1": tests(618).expected = "-9223372036854775808"
  tests(619).expr = "k=-9223372036854775807; k+0": tests(619).expected = "-9223372036854775807"
  tests(620).expr = "9223372036854775806+1": tests(620).expected = "9223372036854775807"
  tests(621).expr = "-9223372036854775807-1": tests(621).expected = "-9223372036854775808"
  tests(622).expr = "-9223372036854775807+0": tests(622).expected = "-9223372036854775807"
  tests(623).expr = "k=9223372036854775806; hex(k)": tests(623).expected = "0x7FFFFFFFFFFFFFFE"
  tests(624).expr = "k=-9223372036854775807; hex(k)": tests(624).expected = "-0x7FFFFFFFFFFFFFFF"
  tests(625).expr = "k=-9223372036854775807; uhex(k)": tests(625).expected = "0x8000000000000001"
  tests(626).expr = "k=9007199254740990; k+2": tests(626).expected = "9007199254740992"
  tests(627).expr = "k=9007199254740991; k+2": tests(627).expected = "9007199254740993"
  tests(628).expr = "k=9007199254740992; k+2": tests(628).expected = "9007199254740994"
  tests(629).expr = "k=9007199254740991; int(k)": tests(629).expected = "9007199254740991"
  tests(630).expr = "k=9007199254740994; hex(int(k/1))": tests(630).expected = "0x20000000000002"
  tests(631).expr = "k=9007199254740992; hex(int((k/2)+0.0))": tests(631).expected = "0x10000000000000"
  tests(632).expr = "k=9007199254740992; a=int(((k+2),(k+6))/1); hex(a[0])": tests(632).expected = "0x20000000000002"
  tests(633).expr = "k=9007199254740992; a=int(((k+2),(k+6))/1); mod(a[1],4)": tests(633).expected = "2"
  tests(634).expr = "k=9007199254740992; a=int(((k+2),(k+6))/2); a[0]&1": tests(634).expected = "1"
  tests(635).expr = "k=9007199254740992; a=int(((k+2),(k+6))/2); hex(a[1])": tests(635).expected = "0x10000000000003"
  tests(636).expr = "x=0.0/0.0; x+0": tests(636).expected = "nan"
  tests(637).expr = "x=1.0/0.0; x+0": tests(637).expected = "inf"
  tests(638).expr = "x=-1.0/0.0; x+0": tests(638).expected = "-inf"
  tests(639).expr = "x=1.0/0.0; x+1": tests(639).expected = "inf"
  tests(640).expr = "x=-1.0/0.0; x-1": tests(640).expected = "-inf"
  tests(641).expr = "x=0.0/0.0; x+1": tests(641).expected = "nan"
  tests(642).expr = "x=-1.0/0.0; abs(x)": tests(642).expected = "inf"
  tests(643).expr = "x=0.0/0.0; abs(x)": tests(643).expected = "nan"
  tests(644).expr = "x=1.0/0.0; sign(x)": tests(644).expected = "1"
  tests(645).expr = "x=-1.0/0.0; sign(x)": tests(645).expected = "-1"
  tests(646).expr = "x=0.0/0.0; sign(x)": tests(646).expected = "1"
  tests(647).expr = "x=0.0/0.0; ln(x)": tests(647).expected = "nan"
  tests(648).expr = "x=1.0/0.0; ln(x)": tests(648).expected = "inf"
  tests(649).expr = "z=0.0; ln(z)": tests(649).expected = "-inf"
  tests(650).expr = "x=0.0/0.0; sqrt(x)": tests(650).expected = "nan"
  tests(651).expr = "x=1.0/0.0; sin(x)": tests(651).expected = "nan"
  tests(652).expr = "x=1.0/0.0; frac(x)": tests(652).expected = "inf"
  tests(653).expr = "x=0.0/0.0; not x": tests(653).expected = "1"
  tests(654).expr = "x=1.0/0.0; not x": tests(654).expected = "0"
  tests(655).expr = "x=0.0/0.0; x&&1": tests(655).expected = "0"
  tests(656).expr = "x=0.0/0.0; x||1": tests(656).expected = "1"
  tests(657).expr = "x=0.0/0.0; x==x": tests(657).expected = "0"
  tests(658).expr = "200 + 2*15%": tests(658).expected = "200.3"
  tests(659).expr = "unpack((1,2),3)": tests(659).expected = "(1,2,3)"
  tests(660).expr = "unpack(1,(2,3))": tests(660).expected = "(1,2,3)"
  tests(661).expr = "unpack((1,2))": tests(661).expected = "(1,2)"
  tests(662).expr = "deg((pi,pi/2))": tests(662).expected = "(180,90)"
  tests(663).expr = "rad((180,90))": tests(663).expected = "(3.141592653589793,1.570796326794896)"
  tests(664).expr = "rad((0,0))": tests(664).expected = "(0,0)"
  tests(665).expr = "clamp(9,0,7)": tests(665).expected = "7"
  tests(666).expr = "clamp((1,9),0,7)": tests(666).expected = "(1,7)"
  tests(667).expr = "fact(21)": tests(667).expected = "5.109094217170944e+019"
  tests(668).expr = "(2<3)+(2>=3)+(5==5)+(5<>4)": tests(668).expected = "3"
  tests(669).expr = "(7<>8)+(7!=8)": tests(669).expected = "2"
  tests(670).expr = "(9>8)+(9<=8)+(8>=8)": tests(670).expected = "2"
  tests(671).expr = "(3==3)+(3!=4)+(3<>3)": tests(671).expected = "2"
  tests(672).expr = "ubin(5)": tests(672).expected = "0b101"
  tests(673).expr = "log((8,64),2)": tests(673).expected = "(3,6)"
  tests(674).expr = "a=1; 2; ans": tests(674).expected = "2"
  tests(675).expr = "10+5": tests(675).expected = "15"
  tests(676).expr = "ans": tests(676).expected = "15"
  tests(677).expr = "stddev((-3,0,3,6))": tests(677).expected = "3.354101966249684"
  tests(678).expr = "stddev((1,2),3,4)": tests(678).expected = "1.118033988749894"
  tests(679).expr = "uhex(18446744073709551615)": tests(679).expected = "0xFFFFFFFFFFFFFFFF"
  tests(680).expr = "hex((1,2.5,3))": tests(680).expectedErrContains = "hex() expects integer values"
  tests(681).expr = "gcd(18446744073709551615,3)": tests(681).expected = "3"
  tests(682).expr = "lcm(18446744073709551615,3)": tests(682).expected = "18446744073709551615"
  tests(683).expr = "18446744073709551615%3": tests(683).expected = "0"
  tests(684).expr = "a=100.5; mod(a,3)": tests(684).expectedErrContains = "mod() expects integer values"
  tests(685).expr = "mod(18446744073709551615,3)": tests(685).expected = "0"
  tests(686).expr = "a=100.5; a&7": tests(686).expectedErrContains = "bitwise operands must be integer values"
  tests(687).expr = "mod(7,(2,3))": tests(687).expected = "(1,1)"
  tests(688).expr = "mod((7,8),3)": tests(688).expected = "(1,2)"
  tests(689).expr = "a=(1,2)<<64": tests(689).expectedErrContains = "incompatible operands"
  tests(690).expr = "x=0.0/0.0; hex(x)": tests(690).expected = "nan"
  tests(691).expr = "x=-1.0/0.0; oct(x)": tests(691).expected = "-inf"
  tests(692).expr = "x=0.0/0.0; mod(x,3)": tests(692).expectedErrContains = "mod() expects integer values"
  tests(693).expr = "x=0.0/0.0; gcd(x,1)": tests(693).expectedErrContains = "gcd() expects integer values"
  tests(694).expr = "x=0.0/0.0; x&1": tests(694).expectedErrContains = "bitwise operands must be integer values"
  tests(695).expr = "clamp(5,1,(4,7))": tests(695).expectedErrContains = "clamp() expects scalar min/max"
  tests(696).expr = "hypot((3,4),5)": tests(696).expected = "(5.830951894845301,6.403124237432849)"
  tests(697).expr = "fact((3,4))": tests(697).expectedErrContains = "fact() expects a non-negative integer"
  tests(698).expr = "mod(5)": tests(698).expectedErrContains = "mod() expects 2 argument(s)"
  tests(699).expr = "pow(5)": tests(699).expectedErrContains = "pow() expects 2 argument(s)"
  tests(700).expr = "log(5)": tests(700).expectedErrContains = "log() expects 2 argument(s)"
  tests(701).expr = "(1,2)+(3,4,5)": tests(701).expectedErrContains = "incompatible operands"
  tests(702).expr = "200 + (2*15)%": tests(702).expected = "260"
  tests(703).expr = "x=1.0/0.0; uhex(x)": tests(703).expected = "inf"
  tests(704).expr = "x=1.0/0.0; sqrt(x)": tests(704).expected = "inf"
  tests(705).expr = "a=(0.0/0.0,1.0/0.0,-1.0/0.0); a": tests(705).expected = "(nan,inf,-inf)"
  tests(706).expr = "x=0.0/0.0; sum(1,x)": tests(706).expected = "nan"

  tests(707).expr = "log(e,e)": tests(707).expected = "1"
  tests(708).expr = "unique((1,2),2,1,3)": tests(708).expected = "(1,2,3)"
  tests(709).expr = "variance((-3,0,3,6))": tests(709).expected = "11.25"
  tests(710).expr = "variance((1,2),3,4)": tests(710).expected = "1.25"
  tests(711).expr = "2**3": tests(711).expected = "8"
  tests(712).expr = "unpack()": tests(712).expectedErrContains = "unpack() expects at least 1 argument"
  tests(713).expr = "deg()": tests(713).expectedErrContains = "deg() expects at least 1 argument"
  tests(714).expr = "rad()": tests(714).expectedErrContains = "rad() expects at least 1 argument"
  tests(715).expr = "clamp(1,2)": tests(715).expectedErrContains = "clamp() expects 3 argument(s)"
  tests(716).expr = "clamp(1,2,3,4)": tests(716).expectedErrContains = "clamp() expects 3 argument(s)"
  tests(717).expr = "clamp((1,2),(3,4),4)": tests(717).expectedErrContains = "clamp() expects scalar min/max"
  tests(718).expr = "random((1,2),3)": tests(718).expectedErrContains = "random() expects scalar values"
  tests(719).expr = "random(1)": tests(719).expectedErrContains = "random() expects 2 argument(s)"
  tests(720).expr = "sum()": tests(720).expectedErrContains = "sum() expects at least 1 argument"
  tests(721).expr = "hex()": tests(721).expectedErrContains = "hex() expects at least 1 argument"
  tests(722).expr = "k=9007199254740992; v=(k+2)-2; hex(int(v))": tests(722).expected = "0x20000000000000"
  tests(723).expr = "k=18446744073709551615; v=k+1; uhex(v)": tests(723).expectedErrContains = "uhex() expects integer values"
  tests(724).expr = "a=(18446744073709551615,1); b=(1,2); c=a+b; uhex(c[0])": tests(724).expectedErrContains = "uhex() expects integer values"
  tests(725).expr = "a=(18446744073709551615,3); b=(3,4); c=a*b; uhex(c[0])": tests(725).expectedErrContains = "uhex() expects integer values"
  tests(726).expr = "a=floor((9007199254740993,2.9)); hex(a[0])": tests(726).expected = "0x20000000000001"
  tests(727).expr = "a=(9007199254740993,2); hex(sum(a[0]))": tests(727).expected = "0x20000000000001"
  tests(728).expr = "a=abs((18446744073709551615,-7)); uhex(a[0])": tests(728).expected = "0xFFFFFFFFFFFFFFFF"
  tests(729).expr = "a=sort((18446744073709551615,2)); uhex(a[1])": tests(729).expected = "0xFFFFFFFFFFFFFFFF"
  tests(730).expr = "a=reverse((18446744073709551615,2)); uhex(a[1])": tests(730).expected = "0xFFFFFFFFFFFFFFFF"
  tests(731).expr = "a=unique((18446744073709551615,18446744073709551615,2)); uhex(a[0])": tests(731).expected = "0xFFFFFFFFFFFFFFFF"
  tests(732).expr = "a=(1.0/0.0,2,3); sum(a)": tests(732).expected = "inf"
  tests(733).expr = "a=(1.0/0.0,2); mod(a,3)": tests(733).expectedErrContains = "mod() expects integer values"
  tests(734).expr = "x=1.0/0.0; hypot(x,3)": tests(734).expected = "inf"
  tests(735).expr = "x=1.0/0.0; clamp(x,0,7)": tests(735).expected = "7"
  tests(736).expr = "x=1.0/0.0; f(a)=a+1; f(x)": tests(736).expected = "inf"
  tests(737).expr = "x=1.0/0.0; f(a,b)=a*b; f(x,2)": tests(737).expected = "inf"
  tests(738).expr = "x=1.0/0.0; x*2": tests(738).expected = "inf"
  tests(739).expr = "x=1.0/0.0; x|1": tests(739).expectedErrContains = "bitwise operands must be integer values"
  tests(740).expr = "x=1.0/0.0; x&&0": tests(740).expected = "0"
  tests(741).expr = "x=1.0/0.0; x>1": tests(741).expected = "1"
  tests(742).expr = "x=1.0/0.0; sum(1,2,x)": tests(742).expected = "inf"
  tests(743).expr = "x=1.0/0.0; max(1,2,x)": tests(743).expected = "inf"
  tests(744).expr = "x=1.0/0.0; avg(1,x,3)": tests(744).expected = "inf"
  tests(745).expr = "x=1.0/0.0; x==(1.0/0.0)": tests(745).expected = "1"
  tests(746).expr = "a=(-1.0/0.0,2,3); sum(a)": tests(746).expected = "-inf"
  tests(747).expr = "a=(-1.0/0.0,2); mod(a,3)": tests(747).expectedErrContains = "mod() expects integer values"
  tests(748).expr = "x=-1.0/0.0; hypot(x,3)": tests(748).expected = "inf"
  tests(749).expr = "x=-1.0/0.0; clamp(x,0,7)": tests(749).expected = "0"
  tests(750).expr = "x=-1.0/0.0; f(a)=a+1; f(x)": tests(750).expected = "-inf"
  tests(751).expr = "x=-1.0/0.0; f(a,b)=a*b; f(x,2)": tests(751).expected = "-inf"
  tests(752).expr = "x=-1.0/0.0; x*2": tests(752).expected = "-inf"
  tests(753).expr = "x=-1.0/0.0; x|1": tests(753).expectedErrContains = "bitwise operands must be integer values"
  tests(754).expr = "x=-1.0/0.0; x&&0": tests(754).expected = "0"
  tests(755).expr = "x=-1.0/0.0; x>1": tests(755).expected = "0"
  tests(756).expr = "x=-1.0/0.0; sum(1,2,x)": tests(756).expected = "-inf"
  tests(757).expr = "x=-1.0/0.0; max(1,2,x)": tests(757).expected = "2"
  tests(758).expr = "x=-1.0/0.0; avg(1,x,3)": tests(758).expected = "-inf"
  tests(759).expr = "x=-1.0/0.0; y=-1.0/0.0; x==y": tests(759).expected = "1"
  tests(760).expr = "x=1.0/0.0; x**2": tests(760).expected = "inf"
  tests(761).expr = "x=1.0/0.0; 2**x": tests(761).expected = "inf"
  tests(762).expr = "x=1.0/0.0; x**x": tests(762).expected = "inf"
  tests(763).expr = "x=1.0/0.0; pow(x,2)": tests(763).expected = "inf"
  tests(764).expr = "x=1.0/0.0; pow(2,x)": tests(764).expected = "inf"
  tests(765).expr = "x=1.0/0.0; pow(x,x)": tests(765).expected = "inf"
  tests(766).expr = "x=1.0/0.0; atan2(x,1)": tests(766).expected = "1.570796326794897"
  tests(767).expr = "x=-1.0/0.0; atan2(x,1)": tests(767).expected = "-1.570796326794897"
  tests(768).expr = "x=-1.0/0.0; atan2(1,x)": tests(768).expected = "3.141592653589793"
  tests(769).expr = "x=-1.0/0.0; sin(x)": tests(769).expected = "nan"
  tests(770).expr = "inf+1": tests(770).expected = "inf"
  tests(771).expr = "INF+1": tests(771).expected = "inf"
  tests(772).expr = "inf=1": tests(772).expectedErrContains = "reserved constant name"
  tests(773).expr = "Inf=1": tests(773).expectedErrContains = "reserved constant name"
  tests(774).expr = "f(inf)=inf+1": tests(774).expectedErrContains = "reserved constant name"
  tests(775).expr = "inf(x)=x": tests(775).expectedErrContains = "reserved constant name"
  tests(776).expr = "-inf": tests(776).expected = "-inf"
  tests(777).expr = "-Inf+1": tests(777).expected = "-inf"
  tests(778).expr = "sum(-inf,2,3)": tests(778).expected = "-inf"
  tests(779).expr = "max(-inf,2,3)": tests(779).expected = "3"
  tests(780).expr = "(-inf)&1": tests(780).expectedErrContains = "bitwise operands must be integer values"
  tests(781).expr = "(-inf)==(-inf)": tests(781).expected = "1"
  tests(782).expr = "-inf + inf": tests(782).expected = "nan"
  tests(783).expr = "inf/-inf": tests(783).expected = "nan"
  tests(784).expr = "pow(inf,-inf)": tests(784).expected = "0"
  tests(785).expr = "pow(-inf,3)": tests(785).expected = "-inf"
  tests(786).expr = "pow(-inf,2)": tests(786).expected = "inf"
  tests(787).expr = "inf-inf": tests(787).expected = "nan"
  tests(788).expr = "(-inf)/(-inf)": tests(788).expected = "nan"
  tests(789).expr = "inf*0": tests(789).expected = "nan"
  tests(790).expr = "0*inf": tests(790).expected = "nan"
  tests(791).expr = "pow(inf,-2)": tests(791).expected = "0"
  tests(792).expr = "ncr(5,2)": tests(792).expected = "10"
  tests(793).expr = "npr(5,2)": tests(793).expected = "20"
  tests(794).expr = "ncr(10,0)": tests(794).expected = "1"
  tests(795).expr = "npr(10,0)": tests(795).expected = "1"
  tests(796).expr = "ncr(5,7)": tests(796).expectedErrContains = "numeric error in ncr()"
  tests(797).expr = "npr(5,7)": tests(797).expectedErrContains = "numeric error in npr()"
  tests(798).expr = "ncr(-1,0)": tests(798).expectedErrContains = "numeric error in ncr()"
  tests(799).expr = "npr(5,-1)": tests(799).expectedErrContains = "numeric error in npr()"
  tests(800).expr = "ncr(5.5,2)": tests(800).expectedErrContains = "ncr() expects integer values"
  tests(801).expr = "npr(inf,2)": tests(801).expectedErrContains = "npr() expects integer values"
  tests(802).expr = "ncr": tests(802).expectedErrContains = "function: ncr(n, r)"
  tests(803).expr = "npr": tests(803).expectedErrContains = "function: npr(n, r)"

  tests(804).expr = "nan+1": tests(804).expected = "nan"
  tests(805).expr = "NAN+1": tests(805).expected = "nan"
  tests(806).expr = "nan=1": tests(806).expectedErrContains = "reserved constant name"
  tests(807).expr = "NaN=1": tests(807).expectedErrContains = "reserved constant name"
  tests(808).expr = "f(nan)=nan+1": tests(808).expectedErrContains = "reserved constant name"
  tests(809).expr = "nan(x)=x": tests(809).expectedErrContains = "reserved constant name"
  tests(810).expr = "(nan, inf)": tests(810).expected = "(nan, inf)"

  tests(811).expr = "acosh(1)": tests(811).expected = "0"
  tests(812).expr = "acosh(2)": tests(812).expected = "1.3169578969248166"
  tests(813).expr = "acosh(0)": tests(813).expected = "nan"
  tests(814).expr = "acosh(inf)": tests(814).expected = "inf"
  tests(815).expr = "asinh(0)": tests(815).expected = "0"
  tests(816).expr = "asinh(1)": tests(816).expected = "0.8813735870195431"
  tests(817).expr = "asinh(-1)": tests(817).expected = "-0.8813735870195431"
  tests(818).expr = "asinh((0,1))": tests(818).expected = "(0,0.8813735870195431)"
  tests(819).expr = "atanh(0)": tests(819).expected = "0"
  tests(820).expr = "atanh(0.5)": tests(820).expected = "0.5493061443340549"
  tests(821).expr = "atanh(1)": tests(821).expected = "inf"
  tests(822).expr = "atanh(-1)": tests(822).expected = "-inf"
  tests(823).expr = "atanh(2)": tests(823).expected = "nan"
  tests(824).expr = "acosh()": tests(824).expectedErrContains = "expects 1 argument(s)"
  tests(825).expr = "asinh()": tests(825).expectedErrContains = "expects 1 argument(s)"
  tests(826).expr = "atanh()": tests(826).expectedErrContains = "expects 1 argument(s)"

  tests(827).expr = "sin(pi/2)": tests(827).expected = "1"
  tests(828).expr = "sin(-pi/2)": tests(828).expected = "-1"
  tests(829).expr = "sin(77777*pi/2)": tests(829).expected = "1"
  tests(830).expr = "sin(-77777*pi/2)": tests(830).expected = "-1"
  tests(831).expr = "sin(0)": tests(831).expected = "0"
  tests(832).expr = "sin(pi)": tests(832).expected = "0"
  tests(833).expr = "sin(-pi)": tests(833).expected = "0"
  tests(834).expr = "sin(2*pi)": tests(834).expected = "0"
  tests(835).expr = "sin(-2*pi)": tests(835).expected = "0"
  tests(836).expr = "sin(77777*pi)": tests(836).expected = "0"
  tests(837).expr = "sin(-77777*pi)": tests(837).expected = "0"
  tests(838).expr = "sin(77778*pi)": tests(838).expected = "0"
  tests(839).expr = "sin(-77778*pi)": tests(839).expected = "0"
  tests(840).expr = "cos(pi/2)": tests(840).expected = "0"
  tests(841).expr = "cos(-pi/2)": tests(841).expected = "0"
  tests(842).expr = "cos(77777*pi/2)": tests(842).expected = "0"
  tests(843).expr = "cos(-77777*pi/2)": tests(843).expected = "0"
  tests(844).expr = "cos(0)": tests(844).expected = "1"
  tests(845).expr = "cos(pi)": tests(845).expected = "-1"
  tests(846).expr = "cos(-pi)": tests(846).expected = "-1"
  tests(847).expr = "cos(2*pi)": tests(847).expected = "1"
  tests(848).expr = "cos(-2*pi)": tests(848).expected = "1"
  tests(849).expr = "cos(77777*pi)": tests(849).expected = "-1"
  tests(850).expr = "cos(-77777*pi)": tests(850).expected = "-1"
  tests(851).expr = "cos(77778*pi)": tests(851).expected = "1"
  tests(852).expr = "cos(-77778*pi)": tests(852).expected = "1"
  tests(853).expr = "tan(pi/2)": tests(853).expected = "inf"
  tests(854).expr = "tan(-pi/2)": tests(854).expected = "-inf"
  tests(855).expr = "tan(77777*pi/2)": tests(855).expected = "inf"
  tests(856).expr = "tan(-77777*pi/2)": tests(856).expected = "-inf"
  tests(857).expr = "tan(0)": tests(857).expected = "0"
  tests(858).expr = "tan(pi)": tests(858).expected = "0"
  tests(859).expr = "tan(-pi)": tests(859).expected = "0"
  tests(860).expr = "tan(2*pi)": tests(860).expected = "0"
  tests(861).expr = "tan(-2*pi)": tests(861).expected = "0"
  tests(862).expr = "tan(77777*pi)": tests(862).expected = "0"
  tests(863).expr = "tan(-77777*pi)": tests(863).expected = "0"
  tests(864).expr = "tan(77778*pi)": tests(864).expected = "0"
  tests(865).expr = "tan(-77778*pi)": tests(865).expected = "0"

  tests(866).expr = "bad1(x)=x)": tests(866).expectedErrContains = "unexpected characters" ' [regression] UDF body must be one expression; no extra )
  tests(867).expr = "bad2(x)=x$$5": tests(867).expectedErrContains = "unexpected characters" ' [regression] garbage after a valid expression prefix in UDF body

  tests(868).expr = "!nan": tests(868).expected = "1" ' [spec] NaN is falsy in logical ops (IEEE: NaN <> 0 is true, so do not use <>0 alone for truthiness)
  tests(869).expr = "nan && 1": tests(869).expected = "0" ' [spec] NaN is falsy
  tests(870).expr = "nan || 0": tests(870).expected = "0" ' [spec] NaN is falsy
  tests(871).expr = "nan==nan": tests(871).expected = "0" ' [spec] IEEE: NaN never equals NaN
  tests(872).expr = "nan!=nan": tests(872).expected = "1" ' [spec] inequality is true for unordered
  tests(873).expr = "nan<>nan": tests(873).expected = "1"
  tests(874).expr = "nan<nan": tests(874).expected = "0"
  tests(875).expr = "nan>nan": tests(875).expected = "0"
  tests(876).expr = "nan<=nan": tests(876).expected = "0"
  tests(877).expr = "nan>=nan": tests(877).expected = "0"

  tests(878).expr = "x=-nan; int(x)": tests(878).expected = "nan"
  tests(879).expr = "x=nan; int(x)": tests(879).expected = "nan"
  tests(880).expr = "x=-inf; int(x)": tests(880).expected = "-inf"
  tests(881).expr = "x=inf; int(x)": tests(881).expected = "inf"
  tests(882).expr = "x=-nan; ceil(x)": tests(882).expected = "nan"
  tests(883).expr = "x=nan; floor(x)": tests(883).expected = "nan"
  tests(884).expr = "x=-inf; round(x)": tests(884).expected = "-inf"
  tests(885).expr = "x=inf; trunc(x)": tests(885).expected = "inf"
  tests(886).expr = "ceil((1e14+0.5, 1e30, -1e30))": tests(886).expected = "(100000000000001, 1e+30, -1e+30)"

  tests(887).expr = "(45,60,90); rad": tests(887).expected = "(0.7853981633974483, 1.047197551196598, 1.570796326794897)"
  tests(888).expr = "(pi/4,pi/3,pi/2); deg": tests(888).expected = "(45, 60, 90)"

  tests(889).expr = "(2**58, 2**58+123)": tests(889).expected = "(288230376151711744, 288230376151711867)"
  tests(890).expr = "(2**58, 2**58+123);hex": tests(890).expected = "(0x400000000000000, 0x40000000000007B)"
  tests(891).expr = "(2**61, 2**61+123)": tests(891).expected = "(2305843009213693952, 2305843009213694075)"
  tests(892).expr = "(2**61, 2**61+123);hex": tests(892).expected = "(0x2000000000000000, 0x200000000000007B)"
  tests(893).expr = "2**58+123": tests(893).expected = "288230376151711867"
  tests(894).expr = "2**61+123": tests(894).expected = "2305843009213694075"
  tests(895).expr = "2**58+123;hex": tests(895).expected = "0x40000000000007B"
  tests(896).expr = "2**61+123;hex": tests(896).expected = "0x200000000000007B"
  tests(897).expr = "9.0*10**18": tests(897).expected = "9000000000000000000"
  tests(898).expr = "9.2e17": tests(898).expected = "920000000000000000"
  tests(899).expr = "9e18": tests(899).expected = "9000000000000000000"
  tests(900).expr = "90.123e15": tests(900).expected = "90123000000000000"
  tests(901).expr = "1.23456789e18": tests(901).expected = "1234567890000000000"
  tests(902).expr = "(9.0*10**18,9.2e17,9e18,90.123e15,1.23456789e18)": tests(902).expected = "(9000000000000000000, 920000000000000000, 9000000000000000000, 90123000000000000, 1234567890000000000)"
  tests(903).expr = "(9.2233e18,9.2234e18,0.123,0.123e3,0.12345e4,0.123e5,0.012345678901234e18,1.234567890123456e18,222.0,0)": tests(903).expected = "(9223300000000000000, 9.2234e+18, 0.123, 123, 1234.5, 12300, 12345678901234000, 1234567890123456000, 222, 0)"
  tests(904).expr = "0x10000000000000000": tests(904).expectedErrContains = "invalid hex literal"
  tests(905).expr = "0b10000000000000000000000000000000000000000000000000000000000000000": tests(905).expectedErrContains = "invalid binary literal"
  tests(906).expr = "0o2000000000000000000000": tests(906).expectedErrContains = "invalid octal literal"
  tests(907).expr = "1e": tests(907).expectedErrContains = "unexpected token"
  tests(908).expr = "1e+": tests(908).expectedErrContains = "unexpected token"
  tests(909).expr = "1e-": tests(909).expectedErrContains = "unexpected token"
  tests(910).expr = ".": tests(910).expectedErrContains = "unexpected token"
  tests(911).expr = ".0": tests(911).expected = "0"
  tests(912).expr = "0.": tests(912).expected = "0"
  tests(913).expr = "0.0": tests(913).expected = "0"
  tests(914).expr = "0xFFFFFFFFFFFFFFFF+2": tests(914).expected = "1.844674407370955e+019"
  tests(915).expr = "0xFFFFFFFFFFFFFFFF-2": tests(915).expected = "18446744073709551613"
  tests(916).expr = "0xFFFFFFFFFFFFFFFF*2": tests(916).expected = "3.689348814741911e+019"
  tests(917).expr = "0xFFFFFFFFFFFFFFFF/2": tests(917).expected = "9.223372036854776e+018"
  tests(918).expr = "0xFFFFFFFFFFFFFFFF%2": tests(918).expected = "1"
  tests(919).expr = "0xFFFFFFFFFFFFFFFF>>1": tests(919).expected = "9223372036854775807"
  tests(920).expr = "0xFFFFFFFFFFFFFFFF<<1": tests(920).expected = "3.689348814741911e+019"
  tests(921).expr = "0xFFFFFFFFFFFFFFFF**2": tests(921).expected = "3.402823669209385e+038"
  tests(922).expr = "0x7FFFFFFFFFFFFFFF**2": tests(922).expected = "8.507059173023462e+037"
  tests(923).expr = "-0xFFFFFFFFFFFFFFFF+2": tests(923).expected = "-1.844674407370955e+019"
  tests(924).expr = "-0xFFFFFFFFFFFFFFFF-2": tests(924).expected = "-1.844674407370955e+019"
  tests(925).expr = "(-0xFFFFFFFFFFFFFFFF)%2": tests(925).expectedErrContains = "modulo operands must be integer values"
  tests(926).expr = "(-0xFFFFFFFFFFFFFFFF)>>1": tests(926).expectedErrContains = "bitwise operands must be integer values"
  tests(927).expr = "-0x7FFFFFFFFFFFFFFF+2": tests(927).expected = "-9223372036854775805"
  tests(928).expr = "0x7FFFFFFFFFFFFFFF+2": tests(928).expected = "9223372036854775809"
  tests(929).expr = "0x7FFFFFFFFFFFFFFF-2": tests(929).expected = "9223372036854775805"
  tests(930).expr = "0x7FFFFFFFFFFFFFFF<<1": tests(930).expected = "18446744073709551614"
  tests(931).expr = "a=(-0xFFFFFFFFFFFFFFFF,-0x7FFFFFFFFFFFFFFF,0x7FFFFFFFFFFFFFFF); mod(a,2)": tests(931).expectedErrContains = "mod() expects integer values"
  tests(932).expr = "a=(-0x7FFFFFFFFFFFFFFF,0x7FFFFFFFFFFFFFFF); a>>1": tests(932).expected = "(-4611686018427387904, 4611686018427387903)"
  tests(933).expr = "a=(0x7FFFFFFFFFFFFFFF,0x7FFFFFFFFFFFFFFF); b=(2,2); a+b": tests(933).expected = "(9223372036854775809, 9223372036854775809)"
  tests(934).expr = "-0x7FFFFFFFFFFFFFFF-2": tests(934).expected = "-9.223372036854776e+018"
  tests(935).expr = "0x7FFFFFFFFFFFFFFF*2": tests(935).expected = "18446744073709551614"
  tests(936).expr = "a=(-0xFFFFFFFFFFFFFFFF,-0x7FFFFFFFFFFFFFFF,0x7FFFFFFFFFFFFFFF); b=(2,2,2); a+b": tests(936).expected = "(-1.844674407370955e+019, -9223372036854775805, 9223372036854775809)"
  tests(937).expr = "a=(-0xFFFFFFFFFFFFFFFF,-0x7FFFFFFFFFFFFFFF,0x7FFFFFFFFFFFFFFF); b=(2,2,2); a*b": tests(937).expected = "(-3.689348814741911e+019, -1.844674407370955e+019, 18446744073709551614)"
  tests(938).expr = "a=(-0xFFFFFFFFFFFFFFFF,-0x7FFFFFFFFFFFFFFF,0x7FFFFFFFFFFFFFFF); a>>1": tests(938).expectedErrContains = "bitwise operands must be integer values"
  tests(939).expr = "0x7FFFFFFFFFFFFFFF<<2": tests(939).expected = "3.68934881474191e+019"
  tests(940).expr = "0x7FFFFFFFFFFFFFFF>>1": tests(940).expected = "4611686018427387903"
  tests(941).expr = "a=(0xFFFFFFFFFFFFFFFF,0x7FFFFFFFFFFFFFFF,0x7FFFFFFFFFFFFFF); a>>1": tests(941).expected = "(9223372036854775807, 4611686018427387903, 288230376151711743)"
  tests(942).expr = "a=(0xFFFFFFFFFFFFFFFF,0x7FFFFFFFFFFFFFFF,0x7FFFFFFFFFFFFFF); a<<1": tests(942).expected = "(3.68934881474191e+19, 18446744073709551614, 1152921504606846974)"
  tests(943).expr = "3.68934881474191e+19>>1": tests(943).expectedErrContains = "bitwise operands must be integer values"
  tests(944).expr = "3.68934881474191e+19/2": tests(944).expected = "1.844674407370955e+019"
  tests(945).expr = "3.68934881474191e+19**0.5": tests(945).expected = "6074000999.952098"
  tests(946).expr = "3.68934881474191e+19%3": tests(946).expectedErrContains = "modulo operands must be integer values"
  tests(947).expr = "sum(18446744073709551614,1)": tests(947).expected = "18446744073709551615"
  tests(948).expr = "max(3,18446744073709551615)": tests(948).expected = "18446744073709551615"
  tests(949).expr = "min(18446744073709551615,5)": tests(949).expected = "5"
  tests(950).expr = "sum(-9223372036854775807,-1)": tests(950).expected = "-9223372036854775808"
  tests(951).expr = "max(-9,-1)": tests(951).expected = "-1"

  dim uniqueTotal as Integer
  dim duplicateTotal as Integer
  dim sigI as String
  dim isDup as Boolean
  uniqueTotal = 0
  duplicateTotal = 0
  for i as Integer = lbound(tests) to ubound(tests)
    sigI = SmokeCaseSignature(tests(i))
    isDup = FALSE
    for j as Integer = lbound(tests) to i - 1
      if SmokeCaseSignature(tests(j)) = sigI then
        isDup = TRUE
      end if
    next j
    if isDup = FALSE then
      uniqueTotal += 1
    else
      duplicateTotal += 1
    end if
  next i
  g_total = uniqueTotal

  print "=== SmartMath parser smoke tests ==="
  print "Total cases: " & g_total
  print "Detected duplicate cases: " & duplicateTotal
  print ""

  Parser_ClearVariables()
  for i as Integer = lbound(tests) to ubound(tests)
    sigI = SmokeCaseSignature(tests(i))
    isDup = FALSE
    for j as Integer = lbound(tests) to i - 1
      if SmokeCaseSignature(tests(j)) = sigI then
        isDup = TRUE
      end if
    next j
    if isDup = FALSE then
      RunCase(tests(i))
    else
      print "[DUPLICATE] SKIP : " & tests(i).expr
    end if
  next i

  print "=== Result ==="
  print "Passed: " & g_passed
  print "Failed: " & g_failed

  if g_failed > 0 then
    end 1
  else
    end 0
  end if
end sub

Main()
