---
schemaVersion: 3
directory: 多会话并发写入约束：提交守卫与 Host 提交通道
id: task-6d4a4a23-411d-4ca0-8dc9-974bfc07227f
title: 多会话并发写入约束：提交守卫与 Host 提交通道
objective: 把「多会话共享工作树」的写入冲突做进产品约束：产出设计文档，定义 C1–C8 约束与其机械强制点，设计 P0 提交守卫、P1 Host 模型提交通道、P2 可见性提示与 P3 代码仓库可选 worktree（含项目资产仓库永久排除的理由与宿主改造点）。
status: active
createdAt: 2026-09-23T08:41:10.805Z
updatedAt: 2026-09-23T09:06:44.828Z
artifacts:
  - type: file
    path: artifacts/hook-deny-probe.mts
    description: 最小验证脚本：用 dsh-agent-loop-testkit 挂真实工具运行时，注册假写工具，分别用 guard 与 tools/pre-execute 拒绝
  - type: file
    path: artifacts/hook-deny-probe.log
    description: 探针输出：guard 拒绝时工具体未执行（body ran 不变）；ask 无审批服务时降级为拒绝；disposer 释放后恢复
  - type: commit
    repository: https://github.com/admintertar/dsh-plugin-project.git
    commit: c353f52dc7839b102b759aeb66f7b47b1970912c
    description: 设计文档提交：resources/dsh-plugin-project docs/session-concurrency.md（292 行，含实测结论与复用评估）
archived: false
phase: design
brief:
  currentBehavior: 多个 Agent 会话共享同一物理工作树，且都能执行任意 git 命令。Host 侧已有仓库级串行锁（lockRepository，按 git-common-dir）、预暂存拒绝（git-index-dirty）、revision 校验与 task 写锁，但这些只在面板/API 通道生效；Agent 用裸 git 提交时全部绕过，导致 A 提交范围污染、B 他人未提交改动被覆盖、C 同分支提交交错。同时模型没有任何提交通道（task/memory 有工具，资源与项目资产提交只有 HTTP 路由与 UI）。
  scope: 沉淀 docs/session-concurrency.md：产品约束 C1–C8、四层机制（P0 提交守卫、P1 Host 提交通道、P2 可见性、P3 代码仓库可选 worktree）、接口草案与分阶段验收；为后续实现提供拍板基础。
  constraints:
    - 仅出设计文档，本轮不实现代码
    - 不改官方源码快照；插件文档留在 dsh-plugin-project，壳侧改动点只做描述
    - 约束必须可机械检查，不接受仅靠 Agent 自觉的条款
  outOfScope:
    - 本轮不做代码实现（P0–P3 均未开始）
    - 不设计每会话 clone 方案
    - 不修改官方 Desktop/Harness 快照
  acceptanceCriteria:
    - id: d1
      text: 设计文档覆盖：三类冲突定性（提交范围污染 / 他人改动被覆盖 / 提交交错）、现有机制盘点（带代码定位）、产品约束条目（每条含强制点与违反行为）、P0–P3 机制设计、接口草案、分阶段验收标准与风险。
      required: true
      version: 1
    - id: d2
      text: worktree 方案给出明确取舍：项目资产仓库（tasks/skills/memory/mcp/index.yaml）永久排除；代码仓库若采用需同时给出归并责任、工装成本与宿主改造点（壳 fork Host 的 cwd、插件 session-capabilities 的 cwd 校验）。
      required: true
      version: 1
    - id: d3
      text: 每条约束都指定了机械强制点（提交守卫 / Host 通道 / UI 可见性），不依赖 Agent 自觉；守卫被设计为唯一提交入口而不是可被 --no-verify 绕过的 hook。
      required: true
      version: 1
    - id: d4
      text: 列出实现前必须拍板的未决问题（提交 trailer、锁粒度、Windows 锁语义、项目资产提交语义）。
      required: true
      version: 1
