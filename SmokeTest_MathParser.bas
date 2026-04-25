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
    if actual = c.expected then passCase = TRUE
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
  dim tests(1 to 179) as SmokeCase
  ' Inline tag legend: [ok-core] [ok-func] [ok-array] [hint] [arity]
  ' [type-int-only] [shape] [shape/broadcast] [syntax] [edge] [overflow]

  ' === A) Operator precedence, core operators, and integer-only operator checks ===
  tests(1).expr = "2**3":               tests(1).expected = "8" ' [ok-core]
  tests(2).expr = "16**-0.5":           tests(2).expected = "0.25" ' [ok-core]
  tests(3).expr = "+5":                 tests(3).expected = "5" ' [ok-core]
  tests(4).expr = "-5":                 tests(4).expected = "-5" ' [ok-core]
  tests(5).expr = "~5":                 tests(5).expected = "-6" ' [ok-core]
  tests(6).expr = "5%3":                tests(6).expected = "2" ' [ok-core]
  tests(7).expr = "200 + 15%":          tests(7).expected = "230" ' [ok-core]
  tests(8).expr = "200 - 15%":          tests(8).expected = "170" ' [ok-core]
  tests(9).expr = "8>>1":               tests(9).expected = "4" ' [ok-core]
  tests(10).expr = "3<<2":              tests(10).expected = "12" ' [ok-core]
  tests(11).expr = "6&3":               tests(11).expected = "2" ' [ok-core]
  tests(12).expr = "6^3":               tests(12).expected = "5" ' [ok-core]
  tests(13).expr = "6|3":               tests(13).expected = "7" ' [ok-core]
  tests(14).expr = "2(3+4)":            tests(14).expected = "14" ' [ok-core]
  tests(15).expr = "2(3+4)**2":         tests(15).expected = "98" ' [ok-core]
  tests(16).expr = "2+3<<1":            tests(16).expected = "10" ' [ok-core]
  tests(17).expr = "1|2^3&6<<1":        tests(17).expected = "3" ' [ok-core]
  tests(18).expr = "2(1+2)%4":          tests(18).expected = "2" ' [ok-core]
  tests(19).expr = "5.5&1":             tests(19).expectedErrContains = "bitwise operands must be integer values" ' [type-int-only]
  tests(20).expr = "5|1.1":             tests(20).expectedErrContains = "bitwise operands must be integer values" ' [type-int-only]
  tests(21).expr = "3.2^1":             tests(21).expectedErrContains = "bitwise operands must be integer values" ' [type-int-only]
  tests(22).expr = "8.1>>1":            tests(22).expectedErrContains = "bitwise operands must be integer values" ' [type-int-only]
  tests(23).expr = "8<<1.2":            tests(23).expectedErrContains = "bitwise operands must be integer values" ' [type-int-only]
  tests(24).expr = "~2.5":              tests(24).expectedErrContains = "bitwise operands must be integer values" ' [type-int-only]
  tests(25).expr = "5.5%2":             tests(25).expectedErrContains = "modulo operands must be integer values" ' [type-int-only]
  tests(26).expr = "5%2.2":             tests(26).expectedErrContains = "modulo operands must be integer values" ' [type-int-only]
  tests(27).expr = "2(1+2.5)%4.2":      tests(27).expectedErrContains = "modulo operands must be integer values" ' [type-int-only]

  ' === B) Function hints, comments, parser diagnostics, and literal parsing ===
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
  tests(46).expr = "hex":               tests(46).expectedErrContains = "function: hex(value_or_array)" ' [hint]
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
  tests(57).expr = "bin":               tests(57).expectedErrContains = "function: bin(value_or_array)" ' [hint]

  ' === C) Integer-accuracy / overflow-path regression cases ===
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

  ' === D) Built-ins and ans variable baseline behavior ===
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
  tests(106).expr = "fact(-1)":         tests(106).expectedErrContains = "fact() expects an integer in range [0..20]" ' [edge]
  tests(107).expr = "fact(2.5)":        tests(107).expectedErrContains = "fact() expects an integer in range [0..20]" ' [type-int-only]
  tests(108).expr = "factorial(21)":    tests(108).expectedErrContains = "factorial() expects an integer in range [0..20]" ' [overflow]
  tests(109).expr = "random(5,5)":      tests(109).expected = "5" ' [edge]
  tests(110).expr = "rand(1)":          tests(110).expectedErrContains = "rand() expects 0 argument(s)" ' [arity]
  tests(111).expr = "rand":             tests(111).expectedErrContains = "function: rand()" ' [hint]
  tests(112).expr = "random":           tests(112).expectedErrContains = "function: random(min, max)" ' [hint]
  tests(113).expr = "median":           tests(113).expectedErrContains = "function: median(...)" ' [hint]

  ' === E) sort/unique baseline behavior ===
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

  ' === F) Stress matrix: argument shape, arity, syntax, and edge-case validation ===
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
  tests(147).expr = "hex()":            tests(147).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(148).expr = "hex(1,2)":         tests(148).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(149).expr = "bin()":            tests(149).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(150).expr = "bin(1,2)":         tests(150).expectedErrContains = "expects 1 argument(s)" ' [arity]
  tests(151).expr = "clamp()":          tests(151).expectedErrContains = "expects 3 argument(s)" ' [arity]
  tests(152).expr = "clamp(1,2)":       tests(152).expectedErrContains = "expects 3 argument(s)" ' [arity]
  tests(153).expr = "clamp(1,2,3,4)":   tests(153).expectedErrContains = "expects 3 argument(s)" ' [arity]
  tests(154).expr = "clamp((1,2),(3),4)": tests(154).expected = "(3,3)" ' [shape/broadcast]
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

  g_total = ubound(tests) - lbound(tests) + 1

  print "=== SmartMath parser smoke tests ==="
  print "Total cases: " & g_total
  print ""

  Parser_ClearVariables()
  for i as Integer = lbound(tests) to ubound(tests)
    RunCase(tests(i))
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
