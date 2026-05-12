#include once "crt.bi"
#include once "Inc\MathParser.bi"

extern "C"
declare function acosh (byval x as double) as double
declare function asinh (byval x as double) as double
declare function atanh (byval x as double) as double
end extern

const FB_STR_AT as string = " at "
const FB_STR_LINE_1_PREFIX as string = "line 1, "
const FB_STR_COL as string = "col "
const FB_STR_COLON as string = ":  "
const FB_STR_COMMA as string = ", "
const FB_STR_RAND as string = "rand"
const FB_STR_RANDOM as string = "random"
const FB_STR_BIN as string = "bin"
const FB_STR_HEX as string = "hex"
const FB_STR_OCT as string = "oct"
const FB_STR_POW as string = "pow"
const FB_STR_ATAN2 as string = "atan2"
const FB_STR_SIN as string = "sin"
const FB_STR_COS as string = "cos"
const FB_STR_TAN as string = "tan"
const FB_STR_ASIN as string = "asin"
const FB_STR_ARCSIN as string = "arcsin"
const FB_STR_ACOS as string = "acos"
const FB_STR_ARCCOS as string = "arccos"
const FB_STR_ATAN as string = "atan"
const FB_STR_ARCTAN as string = "arctan"
const FB_STR_SINH as string = "sinh"
const FB_STR_COSH as string = "cosh"
const FB_STR_TANH as string = "tanh"
const FB_STR_ACOSH as string = "acosh"
const FB_STR_ASINH as string = "asinh"
const FB_STR_ATANH as string = "atanh"
const FB_STR_EXP as string = "exp"
const FB_STR_LOG as string = "log"
const FB_STR_LN as string = "ln"
const FB_STR_LOG10 as string = "log10"
const FB_STR_SQRT as string = "sqrt"
const FB_STR_SQR as string = "sqr"
const FB_STR_INT as string = "int"
const FB_STR_FRAC as string = "frac"
const FB_STR_FRACT as string = "fract"
const FB_STR_ABS as string = "abs"
const FB_STR_FLOOR as string = "floor"
const FB_STR_CEIL as string = "ceil"
const FB_STR_TRUNC as string = "trunc"
const FB_STR_ROUND as string = "round"
const FB_STR_SIGN as string = "sign"
const FB_STR_DEG as string = "deg"
const FB_STR_RAD as string = "rad"
const FB_STR_SUM as string = "sum"
const FB_STR_MEDIAN as string = "median"
const FB_STR_VARIANCE as string = "variance"
const FB_STR_STDDEV as string = "stddev"
const FB_STR_SORT as string = "sort"
const FB_STR_SORTED as string = "sorted"
const FB_STR_REVERSE as string = "reverse"
const FB_STR_REVERSED as string = "reversed"
const FB_STR_UNIQUE as string = "unique"
const FB_STR_UNPACK as string = "unpack"
const FB_STR_FACT as string = "fact"
const FB_STR_FACTORIAL as string = "factorial"
const FB_STR_AVG as string = "avg"
const FB_STR_MEAN as string = "mean"
const FB_STR_MOD as string = "mod"
const FB_STR_CLAMP as string = "clamp"
const FB_STR_HYPOT as string = "hypot"
const FB_STR_GCD as string = "gcd"
const FB_STR_LCM as string = "lcm"
const FB_STR_NCR as string = "ncr"
const FB_STR_NPR as string = "npr"
const FB_STR_PRODUCT as string = "product"
const FB_STR_PROD as string = "prod"
const FB_STR_MIN as string = "min"
const FB_STR_MAX as string = "max"
const FB_STR_UHEX as string = "uhex"
const FB_STR_UOCT as string = "uoct"
const FB_STR_UBIN as string = "ubin"
const FB_STR_NOT as string = "not"
const FB_STR_AND as string = "and"
const FB_STR_OR as string = "or"
const FB_STR_PI as string = "pi"
const FB_STR_E as string = "e"
const FB_STR_INF as string = "inf"
const FB_STR_NAN as string = "nan"
const FB_STR_PAR as string = "()"
const FB_STR_PAR_MIN_COMMA_MAX as string = "(min, max)"
const FB_STR_PAR_DOTDOTDOT as string = "(...)"
const FB_STR_PAR_VALUE_COMMA_POWER as string = "(value, power)"
const FB_STR_PAR_Y_COMMA_X as string = "(y, x)"
const FB_STR_PAR_ANGLE as string = "(angle)"
const FB_STR_PAR_VALUE as string = "(value)"
const FB_STR_PAR_VALUE_COMMA_BASE as string = "(value, base)"
const FB_STR_PAR_N as string = "(n)"
const FB_STR_PAR_VALUE_COMMA_DIVISOR as string = "(value, divisor)"
const FB_STR_PAR_VALUE_COMMA_MIN_COMMA_MAX as string = "(value, min, max)"
const FB_STR_PAR_X_COMMA_Y as string = "(x, y)"
const FB_STR_PAR_A_COMMA_B as string = "(a, b)"
const FB_STR_PAR_N_COMMA_R as string = "(n, r)"
const FB_STR_PAR_ANS as string = "(ans)"
const FB_STR_PREFIX_HEX as string = "0x"
const FB_STR_PREFIX_OCT as string = "0o"
const FB_STR_PREFIX_BIN as string = "0b"
const FB_STR_ANS as string = "ans"
const FB_STR_FORMAL_VALIDATION_PROBE as string = "_"
const FB_STR_INDEXING_REQUIRES_AN_ARRAY_VALUE as string = "indexing requires an array value"
const FB_STR_MISSING_INDEX as string = "missing index"
const FB_STR_ARRAY_INDEX_MUST_BE_A_SCALAR as string = "array index must be a scalar integer"
const FB_STR_ARRAY_INDEX_MUST_BE_AN_INTEGER as string = "array index must be an integer"
const FB_STR_MISMATCHED_CLOSING_PARENTHESIS as string = "mismatched closing parenthesis"
const FB_STR_MISMATCHED_CLOSING_BRACE as string = "mismatched closing brace"
const FB_STR_MISSING_CLOSING_BRACKET as string = "missing closing bracket"
const FB_STR_ARRAY_INDEX_IS_OUT_OF_RANGE as string = "array index is out of range"
const FB_STR_PAR_EXPECTS as string = "() expects "
const FB_STR_ARGUMENT_PAR_S_COMMA as string = " argument(s), "
const FB_STR_GIVEN as string = " given"
const FB_STR_RECURSIVE_USER_FUNCTION_CALL_COLON as string = "recursive function call: "
const FB_STR_USER_FUNCTION_CALL_STACK_OVERFLOW as string = "function call stack overflow"
const FB_STR_MODULO_OPERANDS_MUST_BE_INTEGER_VALUES as string = "modulo operands must be integer values"
const FB_STR_BITWISE_OPERANDS_MUST_BE_INTEGER_VALUES as string = "bitwise operands must be integer values"
const FB_STR_INCOMPATIBLE_OPERANDS as string = "incompatible operands"
const FB_STR_TIME_EMPTY_SEGMENT as string = "time literal: empty segment between colons"
const FB_STR_TIME_INVALID_SEGMENT as string = "time literal: invalid segment"
const FB_STR_TIME_NEGATIVE_SEGMENT as string = "time literal: negative segment"
const FB_STR_TIME_NON_FINITE as string = "time value: non-finite operand"
const FB_STR_TIME_ARRAY_MIXED as string = "array literal: time values cannot be mixed with non-time values"
const FB_STR_TIME_EXPECTS_TIME_ARG as string = "() expects a time value"
const FB_STR_MILLISECOND as string = "millisecond"
const FB_STR_SECOND as string = "second"
const FB_STR_MINUTE as string = "minute"
const FB_STR_HOUR as string = "hour"
const FB_STR_DAY as string = "day"
const FB_STR_MILLISECONDS as string = "milliseconds"
const FB_STR_SECONDS as string = "seconds"
const FB_STR_MINUTES as string = "minutes"
const FB_STR_HOURS as string = "hours"
const FB_STR_DAYS as string = "days"
const FB_STR_PAR_EXPECTS_AT_LEAST_1 as string = "() expects at least 1 argument"
const FB_STR_MISSING_OPENING_BRACKET as string = "missing opening bracket"
const FB_STR_UNEXPECTED_COMMA as string = "unexpected comma"
const FB_STR_MISMATCHED_CLOSING_BRACKET as string = "mismatched closing bracket"
const FB_STR_MISSING_CLOSING_PARENTHESIS as string = "missing closing parenthesis"
const FB_STR_NUMERIC_ERROR_IN as string = "numeric error in "
const FB_STR_PAR_EXPECTS_A_NON_DASH as string = "() expects a non-negative integer"
const FB_STR_PAR_EXPECTS_SCALAR_VALUES as string = "() expects scalar values"
const FB_STR_PAR_EXPECTS_SCALAR_MIN_SLASH as string = "() expects scalar min/max"
const FB_STR_PAR_EXPECTS_INTEGER_VALUES as string = "() expects integer values"
const FB_STR_INVALID_HEX_LITERAL as string = "invalid hex literal"
const FB_STR_INVALID_BINARY_LITERAL as string = "invalid binary literal"
const FB_STR_INVALID_OCTAL_LITERAL as string = "invalid octal literal"
const FB_STR_UNEXPECTED_TOKEN as string = "unexpected token"
const FB_STR_HINT_PREFIX as string = "function: "
const FB_STR_ARRAY_ELEMENT_MUST_BE_SCALAR as string = "array element must be scalar"
const FB_STR_EXPRESSION_IS_TOO_LONG as string = "expression is too long"
const FB_STR_EMPTY_STATEMENT as string = "empty statement"
const FB_STR_RESERVED_FUNCTION_NAME_COLON as string = "reserved function name: "
const FB_STR_RESERVED_CONSTANT_NAME_COLON as string = "reserved constant name: "
const FB_STR_RESERVED_BUILTIN_VARIABLE_NAME_COLON as string = "reserved built-in variable name: "
const FB_STR_DUPLICATE_PARAMETER_NAME_COLON as string = "duplicate parameter name: "
const FB_STR_FUNCTION_BODY_IS_EMPTY as string = "function body is empty"
const FB_STR_FAILED_TO_PARSE_USER_FUNCTION_BODY as string = "failed to parse user function body"
const FB_STR_UNEXPECTED_INPUT as string = "unexpected characters"
const FB_STR_DEFINED as string = "defined "
const FB_STR_UNKNOWN_VARIABLE_COLON as string = "unknown variable: "
const FB_STR_UNKNOWN_FUNCTION_COLON as string = "unknown function: "
const FB_STR_SEMICOLON_UNKNOWN_FUNCTION_COLON as string = "; unknown function: "

const FB_U64_MAX as ULongInt = &hFFFFFFFFFFFFFFFFULL
const FB_I64_MIN as LongInt = -9223372036854775807 - 1 ' -0x8000000000000000
const FB_I64_MAX as LongInt = 9223372036854775807 ' 0x7FFFFFFFFFFFFFFF
const FB_I64_MAX_U as ULongInt = 9223372036854775807
const FB_I64_MIN_MAG_U as ULongInt = &h8000000000000000ULL
const FB_I64_MIN_D as Double = -9223372036854775808.0
const FB_I64_MAX_D as Double = 9223372036854775807.0
const FB_MAX_EXACT_INT_FROM_DOUBLE as Double = 9007199254740992.0 ' 2^53
'' IEEE double: 2^64 (next representable above UINT64_MAX).
const FB_2_POW_64_D as Double = 1.8446744073709551616e+19
const FB_PI_VAL as Double = 4.0 * atn(1.0) ' pi

' -----------------------------------------------------------------------------
'  ASCII byte constants (single-byte stream; multi-byte UTF-8 not interpreted)
' -----------------------------------------------------------------------------
const CHAR_NUL as UByte = 0                ' string terminator / NUL
const CHAR_TAB as UByte = 9                ' horizontal tab
const CHAR_LF as UByte = 10                ' line feed
const CHAR_CR as UByte = 13                ' carriage return
const CHAR_SPACE as UByte = 32             ' space
const CHAR_EXCLAMATION as UByte = 33       ' !
const CHAR_HASH as UByte = 35              ' #
const CHAR_PERCENT as UByte = 37           ' %
const CHAR_AMPERSAND as UByte = 38         ' &
const CHAR_LPAREN as UByte = 40            ' (
const CHAR_RPAREN as UByte = 41            ' )
const CHAR_ASTERISK as UByte = 42          ' *
const CHAR_PLUS as UByte = 43              ' +
const CHAR_COMMA as UByte = 44             ' ,
const CHAR_MINUS as UByte = 45             ' -
const CHAR_DOT as UByte = 46               ' .
const CHAR_DIVIDE as UByte = 47            ' /
const CHAR_DIGIT_0 as UByte = 48           ' digit 0
const CHAR_DIGIT_1 as UByte = 49           ' digit 1
const CHAR_DIGIT_2 as UByte = 50           ' digit 2
const CHAR_DIGIT_3 as UByte = 51           ' digit 3
const CHAR_DIGIT_4 as UByte = 52           ' digit 4
const CHAR_DIGIT_5 as UByte = 53           ' digit 5
const CHAR_DIGIT_6 as UByte = 54           ' digit 6
const CHAR_DIGIT_7 as UByte = 55           ' digit 7
const CHAR_DIGIT_8 as UByte = 56           ' digit 8
const CHAR_DIGIT_9 as UByte = 57           ' digit 9
const CHAR_COLON as UByte = 58             ' :
const CHAR_SEMICOLON as UByte = 59         ' ;
const CHAR_LESS_THAN as UByte = 60         ' <
const CHAR_EQUALS as UByte = 61            ' =
const CHAR_GREATER_THAN as UByte = 62      ' >
const CHAR_QUESTION as UByte = 63          ' ?
const CHAR_AT as UByte = 64                ' @
const CHAR_A as UByte = 65                 ' A
const CHAR_B as UByte = 66                 ' B
const CHAR_C as UByte = 67                 ' C
const CHAR_D as UByte = 68                 ' D
const CHAR_E as UByte = 69                 ' E
const CHAR_F as UByte = 70                 ' F
const CHAR_G as UByte = 71                 ' G
const CHAR_H as UByte = 72                 ' H
const CHAR_I as UByte = 73                 ' I
const CHAR_J as UByte = 74                 ' J
const CHAR_K as UByte = 75                 ' K
const CHAR_L as UByte = 76                 ' L
const CHAR_M as UByte = 77                 ' M
const CHAR_N as UByte = 78                 ' N
const CHAR_O as UByte = 79                 ' O
const CHAR_P as UByte = 80                 ' P
const CHAR_Q as UByte = 81                 ' Q
const CHAR_R as UByte = 82                 ' R
const CHAR_S as UByte = 83                 ' S
const CHAR_T as UByte = 84                 ' T
const CHAR_U as UByte = 85                 ' U
const CHAR_V as UByte = 86                 ' V
const CHAR_W as UByte = 87                 ' W
const CHAR_X as UByte = 88                 ' X
const CHAR_Y as UByte = 89                 ' Y
const CHAR_Z as UByte = 90                 ' Z
const CHAR_LBRACKET as UByte = 91          ' [
const CHAR_BACKSLASH as UByte = 92         ' backslash
const CHAR_RBRACKET as UByte = 93          ' ]
const CHAR_CARET as UByte = 94             ' ^
const CHAR_UNDERSCORE as UByte = 95        ' _
const CHAR_LC_A as UByte = 97              ' a
const CHAR_LC_B as UByte = 98              ' b
const CHAR_LC_C as UByte = 99              ' c
const CHAR_LC_D as UByte = 100             ' d
const CHAR_LC_E as UByte = 101             ' e
const CHAR_LC_F as UByte = 102             ' f
const CHAR_LC_G as UByte = 103             ' g
const CHAR_LC_H as UByte = 104             ' h
const CHAR_LC_I as UByte = 105             ' i
const CHAR_LC_J as UByte = 106             ' j
const CHAR_LC_K as UByte = 107             ' k
const CHAR_LC_L as UByte = 108             ' l
const CHAR_LC_M as UByte = 109             ' m
const CHAR_LC_N as UByte = 110             ' n
const CHAR_LC_O as UByte = 111             ' o
const CHAR_LC_P as UByte = 112             ' p
const CHAR_LC_Q as UByte = 113             ' q
const CHAR_LC_R as UByte = 114             ' r
const CHAR_LC_S as UByte = 115             ' s
const CHAR_LC_T as UByte = 116             ' t
const CHAR_LC_U as UByte = 117             ' u
const CHAR_LC_V as UByte = 118             ' v
const CHAR_LC_W as UByte = 119             ' w
const CHAR_LC_X as UByte = 120             ' x
const CHAR_LC_Y as UByte = 121             ' y
const CHAR_LC_Z as UByte = 122             ' z
const CHAR_LBRACE as UByte = 123           ' {
const CHAR_PIPE as UByte = 124             ' |
const CHAR_RBRACE as UByte = 125           ' }
const CHAR_TILDE as UByte = 126            ' ~

enum ValueKind
  VK_SCALAR = 0
  VK_ARRAY = 1
end enum

enum ScalarStorageKind
  SSK_FLOATINGPOINT = 0
  SSK_INT64 = 1
  SSK_UINT64 = 2
  SSK_TIME = 3
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

declare function ScalarIsTime(byref sv as ScalarValue) as Boolean
declare function TimeTotalMsFromScalarValue(byref sv as ScalarValue) as LongInt
declare function FormatTimeCanonicalFromMs(byval totalMs as LongInt) as String
declare sub ValueSetTimeMs(byref v as EvalValue, byval totalMs as LongInt)
declare function ApplyTimeBinaryScalars(byref leftS as ScalarValue, byref rightS as ScalarValue, byval op as UByte, byref outV as EvalValue) as Boolean

type VarEntry
  name as String
  value as EvalValue
end type

type FuncEntry
  name as String
  params(any) as String
  expr as String
end type

#define __FB_FUNC_VARS_OVERRIDE_GLOBALS__ 1
'
'  With a fixed formal probe of 0, `f(x)=1%x` fails validation (mod 0).
'  With 1, `f(x)=1%(x-1)` can fail (again, mode 0).
'  When this define is enabled, each formal parameter is given the value
'  of scalar variable `_` during UDF body validation if `_` exists,
'  otherwise the default probe 1.
'  Example: `_=10; f(x)=1%(x-1)` passes the validation.
'  Runtime calls still use real arguments.
'
'  Without this define, `x=1; f(x)=1%x` and `x=2; f(x)=1%(x-1)` work by
'  seeding x.
'  Expressions like `x=0.5; f(x)=x<<2` would fail during the validation.
'  But it can be solved in either way:
'  `x=0.5; f(x_)=x_<<2` would work.
'  `x=1; f(x)=x<<2` would work.

dim shared variables() as VarEntry
dim shared userFunctions() as FuncEntry
dim shared pStream as ZString ptr
dim shared parseError as Integer
dim shared wasPercentage as Boolean
dim shared lastErrorText as String
dim shared unknownVarsText as String
dim shared unknownFuncsText as String
#ifdef __FB_FUNC_VARS_OVERRIDE_GLOBALS__
dim shared functionVariableNames() as String
dim shared functionVariableCount as Integer
#endif
dim shared evalDepth as Integer
const UDF_CALL_STACK_MAX as Integer = 128
dim shared udfCallStack(0 to UDF_CALL_STACK_MAX - 1) as String
dim shared udfCallStackSp as Integer
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
      dim locationPart as String = FB_STR_AT
      if Parser_ShowErrorLine then locationPart = locationPart & FB_STR_LINE_1_PREFIX
      locationPart = locationPart & FB_STR_COL & ltrim(str(col)) & FB_STR_COLON
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
    listText &= FB_STR_COMMA & n
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
  FUNC_ACOS
  FUNC_ATAN
  FUNC_SINH
  FUNC_COSH
  FUNC_TANH
  FUNC_ACOSH
  FUNC_ASINH
  FUNC_ATANH
  FUNC_EXP
  FUNC_LOG
  FUNC_LN
  FUNC_LOG10
  FUNC_SQRT
  FUNC_SQR
  FUNC_INT
  FUNC_FRAC
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
  FUNC_REVERSE
  FUNC_UNIQUE
  FUNC_UNPACK
  FUNC_FACT
  FUNC_AVG
  FUNC_MEAN
  FUNC_MOD
  FUNC_CLAMP
  FUNC_HYPOT
  FUNC_GCD
  FUNC_LCM
  FUNC_NCR
  FUNC_NPR
  FUNC_PRODUCT
  FUNC_MIN
  FUNC_MAX
  FUNC_UHEX
  FUNC_UOCT
  FUNC_UBIN
  FUNC_MILLISECONDS
  FUNC_SECONDS
  FUNC_MINUTES
  FUNC_HOURS
  FUNC_DAYS
  FUNC__COUNT
end enum

enum OperatorNameId
  OP_NOT = 0
  OP_AND
  OP_OR
  OP_MOD
  OP__COUNT
end enum

enum OperatorCmpNameId
  OP_CMP_NONE = 0
  OP_CMP_EQ  ' =, ==
  OP_CMP_NE  ' <>, !=
  OP_CMP_LT  ' <
  OP_CMP_GT  ' >
  OP_CMP_LE  ' <=
  OP_CMP_GE  ' >=
  OP_CMP__COUNT
end enum

enum OperatorBitNameId
  OP_BIT_NONE = 0
  OP_BIT_AND  ' &
  OP_BIT_OR   ' |
  OP_BIT_XOR  ' ^
  OP_BIT_SHL  ' <<
  OP_BIT_SHR  ' >>
  OP_BIT_MOD  ' % (mod)
  OP_BIT__COUNT
end enum

enum BuiltinConstId
  CONST_PI = 0
  CONST_E
  CONST_INF
  CONST_NAN
  CONST_MILLISECOND
  CONST_SECOND
  CONST_MINUTE
  CONST_HOUR
  CONST_DAY
  CONST__COUNT
end enum

dim shared FunctionNames(0 to FUNC__COUNT - 1) as String
dim shared OperatorNames(0 to OP__COUNT - 1) as String
dim shared ConstNames(0 to CONST__COUNT - 1) as String
dim shared FunctionNamesInitialized as Boolean = FALSE
dim shared OperatorNamesInitialized as Boolean = FALSE
dim shared ConstNamesInitialized as Boolean = FALSE
const BUILTIN_FN_LOOKUP_CAPACITY as Integer = 127
dim shared BuiltinFnLookupKeys(0 to BUILTIN_FN_LOOKUP_CAPACITY - 1) as String
dim shared BuiltinFnLookupIds(0 to BUILTIN_FN_LOOKUP_CAPACITY - 1) as Integer
dim shared BuiltinFnLookupInitialized as Boolean = FALSE
const BUILTIN_CONST_LOOKUP_CAPACITY as Integer = 32
dim shared BuiltinConstLookupKeys(0 to BUILTIN_CONST_LOOKUP_CAPACITY - 1) as String
dim shared BuiltinConstLookupIds(0 to BUILTIN_CONST_LOOKUP_CAPACITY - 1) as Integer
dim shared BuiltinConstLookupInitialized as Boolean = FALSE

private sub EnsureFunctionNames()
  if FunctionNamesInitialized then exit sub
  FunctionNames(FUNC_RAND) = FB_STR_RAND
  FunctionNames(FUNC_RANDOM) = FB_STR_RANDOM
  FunctionNames(FUNC_BIN) = FB_STR_BIN
  FunctionNames(FUNC_HEX) = FB_STR_HEX
  FunctionNames(FUNC_OCT) = FB_STR_OCT
  FunctionNames(FUNC_POW) = FB_STR_POW
  FunctionNames(FUNC_ATAN2) = FB_STR_ATAN2
  FunctionNames(FUNC_SIN) = FB_STR_SIN
  FunctionNames(FUNC_COS) = FB_STR_COS
  FunctionNames(FUNC_TAN) = FB_STR_TAN
  FunctionNames(FUNC_ASIN) = FB_STR_ASIN
  FunctionNames(FUNC_ACOS) = FB_STR_ACOS
  FunctionNames(FUNC_ATAN) = FB_STR_ATAN
  FunctionNames(FUNC_SINH) = FB_STR_SINH
  FunctionNames(FUNC_COSH) = FB_STR_COSH
  FunctionNames(FUNC_TANH) = FB_STR_TANH
  FunctionNames(FUNC_ACOSH) = FB_STR_ACOSH
  FunctionNames(FUNC_ASINH) = FB_STR_ASINH
  FunctionNames(FUNC_ATANH) = FB_STR_ATANH
  FunctionNames(FUNC_EXP) = FB_STR_EXP
  FunctionNames(FUNC_LOG) = FB_STR_LOG
  FunctionNames(FUNC_LN) = FB_STR_LN
  FunctionNames(FUNC_LOG10) = FB_STR_LOG10
  FunctionNames(FUNC_SQRT) = FB_STR_SQRT
  FunctionNames(FUNC_SQR) = FB_STR_SQR
  FunctionNames(FUNC_INT) = FB_STR_INT
  FunctionNames(FUNC_FRAC) = FB_STR_FRAC
  FunctionNames(FUNC_ABS) = FB_STR_ABS
  FunctionNames(FUNC_FLOOR) = FB_STR_FLOOR
  FunctionNames(FUNC_CEIL) = FB_STR_CEIL
  FunctionNames(FUNC_TRUNC) = FB_STR_TRUNC
  FunctionNames(FUNC_ROUND) = FB_STR_ROUND
  FunctionNames(FUNC_SIGN) = FB_STR_SIGN
  FunctionNames(FUNC_DEG) = FB_STR_DEG
  FunctionNames(FUNC_RAD) = FB_STR_RAD
  FunctionNames(FUNC_SUM) = FB_STR_SUM
  FunctionNames(FUNC_MEDIAN) = FB_STR_MEDIAN
  FunctionNames(FUNC_VARIANCE) = FB_STR_VARIANCE
  FunctionNames(FUNC_STDDEV) = FB_STR_STDDEV
  FunctionNames(FUNC_SORT) = FB_STR_SORT
  FunctionNames(FUNC_REVERSE) = FB_STR_REVERSE
  FunctionNames(FUNC_UNIQUE) = FB_STR_UNIQUE
  FunctionNames(FUNC_UNPACK) = FB_STR_UNPACK
  FunctionNames(FUNC_FACT) = FB_STR_FACT
  FunctionNames(FUNC_AVG) = FB_STR_AVG
  FunctionNames(FUNC_MEAN) = FB_STR_MEAN
  FunctionNames(FUNC_MOD) = FB_STR_MOD
  FunctionNames(FUNC_CLAMP) = FB_STR_CLAMP
  FunctionNames(FUNC_HYPOT) = FB_STR_HYPOT
  FunctionNames(FUNC_GCD) = FB_STR_GCD
  FunctionNames(FUNC_LCM) = FB_STR_LCM
  FunctionNames(FUNC_NCR) = FB_STR_NCR
  FunctionNames(FUNC_NPR) = FB_STR_NPR
  FunctionNames(FUNC_PRODUCT) = FB_STR_PRODUCT
  FunctionNames(FUNC_MIN) = FB_STR_MIN
  FunctionNames(FUNC_MAX) = FB_STR_MAX
  FunctionNames(FUNC_UHEX) = FB_STR_UHEX
  FunctionNames(FUNC_UOCT) = FB_STR_UOCT
  FunctionNames(FUNC_UBIN) = FB_STR_UBIN
  FunctionNames(FUNC_MILLISECONDS) = FB_STR_MILLISECONDS
  FunctionNames(FUNC_SECONDS) = FB_STR_SECONDS
  FunctionNames(FUNC_MINUTES) = FB_STR_MINUTES
  FunctionNames(FUNC_HOURS) = FB_STR_HOURS
  FunctionNames(FUNC_DAYS) = FB_STR_DAYS
  FunctionNamesInitialized = TRUE
