---
schemaVersion: 3
directory: 启动与打开项目耗时埋点：实机阶段日志 + 一键导出日志与诊断
id: task-3ee98604-d1e5-423e-b4e8-d421519c84dc
title: 启动与打开项目耗时埋点：实机阶段日志 + 一键导出日志与诊断
objective: 让“Windows 启动卡二三十秒”“打开项目有时也慢”这类实机延迟可以被定位到具体阶段：在主进程启动链路、打开项目链路与 Host 进程内部加入常开的分阶段时间戳追踪并落到 userData/boot.log；把恢复模式原因并入同一份证据；在项目工具菜单提供一个导出入口，产出可直接发送的“日志 + 官方诊断包”分析材料。
status: active
createdAt: 2026-09-23T13:44:07.489Z
updatedAt: 2026-09-24T02:35:06.292Z
artifacts:
  - type: file
    path: artifacts/c5-export-report-sample.log
    description: C5 端到端一次导出的报告样例（含 boot 段、project/open 段与 Host 阶段、数据来源、恢复原因清单）
  - type: file
    path: artifacts/verification-summary.json
    description: 本轮 C1–C6 复核结论、端到端菜单与产物、四项发现（回归已修/快照漂移已修/两个未修小瑕疵）
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: ada96bcc60dec3eaefdcd4a5155a5b0c7aafaf19
    description: 恢复官方 exportDiagnostics 契约并把导出合并为唯一入口
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: 4ca44a6b61b9962ed14d99d96f77ecc4a39c4154
    description: 导出动作自记一段 export 追踪；macOS 冒烟不再因标题栏语言检查失败
archived: false
phase: validation
brief:
  currentBehavior: 启动与打开项目的耗时光靠离线探针（scripts/probe-host-boot-timing.mjs、probe-boot-timing 工作流）或失败信息推测；实机启动/打开变慢时 shell 没有任何分阶段计时，Host 内部（首次 Profile 准备的 pnpm 依赖实体化、官方插件树）对主进程完全不可见。恢复模式原因只写在项目状态目录的 recovery-events.jsonl，实际没人知道去那里找。
  scope: 壳主进程启动链路、打开项目链路、Host 进程内部阶段埋点；trace 落盘与保留策略；恢复原因并入 trace；项目工具菜单的日志+诊断导出入口；开发与架构文档；真实启动验证探针；单测覆盖 trace 语义与导出报告渲染。
  constraints:
    - 埋点必须常开可回看，不能是需要事先打开的开关
    - 日志写入不能成为启动失败的原因（写失败只静默丢弃）
    - trace 对象显式传递，禁止模块级“当前会话”以免多项目并行打开时串线
    - 导出失败复用官方文案，不新增并行的原生对话框体系
  outOfScope:
    - 官方诊断包内容本身（仍由固定 Desktop 的 exportDiagnosticsZip 生成）
    - 自动上报/遥测上传
    - 把 Host 内部每个子阶段都拆到函数级
    - 本次不做性能优化，只做归因
  acceptanceCriteria:
    - id: C1
      text: 真实 Electron 启动写入 boot 段，含 Electron 就绪、工作区恢复、欢迎窗口等阶段
      required: true
      version: 1
    - id: C2
      text: 真实打开项目写入 project/open:<项目> 段，且含 Host 进程内部阶段（via=host-entry）
      required: true
      version: 1
    - id: C3
      text: 单阶段 ≥1000 ms 在日志中被标记为 [SLOW >1000ms]，段落结束给出 total 与最慢阶段
      required: true
      version: 1
    - id: C4
      text: 文件超过保留预算时只保留最新记录，写入失败不抛错、不影响启动
      required: true
      version: 1
    - id: C5
      text: 项目工具菜单一次导出即产出报告与官方诊断 zip 同目录材料
      required: true
      version: 1
    - id: C6
      text: yarn check 通过（含全部单测与 smoke:host）
      required: true
      version: 1
