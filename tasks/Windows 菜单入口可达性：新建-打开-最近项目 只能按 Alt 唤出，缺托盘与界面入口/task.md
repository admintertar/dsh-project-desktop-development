---
schemaVersion: 3
directory: Windows 菜单入口可达性：新建-打开-最近项目 只能按 Alt 唤出，缺托盘与界面入口
id: task-e04b2a8f-66d5-47f3-9cc3-f96d4d759ecb
title: Windows 菜单入口可达性：新建/打开/最近项目 只能按 Alt 唤出，缺托盘与界面入口
objective: 记录并设计 Windows/Linux 下「新建项目、打开项目、最近项目、欢迎窗口」等命令的可达性入口问题：现状必须按 Alt 才出现、位置在窗口客户区顶端且只属当前聚焦窗口；给出托盘、窗口级快捷键、标题栏界面入口三条备选路径与取舍，供用户选定后实现（本轮不改代码）。
status: active
createdAt: 2026-09-22T08:55:45.953Z
updatedAt: 2026-09-22T16:22:48.636Z
artifacts:
  - type: file
    path: artifacts/evidence/README.md
    description: 窗口级快捷键保底的实现与单元测试（壳侧，removeMenu 后仍可用）
  - type: file
    path: artifacts/evidence/alt-menu-probe-run5.log
    description: 决定性探针运行日志（产品选项 setMenu+setMenuBarVisibility 仍无菜单栏；托盘建议菜单）
  - type: file
    path: artifacts/evidence/63-B-control-menu-bar-window.png
    description: 正对照：标准边框窗口显示 26 DIP 原生菜单栏（文件/视图/窗口）
  - type: file
    path: artifacts/evidence/71-devshell-welcome-after-left-alt.png
    description: 真实开发壳欢迎窗口按左 Alt 后无菜单栏（产品级证据）
  - type: file
    path: artifacts/evidence/65-tray-proposed-menu.png
    description: 托盘菜单可承载新建/打开/最近（popUpContextMenu 截图）
  - type: file
    path: artifacts/evidence/96-titlebar-material.png
    description: 【旧】顶栏与材质一致的效果图
  - type: file
    path: artifacts/evidence/93-titlebar-file-menu-final.png
    description: 【旧】文件菜单展开图
  - type: file
    path: artifacts/evidence/86-titlebar-first-look.png
    description: 首版实机效果（顶栏贯通 + sidebar 下移）
  - type: file
    path: artifacts/evidence/D0-codex-layout.png
    description: C 布局实拍（展开态：☰ + 项目名 + 四组菜单）
  - type: file
    path: artifacts/evidence/E1-titlebar-final-top.png
    description: C 布局顶栏特写（无分隔符、项目名为纯文本）
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: fd7b48f5fbfcab188b0e9184dc434c6df3cf7449
    description: 窗口级快捷键绑定（Windows 不再依赖 application menu）+ 5 例单测
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: f6452bf31b921d196c20179f562dbbee4dea091a
    description: Windows 项目窗口自绘顶栏菜单（shell-titlebar-client.tsx / shell-titlebar-actions.mjs / native.mjs / shell-client.ts / main.mjs）+ 4 例单测
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: a8786cf6b51ab7edc1b9ab58f5ca773cbeeb23ca
    description: 发布 0.1.7（package.json + docs/releases/0.1.7.md）
  - type: file
    path: artifacts/evidence/K1-long-name.png
    description: 长项目名截断到侧栏边界（K1）
  - type: file
    path: artifacts/evidence/L1-short-name.png
    description: 短项目名：菜单紧贴项目名（L1）
  - type: file
    path: artifacts/evidence/I1-divider-fix.png
    description: 分界线不再延伸进顶栏（I1）
