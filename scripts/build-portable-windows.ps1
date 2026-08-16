[CmdletBinding()]
param(
  [string]$Fpc = 'fpc',
  [string]$FpcRes = 'fpcres',
  [string]$Windres = 'windres',
  [string]$ExpectedVersion = '0.6.0'
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$buildDirectory = Join-Path $repositoryRoot 'build\release'
$unitDirectory = Join-Path $buildDirectory 'units'
$testUnitDirectory = Join-Path $buildDirectory 'test-units'
$testDirectory = Join-Path $buildDirectory 'tests'
$distDirectory = Join-Path $repositoryRoot 'dist'
$assetArchive = Join-Path $buildDirectory 'pasweave-assets.zip'
$resourceScript = Join-Path $buildDirectory 'pasweave-assets.rc'
$resourceFile = Join-Path $buildDirectory 'pasweave-assets.res'
$releaseExecutable = Join-Path $distDirectory 'pasweave.exe'
$checksumFile = Join-Path $distDirectory 'pasweave.exe.sha256'
$smokeDirectory = Join-Path $buildDirectory 'standalone-smoke'
$versionUnit = Join-Path $repositoryRoot 'src\cli\PasWeave.Version.pas'
$versionSource = [IO.File]::ReadAllText($versionUnit)
$versionMatch = [regex]::Match($versionSource,
  "(?m)^\s*PasWeaveVersion\s*=\s*'([^']+)'\s*;")
if (-not $versionMatch.Success) {
  throw "could not read PasWeaveVersion from $versionUnit"
}
$sourceVersion = $versionMatch.Groups[1].Value
if ([string]::IsNullOrWhiteSpace($ExpectedVersion)) {
  $ExpectedVersion = $sourceVersion
} elseif ($ExpectedVersion -ne $sourceVersion) {
  throw "release version mismatch: tag expects PasWeave $ExpectedVersion, " +
    "but src/cli/PasWeave.Version.pas declares PasWeave $sourceVersion. " +
    "Create a tag matching the source version."
}

function Assert-LastExitCode([string]$Operation) {
  if ($LASTEXITCODE -ne 0) {
    throw "$Operation failed with exit code $LASTEXITCODE"
  }
}

Push-Location $repositoryRoot
try {
  if (Test-Path -LiteralPath $buildDirectory) {
    Remove-Item -LiteralPath $buildDirectory -Recurse -Force
  }
  if (Test-Path -LiteralPath $distDirectory) {
    Remove-Item -LiteralPath $distDirectory -Recurse -Force
  }
  New-Item -ItemType Directory -Force $unitDirectory, $testUnitDirectory,
    $testDirectory, $distDirectory | Out-Null

  Compress-Archive -Path 'assets\katex', 'assets\mermaid' `
    -DestinationPath $assetArchive -CompressionLevel Optimal
  $archiveForResource = $assetArchive.Replace('\', '/')
  [IO.File]::WriteAllText($resourceScript,
    "PASWEAVE_ASSETS RCDATA `"$archiveForResource`"`n",
    [Text.UTF8Encoding]::new($false))

  $fpcResExecutable = (Get-Command $FpcRes -ErrorAction Stop).Source
  $windres = (Get-Command $Windres -ErrorAction Stop).Source
  & $windres -i $resourceScript -o $resourceFile -O coff `
    --target=pe-x86-64
  Assert-LastExitCode 'resource compilation'

  $unitPaths = @(
    '-Fusrc/cli', '-Fusrc/diagnostics', '-Fusrc/incremental', '-Fusrc/model',
    '-Fusrc/parser', '-Fusrc/render', '-Fusrc/validation'
  )
  $testCompilerArguments = @(
    '-Twin64', '-Px86_64', '-B', '-O2', '-Mobjfpc', '-Sh'
  ) + $unitPaths + @(
    "-FU$testUnitDirectory", "-FE$testDirectory", 'tests/test_pasweave.pas'
  )
  & $Fpc @testCompilerArguments
  Assert-LastExitCode 'test-suite compilation'
  & (Join-Path $testDirectory 'test_pasweave.exe')
  Assert-LastExitCode 'test suite'

  $compilerArguments = @(
    '-Twin64', '-Px86_64', '-B', '-O2', '-Xs', '-CX', '-XX', '-Mobjfpc', '-Sh',
    '-dPASWEAVE_PORTABLE_ASSETS', "-FC$fpcResExecutable"
  ) + $unitPaths + @(
    "-FU$unitDirectory", "-FE$distDirectory",
    '-opasweave.exe', 'src/pasweave.lpr'
  )
  & $Fpc @compilerArguments
  Assert-LastExitCode 'portable executable compilation'

  $reportedVersion = (& $releaseExecutable --version | Out-String).Trim()
  Assert-LastExitCode 'version check'
  if ($reportedVersion -ne "PasWeave $ExpectedVersion") {
    throw "version mismatch: expected PasWeave $ExpectedVersion, got $reportedVersion"
  }

  $smokeBin = Join-Path $smokeDirectory 'bin'
  $smokeWork = Join-Path $smokeDirectory 'work'
  $smokeOutput = Join-Path $smokeDirectory 'output'
  New-Item -ItemType Directory -Force $smokeBin, $smokeWork | Out-Null
  $isolatedExecutable = Join-Path $smokeBin 'pasweave.exe'
  Copy-Item -LiteralPath $releaseExecutable -Destination $isolatedExecutable

  Push-Location $smokeWork
  try {
    & $isolatedExecutable build `
      (Join-Path $repositoryRoot 'examples\scientific-api') `
      --output $smokeOutput --project-name 'Portable release smoke test'
    Assert-LastExitCode 'standalone documentation smoke test'
  }
  finally {
    Pop-Location
  }

  $requiredOutputs = @(
    'api-model.json',
    'markdown\index.md',
    'markdown\units\Scientific.Analysis.md',
    'markdown\units\Scientific.Core.md',
    'html\index.html',
    'html\units\Scientific.Analysis.html',
    'html\units\Scientific.Core.html',
    'html\assets\katex\katex.min.js',
    'html\assets\katex\katex.min.css',
    'html\assets\katex\fonts\KaTeX_Main-Regular.woff2',
    'html\assets\katex\LICENSE',
    'html\assets\mermaid\mermaid.tiny.js',
    'html\assets\mermaid\LICENSE'
  )
  foreach ($relativeOutput in $requiredOutputs) {
    if (-not (Test-Path -LiteralPath (Join-Path $smokeOutput $relativeOutput))) {
      throw "standalone smoke test did not produce $relativeOutput"
    }
  }

  $smokeIndex = [IO.File]::ReadAllText(
    (Join-Path $smokeOutput 'html\index.html'))
  $smokeCoreUnit = [IO.File]::ReadAllText(
    (Join-Path $smokeOutput 'html\units\Scientific.Core.html'))
  if (-not $smokeIndex.Contains('28 of 28 API symbols documented')) {
    throw 'standalone smoke test lost documented-symbol coverage'
  }
  if (-not $smokeIndex.Contains('data-diagram-container')) {
    throw 'standalone smoke test did not render relationship diagrams'
  }
  if (-not $smokeCoreUnit.Contains('data-math-display')) {
    throw 'standalone smoke test did not render mathematical documentation'
  }

  $sourceAssetsRoot = Join-Path $repositoryRoot 'assets'
  $generatedAssetsRoot = Join-Path $smokeOutput 'html\assets'
  $sourceAssetsPrefix = ([IO.Path]::GetFullPath($sourceAssetsRoot)).TrimEnd(
    [IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
  $sourceAssetFiles = Get-ChildItem `
    (Join-Path $sourceAssetsRoot 'katex'), `
    (Join-Path $sourceAssetsRoot 'mermaid') -Recurse -File
  foreach ($sourceAsset in $sourceAssetFiles) {
    if (-not $sourceAsset.FullName.StartsWith(
      $sourceAssetsPrefix, [StringComparison]::OrdinalIgnoreCase)) {
      throw "asset escaped source root: $($sourceAsset.FullName)"
    }
    $relativeAsset = $sourceAsset.FullName.Substring($sourceAssetsPrefix.Length)
    $generatedAsset = Join-Path $generatedAssetsRoot $relativeAsset
    if (-not (Test-Path -LiteralPath $generatedAsset)) {
      throw "embedded asset extraction omitted $relativeAsset"
    }
    $sourceHash = (Get-FileHash -Algorithm SHA256 $sourceAsset.FullName).Hash
    $generatedHash = (Get-FileHash -Algorithm SHA256 $generatedAsset).Hash
    if ($sourceHash -ne $generatedHash) {
      throw "embedded asset content differs for $relativeAsset"
    }
  }

  $checksum = (Get-FileHash -Algorithm SHA256 $releaseExecutable).Hash.ToLower()
  [IO.File]::WriteAllText($checksumFile,
    "$checksum  pasweave.exe`n", [Text.UTF8Encoding]::new($false))

  Write-Host "Portable release ready: $releaseExecutable"
  Write-Host "SHA-256: $checksum"
}
finally {
  Pop-Location
}
