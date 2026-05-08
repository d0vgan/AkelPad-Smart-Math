#!/usr/bin/env python3
"""
Cross-check SmokeTest_MathParser.bas numeric *expected* strings against a Python
reference (math + statistics + explicit Smart-Math-like rules).

Expressions use the Smart Math surface syntax; we translate a large subset to
Python. Cases we cannot translate safely are reported as SKIP (not mismatches).

Float agreement uses the same tolerance idea as SmokeTest_MathParser.bas:
  tol = 16 * eps * max(1, |a|, |b|)
"""

from __future__ import annotations

import ast
import math
import re
import statistics
import sys
from decimal import ROUND_HALF_UP, Decimal
from typing import Any, Optional

EPS = 2.2204460492503131e-16


def smoke_tol(a: float, b: float) -> float:
    scale = max(1.0, abs(a), abs(b))
    return 16.0 * EPS * scale


def close_enough_str(actual: str, expected: str) -> bool:
    if actual.strip() == expected.strip():
        return True

    def try_float(s: str) -> Optional[float]:
        s = s.strip()
        if re.fullmatch(r"[-+]?(\d+(\.\d*)?|\.\d+)([eE][-+]?\d+)?", s):
            return float(s)
        return None

    da, de = try_float(actual), try_float(expected)
    if da is None or de is None:
        return False
    if da == de:
        return True
    return abs(da - de) <= smoke_tol(da, de)


def split_top_level_tuple(s: str) -> Optional[list[str]]:
    s = s.strip()
    if len(s) < 2 or not (s.startswith("(") and s.endswith(")")):
        return None
    inner = s[1:-1].strip()
    if not inner:
        return []
    parts: list[str] = []
    depth = 0
    start = 0
    for i, ch in enumerate(inner):
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        elif ch == "," and depth == 0:
            parts.append(inner[start:i].strip())
            start = i + 1
    parts.append(inner[start:].strip())
    return parts


def tuple_close_enough(actual: str, expected: str) -> bool:
    pa, pe = split_top_level_tuple(actual), split_top_level_tuple(expected)
    if pa is None or pe is None or len(pa) != len(pe):
        return False
    for a, e in zip(pa, pe):
        if not (close_enough_str(a, e) or a == e):
            return False
    return True


def round_half_away_from_zero(x: float) -> float:
    """Smart Math-style round (e.g. round(2.5) -> 3)."""
    return float(Decimal(str(float(x))).quantize(Decimal("1"), rounding=ROUND_HALF_UP))


def trig_near_zero_ok(expected: str, got: str) -> bool:
    """sin/tan near mathematical zero often prints as '0' in smoke tests."""
    if expected.strip() != "0":
        return False
    g = got.strip()
    if re.fullmatch(r"[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?", g):
        return abs(float(g)) <= 5e-11
    return False


def pole_inf_ok(expected: str, got: str) -> bool:
    if expected.strip() in ("inf", "+inf"):
        if got.strip().lower() == "inf":
            return True
        if re.fullmatch(r"[-+]?(?:\d+\.?\d*)(?:[eE][-+]?\d+)?", got.strip()):
            return float(got) > 1e14
    if expected.strip() == "-inf":
        if got.strip().lower() == "-inf":
            return True
        if re.fullmatch(r"[-+]?(?:\d+\.?\d*)(?:[eE][-+]?\d+)?", got.strip()):
            return float(got) < -1e14
    return False


def results_match(expected: str, got_str: str) -> bool:
    exp, got = expected.strip(), got_str.strip()
    if got == exp or close_enough_str(got, exp) or tuple_close_enough(got, exp):
        return True
    if trig_near_zero_ok(exp, got) or pole_inf_ok(exp, got):
        return True
    return False


