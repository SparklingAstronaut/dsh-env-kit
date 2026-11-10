param([Parameter(Mandatory=$true)][string]$DshHome,[string]$DshExe,[switch]$Hidden)
. "$PSScriptRoot\Common.ps1"
$DshHome = Full-Path $DshHome
Assert-NoLinks $DshHome
$marker = Read-Json (Join-Path $DshHome '.env-kit.json')
if (-not $DshExe) { $DshExe = $marker.dshExe }
$DshExe = Full-Path $DshExe
Assert-Host $DshExe (Read-Json (Join-Path $KitRoot 'manifest.json'))
Assert-Stopped $DshHome
Test-Payload $DshHome
$appRoot = Split-Path $DshExe -Parent
$logs = Join-Path $DshHome 'kit-logs'
$null = New-Item -ItemType Directory -Path $logs -Force
$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff')
$saved = @{}
foreach ($name in @('DSH_HOME','DSH_GEMINI_VOICE_HOME','DSH_OFFICIAL_RUNTIME','ELECTRON_RUN_AS_NODE')) { $saved[$name] = [Environment]::GetEnvironmentVariable($name,'Process') }
try {
    $env:DSH_HOME = $DshHome
    $env:DSH_GEMINI_VOICE_HOME = Join-Path $DshHome 'gemini-voice'
    $env:DSH_OFFICIAL_RUNTIME = Join-Path $appRoot 'resources\app.asar\dsh'
    Remove-Item Env:ELECTRON_RUN_AS_NODE -ErrorAction SilentlyContinue
    $style = if ($Hidden) { 'Hidden' } else { 'Normal' }
    $process = Start-Process -FilePath $DshExe -ArgumentList ('--user-data-dir="' + (Join-Path $DshHome 'electron-user-data') + '"') -WorkingDirectory $DshHome -WindowStyle $style -PassThru -RedirectStandardOutput (Join-Path $logs "$stamp.out.log") -RedirectStandardError (Join-Path $logs "$stamp.err.log")
    if ($process.WaitForExit(2000)) { throw 'DSH exited during startup. Inspect this home''s private kit-logs directory.' }
    Write-Json (Join-Path $DshHome '.env-kit-running.json') @{processId=$process.Id; startedUtc=$process.StartTime.ToUniversalTime().ToString('o')}
    Write-Output "Started isolated DSH process $($process.Id)."
} finally {
    foreach ($name in $saved.Keys) {
        if ($null -eq $saved[$name]) { Remove-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue }
        else { [Environment]::SetEnvironmentVariable($name,$saved[$name],'Process') }
    }
}
