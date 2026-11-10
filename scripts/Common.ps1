if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'PowerShell 7 is required. Run these scripts with pwsh, not Windows PowerShell.' }
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$script:KitRoot = Split-Path $PSScriptRoot -Parent

function Read-Json([string]$Path) {
    Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}
function Write-Json([string]$Path, $Value) {
    $text = $Value | ConvertTo-Json -Depth 30
    [IO.File]::WriteAllText($Path, $text, (New-Object Text.UTF8Encoding($false)))
}
function Full-Path([string]$Path) {
    if (-not [IO.Path]::IsPathRooted($Path)) { throw 'Use an absolute target path.' }
    [IO.Path]::GetFullPath($Path).TrimEnd('\','/')
}
function Assert-NoLinks([string]$Path) {
    $current = Full-Path $Path
    while ($current) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked paths are not supported: $current" }
        }
        $parent = Split-Path $current -Parent
        if ($parent -eq $current) { break }
        $current = $parent
    }
}
function Assert-Hash([string]$Path,[string]$Expected) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Missing file: $Path" }
    if ((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -ne $Expected) { throw "Checksum mismatch: $Path" }
}
function Get-HostVersion([string]$DshExe) {
    if (-not (Test-Path -LiteralPath $DshExe -PathType Leaf)) { throw 'Official DSH executable not found.' }
    $asar = Join-Path (Split-Path $DshExe -Parent) 'resources\app.asar'
    $reader = New-Object IO.BinaryReader([IO.File]::OpenRead($asar))
    try {
        $null = $reader.ReadUInt32()
        $headerSize = $reader.ReadUInt32()
        $null = $reader.ReadUInt32()
        $jsonSize = $reader.ReadUInt32()
        $header = [Text.Encoding]::UTF8.GetString($reader.ReadBytes($jsonSize)) | ConvertFrom-Json
        $entry = $header.files.'package.json'
        $null = $reader.BaseStream.Seek((8 + [long]$headerSize + [long]$entry.offset), [IO.SeekOrigin]::Begin)
        $package = [Text.Encoding]::UTF8.GetString($reader.ReadBytes($entry.size)) | ConvertFrom-Json
        $package.version
    } finally { $reader.Dispose() }
}
function Assert-Host([string]$DshExe, $Manifest) {
    $version = Get-HostVersion $DshExe
    if ($version -ne $Manifest.hostVersion) { throw "This kit requires DSH $($Manifest.hostVersion); found $version." }
}
function Assert-Stopped([string]$DshHome) {
    $lock = Join-Path $DshHome '.env-kit-running.json'
    if (Test-Path -LiteralPath $lock) {
        $record = Read-Json $lock
        $running = Get-Process -Id $record.processId -ErrorAction SilentlyContinue
        if ($running -and $running.StartTime.ToUniversalTime().Ticks -eq ([datetime]$record.startedUtc).ToUniversalTime().Ticks) {
            throw 'Close this kit instance of DSH before changing it.'
        }
    }
}
function Expand-SafeZip([string]$Archive,[string]$Destination) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $root = (Full-Path $Destination) + '\'
    $zip = [IO.Compression.ZipFile]::OpenRead($Archive)
    try {
        foreach ($entry in $zip.Entries) {
            if ($entry.FullName -match '(^|[\\/])\.\.([\\/]|$)|:|^[\\/]') { throw 'Unsafe archive path.' }
            $target = [IO.Path]::GetFullPath((Join-Path $Destination $entry.FullName))
            if (-not $target.StartsWith($root,[StringComparison]::OrdinalIgnoreCase)) { throw 'Archive path escapes target.' }
            if (($entry.ExternalAttributes -shr 16 -band 0xF000) -eq 0xA000) { throw 'Archive links are unsupported.' }
        }
        [IO.Compression.ZipFileExtensions]::ExtractToDirectory($zip,$Destination)
    } finally { $zip.Dispose() }
}
function Test-Payload([string]$DshHome) {
    $inventory = Read-Json (Join-Path $script:KitRoot 'payload-files.json')
    foreach ($entry in $inventory.PSObject.Properties) {
        # The app owns this one settings document after first launch.
        if ($entry.Name -eq 'profiles/desktop/cordis.patch.yml') { continue }
        Assert-Hash (Join-Path $DshHome $entry.Name) $entry.Value
    }
    $manifest = Read-Json (Join-Path $script:KitRoot 'manifest.json')
    $profile = Read-Json (Join-Path $DshHome 'profiles\desktop\package.json')
    if (@($profile.dependencies.PSObject.Properties).Count -ne 13) { throw 'Unexpected plugin composition.' }
    foreach ($plugin in $manifest.plugins) {
        if ($profile.dependencies.($plugin.name) -ne $plugin.version) { throw 'Plugin declaration drift.' }
    }
}
