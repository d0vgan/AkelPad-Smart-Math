param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$mathParserPath = Join-Path $RepoRoot "MathParser.bas"
$usagePath = Join-Path $RepoRoot "USAGE_AND_SYNTAX.md"

if (-not (Test-Path $mathParserPath)) {
  throw "Missing file: $mathParserPath"
}
if (-not (Test-Path $usagePath)) {
  throw "Missing file: $usagePath"
}

$mathText = [IO.File]::ReadAllText($mathParserPath)
$usageText = [IO.File]::ReadAllText($usagePath)

# Collect FB_STR_* -> literal mapping.
$constToName = @{}
$constMatches = [regex]::Matches($mathText, 'const\s+FB_STR_([A-Z0-9_]+)\s+as\s+string\s*=\s*"([^"]+)"', 'IgnoreCase')
foreach ($m in $constMatches) {
  $constToName[$m.Groups[1].Value.ToUpperInvariant()] = $m.Groups[2].Value.ToLowerInvariant()
}

# Collect FunctionNames(FUNC_*) = FB_STR_* names.
$parserNames = New-Object 'System.Collections.Generic.HashSet[string]'
$fnMatches = [regex]::Matches($mathText, 'FunctionNames\s*\(\s*FUNC_[A-Z0-9_]+\s*\)\s*=\s*FB_STR_([A-Z0-9_]+)', 'IgnoreCase')
foreach ($m in $fnMatches) {
  $constKey = $m.Groups[1].Value.ToUpperInvariant()
  if ($constToName.ContainsKey($constKey)) {
    [void]$parserNames.Add($constToName[$constKey])
  }
}

if ($parserNames.Count -eq 0) {
  throw "Failed to parse builtin function names from MathParser.bas"
}

# Extract quick-index markdown table block.
$startMarker = "Quick index (alphabetical):"
$startPos = $usageText.IndexOf($startMarker)
if ($startPos -lt 0) {
  throw "Could not find quick index marker in USAGE_AND_SYNTAX.md"
}
$tableStart = $usageText.IndexOf("| Function(s) | Category |", $startPos)
if ($tableStart -lt 0) {
  throw "Could not find quick index table header in USAGE_AND_SYNTAX.md"
}
$tableEnd = $usageText.IndexOf("`n`n### ", $tableStart)
if ($tableEnd -lt 0) {
  $tableEnd = $usageText.Length
}
$tableText = $usageText.Substring($tableStart, $tableEnd - $tableStart)

# Collect doc function names from first table column backticks.
$docNames = New-Object 'System.Collections.Generic.HashSet[string]'
$rowMatches = [regex]::Matches($tableText, '^\|\s*`([^`]+)`\s*\|', 'Multiline')
foreach ($row in $rowMatches) {
  $cell = $row.Groups[1].Value.ToLowerInvariant()
  $nameMatches = [regex]::Matches($cell, '([a-z0-9_]+)\s*(?=\(|/|$)')
  foreach ($nm in $nameMatches) {
    [void]$docNames.Add($nm.Groups[1].Value)
  }
}

if ($docNames.Count -eq 0) {
  throw "Failed to parse function names from quick index table in USAGE_AND_SYNTAX.md"
}

$missingInDocs = @($parserNames | Where-Object { -not $docNames.Contains($_) } | Sort-Object)
$unknownInDocs = @($docNames | Where-Object { -not $parserNames.Contains($_) } | Sort-Object)

if ($missingInDocs.Count -eq 0 -and $unknownInDocs.Count -eq 0) {
  Write-Host "PASS: Quick index matches parser builtin function names."
  Write-Host "Checked $($parserNames.Count) parser names and $($docNames.Count) doc names."
  exit 0
}

Write-Host "FAIL: Quick index and parser builtin names differ."
if ($missingInDocs.Count -gt 0) {
  Write-Host ""
  Write-Host "Missing in docs:"
  foreach ($n in $missingInDocs) { Write-Host "  - $n" }
}
if ($unknownInDocs.Count -gt 0) {
  Write-Host ""
  Write-Host "Unknown in docs (not in parser):"
  foreach ($n in $unknownInDocs) { Write-Host "  - $n" }
}
exit 1
