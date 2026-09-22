---
schemaVersion: 3
directory: Windows 菜单入口可达性：新建-打开-最近项目 只能按 Alt 唤出，缺托盘与界面入口
id: task-e04b2a8f-66d5-47f3-9cc3-f96d4d759ecb
title: Windows 菜单入口可达性：新建/打开/最近项目 只能按 Alt 唤出，缺托盘与界面入口
objective: 记录并设计 Windows/Linux 下「新建项目、打开项目、最近项目、欢迎窗口」等命令的可达性入口问题：现状必须按 Alt 才出现、位置在窗口客户区顶端且只属当前聚焦窗口；给出托盘、窗口级快捷键、标题栏界面入口三条备选路径与取舍，供用户选定后实现（本轮不改代码）。
status: active
createdAt: 2026-09-22T08:55:45.953Z
updatedAt: 2026-09-22T08:55:45.953Z
artifacts: []
archived: false
phase: investigation
brief:
  currentBehavior: Windows 上「新建项目/打开项目/最近项目/欢迎窗口」只存在于 application menu 的 File 组（main.mjs:296-302，含 Ctrl+Shift+N/Ctrl+O/Ctrl+W），不在右键菜单也不在托盘；因 autoHideMenuBar:true，菜单栏默认隐藏，必须按 Alt 才能唤出，且菜单栏压在自定义标题栏之上、仅出现在当前聚焦窗口。
  scope: Windows/Linux 下项目命令（新建项目、打开项目、最近项目、欢迎窗口）的入口位置与可达性设计，含托盘菜单、窗口级快捷键、标题栏界面入口三条备选路径；不包含 Ctrl+R 加速键绑定缺陷本身。
  constraints:
    - Windows 上不得丢失「新建/打开/最近项目」的可达性
    - macOS 保持现状（系统菜单栏已确认无问题）
    - 不设 application menu 时需先安排替代入口，不能先拆后建
    - 官方源码快照只读
  outOfScope:
    - 本轮不改代码（仅记录）
    - macOS 菜单行为不动
    - Ctrl+R 刷新问题（另见 task-b8b39b99）
  acceptanceCriteria:
    - id: c1
      text: Windows 下不按 Alt 也能在不超过一次点击内到达新建项目、打开项目、最近项目
      required: true
      version: 1
    - id: c2
      text: 若保留 Ctrl+Shift+N / Ctrl+O / Ctrl+W 快捷键，其绑定不依赖全局 application menu
      required: true
      version: 1
    - id: c3
      text: macOS 菜单结构、Cmd+R 等既有语义不变
      required: true
      version: 1
handoff:
  nextSteps:
    - 用户在方案 (1) 托盘 / (2) 窗口级快捷键 / (3) 标题栏界面入口 中确定组合后再实现
    - "先在 Windows 实机确认 Electron 43 左 Alt 能否稳定唤出菜单栏（issue #50082 回归）"
    - 确认 Windows 是否保留 application menu；若移除，必须先落地替代入口再拆菜单
  readBefore:
    - main-mjs
    - native-menus
    - upstream-window-options
  verifyBefore:
    - electron-issue-50082
    - electron-custom-titlebar
references:
  - id: main-mjs
    label: application menu 的 File 组与托盘菜单定义
    type: file
    path: resources/dsh-project-desktop/src/app/main.mjs
  - id: native-menus
    label: 全量角色菜单模板（含 reload/toggleDevTools）
    type: file
    path: resources/dsh-project-desktop/src/app/native-menus.mjs
  - id: upstream-window-options
    label: win32 窗口选项：autoHideMenuBar/titleBarOverlay
    type: file
    path: resources/dsh-project-desktop/.upstream/desktop/dsh-plugin-desktop/src/window-options.ts
  - id: guide-index
    label: 欢迎窗口内的新建/打开/最近入口
    type: file
    path: resources/dsh-project-desktop/src/guide/index.tsx
  - id: electron-custom-titlebar
    label: Electron 自定义标题栏文档
    type: url
    url: https://www.electronjs.org/docs/latest/tutorial/custom-title-bar
  - id: electron-issue-50082
    label: Left Alt 不再切换 autoHideMenuBar 的回归
    type: url
    url: https://github.com/electron/electron/issues/50082
