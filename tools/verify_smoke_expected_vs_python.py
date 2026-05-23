#!/usr/bin/env python3
"""
Cross-check SmokeTest_MathParser.bas numeric *expected* strings against a Python
reference (math + statistics + explicit Smart-Math-like rules).

Expressions use the Smart Math surface syntax; we translate a large subset to
Python. Cases we cannot translate safely are reported as SKIP (not mismatches).

When an expression *looks like* a complex or time-duration case (heuristic), we
switch to a dedicated reference path:
  * **Complex:** map Smart-Math `i` suffix / bare `i` to Python ``j``, evaluate with
    ``complex`` arithmetic, then compare after normalizing ``j`` <-> ``i`` spelling.
    Tuple + scalar / tuple * scalar / element-wise tuple/tuple uses the same
    broadcast lowering as the ``RunComplexNumberSupportOptionTests`` block in
    ``SmokeTest_MathParser.bas``. Table rows are discovered from:
    ``StemCases``/``StemOk`` + ``StemExpect``; ``StemExpr`` + ``StemExpect`` (with
    ``&`` string concat via ``dim … as String`` constants); ``dim var`` +
    ``Parser_TryEvaluateEx(var,…) orelse rt <> varExpect``; inline literal probes;
    and ``*ErrExpr`` error tables. ``hex``/``bin``/``oct``/``uhex``/``uoct``/``ubin``
    are evaluated for reference strings (uppercase ``0x``). DSL-only forms
    (``unique``, ``unpack``, ``sort``, trailing ``uhex`` command, user ``f(x)=``) stay
    skipped when not comparable.
  * **Real (recent exact-int math):** ``sqrt``/``sqr`` use Smart-Math-style exact
    integer rules; ``tests(1150)``..``1156`` and ``raw-api/sqrt-non-perfect-square``
    are included. ``hex(sqr(9))`` etc. use the same display builtins as smoke.
  * **Time:** colon literals (MM:SS / HH:MM:SS / DD:HH:MM:SS), named duration
    constants (``second`` … ``day``), compact suffix forms (``1d2h3m4s5ms``),
    converters (``milliseconds``, ``seconds``, …), and ``sum`` of durations —
    enough to mirror the smoke *expected* strings for the time block.

Float agreement uses the same tolerance idea as SmokeTest_MathParser.bas:
  tol = 16 * eps * max(1, |a|, |b|)

Sources parsed (in addition to ``tests(N)`` rows):
  * ``tools/neg_band_cases_generated.bas`` (neg/pos real + complex magnitude bands)
  * ``RunOperatorPrecedenceDocTests`` (``precOk`` / ``precExpect``)
  * ``RunTrigAngleReductionTests`` (magnitude ``|result|`` thresholds)
  * Inline ``Parser_TryEvaluateEx(...) orelse rt <> "..."`` numeric probes in smoke subs
"""

from __future__ import annotations

import ast
import cmath
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
        if math.isinf(r):
            return "-inf" if r < 0 else "inf"
        if abs(r - round(r)) < 1e-12 and abs(r) < 1e15:
            return str(int(round(r)))
        return str(r).rstrip("0").rstrip(".")
    # non-zero imaginary
    eps = 1e-12
    def fmt_re(x: float) -> str:
        if math.isnan(x):
            return "nan"
        if math.isinf(x):
            return "-inf" if x < 0 else "inf"
        if abs(x) < eps:
            return ""
        if abs(x - round(x)) < 1e-12 and abs(x) < 1e15:
            return str(int(round(x)))
        return str(x).rstrip("0").rstrip(".")

    def imag_tail(ai: float) -> str:
        if math.isnan(ai):
            return "nan*i"
        if math.isinf(ai):
            return ("-" if ai < 0 else "") + "inf*i"
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


def is_multiple_of(x: float, x_mult: float) -> bool:
    """Mirror MathParser ``IsMultipleOf`` (round quotient + residual)."""
    if x_mult == 0.0:
        return False
    q = x / x_mult
    if not math.isfinite(q):
        return False
    n = round(q)
    if abs(q - n) > 1e-9:
        return False
    residual = abs(x - n * x_mult)
    eps = max(1e-14 * abs(x_mult), 8.0 * EPS * abs(x_mult))
    return residual <= eps


def sin_sm(x: float) -> float:
    if x == 0.0:
        return 0.0
    if math.isfinite(x) and is_multiple_of(x, math.pi):
        return 0.0
    return math.sin(x)


def cos_sm(x: float) -> float:
    if math.isfinite(x):
        if not is_multiple_of(x, math.pi) and is_multiple_of(x, math.pi / 2.0):
            return 0.0
    return math.cos(x)


def tan_sm(x: float) -> float:
    if x == 0.0:
        return 0.0
    if math.isfinite(x):
        if is_multiple_of(x, math.pi):
            return 0.0
        if is_multiple_of(x, math.pi / 2.0):
            t = math.tan(x)
            return math.inf if t > 0.0 else -math.inf
    return math.tan(x)


def dsl_truth(x: Any) -> bool:
    if isinstance(x, complex):
        return x.real != 0.0 or x.imag != 0.0
    if isinstance(x, float):
        if math.isnan(x):
            return False
        return x != 0.0
    if isinstance(x, int):
        return x != 0
    return bool(x)


def dsl_lnot(x: Any) -> int:
    return 0 if dsl_truth(x) else 1


def dsl_and(a: Any, b: Any) -> int:
    return 1 if dsl_truth(a) and dsl_truth(b) else 0


def dsl_or(a: Any, b: Any) -> int:
    return 1 if dsl_truth(a) or dsl_truth(b) else 0


def dsl_cmp(op: str, a: Any, b: Any) -> int:
    if op == "eq":
        if isinstance(a, float) and isinstance(b, float) and math.isnan(a) and math.isnan(b):
            return 0
        if isinstance(a, (int, float)) and isinstance(b, (int, float)):
            return 1 if close_enough_str(str(a), str(b)) or a == b else 0
        return 1 if a == b else 0
    if op == "ne":
        if isinstance(a, float) and isinstance(b, float) and math.isnan(a) and math.isnan(b):
            return 1
        return 1 - dsl_cmp("eq", a, b)
    if op == "lt":
        return 1 if a < b else 0
    if op == "le":
        return 1 if a <= b else 0
    if op == "gt":
        return 1 if a > b else 0
    if op == "ge":
        return 1 if a >= b else 0
    raise ValueError(op)


def dsl_bitinv(x: Any) -> float:
    return float(~int(math.trunc(float(x))))


def fractional_power_is_odd_unit_root(p: float) -> Optional[int]:
    if p <= 0.0 or p >= 1.0:
        return None
    inv = 1.0 / p
    if inv < 2.0 or inv > 63.0:
        return None
    n = int(round(inv))
    if n < 2 or n > 63:
        return None
    if abs(inv - float(n)) > 1e-6:
        return None
    if (n % 2) == 0:
        return None
    return n


def _real_scalar_mag(v: Any) -> float:
    if isinstance(v, complex):
        return abs(v)
    if isinstance(v, (int, float)):
        return abs(float(v))
    raise TypeError("not numeric")


