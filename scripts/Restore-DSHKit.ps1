param([Parameter(Mandatory=$true)][string]$BackupPath,[Parameter(Mandatory=$true)][string]$DshHome,[Parameter(Mandatory=$true)][string]$DshExe)
. "$PSScriptRoot\Common.ps1"
$BackupPath=Full-Path $BackupPath
$DshHome=Full-Path $DshHome
$DshExe=Full-Path $DshExe
Assert-NoLinks $BackupPath
Assert-NoLinks $DshHome
Assert-Stopped $BackupPath
Assert-Host $DshExe (Read-Json (Join-Path $KitRoot 'manifest.json'))
if (Test-Path -LiteralPath $DshHome) { throw 'Restore target must not exist.' }
if (-not (Test-Path -LiteralPath (Join-Path $BackupPath '.env-kit.json'))) { throw 'Source is not a kit backup.' }
if ($DshHome.StartsWith($BackupPath+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Target cannot be inside the backup.' }
Test-Payload $BackupPath
foreach ($item in Get-ChildItem -LiteralPath $BackupPath -Recurse -Force) {
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Backup contains linked paths; restore manually after reviewing them.' }
}
$parent=Split-Path $DshHome -Parent
$null=New-Item -ItemType Directory -Path $parent -Force
$stage=Join-Path $parent ((Split-Path $DshHome -Leaf)+'.staging-'+[guid]::NewGuid().ToString('N'))
Copy-Item -LiteralPath $BackupPath -Destination $stage -Recurse
Reset-PackageManagerState $stage
Test-Payload $stage
$marker=Read-Json (Join-Path $stage '.env-kit.json')
$marker.dshExe=$DshExe
Write-Json (Join-Path $stage '.env-kit.json') $marker
if ((Split-Path (Full-Path $stage) -Parent) -ne $parent) { throw 'Staging location mismatch.' }
if (Test-Path -LiteralPath $DshHome) { throw 'Target appeared during restore; staging retained.' }
Move-Item -LiteralPath $stage -Destination $DshHome
Write-Output 'Private backup restored to the new path; original backup retained.'
