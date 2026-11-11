> 历史版本来源记录。当前套件 1.0.5 已修复密码登录问题并实测通过；安装请使用 [当前说明](../README.md)。

# CHAT 同步作者正式版 0.2.23

2026-11-11，套件 1.0.4 将 dsh-deepseek-chat 从 fork 的 0.2.22 修复候选迁移到原作者公开的 0.2.23。使用公开 npm tarball 的原始字节，没有修改插件源码、编译文件或包元数据。

- 上游：[xingxingbk-git/dsh-deepseek-chat](https://github.com/xingxingbk-git/dsh-deepseek-chat)
- 正式包：[dsh-deepseek-chat-0.2.23.tgz](https://registry.npmjs.org/dsh-deepseek-chat/-/dsh-deepseek-chat-0.2.23.tgz)
- SHA-256：`5e2cd85cbacf86896d5fa165fe3ca71dec0eba1b9d94a9730ff0239765b5710b`
- 安装来源：`file:./pinned-packages/dsh-deepseek-chat-0.2.23.tgz`。来源固定的是作者原始正式包；并非继续使用旧 fork。完整 npm integrity 记录在 manifest。
- 原 PR 经作者手工合入后关闭；[作者回复](https://github.com/xingxingbk-git/dsh-deepseek-chat/pull/18#issuecomment-6786100622)。0.2.24 是后续未发布候选，不属于此次同步。

## 保留范围

其他 13 个公开插件的归档、版本和自身文件不变。负载中除聊天插件及其安装包外，仅 profile package.json 和依赖锁定文件改变；公开默认设置、工程规则、桌宠组件及聊天插件自己的 zod 4.6.6 保留。旧版本安装包与私有备份保留用于回退。

本机额外的说人话插件及本机专用模型/语音目录保持原状；不会把个人配置复制进公开包。安装来源仍固定，新增其他插件不会自动换掉已验收版本。

## 验证

作者源码的加载/登录 68 项、页面适配 50 项、网页生命周期 14 项回归通过；负对照捕获故意引入的旧问题；36 个预编译文件与源码清单匹配。公开 tarball SHA-256 和 npm integrity 匹配，43 个文件与发布源码逐字节相同，package.json 的差异仅为 npm 去掉了 packageManager 字段。

本机安装后 Host 识别 0.2.23，15 个插件启用且没有加载失败；新版本的“模式切换快捷键”设置实际可见。既有五个设置图标仍各一个。104 项套件回归、全量归档校验、重装及增删插件验证的实际结果写入本轮交付记录，最终提交继续由 GitHub Actions 独立执行。

本次历史同步仅保留已有登录状态；随后已用原来出问题的账号复现文字头像识别问题，并在套件 1.0.5 完成修复与真实密码登录、切换、刷新和重启验证。详见 [当前修复记录](chat-text-avatar-0.2.26.md)。
