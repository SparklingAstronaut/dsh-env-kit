param(
    [string]$DshExe,
    [string]$DshHome,
    [string]$ElectronArchive,
    [switch]$SkipDesktopPet,
    [switch]$Force
)
. "$PSScriptRoot\Common.ps1"
trap { Write-Host ''; Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }
$manifest = Read-Json (Join-Path $KitRoot 'manifest.json')
try { $DshExe = Resolve-DshExe $DshExe } catch {
    if ($DshExe -or [Console]::IsInputRedirected) { throw }
    Write-Output $_.Exception.Message
    $DshExe = Resolve-DshExe ((Read-Host '请把 DeepSeek Harness.exe 拖进这个窗口，然后按回车').Trim().Trim('"'))
}
Assert-Host $DshExe $manifest
$DshHome = Resolve-DshHome $DshHome
Assert-NoLinks $DshHome
if ($DshHome.Length -gt 100) { throw "DSH 数据目录路径太长，Windows 可能放不下插件文件：$DshHome" }
if (-not $Force) { Assert-NotRunning $DshExe }
$archive = Join-Path $KitRoot $manifest.payload.file
Assert-Hash $archive $manifest.payload.sha256
Write-Output "官方 DSH：$DshExe"
Write-Output "插件将装进官方数据目录：$DshHome"

$profileDir = Join-Path $DshHome 'profiles\desktop'
$marker = Join-Path $DshHome '.env-kit.json'
if (Test-Path -LiteralPath $marker) {
    $previous = Read-Json $marker
    if ((Test-Member $previous 'payloadSha256') -and $previous.payloadSha256 -eq $manifest.payload.sha256) {
        try {
            Test-Installed $DshHome $manifest
            Write-Output '这一版插件已经装好，无需重复安装。直接从 DeepSeek Harness 官方图标打开即可。'
            exit 0
        } catch { Write-Output '检测到上次安装不完整，重新安装……' }
    }
}

$null = New-Item -ItemType Directory -Path $DshHome -Force
$stage = Join-Path $DshHome ('.kit-stage-' + [guid]::NewGuid().ToString('N').Substring(0,8))
$backup = Join-Path $DshHome ('env-kit-backups\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$hadProfile = Test-Path -LiteralPath $profileDir
$changed = $false
try {
    Write-Output '[1/4] 解压插件包（约一两分钟）……'
    Expand-SafeZip $archive $stage
    if (-not $SkipDesktopPet) {
        $bundled = Join-Path (Split-Path $KitRoot -Parent) ('electron-v' + $manifest.companion.version + '-win32-x64.zip')
        if (-not $ElectronArchive -and (Test-Path -LiteralPath $bundled)) { $ElectronArchive = $bundled }
        if (-not $ElectronArchive) {
            Write-Output '      下载桌宠运行组件……'
            $ElectronArchive = $stage + '-electron.zip'
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -UseBasicParsing -Uri $manifest.companion.url -OutFile $ElectronArchive
        }
        $ElectronArchive = (Resolve-Path -LiteralPath $ElectronArchive).ProviderPath
        Assert-Hash $ElectronArchive $manifest.companion.sha256
        $electronTarget = Join-Path $stage 'companions\whale-desktop\node_modules\electron\dist'
        $null = New-Item -ItemType Directory -Path (Split-Path $electronTarget -Parent) -Force
        Expand-SafeZip $ElectronArchive $electronTarget
    }
    Write-Output '[2/4] 备份现有环境……'
    $null = New-Item -ItemType Directory -Path $backup -Force
    if ($hadProfile) { Copy-Tree $profileDir (Join-Path $backup 'profiles-desktop') }
    $changed = $true
    Write-Output '[3/4] 安装插件……'
    $result = @(Install-KitProfile $stage $profileDir $manifest)[-1]
    $null = Install-KitHomeFiles $stage $DshHome
    Write-Json $marker @{
        version=$manifest.version; payloadSha256=$manifest.payload.sha256; layout='official-home'; dshExe=$DshExe
        installedUtc=[DateTime]::UtcNow.ToString('o'); desktopPet=(-not $SkipDesktopPet); backup=$backup; hadProfile=$hadProfile
    }
    Write-Output '[4/4] 检查安装结果……'
    Test-Installed $DshHome $manifest
} catch {
    $reason = $_.Exception.Message
    if ($changed) {
        try { Restore-KitBackup $DshHome $backup $hadProfile; $state = '已自动恢复到安装前的状态。' }
        catch { $state = "自动恢复失败，安装前的备份在：$backup" }
    } else { $state = '你的 DSH 环境没有被改动。' }
    throw "安装失败：$reason $state"
} finally {
    try { Remove-Tree $stage } catch { }
    if (Test-Path -LiteralPath ($stage + '-electron.zip')) { Remove-Item -LiteralPath ($stage + '-electron.zip') -Force }
}

Write-Output ''
Write-Output "安装完成：$(@($manifest.plugins).Count) 个插件已装进官方 DSH。"
Write-Output '现在直接从 DeepSeek Harness 的官方图标打开即可，不需要其他启动器。'
if ($result.extras.Count) { Write-Output "你原来装的其他插件已保留：$($result.extras -join '、')" }
if ($result.settings -eq 'kept') { Write-Output '你已有的设置文件保持原样，没有写入套件的默认设置。' }
Write-Output "安装前的环境备份在：$backup"
Write-Output '第一次打开会比平时慢一些（要加载新插件），之后恢复正常。登录、API Key 和模型请在 DSH 设置里填写。'
