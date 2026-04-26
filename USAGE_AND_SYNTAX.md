# SmartMath Usage and Syntax

This document describes practical usage and the expression language implemented in `MathParser.bas`.
It focuses on parser/evaluator behavior (functions, operators, precedence, arrays, variables, user-defined functions, numeric formats, and important edge cases).

## 0) Quick Usage

- Results are shown in the right margin and are not part of file text.
- To copy a result, double-click the result area on that line.
- Copied text is the clean value/error text (without UI prefixes like `=` or `!`).

## 1) Built-in Functions

### 1.1 Trigonometric and Hyperbolic
- `sin(angle)`
- `cos(angle)`
- `tan(angle)`
- `asin(value)`, `arcsin(value)`
- `acos(value)`, `arccos(value)`
- `atan(value)`, `arctan(value)`
- `atan2(y, x)` - angle of vector `(x,y)` in radians
- `deg(...)` - radians -> degrees (supports scalar, array, or multiple values)
- `rad(...)` - degrees -> radians (supports scalar, array, or multiple values)
- `sinh(value)`
- `cosh(value)`
- `tanh(value)`

### 1.2 Logarithmic and Exponential
- `exp(value)`
- `ln(value)` - natural logarithm
- `log(value, base)` - logarithm in arbitrary base
- `log10(value)`

### 1.3 Powers and Roots
- `sqrt(value)` - square root
- `sqr(value)` - value * value
- `pow(value, power)` - equivalent to `value ** power`
- `hypot(x, y)` - sqrt(x*x + y*y)

Note:
- You can compute an y-th root using `pow(x, 1/y)` or `x**(1/y)`.
  - Example: `pow(27, 1/3)` -> `3`, `25**(1/2)` -> `5`

### 1.4 Numeric Utilities
- `floor(value)` - largest integer <= value
- `ceil(value)` - smallest integer >= value
- `trunc(value)` - truncate fractional part toward zero
- `int(value)` - integer part toward zero (same behavior as `trunc(value)`)
- `frac(value)` - fractional part after truncation (`value - int(value)`)
- `fract(value)` - alias of `frac(value)`
- `round(value)` - nearest integer
- `abs(value)`
- `sign(value)` - returns -1, 0, or 1
- `clamp(value, min, max)` - limit value to [min, max]
- `gcd(a, b)` - greatest common divisor (integer)
- `lcm(a, b)` - least common multiple (integer)
- `mod(value, divisor)` - function form of `%` (integer modulo)
- `fact(n)`, `factorial(n)` - factorial for integer `n` in range `[0..20]`
- `rand()` - random floating-point value in `[0, 1)`
- `random(min, max)` - random floating-point value in `[min, max)`

### 1.5 Arrays and Aggregation
- `sum(...)`
- `product(...)`
- `prod(...)` - alias of `product(...)`
- `avg(...)` - average of all arguments
- `mean(...)` - alias of `avg(...)`
- `median(...)` - median of all flattened values
- `variance(...)` - population variance of all flattened values
- `stddev(...)` - population standard deviation of all flattened values
- `min(...)`
- `max(...)`
- `sort(...)` - sorts all provided values (scalars/arrays) and returns an array
- `sorted(...)` - alias of `sort(...)`
- `reverse(...)` - reverses all provided values (scalars/arrays) and returns an array
- `reversed(...)` - alias of `reverse(...)`
- `unique(...)` - keeps unique values from provided values (scalars/arrays), preserving first-occurrence order
- `unpack(...)` - unpacks scalar/array arguments into separate arguments

Aggregation functions accept scalar and array arguments. Array arguments are flattened into one sequence of scalar values.

Notes:
- `variance(...)` and `stddev(...)` use population formulas (divide by `N`).
- Sample formulas (divide by `N-1`) are not currently implemented.
- Example on `a=(1,2,3)`: `variance(a)` = `2/3` and `stddev(a)` = `sqrt(2/3)` (~`0.81649658`), while sample values would be `1` and `1`.