end sub

private function HashLowerIdent(byref s as String) as UInteger
  dim h as UInteger = 2166136261u
  dim i as Integer
  for i = 1 to len(s)
    h xor= asc(mid(s, i, 1))
    h *= 16777619u
  next i
  return h
end function

private sub InsertBuiltinFnAliasLookup(byref aliasKey as String, byval id as Integer)
  dim slot as Integer = CInt(HashLowerIdent(aliasKey) mod BUILTIN_FN_LOOKUP_CAPACITY)
  dim probed as Integer
  for probed = 0 to BUILTIN_FN_LOOKUP_CAPACITY - 1
    if BuiltinFnLookupKeys(slot) = "" then
      BuiltinFnLookupKeys(slot) = aliasKey
      BuiltinFnLookupIds(slot) = id
      exit sub
    elseif BuiltinFnLookupKeys(slot) = aliasKey then
      exit sub
    end if
    slot = (slot + 1) mod BUILTIN_FN_LOOKUP_CAPACITY
  next probed
end sub

private sub EnsureBuiltinFunctionLookup()
  if BuiltinFnLookupInitialized then exit sub
  EnsureFunctionNames()
  dim i as Integer
  for i = 0 to BUILTIN_FN_LOOKUP_CAPACITY - 1
    BuiltinFnLookupKeys(i) = ""
    BuiltinFnLookupIds(i) = -1
  next i
  for i = 0 to FUNC__COUNT - 1
    dim key as String = FunctionNames(i)
    dim slot as Integer = CInt(HashLowerIdent(key) mod BUILTIN_FN_LOOKUP_CAPACITY)
    do while BuiltinFnLookupKeys(slot) <> ""
      slot = (slot + 1) mod BUILTIN_FN_LOOKUP_CAPACITY
    loop
    BuiltinFnLookupKeys(slot) = key
    BuiltinFnLookupIds(slot) = i
  next i
  InsertBuiltinFnAliasLookup FB_STR_ARCSIN, FUNC_ASIN
  InsertBuiltinFnAliasLookup FB_STR_ARCCOS, FUNC_ACOS
  InsertBuiltinFnAliasLookup FB_STR_ARCTAN, FUNC_ATAN
  InsertBuiltinFnAliasLookup FB_STR_FRACT, FUNC_FRAC
  InsertBuiltinFnAliasLookup FB_STR_SORTED, FUNC_SORT
  InsertBuiltinFnAliasLookup FB_STR_REVERSED, FUNC_REVERSE
  InsertBuiltinFnAliasLookup FB_STR_FACTORIAL, FUNC_FACT
  InsertBuiltinFnAliasLookup FB_STR_PROD, FUNC_PRODUCT
  BuiltinFnLookupInitialized = TRUE
end sub

private sub EnsureOperatorNames()
  if OperatorNamesInitialized then exit sub
  OperatorNames(OP_NOT) = FB_STR_NOT
  OperatorNames(OP_AND) = FB_STR_AND
  OperatorNames(OP_OR) = FB_STR_OR
  OperatorNames(OP_MOD) = FB_STR_MOD
  OperatorNamesInitialized = TRUE
end sub

'' Spelling for each BuiltinConstId; keep TryGetConstant in sync when adding constants.
private sub EnsureConstNames()
  if ConstNamesInitialized then exit sub
  ConstNames(CONST_PI) = FB_STR_PI
  ConstNames(CONST_E) = FB_STR_E
  ConstNames(CONST_INF) = FB_STR_INF
  ConstNames(CONST_NAN) = FB_STR_NAN
  ConstNames(CONST_MILLISECOND) = FB_STR_MILLISECOND
  ConstNames(CONST_SECOND) = FB_STR_SECOND
  ConstNames(CONST_MINUTE) = FB_STR_MINUTE
  ConstNames(CONST_HOUR) = FB_STR_HOUR
  ConstNames(CONST_DAY) = FB_STR_DAY
  ConstNamesInitialized = TRUE
end sub

private sub EnsureBuiltinConstLookup()
  if BuiltinConstLookupInitialized then exit sub
  EnsureConstNames()
  dim i as Integer
  for i = 0 to BUILTIN_CONST_LOOKUP_CAPACITY - 1
    BuiltinConstLookupKeys(i) = ""
    BuiltinConstLookupIds(i) = -1
  next i
  for i = 0 to CONST__COUNT - 1
    dim key as String = ConstNames(i)
    dim slot as Integer = CInt(HashLowerIdent(key) mod BUILTIN_CONST_LOOKUP_CAPACITY)
    do while BuiltinConstLookupKeys(slot) <> ""
      slot = (slot + 1) mod BUILTIN_CONST_LOOKUP_CAPACITY
    loop
    BuiltinConstLookupKeys(slot) = key
    BuiltinConstLookupIds(slot) = i
  next i
  BuiltinConstLookupInitialized = TRUE
end sub

private function TryFindBuiltinConstId(byref n as String) as Integer
  EnsureBuiltinConstLookup()
  dim low as String = lcase(n)
  dim slot as Integer = CInt(HashLowerIdent(low) mod BUILTIN_CONST_LOOKUP_CAPACITY)
  dim probed as Integer
  for probed = 0 to BUILTIN_CONST_LOOKUP_CAPACITY - 1
    if BuiltinConstLookupKeys(slot) = "" then return -1
    if BuiltinConstLookupKeys(slot) = low then return BuiltinConstLookupIds(slot)
    slot = (slot + 1) mod BUILTIN_CONST_LOOKUP_CAPACITY
  next probed
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

declare function TryFindBuiltinFunctionId(byref nameText as String) as Integer

private function IsOpKeyword(byref nameText as String, byval id as OperatorNameId) as Boolean
  return lcase(nameText) = OpName(id)
end function

private const BUILTIN_FLAG_UNARY as UInteger = 1u shl 0
private const BUILTIN_FLAG_FORMAT as UInteger = 1u shl 1
private const BUILTIN_FLAG_INTEGER_ONLY as UInteger = 1u shl 2
private const BUILTIN_FLAG_NON_CALCULATING as UInteger = 1u shl 3
private const BUILTIN_FLAG_FINITE_REQUIRED as UInteger = 1u shl 4
private const BUILTIN_FLAG_TRAILING_FORMATTER as UInteger = 1u shl 5

private function GetBuiltinFlags(byval id as Integer) as UInteger
  select case id
    case FUNC_SIN, FUNC_COS, FUNC_TAN, FUNC_ASIN, FUNC_ACOS, FUNC_ATAN, _
         FUNC_SINH, FUNC_COSH, FUNC_TANH, FUNC_ACOSH, FUNC_ASINH, FUNC_ATANH, FUNC_EXP, FUNC_LN, FUNC_LOG10, FUNC_SQRT, FUNC_SQR, _
         FUNC_INT, FUNC_FLOOR, FUNC_CEIL, FUNC_TRUNC, FUNC_ROUND, FUNC_FRAC, FUNC_ABS, FUNC_SIGN
      return BUILTIN_FLAG_UNARY
    case FUNC_DEG, FUNC_RAD
      return BUILTIN_FLAG_UNARY or BUILTIN_FLAG_TRAILING_FORMATTER
    case FUNC_HEX, FUNC_OCT, FUNC_BIN, FUNC_UHEX, FUNC_UOCT, FUNC_UBIN
      return BUILTIN_FLAG_FORMAT or BUILTIN_FLAG_NON_CALCULATING or BUILTIN_FLAG_TRAILING_FORMATTER
    case FUNC_GCD, FUNC_LCM, FUNC_NCR, FUNC_NPR, FUNC_MOD, FUNC_FACT
      return BUILTIN_FLAG_INTEGER_ONLY
    case FUNC_UNPACK, FUNC_SORT, FUNC_REVERSE, FUNC_UNIQUE, FUNC_RAND
      return BUILTIN_FLAG_NON_CALCULATING
    case FUNC_RANDOM
      return BUILTIN_FLAG_FINITE_REQUIRED
  end select
  return 0u
end function

private function HasBuiltinFlag(byval id as Integer, byval flagMask as UInteger) as Boolean
  return (GetBuiltinFlags(id) and flagMask) <> 0u
end function

private function IsUnaryBuiltin(byref fn as String) as Boolean
  dim id as Integer = TryFindBuiltinFunctionId(lcase(fn))
  return HasBuiltinFlag(id, BUILTIN_FLAG_UNARY)
end function

enum BuiltinHintKind
  BHK_NONE = 0
  BHK_EMPTY_PAR
  BHK_MIN_MAX
  BHK_DOTDOTDOT
  BHK_VALUE_POWER
  BHK_Y_X
  BHK_ANGLE
  BHK_VALUE
  BHK_VALUE_BASE
  BHK_N
  BHK_VALUE_DIVISOR
  BHK_VALUE_MIN_MAX
  BHK_X_Y
  BHK_A_B
  BHK_N_R
end enum

private function GetBuiltinHintKind(byval id as Integer) as BuiltinHintKind
  select case id
    case FUNC_RAND: return BHK_EMPTY_PAR
    case FUNC_RANDOM: return BHK_MIN_MAX
    case FUNC_BIN, FUNC_HEX, FUNC_OCT, FUNC_UBIN, FUNC_UHEX, FUNC_UOCT: return BHK_DOTDOTDOT
    case FUNC_POW: return BHK_VALUE_POWER
    case FUNC_ATAN2: return BHK_Y_X
    case FUNC_SIN, FUNC_COS, FUNC_TAN: return BHK_ANGLE
    case FUNC_ASIN, FUNC_ACOS, FUNC_ATAN
      return BHK_VALUE
    case FUNC_SINH, FUNC_COSH, FUNC_TANH, FUNC_ACOSH, FUNC_ASINH, FUNC_ATANH, FUNC_EXP, FUNC_LN, FUNC_LOG10, FUNC_SQRT, FUNC_SQR, FUNC_INT, FUNC_ABS, FUNC_FLOOR, FUNC_CEIL, FUNC_TRUNC, FUNC_ROUND, FUNC_SIGN
      return BHK_VALUE
    case FUNC_FRAC: return BHK_VALUE
    case FUNC_LOG: return BHK_VALUE_BASE
    case FUNC_MILLISECONDS, FUNC_SECONDS, FUNC_MINUTES, FUNC_HOURS, FUNC_DAYS: return BHK_VALUE
    case FUNC_DEG, FUNC_RAD, FUNC_SUM, FUNC_MEDIAN, FUNC_VARIANCE, FUNC_STDDEV, FUNC_UNIQUE, FUNC_UNPACK, FUNC_AVG, FUNC_MEAN, FUNC_PRODUCT, FUNC_MIN, FUNC_MAX, FUNC_SORT, FUNC_REVERSE
      return BHK_DOTDOTDOT
    case FUNC_FACT: return BHK_N
    case FUNC_MOD: return BHK_VALUE_DIVISOR
    case FUNC_CLAMP: return BHK_VALUE_MIN_MAX
    case FUNC_HYPOT: return BHK_X_Y
    case FUNC_GCD, FUNC_LCM: return BHK_A_B
    case FUNC_NCR, FUNC_NPR: return BHK_N_R
  end select
  return BHK_NONE
end function

private function GetBuiltinHintDisplayName(byval id as Integer, byref lowFn as String) as String
  select case id
    case FUNC_ASIN
      if lowFn = FB_STR_ARCSIN then return GetFunctionName(FUNC_ASIN)
    case FUNC_ACOS
      if lowFn = FB_STR_ARCCOS then return GetFunctionName(FUNC_ACOS)
    case FUNC_ATAN
      if lowFn = FB_STR_ARCTAN then return GetFunctionName(FUNC_ATAN)
    case FUNC_FRAC
      if lowFn = FB_STR_FRACT then return GetFunctionName(FUNC_FRAC)
    case FUNC_SORT
      if lowFn = FB_STR_SORTED then return GetFunctionName(FUNC_SORT)
    case FUNC_REVERSE
      if lowFn = FB_STR_REVERSED then return GetFunctionName(FUNC_REVERSE)
    case FUNC_FACT
      if lowFn = FB_STR_FACTORIAL then return GetFunctionName(FUNC_FACT)
    case FUNC_PRODUCT
      if lowFn = FB_STR_PROD then return GetFunctionName(FUNC_PRODUCT)
  end select
  return lowFn
end function

private function TryGetBuiltinSignatureHint(byref fn as String, byref hint as String) as Boolean
  dim lowFn as String = lcase(fn)
  dim id as Integer = TryFindBuiltinFunctionId(lowFn)
  if id < 0 then return FALSE
  dim kind as BuiltinHintKind = GetBuiltinHintKind(id)
  dim displayFn as String = GetBuiltinHintDisplayName(id, lowFn)
  select case kind
    case BHK_EMPTY_PAR: hint = GetFunctionName(id) & FB_STR_PAR
    case BHK_MIN_MAX: hint = GetFunctionName(id) & FB_STR_PAR_MIN_COMMA_MAX
    case BHK_DOTDOTDOT: hint = displayFn & FB_STR_PAR_DOTDOTDOT
    case BHK_VALUE_POWER: hint = GetFunctionName(id) & FB_STR_PAR_VALUE_COMMA_POWER
    case BHK_Y_X: hint = GetFunctionName(id) & FB_STR_PAR_Y_COMMA_X
    case BHK_ANGLE: hint = displayFn & FB_STR_PAR_ANGLE
    case BHK_VALUE: hint = displayFn & FB_STR_PAR_VALUE
    case BHK_VALUE_BASE: hint = GetFunctionName(id) & FB_STR_PAR_VALUE_COMMA_BASE
    case BHK_N: hint = GetFunctionName(id) & FB_STR_PAR_N
    case BHK_VALUE_DIVISOR: hint = GetFunctionName(id) & FB_STR_PAR_VALUE_COMMA_DIVISOR
    case BHK_VALUE_MIN_MAX: hint = GetFunctionName(id) & FB_STR_PAR_VALUE_COMMA_MIN_COMMA_MAX
    case BHK_X_Y: hint = GetFunctionName(id) & FB_STR_PAR_X_COMMA_Y
    case BHK_A_B: hint = lowFn & FB_STR_PAR_A_COMMA_B
    case BHK_N_R: hint = lowFn & FB_STR_PAR_N_COMMA_R
    case else: return FALSE
  end select
  return TRUE
end function

private function IsLogicalBinaryOperatorKeyword(byref nameText as String) as Boolean
  return IsOpKeyword(nameText, OP_AND) orelse IsOpKeyword(nameText, OP_OR)
end function

private function IsReservedOperatorKeyword(byref nameText as String) as Boolean
  return IsOpKeyword(nameText, OP_NOT) orelse IsLogicalBinaryOperatorKeyword(nameText)
end function

private function TryFindBuiltinFunctionId(byref nameText as String) as Integer
  EnsureBuiltinFunctionLookup()
  dim lowName as String = lcase(nameText)
  dim slot as Integer = CInt(HashLowerIdent(lowName) mod BUILTIN_FN_LOOKUP_CAPACITY)
  dim probed as Integer
  for probed = 0 to BUILTIN_FN_LOOKUP_CAPACITY - 1
    if BuiltinFnLookupKeys(slot) = "" then return -1
    if BuiltinFnLookupKeys(slot) = lowName then return BuiltinFnLookupIds(slot)
    slot = (slot + 1) mod BUILTIN_FN_LOOKUP_CAPACITY
  next probed
  return -1
end function

private function IsBuiltinFunctionName(byref nameText as String) as Boolean
  return (TryFindBuiltinFunctionId(nameText) >= 0)
end function

private function IsReservedUserFunctionName(byref nameText as String) as Boolean
  if IsBuiltinFunctionName(nameText) then return TRUE
  if IsReservedOperatorKeyword(nameText) then return TRUE
  return FALSE
end function

private function IsReservedBuiltinVariableNameForUserFunction(byref nameText as String) as Boolean
  if lcase(nameText) = FB_STR_ANS then return TRUE
  if nameText = FB_STR_FORMAL_VALIDATION_PROBE then return TRUE
  return FALSE
end function

private function IsTrailingFormatterFunctionName(byref nameText as String) as Boolean
  dim lowName as String = lcase(nameText)
  dim id as Integer = TryFindBuiltinFunctionId(lowName)
  return HasBuiltinFlag(id, BUILTIN_FLAG_TRAILING_FORMATTER)
end function

private function TryRewriteTrailingFormatterStmt(byref stmt as String, byref rewritten as String) as Boolean
  dim s as String = trim(stmt)
  if len(s) = 0 then return FALSE
  dim p as ZString ptr = strptr(s)
  dim n as Integer = len(s)
  dim i as Integer = 0
  dim ch as UByte = p[i]
  if not ((ch >= asc("A") andalso ch <= asc("Z")) orelse (ch >= asc("a") andalso ch <= asc("z")) orelse ch = asc("_")) then return FALSE
  while i < n
    ch = p[i]
    if (ch >= asc("A") andalso ch <= asc("Z")) orelse (ch >= asc("a") andalso ch <= asc("z")) orelse (ch >= asc("0") andalso ch <= asc("9")) orelse ch = asc("_") then
      i += 1
    else
      exit while
    end if
  wend
  dim fnName as String = left(s, i)
  if IsTrailingFormatterFunctionName(fnName) = FALSE then return FALSE
  while i < n andalso (p[i] = asc(" ") orelse p[i] = 9)
    i += 1
  wend
  dim rest as String = mid(s, i + 1)
  if len(rest) = 0 then
    rewritten = lcase(fnName) & FB_STR_PAR_ANS
    return TRUE
  end if
  if rest[0] <> CHAR_LPAREN then return FALSE
  dim rp as ZString ptr = strptr(rest)
  dim rLen as Integer = len(rest)
  dim rPos as Integer = 1
  while rPos < rLen
    ch = rp[rPos]
    if ch = asc(" ") orelse ch = 9 then
      rPos += 1
    else
      exit while
    end if
  wend
  if rPos >= rLen orelse rp[rPos] <> CHAR_RPAREN then return FALSE
  rPos += 1
  while rPos < rLen
    ch = rp[rPos]
    if ch = asc(" ") orelse ch = 9 then
      rPos += 1
    else
      return FALSE
    end if
  wend
  rewritten = lcase(fnName) & FB_STR_PAR_ANS
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

private function quickMult10(byval x as ULongInt) as ULongInt
  ' x*10 = x*(8+2) = x*8 + x*2 = (x<<3) + (x<<1)
  return (x shl 3) + (x shl 1)
end function

private function mult10_N_times(byval x as ULongInt, byval N as Integer) as ULongInt
  dim i as Integer
  for i = 1 to N
    x = quickMult10(x)
  next i
  return x
end function

private function TryMult10OnceChecked(byval x as ULongInt, byref outV as ULongInt) as Boolean
  if x > (FB_U64_MAX \ 10ull) then return FALSE
  outV = quickMult10(x)
  return TRUE
end function

private function TryMult10_N_TimesChecked(byval x as ULongInt, byval N as Integer, byref outV as ULongInt) as Boolean
  dim i as Integer
  outV = x
  for i = 1 to N
    if TryMult10OnceChecked(outV, outV) = FALSE then return FALSE
  next i
  return TRUE
end function

private function TryAddULongChecked(byval a as ULongInt, byval b as ULongInt, byref outV as ULongInt) as Boolean
  if a > (FB_U64_MAX - b) then return FALSE
  outV = a + b
  return TRUE
end function

private function TryMulULongChecked(byval a as ULongInt, byval b as ULongInt, byref outV as ULongInt) as Boolean
  if b <> 0ull andalso a > (FB_U64_MAX \ b) then return FALSE
  outV = a * b
  return TRUE
end function

private function MakeNaN() as Double
  return 0.0 / 0.0
end function

private function IsNaNValue(byval d as Double) as Boolean
  return (_isnan(d) <> 0)
end function

private function IsInfValue(byval d as Double) as Boolean
  if _isnan(d) <> 0 then return FALSE
  dim infV as Double = 1.0 / 0.0
  return abs(d) = infV
end function

private function IsNonFiniteValue(byval d as Double) as Boolean
  return IsNaNValue(d) orelse IsInfValue(d)
end function

private function IsFiniteValue(byval d as Double) as Boolean
  if IsNaNValue(d) then return FALSE
  if IsInfValue(d) then return FALSE
  return TRUE
end function

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

private sub ValueSetUInt64(byref v as EvalValue, byval n as ULongInt)
  ValueSetScalar(v, CDbl(n))
  v.scalarStorageKind = SSK_UINT64
  v.exactUInt64Valid = TRUE
  v.exactUInt64 = n
  if n <= FB_I64_MAX_U then
    v.exactInt64Valid = TRUE
    v.exactInt64 = CLngInt(n)
  end if
end sub

private function TryGetExactInt64FromDouble(byval n as Double, byref outV as LongInt) as Boolean
  if IsNonFiniteValue(n) then return FALSE
  if n < -FB_MAX_EXACT_INT_FROM_DOUBLE orelse n > FB_MAX_EXACT_INT_FROM_DOUBLE then return FALSE
  if n < FB_I64_MIN_D orelse n > FB_I64_MAX_D then return FALSE
  dim t as LongInt = CLngInt(n)
  if n <> CDbl(t) then return FALSE
  outV = t
  return TRUE
end function

'' If n rounds to an exact LongInt in IEEE double, attach the same metadata as ValueSetInt64.
private sub ValueSetScalarPromoteExactInt64(byref v as EvalValue, byval n as Double)
  ValueSetScalar(v, n)
  dim t as LongInt
  if TryGetExactInt64FromDouble(n, t) then
    v.scalarStorageKind = SSK_INT64
    v.exactInt64Valid = TRUE
    v.exactInt64 = t
    if t >= 0 then
      v.exactUInt64Valid = TRUE
      v.exactUInt64 = CULngInt(t)
    end if
  end if
end sub

private function TryGetExactInt64(byref v as EvalValue, byref outV as LongInt) as Boolean
  if v.kind <> VK_SCALAR then return FALSE
  if v.exactInt64Valid then
    outV = v.exactInt64
    return TRUE
  end if
  if v.exactUInt64Valid then
    outV = CLngInt(v.exactUInt64)
    return TRUE
  end if
  return TryGetExactInt64FromDouble(v.scalar, outV)
end function

private function TryGetExactInt64Scalar(byref s as ScalarValue, byref outV as LongInt) as Boolean
  if s.exactInt64Valid then
    outV = s.exactInt64
    return TRUE
  end if
  if s.exactUInt64Valid then
    outV = CLngInt(s.exactUInt64)
    return TRUE
  end if
  return TryGetExactInt64FromDouble(s.scalar, outV)
end function

private function TryGetExactNonNegativeUInt64Scalar(byref s as ScalarValue, byref outV as ULongInt) as Boolean
  if s.exactUInt64Valid then
    outV = s.exactUInt64
    return TRUE
  end if
  if s.exactInt64Valid andalso s.exactInt64 >= 0 then
    outV = CULngInt(s.exactInt64)
    return TRUE
  end if
  return FALSE
end function

'' Exact signed int64, including from uint64 metadata only when value fits LLONG_MAX (no wrap).
private function TryGetExactSignedInt64NoUIntWrapScalar(byref s as ScalarValue, byref outV as LongInt) as Boolean
  if s.exactInt64Valid then
    outV = s.exactInt64
    return TRUE
  end if
  if s.exactUInt64Valid andalso s.exactUInt64 <= FB_I64_MAX_U then
    outV = CLngInt(s.exactUInt64)
    return TRUE
  end if
  return TryGetExactInt64FromDouble(s.scalar, outV)
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
  if (b > 0 andalso a > FB_I64_MAX - b) orelse (b < 0 andalso a < FB_I64_MIN - b) then return FALSE
  outV = a + b
  return TRUE
end function

private function TrySubInt64(byval a as LongInt, byval b as LongInt, byref outV as LongInt) as Boolean
  if (b < 0 andalso a > FB_I64_MAX + b) orelse (b > 0 andalso a < FB_I64_MIN + b) then return FALSE
  outV = a - b
  return TRUE
end function

private function TryMulInt64(byval a as LongInt, byval b as LongInt, byref outV as LongInt) as Boolean
  if a = 0 orelse b = 0 then outV = 0: return TRUE
  if a = -1 then
    if b = FB_I64_MIN then return FALSE
    outV = -b
    return TRUE
  end if
  if b = -1 then
    if a = FB_I64_MIN then return FALSE
    outV = -a
    return TRUE
  end if
  if a > 0 then
    if b > 0 then
      if a > FB_I64_MAX \ b then return FALSE
    else
      if b < FB_I64_MIN \ a then return FALSE
    end if
  else
    if b > 0 then
      if a < FB_I64_MIN \ b then return FALSE
    else
      if a <> 0 andalso b < FB_I64_MAX \ a then return FALSE
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

