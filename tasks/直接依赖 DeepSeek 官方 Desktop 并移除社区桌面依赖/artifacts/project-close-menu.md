# 关闭页面与关闭项目菜单整理

## 目标与方案

截图中的两个动作并非完全重复。固定官方 `0.2.0-rc.2` 的 `keyboard.ts` 将「关闭页面」送入 `page.close`；`ui-sidebar-right/src/client/shortcuts.ts` 根据焦点关闭最上层弹窗或右侧页面，没有页面目标时才请求关闭窗口。Shell 的「关闭项目」直接进入项目关闭流程，包含任务确认和所属 Host 清理。

保留完整官方上下文关闭逻辑及默认 `⌘W`（Windows 为 `Ctrl+W`）。把 Shell 的「关闭项目」从「文件」移到「项目」，改名为「关闭当前项目 / Close Current Project」，保留 `⇧⌘W`（Windows 为 `Ctrl+Shift+W`）。仅改菜单归属与文案，不改生命周期。相比删除某一动作，分组能保留关闭单个页面和直接关闭整个项目的两个用途。

## 实施步骤

1. 在 `resources/wt-dsh-shared-account` 的 `codex/project-close-menu` 分支改 `src/app/main.mjs` 的菜单组合；同步 Shell 架构和前端规范。
2. 在独立 worktree 运行 `yarn check`。使用临时 userData 的真实 Electron 验证中英文菜单、关闭弹窗后项目仍存活、关闭当前项目后另一个项目仍存活；不在用户真实项目上试关。
3. 精确集成到主 checkout 并本地中文提交，更新本报告。正常重启现有开发壳，使用户能查看新菜单。

## 验收

- Shell 提交：`66ae68c`；只移动菜单项和更新文案，官方代码与关闭流程均未修改。
- 独立 worktree `yarn check` 通过：140 项测试及构建、项目文件检查均通过。
- macOS arm64 / Electron 44.0.0 原生验收：中文文件菜单仅保留「关闭页面」；项目菜单显示「关闭当前项目」。英文对应 `Close Page` / `Close Current Project`。
- `⌘,` 打开真实官方设置弹窗后，`⌘W` 仅关闭弹窗；两个项目窗口和各自 Host 均保持可用（项目 snapshot HTTP 200）。
- 实际点击中文「关闭当前项目」关闭 Alpha，Beta 的 Host 继续返回 200；点击英文 `Close Current Project` 关闭最后一个项目后返回欢迎窗口，此时关闭项目项禁用。
- 菜单中的 `CmdOrCtrl+Shift+W` 绑定已核对保留。自动化合成按键到达 WebContents，但未触发系统菜单 accelerator；同工具对照原有 `CmdOrCtrl+Shift+N` 也未触发。因此未声明组合快捷键实机触发通过，留待物理键盘复核，不根据此现象改写官方按键系统。
- 已正常退出并重启现有开发壳，原有两个项目恢复，运行中菜单已核对为新结构。
- 未做 Windows 原生验收；本次未改页面样式或主题。验收工具无法获取该临时实例的截图，菜单结论来自实际 AX 菜单操作和 Electron 菜单对象，弹窗与 Host 结论来自实时 DOM / 请求。