### 1.6 Output-Formatting Helpers
- `hex(...)` - renders final value in hexadecimal form
- `oct(...)` - renders final value in octal form
- `bin(...)` - renders final value in binary form
- `uhex(...)`, `uoct(...)`, `ubin(...)` - same inputs as `hex`, `oct`, and `bin`.
- For **negative** numbers, they **do not** show a minus sign. They show the value as an **unsigned 64-bit integer** (typical “hex dump” / CPU register style). Positives look the same as with `hex` / `oct` / `bin`.

Notes:
- `hex()`, `oct()`, `bin()`, `uhex()`, `uoct()`, and `ubin()` require integer values.
- In C `printf`, `%x` and `%o` are unsigned. There is no standard “signed hex” flag.
- `hex` / `oct` / `bin` use a minus sign and the magnitude for negatives.
  - `hex(-1)` -> `-0x1`
  - `oct(-1)` -> `-0o1`
- `uhex` / `uoct` / `ubin` use that “all bits, no minus sign” style for negatives.
  - `uhex(-1)` -> `0xFFFFFFFFFFFFFFFF` (every hex digit is `F`)
  - `uhex(~0x0D)` -> `0xFFFFFFFFFFFFFFF2` (same idea after bitwise `~`)
- For a **32-bit**-wide display, mask first.
  - `uhex(0xFFFFFFFF & (~0x0D))` -> `0xFFFFFFF2`
- `hex(...)`, `oct(...)`, `bin(...)`, `uhex(...)`, `uoct(...)`, and `ubin(...)` accept:
  - a single scalar value (`hex(12)`)
  - a list of scalar values (`hex(1,2,3)`)
  - an array value (`hex((1,2,3))`)
- When `hex()` / `oct()` / `bin()` appear inside larger arithmetic expressions, normal arithmetic continues and final result is decimal unless the final top-level value is still formatted by `hex()` / `oct()` / `bin()`.

Examples:
- `atan2(1,1)` -> `0.7853981633974483`
- `floor(2.9)` -> `2`, `ceil(2.1)` -> `3`, `trunc(-2.9)` -> `-2`
- `int(2.9)` -> `2`, `int(-2.9)` -> `-2`
- `frac(2.5)` -> `0.5`, `frac(-2.5)` -> `-0.5`
- `round(2.5)` -> `3`, `sign(-123)` -> `-1`
- `deg(pi)` -> `180`, `rad(180)` -> `pi`
- `deg(pi/2, pi/4)` -> `(90, 45)`, `rad(180, 90)` -> `(pi, pi/2)`
- `hypot(3,4)` -> `5`
- `mod(17,5)` -> `2`
- `avg(1,2,3,4)` -> `2.5`, `mean((1,2,3),9)` -> `3.75`
- `median((1,9),3,7)` -> `5`
- `variance(1,2,3)` -> `0.6666666666666666`, `stddev(1,2,3)` -> `0.816496580927726`
- `clamp(15,0,10)` -> `10`
- `gcd(84,30)` -> `6`, `lcm(6,8)` -> `24`
- `fact(5)` -> `120`, `factorial(10)` -> `3628800`
- `rand()` -> random value in `[0,1)`, `random(10,20)` -> random value in `[10,20)`
- `sort((3,1,2))` -> `(1,2,3)`, `sort(2,5,1)` -> `(1,2,5)`
- `sorted((3,1,2))` -> `(1,2,3)`
- `reverse((3,1,2))` -> `(2,1,3)`, `reverse(2,5,1)` -> `(1,5,2)`
- `reversed((1,2,3),(4,5))` -> `(5,4,3,2,1)`
- `unique((3,1,3,2,1,2))` -> `(3,1,2)`, `unique(1,2,1,2,3)` -> `(1,2,3)`
- `f(x,y)=x*y; a=(2,3); f(unpack(a))` -> `6`
- `f(x,y,z)=x+y+z; f(unpack(1,2,3))` -> `6`
- `hex(12)` -> `0xC`
- `hex(1,2,3)` -> `(0x1,0x2,0x3)`
- `hex((1,2,3))` -> `(0x1,0x2,0x3)`
- `hex(-1)` -> `-0x1`
- `uhex(-1)` -> `0xFFFFFFFFFFFFFFFF`
- `oct(12)` -> `0o14`
- `oct(1,2,3)` -> `(0o1,0o2,0o3)`
- `oct((1,2,3))` -> `(0o1,0o2,0o3)`
- `bin(5)` -> `0b101`
- `bin(1,2,3)` -> `(0b1,0b10,0b11)`
- `bin((1,2,3))` -> `(0b1,0b10,0b11)`
- `0o64` -> `52`, `0b110011 & 0x37 | 0o64` -> `55`