class _SmokeAstTransform(ast.NodeTransformer):
    """Comparisons and boolean ops return Smart-Math 0/1 ints."""

    def __init__(self, mode: str = "real") -> None:
        self._mode = mode

    def visit_BinOp(self, node: ast.BinOp) -> ast.AST:
        if isinstance(node.op, ast.Pow):
            fn = "pow_sm_cx" if self._mode == "complex" else "pow_sm"
        elif isinstance(node.op, ast.Mod):
            fn = "mod_sm"
        else:
            return self.generic_visit(node)
        return ast.Call(
            func=ast.Name(id=fn, ctx=ast.Load()),
            args=[self.visit(node.left), self.visit(node.right)],
            keywords=[],
        )

    def visit_Compare(self, node: ast.Compare) -> ast.AST:
        left = self.visit(node.left)
        for op, comp in zip(node.ops, node.comparators):
            right = self.visit(comp)
            op_name = {
                ast.Eq: "eq",
                ast.NotEq: "ne",
                ast.Lt: "lt",
                ast.LtE: "le",
                ast.Gt: "gt",
                ast.GtE: "ge",
            }.get(type(op))
            if op_name is None:
                raise ValueError("compare op")
            left = ast.Call(
                func=ast.Name(id="dsl_cmp", ctx=ast.Load()),
                args=[ast.Constant(op_name), left, right],
                keywords=[],
            )
        return left

    def visit_BoolOp(self, node: ast.BoolOp) -> ast.AST:
        fn = "dsl_and" if isinstance(node.op, ast.And) else "dsl_or"
        acc = self.visit(node.values[0])
        for v in node.values[1:]:
            acc = ast.Call(
                func=ast.Name(id=fn, ctx=ast.Load()),
                args=[acc, self.visit(v)],
                keywords=[],
            )
        return acc

    def visit_UnaryOp(self, node: ast.UnaryOp) -> ast.AST:
        if isinstance(node.op, ast.Not):
            return ast.Call(
                func=ast.Name(id="dsl_lnot", ctx=ast.Load()),
                args=[self.visit(node.operand)],
                keywords=[],
            )
        if isinstance(node.op, ast.Invert):
            return ast.Call(
                func=ast.Name(id="dsl_bitinv", ctx=ast.Load()),
                args=[self.visit(node.operand)],
                keywords=[],
            )
        return self.generic_visit(node)


def _preprocess_unary_bang_real(expr: str) -> str:
    s = expr
    while True:
        m = re.search(r"!(?!=)", s)
        if not m:
            break
        pos = m.start()
        rest = s[pos + 1 :].lstrip()
        mnum = re.match(r"(\d+\.?\d*(?:[eE][-+]?\d+)?)", rest)
        if mnum:
            num = mnum.group(1)
            s = s[:pos] + f"dsl_lnot({num})" + rest[len(num) :]
            continue
        if rest.startswith("("):
            s = s[:pos] + "dsl_lnot(" + rest[1:]
            continue
        break
    return s


def _preprocess_real_dsl(expr: str) -> str:
    s = expr.replace("<>", "!=")
    s = _preprocess_unary_bang_real(s)
    out: list[str] = []
    i = 0
    while i < len(s):
        if s[i : i + 2] in ("==", "!=", "<=", ">="):
            out.append(s[i : i + 2])
            i += 2
            continue
        if s[i] == "=":
            out.append("==")
            i += 1
            continue
        out.append(s[i])
        i += 1
    s = "".join(out)
    s = re.sub(r"\s*&&\s*", " and ", s)
    s = re.sub(r"\s*\|\|\s*", " or ", s)
    return s


def _preprocess_hex_for_numeric_add(expr: str, expected: str) -> str:
    if not re.search(r"\bhex\s*\(", expr, re.I):
        return expr
    exp = expected.strip()
    if re.fullmatch(r"[-+]?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?", exp) or (
        exp.startswith("(") and "0x" not in exp.lower()
    ):
        return re.sub(r"\bhex\s*\(", "hex_val_sm(", expr, flags=re.I)
    return expr


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


_RE_RUN_COMPLEX_SUB = re.compile(
    r"(?is)private\s+sub\s+RunComplexNumberSupportOptionTests\s*\([^)]*\)\s*(.*?)(?:^\s*end\s+sub\s*$)",
    re.MULTILINE,
)

# Same-line paired table row: fooCases(3) or fooOk(3) = "expr": fooExpect(3) = "expect"
_RE_COMPLEX_OPT_PAIRED_ROW = re.compile(
    r'([A-Za-z_][A-Za-z0-9_]*)(?:Cases|Ok)\s*\(\s*(\d+)\s*\)\s*=\s*"((?:[^"\\]|\\.)*)"\s*:\s*'
    r'\1Expect\s*\(\s*\2\s*\)\s*=\s*"((?:[^"\\]|\\.)*)"',
    re.I,
)

# fooExpr(n) = "real(" & var & ")": fooExpect(n) = "..." or fooExpect(n) = otherVar
_RE_COMPLEX_OPT_PAIRED_EXPR_ROW = re.compile(
    r"([A-Za-z_][A-Za-z0-9_]*)Expr\s*\(\s*(\d+)\s*\)\s*=\s*([^:\r\n]+?)\s*:\s*"
    r"\1Expect\s*\(\s*\2\s*\)\s*=\s*([^:\r\n]+)",
    re.I,
)

_RE_DIM_STRING_CONST = re.compile(
    r'dim\s+([A-Za-z_][A-Za-z0-9_]*)\s+as\s+String\s*=\s*"((?:[^"\\]|\\.)*)"',
    re.I,
)

# Parser_TryEvaluateEx(var, ...) = FALSE orelse rt <> varExpect | "literal"
_RE_COMPLEX_OPT_VAR_PROBE = re.compile(
    r"Parser_TryEvaluateEx\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*,\s*r\s*,\s*rt\s*,\s*ia\s*\)\s*=\s*FALSE\s+"
    r"orelse\s+rt\s+<>\s+(?:\"((?:[^\"\\]|\\.)*)\"|([A-Za-z_][A-Za-z0-9_]*))",
    re.I,
)

_RE_RUN_RAW_SUB = re.compile(
    r"(?is)private\s+sub\s+RunRawResultApiTests\s*\([^)]*\)\s*(.*?)(?:^\s*end\s+sub\s*$)",
    re.MULTILINE,
)

# Error-only table: cmpErrExpr(1) = "1+2i > 0"
_RE_COMPLEX_OPT_ERR_ROW = re.compile(
    r'([A-Za-z_][A-Za-z0-9_]*Err(?:Expr)?)\s*\(\s*(\d+)\s*\)\s*=\s*"((?:[^"\\]|\\.)*)"',
    re.I,
)

# Inline literal probe: if Parser_TryEvaluateEx("expr", r, rt, ia) then ... expected error ...
_RE_COMPLEX_OPT_INLINE_PROBE = re.compile(
    r'if\s+Parser_TryEvaluateEx\("((?:[^"\\]|\\.)*)"\s*,\s*r\s*,\s*rt\s*,\s*ia\s*\)\s+then',
    re.I,
)

# Inline success probe: ... = FALSE orelse rt <> "expect"
_RE_COMPLEX_OPT_INLINE_SUCCESS = re.compile(
    r'if\s+Parser_TryEvaluateEx\("((?:[^"\\]|\\.)*)"\s*,\s*r\s*,\s*rt\s*,\s*ia\s*\)\s*=\s*FALSE\s+'
    r'orelse\s+rt\s+<>\s+"((?:[^"\\]|\\.)*)"',
    re.I,
)


def _extract_run_complex_number_support_sub_body(text: str) -> Optional[str]:
    """Return the body of ``RunComplexNumberSupportOptionTests`` only (no outer subs)."""
    m = _RE_RUN_COMPLEX_SUB.search(text)
    return m.group(1) if m else None


