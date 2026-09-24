---
schemaVersion: 3
directory: Windows「在文件资源管理器中显示」无反应：revealNativePath 传 file--- URL 给 exp
id: task-87d332c9-408f-4a98-8122-228a5feececa
title: Windows「在文件资源管理器中显示」无反应：reveal 经 execFile(windowsHide:true) 启动 explorer 导致窗口被隐藏
objective: 定位并记录「Windows 上交付文件的『在文件资源管理器中显示』点击无反应」的根因：命令级证据表明根因是 native 命令统一使用 execFile(windowsHide:true)，而 explorer.exe 是唯一“被启动进程本身即窗口进程”的场景，导致新窗口被隐藏；同时核查官方新版本是否修复（结论：0.1.5-rc.2 至最新 master/0.1.7-rc.1 均未修），给出影响面与最小修复方向。
status: completed
createdAt: 2026-09-23T15:05:26.670Z
updatedAt: 2026-09-23T15:28:27.518Z
artifacts: []
archived: false
phase: validation
brief:
  currentBehavior: Windows 上交付文件（present 的文件）右键菜单「在文件资源管理器中显示」点击后无任何可见效果；同一菜单的「用默认应用打开」正常。客户端仍显示成功文案（已请求在文件资源管理器中显示），因此用户看到的是“点了没反应”而非错误提示。
  scope: 定位交付文件在 Windows 上“在文件资源管理器中显示”无反应的根因，给出证据链、影响面与最小修复方向，供上游修复或后续适配。
  constraints:
    - 官方 Harness 源码快照只读，不在本仓库修改官方实现
    - 本地验证不得依赖用户手动点击（需可重跑的客观证据）
  outOfScope:
    - 不在本项目仓库内修改官方 Harness 包
    - 不处理 macOS/Linux 对应路径
  acceptanceCriteria:
    - id: R1
      text: 给出 Windows 上 reveal 失败的命令级根因（含代码位置与错误处理路径）
      required: true
      version: 2
    - id: R2
      text: 给出 A/B 对照证据证明 file:// URL 不开窗、真实路径开窗
      required: true
      version: 2
    - id: R3
      text: 给出最小修复方案与影响面（哪些功能受影响、哪些正常）
      required: true
      version: 2
handoff:
  nextSteps:
    - reevaluate-reveal-adapter-after-pin-upgrade
  verifyBefore:
    - yarn-check
    - probe-reveal-adapter