private function TryPowULong(byval baseV as ULongInt, byval expV as ULongInt, byref outV as ULongInt) as Boolean
  dim r as ULongInt = 1
  dim b as ULongInt = baseV
  dim e as ULongInt = expV
  while e > 0ull
    if (e and 1ull) <> 0ull then
      if TryMulULongChecked(r, b, r) = FALSE then return FALSE
    end if
    e = e shr 1
    if e > 0ull then
      if TryMulULongChecked(b, b, b) = FALSE then return FALSE
    end if
  wend
  outV = r
  return TRUE
end function

private function FormatSignedMagnitudeBase(byval iv as LongInt, byval baseN as Integer, byval asUnsigned as Boolean) as String
  dim prefix as String
  select case baseN
    case 16: prefix = FB_STR_PREFIX_HEX
    case 8: prefix = FB_STR_PREFIX_OCT
    case else: prefix = FB_STR_PREFIX_BIN
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
  dim iv as LongInt
  if TryGetExactInt64FromDouble(n, iv) = FALSE then return FALSE
  outText = FormatSignedMagnitudeBase(iv, 16, asUnsigned)
  return TRUE
end function

private function FormatHexUInt64(byval u as ULongInt) as String
  return FB_STR_PREFIX_HEX & Hex(u)
end function

private function FormatBinScalar(byval n as Double, byref outText as String, byval asUnsigned as Boolean = FALSE) as Boolean
  dim iv as LongInt
  if TryGetExactInt64FromDouble(n, iv) = FALSE then return FALSE
  outText = FormatSignedMagnitudeBase(iv, 2, asUnsigned)
  return TRUE
end function

private function FormatBinUInt64(byval u as ULongInt) as String
  return FB_STR_PREFIX_BIN & Bin(u)
end function

private function FormatOctScalar(byval n as Double, byref outText as String, byval asUnsigned as Boolean = FALSE) as Boolean
  dim iv as LongInt
  if TryGetExactInt64FromDouble(n, iv) = FALSE then return FALSE
  outText = FormatSignedMagnitudeBase(iv, 8, asUnsigned)
  return TRUE
end function

private function FormatOctUInt64(byval u as ULongInt) as String
  return FB_STR_PREFIX_OCT & Oct(u)
end function

private function TryFormatScalarByRenderBase(byref sv as ScalarValue, byval renderBase as Integer, byval asUnsigned as Boolean, byref outText as String) as Boolean
  select case renderBase
    case 16
      if sv.exactUInt64Valid then
        outText = FormatHexUInt64(sv.exactUInt64)
        return TRUE
      end if
      if sv.exactInt64Valid then
        outText = FormatSignedMagnitudeBase(sv.exactInt64, 16, asUnsigned)
        return TRUE
      end if
      return FormatHexScalar(sv.scalar, outText, asUnsigned)
    case 8
      if sv.exactUInt64Valid then
        outText = FormatOctUInt64(sv.exactUInt64)
        return TRUE
      end if
      if sv.exactInt64Valid then
        outText = FormatSignedMagnitudeBase(sv.exactInt64, 8, asUnsigned)
        return TRUE
      end if
      return FormatOctScalar(sv.scalar, outText, asUnsigned)
    case 2
      if sv.exactUInt64Valid then
        outText = FormatBinUInt64(sv.exactUInt64)
        return TRUE
      end if
      if sv.exactInt64Valid then
        outText = FormatSignedMagnitudeBase(sv.exactInt64, 2, asUnsigned)
        return TRUE
      end if
      return FormatBinScalar(sv.scalar, outText, asUnsigned)
    case else
      return FALSE
  end select
end function

private function ULongIntToString(byval x as ULongInt) as String
  if x = 0 then return "0"
  dim s as String = ""
  while x > 0
    s = chr(48 + (x mod 10)) + s
    x \= 10
  wend
  return s
end function

private function ValueToString(byref v as EvalValue) as String
  if v.kind = VK_SCALAR then
    if IsNaNValue(v.scalar) then return "nan"
    if IsInfValue(v.scalar) then
      if v.scalar < 0 then return "-inf"
      return "inf"
    end if
    if v.scalarStorageKind = SSK_TIME then
      return FormatTimeCanonicalFromMs(TimeTotalMsFromScalarValue(v.scalarValue))
    end if
    dim fmtText as String
    if TryFormatScalarByRenderBase(v.scalarValue, v.renderBase, v.renderUnsigned, fmtText) then
      return fmtText
    end if
    if v.exactInt64Valid then return ltrim(str(v.exactInt64))
    if v.exactUInt64Valid then return ltrim(ULongIntToString(v.exactUInt64))
    return ltrim(str(v.scalar))
  end if

  dim s as String = "("
  dim i as Integer
  for i = lbound(v.arr) to ubound(v.arr)
    if i > lbound(v.arr) then s &= ", "
    dim sv as ScalarValue = v.arr(i)
    dim fmtText as String
    if TryFormatScalarByRenderBase(sv, v.renderBase, v.renderUnsigned, fmtText) then
      s &= fmtText
    elseif v.renderBase = 0 then
      if IsNaNValue(sv.scalar) then
        s &= "nan"
        continue for
      end if
      if IsInfValue(sv.scalar) then
        if sv.scalar < 0 then
          s &= "-inf"
        else
          s &= "inf"
        end if
        continue for
      end if
      if ScalarIsTime(sv) then
        s &= FormatTimeCanonicalFromMs(TimeTotalMsFromScalarValue(sv))
        continue for
      end if
      if sv.exactUInt64Valid then
        s &= ltrim(str(sv.exactUInt64))
      elseif sv.exactInt64Valid then
        s &= ltrim(str(sv.exactInt64))
      else
        s &= ltrim(str(sv.scalar))
      end if
    else
      if IsNaNValue(sv.scalar) then
        s &= "nan"
      elseif IsInfValue(sv.scalar) then
        if sv.scalar < 0 then
          s &= "-inf"
        else
          s &= "inf"
        end if
      elseif ScalarIsTime(sv) then
        s &= FormatTimeCanonicalFromMs(TimeTotalMsFromScalarValue(sv))
      else
        if sv.exactUInt64Valid then
          s &= ltrim(ULongIntToString(sv.exactUInt64))
        elseif sv.exactInt64Valid then
          s &= ltrim(str(sv.exactInt64))
        else
          s &= ltrim(str(sv.scalar))
        end if
      end if
    end if
  next i
  s &= ")"
  return s
end function

private sub SkipSpaces()
  while (pStream[0] = CHAR_SPACE) orelse (pStream[0] = CHAR_TAB) orelse (pStream[0] = CHAR_LF) orelse (pStream[0] = CHAR_CR)
    pStream += 1
  wend
end sub

private function IsIdentChar(byval ch as UByte) as Boolean
  return ((ch >= CHAR_A andalso ch <= CHAR_Z) orelse (ch >= CHAR_LC_A andalso ch <= CHAR_LC_Z) orelse (ch >= CHAR_DIGIT_0 andalso ch <= CHAR_DIGIT_9) orelse (ch = CHAR_UNDERSCORE))
end function

private function IsIdentStartChar(byval ch as Integer) as Boolean
  return ((ch >= CHAR_A andalso ch <= CHAR_Z) orelse (ch >= CHAR_LC_A andalso ch <= CHAR_LC_Z) orelse (ch = CHAR_UNDERSCORE))
end function

private function IsNumericLiteralStartChar(byval ch as Integer) as Boolean
  return ((ch >= CHAR_DIGIT_0 andalso ch <= CHAR_DIGIT_9) orelse (ch = CHAR_DOT))
end function

private function ToLowerCaseChar(byval c as UByte) as UByte
  if c >= CHAR_A andalso c <= CHAR_Z then return c + 32
  return c
end function

private function ConsumeIdentTokenFromStream() as String
  if IsIdentStartChar(asc(pStream[0])) = FALSE then return ""
  dim pStart as ZString ptr = pStream
  pStream += 1
  while IsIdentChar(asc(pStream[0]))
    pStream += 1
  wend
  return Left(*pStart, pStream - pStart)
end function

private sub SetUnexpectedCommaError()
  SetParseError(FB_STR_UNEXPECTED_COMMA)
end sub

private sub SetIndexingRequiresArrayError()
  SetParseError(FB_STR_INDEXING_REQUIRES_AN_ARRAY_VALUE)
end sub

private sub SetMissingIndexError()
  SetParseError(FB_STR_MISSING_INDEX)
end sub

private function TryConsumeCommaArgSeparator(byref hasComma as Boolean) as Boolean
  hasComma = FALSE
  if pStream[0] <> CHAR_COMMA then return TRUE
  hasComma = TRUE
  pStream += 1
  SkipSpaces()
  if pStream[0] = CHAR_RPAREN orelse pStream[0] = CHAR_COMMA then
    SetUnexpectedCommaError()
    return FALSE
  end if
  return TRUE
end function

private function MatchKeywordOperator(byref kw as String) as Boolean
  dim kwLen as Integer = Len(kw)
  if kwLen <= 0 then return FALSE
  dim kwPtr as UByte Ptr = cast(UByte Ptr, strptr(kw))
  dim p as UByte Ptr = cast(UByte Ptr, pStream)
  dim i as Integer
  for i = 0 to kwLen - 1
    dim c1 as UByte = ToLowerCaseChar(p[i])
    dim c2 as UByte = ToLowerCaseChar(kwPtr[i])
    if c1 <> c2 then return FALSE
  next i
  if IsIdentChar(p[kwLen]) then return FALSE
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

private sub SetMissingClosingParenthesisError()
  SetParseError(FB_STR_MISSING_CLOSING_PARENTHESIS)
end sub

private sub SetMismatchedClosingBracketError()
  SetParseError(FB_STR_MISMATCHED_CLOSING_BRACKET)
end sub

private sub SetMismatchedClosingBraceError()
  SetParseError(FB_STR_MISMATCHED_CLOSING_BRACE)
end sub

private function TryConsumeClosingParenOrSetError() as Boolean
  if pStream[0] = CHAR_RPAREN then
    pStream += 1
    return TRUE
  end if
  if pStream[0] = CHAR_RBRACKET then
    SetMismatchedClosingBracketError()
  elseif pStream[0] = CHAR_RBRACE then
    SetMismatchedClosingBraceError()
  else
    SetMissingClosingParenthesisError()
  end if
  return FALSE
end function

private sub SetUnexpectedTokenError()
  SetParseError(FB_STR_UNEXPECTED_TOKEN)
end sub

private sub SetMismatchedBracketBraceOrUnexpectedToken(byval ch as Integer)
  if ch = CHAR_RBRACKET then
    SetMismatchedClosingBracketError()
  elseif ch = CHAR_RBRACE then
    SetMismatchedClosingBraceError()
  else
    SetUnexpectedTokenError()
  end if
end sub

private function TryValidateIdentifierIsNotReserved(byref ident as String, byref errText as String) as Boolean
  if IsReservedUserFunctionName(ident) then
    errText = FB_STR_RESERVED_FUNCTION_NAME_COLON & ident
    return FALSE
  end if
  if IsBuiltinConstantName(ident) then
    errText = FB_STR_RESERVED_CONSTANT_NAME_COLON & ident
    return FALSE
  end if
  return TRUE
end function

private function TryValidateUserFunctionDefinitionNames(byref fnName as String, fnParams() as String, byref errText as String) as Boolean
  if IsReservedBuiltinVariableNameForUserFunction(fnName) then
    errText = FB_STR_RESERVED_BUILTIN_VARIABLE_NAME_COLON & fnName
    return FALSE
  end if
  if TryValidateIdentifierIsNotReserved(fnName, errText) = FALSE then
    return FALSE
  end if
  if ubound(fnParams) >= lbound(fnParams) then
    for iParam as Integer = lbound(fnParams) to ubound(fnParams)
      if IsBuiltinConstantName(fnParams(iParam)) then
        errText = FB_STR_RESERVED_CONSTANT_NAME_COLON & fnParams(iParam)
        return FALSE
      end if
      for jParam as Integer = iParam + 1 to ubound(fnParams)
        if fnParams(iParam) = fnParams(jParam) then
          errText = FB_STR_DUPLICATE_PARAMETER_NAME_COLON & fnParams(iParam)
          return FALSE
        end if
      next jParam
    next iParam
  end if
  return TRUE
end function

private function TryGetConstant(byref n as String, byref v as EvalValue) as Boolean
  dim cid as Integer = TryFindBuiltinConstId(n)
  if cid < 0 then return FALSE
  select case cast(BuiltinConstId, cid)
    case CONST_PI
      ValueSetScalar(v, FB_PI_VAL)
    case CONST_E
      ValueSetScalar(v, exp(1.0))
    case CONST_INF
      ValueSetScalar(v, 1.0 / 0.0)
    case CONST_NAN
      ValueSetScalar(v, MakeNaN())
    case CONST_MILLISECOND
      ValueSetTimeMs(v, 1)
    case CONST_SECOND
      ValueSetTimeMs(v, 1000)
    case CONST_MINUTE
      ValueSetTimeMs(v, 60000)
    case CONST_HOUR
      ValueSetTimeMs(v, 3600000)
    case CONST_DAY
      ValueSetTimeMs(v, 86400000)
    case else
      return FALSE
  end select
  return TRUE
end function

#ifdef __FB_FUNC_VARS_OVERRIDE_GLOBALS__
declare function TryGetFunctionVariableOverride(byref n as String, byref v as EvalValue) as Boolean
#endif

private function GetVariable(byref n as String, byref v as EvalValue) as Boolean
#ifdef __FB_FUNC_VARS_OVERRIDE_GLOBALS__
  if TryGetFunctionVariableOverride(n, v) then return TRUE
#endif
  if lcase(n) = FB_STR_ANS then
    dim j as Integer
    for j = lbound(variables) to ubound(variables)
      if variables(j).name = FB_STR_ANS then
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

#ifdef __FB_FUNC_VARS_OVERRIDE_GLOBALS__
private function TryGetFunctionVariableOverride(byref n as String, byref v as EvalValue) as Boolean
  dim i as Integer
  for i = 0 to functionVariableCount - 1
    if functionVariableNames(i) = n then
      dim idx as Integer = FindVariableIndex(FB_STR_FORMAL_VALIDATION_PROBE)
      if idx >= 0 andalso variables(idx).value.kind = VK_SCALAR then
        v = variables(idx).value
      else
        ValueSetInt64(v, 1)
      end if
      return TRUE
    end if
  next i
  return FALSE
end function
#endif

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

private sub RemoveVariableAtIndex(byval vIdx as Integer)
  if vIdx < lbound(variables) orelse vIdx > ubound(variables) then exit sub
  if ubound(variables) = lbound(variables) then
    erase variables
    exit sub
  end if
  dim j as Integer
  for j = vIdx to ubound(variables) - 1
    variables(j) = variables(j + 1)
  next j
  redim preserve variables(lbound(variables) to ubound(variables) - 1)
end sub

private sub SetAnsValue(byref v as EvalValue)
  SetVariable(FB_STR_ANS, v)
end sub

private function FindFunctionIndex(byref n as String) as Integer
  dim i as Integer
  for i = lbound(userFunctions) to ubound(userFunctions)
    if userFunctions(i).name = n then return i
  next i
  return -1
end function

'' True if body text contains a call to the same identifier as fnName (case-insensitive), e.g. y(a)=g(a)+y(a)+4.
private function UdfBodyCallsDefinedFunction(byref bodyText as String, byref fnName as String) as Boolean
  dim lowFn as String = lcase(trim(fnName))
  if len(lowFn) = 0 then return FALSE

  dim b as String = bodyText
  dim bn as Integer = len(b)
  dim ip as Integer = 1
  while ip <= bn
    dim ca as Integer = asc(mid(b, ip, 1))
    if (ca >= asc("a") andalso ca <= asc("z")) orelse (ca >= asc("A") andalso ca <= asc("Z")) orelse mid(b, ip, 1) = "_" then
      dim i0 as Integer = ip
      while ip <= bn
        ca = asc(mid(b, ip, 1))
        if (ca >= asc("a") andalso ca <= asc("z")) orelse (ca >= asc("A") andalso ca <= asc("Z")) orelse (ca >= asc("0") andalso ca <= asc("9")) orelse mid(b, ip, 1) = "_" then
          ip += 1
        else
          exit while
        end if
      wend
      if lcase(mid(b, i0, ip - i0)) = lowFn then
        dim jp as Integer = ip
        while jp <= bn
          ca = asc(mid(b, jp, 1))
          if ca = CHAR_SPACE orelse ca = CHAR_TAB then
            jp += 1
          else
            exit while
          end if
        wend
        if jp <= bn andalso mid(b, jp, 1) = "(" then return TRUE
      end if
    else
      ip += 1
    end if
  wend
  return FALSE
end function

declare function TryValidateUserFunctionBodyExpression(byref body as String, fnParams() as String, byref errText as String) as Boolean

private function TryValidateUserFunctionDefinition(byref fnName as String, fnParams() as String, byref body as String, byref errText as String) as Boolean
  if TryValidateUserFunctionDefinitionNames(fnName, fnParams(), errText) = FALSE then
    return FALSE
  end if
  if len(trim(body)) = 0 then
    errText = FB_STR_FUNCTION_BODY_IS_EMPTY
    return FALSE
  end if
  if UdfBodyCallsDefinedFunction(body, fnName) then
    errText = FB_STR_RECURSIVE_USER_FUNCTION_CALL_COLON & fnName
    return FALSE
  end if
  if TryValidateUserFunctionBodyExpression(body, fnParams(), errText) = FALSE then
    return FALSE
  end if
  return TRUE
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

private sub SetUnknownVariableListError(byref unknownVars as String)
  SetParseError(FB_STR_UNKNOWN_VARIABLE_COLON & unknownVars)
end sub

private sub SetUnknownFunctionListError(byref unknownFuncs as String)
  SetParseError(FB_STR_UNKNOWN_FUNCTION_COLON & unknownFuncs)
end sub

private sub AppendUnknownFunctionListError(byref unknownFuncs as String)
  lastErrorText &= FB_STR_SEMICOLON_UNKNOWN_FUNCTION_COLON & unknownFuncs
end sub

private function BuildUnknownNameErrorText(byref unknownVars as String, byref unknownFuncs as String) as String
  dim errText as String = ""
  if unknownVars <> "" then
    errText = FB_STR_UNKNOWN_VARIABLE_COLON & unknownVars
    if unknownFuncs <> "" then
      errText &= FB_STR_SEMICOLON_UNKNOWN_FUNCTION_COLON & unknownFuncs
    end if
    return errText
  end if
  if unknownFuncs <> "" then
    errText = FB_STR_UNKNOWN_FUNCTION_COLON & unknownFuncs
  end if
  return errText
end function

private sub ApplyUnknownNameErrors()
  dim errText as String = BuildUnknownNameErrorText(unknownVarsText, unknownFuncsText)
  if errText <> "" then
    SetParseError(errText)
  end if
end sub

private function TryHandleUnknownIdentifier(byref nam as String, byref outV as EvalValue, byref canIndex as Boolean) as Boolean
  dim lowNam as String = lcase(nam)
  if IsLogicalBinaryOperatorKeyword(lowNam) then
    SetUnexpectedTokenError()
    return FALSE
  end if
  dim fnHint as String
  if TryGetBuiltinSignatureHint(nam, fnHint) then
    SetParseError(FB_STR_HINT_PREFIX & fnHint)
    return FALSE
  end if
  AppendUniqueName(unknownVarsText, nam)
  ValueSetInt64(outV, 0)
  canIndex = FALSE
  return TRUE
end function

private sub SetNumericErrorInFunction(byref fnName as String)
  SetParseError(FB_STR_NUMERIC_ERROR_IN & fnName & FB_STR_PAR)
end sub

private sub SetAtLeastOneArgError(byref fnName as String)
  SetParseError(fnName & FB_STR_PAR_EXPECTS_AT_LEAST_1)
end sub

private sub SetExactArgCountError(byref fnName as String, byval expectedCount as Integer, byval actualCount as Integer)
  SetParseError(fnName & FB_STR_PAR_EXPECTS & ltrim(str(expectedCount)) & FB_STR_ARGUMENT_PAR_S_COMMA & ltrim(str(actualCount)) & FB_STR_GIVEN)
end sub

private sub SetScalarValuesError(byref fnName as String)
  SetParseError(fnName & FB_STR_PAR_EXPECTS_SCALAR_VALUES)
end sub

private sub SetIntegerValuesError(byref fnName as String)
  SetParseError(fnName & FB_STR_PAR_EXPECTS_INTEGER_VALUES)
end sub

private sub SetScalarMinMaxError(byref fnName as String)
  SetParseError(fnName & FB_STR_PAR_EXPECTS_SCALAR_MIN_SLASH)
end sub

private sub SetNonNegativeIntegerError(byref fnName as String)
  SetParseError(fnName & FB_STR_PAR_EXPECTS_A_NON_DASH)
end sub

private sub SetBitwiseIntegerOperandsError()
  SetParseError(FB_STR_BITWISE_OPERANDS_MUST_BE_INTEGER_VALUES)
end sub

private sub SetModuloIntegerOperandsError()
  SetParseError(FB_STR_MODULO_OPERANDS_MUST_BE_INTEGER_VALUES)
end sub

private sub SetIncompatibleOperandsError()
  SetParseError(FB_STR_INCOMPATIBLE_OPERANDS)
end sub

private sub SetTimeLiteralEmptySegmentError()
  SetParseError(FB_STR_TIME_EMPTY_SEGMENT)
end sub

private sub SetTimeLiteralInvalidSegmentError()
  SetParseError(FB_STR_TIME_INVALID_SEGMENT)
end sub

private sub SetTimeLiteralNegativeSegmentError()
  SetParseError(FB_STR_TIME_NEGATIVE_SEGMENT)
end sub

private sub SetTimeNonFiniteError()
  SetParseError(FB_STR_TIME_NON_FINITE)
end sub

private sub SetTimeArrayMixedError()
  SetParseError(FB_STR_TIME_ARRAY_MIXED)
end sub

private function ScalarIsTime(byref sv as ScalarValue) as Boolean
  return (sv.scalarStorageKind = SSK_TIME)
end function

private function EvalValueInvolvesTime(byref v as EvalValue) as Boolean
  if v.kind <> VK_SCALAR then
    if ValueArrayLen(v) <= 0 then return FALSE
    dim i as Integer
    for i = lbound(v.arr) to ubound(v.arr)
      if ScalarIsTime(v.arr(i)) then return TRUE
    next i
    return FALSE
  end if
  return ScalarIsTime(v.scalarValue)
end function

private function TimeTotalMsFromScalarValue(byref sv as ScalarValue) as LongInt
  return sv.exactInt64
end function

private sub ValueSetTimeMs(byref v as EvalValue, byval totalMs as LongInt)
  v.kind = VK_SCALAR
  v.scalarStorageKind = SSK_TIME
  v.scalar = CDbl(totalMs) / 1000.0
  v.exactInt64Valid = FALSE
  v.exactInt64 = totalMs
  v.exactUInt64Valid = FALSE
  v.exactUInt64 = 0
  v.expandArgs = FALSE
  v.renderBase = 10
  v.renderUnsigned = FALSE
  erase v.arr
end sub

private function RoundHalfUpDoubleToLongInt(byval x as Double) as LongInt
  if IsNonFiniteValue(x) then return 0
  if x >= 0 then
    return CLngInt(Int(x + 0.5))
  end if
  return -CLngInt(Int(-x + 0.5))
end function

private function SecondsFieldToMsRounded(byval wholeSec as LongInt, byref fracDigits as String) as LongInt
  dim d as Double = CDbl(wholeSec)
  if len(fracDigits) > 0 then
    dim fd as Double = val("0." & fracDigits)
    if IsNonFiniteValue(fd) then return 0
    d += fd
  end if
  return RoundHalfUpDoubleToLongInt(d * 1000.0)
end function

private function ParseTimeLiteralStringToMs(byref lit as String, byref outMs as LongInt) as Boolean
  dim n as Integer = len(lit)
  if n <= 0 then return FALSE
  dim colonPos() as Integer
  redim colonPos(0 to 7)
  dim colonCount as Integer = 0
  dim i as Integer
  for i = 1 to n
    if mid(lit, i, 1) = ":" then
      if colonCount > 6 then
        SetTimeLiteralInvalidSegmentError()
        return FALSE
      end if
      colonCount += 1
      colonPos(colonCount) = i
    end if
  next i
  dim segCount as Integer = colonCount + 1
  if segCount < 2 orelse segCount > 4 then
    SetTimeLiteralInvalidSegmentError()
    return FALSE
  end if

  dim getSegStart as Integer = 1
  dim si as Integer
  dim d as LongInt, h as LongInt, m as LongInt
  dim lastWhole as LongInt
  dim fracPart as String = ""
  dim dotPos as Integer = 0
  dim segStr as String

  for si = 1 to segCount
    dim segEnd as Integer
    if si <= colonCount then
      segEnd = colonPos(si) - 1
    else
      segEnd = n
    end if
    if segEnd < getSegStart then
      SetTimeLiteralEmptySegmentError()
      return FALSE
    end if
    segStr = mid(lit, getSegStart, segEnd - getSegStart + 1)
    if len(segStr) <= 0 then
      SetTimeLiteralEmptySegmentError()
      return FALSE
    end if
    if si = segCount then
      dotPos = instr(1, segStr, ".")
      if dotPos > 0 then
        fracPart = mid(segStr, dotPos + 1)
        segStr = left(segStr, dotPos - 1)
        if len(segStr) <= 0 then
          SetTimeLiteralEmptySegmentError()
          return FALSE
        end if
      else
        fracPart = ""
      end if
    end if
    dim j as Integer
    for j = 1 to len(segStr)
      dim ch as Integer = asc(mid(segStr, j, 1))
      if ch < CHAR_DIGIT_0 orelse ch > CHAR_DIGIT_9 then
        SetTimeLiteralInvalidSegmentError()
        return FALSE
      end if
    next j
    dim uv as ULongInt = 0
    for j = 1 to len(segStr)
      dim dig as Integer = asc(mid(segStr, j, 1)) - CHAR_DIGIT_0
      if TryMult10OnceChecked(uv, uv) = FALSE then
        SetTimeLiteralInvalidSegmentError()
        return FALSE
      end if
      if TryAddULongChecked(uv, CULngInt(dig), uv) = FALSE then
        SetTimeLiteralInvalidSegmentError()
        return FALSE
      end if
    next j
    if uv > 9223372036854775807ull then
      SetTimeLiteralInvalidSegmentError()
      return FALSE
    end if
    lastWhole = CLngInt(uv)
    if si < segCount then
      select case segCount
        case 2
          if si = 1 then m = lastWhole
        case 3
          if si = 1 then h = lastWhole
          if si = 2 then m = lastWhole
        case 4
          if si = 1 then d = lastWhole
          if si = 2 then h = lastWhole
          if si = 3 then m = lastWhole
      end select
    end if
    getSegStart = segEnd + 2
  next si

  if len(fracPart) > 0 then
    for i = 1 to len(fracPart)
      dim ch2 as Integer = asc(mid(fracPart, i, 1))
      if ch2 < CHAR_DIGIT_0 orelse ch2 > CHAR_DIGIT_9 then
        SetTimeLiteralInvalidSegmentError()
        return FALSE
      end if
    next i
  end if

  dim secMs as LongInt = SecondsFieldToMsRounded(lastWhole, fracPart)
  dim t as Double
  select case segCount
    case 2
      t = CDbl(m) * 60000.0 + CDbl(secMs)
    case 3
      t = (CDbl(h) * 3600.0 + CDbl(m) * 60.0) * 1000.0 + CDbl(secMs)
    case 4
      t = ((CDbl(d) * 24.0 + CDbl(h)) * 3600.0 + CDbl(m) * 60.0) * 1000.0 + CDbl(secMs)
    case else
      SetTimeLiteralInvalidSegmentError()
      return FALSE
  end select
  if IsNonFiniteValue(t) then
    SetTimeLiteralInvalidSegmentError()
    return FALSE
  end if
  if t < CDbl(FB_I64_MIN) orelse t > CDbl(FB_I64_MAX) then
    SetTimeLiteralInvalidSegmentError()
    return FALSE
  end if
  outMs = RoundHalfUpDoubleToLongInt(t)
  return TRUE
