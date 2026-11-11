param([string]$DshHome,[string]$DshExe,[switch]$Force)
. "$PSScriptRoot\Common.ps1"
trap { Write-Host ''; Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }
$DshHome = Resolve-DshHome $DshHome
Assert-NoLinks $DshHome
$marker = Join-Path $DshHome '.env-kit.json'
if (-not (Test-Path -LiteralPath $marker)) { throw '这个 DSH 数据目录里没有本套件的安装记录，无需撤销。' }
$record = Read-Json $marker
if (-not (Test-Member $record 'layout') -or $record.layout -ne 'official-home') { throw '这是旧版套件的独立目录，不是官方数据目录；直接删除它的快捷方式即可。' }
if (-not $Force) { Assert-NotRunning (Resolve-DshExe $(if ($DshExe) { $DshExe } else { $record.dshExe })) }
if ($record.hadProfile -and -not (Test-Path -LiteralPath (Join-Path $record.backup 'profiles-desktop'))) { throw "找不到安装前的备份：$($record.backup)" }
$null = New-Item -ItemType Directory -Path $record.backup -Force
Restore-KitBackup $DshHome $record.backup ([bool]$record.hadProfile)
Write-Output '已撤销：DSH 的插件环境恢复到安装套件之前的状态。'
Write-Output "带插件的那份环境没有删除，保存在：$($record.backup)"
Write-Output '登录信息和聊天记录不受影响。套件带来的三个提示词技能、AGENTS.md 和桌宠组件仍留在数据目录里，不影响使用。'
