# Verifies that relative Markdown links resolve to files in the repository.
#
# Run from the repository root: .\scripts\check-docs-links.ps1
[CmdletBinding()]
param(
  [string]$Root = ''
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($Root)) {
  $Root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
}

$markdownFiles = Get-ChildItem -LiteralPath $Root -Recurse -File -Filter '*.md' |
  Where-Object { $_.FullName -notmatch '[\\/](build|dist|\.git)[\\/]' }

$broken = [System.Collections.Generic.List[string]]::new()
$linkPattern = [regex]'\[[^\]]*\]\(([^)]+)\)'

foreach ($file in $markdownFiles) {
  $text = [IO.File]::ReadAllText($file.FullName)
  foreach ($match in $linkPattern.Matches($text)) {
    $target = $match.Groups[1].Value.Trim()
    if ($target -match '^(https?:|mailto:|#)') {
      continue
    }
    $path = ($target -split '#')[0]
    if ([string]::IsNullOrWhiteSpace($path)) {
      continue
    }
    $path = [Uri]::UnescapeDataString($path)
    $resolved = Join-Path $file.DirectoryName $path
    if (-not (Test-Path -LiteralPath $resolved)) {
      $relative = $file.FullName.Substring($Root.Length + 1)
      $broken.Add("${relative}: $target")
    }
  }
}

if ($broken.Count -gt 0) {
  Write-Host "Broken Markdown links: $($broken.Count)"
  foreach ($entry in $broken) {
    Write-Host "  $entry"
  }
  exit 1
}

Write-Host "All Markdown links resolve ($($markdownFiles.Count) files checked)."
