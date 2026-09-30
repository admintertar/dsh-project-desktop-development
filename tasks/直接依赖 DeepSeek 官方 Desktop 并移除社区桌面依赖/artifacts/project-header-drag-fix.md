# Project 页面顶部拖动修复

## 原因

官方 PluginManager 页面把顶部标题行标记为 `data-window-drag`，并把 macOS 的 frame top clearance 放进标题行自身；基础 CSS 再统一排除按钮、输入框和菜单。Project 的 Resources、Memory、Tasks、Skills、Tools、MCP 页面此前只有 `.project-panel` 的内部 `padding-top:28px`，没有拖动标记，因此窗口顶部落在普通内容区，不能拖动。

## 修复

Project 的所有页面 header 增加 `data-window-drag`。空项目/加载状态也使用同一标题行。样式把 panel 顶部 padding 移到 header：普通顶部 28px，macOS 为 `28px + var(--dsh-frame-top-clearance)`，与官方 PluginManagerPage 对齐。官方基础 CSS 继续负责按钮和弹窗的 `no-drag` 区域。

插件提交待本地提交；官方源码不变。

## 验收

- 插件 `yarn run check`：类型检查、构建及 307 项原有测试通过；新增页面拖动契约静态断言通过。
- Shell 使用本地插件重建通过。
- macOS arm64 真窗口「Sidebar 验证」中，Resources 与 Memory 页实时 DOM 均显示 header `data-window-drag`、计算样式 `-webkit-app-region: drag`、顶部 `padding-top: 76px`（28 + 官方 48px），刷新按钮计算样式为 `no-drag`。
- 资源页窗口 1518×979，无横向溢出；真实窗口顶部拖动操作后仍保持同一窗口和项目页面。
- 原生窗口和临时项目数据在系统 TEMP，未触碰 Stable 数据。