archived: false
phase: design
brief:
  currentBehavior: 已由 Windows 实机探针更正：产品窗口（autoHideMenuBar:true + titleBarStyle:'hidden' + titleBarOverlay 40，window-options.ts:143-148）上原生菜单栏根本无法显示，不只是默认隐藏。探针同选项窗口 isMenuBarVisible() 恒 false，左 Alt/VK_MENU/纯扫描码 Alt/右 Alt/F10、setMenuBarVisibility(true)、setAutoHideMenuBar(false)、win.setMenu(appMenu)、窗口已存在后再 setApplicationMenu 全部无效，内容区不变；真实产品窗口（已安装 app 项目窗口、开发壳欢迎窗口）外部 Win32 GetMenu(hwnd)==0。正对照（标准系统边框窗口）setMenu+setMenuBarVisibility(true) 后可见 26 DIP 原生菜单栏。File 组命令（新建/打开/最近/欢迎窗口，main.mjs:305-311，托盘 main.mjs:331-337 不含它们）今天在 Windows 上唯一可达路径是 accelerator（Ctrl+Shift+N / Ctrl+O / Ctrl+W），已改为窗口级绑定（window-accelerators.mjs，Windows 上不再由 application menu 注册）。标题栏自绘：客户区含顶部 40 DIP 均由渲染进程绘制，Electron 只画右上角三个原生窗口按钮。项目窗口顶行由官方 renderer 的 sidebar（@deepseek-ai/dsh-client-ui-sidebar）绘制，已确认它开放了 sidebar.brand.mark / sidebar.brand.name / sidebar.workspaces / sidebar.panellist / sidebar.footer.action / sidebar.settings 六个子 slot，可通过壳的 client 插件（shell-client.ts 已注入 slots 服务）注入菜单按钮。
  scope: Windows/Linux 下项目命令（新建项目、打开项目、最近项目、欢迎窗口）的入口位置与可达性：在自绘顶栏内注入「文件」菜单（Codex 式，紧接官方收起图标），并以窗口级快捷键保底；含实现、构建与 Windows 原生验收，不含 macOS 菜单改动与 Ctrl+R 绑定缺陷本身。
  constraints:
    - Windows 上不得丢失「新建/打开/最近项目」的可达性
    - macOS 保持现状（系统菜单栏已确认无问题）
    - 不设 application menu 时需先安排替代入口，不能先拆后建；task-b8b39b99 的 removeMenu 落地前必须先有替代入口（实测 removeMenu 后 accelerator 全灭）
    - 官方源码快照只读：菜单 UI 只能通过官方 client slot 注入，不改 .upstream 快照
    - 入口实现需避开 titleBarOverlay 的窗口控件安全区（env(titlebar-area-*))
    - 用户已定方向：像 Codex 一样，项目窗口顶栏左侧「收起图标 + 文件菜单」同一行
  outOfScope:
    - macOS 菜单行为不动
    - Ctrl+R 刷新问题（另见 task-b8b39b99）
    - 不改官方 .upstream 快照与插件仓库界面
  acceptanceCriteria:
    - id: c1
      text: Windows 下不按 Alt 也能在不超过一次点击内到达新建项目、打开项目、最近项目
      required: true
      version: 3
    - id: c2
      text: 若保留 Ctrl+Shift+N / Ctrl+O / Ctrl+W 快捷键，其绑定不依赖全局 application menu
      required: true
      version: 3
    - id: c3
      text: macOS 菜单结构、Cmd+R 等既有语义不变
      required: true
      version: 3
questions:
  - 顶栏菜单是否需要在每次打开项目窗口时都可用（包括安全模式/恢复窗口），或仅普通项目窗口
handoff:
  nextSteps:
    - CI：tag v0.1.7 会触发 package.yml 构建两个平台并自动发布 Release（基准 20–25 分钟）；查进度需带认证（匿名 api.github.com 已 403），日志与 artifact 必须认证
    - 补验收：英文文案 / 暗色主题 / 窄窗（<1024 自动折叠）三张图，以及 Ctrl+Shift+N/O/W 在开发壳里的端到端实测（c2 仍为 not-run）
    - macOS 回归（c3）：本轮未实机，顶栏只在 win32/linux 注册，需在 mac 上确认菜单栏与 Cmd 快捷键未被影响
    - 候选优化：插件贡献的「项目工具」动态分组；菜单位置是否改为固定（现在随项目名长度浮动）；欢迎窗口是否也加同款顶栏
    - 本机环境：git 推 github 需走系统代理（已写入壳仓库 .git/config）；两个临时验收项目在 %TEMP%\dsh-titlebar-probe、%TEMP%\dsh-longname-probe、%TEMP%\dsh-shortname-probe，可删
  readBefore:
    - shell-client
    - window-accelerators
    - evidence-readme
  verifyBefore:
    - evidence-readme
