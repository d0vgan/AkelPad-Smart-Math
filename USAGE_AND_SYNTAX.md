# SmartMath Usage and Syntax

## What Is SmartMath?

SmartMath evaluates math expressions inside AkelPad.

- You type an expression in a line.
- SmartMath shows the result in the right margin.
- The result is not inserted into the file text.
- Double-click the result to copy a clean value/error string.

### Mini Glossary

- `scalar`: a single number, for example `42` or `3.5`.
- `array`: a list of numbers in parentheses, for example `(1,2,3)`.
- `expression`: any calculable input, for example `2+3` or `sin(pi/2)`.
- `statement`: one top-level unit. Multiple statements can be separated with `;`.

## Quick Start

Copy/paste examples:

- `2+3*4` -> `14`
- `a=10; a*3` -> `30`
- `(1,2,3)+10` -> `(11,12,13)`
- `sum(1,2,3,10)` -> `16`
- `sort(3,1,2)` -> `(1,2,3)`
- `hex(255)` -> `0xFF`
- `uhex(-1)` -> `0xFFFFFFFFFFFFFFFF`
- `2+3; ans/10` -> `0.5`
- `f(x)=x*x+1; f(5)` -> `26`
- `clamp((1,9),0,7)` -> `(1,7)`

## Common Tasks

### Numeric Values

Decimal/scientific forms:

- `42`
- `3.1415`
- `1e6` -> `1000000`
- `2.5e-3` -> `0.0025`

Base-prefixed integer forms:

- `0x7FF` - hexadecimal
- `0b01110110011` - binary
- `0o64` - octal

### Percent Calculation

- Use postfix percent for percentage math:
  - `200 + 15%` -> `230`
  - `200 - 15%` -> `170`

### Arrays

- Make arrays with commas in parentheses:
  - `(1,2,3)`
- A single value in parentheses without commas is not an array; it’s just grouping:
  - `(5)` behaves like scalar `5`
  - `((5))` also behaves like scalar `5` (still just grouping)
- Use element-wise math:
  - `(1,2,3)*10` -> `(10,20,30)`
  - `(1,2,3)+(10,20,30)` -> `(11, 22, 33)`
  - `2**(3,5,6)` -> `(8, 32, 64)`
- Index arrays with `[index]`:
  - `(10,20,30)[0]` -> `10` (first element)
  - `(10,20,30)[-1]` -> `30` (last element)
- Pass array to functions:
  - `sqrt((9,25,36))` -> `(3, 5, 6)`
  - `pow((3,2), 4)` -> `(81, 16)`
  - `sin((pi/4,pi/2))` -> `(0.707107, 1)`
- Use array utilities:
  - `reverse((1,2,3),(4,5))` -> `(5,4,3,2,1)`

### Variables and `ans`

- Assign with `=`:
  - `a = 10`
- Reserved names cannot be assignment targets:
  - function names (for example `hex`, `random`, `sin`)
  - built-in constants (`pi`, `e`, `inf`, `nan`)
- Reuse values:
  - `a*3` -> `30`
- `ans` is the last successful result:
  - `2+3; ans*10` -> `50`
- Assign and use arrays:
  - `v = (2,1,3)`
  - `v/3` -> `(0.666667, 0.333333, 1)`
  - `sum(v)` -> `6`
  - `sort(v)` -> `(1, 2, 3)`
  - `(v[-1],v[-2])` -> `(3, 1)`
  - `v=(1,2,3); exp(v)` -> `(2.718282, 7.389056, 20.085537)`

### Formatting Output

- Decimal is default.
- Use helper functions for base formatting:
  - `hex(12)` -> `0xC`
  - `oct(12)` -> `0o14`
  - `bin(5,7)` -> `(0b101, 0b111)`
  - `uhex(-1)` -> `0xFFFFFFFFFFFFFFFF`
