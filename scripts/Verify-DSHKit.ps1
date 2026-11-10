param([string]$DshHome,[string]$DshExe)
. "$PSScriptRoot\Common.ps1"
$manifest = Read-Json (Join-Path $KitRoot 'manifest.json')
Assert-Hash (Join-Path $KitRoot $manifest.payload.file) $manifest.payload.sha256
if ($DshExe) { Assert-Host (Full-Path $DshExe) $manifest }
if ($DshHome) {
    $DshHome = Full-Path $DshHome
    Assert-NoLinks $DshHome
    Test-Payload $DshHome
    $marker=Read-Json (Join-Path $DshHome '.env-kit.json')
    if ($marker.desktopPet -and -not (Test-Path -LiteralPath (Join-Path $DshHome 'companions\whale-desktop\node_modules\electron\dist\electron.exe'))) { throw 'Desktop companion runtime missing.' }
}
Write-Output 'Archive and requested installation checks passed. Runtime/API/model tests are separate.'
