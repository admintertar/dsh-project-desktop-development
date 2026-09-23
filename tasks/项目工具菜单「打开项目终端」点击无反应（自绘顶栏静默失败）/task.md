---
schemaVersion: 3
directory: 项目工具菜单「打开项目终端」点击无反应（自绘顶栏静默失败）
id: task-e79ad05b-9469-4378-a028-9b17050919c8
title: 项目工具菜单「打开项目终端」点击无反应（自绘顶栏静默失败）
objective: 定位并修复「项目工具 → 打开项目终端」点击无任何反馈的缺陷：把 Shell 自有的 terminal runtime 调用补齐官方 DesktopTerminalOptions 契约（spawn/onLaunchError），让失败可见，并为菜单动作补上机械护栏（契约测试 + 原生菜单冒烟）。
status: completed
createdAt: 2026-09-23T12:30:58.645Z
updatedAt: 2026-09-23T12:46:23.157Z
artifacts:
  - type: file
    path: artifacts/report.md
    description: 定位、修复与验证报告（含仍未做项）
  - type: file
    path: artifacts/terminal-launch-proof.txt
    description: 端到端点击验收记录：命令、步骤、前后进程差异
  - type: file
    path: artifacts/terminal-processes-before.txt
    description: 点击前控制台进程快照
  - type: file
    path: artifacts/terminal-processes-after.txt
    description: 点击后控制台进程快照（新增 WindowsTerminal 19904「DSH Desktop」）
  - type: file
    path: artifacts/project-tools-menu.png
    description: 自绘标题栏「项目工具」菜单打开时的截图
  - type: file
    path: artifacts/after-click.json
    description: 「项目工具」菜单项列表与点击后无错误对话框
  - type: file
    path: artifacts/edit-menu-zh.png
    description: 自绘标题栏「编辑」菜单截图（6 项均带快捷键列）
  - type: file
    path: artifacts/edit-menu-zh.json
    description: 「编辑」菜单项与快捷键文本（DOM 读取）
archived: false
phase: implementation
brief:
  currentBehavior: "Windows 上项目窗口的菜单栏是 Shell 自绘顶栏（原生菜单栏不可达）：项目工具 → 打开项目终端走 renderer bridge 的官方字符串动作 'terminal'。Shell 自己的 runtime.openTerminal() 调用官方 openDesktopTerminal 时漏传了官方契约里必需的 spawn（以及可选的 onLaunchError），官方实现在启动进程处直接调用 options.spawn(...)，因此必然抛 TypeError: options.spawn is not a function。该同步抛错被官方 dispatcher 与自绘菜单的 run() 吞掉（只 console.error），UI 完全无反馈，用户看到的就是「点击没有反应」。自绘顶栏的「编辑」「视图」菜单从引入起（f6452bf）就没有 shortcut 字段，只有「文件」菜单有 3 条快捷键文本。"
  scope: 补 Shell → 官方 openDesktopTerminal 的契约（spawn + onLaunchError + 失败可见弹窗），同一处修复覆盖 native.mjs 与 stable/project-native-windows.mjs 两条路径；为自绘顶栏菜单补上与 Electron role 一致的快捷键文本；补契约级回归测试与原生菜单冒烟检查。
  outOfScope:
    - 为自绘菜单新增官方 role 里有而 Shell 未列出的项（pasteAndMatchStyle/delete/forceReload）
    - 重写官方 desktop-terminal 实现或修改 .upstream 只读快照
    - 发布、bump pin、push
  acceptanceCriteria:
    - id: C1
      text: Shell 传给官方 openDesktopTerminal 的参数满足官方契约：spawn 为函数、onLaunchError 为函数，且用真实官方模块 + 假 spawn 调用不再抛错
      required: true
      version: 1
    - id: C2
      text: 终端启动失败（同步抛错与异步 onLaunchError）都经官方同款错误弹窗呈现，不再静默
      required: true
      version: 1
    - id: C3
      text: 契约回归测试进入 tests/ 并由 yarn test 执行：缺 spawn 的写法必须被测试判为失败
      required: true
      version: 1
    - id: C4
      text: 原生冒烟在真实项目窗口里打开「项目工具」菜单并断言菜单项与快捷键文本（Windows/Linux 生效，darwin 跳过）
      required: true
      version: 1
    - id: C5
      text: yarn check 通过（verify:upstream + build + test + recovery + safe-mode + check-project-files + smoke:host）
      required: true
      version: 1
