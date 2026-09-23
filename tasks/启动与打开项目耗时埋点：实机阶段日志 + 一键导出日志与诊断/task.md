---
schemaVersion: 3
directory: 启动与打开项目耗时埋点：实机阶段日志 + 一键导出日志与诊断
id: task-3ee98604-d1e5-423e-b4e8-d421519c84dc
title: 启动与打开项目耗时埋点：实机阶段日志 + 一键导出日志与诊断
objective: 让“Windows 启动卡二三十秒”“打开项目有时也慢”这类实机延迟可以被定位到具体阶段：在主进程启动链路、打开项目链路与 Host 进程内部加入常开的分阶段时间戳追踪并落到 userData/boot.log；把恢复模式原因并入同一份证据；在项目工具菜单提供一个导出入口，产出可直接发送的“日志 + 官方诊断包”分析材料。
status: active
createdAt: 2026-09-23T13:44:07.489Z
updatedAt: 2026-09-23T13:44:07.489Z
artifacts: []
archived: false
phase: implementation
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
references: []
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
criterionVersions:
  C1: 1
  C2: 1
  C3: 1
  C4: 1
  C5: 1
  C6: 1
---

已实现并实机验证：src/app/boot-log.mjs 提供显式 trace 对象（stage/event/measure/end），写 <userData>/boot.log，默认常开、按 256 KiB 半量截断、单阶段 ≥1000 ms 打 [SLOW >1000ms]、段落结束给 total + 最慢阶段；DSH_PROJECT_BOOT_LOG 改路径（空串关闭）、DSH_PROJECT_BOOT_TRACE=1 同时打 stdout、DSH_PROJECT_BOOT_LOG_BYTES 改保留预算。启动链路埋点覆盖 run() 入口/清理/主题/ready/更新服务/托盘菜单/工作区恢复/欢迎窗口；打开项目链路覆盖 open() 请求与项目文件解析、workspace.open、createProject、Host 监督（profile 选择、官方 rpc 模块、代理解析、fork、ready、boot RPC、渲染 URL 认证）、建窗/渲染认证/loadURL 与健康上报/检查点/聚焦。Host 内部通过 DSH_PROJECT_BOOT_LOG_FILE + DSH_PROJECT_BOOT_SESSION 复用同一段 trace，覆盖 boot 请求、Profile 准备（含 pnpm 依赖实体化的独立计时）、官方 Host 启动、渲染进程注册。恢复模式原因在写 recovery-events.jsonl 的同时记入该次 trace。项目工具菜单“导出日志与诊断…”复用官方 diagnostics 动作：写报告（环境/数据来源/追踪全文/各项目恢复原因）+ 复制项目官方诊断 zip 到同目录并在文件管理器定位；失败复用官方 diagnosticsErrorTitle/ErrorMessage 文案。