questions:
  - 修复提交 ada96bc 与 4ca44a6 尚未进入发布：是否需要按发布手册出 0.1.10 补丁版（版本号、双语发布说明、pin/lock 校验、推 tag）？
handoff:
  nextSteps:
    - 如需让两个修复到达用户：按发布手册 bump 到 0.1.10（版本号、双语发布说明、pin/lock 检查、推 tag）——目前只在 master（ada96bc、4ca44a6）
  readBefore:
    - boot-log
    - native-adapter
    - official-tray
    - contract-test
  verifyBefore:
    - cd resources/dsh-project-desktop && yarn check（EXIT=0；含新增 5 项契约测试）
    - yarn probe:startup-trace <label>（macOS 上 trace 7/7 且冒烟退出码 0）
    - 真实端到端：打开项目 → 项目工具菜单应只有「导出日志与诊断…」一个导出入口，点击后同目录得到报告与 dsh-diagnostics-*.zip，boot.log 多出一段 export 追踪
references:
  - id: boot-log
    label: src/app/boot-log.mjs（追踪与导出报告渲染）
    type: file
    path: resources/dsh-project-desktop/src/app/boot-log.mjs
  - id: native-adapter
    label: src/desktop-adapter/native.mjs（项目 runtime 与官方契约方法）
    type: file
    path: resources/dsh-project-desktop/src/desktop-adapter/native.mjs
  - id: official-tray
    label: src/desktop-adapter/stable/official-tray.mjs（官方重复菜单项识别）
    type: file
    path: resources/dsh-project-desktop/src/desktop-adapter/stable/official-tray.mjs
  - id: contract-test
    label: tests/desktop-runtime-contract.test.mjs（官方契约方法防回归）
    type: file
    path: resources/dsh-project-desktop/tests/desktop-runtime-contract.test.mjs