- Trailing formatter sugar after `;` is supported:
  - `0xAA; hex` -> `0xAA` (same as `0xAA; hex(ans)`)
  - `(8,9,10); oct()` -> `(0o10, 0o11, 0o12)` (same as `(8,9,10); oct(ans)`)

### User-Defined Functions

- Define:
  - `f(x)=x*x+1`
- Reserved names cannot be used for function names:
  - `hex(x)=x` -> error (`reserved function name`)
  - `e(x)=x` -> error (`reserved constant name`)
  - `nan=1` -> error (`reserved constant name`)
- Call:
  - `f(5)` -> `26`
  - `f((10,20))` -> `(101, 401)`
- Multiple args:
  - `mix(a,b)=a*2+b*3; mix(2,4)` -> `16`
  - `f(a,b,c)=a+b*c; f(2,3,4)` -> `14`
  - `f(a,b,c)=a+b*c; v=(2,3,4); f(unpack(v))` -> `14`
- Recursive functions are not supported.

#### Late Binding of Referenced Functions

- User-defined functions use late binding (runtime name resolution) for referenced function names.
- If a dependency is missing at call time, evaluation fails with an unknown-function error.
- If that dependency is defined later, the original function starts working without redefinition.
- Example:
  - `f(x)=x*g(x)`
  - `f(2)` -> `unknown function: g`
  - `g(x)=x+5; f(10)` -> `150`
  - `g(x)=x**(1/3); f(8)` -> `16`

#### User-Defined Functions Validation

When you define a function, the body is evaluated once with **dummy** arguments so obvious errors are caught early. Every parameter is replaced by the scalar variable **`_`** with the default value of **`1`**. Real calls still use the arguments you pass.

With the default **`_` = `1`**, validation can fail even when the function would work for other inputs:

- `f(x)=(x/2)<<2` -> error `bitwise operands must be integer values` (dummy gives `(1/2)<<2`, a float on the left of `<<`).
- `f(x,y)=x%(y-1)` -> error `incompatible operands` (dummy gives `1%0`).

Set **`_`** before the definition so the check uses a better dummy, e.g. **`_=2`**:

- `_=2; f(x)=(x/2)<<2` -> OK (`(2/2)<<2`).
- `_=2; f(x,y)=x%(y-1)` -> OK (`2%(2-1)`).

### Comments

- Line comments are supported with `#` or `//`.
- Everything after the comment marker is ignored.
- Useful for keeping notes next to expressions.

Examples:
- `2+3 # comment` -> `5`
- `hex(255) // display as hex` -> `0xFF`

## Core Language Rules

### Operators

- Exponent: `**`
- Unary: `+x`, `-x`, `~x`, `!x`, `not x`
- Multiplicative: `*`, `/`, `%` (modulo)
- Additive: `+`, `-`
- Shifts: `<<`, `>>`
- Bitwise: `&`, `^`, `|`
- Comparisons: `=`, `==`, `<>`, `!=`, `>`, `>=`, `<`, `<=`
- Logical: `&&`/`and`, `||`/`or`
- Postfix percent: `x%`

### Precedence (High -> Low)

1. `**` (power)
2. unary `+`, `-`, `~`, `!`
3. postfix `%` (percentage form `x%`)
4. `*`, `/`, `%` (modulo `x % y`)
5. `+`, `-`
6. `<<`, `>>` (bitwise shift)
7. `&` (bitwise and)
8. `^` (bitwise xor)
9. `|` (bitwise or)
10. `=`, `==`, `<>`, `!=`, `>`, `>=`, `<`, `<=`
11. `not` (logical not)
12. `&&`, `and` (logical and)
13. `||`, `or` (logical or)

Use parentheses to make intent explicit.

### Mini Guide: `=` vs `==`

- `x = ...` at statement start is assignment.
- `==` is always comparison.
- Single `=` can still be comparison when not in assignment form.

Examples:

- `a=10` -> assignment
- `a==10` -> comparison
- `5=5` -> comparison (`1`)
- `(x)=(x)` -> comparison
- `x+y=x` -> comparison