references: []
entries:
  - id: r1
    kind: progress
    content: 调用链：交付文件卡（Harness 的 dsh-client-ui-deliverables）在 action=reveal 时向 Host 发 HTTP 请求（lib/client.js:155 的 `${url}&action=reveal`），Host 侧由 @deepseek-ai/dsh-api-session-controller/lib/index.js:2890 调 `this.revealPath(request.path)`，默认实现在 `@deepseek-ai/dsh-native-command` 的 revealNativePath。与桌面壳的 native runtime 能力无关（不需要壳提供 reveal 能力）。
    basis: observation
    createdAt: 2026-09-23T15:05:26.670Z
  - id: r2
    kind: decision
    content: 根因：dsh-native-command/lib/index.js:228-230 在 Windows 上把路径转成 file:// URL 再交给 explorer：`pathToFileURL(windowsPath, {windows:true}).href` 然后 `run("explorer.exe", ["/select,", target])`；实测捕获到的命令为 `explorer.exe /select, file:///D:/.../DSH-Project-Desktop-0.1.8-win-x64-Setup.exe`。而同模块的 openWindowsPath（第 112-118 行）用的是真实路径经 powershell `Invoke-Item -LiteralPath`，因此「用默认应用打开」正常。
    basis: observation
    createdAt: 2026-09-23T15:05:26.670Z
  - id: r3
    kind: progress
    content: 失败被静默：revealNativePath 第 231-234 行显式忽略 explorer 的 exit code 1（注释：Explorer exit 1 is accepted as a delegated handoff），而 explorer 对 file:// URL 正是返回 1 且不开窗；因此 Host 不报错、客户端显示“已请求在文件资源管理器中显示”，用户感知为点击无反应。
    basis: observation
    createdAt: 2026-09-23T15:05:26.670Z
  - id: r4
    kind: verification
    content: A/B 对照（Windows x64，用 Shell.Application COM 枚举 + Win32 IsWindowVisible 判定）：传 file:// URL 执行后无任何新增窗口（含不可见）；传反斜杠真实路径 `explorer.exe /select, D:\\...\\Setup.exe` 后新增 1 个 visible=True 的资源管理器窗口，定位到安装包所在 release 目录。两侧退出码均为 1，即 exit code 无法区分成败。
    basis: observation
    verification:
      criterionId: R2
      criterionVersion: 1
      method: 捕获命令 + explorer.exe A/B 对照 + COM/Win32 窗口状态枚举
      result: passed
      coverage: URL 形式与路径形式的可见窗口差异已客观验证
    createdAt: 2026-09-23T15:05:26.670Z
  - id: r5
    kind: decision
    content: 最小修复：把 revealNativePath 的 Windows 分支改为向 explorer 传真实路径（保留现有 `/select,` + 路径的参数形式即可，已实测开窗），不再转 file:// URL；同时建议调用方不要把 exit code 1 当作成功，否则失败仍无法反馈给用户。影响面仅限 Windows 的「在 Finder/资源管理器中显示」，不影响「用默认应用打开」（走 powershell Invoke-Item）。
    basis: agent-proposal
    createdAt: 2026-09-23T15:05:26.670Z
  - id: r6
    kind: decision
    content: 更正上一轮结论（supersedes r2）：根因不是 file:// URL。4 组正交实验（同一环境、同一 Node execFile 调用方式、各自独立新目录、COM 枚举 + IsWindowVisible 判定）结果：uri+hide → 窗口 1/可见 0；path+hide → 窗口 1/可见 0；uri+show → 窗口 1/可见 1；path+show → 窗口 1/可见 1。可见性只跟随 windowsHide，与 URL/路径无关。
    basis: observation
    supersedes: r2
    createdAt: 2026-09-23T15:10:51.944Z
  - id: r7
    kind: progress
    content: 真正的根因：dsh-native-command 的 runNativeCommand 对所有 native 命令统一 `execFile(command, args, {encoding:'utf8', signal, windowsHide:true})`；而 reveal 是唯一“被启动的进程本身就是窗口进程（explorer.exe）”的场景，windowsHide 使新窗口以隐藏方式创建。这也解释了实测基线里累积的 5 个 visible=False 窗口——用户每次点击都新增一个隐藏窗口。openWindowsPath（“用默认应用打开”）正常，是因为它启动的是 powershell.exe（控制台进程，隐藏无害），再由 Invoke-Item 让别的进程开窗。
    basis: observation
    createdAt: 2026-09-23T15:10:51.944Z
  - id: r8
    kind: progress
    content: 官方新版本核查（本地官方 monorepo checkout resources/deepseek-harness-source，源码在 packages/util/native-command/src/）：0.1.5-rc.2（本项目 pin）用 pathToFileURL + execFile(windowsHide:true)；0.1.6-alpha.2（本地 HEAD）完全相同；0.1.7-rc.1（远端最新 tag，亦为 master HEAD）runner.ts 仍为 windowsHide:true，path-opener.ts 仅重构出 runExplorer 包装（仍走同一 runner）并新增非 ASCII 转义解码（explorerTarget）。三者均未修复。
    basis: observation
    createdAt: 2026-09-23T15:10:51.944Z
  - id: r9
    kind: decision
    content: 修复方向更正（supersedes r5）：不需要也不需要改 URL/路径形式（两种在可见性上都成立）；只需让 reveal 不再隐藏窗口——壳层覆盖 sessionController.revealPath，用 windowsHide:false 执行 explorer（explorer 不产生控制台窗口，不存在闪黑框问题）；更正统的变体是让 Host 经 RPC 请主进程调 Electron 的 shell.showItemInFolder。另据官方代码注释（为逗号转义、非 ASCII 解码、容忍 exit 1 做过专门处理）判断其本意就是要让这个功能可用，因此适合反馈上游。
    basis: agent-proposal
    supersedes: r5
    createdAt: 2026-09-23T15:10:51.944Z
  - id: r10
    kind: scope
    content: objective 与标题更正：原“revealNativePath 传 file:// URL 给 explorer /select”不再是根因描述；改为“reveal 经 execFile(..., {windowsHide:true}) 启动 explorer.exe，使新建的资源管理器窗口被隐藏”。引用 r6/r7 的实验与代码证据；r2/r5 已被 supersedes。
    basis: agent-proposal
    reason: 根因被更严谨的正交实验推翻，若保留旧描述会误导后续修复方向（会去改 URL 形式而无效）。
    createdAt: 2026-09-23T15:10:59.906Z
  - id: r11
    kind: progress
    content: 已实施修复：新增 src/desktop-adapter/stable/windows-reveal.mjs（explorerTarget 保留官方 URI 目标与逗号转义、createWindowsRevealPath 用 windowsHide:false、installRevealAdapter 做字段校验与带标记替换），并在自有 Host 插件 src/desktop-adapter/stable/shell-host.mjs 里通过 ctx.inject(['sessionController']) 只替换 revealPath 这一个方法；非 Windows 保留官方实现，字段缺失时明确报错，适配安装情况记入启动追踪。提交 64f7dd5（worktree）→ 主树 cherry-pick c9b3222；另新增 tests/windows-reveal.test.mjs 与 yarn probe:reveal-adapter，并记入 docs/architecture.md 的官方内部接入清单。
    basis: agent-proposal
    createdAt: 2026-09-23T15:14:41.680Z
  - id: r12
    kind: verification
    content: 修复验证（三层）：(1) tests/windows-reveal.test.mjs 6/6（URI 目标与逗号转义、windowsHide:false、exit 1 容忍与其它错误拒绝、替换后保留 signal、非 Windows 不动官方实现、字段缺失时上报）；(2) yarn check EXIT=0（含全部单测与 smoke:host）；(3) yarn probe:reveal-adapter 在真实 Host 进程里断言适配已安装并通过，追踪文件里出现“windows reveal adapter — installed”。
    basis: observation
    verification:
      criterionId: R3
      criterionVersion: 2
      method: 单测 + 真实 Host 探针 + yarn check
      result: passed
      coverage: 适配逻辑、接线生效、构建与冒烟均通过
    createdAt: 2026-09-23T15:14:41.680Z
  - id: r13
    kind: verification
    content: R1（命令级根因，criterionVersion 2）：@deepseek-ai/dsh-native-command 的 runNativeCommand 对所有 native 命令用 `execFile(command, args, {encoding:'utf8', signal, windowsHide:true})`（源码 packages/util/native-command/src/runner.ts），而 reveal 是唯一“被启动进程本身即窗口进程（explorer.exe）”的场景；客户端仍显示“已请求在文件资源管理器中显示”，故用户看到无任何反馈。代码位置：api-session-controller/lib/index.js:2890 调 revealPath，默认实现 native-command/lib/index.js:208。
    basis: observation
    verification:
      criterionId: R1
      criterionVersion: 2
      method: 阅读调用链源码 + 捕获实际命令 + 与官方 runner 选项对照
      result: passed
      coverage: 命令级根因已定位到具体函数与选项，并解释了无反馈的静默路径
    createdAt: 2026-09-23T15:28:27.518Z
  - id: r14
    kind: verification
    content: R2（对照证据，criterionVersion 2）：R2 的原始措辞（“file:// URL 不开窗、真实路径开窗”）已被 r6 推翻——4 组正交实验（同一 Node execFile 调用方式、各自独立新目录、COM 枚举 + Win32 IsWindowVisible）结果为 uri+hide→可见 0、path+hide→可见 0、uri+show→可见 1、path+show→可见 1，可见性只跟随 windowsHide，与 URL/路径无关；基线里累积的 5 个 visible=False 窗口即为每次点击留下的隐藏窗口。
    basis: observation
    verification:
      criterionId: R2
      criterionVersion: 2
      method: 4 组正交实验 + Shell COM 枚举 + Win32 IsWindowVisible
      result: passed
      coverage: 用正交实验替代原单一 A/B，排除了实验装置本身的干扰
    createdAt: 2026-09-23T15:28:27.518Z
  - id: r15
    kind: progress
    content: 修复已进入仓库：worktree 提交 64f7dd5 → 主树 cherry-pick c9b3222（已 push），随 0.1.9 覆盖重发构建（Package Desktop run 35880579416）。后续：pin 升级到含上游修复的 Harness 后，需复查 windows-reveal 适配可否移除（上游至 master 仍未修）。
    basis: observation
    createdAt: 2026-09-23T15:28:27.518Z
  - id: r16
    kind: completion
    content: 闭环：根因已定位并更正过一次误判，修复已实现、验证（单测 6/6 + 真实 Host 探针 + yarn check）并推送，随 0.1.9 覆盖重发发布。
    basis: agent-proposal
    verificationEntryIds:
      - r13
      - r14
      - r12
    createdAt: 2026-09-23T15:28:27.518Z
