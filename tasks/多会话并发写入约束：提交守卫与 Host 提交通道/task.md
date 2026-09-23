---
schemaVersion: 3
directory: 多会话并发写入约束：提交守卫与 Host 提交通道
id: task-6d4a4a23-411d-4ca0-8dc9-974bfc07227f
title: 多会话并发写入约束：提交守卫与 Host 提交通道
objective: 把「多会话共享工作树」的写入冲突做进产品约束：产出设计文档，定义 C1–C8 约束与其机械强制点，设计 P0 提交守卫、P1 Host 模型提交通道、P2 可见性提示与 P3 代码仓库可选 worktree（含项目资产仓库永久排除的理由与宿主改造点）。
status: active
createdAt: 2026-09-23T08:41:10.805Z
updatedAt: 2026-09-23T09:53:08.220Z
artifacts:
  - type: file
    path: artifacts/hook-deny-probe.mts
    description: 最小验证脚本：用 dsh-agent-loop-testkit 挂真实工具运行时，注册假写工具，分别用 guard 与 tools/pre-execute 拒绝
  - type: file
    path: artifacts/hook-deny-probe.log
    description: 探针输出：guard 拒绝时工具体未执行（body ran 不变）；ask 无审批服务时降级为拒绝；disposer 释放后恢复
  - type: file
    path: artifacts/dsh-second-pass-research.md
    description: DSH 第二轮调研：官方 0.1.5-rc.2/rc.3/0.1.7-alpha.2 与主分支、官方文件 CAS/沙箱边界、社区插件复核，以及 linked worktree 形态 A/B 的真实 Seatbelt 探针
  - type: commit
    repository: https://github.com/admintertar/dsh-plugin-project.git
    commit: c353f52dc7839b102b759aeb66f7b47b1970912c
    description: 设计文档首版提交：docs/session-concurrency.md（292 行）
  - type: commit
    repository: https://github.com/admintertar/dsh-plugin-project.git
    commit: 5193e8135fa0b27fc43d0a71a0072f3304a02090
    description: 设计文档第二轮修订提交：纳入文件 CAS/沙箱边界、A/B 探针与 P0 定位修正，并完成 §0/§2.5 结构整理
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop-development.git
    commit: 0f937b0970dc27594104aafa8397608d954c1bcc
    description: 项目根提交：task.md（第二轮调研记录、记录修复、验收标准 v2）与 artifacts/dsh-second-pass-research.md
archived: false
phase: design
brief:
  currentBehavior: 多个 Agent 会话共享同一物理工作树，且都能执行任意 git 命令。Host 侧已有仓库级串行锁（lockRepository，按 git-common-dir）、预暂存拒绝（git-index-dirty）、revision 校验与 task 写锁，但这些只在面板/API 通道生效；Agent 用裸 git 提交时全部绕过，导致 A 提交范围污染、B 他人未提交改动被覆盖、C 同分支提交交错。第二轮官方源码与真实沙箱调研进一步确认：包装式提交守卫不是安全边界（tools/pre-execute 看不到脚本/子进程效果），且形态 A 下 linked worktree 的 common-dir 在沙箱根外、Agent 无法写 Git metadata，形态 B 下裸 git add 仍可成功。
  scope: 沉淀 docs/session-concurrency.md：产品约束 C1–C8、机制分层（P0 可信提交执行器 + 真正的进程/沙箱强制边界、P1 Host 提交通道、P2 可见性、P3 隔离模式）、接口草案与分阶段验收；并纳入第二轮官方源码/沙箱调研结论（文件 CAS 可复用、裸 Git 需进程边界、形态 A/B 的真实 Seatbelt 探针差异）。
  constraints:
    - 仅出设计文档，本轮不实现代码
    - 不改官方源码快照；插件文档留在 dsh-plugin-project，壳侧改动点只做描述
    - 约束必须可机械检查，不接受仅靠 Agent 自觉的条款
    - 必须区分「可信提交执行器」与「不可绕过的安全边界」，不得用可被 --no-verify 或裸 git 绕过的包装命令冒充后者
  outOfScope:
    - 本轮不做代码实现（P0–P3 均未开始）
    - 不设计每会话 clone 方案
    - 不修改官方 Desktop/Harness 快照
  acceptanceCriteria:
    - id: d1
      text: 设计文档覆盖：三类冲突定性（提交范围污染 / 他人改动被覆盖 / 提交交错）、现有机制盘点（带代码定位）、产品约束条目（每条含强制点与违反行为）、P0–P3 机制设计、接口草案、分阶段验收标准与风险。
      required: true
      version: 2
    - id: d2
      text: worktree 方案给出明确取舍：项目资产仓库（tasks/skills/memory/mcp/index.yaml）永久排除；代码仓库须给出归并责任、工装成本与宿主改造点，并基于真实沙箱探针给出形态 A（会话 cwd = linked worktree）与形态 B（不切 cwd）的适用边界。
      required: true
      version: 2
    - id: d3
      text: 每条约束的机械强制点必须落在进程/沙箱边界（Agent 进程不能写 Git metadata、Host 在沙箱外提交），而不是提示词或可被绕过的包装命令；文档须区分「可信提交执行器」与「不可绕过的唯一入口」，并给出 protected-path 沙箱与形态 A 二选一的落地方案。
      required: true
      version: 2
    - id: d4
      text: 列出实现前必须拍板的未决问题（提交 trailer、锁粒度、Windows 锁语义、项目资产提交语义，以及 protected-path 沙箱与强制 fork 的取舍）。
      required: true
      version: 2