handoff:
  nextSteps:
    - taskworktree
    - doc
  readBefore:
    - doc
    - hazards
  verifyBefore:
    - guard
references:
  - id: doc
    label: 设计文档：多会话并发写入约束
    type: file
    path: resources/dsh-plugin-project/docs/session-concurrency.md
  - id: lock
    label: 仓库级串行锁（按 git-common-dir）
    type: file
    path: resources/dsh-plugin-project/src/resource-sync.ts
  - id: toollock
    label: 跨 Host 排他锁实现
    type: file
    path: resources/dsh-plugin-project/src/task-lock.ts
  - id: session
    label: 会话 cwd 硬校验（worktree 障碍）
    type: file
    path: resources/dsh-plugin-project/src/session-capabilities.ts
  - id: shellhost
    label: 壳 fork Host 时 cwd 固定为 projectRoot
    type: file
    path: resources/dsh-project-desktop/src/desktop-adapter/index.mjs
  - id: cc-worktrees
    label: Claude Code：worktree 并行会话
    type: url
    url: https://code.claude.com/docs/en/worktrees
  - id: hazards
    label: 社区 worktree 危害清单
    type: url
    url: https://github.com/laurigates/claude-plugins/blob/main/agent-patterns-plugin/skills/parallel-agent-dispatch/references/worktree-hazards.md
  - id: jump
    label: dsh-worktree-jump（fork 到 worktree）
    type: url
    url: https://github.com/frederico-kluser/dsh-worktree-jump
  - id: taskworktree
    label: dsh-task-worktree（任务级 worktree）
    type: url
    url: https://github.com/Letter2025/dsh-task-worktree
  - id: guard
    label: deepseek-harness-security-guard（pre-execute + guard 范本）
    type: url
    url: https://github.com/SparkShieldLab/deepseek-harness-security-guard
  - id: conductor
    label: Conductor：Git worktrees 概念
    type: url
    url: https://www.conductor.build/docs/concepts/git-worktrees
