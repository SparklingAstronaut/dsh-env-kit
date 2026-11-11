$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$script:KitRoot = Split-Path $PSScriptRoot -Parent

function Read-Json([string]$Path) {
    Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}
function Write-Json([string]$Path, $Value) {
    $text = $Value | ConvertTo-Json -Depth 30
    [IO.File]::WriteAllText($Path, $text, (New-Object Text.UTF8Encoding($false)))
}
function Full-Path([string]$Path) {
    if (-not [IO.Path]::IsPathRooted($Path)) { throw '请使用绝对路径。' }
    [IO.Path]::GetFullPath($Path).TrimEnd('\','/')
}
function Test-Member($Object, [string]$Name) {
    $null -ne $Object -and $null -ne $Object.PSObject.Properties[$Name]
}
function Set-Member($Object, [string]$Name, $Value) {
    $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force
}
function Assert-NoLinks([string]$Path) {
    $current = Full-Path $Path
    while ($current) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "不支持链接目录：$current" }
        }
        $parent = Split-Path $current -Parent
        if (-not $parent -or $parent -eq $current) { break }
        $current = $parent
    }
}
function Assert-Hash([string]$Path,[string]$Expected) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "缺少文件：$Path" }
    if ((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -ne $Expected) { throw "文件校验不一致（可能下载不完整）：$Path" }
}

# ---- 找到官方 DSH 程序和它的默认数据目录 ----
function Resolve-DshExe([string]$DshExe) {
    $leaf = 'DeepSeek Harness.exe'
    if ($DshExe) {
        $DshExe = Full-Path $DshExe
        if (-not (Test-Path -LiteralPath $DshExe -PathType Leaf)) { throw "找不到 DSH 程序：$DshExe" }
        return $DshExe
    }
    $candidates = New-Object Collections.Generic.List[string]
    foreach ($key in 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*') {
        foreach ($entry in @(Get-ItemProperty -Path $key -ErrorAction SilentlyContinue)) {
            if (-not (Test-Member $entry 'DisplayName') -or $entry.DisplayName -notlike 'DeepSeek Harness*') { continue }
            if ((Test-Member $entry 'InstallLocation') -and $entry.InstallLocation) { $candidates.Add((Join-Path $entry.InstallLocation.Trim('"') $leaf)) }
            if ((Test-Member $entry 'DisplayIcon') -and $entry.DisplayIcon) { $candidates.Add((Join-Path (Split-Path ($entry.DisplayIcon -replace ',\d+$','').Trim('"') -Parent) $leaf)) }
        }
    }
    if ($env:LOCALAPPDATA) { $candidates.Add((Join-Path $env:LOCALAPPDATA "Programs\DeepSeek Harness\$leaf")) }
    if ($env:ProgramFiles) { $candidates.Add((Join-Path $env:ProgramFiles "DeepSeek Harness\$leaf")) }
    try {
        $shell = New-Object -ComObject WScript.Shell
        $folders = @([Environment]::GetFolderPath('Programs'),[Environment]::GetFolderPath('CommonPrograms'),[Environment]::GetFolderPath('Desktop'),[Environment]::GetFolderPath('CommonDesktopDirectory')) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
        foreach ($link in @(Get-ChildItem -LiteralPath $folders -Filter '*.lnk' -Recurse -ErrorAction SilentlyContinue)) {
            $target = $shell.CreateShortcut($link.FullName).TargetPath
            if ($target -and (Split-Path $target -Leaf) -eq $leaf) { $candidates.Add($target) }
        }
    } catch { }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return (Full-Path $candidate) }
    }
    throw "没有找到已安装的 DeepSeek Harness。请先安装官方 DSH；如果装在特殊位置，运行时加上 -DshExe '<DeepSeek Harness.exe 的完整路径>'。"
}
function Resolve-DshHome([string]$DshHome) {
    if ($DshHome) { return (Full-Path $DshHome) }
    if ($env:DSH_HOME -and $env:DSH_HOME.Trim()) { return (Full-Path $env:DSH_HOME.Trim()) }
    Full-Path (Join-Path $env:USERPROFILE '.dsh')
}
function Get-HostVersion([string]$DshExe) {
    $asar = Join-Path (Split-Path $DshExe -Parent) 'resources\app.asar'
    $reader = New-Object IO.BinaryReader([IO.File]::OpenRead($asar))
    try {
        $null = $reader.ReadUInt32()
        $headerSize = $reader.ReadUInt32()
        $null = $reader.ReadUInt32()
        $jsonSize = $reader.ReadUInt32()
        $json = [Text.Encoding]::UTF8.GetString($reader.ReadBytes($jsonSize))
        # The archive index is larger than Windows PowerShell's ConvertFrom-Json limit.
        Add-Type -AssemblyName System.Web.Extensions
        $serializer = New-Object Web.Script.Serialization.JavaScriptSerializer
        $serializer.MaxJsonLength = [int]::MaxValue
        $serializer.RecursionLimit = 500
        $entry = $serializer.DeserializeObject($json)['files']['package.json']
        $null = $reader.BaseStream.Seek((8 + [long]$headerSize + [long]$entry['offset']), [IO.SeekOrigin]::Begin)
        $package = [Text.Encoding]::UTF8.GetString($reader.ReadBytes([int]$entry['size'])) | ConvertFrom-Json
        $package.version
    } finally { $reader.Dispose() }
}
function Assert-Host([string]$DshExe, $Manifest) {
    $version = Get-HostVersion $DshExe
    if ($version -ne $Manifest.hostVersion) { throw "本套件对应官方 DSH $($Manifest.hostVersion)，你安装的是 $version。请安装对应版本后再试。" }
}
function Assert-NotRunning([string]$DshExe) {
    $running = @(Get-Process -Name 'DeepSeek Harness' -ErrorAction SilentlyContinue | Where-Object { try { $_.Path -eq $DshExe } catch { $false } })
    if ($running.Count) { throw '请先完全退出 DeepSeek Harness（右下角托盘图标 → 退出），再重新运行。' }
}

