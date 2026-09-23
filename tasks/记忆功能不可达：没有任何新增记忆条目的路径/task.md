---
schemaVersion: 3
directory: 记忆功能不可达：没有任何新增记忆条目的路径
id: task-e3ccde1c-c8e5-4062-a5ae-7640d2682230
title: 记忆功能不可达：没有任何新增记忆条目的路径
objective: 记录并定位「项目记忆永远为空且无法新增条目」的缺陷，并按委托补全写入路径：API create/delete、记忆面板入口、Agent 记忆工具与测试。
status: completed
createdAt: 2026-09-20T06:44:56.266Z
updatedAt: 2026-09-23T03:26:54.893Z
artifacts:
  - type: file
    path: artifacts/native-memory-evidence.md
    description: 实现范围、自动化验证与原生验收报告
  - type: file
    path: artifacts/memory-en-light-1180.png
    description: 原生验收：英文/浅色/1180px，含新增卡片与新入口
  - type: file
    path: artifacts/memory-zh-dark-1180.png
    description: 原生验收：中文/深色/1180px
  - type: file
    path: artifacts/memory-en-light-420.png
    description: 原生验收：英文/浅色/420px 窄窗口无横向溢出
  - type: file
    path: artifacts/memory-zh-dark-420.png
    description: 原生验收：中文/深色/420px 窄窗口
  - type: file
    path: artifacts/native-result.json
    description: 原生验收逐项断言结果（创建/编辑/删除/溢出）
  - type: commit
    repository: https://github.com/admintertar/dsh-plugin-project.git
    commit: 8db85fea2dd964283ddd99f0b063a311d1bdd7ad
    description: 记忆写入路径实现（create/delete、Agent 工具、面板入口、测试）
archived: false
phase: validation
brief:
  currentBehavior: 已修复：manifest 声明 memory[] 后，可通过三类入口新增/删除。1) 模型：createProjectMemory(manifestPath, {id?, name, content, path?}) 会在 memory/ 下以独占方式写文件并把声明写入 manifest；id 缺省时由名称派生并避开已声明 id 与同名文件；deleteProjectMemory(manifestPath, id) 先移除声明，再删除未被其他声明共享的文档。2) HTTP：POST /api/project/memory 支持 action=create/update/delete，单篇超 64 KB 仍回复 413 body-too-large。3) Agent：project_memory_list/create/update/delete，写操作要求调用会话 cwd 等于项目根，与 project_task_* 一致。4) 面板：MemoryPanel 提供「新增知识文档」（名称 + Markdown 原文 + 字节计数）与每卡删除确认。全部读取路径沿用 readProject（单篇 64 KB、总量 128 KB、memory/ 下真实文件、拒绝软链与越界路径）。
  scope: 定位并实现 dsh-plugin-project 中记忆条目的读取约束与新增/删除写入路径：模型 create/delete、HTTP create/update/delete、Agent 记忆工具、记忆面板新增/删除入口与测试。
  constraints:
    - 实现沿用既有 64 KB 单篇、128 KB 总量与 memory/ 目录约束（含软链拒绝）
    - 本轮不 push、不改 upstream.lock.json（发布时才 bump）
  outOfScope:
    - 用直接编辑 manifest + 建 memory/ 文件的方式绕行（产品内已提供 create 动作）
    - 在真实项目里沉淀具体记忆内容
  acceptanceCriteria:
    - id: ac1
      text: 完整证据链：记录「无法新增记忆条目」涉及的每一处代码位置与实际行为
      required: true
      version: 2
    - id: ac2
      text: 明确受影响面：新项目、已有项目、面板、HTTP API、Agent 工具各自的表现
      required: true
      version: 2
    - id: ac3
      text: 给出修复方向与影响面，供后续排期
      required: true
      version: 2