def _extract_run_raw_result_sub_body(text: str) -> Optional[str]:
    m = _RE_RUN_RAW_SUB.search(text)
    return m.group(1) if m else None


def _unescape_fb_string(s: str) -> str:
    return s.replace('""', '"')


def _collect_dim_string_constants(block: str) -> dict[str, str]:
    consts: dict[str, str] = {}
    for m in _RE_DIM_STRING_CONST.finditer(block):
        consts[m.group(1)] = _unescape_fb_string(m.group(2))
    return consts


def _resolve_fb_string_piece(piece: str, consts: dict[str, str]) -> str:
    piece = piece.strip()
    m = re.fullmatch(r'"((?:[^"\\]|\\.)*)"', piece)
    if m:
        return _unescape_fb_string(m.group(1))
    if piece in consts:
        return consts[piece]
    raise ValueError(f"unresolved string piece: {piece!r}")


def _resolve_fb_string_expr(rhs: str, consts: dict[str, str]) -> str:
    rhs = rhs.strip()
    if "&" not in rhs:
        return _resolve_fb_string_piece(rhs, consts)
    return "".join(_resolve_fb_string_piece(p, consts) for p in re.split(r"\s*&\s*", rhs))


def _resolve_fb_expect_rhs(rhs: str, consts: dict[str, str]) -> str:
    rhs = rhs.strip()
    if rhs.startswith('"'):
        return _resolve_fb_string_expr(rhs, consts)
    if rhs in consts:
        return consts[rhs]
    return rhs


def _parse_paired_expr_expect_tables(block: str, consts: dict[str, str], add_case) -> None:
    for m in _RE_COMPLEX_OPT_PAIRED_EXPR_ROW.finditer(block):
        stem, n_s, expr_rhs, exp_rhs = m.group(1), m.group(2), m.group(3), m.group(4)
        n = int(n_s)
        try:
            expr = _resolve_fb_string_expr(expr_rhs, consts)
            expected = _resolve_fb_expect_rhs(exp_rhs, consts)
        except ValueError:
            continue
        add_case(
            {
                "idx": f"{stem}Expr({n})",
                "expr": expr,
                "expected": expected,
                "ref_mode": "complex",
                "source": "complex_opt",
            }
        )


def parse_smoke_synthetic_recent_cases() -> list[dict]:
    """Probes that live only in raw/API subs (no tests(N).expected)."""
    return [
        {
            "idx": "raw-api/sqrt-non-perfect-square-display",
            "expr": "sqrt(4611686014132420611)",
            "expected": "2147483647",
            "ref_mode": "real",
            "source": "raw_api",
        },
    ]


_RE_PREC_PAIR = re.compile(
    r'precOk\s*\(\s*(\d+)\s*\)\s*=\s*"((?:[^"\\]|\\.)*)"\s*:\s*precExpect\s*\(\s*\1\s*\)\s*=\s*"((?:[^"\\]|\\.)*)"',
    re.I,
)

_RE_TRIG_NONZERO = re.compile(
    r'nonzeroExpr\s*\(\s*(\d+)\s*\)\s*=\s*"((?:[^"\\]|\\.)*)"',
    re.I,
)

_RE_TRIG_NEARZERO = re.compile(
    r'nearZeroExpr\s*\(\s*(\d+)\s*\)\s*=\s*"((?:[^"\\]|\\.)*)"',
    re.I,
)

_RE_INLINE_NUMERIC = re.compile(
    r'Parser_TryEvaluateEx\s*\(\s*"((?:[^"\\]|\\.)*)"\s*,\s*r\s*,\s*rt\s*,\s*ia\s*\)\s*=\s*FALSE\s+'
    r'orelse\s+rt\s+<>\s+"((?:[^"\\]|\\.)*)"',
    re.I,
)


def _unescape_fb(s: str) -> str:
    return s.replace('""', '"')


def parse_smoke_sub_array_cases(path: str) -> list[dict]:
    """``precOk``/``precExpect`` and trig magnitude tables from SmokeTest_MathParser.bas."""
    text = open(path, encoding="utf-8", errors="replace").read()
    out: list[dict] = []
    seen: set[str] = set()
    for m in _RE_PREC_PAIR.finditer(text):
        n, expr, expected = m.group(1), _unescape_fb(m.group(2)), _unescape_fb(m.group(3))
        key = f"precedence:{expr}"
        if key in seen:
            continue
        seen.add(key)
        out.append(
            {
                "idx": f"precedence-doc/{n}",
                "expr": expr,
                "expected": expected,
                "ref_mode": infer_ref_mode(expr, expected),
                "source": "precedence_doc",
            }
        )
    for m in _RE_TRIG_NONZERO.finditer(text):
        n, expr = m.group(1), _unescape_fb(m.group(2))
        key = f"trig-nz:{expr}"
        if key in seen:
            continue
        seen.add(key)
        out.append(
            {
                "idx": f"trig-reduction/nonzero/{n}",
                "expr": expr,
                "assert_kind": "abs_gt",
                "assert_threshold": 1e-6,
                "ref_mode": "real",
                "source": "trig_reduction",
            }
        )
    for m in _RE_TRIG_NEARZERO.finditer(text):
        n, expr = m.group(1), _unescape_fb(m.group(2))
        key = f"trig-z:{expr}"
        if key in seen:
            continue
        seen.add(key)
        out.append(
            {
                "idx": f"trig-reduction/nearzero/{n}",
                "expr": expr,
                "assert_kind": "abs_lt",
                "assert_threshold": 1e-9,
                "ref_mode": "real",
                "source": "trig_reduction",
            }
        )
    return out


def parse_smoke_inline_numeric_probes(path: str) -> list[dict]:
    """``Parser_TryEvaluateEx(...) orelse rt <> "expect"`` rows across smoke subs."""
    text = open(path, encoding="utf-8", errors="replace").read()
    out: list[dict] = []
    seen: set[str] = set()
    for m in _RE_INLINE_NUMERIC.finditer(text):
        expr = _unescape_fb(m.group(1))
        expected = _unescape_fb(m.group(2))
        if "/" in expected and not re.search(r"\d+/\d+", expected):
            continue
        if expected.strip() in ("0", "1") and re.search(
            r"(?<![<>!=])=(?!=)|<>|!=|==", expr
        ):
            pass
        key = f"{expr}|{expected}"
        if key in seen:
            continue
        seen.add(key)
        out.append(
            {
                "idx": f"inline:{expr[:60]}",
                "expr": expr,
                "expected": expected,
                "ref_mode": infer_ref_mode(expr, expected),
                "source": "inline_probe",
            }
        )
    return out