def parse_smoke_cases(path: str) -> list[dict]:
    """Parse tests(N) fields from SmokeTest_MathParser.bas (same-line assignments)."""
    text = open(path, encoding="utf-8", errors="replace").read()
    lines = text.splitlines()
    cases: dict[int, dict] = {}

    re_expr = re.compile(
        r'tests\((\d+)\)\.expr\s*=\s*"((?:[^"\\]|\\.)*)"\s*:'
    )
    re_exp = re.compile(r'tests\(\d+\)\.expected\s*=\s*"((?:[^"\\]|\\.)*)"')
    re_err = re.compile(
        r'tests\(\d+\)\.expectedErrContains\s*=\s*"((?:[^"\\]|\\.)*)"'
    )
    re_nores = re.compile(r"tests\(\d+\)\.expectNoResult\s*=\s*TRUE")

    for line in lines:
        m = re_expr.search(line)
        if not m:
            continue
        idx = int(m.group(1))
        expr = m.group(2).replace('""', '"')  # FB string escape if any
        entry = cases.setdefault(idx, {"idx": idx, "expr": expr})
        if re_nores.search(line):
            entry["expect_no_result"] = True
        me = re_exp.search(line)
        if me:
            entry["expected"] = me.group(1).replace('""', '"')
        mer = re_err.search(line)
        if mer:
            entry["expected_err"] = mer.group(1).replace('""', '"')

    return [cases[k] for k in sorted(cases)]


# --- Smart-Math-ish reference evaluation ---

def _strip_line_comment(expr: str) -> str:
    if "//" in expr:
        expr = expr.split("//", 1)[0]
    return expr.strip()


def _replace_int_literals(expr: str) -> str:
    def hex_repl(m: re.Match) -> str:
        return str(int(m.group(0), 16))

    def bin_repl(m: re.Match) -> str:
        return str(int(m.group(0), 2))

    def oct_repl(m: re.Match) -> str:
        return str(int(m.group(0), 8))

    s = expr
    s = re.sub(r"\b0[xX][0-9a-fA-F]+\b", hex_repl, s)
    s = re.sub(r"\b0[bB][01]+\b", bin_repl, s)
    s = re.sub(r"\b0[oO][0-7]+\b", oct_repl, s)
    return s


def _implicit_mul(expr: str) -> str:
    s = expr
    s = re.sub(r"(\d)\s*\(", r"\1*(", s)
    s = re.sub(r"\)\s*\(", r")*(", s)
    return s


def _postfix_percent(expr: str) -> Optional[str]:
    """
    Replace `... + 15%` patterns: `%` applies to the immediately preceding
    numeric atom (Smart Math: 200+15% -> 200 + 200*0.15).
    """
    # Tokenize coarsely: find `%` not inside string (we have no strings in smoke)
    if "%" not in expr:
        return expr
    out: list[str] = []
    i = 0
    while i < len(expr):
        if expr[i] == "%":
            j = len(out) - 1
            while j >= 0 and out[j].isspace():
                j -= 1
            if j < 0:
                return None
            atom = out[j]
            if not re.fullmatch(r"[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?", atom.strip()):
                return None
            base_start = j - 1
            while base_start >= 0 and out[base_start].isspace():
                base_start -= 1
            if base_start < 0:
                return None
            op = out[base_start]
            if op not in "+-*/":
                return None
            base_end = base_start - 1
            while base_end >= 0 and out[base_end].isspace():
                base_end -= 1
            if base_end < 0:
                return None
            base_atom = out[base_end]
            if not re.fullmatch(r"[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?", base_atom.strip()):
                return None
            pct = float(atom.strip()) / 100.0
            base_val = float(base_atom.strip())
            repl = str(base_val * pct)
            out = out[: base_end] + [repl] + out[j + 1 :]
            i += 1
            continue
        out.append(expr[i])
        i += 1
    return "".join(out)


def _translate_functions(expr: str) -> Optional[str]:
    """Rename / wrap calls so ast.parse + eval with NS works."""
    s = expr
    repl = {
        "ln": "log_ln",
        "log10": "log10_sm",
        "log": "log_sm",
        "round": "round_sm",
        "pow": "pow_sm",
        "sqr": "sqr_sm",
        "prod": "prod_sm",
        "mean": "mean_sm",
        "avg": "avg_sm",
        "fact": "fact_sm",
        "factorial": "fact_sm",
        "mod": "mod_sm",
        "arcsin": "asin",
        "arccos": "acos",
        "arctan": "atan",
        "deg": "deg_sm",
        "rad": "rad_sm",
        "sign": "sign_sm",
        "clamp": "clamp_sm",
        "gcd": "gcd_sm",
        "lcm": "lcm_sm",
        "median": "median_sm",
        "variance": "variance_sm",
        "stddev": "stddev_sm",
        "min": "min_sm",
        "max": "max_sm",
        "sum": "sum_sm",
        "random": "random_sm",
        "rand": "rand_sm",
    }
    for old, new in repl.items():
        s = re.sub(rf"\b{old}\b", new, s)
    return s