entries:
  - id: e1
    kind: progress
    content: 调研两条慢路径：启动链路（main.mjs run()）与打开项目链路（open → workspace.open → createProject → openNativeProject → startProjectHost → Host boot RPC）。确定 Host 内部是“打开项目慢”的关键盲区：prepareProjectProfile 在 Host 进程内执行，首次会跑受 120 秒预算约束的 pnpm 依赖实体化（src/desktop-adapter/stable/profile.mjs 的 materializeProjectDependencies）。
    basis: observation
    createdAt: 2026-09-23T13:44:07.489Z
  - id: e2
    kind: decision
    content: 追踪常开写入 <userData>/boot.log，而不是要求事先设置环境变量：慢启动往往发生在没开开关的那一次；trace 对象显式向下传递，不用模块级“当前会话”，因为一次启动可能并行打开多个项目。
    basis: agent-proposal
    createdAt: 2026-09-23T13:44:07.489Z
  - id: e3
    kind: decision
    content: Host 进程通过 DSH_PROJECT_BOOT_LOG_FILE 与 DSH_PROJECT_BOOT_SESSION 复用同一段 trace，并单独给 pnpm 依赖实体化计时：否则壳只能说“boot RPC 花了 25 秒”，无法区分首次安装、插件树还是渲染服务器。
    basis: agent-proposal
    createdAt: 2026-09-23T13:44:07.489Z
  - id: e4
    kind: decision
    content: 导出入口合并而不是新增：项目工具菜单里原有的“导出项目诊断…”升级为“导出日志与诊断…”，一次导出写报告（追踪全文 + 各项目恢复原因）并把官方诊断 zip 复制到同目录，避免两个入口把证据拆成两半。
    basis: user-request
    createdAt: 2026-09-23T13:44:07.489Z
  - id: e5
    kind: verification
    content: 实机验证：yarn probe:startup-trace native 启动真实 Electron 壳并打开项目，boot.log 中 boot 段与 project/open:<项目> 段齐备，Host 进程阶段写入同段，实测最慢阶段为“official host booted 7450 ms”，并带 [SLOW >1000ms] 标记。
    basis: observation
    verification:
      criterionId: C2
      criterionVersion: 1
      method: 真实 Electron 启动 + 读取生成的 boot.log
      result: passed
      coverage: 启动、打开项目、Host 内部阶段、慢阶段标记均出现
    createdAt: 2026-09-23T13:44:07.489Z
  - id: e6
    kind: verification
    content: 单测：tests/boot-log.test.mjs 12/12 通过，覆盖阶段耗时与偏移、慢阶段标记、measure 成功/失败、保留策略截断、写失败静默、禁用与重定向、Host 复用会话、导出报告渲染与恢复原因单行化。
    basis: observation
    verification:
      criterionId: C4
      criterionVersion: 1
      method: node --test tests/boot-log.test.mjs
      result: passed
      coverage: 12 项断言全部通过
    createdAt: 2026-09-23T13:44:07.489Z
  - id: e7
    kind: progress
    content: 发布 0.1.9：版本号提到 0.1.9；插件 pin 从 5193e81 提到已推送的 d45b54f（tree f8fe0b42b631df28cf5b7eeb81d1294919813cbf），.upstream/project 快照重导（188 文件）并通过 verify:upstream；新增 docs/releases/0.1.9.md（中英双语）；master 发布提交 24ca2db，tag v0.1.9 已推送，Package Desktop 工作流 run 35877171879 已触发。
    basis: observation
    createdAt: 2026-09-23T14:51:04.026Z
  - id: e8
    kind: verification
    content: 发布前全量校验：yarn check EXIT=0（verify:upstream + build + 全部单测 + recovery + safe-mode + project-files + smoke:host）。
    basis: observation
    verification:
      criterionId: C6
      criterionVersion: 1
      method: yarn check（仓库根）
      result: passed
      coverage: 发布提交前的完整校验链全部通过
    createdAt: 2026-09-23T14:51:04.026Z
  - id: e9
    kind: verification
    content: C1（真实启动写入 boot 段）：yarn probe:startup-trace 真实启动 Electron 壳，boot 段依次含 early electron main / cleanup guide clones / theme and recent-projects state / app.whenReady / updates service / disposable project state cleanup / tray, accelerators, menus / workspace restore / welcome window created，并在 will-quit 收尾 total。
    basis: observation
    verification:
      criterionId: C1
      criterionVersion: 1
      method: 真实 Electron 启动 + 读取 boot.log 的 boot 段
      result: passed
      coverage: 启动段各关键阶段均出现在真实启动日志中
    createdAt: 2026-09-23T15:28:43.586Z
  - id: e10
    kind: verification
    content: "C3（慢阶段标记与段落汇总）：实机日志中单阶段 ≥1000 ms 行带 [SLOW >1000ms]（实测 official host booted 6433 ms、host boot rpc returned 6960 ms），每段结束输出 `--- <name> total <n> ms --- slowest: <stage> <n> ms`；tests/boot-log.test.mjs 另有专项断言（含“快阶段不得被标 SLOW”）。"
    basis: observation
    verification:
      criterionId: C3
      criterionVersion: 1
      method: 实机日志核对 + tests/boot-log.test.mjs
      result: passed
      coverage: 标记、total 与最慢阶段同时在实机日志与单测中被验证
    createdAt: 2026-09-23T15:28:43.586Z
  - id: e11
    kind: verification
    content: C5（一次导出产出报告 + 官方诊断 zip）——仅完成到单元层，未做端到端验收：renderExportReport 的报告渲染有单测（12/12 含该项），但“在项目工具菜单点一次「导出日志与诊断…」→ 同目录出现报告与 dsh-diagnostics-*.zip”这一步需要真实 Electron 对话框（showSaveDialog）与真实点击，尚未执行。
    basis: observation
    verification:
      criterionId: C5
      criterionVersion: 1
      method: 单测（报告渲染）+ 待补的菜单点击端到端
      result: not-run
      coverage: 仅覆盖报告渲染的纯函数层；菜单→对话框→落盘链路未验证
      reason: 导出入口依赖真实 Electron 保存对话框与原生菜单点击，本轮未做端到端点击验收，待装 0.1.9 后人工执行一次。
    createdAt: 2026-09-23T15:28:43.586Z
  - id: e12
    kind: progress
    content: 0.1.9 发布：首次 tag 构建被取消，已用 workflow_dispatch（platform=all / publish=true / replace_existing=true）重发，构建提交 c9b3222（含 reveal 修复），run 35880579416。
    basis: observation
    createdAt: 2026-09-23T15:28:43.586Z
  - id: e13
    kind: verification
    content: C5（一次导出产出报告 + 官方诊断 zip 同目录）——真实 Electron 端到端验收通过：真实启动 → 真实项目窗口 → 真实点击「项目工具 → 导出日志与诊断…」→ 同目录得到报告（6642 B，含 boot 段、project/open 段与 Host 阶段、数据来源、各项目恢复原因）与官方 dsh-diagnostics-*.zip（477 B，含 system-info.txt）。唯一替代物是 macOS 原生保存面板（自动化会话无法驱动），替换点只在 Electron 模块边界，返回值与真实对话框同形。
    basis: observation
    verification:
      criterionId: C5
      criterionVersion: 1
      method: 外部探针经 NODE_OPTIONS=--require 注入真实 Electron 主进程，点击真实菜单项并校验产物
      result: passed
      coverage: 菜单命令 → exportStartupLog → renderExportReport → 官方 exportDiagnosticsZip → 同目录复制 → showItemInFolder 全链路；仅系统保存面板未驱动
    createdAt: 2026-09-24T02:27:47.261Z
  - id: e14
    kind: progress
    content: "发现并修复 0.1.9 引入的用户可见回归：项目 runtime 的官方方法 exportDiagnostics 被改名为 exportLogs，而固定 Host 的 bindNativeRuntime 按名分发 native:exportDiagnostics，官方「导出诊断信息…」一点即抛 TypeError: Cannot read properties of undefined (reading 'apply')；该条目还与壳的「导出日志与诊断…」并列，两个入口写同一份证据。修复（提交 ada96bc）：runtime 恢复官方方法名 exportDiagnostics（行为仍为合并导出），新增 stable/official-tray.mjs 按 group/order/官方文案三者同时匹配丢弃官方重复菜单项（任一不符即保留），新增 tests/desktop-runtime-contract.test.mjs 5 项（从固定 host-runtime-bridge.ts 提取 native:<method> 列表逐个断言，并验证把方法名改回 exportLogs 时测试必失败），更新 architecture/development 文档。真实端到端 8/8：菜单只剩「导出日志与诊断…」，壳入口与官方 renderer action diagnostics 都产出报告 + zip，无错误对话框。"
    basis: observation
    createdAt: 2026-09-24T02:27:47.261Z
  - id: e15
    kind: progress
    content: 环境与遗留：复核时主工作树的 .upstream/project 是旧导出（缺 d45b54f 的两个文件改动，树 dcd0f0e8 ≠ pin f8fe0b42），yarn check 在 verify:upstream 直接失败；已按流程从 pin 重导（树回到 f8fe0b42，verify:upstream 通过，快照被 gitignore 故无提交）。另记录两个未修小瑕疵：(1) scripts/native-smoke-case.mjs:87 对 darwin 上返回 null 的 readTitlebarLocale() 取 .menus，使 probe:startup-trace 在 macOS 上必然 exit 1（其 7 项 trace 检查仍全过）；(2) exportStartupLog 的 trace.event('logs exported') 因 boot 段已 end 而被丢弃，boot.log 不记录导出本身。
    basis: observation
    createdAt: 2026-09-24T02:27:47.261Z
  - id: e16
    kind: progress
    content: 两个小瑕疵已修（提交 4ca44a6）：(1) exportStartupLog 不再往已 end 的 boot 段写事件，而是另开 `export` 段（environment 记 userData，event 记 destination/bytes/diagnostics，结束写 written/failed 与 total），报告的说明段同步补上 export；(2) 标题栏语言检查收进 native-titlebar-checks.mjs 的 checkTitlebarLocale() 并按 DARWIN_SKIP 跳过，native-smoke-case 只留一行调用——此前它直接对 darwin 上返回 null 的 readTitlebarLocale() 取 .menus。验证：worktree yarn check EXIT=0；probe:startup-trace 在 macOS 上 trace 7/7 且冒烟退出码 0（修复前必然 exit 1）；真实 Electron 端到端 11/11，两次导出各留一段 export 追踪；提交后主树 yarn check 再次 EXIT=0。
    basis: observation
    createdAt: 2026-09-24T02:35:06.292Z
