#include once "Inc\MathParser.bi"

type SmokeCase
  expr as String
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

sub RunCase(byref c as SmokeCase)
  g_idx += 1
  print "[" & g_idx & "/" & g_total & "] RUN  : " & c.expr

  dim result as Double
  dim resultText as String
  dim isArray as Boolean
  dim ok as Boolean = Parser_TryEvaluateEx(c.expr, result, resultText, isArray)

  dim actual as String
  dim errText as String
  if ok then
    actual = resultText
  else
    errText = Parser_GetLastError()
    actual = "ERR: " & errText
  end if

  dim passCase as Boolean = FALSE
  if c.expectNoResult then
    if (ok = FALSE) andalso (len(errText) = 0) then
      passCase = TRUE
    end if
  elseif len(c.expectedErrContains) > 0 then
    if (ok = FALSE) andalso (instr(lcase(errText), lcase(c.expectedErrContains)) > 0) then
      passCase = TRUE
    end if
  else
    if ResultCloseEnough(actual, c.expected) then passCase = TRUE
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
  dim tests(1 to 600) as SmokeCase
  ' Inline tag legend:
  ' [spec] = intended language behavior (primary contract)
  ' [regression-lock] = current behavior intentionally locked for compatibility
  ' Default rule: unless explicitly marked [regression-lock], each test is [spec].
  ' [ok-core] [ok-func] [ok-array] [hint] [arity]
  ' [type-int-only] [shape] [shape/broadcast] [syntax] [edge] [overflow]

  ' === SPEC / intended behavior ===
  '
  ' === A) Operator precedence, core operators, and integer-only operator checks ===
  tests(1).expr = "2**3":               tests(1).expected = "8" ' [spec][ok-core]
  tests(2).expr = "16**-0.5":           tests(2).expected = "0.25" ' [spec][ok-core]
  tests(3).expr = "+5":                 tests(3).expected = "5" ' [spec][ok-core]
  tests(4).expr = "-5":                 tests(4).expected = "-5" ' [spec][ok-core]
  tests(5).expr = "~5":                 tests(5).expected = "-6" ' [spec][ok-core]
  tests(6).expr = "5%3":                tests(6).expected = "2" ' [spec][ok-core]
  tests(7).expr = "200 + 15%":          tests(7).expected = "230" ' [spec][ok-core]
  tests(8).expr = "200 - 15%":          tests(8).expected = "170" ' [spec][ok-core]
  tests(9).expr = "8>>1":               tests(9).expected = "4" ' [spec][ok-core]
  tests(10).expr = "3<<2":              tests(10).expected = "12" ' [spec][ok-core]
  tests(11).expr = "6&3":               tests(11).expected = "2" ' [spec][ok-core]
  tests(12).expr = "6^3":               tests(12).expected = "5" ' [spec][ok-core]
  tests(13).expr = "6|3":               tests(13).expected = "7" ' [spec][ok-core]
  tests(14).expr = "2(3+4)":            tests(14).expected = "14" ' [spec][ok-core]
  tests(15).expr = "2(3+4)**2":         tests(15).expected = "98" ' [spec][ok-core]
  tests(16).expr = "2+3<<1":            tests(16).expected = "10" ' [spec][ok-core]
  tests(17).expr = "1|2^3&6<<1":        tests(17).expected = "3" ' [spec][ok-core]
  tests(18).expr = "2(1+2)%4":          tests(18).expected = "2" ' [spec][ok-core]
  tests(19).expr = "5.5&1":             tests(19).expectedErrContains = "bitwise operands must be integer values" ' [spec][type-int-only]
  tests(20).expr = "5|1.1":             tests(20).expectedErrContains = "bitwise operands must be integer values" ' [spec][type-int-only]
  tests(21).expr = "3.2^1":             tests(21).expectedErrContains = "bitwise operands must be integer values" ' [spec][type-int-only]
  tests(22).expr = "8.1>>1":            tests(22).expectedErrContains = "bitwise operands must be integer values" ' [spec][type-int-only]
  tests(23).expr = "8<<1.2":            tests(23).expectedErrContains = "bitwise operands must be integer values" ' [spec][type-int-only]
  tests(24).expr = "~2.5":              tests(24).expectedErrContains = "bitwise operands must be integer values" ' [spec][type-int-only]
  tests(25).expr = "5.5%2":             tests(25).expectedErrContains = "modulo operands must be integer values" ' [spec][type-int-only]
  tests(26).expr = "5%2.2":             tests(26).expectedErrContains = "modulo operands must be integer values" ' [spec][type-int-only]
  tests(27).expr = "2(1+2.5)%4.2":      tests(27).expectedErrContains = "modulo operands must be integer values" ' [spec][type-int-only]

  ' === B) [spec] Function hints, comments, parser diagnostics, and literal parsing ===
  tests(28).expr = "pow(2,3)":          tests(28).expected = "8" ' [ok-func]
  tests(29).expr = "prod(2,3,4)":       tests(29).expected = "24" ' [ok-func]
  tests(30).expr = "pow":               tests(30).expectedErrContains = "function: pow(" ' [hint]
  tests(31).expr = "sin":               tests(31).expectedErrContains = "function: sin(angle)" ' [hint]
  tests(32).expr = "sum":               tests(32).expectedErrContains = "function: sum(...)" ' [hint]
  tests(33).expr = "sqr(5)":            tests(33).expected = "25" ' [ok-func]
  tests(34).expr = "sqr":               tests(34).expectedErrContains = "function: sqr(value)" ' [hint]
  tests(35).expr = "1 + 2 # calculates 1 + 2": tests(35).expected = "3" ' [syntax]
  tests(36).expr = "// this entire line is a comment": tests(36).expectNoResult = TRUE ' [syntax]
  tests(37).expr = "sin(pi/2) // calculates sin(pi/2)": tests(37).expected = "1" ' [syntax]
  tests(38).expr = "[]":                tests(38).expectedErrContains = "unexpected token" ' [syntax]
  tests(39).expr = "b=2; 2b":           tests(39).expectedErrContains = "unexpected token" ' [syntax]
  tests(40).expr = "(2;2b;3)":          tests(40).expectedErrContains = "missing closing parenthesis" ' [syntax]
  tests(41).expr = "(2,2b,3)":          tests(41).expectedErrContains = "unexpected token" ' [syntax]
  tests(42).expr = "hex(12)":           tests(42).expected = "0xC" ' [ok-func]
  tests(43).expr = "hex((12,255))":     tests(43).expected = "(0xC,0xFF)" ' [ok-array]
  tests(44).expr = "10 + hex(12) + 14": tests(44).expected = "36" ' [ok-func]
  tests(45).expr = "hex(12.5)":         tests(45).expectedErrContains = "hex() expects integer values" ' [type-int-only]
  tests(46).expr = "hex":               tests(46).expectedErrContains = "function: hex(...)" ' [hint]
  tests(47).expr = "0x":                tests(47).expectedErrContains = "invalid hex literal" ' [syntax]
  tests(48).expr = "0xG":               tests(48).expectedErrContains = "invalid hex literal" ' [syntax]
  tests(49).expr = "hex(0x7FFFFFFFFFFFFFFF)": tests(49).expected = "0x7FFFFFFFFFFFFFFF" ' [ok-func]
  tests(50).expr = "hex(0xFFFFFFFFFFFFFFFF)": tests(50).expected = "0xFFFFFFFFFFFFFFFF" ' [ok-func]
  tests(51).expr = "0b01110110011":     tests(51).expected = "947" ' [ok-core]
  tests(52).expr = "bin(13)":           tests(52).expected = "0b1101" ' [ok-func]
  tests(53).expr = "bin((1,2,5))":      tests(53).expected = "(0b1,0b10,0b101)" ' [ok-array]
  tests(54).expr = "10 + bin(12) + 14": tests(54).expected = "36" ' [ok-func]
  tests(55).expr = "0b":                tests(55).expectedErrContains = "invalid binary literal" ' [syntax]
  tests(56).expr = "bin(12.5)":         tests(56).expectedErrContains = "bin() expects integer values" ' [type-int-only]
  tests(57).expr = "bin":               tests(57).expectedErrContains = "function: bin(...)" ' [hint]

  ' === C) [spec] Integer-accuracy / overflow-path regression cases ===
  tests(58).expr = "9007199254740991+1": tests(58).expected = "9007199254740992" ' [overflow]
  tests(59).expr = "9007199254740992+1": tests(59).expected = "9007199254740993" ' [overflow]
  tests(60).expr = "3037000499*3037000499": tests(60).expected = "9223372030926249001" ' [overflow]
  tests(61).expr = "5/2":               tests(61).expected = "2.5" ' [edge]
  tests(62).expr = "2**10+1":           tests(62).expected = "1025" ' [ok-core]
  tests(63).expr = "2**-1":             tests(63).expected = "0.5" ' [edge]
  tests(64).expr = "9007199254740993&1": tests(64).expected = "1" ' [overflow]
  tests(65).expr = "9223372036854775807+1": tests(65).expected = "9.223372036854778e+018" ' [overflow]
  tests(66).expr = "-9223372036854775808-1": tests(66).expected = "-9.223372036854778e+018" ' [overflow]
  tests(67).expr = "3037000500*3037000500": tests(67).expected = "9.223372037000249e+018" ' [overflow]
  tests(68).expr = "2**63":             tests(68).expected = "9.223372036854776e+018" ' [overflow]
  tests(69).expr = "2**64":             tests(69).expected = "1.844674407370955e+019" ' [overflow]
  tests(70).expr = "9223372036854775807+0.5": tests(70).expected = "9.223372036854778e+018" ' [overflow]
  tests(71).expr = "hex(9223372036854775807+1)": tests(71).expectedErrContains = "hex() expects integer values" ' [overflow]

  ' === D) [spec] Built-ins and ans variable baseline behavior ===
  tests(72).expr = "log(8,2)":          tests(72).expected = "3" ' [ok-func]
  tests(73).expr = "log(100,10)":       tests(73).expected = "2" ' [ok-func]
  tests(74).expr = "log(8)":            tests(74).expectedErrContains = "log() expects 2 argument(s)" ' [arity]
  tests(75).expr = "ln":                tests(75).expectedErrContains = "function: ln(value)" ' [hint]
  tests(76).expr = "log(e,e)":          tests(76).expected = "1" ' [ok-func]
  tests(77).expr = "a=2;sum(a,a)":      tests(77).expected = "4" ' [ok-func]
  tests(78).expr = "f(a,a)=a":          tests(78).expectedErrContains = "duplicate parameter name" ' [syntax]
  tests(79).expr = "2+3;ans":           tests(79).expected = "5" ' [ok-func]
  tests(80).expr = "(1,2,3);ans":       tests(80).expected = "(1,2,3)" ' [ok-array]
  tests(81).expr = "hex(15);ans":       tests(81).expected = "0xF" ' [ok-func]
  tests(82).expr = "7; ans*2":          tests(82).expected = "14" ' [ok-func]
  tests(83).expr = "v=(10,20);sum(ans)": tests(83).expected = "30" ' [ok-array]
  tests(84).expr = "atan2(1,1)":        tests(84).expected = "0.7853981633974483" ' [ok-func]
  tests(85).expr = "floor(2.9)":        tests(85).expected = "2" ' [ok-func]
  tests(86).expr = "ceil(2.1)":         tests(86).expected = "3" ' [ok-func]
  tests(87).expr = "trunc(-2.9)":       tests(87).expected = "-2" ' [ok-func]
  tests(88).expr = "round(2.5)":        tests(88).expected = "3" ' [ok-func]
  tests(89).expr = "sign(-123)":        tests(89).expected = "-1" ' [ok-func]
  tests(90).expr = "mod(17,5)":         tests(90).expected = "2" ' [ok-func]
  tests(91).expr = "avg(1,2,3,4)":      tests(91).expected = "2.5" ' [ok-func]
  tests(92).expr = "mean((1,2,3),9)":   tests(92).expected = "3.75" ' [ok-array]
  tests(93).expr = "clamp(15,0,10)":    tests(93).expected = "10" ' [ok-func]
  tests(94).expr = "deg(pi)":           tests(94).expected = "180" ' [ok-func]
  tests(95).expr = "rad(180)":          tests(95).expected = "3.141592653589793" ' [ok-func]
  tests(96).expr = "hypot(3,4)":        tests(96).expected = "5" ' [ok-func]
  tests(97).expr = "gcd(84,30)":        tests(97).expected = "6" ' [ok-func]
  tests(98).expr = "lcm(6,8)":          tests(98).expected = "24" ' [ok-func]
  tests(99).expr = "median(1,8,3)":     tests(99).expected = "3" ' [ok-func]
  tests(100).expr = "median((1,9),3,7)": tests(100).expected = "5" ' [ok-array]
  tests(101).expr = "variance(1,2,3)":  tests(101).expected = "0.6666666666666666" ' [ok-func]
  tests(102).expr = "stddev(1,2,3)":    tests(102).expected = "0.816496580927726" ' [ok-func]
  tests(103).expr = "fact(0)":          tests(103).expected = "1" ' [ok-func]
  tests(104).expr = "fact(5)":          tests(104).expected = "120" ' [ok-func]
  tests(105).expr = "factorial(10)":    tests(105).expected = "3628800" ' [ok-func]
  tests(106).expr = "fact(-1)":         tests(106).expectedErrContains = "fact() expects a non-negative integer" ' [edge]
  tests(107).expr = "fact(2.5)":        tests(107).expectedErrContains = "fact() expects a non-negative integer" ' [type-int-only]
  tests(108).expr = "factorial(21)":    tests(108).expected = "5.109094217170944e+019" ' [float-over-20]
  tests(109).expr = "random(5,5)":      tests(109).expected = "5" ' [edge]
  tests(110).expr = "rand(1)":          tests(110).expectedErrContains = "rand() expects 0 argument(s)" ' [arity]
  tests(111).expr = "rand":             tests(111).expectedErrContains = "function: rand()" ' [hint]
  tests(112).expr = "random":           tests(112).expectedErrContains = "function: random(min, max)" ' [hint]
  tests(113).expr = "median":           tests(113).expectedErrContains = "function: median(...)" ' [hint]

  ' === E) [spec] sort/unique baseline behavior ===
  tests(114).expr = "sort((3,1,2))":    tests(114).expected = "(1,2,3)" ' [ok-array]
  tests(115).expr = "a=(5,2,9);sort(a)": tests(115).expected = "(2,5,9)" ' [ok-array]
  tests(116).expr = "sort(5)":          tests(116).expected = "(5)" ' [ok-func]
  tests(117).expr = "sort(2,5,1)":      tests(117).expected = "(1,2,5)" ' [ok-func]
  tests(118).expr = "sort":             tests(118).expectedErrContains = "function: sort(...)" ' [hint]
  tests(119).expr = "unique((3,1,3,2,1,2))": tests(119).expected = "(3,1,2)" ' [ok-array]
  tests(120).expr = "a=(5,2,5,9,2);unique(a)": tests(120).expected = "(5,2,9)" ' [ok-array]
  tests(121).expr = "unique(5)":        tests(121).expected = "(5)" ' [ok-func]
  tests(122).expr = "unique(1,2,1,2,3)": tests(122).expected = "(1,2,3)" ' [ok-func]
  tests(123).expr = "unique":           tests(123).expectedErrContains = "function: unique(...)" ' [hint]

  ' === F) [spec] Stress matrix: argument shape, arity, syntax, and edge-case validation ===
  tests(124).expr = "(1,2)+(3)":        tests(124).expected = "(4,5)" ' [shape/broadcast]
  tests(125).expr = "(1,2)*(3,4,5)":    tests(125).expectedErrContains = "incompatible operands" ' [shape]
  tests(126).expr = "1<<64":            tests(126).expectedErrContains = "incompatible operands" ' [edge]
  tests(127).expr = "1>>-1":            tests(127).expectedErrContains = "incompatible operands" ' [edge]
  tests(128).expr = "5%0":              tests(128).expectedErrContains = "incompatible operands" ' [edge]
  tests(129).expr = "1+":               tests(129).expectedErrContains = "unexpected token" ' [syntax]
  tests(130).expr = "pow()":            tests(130).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(131).expr = "pow(2,3,4)":       tests(131).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(132).expr = "log()":            tests(132).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(133).expr = "log(10,10,10)":    tests(133).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(134).expr = "atan2()":          tests(134).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(135).expr = "atan2(1,2,3)":     tests(135).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(136).expr = "atan2((1,2),3)":   tests(136).expectedErrContains = "numeric error in atan2()" ' [shape]
  tests(137).expr = "hypot()":          tests(137).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(138).expr = "hypot(3,4,5)":     tests(138).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(139).expr = "mod()":            tests(139).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(140).expr = "mod(10,3,1)":      tests(140).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(141).expr = "mod(10,0)":        tests(141).expectedErrContains = "numeric error in mod()" ' [edge]
  tests(142).expr = "gcd()":            tests(142).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(143).expr = "gcd(6,8,10)":      tests(143).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(144).expr = "gcd(6.5,3)":       tests(144).expectedErrContains = "expects integer values" ' [type-int-only]
  tests(145).expr = "lcm(6,0)":         tests(145).expected = "0" ' [edge]
  tests(146).expr = "lcm(6.5,3)":       tests(146).expectedErrContains = "expects integer values" ' [type-int-only]
  tests(147).expr = "hex()":            tests(147).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(148).expr = "hex(1,2)":         tests(148).expected = "(0x1,0x2)" ' [ok-array]
  tests(149).expr = "bin()":            tests(149).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(150).expr = "bin(1,2)":         tests(150).expected = "(0b1,0b10)" ' [ok-array]
  tests(151).expr = "clamp()":          tests(151).expectedErrContains = "expects 3 argument(s)" ' [arity]
  tests(152).expr = "clamp(1,2)":       tests(152).expectedErrContains = "expects 3 argument(s)" ' [arity]
  tests(153).expr = "clamp(1,2,3,4)":   tests(153).expectedErrContains = "expects 3 argument(s)" ' [arity]
  tests(154).expr = "clamp((1,2),(3,4),4)": tests(154).expectedErrContains = "expects scalar min/max" ' [type]
  tests(155).expr = "rand()*0":         tests(155).expected = "0" ' [edge]
  tests(156).expr = "random()":         tests(156).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(157).expr = "random(1)":        tests(157).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(158).expr = "random(1,2,3)":    tests(158).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(159).expr = "random((1,2),3)":  tests(159).expectedErrContains = "expects scalar values" ' [shape]
  tests(160).expr = "sort()":           tests(160).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(161).expr = "sort((2,5,1),4,3)": tests(161).expected = "(1,2,3,4,5)" ' [ok-array]
  tests(162).expr = "unique()":         tests(162).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(163).expr = "unique((1,2),2,1,3)": tests(163).expected = "(1,2,3)" ' [ok-array]
  tests(164).expr = "sum()":            tests(164).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(165).expr = "product()":        tests(165).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(166).expr = "min()":            tests(166).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(167).expr = "max()":            tests(167).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(168).expr = "avg()":            tests(168).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(169).expr = "median()":         tests(169).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(170).expr = "variance()":       tests(170).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(171).expr = "stddev()":         tests(171).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(172).expr = "sin(1,2)":         tests(172).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(173).expr = "cos(1,2)":         tests(173).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(174).expr = "ln(1,2)":          tests(174).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(175).expr = "sqrt(1,2)":        tests(175).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(176).expr = "fact()":           tests(176).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(177).expr = "factorial(1,2)":   tests(177).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(178).expr = "pow(2,)":          tests(178).expectedErrContains = "unexpected comma" ' [syntax]
  tests(179).expr = "sum((1,2),)":      tests(179).expectedErrContains = "unexpected comma" ' [syntax]

  ' === G) [spec] Extended negative matrix: malformed syntax, aliases, and mismatch paths ===
  tests(180).expr = "1/":               tests(180).expectedErrContains = "unexpected token" ' [syntax]
  tests(181).expr = "1**":              tests(181).expectedErrContains = "unexpected token" ' [syntax]
  tests(182).expr = "1<<":              tests(182).expectedErrContains = "unexpected token" ' [syntax]
  tests(183).expr = "1>>":              tests(183).expectedErrContains = "unexpected token" ' [syntax]
  tests(184).expr = "1&":               tests(184).expectedErrContains = "unexpected token" ' [syntax]
  tests(185).expr = "1|":               tests(185).expectedErrContains = "unexpected token" ' [syntax]
  tests(186).expr = "1^":               tests(186).expectedErrContains = "unexpected token" ' [syntax]
  tests(187).expr = "1%":               tests(187).expected = "0.01" ' [edge]
  tests(188).expr = "pow(,2)":          tests(188).expectedErrContains = "unexpected" ' [syntax]
  tests(189).expr = "atan2(,2)":        tests(189).expectedErrContains = "unexpected" ' [syntax]
  tests(190).expr = "random(,2)":       tests(190).expectedErrContains = "unexpected" ' [syntax]
  tests(191).expr = "clamp(1,,3)":      tests(191).expectedErrContains = "unexpected" ' [syntax]
  tests(192).expr = "sum(,1)":          tests(192).expectedErrContains = "unexpected" ' [syntax]
  tests(193).expr = "sin()":            tests(193).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(194).expr = "tan()":            tests(194).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(195).expr = "asin()":           tests(195).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(196).expr = "acos()":           tests(196).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(197).expr = "atan()":           tests(197).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(198).expr = "sinh()":           tests(198).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(199).expr = "cosh()":           tests(199).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(200).expr = "tanh()":           tests(200).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(201).expr = "exp()":            tests(201).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(202).expr = "log10()":          tests(202).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(203).expr = "abs()":            tests(203).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(204).expr = "floor()":          tests(204).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(205).expr = "ceil()":           tests(205).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(206).expr = "trunc()":          tests(206).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(207).expr = "round()":          tests(207).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(208).expr = "sign()":           tests(208).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(209).expr = "deg()":            tests(209).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(210).expr = "rad()":            tests(210).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(211).expr = "ln((1,2))":        tests(211).expected = "(0,0.6931471805599453)" ' [ok-array]
  tests(212).expr = "sqrt((1,2))":      tests(212).expected = "(1,1.414213562373095)" ' [ok-array]
  tests(213).expr = "abs((1,2))":       tests(213).expected = "(1,2)" ' [ok-array]
  tests(214).expr = "arcsin(1)":        tests(214).expected = "1.570796326794897" ' [ok-func]
  tests(215).expr = "arccos(1)":        tests(215).expected = "0" ' [ok-func]
  tests(216).expr = "arctan(1)":        tests(216).expected = "0.7853981633974483" ' [ok-func]
  tests(217).expr = "prod()":           tests(217).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(218).expr = "mean()":           tests(218).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(219).expr = "variance(( ))":    tests(219).expectedErrContains = "unexpected token" ' [syntax]
  tests(220).expr = "stddev(( ))":      tests(220).expectedErrContains = "unexpected token" ' [syntax]
  tests(221).expr = "gcd(1)":           tests(221).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(222).expr = "lcm(1)":           tests(222).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(223).expr = "mod(1)":           tests(223).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(224).expr = "hypot(1)":         tests(224).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(225).expr = "atan2(1)":         tests(225).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(226).expr = "log((1,2),10)":    tests(226).expected = "(0,0.3010299956639812)" ' [ok-array]
  tests(227).expr = "log(10,(2,3))":    tests(227).expected = "(3.321928094887362,2.095903274289384)" ' [ok-array]
  tests(228).expr = "pow((2,3),2)":     tests(228).expected = "(4,9)" ' [ok-array]
  tests(229).expr = "pow(2,(2,3))":     tests(229).expected = "(4,8)" ' [ok-array]
  tests(230).expr = "hex((1,2,3),(4))": tests(230).expected = "(0x1,0x2,0x3,0x4)" ' [ok-array]
  tests(231).expr = "bin((1,2,3),(4))": tests(231).expected = "(0b1,0b10,0b11,0b100)" ' [ok-array]
  tests(232).expr = "random(10,10)":    tests(232).expected = "10" ' [edge]
  tests(233).expr = "random(1.5,1.5)":  tests(233).expected = "1.5" ' [edge]
  tests(234).expr = "random(3.5,3.5)":  tests(234).expected = "3.5" ' [edge]
  tests(235).expr = "fact((1,2))":      tests(235).expectedErrContains = "expects a non-negative integer" ' [shape]
  tests(236).expr = "factorial((1,2))": tests(236).expectedErrContains = "expects a non-negative integer" ' [shape]
  '
  ' === REGRESSION-LOCK / compatibility behavior ===
  ' These cases intentionally lock currently observed behavior that may look odd,
  ' but should not change accidentally without an explicit decision.
  tests(237).expr = "clamp((1,2,3),(4,5),6)": tests(237).expectedErrContains = "expects scalar min/max" ' [type]
  tests(238).expr = "sum((1,2),(3,4),5)": tests(238).expected = "15" ' [ok-array]
  tests(239).expr = "sort(( ))":        tests(239).expectedErrContains = "unexpected token" ' [syntax]
  tests(240).expr = "unique(( ))":      tests(240).expectedErrContains = "unexpected token" ' [syntax]
  tests(241).expr = "RestoreAnsFromCachedRender(g_cachedRenderText(i))": tests(241).expectedErrContains = "unknown functions" ' [regression-lock]
  tests(242).expr = "deg(pi/2,pi/4)":   tests(242).expected = "(90,45)" ' [ok-array]
  tests(243).expr = "rad(180,90)":      tests(243).expected = "(3.141592653589793,1.570796326794897)" ' [ok-array]
  tests(244).expr = "mean":             tests(244).expectedErrContains = "function: mean(...)" ' [hint]
  tests(245).expr = "floor":            tests(245).expectedErrContains = "function: floor(value)" ' [hint]
  tests(246).expr = "ceil":             tests(246).expectedErrContains = "function: ceil(value)" ' [hint]
  tests(247).expr = "trunc":            tests(247).expectedErrContains = "function: trunc(value)" ' [hint]
  tests(248).expr = "round":            tests(248).expectedErrContains = "function: round(value)" ' [hint]
  tests(249).expr = "sign":             tests(249).expectedErrContains = "function: sign(value)" ' [hint]
  tests(250).expr = "deg":              tests(250).expectedErrContains = "function: deg(...)" ' [hint]
  tests(251).expr = "rad":              tests(251).expectedErrContains = "function: rad(...)" ' [hint]
  tests(252).expr = "int(2.9)":         tests(252).expected = "2" ' [ok-func]
  tests(253).expr = "int(-2.9)":        tests(253).expected = "-2" ' [ok-func]
  tests(254).expr = "frac(2.9)":        tests(254).expected = "0.8999999999999999" ' [ok-func]
  tests(255).expr = "frac(-2.9)":       tests(255).expected = "-0.8999999999999999" ' [ok-func]
  tests(256).expr = "int((2.9,-2.9))":  tests(256).expected = "(2,-2)" ' [ok-array]
  tests(257).expr = "frac((2.9,-2.9))": tests(257).expected = "(0.8999999999999999,-0.8999999999999999)" ' [ok-array]
  tests(258).expr = "int":              tests(258).expectedErrContains = "function: int(value)" ' [hint]
  tests(259).expr = "frac":             tests(259).expectedErrContains = "function: frac(value)" ' [hint]
  tests(260).expr = "fract(2.9)":       tests(260).expected = "0.8999999999999999" ' [ok-func]
  tests(261).expr = "fract((2.9,-2.9))": tests(261).expected = "(0.8999999999999999,-0.8999999999999999)" ' [ok-array]
  tests(262).expr = "fract":            tests(262).expectedErrContains = "function: frac(value)" ' [hint]
  tests(263).expr = "oct(12)":          tests(263).expected = "0o14" ' [ok-func]
  tests(264).expr = "oct((12,255))":    tests(264).expected = "(0o14,0o377)" ' [ok-array]
  tests(265).expr = "10 + oct(12) + 14": tests(265).expected = "36" ' [ok-func]
  tests(266).expr = "oct(12.5)":        tests(266).expectedErrContains = "oct() expects integer values" ' [type-int-only]
  tests(267).expr = "oct":              tests(267).expectedErrContains = "function: oct(...)" ' [hint]
  tests(268).expr = "oct()":            tests(268).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(269).expr = "oct(1,2)":         tests(269).expected = "(0o1,0o2)" ' [ok-array]
  tests(270).expr = "oct((1,2,3),(4))": tests(270).expected = "(0o1,0o2,0o3,0o4)" ' [ok-array]
  tests(271).expr = "oct(15);ans":      tests(271).expected = "0o17" ' [ok-func]
  tests(272).expr = "oct(9223372036854775807+1)": tests(272).expectedErrContains = "oct() expects integer values" ' [overflow]
  tests(273).expr = "0O77":             tests(273).expected = "63" ' [ok-core]
  tests(274).expr = "0o123 + 1":        tests(274).expected = "84" ' [ok-core]
  tests(275).expr = "0o20 & 0xF":       tests(275).expected = "0" ' [ok-core]
  tests(276).expr = "oct((0o7,0o10))":  tests(276).expected = "(0o7,0o10)" ' [ok-array]
  tests(277).expr = "0o64":             tests(277).expected = "52" ' [ok-core]
  tests(278).expr = "0o":               tests(278).expectedErrContains = "invalid octal literal" ' [syntax]
  tests(279).expr = "oct(0o17)":        tests(279).expected = "0o17" ' [ok-func]
  tests(280).expr = "0o10 + 8":         tests(280).expected = "16" ' [ok-core]
  tests(281).expr = "0b110011 & 0x37 | 0o64": tests(281).expected = "55" ' [ok-core]
  tests(282).expr = "0o8":              tests(282).expectedErrContains = "invalid octal literal" ' [syntax]
  tests(283).expr = "5=5":              tests(283).expected = "1" ' [ok-core]
  tests(284).expr = "5==4":             tests(284).expected = "0" ' [ok-core]
  tests(285).expr = "5<>4":             tests(285).expected = "1" ' [ok-core]
  tests(286).expr = "5!=5":             tests(286).expected = "0" ' [ok-core]
  tests(287).expr = "5>4":              tests(287).expected = "1" ' [ok-core]
  tests(288).expr = "5>=5":             tests(288).expected = "1" ' [ok-core]
  tests(289).expr = "4<5":              tests(289).expected = "1" ' [ok-core]
  tests(290).expr = "4<=4":             tests(290).expected = "1" ' [ok-core]
  tests(291).expr = "1|2=3":            tests(291).expected = "1" ' [ok-core]
  tests(292).expr = "1|2<2":            tests(292).expected = "0" ' [ok-core]
  tests(293).expr = "(1,2,3)=(1,2,3)":  tests(293).expected = "1" ' [ok-array]
  tests(294).expr = "(1,2,3)!=(1,2,4)": tests(294).expected = "1" ' [ok-array]
  tests(295).expr = "(1,2)<(1,2,0)":    tests(295).expected = "1" ' [ok-array]
  tests(296).expr = "(1,2,9)>(1,2,3)":  tests(296).expected = "1" ' [ok-array]
  tests(297).expr = "(1,2,3)<=(1,2,3)": tests(297).expected = "1" ' [ok-array]
  tests(298).expr = "(1)<(1,0)":        tests(298).expected = "1" ' [ok-array]
  tests(299).expr = "(1,0)>(1)":        tests(299).expected = "1" ' [ok-array]
  tests(300).expr = "5<(5,1)":          tests(300).expected = "1" ' [ok-array]
  tests(301).expr = "(5,1)>5":          tests(301).expected = "1" ' [ok-array]
  tests(302).expr = "2<3<4":            tests(302).expected = "1" ' [ok-core]
  tests(303).expr = "!0":               tests(303).expected = "1" ' [ok-core]
  tests(304).expr = "!5":               tests(304).expected = "0" ' [ok-core]
  tests(305).expr = "not 0":            tests(305).expected = "1" ' [ok-core]
  tests(306).expr = "not 2":            tests(306).expected = "0" ' [ok-core]
  tests(307).expr = "1&&1":             tests(307).expected = "1" ' [ok-core]
  tests(308).expr = "1&&0":             tests(308).expected = "0" ' [ok-core]
  tests(309).expr = "1||0":             tests(309).expected = "1" ' [ok-core]
  tests(310).expr = "0||0":             tests(310).expected = "0" ' [ok-core]
  tests(311).expr = "1 and 1":          tests(311).expected = "1" ' [ok-core]
  tests(312).expr = "1 and 0":          tests(312).expected = "0" ' [ok-core]
  tests(313).expr = "1 or 0":           tests(313).expected = "1" ' [ok-core]
  tests(314).expr = "0 or 0":           tests(314).expected = "0" ' [ok-core]
  tests(315).expr = "!1=0":             tests(315).expected = "1" ' [ok-core]
  tests(316).expr = "1=1 && 0=1":       tests(316).expected = "0" ' [ok-core]
  tests(317).expr = "1|2==3 && 5>3":    tests(317).expected = "1" ' [ok-core]
  tests(318).expr = "1 || 0 && 0":      tests(318).expected = "1" ' [ok-core]
  tests(319).expr = "(0,0) && 1":       tests(319).expected = "1" ' [ok-array]
  tests(320).expr = "(0,0) || 0":       tests(320).expected = "1" ' [ok-array]
  tests(321).expr = "not (0,0)":        tests(321).expected = "0" ' [ok-array]
  tests(322).expr = "0 or (0,0)":       tests(322).expected = "1" ' [ok-array]
  tests(323).expr = "not 1<0":          tests(323).expected = "1" ' [ok-core]
  tests(324).expr = "!1<0":             tests(324).expected = "0" ' [ok-core]
  tests(325).expr = "reverse((3,1,2))": tests(325).expected = "(2,1,3)" ' [ok-array]
  tests(326).expr = "reverse(2,5,1)":   tests(326).expected = "(1,5,2)" ' [ok-func]
  tests(327).expr = "reverse((1,2,3),(4,5,6),(7,8,9))": tests(327).expected = "(9,8,7,6,5,4,3,2,1)" ' [ok-array]
  tests(328).expr = "reverse(5)":       tests(328).expected = "(5)" ' [ok-func]
  tests(329).expr = "reverse":          tests(329).expectedErrContains = "function: reverse(...)" ' [hint]
  tests(330).expr = "reverse()":        tests(330).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(331).expr = "reverse((2,5,1),4,3)": tests(331).expected = "(3,4,1,5,2)" ' [ok-array]
  tests(332).expr = "reverse(( ))":     tests(332).expectedErrContains = "unexpected token" ' [syntax]
  tests(333).expr = "(10,20,30)[0]":    tests(333).expected = "10" ' [ok-array]
  tests(334).expr = "(10,20,30)[2]":    tests(334).expected = "30" ' [ok-array]
  tests(335).expr = "(10,20,30)[-1]":   tests(335).expected = "30" ' [ok-array]
  tests(336).expr = "(10,20,30)[-2]":   tests(336).expected = "20" ' [ok-array]
  tests(337).expr = "(10,20,30)[-3]":   tests(337).expected = "10" ' [ok-array]
  tests(338).expr = "(10,20,30)[-4]":   tests(338).expectedErrContains = "array index is out of range" ' [edge]
  tests(339).expr = "(10,20,30)[3]":    tests(339).expectedErrContains = "array index is out of range" ' [edge]
  tests(340).expr = "sort((3,1,2,4))[-1]": tests(340).expected = "4" ' [ok-array]
  tests(341).expr = "reverse((1,2,3,4))[-1]": tests(341).expected = "1" ' [ok-array]
  tests(342).expr = "reverse((1,2,3,4))[0]": tests(342).expected = "4" ' [ok-array]
  tests(343).expr = "sorted((3,1,2))":  tests(343).expected = "(1,2,3)" ' [ok-array]
  tests(344).expr = "sorted(2,5,1)":    tests(344).expected = "(1,2,5)" ' [ok-func]
  tests(345).expr = "sorted":           tests(345).expectedErrContains = "function: sort(...)" ' [hint]
  tests(346).expr = "reversed((1,2,3),(4,5))": tests(346).expected = "(5,4,3,2,1)" ' [ok-array]
  tests(347).expr = "reversed":         tests(347).expectedErrContains = "function: reverse(...)" ' [hint]
  tests(348).expr = "reversed((1,2,3,4))[-1]": tests(348).expected = "1" ' [ok-array]
  tests(349).expr = "3 + not 4":        tests(349).expected = "3" ' [ok-core]
  tests(350).expr = "3 + not 4 + 5":    tests(350).expected = "3" ' [ok-core]
  tests(351).expr = "oct(80)":          tests(351).expected = "0o120" ' [ok-func]
  tests(352).expr = "oct(0)":           tests(352).expected = "0o0" ' [edge]
  tests(353).expr = "oct(-1)":          tests(353).expected = "-0o1" ' [edge]
  tests(354).expr = "sin(x)=x":         tests(354).expectedErrContains = "reserved function name" ' [syntax]
  tests(355).expr = "oct(x)=x":         tests(355).expectedErrContains = "reserved function name" ' [syntax]
  tests(356).expr = "not(x)=x":         tests(356).expectedErrContains = "reserved function name" ' [syntax]
  tests(357).expr = "f(x,y)=x*y; a=(2,3); f(unpack(a))": tests(357).expected = "6" ' [ok-func]
  tests(358).expr = "f(x,y,z)=x+y+z; f(unpack((1,2,3)))": tests(358).expected = "6" ' [ok-array]
  tests(359).expr = "unpack((1,2,3))":  tests(359).expected = "(1,2,3)" ' [ok-array]
  tests(360).expr = "unpack(5)":        tests(360).expected = "5" ' [ok-func]
  tests(361).expr = "unpack()":         tests(361).expectedErrContains = "expects at least 1 argument" ' [arity]
  tests(362).expr = "unpack":           tests(362).expectedErrContains = "function: unpack(...)" ' [hint]
  tests(363).expr = "sum(unpack((1,2,3)))": tests(363).expected = "6" ' [ok-func]
  tests(364).expr = "f(x,y)=x*y; f(unpack((2,3,4)))": tests(364).expectedErrContains = "expects 2 argument(s)" ' [arity]
  tests(365).expr = "f(x,y,z)=x+y+z; f(unpack(1,2,3))": tests(365).expected = "6" ' [ok-func]
  tests(366).expr = "f(a,b,c,d,t)=a+b+c+d+t; f(unpack((1,2),3,(4,5)))": tests(366).expected = "15" ' [ok-array]
  tests(367).expr = "unpack((1,2),3,(4,5))": tests(367).expected = "(1,2,3,4,5)" ' [ok-array]

  ' === Leading identifier: '=' assignment vs '==' equality (must not steal '=' from '==') ===
  tests(368).expr = "a=5; a==5":              tests(368).expected = "1" ' [syntax] single == after assign
  tests(369).expr = "b=3; b==4":              tests(369).expected = "0" ' [syntax]
  tests(370).expr = "7==7":                   tests(370).expected = "1" ' [ok-core] one ==, literals only
  tests(371).expr = "3==3 && 4==4 && 5==5":   tests(371).expected = "1" ' [ok-core] multiple ==
  tests(372).expr = "(1==1)==(0==0)":         tests(372).expected = "1" ' [ok-core] multiple ==
  tests(373).expr = "5==5==1":                tests(373).expected = "1" ' [ok-core] chained ==
  tests(374).expr = "u=2; v=2; u==v":         tests(374).expected = "1" ' [syntax] = and ==
  tests(375).expr = "k=9; k==9 && k==3+6":    tests(375).expected = "1" ' [syntax] = and multiple ==
  tests(376).expr = "a=1; b=1; a==b==1":      tests(376).expected = "1" ' [syntax] = and chained ==

  ' === [spec] Float-derived scalars promote to exact int64 when representable (bitwise/shift/metadata) ===
  tests(377).expr = "int(7/3) << 60":         tests(377).expected = "2305843009213693952" ' 2<<60, int from float
  tests(378).expr = "sqrt(9) << 2":          tests(378).expected = "12" ' sqrt via float, then shift
  tests(379).expr = "abs(-4) << 1":           tests(379).expected = "8"
  tests(380).expr = "sum(3,5) << 2":          tests(380).expected = "32" ' aggregate float path + shift
  tests(381).expr = "(7/3.5) << 3":           tests(381).expected = "16" ' pure float division, exact int

  ' === '=' assignment (leading identifier + single '=') vs '=' comparison in expressions ===
  tests(382).expr = "x=7; x=x":                tests(382).expected = "7" ' [syntax] leading x=x is assign, not compare
  tests(383).expr = "x=7; x==x":               tests(383).expected = "1" ' [syntax]
  tests(384).expr = "x=7; (x)=(x)":           tests(384).expected = "1" ' [syntax] paren => full expr; = is compare
  tests(385).expr = "x=5; x=x+1":             tests(385).expected = "6" ' [syntax] assign RHS uses +
  tests(386).expr = "z=0; (z)=(z)":           tests(386).expected = "1" ' [syntax] compare; z defined first
  tests(387).expr = "a=2; 1+a=3":             tests(387).expected = "1" ' [syntax] expr does not start with bare name; = compare
  tests(388).expr = "b=2; b+0=2":             tests(388).expected = "1" ' [syntax] leading term is not lone identifier assign form
  tests(389).expr = "c=1; c=2; c=c":           tests(389).expected = "2" ' [syntax] last c=c is assign
  tests(390).expr = "d=4; d = d":             tests(390).expected = "4" ' [syntax] spaces around assign =
  tests(391).expr = "t=3; (t=3)":             tests(391).expected = "1" ' [syntax] inner t=3 is compare ('e' is constant, not a var)
  tests(392).expr = "x=2;y=5;x+y=x":          tests(392).expected = "0" ' [syntax] (x+y)=x compare, not assign; 7=2 -> false
  tests(393).expr = "x=2;y=3;x*y=x*y":        tests(393).expected = "1" ' [syntax] (x*y)=(x*y) compare -> true

  ' === [spec] Built-in constants (pi, e) cannot be variable/function/param names ===
  tests(394).expr = "e=1":                    tests(394).expectedErrContains = "reserved constant name" ' [syntax]
  tests(395).expr = "PI=2":                   tests(395).expectedErrContains = "reserved constant name" ' [syntax] case-insensitive
  tests(396).expr = "f(e)=e+1":               tests(396).expectedErrContains = "reserved constant name" ' [syntax] param
  tests(397).expr = "pi(x)=x":                tests(397).expectedErrContains = "reserved constant name" ' [syntax] function name
  tests(398).expr = "log(e,e)":                tests(398).expected = "1" ' [spec] e still usable as constant in expressions

  ' === hex() signed magnitude vs uhex/uoct/ubin (unsigned / two's complement) ===
  tests(399).expr = "hex(~0x0D)":             tests(399).expected = "-0xE" ' signed: -14
  tests(400).expr = "hex(-1)":                tests(400).expected = "-0x1"
  tests(401).expr = "uhex(~0x0D)":           tests(401).expected = "0xFFFFFFFFFFFFFFF2"
  tests(402).expr = "uhex(-1)":              tests(402).expected = "0xFFFFFFFFFFFFFFFF"
  tests(403).expr = "ubin(-1)":              tests(403).expected = "0b1111111111111111111111111111111111111111111111111111111111111111"
  tests(404).expr = "uoct(-1)":              tests(404).expected = "0o1777777777777777777777"
  tests(405).expr = "uhex()":                tests(405).expectedErrContains = "expects at least 1 argument"
  tests(406).expr = "uhex":                  tests(406).expectedErrContains = "function: uhex(...)"
  tests(407).expr = "uhex(1,2)":             tests(407).expected = "(0x1,0x2)"
  tests(408).expr = "bin(-2)":               tests(408).expected = "-0b10" ' bin/oct/hex still signed magnitude

  ' === int64 accuracy after float-path round-trip (scalar + array) ===
  tests(409).expr = "sqrt(81)&7":                                tests(409).expected = "1"
  tests(410).expr = "hex(sqrt(81))":                             tests(410).expected = "0x9"
  tests(411).expr = "mod(abs(-14),5)":                           tests(411).expected = "4"
  tests(412).expr = "pow(3,2)&7":                                tests(412).expected = "1"
  tests(413).expr = "hex(int((9007199254740992+2)/1))":          tests(413).expected = "0x20000000000002"
  tests(414).expr = "hex(int((9007199254740992+2)/2+0.0))":      tests(414).expected = "0x10000000000001"

  tests(415).expr = "a=sqrt((81,16,25)); a[0]&3":                tests(415).expected = "1"
  tests(416).expr = "a=sqrt((81,16,25)); hex(a[2])":             tests(416).expected = "0x5"
  tests(417).expr = "a=int((2.9,-2.9,7.1)); a[1]&1":             tests(417).expected = "0"
  tests(418).expr = "a=int((2.9,-2.9,7.1)); hex(a[0])":          tests(418).expected = "0x2"
  tests(419).expr = "a=int(((9007199254740992+2),(9007199254740992+6))/1); hex(a[0])": tests(419).expected = "0x20000000000002"
  tests(420).expr = "a=int(((9007199254740992+2),(9007199254740992+6))/1); mod(a[1],4)": tests(420).expected = "2"
  tests(421).expr = "a=int(((9007199254740992+2),(9007199254740992+6))/2); a[0]&1": tests(421).expected = "1"
  tests(422).expr = "a=int(((9007199254740992+2),(9007199254740992+6))/2); hex(a[1])": tests(422).expected = "0x10000000000003"
  tests(423).expr = "a=int(((5.9+0.1),(9.2+0.8))); mod(a[1],4)": tests(423).expected = "2"
  tests(424).expr = "a=int(((5.9+0.1),(9.2+0.8))); hex(a[0])":   tests(424).expected = "0x6"
  tests(425).expr = "a=(4611686018427387903,5)<<1; hex(a[0])":   tests(425).expected = "0x7FFFFFFFFFFFFFFE"
  tests(426).expr = "a=(4611686018427387903,5)<<1; mod(a[0],7)": tests(426).expected = "6"
  tests(427).expr = "a=(4611686018427387903,5)<<1; b=a>>1; hex(b[0])": tests(427).expected = "0x3FFFFFFFFFFFFFFF"
  tests(428).expr = "a=(9223372036854775806,15); b=a&7; hex(b[0])": tests(428).expected = "0x6"
  tests(429).expr = "a=(9223372036854775800,1); b=a|7; hex(b[0])": tests(429).expected = "0x7FFFFFFFFFFFFFFF"
  tests(430).expr = "a=(9223372036854775806,9223372036854775805); mod(a[1],5)": tests(430).expected = "0"
  tests(431).expr = "a=(9223372036854775806,9223372036854775805); b=a>>2; hex(b[0])": tests(431).expected = "0x1FFFFFFFFFFFFFFF"
  tests(432).expr = "-1>>1":                                     tests(432).expected = "-1"
  tests(433).expr = "uhex(1<<63)":                               tests(433).expected = "0x8000000000000000"
  tests(434).expr = "a=(-1,-2)>>1; a[0]":                        tests(434).expected = "-1"
  tests(435).expr = "a=(-1,3)<<1; uhex(a[0])":                   tests(435).expected = "0xFFFFFFFFFFFFFFFE"
  tests(436).expr = "a=(-1,-2)>>1; uhex(a[1])":                  tests(436).expected = "0xFFFFFFFFFFFFFFFF"
  tests(437).expr = "(1+2)(3+4)":                                tests(437).expected = "21"
  tests(438).expr = "2(1+pi)":                                   tests(438).expected = "8.283185307179586"
  tests(439).expr = "a=(3,4)+(5,6); hex(a[0])":                  tests(439).expected = "0x8"
  tests(440).expr = "a=(3,4)*2; hex(a[1])":                      tests(440).expected = "0x8"
  tests(441).expr = "a=2*(3,4); hex(a[1])":                      tests(441).expected = "0x8"
  tests(442).expr = "a=(1,2)&3; hex(a[1])":                      tests(442).expected = "0x2"
  tests(443).expr = "a=3&(1,2); hex(a[1])":                      tests(443).expected = "0x2"
  tests(444).expr = "a=(1,2)&(3,4); hex(a[1])":                  tests(444).expected = "0x0"
  tests(445).expr = "log((8,100),(2,10))":                       tests(445).expected = "(3,2)"
  tests(446).expr = "clamp((1,9),(0,10),(5,7))":                 tests(446).expectedErrContains = "expects scalar min/max"
  tests(447).expr = "clamp(5,(1,6),(4,7))":                      tests(447).expectedErrContains = "expects scalar min/max"
  tests(448).expr = "gcd((84,30),6)":                            tests(448).expectedErrContains = "expects scalar values"
  tests(449).expr = "gcd(6,(84,30))":                            tests(449).expectedErrContains = "expects scalar values"
  tests(450).expr = "lcm((6,8),3)":                              tests(450).expectedErrContains = "expects scalar values"
  tests(451).expr = "lcm((6,8),(3,5))":                          tests(451).expectedErrContains = "expects scalar values"
  tests(452).expr = "16>>1>>2":                                  tests(452).expected = "2"
  tests(453).expr = "7&3|8":                                     tests(453).expected = "11"
  tests(454).expr = "7^3^1":                                     tests(454).expected = "5"
  tests(455).expr = "hex(-2)":                                   tests(455).expected = "-0x2"
  tests(456).expr = "uhex(-2)":                                  tests(456).expected = "0xFFFFFFFFFFFFFFFE"
  tests(457).expr = "hex((15,-2))":                              tests(457).expected = "(0xF,-0x2)"
  tests(458).expr = "hypot(1,2,3,4)":                            tests(458).expectedErrContains = "expects 2 argument(s)"
  tests(459).expr = "a=9007199254740992+1; b=a; hex(b)":         tests(459).expected = "0x20000000000001"
  tests(460).expr = "uhex((1,-1))":                              tests(460).expected = "(0x1,0xFFFFFFFFFFFFFFFF)"
  tests(461).expr = "sum(unpack((1,2),(3,4),5))":                tests(461).expected = "15"
  tests(462).expr = "a=(1,2)+(3,4); hex(a[1])":                  tests(462).expected = "0x6"
  tests(463).expr = "NoT 0":                                     tests(463).expected = "1"
  tests(464).expr = "(5>=4)<2":                                  tests(464).expected = "1"
  tests(465).expr = "a=round((1.2,2.8)); hex(a[1])":             tests(465).expected = "0x3"
  tests(466).expr = "a=(5,6)*(7,8); hex(a[1])":                  tests(466).expected = "0x30"
  tests(467).expr = "a=(10,20)-(3,4); hex(a[1])":                tests(467).expected = "0x10"
  tests(468).expr = "a=(20,21)%(3,4); hex(a[1])":                tests(468).expected = "0x1"
  tests(469).expr = "log(8,(2,4))":                              tests(469).expected = "(3,1.5)"
  tests(470).expr = "lcm(21,6)":                                 tests(470).expected = "42"
  tests(471).expr = "a=(1,2)|(4,8); hex(a[1])":                 tests(471).expected = "0xA"
  tests(472).expr = "a=(1,2)^(4,8); hex(a[1])":                 tests(472).expected = "0xA"
  tests(473).expr = "a=(1,(2+3),7); hex(a[1])":                 tests(473).expected = "0x5"
  tests(474).expr = "a=abs((-1,-2)); hex(a[1])":                tests(474).expected = "0x2"
  tests(475).expr = "a=-(-1,-2); hex(a[1])":                    tests(475).expected = "0x2"
  tests(476).expr = "a=(8,9)>>1; hex(a[1])":                    tests(476).expected = "0x4"
  tests(477).expr = "a=(8,9)<<1; hex(a[1])":                    tests(477).expected = "0x12"
  tests(478).expr = "a=(9,10)&(3,12); hex(a[1])":               tests(478).expected = "0x8"
  tests(479).expr = "a=(9,10)|(3,12); hex(a[1])":               tests(479).expected = "0xE"
  tests(480).expr = "a=(9,10)^(3,12); hex(a[0])":               tests(480).expected = "0xA"
  tests(481).expr = "a=abs((-3,-4)); hex(a[0])":                tests(481).expected = "0x3"
  tests(482).expr = "a=(1,(2+3),4); hex(a[2])":                 tests(482).expected = "0x4"
  tests(483).expr = "a=int((7.9,8.1)); hex(a[1])":              tests(483).expected = "0x8"
  tests(484).expr = "a=(20,21)%(6,4); hex(a[0])":               tests(484).expected = "0x2"
  tests(485).expr = "a=(2,3)+(4,5); hex(a[1])":                 tests(485).expected = "0x8"
  tests(486).expr = "a=(9,7)-(4,5); hex(a[0])":                 tests(486).expected = "0x5"
  tests(487).expr = "a=(3,4)*(5,6); hex(a[0])":                 tests(487).expected = "0xF"
  tests(488).expr = "a=(8,9)/1; hex(a[1])":                     tests(488).expected = "0x9"
  tests(489).expr = "a=int((8.9,9.1)); hex(a[0])":              tests(489).expected = "0x8"
  tests(490).expr = "a=round((8.2,9.8)); hex(a[0])":            tests(490).expected = "0x8"
  tests(491).expr = "a=-(-5,-6); hex(a[0])":                    tests(491).expected = "0x5"
  tests(492).expr = "a=abs((-1,-2,-3)); hex(a[2])":             tests(492).expected = "0x3"
  tests(493).expr = "a=(8,9)|1; hex(a[0])":                     tests(493).expected = "0x9"
  tests(494).expr = "a=(8,9)&7; hex(a[0])":                     tests(494).expected = "0x0"
  tests(495).expr = "a=(8,9)<<1; hex(a[0])":                    tests(495).expected = "0x10"
  tests(496).expr = "a=(8,9)>>1; hex(a[0])":                    tests(496).expected = "0x4"
  tests(497).expr = "a=(20,21)%(6,4); hex(a[1])":               tests(497).expected = "0x1"
  tests(498).expr = "a=int((5.9,6.1,7.2)); hex(a[2])":          tests(498).expected = "0x7"
  tests(499).expr = "a=round((5.2,6.8,7.1)); hex(a[2])":        tests(499).expected = "0x7"
  tests(500).expr = "a=abs((-5,-6,-7)); hex(a[1])":             tests(500).expected = "0x6"
  tests(501).expr = "a=(8,9)|2; hex(a[1])":                     tests(501).expected = "0xB"
  tests(502).expr = "a=(8,9)&3; hex(a[1])":                     tests(502).expected = "0x1"
  tests(503).expr = "a=(8,9)^3; hex(a[1])":                     tests(503).expected = "0xA"
  tests(504).expr = "a=(10,11)+(1,2); hex(a[0])":               tests(504).expected = "0xB"
  tests(505).expr = "a=(10,11)-(1,2); hex(a[1])":               tests(505).expected = "0x9"
  tests(506).expr = "a=(10,11)*(2,3); hex(a[1])":               tests(506).expected = "0x21"
  tests(507).expr = "a=(10,11)/1; hex(a[0])":                   tests(507).expected = "0xA"
  tests(508).expr = "a=int((10.9,11.1)); hex(a[1])":            tests(508).expected = "0xB"
  tests(509).expr = "a=round((10.2,11.8)); hex(a[1])":          tests(509).expected = "0xC"
  tests(510).expr = "a=abs((-10,-11)); hex(a[0])":              tests(510).expected = "0xA"
  tests(511).expr = "a=-(-10,-11); hex(a[1])":                  tests(511).expected = "0xB"
  tests(512).expr = "a=(8,9,10)|1; hex(a[2])":                  tests(512).expected = "0xB"
  tests(513).expr = "a=(8,9,10)&3; hex(a[2])":                  tests(513).expected = "0x2"
  tests(514).expr = "a=(8,9,10)^3; hex(a[2])":                  tests(514).expected = "0x9"
  tests(515).expr = "a=(10,11)>>1; hex(a[1])":                  tests(515).expected = "0x5"
  tests(516).expr = "unique((5,3,5,2,3))":                      tests(516).expected = "(5,3,2)"
  tests(517).expr = "unique((2,1,2,1,3,2))":                    tests(517).expected = "(2,1,3)"
  tests(518).expr = "unique(7)":                                tests(518).expected = "(7)"
  tests(519).expr = "unique((1,2),2,1,3)":                      tests(519).expected = "(1,2,3)"
  tests(520).expr = "unique((0,-0,0,0))":                       tests(520).expected = "(0)"
  tests(521).expr = "unique((-0,0,1))":                         tests(521).expected = "(0,1)"
  tests(522).expr = "unique((1.5,1.5,2.5,1.5))":                tests(522).expected = "(1.5,2.5)"
  tests(523).expr = "unique((2.0,2,2.000,3))":                  tests(523).expected = "(2,3)"
  tests(524).expr = "unique(unpack((4,1),(4,2),1))":            tests(524).expected = "(4,1,2)"
  tests(525).expr = "unique((9,8,7,9,8,7,6,5,6))":              tests(525).expected = "(9,8,7,6,5)"
  tests(526).expr = "unique((3,3,3,3,2,2,1))":                  tests(526).expected = "(3,2,1)"
  tests(527).expr = "median((9,1,5,3,7))":                      tests(527).expected = "5"
  tests(528).expr = "median((10,1,7,3))":                       tests(528).expected = "5"
  tests(529).expr = "variance((-3,0,3,6))":                     tests(529).expected = "11.25"
  tests(530).expr = "stddev((-3,0,3,6))":                       tests(530).expected = "3.354101966249685"
  tests(531).expr = "hex(fact(20))":                            tests(531).expected = "0x21C3677C82B40000"
  tests(579).expr = "factorial(30)":                            tests(579).expected = "2.65252859812191e+032"
  tests(532).expr = "sort((5,1,5,2,2,9,1))":                    tests(532).expected = "(1,1,2,2,5,5,9)"
  tests(533).expr = "sorted((4,4,3,2,2,1))":                    tests(533).expected = "(1,2,2,3,4,4)"
  tests(534).expr = "avg((2,4),6,8)":                           tests(534).expected = "5"
  tests(535).expr = "min((5,7),3,9)":                           tests(535).expected = "3"
  tests(536).expr = "sum(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)": tests(536).expected = "136"
  tests(537).expr = "max((5,7),3,9)":                           tests(537).expected = "9"
  tests(538).expr = "sum(unpack((1,2,3),(4,5),6,7))":          tests(538).expected = "28"
  tests(539).expr = "sorted((3,3,1,2,1))":                     tests(539).expected = "(1,1,2,3,3)"
  tests(540).expr = "reversed((1,2,3,4,5))":                   tests(540).expected = "(5,4,3,2,1)"
  tests(541).expr = "f(x,y)=x+y; f(2,3)":                      tests(541).expected = "5"
  tests(542).expr = "a=(5,2,5,9,2); unique(a)":                tests(542).expected = "(5,2,9)"
  tests(543).expr = "sum(42)":                                 tests(543).expected = "42"
  tests(544).expr = "a=(3,1,2); sorted(a)":                    tests(544).expected = "(1,2,3)"
  tests(545).expr = "unique((1,1,2,2,3,3))":                  tests(545).expected = "(1,2,3)"
  tests(546).expr = "avg(unpack((1,2),(3,4)),10)":            tests(546).expected = "4"
  tests(547).expr = "reverse((1,2),3,(4,5))":                 tests(547).expected = "(5,4,3,2,1)"
  tests(548).expr = "f(a,b)=a*b; f(unpack((3,4)))":           tests(548).expected = "12"
  tests(549).expr = "a=(9007199254740993); hex(unpack(a))":      tests(549).expected = "0x20000000000001"
  tests(550).expr = "a=-(9007199254740991,5); uhex(a[0])":    tests(550).expected = "0xFFE0000000000001"
  tests(551).expr = "hex((1,2.5))":                            tests(551).expectedErrContains = "hex() expects integer values"
  tests(552).expr = "unique((9,9,8,8,7))":                     tests(552).expected = "(9,8,7)"
  tests(553).expr = "reverse((9,8,7,6))":                      tests(553).expected = "(6,7,8,9)"
  tests(554).expr = "deg((pi/2),pi)":                          tests(554).expected = "(90,180)"
  tests(555).expr = "uhex((1,-1),2)":                          tests(555).expected = "(0x1,0xFFFFFFFFFFFFFFFF,0x2)"
  tests(556).expr = "uhex(unpack((1,-1),2))":                  tests(556).expected = "(0x1,0xFFFFFFFFFFFFFFFF,0x2)"
  tests(557).expr = "variance((1,2),3,4)":                     tests(557).expected = "1.25"
  tests(558).expr = "stddev((1,2),3,4)":                       tests(558).expected = "1.118033988749895"
  tests(559).expr = "median(42)":                              tests(559).expected = "42"
  tests(560).expr = "median((42))":                            tests(560).expected = "42"
  tests(561).expr = "123":                                     tests(561).expected = "123"
  tests(562).expr = "unknownFunc(1)":                          tests(562).expectedErrContains = "unknown functions"
  tests(563).expr = "2+3; ans":                                tests(563).expected = "5"
  tests(564).expr = "(e=3)":                                   tests(564).expected = "0"
  tests(565).expr = "(pi=3.141592653589793)":                  tests(565).expected = "1"
  tests(566).expr = "(1,2,3)[1.2]":                            tests(566).expectedErrContains = "array index must be an integer"
  tests(567).expr = "(1,2,3)[(1,2)]":                          tests(567).expectedErrContains = "array index must be a scalar integer"
  tests(568).expr = "1<<0":                                    tests(568).expected = "1"
  tests(569).expr = "8>>0":                                    tests(569).expected = "8"
  tests(570).expr = "1<<63":                                   tests(570).expected = "-9223372036854775808"
  tests(571).expr = "-1>>63":                                  tests(571).expected = "-1"
  tests(572).expr = "a=(1,2)<<0; a":                           tests(572).expected = "(1,2)"
  tests(573).expr = "a=(8,9)>>0; a":                           tests(573).expected = "(8,9)"
  tests(574).expr = "a=(1,2)<<63; uhex(a[0])":                 tests(574).expected = "0x8000000000000000"
  tests(575).expr = "a=(-1,-2)>>63; a[1]":                     tests(575).expected = "-1"
  tests(576).expr = "0b102":                                   tests(576).expectedErrContains = "unexpected token"
  tests(577).expr = "0o89":                                    tests(577).expectedErrContains = "invalid octal literal"
  tests(578).expr = "0x1G":                                    tests(578).expectedErrContains = "unexpected token"
  tests(580).expr = "hex=1":                                   tests(580).expectedErrContains = "reserved function name"
  tests(581).expr = "HEX=1":                                   tests(581).expectedErrContains = "reserved function name"
  tests(582).expr = "random=1":                                tests(582).expectedErrContains = "reserved function name"
  tests(583).expr = "0xAA; hex":                               tests(583).expected = "0xAA"
  tests(584).expr = "0xAA; hex()":                             tests(584).expected = "0xAA"
  tests(585).expr = "(0x3C & 0x75, 0x01 | 0x30); hex":         tests(585).expected = "(0x34,0x31)"
  tests(586).expr = "(8,9); bin()":                            tests(586).expected = "(0b1000,0b1001)"
  tests(587).expr = "15; uhex":                                tests(587).expected = "0xF"
  tests(588).expr = "0xAA; foo()":                             tests(588).expectedErrContains = "unknown functions"

  tests(589).expr = "x(a)=x(a); x(1)":                        tests(589).expectedErrContains = "body cannot call 'x'" ' [regression] direct self-call in UDF body
  tests(590).expr = "y(a)=g(a)+y(a)+4":                      tests(590).expectedErrContains = "body cannot call 'y'" ' [regression] self-call among other terms
  tests(591).expr = "g(a)=y(a)+1; y(a)=g(a)+2; y(5)":        tests(591).expectedErrContains = "recursive user function call" ' [regression] mutual recursion y<->g
  tests(592).expr = "a(x)=b(x); b(x)=c(x); c(x)=d(x); d(x)=b(x); a(1)": tests(592).expectedErrContains = "recursive user function call" ' [regression] longer cycle back to b
  tests(593).expr = "2^3":                                   tests(593).expected = "1" ' [regression] caret is bitwise XOR
  tests(594).expr = "2**3":                                  tests(594).expected = "8" ' [regression] double-star is power
  tests(595).expr = "3^2":                                   tests(595).expected = "1" ' [regression] caret is not power
  tests(596).expr = "3**2":                                  tests(596).expected = "9" ' [regression] double-star power
  tests(597).expr = "f(x)=x*p(x); f(2)":                     tests(597).expectedErrContains = "unknown functions" ' [regression] late binding unresolved referenced UDF
  tests(598).expr = "f(x)=x*p(x); p(x)=x+5; f(10)":          tests(598).expected = "150" ' [regression] late binding resolved after referenced UDF definition
  tests(599).expr = "f(x)=x*p(x); p(x)=x**(1/3); f(8)":      tests(599).expected = "16" ' [regression] late binding with nonlinear referenced UDF
  tests(600).expr = "f(x)=x*p(x); p(x)=x+5; p(x)=x**(1/3); f(8)": tests(600).expected = "16" ' [regression] late binding uses latest referenced UDF definition

  g_total = ubound(tests) - lbound(tests) + 1

  print "=== SmartMath parser smoke tests ==="
  print "Total cases: " & g_total
  print ""

  Parser_ClearVariables()
  for i as Integer = lbound(tests) to ubound(tests)
    RunCase(tests(i))
  next i

  ' Mirror C++ test coverage from Basic runner:
  ' if C++ tests executable exists, run it and require success.
  dim cppTestsExe as String = "cpp\MathParserTests.exe"
  if len(dir(cppTestsExe)) > 0 then
    g_total += 1
    g_idx += 1
    print "[" & g_idx & "/" & g_total & "] RUN  : " & cppTestsExe
    dim rc as Integer = shell(cppTestsExe)
    if rc = 0 then
      g_passed += 1
      print "          PASS : C++ mirrored suite passed"
    else
      g_failed += 1
      print "          FAIL : C++ mirrored suite failed with exit code " & rc
      print "                 build via cpp\BuildTests_vc2022_x64.bat and re-run"
    end if
    print ""
  end if

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
