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
  dim tests(1 to 353) as SmokeCase
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
  tests(106).expr = "fact(-1)":         tests(106).expectedErrContains = "fact() expects an integer in range [0..20]" ' [edge]
  tests(107).expr = "fact(2.5)":        tests(107).expectedErrContains = "fact() expects an integer in range [0..20]" ' [type-int-only]
  tests(108).expr = "factorial(21)":    tests(108).expectedErrContains = "factorial() expects an integer in range [0..20]" ' [overflow]
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
  tests(235).expr = "fact((1,2))":      tests(235).expectedErrContains = "expects an integer in range [0..20]" ' [shape]
  tests(236).expr = "factorial((1,2))": tests(236).expectedErrContains = "expects an integer in range [0..20]" ' [shape]
  '
  ' === REGRESSION-LOCK / compatibility behavior ===
  ' These cases intentionally lock currently observed behavior that may look odd,
  ' but should not change accidentally without an explicit decision.
  tests(237).expr = "clamp((1,2,3),(4,5),6)": tests(237).expected = "(0,0,0)" ' [regression-lock][shape]
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