questions:
  - d3 已升为 v2：现有证据 e8（拒绝链路探针）与 e13（A/B 沙箱探针）均为 v1 时代提交，实现前需针对 v2 的「进程/沙箱边界」补新证据
  - 需拍板：走 protected-path 沙箱扩展（macOS Seatbelt / Linux bwrap-Landlock / Windows ACL）还是强制 fork 到形态 A；两者工作量都超出原 4–5 人日估算
  - 文档在插件仓库内用 tasks/... 相对路径引用项目根 artifact，读者需知道基准是项目根；如需可改为项目根相对说明或绝对引用
handoff:
  nextSteps:
    - research
    - doc
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
  - id: research
    label: DSH 第二轮调研与 Seatbelt A/B 探针记录
    type: file
    path: tasks/多会话并发写入约束：提交守卫与 Host 提交通道/artifacts/dsh-second-pass-research.md
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
  - id: e12
    kind: decision
    content: 第二轮官方源码调研修正 P0：commit-guard 只能定位为可信提交执行器，不能仅凭包装命令宣称唯一入口；tools/pre-execute 只能检查外层工具参数，无法证明任意脚本/子进程的最终文件效果。真正的强制边界必须是 Agent 进程不能写 Git metadata，Host 在沙箱外持有提交通道；命令规则只做纵深防御。
    basis: observation
    createdAt: 2026-09-23T09:29:36.000Z
  - id: e13
    kind: verification
    content: 真实 DSH 0.1.5-rc.2 LocalSandboxProvider/macOS Seatbelt 探针：形态 A（session cwd=linked worktree）中源码写成功，但 git add/commit 因 common-dir index.lock 在沙箱根外而 Operation not permitted；形态 B（session cwd=项目根、绝对路径操作 worktree）中 git add 成功。A 下 worktree 根内 .git 指针仍可改写。结论：机械隔离应默认 A，并补 protected .git；B 只能作为路径纪律兼容模式。
    basis: observation
    verification:
      criterionId: d3
      criterionVersion: 1
      method: 真实 LocalSandboxProvider + 临时主仓库/linked worktree A/B 对照探针
      result: passed
      coverage: 覆盖 macOS Seatbelt enforcement=full 下源码写入与 Git metadata 写入差异；未覆盖 Linux bwrap/Landlock 与 Windows partial ACL。
    createdAt: 2026-09-23T09:29:36.000Z
  - id: e14
    kind: scope
    content: 修正验收标准 d3/d4（Host 已升版为 v2）：d3 从「守卫是唯一提交入口」改为「机械强制点必须落在进程/沙箱边界，文档须区分可信执行器与不可绕过入口，并给出 protected-path 沙箱与形态 A 二选一」；d4 补入 protected-path 与强制 fork 的取舍。触发原因：第二轮源码调研（e12）与真实 Seatbelt 探针（e13）否定了包装命令作为安全边界。
    basis: agent-proposal
    reason: 原 d3 文本与设计结论矛盾，若不修正会导致后续实现按错误标准验收
    createdAt: 2026-09-23T09:38:03.913Z
  - id: e15
    kind: decision
    content: 任务记录 invalid 的根因与修复：e13 的 verification 块缺 criterionId/criterionVersion，而插件 src/task-contract.ts:40 的 verificationSchema 里这两项均必填（zod 非 optional）——经 Host 工具不可能写出该记录。叠加 e12/e13 与 operations 的时间戳为整秒 09:29:36.000Z、而 Host 写入均为毫秒精度（.805Z/.923Z/.882Z/.263Z/.828Z），判定 e13 极可能是绕过 Host 工具直接编辑 task.md 写入的（次要可能：另一个校验更松的 Host 实例）。手工补齐两字段后记录恢复可读（project_task_list diagnostics 清空）。教训：任务记录本身也需要唯一写入通道 + 写入后校验，绕过通道会静默破坏整份记录的可读性。
    basis: observation
    createdAt: 2026-09-23T09:38:25.516Z
  - id: e16
    kind: progress
    content: "文档整理（两处瑕疵）：① §0 原第 4 条与第 6 条重复的「P0 不能宣称不可绕过」合并为一条，条目重编为连续的 1–7；② §2.5 把「第二轮官方源码结论」与「linked worktree A/B 探针」归到同一个 ### 第二轮调研 标题下（各自降为 ####），§2.5 现为三个平级子节（拒绝链路探针 / 第二轮调研 / 复用评估）。grep 标题层级验证：## 0–8、### 4.1–4.4 与 §2.5/§7 子节均连续，无孤立标题。文档仍未提交（工作树 M）。"
    basis: observation
    createdAt: 2026-09-23T09:40:16.670Z
  - id: e17
    kind: progress
    content: 本轮产物已提交（均未 push）：插件仓库 5193e8135fa0b27fc43d0a71a0072f3304a02090（docs/session-concurrency.md，+95/−13，含第二轮调研修订与结构整理）；项目根 0f937b0970dc27594104aafa8397608d954c1bcc（task.md + artifacts/dsh-second-pass-research.md，2 文件 +209/−20）。两次提交前均确认 index 干净、只 add 自己的路径、提交后项目根里他人未提交改动（资源卡片 task.md 的 M、技能索引任务目录的 ??）原样保留。
    basis: observation
    createdAt: 2026-09-23T09:53:02.235Z
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
  44e05be91787aa77176003ad3e72f4594cfc5a02072ecd894d3e9aed04be09e4:
    fingerprint: dbea3a9bbfbfce22c9420ac7b5bdf9a98ea5df1d9293789741a27014a0a03ce4
    kind: update
    at: 2026-09-23T09:29:36.000Z
    entryIds:
      - e12
      - e13
  99155405f1a25ae377f14e28b922079dbaf58222df0b81987a82813cc7bd9323:
    fingerprint: d9425f80add64b2539174f9428dd8a7bb1a1307cdb73bf1dedd9b8ee2f113356
    kind: update
    at: 2026-09-23T09:38:03.913Z
    entryIds:
      - e14
  8a39b30662c3721124d7a5fb7144eddb778667b9aed3b54b1e77d60ad7ce2a85:
    fingerprint: 2ab91a5c919b8424db10375b3c2ea2173e7fad1e807a60e32dca052e5b50a543
    kind: update
    at: 2026-09-23T09:38:25.516Z
    entryIds:
      - e15
  9b53e2036bd6a0ee7aa0e36b26c739427993357437b3073b67c47ac0ce20b8df:
    fingerprint: 95a876a83339823c076a9e19e5f30c0b3685dd5963b5e733edecfaa5f89b84e1
    kind: update
    at: 2026-09-23T09:40:16.670Z
    entryIds:
      - e16
  f05871118ae430a1fed5120434a5df338a6da2dcd3d49385635fb82f9cc51a79:
    fingerprint: d0d3331f9bc6df5bf783fdc0e8f2d64c46e6270189653e14135e331082d8bacc
    kind: update
    at: 2026-09-23T09:53:02.235Z
    entryIds:
      - e17
  98fedbf9f25f7069fcf0a904ceac2a1d6a1f47530c575cac72ed981d47c5861a:
    fingerprint: 4d72252b250d1926c5f3093e9f6d47b0eec36c1c22ecba9eeb06a999523e3b00
    kind: update
    at: 2026-09-23T09:53:08.220Z
    entryIds: []
criterionVersions:
  d1: 2
  d2: 2
  d3: 2
  d4: 2
---