def parse_band_cases_file(path: str) -> list[dict]:
    """Parse ``neg_band_cases_generated.bas`` (and positive/complex tables)."""
    text = open(path, encoding="utf-8", errors="replace").read()
    out: list[dict] = []
    for table, ref_mode in (
        ("negBandReal", "real"),
        ("posBandReal", "real"),
        ("negBandCx", "complex"),
        ("posBandCx", "complex"),
    ):
        exprs: dict[int, str] = {}
        expects: dict[int, str] = {}
        is_err: dict[int, bool] = {}
        err_txt: dict[int, str] = {}
        for m in re.finditer(
            rf'{table}Expr\s*\(\s*(\d+)\s*\)\s*=\s*"((?:[^"\\]|\\.)*)"',
            text,
        ):
            exprs[int(m.group(1))] = _unescape_fb(m.group(2))
        for m in re.finditer(
            rf'{table}Expect\s*\(\s*(\d+)\s*\)\s*=\s*"((?:[^"\\]|\\.)*)"',
            text,
        ):
            expects[int(m.group(1))] = _unescape_fb(m.group(2))
        for m in re.finditer(
            rf'{table}IsErr\s*\(\s*(\d+)\s*\)\s*=\s*(TRUE|FALSE)',
            text,
            re.I,
        ):
            is_err[int(m.group(1))] = m.group(2).upper() == "TRUE"
        for m in re.finditer(
            rf'{table}Err\s*\(\s*(\d+)\s*\)\s*=\s*"((?:[^"\\]|\\.)*)"',
            text,
        ):
            err_txt[int(m.group(1))] = _unescape_fb(m.group(2))
        for i in sorted(exprs):
            label_m = re.search(
                rf'{table}Label\s*\(\s*{i}\s*\)\s*=\s*"((?:[^"\\]|\\.)*)"',
                text,
            )
            label = _unescape_fb(label_m.group(1)) if label_m else f"{table}/{i}"
            entry: dict = {
                "idx": f"band/{table}/{i}",
                "expr": exprs[i],
                "source": "magnitude_band",
                "ref_mode": ref_mode,
                "band_label": label,
            }
            if is_err.get(i):
                entry["expect_error"] = True
                if i in err_txt:
                    entry["expected_err_substr"] = err_txt[i]
            elif i in expects:
                entry["expected"] = expects[i]
            out.append(entry)
    return out


def collect_all_numeric_cases(smoke_bas: str, band_bas: str) -> list[dict]:
    return (
        parse_smoke_cases(smoke_bas)
        + parse_smoke_sub_array_cases(smoke_bas)
        + parse_smoke_inline_numeric_probes(smoke_bas)
        + parse_band_cases_file(band_bas)
        + parse_smoke_complex_opt_cases(smoke_bas)
        + parse_smoke_raw_api_cases(smoke_bas)
        + parse_smoke_synthetic_recent_cases()
    )


def parse_smoke_raw_api_cases(path: str) -> list[dict]:
    """Inline numeric probes from ``RunRawResultApiTests`` (display string, not raw kind)."""
    text = open(path, encoding="utf-8", errors="replace").read()
    block = _extract_run_raw_result_sub_body(text)
    if not block:
        return []
    out: list[dict] = []
    seen: set[str] = set()

    def add(entry: dict) -> None:
        key = entry["idx"]
        if key in seen:
            return
        seen.add(key)
        out.append(entry)

    for m in _RE_COMPLEX_OPT_INLINE_SUCCESS.finditer(block):
        expr = _unescape_fb_string(m.group(1))
        expected = _unescape_fb_string(m.group(2))
        add(
            {
                "idx": f"raw-inline:{expr}",
                "expr": expr,
                "expected": expected,
                "ref_mode": infer_ref_mode(expr, expected),
                "source": "raw_api",
            }
        )
    return out


def parse_smoke_complex_opt_cases(path: str) -> list[dict]:
    """
    Parse numeric and error probes from ``RunComplexNumberSupportOptionTests``.

    * Paired rows: ``fooCases(n) = "expr": fooExpect(n) = "exp"`` or
      ``fooOk(n): fooExpect(n)`` on one line.
    * ``fooExpr(n) = <string expr> : fooExpect(n) = <expect>`` (supports ``&`` concat).
    * ``dim var as String = "lit"`` with ``Parser_TryEvaluateEx(var, ...) orelse rt <> varExpect``.
    * Error tables: ``cmpErrExpr(n) = "expr"`` (no expected string).
    * Inline ``Parser_TryEvaluateEx("literal", ...)`` success/error probes.
    """
    text = open(path, encoding="utf-8", errors="replace").read()
    block = _extract_run_complex_number_support_sub_body(text)
    if not block:
        return []

    consts = _collect_dim_string_constants(block)

    out: list[dict] = []
    stem_first_pos: dict[str, int] = {}
    seen_keys: set[str] = set()

    def add_case(entry: dict) -> None:
        key = entry["idx"]
        if key in seen_keys:
            return
        seen_keys.add(key)
        stem = re.match(r"([A-Za-z_][A-Za-z0-9_]*)", key)
        if stem:
            stem_first_pos.setdefault(stem.group(1).lower(), len(out))
        out.append(entry)

    _parse_paired_expr_expect_tables(block, consts, add_case)

    for m in _RE_COMPLEX_OPT_VAR_PROBE.finditer(block):
        var, lit_exp, id_exp = m.group(1), m.group(2), m.group(3)
        if var not in consts:
            continue
        expr = consts[var]
        if lit_exp is not None:
            expected = _unescape_fb_string(lit_exp)
        elif id_exp in consts:
            expected = consts[id_exp]
        else:
            continue
        add_case(
            {
                "idx": f"var:{var}",
                "expr": expr,
                "expected": expected,
                "ref_mode": "complex",
                "source": "complex_opt",
            }
        )

    for m in _RE_COMPLEX_OPT_PAIRED_ROW.finditer(block):
        stem, n_s, expr_s, exp_s = m.group(1), m.group(2), m.group(3), m.group(4)
        n = int(n_s)
        expr = expr_s.replace('""', '"')
        expected = exp_s.replace('""', '"')
        add_case(
            {
                "idx": f"{stem}({n})",
                "expr": expr,
                "expected": expected,
                "ref_mode": "complex",
                "source": "complex_opt",
            }
        )

    for m in _RE_COMPLEX_OPT_ERR_ROW.finditer(block):
        stem, n_s, expr_s = m.group(1), m.group(2), m.group(3)
        n = int(n_s)
        expr = expr_s.replace('""', '"')
        add_case(
            {
                "idx": f"{stem}({n})",
                "expr": expr,
                "expect_error": True,
                "ref_mode": "complex",
                "source": "complex_opt",
            }
        )

    for m in _RE_COMPLEX_OPT_INLINE_SUCCESS.finditer(block):
        expr_s, exp_s = m.group(1), m.group(2)
        expr = expr_s.replace('""', '"')
        expected = exp_s.replace('""', '"')
        add_case(
            {
                "idx": f"inline:{expr}",
                "expr": expr,
                "expected": expected,
                "ref_mode": "complex",
                "source": "complex_opt",
            }
        )

    for m in _RE_COMPLEX_OPT_INLINE_PROBE.finditer(block):
        expr_s = m.group(1)
        expr = expr_s.replace('""', '"')
        tail = block[m.end() : m.end() + 400]
        if re.search(r"expected\s+error|expected\s+failure", tail, re.I):
            add_case(
                {
                    "idx": f"inline-err:{expr}",
                    "expr": expr,
                    "expect_error": True,
                    "ref_mode": "complex",
                    "source": "complex_opt",
                }
            )

    def _key(c: dict) -> tuple[int, int, str]:
        lab = c["idx"]
        stem_m = re.match(r"([A-Za-z_][A-Za-z0-9_]*)", lab)
        stem = stem_m.group(1).lower() if stem_m else lab.lower()
        n_m = re.search(r"\((\d+)\)", lab)
        n = int(n_m.group(1)) if n_m else 0
        return (stem_first_pos.get(stem, 10**9), n, lab)

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
    # Numeric literal before ``(`` only (not ``log10_sm(`` / ``foo2(``).
    s = re.sub(r"(?<![A-Za-z0-9_])(\d+\.?\d*|\.\d+)\s*\(", r"\1*(", s)
    s = re.sub(r"\)\s*\(", r")*(", s)
    return s