questions: []
references:
  - id: file-api
    label: 项目 API（记忆 create/update/delete 路由）
    type: file
    path: resources/dsh-plugin-project/src/project-api.ts
  - id: file-panel
    label: 记忆面板（新增/编辑/删除）
    type: file
    path: resources/dsh-plugin-project/src/client/MemoryPanel.tsx
  - id: file-project
    label: 项目模型（记忆 create/update/delete 与限额）
    type: file
    path: resources/dsh-plugin-project/src/project.ts
  - id: note-verify-mem
    label: 验证方式
    type: note
    text: cd resources/dsh-plugin-project && yarn run check（typecheck + test + build，≈40s，EXIT=0）。记忆写入需覆盖：新增条目后 manifest 与 memory/ 文件同步、删除后上下文不再加载、单篇 >64KB 与总量 >128KB 被拒、路径越出 memory/ 被拒、越权会话被拒；UI 另做原生四组合视觉验收。
  - id: file-memory-manual
    label: 手工创建并声明的记忆文档（读路径可用性证据）
    type: file
    path: memory/working-agreements.md
  - id: file-memory-tools
    label: Agent 记忆工具（list/create/update/delete）
    type: file
    path: resources/dsh-plugin-project/src/memory-tools.ts
entries:
  - id: inv-mem-1
    kind: progress
    content: "证据链（全部经代码核实）：1) project-files.ts:51 创建项目时写死 memory: []；2) project-api.ts:23 记忆动作只有 z.literal('update')，无 create/delete；3) project.ts:124 updateProjectMemory 在 previous === undefined 时 throw「Unknown project memory: <id>」；4) project-api.ts:25-32 的 manifest 变更动作覆盖 skill / MCP，无 memory；5) defineTool 全库仅出现于 task-tools.ts，只有 project_task_create/list/get/update；6) client/MemoryPanel.tsx 仅对已有 item.content 做编辑，无新增入口；7) 本项目实测：manifest 为 memory: []，且 memory/ 目录不存在。"
    basis: observation
    reason: 确定缺陷性质：不是漏写，而是能力不可达
    createdAt: 2026-09-20T06:44:56.266Z
  - id: inv-mem-2
    kind: progress
    content: 影响面：新项目创建后记忆恒为空；已有项目同样无法新增（面板无入口、API 报 Unknown project memory）；Agent 侧无工具可用，无法自主沉淀；因此「长期知识随项目保存」这一产品承诺目前不可实现。
    basis: observation
    reason: 评估影响范围
    createdAt: 2026-09-20T06:44:56.266Z
  - id: prop-mem-1
    kind: decision
    content: 修复方向（供排期参考）：1) 记忆 API 新增 create / delete 动作，并允许声明新的 memory/ 文件（保留现有 128 KB 总量与 64 KB 单篇限制）；2) MemoryPanel 新增「新增记忆」入口与删除；3) 为 Agent 新增记忆工具（与 project_task_* 对齐），使会话中的长期知识可自主沉淀；4) 补测试覆盖新增/删除/超限/路径越界。
    basis: agent-proposal
    reason: 给出可排期的修复范围
    createdAt: 2026-09-20T06:44:56.266Z
  - id: prog-mem-manual-1
    kind: progress
    content: "按用户明确要求，手工走通「声明式」写入路径（此前列为 outOfScope，仅因本轮调查约束；用户直接指示优先）：新建 memory/working-agreements.md（1151 字节），并在 dsh-project-desktop-development.agent-project 的 memory[] 中声明 {id: working-agreements, name: 项目工作约定与验证流程, path: memory/working-agreements.md}。用 readProject() 实测：memory 条目 1 条、字节数 1151，projectContext() 已把该文档拼入项目参考材料，会话运行时上下文同步出现该文档。结论：读路径与声明路径本身完整可用，缺陷确实只在「新增/删除的写入入口」（API create/delete、面板入口、Agent 工具）缺失。"
    basis: observation
    referenceIds:
      - file-memory-manual
    reason: 补一条可复现的手工声明证据，收敛缺陷边界
    createdAt: 2026-09-20T10:46:28.520Z
  - id: scope-mem-impl
    kind: scope
    content: 范围扩展（用户确认全量）：把已定位的记忆写入缺陷实现为可用能力——模型 create/delete、HTTP create/update/delete、Agent 记忆工具、记忆面板新增/删除入口与测试；原「本轮只做调查与记录，不修改产品代码」约束与「实现修复（本轮只记录）」等 outOfScope 条目作废。
    basis: user-request
    reason: 用户要求按已有委托继续未完成工作，并选择含 Agent 记忆工具的全量范围
    createdAt: 2026-09-23T03:26:46.694Z
  - id: impl-mem-1
    kind: progress
    content: 实现并本地提交 8db85fea2dd964283ddd99f0b063a311d1bdd7ad：project.ts 新增 createProjectMemory/deleteProjectMemory（路径先校验、再算 128 KB 预算，文件独占写入后写 manifest，manifest 失败回滚新文件；删除只移除未被共享的文档）；project-api.ts 的 POST /api/project/memory 支持 create/update/delete；新增 src/memory-tools.ts 的 project_memory_list/create/update/delete 与 src/tool-schema.ts 共享 schema 投影；MemoryPanel.tsx 增加新增弹窗与删除确认，补齐 en/zh 文案、aria-label 与 Escape 行为；工具页把记忆工具归入「项目工具」。
    basis: observation
    referenceIds:
      - file-project
      - file-api
      - file-panel
      - file-memory-tools
    reason: 完成委托的实现项
    createdAt: 2026-09-23T03:26:46.694Z
  - id: ver-mem-ac1
    kind: verification
    content: 逐处复核并补回归测试锚定写入路径：project.test.ts 覆盖创建同时写文件与声明、重复 id/重复路径/非法 id/已存在文件被拒、64 KB 与 128 KB 上限、绝对路径与 .. / 反斜杠 / memory// 越界、memory/ 为软链被拒、删除只删声明与未共享文档；project-api.test.ts 覆盖 create（显式/派生 id、越界 422、超限 413）与 delete；memory-tools.test.ts 覆盖四个工具注册与调用。既有 inv-mem-1 的七处代码位置在实现后逐一复核。
    basis: observation
    reason: 验收 ac1（证据链）
    verification:
      criterionId: ac1
      criterionVersion: 2
      method: 代码复核 + tests/project.test.ts、tests/project-api.test.ts、tests/memory-tools.test.ts 全通过
      result: passed
      coverage: 模型/HTTP/工具/面板四条写入路径及其约束
    createdAt: 2026-09-23T03:26:54.893Z
  - id: ver-mem-ac2
    kind: verification
    content: 受影响入口逐一验证：新项目创建后即可通过面板或 Agent 工具新增（id 缺省时自动派生并避开同名文件）；已有项目同样可用；面板显示新增入口与删除确认；HTTP 返回新快照且拒绝越界/超限；Agent 四个工具可用且越权会话被拒。yarn run check EXIT=0（293 测试）；macOS arm64 Electron 开发壳 en/zh × light/dark × 1180/420 全通过。
    basis: observation
    reason: 验收 ac2（受影响面）
    verification:
      criterionId: ac2
      criterionVersion: 2
      method: yarn run check EXIT=0 + 原生开发壳实时 DOM 验收（四组合、两宽度）
      result: passed
      coverage: 新项目/已有项目/面板/HTTP API/Agent 工具
    createdAt: 2026-09-23T03:26:54.893Z
  - id: ver-mem-ac3
    kind: verification
    content: 按 prop-mem-1 的四项修复方向全部落地并验证：1) API create/delete 与声明路径；2) 面板新增/删除入口；3) 与 project_task_* 对齐的 Agent 记忆工具；4) 新增/删除/超限/路径越界测试。未改 upstream.lock.json，未 push。
    basis: observation
    referenceIds:
      - note-verify-mem
    reason: 验收 ac3（修复方向）
    verification:
      criterionId: ac3
      criterionVersion: 2
      method: 按既定修复方向实现后运行 yarn run check 与原生验收
      result: passed
      coverage: 修复方向四项全部实现
    createdAt: 2026-09-23T03:26:54.893Z
  - id: done-mem-1
    kind: completion
    content: 委托的三项全部完成：确认修复范围（用户选择含 Agent 工具的全量）；实现记忆 create/delete 与声明路径并补齐面板入口；补齐新增/删除/64 KB 与 128 KB 超限/路径越界的测试。证据：yarn run check EXIT=0（293 通过）、4 组原生验收截图与 native-result.json。
    basis: observation
    verificationEntryIds:
      - ver-mem-ac1
      - ver-mem-ac2
      - ver-mem-ac3
    createdAt: 2026-09-23T03:26:54.893Z
