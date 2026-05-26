#!/usr/bin/env python3
"""Generate positive/negative argument magnitude band cases using MathParserTests --eval."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

try:
    from verify_smoke_expected_vs_python import ref_format, try_reference
except ImportError:
    ref_format = None  # type: ignore
    try_reference = None  # type: ignore
EXE_CPP = ROOT / "cpp" / "MathParserTests.exe"
EXE_BAS = ROOT / "tools" / "NegBandProbe.exe"


def eval_expr(expr: str, complex_mode: bool = False) -> tuple[str, bool]:
    # Prefer Basic NegBandProbe (smoke tests Basic); fall back to C++ --eval.
    if EXE_BAS.is_file():
        bas_args = [str(EXE_BAS)]
        if complex_mode:
            bas_args.append("--complex")
        bas_args.append(expr)
        try:
            bas_proc = subprocess.run(bas_args, capture_output=True, text=True, cwd=ROOT, timeout=30)
            bas_out = (bas_proc.stdout or "").strip()
            if bas_proc.returncode == 0 and bas_out:
                return bas_out, True
        except (OSError, subprocess.TimeoutExpired):
            pass
    args = [str(EXE_CPP), "--eval"]
    if complex_mode:
        args.append("--complex")
    args.append(expr)
    proc = subprocess.run(args, capture_output=True, text=True, cwd=ROOT / "cpp")
    out = (proc.stdout or "").strip()
    if proc.returncode != 0:
        if out.startswith("ERROR:"):
            return out[6:].strip(), False
        err = (proc.stderr or "").strip()
        return err or out or f"exit {proc.returncode}", False
    return out, True


def band_values(sign: str) -> list[tuple[str, str]]:
    if sign == "neg":
        return [
            ("A_lo", "-1"),
            ("A_mid", "-125"),
            ("A_hi", "-9007199254740992"),  # -2^53
            ("B_lo", "-18014398509481984"),  # -2^54
            ("B_mid", "-4611686018427387904"),  # -2^62
            ("B_hi", "-9223372036854775808"),  # -2^63
            ("C_lo", "-(2**64)"),
            ("C_mid", "-(2**100)"),
            ("C_hi", "-inf"),
        ]
    return [
        ("A_lo", "1"),
        ("A_mid", "125"),
        ("A_hi", "9007199254740992"),  # 2^53
        ("B_lo", "18014398509481984"),  # 2^54
        ("B_mid", "4611686018427387904"),  # 2^62
        ("B_hi", "9223372036854775808"),  # 2^63
        ("C_lo", "2**64"),
        ("C_mid", "2**100"),
        ("C_hi", "inf"),
    ]


def real_probes(v: str, sign: str) -> list[tuple[str, str]]:
    gcd_b = "-50" if sign == "neg" else "50"
    return [
        ("unary_neg", f"-({v})"),
        ("abs", f"abs({v})"),
        ("sign", f"sign({v})"),
        ("add1", f"{v}+1"),
        ("sub1", f"{v}-1"),
        ("mul2", f"{v}*2"),
        ("div2", f"{v}/2"),
        ("pow2", f"{v}**2"),
        ("pow_fn", f"pow({v},2)"),
        ("sqr", f"sqr({v})"),
        ("cmp_lt0", f"{v}<0"),
        ("cmp_eq", f"{v}=={v}"),
        ("hex", f"hex({v})"),
        ("uhex", f"uhex({v})"),
        ("int_cast", f"int({v})"),
        ("floor", f"floor({v})"),
        ("ceil", f"ceil({v})"),
        ("round", f"round({v})"),
        ("gcd", f"gcd({v},{gcd_b})"),
        ("mod", f"mod({v},7)"),
        ("hypot", f"hypot({v},3)"),
        ("max", f"max({v},0)"),
        ("min", f"min({v},0)"),
        ("bit_and1", f"{v}&1"),
        ("bit_or0", f"{v}|0"),
        ("bit_xor0", f"{v}^0"),
        ("shl1", f"{v}<<1"),
        ("shr1", f"{v}>>1"),
        ("sqrt", f"sqrt({v})"),
        ("ln", f"ln({v})"),
        ("not", f"not({v})"),
        ("udf_add1", f"f(x)=x+1; f({v})"),
        ("udf_abs", f"g(x)=abs(x); g({v})"),
        ("udf_neg", f"h(x)=-x; h({v})"),
    ]


def complex_probes(z: str) -> list[tuple[str, str]]:
    return [
        ("cx_abs", f"abs({z})"),
        ("cx_real", f"real({z})"),
        ("cx_imag", f"imag({z})"),
        ("cx_conj", f"conj({z})"),
        ("cx_add1", f"{z}+1"),
        ("cx_sub1", f"{z}-1"),
        ("cx_mul2", f"{z}*2"),
        ("cx_div2", f"{z}/2"),
        ("cx_pow2", f"{z}**2"),
        ("cx_pow_fn", f"pow({z},2)"),
        ("cx_sqr", f"sqr({z})"),
        ("cx_sqrt", f"sqrt({z})"),
        ("cx_hypot", f"hypot({z},3)"),
        ("cx_ln", f"ln({z})"),
        ("cx_udf", f"f(z)=z+1; f({z})"),
    ]


def complex_literal(v: str, sign: str) -> str:
    if v in ("-inf", "inf"):
        return v
    return f"({v})"


def complex_literal_re_im(re: str, im: str) -> str:
    if im in ("0", "0.0", "-0", "-0.0"):
        return re
    im_f = float(im) if im not in ("inf", "-inf", "nan") else None
    if im_f is not None and im_f < 0:
        mag = im[1:] if im.startswith("-") else im
        if mag in ("inf",):
            return f"{re}-inf*i"
        return f"{re}-{mag}*i" if "*" not in mag else f"{re}-{mag}"
    if im in ("inf",):
        return f"{re}+inf*i"
    if im in ("nan",):
        return f"{re}+nan*i"
    return f"{re}+{im}*i"


def float_band_values() -> list[tuple[str, str]]:
    return [
        ("D_float_hi", "1.123e+20"),
        ("D_float_lo", "1.123e-20"),
        ("D_extreme_hi", "1.123e+197"),
        ("D_extreme_lo", "1.123e-197"),
    ]


def complex_re_im_grid() -> list[tuple[str, str, str]]:
    """(band_id, re, im) trimmed grid."""
    vals = ["1.123e+20", "1.123e-20", "0", "1", "-1"]
    out: list[tuple[str, str, str]] = []
    for re in vals:
        for im in vals:
            if re == "0" and im == "0":
                continue
            out.append((f"R{re}_I{im}", re, im))
    return out


def normalize_err_text(err: str) -> str:
    e = err.strip()
    while e.upper().startswith("ERR:"):
        e = e[4:].lstrip()
    if e.upper().startswith("ERROR:"):
        e = e[6:].lstrip()
    return e


def band_expect(expr: str, *, complex_mode: bool = False) -> tuple[str, bool]:
    """Parser eval (C++ --eval); errors normalized for smoke/C++ tables."""
    out, ok = eval_expr(expr, complex_mode=complex_mode)
    if ok:
        return out, True
    return normalize_err_text(out), False


def collect_rows(sign: str) -> tuple[list[tuple[str, str, str]], list[tuple[str, str, str]]]:
    real_rows: list[tuple[str, str, str]] = []
    cx_rows: list[tuple[str, str, str]] = []
    prefix = "real" if sign == "neg" else "pos/real"
    cx_prefix = "cx" if sign == "neg" else "pos/cx"

    for band_id, v in band_values(sign):
        for probe_id, expr in real_probes(v, sign):
            label = f"{prefix}/{band_id}/{probe_id}"
            result, ok = band_expect(expr, complex_mode=False)
            if ok:
                real_rows.append((label, expr, result))
            else:
                real_rows.append((label, expr, f"ERR:{normalize_err_text(result)}"))

        z = complex_literal(v, sign)
        for probe_id, expr in complex_probes(z):
            label = f"{cx_prefix}/{band_id}/{probe_id}"
            result, ok = band_expect(expr, complex_mode=True)
            if ok:
                cx_rows.append((label, expr, result))
            else:
                cx_rows.append((label, expr, f"ERR:{normalize_err_text(result)}"))

    for band_id, v in float_band_values():
        for probe_id, expr in real_probes(v, sign):
            label = f"{prefix}/float/{band_id}/{probe_id}"
            result, ok = band_expect(expr, complex_mode=False)
            if ok:
                real_rows.append((label, expr, result))
            else:
                real_rows.append((label, expr, f"ERR:{normalize_err_text(result)}"))

    cx_mix_probes = [
        ("cx_abs", "abs({z})"),
        ("cx_real", "real({z})"),
        ("cx_imag", "imag({z})"),
        ("cx_conj", "conj({z})"),
        ("cx_add1", "{z}+1"),
        ("cx_mul2", "{z}*2"),
        ("cx_div2", "{z}/2"),
    ]
    for band_id, re, im in complex_re_im_grid():
        z = complex_literal_re_im(re, im)
        for probe_id, tmpl in cx_mix_probes:
            expr = tmpl.format(z=z)
            label = f"{cx_prefix}/mix/{band_id}/{probe_id}"
            result, ok = band_expect(expr, complex_mode=True)
            if ok:
                cx_rows.append((label, expr, result))
            else:
                cx_rows.append((label, expr, f"ERR:{normalize_err_text(result)}"))

    return real_rows, cx_rows


def esc(s: str) -> str:
    return s.replace('"', '""')


def write_bas_rows(
    f,
    count_name: str,
    label_prefix: str,
    expr_prefix: str,
    expect_prefix: str,
    err_prefix: str,
    is_err_prefix: str,
    rows: list[tuple[str, str, str]],
) -> None:
    f.write(f"const {count_name} = {len(rows)}\n")
    f.write(f"dim shared {label_prefix}(1 to {count_name}) as String\n")
    f.write(f"dim shared {expr_prefix}(1 to {count_name}) as String\n")
    f.write(f"dim shared {expect_prefix}(1 to {count_name}) as String\n")
    f.write(f"dim shared {err_prefix}(1 to {count_name}) as String\n")
    f.write(f"dim shared {is_err_prefix}(1 to {count_name}) as Boolean\n")
    for i, (label, expr, expect) in enumerate(rows, 1):
        f.write(f'{label_prefix}({i}) = "{esc(label)}"\n')
        f.write(f'{expr_prefix}({i}) = "{esc(expr)}"\n')
        if expect.startswith("ERR:"):
            f.write(f'{err_prefix}({i}) = "{esc(expect[4:])}"\n')
            f.write(f"{is_err_prefix}({i}) = TRUE\n")
        else:
            f.write(f'{expect_prefix}({i}) = "{esc(expect)}"\n')
            f.write(f"{is_err_prefix}({i}) = FALSE\n")
    f.write("\n")


def write_cpp_rows(path: Path, rows: list[tuple[str, str, str]]) -> None:
    with path.open("w", encoding="utf-8", newline="\n") as f:
        f.write("// AUTO-GENERATED by tools/gen_neg_band_cases.py\n")
        for label, expr, expect in rows:
            el = expr.replace("\\", "\\\\").replace('"', '\\"')
            if expect.startswith("ERR:"):
                ee = expect[4:].replace("\\", "\\\\").replace('"', '\\"')
                f.write(f'    {{"{label}", "{el}", nullptr, "{ee}"}},\n')
            else:
                ex = expect.replace("\\", "\\\\").replace('"', '\\"')
                f.write(f'    {{"{label}", "{el}", "{ex}", nullptr}},\n')


def main() -> int:
    if not EXE_CPP.is_file():
        print(f"Build {EXE_CPP} first (cpp/BuildTests_vc2022_x64.bat)", file=sys.stderr)
        return 1

    neg_real, neg_cx = collect_rows("neg")
    pos_real, pos_cx = collect_rows("pos")

    out_bas = ROOT / "tools" / "neg_band_cases_generated.bas"

    with out_bas.open("w", encoding="utf-8", newline="\n") as f:
        f.write("' AUTO-GENERATED by tools/gen_neg_band_cases.py — do not edit by hand.\n\n")
        write_bas_rows(
            f,
            "NEG_BAND_REAL_COUNT",
            "negBandRealLabel",
            "negBandRealExpr",
            "negBandRealExpect",
            "negBandRealErr",
            "negBandRealIsErr",
            neg_real,
        )
        write_bas_rows(
            f,
            "NEG_BAND_CX_COUNT",
            "negBandCxLabel",
            "negBandCxExpr",
            "negBandCxExpect",
            "negBandCxErr",
            "negBandCxIsErr",
            neg_cx,
        )
        write_bas_rows(
            f,
            "POS_BAND_REAL_COUNT",
            "posBandRealLabel",
            "posBandRealExpr",
            "posBandRealExpect",
            "posBandRealErr",
            "posBandRealIsErr",
            pos_real,
        )
        write_bas_rows(
            f,
            "POS_BAND_CX_COUNT",
            "posBandCxLabel",
            "posBandCxExpr",
            "posBandCxExpect",
            "posBandCxErr",
            "posBandCxIsErr",
            pos_cx,
        )

    write_cpp_rows(ROOT / "tools" / "neg_band_cases_generated.cpp.inc", neg_real)
    write_cpp_rows(ROOT / "tools" / "neg_band_cases_generated_cx.cpp.inc", neg_cx)
    write_cpp_rows(ROOT / "tools" / "pos_band_cases_generated.cpp.inc", pos_real)
    write_cpp_rows(ROOT / "tools" / "pos_band_cases_generated_cx.cpp.inc", pos_cx)

    print(
        f"Wrote neg {len(neg_real)} real + {len(neg_cx)} cx; "
        f"pos {len(pos_real)} real + {len(pos_cx)} cx"
    )
    print(out_bas)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