def _postfix_percent(expr: str) -> Optional[str]:
    """
    Replace `... + 15%` patterns: `%` applies to the immediately preceding
    numeric atom (Smart Math: 200+15% -> 200 + 200*0.15).
    Lone ``1%`` -> ``0.01``.
    """
    if "%" not in expr:
        return expr
    if re.fullmatch(r"[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?\s*%", expr.strip()):
        return str(float(expr.strip()[:-1].strip()) / 100.0)
    out: list[str] = []
    i = 0
    while i < len(expr):
        if expr[i] == "%":
            rest = expr[i + 1 :].lstrip()
            if rest and rest[0] in "0123456789.(":
                out.append("%")
                i += 1
                continue
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
                pct = float(atom.strip()) / 100.0
                out = out[:j] + [str(pct)]
                i += 1
                continue
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


def _preprocess_complex_dsl(expr: str) -> str:
    """Smart-Math DSL in complex-option block: ``<>``, ``=``, ``!`` / ``not``."""
    s = expr.replace("<>", "!=")
    s = re.sub(r"!\s*\(", "complex_not_sm(", s)
    s = re.sub(r"\bnot\s+\(", "complex_not_sm(", s, flags=re.I)
    out: list[str] = []
    i = 0
    while i < len(s):
        if s[i : i + 2] in ("==", "!=", "<=", ">="):
            out.append(s[i : i + 2])
            i += 2
            continue
        if s[i] == "=":
            out.append("==")
            i += 1
            continue
        out.append(s[i])
        i += 1
    return "".join(out)


def _translate_functions(expr: str, *, mode: str = "real") -> Optional[str]:
    """Rename / wrap calls so ast.parse + eval with NS works."""
    s = expr
    repl = {
        "ln": "log_ln",
        "log10": "log10_sm",
        "product": "prod_sm",
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
        "int": "int_sm",
        "trunc": "int_sm",
    }
    repl.update(
        {
            "hex": "hex_sm",
            "bin": "bin_sm",
            "oct": "oct_sm",
            "uhex": "uhex_sm",
            "uoct": "uoct_sm",
            "ubin": "ubin_sm",
            "sqrt": "sqrt_sm_real",
        }
    )
    if mode == "complex":
        repl.update(
            {
                "int": "int_sm_cx",
        "trunc": "int_sm_cx",
                "frac": "frac_sm_cx",
                "floor": "floor_sm_cx",
                "ceil": "ceil_sm_cx",
                "round": "round_sm_cx",
                "real": "real_sm",
                "imag": "imag_sm",
                "conj": "conj_sm",
                "phase": "phase_sm",
                "polar": "polar_sm",
                "cart": "cart_sm",
                "sqrt": "sqrt_sm",
                "hypot": "hypot_sm",
            }
        )
    # Longer names first so ``log`` does not alter ``log10`` / ``log10_sm``.
    for old, new in sorted(repl.items(), key=lambda kv: -len(kv[0])):
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
    bf = float(b) if not isinstance(b, complex) else b
    ef = float(e) if not isinstance(e, complex) else e
    if isinstance(bf, complex) or isinstance(ef, complex):
        return bf**ef
    if bf < 0.0 and math.isfinite(bf) and math.isfinite(ef):
        n_root = fractional_power_is_odd_unit_root(ef)
        if n_root is not None:
            return -(abs(bf) ** ef)
    return bf**ef


def _as_int_exact(x: Any) -> Optional[int]:
    if isinstance(x, bool):
        return int(x)
    if isinstance(x, int):
        return x
    if isinstance(x, float) and math.isfinite(x):
        r = round(x)
        if abs(x - r) <= 1e-9 and abs(r) < (1 << 63):
            return int(r)
    return None


def _map_unary_real(fn):
    def wrapped(x: Any) -> Any:
        if isinstance(x, tuple):
            return tuple(wrapped(e) for e in x)
        return fn(x)

    return wrapped


def hex_val_sm(x: Any) -> Any:
    xi = _as_int_exact(x)
    if xi is None:
        raise ValueError("hex_val expects integer")
    return xi


def int_sm(x: Any) -> Any:
    if isinstance(x, tuple):
        return tuple(int_sm(e) for e in x)
    if isinstance(x, complex):
        return complex(math.trunc(x.real), math.trunc(x.imag))
    return float(math.trunc(float(x)))


def sqrt_sm_real(x: Any) -> Any:
    """Smart-Math sqrt: exact int only when round(sqrt(n))^2 == n (checked int multiply)."""
    if isinstance(x, tuple):
        return tuple(sqrt_sm_real(e) for e in x)
    if isinstance(x, complex):
        return sqrt_sm(x)
    xi = _as_int_exact(x)
    xf = float(x)
    if xi is None:
        return math.sqrt(xf)
    if xi < 0:
        return math.sqrt(xf)
    r = math.sqrt(float(xi))
    if not math.isfinite(r):
        return r
    n = int(round(r))
    if n * n == xi:
        return n
    return r


def sqr_sm(x):
    xi = _as_int_exact(x)
    if xi is not None:
        return xi * xi
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


def _flatten_args_cx(*args: Any) -> list[Any]:
    flat: list[Any] = []
    for a in args:
        if isinstance(a, tuple):
            flat.extend(a)
        else:
            flat.append(a)
    return flat


def mean_sm_cx(*args: Any) -> complex:
    flat = _flatten_args_cx(*args)
    if not flat:
        raise ValueError("empty")
    return sum(_as_complex(x) for x in flat) / len(flat)


def avg_sm_cx(*args: Any) -> complex:
    return mean_sm_cx(*args)


def fact_sm(n):
    if not float(n).is_integer() or n < 0:
        raise ValueError("fact")
    n = int(n)
    return float(math.factorial(n)) if n > 12 else math.factorial(n)


def mod_sm(a, b):
    """FreeBASIC ``mod`` / ``%``: remainder with sign of dividend."""
    a_i, b_i = int(a), int(b)
    if b_i == 0:
        raise ValueError("mod")
    return a_i - b_i * int(a_i / b_i)


def deg_sm(x):
    return x * 180.0 / math.pi


def rad_sm(x):
    return x * math.pi / 180.0


def _as_complex(z: Any) -> complex:
    if isinstance(z, complex):
        return z
    if isinstance(z, (int, float)):
        return complex(float(z), 0.0)
    raise TypeError("not scalar")


def _map_unary_cx(fn):
    """Element-wise on tuples (Smart-Math array builtins)."""

    def wrapped(x: Any) -> Any:
        if isinstance(x, tuple):
            return tuple(wrapped(e) for e in x)
        return fn(x)

    return wrapped


def complex_not_sm(z: Any) -> int:
    """Smart-Math ``!`` / ``not``: true only when both Cartesian parts are ~0."""
    c = _as_complex(z)
    eps = 1e-15
    return 1 if abs(c.real) < eps and abs(c.imag) < eps else 0


def sign_sm(x):
    if isinstance(x, complex):
        if abs(x) < 1e-15:
            return 0
        return x / abs(x)
    return -1 if x < 0 else (1 if x > 0 else 0)


def sign_sm_real(x):
    return -1 if x < 0 else (1 if x > 0 else 0)


def sqrt_sm(x):
    if isinstance(x, complex) or (isinstance(x, (int, float)) and x < 0):
        return cmath.sqrt(complex(x))
    return sqrt_sm_real(x)