end function

private function TryParseScalarTimeLiteral(byref outV as EvalValue) as Boolean
  dim p0 as ZString ptr = pStream
  if p0[0] < CHAR_DIGIT_0 orelse p0[0] > CHAR_DIGIT_9 then return FALSE
  if p0[0] = CHAR_DIGIT_0 then
    if p0[1] = CHAR_LC_X orelse p0[1] = CHAR_X orelse p0[1] = CHAR_LC_B orelse p0[1] = CHAR_B orelse p0[1] = CHAR_LC_O orelse p0[1] = CHAR_O then
      return FALSE
    end if
  end if
  dim q as ZString ptr = p0
  dim hasColon as Boolean = FALSE
  while (q[0] >= CHAR_DIGIT_0 andalso q[0] <= CHAR_DIGIT_9) orelse q[0] = CHAR_COLON orelse q[0] = CHAR_DOT
    if q[0] = CHAR_COLON then hasColon = TRUE
    q += 1
  wend
  if hasColon = FALSE then return FALSE
  dim litLen as Integer = CInt(q - p0)
  if litLen <= 0 then return FALSE
  dim lit as String = left(*p0, litLen)
  dim ms as LongInt = 0
  if ParseTimeLiteralStringToMs(lit, ms) = FALSE then
    return FALSE
  end if
  pStream = q
  ValueSetTimeMs(outV, ms)
  return TRUE
end function

private function Pad2Digits(byval n as LongInt) as String
  if n < 0 then n = 0
  if n >= 100 then return ltrim(str(n))
  if n >= 10 then return chr(48 + n \ 10) & chr(48 + n mod 10)
  return "0" & chr(48 + n mod 10)
end function

private function FormatTimeCanonicalFromMs(byval totalMs as LongInt) as String
  dim neg as Boolean = (totalMs < 0)
  dim rU as ULongInt
  if neg then
    if totalMs = FB_I64_MIN then
      rU = CULngInt(FB_I64_MIN_MAG_U)
    else
      rU = CULngInt(-totalMs)
    end if
  else
    rU = CULngInt(totalMs)
  end if
  dim msPart as LongInt = CLngInt(rU mod 1000ull)
  rU = rU \ 1000ull
  dim sPart as LongInt = CLngInt(rU mod 60ull)
  rU = rU \ 60ull
  dim mPart as LongInt = CLngInt(rU mod 60ull)
  rU = rU \ 60ull
  dim hPart as LongInt = CLngInt(rU mod 24ull)
  rU = rU \ 24ull
  dim dPart as ULongInt = rU
  dim body as String
  if dPart > 0ull then
    body = ULongIntToString(dPart) & ":" & Pad2Digits(hPart) & ":" & Pad2Digits(mPart) & ":" & Pad2Digits(sPart)
  elseif hPart > 0 then
    body = Pad2Digits(hPart) & ":" & Pad2Digits(mPart) & ":" & Pad2Digits(sPart)
  else
    body = Pad2Digits(mPart) & ":" & Pad2Digits(sPart)
  end if
  if msPart <> 0 then
    body &= "." & chr(48 + (msPart \ 100)) & chr(48 + ((msPart \ 10) mod 10)) & chr(48 + (msPart mod 10))
  end if
  if neg then return "-" & body
  return body
end function

private function TryAddTimeMsChecked(byval a as LongInt, byval b as LongInt, byref outMs as LongInt) as Boolean
  dim t as Double = CDbl(a) + CDbl(b)
  if t < CDbl(FB_I64_MIN) orelse t > CDbl(FB_I64_MAX) then return FALSE
  outMs = RoundHalfUpDoubleToLongInt(t)
  return TRUE
end function

private function TrySubTimeMsChecked(byval a as LongInt, byval b as LongInt, byref outMs as LongInt) as Boolean
  dim t as Double = CDbl(a) - CDbl(b)
  if t < CDbl(FB_I64_MIN) orelse t > CDbl(FB_I64_MAX) then return FALSE
  outMs = RoundHalfUpDoubleToLongInt(t)
  return TRUE
end function

private function ScalarToSecondsMsForTimeOp(byref sv as ScalarValue, byref outMs as LongInt) as Boolean
  if ScalarIsTime(sv) then
    outMs = TimeTotalMsFromScalarValue(sv)
    return TRUE
  end if
  if IsNonFiniteValue(sv.scalar) then return FALSE
  outMs = RoundHalfUpDoubleToLongInt(sv.scalar * 1000.0)
  return TRUE
end function

private function ScalarIsNonFiniteOrTimeMixInvalid(byref sv as ScalarValue) as Boolean
  if ScalarIsTime(sv) then return FALSE
  return IsNonFiniteValue(sv.scalar)
end function

private sub SetUserFunctionCallStackOverflowError()
  SetParseError(FB_STR_USER_FUNCTION_CALL_STACK_OVERFLOW)
end sub

private sub SetRecursiveUserFunctionCallError(byref fnName as String)
  SetParseError(FB_STR_RECURSIVE_USER_FUNCTION_CALL_COLON & fnName)
end sub

private sub SetArrayElementMustBeScalarError()
  SetParseError(FB_STR_ARRAY_ELEMENT_MUST_BE_SCALAR)
end sub

private sub SetArrayIndexMustBeScalarError()
  SetParseError(FB_STR_ARRAY_INDEX_MUST_BE_A_SCALAR)
end sub

private sub SetArrayIndexMustBeIntegerError()
  SetParseError(FB_STR_ARRAY_INDEX_MUST_BE_AN_INTEGER)
end sub

private sub SetArrayIndexOutOfRangeError()
  SetParseError(FB_STR_ARRAY_INDEX_IS_OUT_OF_RANGE)
end sub

private sub SetFunctionHintError(byref hintText as String)
  SetParseError(FB_STR_HINT_PREFIX & hintText)
end sub

private sub SetInvalidHexLiteralError()
  SetParseError(FB_STR_INVALID_HEX_LITERAL)
end sub

private sub SetInvalidBinaryLiteralError()
  SetParseError(FB_STR_INVALID_BINARY_LITERAL)
end sub

private sub SetInvalidOctalLiteralError()
  SetParseError(FB_STR_INVALID_OCTAL_LITERAL)
end sub

private sub SetInvalidPrefixedLiteralError(byval prefixChar as UByte)
  select case prefixChar
    case CHAR_LC_X, CHAR_X
      SetInvalidHexLiteralError()
    case CHAR_LC_B, CHAR_B
      SetInvalidBinaryLiteralError()
    case CHAR_LC_O, CHAR_O
      SetInvalidOctalLiteralError()
  end select
end sub

private sub SetMissingClosingBracketError()
  SetParseError(FB_STR_MISSING_CLOSING_BRACKET)
end sub

private sub SetMissingOpeningBracketError()
  SetParseError(FB_STR_MISSING_OPENING_BRACKET)
end sub

private sub SetExpressionTooLongError()
  SetParseError(FB_STR_EXPRESSION_IS_TOO_LONG)
end sub

private sub SetMismatchedClosingParenthesisError()
  SetParseError(FB_STR_MISMATCHED_CLOSING_PARENTHESIS)
end sub

private sub SetEmptyStatementError()
  SetParseError(FB_STR_EMPTY_STATEMENT)
end sub

private sub SetFunctionBodyIsEmptyError()
  SetParseError(FB_STR_FUNCTION_BODY_IS_EMPTY)
end sub

private sub SetValidationError(byref errText as String)
  SetParseError(errText)
end sub

private function TryValidateAssignmentTargetName(byref varName as String, byref errText as String) as Boolean
  return TryValidateIdentifierIsNotReserved(varName, errText)
end function

private function TryParseArrayIndex(byref baseValue as EvalValue, byref outValue as EvalValue) as Boolean
  outValue = baseValue
  SkipSpaces()
  if pStream[0] <> CHAR_LBRACKET then return TRUE

  if baseValue.kind <> VK_ARRAY then
    SetIndexingRequiresArrayError()
    return FALSE
  end if

  pStream += 1
  SkipSpaces()
  if pStream[0] = CHAR_RBRACKET then
    SetMissingIndexError()
    return FALSE
  end if

  dim idxValue as EvalValue = ParseExpression()
  if parseError then return FALSE
  if idxValue.kind <> VK_SCALAR then
    SetArrayIndexMustBeScalarError()
    return FALSE
  end if

  dim idxRaw as Double = idxValue.scalar
  dim idxInt as Integer = cint(idxRaw)
  if idxRaw <> idxInt then
    SetArrayIndexMustBeIntegerError()
    return FALSE
  end if
  SkipSpaces()
  if pStream[0] <> CHAR_RBRACKET then
    if pStream[0] = CHAR_RPAREN then
      SetMismatchedClosingParenthesisError()
    elseif pStream[0] = CHAR_RBRACE then
      SetMismatchedClosingBraceError()
    else
      SetMissingClosingBracketError()
    end if
    return FALSE
  end if
  pStream += 1

  dim arrLen as Integer = ValueArrayLen(baseValue)
  if idxInt < 0 then idxInt = arrLen + idxInt
  if idxInt < 0 orelse idxInt >= arrLen then
    SetArrayIndexOutOfRangeError()
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
    SetExactArgCountError(fnName, pCount, aCount)
    return TRUE
  end if

  dim lowNm as String = lcase(fnName)
  dim si as Integer
  for si = 0 to udfCallStackSp - 1
    if udfCallStack(si) = lowNm then
      SetRecursiveUserFunctionCallError(fnName)
      return TRUE
    end if
  next si
  if udfCallStackSp >= UDF_CALL_STACK_MAX then
    SetUserFunctionCallStackOverflowError()
    return TRUE
  end if
  udfCallStack(udfCallStackSp) = lowNm
  udfCallStackSp += 1

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
  if pStream[0] <> CHAR_NUL then SetParseError(FB_STR_UNEXPECTED_INPUT)
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
      if vIdx >= 0 then RemoveVariableAtIndex(vIdx)
    end if
  next i

  udfCallStackSp -= 1

  if evalError <> 0 then parseError = 1
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

private function GcdULong(byval a as ULongInt, byval b as ULongInt) as ULongInt
  dim x as ULongInt = a
  dim y as ULongInt = b
  while y <> 0ull
    dim t as ULongInt = x mod y
    x = y
    y = t
  wend
  return x
end function

private function TryLcmULong(byval a as ULongInt, byval b as ULongInt, byref outL as ULongInt) as Boolean
  if a = 0ull orelse b = 0ull then
    outL = 0ull
    return TRUE
  end if
  dim g as ULongInt = GcdULong(a, b)
  dim a1 as ULongInt = a \ g
  if a1 > (FB_U64_MAX \ b) then return FALSE
  outL = a1 * b
  return TRUE
end function

private function TryGetExactNonNegativeUInt64Pair(byref aV as EvalValue, byref bV as EvalValue, byref aU as ULongInt, byref bU as ULongInt) as Boolean
  if aV.kind <> VK_SCALAR orelse bV.kind <> VK_SCALAR then return FALSE
  return TryGetExactNonNegativeUInt64Scalar(aV.scalarValue, aU) andalso TryGetExactNonNegativeUInt64Scalar(bV.scalarValue, bU)
end function

private function TryGetScalarInt64Pair(byref aV as EvalValue, byref bV as EvalValue, byref a as LongInt, byref b as LongInt) as Boolean
  if aV.kind <> VK_SCALAR orelse bV.kind <> VK_SCALAR then return FALSE
  if TryGetExactInt64(aV, a) = FALSE then return FALSE
  if TryGetExactInt64(bV, b) = FALSE then return FALSE
  return TRUE
end function

' Returns 0 = ok, 1 = operands not exact integers, 2 = lcm overflow (uint64)
private function ApplyGcdLcm(byref aV as EvalValue, byref bV as EvalValue, byval doLcm as Boolean, byref outV as EvalValue) as Integer
  if aV.kind = VK_SCALAR andalso bV.kind = VK_SCALAR then
    dim aU as ULongInt, bU as ULongInt
    if TryGetExactNonNegativeUInt64Pair(aV, bV, aU, bU) then
      dim gU as ULongInt = GcdULong(aU, bU)
      if doLcm = FALSE then
        ValueSetUInt64(outV, gU)
        return 0
      end if
      dim lU as ULongInt
      if TryLcmULong(aU, bU, lU) = FALSE then return 2
      ValueSetUInt64(outV, lU)
      return 0
    end if
    dim a as LongInt, b as LongInt
    if TryGetScalarInt64Pair(aV, bV, a, b) = FALSE then return 1
    dim g as LongInt = GcdInt64(a, b)
    if doLcm = FALSE then
      ValueSetInt64(outV, g)
      return 0
    end if
    if g = 0 then
      ValueSetInt64(outV, 0)
      return 0
    end if
    dim q as LongInt = a \ g
    dim l as LongInt
    if TryMulInt64(q, b, l) = FALSE then return 2
    if l < 0 then
      if l = FB_I64_MIN then return 2
      l = -l
    end if
    ValueSetInt64(outV, l)
    return 0
  end if

  dim i as Integer
  if aV.kind = VK_ARRAY then
    ValueInitArrayLike(outV, lbound(aV.arr), ubound(aV.arr))
    for i = lbound(aV.arr) to ubound(aV.arr)
      dim a as EvalValue, r as EvalValue
      ValueGetArrayElemAsScalar(aV, i, a)
      dim rc as Integer = ApplyGcdLcm(a, bV, doLcm, r)
      if rc <> 0 then return rc
      ValueSetArrayElemFromScalar(outV, i, r)
    next i
    return 0
  end if
  ValueInitArrayLike(outV, lbound(bV.arr), ubound(bV.arr))
  for i = lbound(bV.arr) to ubound(bV.arr)
    dim b as EvalValue, r as EvalValue
    ValueGetArrayElemAsScalar(bV, i, b)
    dim rc as Integer = ApplyGcdLcm(aV, b, doLcm, r)
    if rc <> 0 then return rc
    ValueSetArrayElemFromScalar(outV, i, r)
  next i
  return 0
end function

private function TryApplyNcrNpr(byref nV as EvalValue, byref rV as EvalValue, byval doPerm as Boolean, byref outV as EvalValue) as Boolean
  dim n as LongInt, r as LongInt
  if TryGetScalarInt64Pair(nV, rV, n, r) = FALSE then return FALSE
  if n < 0 orelse r < 0 orelse r > n then return FALSE
  if r = 0 then
    ValueSetInt64(outV, 1)
    return TRUE
  end if

  if doPerm then
    dim permAcc as LongInt = 1
    for i as LongInt = 0 to r - 1
      dim term as LongInt = n - i
      if TryMulInt64(permAcc, term, permAcc) = FALSE then return FALSE
    next i
    ValueSetInt64(outV, permAcc)
    return TRUE
  end if

  dim rEff as LongInt = r
  if (n - rEff) < rEff then rEff = (n - rEff)
  dim combAcc as LongInt = 1
  for i as LongInt = 1 to rEff
    dim num as LongInt = (n - rEff) + i
    dim den as LongInt = i
    dim g1 as LongInt = GcdInt64(num, den)
    if g1 > 1 then
      num \= g1
      den \= g1
    end if
    dim g2 as LongInt = GcdInt64(combAcc, den)
    if g2 > 1 then
      combAcc \= g2
      den \= g2
    end if
    if den <> 1 then return FALSE
    if TryMulInt64(combAcc, num, combAcc) = FALSE then return FALSE
  next i
  ValueSetInt64(outV, combAcc)
  return TRUE
end function

private function TryApplyScalarBinaryIntegerBuiltin(byval fnId as Integer, byref fnName as String, args() as EvalValue, byref outV as EvalValue) as Boolean
  if (fnId <> FUNC_GCD) andalso (fnId <> FUNC_LCM) andalso (fnId <> FUNC_NCR) andalso (fnId <> FUNC_NPR) then return FALSE
  if args(0).kind <> VK_SCALAR orelse args(1).kind <> VK_SCALAR then
    SetScalarValuesError(fnName)
    return TRUE
  end if
  if (fnId = FUNC_GCD) orelse (fnId = FUNC_LCM) then
    dim gcdRc as Integer = ApplyGcdLcm(args(0), args(1), (fnId = FUNC_LCM), outV)
    if gcdRc = 1 then
      SetIntegerValuesError(fnName)
    elseif gcdRc = 2 then
      SetNumericErrorInFunction(fnName)
    end if
    return TRUE
  end if
  if TryApplyNcrNpr(args(0), args(1), (fnId = FUNC_NPR), outV) = FALSE then
    SetNumericErrorInFunction(fnName)
  end if
  return TRUE
end function

private function IsMultipleOf(byval x as Double, byval x_mult as Double) as Boolean
  dim abs_x as Double = abs(x)
  dim y as Double = abs_x/x_mult + abs_x/1e+15
  if y >= 1.0 then
    if y/Fix(y) - 1.0 < 1e-14 then return TRUE
  end if
  return FALSE
end function

private function CalcSin(byval x as Double) as Double
  if x=0.0 then return 0.0
  if IsFiniteValue(x) then
    if IsMultipleOf(x, FB_PI_VAL) then
      ' sin(N*pi), N = 1,2,3,4,...
      return 0.0
    end if
  end if
  return sin(x)
end function

private function CalcCos(byval x as Double) as Double
  if IsFiniteValue(x) then
    if not IsMultipleOf(x, FB_PI_VAL) then
      if IsMultipleOf(x, FB_PI_VAL/2) then
        ' cos(N*pi/2), N = 1,3,5,7,...
        return 0.0
      end if
    end if
  endif
  return cos(x)
end function

private function CalcTan(byval x as Double) as Double
  if x=0.0 then return 0.0
  if IsFiniteValue(x) then
    if IsMultipleOf(x, FB_PI_VAL) then
      ' tan(N*pi), N = 1,2,3,4,...
      return 0.0
    end if
    if IsMultipleOf(x, FB_PI_VAL/2) then
      ' tan(N*pi/2), N = 1,3,5,7,...
      if tan(x) > 0.0 then return 1.0/0.0 ' INF
      return -1.0/0.0 ' -INF
    end if
  end if
  return tan(x)
end function

private function CalcAtan2(byval y as Double, byval x as Double) as Double
  if x > 0 then return atn(y / x)
  if x < 0 then
    if y >= 0 then
      return atn(y / x) + FB_PI_VAL
    else
      return atn(y / x) - FB_PI_VAL
    end if
  end if
  if y > 0 then return FB_PI_VAL / 2.0
  if y < 0 then return -FB_PI_VAL / 2.0
  return 0
end function

private function CalcHypot(byval x as Double, byval y as Double) as Double
  return sqr((x * x) + (y * y))
end function

private sub CalcRoundingFnHugeAsFloat(byval fnId as Integer, byval x as Double, byref outV as EvalValue)
  '' Fix/Int are not reliable past exact LongInt range; use C floor for full double domain.
  select case fnId
  case FUNC_INT, FUNC_TRUNC
    if x >= 0 then
      ValueSetScalar(outV, floor(x))
    else
      ValueSetScalar(outV, -floor(-x))
    end if
  case FUNC_FLOOR
    ValueSetScalar(outV, floor(x))
  case FUNC_CEIL
    ValueSetScalar(outV, -floor(-x))
  case FUNC_ROUND
    if x >= 0 then
      ValueSetScalar(outV, floor(x + 0.5))
    else
      ValueSetScalar(outV, -floor(-x + 0.5))
    end if
  case else
    ValueSetScalar(outV, x)
  end select
end sub

private sub calcRoundingFn(byval fnId as Integer, byref scalarV as ScalarValue, byref outV as EvalValue)
  dim x as Double = scalarV.scalar

  if IsNonFiniteValue(x) then
    ValueSetScalar(outV, x)
  elseif scalarV.exactUInt64Valid then
    ValueSetUInt64(outV, scalarV.exactUInt64)
  elseif scalarV.exactInt64Valid then
    ValueSetInt64(outV, scalarV.exactInt64)
  elseif (x > FB_MAX_EXACT_INT_FROM_DOUBLE) orelse (x < -FB_MAX_EXACT_INT_FROM_DOUBLE) then
    if (x <= FB_I64_MAX_D) andalso (x >= FB_I64_MIN_D) then
      ValueSetInt64(outV, CLngInt(x))
    elseif (x >= 0) andalso (x < FB_2_POW_64_D) andalso (x = floor(x)) then
      dim u as ULongInt = CULngInt(floor(x))
      if CDbl(u) = x then
        ValueSetUInt64(outV, u)
      else
        CalcRoundingFnHugeAsFloat(fnId, x, outV)
      end if
    else
      CalcRoundingFnHugeAsFloat(fnId, x, outV)
    end if
  else
    dim rounded as LongInt = 0
    select case fnId
      case FUNC_INT, FUNC_TRUNC
        rounded = CLngInt(Fix(x))
      case FUNC_FLOOR
        rounded = CLngInt(Int(x))
      case FUNC_CEIL
        rounded = CLngInt(-Int(-x))
      case FUNC_ROUND
        if x >= 0 then
          rounded = CLngInt(Int(x + 0.5))
        else
          rounded = CLngInt(-Int(-x + 0.5))
        end if
    end select
    ValueSetInt64(outV, rounded)
  end if
end sub

private function ApplyUnaryScalarFunctionById(byval fnId as Integer, byref scalarV as ScalarValue, byref outV as EvalValue) as Boolean
  dim x as Double = scalarV.scalar
  if fnId = FUNC_SIN then
    ValueSetScalarPromoteExactInt64(outV, CalcSin(x))
  elseif fnId = FUNC_COS then
    ValueSetScalarPromoteExactInt64(outV, CalcCos(x))
  elseif fnId = FUNC_TAN then
    ValueSetScalarPromoteExactInt64(outV, CalcTan(x))
  elseif fnId = FUNC_ASIN then
    ValueSetScalarPromoteExactInt64(outV, asin(x))
  elseif fnId = FUNC_ACOS then
    ValueSetScalarPromoteExactInt64(outV, acos(x))
  elseif fnId = FUNC_ATAN then
    ValueSetScalarPromoteExactInt64(outV, atn(x))
  elseif fnId = FUNC_SINH then
    ValueSetScalarPromoteExactInt64(outV, sinh(x))
  elseif fnId = FUNC_COSH then
    ValueSetScalarPromoteExactInt64(outV, cosh(x))
  elseif fnId = FUNC_TANH then
    ValueSetScalarPromoteExactInt64(outV, tanh(x))
  elseif fnId = FUNC_ACOSH then
    ValueSetScalarPromoteExactInt64(outV, acosh(x))
  elseif fnId = FUNC_ASINH then
    ValueSetScalarPromoteExactInt64(outV, asinh(x))
  elseif fnId = FUNC_ATANH then
    ValueSetScalarPromoteExactInt64(outV, atanh(x))
  elseif fnId = FUNC_EXP then
    ValueSetScalarPromoteExactInt64(outV, exp(x))
  elseif fnId = FUNC_LN then
    ValueSetScalarPromoteExactInt64(outV, log(x))
  elseif fnId = FUNC_LOG10 then
    ValueSetScalarPromoteExactInt64(outV, log(x) / log(10.0))
  elseif fnId = FUNC_SQRT then
    ValueSetScalarPromoteExactInt64(outV, sqr(x))
  elseif fnId = FUNC_SQR then
    ValueSetScalarPromoteExactInt64(outV, x * x)
  elseif (fnId = FUNC_INT) orelse (fnId = FUNC_TRUNC) orelse _
         (fnId = FUNC_FLOOR) orelse (fnId = FUNC_CEIL) orelse _
         (fnId = FUNC_ROUND) then
    calcRoundingFn(fnId, scalarV, outV)
  elseif fnId = FUNC_FRAC then
    ValueSetScalarPromoteExactInt64(outV, x - Fix(x))
  elseif fnId = FUNC_ABS then
    if IsNaNValue(x) then
      ValueSetScalar(outV, MakeNaN())
    elseif scalarV.exactUInt64Valid then
      ValueSetUInt64(outV, scalarV.exactUInt64)
    else
      ValueSetScalarPromoteExactInt64(outV, abs(x))
    end if
  elseif fnId = FUNC_SIGN then
    if scalarV.exactInt64Valid then
      if scalarV.exactInt64 > 0 then
        ValueSetInt64(outV, 1)
      elseif scalarV.exactInt64 < 0 then
        ValueSetInt64(outV, -1)
      else
        ValueSetInt64(outV, 0)
      end if
    elseif scalarV.exactUInt64Valid then
      if scalarV.exactUInt64 = 0 then
        ValueSetInt64(outV, 0)
      else
        ValueSetInt64(outV, 1)
      end if
    elseif x > 0 then
      ValueSetInt64(outV, 1)
    elseif x < 0 then
      ValueSetInt64(outV, -1)
    else
      ValueSetInt64(outV, 0)
    end if
  elseif fnId = FUNC_DEG then
    ValueSetScalarPromoteExactInt64(outV, x * 180.0 / FB_PI_VAL)
  elseif fnId = FUNC_RAD then
    ValueSetScalarPromoteExactInt64(outV, x * FB_PI_VAL / 180.0)
  else
    return FALSE
  end if
  return TRUE
