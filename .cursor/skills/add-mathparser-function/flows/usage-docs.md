# Update `USAGE_AND_SYNTAX.md`

Load when editing function or constant documentation in `USAGE_AND_SYNTAX.md`.

## Shared style (functions and constants)

- Scan the nearest headings, bullets, and examples first; match structure, terms, list depth, and example shape (`expr` -> `result` vs inline prose).
- Prefer ASCII in new/changed lines: `-` for dashes (not en/em), `->` for results (not Unicode arrows), straight quotes unless extending an existing non-ASCII paragraph in place.
- One author voice: no one-off style for a single symbol.
- Typo pass on changed lines (watch split words like `implemen ted`).

## Function documentation

- Add/update the function in the appropriate section.
- Update **"Quick index (alphabetical)"** under **"Built-in Functions"**: alphabetical names; aliases on the same row as the canonical name (e.g. `asin/arcsin(value)`); category labels consistent with neighbors.
- Document purpose, signature, each argument/constraints, return behavior (arrays/variadic if relevant).
- At least 2–3 examples: basic scalar; edge/interesting; array when supported.

## Constant documentation

List the new constant **everywhere** older constants (`pi`, `e`) appear for builtins and reserved names. At minimum scan:

- **Built-in constants** list
- Reserved-name / assignment / UDF-parameter restriction sections
- Examples that constants resolve **before** variables (extend in the same tone when helpful, e.g. `(e=3)` notes)

Do not document the new constant in only one section while older constants appear in several.