def _format_hex_component(v: int, *, unsigned: bool = False) -> str:
    if unsigned and v < 0:
        uv = v % (1 << 64)
        return "0x" + format(uv, "X")
    if v < 0:
        return "-0x" + format(-v, "X")
    return "0x" + format(v, "X")


def _format_hex_imag_coeff(ai: float) -> str:
    if abs(ai) < 1e-15:
        return "0"
    neg = ai < 0
    a = abs(ai)
    if abs(a - 1.0) < 1e-12:
        body = "i" if not neg else "-i"
    else:
        iv = int(round(a)) if abs(a - round(a)) < 1e-12 else None
        if iv is not None:
            body = (f"0x{format(iv, 'X')}i" if iv != 1 else "i")
        else:
            body = f"{a}i".rstrip("0").rstrip(".")
        if neg:
            body = "-" + body.lstrip("-")
    return body


def hex_sm(x: Any, *, unsigned: bool = False) -> Any:
    if isinstance(x, tuple):
        return tuple(hex_sm(e, unsigned=unsigned) for e in x)
    if isinstance(x, complex):
        re_s = _format_hex_component(int(round(x.real)), unsigned=unsigned)
        im_s = _format_hex_imag_coeff(x.imag)
        if im_s in ("0", "i", "-i"):
            if im_s == "0":
                return re_s
            if not re_s or re_s == "0x0":
                return im_s
        if x.imag > 0:
            return f"{re_s}+{im_s}"
        return f"{re_s}{im_s}"
    xi = _as_int_exact(x)
    if xi is None:
        raise ValueError("hex expects integer values")
    return _format_hex_component(xi, unsigned=unsigned)


def bin_sm(x: Any) -> Any:
    if isinstance(x, tuple):
        return tuple(bin_sm(e) for e in x)
    xi = _as_int_exact(x)
    if xi is None:
        raise ValueError("bin expects integer values")
    if xi < 0:
        return "-0b" + format(-xi, "b")
    return "0b" + format(xi, "b")


def oct_sm(x: Any) -> Any:
    if isinstance(x, tuple):
        return tuple(oct_sm(e) for e in x)
    xi = _as_int_exact(x)
    if xi is None:
        raise ValueError("oct expects integer values")
    if xi < 0:
        return "-0o" + format(-xi, "o")
    return "0o" + format(xi, "o")


def uhex_sm(x: Any) -> Any:
    return hex_sm(x, unsigned=True)


def uoct_sm(x: Any) -> Any:
    if isinstance(x, tuple):
        return tuple(uoct_sm(e) for e in x)
    xi = _as_int_exact(x)
    if xi is None:
        raise ValueError("uoct expects integer values")
    uv = xi % (1 << 64) if xi < 0 else xi
    return "0o" + format(uv, "o")


def ubin_sm(x: Any) -> Any:
    if isinstance(x, tuple):
        return tuple(ubin_sm(e) for e in x)
    xi = _as_int_exact(x)
    if xi is None:
        raise ValueError("ubin expects integer values")
    uv = xi % (1 << 64) if xi < 0 else xi
    return "0b" + format(uv, "b")


def hypot_sm(a, b):
    a, b = _as_complex(a), _as_complex(b)
    return (abs(a) ** 2 + abs(b) ** 2) ** 0.5


def _log_ln_cx_scalar(x: Any) -> complex:
    c = _as_complex(x)
    if c == 0:
        return complex(-math.inf, 0.0)
    return cmath.log(c)


log_ln_cx = _map_unary_cx(_log_ln_cx_scalar)


def _log10_cx_scalar(x: Any) -> complex:
    return cmath.log10(_as_complex(x))


log10_sm_cx = _map_unary_cx(_log10_cx_scalar)


def log_sm_cx(a, b=None):
    if b is None:
        raise TypeError("log needs 2 args")
    if isinstance(a, tuple) or isinstance(b, tuple):
        if not (isinstance(a, tuple) and isinstance(b, tuple)):
            raise TypeError("not scalar")
        if len(a) != len(b):
            raise ValueError("length")
        return tuple(log_sm_cx(x, y) for x, y in zip(a, b))
    return cmath.log(_as_complex(a)) / cmath.log(_as_complex(b))


def pow_sm_cx(b, e):
    br = _as_complex(b)
    er = _as_complex(e)
    if abs(br.imag) < 1e-15 and abs(er.imag) < 1e-15:
        r = pow_sm(br.real, er.real)
        if isinstance(r, (int, float)) and math.isfinite(float(r)):
            return complex(float(r), 0.0)
    return br**er


def _int_sm_cx_scalar(z: Any) -> complex:
    c = _as_complex(z)
    return complex(math.trunc(c.real), math.trunc(c.imag))


int_sm_cx = _map_unary_cx(_int_sm_cx_scalar)


def frac_sm_cx(z):
    c = _as_complex(z)
    return complex(c.real - math.trunc(c.real), c.imag - math.trunc(c.imag))


def round_sm_cx(z):
    c = _as_complex(z)
    return complex(round_half_away_from_zero(c.real), round_half_away_from_zero(c.imag))


def floor_sm_cx(z):
    c = _as_complex(z)
    return complex(math.floor(c.real), math.floor(c.imag))


def ceil_sm_cx(z):
    c = _as_complex(z)
    return complex(math.ceil(c.real), math.ceil(c.imag))


def real_sm(z):
    c = _as_complex(z)
    return c.real


def imag_sm(z):
    return _as_complex(z).imag


def conj_sm(z):
    return _as_complex(z).conjugate()


def phase_sm(z):
    return cmath.phase(_as_complex(z))


def polar_sm(z):
    c = _as_complex(z)
    return (abs(c), cmath.phase(c))


def cart_sm(z):
    if isinstance(z, tuple) and len(z) == 2:
        return cmath.rect(float(z[0]), float(z[1]))
    return _as_complex(z)


def atan2_sm_cx(y: Any, x: Any) -> float:
    if isinstance(y, complex) or isinstance(x, complex):
        raise ValueError("incompatible operands")
    return math.atan2(float(y), float(x))


def deg_sm_cx(x: Any) -> float:
    if isinstance(x, complex) and abs(x.imag) > 1e-15:
        raise ValueError("incompatible operands")
    return deg_sm(x.real if isinstance(x, complex) else float(x))


def rad_sm_cx(x: Any) -> float:
    if isinstance(x, complex) and abs(x.imag) > 1e-15:
        raise ValueError("incompatible operands")
    return rad_sm(x.real if isinstance(x, complex) else float(x))


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
        "inf": math.inf,
        "nan": math.nan,
        "ans": ans,
        "dsl_cmp": dsl_cmp,
        "dsl_lnot": dsl_lnot,
        "dsl_and": dsl_and,
        "dsl_or": dsl_or,
        "dsl_bitinv": dsl_bitinv,
        "hex_val_sm": hex_val_sm,
        "int_sm": int_sm,
        "log_sm": log_sm,
        "log_ln": _map_unary_real(log_ln),
        "log10_sm": _map_unary_real(log10_sm),
        "pow_sm": pow_sm,
        "pow_sm_cx": pow_sm_cx,
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
        "sin": _map_unary_real(sin_sm),
        "cos": _map_unary_real(cos_sm),
        "tan": _map_unary_real(tan_sm),
        "asin": math.asin,
        "acos": math.acos,
        "atan": math.atan,
        "sinh": math.sinh,
        "cosh": math.cosh,
        "tanh": math.tanh,
        "exp": math.exp,
        "sqrt": sqrt_sm_real,
        "hex_sm": hex_sm,
        "bin_sm": bin_sm,
        "oct_sm": oct_sm,
        "uhex_sm": uhex_sm,
        "uoct_sm": uoct_sm,
        "ubin_sm": ubin_sm,
        "abs": abs,
        "floor": math.floor,
        "ceil": math.ceil,
        "trunc": math.trunc,
        "round_sm": round_sm,
        "atan2": math.atan2,
        "hypot": math.hypot,
    }