end function

private function ApplyUnaryFunction(byref fn as String, byref v as EvalValue, byref outV as EvalValue) as Boolean
  dim fnId as Integer = TryFindBuiltinFunctionId(fn)
  dim i as Integer
  if v.kind = VK_SCALAR then
    return ApplyUnaryScalarFunctionById(fnId, v.scalarValue, outV)
  end if

  if ubound(v.arr) < lbound(v.arr) then
    parseError = 1
    return FALSE
  end if
  ValueInitArrayLike(outV, lbound(v.arr), ubound(v.arr))
  for i = lbound(v.arr) to ubound(v.arr)
    dim tmpOut as EvalValue
    if ApplyUnaryScalarFunctionById(fnId, v.arr(i), tmpOut) = FALSE then return FALSE
    ValueSetArrayElemFromScalar(outV, i, tmpOut)
  next i
  return TRUE
end function

private function ValueApplyBinaryScalars(byref leftS as ScalarValue, byref rightS as ScalarValue, byval op as UByte, byref outV as EvalValue) as Boolean
  dim li as LongInt, ri as LongInt, ro as LongInt
  dim hasUIntL as Boolean
  dim hasUIntR as Boolean
  dim lu as ULongInt, ru as ULongInt
  hasUIntL = TryGetExactNonNegativeUInt64Scalar(leftS, lu)
  hasUIntR = TryGetExactNonNegativeUInt64Scalar(rightS, ru)
  if leftS.exactUInt64Valid andalso rightS.exactUInt64Valid andalso _
     ((leftS.exactInt64Valid = FALSE) orelse (rightS.exactInt64Valid = FALSE)) then
    select case op
      case CHAR_PLUS
        dim outU as ULongInt
        if TryAddULongChecked(leftS.exactUInt64, rightS.exactUInt64, outU) then
          ValueSetUInt64(outV, outU)
          return TRUE
        end if
      case CHAR_MINUS
        if leftS.exactUInt64 >= rightS.exactUInt64 then
          ValueSetUInt64(outV, leftS.exactUInt64 - rightS.exactUInt64)
          return TRUE
        end if
      case CHAR_ASTERISK
        dim outU as ULongInt
        if TryMulULongChecked(leftS.exactUInt64, rightS.exactUInt64, outU) then
          ValueSetUInt64(outV, outU)
          return TRUE
        end if
    end select
  end if

  dim hasIntL as Boolean = leftS.exactInt64Valid
  dim hasIntR as Boolean = rightS.exactInt64Valid
  if hasIntL then
    li = leftS.exactInt64
  elseif leftS.exactUInt64Valid andalso leftS.exactUInt64 <= FB_I64_MAX_U then
    hasIntL = TRUE
    li = CLngInt(leftS.exactUInt64)
  end if
  if hasIntR then
    ri = rightS.exactInt64
  elseif rightS.exactUInt64Valid andalso rightS.exactUInt64 <= FB_I64_MAX_U then
    hasIntR = TRUE
    ri = CLngInt(rightS.exactUInt64)
  end if
  if op = CHAR_CARET then
    if hasUIntL andalso hasUIntR then
      dim powU as ULongInt
      if TryPowULong(lu, ru, powU) then ValueSetUInt64(outV, powU): return TRUE
    end if
    if hasIntL andalso hasUIntR andalso li < 0 then
      dim baseMag as ULongInt
      if li = FB_I64_MIN then
        baseMag = FB_I64_MIN_MAG_U
      else
        baseMag = CULngInt(-li)
      end if
      dim powMag as ULongInt
      if TryPowULong(baseMag, ru, powMag) then
        if (ru and 1ull) = 0ull then
          ValueSetUInt64(outV, powMag)
          return TRUE
        elseif powMag <= FB_I64_MIN_MAG_U then
          if powMag = FB_I64_MIN_MAG_U then
            ValueSetInt64(outV, FB_I64_MIN)
          else
            ValueSetInt64(outV, -CLngInt(powMag))
          end if
          return TRUE
        end if
      end if
    end if
  end if
  if hasIntL andalso hasIntR then
    select case op
      case CHAR_ASTERISK
        if TryMulInt64(li, ri, ro) then ValueSetInt64(outV, ro): return TRUE
      case CHAR_PLUS
        if TryAddInt64(li, ri, ro) then ValueSetInt64(outV, ro): return TRUE
      case CHAR_MINUS
        if TrySubInt64(li, ri, ro) then ValueSetInt64(outV, ro): return TRUE
      case CHAR_CARET
        if TryPowInt64(li, ri, ro) then ValueSetInt64(outV, ro): return TRUE
    end select
  end if

  if hasUIntL andalso hasUIntR then
    select case op
      case CHAR_PLUS
        dim outU as ULongInt
        if TryAddULongChecked(lu, ru, outU) then ValueSetUInt64(outV, outU): return TRUE
      case CHAR_ASTERISK
        dim outU as ULongInt
        if TryMulULongChecked(lu, ru, outU) then ValueSetUInt64(outV, outU): return TRUE
    end select
  end if

  select case op
    case CHAR_ASTERISK: ValueSetScalarPromoteExactInt64(outV, leftS.scalar * rightS.scalar)
    case CHAR_DIVIDE
      if rightS.scalar = 0 andalso leftS.scalar = 0 then
        ValueSetScalar(outV, MakeNaN())
      else
        ValueSetScalarPromoteExactInt64(outV, leftS.scalar / rightS.scalar)
      end if
    case CHAR_PLUS: ValueSetScalarPromoteExactInt64(outV, leftS.scalar + rightS.scalar)
    case CHAR_MINUS: ValueSetScalarPromoteExactInt64(outV, leftS.scalar - rightS.scalar)
    case CHAR_CARET: ValueSetScalarPromoteExactInt64(outV, leftS.scalar ^ rightS.scalar)
    case else: return FALSE
  end select
  return TRUE
end function

declare function ValueApplyBinaryInt64Scalars(byref leftS as ScalarValue, byref rightS as ScalarValue, byval op as OperatorBitNameId, byref outV as EvalValue) as Boolean
declare function ApplyScalarBinaryMathFunctionScalars(byref leftS as ScalarValue, byref rightS as ScalarValue, byval fnId as Integer, byref outV as EvalValue) as Boolean

private const MAP_BINARY_OP_NUMERIC as Integer = 1
private const MAP_BINARY_OP_INT64 as Integer = 2
private const MAP_BINARY_OP_SCALAR_MATH as Integer = 3

private function TryMapBinaryPair(byval mode as Integer, byref leftS as ScalarValue, byref rightS as ScalarValue, byval op as UByte, byval intOp as OperatorBitNameId, byval fnId as Integer, byref outV as EvalValue) as Boolean
  select case mode
    case MAP_BINARY_OP_NUMERIC
      return ValueApplyBinaryScalars(leftS, rightS, op, outV)
    case MAP_BINARY_OP_INT64
      return ValueApplyBinaryInt64Scalars(leftS, rightS, intOp, outV)
    case MAP_BINARY_OP_SCALAR_MATH
      return ApplyScalarBinaryMathFunctionScalars(leftS, rightS, fnId, outV)
  end select
  return FALSE
end function

private function MapBinaryBroadcastScalars(byval mode as Integer, byref leftV as EvalValue, byref rightV as EvalValue, byval op as UByte, byval intOp as OperatorBitNameId, byval fnId as Integer, byref outV as EvalValue) as Boolean
  dim i as Integer
  if leftV.kind = VK_SCALAR andalso rightV.kind = VK_SCALAR then
    return TryMapBinaryPair(mode, leftV.scalarValue, rightV.scalarValue, op, intOp, fnId, outV)
  end if

  dim lb as Integer, ub as Integer
  if leftV.kind = VK_ARRAY andalso rightV.kind = VK_ARRAY then
    if ValueArrayLen(leftV) <> ValueArrayLen(rightV) then return FALSE
    lb = lbound(leftV.arr): ub = ubound(leftV.arr)
    ValueInitArrayLike(outV, lb, ub)
    dim rAA as EvalValue
    for i = lb to ub
      if TryMapBinaryPair(mode, leftV.arr(i), rightV.arr(i), op, intOp, fnId, rAA) = FALSE then return FALSE
      ValueSetArrayElemFromScalar(outV, i, rAA)
    next i
    return TRUE
  end if

  if leftV.kind = VK_ARRAY then
    lb = lbound(leftV.arr): ub = ubound(leftV.arr)
    ValueInitArrayLike(outV, lb, ub)
    dim rAS as EvalValue
    for i = lb to ub
      if TryMapBinaryPair(mode, leftV.arr(i), rightV.scalarValue, op, intOp, fnId, rAS) = FALSE then return FALSE
      ValueSetArrayElemFromScalar(outV, i, rAS)
    next i
    return TRUE
  end if

  lb = lbound(rightV.arr): ub = ubound(rightV.arr)
  ValueInitArrayLike(outV, lb, ub)
  dim rSA as EvalValue
  for i = lb to ub
    if TryMapBinaryPair(mode, leftV.scalarValue, rightV.arr(i), op, intOp, fnId, rSA) = FALSE then return FALSE
    ValueSetArrayElemFromScalar(outV, i, rSA)
  next i
  return TRUE
end function

private function MapTimeBinaryBroadcastScalars(byref leftV as EvalValue, byref rightV as EvalValue, byval op as UByte, byref outV as EvalValue) as Boolean
  dim i as Integer
  if leftV.kind = VK_SCALAR andalso rightV.kind = VK_SCALAR then
    return ApplyTimeBinaryScalars(leftV.scalarValue, rightV.scalarValue, op, outV)
  end if

  dim lb as Integer, ub as Integer
  if leftV.kind = VK_ARRAY andalso rightV.kind = VK_ARRAY then
    if ValueArrayLen(leftV) <> ValueArrayLen(rightV) then return FALSE
    lb = lbound(leftV.arr): ub = ubound(leftV.arr)
    ValueInitArrayLike(outV, lb, ub)
    dim rAA as EvalValue
    for i = lb to ub
      if ApplyTimeBinaryScalars(leftV.arr(i), rightV.arr(i), op, rAA) = FALSE then return FALSE
      ValueSetArrayElemFromScalar(outV, i, rAA)
    next i
    return TRUE
  end if

  if leftV.kind = VK_ARRAY then
    lb = lbound(leftV.arr): ub = ubound(leftV.arr)
    ValueInitArrayLike(outV, lb, ub)
    dim rAS as EvalValue
    for i = lb to ub
      if ApplyTimeBinaryScalars(leftV.arr(i), rightV.scalarValue, op, rAS) = FALSE then return FALSE
      ValueSetArrayElemFromScalar(outV, i, rAS)
    next i
    return TRUE
  end if

  lb = lbound(rightV.arr): ub = ubound(rightV.arr)
  ValueInitArrayLike(outV, lb, ub)
  dim rSA as EvalValue
  for i = lb to ub
    if ApplyTimeBinaryScalars(leftV.scalarValue, rightV.arr(i), op, rSA) = FALSE then return FALSE
    ValueSetArrayElemFromScalar(outV, i, rSA)
  next i
  return TRUE
end function

private function ApplyTimeBinaryScalars(byref leftS as ScalarValue, byref rightS as ScalarValue, byval op as UByte, byref outV as EvalValue) as Boolean
  dim lt as Boolean = ScalarIsTime(leftS)
  dim rt as Boolean = ScalarIsTime(rightS)
  if lt = FALSE andalso rt = FALSE then return FALSE

  if (lt = FALSE andalso IsNonFiniteValue(leftS.scalar)) orelse (rt = FALSE andalso IsNonFiniteValue(rightS.scalar)) then
    SetTimeNonFiniteError()
    return FALSE
  end if

  dim lms as LongInt
  dim rms as LongInt
  dim outMs as LongInt

  if lt then
    lms = TimeTotalMsFromScalarValue(leftS)
  else
    lms = RoundHalfUpDoubleToLongInt(leftS.scalar * 1000.0)
  end if
  if rt then
    rms = TimeTotalMsFromScalarValue(rightS)
  else
    rms = RoundHalfUpDoubleToLongInt(rightS.scalar * 1000.0)
  end if

  select case op
    case CHAR_PLUS
      if TryAddTimeMsChecked(lms, rms, outMs) = FALSE then return FALSE
      ValueSetTimeMs(outV, outMs)
      return TRUE
    case CHAR_MINUS
      if TrySubTimeMsChecked(lms, rms, outMs) = FALSE then return FALSE
      ValueSetTimeMs(outV, outMs)
      return TRUE
    case CHAR_ASTERISK
      if lt andalso rt then
        return FALSE
      else
        dim mult as Double
        dim baseMs as LongInt
        if lt then
          baseMs = lms
          mult = rightS.scalar
        else
          baseMs = rms
          mult = leftS.scalar
        end if
        if IsNonFiniteValue(mult) then return FALSE
        dim tMul as Double = CDbl(baseMs) * mult
        if tMul < CDbl(FB_I64_MIN) orelse tMul > CDbl(FB_I64_MAX) then return FALSE
        ValueSetTimeMs(outV, RoundHalfUpDoubleToLongInt(tMul))
        return TRUE
      end if
    case CHAR_DIVIDE
      if lt andalso rt then
        if rms = 0 then return FALSE
        dim ratio as Double = (CDbl(lms) / 1000.0) / (CDbl(rms) / 1000.0)
        if IsNonFiniteValue(ratio) then return FALSE
        ValueSetScalar(outV, ratio)
        return TRUE
      elseif lt andalso rt = FALSE then
        if rightS.scalar = 0.0 then return FALSE
        dim td as Double = (CDbl(lms) / 1000.0) / rightS.scalar
        if IsNonFiniteValue(td) then return FALSE
        if td < CDbl(FB_I64_MIN) orelse td > CDbl(FB_I64_MAX) then return FALSE
        ValueSetTimeMs(outV, RoundHalfUpDoubleToLongInt(td * 1000.0))
        return TRUE
      else
        return FALSE
      end if
  end select
  return FALSE
end function

private function ValueApplyBinaryTimeAware(byref leftV as EvalValue, byref rightV as EvalValue, byval op as UByte, byref outV as EvalValue) as Boolean
  if EvalValueInvolvesTime(leftV) = FALSE andalso EvalValueInvolvesTime(rightV) = FALSE then return FALSE
  if op <> CHAR_PLUS andalso op <> CHAR_MINUS andalso op <> CHAR_ASTERISK andalso op <> CHAR_DIVIDE then
    SetIncompatibleOperandsError()
    return TRUE
  end if
  if MapTimeBinaryBroadcastScalars(leftV, rightV, op, outV) = FALSE then
    if parseError = 0 then SetIncompatibleOperandsError()
    return TRUE
  end if
  return TRUE
end function

private function ValueApplyBinary(byref leftV as EvalValue, byref rightV as EvalValue, byval op as UByte, byref outV as EvalValue) as Boolean
  return MapBinaryBroadcastScalars(MAP_BINARY_OP_NUMERIC, leftV, rightV, op, OP_BIT_NONE, -1, outV)
end function

private function ApplyScalarBinaryMathFunctionScalars(byref leftS as ScalarValue, byref rightS as ScalarValue, byval fnId as Integer, byref outV as EvalValue) as Boolean
  if fnId = FUNC_LOG then
    if leftS.scalar <= 0 orelse rightS.scalar <= 0 orelse rightS.scalar = 1 then return FALSE
    ValueSetScalarPromoteExactInt64(outV, log(leftS.scalar) / log(rightS.scalar))
    return TRUE
  end if
  if fnId = FUNC_ATAN2 then
    ValueSetScalarPromoteExactInt64(outV, CalcAtan2(leftS.scalar, rightS.scalar))
    return TRUE
  end if
  if fnId = FUNC_HYPOT then
    ValueSetScalarPromoteExactInt64(outV, CalcHypot(leftS.scalar, rightS.scalar))
    return TRUE
  end if
  return FALSE
end function

private function ApplyScalarBinaryMathFunctionValues(byref leftV as EvalValue, byref rightV as EvalValue, byval fnId as Integer, byref outV as EvalValue) as Boolean
  return MapBinaryBroadcastScalars(MAP_BINARY_OP_SCALAR_MATH, leftV, rightV, 0, OP_BIT_NONE, fnId, outV)
end function

private function TryShiftLeftUInt64MaybeExact( _
  byref outV as EvalValue, _
  byval leftU as ULongInt, _
  byval leftScalar as Double, _
  byval shiftU as ULongInt) as Boolean
  if shiftU > 63ull then return FALSE
  if shiftU > 0ull andalso leftU > (FB_U64_MAX shr CInt(shiftU)) then
    ValueSetScalarPromoteExactInt64(outV, leftScalar * pow(2.0, CDbl(shiftU)))
    return TRUE
  end if
  ValueSetUInt64(outV, leftU shl CInt(shiftU))
  return TRUE
end function

private function ValueApplyBinaryInt64Scalars(byref leftS as ScalarValue, byref rightS as ScalarValue, byval op as OperatorBitNameId, byref outV as EvalValue) as Boolean
  dim requiresIntegers as Boolean = (op = OP_BIT_SHL orelse op = OP_BIT_SHR orelse op = OP_BIT_AND orelse op = OP_BIT_XOR orelse op = OP_BIT_OR orelse op = OP_BIT_MOD)
  dim l as LongInt, r as LongInt

  if op = OP_BIT_SHL then
    dim luShl as ULongInt, ruShl as ULongInt
    if TryGetExactNonNegativeUInt64Scalar(leftS, luShl) andalso TryGetExactNonNegativeUInt64Scalar(rightS, ruShl) then
      return TryShiftLeftUInt64MaybeExact(outV, luShl, leftS.scalar, ruShl)
    end if
  end if

  if leftS.exactUInt64Valid andalso rightS.exactUInt64Valid andalso _
     ((leftS.exactInt64Valid = FALSE) orelse (rightS.exactInt64Valid = FALSE)) then
    dim lu as ULongInt = leftS.exactUInt64
    dim ru as ULongInt = rightS.exactUInt64
    select case op
      case OP_BIT_SHL
        return TryShiftLeftUInt64MaybeExact(outV, lu, leftS.scalar, ru)
      case OP_BIT_SHR
        if ru > 63ull then return FALSE
        ValueSetUInt64(outV, lu shr CInt(ru))
        return TRUE
      case OP_BIT_AND
        ValueSetUInt64(outV, lu and ru)
        return TRUE
      case OP_BIT_XOR
        ValueSetUInt64(outV, lu xor ru)
        return TRUE
      case OP_BIT_OR
        ValueSetUInt64(outV, lu or ru)
        return TRUE
      case OP_BIT_MOD
        if ru = 0ull then return FALSE
        ValueSetUInt64(outV, lu mod ru)
        return TRUE
    end select
  end if

  if requiresIntegers then
    if (TryGetExactInt64Scalar(leftS, l) = FALSE) orelse (TryGetExactInt64Scalar(rightS, r) = FALSE) then
      if op = OP_BIT_MOD then
        SetModuloIntegerOperandsError()
      else
        SetBitwiseIntegerOperandsError()
      end if
      return FALSE
    end if
  end if

  select case op
    case OP_BIT_SHL
      if r < 0 orelse r > 63 then return FALSE
      ValueSetInt64(outV, l shl r)
    case OP_BIT_SHR
      if r < 0 orelse r > 63 then return FALSE
      ValueSetInt64(outV, l shr r)
    case OP_BIT_AND
      ValueSetInt64(outV, l and r)
    case OP_BIT_XOR
      ValueSetInt64(outV, l xor r)
    case OP_BIT_OR
      ValueSetInt64(outV, l or r)
    case OP_BIT_MOD
      if r = 0 then return FALSE
      ValueSetInt64(outV, l mod r)
    case else
      return FALSE
  end select
  return TRUE
end function

private function ValueApplyBinaryInt64(byref leftV as EvalValue, byref rightV as EvalValue, byval op as OperatorBitNameId, byref outV as EvalValue) as Boolean
  return MapBinaryBroadcastScalars(MAP_BINARY_OP_INT64, leftV, rightV, 0, op, -1, outV)
end function

private function CompareScalarArrayLex(byval scalarV as Double, byref arrV as EvalValue) as Integer
  dim arrLen as Integer = ValueArrayLen(arrV)
  if arrLen <= 0 then return 1
  dim firstSv as ScalarValue = arrV.arr(lbound(arrV.arr))
  dim sm as LongInt = RoundHalfUpDoubleToLongInt(scalarV * 1000.0)
  dim fm as LongInt
  if ScalarIsTime(firstSv) then
    fm = TimeTotalMsFromScalarValue(firstSv)
  else
    fm = RoundHalfUpDoubleToLongInt(firstSv.scalar * 1000.0)
  end if
  if sm < fm then return -1
  if sm > fm then return 1
  if arrLen = 1 then return 0
  return -1
end function

private function CompareEvalValues(byref leftV as EvalValue, byref rightV as EvalValue, byref cmp as Integer) as Boolean
  if leftV.kind = VK_SCALAR andalso rightV.kind = VK_SCALAR then
    if ScalarIsTime(leftV.scalarValue) orelse ScalarIsTime(rightV.scalarValue) then
      dim lm as LongInt
      dim rm as LongInt
      if ScalarIsTime(leftV.scalarValue) then
        lm = TimeTotalMsFromScalarValue(leftV.scalarValue)
      else
        lm = RoundHalfUpDoubleToLongInt(leftV.scalar * 1000.0)
      end if
      if ScalarIsTime(rightV.scalarValue) then
        rm = TimeTotalMsFromScalarValue(rightV.scalarValue)
      else
        rm = RoundHalfUpDoubleToLongInt(rightV.scalar * 1000.0)
      end if
      if lm < rm then
        cmp = -1
      elseif lm > rm then
        cmp = 1
      else
        cmp = 0
      end if
      return TRUE
    end if
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
  dim useMsLex as Boolean = (EvalValueInvolvesTime(leftV) orelse EvalValueInvolvesTime(rightV))
  for i = 0 to minLen - 1
    dim lsv as ScalarValue = leftV.arr(leftLb + i)
    dim rsv as ScalarValue = rightV.arr(rightLb + i)
    if useMsLex then
      dim lvMs as LongInt
      dim rvMs as LongInt
      if ScalarIsTime(lsv) then
        lvMs = TimeTotalMsFromScalarValue(lsv)
      else
        lvMs = RoundHalfUpDoubleToLongInt(lsv.scalar * 1000.0)
      end if
      if ScalarIsTime(rsv) then
        rvMs = TimeTotalMsFromScalarValue(rsv)
      else
        rvMs = RoundHalfUpDoubleToLongInt(rsv.scalar * 1000.0)
      end if
      if lvMs < rvMs then
        cmp = -1
        return TRUE
      elseif lvMs > rvMs then
        cmp = 1
        return TRUE
      end if
    else
      dim lv as Double = lsv.scalar
      dim rv as Double = rsv.scalar
      if lv < rv then
        cmp = -1
        return TRUE
      elseif lv > rv then
        cmp = 1
        return TRUE
      end if
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

private function ApplyComparison(byref leftV as EvalValue, byref rightV as EvalValue, byval op as OperatorCmpNameId, byref outV as EvalValue) as Boolean
  if leftV.kind = VK_SCALAR andalso rightV.kind = VK_SCALAR then
    if ScalarIsTime(leftV.scalarValue) orelse ScalarIsTime(rightV.scalarValue) then
      if (ScalarIsTime(leftV.scalarValue) = FALSE andalso IsNonFiniteValue(leftV.scalar)) orelse _
         (ScalarIsTime(rightV.scalarValue) = FALSE andalso IsNonFiniteValue(rightV.scalar)) then
        SetIncompatibleOperandsError()
        return FALSE
      end if
    end if
  end if
  '' IEEE: any scalar NaN makes comparisons unordered — only ``!=`` / ``<>`` is true.
  if leftV.kind = VK_SCALAR andalso rightV.kind = VK_SCALAR then
    if IsNaNValue(leftV.scalar) orelse IsNaNValue(rightV.scalar) then
      select case op
        case OP_CMP_NONE
          return FALSE
        case OP_CMP_NE
          ValueSetInt64(outV, 1)
        case else
          ValueSetInt64(outV, 0)
      end select
      return TRUE
    end if
  end if

  dim cmp as Integer = 0
  if CompareEvalValues(leftV, rightV, cmp) = FALSE then return FALSE
  dim isTrue as Boolean = FALSE
  select case op
    case OP_CMP_EQ
      isTrue = (cmp = 0)
    case OP_CMP_NE
      isTrue = (cmp <> 0)
    case OP_CMP_LT
      isTrue = (cmp < 0)
    case OP_CMP_LE
      isTrue = (cmp <= 0)
    case OP_CMP_GT
      isTrue = (cmp > 0)
    case OP_CMP_GE
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
  if IsNaNValue(v.scalar) then return FALSE
  return (v.scalar <> 0)
end function

private sub ValueSetBoolResult(byval b as Boolean, byref outV as EvalValue)
  if b then
    ValueSetInt64(outV, 1)
  else
    ValueSetInt64(outV, 0)
  end if
end sub

private function ApplyInt64ParserOp(byref leftV as EvalValue, byref rightV as EvalValue, byval op as OperatorBitNameId, byref outV as EvalValue) as Boolean
  if EvalValueInvolvesTime(leftV) orelse EvalValueInvolvesTime(rightV) then
    SetIncompatibleOperandsError()
    return FALSE
  end if
  if ValueApplyBinaryInt64(leftV, rightV, op, outV) = FALSE then
    SetIncompatibleOperandsError()
    return FALSE
  end if
  return TRUE
end function

private function ApplyBinaryParserOp(byref leftV as EvalValue, byref rightV as EvalValue, byval op as UByte, byref outV as EvalValue) as Boolean
  if ValueApplyBinaryTimeAware(leftV, rightV, op, outV) then
    return (parseError = 0)
  end if
  if ValueApplyBinary(leftV, rightV, op, outV) = FALSE then
    SetIncompatibleOperandsError()
    return FALSE
  end if
  return TRUE
end function