## 2) Operators and Precedence

Supported operators:
- Exponentiation: `x ** y`
- Unary operators: `+x`, `-x`, `~x`, `!x`
- Multiplicative: `x * y`, `x / y`, `x % y`
- Additive: `x + y`, `x - y`
- Shifts: `x << y`, `x >> y`
- Bitwise: `x & y`, `x ^ y`, `x | y`
- Comparison: `x = y`, `x == y`, `x <> y`, `x != y`, `x > y`, `x >= y`, `x < y`, `x <= y`
- Logical NOT: `!x`, `not x`
- Logical AND: `x && y`, `x and y`
- Logical OR: `x || y`, `x or y`
- Postfix percentage: `x%` (percentage form, see section 3.6)

Implicit multiplication:
- Supported only before opening parenthesis:
  - `x(y + z)` means `x * (y + z)`
- Not supported before variable names:
  - `2x` is invalid (does not become `2*x`)

Operator precedence (highest -> lowest):
1. `**`
2. unary `+`, `-`, `~`, `!` (C/C++-style logical NOT)
3. postfix `%` (percentage form, `x%`)
4. `*`, `/`, `%` (binary modulo)
5. `+`, `-`
6. `<<`, `>>`
7. `&`
8. `^`
9. `|`
10. `=`, `==`, `<>`, `!=`, `>`, `>=`, `<`, `<=`
11. logical NOT (Python-style): `not`
12. logical AND: `&&`, `and`
13. logical OR: `||`, `or`

Parentheses can override precedence.

Note on logical NOT precedence:
- `!` is a high-precedence unary logical NOT, grouped with unary `+`, `-`, `~` (C/C++-style precedence).
- `not` is a low-precedence logical NOT placed below comparisons (Python-style precedence).
- Because they have different precedence, `!` and `not` are not interchangeable in mixed expressions.

Note on chained comparisons:
- Chained comparisons are evaluated left-to-right.
- Example: `2 < 3 < 4` is interpreted as `(2 < 3) < 4`.
- This differs from Python semantics:
  - Python interprets `a < b < c` as `(a < b) and (b < c)`.
  - Smart Math interprets it as `(a < b) < c`, where `(a < b)` becomes `1` or `0`.

Logical operators return scalar integer results:
- `1` for true
- `0` for false

For arrays (Python-compatible truthiness):
- empty array is false;
- non-empty array is true (regardless of element values).

## 3) Numbers, Literals, and Numeric Behavior

### 3.1 Decimal Literals
- Integers and floating-point are supported:
  - `42`
  - `3.1415`
  - `1e6`
  - `2.5e-3`

### 3.2 Hex Literals
- Prefix: `0x` / `0X`
  - Example: `0x7FF`
- Invalid form:
  - `0x` -> `invalid hex literal`

### 3.3 Binary Literals
- Prefix: `0b` / `0B`
  - Example: `0b01110110011`
- Invalid form:
  - `0b` -> `invalid binary literal`

### 3.4 Octal Literals
- Prefix: `0o` / `0O`
  - Example: `0o64`
- Invalid form:
  - `0o` -> `invalid octal literal`