operations:
  9bc2cbc24152d5b02c3c46bf8ebfd7c7eb1f47bdd204d17e545a538dc11cba96:
    fingerprint: 23cb490cefe792c605875a310451a00116ee91856b617031936c20318ab7f1c9
    kind: create
    at: 2026-09-23T15:05:26.670Z
    entryIds:
      - r1
      - r2
      - r3
      - r4
      - r5
  fa956e1b9cd0f4d44d32f90943c545328978df53d1198b8bad9fb607e4bab65f:
    fingerprint: 8b86b5093ca1bc419e0c725ad11f239659332ea20d485f8cb3d79906e5e5bca4
    kind: update
    at: 2026-09-23T15:10:51.944Z
    entryIds:
      - r6
      - r7
      - r8
      - r9
  69e28bfa3c18da4432f7099c0f5fc9847984132dcb9ffa4716b95cb654f0e47c:
    fingerprint: abe8035d64b8b2e865508bec1cd764ac458ee6c13ccd6ea8f841b9afdfd99c05
    kind: update
    at: 2026-09-23T15:10:59.906Z
    entryIds:
      - r10
  bc2fa20819c432971f4fe8430427b6c500558ed70b71c76e43df1f55a45b7416:
    fingerprint: 360249f85dcab3619dc5f054fda0c552168920e86071588fc4d0efca8453c316
    kind: update
    at: 2026-09-23T15:14:41.680Z
    entryIds:
      - r11
      - r12
  c3ee5c53dd95a8178f05c3b2361a3568b904c7a313ffbd5c5442416181f92360:
    fingerprint: a0fe6a5fcf3df8fab5649ca54be63267515a2bc5b496d5d9b1bcb5034e006434
    kind: update
    at: 2026-09-23T15:28:27.518Z
    entryIds:
      - r13
      - r14
      - r15
      - r16
criterionVersions:
  R1: 2
  R2: 2
  R3: 2
---

根因（已更正过一次）：不是 file:// URL，而是官方 runner 对所有 native 命令统一用 execFile(..., {windowsHide:true})，而 reveal 是唯一“被启动进程本身就是窗口进程（explorer.exe）”的场景，新窗口被隐藏（exit code 1 又被容忍，失败完全静默）。官方从 pin 的 0.1.5-rc.2 到最新 master/0.1.7-rc.1 均未修。修复：在自有 Host 插件里覆盖 sessionController.revealPath，改用 windowsHide:false（保留官方 URI 目标与逗号转义、exit 1 容忍；非 Windows 不动）。提交 c9b3222 已推送，随 0.1.9 覆盖重发发布；验证：单测 6/6、真实 Host 探针 PASS、yarn check EXIT=0。
