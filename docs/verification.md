# 1.0.1 Google 登录修复与版本固定验收

环境：Windows x64，官方 DSH 0.2.2-rc.1，PowerShell 7。日期：2026-11-11。

- 套件包含 14 个插件、188 个生产包、14,141 个文件。离线审计的文件哈希、本地修复包对应内容、敏感路径和密钥特征扫描全部通过。
- 在原公开负载上新增修复插件及其独立的 zod 4.6.6；原有 13,256 个文件字节不变，仅修改 profile 的 package.json 以登记新增插件。
- 在含中文和空格的新目录安装，官方 Host 的插件清单确认全部 14 个插件 active；原有 15 项图标、菜单与通知检查通过。
- 官方插件管理器报告修复插件 enabled=true、updatable=false；查询更新版本返回 not-updatable。修复包的 43 个发布文件与本机安装内容一致。
- 复制恢复到第二个中文/空格目录后，14 个插件再次全部 active；固定来源自动解析至新 home 内的修复包，仍拒绝常规更新。测试实例均已停止。
- 仅验证同一物理电脑上的隔离安装和路径变化。本次安装使用 SkipDesktopPet；没有重新执行真实 Google 登录、麦克风、付费云服务、本地模型或桌宠行为测试。此前本机 Google 登录已由用户完成并确认能聊天，不能据此替代另一台电脑的账号登录测试。

固定的是 fork 提交 4ba6ade65efc851bd2607501956fd2836060596b 构建的 0.2.22 候选包，不是已发布的 npm 正式版。只有确认上游正式发行包含 [PR #18](https://github.com/xingxingbk-git/dsh-deepseek-chat/pull/18) 或等效修复后，才手动切回官方来源；没有自动监视或解除固定的任务。

机器可读证据：[google-login-pin-verification.json](google-login-pin-verification.json)。线上结果见 [GitHub Actions](https://github.com/SparklingAstronaut/dsh-env-kit/actions/workflows/verify.yml)。

# 1.0.0 历史验收记录

环境：Windows x64，官方 DSH 0.2.2-rc.1，PowerShell 7，官方随附 Node 24.21.0。日期：2026-11-10。

这是同一台 Windows 电脑上的隔离目录恢复测试，模拟新 home 和路径变化；未声称已在另一台物理电脑或另一个 Windows 用户账号测试。

| 检查 | 结果与证据 |
|---|---|
| 发布负载 | 13 个顶层插件、186 个生产包、13,257 个文件；SHA-256 清单逐项通过 |
| 脱敏 | 归档文件、敏感路径和常见密钥特征扫描通过；不包含用户会话、凭据、运行缓存、日志或权重 |
| 新目录安装 | 在含中文和空格的全新路径安装成功；插件离线恢复，桌宠使用校验过的官方 Electron 压缩包 |
| 实际加载 | 官方 Host 的 `pluginInventory/list` 返回全部 13 个插件 active；Doublecheck 两个模块均 active |
| 干净语音配置 | 新环境的 Gemini 与语音路由接口均返回 configured=false，没有沿用原环境的旧密钥 |
| 桌面宠物 | 新 home 的桌宠控制接口返回 running=true、error 为空 |
| 图标和通知 | 15 项行为断言通过：三个官方图标注册、纯文字标签、通知去重、Ghost 无发光、语音目录隔离 |
| 重复安装 | 校验成功，用户修改的测试设置文件哈希未变 |
| 拒绝错误输入 | 已有普通目录、缺失官方程序、错误 DSH 版本、损坏归档、ZIP 路径穿越均被拒绝；未覆盖目标 |
| 运行中保护 | 测试实例运行时，回滚脚本拒绝执行 |
| 本地模型 | 新环境首次创建通用供应商成功；实际启动已有本地推理引擎，HTTP 推理返回精确内容 `391`；随后停止，测试端口关闭 |
| 回滚与换路径恢复 | 回滚保留原备份；复制至第三个中文/空格路径后，13,462 个文件内容完全一致（仅安装元数据允许更新）。再次启动后 13 个插件 active，字号设置、本地供应商和桌宠状态均恢复 |

本地模型测试使用本机已有的模型和引擎，只把路径写进私有测试 home；这些路径和文件没有进入发布套件。该次推理通过新控制器启动的 OpenAI 兼容接口完成，没有把它表述为一次新环境内的完整聊天/UI 测试。

本次没有真实录音或付费云端转写测试，没有替接收者安装 GPU 驱动/模型，没有测试未来 DSH 版本。语音提醒做了事件触发逻辑检查，未把系统实际扬声器播放当作已验收项目。

新套件解决了隔离测试发现的长路径解压、Electron 启动环境变量、旧语音共享配置、本地模型首次注册问题。最终需使用 PowerShell 7；Windows PowerShell 5.1 会被明确拒绝。

线上 CI 的最新结果见 [GitHub Actions](https://github.com/SparklingAstronaut/dsh-env-kit/actions/workflows/verify.yml)，与上述本地验收分开记录。验收会话没有 DSH 原生 doublecheck 工具，采用实际命令与测试结果记录，没有声称运行过原生 `/gate run`。

机器可读汇总见 [verification-results.json](verification-results.json)。测试结束后隔离实例和模型服务均已停止；测试与恢复备份保留在私有工作目录，未放入发布包。