operations:
  77c44e0f10e7de935c6d2d8b92c9fa2cc2ab55e3dfab9f05a5244ca3fc0ec452:
    fingerprint: 1847f9a04e6a1e00968de879be9af8a6ca73339fae71a255b68a024f3de43dc4
    kind: create
    at: 2026-09-23T13:44:07.489Z
    entryIds:
      - e1
      - e2
      - e3
      - e4
      - e5
      - e6
  7ca1b8162cb9b573e9275becb55d1b98029afe46ad3dc02d25ba7e1485176ca9:
    fingerprint: 724ec2a9a16db9b05564755f8dc97f8add774b17535c5f83320ad09c42241492
    kind: update
    at: 2026-09-23T14:51:04.026Z
    entryIds:
      - e7
      - e8
  5194fd12c88ff74954e9a932143d579515c24873a03b259fbf8fcd4d3b02b9a7:
    fingerprint: f775777fd4484339eb1f572c685f61eda980154c4134059758ea0a5191bdd4ca
    kind: update
    at: 2026-09-23T15:28:43.586Z
    entryIds:
      - e9
      - e10
      - e11
      - e12
  551299bd702a28edbf9db8481294fa05e2e08fc75dc71b84ceb539709e27b7d7:
    fingerprint: 26bd0ef91b41604d21bab0193fabca1755d21037e132487fb72067844552986e
    kind: update
    at: 2026-09-24T02:27:47.261Z
    entryIds:
      - e13
      - e14
      - e15
  0c58dcd93e34fc12807dc741faf5ba37770c3f9e066044c589e37c1d8889317e:
    fingerprint: 5e672694c63bdbfdd9d27bc6e1424aab4716884f7dde9b6a562eae6ce69928d8
    kind: update
    at: 2026-09-24T02:35:06.292Z
    entryIds:
      - e16
