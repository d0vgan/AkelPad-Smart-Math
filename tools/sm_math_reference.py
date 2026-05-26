#!/usr/bin/env python3
"""Reference evaluation helpers for Smart Math test generation (Python/math, not parser output)."""

from __future__ import annotations

import cmath
import math
import re
from typing import Any, Optional, Union

Number = Union[int, float, complex]

EPS = 2.2204460492503131e-16

# Duration model (ms) — aligned with tools/verify_smoke_expected_vs_python.py
_MS = 1
_SECOND_MS = 1000
_MINUTE_MS = 60 * _SECOND_MS
_HOUR_MS = 60 * _MINUTE_MS
_DAY_MS = 24 * _HOUR_MS


def duration_format_ms(ms: float) -> str:
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
    ss = rem_ms / _SECOND_MS
    if abs(ss) < 1e-6:
        return f"{sign}{dd}:{hh:02d}:{mm:02d}"
    if abs(ss - round(ss)) < 1e-6:
        return f"{sign}{dd}:{hh:02d}:{mm:02d}:{int(round(ss)):02d}"
    return f"{sign}{dd}:{hh:02d}:{mm:02d}:{ss:06.3f}".rstrip("0").rstrip(".")


def _dur_parse_colon(lit: str) -> float:
    parts = lit.split(":")
    if len(parts) == 2:
        mm, ss = parts
        return (int(mm) * 60 + float(ss)) * _SECOND_MS
    if len(parts) == 3:
        a, b, c = parts
        if int(a) >= 24 or (int(a) < 24 and int(b) < 60 and float(c) < 60):
            return (int(a) * 3600 + int(b) * 60 + float(c)) * _SECOND_MS
        return (int(a) * 60 + int(b) + float(c) / 1000.0) * _SECOND_MS  # fallback
    if len(parts) == 4:
        d, h, m, s = parts
        return (int(d) * _DAY_MS + int(h) * _HOUR_MS + int(m) * _MINUTE_MS + float(s) * _SECOND_MS)
    raise ValueError(lit)


def _dur_parse_compact(s: str) -> float:
    ms = 0.0
    i = 0
    while i < len(s):
        m = re.match(r"(-?\d+(?:\.\d+)?)(ms|[dhms])", s[i:])
        if not m:
            break
        v = float(m.group(1))
        u = m.group(2)
        if u == "d":
            ms += v * _DAY_MS
        elif u == "h":
            ms += v * _HOUR_MS
        elif u == "m":
            ms += v * _MINUTE_MS
        elif u == "s":
            ms += v * _SECOND_MS
        elif u == "ms":
            ms += v
        i += m.end()
    return ms


def format_scalar(v: float) -> str:
    if math.isnan(v):
        return "nan"
    if math.isinf(v):
        return "inf" if v > 0 else "-inf"
    if v == 0.0 and math.copysign(1.0, v) < 0:
        return "-0"
    if v == 0.0:
        return "0"
    if abs(v - round(v)) < 1e-12 and abs(v) < 1e15:
        return str(int(round(v)))
    av = abs(v)
    if av >= 1e15 or (av > 0 and av < 1e-6):
        return f"{v:.17g}".replace("e+", "e").replace("e0", "e")
    s = f"{v:.15g}"
    if "e" in s.lower():
        return s
    if "." not in s and "e" not in s.lower():
        return s
    return s


def format_complex(z: complex) -> str:
    if math.isnan(z.real) and math.isnan(z.imag):
        return "nan"
    if math.isinf(z.real) or math.isinf(z.imag) or math.isnan(z.real) or math.isnan(z.imag):
        re_s = format_scalar(z.real) if not (z.real == 0 and not math.isnan(z.real) and not math.isinf(z.real)) else "0"
        if z.imag == 0 and not math.isnan(z.imag) and not math.isinf(z.imag):
            return re_s
        im_abs = format_scalar(abs(z.imag)) if z.imag != 0 else "0"
        if z.imag < 0:
            return f"{re_s}-{im_abs}i" if im_abs != "0" else re_s
        if z.imag > 0:
            return f"{re_s}+{im_abs}i"
        return re_s
    re_part = z.real
    im_part = z.imag
    if abs(im_part) < 1e-15:
        return format_scalar(re_part)
    re_s = format_scalar(re_part)
    im_mag = abs(im_part)
    im_s = format_scalar(im_mag)
    if im_part > 0:
        return f"{re_s}+{im_s}i"
    return f"{re_s}-{im_s}i"


