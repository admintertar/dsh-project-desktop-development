---
schemaVersion: 3
directory: 更新下载阶段欢迎窗口按钮文案错误，且下载无进度反馈
id: task-dea263a0-949d-4493-856c-67159d4171db
title: 更新下载阶段欢迎窗口按钮文案错误，且下载无进度反馈
objective: 定位并记录「更新进入下载阶段后，欢迎窗口按钮仍显示『正在检查更新…』」的缺陷证据链；同时确认官方下载实现无进度回调这一边界，并给出「下载进度可见」的可行设计方案（数据源、通道、UI 位置、验证方式），供后续排期实现。
status: completed
createdAt: 2026-09-20T13:36:45.619Z
updatedAt: 2026-09-20T18:37:44.915Z
artifacts:
  - type: file
    path: artifacts/updates-welcome-downloading.png
    description: 中文 + 暗色 + 420px 窄窗口：下载中按钮显示「正在下载 0%」
  - type: file
    path: artifacts/updates-welcome-downloading-en-light.png
    description: 英文 + 浅色：下载中按钮显示「Downloading 0%」
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: 945734e39519d7f1bb9bd65e27bb2f8d54b645ed
    description: 下载阶段 phase 与进度：按钮文案、feed onProgress、guide state、测试与验收
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: 7aa6af947338250a7a5632deb8f494f9934a5190
    description: 菜单保持官方文案、新增 progressChanged 使进度不再重建原生菜单（用户验证后的范围收敛）
archived: false
phase: validation
brief:
  currentBehavior: 打包版手动/后台检查到 stable 新版本后，官方生命周期进入下载阶段（托盘/应用菜单文案已变为「正在下载 DSH Project Desktop <version>…」），但欢迎窗口右下角的更新按钮仍然显示「正在检查更新…」，直到整个下载与安装交接结束才恢复。下载期间窗口内没有任何进度信息。
  scope: 定位欢迎窗口更新按钮文案错误的根因与数据流，评估在适配层补齐下载进度的可行性，并给出修复方向与验证方式。
  constraints:
    - 本轮只做调查与设计，不修改产品代码
    - 不修改官方 upstream 源码或 bundle；适配只能落在 src/desktop-adapter/stable/ 与 shell 窗口层
    - 不引入 Electron download manager 取代官方 downloadDesktopUpdate（会丢失 SHA-256 校验、临时文件原子替换与清理语义）
    - 进度上报不得绕过官方 feed 的完整性与大小校验
  outOfScope:
    - 实现修复（本轮只记录与设计）
    - 官方 upstream 源码改动
    - 发布与打包流程变更
    - beta 通道 installStable 路径
  acceptanceCriteria:
    - id: ac1
      text: 缺陷证据链：逐处记录「下载阶段按钮仍显示正在检查更新」涉及的代码位置、状态字段与数据流，并解释为何官方菜单文案正确而欢迎窗口错误
      required: true
      version: 1
    - id: ac2
      text: 影响面与触发条件：说明打包/开发、手动与后台检查、欢迎窗口与应用菜单各自的表现差异
      required: true
      version: 1
    - id: ac3
      text: 进度方案设计：确认官方无进度回调的边界，给出基于现有 downloadRequest 流的进度方案（数据源、IPC 通道、节流、取消、UI 位置）与验证方式，含测试夹具需支持分块
      required: true
      version: 1
    - id: ac4
      text: 实现：欢迎窗口按钮在下载阶段显示「正在下载 <n>%」（英文 Downloading <n>%），busy 仅负责禁用；应用菜单与托盘保持官方文案、不追加百分比；下载结束或取消后状态清空
      required: true
      version: 2
    - id: ac5
      text: 验证证据：单测覆盖进度回调与节流；npm run check 通过；原生图形验收在中英文与浅色/暗色下断言按钮的下载中百分比、菜单仍等于官方 label，且窄窗口不溢出
      required: true
      version: 2
questions:
  - Windows 平台尚未做原生更新验收，是否需要安排？