handoff:
  nextSteps:
    - 视图菜单：为 reload/zoom 装窗口级绑定（参考 src/app/window-accelerators.mjs），然后才能打印 Ctrl+R / Ctrl+0 / Ctrl+= / Ctrl+-；F11 与 Ctrl+Shift+I 实测已生效，可直接打印
    - 考虑把 smoke:native 纳入 Windows CI（当前 CI 只跑 yarn check 与 smoke:updates，原生菜单/终端回归只能手工跑）
    - 把契约测试的做法推广到其它自有 runtime 对官方对象的替换点（官方字段漏传通常静默失效）
  readBefore:
    - report
  verifyBefore:
    - yarn check
    - yarn smoke:native
references:
  - id: report
    label: 定位、修复与验证报告
    type: file
    path: artifacts/report.md
entries:
  - id: e1
    kind: progress
    content: "用探针 .runtime/terminal-probe/probe.mjs 复刻 native.mjs 的调用参数：case A（现状，无 spawn）抛 TypeError: options.spawn is not a function；case B（同参数 + 注入 spawn）成功走到 spawn，命令行 cmd.exe /D /S /C launch.cmd、cwd=<stateDir>、windowsHide=true。"
    basis: observation
    createdAt: 2026-09-23T12:30:58.645Z
  - id: e2
    kind: progress
    content: 官方 electron-runtime.ts:363-390 的 openTerminal 把调用包在 try/catch 并传 spawn(node:child_process) 与 onLaunchError → reportTerminalLaunchError（logError + desktopNativeCopy 错误弹窗）。我们的 native.mjs:101-108 与 stable/project-native-windows.mjs:57 两处都缺这两个字段，且没有任何错误呈现。
    basis: observation
    createdAt: 2026-09-23T12:30:58.645Z
  - id: e3
    kind: progress
    content: 自绘顶栏菜单快捷键现状：FILE 有 Ctrl+Shift+N / Ctrl+O / Ctrl+W；EDIT 与 VIEW 从 f6452bf 引入起就没有 shortcut 字段（git show f6452bf 证实，不是后来丢失）。Electron 43.3.0 在 win32 上 role 的默认 accelerator 由探针 .runtime/terminal-probe/roles.cjs 读出：undo=CommandOrControl+Z、redo=Control+Y、cut/copy/paste=CommandOrControl+X/C/V、selectAll=CommandOrControl+A、reload=CmdOrCtrl+R、forceReload=Shift+CmdOrCtrl+R、toggleDevTools=Ctrl+Shift+I、resetZoom=CommandOrControl+0、zoomIn=CommandOrControl+Plus、zoomOut=CommandOrControl+-、togglefullscreen=F11。
    basis: observation
    createdAt: 2026-09-23T12:30:58.645Z
  - id: e4
    kind: progress
    content: 新增 src/desktop-adapter/terminal-launch.mjs：把官方 DesktopTerminalOptions 一次凑齐（spawn 默认 node:child_process.spawn、onLaunchError）并把同步抛错与异步启动失败统一交给调用方的 reporter；native.mjs 与 stable/project-native-windows.mjs 两处 openTerminal 改为使用它，失败走官方 desktopNativeCopy + showDesktopMessageBox 错误弹窗，不再静默。
    basis: agent-proposal
    createdAt: 2026-09-23T12:33:22.243Z
  - id: e5
    kind: progress
    content: 新增 tests/terminal-launch.test.mjs（4 项）：① 官方实现缺 spawn 必抛 TypeError（回归护栏，防倒退回静默失败）；② 完整参数下 spawn 被调用一次且 win32 命令行/参数/生成文件正确；③ 同步抛错与 child error 都进入 reportFailure；④ dsh-cli.js 与 pnpm.mjs 路径在固定 runtime 内存在。yarn test 共 129 项全通过。
    basis: agent-proposal
    createdAt: 2026-09-23T12:33:22.243Z
  - id: e6
    kind: progress
    content: 自绘顶栏「编辑」菜单补上与 Electron win32 role 默认一致的快捷键文本（Ctrl+Z / Ctrl+Y / Ctrl+X / Ctrl+C / Ctrl+V / Ctrl+A）；新增 scripts/native-titlebar-checks.mjs 并在 native-smoke 里接入：在真实项目窗口打开「项目工具」与「编辑」菜单、断言菜单项与快捷键文本、断言 Escape 关闭，并用 sendInputEvent 验证 Ctrl+A 真能到达焦点输入框（避免打印不生效的假快捷键）。
    basis: agent-proposal
    createdAt: 2026-09-23T12:33:22.243Z
  - id: e7
    kind: progress
    content: 原生冒烟（smoke:native）在 Windows 上原本第一步就挂：native-guide-checks.mjs 靠 item.accelerator === 'CmdOrCtrl+Shift+N' 找「新建项目」，而 f6452bf 后 Windows 端 File 菜单故意不注册 accelerator（改由 window-accelerators.mjs 装窗口级绑定），所以这个检查在 Windows 上自那时起就不可能通过——任何菜单/终端回归都测不到。已改为 accelerator 优先、label 回退匹配。
    basis: observation
    createdAt: 2026-09-23T12:39:28.859Z
  - id: e8
    kind: progress
    content: 修好后 smoke:native 完整通过（EXIT=0），新增的 titlebar-menu-entries-and-edit-accelerators 进入 result.checks；Ctrl+A 通过 sendInputEvent 真实到达焦点输入框（selection 0..5）。
    basis: observation
    createdAt: 2026-09-23T12:39:28.859Z
  - id: e9
    kind: progress
    content: 真实点击验收（开发壳 + --remote-debugging-port=9333 + 隔离 userData，CDP 点击自绘菜单）：点击前无 WindowsTerminal 进程；点击「打开项目终端」后出现 WindowsTerminal 窗口标题 'DSH Desktop'（start "DSH Desktop" /D <profileDir> pwsh −NoExit 生成的交互终端），且 after-click.json 显示没有错误对话框窗口。
    basis: observation
    createdAt: 2026-09-23T12:39:28.859Z
  - id: e10
    kind: progress
    content: 视图菜单快捷键实测（同一真实项目窗口，sendInputEvent）：F11 → isFullScreen true（生效）；Ctrl+Shift+I → devtools true（生效）；Ctrl+= 两次后 zoom level 仍为 0（不生效）；Ctrl+R → did-finish-load 计数 0（不生效）。因此暂不给「视图」菜单打印 Ctrl+R / Ctrl+0 / Ctrl+= / Ctrl+- 文本，否则是假承诺；要打印必须先像 window-accelerators.mjs 那样给这些命令装窗口级绑定（F11/Ctrl+Shift+I 可直接打印）。
    basis: observation
    createdAt: 2026-09-23T12:39:28.859Z
  - id: v1
    kind: verification
    content: C1 通过：tests/terminal-launch.test.mjs 4/4（官方实现缺 spawn 必抛 TypeError；完整参数下 spawn 被调用一次且 win32 命令行 cmd.exe /D /S /C launch.cmd、welcome/launch 文件生成；dsh-cli.js 与 pnpm.mjs 路径存在），另有独立探针复现 A/B 对照。
    basis: observation
    verification:
      criterionId: C1
      criterionVersion: 1
      method: node --test tests/terminal-launch.test.mjs（yarn test 内 129/129）
      result: passed
      coverage: 真实固定 runtime 模块 + 假 spawn；darwin/win32 均适用，linux 自动跳过
    createdAt: 2026-09-23T12:46:23.157Z
  - id: v2
    kind: verification
    content: C2 通过：openTerminal 的同步抛错与异步 onLaunchError 统一进入 reportFailure，壳侧用官方 desktopNativeCopy 文案 + 官方 showDesktopMessageBox 弹错误框（native.mjs 与 stable/project-native-windows.mjs 两处）；单测断言两类失败都被上报。
    basis: observation
    verification:
      criterionId: C2
      criterionVersion: 1
      method: 代码对比官方 electron-runtime.ts:363-390 + 单测
      result: passed
      coverage: 上报链路有单测覆盖；未制造真实启动失败去截错误弹窗图（弹窗为官方组件、与官方 reportTerminalLaunchError 同款）
    createdAt: 2026-09-23T12:46:23.157Z
  - id: v3
    kind: verification
    content: C3 通过：tests/terminal-launch.test.mjs 的第一项就是「官方实现缺 spawn 必抛 TypeError」，且 129 项全绿；该测试随 yarn test 由 CI 的 yarn check 执行。
    basis: observation
    verification:
      criterionId: C3
      criterionVersion: 1
      method: yarn test
      result: passed
      coverage: tests/terminal-launch.test.mjs 已进入 tests/*.test.mjs 模式（yarn test），CI package.yml 在 windows-2022/macOS 上跑 yarn check
    createdAt: 2026-09-23T12:46:23.157Z
  - id: v4
    kind: verification
    content: C4 通过：scripts/native-titlebar-checks.mjs 在真实项目窗口打开「项目工具」与「编辑」菜单，断言菜单项、快捷键文本、Escape 关闭，并用 sendInputEvent 验证 Ctrl+A 真到达焦点输入框（selection 0..5）；已接入 native-smoke，且同一轮断言切换语言后标题栏改为 Project Tools。
    basis: observation
    verification:
      criterionId: C4
      criterionVersion: 1
      method: yarn smoke:native（本轮共跑 5 次，末次 EXIT=0）
      result: passed
      coverage: Windows 实机 Electron 43.3.0；darwin 平台整段跳过（自绘标题栏不在 macOS 注册）
    createdAt: 2026-09-23T12:46:23.157Z
  - id: v5
    kind: verification
    content: C5 通过：最终代码状态下 yarn check 退出码 0（verify:upstream + build + test + recovery + safe-mode + check-project-files + smoke:host）。
    basis: observation
    verification:
      criterionId: C5
      criterionVersion: 1
      method: yarn check（.runtime/logs/yarn-check-2.log）
      result: passed
      coverage: 本地 Windows 实机；未涉及发布/打包
    createdAt: 2026-09-23T12:46:23.157Z
  - id: v6
    kind: verification
    content: 端到端验收：隔离开发壳 + CDP 点击自绘菜单「打开项目终端」，点击前控制台进程快照无 DSH 终端，点击后新增 WindowsTerminal 19904（窗口标题 DSH Desktop）且无错误对话框；验收后终端与开发壳均已关闭（调试端口 9333 已关闭）。
    basis: observation
    verification:
      criterionId: C1
      criterionVersion: 1
      method: CDP 点击 + Get-Process 前后快照
      result: passed
      coverage: 真实 Electron 43.3.0 / Windows 11 实机；用进程增量而非“存在终端进程”作判据
    createdAt: 2026-09-23T12:46:23.157Z
  - id: c1
    kind: completion
    content: 完成：终端的静默失败已修复并有机械护栏；自绘标题栏已接入官方 i18n（语言跟随）并补上编辑菜单快捷键；附带修好了 Windows 上跑不起来的 native-guide 断言。
    basis: agent-proposal
    verificationEntryIds:
      - v1
      - v2
      - v3
      - v4
      - v5
      - v6
    createdAt: 2026-09-23T12:46:23.157Z
operations:
  2baef8020fab752b23bdec3c0155dac700c63682b449c876d6ec6d89ccf11f49:
    fingerprint: 2327e3e6fcb4a1ac36a67019e7d92c5a100ba525f9c55a815c02caafe9e05d18
    kind: create
    at: 2026-09-23T12:30:58.645Z
    entryIds:
      - e1
      - e2
      - e3
  3c4a33d2f44b123ad86f49540db1ec61a61400cdb0809981a258cbc6a9127347:
    fingerprint: 1c0b3a2983f193e010b676d88fb1af5fda62879b41833096a176d128a95fad1d
    kind: update
    at: 2026-09-23T12:33:22.243Z
    entryIds:
      - e4
      - e5
      - e6
  32293417289079b666ce50d20e177129075266ad5a9a7b85582d8931f36541ba:
    fingerprint: 024db685ad2f7083c19dd18a94a85bf808528bd0f115ed5a81ec88525d5a6a6a
    kind: update
    at: 2026-09-23T12:39:28.859Z
    entryIds:
      - e7
      - e8
      - e9
      - e10
  bc27a8c12ba56a3e697c3f363556e6ea011b95969f52f6f697534a4028caf780:
    fingerprint: 67eea9e462d48cabd5234e0aeef04e38fd7f7b8d695c23ac85eb5e1963c1e3d3
    kind: update
    at: 2026-09-23T12:46:23.157Z
    entryIds:
      - v1
      - v2
      - v3
      - v4
      - v5
      - v6
      - c1
criterionVersions:
  C1: 1
  C2: 1
  C3: 1
  C4: 1
  C5: 1
---

「项目工具 → 打开项目终端」无反应的根因是壳自有 runtime 漏传官方 DesktopTerminalOptions 必需的 spawn（以及 onLaunchError），官方生成器必然抛 TypeError，而官方 dispatcher、自绘菜单、壳 runtime 三层都没把它呈现给用户。新增 src/desktop-adapter/terminal-launch.mjs 一处凑齐契约并把同步/异步失败统一交给官方错误弹窗，native.mjs 与恢复窗口两处路径都改用它；补 tests/terminal-launch.test.mjs 契约回归（含“缺 spawn 必抛错”）与 scripts/native-titlebar-checks.mjs 原生菜单冒烟（菜单项、快捷键文本、Ctrl+A 键盘真实性）。顺带修好：Windows 上 native-guide 断言用 accelerator 找菜单导致 smoke:native 自 f6452bf 起第一步必挂；自绘标题栏读 <html lang> 导致切语言不跟随（已改用官方 locale 服务）；编辑菜单补上 Electron role 默认快捷键文本。实测视图菜单 Ctrl+R / Ctrl+±/0 在 Windows 项目窗口不生效，故未打印其快捷键。限制：错误弹窗链路只有单测覆盖，未制造真实失败截图；视图快捷键与 smoke:native 进 CI 仍未做。
