[CmdletBinding()]
param([string] $SourceRoot)
$ErrorActionPreference = 'Stop'
if (-not $SourceRoot) { $SourceRoot = Join-Path $PSScriptRoot '..\..' }
$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
$preflight = Join-Path $SourceRoot 'lotro\scripts\Preflight-Lotro.ps1'
$buildPackage = Join-Path $SourceRoot 'lotro\scripts\Build-LotroPackage.ps1'
$verifyPackage = Join-Path $SourceRoot 'lotro\scripts\Verify-LotroPackage.ps1'
$collect = Join-Path $SourceRoot 'lotro\scripts\Collect-LotroDiagnostics.ps1'
$restore = Join-Path $SourceRoot 'lotro\scripts\Restore-Lotro.ps1'
$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
$fixture = Join-Path $tempRoot ('lotro-tests-' + [Guid]::NewGuid().ToString('N'))

function Assert-Lotro([bool] $Condition, [string] $Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
}
function New-TestPe([string] $Path, [UInt16] $Machine) {
    $bytes = New-Object byte[] 256
    $bytes[0] = 0x4D; $bytes[1] = 0x5A
    [BitConverter]::GetBytes([int]128).CopyTo($bytes, 0x3C)
    $bytes[128] = 0x50; $bytes[129] = 0x45
    [BitConverter]::GetBytes($Machine).CopyTo($bytes, 132)
    [IO.File]::WriteAllBytes($Path, $bytes)
}

try {
    New-Item -ItemType Directory -Path $fixture -Force | Out-Null
    $game = Join-Path $fixture 'synthetic-game'
    New-Item -ItemType Directory -Path $game -Force | Out-Null
    $x64 = Join-Path $game 'lotroclient64.exe'
    $x86 = Join-Path $game 'lotroclient.exe'
    New-TestPe -Path $x64 -Machine 0x8664
    New-TestPe -Path $x86 -Machine 0x014c
    $prefs = Join-Path $fixture 'UserPreferences.ini'
    [IO.File]::WriteAllText($prefs, "GraphicsCore=D3D11`n")
    $found = (& $preflight -GameExe $x64 -PreferencesPath $prefs | ConvertFrom-Json)
    Assert-Lotro ($found.Status -eq 'CandidateFound') 'explicit candidate'
    Assert-Lotro ($found.Executables[0].Machine -eq 'x64') 'PE x64 detection'
    Assert-Lotro ($found.RendererHint -eq 'D3D11' -and $found.RendererEvidence -match 'unverified') 'renderer hint labeling'
    $both = (& $preflight -SearchRoot $game -PreferencesPath $prefs | ConvertFrom-Json)
    Assert-Lotro ($both.Status -eq 'Ambiguous' -and $both.Executables.Count -eq 2) 'ambiguous candidates'
    $found32 = (& $preflight -GameExe $x86 -PreferencesPath $prefs | ConvertFrom-Json)
    Assert-Lotro ($found32.Executables[0].Machine -eq 'x86') 'PE x86 detection'
    $missingRejected = $false
    try { $null = & $preflight -GameExe (Join-Path $game 'missing.exe') -PreferencesPath $prefs } catch { $missingRejected = $true }
    Assert-Lotro $missingRejected 'missing explicit executable must fail'

    $logs = Join-Path $fixture 'logs'
    New-Item -ItemType Directory -Path $logs -Force | Out-Null
    $buildLog = Join-Path $logs 'build.log'; $testLog = Join-Path $logs 'tests.log'; $deps = Join-Path $logs 'dependencies.json'
    [IO.File]::WriteAllText($buildLog, 'synthetic test packaging input')
    [IO.File]::WriteAllText($testLog, 'synthetic test packaging input')
    [IO.File]::WriteAllText($deps, '{}')
    $packageRoot = Join-Path $fixture 'package'
    $package = & $buildPackage -SourceRoot $SourceRoot -OutputDirectory $packageRoot -BuildLog $buildLog -TestLog $testLog -DependencyManifest $deps
    Assert-Lotro (Test-Path -LiteralPath $package.ZipPath) 'package ZIP created'
    $verified = & $verifyPackage -ZipPath $package.ZipPath
    Assert-Lotro ($verified.Status -eq 'PASS' -and $verified.FileCount -gt 10) 'ZIP contents verified'
    $occupiedRejected = $false
    try { $null = & $buildPackage -SourceRoot $SourceRoot -OutputDirectory $packageRoot -BuildLog $buildLog -TestLog $testLog -DependencyManifest $deps } catch { $occupiedRejected = $true }
    Assert-Lotro $occupiedRejected 'occupied package folder must be refused'

    [IO.File]::WriteAllText((Join-Path $game 'dlss5-feed.log'), "test $env:USERPROFILE")
    $diagRoot = Join-Path $fixture 'diagnostics'
    $diagnostics = & $collect -GameDirectory $game -OutputDirectory $diagRoot
    Assert-Lotro ($diagnostics.Status -eq 'Collected') 'diagnostics collected outside game'
    Assert-Lotro ((Get-Content (Join-Path $diagRoot 'dlss5-feed.log') -Raw) -match '%USERPROFILE%') 'profile path redacted'

    $installed = Join-Path $game 'dlss5-feed.addon64'
    [IO.File]::WriteAllText($installed, 'synthetic installed package file')
    $installedHash = (Get-FileHash -LiteralPath $installed -Algorithm SHA256).Hash.ToLowerInvariant()
    $installManifest = Join-Path $fixture 'install-manifest.json'
    $record = @{ package = 'LOTRO-DLSS5-Prototype'; files = @(@{ relativePath = 'dlss5-feed.addon64'; installedSha256 = $installedHash }) }
    [IO.File]::WriteAllText($installManifest, ($record | ConvertTo-Json -Depth 5))
    $preview = & $restore -GameDirectory $game -InstallManifest $installManifest
    Assert-Lotro ($preview.Status -eq 'PreviewOnly' -and (Test-Path $installed)) 'restoration defaults to preview'
    $applied = & $restore -GameDirectory $game -InstallManifest $installManifest -Apply
    Assert-Lotro ($applied.Status -eq 'Restored' -and -not (Test-Path $installed)) 'restoration affects only fixture package file'

    Write-Output 'PASS: preflight, ambiguity, bitness, ZIP integrity, overwrite refusal, diagnostics, preview and fixture restoration'
} finally {
    $resolved = [IO.Path]::GetFullPath($fixture)
    if ($resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $resolved) -match '^lotro-tests-[0-9a-f]{32}$' -and
        (Test-Path -LiteralPath $resolved)) {
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
