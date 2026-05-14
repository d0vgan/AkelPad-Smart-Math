#!/usr/bin/env python3
"""
Cross-check SmokeTest_MathParser.bas numeric *expected* strings against a Python
reference (math + statistics + explicit Smart-Math-like rules).

Expressions use the Smart Math surface syntax; we translate a large subset to
Python. Cases we cannot translate safely are reported as SKIP (not mismatches).

When an expression *looks like* a complex or time-duration case (heuristic), we
switch to a dedicated reference path:
  * **Complex:** map Smart-Math `i` suffix / bare `i` to Python `j`, evaluate with
    ``complex`` arithmetic, then compare after normalizing ``j`` <-> ``i`` spelling.
    Tuple + scalar / tuple * scalar / element-wise tuple/tuple uses the same
    broadcast lowering as the ``RunComplexNumberSupportOptionTests`` block in
    ``SmokeTest_MathParser.bas`` (``complexCases`` / ``arrCases``), which this
    tool parses in addition to ``tests(N)``.
  * **Time:** colon literals (MM:SS / HH:MM:SS / DD:HH:MM:SS), named duration
    constants (``second`` … ``day``), compact suffix forms (``1d2h3m4s5ms``),
    converters (``milliseconds``, ``seconds``, …), and ``sum`` of durations —
    enough to mirror the smoke *expected* strings for the time block.

Float agreement uses the same tolerance idea as SmokeTest_MathParser.bas:
  tol = 16 * eps * max(1, |a|, |b|)
"""

from __future__ import annotations

import ast
import math
import re
import statistics
import sys
from dataclasses import dataclass
from decimal import ROUND_HALF_UP, Decimal
from typing import Any, Optional

EPS = 2.2204460492503131e-16

# --- Duration (time) reference model (milliseconds, signed) -----------------

_MS = 1
_SECOND_MS = 1000
_MINUTE_MS = 60 * _SECOND_MS
_HOUR_MS = 60 * _MINUTE_MS
_DAY_MS = 24 * _HOUR_MS

_UNIT_ORDER = {"d": 0, "h": 1, "m": 2, "s": 3, "ms": 4}


@dataclass(frozen=True)
class Duration:
    """Signed duration stored in milliseconds (may be fractional)."""

    ms: float

    def __add__(self, other: object) -> "Duration":
        if isinstance(other, Duration):
            return Duration(self.ms + other.ms)
        if isinstance(other, (int, float)):
            return Duration(self.ms + float(other) * _SECOND_MS)
        return NotImplemented

    def __radd__(self, other: object) -> "Duration":
        return self.__add__(other)  # type: ignore[arg-type]

    def __sub__(self, other: object) -> "Duration":
        if isinstance(other, Duration):
            return Duration(self.ms - other.ms)
        if isinstance(other, (int, float)):
            return Duration(self.ms - float(other) * _SECOND_MS)
        return NotImplemented

    def __rsub__(self, other: object) -> "Duration":
        if isinstance(other, Duration):
            return Duration(other.ms - self.ms)
        if isinstance(other, (int, float)):
            return Duration(float(other) * _SECOND_MS - self.ms)
        return NotImplemented

    def __mul__(self, other: object) -> "Duration":
        if isinstance(other, (int, float)):
            return Duration(self.ms * float(other))
        return NotImplemented

    def __rmul__(self, other: object) -> "Duration":
        return self.__mul__(other)  # type: ignore[arg-type]

    def __truediv__(self, other: object) -> float:
        if isinstance(other, Duration):
            if other.ms == 0:
                raise ZeroDivisionError
            return self.ms / other.ms
        if isinstance(other, (int, float)):
            return self.ms / float(other)
        return NotImplemented

    def __neg__(self) -> "Duration":
        return Duration(-self.ms)


