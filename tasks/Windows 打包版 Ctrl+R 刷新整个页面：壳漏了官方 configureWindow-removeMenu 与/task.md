---
schemaVersion: 3
directory: Windows 打包版 Ctrl+R 刷新整个页面：壳漏了官方 configureWindow-removeMenu 与
id: task-b8b39b99-9dae-48f5-aa89-89547e4a865c
title: Windows 打包版 Ctrl+R 刷新整个页面：壳漏了官方 configureWindow/removeMenu 与 application menu 裁剪
objective: 记录并定位「Windows 打包版 Ctrl+R 触发整页刷新，官方版不会」的缺陷根因与修复方向，供后续排期实现（用户已确认平台为 Windows，并明确本轮先不改代码）。
status: active
createdAt: 2026-09-22T08:44:33.458Z
updatedAt: 2026-09-22T08:50:41.464Z
artifacts: []
archived: false
phase: investigation
brief:
  currentBehavior: Windows 打包版按 Ctrl+R 会重新加载整个项目渲染页；官方 DSH Desktop 同快捷键无反应。
  scope: 壳侧（resources/dsh-project-desktop）：窗口菜单契约与 BrowserWindow 菜单配置，与插件无关。
  constraints:
    - 官方源码快照只读
    - 修复需保持 macOS 菜单行为不变（Cmd+R 属官方语义）
    - 验收需要 Windows 实机；不得用 macOS 结果声称 Windows 通过
  outOfScope:
    - 本轮不实现修复（用户明确先不改）
    - 不改动 resources/dsh-plugin-project
handoff:
  nextSteps:
    - 与用户确认 Windows 菜单取舍后再动代码（本轮用户已选择先不改）
    - 取舍已量化：Windows 对齐官方后功能仍可达（欢迎窗口按钮/列表 + 托盘「欢迎窗口」），代价是 Ctrl+Shift+N / Ctrl+O / Ctrl+W 与 Alt 菜单栏；如需保留快捷键改用窗口级 before-input-event
    - 实现后在 Windows 实机验证：Ctrl+R 与 Ctrl+Shift+R/F12 不再重载，Alt 不唤出菜单栏，macOS 仍保留 Cmd+R 与完整菜单
  readBefore:
    - native-mjs
    - main-mjs
    - native-menus
    - upstream-platform
  verifyBefore:
    - upstream-spec
    - upstream-runtime-spec
references:
  - id: native-mjs
    label: 我们的项目窗口创建（缺 configureWindow 调用）
    type: file
    path: resources/dsh-project-desktop/src/desktop-adapter/native.mjs
  - id: main-mjs
    label: 全平台设置 application menu
    type: file
    path: resources/dsh-project-desktop/src/app/main.mjs
  - id: native-menus
    label: 含 reload/toggleDevTools role 的视图菜单
    type: file
    path: resources/dsh-project-desktop/src/app/native-menus.mjs
  - id: upstream-platform
    label: 官方策略：win32 removeMenu / darwin 设菜单
    type: file
    path: resources/dsh-project-desktop/.upstream/desktop/dsh-plugin-desktop/src/electron-platform.ts
  - id: upstream-shell
    label: 官方调用点 configureWindow(window)
    type: file
    path: resources/dsh-project-desktop/.upstream/desktop/dsh-plugin-desktop/src/electron-shell-generation.ts
  - id: upstream-spec
    label: 官方契约测试：win32 removeMenu 且不设 application menu
    type: file
    path: resources/dsh-project-desktop/.upstream/desktop/dsh-plugin-desktop/tests/electron-platform.spec.ts
  - id: upstream-runtime-spec
    label: 官方契约测试：autoHideMenuBar + removeMenu
    type: file
    path: resources/dsh-project-desktop/.upstream/desktop/dsh-plugin-desktop/tests/electron-runtime.spec.ts
