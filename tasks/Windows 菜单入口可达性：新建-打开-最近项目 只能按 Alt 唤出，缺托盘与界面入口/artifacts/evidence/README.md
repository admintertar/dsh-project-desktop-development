# Windows 菜单入口可达性 — 实机证据

日期：2026-09-22 · 机器：Windows 10.0.26200（AMD64，200% DPI）· Electron 43.3.0（chrome 150.0.7871.212）
结论来源：本目录 `alt-menu-probe/` 里的一次性探针（非产品代码），窗口选项与产品窗口逐项一致
（`autoHideMenuBar:true` + `titleBarStyle:'hidden'` + `titleBarOverlay{height:40}`，见 `.upstream/.../window-options.ts:143-148`）。

方法：键位用 `user32!keybd_event` 真注入（含左 Alt / 通用 VK_MENU / 纯扫描码 Alt / 右 Alt / F10 / Ctrl 组合），
**每次注入前用 `GetForegroundWindow` 证明目标窗口确为前台**；结论读 Electron 主进程 API，并用外部 Win32
`GetMenu`/`GetClientRect` 与 DPI 正确的 `desktopCapturer` 截图交叉验证。

---

## 一、核心结论

### F1 Windows 产品窗口上，原生菜单栏根本没有位置（不是"默认隐藏"）
- 探针窗口（产品同款选项）：`isMenuBarVisible()` 恒为 `false`；左 Alt、`VK_MENU`(0x12)、纯扫描码 Alt、右 Alt、F10 全部无效；
  `setMenuBarVisibility(true)`、`setAutoHideMenuBar(false)`、`win.setMenu(appMenu)`、窗口建立后再 `Menu.setApplicationMenu()`
  也全部无效；内容区始终 `1099x760`（没有任何"菜单栏占高"）。
- **真实产品窗口**（外部 Win32 查询）：已安装 app 的项目窗口与开发壳欢迎窗口 `GetMenu(hwnd) == 0`（窗口没有 HMENU），
  Alt/F10 后 `GetClientRect` 不变。→ 菜单栏不是被隐藏，而是不存在。
- 正对照：标准系统边框 + `autoHideMenuBar` 的窗口 B，`setMenu` + `setMenuBarVisibility(true)` 后
  `isMenuBarVisible()=true`，内容高 `485 → 459`（**26 DIP 原生菜单栏**），截图可见「文件 / 视图 / 窗口」。
- **修正历史记录**：本任务原先把现状写成"菜单栏默认隐藏、必须按 Alt 唤出"。实机证明该前提不成立 ——
  在 Windows 自绘标题栏窗口上按 Alt 唤不出任何菜单栏。

证据：`alt-menu-probe-run5.log`、`alt-menu-probe-run5-state.json`、`60/61/62-A-product-*.png`、
`63-B-control-menu-bar-window.png`、`devshell-menu-check.log`、`devshell-menu-check.json`、`71-devshell-welcome-after-left-alt.png`

### F2 accelerator 有效，且不依赖菜单栏
菜单栏隐藏（`isMenuBarVisible()=false`）时：`Ctrl+Shift+N → 新建项目`、`Ctrl+O → 打开项目`、`Ctrl+R → reload` 均命中
（计数 `newProject/openProject/reloads` 递增）。真实开发壳欢迎窗口按 `Ctrl+Shift+N` 打开了「新建项目」窗口。
→ 快捷键是今天 Windows 上到达 File 组命令的**唯一**路径。

证据：`alt-menu-probe-run1`/`run3` 日志中的 `A-accel-*` 行；`alt-menu-probe.log`

### F3 `removeMenu()` 之后 accelerator 全灭（对姊妹任务的硬约束）
`win.removeMenu()`（官方 win32 策略）之后，`Ctrl+Shift+N`、`Ctrl+O`、`Ctrl+R` 计数不再变化（稳定停在 `1/1/0/1`）。
→ `task-b8b39b99`（对齐官方 `configureWindow/removeMenu`）一旦落地，Windows 上「新建/打开/关闭项目」
**将没有任何入口**，必须先落地替代入口再拆菜单。

证据：`alt-menu-probe-run1`/`run4` 日志中的 `A-post-removeMenu-*`、`A-reapply-removeMenu-*` 行

### F4 托盘能承载这三个命令，但新图标默认落在 Windows 溢出区
- 用产品托盘图标 + 建议菜单（新建项目…/打开项目…/最近项目▸/欢迎窗口/显示应用/检查更新…/退出）调 `tray.popUpContextMenu()`，
  菜单项完整渲染（截图 `65-tray-proposed-menu.png`）；`tray.getBounds()` 报 DIP `{x:1462,y:1032,w:32,h:48}`。
- 新建一个 32 DIP 的合成品红托盘图标后，通知区域像素差仅 `87 px`（一个 12×20 的小块杂散变化），
  而一个可见图标应产生 64×64 物理像素（≈4096 px）的色块并挤动相邻图标。→ **Windows 把新图标放进了溢出区**；
  已安装 DSH 的鲸鱼图标因为此前被用户置为可见才直接显示。
