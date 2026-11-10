# DSH Environment Kit

[![Verify portable kit](https://github.com/SparklingAstronaut/dsh-env-kit/actions/workflows/verify.yml/badge.svg)](https://github.com/SparklingAstronaut/dsh-env-kit/actions/workflows/verify.yml)

把一套固定的 13 个插件恢复到独立的 Windows DSH 环境。包含插件、完整生产依赖、中文默认设置、三个提示词技能和安装/启动/校验/回滚脚本。

本套件与 **官方 DSH 0.2.2-rc.1、Windows x64、PowerShell 7** 配套。其他 DSH 版本会在安装前被拒绝；升级前应在新目录重新验证兼容性。请先自行安装该版本官方 DSH 和 PowerShell 7。

## 下载

- [标准安装包](https://github.com/SparklingAstronaut/dsh-env-kit/releases/download/v1.0.0/dsh-env-kit-1.0.0.zip)：包含全部插件和依赖；桌面宠物运行组件在安装时下载。
- [完整离线包（Windows x64）](https://github.com/SparklingAstronaut/dsh-env-kit/releases/download/v1.0.0/dsh-env-kit-1.0.0-offline-win-x64.zip)：额外包含已校验的 Electron 桌宠组件；解压后按 `INSTALL-OFFLINE.zh-CN.md` 安装。
- [SHA-256 校验清单](https://github.com/SparklingAstronaut/dsh-env-kit/releases/download/v1.0.0/dsh-env-kit-1.0.0-SHA256SUMS.txt) · [Release 与更新记录](https://github.com/SparklingAstronaut/dsh-env-kit/releases/tag/v1.0.0)

两个安装包均不包含官方 DSH 主程序、模型权重、推理引擎、账号、个人配置或聊天记录。离线包的“离线”指已准备好官方 DSH 和 PowerShell 7 后，安装本套件不再需要下载插件或桌宠组件。

## 安装

在 PowerShell 7 中进入本目录，指定官方程序和一个**尚不存在**的新数据目录：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Install-DSHKit.ps1 `
  -DshExe 'C:\Apps\DSH\DeepSeek Harness.exe' `
  -DshHome 'C:\DSH-kit-home'

pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Start-DSH.ps1 `
  -DshHome 'C:\DSH-kit-home'
```

脚本不修改官方程序、不覆盖已有普通 DSH 目录，也不修改系统环境变量。请始终用本套件的启动脚本打开这个环境；默认官方快捷方式仍指向原来的环境。安装后在设置里填自己的模型、API 密钥和本地模型路径。

插件及 186 个生产包已经固定在 `vendor/plugins-win-x64.zip` 中。安装不运行 npm/pnpm、不执行第三方安装脚本，也不会重新解析依赖版本。完整文件哈希在 `payload-files.json`。

桌面宠物需要 Electron 45.1.0。默认安装会从 Electron 官方 GitHub Release 下载固定的 Windows x64 压缩包，并验证 SHA-256。可预先下载该文件，然后完全离线安装：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Install-DSHKit.ps1 `
  -DshExe 'C:\Apps\DSH\DeepSeek Harness.exe' -DshHome 'C:\DSH-kit-home' `
  -ElectronArchive 'C:\Downloads\electron-v45.1.0-win32-x64.zip'
```

`-SkipDesktopPet` 可跳过桌面组件下载，网页宠物仍在；桌面宠物按钮会提示缺少运行组件。该选项不属于完整桌宠恢复。Electron 的下载 URL 和预期哈希保存在 `manifest.json`。

## 固定组合

| 插件 | 版本 | 用途 |
|---|---|---|
| dsh-better-sidebar | 0.30.1 | 会话与工作区侧栏 |
| dsh-context | 0.83.1 | 上下文洞察 |
| dsh-computer-use-win | 0.5.5 | Windows 电脑操控 |
| dsh-doublecheck | 0.9.30 | 工程检查与验收记录 |
| dsh-gemini-voice | 0.3.4 | Gemini 语音识别 |
| dsh-voice-router | 0.1.2 | Gemini / 云端 API / 本地语音路由 |
| dsh-voice-notify | 1.0.0 | 任务结束语音提醒 |
| dsh-local-llm-controller | 2.0.4-kvmem.1-official.2 | 启停、配置本地推理服务 |
| dsh-paste-spill | 0.2.0 | 长文本粘贴处理 |
| dsh-suggest-ghost | 0.9.0 | 智能追问建议，保留无发光补丁 |
| dsh-whale-desktop-integration | 1.1.6 | 桌宠侧栏、设置与桌面联动 |
| superpowers-dsh | 0.5.0 | 工程工作流技能 |
| whale-girl | 0.2.3 | 网页宠物 |

上述版本是来源包版本。便携修复按文件哈希锁定，详情见 [变更说明](docs/portability.md)。未加入 image-gen、AnySearch、ego-browser 或 prompt-history。

## 首次配置

- **模型**：配置自己的云端供应商，或自行登录官方账号。套件没有预置账号、余额、API 密钥或默认付费模型。
- **本地模型**：在“本地模型”设置里选择自己电脑上的推理程序目录、服务程序名和模型目录。套件不包含模型权重、llama.cpp/KVMem/NInfer 程序、CUDA 驱动，也不会自动下载模型。
- **语音**：按需要填写 Gemini 或兼容云端转写 API。没有云端密钥时需自行准备本地 SenseVoice 所需组件，不能据此认为云端/麦克风已经测通。
- **桌宠**：数据在新 DSH home 的 `companions/whale-desktop` 中，与其他安装隔离。
- **三个提示词技能**：`anima-prompt`、`qwen-prompt`、`story` 仅生成提示词/分镜，不安装图片生成器。

## 校验、回滚与换机

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Verify-DSHKit.ps1 -DshHome 'C:\DSH-kit-home'
```

重复运行安装脚本会校验已有同版本环境并保留设置。普通设置文件允许 DSH 正常改写；插件文件发生变化时会报错，避免悄悄覆盖本地修改。

关闭**这个套件实例**后回滚：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Rollback-DSHKit.ps1 -DshHome 'C:\DSH-kit-home'
```

回滚将整个 home 改名为同级 `.retained-...` 备份，原安装的 DSH 不受影响。不会删除任何内容。备份可能含登录状态、密钥和聊天，必须私下保管，不要上传 GitHub。

换机有两种方式：直接使用套件安装全新环境；或把自己私下保管的同版本备份复制到新电脑，再运行：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Restore-DSHKit.ps1 `
  -BackupPath 'C:\Backups\DSH-kit-home.retained-example' `
  -DshHome 'C:\DSH-kit-home' -DshExe 'C:\Apps\DSH\DeepSeek Harness.exe'
```

恢复会复制到新目录，保留原备份。账号凭据是否能跨电脑解密取决于其上游存储方式，可能需要重新登录；本地模型路径也需改为新电脑的路径。恢复不意味着这些外部服务已经可用。

## 发布与验证

仓库仅包含**本套件的公开文件**。插件压缩包约 66 MiB；包含 Electron 的完整离线包放在 Release，不放进 Git 历史。不要把安装后的 DSH home、私有备份、日志或测试工作目录一起发布。

`python tests/audit.py` 检查文件清单、哈希、敏感路径和密钥特征；`node tests/contracts.mjs <已安装的home>` 检查菜单图标和通知逻辑。线上运行结果见 [GitHub Actions](https://github.com/SparklingAstronaut/dsh-env-kit/actions/workflows/verify.yml)，本地验收与线上结果分别记录。

实际执行结果和限制见 [验收记录](docs/verification.md)。许可、来源和本地补丁归属见 [第三方说明](THIRD_PARTY_NOTICES.md) 与 `third-party.json`。

整理本仓库的发布 ZIP 可运行 `python tools/pack-release.py`；加上 `--electron-archive <官方Electron压缩包路径>` 会额外生成完整离线包和总校验清单。该脚本先检查负载和 Electron 哈希，再生成文件校验清单、发布 ZIP 及其 SHA-256；它不读取现用 DSH，也不上传 GitHub。
