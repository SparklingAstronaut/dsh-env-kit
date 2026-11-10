param(
    [Parameter(Mandatory=$true)][string]$DshExe,
    [Parameter(Mandatory=$true)][string]$DshHome,
    [string]$ElectronArchive,
    [switch]$SkipDesktopPet
)
. "$PSScriptRoot\Common.ps1"
$DshExe = Full-Path $DshExe
$DshHome = Full-Path $DshHome
Assert-NoLinks $DshHome
$manifest = Read-Json (Join-Path $KitRoot 'manifest.json')
Assert-Host $DshExe $manifest
$archive = Join-Path $KitRoot $manifest.payload.file
Assert-Hash $archive $manifest.payload.sha256
Assert-Stopped $DshHome
if (Test-Path -LiteralPath $DshHome) {
    $marker = Join-Path $DshHome '.env-kit.json'
    if (-not (Test-Path -LiteralPath $marker)) { throw 'Target already exists and is not owned by this kit. Choose a new empty path.' }
    $old = Read-Json $marker
    if ($old.payloadSha256 -ne $manifest.payload.sha256) { throw 'Different kit version. Install into a new home; preserve this one.' }
    Test-Payload $DshHome
    Write-Output 'Already installed; files verified and user settings preserved.'
    exit 0
}
$parent = Split-Path $DshHome -Parent
$null = New-Item -ItemType Directory -Path $parent -Force
$stage = Join-Path $parent ((Split-Path $DshHome -Leaf) + '.staging-' + [guid]::NewGuid().ToString('N'))
try {
    Expand-SafeZip $archive $stage
    Test-Payload $stage
    if (-not $SkipDesktopPet) {
        if (-not $ElectronArchive) {
            $ElectronArchive = $stage + '.electron.zip'
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -UseBasicParsing -Uri $manifest.companion.url -OutFile $ElectronArchive
        }
        $ElectronArchive = (Resolve-Path -LiteralPath $ElectronArchive).ProviderPath
        Assert-Hash $ElectronArchive $manifest.companion.sha256
        $electronTarget = Join-Path $stage 'companions\whale-desktop\node_modules\electron\dist'
        $null = New-Item -ItemType Directory -Path (Split-Path $electronTarget -Parent) -Force
        Expand-SafeZip $ElectronArchive $electronTarget
    }
    Write-Json (Join-Path $stage '.env-kit.json') @{
        version=$manifest.version; payloadSha256=$manifest.payload.sha256; dshExe=$DshExe
        installedUtc=[DateTime]::UtcNow.ToString('o'); desktopPet=(-not $SkipDesktopPet)
    }
    # Both paths are verified siblings. No old target is overwritten or deleted.
    if ((Split-Path (Full-Path $stage) -Parent) -ne $parent) { throw 'Staging location mismatch.' }
    if (Test-Path -LiteralPath $DshHome) { throw 'Target appeared during installation; staging retained.' }
    Move-Item -LiteralPath $stage -Destination $DshHome
    Write-Output "Installed $(@($manifest.plugins).Count) plugins into: $DshHome"
    Write-Output 'Use Start-DSH.ps1 with this home. Configure API keys and model folders in DSH settings.'
} catch {
    throw "Install failed; active homes were not replaced. Staging retained at $stage. $($_.Exception.Message)"
}