### 3.5 Integer-Accuracy Policy
- Parser preserves exact signed 64-bit integer calculations whenever possible.
- It automatically falls back to floating-point when:
  - an operand is floating-point, or
  - an operation inherently yields floating-point (for example division), or
  - exact int64 result cannot be represented (overflow path).
- When a computation goes through floating-point but the result is exactly representable as a signed 64-bit integer (for example `sqrt(9)`, `abs(-4)`, or `sum(3,5)`), that exact integer form is retained for integer-only operators (shifts, bitwise, modulo) and for decimal display when applicable. Array elements are still stored as doubles; indexing a single element can recover exact-integer metadata when the stored value is an exact integer.

### 3.6 `%` Has Two Meanings
- Binary modulo operator:
  - `x % y`
  - Requires integer operands.
- Postfix percentage form:
  - `200 + 15%` -> `230`
  - `200 - 15%` -> `170`

## 4) Bitwise and Integer-Only Rules

Bitwise operators:
- `~`, `<<`, `>>`, `&`, `^`, `|`

Requirements:
- Bitwise and modulo operations require integer operands.
- Non-integer operands produce parser errors:
  - `bitwise operands must be integer values`
  - `modulo operands must be integer values`

Important range note:
- Bitwise/modulo are signed 64-bit integer operations.
- Values outside signed int64 range are not accepted by bitwise/modulo logic.

## 5) Arrays and Indexing

### 5.1 Array Literals
- Comma-separated values inside parentheses:
  - `(1,2,3)`

### 5.2 Element-Wise Operations
- Scalar-array and array-scalar operations are broadcast element-wise.
- Array-array operations require equal length.

Examples:
- `(1,2,3) + 10` -> `(11,12,13)`
- `(1,2,3) * 10` -> `(10,20,30)`
- `(1,2,3) ** 3` -> `(1, 8, 27)`
- `(1,2,3) + (10,20,30)` -> `(11,22,33)`
- `(1,2,3) + (10,20)` -> error (incompatible operands; array lengths must match)
- `(1,2,3) * (4,5,6)` -> `(4,10,18)`

### 5.3 Array Comparison Rules
- Comparison operators return scalar integer results:
  - `1` for true
  - `0` for false
- Arrays are compared lexicographically (Python-like behavior):
  - Compare values from left to right.
  - First mismatch determines the result.
  - If one array is a full prefix of the other, the shorter array is less than the longer one.
- Scalar-array comparisons are treated as comparison of one-element array against the other side.

Examples:
- `(1,2,3) = (1,2,3)` -> `1`
- `(1,2,3) < (1,2,4)` -> `1`
- `(1,2) < (1,2,0)` -> `1`
- `(1,3) > (1,2,3)` -> `1`

### 5.4 Indexing
- Array index syntax:
  - `arr[0]`
- Index must be an integer scalar.
- Negative indexes are supported:
  - `arr[-1]` = last item
  - `arr[-2]` = second item from the end
- Out-of-range access raises an error.

Examples:
- `(10,20,30)[0]` -> `10`
- `(10,20,30)[-1]` -> `30`
- `(10,20,30)[-2]` -> `20`
- `sort((3,1,4,2))[-1]` -> `4`
- `reverse((1,2,3,4))[0]` -> `4`
- `reverse((1,2,3,4))[-1]` -> `1`

### 5.5 Functions with Arrays
- Unary math functions apply element-wise.
- `sum`, `product`/`prod`, `min`, `max` flatten array arguments.
- `median`, `variance`, `stddev` also flatten array arguments.
- `sort(...)` flattens scalar/array arguments, then returns sorted values.
- `sorted(...)` is an alias of `sort(...)`.
- `reverse(...)` flattens scalar/array arguments, then returns values in reverse order.
- `reversed(...)` is an alias of `reverse(...)`.
- `unique(...)` flattens scalar/array arguments, then keeps first occurrences.
- `unpack(...)` unpacks scalar/array arguments into separate arguments:
  - scalar inputs are passed as-is: `unpack(1,2,3)` -> `1,2,3`;
  - array inputs are expanded element-by-element: `unpack((1,2),3)` -> `1,2,3`.