private sub ApplyInt64ParserOpInPlace(byref leftV as EvalValue, byref rightV as EvalValue, byval op as OperatorBitNameId)
  dim outV as EvalValue
  if ApplyInt64ParserOp(leftV, rightV, op, outV) then leftV = outV
end sub

private sub ApplyBinaryParserOpInPlace(byref leftV as EvalValue, byref rightV as EvalValue, byval op as UByte)
  dim outV as EvalValue
  if ApplyBinaryParserOp(leftV, rightV, op, outV) then leftV = outV
end sub

private sub ApplyComparisonParserOpInPlace(byref leftV as EvalValue, byref rightV as EvalValue, byval op as OperatorCmpNameId)
  dim outV as EvalValue
  if ApplyComparison(leftV, rightV, op, outV) = FALSE then
    SetIncompatibleOperandsError()
  else
    leftV = outV
  end if
end sub

private function EnsureExactArgCount(args() as EvalValue, byval expectedCount as Integer, byref fnName as String) as Boolean
  dim argc as Integer = ubound(args) + 1
  if argc <> expectedCount then
    SetExactArgCountError(fnName, expectedCount, argc)
    return FALSE
  end if
  return TRUE
end function

private function ArgsContainNonFinite(args() as EvalValue) as Boolean
  if ubound(args) = -1 then return FALSE
  for i as Integer = lbound(args) to ubound(args)
    if args(i).kind = VK_SCALAR then
      if IsNonFiniteValue(args(i).scalar) then return TRUE
    else
      for j as Integer = lbound(args(i).arr) to ubound(args(i).arr)
        if IsNonFiniteValue(args(i).arr(j).scalar) then return TRUE
      next j
    end if
  next i
  return FALSE
end function

private function ValidateIntegerRepresentableArgs(args() as EvalValue, byref fnName as String, byval allowNonFiniteForFormat as Boolean) as Boolean
  if ubound(args) = -1 then return TRUE
  for i as Integer = lbound(args) to ubound(args)
    if args(i).kind = VK_SCALAR then
      if IsNonFiniteValue(args(i).scalar) then
        if allowNonFiniteForFormat = FALSE then SetIntegerValuesError(fnName): return FALSE
      elseif (args(i).exactInt64Valid = FALSE) andalso (args(i).exactUInt64Valid = FALSE) then
        dim tmpFmt as String
        if FormatHexScalar(args(i).scalar, tmpFmt, TRUE) = FALSE then SetIntegerValuesError(fnName): return FALSE
      end if
    else
      for j as Integer = lbound(args(i).arr) to ubound(args(i).arr)
        if IsNonFiniteValue(args(i).arr(j).scalar) then
          if allowNonFiniteForFormat = FALSE then SetIntegerValuesError(fnName): return FALSE
        elseif (args(i).arr(j).exactInt64Valid = FALSE) andalso (args(i).arr(j).exactUInt64Valid = FALSE) then
          dim tmpFmt as String
          if FormatHexScalar(args(i).arr(j).scalar, tmpFmt, TRUE) = FALSE then SetIntegerValuesError(fnName): return FALSE
        end if
      next j
    end if
  next i
  return TRUE
end function

private function ValidateBuiltinCallArgs(byval fnId as Integer, byref fnName as String, args() as EvalValue) as Boolean
  if HasBuiltinFlag(fnId, BUILTIN_FLAG_FORMAT) then
    return ValidateIntegerRepresentableArgs(args(), fnName, TRUE)
  end if
  if HasBuiltinFlag(fnId, BUILTIN_FLAG_INTEGER_ONLY) then
    return ValidateIntegerRepresentableArgs(args(), fnName, FALSE)
  end if
  if HasBuiltinFlag(fnId, BUILTIN_FLAG_NON_CALCULATING) then
    return TRUE
  end if
  if HasBuiltinFlag(fnId, BUILTIN_FLAG_FINITE_REQUIRED) andalso ArgsContainNonFinite(args()) then
    SetNumericErrorInFunction(fnName)
    return FALSE
  end if
  return TRUE
end function

private function IsPercentageTail() as Boolean
  dim p as ZString ptr = pStream
  while (p[0] = CHAR_SPACE) orelse (p[0] = CHAR_TAB) orelse (p[0] = CHAR_LF) orelse (p[0] = CHAR_CR)
    p += 1
  wend

  dim ch as UByte = p[0]
  if (ch = CHAR_NUL) orelse (ch = CHAR_RPAREN) orelse (ch = CHAR_PLUS) orelse (ch = CHAR_MINUS) _
     orelse (ch = CHAR_COMMA) orelse (ch = CHAR_SEMICOLON) orelse (ch = CHAR_RBRACKET) orelse (ch = CHAR_RBRACE) then
    return TRUE
  end if
  return FALSE
end function

private function IsImplicitMulStart() as Boolean
  ' Allow implicit multiplication only for parenthesized expressions: x(y+z) => x*(y+z)
  if pStream[0] = CHAR_LPAREN then return TRUE
  return FALSE
end function

private function TryParsePrefixedUIntLiteral(byval prefixChar as UByte, byval radix as ULongInt, byref outV as ULongInt) as Boolean
  dim p as ZString ptr = pStream
  if p[0] <> CHAR_DIGIT_0 then return FALSE
  dim prefixUpper as UByte = prefixChar
  if prefixUpper >= CHAR_LC_A andalso prefixUpper <= CHAR_LC_Z then
    prefixUpper -= (CHAR_LC_A - CHAR_A)
  end if
  if p[1] <> prefixChar andalso p[1] <> prefixUpper then return FALSE
  p += 2
  dim parsed as ULongInt = 0
  dim digits as Integer = 0
  while TRUE
    dim c as UByte = p[0]
    dim d as Integer = -1
    if c >= CHAR_DIGIT_0 andalso c <= CHAR_DIGIT_9 then
      d = c - CHAR_DIGIT_0
    elseif c >= CHAR_LC_A andalso c <= CHAR_LC_F then
      d = 10 + (c - CHAR_LC_A)
    elseif c >= CHAR_A andalso c <= CHAR_F then
      d = 10 + (c - CHAR_A)
    else
      exit while
    end if
    if d < 0 orelse CULngInt(d) >= radix then exit while
    if parsed > ((FB_U64_MAX - CULngInt(d)) \ radix) then
      return FALSE
    end if
    parsed = parsed * radix + CULngInt(d)
    digits += 1
    p += 1
  wend
  if digits = 0 then return FALSE
  pStream = p
  outV = parsed
  return TRUE
end function

declare function ArgScalarWalkNext(args() as EvalValue, byref argIdx as Integer, byref elemIdx as Integer, byref outV as Double) as Boolean
declare function ArgScalarValueWalkNext(args() as EvalValue, byref argIdx as Integer, byref elemIdx as Integer, byref outV as ScalarValue) as Boolean

private function CountFlattenedArgs(args() as EvalValue) as Integer
  dim count as Integer = 0
  dim i as Integer
  for i = lbound(args) to ubound(args)
    if args(i).kind = VK_SCALAR then
      count += 1
    else
      count += ValueArrayLen(args(i))
    end if
  next i
  return count
end function

private function CollectArgsAsFlat(args() as EvalValue, flat() as Double) as Integer
  dim count as Integer = CountFlattenedArgs(args())
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
    SetAtLeastOneArgError(fnName)
    return 0
  end if
  return count
end function

private function CollectArgsAsScalarValues(args() as EvalValue, vals() as ScalarValue) as Integer
  dim count as Integer = CountFlattenedArgs(args())
  if count <= 0 then return 0
  redim vals(0 to count - 1)

  dim outPos as Integer = 0
  dim argIdx as Integer = lbound(args)
  dim elemIdx as Integer = -1
  dim item as ScalarValue
  while ArgScalarValueWalkNext(args(), argIdx, elemIdx, item)
    vals(outPos) = item
    outPos += 1
  wend
  return count
end function

private function CollectRequiredArgsAsScalarValues(args() as EvalValue, vals() as ScalarValue, byref fnName as String) as Integer
  dim count as Integer = CollectArgsAsScalarValues(args(), vals())
  if count <= 0 then
    SetAtLeastOneArgError(fnName)
    return 0
  end if
  return count
end function

private function CopySingleArgToScalarValues(byref a as EvalValue, vals() as ScalarValue, byval reverseOrder as Boolean) as Integer
  if a.kind = VK_SCALAR then
    redim vals(0 to 0)
    vals(0) = a.scalarValue
    return 1
  end if
  dim c as Integer = ValueArrayLen(a)
  if c <= 0 then return 0
  redim vals(0 to c - 1)
  dim i as Integer
  if reverseOrder then
    for i = 0 to c - 1
      vals(i) = a.arr(ubound(a.arr) - i)
    next i
  else
    for i = 0 to c - 1
      vals(i) = a.arr(lbound(a.arr) + i)
    next i
  end if
  return c
end function

private function ArgWalkNextPosition(args() as EvalValue, byref argIdx as Integer, byref elemIdx as Integer, byref srcArgIdx as Integer, byref srcElemIdx as Integer, byref isScalar as Boolean) as Boolean
  if ubound(args) = -1 then return FALSE
  do while argIdx <= ubound(args)
    if args(argIdx).kind = VK_SCALAR then
      srcArgIdx = argIdx
      srcElemIdx = -1
      isScalar = TRUE
      argIdx += 1
      elemIdx = -1
      return TRUE
    else
      if elemIdx = -1 then elemIdx = lbound(args(argIdx).arr)
      if elemIdx <= ubound(args(argIdx).arr) then
        srcArgIdx = argIdx
        srcElemIdx = elemIdx
        isScalar = FALSE
        elemIdx += 1
        return TRUE
      end if
      argIdx += 1
      elemIdx = -1
    end if
  loop
  return FALSE
end function

private function ArgScalarWalkNext(args() as EvalValue, byref argIdx as Integer, byref elemIdx as Integer, byref outV as Double) as Boolean
  dim srcArgIdx as Integer
  dim srcElemIdx as Integer
  dim isScalar as Boolean
  if ArgWalkNextPosition(args(), argIdx, elemIdx, srcArgIdx, srcElemIdx, isScalar) = FALSE then return FALSE
  if isScalar then
    outV = args(srcArgIdx).scalar
  else
    outV = args(srcArgIdx).arr(srcElemIdx).scalar
  end if
  return TRUE
end function

private function ArgScalarValueWalkNext(args() as EvalValue, byref argIdx as Integer, byref elemIdx as Integer, byref outV as ScalarValue) as Boolean
  dim srcArgIdx as Integer
  dim srcElemIdx as Integer
  dim isScalar as Boolean
  if ArgWalkNextPosition(args(), argIdx, elemIdx, srcArgIdx, srcElemIdx, isScalar) = FALSE then return FALSE
  if isScalar then
    outV = args(srcArgIdx).scalarValue
  else
    outV = args(srcArgIdx).arr(srcElemIdx)
  end if
  return TRUE
end function

'' sum / product / min / max: preserve exact uint64/int64 metadata when every operand carries exact integer state.
private function TryAggSimpleExactInteger(args() as EvalValue, byval fnId as Integer, byref outV as EvalValue) as Boolean
  dim argIdx as Integer = lbound(args)
  dim elemIdx as Integer = -1
  dim sv as ScalarValue
  dim allNnU as Boolean = TRUE
  dim allSwI as Boolean = TRUE
  dim gotAny as Boolean = FALSE
  while ArgScalarValueWalkNext(args(), argIdx, elemIdx, sv)
    gotAny = TRUE
    dim uProbe as ULongInt
    dim liProbe as LongInt
    dim nnU as Boolean = TryGetExactNonNegativeUInt64Scalar(sv, uProbe)
    dim swI as Boolean = TryGetExactSignedInt64NoUIntWrapScalar(sv, liProbe)
    if (nnU = FALSE) andalso (swI = FALSE) then return FALSE
    if nnU = FALSE then allNnU = FALSE
    if swI = FALSE then allSwI = FALSE
  wend
  if gotAny = FALSE then return FALSE

  if fnId = FUNC_PRODUCT then
    argIdx = lbound(args)
    elemIdx = -1
    dim productMag as ULongInt = 1
    dim isNegativeProduct as Boolean = FALSE
    while ArgScalarValueWalkNext(args(), argIdx, elemIdx, sv)
      dim termMag as ULongInt
      if TryGetExactNonNegativeUInt64Scalar(sv, termMag) then
        ' termMag already contains the unsigned magnitude.
      else
        dim termI as LongInt
        if TryGetExactSignedInt64NoUIntWrapScalar(sv, termI) = FALSE then return FALSE
        if termI < 0 then
          isNegativeProduct = not isNegativeProduct
          if termI = FB_I64_MIN then
            termMag = FB_I64_MIN_MAG_U
          else
            termMag = CULngInt(-termI)
          end if
        else
          termMag = CULngInt(termI)
        end if
      end if

      dim nextMag as ULongInt
      if TryMulULongChecked(productMag, termMag, nextMag) = FALSE then return FALSE
      productMag = nextMag
    wend
    if isNegativeProduct then
      if productMag > FB_I64_MIN_MAG_U then return FALSE
      if productMag = FB_I64_MIN_MAG_U then
        ValueSetInt64(outV, FB_I64_MIN)
      else
        ValueSetInt64(outV, -CLngInt(productMag))
      end if
    else
      ValueSetUInt64(outV, productMag)
    end if
    return TRUE
  end if

  if allNnU then
    argIdx = lbound(args)
    elemIdx = -1
    dim accU as ULongInt = 0
    dim hasBestU as Boolean = FALSE
    dim bestU as ULongInt
    while ArgScalarValueWalkNext(args(), argIdx, elemIdx, sv)
      dim u2 as ULongInt
      TryGetExactNonNegativeUInt64Scalar(sv, u2)
      if fnId = FUNC_SUM then
        dim nextU as ULongInt
        if TryAddULongChecked(accU, u2, nextU) = FALSE then return FALSE
        accU = nextU
      elseif fnId = FUNC_MIN then
        if (hasBestU = FALSE) orelse (u2 < bestU) then bestU = u2: hasBestU = TRUE
      else
        if (hasBestU = FALSE) orelse (u2 > bestU) then bestU = u2: hasBestU = TRUE
      end if
    wend
    if fnId = FUNC_SUM then ValueSetUInt64(outV, accU) else ValueSetUInt64(outV, bestU)
    return TRUE
  elseif allSwI then
    argIdx = lbound(args)
    elemIdx = -1
    dim accI as LongInt = 0
    dim hasBestI as Boolean = FALSE
    dim bestI as LongInt
    while ArgScalarValueWalkNext(args(), argIdx, elemIdx, sv)
      dim i2 as LongInt
      TryGetExactSignedInt64NoUIntWrapScalar(sv, i2)
      if fnId = FUNC_SUM then
        dim nextI as LongInt
        if TryAddInt64(accI, i2, nextI) = FALSE then return FALSE
        accI = nextI
      elseif fnId = FUNC_MIN then
        if (hasBestI = FALSE) orelse (i2 < bestI) then bestI = i2: hasBestI = TRUE
      else
        if (hasBestI = FALSE) orelse (i2 > bestI) then bestI = i2: hasBestI = TRUE
      end if
    wend
    if fnId = FUNC_SUM then ValueSetInt64(outV, accI) else ValueSetInt64(outV, bestI)
    return TRUE
  end if
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

private sub EnsureEvalArgsCapacity(args() as EvalValue, byref argsCount as Integer, byref argsCap as Integer)
  if argsCount < argsCap then exit sub
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
end sub

private sub AppendEvalArg(args() as EvalValue, byref argsCount as Integer, byref argsCap as Integer, byref value as EvalValue)
  EnsureEvalArgsCapacity(args(), argsCount, argsCap)
  args(argsCount) = value
  argsCount += 1
end sub

private function TryParseCallArguments(args() as EvalValue, byref argsCount as Integer, byref argsCap as Integer) as Boolean
  if pStream[0] = CHAR_COMMA then
    SetUnexpectedCommaError()
    return FALSE
  end if
  if pStream[0] = CHAR_RPAREN then
    return TRUE
  end if
  do
    dim a as EvalValue = ParseExpression()
    if parseError then return FALSE
    AppendEvalArg(args(), argsCount, argsCap, a)
    SkipSpaces()
    dim hasComma as Boolean
    if TryConsumeCommaArgSeparator(hasComma) = FALSE then return FALSE
    if hasComma = FALSE then exit do
  loop
  return TRUE
end function

private function ScalarSortLess(byref a as ScalarValue, byref b as ScalarValue) as Boolean
  if ScalarIsTime(a) orelse ScalarIsTime(b) then
    dim am as LongInt
    dim bm as LongInt
    if ScalarIsTime(a) then
      am = TimeTotalMsFromScalarValue(a)
    else
      am = RoundHalfUpDoubleToLongInt(a.scalar * 1000.0)
    end if
    if ScalarIsTime(b) then
      bm = TimeTotalMsFromScalarValue(b)
    else
      bm = RoundHalfUpDoubleToLongInt(b.scalar * 1000.0)
    end if
    return am < bm
  end if
  dim aNan as Boolean = IsNaNValue(a.scalar)
  dim bNan as Boolean = IsNaNValue(b.scalar)
  if aNan then return (bNan = FALSE)
  if bNan then return FALSE
  return a.scalar < b.scalar
end function

private function ScalarSortGreater(byref a as ScalarValue, byref b as ScalarValue) as Boolean
  if ScalarIsTime(a) orelse ScalarIsTime(b) then
    dim am as LongInt
    dim bm as LongInt
    if ScalarIsTime(a) then
      am = TimeTotalMsFromScalarValue(a)
    else
      am = RoundHalfUpDoubleToLongInt(a.scalar * 1000.0)
    end if
    if ScalarIsTime(b) then
      bm = TimeTotalMsFromScalarValue(b)
    else
      bm = RoundHalfUpDoubleToLongInt(b.scalar * 1000.0)
    end if
    return am > bm
  end if
  dim aNan as Boolean = IsNaNValue(a.scalar)
  dim bNan as Boolean = IsNaNValue(b.scalar)
  if bNan then return (aNan = FALSE)
  if aNan then return FALSE
  return a.scalar > b.scalar
end function

private sub SortScalarValueArray(a() as ScalarValue)
  dim lo as Integer = lbound(a)
  dim hi as Integer = ubound(a)
  if hi <= lo then exit sub
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
      dim pivot as ScalarValue = a(midIdx)
      dim i as Integer = lo
      dim j as Integer = hi
      do
        while ScalarSortLess(a(i), pivot)
          i += 1
        wend
        while ScalarSortGreater(a(j), pivot)
          j -= 1
        wend
        if i <= j then
          dim t as ScalarValue = a(i)
          a(i) = a(j)
          a(j) = t
          i += 1
          j -= 1
        end if
      loop while i <= j
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
    dim x as Integer
    for x = lo + 1 to hi
      dim v as ScalarValue = a(x)
      dim y as Integer = x - 1
      while y >= lo andalso ScalarSortGreater(a(y), v)
        a(y + 1) = a(y)
        y -= 1
      wend
      a(y + 1) = v
    next x
  loop
end sub

private sub ReverseScalarValueArrayInPlace(a() as ScalarValue, byval count as Integer)
  dim i as Integer
  for i = 0 to (count \ 2) - 1
    dim t as ScalarValue = a(i)
    a(i) = a(count - 1 - i)
    a(count - 1 - i) = t
  next i
end sub

private sub ValueSetArrayFromScalarValues(byref outV as EvalValue, vals() as ScalarValue)
  ValueSetScalar(outV, 0)
  outV.kind = VK_ARRAY
  redim outV.arr(lbound(vals) to ubound(vals))
  dim i as Integer
  for i = lbound(vals) to ubound(vals)
    outV.arr(i) = vals(i)
  next i
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

' Returns: 1 if outV has final passthrough result; 0 if vals()/c are collected; -1 on error (parseError set).
private function TrySingleArgPassthroughOrCollect( _
  args() as EvalValue, _
  byref fnName as String, _
  byval reverseSingleArray as Boolean, _
  byref outV as EvalValue, _
  vals() as ScalarValue, _
  byref c as Integer _
) as Integer
  if ubound(args) = -1 then
    SetAtLeastOneArgError(fnName)
    return -1
  end if

  if ubound(args) = 0 then
    if args(0).kind = VK_SCALAR then
      c = CopySingleArgToScalarValues(args(0), vals(), FALSE)
      ValueSetArrayFromScalarValues(outV, vals())
      return 1
    end if
    c = CopySingleArgToScalarValues(args(0), vals(), reverseSingleArray)
    if c <= 0 then
      SetAtLeastOneArgError(fnName)
      return -1
    end if
    return 0
  end if

  c = CollectRequiredArgsAsScalarValues(args(), vals(), fnName)
  if c <= 0 then return -1
  return 0
end function

private function CallArgsInvolveTime(args() as EvalValue) as Boolean
  dim i as Integer
  if ubound(args) < lbound(args) then return FALSE
  for i = lbound(args) to ubound(args)
    if EvalValueInvolvesTime(args(i)) then return TRUE
  next i
  return FALSE
end function

private function CollectRequiredArgsAsFlatTimeMs(args() as EvalValue, flat() as Double, byref fnName as String) as Integer
  dim argIdx as Integer = lbound(args)
  dim elemIdx as Integer = -1
  dim count as Integer = 0
  dim sv as ScalarValue
  while ArgScalarValueWalkNext(args(), argIdx, elemIdx, sv)
    if ScalarIsTime(sv) = FALSE then
      SetParseError(FB_STR_TIME_EXPECTS_TIME_ARG)
      return -1
    end if
    if count = 0 then
      redim flat(0 to 0)
    else
      redim preserve flat(0 to count)
    end if
    flat(count) = CDbl(TimeTotalMsFromScalarValue(sv))
    count += 1
  wend
  if count <= 0 then
    SetAtLeastOneArgError(fnName)
    return -1
  end if
  return count
end function

private function MedianFromDoubleFlatInPlace(a() as Double, byval c as Integer) as Double
  dim midIdx as Integer = c \ 2
  dim leftIdx as Integer = 0
  dim rightIdx as Integer = c - 1
  dim kIdx as Integer = midIdx
  dim i as Integer
  do while leftIdx < rightIdx
    dim pivot as Double = a((leftIdx + rightIdx) \ 2)
    i = leftIdx
    dim j as Integer = rightIdx
    do
      while a(i) < pivot
        i += 1
      wend
      while a(j) > pivot
        j -= 1
      wend
      if i <= j then
        SwapDouble(a(i), a(j))
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
  dim upper as Double = a(kIdx)
  if (c and 1) = 1 then
    return upper
  end if
  dim lower as Double = a(0)
  for i = 1 to midIdx - 1
    if a(i) > lower then lower = a(i)
  next i
  return (lower + upper) / 2.0
end function

private function TryBuiltinDispatchWithTime(byval fnId as Integer, byref fnName as String, args() as EvalValue, byref outV as EvalValue) as Boolean
  if (fnId = FUNC_MILLISECONDS) orelse (fnId = FUNC_SECONDS) orelse (fnId = FUNC_MINUTES) orelse (fnId = FUNC_HOURS) orelse (fnId = FUNC_DAYS) then
    if EnsureExactArgCount(args(), 1, fnName) = FALSE then return TRUE
    if args(0).kind = VK_SCALAR then
      if ScalarIsTime(args(0).scalarValue) = FALSE then
        SetParseError(FB_STR_TIME_EXPECTS_TIME_ARG)
        return TRUE
      end if
      dim msArg as LongInt = TimeTotalMsFromScalarValue(args(0).scalarValue)
      select case fnId
        case FUNC_MILLISECONDS
          ValueSetInt64(outV, msArg)
        case FUNC_SECONDS
          ValueSetScalarPromoteExactInt64(outV, CDbl(msArg) / 1000.0)
        case FUNC_MINUTES
          ValueSetScalarPromoteExactInt64(outV, CDbl(msArg) / 60000.0)
        case FUNC_HOURS
          ValueSetScalarPromoteExactInt64(outV, CDbl(msArg) / 3600000.0)
        case FUNC_DAYS
          ValueSetScalarPromoteExactInt64(outV, CDbl(msArg) / 86400000.0)
      end select
      return TRUE
    elseif args(0).kind = VK_ARRAY then
      dim lbA as Integer = lbound(args(0).arr)
      dim ubA as Integer = ubound(args(0).arr)
      ValueInitArrayLike(outV, lbA, ubA)
      dim iA as Integer
      for iA = lbA to ubA
        if ScalarIsTime(args(0).arr(iA)) = FALSE then
          SetParseError(FB_STR_TIME_EXPECTS_TIME_ARG)
          return TRUE
        end if
        dim msElem as LongInt = TimeTotalMsFromScalarValue(args(0).arr(iA))
        dim rConv as EvalValue
        select case fnId
          case FUNC_MILLISECONDS
            ValueSetInt64(rConv, msElem)
          case FUNC_SECONDS
            ValueSetScalarPromoteExactInt64(rConv, CDbl(msElem) / 1000.0)
          case FUNC_MINUTES
            ValueSetScalarPromoteExactInt64(rConv, CDbl(msElem) / 60000.0)
          case FUNC_HOURS
            ValueSetScalarPromoteExactInt64(rConv, CDbl(msElem) / 3600000.0)
          case FUNC_DAYS
            ValueSetScalarPromoteExactInt64(rConv, CDbl(msElem) / 86400000.0)
        end select
        ValueSetArrayElemFromScalar(outV, iA, rConv)
      next iA
      return TRUE
    else
      SetParseError(FB_STR_TIME_EXPECTS_TIME_ARG)
      return TRUE
    end if
  end if

  if CallArgsInvolveTime(args()) = FALSE then return FALSE

  if fnId = FUNC_PRODUCT then
    SetIncompatibleOperandsError()
    return TRUE
  end if

  select case fnId
    case FUNC_SORT, FUNC_REVERSE, FUNC_UNPACK
      return FALSE
    case FUNC_VARIANCE, FUNC_STDDEV
      SetIncompatibleOperandsError()
      return TRUE
    case FUNC_SUM, FUNC_MIN, FUNC_MAX, FUNC_AVG, FUNC_MEAN
      dim argIdx as Integer = lbound(args)
      dim elemIdx as Integer = -1
      dim sv as ScalarValue
      dim aggMode as Integer = 1
      dim accMs as LongInt = 0
      dim accInit as Boolean = FALSE
      dim itemCount as Integer = 0
      if fnId = FUNC_MIN then
        aggMode = 3
      elseif fnId = FUNC_MAX then
        aggMode = 4
      end if
      while ArgScalarValueWalkNext(args(), argIdx, elemIdx, sv)
        if ScalarIsTime(sv) = FALSE then
          SetParseError(FB_STR_TIME_EXPECTS_TIME_ARG)
          return TRUE
        end if
        dim curMs as LongInt = TimeTotalMsFromScalarValue(sv)
        if aggMode = 1 then
          if TryAddTimeMsChecked(accMs, curMs, accMs) = FALSE then
            SetIncompatibleOperandsError()
            return TRUE
          end if
        elseif aggMode = 3 then
          if accInit = FALSE orelse curMs < accMs then accMs = curMs
          accInit = TRUE
        else
          if accInit = FALSE orelse curMs > accMs then accMs = curMs
          accInit = TRUE
        end if
        itemCount += 1
      wend
      if itemCount <= 0 then
        SetAtLeastOneArgError(fnName)
        return TRUE
      end if
      if (fnId = FUNC_AVG) orelse (fnId = FUNC_MEAN) then
        dim avgD as Double = CDbl(accMs) / CDbl(itemCount)
        ValueSetTimeMs(outV, RoundHalfUpDoubleToLongInt(avgD))
        return TRUE
      end if
      ValueSetTimeMs(outV, accMs)
      return TRUE
    case FUNC_MEDIAN
      dim flatMed() as Double
      dim cM as Integer = CollectRequiredArgsAsFlatTimeMs(args(), flatMed(), fnName)
      if cM < 0 then return TRUE
      if cM = 1 then
        ValueSetTimeMs(outV, RoundHalfUpDoubleToLongInt(flatMed(0)))
        return TRUE
      end if
      dim med as Double = MedianFromDoubleFlatInPlace(flatMed(), cM)
      ValueSetTimeMs(outV, RoundHalfUpDoubleToLongInt(med))
      return TRUE
    case else
      SetIncompatibleOperandsError()
      return TRUE
  end select