entries:
  - id: e1
    kind: decision
    content: 用户选择推进 L1（提交守卫）+ L2（提交收回 Host 通道），并要求「做进产品约束」而不是仅写技能；本轮先出设计文档再实现。
    basis: user-request
    createdAt: 2026-09-23T08:41:10.805Z
  - id: e2
    kind: progress
    content: "调研发现关键约束：插件 session-capabilities.ts 硬校验 observation.header.cwd !== root 即 404，壳 desktop-adapter/index.mjs 以 cwd: projectRoot fork 每项目一个 Host —— 会话级工作目录（worktree per session）需要宿主改造，不是 Agent 能自立目录解决的。"
    basis: observation
    createdAt: 2026-09-23T08:41:10.805Z
  - id: e3
    kind: progress
    content: 现有可复用的机制（均已具备但仅在 Host 通道生效）：resource-sync.ts 的 lockRepository（锁 key = git rev-parse --git-common-dir，注释已明确为 linked worktree 共享 refs 设计）、commitProjectSelection 的 git-index-dirty 拒绝与 assertRevision、task-lock.ts 的 withTaskWriteLock（PID/hostname 存活检测 + 陈旧锁回收 + 模糊所有权不接管）。缺口是模型没有提交通道且 ResourceSyncManager 只在 resource-api 内部创建。
    basis: observation
    createdAt: 2026-09-23T08:41:10.805Z
  - id: e4
    kind: progress
    content: 设计文档已写入 resources/dsh-plugin-project/docs/session-concurrency.md：结论摘要、问题定义（A/B/C）、现状盘点、C1–C8 产品约束（含强制点与违反行为）、P0 提交守卫/P1 Host 工具/P2 可见性/P3 worktree、接口草案、分阶段验收与风险清单。
    basis: observation
    createdAt: 2026-09-23T08:41:10.805Z
  - id: e5
    kind: progress
    content: 生态调研结论：DSH 官方无 worktree 能力（node_modules/@deepseek-ai 全量 grep worktree 零命中），但已有社区实现：dsh-worktree-jump（新会话界面按钮 → agents.create + meta.cwd fork 到 worktree，实证 session.header.cwd 冻结、无法原地切目录）、dsh-task-worktree（任务级 worktree；worktree_create/list/status 为模型工具，finish/bring-back/remove 人类专属；不切 cwd，模型用绝对路径，会话头打 branch badge；per-repo manifest 跨重启）、dsh-worktree（Codex 风格工具化）、dsh-plugin-worktrees。
    basis: observation
    createdAt: 2026-09-23T08:48:54.923Z
  - id: e6
    kind: progress
    content: "官方扩展点调研（seam 名称取自实际实现，被 deepseek-harness-security-guard 使用）：tools/pre-execute、tools/post-execute、tools/result、ctx.tools.guard()（deny-only）、agent/pre-step、agent/turn-stopping、agent/session-start、subagent/start|end；决策 allow/ask/block/warn，ask 走 harness 原生审批服务；dsh-hook-protocol + dsh-hooks-claude-code|-codex 桥（PreToolUse 含 permissionDecision: allow/deny/ask）；dsh-permission-presets、dsh-sandbox-policy、workspaceRegistry。外部教训：Claude Code 多代理社区的 worktree hazards（cwd 漂移、GIT_DIR 泄漏、嵌套仓库、共享路径冲突、worktree 被删、分支预检、远端静默降级）；业界产品化形态是 isolation: worktree 作为 dispatch 参数由 harness 建工作树，而非让模型敲 git。"
    basis: observation
    createdAt: 2026-09-23T08:48:54.923Z
  - id: e7
    kind: progress
    content: 文档已扩写 docs/session-concurrency.md：§0 增加第 5 条（cwd 冻结 → 只能 fork 或不切 cwd + 强制点用 pre-execute/guard）；新增 §2.5 DSH 可挂载点与生态先例（官方扩展点表 + 四个生态插件表）；§4.4 重写为「P3 隔离模式：把自动 worktree 做进产品」（形态 A fork / 形态 B 不切 cwd，含触发判定、强制点、目标仓库、人类专属动作、模型侧规则、工装成本）；§6 P3 行给出可验收场景；§7 新增「社区实测 worktree 危害与本项目映射」表；§8 补外部参考链接。
    basis: observation
    createdAt: 2026-09-23T08:48:54.923Z
  - id: e8
    kind: verification
    content: 实测（探针，真实 runtime）：无守卫时工具执行成功；ctx.tools.guard() 返回理由时 isError:true 且工具体未执行；disposer 释放后恢复；tools/pre-execute 返回 {kind:'ask'} 而无审批服务时同样 isError:true（fail-closed）。脚本与输出：artifacts/hook-deny-probe.mts / .log。
    basis: observation
    verification:
      criterionId: d3
      criterionVersion: 1
      method: native runtime probe：dsh-agent-loop-testkit mountAgentLoopTestDependencies + dsh-tools defineTool/guard + tools/pre-execute
      result: passed
      coverage: 覆盖：DSH 拒绝链路可行（guard 拒绝、ask 缺审批降级为拒绝、disposer 可释放、工具体确实未执行）。未覆盖：P0–P3 机制本身（均未实现）。
    createdAt: 2026-09-23T08:58:34.882Z
  - id: e9
    kind: decision
    content: 实测发现的硬边界：tools/pre-execute 的 PreToolDecision 只有 allow/deny/ask，官方注释明确 arguments are already logged and presented —— 不能改写工具输入。因此产品无法把一次 Edit 自动重定向进 worktree；强制只能是「拒绝 + 指引模型先建工作树」，或走形态 A（fork 会话，使路径天然在 worktree 内）。已写入文档 §2.5 与 §4.4 第 8 条。
    basis: observation
    createdAt: 2026-09-23T08:58:34.882Z
  - id: e10
    kind: decision
    content: 复用评估结论（读 dsh-task-worktree 0.4.2 源码后）：不采用直接依赖，仅借鉴设计；P3 落地时小范围 fork ≈4–5 人日。阻断项：① peer @deepseek-ai/*:^0.1.2-rc.1 与本机 0.1.5-rc.2 实测不匹配（预发布语义），dsh plugin add 转发 pnpm（auto-install-peers 默认 true）会装出第二份 harness → 破坏 TOOL_RUNTIME_SCHEDULER unique symbol、工具全失效；② 无仓库排除概念，会在项目根建 worktree 并向 .gitignore 追加 .dsh-worktrees/（撞 git-index-dirty 拒绝）；③ 仓库只由会话 cwd 推导（resolveCwd），根会话无法为 resources 下仓库建 worktree；④ finish/bring-back 走裸 git add -A && git commit / git merge --no-ff，绕开 Host 资源通道；⑤ 人类专属仅是命令面分离，模型可用 bash 绕过，机械点必须靠 ctx.tools.guard()。借鉴项：per-repo manifest + tmp/rename 原子写 + 按 git worktree list --porcelain prune、.git/info/exclude 而非 .gitignore、不切 cwd 用绝对路径、会话头 branch badge、人类命令面 vs 最小模型工具面、manifest 无跨进程锁需补。补充洞见：worktree 的独立 index 天然消除多会话 index 撞车，P3 与 P0/P1 互补而非替代。对比：FlashingChen/dsh-worktree 把 worktree_remove 暴露为模型工具且真装 @deepseek-ai/*；frederico-kluser/dsh-worktree-jump npm 404/private/node≥24/需构建且形态相反。已写入文档 §2.5 复用评估小节、§6 P3 工作量、§7 peer 版本风险。
    basis: observation
    createdAt: 2026-09-23T09:00:23.263Z
  - id: e11
    kind: progress
    content: 设计文档已提交到插件仓库：c353f52dc7839b102b759aeb66f7b47b1970912c（docs/session-concurrency.md，292 行，1 file changed，未 push）。提交前 index 干净、只 add 该路径、提交后 status 干净。
    basis: observation
    createdAt: 2026-09-23T09:06:44.828Z
operations:
  e7bbed9a116c44b0122a51d067bb115b43671f151ce73d1a502a8b3187425535:
    fingerprint: 039f3394cfffbcb9cbe7bb93b7f64ca3165264bd329f3c739509e1685eb66cad
    kind: create
    at: 2026-09-23T08:41:10.805Z
    entryIds:
      - e1
      - e2
      - e3
      - e4
  fb2de43af8a0541f2e0d24d18f7b0c6326230c025dafe35374f3c6913727aa01:
    fingerprint: 041ddca78352b9b443cbd1b08ff8611dd06f34efeab43d7f8d3d7f012bf1e7ce
    kind: update
    at: 2026-09-23T08:48:54.923Z
    entryIds:
      - e5
      - e6
      - e7
  2cec1d0eb70d40631a39e305ccfdfb46ddeba75c95caa278056143563c61f3cf:
    fingerprint: 98936c7855b486ab9412b4cd97d8d309ffe74fb27bdf50a8d94d120eea98e871
    kind: update
    at: 2026-09-23T08:58:34.882Z
    entryIds:
      - e8
      - e9
  5914a503ccb2fc30ea36079889406bcf63b42ca6363e40c3b5249d81479f9edf:
    fingerprint: 583c66f8fc18e4f8c06f74df72a3cac231d936c295cf51f54034f5264048c580
    kind: update
    at: 2026-09-23T09:00:23.263Z
    entryIds:
      - e10
  106a516b9d1e4c3bad19510658001001c7d7e0d197976b20b279a30d6216fa6a:
    fingerprint: 6235676c75828933d753bf497ee03f018d35eb43ec09305c5acbf280c85969a5
    kind: update
    at: 2026-09-23T09:06:44.828Z
    entryIds:
      - e11
criterionVersions:
  d1: 1
  d2: 1
  d3: 1
  d4: 1
---


