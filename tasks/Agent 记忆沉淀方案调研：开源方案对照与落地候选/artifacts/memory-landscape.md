# Agent 记忆沉淀方案调研：开源方案对照与落地候选

状态：**调研记录，未实现**。范围与结论供后续排期，不构成实现授权。
日期：2026-09-23。对象：`dsh-plugin-project` 的项目记忆（`memory/` + manifest 声明 + `project_memory_*` 工具）。

## 0. TL;DR

- 领域内的差异**主要不在存储，而在「谁决定该沉淀什么、什么时候沉淀」**。
- 按写入时机可分成五类：人写常驻 / 模型主动工具写 / 每轮自动抽取 / 空闲后台整理 / 查询时召回。
- 我们（提交 `8db85fe`）属于第二类，但**缺第二类产品普遍具备的提示词级触发引导**，也没有索引层、元数据、检索与整理机制。
- 最有性价比的三件事：① 补「何时该写」的引导；② 加索引层（正文按需读）；③ 给文档加元数据（类型/更新时间/来源）。向量库与时序图谱在当前 128KB 规模下收益很低。

## 1. 分类框架：谁决定写入

| 写入时机 | 代表方案 | 机制 | 写入由谁决定 |
| --- | --- | --- | --- |
| 人写、每会话常驻 | Claude Code 的 `CLAUDE.md` / `AGENTS.md`；Cursor / Windsurf rules | 人维护 Markdown，启动即注入 | 人 |
| 模型主动工具写 | Claude Code **auto memory**、MCP 官方 memory server、Basic Memory、**本项目的 `project_memory_*`** | 模型在工具目录看到工具后自行调用 | 模型（靠描述与提示词引导） |
| 每轮对话后自动抽取 | mem0、LangMem、cognee | 框架在 `add()` / 每轮结束后跑 LLM 抽取、去重、更新 | 框架管道（无需模型决策） |
| 空闲 / 后台整理 | Letta 的 sleep-time compute、A-MEM 的 memory evolution、Generative Agents 的 reflection | 新记忆触发旧记忆改写、建链、归纳 | 后台任务 |
| 查询时召回 | Zep / Graphiti、A-MEM、LangMem | 不常驻全文，按 query 检索（向量 / BM25 / 图遍历）后拼上下文 | 检索器 |

## 2. 代表方案要点

### 2.1 Claude Code（形态与我们最接近，且已往自动沉淀走）——已核实

来源：<https://code.claude.com/docs/en/memory>

- 双轨：
  - `CLAUDE.md` / `AGENTS.md`：**人写**的持久指令，分层（企业托管 / 用户 `~/.claude/CLAUDE.md` / 项目 / 本地 `CLAUDE.local.md`），由文件系统根向下拼接，支持 `@path` import（最多 4 跳）与 `.claude/rules/` 路径作用域规则。
  - auto memory：**Claude 自己写**的笔记，按仓库隔离、机器本地，`~/.claude/projects/<project>/memory/` 下 `MEMORY.md` 当索引 + 每主题一个文件；**开头 200 行或 25KB** 进每个会话，正文按需读。
- 笔记分四类（写进 frontmatter `type`）：`user`（角色/偏好）、`feedback`（被纠正与确认的做法）、`project`（代码与 git 推不出的进行中工作与决策）、`reference`（外部信息在哪找）。
- 写入策略（原文明说）：**从代码库能推出来的不记**（架构、文件路径、调试修复），**CLAUDE.md 已写的也不记**；不是每次会话都写，只在"对未来对话有用"时写。
- 运维：`/memory` 审计与编辑；`autoMemoryEnabled` 可关；索引超阈值时提示模型压缩；写入时在 frontmatter 记 `modified` 时间戳；旧的会话记录会被清理，但 memory 目录豁免。
- 对我们的直接价值：**这几条"记什么/不记什么"可以直接翻译成我们的项目参考材料引导**。

### 2.2 Zep / Graphiti（时序知识图谱，工程化最强）——已核实

来源：<https://ar5iv.labs.arxiv.org/html/2501.13956>

- 三层子图：episode（原始消息/文本/JSON，非丢失存储）→ semantic（实体与事实边）→ community（强连通实体簇的摘要）。
- **双时间轴**：`t_valid` / `t_invalid`（事实在真实世界何时成立）+ `t'_created` / `t'_expired`（系统何时录入/失效）。新事实与旧边冲突时**将旧边置为失效而非删除**，保留历史演化。
- 检索 = 向量 + BM25 + 图 BFS（n 跳），再 rerank（RRF / MMR / episode-mentions / 图距离 / cross-encoder）。
- 数据：DMR 94.8% vs MemGPT 93.4%（gpt-4-turbo）；LongMemEval 71.2% vs 全上下文 60.2%（gpt-4o），平均上下文 **1.6k vs 115k tokens**、延迟 **2.58s vs 28.9s**。
- 论文自己承认 DMR 太简单：gpt-4o-mini 全上下文基线就有 98%，真正区分方案的是 LongMemEval / LoCoMo 这类长会话、多会话与时间推理题。

