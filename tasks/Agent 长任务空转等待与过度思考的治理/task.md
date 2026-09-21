---
schemaVersion: 3
directory: Agent 长任务空转等待与过度思考的治理
id: task-4feb1d61-e74f-4845-940c-027ed3d9cbe2
title: Agent 长任务空转等待与过度思考的治理
objective: 治理两类 Agent 效率缺陷：(1) 盲等后台作业（job_output 空转）与管道掩盖退出码，(2) 过度思考（单 turn 步数无上限）。给出量化证据、落地行为约定，并设计机械拦截方案与评估第三方 turn-budget-guard，供后续排期实现。
status: active
createdAt: 2026-09-21T10:01:00.558Z
updatedAt: 2026-09-21T10:01:24.523Z
artifacts: []
archived: false
phase: investigation
brief:
  currentBehavior: Agent 在长任务上会盲等后台作业：`job_output wait:true` 对无输出作业反复等待，单次最长 600 秒，历史 20 个会话累计 173.9 分钟；同时习惯用 `cmd 2>&1 | tail -N` 收尾，既隐藏增量输出又隐藏真实退出码。另一类是过度思考：单 turn 步数无上限，实测最大 147 步，且写完文件后平均还要 6.9 步（最多 42 步）做验证。
  scope: 记录两类 Agent 效率缺陷的量化证据与机制、落地行为约定、设计机械拦截方案并评估第三方 turn-budget-guard，供后续排期实现。
  constraints:
    - 本轮不改运行中的 Profile、不装第三方插件、不改模型设置
    - 任何机械拦截方案必须基于宿主公开 API（tools/pre-execute / ToolRuntime.guard），不依赖内部实现
  outOfScope:
    - 实现 guard 插件（本轮只记录方案）
    - 在 Profile 中挂载 turn-budget-guard
    - 修改 reasoningEffort 等模型设置
    - 修复壳测试挂起（已单独建 task-bf50c979）
  acceptanceCriteria:
    - id: ac1
      text: 量化证据链：空转时长、管道命令数、退出码掩盖次数、单 turn 步数分布
      required: true
      version: 1
    - id: ac2
      text: 行为约定落地到 memory/working-agreements.md 并被会话自动加载
      required: true
      version: 1
    - id: ac3
      text: 机械拦截方案（tools/pre-execute）与 turn-budget-guard 评估可供后续排期
      required: true
      version: 1
handoff:
  nextSteps:
    - 观察 memory/working-agreements.md 新增章节的实际约束效果；若空转等待复发，排期实现 tools/pre-execute 机械拦截（见 eff-3）
    - 若决定治理过度思考：先取得改 Profile 的明确授权，再在 profiles/desktop/cordis.patch.yml 挂载 turn-budget-guard 并按 maxSteps 40 / gracefulSteps 12 / maxFires 3 调参
    - 可选独立杠杆：settings.yaml 的 reasoningEffort 目前为 xhigh，可试下调后对比单 turn 步数分布
  readBefore:
    - file-memory
    - note-guard-design
    - note-budget-guard
  verifyBefore:
    - note-verify-eff
