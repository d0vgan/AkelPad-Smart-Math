"""Build the SmartMath web calculator (GitHub Pages site).

Output folder (default: tools/_site):
  index.html, app.js, style.css   copied from tools/web/
  smartmath.js, smartmath.wasm    cpp/calc_wasm.cpp + the C++ MathParser, built with Emscripten (emcc)
  help.html                       USAGE_AND_SYNTAX.md converted with pandoc
                                  (the AkelPad-only "SmartMath Options" section is omitted)

Usage:
  python tools/build_web.py [--out DIR] [--no-help] [--tests]

--tests also builds cpp/Tests_MathParser.cpp with Emscripten and runs it with Node.js,
so the WebAssembly build of the parser is checked against the same tests as the MSVC build.
em++, pandoc and node are looked up on PATH.
"""

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CPP = ROOT / "cpp"
WEB = Path(__file__).resolve().parent / "web"

PARSER_SOURCES = ["MathParser.cpp", "MathParserFactorInt.cpp", "MathParserRawResult.cpp"]
STATIC_FILES = ["index.html", "app.js", "style.css"]

# The parser recurses per nesting level; Emscripten's default 64 KB stack is far below MSVC's 1 MB.
COMMON_EMCC_FLAGS = ["-O2", "-sALLOW_MEMORY_GROWTH=1", "-sSTACK_SIZE=4MB"]


def tool(name):
    path = shutil.which(name)
    if path is None:
        sys.exit(f"error: '{name}' was not found on PATH")
    return path


def run(args):
    print("+ " + " ".join(str(a) for a in args), flush=True)
    subprocess.run([str(a) for a in args], check=True)


def build_wasm(out_dir):
    sources = [CPP / "calc_wasm.cpp"] + [CPP / s for s in PARSER_SOURCES]
    run([tool("em++"), "-std=c++17", *COMMON_EMCC_FLAGS, "-lembind",
         "-sMODULARIZE=1", "-sEXPORT_ES6=1", "-sEXPORT_NAME=createSmartMath",
         "-sENVIRONMENT=web",
         *sources, "-o", out_dir / "smartmath.js"])


def markdown_for_web_help():
    text = (ROOT / "USAGE_AND_SYNTAX.md").read_text(encoding="utf-8")
    marker = "\n## SmartMath Options\n"
    cut = text.find(marker)
    if cut < 0:
        sys.exit("error: USAGE_AND_SYNTAX.md is missing the '## SmartMath Options' section")
    return text[:cut].rstrip() + "\n"


def build_help(out_dir):
    args = [tool("pandoc"), "--from=gfm", "--to=html5", "--standalone",
            "--toc", "--toc-depth=3",
            "--template", WEB / "help-template.html",
            "--metadata", "pagetitle=SmartMath Usage and Syntax",
            "--output", out_dir / "help.html"]
    print("+ " + " ".join(str(a) for a in args), flush=True)
    subprocess.run([str(a) for a in args], input=markdown_for_web_help(),
                   text=True, encoding="utf-8", check=True)


def run_tests(build_dir):
    build_dir.mkdir(parents=True, exist_ok=True)
    test_js = build_dir / "Tests_MathParser.js"
    sources = [CPP / "Tests_MathParser.cpp"] + [CPP / s for s in PARSER_SOURCES]
    run([tool("em++"), "-std=c++14", *COMMON_EMCC_FLAGS, "-sENVIRONMENT=node",
         *sources, "-o", test_js])
    run([tool("node"), test_js])


def main():
    parser = argparse.ArgumentParser(description="Build the SmartMath web calculator.")
    parser.add_argument("--out", default=str(Path(__file__).resolve().parent / "_site"),
                        help="output folder (default: tools/_site)")
    parser.add_argument("--no-help", action="store_true", help="skip help.html (no pandoc needed)")
    parser.add_argument("--tests", action="store_true", help="also build and run the C++ tests under Node.js")
    args = parser.parse_args()

    out_dir = Path(args.out).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    for name in STATIC_FILES:
        shutil.copy2(WEB / name, out_dir / name)
    (out_dir / ".nojekyll").write_text("", encoding="utf-8")
    build_wasm(out_dir)
    if not args.no_help:
        build_help(out_dir)
    if args.tests:
        run_tests(ROOT / "_build" / "wasm-tests")
    print(f"Done: {out_dir}")


if __name__ == "__main__":
    main()
