---
schemaVersion: 3
directory: Agent 记忆沉淀方案调研：开源方案对照与落地候选
id: task-50ad7eed-97e3-4b3c-b915-b15439d35b1f
title: Agent 记忆沉淀方案调研：开源方案对照与落地候选
objective: 调研主流 agent 记忆沉淀方案（学术与开源产品），形成与 dsh-plugin-project 记忆功能的对照、差距清单与按成本排序的落地候选，供后续排期（本轮只记录，不实现）。
status: active
createdAt: 2026-09-23T07:50:43.548Z
updatedAt: 2026-09-23T07:51:17.408Z
artifacts:
  - type: file
    path: artifacts/memory-landscape.md
    description: 调研正文：分类框架、代表方案要点、与现状的差距清单、按成本排序的落地候选、来源与待核实清单
archived: false
phase: investigation
brief:
  currentBehavior: 现状（提交 8db85fe 后）：记忆是 manifest 声明的扁平 Markdown 文档，全文随项目参考材料常驻每个会话（单篇 ≤64KB、合计 ≤128KB），写入有三个入口——HTTP /api/project/memory（create/update/delete）、MemoryPanel 新增/删除、Agent 工具 project_memory_list/create/update/delete（写操作要求会话 cwd 等于项目根）。缺口：1) 没有「何时该沉淀」的提示词级引导（projectContext 只注入文档内容，projectTaskContext 才有 CONTEXT_GUIDANCE 式规则）；2) 没有索引层，全文常驻导致 128KB 即硬天花板；3) 文档无元数据（类型/更新时间/来源）；4) 无检索、无关系、无整理（合并/重写）机制；5) 无按需加载。调研结论：领域主流按写入时机分五类（人写常驻 / 模型主动工具写 / 每轮自动抽取 / 空闲后台整理 / 查询时召回），我们属第二类中最被动的一种。
  scope: 调研主流 agent 记忆沉淀方案（学术论文 + 开源/商业产品），形成分类框架、代表项目要点、与 dsh-plugin-project 记忆功能的差距清单，以及按成本排序的落地候选，供后续排期。
  constraints:
    - 本轮只调研与记录，不实现、不改产品代码
    - 区分「已核实来源」与「仅见于搜索摘要」的说法，不把未核实的细节当结论
    - 不引入向量库/图数据库，不 bump upstream.lock.json
  outOfScope:
    - 实现任一调研方案
    - 引入向量数据库或图数据库
    - 改动 upstream.lock.json 或发布
handoff:
  nextSteps:
    - 确认是否采纳候选①（记忆沉淀引导）与②（文档元数据）：两者成本低且互不依赖，可同批实现
    - 候选③（索引层 + 正文按需读取）需要先定索引格式，并考虑已声明文档与旧 manifest 的兼容迁移
    - 候选④（整理动作）与⑤（检索/时序图谱）暂搁置，等记忆规模或跨项目需求出现再评估
    - 若采纳①，建议同时给 projectContext 加一段可验收的文案断言，并做一次原生视觉验收（中英文）
  readBefore:
    - file-memory-tools
    - file-project
    - art-memory-landscape
  verifyBefore:
    - note-verify-memory-followup
references:
  - id: url-claude-memory
    label: Claude Code：CLAUDE.md / AGENTS.md + auto memory（最接近我们形态）
    type: url
    url: https://code.claude.com/docs/en/memory
  - id: url-zep
    label: Zep：时序知识图谱记忆层论文（Graphiti、双时间轴、LongMemEval 数据）
    type: url
    url: https://ar5iv.labs.arxiv.org/html/2501.13956
  - id: url-amem
    label: A-MEM：Zettelkasten 式 agentic memory（链接生成 + memory evolution）
    type: url
    url: https://ar5iv.labs.arxiv.org/html/2502.12110v2
  - id: url-langmem
    label: LangMem：semantic / episodic / procedural 三分法与 namespace
    type: url
    url: https://www.langchain.com/blog/langmem-sdk-launch
  - id: url-mem0-types
    label: mem0：memory_type 现状（仅 procedural 真正实现）
    type: url
    url: https://docs.mem0.ai/core-concepts/memory-types
  - id: url-basicmemory
    label: Basic Memory：本地 Markdown + SQLite 索引 + MCP 工具
    type: url
    url: https://docs.basicmemory.com/
  - id: url-letta
    label: Letta（MemGPT）：memory blocks / archival memory 文档
    type: url
    url: https://docs.letta.com/
  - id: url-mcp-memory
    label: MCP 官方 memory server（知识图谱式实体/关系/观察）
    type: url
    url: https://github.com/modelcontextprotocol/servers/tree/main/src/memory
  - id: url-awesome
    label: Awesome-Agent-Memory：论文/系统/基准清单
    type: url
    url: https://github.com/TeleAI-UAGI/Awesome-Agent-Memory
  - id: file-memory-tools
    label: 现状：Agent 记忆工具（list/create/update/delete）
    type: file
    path: resources/dsh-plugin-project/src/memory-tools.ts
  - id: file-project
    label: 现状：项目模型与记忆限额（64KB/128KB、memory/ 约束）
    type: file
    path: resources/dsh-plugin-project/src/project.ts
  - id: art-memory-landscape
    label: 调研正文（本任务 artifacts）
    type: file
    path: artifacts/memory-landscape.md
  - id: note-verify-memory-followup
    label: 后续实现的验证方式
    type: note
    text: 采纳任一候选后：cd resources/dsh-plugin-project && yarn run check（≈40s，typecheck+test+build）必须 EXIT=0；涉及 projectContext/工具描述的改动要加可断言的测试；涉及面板文案或元数据展示时另做原生四组合视觉验收（en/zh × light/dark × 1180/420）。