references:
  - id: file-memory
    label: 已落地的行为约定（每会话自动加载）
    type: file
    path: memory/working-agreements.md
  - id: note-mechanism
    label: tail 缓冲机制与实测对照
    type: note
    text: '`cmd | tail -N` 的 tail 必须读到 EOF 才能确定最后 N 行，因此后台运行时零增量输出，job_output 只会一直返回 (no new output) [status: running]。对照实验（本会话实测）：两个同样打印 12 行、跑 30 秒的作业，8 秒后轮询——带 `| tail -3` 无输出，不带 tail 的对照组正常流出 tick-1..12。退出码：管道退出码是 tail 的 0，故 `cmd | tail -30` 即使失败也报成功；正确写法是 `cmd 2>&1 | tail -30; echo "EXIT=${PIPESTATUS[0]}"`，或后台时改为 `cmd > /tmp/x.log 2>&1; echo "EXIT=$?"` 并另起前台调用 tail 读日志。'
  - id: note-metrics
    label: 量化口径（可复现）
    type: note
    text: 会话日志位于 $DSH_HOME/sessions/<workspace>/session-*/session.v3.jsonl.zstd，为 append-only 多帧 zstd，Node 内置 zstdDecompressSync 只解第一帧，需分帧后逐帧解压。统计口径：job_output 结果文本含 "(no new output)" 或 "wait aborted" 的调用计为一次空转，其 elapsed = 该 tool/result 时间戳 - 对应 tool/call 时间戳。turn 步数取 step/end 事件按 turn 计数。
  - id: note-guard-design
    label: 机械拦截设计（未实现）
    type: note
    text: "宿主公开 API：tools/pre-execute 是瀑布事件，返回 PreToolDecision = {kind:'allow'} | {kind:'deny', reason} | {kind:'ask', reason?}；ToolRuntime 另有 guard(guard: (exec)=>string|undefined)。注意两者都只能 allow/deny/ask，不能改写命令参数。拟拦截三条：(a) bash 且 run_in_background===true 且命令匹配 /\\|\\s*(tail|head)/ → deny，reason 给出落盘写法；(b) job_output 且 wait===true 且 timeout_ms>120000 → deny；(c) 同一 job_id 连续两次无新输出 → deny 并提示 job_list → 读落盘日志 → ps → job_kill。动态 Cordis 插件仅存活于当前进程，跨会话需装进 Profile。"
  - id: note-budget-guard
    label: turn-budget-guard 评估
    type: note
    text: "@argszero/cordis-plugin-turn-budget-guard 0.1.1（npm 可获取）。兼容：peer range 覆盖本机 dsh 0.1.5-rc.2。机制：监听公开 agent/pre-step 瀑布，step 即循环自身计数器；超预算注入可归属的 wrap-up user/message（source.kind:'plugin'），再 agent.cancel(cause,{keepInbox:true})；用户中途插话会 rebase 预算。默认 maxSteps 20 / gracefulSteps 8 / maxFires 2。局限：pre-step 只在两步之间触发，无法中断卡在 job_output wait 里的 turn，因此不解决空转等待。挂载：在 $DSH_HOME/profiles/desktop/cordis.patch.yml 插入一行（属禁止事项，需明确授权）。"
  - id: note-verify-eff
    label: 验证方式
    type: note
    text: 行为约定生效：新会话的 project reference material 中应出现「长任务与后台作业（禁止空转等待）」章节。机械拦截若实现：构造 run_in_background + `| tail` 的 bash 调用应被 deny 并返回落盘写法；构造 timeout_ms=600000 的 job_output 应被 deny。统计口径见 note-metrics，可重算 eff-1 的数字核对。
  - id: url-guard
    label: turn-budget-guard 仓库
    type: url
    url: https://github.com/argszero/cordis-plugin-turn-budget-guard
