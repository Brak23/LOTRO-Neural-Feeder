[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $GameDirectory,
    [Parameter(Mandatory)][string] $InstallManifest,
    [switch] $Apply
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Lotro.Common.ps1')
if (-not (Test-Path -LiteralPath $GameDirectory -PathType Container)) { throw "Game directory not found: $GameDirectory" }
if (-not (Test-Path -LiteralPath $InstallManifest -PathType Leaf)) { throw "Install manifest not found: $InstallManifest" }
$game = (Resolve-Path -LiteralPath $GameDirectory).Path
$manifestFile = (Resolve-Path -LiteralPath $InstallManifest).Path
$manifest = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
if ($manifest.package -ne 'LOTRO-DLSS5-Prototype' -or -not $manifest.files) {
    throw 'This is not a LOTRO prototype installation manifest'
}
$allowed = @(
    'dlss5-feed.addon64',
    'dlss5-feed.cfg',
    'reshade-shaders/Shaders/DLSS5_Feed.fx'
)
$actions = @()
foreach ($item in $manifest.files) {
    $relative = ([string]$item.relativePath).Replace('\', '/')
    if ($allowed -notcontains $relative) { throw "Manifest names a file outside the package-owned allowlist: $relative" }
    if ($item.installedSha256 -notmatch '^[0-9a-fA-F]{64}$') { throw "Missing installed hash: $relative" }
    $target = Resolve-LotroChildPath -Root $game -RelativePath $relative
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw "Expected installed file is missing: $relative" }
    if ((Get-LotroSha256 -Path $target) -ne $item.installedSha256.ToLowerInvariant()) {
        throw "Installed file changed since installation; refusing to alter it: $relative"
    }
    $backup = $null
    if ($item.PSObject.Properties['backupRelativePath'] -and $item.backupRelativePath) {
        if (-not $item.PSObject.Properties['backupSha256'] -or $item.backupSha256 -notmatch '^[0-9a-fA-F]{64}$') { throw "Missing backup hash: $relative" }
        $backupRoot = Split-Path -Parent $manifestFile
        $backup = Resolve-LotroChildPath -Root $backupRoot -RelativePath $item.backupRelativePath
        if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) { throw "Backup is missing: $relative" }
        if ((Get-LotroSha256 -Path $backup) -ne $item.backupSha256.ToLowerInvariant()) {
            throw "Backup hash mismatch: $relative"
        }
    }
    $actions += [pscustomobject]@{ RelativePath = $relative; Action = if ($backup) { 'RestoreBackup' } else { 'RemovePackageFile' }; Target = $target; Backup = $backup }
}
if (-not $Apply) {
    Write-Output ([pscustomobject]@{ Status = 'PreviewOnly'; Actions = $actions })
    return
}
foreach ($action in $actions) {
    if ($action.Backup) {
        Copy-Item -LiteralPath $action.Backup -Destination $action.Target -Force -ErrorAction Stop
    } else {
        Remove-Item -LiteralPath $action.Target -Force -ErrorAction Stop
    }
}
Write-Output ([pscustomobject]@{ Status = 'Restored'; Actions = $actions })