def real_pow(base: float, exp: float) -> float:
    """Real pow with odd-integer root preference when inverse checks out."""
    if math.isfinite(base) and math.isfinite(exp):
        if base < 0 and abs(exp - round(exp)) < 1e-12:
            n = int(round(exp))
            if n % 2 == 1:
                root = round((-base) ** (1.0 / n))
                if root ** n == -base or abs(root ** n + base) < 1e-6 * max(1.0, abs(base)):
                    return -root if n % 2 == 1 else root
        try:
            return float(base**exp)
        except Exception:
            return float("nan")
    return float(base**exp)


def eval_real_expr(expr: str) -> tuple[Optional[str], Optional[str]]:
    """Evaluate a small real subset; return (ok_string, err_substring)."""
    e = expr.strip()
    try:
        if e in ("nan", "+nan", "-nan"):
            return "nan", None
        if e in ("inf", "+inf"):
            return "inf", None
        if e == "-inf":
            return "-inf", None
        # Simple binary/unary patterns
        m = re.fullmatch(r"(-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?)\s*\+\s*0", e)
        if m:
            return format_scalar(float(m.group(1))), None
        m = re.fullmatch(r"abs\((.+)\)", e)
        if m:
            v = _eval_atom(m.group(1))
            return format_scalar(abs(v)), None
        m = re.fullmatch(r"sign\((.+)\)", e)
        if m:
            v = _eval_atom(m.group(1))
            if math.isnan(v):
                return "0", None
            if v > 0:
                return "1", None
            if v < 0:
                return "-1", None
            return "0", None
        m = re.fullmatch(r"ln\((.+)\)", e)
        if m:
            v = _eval_atom(m.group(1))
            if v == 0:
                return "-inf", None
            if v < 0:
                return None, "domain"
            return format_scalar(math.log(v)), None
        m = re.fullmatch(r"(.+)\s*==\s*(.+)", e)
        if m:
            a, b = _eval_atom(m.group(1)), _eval_atom(m.group(2))
            if math.isnan(a) or math.isnan(b):
                return "0", None
            return ("1" if a == b else "0"), None
        for op, fn in (("+", lambda a, b: a + b), ("-", lambda a, b: a - b), ("*", lambda a, b: a * b), ("/", lambda a, b: a / b)):
            parts = e.split(op)
            if len(parts) == 2 and op in e:
                a, b = _eval_atom(parts[0]), _eval_atom(parts[1])
                return format_scalar(fn(a, b)), None
        m = re.fullmatch(r"(.+)\*\*(.+)", e)
        if m:
            a, b = _eval_atom(m.group(1)), _eval_atom(m.group(2))
            return format_scalar(real_pow(a, b)), None
        return format_scalar(_eval_atom(e)), None
    except Exception as ex:
        return None, str(ex)


def _eval_atom(s: str) -> float:
    s = s.strip()
    if s in ("nan",):
        return float("nan")
    if s in ("inf", "+inf"):
        return float("inf")
    if s == "-inf":
        return float("-inf")
    if s.startswith("(") and s.endswith(")"):
        return _eval_atom(s[1:-1])
    return float(s)


def eval_complex_expr(expr: str) -> tuple[Optional[str], Optional[str]]:
  try:
    py = expr.replace("**", "**").replace("i", "j").replace("I", "j")
    # Smart Math: 2-3*i -> 2-3j
    z = eval(py, {"__builtins__": {}}, {"j": 1j, "cmath": cmath, "math": math})
    if isinstance(z, complex):
      return format_complex(z), None
    return format_scalar(float(z)), None
  except Exception as ex:
    return None, str(ex)