def _split_statements(expr: str) -> list[str]:
    parts = []
    depth = 0
    start = 0
    for i, ch in enumerate(expr):
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        elif ch == ";" and depth == 0:
            parts.append(expr[start:i].strip())
            start = i + 1
    parts.append(expr[start:].strip())
    return [p for p in parts if p]


def _eval_tuple_literal(expr: str, ns: dict) -> Any:
    expr = expr.strip()
    if not (expr.startswith("(") and expr.endswith(")")):
        raise ValueError("not tuple")
    inner = expr[1:-1].strip()
    if not inner:
        return tuple()
    depth = 0
    start = 0
    elems: list[str] = []
    for i, ch in enumerate(inner):
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        elif ch == "," and depth == 0:
            elems.append(inner[start:i].strip())
            start = i + 1
    elems.append(inner[start:].strip())
    return tuple(ref_eval(e, ns) for e in elems)


def log_sm(a, b=None):
    if b is None:
        raise TypeError("log needs 2 args")
    if a <= 0 or b <= 0 or b == 1:
        raise ValueError("domain")
    return math.log(a) / math.log(b)


def log_ln(x):
    return math.log(x)


def log10_sm(x):
    return math.log10(x)


def pow_sm(b, e):
    return b**e


def sqr_sm(x):
    return x * x


def prod_sm(*args):
    if len(args) == 1 and isinstance(args[0], tuple):
        return math.prod(args[0])
    return math.prod(args)


def mean_sm(*args):
    if len(args) == 1 and isinstance(args[0], tuple):
        return statistics.mean(args[0])
    flat = []
    for a in args:
        if isinstance(a, tuple):
            flat.extend(a)
        else:
            flat.append(a)
    return statistics.mean(flat)


def avg_sm(*args):
    return mean_sm(*args)


def fact_sm(n):
    if not float(n).is_integer() or n < 0:
        raise ValueError("fact")
    n = int(n)
    return float(math.factorial(n)) if n > 12 else math.factorial(n)


def mod_sm(a, b):
    return a % b


def deg_sm(x):
    return x * 180.0 / math.pi


def rad_sm(x):
    return x * math.pi / 180.0


def sign_sm(x):
    return -1 if x < 0 else (1 if x > 0 else 0)


def clamp_sm(x, lo, hi):
    return max(lo, min(hi, x))


def gcd_sm(a, b):
    return math.gcd(int(a), int(b))


def lcm_sm(a, b):
    return abs(a * b) // math.gcd(int(a), int(b)) if a or b else 0


def median_sm(*args):
    if len(args) == 1 and isinstance(args[0], tuple):
        return statistics.median(args[0])
    flat = []
    for a in args:
        if isinstance(a, tuple):
            flat.extend(a)
        else:
            flat.append(a)
    return statistics.median(flat)


def variance_sm(*args):
    if len(args) == 1 and isinstance(args[0], tuple):
        return statistics.pvariance(args[0])
    flat = []
    for a in args:
        if isinstance(a, tuple):
            flat.extend(a)
        else:
            flat.append(a)
    return statistics.pvariance(flat)


def stddev_sm(*args):
    if len(args) == 1 and isinstance(args[0], tuple):
        return statistics.pstdev(args[0])
    flat = []
    for a in args:
        if isinstance(a, tuple):
            flat.extend(a)
        else:
            flat.append(a)
    return statistics.pstdev(flat)


def min_sm(*args):
    if len(args) == 1 and isinstance(args[0], tuple):
        return min(args[0])
    flat = []
    for a in args:
        if isinstance(a, tuple):
            flat.extend(a)
        else:
            flat.append(a)
    return min(flat)