def build_ns_complex(ans: Any) -> dict:
    """Namespace for complex-option reference (``cmath`` + Smart-Math component rules)."""
    ns = build_ns(ans)
    ns.update(
        {
            "log_sm": log_sm_cx,
            "log_ln": log_ln_cx,
            "log10_sm": log10_sm_cx,
            "mean_sm": mean_sm_cx,
            "avg_sm": avg_sm_cx,
            "pow_sm": pow_sm_cx,
            "sqrt_sm": sqrt_sm,
            "hypot_sm": hypot_sm,
            "sign_sm": sign_sm,
            "complex_not_sm": complex_not_sm,
            "int_sm_cx": int_sm_cx,
            "frac_sm_cx": frac_sm_cx,
            "round_sm_cx": round_sm_cx,
            "floor_sm_cx": floor_sm_cx,
            "ceil_sm_cx": ceil_sm_cx,
            "real_sm": real_sm,
            "imag_sm": imag_sm,
            "conj_sm": conj_sm,
            "phase_sm": phase_sm,
            "polar_sm": polar_sm,
            "cart_sm": cart_sm,
            "sin": _map_unary_cx(cmath.sin),
            "cos": _map_unary_cx(cmath.cos),
            "tan": _map_unary_cx(cmath.tan),
            "asin": _map_unary_cx(cmath.asin),
            "acos": _map_unary_cx(cmath.acos),
            "atan": _map_unary_cx(cmath.atan),
            "sinh": _map_unary_cx(cmath.sinh),
            "cosh": _map_unary_cx(cmath.cosh),
            "tanh": _map_unary_cx(cmath.tanh),
            "asinh": _map_unary_cx(cmath.asinh),
            "acosh": _map_unary_cx(cmath.acosh),
            "atanh": _map_unary_cx(cmath.atanh),
            "exp": _map_unary_cx(cmath.exp),
            "abs": _map_unary_cx(abs),
            "hex_sm": hex_sm,
            "bin_sm": bin_sm,
            "oct_sm": oct_sm,
            "uhex_sm": uhex_sm,
            "uoct_sm": uoct_sm,
            "ubin_sm": ubin_sm,
            "sqrt": _map_unary_cx(sqrt_sm),
            "hypot": hypot_sm,
            "atan2": atan2_sm_cx,
            "deg_sm": deg_sm_cx,
            "rad_sm": rad_sm_cx,
        }
    )
    return ns


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


def ref_eval(
    expr: str, ns: dict, *, mode: str = "real", expected_hint: str = ""
) -> Any:
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
        e = _preprocess_complex_dsl(e)
    elif mode == "time":
        e = _preprocess_time_expression(e)
    else:
        e = _preprocess_real_dsl(e)
        e = _preprocess_hex_for_numeric_add(e, expected_hint)
    e = _implicit_mul(e)
    t = _translate_functions(e, mode=mode)
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
    if mode in ("real", "time", "complex"):
        body = _SmokeAstTransform(mode).visit(node.body)
        ast.fix_missing_locations(body)
        node = ast.Expression(body=body)
    return eval(compile(node, "<smoke>", "eval"), {"__builtins__": {}}, ns)


def ref_format(v: Any, *, mode: str = "real") -> str:
    if isinstance(v, Duration):
        return duration_format_ms(v.ms)
    if isinstance(v, str):
        return v
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
        return f"({inner})".replace(", ", ",").replace("( ", "(")
    return str(v)


def try_reference(
    expr_chain: str, *, mode: str = "real", expected_hint: str = ""
) -> tuple[Optional[Any], Optional[str]]:
    """Evaluate semicolon chain; last statement value is result."""
    parts = _split_statements(expr_chain)
    if mode == "time":
        ns: dict = build_ns_time(None)
    elif mode == "complex":
        ns = build_ns_complex(None)
    else:
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
                    last = ref_eval(rhs, ns, mode=mode, expected_hint=expected_hint)
                    ns[name] = last
                    ns["ans"] = last
                    continue
            last = ref_eval(part, ns, mode=mode, expected_hint=expected_hint)
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
    if case.get("assert_kind"):
        return None
    if case.get("expect_no_result"):
        return "expectNoResult"
    if case.get("expected_err"):
        return "expected error path"
    ex_raw = case["expr"]
    ex = _strip_line_comment(ex_raw)
    is_co = case.get("source") == "complex_opt"
    src = case.get("source", "")
    if case.get("expect_error"):
        if src == "magnitude_band":
            return "magnitude-band parser error probe"
        if is_co and (ex.strip() in ("10+5i",) or "cart((5,1))" in ex):
            return "complex support disabled (not modeled in Python reference)"
        if is_co and re.search(r"\bhex\s*\([^)]*\.", ex, re.I):
            return "hex() fractional complex part (parser-specific error text)"
        return None

    if ex.strip() == "ans" and ";" not in ex:
        return "standalone ans (no prior statement in harness)"

    exp = case.get("expected", "").strip()
    if re.fullmatch(r"-?\d+/\d+", exp) or (
        exp.count("/") == 1 and not exp.startswith("(") and "ratio" in ex
    ):
        return "ratio fraction string"

    fmt_m = re.search(r"\b(uhex|uoct|ubin)\s*\(", ex, re.I)
    if fmt_m and not is_co:
        return "unsigned formatting builtin (display-only)"
    if not is_co and ("sort(" in ex or "unique(" in ex or "sortby(" in ex):
        return "sort/unique/sortby"
    if "unpack(" in ex or "reverse(" in ex:
        return "array DSL builtin (unpack/reverse)"
    if "ratio(" in ex and src != "complex_opt":
        return "ratio() builtin"

    last = _last_statement(ex_raw)
    if re.fullmatch(r"(rad|deg|hex|bin|oct|uhex|uoct|ubin)\b(\(\))?", last.strip(), flags=re.I):
        return "trailing formatter command (DSL)"

    if ";" in ex:
        if re.search(r"\b[a-z_][a-z0-9_]*\s*[\+\-\*/]\s*[a-z_][a-z0-9_]*\s*$", last):
            return "broadcast / element-wise array algebra (DSL)"

    if re.search(r"\b[a-z_][a-z0-9_]*\s*\([^)]*\)\s*=", ex, re.I) and "rd(t)=" not in ex:
        if src not in ("inline_probe",):
            return "user-defined function"
    if re.search(r"\by\s*\(", ex) or (
        re.search(r"\bf\s*\(", ex) and "f=x:" not in ex and "f=(" not in ex
    ):
        return "user-defined function (y(a)=...)"

    if re.search(r"\(e=3\)|\(pi\s*=", ex):
        return "assignment-in-parens truth (DSL scalar vs tuple)"
    if re.search(r"a\s*=\s*\([^)]+\)\s*[\+\-\*]", ex) and re.search(
        r"hex\s*\(\s*a\s*\[", ex, re.I
    ):
        return "tuple broadcast + hex(index) (DSL)"
    if re.search(r"mod\s*\(\s*a\s*\[", ex, re.I):
        return "mod on broadcast array element (DSL)"
    if re.search(r"0x[fF]{8,}|1844674407370955161", ex) and (
        "%" in ex or "mod(" in ex
    ):
        return "uint64-scale mod (exact uint64 not in float reference)"
    if src == "magnitude_band" and re.search(r"2\*\*100", ex):
        return "magnitude-band 2**100 (exact wide int; float reference)"
    if src == "magnitude_band" and re.search(r"2\*\*64", ex):
        if re.search(r"\b(conj|pow)\s*\(", ex, re.I):
            return "magnitude-band 2**64 float overflow"
        if re.search(r"\b(sqrt|ln)\s*\(\s*\(\s*-\s*\(\s*2\*\*64", ex, re.I):
            return "complex sqrt/ln(-2**64) branch cut"
    if src == "magnitude_band" and re.search(
        r"4611686018427387904|9223372036854775808", ex
    ):
        if "mod(" in ex or "<<" in ex or ">>" in ex:
            return "magnitude-band int64 edge (exact wide int)"
    if is_co and re.search(r"inf\s*\+\s*i\s*\*\s*inf", ex, re.I):
        return "complex inf*i*inf formatting (non-associative product)"
    if re.search(r"(-?\s*inf)\s*\*\*", ex, re.I) and src == "magnitude_band":
        return "inf**n edge (real band)"
    if re.search(r"pow\s*\(\s*-?\s*inf", ex, re.I) and src in (
        "magnitude_band",
        "inline_probe",
    ):
        return "complex pow(inf) edge"
    if re.search(r"(sqrt|ln)\s*\(\s*-?\s*inf", ex, re.I) and src in (
        "magnitude_band",
        "inline_probe",
    ):
        return "complex sqrt/ln(inf) edge"
    if re.search(r"inf\s*\+\s*i\s*\*", ex, re.I) and "inf" in ex.lower():
        return "complex inf*i product formatting"
    if re.search(r"t=3;\s*\(t=3\)", ex):
        return "assignment-in-parens truth (DSL scalar vs tuple)"
    if re.search(r"a=2\*\(3,4\)", ex) and "hex(a[" in ex:
        return "scalar-times-tuple broadcast hex (DSL)"

    return None


