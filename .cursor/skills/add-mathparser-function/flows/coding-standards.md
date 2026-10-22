# Coding Standards (Parser Implementation)

Load when writing or editing Basic/C++ parser implementation (skip for docs-only or gate-only work).

## Helper reuse and optimization

For any source change (feature/fix/refactor/cleanup/optimization):

- Prefer shared helpers; avoid duplication.
- Search for an existing helper that covers or nearly covers the need before adding a new one.
- If close: extend/tune it and migrate old and new call sites; keep it hot-path efficient.
- If no fit without harming clarity/behavior/performance: add a **narrow** new helper (no overlapping responsibilities).
- Reuse existing locals/state before new temporaries; add a variable only when needed for correctness, readability, or performance.
- Keep project indentation and clean nested blocks when refactoring.

## Integer metadata preservation (Required)

In Basic and C++:

- Treat exact signed/unsigned int64 metadata as first-class (`exactInt64` / `exactUInt64` or equivalents).
- Propagate metadata that is already valid, including when the stored result is floating-point. Do not drop valid exact-int or exact-uint metadata. An integer-looking double is not by itself an exact integer.
- Structure-only transforms (flatten, reshape, sort, reverse, dedupe, format, unpack, etc.) must not drop metadata via raw `double`/`Double` buffers.
- Prefer metadata-carrying scalar walkers (`ScalarValue`-like) over float-only containers on context-preserving paths.
- Float-derived restoration: restore only under project exactness policy; **reject** on overflow, fractional values, NaN/Inf, and out-of-policy ranges; keep Basic/C++ boundaries and errors aligned. **`MAX_MAGNITUDE` = `2^53`** (code: `FB_MAX_EXACT_INT_FROM_DOUBLE`, `kMaxExactIntFromDouble`). That is the largest double **magnitude** at which every integer is still exact. Do not restore an exact integer from a double whose magnitude is greater than `MAX_MAGNITUDE`. Use this name below; do not repeat the literal.
- Transcendental, variance, stddev, and similar paths may leave a non-integral result as float without integer metadata; justify and cover with tests. When the result is an exact integer with magnitude `<= MAX_MAGNITUDE`, the next subsection still applies.

### Float-capable builtins keep exact integer metadata (Required)

Attaches metadata. Does not round a non-integer into an integer. Does not restore an integer from a double with magnitude greater than `MAX_MAGNITUDE`.

Applies when **adding** a builtin or operator, or when **intentionally changing** numeric behavior. A behavior-preserving cleanup keeps the metadata behavior it found.

For each scalar and every array element:

- **Preserve** `exactInt64` / `exactUInt64` (or equivalents) when that metadata is already valid. An integer operation may have produced a value with magnitude greater than `MAX_MAGNITUDE`; keep that metadata. Do not re-derive it from the double.
- **Restore from the double** only when its magnitude is `<= MAX_MAGNITUDE` and the value is an exact integer:
  - exact-int when the value is in `-MAX_MAGNITUDE`…`MAX_MAGNITUDE`;
  - exact-uint when the value is in `0`…`MAX_MAGNITUDE`;
  - a value in `0`…`MAX_MAGNITUDE` gets **both**; a value in `-MAX_MAGNITUDE`…`< 0` gets exact-int only.
- **Magnitude greater than `MAX_MAGNITUDE`:** do not convert the double with `CLng` or a cast. The unit in the last place is greater than 1, so a fraction or low bits may already be gone. This includes negative values such as `-MAX_MAGNITUDE - 1`.
- An operation expected to produce an integer (sum of integer values, subtraction of integer values, any other integer-valued function or operation) keeps the integer **that operation produced**, even when its magnitude is greater than `MAX_MAGNITUDE`. That integer comes from the operation, not from the double. If the only remaining value is a double with magnitude greater than `MAX_MAGNITUDE`, the exact integer **cannot** be restored. For that produced integer, use the full integer ranges, not `MAX_MAGNITUDE`: exact-int in `INT64_MIN`…`INT64_MAX`, exact-uint in `0`…`UINT64_MAX`, **both** in `0`…`INT64_MAX`, exact-int only when negative, exact-uint only above `INT64_MAX` through `UINT64_MAX`.
- Do not use a tolerance helper (such as `nearlyInt`) to stamp exact metadata.
- Keep Basic/C++ parity. Lock with tests where display kind (`RSK_INT64` vs floating) or metadata is affected.

## String constants naming

In Basic and C++:

- String literals longer than one character → named constant; one-character literals may stay inline.
- Reuse an existing constant when the same literal already exists.
- New names must be human-readable and semantic (no opaque `STR_0001`-style names).
- Style: `STR_*` in C++, `FB_STR_*` in Basic.
