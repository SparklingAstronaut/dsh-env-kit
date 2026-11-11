param([string]$Work)
# Installs into throwaway copies of an official-style DSH home. Works in Windows PowerShell 5.1 and PowerShell 7.
. "$PSScriptRoot\..\scripts\Common.ps1"
if (-not $Work) { $Work = Join-Path ([IO.Path]::GetTempPath()) ('kit-t-' + [guid]::NewGuid().ToString('N').Substring(0,6)) }
$Work = Full-Path $Work
$manifest = Read-Json (Join-Path $KitRoot 'manifest.json')
$archive = Join-Path $KitRoot $manifest.payload.file
function Assert-That($Condition,[string]$Message) { if (-not $Condition) { throw "FAIL: $Message" } }
function New-Stage([string]$DshHome) {
    $stage = Join-Path $DshHome '.kit-stage-test'
    Expand-SafeZip $archive $stage
    $stage
}
function Invoke-Install([string]$DshHome,[switch]$OwnLockfile) {
    $stage = New-Stage $DshHome
    $profileDir = Join-Path $DshHome 'profiles\desktop'
    $backup = Join-Path $DshHome ('env-kit-backups\test-' + [guid]::NewGuid().ToString('N').Substring(0,6))
    $null = New-Item -ItemType Directory -Path $backup -Force
    $had = Test-Path -LiteralPath $profileDir
    if ($had) { Copy-Tree $profileDir (Join-Path $backup 'profiles-desktop') }
    $result = @(Install-KitProfile $stage $profileDir $manifest)[-1]
    $null = Install-KitHomeFiles $stage $DshHome
    Remove-Tree $stage
    Test-Installed $DshHome $manifest
    # A home with other plugins keeps its own lockfile, which the lockfile contract does not describe.
    if (-not $OwnLockfile) {
        & node "$PSScriptRoot\contracts.mjs" $DshHome | Out-Host
        if ($LASTEXITCODE -ne 0) { throw 'Plugin contract regression.' }
    }
    New-Object PSObject -Property @{ result = $result; backup = $backup; had = $had }
}
$utf8 = New-Object Text.UTF8Encoding($false)

# 1. A home where the official app has only been opened once.
$fresh = Join-Path $Work 'fresh'
$profileDir = Join-Path $fresh 'profiles\desktop'
$null = New-Item -ItemType Directory -Path (Join-Path $profileDir 'node_modules') -Force
[IO.File]::WriteAllText((Join-Path $profileDir 'package.json'), '{"name":"dsh-profile-desktop","private":true,"dependencies":{},"dsh":{"profile":{"bundles":["@deepseek-ai/dsh-base","@deepseek-ai/dsh-web-app"]}}}', $utf8)
[IO.File]::WriteAllText((Join-Path $profileDir 'cordis.yml'), "[]`n", $utf8)
[IO.File]::WriteAllText((Join-Path $profileDir 'node_modules\.modules.yaml'), "stale`n", $utf8)
$run = Invoke-Install $fresh
Assert-That (-not $run.result.extras.Count) 'fresh home has no other plugins'
Assert-That ($run.result.settings -eq 'created') 'fresh home receives default settings'
Assert-That (@((Read-Json (Join-Path $profileDir 'package.json')).dsh.profile.bundles).Count -eq @($manifest.bundles).Count) 'fresh bundles equal kit bundles'
Assert-That (-not (Test-Path -LiteralPath (Join-Path $profileDir 'node_modules\.modules.yaml'))) 'stale package index removed'
Assert-That ((Get-FileHash -LiteralPath (Join-Path $profileDir 'pnpm-lock.yaml')).Hash -eq (Read-Json (Join-Path $KitRoot 'payload-files.json')).'profiles/desktop/pnpm-lock.yaml') 'kit lockfile installed'
Assert-That (Test-Path -LiteralPath (Join-Path $fresh 'skills\story\SKILL.md')) 'skills copied'
Assert-That ((Get-Content -LiteralPath (Join-Path $profileDir 'node_modules\dsh-whale-desktop-integration\index.mjs') -Raw).Contains("homedir(),'.dsh'")) 'desktop pet works without a launcher'

