# macOS 项目侧栏底部白条修复

## 原因与改动

Project 会话列表的 `.project-session-fade` 在底部绘制 24px 渐变，终点使用不透明的 `--dsw-specific-sidebar-fill`。macOS 侧栏透出窗口 vibrancy，因此这层渐变显示为“更多”上方的白条。

固定官方 0.2.0-rc.2 的 `packages/client/ui-workspace/src/client/rows/WorkspaceBrowser.module.css:341` 已有 Darwin 下隐藏渐变的规则。插件 `src/client/styles.ts` 补齐同样规则，仅作用于自己的 `.project-session-fade`，并注明官方来源。官方源码保持只读。

插件本地提交：`0643b3a`（修复 macOS 项目侧栏底部白条）。

## 验证

- 插件 `yarn run check`：类型检查、307/307 测试、构建通过。
- Shell 使用 `DSH_PROJECT_PLUGIN_SOURCE=../dsh-plugin-project yarn run build` 构建通过。
- 正式 Shell 主进程加载官方 0.2.0-rc.2 与本地插件；macOS arm64 的项目与 userData 均建在系统 TEMP。
- 先用原生 AX 确认窗口标题为“Sidebar 验证”，再检查原生窗口截图与目标 `dsh-app://app/` 的实时 DOM。
- 中文、跟随系统的浅色外观（1280×820）：底部白条消失。
- 官方设置切到英文与深色（1280×820）：底部无色块。
- 拖动窗口至 852×672，检查自动折叠与重新展开侧栏：底部无色块，页面无横向溢出。
- 窄窗口会话搜索输入后 Escape 返回空列表；官方设置 Escape 关闭正常。

三次 DOM 采样均为 `data-platform=darwin`、渐变 `display:none`、渐变占用尺寸 0×0、页面横向溢出 false。底色 token 在浅色为 `rgb(249,250,251)`，深色为 `rgb(27,27,28)`，证实此前渐变终点是实色。

## 范围

本次验收覆盖空会话列表；未另造长列表或运行跨平台原生验收。修复只增加 macOS 下的装饰层隐藏规则，不变更会话数据、列表布局或滚动行为。

开发壳已使用本地插件重新构建。未更新发行 pin、安装包或已安装 Stable，未推送。临时窗口验收后退出。
