# DSH Environment Kit

> [!NOTE]
> **当前版本 1.1.0：插件直接装进官方 DeepSeek Harness，只有一个软件、一个图标。**
>
> 不再新建独立数据目录，也不再需要专门的启动命令：装好后照常从官方图标打开即可。之前用 1.0.x 装出“两个入口”的用户，请看 [从旧版换过来](#from-old)。

[![Verify portable kit](https://github.com/SparklingAstronaut/dsh-env-kit/actions/workflows/verify.yml/badge.svg)](https://github.com/SparklingAstronaut/dsh-env-kit/actions/workflows/verify.yml)

给官方 DeepSeek Harness（DSH）一次装好 14 个插件。**一共三步：装官方 DSH → 双击安装插件 → 从官方图标打开。**

适用：**Windows x64 · 官方 DSH 0.2.2-rc.1**。Windows 自带的 PowerShell 就够，不用另装别的。套件不包含账号、密钥、聊天记录、模型或推理程序。

想让 AI 代劳？直接复制本页的 [AI 安装提示词](#ai-prompt)。

<a id="install"></a>
## 1. 安装官方 DeepSeek Harness

到 [官网](https://deepseek.com/harness/) 或 [版本记录](https://github.com/deepseek-ai/deepseek-harness/releases) 下载并安装 **0.2.2-rc.1，Windows x64**。已经装了这个版本就跳过。

装好后**打开一次，再完全退出**（右下角托盘图标 → 退出）。本套件只认这个版本，其他版本会提示并停止，不会改动任何东西。

## 2. 安装插件

**[点击下载插件包](https://github.com/SparklingAstronaut/dsh-env-kit/releases/download/v1.1.0/dsh-env-kit-1.1.0-offline-win-x64.zip)**，整个解压，打开里面的 `dsh-env-kit` 文件夹，**双击 `Install.cmd`**。

它会自动找到你装的 DSH，把插件装进官方数据目录，大约一两分钟。看到“安装完成”就可以关掉窗口。

- 找不到 DSH 时，窗口会让你把 `DeepSeek Harness.exe` 拖进去再按回车。
- 安装前会自动备份原来的插件环境；你已有的登录、聊天记录、设置和其他插件都保留，只是多了这 14 个插件。
- 解压出来的文件夹装完可以删除；想留着以后 [撤销](#undo) 用也可以。

## 3. 打开

**直接从 DeepSeek Harness 的官方图标打开。** 没有第二个软件，也没有额外的启动器。

装完第一次打开会比平时慢一些，因为要加载新插件；之后恢复正常。打开后确认侧栏、设置里的新菜单和桌宠都在。

<a id="api-keys"></a>
## 4. 登录或填写 API Key

**只配置你需要的功能。** 只用本地模型不需要云端 Key，不用语音就跳过语音。

| 要用的功能 | 官方入口与操作 | 在 DSH 哪里填 |
|---|---|---|
| 官方账号模式 | 在 DSH 内直接登录 | 设置 → 账号与余额 |
| DeepSeek 云端 API 聊天 | [打开 DeepSeek API Keys](https://platform.deepseek.com/api_keys) → 登录 → 选择已有密钥或创建密钥 | 设置 → 模型 → 对应供应商；地址填 `https://api.deepseek.com`，模型选账号可用的名称 |
| Gemini 语音识别 | [打开 Google AI Studio](https://aistudio.google.com/apikey) → 登录 Google → 选择项目 → 创建或选择 API Key | 设置 → 语音 → Gemini API Key → 保存 |
| 阿里云语音识别 | [百炼新加坡](https://bailian.console.aliyun.com/ap-southeast-1/model/settings/api-key) / [百炼北京](https://bailian.console.aliyun.com/cn-beijing/model/settings/api-key) → 登录 → 选择业务空间 → 创建或选择 API Key | 设置 → 语音路由 → 对应云端后端 → 填 API 地址和“云端 API Key” → 保存 |

百炼的 **Key、地址和模型要使用同一地域**。语音路由填写控制台给出的 `API Host` 加 `/api/v1`，不是聊天接口的 `/compatible-mode/v1`。新密钥可能只完整显示一次，创建后及时私下保存。**不要把真实 Key 发进聊天或上传 GitHub。**

网页变化时核对官方说明：[DeepSeek](https://api-docs.deepseek.com/) · [Gemini](https://ai.google.dev/gemini-api/docs/api-key) · [百炼密钥](https://help.aliyun.com/zh/model-studio/get-api-key/) · [百炼地域](https://help.aliyun.com/zh/model-studio/regions)。入口最后核对：2026-11-10。

<a id="local-models"></a>
## 5. 使用本地模型（需要时再做）

先私下复制旧电脑的**模型文件夹和配套推理程序整个文件夹**，包括 DLL 等依赖，并准备适配新显卡的驱动。套件不会自动下载模型。

按当前默认的 **KVMem** 方式配置：

1. 打开 **设置 → 本地模型 → 高级设置**。
2. “llama.cpp 目录”填配套推理程序的文件夹。当前默认寻找 **`llama-kvmem-server.exe`**，普通 `llama-server.exe` 不能直接替代。
3. “模型文件夹”填含 `.gguf` 的目录，首次建议一个文件夹只放一个主模型。先测试文本模式；视觉模式另需匹配的 `mmproj`。
4. 本地“密钥”留空，端口先保留 `55555`。服务只监听本机 `127.0.0.1`，不要填云端 Key。
5. 点 **保存配置 → 启动**，显示“可以聊天”后点 **添加到模型列表**。
6. 回到聊天界面选这个本地模型，发一句“只回复 LOCAL_OK”，确认实际能回复。

<details>
<summary>其他后端、旧配置或启动失败时看这里</summary>

KVMem、NInfer、Prism 的程序、模型格式和参数不同。恢复旧配置时，检查槽位的 `backend`、`engineDir`、`serverExe`、模型目录及文件名，改成新电脑的真实位置，并按显存调整参数。

DSH 数据目录里的 `local-llm.config.json` 优先于界面配置，槽位路径也可能覆盖公共目录。端口被占用时换空闲端口并重新添加到模型列表。没有成功回复前，不应认为模型已可用。

</details>

<a id="ai-prompt"></a>
## 不想自己操作？把这段复制给 AI

适合能操作本机文件和终端的 AI。**不要把真实密钥放进提示词。**

```text
请按这个仓库首页 README，直接帮我在当前 Windows 电脑给官方 DeepSeek Harness 装好插件，不要只给方案：
https://github.com/SparklingAstronaut/dsh-env-kit

先确认已安装官方 DSH 0.2.2-rc.1 并且已完全退出，然后下载 README 里的插件包、解压、运行其中的 scripts\Install-DSHKit.ps1（找不到 DSH 时用 -DshExe 传入 DeepSeek Harness.exe 的完整路径），再运行 scripts\Verify-DSHKit.ps1 确认。插件要装进官方 DSH 自己的数据目录，装完只从官方图标启动；不要新建独立数据目录，不要创建别的启动器或快捷方式，不要绕过版本检查。

只配置我需要的功能。需要 API Key 时打开 README 中的官方网址带我创建，并让我自己粘贴到 DSH 对应输入框；不要让我把密钥发进聊天。付款或开通计费先让我决定。

最后告诉我实测结果和未完成项。没有本机操作能力时请明确说明，再逐步指导，不要声称已操作。
```

<a id="undo"></a>
## 撤销安装

完全退出 DSH，在 `dsh-env-kit` 文件夹的地址栏输入 `powershell` 回车，运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Rollback-DSHKit.ps1
```

DSH 的插件环境会恢复到安装套件之前的样子，登录和聊天记录不受影响。带插件的那份环境不会被删除，保存在 DSH 数据目录的 `env-kit-backups` 文件夹里。

想确认是否装好，可以运行 `.\scripts\Verify-DSHKit.ps1`（用法同上）。它只检查文件和版本；登录、密钥、模型和语音要在 DSH 里实际试一次。

<a id="from-old"></a>
## 从旧版（1.0.x）换过来

旧版会新建一个独立数据目录（例如 `C:\DSH-kit-home`），并用单独的启动命令或“DSH 套件”快捷方式打开，所以看起来像两个软件，启动也更慢。换到新版：

1. 按上面三步安装。插件会装进官方 DSH，之后只用官方图标。
2. 删除旧的“DSH 套件”快捷方式。
3. 在官方 DSH 里重新登录、重新填写 API Key 和模型路径。**旧目录里的聊天记录不会自动搬过来**；旧目录本身不会被改动，确认不再需要后可以自行删除。

## 套件里有什么

<details>
<summary>查看固定的 14 个插件</summary>

| 插件 | 版本 | 用途 |
|---|---|---|
| dsh-better-sidebar | 0.30.1 | 会话与工作区侧栏 |
| dsh-context | 0.83.1 | 上下文洞察 |
| dsh-computer-use-win | 0.5.5 | Windows 电脑操控 |
| dsh-deepseek-chat | 0.2.26 本 fork 修复构建（固定归档） | 修复文字头像账号登录后空白；CHAT / HARNESS 切换；凭据由用户自行登录 |
| dsh-doublecheck | 0.9.30 | 工程检查与验收记录 |
| dsh-gemini-voice | 0.3.7 | Gemini 语音识别 |
| dsh-voice-router | 0.1.2 | Gemini / 云端 API / 本地语音路由 |
| dsh-voice-notify | 1.0.0 | 任务结束语音提醒 |
| dsh-local-llm-controller | 2.0.4-kvmem.1-official.2 | 启停、配置本地推理服务 |
| dsh-paste-spill | 0.2.0 | 长文本粘贴处理 |
| dsh-suggest-ghost | 0.9.0 | 智能追问建议，保留无发光补丁 |
| dsh-whale-desktop-integration | 1.1.7 | 桌宠侧栏、设置与桌面联动 |
| superpowers-dsh | 0.5.0 | 工程工作流技能 |
| whale-girl | 0.2.3 | 网页宠物 |

另含中文默认设置和 `anima-prompt`、`qwen-prompt`、`story` 三个提示词技能。未加入 image-gen、AnySearch、ego-browser 或 prompt-history。

</details>

<details>
<summary>安装时具体做了什么（一般不需要看）</summary>

- 插件装进官方 DSH 的数据目录（默认 `%USERPROFILE%\.dsh`；设置过 `DSH_HOME` 环境变量时用它）里的 `profiles\desktop`，和在 DSH 里手动装插件是同一个位置。
- 安装前把原来的 `profiles\desktop` 完整复制到数据目录的 `env-kit-backups\<时间>`。
- 已有的设置逐条保留，只补上你没有的默认项（中文界面、Doublecheck 提醒级别）；已有的 `AGENTS.md` 和同名技能不覆盖；原来装的其他插件保留。
- 14 个插件都来自包内固定的安装包并核对校验值，安装过程不联网、不运行 npm/pnpm。只有单独下载不含 Electron 的 [标准包](https://github.com/SparklingAstronaut/dsh-env-kit/releases/download/v1.1.0/dsh-env-kit-1.1.0.zip) 时，才会从官方源下载桌宠组件；加 `-SkipDesktopPet` 可跳过桌宠。
- 装完重复运行不会重复安装。安装中途失败会自动恢复到安装前。
- 命令行参数：`-DshExe <DeepSeek Harness.exe 路径>`、`-DshHome <数据目录>`、`-ElectronArchive <Electron 压缩包>`、`-SkipDesktopPet`。
- [Release 下载页](https://github.com/SparklingAstronaut/dsh-env-kit/releases/tag/v1.1.0) · [SHA-256 校验清单](https://github.com/SparklingAstronaut/dsh-env-kit/releases/download/v1.1.0/dsh-env-kit-1.1.0-SHA256SUMS.txt)

</details>

<details>
<summary>开发与发布记录</summary>

包含 14 个插件的 188 个生产包固定在 `vendor/plugins-win-x64.zip`；文件清单在 `payload-files.json`。全部 14 个内置插件使用本地安装包固定来源，DSH 常规更新会跳过它们。新增插件可正常管理；升级内置插件需要主动更换来源并重新验收。

仓库仅包含**本套件的公开文件**。包含 Electron 的完整离线包放在 Release，不放进 Git 历史。不要把安装后的 DSH 数据目录、备份、日志或测试工作目录一起发布。

`python tests/audit.py` 检查文件清单、哈希、本地固定包及其安装内容、敏感路径和密钥特征；`tests/official-home-install.ps1` 在临时目录模拟“只打开过一次的官方环境”和“已有设置与其他插件的环境”，实际执行安装、重复安装和撤销；`node tests/contracts.mjs <数据目录>` 检查菜单图标和通知逻辑；`tests/package-operations.ps1` 执行新增、卸载和空目录重装。线上运行结果见 [GitHub Actions](https://github.com/SparklingAstronaut/dsh-env-kit/actions/workflows/verify.yml)。

实际执行结果和限制见 [验收记录](docs/verification.md)，各版变化见 [版本记录](docs/version-history.md)。许可、来源和本地补丁归属见 [第三方说明](THIRD_PARTY_NOTICES.md) 与 `third-party.json`。

整理发布 ZIP 可运行 `python tools/pack-release.py`；加上 `--electron-archive <官方Electron压缩包路径>` 会额外生成完整离线包和总校验清单。

</details>
