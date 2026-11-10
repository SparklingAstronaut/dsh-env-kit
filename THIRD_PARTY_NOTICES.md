# 来源与许可

新增安装、验证、启动和恢复脚本按根目录 MIT 许可提供。第三方组件保留各自许可，根目录许可不覆盖第三方权利。

`third-party.json` 列出了全部 188 个生产包的名称、版本、仓库信息和许可文件路径；原有 LICENSE、COPYING、NOTICE 与作者信息保留在插件压缩包内。

本地定制扩展包括语音路由、任务完成提醒与桌宠联动。它们的套件副本包含相应 MIT 许可文件；本套件的发布不改变各第三方原有许可和署名。

`superpowers-dsh` 0.5.0 的 package.json 声明 MIT，但其 npm 包和当前移植仓库没有独立 LICENSE 文件。套件保留该声明及来源，并补附原项目 obra/superpowers 的 MIT 许可（Copyright 2025 Jesse Vincent）；这不是代替移植作者作出的额外授权。

`fastdom`、`strictdom` 的完整 MIT 条款原在 README，已原样整理为 LICENSE 文件，README 仍保留。桌面伴侣保留 whale-girl 的 MIT 许可。Electron 独立下载包保留其 LICENSE 和 Chromium 第三方许可。

官方 DSH 软件不包含在此套件中；使用者需要另行安装并遵守其条款。模型权重、语音模型和本地推理引擎也不包含在套件中。

新增的 dsh-deepseek-chat 来自 xingxingbk-git/dsh-deepseek-chat，Google 登录修复源码为 SparklingAstronaut/dsh-deepseek-chat 的提交 4ba6ade65efc851bd2607501956fd2836060596b。保留上游 README、仓库信息及预编译产物。上游该版本未声明 package.json license 字段，也未提供独立 LICENSE；third-party.json 如实标为 UNSPECIFIED，本套件 MIT 许可不授予该第三方组件的额外权利。其独立固定的 zod 4.6.6 保留 MIT LICENSE。