Recommendation: use `==` for equality checks to avoid confusion.

### Mini Guide: `%` Means Two Different Things

- Binary modulo:
  - `17%5` -> `2`
- Postfix percent:
  - `200+15%` -> `230`
- Percentage math and precedence:
  - `5 + 2*3%` means `5 + (2*3%)` -> `5 + 0.06` -> `5.06`.
  - `5 + (2*3)%` means `5 + 6%` -> `5 + (5*0.06)` -> `5.3`.
- Tricky examples:
  - `5 % -20` means `(5%) - 20` -> `0.05 - 20` -> `-19.5`.
  - `-20 + 5%` means `-20 + (-20*0.05)` -> `-21`.
  - `5 % (-20)` means `mod(5, -20)` -> `5`.

### Mini Guide: `!` vs `not`

- `!` has high precedence.
- `not` has lower precedence.
- They are not interchangeable in mixed expressions.

Logical note (scalar vs array):
- `!x` / `not x` are logical NOT and always return a scalar (`1` or `0`).
- Non-empty arrays are always treated as truthy in logical operators, so `!(0,0)`, as well as `not (0,0)`, evaluates to `0`.
- Precedence contrast (only in mixed expressions):
  - `!2==1` -> `0`
  - `not 2==1` -> `1`
- These happen because of precedence:
  - `!2==1` parses like `(!2)==1` -> `0`
  - `not 2==1` parses like `not (2==1)` -> `1`

Recommendation: parenthesize when using `not` in complex expressions.

### Arrays in Logical and Bitwise Operators (With Arrays)

- `x && y` and `x || y` are logical and return a scalar (`1` or `0`). If an operand is a non-empty array, that operand is considered truthy.
  - `(0,0) && 1` -> `1`
  - `0 || (0,0)` -> `1`
- `x & y`, `x ^ y`, and `x | y` are bitwise and work element-wise:
  - If an operand is an array, the result is an array.
  - If both operands are arrays and their shapes/lengths are incompatible, you may get `incompatible operands`.
  - Bitwise operators require integer inputs (use `int(...)` to convert floats).
  - Example: `(1,2,3) & 1` -> `(1,0,1)`
  - Example: `(1,2,3) | 1` -> `(1,3,3)`

### Arrays and Comparisons

- Arrays are compared item by item, until the first mismatch or until the end of an array.
  - Example: `(10,20) > 20` -> `0` because the first item `10` < `20`.
  - Example: `(1,2,3) < (1,3)` -> `1` because the second item `2` < `3`.
  - Example: `(1,2,0) >= (1,2)` -> `1` because the values are equal until the end of the 2nd array.
  - Example: `(1,2) == sort(2,1)` -> `1` because the arrays are equal after sorting.

### Chained Comparisons Warning

- Chained comparisons are evaluated left-to-right.
- `2<3<4` is interpreted as `(2<3)<4`.
- That means `2<3` becomes `1`, then `1<4` is evaluated.

This differs from Python-style chained comparison logic.

## Function Reference

Quick index (alphabetical):

