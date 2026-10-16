[CmdletBinding()]
param([Parameter(Mandatory)][string] $ZipPath)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Lotro.Common.ps1')
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) { throw "ZIP not found: $ZipPath" }
$archive = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $ZipPath).Path)
try {
    $byName = @{}
    foreach ($entry in $archive.Entries) {
        if (-not $entry.Name) { continue }
        $name = $entry.FullName.Replace('\', '/')
        if ($name -match '(^/|^[A-Za-z]:|(^|/)\.\.(/|$))') { throw "Unsafe ZIP path: $name" }
        if ($byName.ContainsKey($name)) { throw "Duplicate ZIP path: $name" }
        if ($name -match '(?i)(^|/)(nvngx_dlss(nr)?\.dll|deep-fried-chicken.*|renodx-dlss5.*)$') {
            throw "Proprietary runtime or neural consumer in package: $name"
        }
        $byName[$name] = $entry
    }
    if (-not $byName.ContainsKey('package-manifest.json')) { throw 'Package manifest is missing' }
    $reader = New-Object IO.StreamReader($byName['package-manifest.json'].Open())
    try { $manifest = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
    if ($manifest.package -ne 'LOTRO-DLSS5-Prototype' -or $manifest.version -ne '0.1.0') {
        throw 'Unexpected package identity or version'
    }
    $expected = @{}
    foreach ($item in $manifest.files) {
        if ($expected.ContainsKey($item.path)) { throw "Duplicate manifest path: $($item.path)" }
        $expected[$item.path] = $item
    }
    foreach ($name in $byName.Keys) {
        if ($name -eq 'package-manifest.json') { continue }
        if (-not $expected.ContainsKey($name)) { throw "Unexpected ZIP file: $name" }
    }
    foreach ($name in $expected.Keys) {
        if (-not $byName.ContainsKey($name)) { throw "ZIP file is missing: $name" }
        $entry = $byName[$name]
        if ($entry.Length -ne $expected[$name].bytes) { throw "Size mismatch: $name" }
        $hash = [Security.Cryptography.SHA256]::Create()
        $stream = $entry.Open()
        try {
            $actual = ([BitConverter]::ToString($hash.ComputeHash($stream))).Replace('-', '').ToLowerInvariant()
        } finally { $stream.Dispose(); $hash.Dispose() }
        if ($actual -ne $expected[$name].sha256) { throw "SHA-256 mismatch: $name" }
    }
    Write-Output ([pscustomobject]@{
        Status = 'PASS'
        ZipPath = (Resolve-Path -LiteralPath $ZipPath).Path
        Sha256 = Get-LotroSha256 -Path $ZipPath
        FileCount = $expected.Count
    })
} finally { $archive.Dispose() }
