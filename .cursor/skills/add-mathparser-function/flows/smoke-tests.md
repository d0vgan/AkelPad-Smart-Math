# Smoke / Parity Tests (Authoring Expectations)

Load when **adding or reviewing** smoke/parity test expectations — not when only running gates (use `.cursor/skills/internal-mathparser-build-gates/SKILL.md` for that).

For complex-domain cases, also read `.cursor/skills/add-mathparser-function/flows/complex-support.md`.

## Coverage in `SmokeTest_MathParser.bas`

- Normal behavior; invalid arity/types; array/scalar combos when arrays apply; variadic min + extra args when applicable.
- Match existing naming and assertion style.
- If the function is 1-arg or variadic: one normal single-arg case, one single-arg edge, and one single-arg overflow/range case when the domain has limits.

Minimum recommended set: happy-path scalar; boundary/edge; failure; array-related (if supported); plus the single-arg set above when applicable.

Mirror equivalent cases into `cpp/Tests_MathParser.cpp` when C++ exists (parity skill).

## External reference for expected values (Required)

Applies to `SmokeTest_MathParser.bas`, `cpp/Tests_MathParser.cpp`, generated band tables, coverage-audit batches.

- **Do not** seed `expected` from current Basic/C++ parser output (`Parser_TryEvaluateEx` / `parseAndEvaluate`) — that locks bugs in.
- **Do** derive expectations from, in order:
  1. `USAGE_AND_SYNTAX.md` (documented examples / intentional semantics)
  2. **Python** (`math` / `cmath` / `statistics` / project rules) — prefer `tools/verify_smoke_expected_vs_python.py` when it already translates the expression; else a short script/REPL
  3. IEEE / exact-integer rules when the doc is silent (e.g. `nan==nan` → `0`, int64 overflow promotion)
- After setting expectations, run both harnesses. Failures are parser/formatter defects unless the spec intentionally differs (then document in `USAGE_AND_SYNTAX.md` and test the spec).
- Float: `ResultCloseEnough` / `smokeResultCloseEnough`. Exact strings for exact integers, `0`/`1`, and `inf`/`nan` families per existing smoke policy.

**Strange Python / principal-branch results** (e.g. complex where a real calculator answer is natural):

- Prefer a **real** value that satisfies the expression under project real-only semantics when applicable.
- Confirm with the **inverse** when possible (`(-5)**3` = `-125` ⇒ `(-125)**(1/3)` = `-5`, not a complex root).
- Comment in the test when diverging from Python’s default library branch.

**Errors:** prefer substrings from `USAGE_AND_SYNTAX.md` or documented error policy — do not copy ad-hoc parser text unchecked.

## Value preservation in tests (Required)

Encode correct math/structure; do not tolerate implementation bugs.

- Never assert a weakened result just because the parser currently returns it (dropped Cartesian parts, wrong `inf`/`nan` collapse, etc.). Never seed `expected` from live parser output.
- Aggregates / structure-only builtins (`sum`, `product`, `reverse`, `unique`, `unpack`, `sort`, aliases): operands survive except for the operation itself.
- Operands with `inf`/`-inf`/`nan`: expected strings still show every non-zero Cartesian part, exact int metadata when applicable, and time/duration formatting when applicable.
- After tightening expectations, **fix the parser** (Basic and C++), do not loosen the test, unless the spec defines different semantics (document + test the spec).
- `nan` is valid only when IEEE or documented domain rules require it — not from spurious `0*Inf` or display shortcuts.