# ---- 文件操作 ----
function Expand-SafeZip([string]$Archive,[string]$Destination) {
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $root = (Full-Path $Destination) + '\'
    $zip = [IO.Compression.ZipFile]::OpenRead($Archive)
    try {
        foreach ($entry in $zip.Entries) {
            if ($entry.FullName -match '(^|[\\/])\.\.([\\/]|$)|:|^[\\/]') { throw '压缩包内有不安全的路径。' }
            $target = [IO.Path]::GetFullPath((Join-Path $Destination $entry.FullName))
            if (-not $target.StartsWith($root,[StringComparison]::OrdinalIgnoreCase)) { throw '压缩包路径越界。' }
            if (($entry.ExternalAttributes -shr 16 -band 0xF000) -eq 0xA000) { throw '压缩包内不允许链接。' }
        }
        [IO.Compression.ZipFileExtensions]::ExtractToDirectory($zip,$Destination)
    } finally { $zip.Dispose() }
}
function Copy-Tree([string]$From,[string]$To,[switch]$Move) {
    $options = @('/E','/XJ','/R:1','/W:1','/NFL','/NDL','/NJH','/NJS','/NP')
    if ($Move) { $options += '/MOVE' }
    & robocopy $From $To @options | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "复制失败：$From" }
    $global:LASTEXITCODE = 0
}
function Remove-Tree([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return }
    # rd removes a junction itself and never follows it into its target.
    & cmd /c rd /s /q "`"$Path`""
    if (Test-Path -LiteralPath $Path) { throw "无法删除：$Path" }
    $global:LASTEXITCODE = 0
}
function Replace-Tree([string]$From,[string]$To) {
    Remove-Tree $To
    Move-Item -LiteralPath $From -Destination $To
}

# ---- 把插件装进官方 profile ----
# 默认设置逐条合并：用户已有的条目一律不动，只补上缺少的条目。
function Merge-Settings([string]$KitFile,[string]$UserFile) {
    $utf8 = New-Object Text.UTF8Encoding($false)
    $kit = [IO.File]::ReadAllText($KitFile)
    $user = if (Test-Path -LiteralPath $UserFile) { [IO.File]::ReadAllText($UserFile) } else { '' }
    $body = @($user -split "`r?`n" | Where-Object { $_.Trim() -and -not $_.TrimStart().StartsWith('#') })
    if (-not $body.Count -or (($body -join '').Trim() -eq '[]')) {
        [IO.File]::WriteAllText($UserFile, $kit, $utf8); return 'created'
    }
    if (@($body | Where-Object { $_ -notmatch '^(- |\s)' }).Count) { return 'kept' }
    $have = @([regex]::Matches($user, '(?m)^(?:- |  )id:\s*["'']?([^"''\r\n#]+?)["'']?\s*$') | ForEach-Object { $_.Groups[1].Value })
    $add = New-Object Text.StringBuilder
    $take = $false
    foreach ($line in ($kit -split "`r?`n")) {
        if ($line -match '^- id:\s*(.+?)\s*$') { $take = $have -notcontains $Matches[1] }
        elseif ($line -notmatch '^\s') { $take = $false }
        if ($take) { $null = $add.Append($line).Append("`n") }
    }
    if (-not $add.Length) { return 'kept' }
    [IO.File]::WriteAllText($UserFile, ($user.TrimEnd("`r","`n") + "`n" + $add.ToString()), $utf8)
    'merged'
}
function Install-KitProfile([string]$Stage,[string]$ProfileDir,$Manifest) {
    $source = Join-Path $Stage 'profiles\desktop'
    $null = New-Item -ItemType Directory -Path $ProfileDir -Force
    $kitPackage = Read-Json (Join-Path $source 'package.json')
    $kitNames = @($Manifest.plugins | ForEach-Object { $_.name })
    $packagePath = Join-Path $ProfileDir 'package.json'
    $extras = @()
    if (Test-Path -LiteralPath $packagePath) {
        $package = Read-Json $packagePath
        if (-not (Test-Member $package 'dependencies') -or $null -eq $package.dependencies) { Set-Member $package 'dependencies' (New-Object PSObject) }
        if (-not (Test-Member $package 'dsh')) { Set-Member $package 'dsh' (New-Object PSObject) }
        if (-not (Test-Member $package.dsh 'profile')) { Set-Member $package.dsh 'profile' (New-Object PSObject) }
        $existing = if (Test-Member $package.dsh.profile 'bundles') { @($package.dsh.profile.bundles) } else { @() }
        $extras = @($package.dependencies.PSObject.Properties | ForEach-Object { $_.Name } | Where-Object { $kitNames -notcontains $_ })
        foreach ($dependency in $kitPackage.dependencies.PSObject.Properties) { Set-Member $package.dependencies $dependency.Name $dependency.Value }
        $bundles = @($Manifest.bundles) + @($existing | Where-Object { $Manifest.bundles -notcontains $_ })
        Set-Member $package.dsh.profile 'bundles' $bundles
        Set-Member $package 'dshEnvKit' $kitPackage.dshEnvKit
    } else { $package = $kitPackage }

    # Real directories in the hoisted layout; a same-named older copy is replaced, everything else stays.
    $modules = Join-Path $ProfileDir 'node_modules'
    $null = New-Item -ItemType Directory -Path $modules -Force
    foreach ($item in Get-ChildItem -LiteralPath (Join-Path $source 'node_modules') -Force) {
        if ($item.Name.StartsWith('@')) {
            $scope = Join-Path $modules $item.Name
            $null = New-Item -ItemType Directory -Path $scope -Force
            foreach ($child in Get-ChildItem -LiteralPath $item.FullName -Force) { Replace-Tree $child.FullName (Join-Path $scope $child.Name) }
        } else { Replace-Tree $item.FullName (Join-Path $modules $item.Name) }
    }
    # Stale package-manager indexes would describe the old tree; DSH and pnpm rebuild them.
    foreach ($name in '.modules.yaml','.pnpm-workspace-state-v1.json','.package-map.json') {
        $file = Join-Path $modules $name
        if (Test-Path -LiteralPath $file -PathType Leaf) { Remove-Item -LiteralPath $file -Force }
    }
    $pinned = Join-Path $ProfileDir 'pinned-packages'
    $null = New-Item -ItemType Directory -Path $pinned -Force
    Copy-Item -Path (Join-Path $source 'pinned-packages\*.tgz') -Destination $pinned -Force
    $lock = Join-Path $ProfileDir 'pnpm-lock.yaml'
    if (-not $extras.Count -or -not (Test-Path -LiteralPath $lock)) { Copy-Item -LiteralPath (Join-Path $source 'pnpm-lock.yaml') -Destination $lock -Force }
    $workspace = Join-Path $ProfileDir 'pnpm-workspace.yaml'
    if (-not (Test-Path -LiteralPath $workspace)) { Copy-Item -LiteralPath (Join-Path $source 'pnpm-workspace.yaml') -Destination $workspace }
    Write-Json $packagePath $package
    $settings = Merge-Settings (Join-Path $source 'cordis.patch.yml') (Join-Path $ProfileDir 'cordis.patch.yml')
    New-Object PSObject -Property @{ extras = $extras; settings = $settings }
}
function Install-KitHomeFiles([string]$Stage,[string]$DshHome) {
    $agents = Join-Path $DshHome 'AGENTS.md'
    if (-not (Test-Path -LiteralPath $agents)) { Copy-Item -LiteralPath (Join-Path $Stage 'AGENTS.md') -Destination $agents }
    $skills = Join-Path $DshHome 'skills'
    $null = New-Item -ItemType Directory -Path $skills -Force
    foreach ($skill in Get-ChildItem -LiteralPath (Join-Path $Stage 'skills') -Directory) {
        $target = Join-Path $skills $skill.Name
        if (-not (Test-Path -LiteralPath $target)) { Copy-Tree $skill.FullName $target }
    }
    Copy-Tree (Join-Path $Stage 'companions\whale-desktop') (Join-Path $DshHome 'companions\whale-desktop') -Move
}
function Test-Installed([string]$DshHome,$Manifest) {
    $profileDir = Join-Path $DshHome 'profiles\desktop'
    $package = Read-Json (Join-Path $profileDir 'package.json')
    foreach ($plugin in $Manifest.plugins) {
        if (-not (Test-Member $package.dependencies $plugin.name) -or $package.dependencies.($plugin.name) -ne $plugin.source) { throw "插件声明不一致：$($plugin.name)" }
        $installed = Join-Path $profileDir "node_modules\$($plugin.name)\package.json"
        if (-not (Test-Path -LiteralPath $installed) -or (Read-Json $installed).version -ne $plugin.version) { throw "插件未装好：$($plugin.name)" }
        Assert-Hash (Join-Path $profileDir ($plugin.source -replace '^file:\./','')) $plugin.sha256
    }
    foreach ($bundle in $Manifest.bundles) {
        if (@($package.dsh.profile.bundles) -notcontains $bundle) { throw "插件未启用：$bundle" }
    }
}
function Restore-KitBackup([string]$DshHome,[string]$Backup,[bool]$HadProfile) {
    $profileDir = Join-Path $DshHome 'profiles\desktop'
    if (Test-Path -LiteralPath $profileDir) {
        $aside = Join-Path $Backup ('profile-with-kit-' + [guid]::NewGuid().ToString('N').Substring(0,6))
        Move-Item -LiteralPath $profileDir -Destination $aside
    }
    if ($HadProfile) { Copy-Tree (Join-Path $Backup 'profiles-desktop') $profileDir }
    $marker = Join-Path $DshHome '.env-kit.json'
    if (Test-Path -LiteralPath $marker) { Remove-Item -LiteralPath $marker -Force }
}

