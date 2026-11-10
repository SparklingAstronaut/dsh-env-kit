param([Parameter(Mandatory=$true)][string]$DshHome)
. "$PSScriptRoot\Common.ps1"
$DshHome = Full-Path $DshHome
Assert-NoLinks $DshHome
if (-not (Test-Path -LiteralPath (Join-Path $DshHome '.env-kit.json'))) { throw 'Target is not a kit-owned home.' }
Assert-Stopped $DshHome
$backup = $DshHome + '.retained-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
if ((Split-Path (Full-Path $backup) -Parent) -ne (Split-Path $DshHome -Parent)) { throw 'Backup must be a sibling.' }
Move-Item -LiteralPath $DshHome -Destination $backup
Write-Output "Kit home retained at: $backup"
Write-Output 'All user settings, conversations, credentials and companion state remain in this private backup. Never publish it.'
