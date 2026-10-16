[CmdletBinding()]
param(
    [string] $SourceRoot,
    [Parameter(Mandatory)][string] $OutputDirectory,
    [Parameter(Mandatory)][string] $BuildLog,
    [Parameter(Mandatory)][string] $TestLog,
    [Parameter(Mandatory)][string] $DependencyManifest
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Lotro.Common.ps1')

if (-not $SourceRoot) { $SourceRoot = Join-Path $PSScriptRoot '..\..' }
$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
foreach ($inputFile in @($BuildLog, $TestLog, $DependencyManifest)) {
    if (-not (Test-Path -LiteralPath $inputFile -PathType Leaf)) { throw "Required evidence file is missing: $inputFile" }
}
$zipName = 'LOTRO-DLSS5-Prototype-v0.1.0.zip'
$out = [IO.Path]::GetFullPath($OutputDirectory)
if (Test-Path -LiteralPath $out) {
    if (Get-ChildItem -LiteralPath $out -Force | Select-Object -First 1) {
        throw "Output directory is not empty; refusing to overwrite any file: $out"
    }
} else { New-Item -ItemType Directory -Path $out -Force | Out-Null }

$files = [ordered]@{
    'README-LOTRO.md' = 'README-LOTRO.md'
    'lotro\START-HERE.md' = 'START-HERE.md'
    'lotro\COMPATIBILITY.md' = 'COMPATIBILITY.md'
    'lotro\TEST-PLAN.md' = 'TEST-PLAN.md'
    'lotro\CHANGELOG.md' = 'CHANGELOG.md'
    'lotro\THIRD-PARTY-NOTICES.md' = 'THIRD-PARTY-NOTICES.md'
    'lotro\config\lotro-disabled.cfg' = 'config\lotro-disabled.cfg'
    'lotro\config\lotro-prototype.cfg' = 'config\lotro-prototype.cfg'
    'lotro\scripts\Lotro.Common.ps1' = 'scripts\Lotro.Common.ps1'
    'lotro\scripts\Preflight-Lotro.ps1' = 'scripts\Preflight-Lotro.ps1'
    'lotro\scripts\Build-LotroPackage.ps1' = 'scripts\Build-LotroPackage.ps1'
    'lotro\scripts\Verify-LotroPackage.ps1' = 'scripts\Verify-LotroPackage.ps1'
    'lotro\scripts\Collect-LotroDiagnostics.ps1' = 'scripts\Collect-LotroDiagnostics.ps1'
    'lotro\scripts\Restore-Lotro.ps1' = 'scripts\Restore-Lotro.ps1'
    'shaders\DLSS5_Feed.fx' = 'shaders\DLSS5_Feed.fx'
    'build\dlss5-feed.addon64' = 'bin\dlss5-feed.addon64'
    'host\dlss5-feed-host64.exe' = 'diagnostics\dlss5-feed-host64.exe'
    'LICENSE' = 'LICENSE'
    'external\minhook\LICENSE.txt' = 'licenses\MinHook-LICENSE.txt'
    'external\imgui\LICENSE.txt' = 'licenses\ImGui-LICENSE.txt'
    'external\ngx\LICENSE.txt' = 'licenses\NVIDIA-RTX-SDK-LICENSE.txt'
    'CAREFUL_FAKE_MALICIOUS_FEEDER.txt' = 'UPSTREAM-SECURITY-NOTICE.txt'
}
foreach ($sourceRelative in $files.Keys) {
    $from = Resolve-LotroChildPath -Root $SourceRoot -RelativePath $sourceRelative
    if (-not (Test-Path -LiteralPath $from -PathType Leaf)) { throw "Required package file is missing: $sourceRelative" }
    $to = Resolve-LotroChildPath -Root $out -RelativePath $files[$sourceRelative]
    $parent = Split-Path -Parent $to
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    Copy-Item -LiteralPath $from -Destination $to -ErrorAction Stop
}
$evidence = [ordered]@{
    $BuildLog = 'results\build.log'
    $TestLog = 'results\tests.log'
    $DependencyManifest = 'results\dependencies.json'
}
foreach ($from in $evidence.Keys) {
    $to = Resolve-LotroChildPath -Root $out -RelativePath $evidence[$from]
    New-Item -ItemType Directory -Path (Split-Path -Parent $to) -Force | Out-Null
    Copy-Item -LiteralPath $from -Destination $to -ErrorAction Stop
}

$entries = @(Get-ChildItem -LiteralPath $out -File -Recurse | ForEach-Object {
    [pscustomobject]@{
        path = $_.FullName.Substring($out.TrimEnd('\').Length + 1).Replace('\', '/')
        bytes = $_.Length
        sha256 = Get-LotroSha256 -Path $_.FullName
    }
} | Sort-Object path)
$manifest = [ordered]@{
    package = 'LOTRO-DLSS5-Prototype'
    version = '0.1.0'
    upstreamBase = '3c09eabcd138a68d144b6cc396a23e6b493eea4d'
    createdUtc = [DateTime]::UtcNow.ToString('o')
    files = $entries
}
$manifestPath = Join-Path $out 'package-manifest.json'
[IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
$zipPath = Join-Path $out $zipName
Compress-Archive -Path (Join-Path $out '*') -DestinationPath $zipPath -CompressionLevel Optimal
Write-Output ([pscustomobject]@{ ZipPath = $zipPath; Sha256 = Get-LotroSha256 -Path $zipPath; FileCount = $entries.Count })