handoff:
  nextSteps:
    - 如需 Windows 覆盖，在 Windows 机器上补跑 npm run smoke:updates 并报告平台结果
    - 开发期验证更新下载需临时打开 canDownload（本次已还原，未保留环境变量开关）
    - 如需调整进度节流粒度，policy.progressIntervalMs 可配置，默认 500 ms
  readBefore:
    - file-project-updates
    - file-release-feed
    - file-guide-index
  verifyBefore:
    - note-verify-update
references:
  - id: file-guide-index
    label: 欢迎窗口渲染层（按钮文案仅用 busy）
    type: file
    path: resources/dsh-project-desktop/src/guide/index.tsx
  - id: file-guide-window
    label: 欢迎窗口主进程（state 只透出 label/busy）
    type: file
    path: resources/dsh-project-desktop/src/windows/guide-window.mjs
  - id: file-project-updates
    label: 更新适配层（busy/label/下载与安装交接）
    type: file
    path: resources/dsh-project-desktop/src/desktop-adapter/stable/project-updates.mjs
  - id: file-release-feed
    label: Release feed（唯一可靠进度注入点）
    type: file
    path: resources/dsh-project-desktop/src/desktop-adapter/stable/project-release-feed.mjs
  - id: file-main
    label: 主进程接线（changed 广播与菜单 label）
    type: file
    path: resources/dsh-project-desktop/src/app/main.mjs
  - id: file-update-case
    label: 原生更新图形验收用例
    type: file
    path: resources/dsh-project-desktop/scripts/native-update-case.mjs
  - id: file-fixture
    label: 原生更新测试夹具（假 feed）
    type: file
    path: resources/dsh-project-desktop/scripts/native-update-fixture.mjs
  - id: file-update-fixtures
    label: 安装包夹具生成器（512 字节，需支持分块）
    type: file
    path: resources/dsh-project-desktop/scripts/update-fixtures.mjs
  - id: file-updates-test
    label: 更新单元测试
    type: file
    path: resources/dsh-project-desktop/tests/project-updates.test.mjs
  - id: file-arch
    label: 架构文档更新适配章节
    type: file
    path: resources/dsh-project-desktop/docs/architecture.md
  - id: note-verify-update
    label: 验证方式
    type: note
    text: cd resources/dsh-project-desktop && npm run check（含 verify:upstream/build/test/smoke:host）；更新专项：npm test（tests/project-updates.test.mjs）与 npm run smoke:updates。UI 改动必须另做原生图形验收并分别报告平台，不能以 macOS x64 结果声称 Windows 或 macOS arm64 通过；开发期 UI 迭代用 DSH_PROJECT_PLUGIN_SOURCE + DSH_PROJECT_DESKTOP_USER_DATA 起本地壳。