references:
  - id: main-mjs
    label: application menu 的 File 组、托盘菜单与窗口级快捷键接线
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
    label: Electron 自定义标题栏文档（titlebar-area 安全区）
    type: url
    url: https://www.electronjs.org/docs/latest/tutorial/custom-title-bar
  - id: electron-issue-50082
    label: "Left Alt 不再切换 autoHideMenuBar 的回归（duplicate of #50050）"
    type: url
    url: https://github.com/electron/electron/issues/50082
  - id: evidence-readme
    label: Windows 实机证据与结论（F1-F6 + 方法学备注）
    type: file
    path: artifacts/evidence/README.md
  - id: evidence-run5
    label: 决定性探针运行日志（产品选项无法显示菜单栏 + 托盘建议菜单）
    type: file
    path: artifacts/evidence/alt-menu-probe-run5.log
  - id: evidence-b-window
    label: 正对照截图：标准边框窗口上的 26 DIP 原生菜单栏
    type: file
    path: artifacts/evidence/63-B-control-menu-bar-window.png
  - id: evidence-devshell-alt
    label: 真实开发壳欢迎窗口按左 Alt 后（无菜单栏）
    type: file
    path: artifacts/evidence/71-devshell-welcome-after-left-alt.png
  - id: evidence-tray-menu
    label: 托盘建议菜单截图（popUpContextMenu）
    type: file
    path: artifacts/evidence/65-tray-proposed-menu.png
  - id: window-accelerators
    label: 新增：窗口级 Ctrl+Shift+N/O/W 绑定（Windows 不依赖 application menu）
    type: file
    path: resources/dsh-project-desktop/src/app/window-accelerators.mjs
  - id: shell-client
    label: 壳的 client 插件（已注入官方 slots，菜单注入点）
    type: file
    path: resources/dsh-project-desktop/src/desktop-adapter/stable/shell-client.ts
  - id: official-sidebar-slots
    label: 官方 sidebar 行开放的子 slot（brand.name / workspaces / panellist …）
    type: file
    path: resources/dsh-project-desktop/.cache/runtime/dsh-plugin-desktop/node_modules/@deepseek-ai/dsh-client-ui-sidebar/lib/client.js
  - id: advanced-frame
    label: 官方 advanced 模式 frame 与 slot 渲染点（sidebar/rightbar/shell.overlay/main）
    type: file
    path: resources/dsh-project-desktop/.upstream/desktop/dsh-plugin-desktop/src/client/AdvancedFrame.tsx
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
  - id: e6
    kind: progress
    content: Windows 实机验证完成（首次具备条件）：Electron 43.3.0 / Windows 10.0.26200 / 200% DPI，用与产品窗口逐项同选项的探针 + user32!keybd_event 真注入（每次注入前 GetForegroundWindow 证明前台）得出：F1 产品窗口无原生菜单栏（探针 API 全无效 + 真实窗口 GetMenu==0 + 标准边框正对照可见 26 DIP 菜单栏）；F2 accelerator 在菜单栏隐藏时仍有效（Ctrl+Shift+N/O/R 均命中）；F3 removeMenu() 后 accelerator 全灭；F4 托盘可承载三个命令（popUpContextMenu 截图），但新图标被 Windows 放进溢出区（通知区域像素差仅 87px，可见图标应为 64x64 物理像素块）；F5 左 Alt 在标准边框窗口上能隐藏可见菜单栏、但唤不出隐藏菜单栏（electron#50050/#50082 在本机 43.3.0 复现）；F6 标题栏为自绘（titleBarStyle:hidden 去系统标题栏，titleBarOverlay 只画右上角三个原生按钮，其余客户区含顶部 40 DIP 由 React 渲染）。证据与完整时间线：artifacts/evidence/README.md。
    basis: observation
    referenceIds:
      - evidence-readme
      - electron-issue-50082
    createdAt: 2026-09-22T14:34:49.534Z
  - id: e7
    kind: decision
    content: 方向收敛（待用户选定后实现）：原生菜单栏方案被实机证据排除。可行组合按代价排序——(a) 在自绘标题栏内加命令入口（VS Code/Chrome 风，1 次点击打开菜单，新建/打开/最近同屏，需避开 env(titlebar-area-*) 的窗口控件区）；(b) 托盘菜单补「新建/打开/最近」，机器上图标已被固定时 1 次右键，首次使用因 Windows 溢出区默认隐藏而需 2 次点击；(c) 窗口级 before-input-event 快捷键作为保底，必须在 task-b8b39b99 的 removeMenu 落地前完成，否则 Ctrl+Shift+N/O/W 一并失效。推荐 (a)+(c)，按需叠加 (b)。
    basis: agent-proposal
    referenceIds:
      - evidence-readme
      - main-mjs
    createdAt: 2026-09-22T14:34:49.534Z
  - id: e8
    kind: progress
    content: 验收基线（本轮不实现，仅记录）：c1 未达标——Windows 产品窗口既无原生菜单栏也无窗口内界面入口（File 组命令只在 main.mjs:305-311 的 application menu，托盘 main.mjs:331-337 不含，src 内无 context-menu）。c2 未达标——accelerator 目前由全局 application menu 提供（菜单栏隐藏时有效、removeMenu 后全灭），改用窗口级绑定后才成立。c3 本轮无改动，无需回归。
    basis: observation
    referenceIds:
      - evidence-readme
    createdAt: 2026-09-22T14:34:49.534Z
  - id: e9
    kind: scope
    content: scope/constraints 收敛：scope 明确为「自绘标题栏内命令入口 / 托盘菜单 / 窗口级快捷键」三条路径的取舍与实现方案；constraints 新增「入口实现需避开 titleBarOverlay 的窗口控件安全区（env(titlebar-area-*)）」与「removeMenu 落地前必须先有替代入口（实测 accelerator 全灭）」。验收标准 c1-c3 文本不变。
    basis: observation
    referenceIds:
      - evidence-readme
    reason: 实机证据推翻了「菜单栏默认隐藏、按 Alt 唤出」的现状前提，并把两个实现约束固化下来，需要同步 scope/constraints。
    createdAt: 2026-09-22T14:34:49.534Z
  - id: e10
    kind: progress
    content: 窗口级快捷键保底已实现（壳侧，已改代码）：新增 src/app/window-accelerators.mjs（matchWindowAccelerator 纯函数 + installWindowAccelerators，仅 win32 生效，macOS 不安装）；main.mjs 在 Windows 上不再由 application menu 注册 Ctrl+Shift+N / Ctrl+O / Ctrl+W（refreshMenus 的 fileAccelerator），改为窗口级 before-input-event 绑定到 newProject / pickOpen / 当前项目 close（窗口→项目映射，回退到 active()）；新增 tests/window-accelerators.test.mjs（5 例：三个组合映射、无关组合不拦截、autoRepeat 不重复触发、win32 装到当前+未来窗口且不重复挂载、macOS 不安装）。`yarn check` 全绿（EXIT=0，103 项主测试 + 恢复/安全模式 7+1 项 + 宿主冒烟，官方源码完整性通过）。开发壳（隔离 userData）能正常起「欢迎使用 DSH Project Desktop」窗口，说明改动未破坏启动。
    basis: observation
    referenceIds:
      - window-accelerators
      - main-mjs
    createdAt: 2026-09-22T14:42:14.160Z
  - id: e11
    kind: progress
    content: 官方顶栏注入点已查实（只读快照/运行时包）：项目窗口为 advanced 模式，官方 AdvancedFrame 渲染 sidebar / rightbar / shell.overlay / main 四个 slot；sidebar 包自己声明了子 slot：sidebar.brand.mark、sidebar.brand.name、sidebar.workspaces、sidebar.panellist、sidebar.footer.action、sidebar.settings（renderSlot 调用点位于 @deepseek-ai/dsh-client-ui-sidebar/lib/client.js）。壳的 client 插件（src/desktop-adapter/stable/shell-client.ts）已注入 slots 服务，并已用同样方式注入 settings.section/settings.action，因此「文件」菜单按钮可以按官方方式注入顶行，无需改官方快照。
    basis: observation
    referenceIds:
      - official-sidebar-slots
      - shell-client
    createdAt: 2026-09-22T14:42:14.160Z
  - id: e12
    kind: scope
    content: 实现方向（用户定）：项目窗口像 Codex 一样，顶栏左侧「现有收起图标 + 文件菜单」同一行；菜单内容为新建项目 / 打开项目 / 最近项目（可扩展到编辑/视图/帮助）。实现分三步：(1) 壳 client 插件用官方 slot 注入菜单按钮与弹出菜单，复用官方 UI 组件与 i18n，避开 titleBarOverlay 安全区；(2) 主进程沿既有 renderer action 通道（native.mjs 的 createDesktopRendererActionDispatcher）补三个命令，复用 main.mjs 已有的 newProject / pickOpen / recent 列表逻辑；(3) 重建 client bundle 后做 Windows 原生验收（中英文案、主题、窄窗口、键盘）并把截图落 tasks/<task>/artifacts/。窗口级快捷键保底（e10）已完成，是这三步的前置条件。
    basis: user-request
    referenceIds:
      - official-sidebar-slots
      - window-accelerators
      - main-mjs
    reason: 用户明确选定 Codex 式菜单位置并授权实现，任务从调查/设计转为实现，需把实现路径与分步方案固定下来。
    createdAt: 2026-09-22T14:42:14.160Z
  - id: e13
    kind: progress
    content: "落点修订（用户纠正后核实）：菜单不是注入 sidebar 行内的 slot，而应画在一条**满窗宽的顶栏**上（Codex 式）。官方 advanced frame 已存在两个可用结构：.dshDesktopWindowsCaptionRow（grid-column: 2 / -1，仅覆盖 sidebar 右侧，右侧留 WINDOWS_CAPTION_CONTROLS_WIDTH 给原生窗口按钮，带 -webkit-app-region: drag）与 .dshDesktopOverlay / shell.overlay（inset:0、z-index:1000、pointer-events:none + 子元素恢复）。因此实现=把这条 caption 行扩成整宽（1 / -1）并让 sidebar/内容下移一行，或直接由 shell.overlay 画满宽顶栏；官方 extended 模式的 .dshDesktopFrameTitlebar（extended-styles.ts:88）已是一整条自绘顶栏，含平台差异与 drag/no-drag 约定，可照搬其样式结构。另：右上角三个窗口按钮不是壳自绘，是 Electron titleBarOverlay 绘制，需避开其安全区。"
    basis: observation
    referenceIds:
      - advanced-frame
      - official-sidebar-slots
      - electron-custom-titlebar
    createdAt: 2026-09-22T14:46:54.019Z
  - id: e14
    kind: decision
    content: 菜单分组已定（与 macOS 保持一致，去平台专有项）：文件（新建项目… / 打开项目… / 最近项目 ▸ / 欢迎窗口 / 关闭项目）、编辑（撤销/重做/剪切/复制/粘贴/粘贴并匹配样式/删除/全选）、视图（重新加载/切换开发者工具/实际大小/放大/缩小/全屏）、项目工具（插件贡献项 + 打开项目终端 / 导出项目诊断… / Profile… / 重启当前项目 / 安全模式 / 项目恢复…）。macOS 的应用菜单为系统专有，不搬到 Windows 顶栏；Codex 的「帮助」无对应内容，暂不放。
    basis: user-request
    referenceIds:
      - native-menus
      - main-mjs
    createdAt: 2026-09-22T14:46:54.019Z
  - id: e15
    kind: progress
    content: 顶栏实现契约已全部查实（可直接施工）：(1) 命令通道——官方 preload 桥 window[DESKTOP_RENDERER_ACTIONS_BRIDGE].invoke(action) → ipc『dsh-desktop:renderer-action』；主进程 dispatcher 是官方白名单（renderer-actions-dispatch.ts:52-63，default throw），所以壳侧在 native.mjs:177 的 ipc.handle 里先匹配自定义动作再回落官方 dispatch，不需要改官方代码。(2) 侧栏收起——官方 layout 服务通过 ctx.reflect.provide('layout') 暴露 ILayout，含 toggleSidebar()（dsh-client-ui-layout/service.d.ts:24-37）。(3) 几何——ctx.desktopWindow.dragRegion（height=顶栏高、rightInset=窗口控件安全区）与 safeAreaInsets（官方 contracts.ts:33-48），由壳已调用的 provideDesktopWindow 提供。(4) 官方 Windows 布局——.dshDesktopFrame[win32] 为两行 grid（第一行=ADVANCED_WINDOWS_TITLEBAR_HEIGHT），sidebar 贯穿 grid-row 1/-1，caption row 仅 grid-column 2/-1，overlay inset:0/z-index:1000。(5) 样式下移先例——官方 macOS 就是给 .dshDesktopUpstreamSidebar 加 padding-top 给 traffic lights 让位（styles.ts:19），Windows 同法让出顶栏高度。(6) 菜单项内容与 macOS 对齐（e14）。
    basis: observation
    referenceIds:
      - advanced-frame
      - shell-client
      - official-sidebar-slots
      - electron-custom-titlebar
    createdAt: 2026-09-22T14:48:00.960Z
  - id: e16
    kind: decision
    content: 实施顺序决定：顶栏 UI 不在本轮半做。项目规范要求 UI 改动必须做原生视觉验收（中英文案、主题、窄窗、键盘），而本轮剩余预算不足以同时完成客户端组件、主进程动作、client bundle 构建与实机验收；已完成且已验证的是窗口级快捷键保底（e10）。顶栏按 e15 契约一次性实现并在同一轮完成构建与原生验收，避免留下未验收的 UI。
    basis: agent-proposal
    createdAt: 2026-09-22T14:48:00.960Z
  - id: e17
    kind: progress
    content: 顶栏菜单已实现并实机运行（壳源码改动）：新增 src/desktop-adapter/stable/shell-titlebar-client.tsx（注册官方 shell.overlay slot；几何读 ctx.desktopWindow.dragRegion；收起按钮调 ctx.layout.toggleSidebar；四组菜单 文件/编辑/视图/项目工具，中英双语；菜单定位用按钮 getBoundingClientRect；Esc 与点击外部关闭）与 shell-titlebar-actions.mjs（壳动作白名单 + runner）；shell-client.ts 接入 applyShellTitlebar（darwin 直接 return）；native.mjs 在 ipc『dsh-desktop:renderer-action』里先匹配壳请求再回落官方 dispatch，edit/view 用 webContents 方法；main.mjs 向 openNativeProject 传 newProject / openProject / showWelcome / closeProject / recentProjects / openRecent。样式按官方 extended 顶栏的材质规则（body:not([material=off]) → color-mix(bg-base 18%, transparent)，否则 layer-1），并把 .dshDesktopWindowsCaptionRow 在材质开启时置透明、给 .dshDesktopUpstreamSidebar 加 padding-top 让出整条顶栏。验收：yarn build 通过；yarn check 全绿（106 项主测试含新增 3 项 + 7 恢复 + 1 安全模式 + 冒烟）；开发壳实机截图 86（首版）、93（文件菜单）、96（材质一致）。
    basis: observation
    referenceIds:
      - window-accelerators
      - shell-client
      - advanced-frame
      - evidence-readme
    createdAt: 2026-09-22T15:06:33.024Z
  - id: e18
    kind: verification
    content: c1 验收（Windows）：顶栏「文件」菜单 1 次点击即可看到并执行新建项目…/打开项目…/欢迎窗口/关闭项目，同一面板列出最近项目并可点击打开（截图 93-titlebar-file-menu-final.png，窗口已证明前台）。菜单项文案与快捷键标注与 macOS 文件菜单一致。
    basis: observation
    referenceIds:
      - evidence-readme
    verification:
      criterionId: c1
      criterionVersion: 3
      method: 开发壳实机截图 + 鼠标真注入点击（artifacts/evidence/93-titlebar-file-menu-final.png）
      result: passed
      coverage: Windows 实机：点击顶栏「文件」→ 菜单展开且三项均可达；未逐项执行新建/打开流程（会真实建项目/选目录）
    createdAt: 2026-09-22T15:06:33.024Z
  - id: e19
    kind: verification
    content: c2 状态：Windows 上三个快捷键已改为窗口级 before-input-event 绑定且 application menu 不再注册它们（单测 5 例覆盖，yarn check 通过）；但「开发壳里按 Ctrl+Shift+N 真的弹出新建项目窗口」的端到端实测本次被中断，未取得截图证据，因此仍记为未验收。
    basis: observation
    referenceIds:
      - window-accelerators
    verification:
      criterionId: c2
      criterionVersion: 3
      method: 单测 tests/window-accelerators.test.mjs（5 例）
      result: not-run
      coverage: 单测证明绑定不依赖 application menu；端到端实机未跑完
      reason: 开发壳内的快捷键端到端点击验证未完成（上一条注入命令被中断）。
    createdAt: 2026-09-22T15:06:33.024Z
  - id: e20
    kind: verification
    content: c3 状态：本轮未改 macOS 代码路径（applyShellTitlebar 在 darwin 直接 return），application menu 模板未动；但本轮无 macOS 实机，未做回归验收。
    basis: observation
    verification:
      criterionId: c3
      criterionVersion: 3
      method: 代码路径审查（darwin 不注册顶栏；菜单模板未改）
      result: not-run
      coverage: 无 macOS 实机可验
      reason: 本机为 Windows，无法执行 macOS 回归验收。
    createdAt: 2026-09-22T15:06:33.024Z
  - id: e21
    kind: progress
    content: C（Codex）布局与项目工具已实现并实机验收：顶栏 = ☰ + 项目名（纯文本，用户要求不可点）+ 文件/编辑/视图/项目工具；展开态隐藏官方身份行（实测其真实类为 EXfQ3q_logoRow，且品牌按钮带两个类 EXfQ3q_brand EXfQ3q_wide，所以早先按 class$="_brand" 写的规则永远不命中）；折叠态保留官方 rail（规则带 :not([data-sidebar-collapsed])）；顶栏填充跟随窗口材质（官方 extended titlebar 同规则），且材质开启时把官方 caption row 置透明。项目工具补上 Profile…/重启当前项目/在安全模式中打开/项目恢复…（新增 title/profile/restart/safe-mode/recover/contributions/contribution 动作；main.mjs 传 showProfile/restartProject/toggleSafeMode/recoverProject，安全模式分支照搬原生菜单逻辑）。单测 4 例通过，yarn build 通过。证据：D0/D1/E1 截图。
    basis: observation
    referenceIds:
      - shell-client
      - advanced-frame
      - official-sidebar-slots
    createdAt: 2026-09-22T15:41:17.761Z
  - id: e22
    kind: progress
    content: "踩坑记录（教训）：在注入样式的模板字符串里写 CSS 注释时用了反引号（`*_logoRow`），直接终止了模板字符串，使 * _logoRow 变成模板外的 JS 表达式 —— 渲染进程报 ReferenceError: _logoRow is not defined，slot entry crashed in 'shell.overlay'，表现是顶栏与样式一起消失。定位手段：CDP 只告诉 titlebar=null、paddingTop=0；真正的原因在开发壳 stdout 的 Project renderer: 行（native.mjs 把渲染进程 console.error 转发到主进程）。结论：注入 CSS/模板字符串内禁用反引号；排 UI 缺失时优先读壳日志。"
    basis: observation
    createdAt: 2026-09-22T15:41:17.761Z
  - id: e23
    kind: progress
    content: 已提交并发布 0.1.7：三个提交（fd7b48f 快捷键保底、f6452bf 顶栏菜单、a8786cf 发布）与 tag v0.1.7 均已推送到 origin/master；提交前 yarn check 全绿（107+7+1，EXIT=0）；pin d1e1745 已在 origin/master，其 tree 399ea73 与 lock 逐字一致，repository URL 一致，因此 lock 未动。发布说明 docs/releases/0.1.7.md 为中英双语，已写明已知限制（macOS 未实机回归、插件贡献项未进菜单、包未签名）。
    basis: observation
    referenceIds:
      - shell-client
    createdAt: 2026-09-22T16:22:48.636Z
  - id: e24
    kind: progress
    content: "环境坑（本机特有，值得复用）：git 直连 github.com:443 超时（fatal: Failed to connect），但同一时刻 PowerShell 访问 github.com/api.github.com 返回 200 —— 原因是系统代理（HKCU Internet Settings：ProxyEnable=1, ProxyServer=127.0.0.1:7890）只对部分程序生效。解法：git config http.proxy/https.proxy http://127.0.0.1:7890（已写入壳仓库本地 .git/config），随后 push master 与 push tag 均成功。另外匿名 api.github.com 查 actions/runs 已返回 403（限流），后续查 CI 需带认证。"
    basis: observation
    createdAt: 2026-09-22T16:22:48.636Z
  - id: e25
    kind: progress
    content: 验证现状：c1 已 passed（顶栏「文件」菜单一次点击可达三项 + 最近列表）；c2 仅单测覆盖，端到端（开发壳里 Ctrl+Shift+N/O/W 真实触发）仍未取证；c3（macOS）未实机回归。UI 完成度：四组菜单均已实机看过，但英文文案、暗色主题、窄窗（<1024 自动折叠）三张验收图尚未补。
    basis: observation
    referenceIds:
      - evidence-readme
    createdAt: 2026-09-22T16:22:48.636Z
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
  b4404c425b99c0fdc57b7c2bd94a302aba13c416d59112c640a6143f94b0f94a:
    fingerprint: f70e677e459260015bdd58317a3bbc74b182560b0114faf6099c1fdb491e49f1
    kind: update
    at: 2026-09-22T14:34:49.534Z
    entryIds:
      - e6
      - e7
      - e8
      - e9
  1a1ba0121370d9989bc1f7fd537e71ae2b61aba4d53efe466ae4566e3ee0f8f0:
    fingerprint: 4e1ec930917a9c5f34afeca3d6b4aacd4928dd61cef0bd3e4de5e230cfc24566
    kind: update
    at: 2026-09-22T14:34:57.332Z
    entryIds: []
  7c50d665f49c9472df61330b72df2b9d35505ccf2e950c4032e8b99be75cc35e:
    fingerprint: 5780355ad64d548f3a29fe7fe84bbbcc7e9fd84c6a27784e5ad34aef48d865f3
    kind: update
    at: 2026-09-22T14:42:14.160Z
    entryIds:
      - e10
      - e11
      - e12
  e74178c10da13ab87c1bc84a08103e19843a48b3069ce529869377b12e484d89:
    fingerprint: 55e3b477eccdf1f9d0b83f4c997b3a3488419f04a64bd7877fb313c2c7d61207
    kind: update
    at: 2026-09-22T14:46:54.019Z
    entryIds:
      - e13
      - e14
  f90577461c3ad8a8d25d5035c7713d2165a25c8c6a591f12ce9b8829b5c30af6:
    fingerprint: 58c50e7be28b37ba6de2648c68817c12bd210624b90563a2d7763fbb2f56ef86
    kind: update
    at: 2026-09-22T14:48:00.960Z
    entryIds:
      - e15
      - e16
  5ca1d976f5b37bfc36e3b0be7edddb22a28751a8d3734e49cd381797235240df:
    fingerprint: 346a38a127681b6d6334eff41718ee90db83c9d778fc5578e3ef50ff087f2961
    kind: update
    at: 2026-09-22T15:06:33.024Z
    entryIds:
      - e17
      - e18
      - e19
      - e20
  948359ccb3468a8529f2c6d49da0c8bd9aeb5a7d997cf225c93a502de37f757a:
    fingerprint: 8dbdd68d2cd087b223c08f90e617c843f595c4b466d485d782aef81bcf985ff3
    kind: update
    at: 2026-09-22T15:41:17.761Z
    entryIds:
      - e21
      - e22
  976d646eb32e7c972dc6656c4d201bb1e39a781a62c02e2a76c72dc200304c4d:
    fingerprint: 46e9d3ecea86c3d98a1e5470c9e841b09ecee441900505947db68491fcf862aa
    kind: update
    at: 2026-09-22T16:22:48.636Z
    entryIds:
      - e23
      - e24
      - e25