| Function(s) | Category |
|---|---|
| `abs(value)` | numeric utility |
| `acos/arccos(value)` | trigonometric |
| `acosh(value)` | trigonometric/hyperbolic |
| `asin/arcsin(value)` | trigonometric |
| `asinh(value)` | trigonometric/hyperbolic |
| `atan/arctan(value)` | trigonometric |
| `atan2(y, x)` | trigonometric |
| `atanh(value)` | trigonometric/hyperbolic |
| `avg/mean(...)` | aggregation |
| `bin(...)` | output formatting |
| `ceil(value)` | numeric utility |
| `clamp(value, min, max)` | numeric utility |
| `cos(angle)` | trigonometric |
| `cosh(value)` | trigonometric/hyperbolic |
| `deg(...)` | trigonometric conversion |
| `exp(value)` | logarithmic/exponential |
| `fact/factorial(n)` | numeric utility |
| `floor(value)` | numeric utility |
| `frac/fract(value)` | numeric utility |
| `gcd(a, b)` | numeric utility |
| `hex(...)` | output formatting |
| `hypot(x, y)` | power/root |
| `int(value)` | numeric utility |
| `lcm(a, b)` | numeric utility |
| `ln(value)` | logarithmic/exponential |
| `log(value, base)` | logarithmic/exponential |
| `log10(value)` | logarithmic/exponential |
| `max(...)` | aggregation |
| `median(...)` | aggregation |
| `min(...)` | aggregation |
| `mod(value, divisor)` | numeric utility |
| `ncr(n, r)` | numeric utility |
| `npr(n, r)` | numeric utility |
| `oct(...)` | output formatting |
| `pow(value, power)` | power/root |
| `product/prod(...)` | aggregation |
| `rad(...)` | trigonometric conversion |
| `rand()` | random |
| `random(min, max)` | random |
| `reverse/reversed(...)` | array utility |
| `round(value)` | numeric utility |
| `sign(value)` | numeric utility |
| `sin(angle)` | trigonometric |
| `sinh(value)` | trigonometric/hyperbolic |
| `sort/sorted(...)` | array utility |
| `sqrt(value)` | power/root |
| `sqr(value)` | power/root |
| `stddev(...)` | aggregation |
| `sum(...)` | aggregation |
| `tan(angle)` | trigonometric |
| `tanh(value)` | trigonometric/hyperbolic |
| `trunc(value)` | numeric utility |
| `ubin(...)` | output formatting |
| `uhex(...)` | output formatting |
| `unique(...)` | array utility |
| `unpack(...)` | array utility |
| `uoct(...)` | output formatting |
| `variance(...)` | aggregation |

### Trigonometric and Hyperbolic

Purpose: angle and trig math.

- Key functions:
- `sin(angle)` - sine of an angle (radians)
- `cos(angle)` - cosine of an angle (radians)
- `tan(angle)` - tangent of an angle (radians)
- `asin(value)`, `arcsin(value)` - inverse sine
- `acos(value)`, `arccos(value)` - inverse cosine
- `atan(value)`, `arctan(value)` - inverse tangent
- `atan2(y, x)` - angle of vector `(x,y)` in radians
- `sinh(value)` - hyperbolic sine
- `cosh(value)` - hyperbolic cosine
- `tanh(value)` - hyperbolic tangent
- `asinh(value)` - inverse hyperbolic sine
- `acosh(value)` - inverse hyperbolic cosine
- `atanh(value)` - inverse hyperbolic tangent
- `deg(...)` - convert radians to degrees
- `rad(...)` - convert degrees to radians
- Examples:
  - `sin(pi/2)` -> `1`
  - `atan2(1,1)` -> `0.7853981633974483`
  - `deg(pi)` -> `180`
  - `rad(180)` -> `pi`
  - `cos(rad(30,45,60))` -> `(0.866025, 0.707107, 0.5)`
  - `acos((sqrt(3)/2, sqrt(2)/2, 1/2)); deg` -> `(30, 45, 60)`

### Logarithmic and Exponential

Purpose: growth/scale and logarithm operations.

- Key functions:
- `exp(value)` - Euler exponential (`e**x`)
- `ln(value)` - natural logarithm
- `log(value, base)` - logarithm in a chosen base
- `log10(value)` - base-10 logarithm
- Examples:
  - `ln(exp(3))` -> `3`
  - `log(8,2)` -> `3`
  - `log10(1000)` -> `3`

### Power and Root

Purpose: power (`**`) and root operations.

- Key functions:
- `pow(value, power)` - raise value to a power (same as `value ** power`)
- `sqrt(value)` - square root
- `sqr(value)` - square (value * value)
- `hypot(x, y)` - hypotenuse (`sqrt(x*x + y*y)`)
- Examples:
  - `pow(27,1/3)` -> `3`
  - `2**63` -> `9223372036854775808`
  - `sqrt(25)` -> `5`
  - `hypot(3,4)` -> `5`