- Examples of standard functions with array values:
  - `sin((0,pi/4,pi/2))` -> `(0,0.70710678,1)` (element-wise unary function)
  - `sum((1,2,3),10)` -> `16` (flattened aggregation)
  - `sort((5,2,9))` -> `(2,5,9)`
  - `reverse((1,2,3),(4,5))` -> `(5,4,3,2,1)`
  - `unique((5,2,5,9,2))` -> `(5,2,9)`
  - `pow(unpack((5,2)))` -> `25`
  - `sum(unpack((1,2,3)))` -> `6`
  - `sum(unpack((1,2),3,(4,5)))` -> `15`
- `hex` / `oct` / `bin` (and `uhex` / `uoct` / `ubin`) can render array outputs:
  - `hex((12,255))` -> `(0xC,0xFF)`
  - `hex(12,255)` -> `(0xC,0xFF)`
  - `oct((12,255))` -> `(0o14,0o377)`
  - `oct(12,255)` -> `(0o14,0o377)`
  - `bin((1,2,5))` -> `(0b1,0b10,0b101)`
  - `bin(1,2,5)` -> `(0b1,0b10,0b101)`
  - `uhex(1,2)` -> `(0x1,0x2)`

## 6) Variables and User-Defined Functions

### 6.1 Variables
- Built-in variable:
  - `ans` = last successful result (scalar or array)
  - `ans` updates after each successful evaluated expression/statement.
- Assignment:
  - `a = 10`
- Usage:
  - `a * 3`
- Names **`pi`** and **`e`** are reserved built-in constants (case-insensitive): you cannot assign to them (`e = 1` is an error), and they cannot be used as user-defined function names or parameter names. In expressions they always refer to π and Euler’s number.
- Equality comparison uses two equals signs: `a == 10`. At the start of a statement, a single `=` after a name means assignment; `==` is never split into assign-then-equals, so expressions like `a==b` compare rather than assign.
- **When a single `=` means comparison:** the input must **not** be parsed as that special “identifier at the very beginning” form. Then `=` is handled inside the expression parser as equality (same meaning as `==`). Examples:
  - `5 = 5` → comparison (expression starts with a digit).
  - `(x) = (x)` → comparison (expression starts with `(`).
  - `1|2=3` → comparison (expression starts with a digit after optional leading ops / the left side is not “bare name at column 1”).
- **`x = x` at the start of a line/statement is assignment:** the right-hand `x` is evaluated, then stored back into `x` (same as any `x = expr`). For boolean equality on variables, use `x == x` or parenthesize, e.g. `(x) = (x)`.
- If anything other than spaces follows the first identifier before `=`, the line is an expression and `=` is comparison: e.g. `x + y = x` means `(x + y) = x`; `x * y = x * y` means `(x * y) = (x * y)` (equality test, `0` or `1`).
- Array assignment:
  - `v = (1,2,3)`
- Passing array variables to functions:
  - `sum(v)` -> `6`
  - `hex(v)` -> `(0x1,0x2,0x3)`
  - `a=(1,2,1,3,5,7,6,5); sort(a)` -> `(1,1,2,3,5,5,6,7)`
  - `a=(1,2,3,4); reverse(a)` -> `(4,3,2,1)`
- Examples with `ans`:
  - `2+3; ans/10` -> `0.5`
  - `(1,2,3); ans*10` -> `(10,20,30)`

### 6.2 User-Defined Functions
- Definition:
  - `f(x) = x * x + 1`
- Definition with two arguments:
  - `mix(a,b) = a*2 + b*3`
