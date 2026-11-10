param([Parameter(Mandatory=$true)][string]$DshHome,[string]$PnpmScript)
. "$PSScriptRoot\..\scripts\Common.ps1"
function Invoke-Pnpm([string[]]$Arguments) {
    if ($PnpmScript) { & node $PnpmScript @Arguments }
    else { & pnpm.cmd @Arguments }
    if ($LASTEXITCODE -ne 0) { throw 'Package operation failed.' }
}
function Check-Installation([string]$Path) {
    Test-Payload $Path
    & node "$PSScriptRoot\contracts.mjs" $Path
    if ($LASTEXITCODE -ne 0) { throw 'Plugin contract regression.' }
}
$DshHome = Full-Path $DshHome
Check-Installation $DshHome
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('dsh-addon-' + [guid]::NewGuid())
$null = New-Item -ItemType Directory -Path $fixture
Write-Json (Join-Path $fixture 'package.json') @{name='dsh-kit-install-probe';version='0.0.0';private=$true}
Push-Location (Join-Path $DshHome 'profiles\desktop')
try {
    Invoke-Pnpm -Arguments @('add',('file:' + $fixture.Replace('\','/')),'--save-exact','--ignore-scripts')
    Check-Installation $DshHome
    Invoke-Pnpm -Arguments @('--config.ignore-scripts=true','remove','dsh-kit-install-probe')
    Check-Installation $DshHome
} finally { Pop-Location }

# A new directory with no installed packages exercises every recorded source.
$clean = Join-Path ([IO.Path]::GetTempPath()) ('DSH clean restore ' + [guid]::NewGuid())
foreach ($file in Get-ChildItem -LiteralPath $DshHome -File -Recurse -Force) {
    $relative = [IO.Path]::GetRelativePath($DshHome,$file.FullName)
    if ($relative.StartsWith('profiles\desktop\node_modules\')) { continue }
    $target = Join-Path $clean $relative
    $null = New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force
    Copy-Item -LiteralPath $file.FullName -Destination $target
}
Push-Location (Join-Path $clean 'profiles\desktop')
try { Invoke-Pnpm -Arguments @('install','--frozen-lockfile','--ignore-scripts') }
finally { Pop-Location }
Check-Installation $clean

# The relaxed runtime check must still reject a changed pin or overwritten client.
$profilePath = Join-Path $clean 'profiles\desktop\package.json'
$original = [IO.File]::ReadAllBytes($profilePath)
try {
    $profile = Read-Json $profilePath
    $profile.dependencies.'dsh-gemini-voice' = '0.3.4'
    Write-Json $profilePath $profile
    $rejected = $false
    try { Test-Payload $clean } catch { $rejected = $true }
    if (-not $rejected) { throw 'Old voice source was not rejected.' }
} finally { [IO.File]::WriteAllBytes($profilePath,$original) }
$client = Join-Path $clean 'profiles\desktop\node_modules\dsh-gemini-voice\client.js'
$original = [IO.File]::ReadAllBytes($client)
try {
    [IO.File]::AppendAllText($client,"`n// unexpected replacement")
    $rejected = $false
    try { Test-Payload $clean } catch { $rejected = $true }
    if (-not $rejected) { throw 'Overwritten voice client was not rejected.' }
} finally { [IO.File]::WriteAllBytes($client,$original) }
# Moving a managed tree must not retain absolute store paths from its old home.
$moved = Full-Path ($clean + ' moved')
$tempRoot = (Full-Path ([IO.Path]::GetTempPath())) + '\'
if (-not (Full-Path $clean).StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase) -or
    -not $moved.StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase) -or
    (Split-Path $moved -Parent) -ne (Split-Path $clean -Parent)) { throw 'Unexpected relocation paths.' }
Move-Item -LiteralPath $clean -Destination $moved
Reset-PackageManagerState $moved
Push-Location (Join-Path $moved 'profiles\desktop')
try {
    Invoke-Pnpm -Arguments @('add',('file:' + $fixture.Replace('\','/')),'--save-exact','--ignore-scripts')
    Invoke-Pnpm -Arguments @('--config.ignore-scripts=true','remove','dsh-kit-install-probe')
} finally { Pop-Location }
Check-Installation $moved
Write-Output 'PASS: add, remove, clean reinstall, relocation, relative sources, contracts and tamper rejection.'