def main() -> int:
    root = __file__.rsplit("\\", 1)[0]
    if "/" in root and "\\" not in root:
        root = __file__.rsplit("/", 1)[0]
    bas = root + "/../SmokeTest_MathParser.bas"
    band = root + "/neg_band_cases_generated.bas"
    if len(sys.argv) > 1:
        bas = sys.argv[1]
    if len(sys.argv) > 2:
        band = sys.argv[2]

    cases = collect_all_numeric_cases(bas, band)
    mismatches: list[str] = []
    skipped: list[str] = []
    ok = 0
    n_complex = 0
    n_complex_opt_compared_ok = 0
    n_complex_opt_parsed = sum(
        1 for c in cases if c.get("source") in ("complex_opt", "raw_api")
    )
    n_complex_opt_skip_should = 0
    n_complex_opt_skip_eval = 0
    n_complex_opt_error_ok = 0
    n_complex_opt_error_fail = 0
    n_time = 0
    n_assert_ok = 0
    n_band = sum(1 for c in cases if c.get("source") == "magnitude_band")

    for case in cases:
        idx = case["idx"]
        if (
            "expected" not in case
            and not case.get("expect_error")
            and not case.get("assert_kind")
        ):
            continue
        reason = should_skip_case(case)
        if reason:
            skipped.append(f"#{idx}: {reason}")
            if case.get("source") == "complex_opt":
                n_complex_opt_skip_should += 1
            continue
        is_co = case.get("source") == "complex_opt"
        mode = case.get("ref_mode") or infer_ref_mode(
            case["expr"], case.get("expected", "")
        )

        if case.get("expect_error"):
            if mode == "complex":
                n_complex += 1
            val, err = try_reference(
                case["expr"],
                mode=mode,
                expected_hint=case.get("expected", ""),
            )
            if err:
                substr = case.get("expected_err_substr")
                if substr and substr.lower() not in err.lower():
                    mismatches.append(
                        f"#{idx} expr={case['expr']!r}\n  expected err contains {substr!r}, got {err!r}\n"
                    )
                    if is_co:
                        n_complex_opt_error_fail += 1
                else:
                    ok += 1
                    if is_co:
                        n_complex_opt_error_ok += 1
            else:
                got = ref_format(val, mode=mode).strip()
                mismatches.append(
                    f"#{idx} expr={case['expr']!r}\n  expected error, ref_python={got!r}\n"
                )
                if is_co:
                    n_complex_opt_error_fail += 1
            continue

        assert_kind = case.get("assert_kind")
        exp_hint = case.get("expected", "")
        val, err = try_reference(
            case["expr"], mode=mode, expected_hint=exp_hint
        )
        if err:
            skipped.append(f"#{idx}: eval failed ({err[:80]})")
            if is_co:
                n_complex_opt_skip_eval += 1
            continue

        if assert_kind == "abs_gt":
            thr = float(case.get("assert_threshold", 1e-6))
            try:
                mag = _real_scalar_mag(val)
            except TypeError:
                skipped.append(f"#{idx}: non-scalar magnitude assert")
                continue
            if mag >= thr:
                ok += 1
                n_assert_ok += 1
            else:
                mismatches.append(
                    f"#{idx} expr={case['expr']!r}\n  expected |result| >= {thr}, got |{mag}|\n"
                )
            continue
        if assert_kind == "abs_lt":
            thr = float(case.get("assert_threshold", 1e-9))
            try:
                mag = _real_scalar_mag(val)
            except TypeError:
                skipped.append(f"#{idx}: non-scalar magnitude assert")
                continue
            if mag < thr:
                ok += 1
                n_assert_ok += 1
            else:
                mismatches.append(
                    f"#{idx} expr={case['expr']!r}\n  expected |result| < {thr}, got |{mag}|\n"
                )
            continue

        exp = case["expected"].strip()
        if mode == "complex":
            n_complex += 1
        elif mode == "time":
            n_time += 1
        got = ref_format(val, mode=mode).strip()
        if results_match(exp, got, mode=mode):
            ok += 1
            if is_co:
                n_complex_opt_compared_ok += 1
            continue
        mismatches.append(
            f"#{idx} expr={case['expr']!r}\n  expected(smoke)={exp!r}\n  ref_python  ={got!r}\n"
        )

    print("=== Smoke expected vs Python reference ===")
    n_exp = sum(
        1
        for c in cases
        if "expected" in c or c.get("assert_kind") or c.get("expect_error")
    )
    print(f"Cases parsed (numeric / assert / error): {n_exp}  (magnitude-band rows: {n_band})")
    n_raw_api = sum(1 for c in cases if c.get("source") == "raw_api")
    print(
        f"Option/raw subs: parsed {n_complex_opt_parsed} rows from complex-opt + raw API "
        f"({n_complex_opt_compared_ok} numeric OK, {n_complex_opt_error_ok} error probes OK); "
        f"{n_complex_opt_skip_should} skipped (DSL/display), "
        f"{n_complex_opt_skip_eval} eval-failed in Python stub, "
        f"{n_complex_opt_error_fail} error-probe mismatches "
        f"(raw_api rows: {n_raw_api})."
    )
    print(
        f"Compared OK (real/complex/time reference, tol rules): {ok}  "
        f"(complex-mode eval rows: {n_complex}, time-mode: {n_time}, "
        f"magnitude asserts: {n_assert_ok})"
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