entries:
  - id: e1
    kind: scope
    content: 用户要求：不拆改变窗口逻辑，先单独记录「Windows 下新建项目/打开项目等只能按 Alt 唤出」的入口问题。用户明确表示 Ctrl+R 刷新可以接受，本任务聚焦菜单入口与位置。
    basis: user-request
    reason: 与 task-b8b39b99（Ctrl+R 加速键缺陷）分开排期，避免两个问题纠缠。
    createdAt: 2026-09-22T08:55:45.953Z
  - id: e2
    kind: progress
    content: 现状核查：新建项目/打开项目/最近项目/欢迎窗口只在 application menu 的 File 组（main.mjs:296-302），带 Ctrl+Shift+N、Ctrl+O、Ctrl+W；全仓 src 无 context-menu/contextmenu 处理，无 setMenuBarVisibility/showMenuBar；托盘菜单（main.mjs:322-328）只有窗口列表/显示应用/欢迎窗口/检查更新/退出。
    basis: observation
    referenceIds:
      - main-mjs
      - native-menus
    createdAt: 2026-09-22T08:55:45.953Z
  - id: e3
    kind: progress
    content: 位置机制：win32 选项为 titleBarStyle:'hidden' + titleBarOverlay + autoHideMenuBar:true（window-options.ts:143-148）。菜单栏是每窗口客户区顶端的原生条，位于自定义标题栏之上，仅当前聚焦窗口可见，唤出时会占高并下压内容；autoHideMenuBar 语义为「Alt 切换显示」。
    basis: observation
    referenceIds:
      - upstream-window-options
    createdAt: 2026-09-22T08:55:45.953Z
  - id: e4
    kind: progress
    content: 版本风险：本地固定 Electron 43.3.0（.cache/runtime/dsh-plugin-desktop/node_modules/electron）。上游有「Left Alt key no longer toggles autoHideMenuBar after AltGr fix (#50082)」回归，Windows 下左 Alt 唤出菜单栏可能在部分键盘布局失效；本项目在 macOS 上无法验证，必须 Windows 实机确认。
    basis: observation
    referenceIds:
      - electron-issue-50082
      - electron-custom-titlebar
    createdAt: 2026-09-22T08:55:45.953Z
  - id: e5
    kind: decision
    content: 备选方案（按侵入性排序，待选）：(1) 托盘菜单补新建/打开/最近；(2) 窗口级 webContents.on('before-input-event') 自实现 Ctrl+N/O/W，不依赖菜单 accelerator（官方对缩放键即此做法）；(3) 欢迎窗口已有界面入口，可扩展到项目窗口自定义标题栏的菜单按钮（VS Code 风）；(4) 按官方在 Windows 不设 application menu + 用 (1)(2) 补回可达性。三项需先定方向再开工。
    basis: agent-proposal
    createdAt: 2026-09-22T08:55:45.953Z
operations:
  6394229ae7d125edf075f34fe0240579a05cad1220f26a67a64c4e900d325297:
    fingerprint: ac3fe77709e07fa0283ada7eee62fa70b86def6bf81b5570712ce92387d56ae6
    kind: create
    at: 2026-09-22T08:55:45.953Z
    entryIds:
      - e1
      - e2
      - e3
      - e4
      - e5
criterionVersions:
  c1: 1
  c2: 1
  c3: 1
---

已记录（未改代码）：Windows 上「新建项目/打开项目/最近项目/欢迎窗口」只存在于 application menu 的 File 组（main.mjs:296-302，带 Ctrl+Shift+N、Ctrl+O、Ctrl+W），不在右键菜单（src 内无 context-menu 处理）也不在托盘（托盘只有窗口列表/显示应用/欢迎窗口/检查更新/退出，main.mjs:322-328）。win32 窗口为 titleBarStyle:'hidden' + titleBarOverlay + autoHideMenuBar:true（window-options.ts:143），因此菜单栏默认隐藏、必须按 Alt 唤出，且它是每窗口客户区顶端的原生条（压在自定义标题栏之上、仅当前聚焦窗口可见、唤出时下压内容），不是浮层也不是全局菜单。另发现版本风险：本地固定 Electron 43.3.0，上游存在「Left Alt 不再切换 autoHideMenuBar（#50082）」回归，Windows 下 Alt 可能失效，需实机确认。备选方案：托盘补命令、窗口级 before-input-event 快捷键、欢迎窗口/标题栏界面入口，或按官方在 Windows 不设 application menu 并用前三者补回可达性。用户另有独立的 Ctrl+R 任务（task-b8b39b99），本任务不包含该加速键缺陷。
