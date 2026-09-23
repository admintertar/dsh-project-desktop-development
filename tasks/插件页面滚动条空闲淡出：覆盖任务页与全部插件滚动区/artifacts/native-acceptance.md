# 原生验收报告：插件滚动条空闲淡出

- 日期：2026-09-23
- 平台：macOS（darwin，x64 开发机），真实 Electron 项目窗口，非模拟返回
- 构建：`cd resources/dsh-project-desktop && DSH_PROJECT_PLUGIN_SOURCE=/tmp/dsh-scrollbar-worktree yarn run build`（development build，日志见正文说明）
- 探针：`resources/dsh-project-desktop/scripts/probe-scrollbar-native.mjs`，入口 `node /tmp/run-scrollbar-probe.mjs`
- 结果：`passed`（`failures: []`，`PROBE_EXIT=0`）

## 探针做了什么

真实 Host + Renderer 打开一个 fixture 项目（14 个短任务、1 个带长历史的真实任务、8 个资源目录、4 篇已声明记忆文档），窗口 `1280×460`（随后 `760×460` 窄窗口），按面板逐项断言。每个可溢出滚动容器的断言顺序：

1. 空闲：`--project-scrollbar-alpha === 0`、`::-webkit-scrollbar-thumb` 计算值 alpha 为 0、`scrollbar-gutter` 为 `stable` 且保留 8px 滚动槽。
2. 程序化滚动（先归零再滚动，否则同值滚动不派发事件）：`data-project-scrolling` 立即出现、alpha 立即为 1、thumb 不透明。
3. 布局不变：`clientWidth`、`offsetWidth`、gutter、容器的 `left/width/top/height` 与空闲态逐项一致（0.5px 容差）。
4. 停止 1.1s 后：标记移除、alpha 回到 0、thumb 透明，几何仍与空闲态一致。

## 覆盖结论（全部 `passed`）

| 表面 | 选择器 | 结果 |
| --- | --- | --- |
| 任务列表 | `.project-tasks .project-capability-list` | passed |
| 任务详情 | `.project-tasks .project-task-detail` | passed |
| 长设置弹窗正文 | `.project-settings-dialog-content>div:last-child` | passed |
| 页面面板（记忆页） | `.project-panel` | passed |
| 任务列表（暗色主题） | `.project-tasks .project-capability-list` | passed |
| 任务列表（窄窗口 760px） | `.project-tasks .project-capability-list` | passed |
| 任务详情（窄窗口 760px） | `.project-tasks .project-task-detail` | passed |
| 减少动态效果偏好 | `transitionDuration === '0s'`（CDP `Emulation.setEmulatedMedia`） | passed |

## 未覆盖与理由

- **侧栏会话列表 / 资源页 / 工具页**：新 fixture 内容不足，容器未产生溢出（探针记为 `not-overflowing`，不是通过）。这三个容器与上表共用同一份生成规则与清单，由 `tests/client-styles.test.ts` 的清单一致性断言与 `tests/client-scrollbar-auto-hide.test.ts` 的控制器用例覆盖。
- **`:active` 拖动滑块保持可见**：无法在程序化滚动中模拟真实按住滑块，只有 CSS 规则（`::-webkit-scrollbar-thumb:active` 使用不透明 hover 色）与单测对规则的断言。
- **官方聊天表面**：未直接滚动采样。控制器只在 `event.target` 匹配插件清单时才标记，单测用 `official-chat-surface` 断言非清单元素不被标记。
- **中英文案**：本次窗口语言为中文；滚动条本身不含文案，语言切换未单独采样。

## 过程中修复的问题

1. `@property --project-scrollbar-alpha` 原为 `inherits:false`，`::-webkit-scrollbar-thumb` 伪元素因此解析到初始值——宿主 alpha 已为 1 而滑块仍透明。改为 `inherits:true`，并由每个登记容器显式声明 0，避免嵌套容器互相继承。
2. 任务详情容器的 gutter 含卡片 0.5px 边框（共 9px），期望值改为“至少保留 8px 滚动槽”。
3. 面板切换会恢复滚动位置并触发一次真实 scroll，留下短暂标记；探针在采样前等待标记清空并等完 180ms 淡出。
4. 探针在渲染进程发生已记录的 boot-order 缺陷（`renderSlot('root')`）时会因 `executeJavaScript` 永不 settle 而挂死；已加 20s 求值超时与帧等待兜底。

## 证据文件

- `native-scrollbar-report.json` — 探针完整结果（含每个容器的 geometry、`markedWhileScrolling`、`reducedMotion`）
- `native-tasks-idle.png` — 任务页空闲态（2560×1280）
- `native-tasks-dark-idle.png` — 任务页暗色主题（2560×1280）
- `native-tasks-narrow-idle.png` — 任务页窄窗口（1800×1280）
- `native-dialog-idle.png` — 长设置弹窗空闲态（2560×1280）

运行期 `userData` 位于壳仓库被忽略的 `.runtime/scrollbar-probe-fuECeA/`，未进入任务目录。