entries:
  - id: research-mem-1
    kind: progress
    content: 分类框架（按写入时机）：1) 人写、每会话常驻——Claude Code 的 CLAUDE.md/AGENTS.md、Cursor/Windsurf rules；2) 模型主动工具写——Claude Code auto memory、MCP 官方 memory server、Basic Memory、以及我们的 project_memory_*；3) 每轮对话后自动抽取——mem0、LangMem、cognee；4) 空闲/后台整理——Letta sleep-time compute、A-MEM memory evolution、Generative Agents reflection；5) 查询时召回——Zep/Graphiti、A-MEM、LangMem。我们的工具属于第 2 类，但缺第 2 类产品普遍具有的「何时该写」提示词引导。
    basis: observation
    reason: 给出调研主线和分类
    createdAt: 2026-09-23T07:50:43.548Z
  - id: research-mem-2
    kind: progress
    content: 代表方案要点（均已核实来源）：1) Claude Code = CLAUDE.md/AGENTS.md（人写、分层、@import、路径作用域 rules）+ auto memory（模型自写、每仓库一份、机器本地，MEMORY.md 索引 + 主题文件，开头 200 行/25KB 进会话，四类 user/feedback/project/reference，策略是「能从代码与 git 推出的不记」）。2) Zep/Graphiti = episode→entity/fact→community 三层子图 + 双时间轴（t_valid/t_invalid 与 t'_created/t'_expired，冲突时边失效不删除），检索 = 向量+BM25+图 BFS+rerank；DMR 94.8% vs MemGPT 93.4%，LongMemEval 71.2% vs 全上下文 60.2%，上下文 1.6k vs 115k tokens。3) A-MEM = Zettelkasten 结构化 note（关键词/标签/上下文描述/向量/链接）+ 写入时 top-k 建链 + memory evolution 反写旧记忆。4) LangMem = semantic/episodic/procedural 三分法 + create_memory_manager 抽取 + prompt optimizer + namespace 隔离。5) Basic Memory = 本地 Markdown + SQLite 索引 + MCP 工具，含 observations/relations 等结构化概念。
    basis: observation
    referenceIds:
      - url-claude-memory
      - url-zep
      - url-amem
      - url-langmem
      - url-basicmemory
    reason: 沉淀重点方案的可排期事实
    createdAt: 2026-09-23T07:51:17.408Z
  - id: research-mem-3
    kind: progress
    content: 与现状的七项差距：1) 无「何时沉淀」的提示词级引导（projectContext 只注入内容）；2) 无索引层，全文常驻使 128KB 成为硬天花板；3) 文档无元数据（类型/更新时间/来源）；4) 无检索，只有全量加载；5) 无关系与时间有效性；6) 无整理/合并机制；7) 除项目根外无作用域概念。前两项是当前规模下最痛的，后四项要到记忆规模或跨项目需求出现才值得做。
    basis: observation
    reason: 把调研收敛成可排期的差距清单
    createdAt: 2026-09-23T07:51:17.408Z
  - id: prop-mem-landscape
    kind: decision
    content: 落地候选（按成本）：①【低】把 Claude Code「记什么/不记什么」翻译成项目参考材料引导，与 projectTaskContext 的 CONTEXT_GUIDANCE 对称；②【低】manifest 声明加 type/summary 与更新时间元数据；③【中】索引层 + 正文按需读取（把 128KB 从常驻上限降为总量上限）；④【中】整理动作（合并重复/重写索引/标记失效，A-MEM evolution 轻量版）；⑤【高，暂不建议】检索层或时序知识图谱（收益在 10 万 tokens 量级，当前 128KB 规模不划算）。
    basis: agent-proposal
    reason: 给出可直接排期的候选与优先级
    createdAt: 2026-09-23T07:51:17.408Z
  - id: prog-mem-landscape-report
    kind: progress
    content: 调研正文已落盘：artifacts/memory-landscape.md（分类框架、代表方案要点、差距清单、落地候选、来源与待核实清单）。第九轮对话中已向用户口头汇报同一内容。
    basis: observation
    reason: 把调研结论固定为可引用的任务产物
    createdAt: 2026-09-23T07:51:17.408Z
operations:
  bdcc4d70b0f75aa57b5fc50d44674bfd9e7c6197dd8ee6a853be7655048f204c:
    fingerprint: 96984d113f0b9429e478e365072000bd948780d36bf93c766251405777a7e92a
    kind: create
    at: 2026-09-23T07:50:43.548Z
    entryIds:
      - research-mem-1
  767d48e99068a25d0105eeab86ccad94be8f191b7ead01fbae4439b75b707284:
    fingerprint: fae47dba0f289bbcdcb3172939e21d6fc0a304d1da3ff782fd76a27d0ec5bd3f
    kind: update
    at: 2026-09-23T07:51:17.408Z
    entryIds:
      - research-mem-2
      - research-mem-3
      - prop-mem-landscape
      - prog-mem-landscape-report
criterionVersions: {}
---