entries:
  - id: inv-update-1
    kind: progress
    content: "缺陷根因（已逐行核实）：src/guide/index.tsx:394-395 的按钮只按布尔量二选一渲染文案 —— `disabled={updates.busy}`、`title={updates.label}`、`{updates.busy ? t.checkingUpdates : t.checkUpdates}`。updates.busy 来自 src/desktop-adapter/stable/project-updates.mjs:122 `get busy() {return Boolean(manual)}`，而 manual 是 lifecycle.checkNow() 的整个 Promise（project-updates.mjs:127）。官方 runManualCheck 会 await offerDownload → startDownload → adapter.downloadAndOpen，直到下载、打开安装包或安装交接全部结束才 resolve，因此 busy 在整个下载阶段恒为 true。结论：数据层面 busy 正确，错误在于渲染层把 busy 当成「正在检查」的同义词；官方准确的 label（此时为「正在下载 …」）只被用作 tooltip，未参与文案。"
    basis: observation
    reason: 确定缺陷性质：渲染层语义缺失，而非状态机错误
    createdAt: 2026-09-20T13:36:45.619Z
  - id: inv-update-2
    kind: progress
    content: 官方生命周期本身具备三态区分：lib/chunk-N4AZ2ZSD.js 的 DesktopUpdateLifecycleOwner 维护 checking / downloadingVersion / availableVersion，trayLabel() 依次返回 checkingForUpdates、downloadingUpdate(version)、updateAvailable(version)、checkForUpdates，并在 startCheck、startDownload、observeResult 中调用 registration.refresh()。我们的适配层把 registerTrayItem 的 refresh 映射为 changed()（project-updates.mjs:118），main.mjs:357 的 changed() 向 guide 与 projectCreate 广播 project-desktop:state-changed。因此下载开始时 renderer 确实收到了刷新，并拿到了 label=「正在下载 DSH Project Desktop 0.1.2…」（brand() 已替换品牌），但 guide-window.mjs:85 只透出 {label, busy} 两个字段，且 label 仅用于 title。用户截图中「关于」菜单正确显示下载中文案、欢迎窗口按钮错误，与此完全一致。
    basis: observation
    reason: 证明修复成本低：状态已到达渲染层，缺的是渲染语义与显式 phase
    createdAt: 2026-09-20T13:36:45.619Z
  - id: inv-update-3
    kind: progress
    content: 进度边界已确认：官方 downloadDesktopUpdate(options) 仅接受 {platform, channel, version, destinationPath, request, signal}，内部 await writeResponseBody(paths.temporary, response.body, options.signal) 直接流式落盘，没有任何进度回调；它走 electron.net.fetch 而非 Electron download manager，因此 session 的 will-download / download-progress 不会触发，不能用官方事件做进度。可行的唯一进度源是我们在 project-release-feed.mjs:69-92 注入的 downloadRequest：它已经在用 TransformStream 逐块累加 size 并计算 SHA-256（第 79-90 行），总大小可靠来自清单 release.installer.size（同值作为 Content-Length 返回给官方下载器，官方还会 assertDeclaredSize 复核）。
    basis: observation
    reason: 确认官方无进度能力的边界，并锁定唯一可靠的进度注入点
    createdAt: 2026-09-20T13:36:45.619Z
  - id: dec-update-4
    kind: decision
    content: 修复方向（供排期，未实现）：一、文案与状态：在 project-updates.mjs 暴露显式 phase（idle/checking/downloading/available）或直接暴露下载中的 version，guide-window 的 state 增加该字段，index.tsx 据此渲染「正在检查更新…」/「正在下载 <version>…（<n>%）」，busy 仍只负责禁用；文案沿用官方 native-dialog-copy 的 downloadingUpdate 语义，不新造第二套词表。二、进度：由 createProjectReleaseFeed 接受 onProgress 回调，在既有 TransformStream 的 transform 中累加 received 并回调 {version, received, total}；project-updates 持有该进度并经现有 changed() 广播（需按百分比或 ~200ms 节流，避免 IPC 风暴），abort/finally 时清空。三、UI：欢迎窗口底部按钮区（data-check-updates 附近）显示百分比或细进度条；是否也在下载确认对话框之后提供独立进度窗口需在实现前定夺。
    basis: agent-proposal
    reason: 把调查结论转成可排期的实现方向
    createdAt: 2026-09-20T13:36:45.619Z
  - id: obs-update-5
    kind: progress
    content: 验证路径与当前障碍：单测入口 tests/project-updates.test.mjs（已覆盖清单校验、条件请求、下载完整性、生命周期）；原生图形验收入口 scripts/smoke-updates.mjs → scripts/native-update-case.mjs，用 scripts/native-update-fixture.mjs 注入假 feed（packaged:true、可替换 openPath/notify），并在下载段断言了「Later 不下载」「保存选择器替换」「下载完成弹窗」；scripts/native-update-case.mjs:142-154 已有窄窗口 + data-check-updates 按钮的几何断言，是加按钮文案断言的自然位置。障碍：scripts/update-fixtures.mjs 生成的安装包只有 512 字节、一次 chunk 读完，无法产生可观测进度；要实现进度验收必须先让夹具支持分块与可控延迟（例如返回可分段 enqueue 的 ReadableStream 并暴露 chunk 数）。另：本工作树尚未 setup，.cache/runtime 与 .upstream 不存在，官方源码核对当前借助已安装应用的 .cache/runtime/dsh-plugin-desktop（版本 2.0.11，与 upstream.lock.json 一致）。
    basis: observation
    reason: 记录验证落点与必须先解决的工具缺口
    createdAt: 2026-09-20T13:36:45.619Z
  - id: inv-update-6
    kind: progress
    content: 影响面与触发条件：1) 仅打包版可复现 —— createProjectUpdates 的 canDownload = packaged && (darwin || win32 x64)（project-updates.mjs:51），官方 observeResult 只在 canDownload 时设 availableVersion，开发/未打包时根本不会进入下载；2) 手动检查必然复现 —— 按钮点击 checkNow 后 busy 覆盖整个下载；3) 后台检查间接复现 —— 启动 60s 后 runBackgroundCheck 只 notify 不自动下载，此时按钮仍是「检查更新」，但用户点通知后进入同一条下载路径；4) 应用菜单/托盘文案正确 —— main.mjs:278-279 与 317 使用 updates.label()（官方 trayLabel），下载时显示「正在下载 …」且 enabled=!busy；5) 项目窗口不涉及 —— 项目窗口的 Host runtime（src/desktop-adapter/native.mjs:59）把 updates 整体 disabled（request/confirmDownload/downloadAndOpen 均为 disabled，canDownload:false），应用级更新只由欢迎窗口与应用菜单提供。
    basis: observation
    reason: 回答验收 ac2：区分打包/开发、手动/后台、各入口的表现
    createdAt: 2026-09-20T13:38:02.772Z
  - id: ver-update-ac1
    kind: verification
    content: 验收 ac1：缺陷证据链已完成。渲染层 src/guide/index.tsx:394-395 以 updates.busy 二选一输出文案，label 仅作为 title；适配层 src/desktop-adapter/stable/project-updates.mjs:122 busy = Boolean(manual)，:127 manual = lifecycle.checkNow() 的整个 Promise；官方 chunk-N4AZ2ZSD.js 的 runManualCheck 依次 await startCheck → observeResult → offerDownload → startDownload → adapter.downloadAndOpen，故 busy 在整个下载阶段恒为 true；状态确实会推送（官方 registration.refresh() → changed() → main.mjs:357 广播 project-desktop:state-changed），但 src/windows/guide-window.mjs:85 只透出 {label, busy}。结论：状态机正确、渲染层把 busy 误用为「正在检查」。
    basis: observation
    reason: 逐处核实并回答 ac1
    verification:
      criterionId: ac1
      criterionVersion: 1
      method: 逐行读取 src/guide/index.tsx、src/windows/guide-window.mjs、src/desktop-adapter/stable/project-updates.mjs、src/app/main.mjs，并与已安装应用内官方 bundle lib/chunk-N4AZ2ZSD.js 对照
      result: passed
      coverage: 覆盖渲染层、适配层、官方生命周期与广播链路；未加运行时断点（本轮不改代码），用户提供的两张截图已给出「菜单正确 / 按钮错误」的对照复现
    createdAt: 2026-09-20T13:38:02.772Z
  - id: ver-update-ac2
    kind: verification
    content: 验收 ac2：影响面与触发条件已记录（见 inv-update-6）：仅打包版且平台受支持时进入下载；手动检查必现；后台检查经通知点击后同样进入；应用菜单与托盘因复用官方 label 而文案正确；项目窗口不提供更新入口。开发模式因 canDownload=false 不复现。
    basis: observation
    reason: 回答 ac2
    verification:
      criterionId: ac2
      criterionVersion: 1
      method: 核对 canDownload 条件（project-updates.mjs:51）、native.mjs:59 的 disabled runtime、main.mjs:278-279/317 的菜单接线，以及官方 observeResult 的 availableVersion 赋值条件
      result: passed
      coverage: 覆盖打包/开发、手动/后台、欢迎窗口/应用菜单/托盘/项目窗口四类入口；开发与未打包路径未实际启动验证（本工作树尚未 setup），结论来自条件与 disabled 定义
    createdAt: 2026-09-20T13:38:02.772Z
  - id: ver-update-ac3
    kind: verification
    content: 验收 ac3：进度方案设计已完成（见 inv-update-3 与 dec-update-4）。边界：官方 downloadDesktopUpdate 无进度回调、走 electron.net.fetch 而非 Electron download manager，will-download 不触发；唯一可靠进度源是 src/desktop-adapter/stable/project-release-feed.mjs:69-92 已存在的 TransformStream（累加 size + SHA-256），总大小取自清单 release.installer.size（已作为 Content-Length 交给官方，并有 assertDeclaredSize 复核）。方案：feed 接受 onProgress 回调 → project-updates 暴露 phase 与 {received,total} → 经现有 changed() 节流广播 → guide-window state 透出 → index.tsx 按 phase 渲染文案与百分比。验证障碍：scripts/update-fixtures.mjs 的安装包仅 512 字节、单 chunk 读完，必须先支持分块与延迟才能观测进度。
    basis: observation
    reason: 回答 ac3：确认官方无进度能力的边界并给出可行设计
    verification:
      criterionId: ac3
      criterionVersion: 1
      method: 读取官方 downloadDesktopUpdate 实现与选项签名、核对 Electron net.fetch 与 download manager 差异、定位 feed 注入点与既有校验逻辑、检查测试夹具与原生验收脚本能力
      result: passed
      coverage: 覆盖官方能力边界、进度数据源、IPC 通道、节流与取消、UI 位置与验证路径；方案尚未实现，节流参数与夹具分块方式未实测
    createdAt: 2026-09-20T13:38:02.772Z
  - id: dec-update-7
    kind: decision
    content: 交互决策已定（用户确认）：一、进度展示形态——欢迎窗口更新按钮内联百分比，不做独立进度窗口/进度条；二、下载期间不提供取消入口（官方 signal 虽已贯通，但 UI 不加取消按钮）；三、后台检查保持现状——启动 60s 后只通知一次，不自动下载、不显示进度，用户点击通知/按钮后才进入下载并显示进度。
    basis: user-request
    reason: 锁定实现范围，避免后续交互反复
    createdAt: 2026-09-20T13:48:24.672Z
  - id: inv-update-8
    kind: progress
    content: 应用菜单/托盘百分比可行性调查（回答用户第 4 点）：可行，但有三条约束。一、文案同源：main.mjs:278-279 的应用菜单项与 :317 的托盘项都用 updates.label()，而 label() 在 project-updates.mjs:121 直接返回官方 brand(registration.label())，所以只需让 label() 在下载中返回带百分比的文案，菜单与托盘会同时生效。二、成本：main.mjs:272-312 的 refreshMenus() 每次都全量 Menu.buildFromTemplate + Menu.setApplicationMenu + tray.setContextMenu，而 changed() 在每次状态变化时调用 refreshMenus()（main.mjs:357），因此进度广播频率直接等于菜单重建频率，必须节流（建议整数百分比变化或 ~500ms，避免每个 chunk 重建）。三、平台行为：macOS/Windows 原生菜单在下拉展开期间重建 setApplicationMenu 不保证刷新已展开内容，用户需关掉重开才能看到新百分比，验收不能承诺实时跳动。文案建议复用 copy().downloadingUpdate(version)（官方 desktopNativeCopy + brand 替换）再追加百分比，不另造词表。
    basis: observation
    reason: 确认菜单/托盘显示百分比的可行性与实现约束
    createdAt: 2026-09-20T13:48:24.672Z
  - id: scope-update-9
    kind: scope
    content: 实现范围扩展（用户确认开工）：任务从「调查与设计」扩展到交付。实现约束：按钮内联百分比（文案「正在下载 <n>%」）；不提供下载取消入口；后台检查保持只通知一次；应用菜单与托盘一并显示百分比。官方 upstream 源码与 bundle 仍不得修改，进度只在 Shell 适配层实现。
    basis: user-request
    reason: 将用户确认的实现范围纳入任务验收
    createdAt: 2026-09-20T15:12:13.666Z
  - id: impl-update-10
    kind: progress
    content: 实现完成（全部在 Shell 侧，未改官方源码）：1) src/desktop-adapter/stable/project-release-feed.mjs —— createProjectReleaseFeed 新增 onProgress，在已确认版本的校验流上回调 {version, received, total}（起始 0 与每 chunk 各一次，total 取清单 installer.size）；2) src/desktop-adapter/stable/project-updates.mjs —— 新增导出 createUpdateProgress（downloading 阶段 + 节流百分比 + end 清空），downloadAndOpen 入口 begin、finally end，service 新增 phase/progress getter，label() 在下载中追加「 <n>%」（菜单与托盘同源生效）；3) src/windows/guide-window.mjs —— state 透出 phase/progress；4) src/guide/index.tsx —— 按钮按 phase 渲染「正在下载 <n>%」/「Downloading <n>%」，busy 仅用于禁用；5) scripts/native-update-fixture.mjs —— 支持 chunkSize/chunkDelayMs 分块下载；6) scripts/native-update-case.mjs —— 新增下载中按钮与菜单断言、窄窗口不溢出、结束清空，以及英文浅色一次；7) docs/architecture.md 记录进度为 Shell 新增适配及其官方来源。
    basis: observation
    reason: 记录实际交付内容
    createdAt: 2026-09-20T15:14:57.954Z
  - id: ver-update-ac4
    kind: verification
    content: 验收 ac4：实现行为已核实。单测断言 createUpdateProgress 的 begin→0%→节流丢弃→25%→同百分比不刷新→50%→100% 必刷新→end 清空；原生验收在真实窗口断言按钮文案匹配「正在下载 <n>%」/「Downloading <n>%」、updates.phase === 'downloading'、updates.label() 以百分比结尾、结束或取消后 phase === 'idle' 且 progress === undefined。按用户决定未提供下载取消入口，因此「取消后清空」仅由 downloadAndOpen 的 finally 路径覆盖，未做取消 UI 验收。
    basis: observation
    reason: 验收 ac4：实现与状态清理
    verification:
      criterionId: ac4
      criterionVersion: 1
      method: node --test tests/project-updates.test.mjs 与 npm run smoke:updates（scripts/native-update-case.mjs 新增断言）
      result: passed
      coverage: 覆盖 phase、百分比推进、节流、菜单 label 追加、结束清空与窄窗口不溢出；取消入口按用户要求未实现，故无取消按钮的视觉验收
    createdAt: 2026-09-20T15:14:57.954Z
  - id: ver-update-ac5
    kind: verification
    content: 验收 ac5：验证证据完整。npm run check 全绿（verify:upstream、build、72 个单测、test:recovery、test:safe-mode、check-project-files、smoke:host）；npm run smoke:updates 在 macOS 真实窗口通过 20 项，含新增的 welcome-download-progress 与 welcome-download-progress-english-light；截图证据 updates-welcome-downloading.png（中文、暗色、420px 窄窗口，按钮「正在下载 0%」）与 updates-welcome-downloading-en-light.png（英文、浅色，按钮「Downloading 0%」）。限制：仅 macOS x64，Windows 未做原生更新验收，不能据此外推 Windows 结果。
    basis: observation
    reason: 验收 ac5：构建、单测与原生图形验收证据
    verification:
      criterionId: ac5
      criterionVersion: 1
      method: npm run check 与 npm run smoke:updates（真实 Electron 窗口 + 假 feed 分块下载）
      result: passed
      coverage: 覆盖壳完整检查链、进度单测、原生下载中按钮与菜单文案、中英双语与浅/暗两套主题、窄窗口不溢出；Windows 平台未验收
    createdAt: 2026-09-20T15:14:57.954Z
  - id: completion-update-11
    kind: completion
    content: 交付完成：原缺陷（下载阶段按钮仍显示「正在检查更新…」）已修复，并新增官方不具备的下载进度可见性（欢迎窗口按钮内联百分比、应用菜单与托盘 label 同源追加百分比）。实现只落在 Shell 适配层，官方 upstream 源码与 bundle 未改；节流与状态清理均有单测与原生验收证据。
    basis: observation
    reason: 所有 required 验收标准均已通过
    verificationEntryIds:
      - ver-update-ac1
      - ver-update-ac2
      - ver-update-ac3
      - ver-update-ac4
      - ver-update-ac5
    createdAt: 2026-09-20T15:14:57.954Z
  - id: scope-update-12
    kind: scope
    content: 范围收敛（用户验证后决定）：应用菜单与托盘保持官方文案，不追加下载百分比；只有欢迎窗口按钮显示进度。同时新增 progressChanged 通道，使进度更新只推送到欢迎窗口，不再每 500 ms 重建应用菜单与托盘菜单；菜单项启用状态仍跟随官方 registration.refresh()。
    basis: user-request
    reason: 记录菜单范围回退与随之而来的菜单重建优化
    createdAt: 2026-09-20T18:37:15.626Z
  - id: change-427aa072-926c-4cc6-b85b-932d2518d78e
    kind: decision
    content: completed → active
    reason: 用户实际验证后决定菜单栏与官方保持一致、不做百分比（macOS 不会重绘已展开的原生菜单，菜单里的百分比只能是打开那一刻的快照）；ac4/ac5 原文要求菜单与托盘追加百分比，已按该决定回退实现，因此先重新打开任务以修正验收标准，再按新标准重新验收。
    createdAt: 2026-09-20T18:37:15.626Z
  - id: ver-update-ac4b
    kind: verification
    content: 验收 ac4（v2，最终实现）：欢迎窗口按钮按 phase 渲染「正在下载 <n>%」/「Downloading <n>%」，busy 仅负责禁用；应用菜单与托盘保持官方文案、不追加百分比；下载结束或取消后 phase 回 idle 且 progress 清空。单测断言 createUpdateProgress 的 begin→0%→节流丢弃→25%→同百分比不刷新→50%→100% 必刷新→end 清空；原生验收在真实窗口断言按钮文案与 phase === 'downloading'、结束清空，并断言下载中菜单项文案仍等于 updates.label()（官方文案）。按用户决定未提供取消入口，取消后清空仅由 downloadAndOpen 的 finally 路径覆盖。
    basis: observation
    reason: 按修正后的 ac4（v2）重新验收最终实现
    verification:
      criterionId: ac4
      criterionVersion: 2
      method: node --test tests/project-updates.test.mjs 与 npm run smoke:updates（菜单回退后重跑）
      result: passed
      coverage: 覆盖 phase、百分比推进、节流、按钮文案、菜单保持官方、结束清空与窄窗口不溢出；取消入口按用户要求未实现，无取消按钮的视觉验收
    createdAt: 2026-09-20T18:37:44.915Z
  - id: ver-update-ac5b
    kind: verification
    content: 验收 ac5（v2，回退后重跑）：npm run check 全绿（verify:upstream、build（版本已还原 0.1.1）、72 个单测、test:recovery、test:safe-mode、check-project-files、smoke:host）；npm run smoke:updates 在 macOS 真实窗口通过 20 项，含 welcome-download-progress 与 welcome-download-progress-english-light，且下载中菜单项断言为官方 label。限制：仅 macOS x64，Windows 未做原生更新验收。
    basis: observation
    reason: 按修正后的 ac5（v2）重新验收
    verification:
      criterionId: ac5
      criterionVersion: 2
      method: npm run check && npm run smoke:updates（还原临时版本号与开发开关后）
      result: passed
      coverage: 覆盖壳完整检查链、进度单测、原生下载中按钮百分比、菜单保持官方文案、中英双语与浅/暗主题、窄窗口不溢出；Windows 未验收
    createdAt: 2026-09-20T18:37:44.915Z
  - id: completion-update-13
    kind: completion
    content: 交付完成：原缺陷（下载阶段按钮仍显示「正在检查更新…」）已修复，并新增官方不具备的下载进度可见性——仅限欢迎窗口按钮内联百分比；应用菜单与托盘经用户验证后决定保持官方文案。实现只落在 Shell 适配层，官方 upstream 源码与 bundle 未改。提交为 945734e（phase/进度/按钮）与 7aa6af9（菜单保持官方 + progressChanged）。
    basis: observation
    reason: 修正后的全部 required 验收标准均已通过
    verificationEntryIds:
      - ver-update-ac1
      - ver-update-ac2
      - ver-update-ac3
      - ver-update-ac4b
      - ver-update-ac5b
    createdAt: 2026-09-20T18:37:44.915Z
