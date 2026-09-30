# 复用官方侧栏更新入口实施计划

目标：原样复用固定 DeepSeek 官方 0.2.0-rc.2 的账号右侧更新指示器、折叠侧栏 badge、状态协议与更新确认界面，恢复壳的应用级更新入口。

发现：当前官方 Web 已包含 DesktopUpdateIndicator / DesktopUpdateBadge，但 Shell 的 updates-status 固定 idle，updates-open 抛未接入错误。旧社区更新生命周期不可再使用。

方案：从固定官方源码只读构建 UpdateCoordinator、UpdateSchedule、UpdateDialog、UpdateOverlays 与 presentation；Shell 仅适配自己的 GitHub update.json、安装包校验和多窗口生命周期。官方预加载 API 已提供 status/open/subscribe，不新增插件 UI 或改上游 bundle。

1. 在已有空闲隔离 worktree 上从已集成 HEAD 建立 codex/official-update-sidebar；保留上一轮账号共享提交。
2. 构建官方更新模块、原始对话框 assets 与独立 preload 至 Shell dist，来源纳入 build.json；不改官方 runtime。
3. 接入自有更新 feed 和受版本/大小/SHA-256 约束的下载适配。macOS 沿用 DMG 手动安装；Windows 沿用原安装器并先关闭全部项目。开发模式检查允许，安装交接保持明确用户确认。
4. 应用级单实例管理检查/下载/确认；所有项目使用同一状态广播。复用官方侧栏布局和文案，菜单提供手动检查，空闲状态按官方规则隐藏。
5. 覆盖真实官方控件的可用更新、下载进度、失败重试、取消、折叠徽标、中英文、明暗、窄窗口、两个项目同步和关闭所属窗口。测试安装边界用临时包与拦截交接，不能执行假安装器或替换用户应用。
6. 源码检查与所需原生回归通过后精确集成本地中文提交，重启当前开发壳并记录任务结论；不 push 或发布。
