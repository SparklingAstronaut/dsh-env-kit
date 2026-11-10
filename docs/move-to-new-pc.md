# 换电脑恢复 DSH：照着做即可

适用于 **dsh-env-kit v1.0.0、Windows x64、官方 DSH 0.2.2-rc.1、PowerShell 7**。本页提供完整步骤和一段可直接复制给 AI 的提示词。

不想自己操作：直接跳到 [让 AI 帮你恢复](#ai-prompt)。AI 需要具备本机文件、终端和浏览器操作能力；只有聊天能力的 AI 可以逐步指导，但不能代你安装或点击页面。

<a id="install"></a>
## 1. 下载、安装和启动

### 下载哪个包

下载 [完整离线包 dsh-env-kit-1.0.0-offline-win-x64.zip](https://github.com/SparklingAstronaut/dsh-env-kit/releases/download/v1.0.0/dsh-env-kit-1.0.0-offline-win-x64.zip)，约 229 MB。它包含全部 13 个插件、依赖和桌宠运行组件。

不用另下标准包，也不用点 GitHub 的 “Source code (zip)”。完整离线包仍需另行准备 **DSH 主程序、PowerShell 7、账号密钥和本地模型**。云端聊天和云端语音仍需要联网。

把压缩包整个解压，保留下面的相对位置；里面的 Electron ZIP 不用手动解压：

```text
解压目录/
├─ dsh-env-kit/
│  ├─ README.md
│  └─ scripts/
├─ electron-v45.1.0-win32-x64.zip
└─ INSTALL-OFFLINE.zh-CN.md
```

需要校验下载时，在 ZIP 所在目录执行 `Get-FileHash .\dsh-env-kit-1.0.0-offline-win-x64.zip -Algorithm SHA256`，与 [官方套件校验清单](https://github.com/SparklingAstronaut/dsh-env-kit/releases/download/v1.0.0/dsh-env-kit-1.0.0-SHA256SUMS.txt) 中同名文件的值对比。交给 AI 操作时让它自动完成。

### 准备两个程序

| 程序 | 官方入口 | 要注意什么 |
|---|---|---|
| DeepSeek Harness | [官方下载页](https://deepseek.com/harness/) · [官方版本记录](https://github.com/deepseek-ai/deepseek-harness/releases) | 必须是 **0.2.2-rc.1 / Windows x64**。官网“最新版”以后可能变化，先核对版本；已有别的版本时保留它，使用独立安装位置。找不到兼容版本时不要绕过安装脚本检查。 |
| PowerShell 7 | [微软安装说明](https://learn.microsoft.com/zh-cn/powershell/scripting/install/install-powershell-on-windows) | 安装 Windows x64 稳定版，并从开始菜单打开“PowerShell 7”；Windows 自带的 PowerShell 5.1 不够。 |

如果要恢复私有备份和聊天记录，完成上述准备后跳到 [第 5 节](#private-backup)，不要先在同一个目标目录做全新安装。

### 安装 13 个插件

进入解压后的 **`dsh-env-kit` 文件夹**，在这里打开 PowerShell 7，运行：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Install-DSHKit.ps1 `
  -DshExe 'C:\Apps\DSH\DeepSeek Harness.exe' `
  -DshHome 'C:\DSH-kit-home' `
  -ElectronArchive '..\electron-v45.1.0-win32-x64.zip'
```

只需要检查两处：`DshExe` 改为新电脑上官方 DSH 程序的实际绝对路径；`DshHome` 是存放新环境的目录，安装前**不要创建它**，也不要指向现有 DSH 或备份。示例盘符可换成自己有写入权限的位置。

### 启动与日常使用

安装成功后，在同一文件夹运行：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Start-DSH.ps1 `
  -DshHome 'C:\DSH-kit-home'
```

以后也用这个启动脚本，并保持相同的 `DshHome`；默认官方快捷方式可能打开另一个环境。可以让 AI 建一个调用这条命令的“DSH 套件”快捷方式，保留原来的快捷方式和解压文件夹。

<a id="api-keys"></a>
## 2. 账号与 API Key：只配你要用的功能

**先复用仍有效的旧密钥；没有保存或已经失效，再去官方页面创建。** 不是每一项都要申请：只用本地模型不需要云端 API Key，暂时不用语音就跳过语音配置。

| 想使用的功能 | 官方入口 | 在 DSH 哪里填 |
|---|---|---|
| 官方账号模式 | 直接在 DSH 的账号页面登录 | 设置 → 账号与余额；按实际页面提示完成登录 |
| DeepSeek 云端 API 聊天 | [DeepSeek API Keys](https://platform.deepseek.com/api_keys) | 设置 → 模型 → 对应供应商的 API Key；OpenAI 兼容地址为 `https://api.deepseek.com`，模型选账号当前可用的名称 |
| Gemini 语音识别 | [Google AI Studio API Keys](https://aistudio.google.com/apikey) | 设置 → 语音 → Gemini API Key |
| 阿里云语音识别 | [百炼新加坡 API Key](https://bailian.console.aliyun.com/ap-southeast-1/model/settings/api-key) 或 [百炼北京 API Key](https://bailian.console.aliyun.com/cn-beijing/model/settings/api-key) | 设置 → 语音路由 → 对应云端后端，填写 API 地址和“云端 API Key” |

**DeepSeek：**打开上面的 API Keys 页面 → 登录 → 找到可复用的密钥或创建新密钥 → 在 DSH 的对应供应商中填写并保存。API 地址和模型名以 [DeepSeek 官方接入说明](https://api-docs.deepseek.com/) 与账号实际可用模型为准；官网登录和手动配置供应商是两种入口，不要求两套都做。

**Gemini：**打开 AI Studio → 用 Google 账号登录 → 在 API Keys 页面选择已有项目/密钥，或使用“创建 API 密钥”流程 → 把密钥填入 DSH 的“语音”设置并保存。项目权限、地区或账号不可用时，按页面提示处理，或跳过此服务继续其他恢复步骤。入口来自 [Google 官方 AI Studio 指南](https://ai.google.dev/aistudio)，密钥规则见 [官方密钥说明](https://ai.google.dev/gemini-api/docs/api-key)。

**阿里云百炼：**打开与原服务一致的地域 → 登录 → API Key 页面中复用密钥或点击“创建 API Key” → 按账号情况选择归属账号和业务空间。新创建的密钥可能只完整显示一次，立即私下保存并填写到 DSH。新加坡和北京的 Key、地址、模型不能混用；可按创建页面或业务空间给出的 **API Host 加 `/api/v1`** 配置本套件的语音路由。这里不是聊天接口的 `/compatible-mode/v1`。具体入口和地域规则见 [阿里云密钥说明](https://help.aliyun.com/zh/model-studio/get-api-key/) 与 [地域说明](https://help.aliyun.com/zh/model-studio/regions)。

AI 可以帮你打开这些页面、定位按钮、准备 DSH 设置并检查保存结果。需要你接手时，它应只说明眼下的一步，例如：

> 已打开 Gemini 官方密钥页面，请在这里登录 Google 账号。完成后告诉我“已登录”，我会继续带你创建或选择密钥。

> 请将密钥粘贴到 DSH 的“语音 → Gemini API Key”输入框并保存，不要发到聊天里。完成后告诉我“已保存”，我会继续检查。

登录、验证码、密码和付款由你在官方页面完成。出现充值、绑定支付方式或开通计费时，先了解页面显示的费用，由你决定是否继续；也可以暂时跳过。密钥只保存在当前本地环境或你自己的密码管理器里，不回显到聊天、日志、截图、命令历史或 GitHub。无需为了安装插件给所有服务开账号，也不需要设置全局密钥环境变量。

<a id="local-models"></a>
## 3. 本地模型重新配置

### 先带走模型与推理程序

从旧电脑私下复制 **模型文件夹** 和 **配套推理程序的整个文件夹**，包含 DLL 等依赖；新电脑还需要适配显卡的驱动。套件只提供控制入口，不包含权重、引擎或驱动。没有这些文件时，让 AI 先确认模型和硬件，再从对应官方来源准备，不要把任意引擎当成可直接替换的程序。

### 默认 KVMem 方式

1. 打开 **设置 → 本地模型**，展开卡片和 **高级设置**。
2. 在“llama.cpp 目录”中填写配套推理程序的文件夹。虽然界面叫这个名字，当前默认实际运行的是 **`llama-kvmem-server.exe`**，不是普通 `llama-server.exe`。
3. 在当前槽位的“模型文件夹”里填写包含 `.gguf` 的目录。首次配置建议一个目录只放一个主模型；视觉模型需要相匹配的 `mmproj`，首次先测试文本模式。
4. 本地“密钥”留空，端口先保留默认 `55555`；当前 KVMem 配置只监听本机 `127.0.0.1`。云端服务的密钥不要填在这里。
5. 点 **保存配置 → 启动**。显示“可以聊天”后，再点 **添加到模型列表**。
6. 回到聊天界面选择这个本地模型，发送“只回复 LOCAL_OK”，看到回复后再测试其他功能。

如果端口被占用，换一个空闲端口并重新添加到模型列表。模型启动失败时先看错误：路径不对就修正路径；驱动/程序不匹配就准备正确引擎；显存不够则调整模型或上下文，不要重复强行启动。

### 恢复已有 KVMem / NInfer / Prism 配置

这些后端的程序、模型格式和参数不同。复用旧配置时，需要检查各槽位的 `backend`、`engineDir`、`serverExe`、模型目录及文件名，改成新电脑的真实位置，并按硬件重新核对参数。界面没有直接编辑后端和服务程序名的选项，不能只改“llama.cpp 目录”就当作完成了全部迁移。

若新 home 内带有 `local-llm.config.json`，它的配置优先于界面保存的配置。让 AI 在保留原备份的前提下检查这份本地文件以及槽位路径覆盖项；不要将含密钥或个人路径的配置发到聊天或公开仓库。确认后端实际正常启动并完成一次回复，才能报告“本地模型可用”。

<a id="verify"></a>
## 4. 安装后检查

在套件文件夹运行，路径与安装时一致：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Verify-DSHKit.ps1 `
  -DshHome 'C:\DSH-kit-home' `
  -DshExe 'C:\Apps\DSH\DeepSeek Harness.exe'
```

这个命令检查安装文件和版本。然后在 DSH 界面确认 13 个插件已加载、相关菜单可以打开、桌宠能启动，并按需要实际测试模型回复和一小段语音转写。云端测试可能消耗服务额度，缺密钥或没有进行真实调用的项目应记为“未测试”，不能因为文件校验通过就说全部功能可用。

<a id="private-backup"></a>
## 5. 要保留聊天记录：改用私有备份恢复

这是全新安装的替代方式。先关闭旧电脑上对应的套件实例，私下复制其完整 home，包含隐藏的 `.env-kit.json`；不要只复制插件文件夹。原备份继续保留。

`Restore-DSHKit.ps1` **只接受同版本套件的完整备份**，会检查 `.env-kit.json` 和插件文件。普通官方 DSH 的旧 home、任意旧插件备份或改过插件的目录，不应直接套用这个命令；需要另行评估迁移，不能伪造标记或覆盖现有环境。

把备份带到新电脑后，进入解压后的 `dsh-env-kit` 文件夹，在 PowerShell 7 运行：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Restore-DSHKit.ps1 `
  -BackupPath 'C:\Backups\DSH-kit-home-backup' `
  -DshHome 'C:\DSH-kit-home' `
  -DshExe 'C:\Apps\DSH\DeepSeek Harness.exe'
```

三个路径都替换为实际绝对路径，目标 `DshHome` 必须尚不存在。恢复会复制到新目录并保留原备份；随后使用第 1 节的启动命令，再完成账号、密钥、本地路径和实测检查。旧电脑加密保存的登录信息不一定能跨机解密，需要时重新登录即可。

<a id="ai-prompt"></a>
## 6. 复制给 AI：直接开始恢复

把下面整段复制给一个能操作本机和浏览器的 AI。不必提前填写电脑路径，让 AI 先检查；不要把真实密钥加到提示词中。

```text
请直接帮我在这台 Windows 电脑恢复 dsh-env-kit，执行安装和验证，不要只给方案。

仓库：https://github.com/SparklingAstronaut/dsh-env-kit
换机指南：https://github.com/SparklingAstronaut/dsh-env-kit/blob/main/docs/move-to-new-pc.md
固定版本：https://github.com/SparklingAstronaut/dsh-env-kit/releases/tag/v1.0.0

先读 README、换机指南和 manifest，检查 Windows x64、PowerShell 7、官方 DSH 的版本和位置。此套件要求 DSH 0.2.2-rc.1，不要拿其他版本硬装或绕过检查。缺少前置程序时，从官方来源准备兼容版本；不要覆盖电脑上已有的其他安装。下载完整离线包 dsh-env-kit-1.0.0-offline-win-x64.zip 和同一 Release 的 SHA256SUMS，校验一致后再解压。保持 Electron ZIP 和 dsh-env-kit 文件夹的相对位置。

为套件选择一个有写入权限、尚不存在的新 home，运行 Install-DSHKit.ps1，指定实际 DshExe、DshHome 和离线 ElectronArchive，然后使用 Start-DSH.ps1 启动。记录实际路径，给我建立一个调用该启动脚本的“DSH 套件”快捷方式，保留原快捷方式。如果我提供了私有备份，先判断是否是有 .env-kit.json 且符合当前版本的完整套件备份；符合时用 Restore-DSHKit.ps1 代替全新安装，不要在同一目标先安装再恢复。原备份、已有 DSH、其他插件和个人文件全部保留。

只配置我需要的服务，优先复用有效的旧密钥和登录状态，不要让我把所有平台注册一遍。按已知偏好继续；无法判断我要用哪种服务时，用一个简短问题让我选择，再继续能独立完成的安装工作。

需要 API Key 时，直接用浏览器打开对应官方页面并引导我完成：
- 官方账号模式：在 DSH 设置→账号与余额登录。
- DeepSeek 云端 API：https://platform.deepseek.com/api_keys
- Gemini 语音：https://aistudio.google.com/apikey
- 百炼新加坡：https://bailian.console.aliyun.com/ap-southeast-1/model/settings/api-key
- 百炼北京：https://bailian.console.aliyun.com/cn-beijing/model/settings/api-key

先核对官方页面与账号当前流程；链接或界面变化时从该服务的官方文档找入口，不去第三方密钥网站。帮我定位创建密钥或选择已有密钥的步骤，并打开 DSH 对应设置。每次只提示当前需要我完成的一件事，例如“请在这个页面登录，完成后告诉我已登录”或“请将密钥粘贴到 DSH 的语音密钥框并保存，完成后告诉我已保存”。我完成后就继续，不要再问一遍是否继续安装。登录密码、验证码和支付步骤交给我；不要索要聊天中的密钥，不要回显、截图或记录完整密钥。密钥仅保存在当前本地环境或我的密码管理器。涉及充值、绑定支付方式或开通计费时，说明页面要求并等我决定，不擅自购买，也不承诺服务免费。跳过某个服务不应阻塞其余恢复。

Gemini Key 填“设置→语音”；百炼 Key 填“设置→语音路由”，Key、模型与 API 地址必须同地域，并按当前指南设置语音接口路径；聊天 API Key 填相应模型供应商。不要把云端 Key 填进本地模型的密钥框，也不要设置系统全局密钥。

本地模型：先检查我提供的模型、推理程序和旧配置，只读取完成迁移需要的信息，不输出秘密。缺少文件位置时问我一次具体目录；没有权重时不要擅自下载大模型。默认 KVMem 要使用配套 llama-kvmem-server.exe 和 GGUF，不能直接换普通 llama-server.exe。其他后端要确认 backend、engineDir、serverExe、模型格式和参数；有 local-llm.config.json 时注意它优先于界面配置，槽位路径覆盖项也需改成新电脑路径。只在新环境修改，保留原备份。检查驱动、显存和端口，保存后启动本地服务、添加到模型列表，并在 DSH 实际选择该模型完成一次简短回复。

执行 Verify-DSHKit.ps1，确认 13 个插件已加载、菜单和桌宠可用。对我已选择且配置好的云端服务说明会消耗额度，并在我同意后做最小测试；麦克风测试先提醒我录一小段。没密钥、没模型或没有真的测试的功能，明确写成待配置/未测试，不冒充成功。最后用中文告诉我实际启动方式、配置完成项、测试结果和剩下需要我做的事。

全程不要删除或上传个人配置、密钥、聊天、日志、模型和备份，不改当前可用 DSH，不自动升级插件。能直接做的继续做；只有缺少必要信息、人工登录/验证或付费决定时才让我接手。如果你没有本机或浏览器操作能力，请明确说明，并按上述顺序一次引导我完成一个步骤，不要声称已操作。
```

官方入口最后核对日期：2026-11-10。网站页面、账号权限和可用模型可能变化；让 AI 按实时官方页面核对，不猜按钮、密钥或模型名。