- 因此托盘路径对"首次使用的机器"是 **2 次点击**（溢出箭头 → 图标），除非用户手动固定图标；
  且左键已绑定 `showApplication`（`main.mjs:395`），命令只能走右键菜单。

证据：`30/31-tray-*.png`、`12-tray-zoom3x.png`、`65-tray-proposed-menu.png`、`alt-menu-probe-run3.log`

### F5 左 Alt 回归在本机可复现（仅标准边框窗口可观察到该现象）
窗口 B 菜单栏可见时，按左 Alt 能把它**隐藏**（`true→false`，内容 `459→485`）；但菜单栏隐藏时按左 Alt
**唤不出**（run2 `B-baseline → B-after-left-Alt` 仍为 `false`）。与 electron#50050 / #50082
（AltGr 修复破坏左 Alt 切换 `autoHideMenuBar`）描述一致；issue 于 2026-03-05 以 duplicate 关闭，本机 43.3.0 仍复现。

### F6 标题栏确实是自绘的（"菜单放哪里"的前提）
- `titleBarStyle:'hidden'` 去掉系统标题栏；`titleBarOverlay` 只由 Electron 在客户区右上角画三个原生窗口按钮
  （透明底、`symbolColor:#7f858f`、高 40 DIP）。
- 窗口顶部那 40 DIP 以及整个客户区都是我们的 React 页面渲染的（欢迎窗口截图 `71-*` 顶部即页面内容，
  自绘标题栏/侧栏 + 右上角原生按钮）。
- 窗口控件安全区用 `env(titlebar-area-x,0px)` / `env(titlebar-area-width,100%)` 避开（Electron 自定义标题栏文档）。
- → 菜单/命令入口可以随时加在自绘标题栏里；原生菜单栏在这个窗口形态下没有位置。

证据：`71-devshell-welcome-baseline.png`、`44-C-menu-bar-visible-window.png`（自绘 40px 条 + 无原生菜单栏）

## 二、由此得到的方案取舍

| 方案 | 可达性 | 代价 / 风险 |
| --- | --- | --- |
| 自绘标题栏内命令按钮/菜单（VS Code/Chrome 风） | 1 次点击打开菜单，新建/打开/最近都在里面；位置天然属于应用 UI | 需前端实现 + 键盘可达性；必须避开 `titlebar-area` 的窗口控件区 |
| 托盘菜单补「新建/打开/最近」 | 已固定图标的机器 1 次右键；首次使用 2 次点击（溢出区，见 F4） | 图标可见性由 Windows 每用户设置决定，应用无法保证；左键语义已被占用 |
| 窗口级快捷键（`webContents.on('before-input-event')`） | 不是"入口"，是保底：保住 `Ctrl+Shift+N/O/W` | 不可发现；但 F3 表明 `removeMenu` 落地前**必须**做 |

原生菜单栏方案已被 F1 排除；F3 说明"先拆菜单再补入口"的顺序会造成 Windows 功能真空。

## 三、本目录文件

探针与驱动（可重跑，均为一次性诊断代码）：
- `alt-menu-probe/main.js` `index*.html` `package.json` — Electron 探针（窗口 A=产品同款、B=标准边框对照、C=产品同款但 `autoHideMenuBar:false`）
- `alt-menu-probe/drive.ps1` — 主矩阵：Alt 各变体 / accelerator / `removeMenu`
- `alt-menu-probe/drive2.ps1` — 菜单栏 oracle + 托盘图标可见性
- `alt-menu-probe/drive3.ps1` — `setMenu` oracle + 品红图标像素差 + 托盘菜单
- `alt-menu-probe/drive4.ps1` — 产品时序（窗口已存在后再 `setApplicationMenu`）
- `alt-menu-probe/drive5.ps1` — 决定性组合（产品选项 `setMenu`+`setMenuBarVisibility(true)`）+ 托盘建议菜单
- `alt-menu-probe/drive-devshell.ps1` — 对真实开发壳/已安装 app 窗口的外部 Win32 检查（`GetMenu`/`GetClientRect`）

证据：`evidence/` 下的 `*.log`（逐行时间线）、`*.json`（结构化的每步快照）、`*.png`（DPI 正确的截图）。

## 四、方法学备注（失败尝试）
- 本机只有 Windows PowerShell 5.1（无 `pwsh`）；它按 ANSI 解码无 BOM 的 `.ps1`，中文注释会破坏语法 → 脚本一律纯 ASCII 或加 BOM。
- `Start-Process electron.exe "<含空格路径>"` 不加引号会静默 `exit 1`。
- Windows 11 的任务栏/托盘菜单不是 `#32768` 类，用 `FindWindow('#32768')` 判定"菜单是否打开"不可靠 → 改用截图判定。
- 驱动期间有第三方应用（uTools 等）抢前台，个别注入无效（如真实壳的 `Ctrl+O` 测试）；此类结果已剔除，
  保留的结论都带前台证明。
- Electron 43 的 `BrowserWindow` 没有 `getMenu()`（有 `setMenu()`）；探针里第一次调用因此抛错，但 `setMenu` 已生效。