- Call:
  - `f(5)`
  - `mix(2,4)` -> `16`
  - `f(x,y)=x*y; a=(2,3); f(unpack(a))` -> `6`
  - `f(x,y,z)=x+y+z; f(unpack((1,2,3)))` -> `6`
  - `f(a,b,c,d,t)=a+b+c+d+t; f(unpack((1,2),3,(4,5)))` -> `15`
  - `f(a,b,c)=a*b*c; v=(2,3,4); f(unpack(v))` -> `24`

User-defined functions also accept array arguments when the expression supports
array math:
- `scale(v,k) = v*k  # definition`
- `scale((1,2,3),10)  # usage` -> `(10,20,30)`

Rules:
- Duplicate parameter names are not allowed in definitions.
- Function definitions are stored and reused in subsequent expressions.
- User-defined function names cannot match built-in function names.
- User-defined function names cannot match built-in operator keywords (`not`, `and`, `or`).
- User-defined function names and parameter names cannot match built-in constants (`pi`, `e`).

### 6.3 Statement Separator
- Top-level semicolon separates statements:
  - `a=2; a+3` -> `5`
  - `v=(1,2,3); exp(v)` -> `(2.718282,7.389056,20.085537)`

## 7) Comments

Single-line comments are supported with:
- `#`
- `//`

Examples:
- `1 + 2 # calculates 1 + 2`
- `// whole line comment`
- `# another whole line comment`
- `sin(pi/2) // inline comment`

## 8) Constants

Built-in constants:
- `pi`
- `e`

In expressions, these names are always resolved as constants **before** variables. For example `(e=3)` compares Euler’s number to `3` (false), not a user variable `e`. Use another name (e.g. `t`) if you need a variable.

You cannot create a variable or function parameter named `pi` or `e`; the parser reports `reserved constant name: …`.

## 9) Function Hints and Diagnostics

When a built-in function name is typed without call parentheses, parser provides a hint in the form:
- `function: name(signature)`

Examples:
- `function: pow(value, power)`
- `function: sin(angle)`
- `function: sum(...)`
- `function: median(...)`
- `function: hex(...)`
- `function: uhex(...)`
- `function: bin(...)`

Parser errors are one line, in this form:

- `{message} at col {C}:  {excerpt-with-|}`

The short excerpt includes `|` inserted at the exact reported column position so the location is visible even when the excerpt is taken from the middle of the input.

When `Parser_SetShowErrorLine(TRUE)` is used, the middle part becomes `at line 1, col {C}:  ` (still one physical line in the editor). Default is `FALSE`.

Example: `unexpected token at col 5:  5*5 |: 25`

## 10) Manual Formatting Options (`SmartMath.ini`)

In `[Settings]`, you can manually override one-character separators used by SmartMath rendering to e.g.:

```ini
DecimalSeparatorChar=,
ThousandsSeparatorChar=.
ArrayOutputSeparatorChar=;
```

Rules:
- Each value is treated as a single character.
- If more than one character is provided, only the first character is used.
- If a key is missing or empty, SmartMath falls back to defaults:
  - `DecimalSeparatorChar=.`  
  - `ThousandsSeparatorChar='`  
  - `ArrayOutputSeparatorChar=,`
- Input expression argument separator remains comma (`,`).
- If `ArrayOutputSeparatorChar` is not comma, double-click copy normalizes array output back to comma so copied text is valid parser input.

## 11) Troubleshooting

If you need to diagnose a crash or a problematic input line, you can enable per-line parser logging in `SmartMath.ini`.

`SmartMath.ini` (`[Settings]` section):

```ini
LogParsedLines=1
```

Notes:
- `LogParsedLines=0` disables this logging (default).
- After editing `SmartMath.ini`, toggle SmartMath off/on (or restart AkelPad) to reload settings.
- Logs are emitted via Windows `OutputDebugString`.
- You can view these logs in [DbgView (Sysinternals)](https://learn.microsoft.com/sysinternals/downloads/debugview).
- Log entries include `parse-line begin [...]` / `parse-line end [...]`, which helps identify the last processed line before a failure.