def _parse_colon_groups(groups: list[str]) -> Duration:
    """Parse 2/3/4 colon-separated groups into total ms (Smart-Math segment rules)."""
    parts = [g.strip() for g in groups if g.strip() != ""]
    n = len(parts)
    if n < 2 or n > 4:
        raise ValueError("colon time segment count")
    last = parts[-1]
    frac = 0.0
    if "." in last:
        base, frac_s = last.split(".", 1)
        parts[-1] = base
        frac = float("0." + frac_s) * _SECOND_MS if frac_s else 0.0
    ints = [int(p) for p in parts]
    if n == 2:
        mm, ss = ints
        return Duration(mm * _MINUTE_MS + ss * _SECOND_MS + frac)
    if n == 3:
        hh, mm, ss = ints
        return Duration(hh * _HOUR_MS + mm * _MINUTE_MS + ss * _SECOND_MS + frac)
    dd, hh, mm, ss = ints
    return Duration(dd * _DAY_MS + hh * _HOUR_MS + mm * _MINUTE_MS + ss * _SECOND_MS + frac)


def dur_parse_colon_literal(text: str) -> Duration:
    s = text.strip()
    return _parse_colon_groups(s.split(":"))


def dur_parse_compact(s: str) -> Duration:
    """
    Parse compact suffix literal: ``1d2h3m4s5ms``, ``5000ms``, ``-1s-1m`` (spaces ignored).
    Units must appear in non-decreasing order d,h,m,s,ms.
    Per-token leading ``-`` is allowed on each field (``-1s-1m``).
    For unary minus on a whole literal written like ``-1m 1s``, use ``(-_dur_lit_compact('1m1s'))``.
    """
    s0 = re.sub(r"\s+", "", s.strip())
    tokens = re.findall(r"-?\d+(?:ms|[dhms])", s0)
    if not tokens:
        raise ValueError("empty compact time")
    total = 0.0
    last_rank = -1
    for tok in tokens:
        m = re.fullmatch(r"(-?)(\d+)(ms|[dhms])", tok)
        if not m:
            raise ValueError("bad compact token")
        sign = -1.0 if m.group(1) == "-" else 1.0
        val = int(m.group(2)) * sign
        unit = m.group(3)
        rank = _UNIT_ORDER[unit]
        if rank < last_rank:
            raise ValueError("compact time unit order")
        last_rank = rank
        if unit == "d":
            total += val * _DAY_MS
        elif unit == "h":
            total += val * _HOUR_MS
        elif unit == "m":
            total += val * _MINUTE_MS
        elif unit == "s":
            total += val * _SECOND_MS
        elif unit == "ms":
            total += val * _MS
    return Duration(total)


def _replace_compact_time_literals(expr: str) -> str:
    """Replace compact duration runs with ``_dur_lit_compact('...')`` or negated form."""

    def scan_replace(s: str) -> str:
        out: list[str] = []
        i = 0
        n = len(s)
        while i < n:
            m = re.match(r"-?\d+(?:ms|[dhms])", s[i:])
            if not m:
                out.append(s[i])
                i += 1
                continue
            j = i + m.end()
            parts = [m.group(0)]
            sp_mid = j
            while j < n and s[j].isspace():
                j += 1
            had_space_between = j > sp_mid
            while j < n:
                m2 = re.match(r"-?\d+(?:ms|[dhms])", s[j:])
                if not m2:
                    break
                parts.append(m2.group(0))
                j += m2.end()
                while j < n and s[j].isspace():
                    j += 1
            blob = "".join(parts)
            if re.fullmatch(r"-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?", blob):
                out.append(blob)
                i = j
                continue
            if ":" in blob:
                out.append(blob)
                i = j
                continue
            if (
                had_space_between
                and len(parts) == 2
                and parts[1]
                and parts[0].startswith("-")
                and not parts[1].startswith("-")
                and parts[0] == "-" + parts[1][0] + "m"
            ):
                inner = parts[1][0] + "m" + parts[1]
                try:
                    dur_parse_compact(inner)
                except Exception:
                    out.append(blob)
                    i = j
                    continue
                out.append(f"(-_dur_lit_compact({inner!r}))")
                i = j
                continue
            try:
                dur_parse_compact(blob)
            except Exception:
                out.append(blob)
                i = j
                continue
            out.append(f"_dur_lit_compact({blob!r})")
            i = j
        return "".join(out)

    return scan_replace(expr)