### 2.3 A-MEM（Zettelkasten 式 agentic memory）——已核实

来源：<https://ar5iv.labs.arxiv.org/html/2502.12110v2>（生产实现：<https://github.com/agiresearch/A-mem>）

- 每条记忆是一张结构化 note：原文 `c` + 时间戳 `t` + LLM 生成的关键词 `K` / 标签 `G` / 上下文描述 `X` + 向量 `e` + 链接集合 `L`。
- 写入流程：新 note 取 top-k 相似旧 note → LLM 判断是否建链 → **memory evolution：新记忆可以反过来改写旧记忆的描述、关键词与标签**，形成"box"（同一 box 的 note 检索时连带召回）。
- 立场：反对"预定义 schema + 固定工作流"，主张记忆组织结构本身由模型演化决定。
- 在 LoCoMo 上对比 LoCoMo/ReadAgent/MemoryBank/MemGPT，F1 与 token 消耗（约为 MemGPT 的 1/10 量级）均占优。

### 2.4 LangMem（把记忆类型讲得最清楚的 SDK）——已核实

来源：<https://www.langchain.com/blog/langmem-sdk-launch>

- 三分法：
  - **semantic**：事实与关系（用户偏好、知识三元组）→ profile 或 collection。
  - **episodic**：过往经历、few-shot 示例、会话摘要 → collection。
  - **procedural**：行为规则（"怎么做"），直接更新系统提示 → prompt rules。
- 提供 `create_memory_manager`（从对话抽取事实并做 insert/update）与 `create_prompt_optimizer`（用带分数的轨迹优化提示，metaprompt / gradient / prompt_memory 三种算法）。
- 强调 **namespace**：按 user / team / app route 隔离，或跨用户共享"核心流程"；隐私与性能共同决定共享范围。
- 提出三个设计问题，可直接拿来审我们的设计：**什么行为该学、该跟踪哪类知识、什么条件触发召回**。

### 2.5 Basic Memory（本地优先，文件模型与我们最像）——已核实

来源：<https://docs.basicmemory.com/>

- 记忆就是本地 Markdown（兼容 Obsidian），SQLite 只做索引；通过 MCP 暴露工具，AI 与人在同一批文件上协作，可进 Git。
- 概念层比我们丰富：knowledge format、**observations and relations**、projects and folders、memory URLs、schema system、semantic search、metadata search。
- 对我们的价值：证明"纯文件 + 索引"可以既保持可读可审计，又提供结构化与检索；我们的差距主要是**关系与索引**，不是存储介质。

### 2.6 其他值得知道的名字——部分仅见于搜索摘要

- **mem0**（<https://docs.mem0.ai/core-concepts/memory-types>，已核实该页）：`add / search / update / delete` 四操作 + 抽取管道；其文档明确说明三种 `memory_type` 里**只有 `procedural_memory` 真正实现**，semantic / episodic 只是枚举占位、传入会被拒。教训：记忆类型容易被产品化过度承诺。
- **Letta（MemGPT 后继）**（<https://docs.letta.com/>，已核实文档结构）：**memory blocks**（agent 用工具自行编辑的核心记忆，如 persona/human）+ **archival memory**（可检索的长期库）+ recall；另有 shared memory / repositories。sleep-time compute（后台 agent 在空闲时整理记忆）属其提出的方向，本次未取到该页原文，**标记为待核实**。
- **MCP 官方 memory server**（<https://github.com/modelcontextprotocol/servers/tree/main/src/memory>）：知识图谱式实体/关系/观察，工具语义为 create_entities / create_relations / add_observations / search_nodes / read_graph 等，存储为本地 JSON。**工具名与存储细节本次未取到 README 正文（GitHub 页面抓取被截断），标记为待核实。**
- **cognee**：ECL（Extract / Cognify / Load）管道 + 知识图谱与向量混合；本次仅见搜索摘要，**细节待核实**。
- **Awesome-Agent-Memory**（<https://github.com/TeleAI-UAGI/Awesome-Agent-Memory>）：论文 / 系统 / 基准的持续清单，适合当索引用。
- **评测基准**：DMR（MemGPT 提出，已被 Zep 指出过易）、**LoCoMo**（长多会话对话 QA）、**LongMemEval**（长会话 + 时间推理，含 knowledge-update / temporal-reasoning / multi-session 等题型）。
- **Generative Agents**（Park et al., 2023, arXiv:2304.03442）：memory stream + recency/importance/relevance 检索 + reflection，是这一方向的源头工作。