### Numeric Utilities

Purpose: rounding, bounds, integer helpers, factorial.

- Key functions:
- `floor(value)` - largest integer less than or equal to value
- `ceil(value)` - smallest integer greater than or equal to value
- `trunc(value)` - drop fractional part toward zero
- `int(value)` - integer part toward zero (same as `trunc`)
- `frac(value)`, `fract(value)` - fractional part (`value - int(value)`)
- `round(value)` - nearest integer
- `abs(value)` - absolute value
- `sign(value)` - sign as `-1`, `0`, or `1`
- `clamp(value, min, max)` - limit value to `[min, max]`
- `gcd(a, b)` - greatest common divisor
- `lcm(a, b)` - least common multiple
- `mod(value, divisor)` - modulo as a function form of `value % divisor`
- `ncr(n, r)` - combinations (`n` choose `r`)
- `npr(n, r)` - permutations (`n` permute `r`)
- `fact(n)`, `factorial(n)` - factorial for non-negative integers
- Examples:
  - `round(2.5)` -> `3`
  - `clamp(15,0,10)` -> `10`
  - `gcd(84,30)` -> `6`
  - `ncr(5,2)` -> `10`
  - `npr(5,2)` -> `20`
  - `fact(21)` -> `5.109094217170944e+019`

### Arrays and Aggregation

Purpose: aggregate and transform values/lists.

- Key functions:
- `sum(...)` - sum all inputs
- `product(...)`, `prod(...)` - multiply all inputs
- `avg(...)`, `mean(...)` - average of all inputs
- `median(...)` - median of flattened inputs
- `variance(...)` - population variance
- `stddev(...)` - population standard deviation
- `min(...)` - smallest value
- `max(...)` - largest value
- `sort(...)`, `sorted(...)` - sorted flattened values
- `reverse(...)`, `reversed(...)` - reversed flattened values
- `unique(...)` - first-occurrence unique values
- `unpack(...)` - expand arrays into positional arguments
- Examples:
  - `sum(1,2,3,10)` -> `16`
  - `product(18446744073709551615,1)` -> `18446744073709551615`
  - `avg(1,2,3,4)` -> `2.5`
  - `sort(3,1,2)` -> `(1,2,3)`
  - `sort(nan,inf,2,-inf,nan,-2)` -> `(nan,nan,-inf,-2,2,inf)`
  - `unique(3,1,3,2,1,2)` -> `(3,1,2)`
  - `a=(5,2); pow(unpack(a))` -> `25`

Notes:

- Aggregation functions flatten array inputs.
- `variance` and `stddev` use population formulas (`N`, not `N-1`).

### Output Formatting

Purpose: render values in hex/oct/bin.

- Key functions:
- `hex(...)` - format output in hexadecimal
- `oct(...)` - format output in octal
- `bin(...)` - format output in binary
- `uhex(...)` - unsigned-style hexadecimal formatting
- `uoct(...)` - unsigned-style octal formatting
- `ubin(...)` - unsigned-style binary formatting
- Examples:
  - `hex(12)` -> `0xC`
  - `bin(5,11)` -> `(0b101, 0b1011)`
  - `uhex(-1)` -> `0xFFFFFFFFFFFFFFFF`
  - `170; hex` -> `0xAA`
  - `(0x5,0x10); oct` -> `(0o5, 0o20)`
  - `0xFFFFFFFF & ~0x123; uhex` -> `0xFFFFFEDC`

Notes:

- Formatting functions require integer values.
- `uhex/uoct/ubin` show unsigned 64-bit style for negatives.

### Random

Purpose: random values.

- Key functions:
- `rand()` - random scalar in `[0,1)`
- `random(min, max)` - random scalar in `[min,max)` (or exact bound if equal)
- Examples:
  - `rand()` -> random value in `[0,1)`
  - `random(10,20)` -> random value in `[10,20)`
  - `random(5,5)` -> `5`

