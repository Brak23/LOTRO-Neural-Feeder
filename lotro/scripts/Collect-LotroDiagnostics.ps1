[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $GameDirectory,
    [Parameter(Mandatory)][string] $OutputDirectory
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Lotro.Common.ps1')
if (-not (Test-Path -LiteralPath $GameDirectory -PathType Container)) { throw "Game directory not found: $GameDirectory" }
$game = (Resolve-Path -LiteralPath $GameDirectory).Path.TrimEnd('\')
$output = [IO.Path]::GetFullPath($OutputDirectory).TrimEnd('\')
if ($output.StartsWith(($game + '\'), [StringComparison]::OrdinalIgnoreCase) -or $output -eq $game) {
    throw 'Diagnostic output must be outside the game directory'
}
if (Test-Path -LiteralPath $output) {
    if (Get-ChildItem -LiteralPath $output -Force | Select-Object -First 1) {
        throw "Output directory is not empty: $output"
    }
} else { New-Item -ItemType Directory -Path $output -Force | Out-Null }

$names = @('dlss5-feed.log', 'ReShade.log', 'host64\dlss5-feed-host.log')
$copied = @()
$missing = @()
foreach ($relative in $names) {
    $source = Resolve-LotroChildPath -Root $game -RelativePath $relative
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { $missing += $relative; continue }
    if ((Get-Item -LiteralPath $source).Length -gt 8MB) { throw "Log is over the 8 MB collection limit: $relative" }
    $target = Resolve-LotroChildPath -Root $output -RelativePath $relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
    $content = [IO.File]::ReadAllText($source)
    if ($env:USERPROFILE) {
        $content = [regex]::Replace($content, [regex]::Escape($env:USERPROFILE), '%USERPROFILE%', 'IgnoreCase')
    }
    [IO.File]::WriteAllText($target, $content, (New-Object Text.UTF8Encoding($false)))
    $copied += $relative
}
$summary = [pscustomobject]@{
    Status = if ($copied.Count) { 'Collected' } else { 'NoLogsFound' }
    Collected = $copied
    Missing = $missing
    Note = 'Inspect logs before sharing; other private paths or account identifiers may remain.'
}
$summary | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding UTF8
$summary
