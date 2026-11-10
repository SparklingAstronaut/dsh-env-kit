# DSH Environment Kit

[![Verify portable kit](https://github.com/SparklingAstronaut/dsh-env-kit/actions/workflows/verify.yml/badge.svg)](https://github.com/SparklingAstronaut/dsh-env-kit/actions/workflows/verify.yml)

一次装好 13 个 DSH 插件，换电脑也能恢复。**下载、安装、密钥申请、本地模型和 AI 提示词都在本页，按顺序操作即可。**

适用：**Windows x64 · 官方 DSH 0.2.2-rc.1 · PowerShell 7**。套件不包含账号、密钥、聊天记录、模型或推理程序。

想让 AI 代劳？直接复制本页的 [AI 安装提示词](#ai-prompt)。

<a id="install"></a>
## 1. 下载并准备

**[点击下载完整离线包（约 229 MB）](https://github.com/SparklingAstronaut/dsh-env-kit/releases/download/v1.0.0/dsh-env-kit-1.0.0-offline-win-x64.zip)**

整个解压，保留里面 `dsh-env-kit` 文件夹和 `electron-v45.1.0-win32-x64.zip` 的相对位置；Electron ZIP 不用手动解压。只需这个套件包，不用再下载标准包或 “Source code”。

电脑上还需要两个程序，已有符合要求的版本就跳过：

| 程序 | 官方下载入口 | 选择什么 |
|---|---|---|
| DeepSeek Harness | [官网](https://deepseek.com/harness/) · [版本记录](https://github.com/deepseek-ai/deepseek-harness/releases) | **0.2.2-rc.1，Windows x64**。官网最新版可能变化，先核对版本；本套件不接受其他版本。 |
| PowerShell | [微软安装说明](https://learn.microsoft.com/zh-cn/powershell/scripting/install/install-powershell-on-windows) | **PowerShell 7，Windows x64 稳定版**。Windows 自带的 5.1 不够。 |

准备好这两个程序后，安装套件不再下载插件或桌宠组件；云端聊天和语音仍需联网。

**有同版本套件的私有备份、想保留聊天记录？直接按本页的 [备份恢复](#private-backup) 操作，跳过下面的全新安装。**

## 2. 安装并启动

打开解压后的 **`dsh-env-kit` 文件夹**，在这里打开 **PowerShell 7**，粘贴下面的命令：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Install-DSHKit.ps1 `
  -DshExe 'C:\Apps\DSH\DeepSeek Harness.exe' `
  -DshHome 'C:\DSH-kit-home' `
  -ElectronArchive '..\electron-v45.1.0-win32-x64.zip'
```

把 `DshExe` 改成你的 DSH 程序实际位置。`DshHome` 是新的数据目录，安装前**不要创建它**，也不要指向已有 DSH 或备份；可换成其他有写入权限的新路径，后续命令也要保持一致。

看到安装成功后，再运行：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Start-DSH.ps1 `
  -DshHome 'C:\DSH-kit-home'
```

**以后也用这条启动命令。** 默认官方快捷方式可能打开另一个环境。保留解压文件夹；可以让 AI 为这条命令创建“DSH 套件”快捷方式。安装脚本不会覆盖已有的普通 DSH 目录。

<a id="api-keys"></a>
## 3. 登录或填写 API Key

**只配置你需要的功能。** 有效的旧密钥可以继续用；只用本地模型不需要云端 Key，不用语音就跳过语音。

| 要用的功能 | 官方入口与操作 | 在 DSH 哪里填 |
|---|---|---|
| 官方账号模式 | 在 DSH 内直接登录 | 设置 → 账号与余额 |
| DeepSeek 云端 API 聊天 | [打开 DeepSeek API Keys](https://platform.deepseek.com/api_keys) → 登录 → 选择已有密钥或创建密钥 | 设置 → 模型 → 对应供应商；地址填 `https://api.deepseek.com`，模型选账号可用的名称 |
| Gemini 语音识别 | [打开 Google AI Studio](https://aistudio.google.com/apikey) → 登录 Google → 选择项目 → 创建或选择 API Key | 设置 → 语音 → Gemini API Key → 保存 |
| 阿里云语音识别 | [百炼新加坡](https://bailian.console.aliyun.com/ap-southeast-1/model/settings/api-key) / [百炼北京](https://bailian.console.aliyun.com/cn-beijing/model/settings/api-key) → 登录 → 选择业务空间 → 创建或选择 API Key | 设置 → 语音路由 → 对应云端后端 → 填 API 地址和“云端 API Key” → 保存 |

百炼的 **Key、地址和模型要使用同一地域**。语音路由填写控制台给出的 `API Host` 加 `/api/v1`，不是聊天接口的 `/compatible-mode/v1`。新密钥可能只完整显示一次，创建后及时私下保存。

AI 可以打开上面的官方页面并带你操作。需要你接手时，它应明确提示“请在这里登录”或“请把 Key 粘贴到 DSH 的这个输入框，保存后告诉我”，完成后继续。密码、验证码和支付由你操作；充值或开通计费先由你决定。**不要把真实 Key 发进聊天或上传 GitHub。**

网页变化时核对官方说明：[DeepSeek](https://api-docs.deepseek.com/) · [Gemini](https://ai.google.dev/gemini-api/docs/api-key) · [百炼密钥](https://help.aliyun.com/zh/model-studio/get-api-key/) · [百炼地域](https://help.aliyun.com/zh/model-studio/regions)。入口最后核对：2026-11-10。

<a id="local-models"></a>
## 4. 使用本地模型（需要时再做）

先私下复制旧电脑的**模型文件夹和配套推理程序整个文件夹**，包括 DLL 等依赖，并准备适配新显卡的驱动。套件不会自动下载模型；没有这些文件时，先确定模型和硬件，再准备对应引擎。

按当前默认的 **KVMem** 方式配置：

1. 打开 **设置 → 本地模型 → 高级设置**。
2. “llama.cpp 目录”填配套推理程序的文件夹。当前默认寻找 **`llama-kvmem-server.exe`**，普通 `llama-server.exe` 不能直接替代。
3. “模型文件夹”填含 `.gguf` 的目录，首次建议一个文件夹只放一个主模型。先测试文本模式；视觉模式另需匹配的 `mmproj`。
4. 本地“密钥”留空，端口先保留 `55555`。服务只监听本机 `127.0.0.1`，不要填云端 Key。
5. 点 **保存配置 → 启动**，显示“可以聊天”后点 **添加到模型列表**。
6. 回到聊天界面选这个本地模型，发一句“只回复 LOCAL_OK”，确认实际能回复。

<details>
<summary>其他后端、旧配置或启动失败时看这里</summary>

KVMem、NInfer、Prism 的程序、模型格式和参数不同。恢复旧配置时，检查槽位的 `backend`、`engineDir`、`serverExe`、模型目录及文件名，改成新电脑的真实位置，并按显存调整参数。界面没有后端和程序名的直接编辑选项，只改“llama.cpp 目录”可能不够。

新数据目录里的 `local-llm.config.json` 优先于界面配置，槽位路径也可能覆盖公共目录。让 AI 保留原备份，只修改新环境中的配置，不公开个人路径或密钥。

端口被占用时换空闲端口并重新添加到模型列表。路径错误先修路径，驱动或引擎不匹配先修程序，显存不足时调整模型或上下文。没有成功回复前，不应报告模型已可用。

</details>

<a id="verify"></a>
## 5. 确认装好了

在套件文件夹运行，路径与安装时一致：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Verify-DSHKit.ps1 `
  -DshHome 'C:\DSH-kit-home' `
  -DshExe 'C:\Apps\DSH\DeepSeek Harness.exe'
```

再打开 DSH，确认插件已加载、菜单和桌宠能用，并测试你选择的模型和语音。这个命令只校验文件和版本；没有密钥、模型或未实测的功能仍属于“待配置/未测试”。云端测试可能消耗服务额度。

<a id="ai-prompt"></a>
## 不想自己操作？把这段复制给 AI

适合能操作本机文件、终端和浏览器的 AI；只有聊天能力的 AI 可以逐步指导。**不用提前填写路径，也不要把真实密钥放进提示词。**

```text
请按这个仓库首页 README，直接帮我在当前 Windows 电脑安装或换机恢复 DSH 插件环境，不要只给方案：
https://github.com/SparklingAstronaut/dsh-env-kit

先检查电脑、PowerShell 7 和官方 DSH 0.2.2-rc.1，按 README 下载完整离线包、核对校验值，在新目录安装、验证和启动，并创建“DSH 套件”快捷方式。有同版本完整套件备份时，检查后改用备份恢复。保留已有 DSH、其他插件和所有备份，不绕过版本检查，不自动升级插件。

只配置我需要的功能。需要 API Key 时，直接打开 README 中的官方网址，带我创建或选择密钥，并打开 DSH 对应输入框。每次只提醒我完成当前一步，例如登录、验证码或粘贴密钥；完成后继续。不要让我把密钥发进聊天，不记录或上传密钥。付款或开通计费先让我决定，不要求注册所有服务。

本地模型按 README 检查配套引擎、模型文件、驱动和新路径，保留原配置备份，再实际启动并在 DSH 完成一次回复。缺文件时问我具体位置，不擅自下载大模型。云端测试先说明额度消耗并得到同意，语音测试提醒我录一小段。

最后检查插件、菜单和桌宠，告诉我启动方式、实测结果和未完成项。能直接做的继续做，只在必要时让我接手；不公开个人配置、聊天、日志或备份。没有本机或浏览器操作能力时请明确说明，再逐步指导，不要声称已操作。
```

<a id="private-backup"></a>
## 有旧备份，想连聊天记录一起恢复？

关闭旧电脑的套件实例，私下复制它的**整个数据目录**，包括隐藏的 `.env-kit.json`，并保留原件。此方法只支持同版本套件的完整备份；普通官方 DSH 目录或任意旧插件备份需要另行迁移。

准备好第 1 步的程序和解压文件后，在 `dsh-env-kit` 文件夹打开 PowerShell 7，运行以下命令，**代替第 2 步的安装命令**：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Restore-DSHKit.ps1 `
  -BackupPath 'C:\Backups\DSH-kit-home-backup' `
  -DshHome 'C:\DSH-kit-home' `
  -DshExe 'C:\Apps\DSH\DeepSeek Harness.exe'
```

换成实际绝对路径，目标数据目录必须尚不存在。恢复会复制到新目录并保留备份。随后按第 2 步启动，重新登录、调整模型路径和测试；旧电脑加密保存的登录信息可能需要重新填写。

## 套件里有什么

<details>
<summary>查看固定的 13 个插件</summary>

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

另含中文默认设置和 `anima-prompt`、`qwen-prompt`、`story` 三个提示词技能，不安装图片生成器。桌宠数据归属于新 home。

</details>

<details>
<summary>校验、回滚与其他下载方式（一般安装不需要看）</summary>

- [Release 下载页](https://github.com/SparklingAstronaut/dsh-env-kit/releases/tag/v1.0.0) · [SHA-256 校验清单](https://github.com/SparklingAstronaut/dsh-env-kit/releases/download/v1.0.0/dsh-env-kit-1.0.0-SHA256SUMS.txt)。可用 `Get-FileHash .\dsh-env-kit-1.0.0-offline-win-x64.zip -Algorithm SHA256` 核对同名文件的值。
- [标准包](https://github.com/SparklingAstronaut/dsh-env-kit/releases/download/v1.0.0/dsh-env-kit-1.0.0.zip) 不带 Electron；安装时省略 `-ElectronArchive` 会从官方源下载固定桌宠组件并校验。`-SkipDesktopPet` 可跳过桌面组件，但不属于完整桌宠恢复。
- 重复安装同版本套件会校验文件并保留设置；插件文件被修改时会报错，不会悄悄覆盖。
- 需要回滚时，关闭这个套件实例，再在套件文件夹运行：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Rollback-DSHKit.ps1 `
  -DshHome 'C:\DSH-kit-home'
```

回滚把数据目录改名为同级 `.retained-...` 备份，不删除内容。备份可能含密钥和聊天，只能私下保管。

</details>

<details>
<summary>开发与发布记录</summary>

插件和 186 个生产依赖包固定在 `vendor/plugins-win-x64.zip`，安装不运行 npm/pnpm；文件清单在 `payload-files.json`。便携修复按哈希锁定，插件更新可能覆盖补丁。

仓库仅包含**本套件的公开文件**。插件压缩包约 66 MiB；包含 Electron 的完整离线包放在 Release，不放进 Git 历史。不要把安装后的 DSH home、私有备份、日志或测试工作目录一起发布。

`python tests/audit.py` 检查文件清单、哈希、敏感路径和密钥特征；`node tests/contracts.mjs <已安装的home>` 检查菜单图标和通知逻辑。线上运行结果见 [GitHub Actions](https://github.com/SparklingAstronaut/dsh-env-kit/actions/workflows/verify.yml)，本地验收与线上结果分别记录。

实际执行结果和限制见 [验收记录](docs/verification.md)。许可、来源和本地补丁归属见 [第三方说明](THIRD_PARTY_NOTICES.md) 与 `third-party.json`。

整理本仓库的发布 ZIP 可运行 `python tools/pack-release.py`；加上 `--electron-archive <官方Electron压缩包路径>` 会额外生成完整离线包和总校验清单。该脚本先检查负载和 Electron 哈希，再生成文件校验清单、发布 ZIP 及其 SHA-256；它不读取现用 DSH，也不上传 GitHub。

</details>