def _replace_colon_time_literals(expr: str) -> str:
    """Replace ``H:MM(:SS)?`` colon durations with ``dur_parse_colon_literal('...')``."""

    def find_match(s: str, pos: int) -> Optional[re.Match]:
        if pos >= len(s) or not s[pos].isdigit():
            return None
        for nseg in (4, 3, 2):
            if nseg == 4:
                rgx = re.compile(
                    r"^(\d+):(\d{2}):(\d{2}):(\d{2})(\.\d+)?(?![:\d])"
                )
            elif nseg == 3:
                rgx = re.compile(r"^(\d+):(\d{2}):(\d{2})(\.\d+)?(?!\s*:)")
            else:
                rgx = re.compile(r"^(\d+):(\d{2})(\.\d+)?(?!\s*:)")
            m = rgx.match(s[pos:])
            if m:
                return m
        return None

    out: list[str] = []
    i = 0
    n = len(expr)
    while i < n:
        m = find_match(expr, i)
        if m:
            lit = m.group(0)
            out.append(f"dur_parse_colon_literal({lit!r})")
            i += len(lit)
        else:
            out.append(expr[i])
            i += 1
    return "".join(out)


def _dur_lit_compact(s: str) -> Duration:
    return dur_parse_compact(s)


def duration_format_ms(ms: float) -> str:
    """
    Format ``ms`` into Smart-Math-like canonical strings used in smoke tests.
    Heuristic but tuned to the SmokeTest_MathParser.bas time block.
    """
    if ms != ms:
        return "nan"
    sign = "-" if ms < 0 else ""
    ms_abs = abs(ms)
    total_sec = ms_abs / _SECOND_MS

    if total_sec + 1e-9 < _DAY_MS / _SECOND_MS:
        if total_sec < 3600 - 1e-9:
            mm = int(math.floor(total_sec / 60.0 + 1e-12))
            ss = total_sec - mm * 60.0
            if abs(ss - round(ss)) < 1e-6:
                return f"{sign}{mm:02d}:{int(round(ss)):02d}"
            return f"{sign}{mm:02d}:{ss:06.3f}".rstrip("0").rstrip(".")
        hh = int(math.floor(total_sec / 3600.0 + 1e-12))
        rem = total_sec - hh * 3600.0
        mm = int(math.floor(rem / 60.0 + 1e-12))
        ss = rem - mm * 60.0
        if abs(ss) < 1e-6:
            return f"{sign}{hh:02d}:{mm:02d}"
        if abs(ss - round(ss)) < 1e-6:
            return f"{sign}{hh:02d}:{mm:02d}:{int(round(ss)):02d}"
        return f"{sign}{hh:02d}:{mm:02d}:{ss:06.3f}".rstrip("0").rstrip(".")
    dd = int(math.floor(ms_abs / _DAY_MS + 1e-12))
    rem_ms = ms_abs - dd * _DAY_MS
    hh = int(rem_ms // _HOUR_MS)
    rem_ms -= hh * _HOUR_MS
    mm = int(rem_ms // _MINUTE_MS)
    rem_ms -= mm * _MINUTE_MS
    sec = rem_ms / _SECOND_MS
    if abs(sec - round(sec)) < 1e-6:
        return f"{sign}{dd}:{hh:02d}:{mm:02d}:{int(round(sec)):02d}"
    return f"{sign}{dd}:{hh:02d}:{mm:02d}:{sec:06.3f}".rstrip("0").rstrip(".")


def milliseconds_sm(x: object) -> Any:
    if isinstance(x, Duration):
        return int(round(x.ms))
    if isinstance(x, tuple):
        return tuple(milliseconds_sm(t) for t in x)
    raise TypeError("milliseconds expects duration or tuple of durations")


def seconds_sm(x: object) -> Any:
    if isinstance(x, Duration):
        return x.ms / _SECOND_MS
    if isinstance(x, tuple):
        return tuple(seconds_sm(t) for t in x)
    raise TypeError("seconds expects duration or tuple of durations")


def minutes_sm(x: object) -> Any:
    if isinstance(x, Duration):
        return x.ms / _MINUTE_MS
    if isinstance(x, tuple):
        return tuple(minutes_sm(t) for t in x)
    raise TypeError("minutes expects duration or tuple of durations")


def hours_sm(x: object) -> Any:
    if isinstance(x, Duration):
        return x.ms / _HOUR_MS
    if isinstance(x, tuple):
        return tuple(hours_sm(t) for t in x)
    raise TypeError("hours expects duration or tuple of durations")


def days_sm(x: object) -> Any:
    if isinstance(x, Duration):
        return x.ms / _DAY_MS
    if isinstance(x, tuple):
        return tuple(days_sm(t) for t in x)
    raise TypeError("days expects duration or tuple of durations")


def sum_dur_sm(*args: object) -> Duration:
    if len(args) == 1 and isinstance(args[0], tuple):
        args = args[0]  # type: ignore[assignment]
    acc = Duration(0.0)
    for a in args:
        if not isinstance(a, Duration):
            raise TypeError("sum_dur expects durations")
        acc = Duration(acc.ms + a.ms)
    return acc


# --- Complex helpers ---------------------------------------------------------


def _preprocess_complex_surface(expr: str) -> str:
    """
    Turn Smart-Math complex surface syntax into Python ``complex`` literals
    (``...j``), without leaving a bare ``i`` identifier.
    """
    s = expr
    s = re.sub(
        r"(?<![A-Za-z0-9_])(\d+\.?\d*|\.\d+)i(?![A-Za-z0-9_])",
        r"\1j",
        s,
    )
    s = re.sub(r"(?<![A-Za-z0-9_])i(?![A-Za-z0-9_])", "(1j)", s)
    return s


def _looks_like_complex_expr(expr: str) -> bool:
    e = _strip_line_comment(expr)
    if re.search(r"(?<![A-Za-z0-9_])(\d+\.?\d*|\.\d+)i(?![A-Za-z0-9_])", e):
        return True
    if re.search(r"(?<![A-Za-z0-9_])i(?![A-Za-z0-9_])", e):
        return True
    return False


def _looks_like_complex_expected(expected: str) -> bool:
    s = expected.strip()
    if "i" not in s and "I" not in s:
        return False
    if re.search(r"(?<![A-Za-z0-9_])(\d+\.?\d*|\.\d+)i\b", s, flags=re.I):
        return True
    if re.search(r"[+-]\s*i\b", s, flags=re.I):
        return True
    if re.search(r"\(\s*i\b", s, flags=re.I):
        return True
    return False


def _looks_like_time(expr: str, expected: str) -> bool:
    ex = _strip_line_comment(expr)
    if re.search(
        r"\b(second|minute|hour|day|millisecond|milliseconds|seconds|minutes|hours|days)\b",
        ex,
        flags=re.I,
    ):
        return True
    if re.search(r"\b\d+\s*:\s*\d{2}\b", ex):
        return True
    if re.search(r"(?:^|[^\w.])(-?\s*(?:\d+)(?:ms|[dhms])(?:\s*(?:\d+)(?:ms|[dhms]))+)(?:[^\w.]|$)", ex):
        if not re.search(r"\d+e[-+]?\d", ex, flags=re.I):
            return True
    if re.search(r"\b\d+\s*:\s*\d{2}\b", expected):
        return True
    return False


def infer_ref_mode(expr: str, expected: str) -> str:
    if _looks_like_time(expr, expected):
        return "time"
    if _looks_like_complex_expr(expr) or _looks_like_complex_expected(expected):
        return "complex"
    return "real"


def _fold_tuple_broadcast_ast(node: ast.AST) -> ast.AST:
    """
    Lower Smart-Math element-wise tuple algebra to nested tuple of scalars
    (``(a,b)+c -> (a+c, b+c)``, same for ``- * /`` when one side is a tuple).
    """

    def fold(n: ast.AST) -> ast.AST:
        if isinstance(n, ast.BinOp):
            left, right = fold(n.left), fold(n.right)
            op = n.op
            if isinstance(left, ast.Tuple) and isinstance(right, ast.Tuple):
                if len(left.elts) != len(right.elts):
                    return ast.BinOp(left=left, op=op, right=right)
                return ast.Tuple(
                    elts=[
                        ast.BinOp(left=le, op=op, right=re) for le, re in zip(left.elts, right.elts)
                    ],
                    ctx=ast.Load(),
                )
            if isinstance(left, ast.Tuple) and not isinstance(right, ast.Tuple):
                return ast.Tuple(
                    elts=[ast.BinOp(left=le, op=op, right=right) for le in left.elts],
                    ctx=ast.Load(),
                )
            if isinstance(right, ast.Tuple) and not isinstance(left, ast.Tuple):
                return ast.Tuple(
                    elts=[ast.BinOp(left=left, op=op, right=re) for re in right.elts],
                    ctx=ast.Load(),
                )
            return ast.BinOp(left=left, op=op, right=right)
        if isinstance(n, ast.UnaryOp):
            return ast.UnaryOp(op=n.op, operand=fold(n.operand))
        if isinstance(n, ast.Tuple):
            return ast.Tuple(elts=[fold(e) for e in n.elts], ctx=ast.Load())
        if isinstance(n, ast.Call):
            return ast.Call(
                func=fold(n.func),
                args=[fold(a) for a in n.args],
                keywords=n.keywords,
            )
        if isinstance(n, ast.IfExp):
            return ast.IfExp(test=fold(n.test), body=fold(n.body), orelse=fold(n.orelse))
        if isinstance(n, ast.Attribute):
            return ast.Attribute(value=fold(n.value), attr=n.attr, ctx=n.ctx)
        if isinstance(n, ast.Subscript):
            sl = n.slice
            if isinstance(sl, ast.Slice):
                sl = ast.Slice(
                    lower=fold(sl.lower) if sl.lower else None,
                    upper=fold(sl.upper) if sl.upper else None,
                    step=fold(sl.step) if sl.step else None,
                )
            else:
                sl = fold(sl)
            return ast.Subscript(value=fold(n.value), slice=sl, ctx=n.ctx)
        return n

    return fold(node)


def _broadcast_tuple_expr_string(e: str) -> str:
    """Apply tuple broadcast then re-emit (requires Python 3.9+ ``ast.unparse``)."""
    tree = ast.parse(e, mode="eval")
    new_body = _fold_tuple_broadcast_ast(tree.body)
    wrapped = ast.Expression(body=new_body)
    ast.fix_missing_locations(wrapped)
    return ast.unparse(new_body)


def _preprocess_time_expression(expr: str) -> str:
    s = _replace_colon_time_literals(expr)
    s = _replace_compact_time_literals(s)
    s = re.sub(
        r"\bsum\(\s*(dur_parse_colon_literal\([^)]+\))\s*,\s*(dur_parse_colon_literal\([^)]+\))\s*\)",
        r"sum_dur_sm(\1, \2)",
        s,
    )
    return s


def _smoke_str_to_complex(s: str) -> Optional[complex]:
    t = s.strip().replace(" ", "")
    t = re.sub(
        r"(?<![A-Za-z0-9_])(\d+\.?\d*|\.\d+)i(?![A-Za-z0-9_])",
        r"\1j",
        t,
        flags=re.I,
    )
    t = re.sub(r"(?<![A-Za-z0-9_])i(?![A-Za-z0-9_])", "(1j)", t, flags=re.I)
    try:
        v = eval(compile(ast.parse(t, mode="eval"), "<cpx>", "eval"), {"__builtins__": {}}, {})
    except Exception:
        return None
    if isinstance(v, complex):
        return v
    if isinstance(v, (int, float)):
        return complex(float(v), 0.0)
    return None


def _complex_close(a: complex, b: complex) -> bool:
    return abs(a.real - b.real) <= smoke_tol(a.real, b.real) and abs(a.imag - b.imag) <= smoke_tol(
        a.imag, b.imag
    )


def _format_complex_smoke(z: complex) -> str:
    """Emit strings closer to Smart-Math smoke (``-5+10i``, ``5-i``, ``i``)."""
    r, i = z.real, z.imag
    if abs(i) < 1e-15:
        if abs(r) < 1e-15:
            return "0"
        if abs(r - round(r)) < 1e-12 and abs(r) < 1e15:
            return str(int(round(r)))
        return str(r).rstrip("0").rstrip(".")
    # non-zero imaginary
    eps = 1e-12
    def fmt_re(x: float) -> str:
        if abs(x) < eps:
            return ""
        if abs(x - round(x)) < 1e-12 and abs(x) < 1e15:
            return str(int(round(x)))
        return str(x).rstrip("0").rstrip(".")

    def imag_tail(ai: float) -> str:
        a = abs(ai)
        neg = ai < 0
        if abs(a - 1.0) < eps:
            return "-i" if neg else "i"
        if abs(a - round(a)) < 1e-12 and a < 1e15:
            n = int(round(a))
            return f"-{n}i" if neg else f"{n}i"
        body = (f"{a}i").rstrip("0").rstrip(".")
        return "-" + body if neg else body

    tr = fmt_re(r)
    ti = imag_tail(i)
    if not tr:
        return ti
    if i > 0:
        return f"{tr}+{ti}".replace("+-", "-")
    return f"{tr}{ti}".replace("+-", "-")


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


def tuple_close_enough_complex(actual: str, expected: str) -> bool:
    pa, pe = split_top_level_tuple(actual), split_top_level_tuple(expected)
    if pa is None or pe is None or len(pa) != len(pe):
        return False
    for a, e in zip(pa, pe):
        ca, ce = _smoke_str_to_complex(a), _smoke_str_to_complex(e)
        if ca is not None and ce is not None:
            if not _complex_close(ca, ce):
                return False
            continue
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
            return float(got) > 1e10
    if expected.strip() == "-inf":
        if got.strip().lower() == "-inf":
            return True
        if re.fullmatch(r"[-+]?(?:\d+\.?\d*)(?:[eE][-+]?\d+)?", got.strip()):
            return float(got) < -1e10
    return False


def results_match(expected: str, got_str: str, *, mode: str = "real") -> bool:
    exp, got = expected.strip(), got_str.strip()
    if got == exp:
        return True
    if mode == "complex":
        if tuple_close_enough_complex(got, exp):
            return True
        ca, ce = _smoke_str_to_complex(got), _smoke_str_to_complex(exp)
        if ca is not None and ce is not None and _complex_close(ca, ce):
            return True
        if close_enough_str(got, exp) or tuple_close_enough(got, exp):
            return True
    elif mode == "time":
        def _strip_hhmmss_trailing_zero_seconds(x: str) -> str:
            x = x.strip()
            ps = x.split(":")
            if len(ps) == 3 and ps[2] == "00":
                return ":".join(ps[:2])
            return x

        ge, gg = _strip_hhmmss_trailing_zero_seconds(exp), _strip_hhmmss_trailing_zero_seconds(got)
        if ge == gg or tuple_close_enough(ge, gg) or close_enough_str(ge, gg):
            return True
        return False
    if close_enough_str(got, exp) or tuple_close_enough(got, exp):
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


_RE_COMPLEX_OPT_PAIR = re.compile(
    r'complexCases\(\s*(\d+)\s*\)\s*=\s*"((?:[^"\\]|\\.)*)"\s*:\s*'
    r'complexExpect\(\s*\1\s*\)\s*=\s*"((?:[^"\\]|\\.)*)"',
    re.I,
)
_RE_COMPLEX_OPT_ARR_PAIR = re.compile(
    r'arrCases\(\s*(\d+)\s*\)\s*=\s*"((?:[^"\\]|\\.)*)"\s*:\s*'
    r'arrExpect\(\s*\1\s*\)\s*=\s*"((?:[^"\\]|\\.)*)"',
    re.I,
)


def parse_smoke_complex_opt_cases(path: str) -> list[dict]:
    """
    Parse ``complexCases`` / ``complexExpect`` and ``arrCases`` / ``arrExpect`` pairs
    from ``RunComplexNumberSupportOptionTests`` in ``SmokeTest_MathParser.bas``.
    """
    text = open(path, encoding="utf-8", errors="replace").read()
    out: list[dict] = []
    for m in _RE_COMPLEX_OPT_PAIR.finditer(text):
        n = int(m.group(1))
        expr = m.group(2).replace('""', '"')
        expected = m.group(3).replace('""', '"')
        out.append(
            {
                "idx": f"complexCases({n})",
                "expr": expr,
                "expected": expected,
                "ref_mode": "complex",
                "source": "complex_opt",
            }
        )
    for m in _RE_COMPLEX_OPT_ARR_PAIR.finditer(text):
        n = int(m.group(1))
        expr = m.group(2).replace('""', '"')
        expected = m.group(3).replace('""', '"')
        out.append(
            {
                "idx": f"arrCases({n})",
                "expr": expr,
                "expected": expected,
                "ref_mode": "complex",
                "source": "complex_opt",
            }
        )

    def _key(c: dict) -> tuple[int, int]:
        lab = c["idx"]
        if lab.startswith("complexCases"):
            return (0, int(lab.split("(")[1].rstrip(")")))
        return (1, int(lab.split("(")[1].rstrip(")")))

    out.sort(key=_key)
    return out


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


def _eval_tuple_literal(expr: str, ns: dict, *, mode: str = "real") -> Any:
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
    return tuple(ref_eval(e, ns, mode=mode) for e in elems)


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


def build_ns_time(ans: Any) -> dict:
    ns = build_ns(ans)
    ns.update(
        {
            "millisecond": Duration(1),
            "second": Duration(_SECOND_MS),
            "minute": Duration(_MINUTE_MS),
            "hour": Duration(_HOUR_MS),
            "day": Duration(_DAY_MS),
            "dur_parse_colon_literal": dur_parse_colon_literal,
            "_dur_lit_compact": _dur_lit_compact,
            "sum_dur_sm": sum_dur_sm,
            "milliseconds": milliseconds_sm,
            "seconds": seconds_sm,
            "minutes": minutes_sm,
            "hours": hours_sm,
            "days": days_sm,
        }
    )
    return ns


def ref_eval(expr: str, ns: dict, *, mode: str = "real") -> Any:
    e = _strip_line_comment(expr).strip()
    if not e:
        raise ValueError("empty")
    e = _replace_int_literals(e)
    p = _postfix_percent(e)
    if p is None:
        raise ValueError("postfix percent")
    e = p
    if mode == "complex":
        e = _preprocess_complex_surface(e)
    elif mode == "time":
        e = _preprocess_time_expression(e)
    e = _implicit_mul(e)
    t = _translate_functions(e)
    if t is None:
        raise ValueError("translate")
    e = t
    if mode == "complex" and hasattr(ast, "unparse"):
        try:
            e = _broadcast_tuple_expr_string(e)
        except Exception:
            pass
    if e.startswith("(") and e.endswith(")") and e.count("(") == 1:
        try:
            return _eval_tuple_literal(e, ns, mode=mode)
        except Exception:
            pass
    node = ast.parse(e, mode="eval")
    return eval(compile(node, "<smoke>", "eval"), {"__builtins__": {}}, ns)


def ref_format(v: Any, *, mode: str = "real") -> str:
    if isinstance(v, Duration):
        return duration_format_ms(v.ms)
    if isinstance(v, complex):
        return _format_complex_smoke(v)
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
        inner = ", ".join(ref_format(x, mode=mode) for x in v)
        return f"({inner})"
    return str(v)


def try_reference(expr_chain: str, *, mode: str = "real") -> tuple[Optional[Any], Optional[str]]:
    """Evaluate semicolon chain; last statement value is result."""
    parts = _split_statements(expr_chain)
    ns: dict = build_ns_time(None) if mode == "time" else build_ns(None)
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
                    last = ref_eval(rhs, ns, mode=mode)
                    ns[name] = last
                    ns["ans"] = last
                    continue
            last = ref_eval(part, ns, mode=mode)
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

    cases = parse_smoke_cases(bas) + parse_smoke_complex_opt_cases(bas)
    mismatches: list[str] = []
    skipped: list[str] = []
    ok = 0
    n_complex = 0
    n_complex_opt = 0
    n_time = 0

    for case in cases:
        idx = case["idx"]
        if "expected" not in case:
            continue
        reason = should_skip_case(case)
        if reason:
            skipped.append(f"#{idx}: {reason}")
            continue
        exp = case["expected"].strip()
        mode = case.get("ref_mode") or infer_ref_mode(case["expr"], exp)
        if case.get("source") == "complex_opt":
            n_complex_opt += 1
        if mode == "complex":
            n_complex += 1
        elif mode == "time":
            n_time += 1
        val, err = try_reference(case["expr"], mode=mode)
        if err:
            skipped.append(f"#{idx}: eval failed ({err[:80]})")
            continue
        got = ref_format(val, mode=mode).strip()
        if results_match(exp, got, mode=mode):
            ok += 1
            continue
        mismatches.append(
            f"#{idx} expr={case['expr']!r}\n  expected(smoke)={exp!r}\n  ref_python  ={got!r}\n"
        )

    print("=== Smoke expected vs Python reference ===")
    print(f"Cases with numeric expected: {sum(1 for c in cases if 'expected' in c)}")
    print(
        f"Compared OK (real/complex/time reference, tol rules): {ok}  "
        f"(complex-mode rows: {n_complex} incl. complex-opt block {n_complex_opt}, "
        f"time-mode: {n_time})"
    )
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