criterionVersions:
  c1: 3
  c2: 3
  c3: 3
---

0.1.7 已发布。Windows 上项目窗口的原生菜单栏在该窗口形态（titleBarStyle:hidden + titleBarOverlay + autoHideMenuBar）下根本无法显示（实测 isMenuBarVisible() 恒 false、外部 GetMenu(hwnd)==0、Alt/F10/setMenuBarVisibility 全无效），本版在官方 shell.overlay 里自绘一条满宽顶栏：左侧收起按钮 + 项目名（宽度跟随侧栏列宽，过长截断不越界），随后是文件/编辑/视图/项目工具四组菜单（文件组含新建/打开/最近/欢迎/关闭，项目工具含终端/诊断/Profile/重启/安全模式/恢复/检查更新）；顶栏填充跟随窗口材质，展开态隐藏官方身份行且分界线不侵入顶栏，收起态完全保持官方 rail。同时把 Ctrl+Shift+N/O/Ctrl+W 改为窗口级绑定（不再依赖 application menu，为对齐官方 removeMenu 留出空间），macOS 不安装该层。主进程侧在官方 ipc 通道先匹配壳动作再回落官方 dispatcher，官方快照零修改。提交：fd7b48f、f6452bf、a8786cf；tag v0.1.7 已推送，CI 将自动构建并发布（20–25 分钟）。提交前 yarn check 全绿（107+7+1）。仍未完成：c2 快捷键端到端实机取证、c3 macOS 回归、英文/暗色/窄窗验收图。