operations:
  e06411a1ef58a74f4a35366be396c59612f2ff768082a0f8d900c68a97bb8acb:
    fingerprint: 7d005007cbf948c9961c9469731aae39a15a93e65178ed9e029d61ff142f6936
    kind: create
    at: 2026-09-20T13:36:45.619Z
    entryIds:
      - inv-update-1
      - inv-update-2
      - inv-update-3
      - dec-update-4
      - obs-update-5
  d67a7c1521544d8296c9acc78e35f6833cb1a182b95e8139454ec6cdb3043504:
    fingerprint: b3f1cedc600a1aefe5f7a890184175c20ad97b70e82105ed05743989d2698f21
    kind: update
    at: 2026-09-20T13:38:02.772Z
    entryIds:
      - inv-update-6
      - ver-update-ac1
      - ver-update-ac2
      - ver-update-ac3
  70910058e33421bfb207466e0dddaa9b0ce2c2db24819037ecd6abec002299b0:
    fingerprint: fdb06c51874801bbe4d7f6a9f98baf5df5658dcd58afcf3f389a5ac79c8f7302
    kind: update
    at: 2026-09-20T13:48:24.672Z
    entryIds:
      - dec-update-7
      - inv-update-8
  f712368ce3b6f2f4aa3121763e8675550eb0e5698413ec4453dc775edf4929a5:
    fingerprint: e0682e928d9afd74663b4792dfbca7bb97b20c26dfbf70c45482e09cdbe9f036
    kind: update
    at: 2026-09-20T13:49:25.943Z
    entryIds: []
  bc5e81a97d4d34da9186d88bd1477a88da2cd59a0fcac8614cc8df2e9c1ea693:
    fingerprint: 1d46b24b8f10715ae4199b567b19c45f9ad5a600492a5d4c3308a48d84a8fff7
    kind: update
    at: 2026-09-20T15:12:13.666Z
    entryIds:
      - scope-update-9
  501dd599676684889211c17c127580edf1db92b82f4ba7fee635b51f3cbc69f3:
    fingerprint: 89e69d9a7b327cf4c14e876893e0f35c628c29830639ec6f2b77cb97835eaf85
    kind: update
    at: 2026-09-20T15:14:57.954Z
    entryIds:
      - impl-update-10
      - ver-update-ac4
      - ver-update-ac5
      - completion-update-11
  9d0fd80ea9da27c4e9bec1d8844fd8aa213445de29aabe87ed1c893586466102:
    fingerprint: 4cfd763ec5c7bf849ca2c0e9b5ab64cb985c1aa5bc8978b390c687d59e6e664e
    kind: update
    at: 2026-09-20T15:16:33.246Z
    entryIds: []
  347a3632fb46209f9648de2591eb46d507e9031b356f545326ea05137159b215:
    fingerprint: 6510f64c644da5fc36c264a86047fd121561fdb95ff69184ae54a75a181e4f01
    kind: update
    at: 2026-09-20T18:37:15.626Z
    entryIds:
      - scope-update-12
      - change-427aa072-926c-4cc6-b85b-932d2518d78e
  2fe277f075d685634c2e035d7477cb95ea59537e83317ae322fb9c1eceb98091:
    fingerprint: 7df017c5f385fcfb1d1862e3d9f6bfc75c499e41ea1a6315dbc2f638ce2e47cb
    kind: update
    at: 2026-09-20T18:37:44.915Z
    entryIds:
      - ver-update-ac4b
      - ver-update-ac5b
      - completion-update-13
criterionVersions:
  ac1: 1
  ac2: 1
  ac3: 1
  ac4: 2
  ac5: 2
---

缺陷与增强均已交付：下载阶段欢迎窗口按钮按显式 phase 渲染「正在下载 <n>%」（英文 Downloading <n>%），busy 仅负责禁用；应用菜单与托盘经用户验证后保持官方文案、不追加百分比（macOS 不会重绘已展开的原生菜单，菜单里的百分比只能是打开那一刻的快照）。官方下载器无进度回调，进度由 Shell 在自有校验流上采集（createProjectReleaseFeed 的 onProgress）并经 createUpdateProgress 节流为 500 ms/整数百分比；进度更新走独立的 progressChanged 通道，只推送到欢迎窗口，不再重建应用菜单与托盘菜单。验证：npm run check 全绿（含 72 个单测），npm run smoke:updates 在 macOS 真实窗口通过 20 项（含中英文与浅/暗主题的下载中按钮断言、菜单仍等于官方 label、窄窗口不溢出）。提交：945734e、7aa6af9。限制：Windows 未做原生验收；临时版本号与开发下载开关已还原，未保留。
