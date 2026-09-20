---
schemaVersion: 3
directory: 记忆功能不可达：没有任何新增记忆条目的路径
id: task-e3ccde1c-c8e5-4062-a5ae-7640d2682230
title: 记忆功能不可达：没有任何新增记忆条目的路径
objective: 记录并定位「项目记忆永远为空且无法新增条目」的缺陷：给出完整证据链、影响面与修复方向，供后续排期实现。
status: active
createdAt: 2026-09-20T06:44:56.266Z
updatedAt: 2026-09-20T10:46:28.520Z
artifacts: []
archived: false
phase: investigation
brief:
  currentBehavior: "项目创建时 manifest 写入 memory: []（project-files.ts:51）。唯一的写入 API 是 updateProjectMemory(id, content)，而它在 id 未声明时直接 throw「Unknown project memory」（project.ts:124-140）。除此之外：manifest 变更动作支持 skill 的 enable/import 与 MCP 的 upsert/delete/reload，但没有 memory；defineTool 全库只出现在 task-tools.ts（仅 4 个 project_task_* 工具），没有记忆工具；客户端 MemoryPanel.tsx 只提供对已有条目的编辑，没有新增入口。结果是：项目从创建起记忆永远为空，且无法增加。"
  scope: 定位并记录 dsh-plugin-project 中「记忆条目无法新增」缺陷的证据链、影响面与修复方向。
  constraints:
    - 本轮只做调查与记录，不修改产品代码
    - 不使用「直接编辑 manifest」的绕行办法写记忆
  outOfScope:
    - 实现修复（本轮只记录）
    - 用直接编辑 manifest + 建 memory/ 文件的方式绕行
    - 记忆内容的实际写入
  acceptanceCriteria:
    - id: ac1
      text: 完整证据链：记录「无法新增记忆条目」涉及的每一处代码位置与实际行为
      required: true
      version: 1
    - id: ac2
      text: 明确受影响面：新项目、已有项目、面板、HTTP API、Agent 工具各自的表现
      required: true
      version: 1
    - id: ac3
      text: 给出修复方向与影响面，供后续排期
      required: true
      version: 1
handoff:
  nextSteps:
    - 确认修复方案范围（是否含 Agent 记忆工具）
    - 实现记忆 create/delete 与声明路径，并补齐面板入口
    - 补测试：新增、删除、单篇 64 KB 与总量 128 KB 超限、路径越出 memory/ 被拒
  readBefore:
    - file-project
    - file-api
    - file-panel
  verifyBefore:
    - note-verify-mem
references:
  - id: file-api
    label: 项目 API（记忆路由与变更动作）
    type: file
    path: resources/dsh-plugin-project/src/project-api.ts
  - id: file-panel
    label: 记忆面板（仅编辑，无新增）
    type: file
    path: resources/dsh-plugin-project/src/client/MemoryPanel.tsx
  - id: file-project
    label: 项目模型（updateProjectMemory 与 128KB 上限）
    type: file
    path: resources/dsh-plugin-project/src/project.ts
  - id: note-verify-mem
    label: 验证方式
    type: note
    text: cd resources/dsh-plugin-project && npm run check。新增能力需覆盖：新增条目后 manifest 与 memory/ 文件同步、删除后上下文不再加载、单篇 >64KB 与总量 >128KB 被拒、路径越出 memory/ 被拒。
  - id: file-memory-manual
    label: 手工创建并声明的记忆文档（读路径可用性证据）
    type: file
    path: memory/working-agreements.md
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
criterionVersions:
  ac1: 1
  ac2: 1
  ac3: 1
---