criterionVersions:
  C1: 1
  C2: 1
  C3: 1
  C4: 1
  C5: 1
  C6: 1
---

实现与实机验证全部完成（含 C5），两轮验证期发现的问题也都已修复：src/app/boot-log.mjs 提供显式 trace 对象并写 <userData>/boot.log（常开、≥256 KiB 半量截断、单阶段 ≥1000 ms 标 [SLOW >1000ms]、段落结束给 total 与最慢阶段）；启动/打开项目链路与 Host 进程阶段均已埋点，恢复模式原因并入同段追踪；项目工具菜单的「导出日志与诊断…」一次导出报告 + 官方诊断 zip，每次导出另留一段 export 追踪。本轮复核（2026-09-24，macOS arm64；不声称 Windows 验收）：probe:startup-trace trace 7/7 且冒烟退出码 0、tests/boot-log.test.mjs 12/12、真实 Electron 端到端 11/11、yarn check EXIT=0（两个 worktree 与提交后主树各一次）。修复内容：ada96bc 恢复官方 exportDiagnostics 契约并把菜单合并为唯一导出入口（0.1.9 的改名让官方入口以 undefined.apply 失败）；4ca44a6 让导出自记 export 段，并修掉 macOS 上 probe:startup-trace 必然 exit 1 的标题栏空指针。两个修复都未发布。