# ---- 发布包完整性（仓库自测用）----
function Test-Payload([string]$DshHome, [switch]$Pristine) {
    $inventory = Read-Json (Join-Path $script:KitRoot 'payload-files.json')
    foreach ($entry in $inventory.PSObject.Properties) {
        # Users own their settings and instructions after first launch.
        if (-not $Pristine -and $entry.Name -in @('profiles/desktop/cordis.patch.yml','AGENTS.md')) { continue }
        # pnpm owns the dependency layout and lockfile after plugin operations.
        if (-not $Pristine -and ($entry.Name -in @('profiles/desktop/package.json','profiles/desktop/pnpm-lock.yaml') -or $entry.Name.StartsWith('profiles/desktop/node_modules/'))) { continue }
        Assert-Hash (Join-Path $DshHome $entry.Name) $entry.Value
    }
    $manifest = Read-Json (Join-Path $script:KitRoot 'manifest.json')
    $profile = Read-Json (Join-Path $DshHome 'profiles\desktop\package.json')
    if ($Pristine -and @($profile.dependencies.PSObject.Properties).Count -ne @($manifest.plugins).Count) { throw 'Unexpected plugin composition.' }
    foreach ($plugin in $manifest.plugins) {
        if ($profile.dependencies.($plugin.name).Replace('file:./','file:') -ne $plugin.source.Replace('file:./','file:')) { throw "Plugin declaration drift: $($plugin.name). Restore its versioned archive source." }
        $installed = Read-Json (Join-Path $DshHome "profiles/desktop/node_modules/$($plugin.name)/package.json")
        if ($installed.version -ne $plugin.version) { throw 'Installed plugin version drift.' }
        if (-not $Pristine) {
            $prefix = "profiles/desktop/node_modules/$($plugin.name)/"
            foreach ($entry in $inventory.PSObject.Properties) {
                if ($entry.Name.StartsWith($prefix) -and -not $entry.Name.Substring($prefix.Length).StartsWith('node_modules/')) {
                    Assert-Hash (Join-Path $DshHome $entry.Name) $entry.Value
                }
            }
        }
    }
}
function Reset-PackageManagerState([string]$DshHome) {
    foreach ($name in @('.modules.yaml','.pnpm-workspace-state-v1.json')) {
        $file = Join-Path $DshHome "profiles/desktop/node_modules/$name"
        if (Test-Path -LiteralPath $file -PathType Leaf) { Remove-Item -LiteralPath $file }
    }
}