def max_sm(*args):
    if len(args) == 1 and isinstance(args[0], tuple):
        return max(args[0])
    flat = []
    for a in args:
        if isinstance(a, tuple):
            flat.extend(a)
        else:
            flat.append(a)
    return max(flat)


def sum_sm(*args):
    if len(args) == 1 and isinstance(args[0], tuple):
        return sum(args[0])
    flat = []
    for a in args:
        if isinstance(a, tuple):
            flat.extend(a)
        else:
            flat.append(a)
    return sum(flat)


def random_sm(lo, hi):
    return hi


def rand_sm():
    return 0.0


def round_sm(x):
    return round_half_away_from_zero(float(x))


def build_ns(ans: Any) -> dict:
    return {
        "pi": math.pi,
        "e": math.e,
        "ans": ans,
        "log_sm": log_sm,
        "log_ln": log_ln,
        "log10_sm": log10_sm,
        "pow_sm": pow_sm,
        "sqr_sm": sqr_sm,
        "prod_sm": prod_sm,
        "mean_sm": mean_sm,
        "avg_sm": avg_sm,
        "fact_sm": fact_sm,
        "mod_sm": mod_sm,
        "deg_sm": deg_sm,
        "rad_sm": rad_sm,
        "sign_sm": sign_sm,
        "clamp_sm": clamp_sm,
        "gcd_sm": gcd_sm,
        "lcm_sm": lcm_sm,
        "median_sm": median_sm,
        "variance_sm": variance_sm,
        "stddev_sm": stddev_sm,
        "min_sm": min_sm,
        "max_sm": max_sm,
        "sum_sm": sum_sm,
        "random_sm": random_sm,
        "rand_sm": rand_sm,
        "sin": math.sin,
        "cos": math.cos,
        "tan": math.tan,
        "asin": math.asin,
        "acos": math.acos,
        "atan": math.atan,
        "sinh": math.sinh,
        "cosh": math.cosh,
        "tanh": math.tanh,
        "exp": math.exp,
        "sqrt": math.sqrt,
        "abs": abs,
        "floor": math.floor,
        "ceil": math.ceil,
        "trunc": math.trunc,
        "round_sm": round_sm,
        "atan2": math.atan2,
        "hypot": math.hypot,
    }


def ref_eval(expr: str, ns: dict) -> Any:
    e = _strip_line_comment(expr).strip()
    if not e:
        raise ValueError("empty")
    e = _replace_int_literals(e)
    p = _postfix_percent(e)
    if p is None:
        raise ValueError("postfix percent")
    e = p
    e = _implicit_mul(e)
    t = _translate_functions(e)
    if t is None:
        raise ValueError("translate")
    e = t
    if e.startswith("(") and e.endswith(")") and e.count("(") == 1:
        try:
            return _eval_tuple_literal(e, ns)
        except Exception:
            pass
    node = ast.parse(e, mode="eval")
    return eval(compile(node, "<smoke>", "eval"), {"__builtins__": {}}, ns)


def ref_format(v: Any) -> str:
    if isinstance(v, bool):
        return "1" if v else "0"
    if isinstance(v, float):
        if math.isinf(v):
            return "-inf" if v < 0 else "inf"
        if math.isfinite(v) and v != 0 and (abs(v) >= 1e16 or abs(v) < 1e-4):
            s = f"{v:.15e}"
            if "e" in s.lower():
                s = re.sub(r"e\+0+(\d)", r"e+\1", s, flags=re.I)
                s = re.sub(r"e-0+(\d)", r"e-\1", s, flags=re.I)
            return s
        return str(v)
    if isinstance(v, tuple):
        inner = ", ".join(ref_format(x) for x in v)
        return f"({inner})"
    return str(v)


def try_reference(expr_chain: str) -> tuple[Optional[Any], Optional[str]]:
    """Evaluate semicolon chain; last statement value is result."""
    parts = _split_statements(expr_chain)
    ns = build_ns(None)
    last = None
    try:
        for part in parts:
            part = part.strip()
            if "=" in part and not any(
                part.startswith(pref)
                for pref in ("atan2", "pow", "log", "mod", "gcd", "lcm", "hypot", "random")
            ):
                if re.match(r"^[A-Za-z_][A-Za-z0-9_]*\s*=", part):
                    name, rhs = part.split("=", 1)
                    name = name.strip()
                    rhs = rhs.strip()
                    last = ref_eval(rhs, ns)
                    ns[name] = last
                    ns["ans"] = last
                    continue
            last = ref_eval(part, ns)
            ns["ans"] = last
        return last, None
    except Exception as ex:
        return None, str(ex)