operations:
  1b0486f0e992816c4805123cb7879bfc1b34c40379d00f5b2197ec18a592e80e:
    fingerprint: 30e3d79f480fdc163ae179407e01ddf23b40644c64e919f43d7fb6064f1a2866
    kind: create
    at: 2026-09-20T06:44:56.266Z
    entryIds:
      - inv-mem-1
      - inv-mem-2
      - prop-mem-1
  240383fae42b7afc3502ccb39051030c485f6a2c44cacb46acd8106153ae5b7d:
    fingerprint: fcedccb62a9877688137bf762287db31828fa7b896417f54d497b78915f450ba
    kind: update
    at: 2026-09-20T10:46:28.520Z
    entryIds:
      - prog-mem-manual-1
  925f236f434e6cfb4930ac5e263fb27d7a3cdfc0f144cb266069462d30e49194:
    fingerprint: 7144de18ba85b5fb51c54cf48a6a91e80ee05318a75bb35cf54c30a2257bb80e
    kind: update
    at: 2026-09-23T03:26:46.694Z
    entryIds:
      - scope-mem-impl
      - impl-mem-1
  1eb2797e68bd9ef5b0260ca68f11a7f480c83e05d1e09bb0fce1013f82b6c4dd:
    fingerprint: 2429260ffa9ffcd8aaade0d23fda35abbec21f90aa5897d0ed1ae5dea9900a32
    kind: update
    at: 2026-09-23T03:26:54.893Z
    entryIds:
      - ver-mem-ac1
      - ver-mem-ac2
      - ver-mem-ac3
      - done-mem-1
