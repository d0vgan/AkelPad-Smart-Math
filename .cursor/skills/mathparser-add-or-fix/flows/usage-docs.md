# Update `USAGE_AND_SYNTAX.md`

Load when editing `USAGE_AND_SYNTAX.md` (and its published copy `AkelFiles/Docs/SmartMath-Eng.md`): function or constant documentation, or operator/numeric/error semantics that a change added, changed, or that the docs got wrong.

## Audience (Required)

`USAGE_AND_SYNTAX.md` is **end-user** documentation. Keep it readable for people who calculate with Smart Math and do not need implementation detail.

**Belong in USAGE:**

- What a feature does in ordinary use: purpose, signature, main argument meaning, typical return shape.
- A few clear examples (`expr` -> `result`), including an example that happens to use `nan` / `inf` when that is the natural demo for a function — not a full NaN policy essay.
- Syntax, common tasks, Quick index, and brief **Advanced Numeric Behavior** notes (integer accuracy overview, NaN/Inf rendering/truthiness at a high level).

**Do not put in USAGE** (record these in skills/flows instead — see `numeric-behavior.md`, coding-standards, smoke-tests, parity):

- Edge-case catalogs, ulp / snap tolerances, compensated-summation algorithm names, mantissa/seed implementation notes.
- Complete NaN / Inf policies per function (beyond a short Advanced Behavior mention or a single example parameter).
- Numeric limits, magnitude thresholds (`2^53`, `1e308`, …), overflow-avoidance recipes, and exact-int compare/sort/unique rules in function bullets.
- Build- or language-specific implementation detail (C++ vs Basic RNG, formatter digit heuristics, type-width retargeting beyond the one Advanced Behavior integer-accuracy sentence).

When a behavior change is technical only: update the internal skill/flow and tests; leave USAGE unchanged unless the **user-visible everyday description** actually changed (new function, new ordinary example, wrong everyday claim).

Keep `AkelFiles/Docs/SmartMath-Eng.md` in sync with `USAGE_AND_SYNTAX.md` whenever either changes.

## Shared style

- Scan the nearest headings, bullets, and examples first; match structure, terms, list depth, and example shape (`expr` -> `result` vs inline prose).
- **ASCII only (Required):** `USAGE_AND_SYNTAX.md` and `AkelFiles/Docs/SmartMath-Eng.md` must not contain Unicode. Use ASCII in every new or changed line (`-` for dashes, `->` for results, straight quotes, `*` / `<=` / `sqrt` instead of math symbols). If newly generated or edited text in either file contains Unicode, replace each character with an ASCII equivalent before finishing the edit. Keep both files in sync after that replacement.
- One author voice: no one-off style for a single symbol.
- Example results use the parser's display format (3-digit exponents, e.g. `1e+020`) and must be verified against a reference (smoke-tests flow), not copied from parser output.
- Typo pass on changed lines (watch split words like `implemen ted`).

## Function documentation

- Add/update the function in the appropriate section with an **everyday** description (usage-docs "Audience").
- Update **"Quick index (alphabetical)"** under **"Built-in Functions"**: alphabetical names; aliases on the same row as the canonical name (e.g. `asin/arcsin(value)`); category labels consistent with neighbors. Then run the docs index gate (build-gates).
- Document purpose, signature, each argument at user level, and return behavior (arrays/variadic if relevant). Constraints that are only numeric edge cases or implementation limits go to `numeric-behavior.md`, not into the bullet.
- At least 2–3 examples: basic scalar; one interesting everyday case; array when supported. Prefer ordinary numbers over limit/overflow probes unless the feature is specifically about that.
- User-defined functions and lambda-style definitions are one section. A body or parameter rule is written once and shown in both spellings (user-functions-and-lambdas flow).

## Semantics changes

- Everyday rule next to the related operator or function, with one example when it helps the user.
- Put technical edge cases, NaN catalogs, and numeric limits in `numeric-behavior.md` (and tests). Only a **brief** Advanced Behavior addition when the user needs a high-level heads-up (same tone as Integer Accuracy / NaN Inf already there).
- Array examples that include `()` follow empty-array-policy.
- Fix wrong existing examples in place; do not add a contradicting note elsewhere.
- Complex-only behavior goes in the matching "... With Complex Numbers" subsection.

## Constant documentation

List the new constant **everywhere** older constants (`pi`, `e`) appear for builtins and reserved names. At minimum scan:

- **Built-in constants** list
- Reserved-name / assignment / UDF-parameter restriction sections
- Examples that constants resolve **before** variables (extend in the same tone, e.g. `(e=3)` notes)
