[CmdletBinding()]
param(
    [string] $GameExe,
    [string[]] $SearchRoot = @(),
    [string] $PreferencesPath,
    [string] $SteamLibraryFoldersPath
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Lotro.Common.ps1')

$candidates = New-Object 'System.Collections.Generic.List[string]'
if ($GameExe) {
    if (-not (Test-Path -LiteralPath $GameExe -PathType Leaf)) { throw "Game executable not found: $GameExe" }
    $candidates.Add((Resolve-Path -LiteralPath $GameExe).Path)
} else {
    $roots = New-Object 'System.Collections.Generic.List[string]'
    foreach ($root in $SearchRoot) {
        if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw "Search root not found: $root" }
        $roots.Add((Resolve-Path -LiteralPath $root).Path)
    }
    if ($roots.Count -eq 0) {
        foreach ($base in @(${env:ProgramFiles}, ${env:ProgramFiles(x86)})) {
            if (-not $base) { continue }
            foreach ($relative in @('Steam\steamapps\common\The Lord of the Rings Online', 'StandingStoneGames\The Lord of the Rings Online', 'Turbine\The Lord of the Rings Online')) {
                $path = Join-Path $base $relative
                if (Test-Path -LiteralPath $path -PathType Container) { $roots.Add($path) }
            }
        }
        if (-not $SteamLibraryFoldersPath -and ${env:ProgramFiles(x86)}) {
            $SteamLibraryFoldersPath = Join-Path ${env:ProgramFiles(x86)} 'Steam\steamapps\libraryfolders.vdf'
        }
        if ($SteamLibraryFoldersPath -and (Test-Path -LiteralPath $SteamLibraryFoldersPath -PathType Leaf)) {
            $vdf = Get-Content -LiteralPath $SteamLibraryFoldersPath -Raw
            foreach ($libraryMatch in [regex]::Matches($vdf, '(?m)^\s*"path"\s*"([^"]+)"')) {
                $library = $libraryMatch.Groups[1].Value.Replace('\\', '\')
                $steamapps = Join-Path $library 'steamapps'
                if (-not (Test-Path -LiteralPath $steamapps -PathType Container)) { continue }
                foreach ($manifest in (Get-ChildItem -LiteralPath $steamapps -File -Filter 'appmanifest_*.acf' -ErrorAction SilentlyContinue)) {
                    $content = Get-Content -LiteralPath $manifest.FullName -Raw
                    if ($content -notmatch '(?m)^\s*"name"\s*"The Lord of the Rings Online[^"]*"') { continue }
                    if ($content -match '(?m)^\s*"installdir"\s*"([^"]+)"') {
                        $common = Join-Path $steamapps 'common'
                        try {
                            $install = Resolve-LotroChildPath -Root $common -RelativePath $matches[1]
                            if (Test-Path -LiteralPath $install -PathType Container) { $roots.Add($install) }
                        } catch { }
                    }
                }
            }
        }
    }
    foreach ($root in $roots) {
        Get-ChildItem -LiteralPath $root -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^lotroclient(64)?\.exe$' -and $_.FullName -notmatch '(?i)[\\/]backup[\\/]' } |
            ForEach-Object { $candidates.Add($_.FullName) }
    }
}

if (-not $PreferencesPath) {
    $docs = [Environment]::GetFolderPath('MyDocuments')
    if ($docs) { $PreferencesPath = Join-Path $docs 'The Lord of the Rings Online\UserPreferences.ini' }
}
$renderer = 'Unknown'
$rendererEvidence = 'No live renderer observation; game was not launched.'
if ($PreferencesPath -and (Test-Path -LiteralPath $PreferencesPath -PathType Leaf)) {
    $line = Get-Content -LiteralPath $PreferencesPath | Where-Object { $_ -match '^\s*GraphicsCore\s*=' } | Select-Object -Last 1
    if ($line -and $line -match '=\s*(D3D\d+|DirectX\s*\d+)\s*$') {
        $renderer = $matches[1]
        $rendererEvidence = 'Configuration hint from UserPreferences.ini; actual loaded graphics API is unverified.'
    }
}

$detected = @()
foreach ($path in @($candidates | Select-Object -Unique)) {
    try {
        $file = Get-Item -LiteralPath $path
        $detected += [pscustomobject]@{
            Path = $file.FullName
            FileName = $file.Name
            Machine = Get-LotroPeMachine -Path $file.FullName
            Sha256 = Get-LotroSha256 -Path $file.FullName
            FileVersion = $file.VersionInfo.FileVersion
        }
    } catch {
        $detected += [pscustomobject]@{ Path = $path; Error = $_.Exception.Message }
    }
}
$gpu = @()
try {
    $gpu = @(Get-CimInstance Win32_VideoController -ErrorAction Stop | ForEach-Object {
        [pscustomobject]@{ Name = $_.Name; DriverVersion = $_.DriverVersion }
    })
} catch { $gpu = @() }

[pscustomobject]@{
    Status = if ($detected.Count -eq 0) { 'GameNotFound' } elseif ($detected.Count -gt 1) { 'Ambiguous' } else { 'CandidateFound' }
    Host = [pscustomobject]@{
        OS = [Environment]::OSVersion.VersionString
        Is64BitOS = [Environment]::Is64BitOperatingSystem
        Is64BitProcess = [Environment]::Is64BitProcess
        GPU = $gpu
    }
    Executables = $detected
    RendererHint = $renderer
    RendererEvidence = $rendererEvidence
} | ConvertTo-Json -Depth 6