criterionVersions:
  ac1: 2
  ac2: 2
  ac3: 2
---

记忆写入路径已补全并验证。模型层新增 createProjectMemory/deleteProjectMemory（保留 64KB 单篇、128KB 总量、memory/ 路径与真实目录约束；文件与 manifest 一起提交，manifest 失败回滚文件；删除只清未被其他声明共享的文档）；HTTP /api/project/memory 支持 create/update/delete；新增 project_memory_list/create/update/delete 四个 Agent 工具（写操作要求会话 cwd 等于项目根）；MemoryPanel 增加「新增知识文档」入口与删除确认弹窗，补齐中英文案、无障碍名称与 Escape 行为。yarn run check EXIT=0（293 测试全通过，含 7 个新增记忆测试）；macOS arm64 Electron 开发壳四组合（en/zh × light/dark）、两种宽度（1180/420）原生验收通过：新增、内联编辑、Escape 取消、确认删除后文件与 manifest 同步、无横向溢出。提交 8db85fea2dd964283ddd99f0b063a311d1bdd7ad（未 push）。限制：Agent 记忆工具只经工具运行时测试验证，未在真实对话轮次中调用；截图由人工复核，本轮模型不支持读图；验收期间另一会话占用共享开发壳构建，已按其源码快照重建还原；未改 upstream.lock.json，未 bump pin。
