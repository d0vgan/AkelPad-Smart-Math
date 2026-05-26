' AUTO-GENERATED append rows for main tests() — indices assigned in SmokeTest.
const SMOKE_APPEND_COUNT = 14
dim shared smokeAppendExpr(1 to SMOKE_APPEND_COUNT) as String
dim shared smokeAppendExpected(1 to SMOKE_APPEND_COUNT) as String
dim shared smokeAppendErr(1 to SMOKE_APPEND_COUNT) as String
dim shared smokeAppendIsErr(1 to SMOKE_APPEND_COUNT) as Boolean
smokeAppendExpr(1) = "hours((1:00,0:30)*60)"
smokeAppendExpected(1) = "(1,0.5)"
smokeAppendIsErr(1) = FALSE
smokeAppendExpr(2) = "(1:45, 2)"
smokeAppendErr(2) = "time values cannot be mixed with non-time values"
smokeAppendIsErr(2) = TRUE
smokeAppendExpr(3) = "1/1:00"
smokeAppendErr(3) = "incompatible operands"
smokeAppendIsErr(3) = TRUE
smokeAppendExpr(4) = "1:00 + 5"
smokeAppendExpected(4) = "01:05"
smokeAppendIsErr(4) = FALSE
smokeAppendExpr(5) = "999d"
smokeAppendExpected(5) = "999:00:00:00"
smokeAppendIsErr(5) = FALSE
smokeAppendExpr(6) = "999d+1d"
smokeAppendExpected(6) = "1000:00:00:00"
smokeAppendIsErr(6) = FALSE
smokeAppendExpr(7) = "milliseconds(999d)"
smokeAppendExpected(7) = "86313600000"
smokeAppendIsErr(7) = FALSE
smokeAppendExpr(8) = "seconds((1:00,0:30)*2)"
smokeAppendExpected(8) = "(120,60)"
smokeAppendIsErr(8) = FALSE
smokeAppendExpr(9) = "days((0:30,1:00)+0:30)"
smokeAppendExpected(9) = "(0.0006944444444444444,0.0010416666666666666)"
smokeAppendIsErr(9) = FALSE
smokeAppendExpr(10) = "days((1:00,0:30)*2)"
smokeAppendExpected(10) = "(0.001388888888888888,0.0006944444444444444)"
smokeAppendIsErr(10) = FALSE
smokeAppendExpr(11) = "1:00**2"
smokeAppendErr(11) = "incompatible operands"
smokeAppendIsErr(11) = TRUE
smokeAppendExpr(12) = "1:00%2"
smokeAppendErr(12) = "modulo operands must be integer values"
smokeAppendIsErr(12) = TRUE
smokeAppendExpr(13) = "0:30**2"
smokeAppendErr(13) = "incompatible operands"
smokeAppendIsErr(13) = TRUE
smokeAppendExpr(14) = "product(18446744073709551615,1)"
smokeAppendExpected(14) = "18446744073709551615"
smokeAppendIsErr(14) = FALSE