# 2. A home that already has its own settings, instructions, another plugin and another bundle.
$used = Join-Path $Work 'used'
$profileDir = Join-Path $used 'profiles\desktop'
$other = Join-Path $profileDir 'node_modules\my-other-plugin'
$null = New-Item -ItemType Directory -Path $other -Force
[IO.File]::WriteAllText((Join-Path $other 'package.json'), '{"name":"my-other-plugin","version":"9.9.9"}', $utf8)
$stale = Join-Path $profileDir 'node_modules\dsh-gemini-voice'
$null = New-Item -ItemType Directory -Path $stale -Force
[IO.File]::WriteAllText((Join-Path $stale 'package.json'), '{"name":"dsh-gemini-voice","version":"0.3.4"}', $utf8)
[IO.File]::WriteAllText((Join-Path $profileDir 'package.json'), '{"name":"dsh-profile-desktop","private":true,"dependencies":{"my-other-plugin":"9.9.9","dsh-gemini-voice":"0.3.4"},"dsh":{"profile":{"bundles":["@deepseek-ai/dsh-base","@deepseek-ai/dsh-web-app","my-other-plugin","dsh-gemini-voice"]}}}', $utf8)
[IO.File]::WriteAllText((Join-Path $profileDir 'pnpm-lock.yaml'), "user lock`n", $utf8)
$userSettings = "- id: locale`r`n  config:`r`n    preference: en`r`n- id: agent-default-model`r`n  config:`r`n    model: mine`r`n"
[IO.File]::WriteAllText((Join-Path $profileDir 'cordis.patch.yml'), $userSettings, $utf8)
[IO.File]::WriteAllText((Join-Path $used 'AGENTS.md'), "my own rules`n", $utf8)
$before = [IO.File]::ReadAllText((Join-Path $profileDir 'package.json'))
$run = Invoke-Install $used -OwnLockfile
$package = Read-Json (Join-Path $profileDir 'package.json')
Assert-That (($run.result.extras -join ',') -eq 'my-other-plugin') 'other plugin reported'
Assert-That ($package.dependencies.'my-other-plugin' -eq '9.9.9') 'other plugin declaration kept'
Assert-That (Test-Path -LiteralPath (Join-Path $other 'package.json')) 'other plugin files kept'
Assert-That (@($package.dsh.profile.bundles) -contains 'my-other-plugin') 'other bundle kept'
Assert-That (@($package.dsh.profile.bundles | Where-Object { $_ -eq 'dsh-gemini-voice' }).Count -eq 1) 'no duplicate bundle'
Assert-That ([IO.File]::ReadAllText((Join-Path $profileDir 'pnpm-lock.yaml')) -eq "user lock`n") 'existing lockfile left for the package manager'
$settings = [IO.File]::ReadAllText((Join-Path $profileDir 'cordis.patch.yml'))
Assert-That ($settings.StartsWith($userSettings.TrimEnd())) 'user settings untouched'
Assert-That (([regex]::Matches($settings,'(?m)^- id: locale')).Count -eq 1 -and $settings.Contains('preference: en')) 'user language choice wins'
Assert-That ($settings.Contains('- id: doublecheck-guard') -and $settings.Contains('- id: doublecheck-grill')) 'missing defaults appended'
Assert-That ([IO.File]::ReadAllText((Join-Path $used 'AGENTS.md')) -eq "my own rules`n") 'user instructions untouched'
Assert-That ($run.result.settings -eq 'merged') 'settings merged'
# Installing again over the result changes nothing that matters.
$run2 = Invoke-Install $used -OwnLockfile
Assert-That ([IO.File]::ReadAllText((Join-Path $profileDir 'cordis.patch.yml')) -eq $settings) 'repeat install keeps settings'
Assert-That ($run2.result.settings -eq 'kept') 'repeat install adds nothing'
# Undo returns the profile exactly as it was before the first install.
Restore-KitBackup $used $run.backup $true
Assert-That ([IO.File]::ReadAllText((Join-Path $profileDir 'package.json')) -eq $before) 'undo restores declarations'
Assert-That ((Read-Json (Join-Path $stale 'package.json')).version -eq '0.3.4') 'undo restores previous plugin files'
Assert-That ([IO.File]::ReadAllText((Join-Path $profileDir 'cordis.patch.yml')) -eq $userSettings) 'undo restores settings'

# 3. Settings in a shape this kit does not understand are left alone.
$odd = Join-Path $Work 'odd.yml'
[IO.File]::WriteAllText($odd, "{ strange: true }`n", $utf8)
Assert-That ((Merge-Settings (Join-Path $fresh 'profiles\desktop\cordis.patch.yml') $odd) -eq 'kept') 'unknown settings shape kept'
Assert-That ([IO.File]::ReadAllText($odd) -eq "{ strange: true }`n") 'unknown settings file unchanged'
Remove-Tree $Work
Write-Output 'PASS: fresh official home, existing home merge, repeat install, undo, settings safety.'
