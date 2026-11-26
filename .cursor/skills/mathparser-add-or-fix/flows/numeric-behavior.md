# Numeric Behavior (Internal Reference)

Load when implementing, fixing, or testing numeric edge cases, NaN/Inf handling, trig snapping, aggregation accuracy, float display digit choice, or RNG detail. These rules are **agent/internal** — do **not** paste them into `USAGE_AND_SYNTAX.md` (usage-docs "Audience"). Lock them with smoke/parity tests and keep Basic/C++ parity. A brief Advanced Behavior note in USAGE is allowed only when usage-docs says so.

Accepted decisions below are already settled (raise-concerns "Already decided"). A **new** rejection or limit still goes through raise-concerns.

## Trig angle snap (`sin` / `cos` / `tan`)

Mirror `CalcSin` / `CalcCos` / `CalcTan` (Basic) and `calcSin` / `calcCos` / `calcTan` (C++):

- Snap only when the angle is a multiple of `pi/2` (and for `tan`, also `pi/4` odd multiples → `±1`) within the same residual tolerance as `IsMultipleOf` / `TryTrigHalfPiQuotient` (a few ulps of the multiple; `|k|` must fit exact-int-from-float).
- Then `sin` / `cos` return exact `0`, `±1` from `k mod 4`; `tan` returns `0` on `pi` multiples and `±inf` on odd `pi/2` multiples.
- Do **not** snap approximate constants: `sin(1e-10)`, `sin(3.14159265359)`, `cos(1.5707963268)` stay unsnapped (near-zero or wrong-sign residual relative to true `pi`).
- Example that must snap: `cos(1e12*pi)` → `1` (float display may keep `.0`).

Python `math.sin` / `math.cos` without this snap is **not** the reference for those exact-multiple cases; the verifier stubs (`sin_sm` / `cos_sm` / `tan_sm`) must mirror the parser.

## `sign` and NaN

- Real `sign(nan)` → `nan` (not `0`). Plain compare `x < 0` / `x > 0` is wrong for NaN.
- `sign(±inf)` → `±1`. Complex `sign` stays `c/abs(c)` (coding-standards / complex-support for non-finite complex).

## Aggregates: `sum`, `avg`/`mean`, `median`, `unique`, compares/sorts

- **`sum`:** floating-point terms use compensated (Neumaier) summation (same idea as Python 3.12+ `sum` / `math.fsum`). Example: `sum(1e100, 1, -1e100)` → `1`; `sum(0.1, 0.2, 0.3)` → `0.6`. Exact integers stay exact.
- **`avg` / `mean`:** integer inputs are summed and divided exactly when possible (`avg(9007199254740993, 9007199254740995)` → `9007199254740994`).
- **`median`:** any input `nan` → `nan`. Even count: average the two middle values with an overflow-safe float form (`0.5*lo + 0.5*hi`), so `median(1e308, 1.5e308)` → `1.25e+308` and `median(-1e308, 1e308)` → `0`. Integer middles above `2^53` compare and average exactly.
- **`unique` / `sort` / compares:** distinct exact integers above `2^53` (and SmUInt range) stay distinct and order by true integer value — never by float equality that collapses them. `unique` keeps only the first NaN; later `nan` / `-nan` drop (USAGE Advanced Behavior may mention NaN uniqueness briefly; full exact-int rule stays here).
- Empty remaining values → `()` (empty-array-policy).

## Float display digits

- Prefer the shortest decimal that round-trips (often 15 significant digits); use 16 when 15 is not enough. Large binary64 magnitudes keep scientific form (`1e23` → `1e+023`).
- C++ / Basic / plugin formatter differences that remain intentional are listed in the parity skill (ties, `±2^53` display). Do not document digit heuristics in USAGE function sections.

## Random

- `rand` / `random` are seeded from the clock at start-up.
- C++ draws a full floating-point mantissa per call; keep Basic/C++ statistical contract (`random(a,a)` → `a`, range half-open) without putting RNG implementation text in USAGE.

## Where else this lives

| Concern | Also see |
|---|---|
| Exact-int metadata / `MAX_MAGNITUDE` | coding-standards "Integer metadata preservation" |
| Non-finite accept/reject for a **new** path | coding-standards "Non-finite values" + raise-concerns |
| Empty `()` aggregates | empty-array-policy |
| Test expectations / Python verifier stubs | smoke-tests; `tools/verify_smoke_expected_vs_python.py` |
| End-user wording | usage-docs "Audience" |