## 3. 与我们现状的差距清单

现状（提交 `8db85fe`）：manifest 声明的扁平 Markdown，全文随项目参考材料常驻每个会话（单篇 ≤64KB、合计 ≤128KB）；写入入口 = HTTP `/api/project/memory`（create/update/delete）+ MemoryPanel 新增/删除 + `project_memory_list/create/update/delete`（写操作要求会话 cwd 等于项目根）。

| # | 差距 | 对照对象 | 影响 |
| --- | --- | --- | --- |
| 1 | 没有「何时该沉淀」的提示词级引导（`projectContext` 只注入内容；只有 task 侧有 `CONTEXT_GUIDANCE`） | Claude Code auto memory 策略 / LangMem 三问 | 能力可达但主动性全靠模型读工具描述，实际沉淀率低 |
| 2 | 无索引层，全文常驻 → 128KB 即硬天花板 | Claude Code `MEMORY.md` 索引 + 主题文件按需读 | 记忆一多就触顶，只能靠删减 |
| 3 | 文档无元数据（类型 / 更新时间 / 来源会话） | Claude Code `type` + `modified`；LangMem 三类 | 无法审计、无法按新鲜度淘汰、无法区分"偏好"与"事实" |
| 4 | 无检索，只有"全部加载" | Zep / A-MEM / LangMem 的按 query 召回 | 规模上限被上下文预算锁死 |
| 5 | 无关系与时间有效性 | Zep 双时间轴与边失效；Basic Memory observations/relations | 事实更新只能整篇重写，旧结论无法标记失效 |
| 6 | 无整理/合并机制 | A-MEM memory evolution；Letta sleep-time；Generative Agents reflection | 重复与矛盾条目会累积 |
| 7 | 无作用域概念（除"项目根"外） | LangMem namespace | 跨项目/团队共享缺少表达方式 |

## 4. 落地候选（按成本排序，供后续排期）

1. **【低成本】补记忆沉淀引导**：把 Claude Code 的"记什么/不记什么"翻译成项目参考材料里的一小段（能从代码与 git 推出、或 `CLAUDE.md`/`AGENTS.md` 已写的不记；被纠正两次的做法、项目决策、外部资料位置要记；先 `list` 再 `create/update`；一篇一个主题）。与 `projectTaskContext` 的 `CONTEXT_GUIDANCE` 对称，改 `projectContext` 或新增一段注入即可。
2. **【低成本】文档元数据**：在 manifest 声明里加 `type`（user/feedback/project/reference 或 semantic/episodic/procedural）与 `summary`，写入时记录更新时间；面板与工具输出都带上。
3. **【中成本】索引层 + 按需读取**：上下文只放"索引 + 每篇摘要"（类似 `MEMORY.md`），正文由模型用既有读文件能力按需取；把 128KB 从"常驻上限"降级为"总量上限"。
4. **【中成本】整理动作**：新增一次性的"合并重复 / 重写索引 / 标记失效"动作（A-MEM evolution 的轻量版），可由面板按钮或 Agent 工具触发。
5. **【高成本，暂不建议】** 检索层（FTS/嵌入）或时序知识图谱（Graphiti 式）：收益出现在 10 万 tokens 量级的会话历史上；我们记忆总量上限 128KB，先做 1–3 的性价比远高。

## 5. 参考来源

- Claude Code 记忆机制：<https://code.claude.com/docs/en/memory>
- Zep 论文：<https://ar5iv.labs.arxiv.org/html/2501.13956>
- A-MEM 论文：<https://ar5iv.labs.arxiv.org/html/2502.12110v2>；实现：<https://github.com/agiresearch/A-mem>
- LangMem：<https://www.langchain.com/blog/langmem-sdk-launch>
- mem0 记忆类型现状：<https://docs.mem0.ai/core-concepts/memory-types>
- Basic Memory：<https://docs.basicmemory.com/>
- Letta 文档：<https://docs.letta.com/>
- MCP 官方 memory server：<https://github.com/modelcontextprotocol/servers/tree/main/src/memory>
- Awesome-Agent-Memory：<https://github.com/TeleAI-UAGI/Awesome-Agent-Memory>

## 6. 待核实清单（避免当成结论使用）

- Letta 的 sleep-time compute 具体机制（本次未取到该页正文）。
- MCP 官方 memory server 的完整工具名与存储格式（README 正文抓取被截断）。
- cognee 的 ECL 细节（仅见搜索摘要）。
- Zep / A-MEM 论文中的对比数字来自论文自测，未在本项目复现。
