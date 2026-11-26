# Reports hard-coded numeric types, 64-bit / binary64 constants and magic thresholds that must live only in
# the type-config layer (cpp/MathParserTypes.hpp, Inc/MathParserTypes.bi).
# Usage (from anywhere):  powershell -File tools\check_type_literals.ps1 [-Strict] [-Detail]
#   default : prints per-file / per-pattern counts, exit code 0 (report only)
#   -Strict : exit code 1 when any non-allowlisted hit remains
#   -Detail : also prints every hit as file:line:text
# Allowlist: a line containing SM_FIXED_WIDTH, or a region between SM_FIXED_WIDTH_BEGIN and SM_FIXED_WIDTH_END,
# uses a width on purpose (algorithm bound to binary64 / 64-bit, libc extern block, ...). BEGIN/END must balance;
# an unbalanced marker counts as a hit (an unclosed BEGIN would silently disable the rest of the file).
# String literals are ignored while matching.
param([switch]$Strict, [switch]$Detail)

$root = Split-Path -Parent $PSScriptRoot

$cppFiles = @(
  'cpp\MathParser.cpp', 'cpp\MathParser.hpp', 'cpp\MathParserInternal.hpp',
  'cpp\MathParserFactorInt.cpp', 'cpp\MathParserRawResult.cpp',
  'cpp\calc.cpp', 'cpp\calc_wasm.cpp')
$basFiles = @(
  'MathParser.bas', 'MathParserFactorInt.bas', 'MathParserRawResult.bas',
  'Inc\MathParser.bi', 'Inc\MathParserRawResult.bi',
  'SmartMath_Format.bas', 'SmartMath.bas', 'SmartMath_Globals.bi', 'tools\calc.bas')

$cppPatterns = [ordered]@{
  'double'          = '\bdouble\b'
  'long double'     = '\blong\s+double\b'
  'long long'       = '\blong\s+long\b'
  'u/int64_t'       = '\bu?int64_t\b'
  '__int64'         = '__int64'
  'LL/ULL suffix'   = '\b\d+[uU]?[lL]{2}\b'
  '1ull<<N'         = '\b1(ull|ULL)\s*<<'
  'ldexp(1,N)'      = 'ldexp\(\s*1\.0\s*,'
  'llround/strtoll' = '\b(llround|lround|strtoll|strtoull|stoll|stoull|atoll)\b'
  'strtod/strtof'   = '\b(strtod|strtof|strtold)\b'
  '%lld format'     = '%[-0-9.]*ll[du]'
  '2^53 literal'    = '9007199254740992'
  '2^63/2^64 lit'   = '922337203685477|1844674407370955'
  'all-F hex mask'  = '\b0[xX][fF]{8,}'
  '1eN literal'     = '\b\d+(\.\d+)?[eE][+-]?\d+\b'
}
$basPatterns = [ordered]@{
  'Double'          = '\bDouble\b'
  'Single'          = '\bSingle\b'
  'LongInt'         = '\bLongInt\b'
  'ULongInt'        = '\bULongInt\b'
  'CLngInt'         = '\bC(U)?LngInt\b'
  'CDbl/CSng/CLng'  = '\bC(Dbl|Sng|Lng|ULng)\b'
  'LL/ULL suffix'   = '\b\d+(ull|ll)\b'
  '2^53 literal'    = '9007199254740992'
  '2^63/2^64 lit'   = '922337203685477|1844674407370955'
  'all-F hex mask'  = '&h[fF]{8,}'
  '1eN literal'     = '\b\d+(\.\d+)?e[+-]?\d+\b'
}

$total = 0
function Scan($files, $patterns, $commentPrefix, $ignoreCase) {
  foreach ($rel in $files) {
    $path = Join-Path $root $rel
    if (-not (Test-Path $path)) { continue }
    $lines = Get-Content $path
    $counts = [ordered]@{}
    $inFixed = $false
    $beginLine = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
      $t = $lines[$i].TrimStart()
      # Regions/lines marked SM_FIXED_WIDTH use a width on purpose (algorithm bound to binary64 / 64-bit).
      $problem = $null
      if ($lines[$i] -match "SM_FIXED_WIDTH_BEGIN") {
        if ($inFixed) { $problem = "nested SM_FIXED_WIDTH_BEGIN (previous one opened at line $beginLine)" }
        $inFixed = $true; $beginLine = $i + 1
      } elseif ($lines[$i] -match "SM_FIXED_WIDTH_END") {
        if (-not $inFixed) { $problem = "SM_FIXED_WIDTH_END without BEGIN" }
        $inFixed = $false
      }
      if ($problem) {
        if (-not $counts.Contains('unbalanced marker')) { $counts['unbalanced marker'] = 0 }
        $counts['unbalanced marker']++
        $script:total++
        "{0}:{1}: [unbalanced marker] {2}" -f $rel, ($i + 1), $problem
        continue
      }
      if ($lines[$i] -match "SM_FIXED_WIDTH") { continue }
      if ($inFixed) { continue }
      if ($t.StartsWith($commentPrefix)) { continue }
      $code = [regex]::Replace($lines[$i], '"[^"]*"', '""')
      foreach ($k in $patterns.Keys) {
        $hit = if ($ignoreCase) { $code -match $patterns[$k] } else { $code -cmatch $patterns[$k] }
        if ($hit) {
          if (-not $counts.Contains($k)) { $counts[$k] = 0 }
          $counts[$k]++
          $script:total++
          if ($Detail) { "{0}:{1}: [{2}] {3}" -f $rel, ($i + 1), $k, $lines[$i].Trim() }
        }
      }
    }
    if ($inFixed) {
      if (-not $counts.Contains('unbalanced marker')) { $counts['unbalanced marker'] = 0 }
      $counts['unbalanced marker']++
      $script:total++
      "{0}:{1}: [unbalanced marker] SM_FIXED_WIDTH_BEGIN never closed" -f $rel, $beginLine
    }
    if ($counts.Count -gt 0) {
      $s = ($counts.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', '
      "{0,-34} {1}" -f $rel, $s
    }
  }
}

Scan $cppFiles $cppPatterns '//' $false
Scan $basFiles $basPatterns "'" $true
"TOTAL hits outside the config layer: $total"
if ($Strict -and $total -gt 0) { exit 1 }
exit 0