entries:
  - id: e1
    kind: scope
    content: 用户报告：打包版 Ctrl+R 刷新整个页面，官方版不会；并确认平台为 Windows。本轮用户明确「先不改」，仅记录定位结论。
    basis: user-request
    reason: 限定本次记录的范围为壳侧窗口菜单契约，不含插件与实现改动。
    createdAt: 2026-09-22T08:44:33.458Z
  - id: e2
    kind: progress
    content: 官方链路：electron-shell-generation.ts:298 建窗后调用 platform.configureWindow(window)；electron-platform.ts WindowsPlatformStrategy.configureWindow → window.removeMenu()，MacPlatformStrategy 为空实现；官方 application menu 仅在 MacPlatformStrategy.refreshApplicationMenu 中设置，Windows/Linux 的 configureApplication/refreshApplicationMenu 为空实现（electron-runtime.ts 不自调 Menu.setApplicationMenu）。
    basis: observation
    referenceIds:
      - upstream-platform
      - upstream-shell
    createdAt: 2026-09-22T08:44:33.458Z
  - id: e3
    kind: progress
    content: 我方差异：native.mjs:66 创建 platformStrategy 后只传给 createWindowMaterialRefresher，src/ 全量搜索无 configureWindow / removeMenu 调用；main.mjs:321 在所有平台执行 Menu.setApplicationMenu；native-menus.mjs:17 视图菜单含 role('reload') 与 role('toggleDevTools')。
    basis: observation
    referenceIds:
      - native-mjs
      - main-mjs
      - native-menus
    createdAt: 2026-09-22T08:44:33.458Z
  - id: e4
    kind: decision
    content: 根因判定：Windows 上 advancedWindowOptions 仅设 autoHideMenuBar:true（window-options.ts:143），菜单栏仅被隐藏、加速键仍生效；我们全局设置含 reload role 的 application menu，使 Ctrl+R 命中 webContents.reload()。官方因 removeMenu 且不设 application menu 而无绑定。
    basis: agent-proposal
    referenceIds:
      - native-menus
      - upstream-platform
    createdAt: 2026-09-22T08:44:33.458Z
  - id: e5
    kind: progress
    content: 官方契约测试固定了该行为：electron-platform.spec.ts:55（win32 removeMenu 被调用、Menu.setApplicationMenu 未被调用、darwin 反之）、electron-runtime.spec.ts:781（win32 autoHideMenuBar:true + removeMenu 各一次）。
    basis: observation
    referenceIds:
      - upstream-spec
      - upstream-runtime-spec
    createdAt: 2026-09-22T08:44:33.458Z
  - id: e6
    kind: decision
    content: 修复方向（待排期，未实现）：(a) 必做——在 native.mjs 与 guide-window.mjs 建窗后补 platformStrategy.configureWindow(window)，对齐官方 Windows 语义；(b) 取舍——Windows 是否保留我方 application menu，若完全对齐官方则菜单栏与「新建/打开项目、项目工具、Profile、恢复」入口一并消失，需确认是否有托盘菜单承载，或在 Windows 上只裁剪 reload/toggleDevTools。
    basis: agent-proposal
    createdAt: 2026-09-22T08:44:33.458Z
  - id: e7
    kind: progress
    content: 菜单宿主按平台不同（Electron 模型）：macOS 为全局系统菜单栏（window.removeMenu() 为 no-op），Windows/Linux 为每窗口菜单栏，accelerator 由该窗口菜单解析、无则回退 application menu。我方现状：main.mjs 全平台 setApplicationMenu；advancedWindowOptions 在 Windows 只设 autoHideMenuBar:true（仅隐藏，accelerator 仍生效）。官方：仅 darwin 设置（复用 macApplicationMenuTemplate），win32 建窗后 removeMenu()，linux 既不设也不 removeMenu（electron-platform.spec.ts:97 期望不被调用）。
    basis: observation
    referenceIds:
      - upstream-platform
      - upstream-spec
      - main-mjs
    createdAt: 2026-09-22T08:50:41.464Z
  - id: e8
    kind: progress
    content: 命令落点核查（为取舍提供依据）：新建项目/打开项目/最近项目/欢迎窗口目前只在 application menu 的 File 组（main.mjs:296-302，含 Ctrl+Shift+N、Ctrl+O、Ctrl+W），不在任何右键菜单（src/ 内无 context-menu/contextmenu 处理）；托盘菜单（main.mjs:322-328）仅含窗口列表/显示应用/欢迎窗口/检查更新/退出，不含新建、打开、最近；欢迎窗口界面自带「新建项目」按钮（index.tsx:369）、「打开」按钮与最近项目列表（含行内 ⋯ 浮层菜单，index.tsx:101-104）。
    basis: observation
    referenceIds:
      - main-mjs
      - native-menus
    createdAt: 2026-09-22T08:50:41.464Z
  - id: e9
    kind: decision
    content: 取舍结论：Windows 对齐官方后功能仍可经欢迎窗口界面与托盘到达，不会被切断；实际会丢失的是 application menu 提供的键盘加速键 Ctrl+Shift+N/Ctrl+O/Ctrl+W（仅由菜单 accelerator 提供）以及 Alt 唤出的菜单栏。若要保留快捷键又对齐官方外观，应改用窗口级 webContents.on('before-input-event')（官方对缩放键即此做法），而不是继续依赖全局 application menu。
    basis: agent-proposal
    referenceIds:
      - main-mjs
      - upstream-shell
    createdAt: 2026-09-22T08:50:41.464Z
operations:
  f2650d9ba9d5ccfaf04d914f7946ec779032cdd8fa5cb8a9878470c44352826d:
    fingerprint: 4cc5b4d31c9ab965391cf3727c838b0ea8e13eb06c5a322ca73ce09dd6c0cb7e
    kind: create
    at: 2026-09-22T08:44:33.458Z
    entryIds:
      - e1
      - e2
      - e3
      - e4
      - e5
      - e6
  66a06da3fef472b9db3f994286fdc842462995546e0c2f118c83e79955025751:
    fingerprint: bfb194186aa6cabd3e924a61ca7a24d28c08b73bbc037a0718907d735c4bf94c
    kind: update
    at: 2026-09-22T08:50:41.464Z
    entryIds:
      - e7
      - e8
      - e9
criterionVersions: {}
---

已定位根因（未改代码）：官方壳在建窗后无条件调用 platform.configureWindow(window)，Windows 策略执行 window.removeMenu()，且官方 application menu 只在 macOS 设置；我们的 native.mjs:66 只把 platformStrategy 用于窗口材质刷新，从未调用 configureWindow（src/ 内无 configureWindow/removeMenu），同时 main.mjs:321 在所有平台执行 Menu.setApplicationMenu(nativeRoleMenus 全量模板)，其中 native-menus.mjs:17 含 role('reload')/role('toggleDevTools')。Windows 上 advancedWindowOptions 只设 autoHideMenuBar:true（window-options.ts:143），菜单栏只是隐藏，加速键仍生效，因此 Ctrl+R 命中 reload role 导致整页重载。官方契约有测试固定：electron-platform.spec.ts:55 期望 win32 调用 removeMenu 且 setApplicationMenu 不被调用；electron-runtime.spec.ts:781 期望 autoHideMenuBar:true 与 removeMenu 各一次。修复需权衡：完全对齐官方会同时失去 Windows 菜单栏里的新建/打开项目、项目工具、Profile、恢复等入口，可能需托盘菜单承载。用户已确认平台为 Windows，并明确本轮先不改代码。
