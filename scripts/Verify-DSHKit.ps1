param([string]$DshHome,[string]$DshExe)
. "$PSScriptRoot\Common.ps1"
trap { Write-Host ''; Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }
$manifest = Read-Json (Join-Path $KitRoot 'manifest.json')
Assert-Hash (Join-Path $KitRoot $manifest.payload.file) $manifest.payload.sha256
$DshExe = Resolve-DshExe $DshExe
Assert-Host $DshExe $manifest
$DshHome = Resolve-DshHome $DshHome
Test-Installed $DshHome $manifest
$marker = Join-Path $DshHome '.env-kit.json'
if ((Test-Path -LiteralPath $marker) -and (Read-Json $marker).desktopPet -and
    -not (Test-Path -LiteralPath (Join-Path $DshHome 'companions\whale-desktop\node_modules\electron\dist\electron.exe'))) { throw '桌宠运行组件缺失，请重新运行安装。' }
Write-Output "检查通过：官方 DSH $($manifest.hostVersion) + $(@($manifest.plugins).Count) 个插件已装在 $DshHome"
Write-Output '这里只检查文件和版本；登录、API Key、模型和语音需要你在 DSH 里实际试一次。'