## Advanced Numeric Behavior

### Advanced Behavior: Integer Accuracy (Int64/UInt64)

- SmartMath tries to keep exact signed 64-bit integer semantics when possible.
- It falls back to floating-point when required (for example division or overflow path).
- Integer-only operators are checked in a defined signed 64-bit domain.
- Shift count must be in `0..63`.

Advanced examples:

- `hex(int((9007199254740992+2)/1))` -> `0x20000000000002`
- `a=(4611686018427387903,5)<<1; hex(a[0])` -> `0x7FFFFFFFFFFFFFFE`
- `a=(9223372036854775806,9223372036854775805); b=a>>2; hex(b[0])` -> `0x1FFFFFFFFFFFFFFF`

### Advanced Behavior: NaN / Inf

- Rendering:
  - `nan`, `inf`, `-inf`
- Truthiness:
  - finite nonzero and infinities are truthy (`1`)
  - `0` and `nan` are falsy (`0`)
- Integer-only operations reject `nan`/`inf`.

### Compatibility Behavior (Current)

- `nan == nan` evaluates to `0` (IEEE unordered: NaN is not equal to any value, including another NaN).
- `nan != nan` is `1`.

These behaviors may differ from other tools/languages.

### Literals

- Decimal: `42`, `3.1415`, `1e6`
- Hex: `0x7FF`
- Binary: `0b1011`
- Octal: `0o64`
- Invalid prefixes alone are errors (for example `0x`, `0b`, `0o`).

## Errors and Troubleshooting

### Common Errors and Fixes

- `unexpected token`
  - Usually caused by malformed syntax.
  - Example: `1 + * 2`
  - Fix: check operators, commas, and parentheses.

- `bitwise operands must be integer values`
  - Example: `1.5 & 1`
  - Fix: use integer inputs.

- `modulo operands must be integer values`
  - Example: `5.2 % 2`
  - Fix: use integer inputs.

- `... expects N argument(s)`
  - Example: `pow(2)`
  - Fix: match the function signature.

- `incompatible operands`
  - Often array length mismatch.
  - Example: `(1,2,3) + (10,20)`
  - Fix: use same-length arrays or scalar broadcasting where supported.

- `array index is out of range`
  - Example: `(10,20)[5]`
  - Fix: use a valid index (`0..len-1` or negative within bounds).

### Diagnostics Format

- Errors are one line and include location context (`col`, optional `line`).
- Current builds usually include an excerpt with `|` near the position.
- With `Parser_SetShowErrorLine(TRUE)`, location text includes line info.

Example:

- `unexpected token at col 5:  5*5 |: 25`

## SmartMath Options

Depending on AkelPad's settings, SmartMath Options are stored either in "AkelFiles\Plugs\SmartMath.ini" or under "HKEY_CURRENT_USER\SOFTWARE\Akelsoft\AkelPad\Plugs\SmartMath" in Registry.

Manual formatting options:

```ini
[Options]
DecimalSeparatorChar=,
ThousandsSeparatorChar=.
ArrayOutputSeparatorChar=;
```

Rules:

- Each of these keys uses one character (extra characters are ignored).
- Missing/empty key falls back to defaults:
  - `DecimalSeparatorChar=.`
  - `ThousandsSeparatorChar='`
  - `ArrayOutputSeparatorChar=,`
- Input expression argument separator stays comma (`,`).
- If array output separator is changed, double-click copy normalizes array output back to comma for valid parser input.

Troubleshooting logging option:

```ini
LogParsedLines=1
```

- `0` disables logging (default).
- `1` enables logging.
- Toggle SmartMath off/on (or restart AkelPad) after editing `SmartMath.ini` or Registry.
- Logs are sent through Windows `OutputDebugString`.
- You can inspect logs with [DbgView (Sysinternals)](https://learn.microsoft.com/sysinternals/downloads/debugview).