end function

private function ParseFunctionCall(byref fnName as String) as EvalValue
  dim outV as EvalValue
  if pStream[0] <> CHAR_LPAREN then SetMissingOpeningBracketError(): return outV
  pStream += 1
  SkipSpaces()

  dim args() as EvalValue
  dim argsCount as Integer = 0
  dim argsCap as Integer = 0
  if TryParseCallArguments(args(), argsCount, argsCap) = FALSE then return outV

  if TryConsumeClosingParenOrSetError() = FALSE then return outV
  if parseError then return outV

  if argsCount = 0 then
    erase args
  elseif argsCap <> argsCount then
    redim preserve args(0 to argsCount - 1)
  end if

  dim fn as String = lcase(fnName)
  dim fnId as Integer = TryFindBuiltinFunctionId(fn)
  dim flat() as Double
  dim c as Integer = 0
  NormalizeCallArgs(args())
  if ValidateBuiltinCallArgs(fnId, fnName, args()) = FALSE then return outV
  if TryBuiltinDispatchWithTime(fnId, fnName, args(), outV) then return outV

  dim isAggSimple as Boolean = (fnId = FUNC_SUM) orelse (fnId = FUNC_PRODUCT) orelse (fnId = FUNC_MIN) orelse (fnId = FUNC_MAX) orelse (fnId = FUNC_AVG) orelse (fnId = FUNC_MEAN)
  if isAggSimple orelse (fnId = FUNC_MEDIAN) orelse (fnId = FUNC_VARIANCE) orelse (fnId = FUNC_STDDEV) then
    if ubound(args) = -1 then SetAtLeastOneArgError(fnName): return outV
    if ubound(args) = 0 andalso args(0).kind = VK_SCALAR then
      if isAggSimple then
        outV = args(0)
        return outV
      end if
    end if
    dim acc as Double = 0
    dim i as Integer
    if isAggSimple then
      dim itemCount as Integer = 0
      dim hasValue as Boolean = FALSE
      dim aggMode as Integer = 0 '1=sum/avg/mean, 2=product, 3=min, 4=max
      if fnId = FUNC_PRODUCT then
        aggMode = 2
        acc = 1
      elseif fnId = FUNC_MIN then
        aggMode = 3
      elseif fnId = FUNC_MAX then
        aggMode = 4
      else
        aggMode = 1
      end if
      if (fnId = FUNC_SUM) orelse (fnId = FUNC_PRODUCT) orelse (fnId = FUNC_MIN) orelse (fnId = FUNC_MAX) then
        if TryAggSimpleExactInteger(args(), fnId, outV) then return outV
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
      if itemCount <= 0 then SetAtLeastOneArgError(fnName): return outV
      if (fnId = FUNC_AVG) orelse (fnId = FUNC_MEAN) then acc /= itemCount
    elseif fnId = FUNC_MEDIAN then
      if ubound(args) = lbound(args) then
        dim onlyIdx as Integer = lbound(args)
        if args(onlyIdx).kind = VK_SCALAR then
          outV = args(onlyIdx)
          return outV
        end if
        c = ValueArrayLen(args(onlyIdx))
        if c = 1 then
          ValueGetArrayElemAsScalar(args(onlyIdx), lbound(args(onlyIdx).arr), outV)
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
    elseif (fnId = FUNC_VARIANCE) orelse (fnId = FUNC_STDDEV) then
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
      if n <= 0 then SetAtLeastOneArgError(fnName): return outV
      acc = m2 / n
      if fnId = FUNC_STDDEV then acc = sqr(acc)
    end if
    ValueSetScalarPromoteExactInt64(outV, acc)
    return outV
  end if

  if fnId = FUNC_SORT then
    dim sortVals() as ScalarValue
    dim prepSort as Integer = TrySingleArgPassthroughOrCollect(args(), fnName, FALSE, outV, sortVals(), c)
    if prepSort = -1 then return outV
    if prepSort = 1 then return outV
    SortScalarValueArray(sortVals())
    ValueSetArrayFromScalarValues(outV, sortVals())
    return outV
  end if

  if fnId = FUNC_REVERSE then
    dim reverseVals() as ScalarValue
    dim prepReverse as Integer = TrySingleArgPassthroughOrCollect(args(), fnName, FALSE, outV, reverseVals(), c)
    if prepReverse = -1 then return outV
    if prepReverse = 1 then return outV
    ReverseScalarValueArrayInPlace(reverseVals(), c)
    ValueSetArrayFromScalarValues(outV, reverseVals())
    return outV
  end if

  if fnId = FUNC_UNPACK then
    if ubound(args) = -1 then
      SetAtLeastOneArgError(fnName)
      return outV
    end if
    if ubound(args) = 0 then
      outV = args(0)
    else
      dim unpackVals() as ScalarValue
      c = CollectRequiredArgsAsScalarValues(args(), unpackVals(), fnName)
      if c <= 0 then return outV
      ValueSetArrayFromScalarValues(outV, unpackVals())
    end if
    outV.expandArgs = TRUE
    return outV
  end if

  if fnId = FUNC_UNIQUE then
    dim uniqueVals() as ScalarValue
    dim prepUnique as Integer = TrySingleArgPassthroughOrCollect(args(), fnName, FALSE, outV, uniqueVals(), c)
    if prepUnique = -1 then return outV
    if prepUnique = 1 then return outV
    dim tmp() as ScalarValue, keys() as ULongInt, used() as UByte
    redim tmp(0 to c - 1)
    dim cap as Integer = NextPow2AtLeast(c * 2)
    if cap < 4 then cap = 4
    redim keys(0 to cap - 1)
    redim used(0 to cap - 1)
    dim outCount as Integer = 0
    dim i as Integer
    for i = 0 to c - 1
      dim v as Double = uniqueVals(i).scalar
      dim seen as Boolean = FALSE
      if v <> v then
        tmp(outCount) = uniqueVals(i)
        outCount += 1
        continue for
      end if
      dim key as ULongInt
      if ScalarIsTime(uniqueVals(i)) then
        key = UniqueHashKeyFromDouble(CDbl(TimeTotalMsFromScalarValue(uniqueVals(i))))
      else
        key = UniqueHashKeyFromDouble(v)
      end if
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
        tmp(outCount) = uniqueVals(i)
        outCount += 1
      end if
    next i

    redim preserve tmp(0 to outCount - 1)
    ValueSetArrayFromScalarValues(outV, tmp())
    return outV
  end if

  if fnId = FUNC_LOG then
    if EnsureExactArgCount(args(), 2, fnName) = FALSE then return outV
    if ApplyScalarBinaryMathFunctionValues(args(0), args(1), FUNC_LOG, outV) = FALSE then SetNumericErrorInFunction(fnName)
    return outV
  end if

  if fnId = FUNC_ATAN2 then
    if EnsureExactArgCount(args(), 2, fnName) = FALSE then return outV
    if ApplyScalarBinaryMathFunctionValues(args(0), args(1), FUNC_ATAN2, outV) = FALSE then
      SetNumericErrorInFunction(fnName)
    end if
    return outV
  end if

  if fnId = FUNC_HYPOT then
    if EnsureExactArgCount(args(), 2, fnName) = FALSE then return outV
    if ApplyScalarBinaryMathFunctionValues(args(0), args(1), FUNC_HYPOT, outV) = FALSE then
      SetNumericErrorInFunction(fnName)
    end if
    return outV
  end if

  if fnId = FUNC_MOD then
    if EnsureExactArgCount(args(), 2, fnName) = FALSE then return outV
    if ValueApplyBinaryInt64(args(0), args(1), OP_BIT_MOD, outV) = FALSE andalso parseError = 0 then SetNumericErrorInFunction(fnName)
    return outV
  end if

  if fnId = FUNC_FACT then
    if EnsureExactArgCount(args(), 1, fnName) = FALSE then return outV
    if TryApplyFactorial(args(0), outV) = FALSE then
      SetNonNegativeIntegerError(fnName)
    end if
    return outV
  end if

  if fnId = FUNC_RAND then
    if EnsureExactArgCount(args(), 0, fnName) = FALSE then return outV
    ValueSetScalarPromoteExactInt64(outV, rnd)
    return outV
  end if

  if fnId = FUNC_RANDOM then
    if EnsureExactArgCount(args(), 2, fnName) = FALSE then return outV
    if args(0).kind <> VK_SCALAR orelse args(1).kind <> VK_SCALAR then
      SetScalarValuesError(fnName)
      return outV
    end if
    ValueSetScalarPromoteExactInt64(outV, args(0).scalar + (args(1).scalar - args(0).scalar) * rnd)
    return outV
  end if

  if fnId = FUNC_CLAMP then
    if EnsureExactArgCount(args(), 3, fnName) = FALSE then return outV
    if args(1).kind <> VK_SCALAR orelse args(2).kind <> VK_SCALAR then
      SetScalarMinMaxError(fnName)
      return outV
    end if
    if ApplyClamp(args(0), args(1), args(2), outV) = FALSE then SetNumericErrorInFunction(fnName)
    return outV
  end if

  if (fnId = FUNC_GCD) orelse (fnId = FUNC_LCM) orelse (fnId = FUNC_NCR) orelse (fnId = FUNC_NPR) then
    if EnsureExactArgCount(args(), 2, fnName) = FALSE then return outV
  end if
  if TryApplyScalarBinaryIntegerBuiltin(fnId, fnName, args(), outV) then
    return outV
  end if

  if (fnId = FUNC_HEX) orelse (fnId = FUNC_OCT) orelse (fnId = FUNC_BIN) orelse _
     (fnId = FUNC_UHEX) orelse (fnId = FUNC_UOCT) orelse (fnId = FUNC_UBIN) then
    if ubound(args) = -1 then
      SetAtLeastOneArgError(fnName)
      return outV
    end if
    if ubound(args) = 0 then
      outV = args(0)
    else
      dim formatVals() as ScalarValue
      c = CollectRequiredArgsAsScalarValues(args(), formatVals(), fnName)
      if c <= 0 then return outV
      ValueSetArrayFromScalarValues(outV, formatVals())
    end if
    dim fmtBase as Integer = IIf((fnId = FUNC_HEX) orelse (fnId = FUNC_UHEX), 16, _
                                 IIf((fnId = FUNC_OCT) orelse (fnId = FUNC_UOCT), 8, 2))
    dim asUnsigned as Boolean = (fnId = FUNC_UHEX) orelse (fnId = FUNC_UOCT) orelse (fnId = FUNC_UBIN)
    outV.renderBase = fmtBase
    outV.renderUnsigned = asUnsigned
    return outV
  end if

  if fnId = FUNC_POW then
    if EnsureExactArgCount(args(), 2, fnName) = FALSE then return outV
    if ValueApplyBinary(args(0), args(1), CHAR_CARET, outV) = FALSE then SetNumericErrorInFunction(fnName)
    return outV
  end if

  if (fnId = FUNC_DEG) orelse (fnId = FUNC_RAD) then
    if ubound(args) = -1 then
      SetAtLeastOneArgError(fnName)
      return outV
    end if
    if ubound(args) = 0 then
      if ApplyUnaryFunction(fn, args(0), outV) = FALSE then SetNumericErrorInFunction(fnName)
      return outV
    end if

    dim angleVals() as ScalarValue
    c = CollectRequiredArgsAsScalarValues(args(), angleVals(), fnName)
    if c <= 0 then return outV
    ValueInitArrayLike(outV, 0, c - 1)
    for i as Integer = 0 to c - 1
      dim tmpOut as EvalValue
      if ApplyUnaryScalarFunctionById(fnId, angleVals(i), tmpOut) = FALSE then
        SetNumericErrorInFunction(fnName)
        return outV
      end if
      ValueSetArrayElemFromScalar(outV, i, tmpOut)
    next i
    return outV
  end if

  if IsUnaryBuiltin(fnName) then
    if EnsureExactArgCount(args(), 1, fnName) = FALSE then return outV
    if ApplyUnaryFunction(fn, args(0), outV) = FALSE then SetNumericErrorInFunction(fnName)
    return outV
  end if

  if EvaluateUserFunction(fnName, args(), outV) then return outV

  AppendUniqueName(unknownFuncsText, fnName)
  ValueSetInt64(outV, 0)
  return outV
end function

private function ParseScalarNumericValue(byref n as EvalValue) as Boolean
  dim dVal as Double = 0
  dim keepExactInt as Boolean = FALSE
  dim keepInt as LongInt = 0
  dim keepExactUInt as Boolean = FALSE
  dim keepUInt as ULongInt = 0

  if pStream[0] = CHAR_DIGIT_0 then
    dim prefixLower as UByte = 0
    dim radix as ULongInt = 0
    if pStream[1] = CHAR_LC_X orelse pStream[1] = CHAR_X then
      prefixLower = CHAR_LC_X
      radix = 16
    elseif pStream[1] = CHAR_LC_B orelse pStream[1] = CHAR_B then
      prefixLower = CHAR_LC_B
      radix = 2
    elseif pStream[1] = CHAR_LC_O orelse pStream[1] = CHAR_O then
      prefixLower = CHAR_LC_O
      radix = 8
    end if
    if prefixLower <> 0 then
      if TryParsePrefixedUIntLiteral(prefixLower, radix, keepUInt) = FALSE then
        SetInvalidPrefixedLiteralError(prefixLower)
        return FALSE
      end if

      dVal = CDbl(keepUInt)
      keepExactUInt = TRUE
      if keepUInt <= FB_I64_MAX_U then
        keepExactInt = TRUE
        keepInt = CLngInt(keepUInt)
      end if
    end if
  end if

  if keepExactUInt = FALSE then
    ' decimal number
    dim fract as Double = 1
    dim decIntAcc as ULongInt = 0
    dim decFracAcc as ULongInt = 0
    dim numIntDigits as Integer = 0
    dim numFracDigits as Integer = 0
    dim decIntOverflow as Boolean = FALSE
    dim intPartStarted as Boolean = FALSE
    dim hasDigit as Boolean = FALSE
    const U64_MAX_DIV10 as ULongInt = (FB_U64_MAX \ 10ull)
    const U64_MAX_MOD10 as Integer = CInt(FB_U64_MAX mod 10ull)

    ' Parse integer part, skip leading zeros
    while pStream[0] >= CHAR_DIGIT_0 andalso pStream[0] <= CHAR_DIGIT_9
      dim digit as Integer = (pStream[0] - CHAR_DIGIT_0)
      dVal = dVal * 10 + digit
      hasDigit = TRUE
      if digit <> 0 then
        intPartStarted = TRUE
      end if
      if intPartStarted then
        if not decIntOverflow then
          if (decIntAcc > U64_MAX_DIV10) orelse (decIntAcc = U64_MAX_DIV10 andalso digit > U64_MAX_MOD10) then
            decIntOverflow = TRUE
            decIntAcc = 0
          else
            decIntAcc = quickMult10(decIntAcc) + CULngInt(digit)
          end if
        end if
        numIntDigits += 1
      end if
      pStream += 1
    wend

    ' Parse fractional part
    if pStream[0] = CHAR_DOT then
      intPartStarted = TRUE
      pStream += 1
      while pStream[0] >= CHAR_DIGIT_0 andalso pStream[0] <= CHAR_DIGIT_9
        dim digit as Integer = (pStream[0] - CHAR_DIGIT_0)
        hasDigit = TRUE
        fract /= 10
        dVal += digit * fract
        if not decIntOverflow then
          if (decFracAcc > U64_MAX_DIV10) orelse (decFracAcc = U64_MAX_DIV10 andalso digit > U64_MAX_MOD10) then
            decIntOverflow = TRUE
            decFracAcc = 0
          else
            decFracAcc = quickMult10(decFracAcc) + CULngInt(digit)
          end if
        end if
        numFracDigits += 1
        pStream += 1
      wend
    end if

    ' Check if we have any digits
    if numIntDigits = 0 andalso numFracDigits = 0 then
      if not hasDigit then
        SetUnexpectedTokenError()
        return FALSE
      end if
      dVal = 0
      keepExactInt = TRUE
      keepInt = 0
      keepExactUInt = TRUE
      keepUInt = 0
    end if

    ' Parse exponent
    dim expVal as Integer = 0
    dim expNegative as Boolean = FALSE
    dim exactIntLiteral as Boolean = FALSE
    dim hasExponent as Boolean = FALSE
    if pStream[0] = CHAR_LC_E orelse pStream[0] = CHAR_E then
      hasExponent = TRUE
      dim pExp as ZString ptr = pStream + 1
      if pExp[0] = CHAR_MINUS then
        expNegative = TRUE
        pExp += 1
      elseif pExp[0] = CHAR_PLUS then
        pExp += 1
      end if
      if pExp[0] < CHAR_DIGIT_0 orelse pExp[0] > CHAR_DIGIT_9 then
        SetUnexpectedTokenError()
        return FALSE
      end if
      dim expDigits as Integer = 0
      pStream = pExp
      while pStream[0] >= CHAR_DIGIT_0 andalso pStream[0] <= CHAR_DIGIT_9
        dim digit as Integer = (pStream[0] - CHAR_DIGIT_0)
        if digit <> 0 orelse expDigits <> 0 then
          if expDigits < 4 then
            expVal = expVal * 10 + digit
          end if
          expDigits += 1
        end if
        pStream += 1
      wend
      if expNegative then
        expVal = -expVal
      end if
    end if

    if not decIntOverflow then
      ' Compute adjustment: exponent - fracDigits
      dim adjust as Integer = expVal - numFracDigits
      if adjust >= 0 then
        ' Positive adjustment: combine int and frac parts, then scale
        dim significantDigits as Integer = numIntDigits + numFracDigits
        if significantDigits + adjust > 20 then
          ' Result would exceed uint64 range
          decIntOverflow = TRUE
        elseif numFracDigits = 0 andalso adjust = 0 then
          ' Pure decimal integer without exponent: mantissa already in decIntAcc (skip mult/add no-ops)
          dVal = CDbl(decIntAcc)
          keepExactUInt = TRUE
          keepUInt = decIntAcc
          exactIntLiteral = TRUE
        else
          ' Combine: intPart * 10^fracDigits + fracPart (checked: silent ULongInt wrap must not attach exact uint metadata)
          dim exactInt as ULongInt = decIntAcc
          if TryMult10_N_TimesChecked(exactInt, numFracDigits, exactInt) = FALSE then
            decIntOverflow = TRUE
          elseif TryAddULongChecked(exactInt, decFracAcc, exactInt) = FALSE then
            decIntOverflow = TRUE
          elseif adjust > 0 then
            if TryMult10_N_TimesChecked(exactInt, adjust, exactInt) = FALSE then decIntOverflow = TRUE
          end if

          if decIntOverflow = FALSE then
            decIntAcc = exactInt
            numFracDigits = 0
            dVal = CDbl(exactInt)
            keepExactUInt = TRUE
            keepUInt = decIntAcc
            exactIntLiteral = TRUE
          end if
        end if
      else
        ' Negative adjustment: check if exactly divisible
        dim divisor as Integer = -adjust
        if divisor <= numFracDigits then
          dim pow10Divisor as ULongInt
          if TryMult10_N_TimesChecked(1ull, divisor, pow10Divisor) then
            ' Check if the last 'divisor' fractional digits are all zero
            dim fracRemainder as ULongInt = decFracAcc mod pow10Divisor
            if fracRemainder = 0ull then
              ' Divisible: result is exact integer
              dim resultDigits as Integer = numIntDigits + numFracDigits - divisor
              exactIntLiteral = TRUE
              if resultDigits = 0 then
                decIntAcc = 0
              elseif resultDigits <= 20 then
                ' Combine and reduce by divisor
                dim exactInt as ULongInt = decIntAcc
                if TryMult10_N_TimesChecked(exactInt, numFracDigits - divisor, exactInt) = FALSE then
                  exactIntLiteral = FALSE
                elseif TryAddULongChecked(exactInt, decFracAcc \ pow10Divisor, exactInt) = FALSE then
                  exactIntLiteral = FALSE
                else
                  decIntAcc = exactInt
                end if
              else
                ' Too many result digits
                exactIntLiteral = FALSE
              end if
              if exactIntLiteral then
                numFracDigits = 0
                dVal = CDbl(decIntAcc)
              end if
            end if
          end if
        end if
      end if
    end if

    if numFracDigits = 0 andalso exactIntLiteral then
      if decIntAcc <= FB_I64_MAX_U then
        keepExactInt = TRUE
        keepInt = CLngInt(decIntAcc)
      end if
      keepExactUInt = TRUE
      keepUInt = decIntAcc
    elseif hasExponent then
      dVal = dVal * pow(10.0, CDbl(expVal))
    end if
  end if

  if keepExactUInt andalso keepUInt <= FB_I64_MAX_U then
    if keepExactInt = FALSE then
      keepExactInt = TRUE
      keepInt = CLngInt(keepUInt)
    end if
  end if

  ValueSetScalar(n, dVal)
  n.exactInt64Valid = keepExactInt
  if keepExactInt then n.exactInt64 = keepInt
  n.exactUInt64Valid = keepExactUInt
  if keepExactUInt then n.exactUInt64 = keepUInt
  return TRUE
end function

private function ParseFactor() as EvalValue
  dim n as EvalValue
  ValueSetInt64(n, 0)
  wasPercentage = FALSE

  SkipSpaces()
  if IsNumericLiteralStartChar(asc(pStream[0])) then
    dim pNum as ZString ptr = pStream
    dim hasColonPeek as Boolean = FALSE
    if pNum[0] >= CHAR_DIGIT_0 andalso pNum[0] <= CHAR_DIGIT_9 then
      if pNum[0] = CHAR_DIGIT_0 andalso (pNum[1] = CHAR_LC_X orelse pNum[1] = CHAR_X orelse pNum[1] = CHAR_LC_B orelse pNum[1] = CHAR_B orelse pNum[1] = CHAR_LC_O orelse pNum[1] = CHAR_O) then
        hasColonPeek = FALSE
      else
        dim qq as ZString ptr = pNum
        while (qq[0] >= CHAR_DIGIT_0 andalso qq[0] <= CHAR_DIGIT_9) orelse qq[0] = CHAR_COLON orelse qq[0] = CHAR_DOT
          if qq[0] = CHAR_COLON then hasColonPeek = TRUE
          qq += 1
        wend
      end if
    end if
    if hasColonPeek then
      if TryParseScalarTimeLiteral(n) = FALSE then return n
    else
      if not ParseScalarNumericValue(n) then return n
    end if
  elseif IsIdentStartChar(asc(pStream[0])) then
    dim nam as String = ConsumeIdentTokenFromStream()
    SkipSpaces()
    if pStream[0] = CHAR_LPAREN then
      n = ParseFunctionCall(nam)
      if parseError then return n
      dim indexed as EvalValue
      if TryParseArrayIndex(n, indexed) = FALSE then return n
      n = indexed
    else
      dim canIndex as Boolean = TRUE
      if TryGetConstant(nam, n) = FALSE then
        if GetVariable(nam, n) = FALSE then
          if TryHandleUnknownIdentifier(nam, n, canIndex) = FALSE then return n
        end if
      end if
      if canIndex then
        dim indexed as EvalValue
        if TryParseArrayIndex(n, indexed) = FALSE then return n
        n = indexed
      end if
    end if
  elseif pStream[0] = CHAR_LPAREN then
    pStream += 1
    if pStream[0] = CHAR_COMMA then
      SetUnexpectedCommaError()
      return n
    end if
    dim firstVal as EvalValue = ParseExpression()
    if parseError then return n
    SkipSpaces()
    if pStream[0] = CHAR_COMMA then
      dim vals() as EvalValue
      redim vals(0)
      if firstVal.kind <> VK_SCALAR then SetArrayElementMustBeScalarError(): return n
      vals(0) = firstVal
      dim firstIsT as Boolean = ScalarIsTime(firstVal.scalarValue)
      dim hasComma as Boolean = TRUE
      do
        if TryConsumeCommaArgSeparator(hasComma) = FALSE then return n
        if hasComma = FALSE then exit do
        dim nextVal as EvalValue = ParseExpression()
        if parseError then return n
        if nextVal.kind <> VK_SCALAR then SetArrayElementMustBeScalarError(): return n
        if ScalarIsTime(nextVal.scalarValue) <> firstIsT then
          SetTimeArrayMixedError()
          return n
        end if
        redim preserve vals(0 to ubound(vals) + 1)
        vals(ubound(vals)) = nextVal
        SkipSpaces()
        if pStream[0] <> CHAR_COMMA andalso pStream[0] <> CHAR_RPAREN then
          SetMismatchedBracketBraceOrUnexpectedToken(asc(pStream[0]))
          return n
        end if
      loop while hasComma
      if TryConsumeClosingParenOrSetError() = FALSE then return n
      ValueInitArrayLike(n, 0, ubound(vals))
      dim arrI as Integer
      for arrI = 0 to ubound(vals)
        ValueSetArrayElemFromScalar(n, arrI, vals(arrI))
      next arrI
    else
      if TryConsumeClosingParenOrSetError() = FALSE then return n
      n = firstVal
    end if
  else
    SetUnexpectedTokenError()
  end if

  return n
