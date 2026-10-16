Set-StrictMode -Version Latest

function Get-LotroSha256 {
    param([Parameter(Mandatory)][string] $Path)
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Resolve-LotroChildPath {
    param(
        [Parameter(Mandatory)][string] $Root,
        [Parameter(Mandatory)][string] $RelativePath
    )
    if ([IO.Path]::IsPathRooted($RelativePath)) { throw "Absolute package path is forbidden: $RelativePath" }
    if ($RelativePath -match '(^|[\\/])\.\.([\\/]|$)') { throw "Parent traversal is forbidden: $RelativePath" }
    $rootPath = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $child = [IO.Path]::GetFullPath((Join-Path $rootPath $RelativePath))
    if (-not $child.StartsWith($rootPath, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Package path escapes its root: $RelativePath"
    }
    $child
}

function Get-LotroPeMachine {
    param([Parameter(Mandatory)][string] $Path)
    $stream = [IO.File]::OpenRead($Path)
    try {
        if ($stream.Length -lt 70) { throw 'File is too short to be a PE executable' }
        $reader = New-Object IO.BinaryReader($stream)
        if ($reader.ReadUInt16() -ne 0x5A4D) { throw 'Missing MZ signature' }
        [void] $stream.Seek(0x3C, [IO.SeekOrigin]::Begin)
        $offset = $reader.ReadInt32()
        if ($offset -lt 64 -or $offset -gt ($stream.Length - 6)) { throw 'Invalid PE header offset' }
        [void] $stream.Seek($offset, [IO.SeekOrigin]::Begin)
        if ($reader.ReadUInt32() -ne 0x00004550) { throw 'Missing PE signature' }
        $machine = $reader.ReadUInt16()
        switch ($machine) {
            0x8664 { 'x64'; break }
            0x014c { 'x86'; break }
            default { ('Unknown(0x{0:x4})' -f $machine) }
        }
    } finally {
        $stream.Dispose()
    }
}