def _last_statement(expr: str) -> str:
    depth = 0
    start = 0
    last = expr.strip()
    for i, ch in enumerate(expr):
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        elif ch == ";" and depth == 0:
            last = expr[i + 1 :].strip()
    return _strip_line_comment(last).strip()


def should_skip_case(case: dict) -> Optional[str]:
    if case.get("expect_no_result"):
        return "expectNoResult"
    if case.get("expected_err"):
        return "expected error path"
    ex_raw = case["expr"]
    ex = _strip_line_comment(ex_raw)

    if ex.strip() == "ans" and ";" not in ex:
        return "standalone ans (no prior statement in harness)"

    if "hex(" in ex or "bin(" in ex or "oct(" in ex or "uhex(" in ex:
        return "formatting builtin"
    if "sort(" in ex or "unique(" in ex:
        return "sort/unique"
    if "~" in ex:
        return "bitwise complement (~)"

    last = _last_statement(ex_raw)
    if re.fullmatch(r"(rad|deg|hex|bin|oct)\b(\(\))?", last.strip()):
        return "trailing formatter command (DSL)"

    if "==" in ex or "!=" in ex or "<=" in ex or ">=" in ex:
        return "comparison / equality (DSL 0/1 vs Python bool)"
    if ex.count("==") > 1:
        return "chained =="
    if " not " in ex or " and " in ex or " or " in ex:
        return "logical not/and/or (DSL semantics)"
    masked = ex.replace("<<", "@@SL@@").replace(">>", "@@SR@@")
    if "<" in masked or ">" in masked:
        return "ordering compare (e.g. chained inequalities)"

    if ";" in ex:
        if re.search(r"\b[a-z_][a-z0-9_]*\s*[\+\-\*/]\s*[a-z_][a-z0-9_]*\s*$", last):
            return "broadcast / element-wise array algebra (DSL)"

    if re.search(r"\by\s*\(", ex) or re.search(r"\bf\s*\(", ex):
        return "user-defined function (y(a)=...)"

    return None


def main() -> int:
    root = __file__.rsplit("\\", 1)[0]
    if "/" in root and "\\" not in root:
        root = __file__.rsplit("/", 1)[0]
    bas = root + "/../SmokeTest_MathParser.bas"
    if len(sys.argv) > 1:
        bas = sys.argv[1]

    cases = parse_smoke_cases(bas)
    mismatches: list[str] = []
    skipped: list[str] = []
    ok = 0

    for case in cases:
        idx = case["idx"]
        if "expected" not in case:
            continue
        reason = should_skip_case(case)
        if reason:
            skipped.append(f"#{idx}: {reason}")
            continue
        val, err = try_reference(case["expr"])
        if err:
            skipped.append(f"#{idx}: eval failed ({err[:80]})")
            continue
        exp = case["expected"].strip()
        got = ref_format(val).strip()
        if results_match(exp, got):
            ok += 1
            continue
        mismatches.append(
            f"#{idx} expr={case['expr']!r}\n  expected(smoke)={exp!r}\n  ref_python  ={got!r}\n"
        )

    print("=== Smoke expected vs Python reference ===")
    print(f"Cases with numeric expected: {sum(1 for c in cases if 'expected' in c)}")
    print(f"Compared OK (exact, float-tol, tuple-tol, or near-zero trig / pole inf): {ok}")
    print(f"Skipped (DSL-only / non-comparable / eval failed): {len(skipped)}")
    print(f"MISMATCH vs plain Python math: {len(mismatches)}")
    print()
    if mismatches:
        print("--- MISMATCHES ---")
        for m in mismatches:
            print(m)
    if skipped and "--verbose-skip" in sys.argv:
        print("--- SKIPPED ---")
        for s in skipped:
            print(s)
    return 1 if mismatches else 0


if __name__ == "__main__":
    raise SystemExit(main())