entries:
  - id: eff-1
    kind: progress
    content: 量化证据（解压全部 20 个会话日志统计）：job_output 返回「无新输出」共 38 次，累计等待 173.9 分钟（10432 秒）；最长单作业空转 48.9 分钟（session-2d5c8869，`npm run check 2>&1 | tail -80`，同命令正常仅 ~35 秒）。管道进 tail/head 的 bash 调用 96 条，其中未捕获真实退出码的 875 条（历史后台作业创建共 100 次）；36 次报 exit 0 但输出里实际是失败。过度思考：82 个 turn 步数中位数 13、均值 23.3、p90 56、最大 147，6 个 turn 超过 60 步；写完文件后平均再花 6.9 步（最多 42 步）做验证。
    basis: observation
    reason: 把主观感受换成可核对的量化证据
    createdAt: 2026-09-21T10:01:00.558Z
  - id: eff-2
    kind: progress
    content: '根因与实测对照：`cmd | tail -N` 中的 tail 必须读到 EOF 才能确定最后 N 行，所以后台运行时永远不产生增量输出。对照实验：两个同样打印 12 行、跑 30 秒的作业，8 秒后轮询——带 `| tail -3` 的返回 `(no new output) [status: running]`，不带 tail 的对照组正常流出 tick-1..12。同时管道退出码是 tail 的 0，掩盖真实失败。日志显示 agent 曾自己补 `echo "[exit ${PIPESTATUS[0]}]"` 绕过，但只是偶发。'
    basis: observation
    reason: 区分机制与巧合，避免把现象当根因
    createdAt: 2026-09-21T10:01:00.558Z
  - id: eff-3
    kind: decision
    content: 机械拦截设计（待排期，未实现）：宿主有公开的 tools/pre-execute 瀑布事件（可 allow/deny/ask）与 ToolRuntime.guard()，可机械阻止复发——(a) bash 且 run_in_background===true 且命令匹配 `\|\s*(tail|head)` 时 deny，reason 直接给出落盘写法；(b) job_output 且 wait===true 且 timeout_ms 超过阈值（如 120000）时 deny；(c) 同一 job_id 连续两次返回无新输出时 deny 并提示按卡死处理（job_list → 读落盘日志 → ps → job_kill）。注意 pre-execute 只能 allow/deny/ask，不能改写命令；要自动改写需自注册替代工具。
    basis: agent-proposal
    reason: 规则会被忽略，拦截不会；但先记录不实现
    createdAt: 2026-09-21T10:01:00.558Z
  - id: eff-4
    kind: progress
    content: turn-budget-guard 评估（@argszero/cordis-plugin-turn-budget-guard，npm 上 0.1.1）：peer range 覆盖本机 dsh 0.1.5-rc.2，可直接安装；机制干净，只监听公开的 agent/pre-step 瀑布，超预算先注入一条可归属（source.kind:'plugin'）的 wrap-up 消息，再 agent.cancel(cause,{keepInbox:true})，用户中途插话会重设预算。局限：pre-step 只在两步之间触发，agent 卡在 job_output wait:true 时它不会介入，因此它治过度思考、不治空转等待（后者才是 173.9 分钟的主因）。风险：默认 maxSteps 20 / gracefulSteps 8 / maxFires 2 会砍掉实测 6 个 >60 步的 turn（含 147 步那次跨文件重构），需调参（如 40/12/3）。挂载点：$DSH_HOME/profiles/desktop/cordis.patch.yml，属于项目禁止事项「重写运行中的 Profile」，未获授权不得执行。
    basis: observation
    reason: 回答用户「这个仓库有没有可以使用的地方」
    createdAt: 2026-09-21T10:01:00.558Z
  - id: ver-eff-ac1
    kind: verification
    content: ac1 已验证：解压全部 20 个会话日志（分帧 zstd）统计得出——job_output 无输出等待 38 次 / 累计 173.9 分钟 / 最长单作业 48.9 分钟；管道进 tail/head 96 条，未捕获真实退出码 875 条，36 次报成功实为失败；82 个 turn 步数中位数 13 / p90 56 / 最大 147，写完文件后平均再花 6.9 步验证。统计口径见 note-metrics，可复算。
    basis: observation
    verification:
      criterionId: ac1
      criterionVersion: 1
      method: 解压 $DSH_HOME 下 20 个 session.v3.jsonl.zstd（append-only 多帧，分帧后逐帧解压）并统计 tool/call、tool/result、step/end 事件
      result: passed
      coverage: 全部量化结论均来自会话日志实测，非估算；口径已写入 note-metrics 供重算
    createdAt: 2026-09-21T10:01:24.523Z
  - id: ver-eff-ac2
    kind: verification
    content: ac2 已验证：memory/working-agreements.md 新增「长任务与后台作业（禁止空转等待）」章节（6 条硬规则 + 根因说明），且该文件在 manifest 的 memory[] 中声明，已确认出现在当前会话的 project reference material 里，即跨会话自动加载生效。
    basis: observation
    verification:
      criterionId: ac2
      criterionVersion: 1
      method: 检查 memory/working-agreements.md 内容，并核对新会话上下文快照的 project reference material 是否包含该章节
      result: passed
      coverage: 仅验证约定已被加载；其实际约束效果需后续会话观察（见 handoff.nextSteps 第 1 项）
    createdAt: 2026-09-21T10:01:24.523Z
  - id: ver-eff-ac3
    kind: verification
    content: ac3 已验证：机械拦截方案已依据宿主公开 API 写成（tools/pre-execute 返回 PreToolDecision allow/deny/ask，ToolRuntime.guard()；两者均不能改写参数）并记录为 note-guard-design 与 entry eff-3；turn-budget-guard 已核对 npm 版本 0.1.1、peerDependencies 覆盖本机 dsh 0.1.5-rc.2、并读完 src/guard.ts 确认真实机制与 pre-step 的介入边界，结论记录为 note-budget-guard 与 entry eff-4。
    basis: observation
    verification:
      criterionId: ac3
      criterionVersion: 1
      method: cordis_inspect_query 查 tools/pre-execute 契约与 ToolRuntime 声明；npm view 与 git clone 读 turn-budget-guard 的 package.json、README、src/guard.ts
      result: passed
      coverage: 仅完成方案与评估，未实现、未挂载；实现需单独授权（改 Profile 属项目禁止事项）
    createdAt: 2026-09-21T10:01:24.523Z
operations:
  851143721d30906c06ba7610b6d4b0ef2690015e1fed429619123beaa19791f2:
    fingerprint: 7efb866d805fac9e0c46167ee30d24a8661474dbe267f390dba4fc81b5bf41fa
    kind: create
    at: 2026-09-21T10:01:00.558Z
    entryIds:
      - eff-1
      - eff-2
      - eff-3
      - eff-4
  1931ae93ab8a372138d374d1f218ea98be3e2ff66a5f531ccb087c1b9a403af3:
    fingerprint: cab36d570dc41470733f67ebebea9fe6d330bae140ff5b6b3b94a6d0c23afb33
    kind: update
    at: 2026-09-21T10:01:24.523Z
    entryIds:
      - ver-eff-ac1
      - ver-eff-ac2
      - ver-eff-ac3
criterionVersions:
  ac1: 1
  ac2: 1
  ac3: 1
---