end function

private function ParsePower() as EvalValue
  dim n as EvalValue = ParseFactor()
  if parseError then return n
  SkipSpaces()

  if pStream[0] = CHAR_ASTERISK andalso pStream[1] = CHAR_ASTERISK then
    pStream += 2
    dim rhs as EvalValue
    rhs = ParseUnary()
    if parseError then return n
    ApplyBinaryParserOpInPlace(n, rhs, CHAR_CARET)
  end if
  return n
end function

private function TryConsumeMultiplicativeOp(byref op as UByte, byref useInt64 as Integer, byref intOp as OperatorBitNameId) as Boolean
  op = 0
  useInt64 = FALSE
  intOp = OP_BIT_NONE
  if pStream[0] = CHAR_ASTERISK andalso pStream[1] <> CHAR_ASTERISK then
    op = CHAR_ASTERISK
    pStream += 1
    return TRUE
  end if
  if pStream[0] = CHAR_DIVIDE then
    op = CHAR_DIVIDE
    pStream += 1
    return TRUE
  end if
  if pStream[0] = CHAR_PERCENT then
    useInt64 = TRUE
    intOp = OP_BIT_MOD
    pStream += 1
    return TRUE
  end if
  if IsImplicitMulStart() then
    op = CHAR_ASTERISK
    return TRUE
  end if
  return FALSE
end function

private sub ApplyMultiplicativeOpInPlace(byref leftV as EvalValue, byref rightV as EvalValue, byval useInt64 as Integer, byval intOp as OperatorBitNameId, byval op as UByte)
  if useInt64 then
    ApplyInt64ParserOpInPlace(leftV, rightV, intOp)
  else
    ApplyBinaryParserOpInPlace(leftV, rightV, op)
  end if
end sub

private function ParseUnary() as EvalValue
  SkipSpaces()
  if pStream[0] = CHAR_PLUS then
    pStream += 1
    return ParseUnary()
  elseif pStream[0] = CHAR_MINUS then
    pStream += 1
    dim v as EvalValue
    v = ParseUnary()
    if parseError then return v
    dim minusOne as EvalValue, outV as EvalValue
    ValueSetInt64(minusOne, -1)
    if ApplyBinaryParserOp(v, minusOne, CHAR_ASTERISK, outV) = FALSE then return outV
    return outV
  elseif pStream[0] = CHAR_TILDE then
    pStream += 1
    dim v as EvalValue
    v = ParseUnary()
    if parseError then return v
    dim outV as EvalValue
    dim minusOne as EvalValue
    ValueSetInt64(minusOne, -1)
    if ApplyInt64ParserOp(v, minusOne, OP_BIT_XOR, outV) = FALSE then return outV
    return outV
  elseif pStream[0] = CHAR_EXCLAMATION andalso pStream[1] <> CHAR_EQUALS then
    pStream += 1
    dim v as EvalValue
    v = ParseUnary()
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
  while pStream[0] = CHAR_LBRACKET
    dim indexed as EvalValue
    if TryParseArrayIndex(n, indexed) = FALSE then return n
    n = indexed
    SkipSpaces()
  wend

  SkipSpaces()
  if pStream[0] = CHAR_PERCENT then
    pStream += 1
    if IsPercentageTail() then
      dim divV as EvalValue, outV as EvalValue
      ValueSetScalar(divV, 100.0)
      if ValueApplyBinary(n, divV, CHAR_DIVIDE, outV) = FALSE then
        SetIncompatibleOperandsError()
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
    dim intOp as OperatorBitNameId = OP_BIT_NONE
    if TryConsumeMultiplicativeOp(op, useInt64, intOp) = FALSE then exit while

    dim n2 as EvalValue = ParseUnary()
    ApplyMultiplicativeOpInPlace(n, n2, useInt64, intOp, op)
    termWasPercentage = FALSE
    SkipSpaces()
  wend
  wasPercentage = termWasPercentage
  return n
end function

private function IsAdditiveTermBoundary() as Boolean
  return (pStream[0] = CHAR_NUL) orelse (pStream[0] = CHAR_RPAREN) orelse (pStream[0] = CHAR_PLUS) orelse (pStream[0] = CHAR_MINUS) orelse (pStream[0] = CHAR_COMMA) orelse (pStream[0] = CHAR_SEMICOLON) _
         orelse (pStream[0] = CHAR_LESS_THAN) orelse (pStream[0] = CHAR_GREATER_THAN) orelse (pStream[0] = CHAR_AMPERSAND) orelse (pStream[0] = CHAR_CARET) orelse (pStream[0] = CHAR_PIPE) _
         orelse (pStream[0] = CHAR_RBRACKET) orelse (pStream[0] = CHAR_RBRACE)
end function

private function TryConsumeAdditiveOperator(byref op as UByte) as Boolean
  if (pStream[0] = CHAR_PLUS) orelse (pStream[0] = CHAR_MINUS) then
    op = pStream[0]
    pStream += 1
    return TRUE
  end if
  return FALSE
end function

private sub ApplyPercentageRhsByContext(byref lhs as EvalValue, byref rhs as EvalValue)
  if wasPercentage = FALSE then exit sub
  SkipSpaces()
  if IsAdditiveTermBoundary() then
    dim pctV as EvalValue
    if ApplyBinaryParserOp(lhs, rhs, CHAR_ASTERISK, pctV) then rhs = pctV
  end if
end sub

private function ParseAdditive() as EvalValue
  dim n as EvalValue = ParseMultiplicative()
  SkipSpaces()
  while TRUE
    if parseError then exit while
    dim op as UByte = 0
    if TryConsumeAdditiveOperator(op) = FALSE then exit while
    dim n2 as EvalValue = ParseMultiplicative()
    ApplyPercentageRhsByContext(n, n2)
    ApplyBinaryParserOpInPlace(n, n2, op)
    SkipSpaces()
  wend
  return n
end function

private const PARSE_INT64_LEVEL_ADDITIVE as Integer = 1
private const PARSE_INT64_LEVEL_SHIFT as Integer = 2
private const PARSE_INT64_LEVEL_BITAND as Integer = 3
private const PARSE_INT64_LEVEL_BITXOR as Integer = 4

private function ParseInt64OperandLevel(byval levelId as Integer) as EvalValue
  select case levelId
    case PARSE_INT64_LEVEL_ADDITIVE: return ParseAdditive()
    case PARSE_INT64_LEVEL_SHIFT: return ParseShift()
    case PARSE_INT64_LEVEL_BITAND: return ParseBitwiseAnd()
    case PARSE_INT64_LEVEL_BITXOR: return ParseBitwiseXor()
  end select
  dim outV as EvalValue
  ValueSetInt64(outV, 0)
  SetUnexpectedTokenError()
  return outV
end function

private function TryConsumeInt64BinaryOp(byval levelId as Integer, byref outOp as OperatorBitNameId) as Boolean
  select case levelId
    case PARSE_INT64_LEVEL_ADDITIVE
      if (pStream[0] = CHAR_LESS_THAN andalso pStream[1] = CHAR_LESS_THAN) orelse (pStream[0] = CHAR_GREATER_THAN andalso pStream[1] = CHAR_GREATER_THAN) then
        if pStream[0] = CHAR_LESS_THAN then outOp = OP_BIT_SHL else outOp = OP_BIT_SHR
        pStream += 2
        return TRUE
      end if
    case PARSE_INT64_LEVEL_SHIFT
      if pStream[0] = CHAR_AMPERSAND andalso pStream[1] <> CHAR_AMPERSAND then
        outOp = OP_BIT_AND
        pStream += 1
        return TRUE
      end if
    case PARSE_INT64_LEVEL_BITAND
      if pStream[0] = CHAR_CARET then
        outOp = OP_BIT_XOR
        pStream += 1
        return TRUE
      end if
    case PARSE_INT64_LEVEL_BITXOR
      if pStream[0] = CHAR_PIPE andalso pStream[1] <> CHAR_PIPE then
        outOp = OP_BIT_OR
        pStream += 1
        return TRUE
      end if
  end select
  return FALSE
end function

private function ParseLeftAssocInt64Binary(byval operandLevelId as Integer) as EvalValue
  dim n as EvalValue = ParseInt64OperandLevel(operandLevelId)
  SkipSpaces()
  while TRUE
    if parseError then exit while
    dim op as OperatorBitNameId = OP_BIT_NONE
    if TryConsumeInt64BinaryOp(operandLevelId, op) = FALSE then exit while
    dim n2 as EvalValue = ParseInt64OperandLevel(operandLevelId)
    ApplyInt64ParserOpInPlace(n, n2, op)
    SkipSpaces()
  wend
  return n
end function

private function ParseShift() as EvalValue
  return ParseLeftAssocInt64Binary(PARSE_INT64_LEVEL_ADDITIVE)
end function

private function ParseBitwiseAnd() as EvalValue
  return ParseLeftAssocInt64Binary(PARSE_INT64_LEVEL_SHIFT)
end function

private function ParseBitwiseXor() as EvalValue
  return ParseLeftAssocInt64Binary(PARSE_INT64_LEVEL_BITAND)
end function

private function ParseBitwiseOr() as EvalValue
  return ParseLeftAssocInt64Binary(PARSE_INT64_LEVEL_BITXOR)
end function

private function TryConsumeComparisonOperator(byref outOp as OperatorCmpNameId) as Boolean
  if pStream[0] = CHAR_EQUALS then
    if pStream[1] = CHAR_EQUALS then
      outOp = OP_CMP_EQ
      pStream += 2
    else
      outOp = OP_CMP_EQ
      pStream += 1
    end if
    return TRUE
  end if
  if pStream[0] = CHAR_LESS_THAN then
    if pStream[1] = CHAR_GREATER_THAN then
      outOp = OP_CMP_NE
      pStream += 2
    elseif pStream[1] = CHAR_EQUALS then
      outOp = OP_CMP_LE
      pStream += 2
    elseif pStream[1] = CHAR_LESS_THAN then
      return FALSE
    else
      outOp = OP_CMP_LT
      pStream += 1
    end if
    return TRUE
  end if
  if pStream[0] = CHAR_GREATER_THAN then
    if pStream[1] = CHAR_EQUALS then
      outOp = OP_CMP_GE
      pStream += 2
    elseif pStream[1] = CHAR_GREATER_THAN then
      return FALSE
    else
      outOp = OP_CMP_GT
      pStream += 1
    end if
    return TRUE
  end if
  if pStream[0] = CHAR_EXCLAMATION andalso pStream[1] = CHAR_EQUALS then
    outOp = OP_CMP_NE
    pStream += 2
    return TRUE
  end if
  return FALSE
end function

private function ParseComparison() as EvalValue
  dim n as EvalValue = ParseBitwiseOr()
  SkipSpaces()
  while TRUE
    if parseError then exit while
    dim op as OperatorCmpNameId = OP_CMP_NONE
    if TryConsumeComparisonOperator(op) = FALSE then exit while

    dim n2 as EvalValue = ParseBitwiseOr()
    ApplyComparisonParserOpInPlace(n, n2, op)
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

private function TryConsumeLogicalBinaryOperator(byval keywordId as OperatorNameId, byval symbol as UByte) as Boolean
  if pStream[0] = symbol andalso pStream[1] = symbol then
    pStream += 2
    return TRUE
  end if
  if MatchKeywordOperator(OpName(keywordId)) then
    return TRUE
  end if
  return FALSE
end function

private function ParseLeftAssocLogical(byval keywordId as OperatorNameId, byval symbol as UByte, byval useOr as Boolean) as EvalValue
  dim n as EvalValue
  if useOr then
    n = ParseLogicalAnd()
  else
    n = ParseLogicalNot()
  end if
  SkipSpaces()
  while TRUE
    if parseError then exit while
    if TryConsumeLogicalBinaryOperator(keywordId, symbol) = FALSE then exit while

    dim n2 as EvalValue
    if useOr then
      n2 = ParseLogicalAnd()
    else
      n2 = ParseLogicalNot()
    end if
    if useOr then
      ValueSetBoolResult(EvalValueIsTruthy(n) orelse EvalValueIsTruthy(n2), n)
    else
      ValueSetBoolResult(EvalValueIsTruthy(n) andalso EvalValueIsTruthy(n2), n)
    end if
    SkipSpaces()
  wend
  return n
end function

private function ParseLogicalAnd() as EvalValue
  return ParseLeftAssocLogical(OP_AND, CHAR_AMPERSAND, FALSE)
end function

private function ParseLogicalOr() as EvalValue
  return ParseLeftAssocLogical(OP_OR, CHAR_PIPE, TRUE)
end function

private function ParseExpression() as EvalValue
  wasPercentage = FALSE
  return ParseLogicalOr()
end function

private function TryValidateUserFunctionBodyExpression(byref body as String, fnParams() as String, byref errText as String) as Boolean
  dim savedStream as ZString ptr = pStream
  dim savedExprStart as ZString ptr = exprStart
  dim savedParseError as Integer = parseError
  dim savedWasPercentage as Boolean = wasPercentage
  dim savedBaseCol as Integer = errorBaseCol
  dim savedLastErr as String = lastErrorText
  dim savedUnknownVars as String = unknownVarsText
  dim savedUnknownFuncs as String = unknownFuncsText

#ifdef __FB_FUNC_VARS_OVERRIDE_GLOBALS__
  dim savedFunctionVariableCount as Integer = functionVariableCount
  dim savedFunctionVariableNames() as String
  if savedFunctionVariableCount > 0 then
    redim savedFunctionVariableNames(0 to savedFunctionVariableCount - 1)
    for iSaved as Integer = 0 to savedFunctionVariableCount - 1
      savedFunctionVariableNames(iSaved) = functionVariableNames(iSaved)
    next iSaved
  end if

  dim paramCount as Integer = 0
  if ubound(fnParams) >= lbound(fnParams) then paramCount = ubound(fnParams) - lbound(fnParams) + 1
  if paramCount > 0 then
    redim functionVariableNames(0 to paramCount - 1)
    for iParam as Integer = 0 to paramCount - 1
      functionVariableNames(iParam) = fnParams(lbound(fnParams) + iParam)
    next iParam
    functionVariableCount = paramCount
  else
    erase functionVariableNames
    functionVariableCount = 0
  end if
#endif

  lastErrorText = ""
  unknownVarsText = ""
  unknownFuncsText = ""
  pStream = strptr(body)
  exprStart = pStream
  errorBaseCol = 1
  parseError = 0

  dim dummy as EvalValue
  dummy = ParseExpression()
  SkipSpaces()

  dim ok as Boolean = TRUE
  if parseError then
    ok = FALSE
    errText = lastErrorText
    if len(errText) = 0 then errText = FB_STR_FAILED_TO_PARSE_USER_FUNCTION_BODY
  elseif pStream[0] <> CHAR_NUL then
    ok = FALSE
    errText = FB_STR_UNEXPECTED_INPUT
  end if

  pStream = savedStream
  exprStart = savedExprStart
  parseError = savedParseError
  wasPercentage = savedWasPercentage
  errorBaseCol = savedBaseCol
  lastErrorText = savedLastErr
  unknownVarsText = savedUnknownVars
  unknownFuncsText = savedUnknownFuncs

#ifdef __FB_FUNC_VARS_OVERRIDE_GLOBALS__
  if savedFunctionVariableCount > 0 then
    redim functionVariableNames(0 to savedFunctionVariableCount - 1)
    for iSaved as Integer = 0 to savedFunctionVariableCount - 1
      functionVariableNames(iSaved) = savedFunctionVariableNames(iSaved)
    next iSaved
  else
    erase functionVariableNames
  end if
  functionVariableCount = savedFunctionVariableCount
#endif

  return ok
end function

private sub ResetTopLevelEvaluationState(byref exprInput as String)
  lastErrorText = ""
  unknownVarsText = ""
  unknownFuncsText = ""
  udfCallStackSp = 0
  errorBaseCol = 1
  rootInputExpr = exprInput
end sub

sub Parser_ClearVariables()
  erase variables
  erase userFunctions
  dim emptyExpr as String = ""
  ResetTopLevelEvaluationState(emptyExpr)
  dim probeDefault as EvalValue
  ValueSetInt64(probeDefault, 1)
  SetVariable(FB_STR_FORMAL_VALIDATION_PROBE, probeDefault)
end sub

function Parser_TryEvaluate(byref sExpr as String, byref result as Double) as Boolean
  dim textResult as String, isArray as Boolean
  return Parser_TryEvaluateEx(sExpr, result, textResult, isArray)
end function

private function IsTopLevelStatementSeparator(byref ch as String, byval depthParen as Integer, byval depthBracket as Integer, byval depthBrace as Integer) as Boolean
  return (ch = ";") andalso (depthParen = 0) andalso (depthBracket = 0) andalso (depthBrace = 0)
end function

private function IsTopLevelStatementSeparatorChar(byval ch as UByte, byval depthParen as Integer, byval depthBracket as Integer, byval depthBrace as Integer) as Boolean
  return (ch = CHAR_SEMICOLON) andalso (depthParen = 0) andalso (depthBracket = 0) andalso (depthBrace = 0)
end function

private sub UpdateNestingDepths(byval ch as UByte, byref depthParen as Integer, byref depthBracket as Integer, byref depthBrace as Integer)
  if ch = CHAR_LPAREN then
    depthParen += 1
  elseif ch = CHAR_RPAREN then
    if depthParen > 0 then depthParen -= 1
  elseif ch = CHAR_LBRACKET then
    depthBracket += 1
  elseif ch = CHAR_RBRACKET then
    if depthBracket > 0 then depthBracket -= 1
  elseif ch = CHAR_LBRACE then
    depthBrace += 1
  elseif ch = CHAR_RBRACE then
    if depthBrace > 0 then depthBrace -= 1
  end if
end sub

private function TryEvaluateTopLevelStatements(byref exprInput as String, byref result as Double, byref resultText as String, byref isArray as Boolean, byref handled as Boolean) as Boolean
  handled = FALSE
  if instr(exprInput, ";") <= 0 then return TRUE

  dim hasTopLevelSep as Integer = 0
  dim scanParen as Integer = 0
  dim scanBracket as Integer = 0
  dim scanBrace as Integer = 0
  dim scanP as ZString ptr = StrPtr(exprInput)
  while scanP[0] <> CHAR_NUL
    dim sch as UByte = scanP[0]
    if IsTopLevelStatementSeparatorChar(sch, scanParen, scanBracket, scanBrace) then
      hasTopLevelSep = 1
      exit while
    end if
    UpdateNestingDepths(sch, scanParen, scanBracket, scanBrace)
    scanP += 1
  wend

  if hasTopLevelSep = 0 then return TRUE

  dim stmtStart as Integer = 1
  dim depthParen as Integer = 0
  dim depthBracket as Integer = 0
  dim depthBrace as Integer = 0
  dim hasPrevStmtResult as Boolean = FALSE
  dim iStmt as Integer
  for iStmt = 1 to len(exprInput) + 1
    dim ch as String
    dim chByte as UByte
    if iStmt <= len(exprInput) then
      ch = mid(exprInput, iStmt, 1)
      chByte = asc(ch)
    else
      ch = ";"
      chByte = CHAR_SEMICOLON
    end if
    dim isStmtSep as Integer = 0
    if iStmt > len(exprInput) then
      isStmtSep = 1
    elseif IsTopLevelStatementSeparatorChar(chByte, depthParen, depthBracket, depthBrace) then
      isStmtSep = 1
    end if

    if isStmtSep then
      dim rawStmtLen as Integer = iStmt - stmtStart
      dim rawStmt as String
      if rawStmtLen > 0 then
        rawStmt = mid(exprInput, stmtStart, rawStmtLen)
      else
        rawStmt = ""
      end if
      dim stmt as String = trim(rawStmt)
      if stmt = "" then
        SetEmptyStatementError()
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
        return FALSE
      end if
      hasPrevStmtResult = TRUE
      errorBaseCol = savedBaseCol
      stmtStart = iStmt + 1
    else
      UpdateNestingDepths(chByte, depthParen, depthBracket, depthBrace)
    end if
  next iStmt

  handled = TRUE
  return TRUE
end function

private function FinishParserEvaluateEx(byval ok as Boolean) as Boolean
  evalDepth -= 1
  return ok
end function

function Parser_TryEvaluateEx(byref sExpr as String, byref result as Double, byref resultText as String, byref isArray as Boolean) as Boolean
  dim exprInput as String = StripLineComment(sExpr)
  const PARSER_MAX_EXPR_LEN as Integer = 32760
  evalDepth += 1
  if evalDepth = 1 then
    ResetTopLevelEvaluationState(exprInput)
  end if
  if Len(exprInput) = 0 then
    return FinishParserEvaluateEx(FALSE)
  end if
  if Len(exprInput) > PARSER_MAX_EXPR_LEN then
    SetExpressionTooLongError()
    return FinishParserEvaluateEx(FALSE)
  end if

  dim handledTopLevel as Boolean = FALSE
  if TryEvaluateTopLevelStatements(exprInput, result, resultText, isArray, handledTopLevel) = FALSE then
    return FinishParserEvaluateEx(FALSE)
  end if
  if handledTopLevel then
    return FinishParserEvaluateEx(TRUE)
  end if

  dim i as Integer, hasNonSpace as Integer = 0
  for i = 1 to Len(exprInput)
    dim c as Integer = Asc(Mid(exprInput, i, 1))
    if not (c = CHAR_SPACE orelse c = CHAR_TAB orelse c = CHAR_LF orelse c = CHAR_CR) then
      hasNonSpace = 1
      exit for
    end if
  next i
  if hasNonSpace = 0 then
    return FinishParserEvaluateEx(FALSE)
  end if

  pStream = StrPtr(exprInput)
  exprStart = pStream
  parseError = 0
  isArray = FALSE
  resultText = ""
  result = 0

  SkipSpaces()
  if IsIdentStartChar(asc(pStream[0])) then
    dim varName as String = ConsumeIdentTokenFromStream()
    SkipSpaces()
    if pStream[0] = CHAR_LPAREN then
      dim savedPos as ZString ptr = pStream
      pStream += 1
      SkipSpaces()
      dim fnParams() as String
      dim parseParamsOk as Integer = 1

      if pStream[0] <> CHAR_RPAREN then
        do
          if not IsIdentStartChar(asc(pStream[0])) then
            parseParamsOk = 0
            exit do
          end if
          dim parName as String = ConsumeIdentTokenFromStream()
          if ubound(fnParams) = -1 then
            redim fnParams(0)
          else
            redim preserve fnParams(ubound(fnParams) + 1)
          end if
          fnParams(ubound(fnParams)) = parName
          SkipSpaces()
          if pStream[0] = CHAR_COMMA then
            pStream += 1
            SkipSpaces()
          else
            exit do
          end if
        loop
      end if

      if parseParamsOk andalso pStream[0] = CHAR_RPAREN then
        pStream += 1
        SkipSpaces()
        '' UDF: name(params)=body — single '=' only; do not treat first '=' of '==' as UDF starter.
        if pStream[0] = CHAR_EQUALS andalso pStream[1] <> CHAR_EQUALS then
          pStream += 1
          SkipSpaces()
          dim udfValidationErr as String
          dim body as String = *pStream
          if TryValidateUserFunctionDefinition(varName, fnParams(), body, udfValidationErr) = FALSE then
            SetValidationError(udfValidationErr)
            return FinishParserEvaluateEx(FALSE)
          end if
          SetUserFunction(varName, fnParams(), body)
          dim sig as String = varName & "("
          if ubound(fnParams) >= lbound(fnParams) then
            dim k as Integer
            for k = lbound(fnParams) to ubound(fnParams)
              if k > lbound(fnParams) then sig &= FB_STR_COMMA
              sig &= fnParams(k)
            next k
          end if
          sig &= ")"
          resultText = FB_STR_DEFINED & sig
          isArray = FALSE
          result = 0
          return FinishParserEvaluateEx(TRUE)
        end if
      end if
      pStream = savedPos
    end if

    ' Single '=' is assignment; '==' is equality (do not consume the first '=' of '==').
    if pStream[0] = CHAR_EQUALS andalso pStream[1] <> CHAR_EQUALS then
      pStream += 1
      dim exprV as EvalValue
      exprV = ParseExpression()
      if parseError then
        return FinishParserEvaluateEx(FALSE)
      end if
      SkipSpaces()
      ApplyUnknownNameErrors()
      if pStream[0] = CHAR_NUL andalso parseError = 0 then
        dim assignNameErr as String
        if TryValidateAssignmentTargetName(varName, assignNameErr) = FALSE then
          SetValidationError(assignNameErr)
          return FinishParserEvaluateEx(FALSE)
        end if
        SetVariable(varName, exprV)
        SetAnsValue(exprV)
        resultText = ValueToString(exprV)
        isArray = (exprV.kind = VK_ARRAY)
        if exprV.kind = VK_SCALAR then result = exprV.scalar
        return FinishParserEvaluateEx(TRUE)
      end if
      if parseError = 0 then SetUnexpectedTokenError()
      return FinishParserEvaluateEx(FALSE)
    end if
  end if

  pStream = StrPtr(exprInput)
  exprStart = pStream
  parseError = 0
  dim outV as EvalValue
  outV = ParseExpression()
  if parseError then
    return FinishParserEvaluateEx(FALSE)
  end if
  SkipSpaces()

  ApplyUnknownNameErrors()

  if pStream[0] <> CHAR_NUL andalso parseError = 0 then
    if pStream[0] = CHAR_COMMA then
      SetUnexpectedCommaError()
    elseif pStream[0] = CHAR_RPAREN then
      SetMismatchedClosingParenthesisError()
    else
      SetMismatchedBracketBraceOrUnexpectedToken(asc(pStream[0]))
    end if
  end if
  if parseError = 1 then
    return FinishParserEvaluateEx(FALSE)
  end if
  resultText = ValueToString(outV)
  isArray = (outV.kind = VK_ARRAY)
  if outV.kind = VK_SCALAR then result = outV.scalar
  SetAnsValue(outV)
  return FinishParserEvaluateEx(TRUE)
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