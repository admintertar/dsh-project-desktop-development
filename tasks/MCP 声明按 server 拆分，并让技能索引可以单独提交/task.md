---
schemaVersion: 3
directory: MCP 声明按 server 拆分，并让技能索引可以单独提交
id: task-2ee04a32-b5e0-4eff-8377-837928ad2605
title: MCP 声明按 server 拆分，并让技能索引可以单独提交
objective: 让「项目资产」区块真正兑现「勾什么就提交什么」：把 MCP 声明从单一 mcp/servers.yaml 拆成每个 server 一个文件（读双源以兼容既有项目），并让技能索引的逐技能提交不再连带同一文件里的其他技能变更（用 git hash-object + update-index 构造只含选中项的暂存内容，不改写工作区）。
status: completed
createdAt: 2026-09-22T10:53:17.316Z
updatedAt: 2026-09-22T11:08:33.382Z
artifacts:
  - type: file
    path: artifacts/project-changes-zh-light-1180.png
    description: 中文/浅色/1180px：任务、技能、MCP 三组卡片
  - type: file
    path: artifacts/project-changes-zh-dark-1180.png
    description: 中文/深色/1180px
  - type: file
    path: artifacts/project-changes-en-light-1180.png
    description: 英文/浅色/1180px
  - type: file
    path: artifacts/project-changes-en-dark-1180.png
    description: 英文/深色/1180px
  - type: file
    path: artifacts/project-changes-zh-light-420.png
    description: 中文/浅色/420px 窄窗
  - type: file
    path: artifacts/project-changes-zh-dark-420.png
    description: 中文/深色/420px 窄窗
  - type: file
    path: artifacts/project-changes-en-light-420.png
    description: 英文/浅色/420px 窄窗
  - type: file
    path: artifacts/project-changes-en-dark-420.png
    description: 英文/深色/420px 窄窗
  - type: file
    path: artifacts/project-changes-selection.png
    description: 选中状态与工具栏
  - type: file
    path: artifacts/project-changes-plan-tooltip.png
    description: 提交计划气泡
  - type: file
    path: artifacts/project-changes-after-commit.png
    description: 提交后：两个资产离开审阅
  - type: file
    path: artifacts/native-smoke-result.json
    description: 原生冒烟完整结果
  - type: file
    path: artifacts/native-smoke-run.log
    description: smoke:resources 运行日志（EXIT=0）
  - type: file
    path: artifacts/unit-tests.log
    description: 插件 yarn check 日志（274 tests 全绿）
archived: false
phase: validation
brief:
  currentBehavior: mcp/servers.yaml 是唯一声明文件。变更映射虽然给每个 server 单独一条记录，但每条都指向同一路径，并标记 shared:true；commitProjectSelection 用 `git add -A -- <path>` 暂存整个文件，因此勾选其中一个 server 提交时，同一文件里其他 server 的变更会被一起提交，而界面仍把它们显示为待提交（审阅结果与实际提交不一致）。skills/index.yaml 存在同样问题。
  scope: dsh-plugin-project：MCP 声明的存储布局与读写、变更映射、逐条目提交的暂存构造、MCP 面板与工具、单元测试与原生验收。
  constraints:
    - 读双源：先 mcp/servers.yaml（既有数据），再 mcp/servers/*.yaml（同名 id 覆盖）；没有该目录时行为与今天完全一致
    - 写入一律走新格式 mcp/servers/<id>.yaml，不擅自迁移老文件
    - mcp/local.yaml（gitignored 的本机值）保持不动
    - 逐条目提交不得改写工作区：用 git hash-object -w + git update-index --cacheinfo 构造暂存内容
    - 沿用既有 Git 立场：不 force、不 rebase、不 stash、不跑 hooks；暂存区非空时拒绝提交
  outOfScope:
    - 技能本体的存储方式（已经是 skills/<name>/ 目录，无需改动）
    - 记忆与任务（一份文档 / 一个目录即一条，不存在共享文件问题）
    - mcp/local.yaml 的拆分
  acceptanceCriteria:
    - id: ac1
      text: MCP 声明支持 mcp/servers/<id>.yaml：新增与修改的 server 一律写入该目录
      required: true
      version: 1
    - id: ac2
      text: 读配置同时识别 mcp/servers.yaml（兼容既有项目）与 mcp/servers/*.yaml，同名 id 以后者为准，不强制迁移
      required: true
      version: 1
    - id: ac3
      text: 「项目资产」里每个 server 一条独立路径；勾选其中一个只提交该 server 的变更，不再连带同一文件里的其他 server 变更
      required: true
      version: 1
    - id: ac4
      text: 技能索引的逐技能提交同样只提交选中技能的状态变更，且不改写工作区
      required: true
      version: 1
    - id: ac5
      text: 单测覆盖双源读取、同名覆盖与逐条目暂存构造；yarn run check 通过
      required: true
      version: 1
    - id: ac6
      text: 中英文案、明暗主题、窄窗口的原生验收通过，证据落盘到任务 artifacts/
      required: true
      version: 1
handoff:
  nextSteps:
    - 本次改动尚未提交：插件仓库工作树（layout / mcp-config / changes / staging / api / controller / panel / 测试）与壳仓库工作树（native-resource-state-checks.mjs）都是脏的，等用户确认后一起提交。
    - MCP 面板文案仍写着「声明保存在 mcp/servers.yaml」（locales 的 mcpPanelBody），拆分后建议补一句「新建的声明写入 mcp/servers/<id>.yaml」。
    - 可选跟进：为旧项目提供一个显式的「把 legacy 声明迁移到每-server 文件」动作（本次刻意不做自动迁移）。
    - 如果要把这些改动带进发布：按 desktop-release 技能走 pin bump → 重导快照 → verify:upstream → 写 docs/releases/<version>.md 中英双语 → 推 tag。
references: []
entries:
  - id: dec-1
    kind: decision
    content: 设计定稿：布局新增 mcp/servers 目录（保留 servers.yaml 作为兼容读源）；store 读双源、同名 id 以每-server 文件优先；新增/修改写 mcp/servers/<id>.yaml（不动 legacy 文件）；删除时若命中的是每-server 文件则单独删，若只存在于 legacy 则重写 legacy；提交阶段的精确隔离留待 hash-object + update-index 处理 legacy 文件与 skills/index.yaml。
    basis: agent-proposal
    createdAt: 2026-09-22T10:56:56.930Z
  - id: prog-1
    kind: progress
    content: 阶段一（存储层）完成：project-layout.ts 新增 mcpServerDirectory；project-mcp-config.ts 的 readState 改为双源合并（legacy 先、每-server 后覆盖），新增 readLegacyServers/readServerFiles/readLocal/serverFilePath；upsert 改为先序列化校验再写单文件（保留原超限文案与跨文件回滚）；delete 按来源处理。插件 yarn check EXIT=0，271 tests 通过（新增双源与同名覆盖用例）。尚未改动变更映射与 resource-api 的 context，因此新格式的 server 还不会出现在「项目资产」里——这部分必须在下一轮补齐，否则界面看不到它。
    basis: observation
    createdAt: 2026-09-22T10:56:56.930Z
  - id: prog-2
    kind: progress
    content: 阶段二（变更映射）完成：parseMcpServers 改为接受「声明文件列表」并支持两种形态（legacy 的 {servers:[...]} 与每-server 文件里的单个对象），每个 server 记住自己的 source 路径；resource-api.ts 对 HEAD 与工作区都读双源（工作区走 readdir、HEAD 走 ls-tree + git show）；project-changes.ts 的 MCP 分支按 source 给出各自路径，只有仍住在 legacy 文件里的 id 才标 shared，并保留「文件字节变了、声明没变」的兜底条目。插件 yarn check EXIT=0，272 tests（新增「每-server 文件独占自己的路径、不拖动兄弟项」用例）。至此 MCP 新格式已实现路径隔离，但 legacy 文件与 skills/index.yaml 仍会连带提交，需阶段三解决。
    basis: observation
    createdAt: 2026-09-22T11:00:58.933Z
  - id: prog-3
    kind: progress
    content: 阶段三（实现）完成：resource-sync.ts 新增 StagedProjectFile/ProjectStagingResolver 与私有 stageContent——因为 GitRun 的 stdin 是关闭的，改用 mkdtemp 临时文件 + hash-object -w + update-index --add --cacheinfo 把精确字节写进暂存区，全程不碰工作区；commitProjectSelection 增加可选 resolveStaged 回调（带条目下标）并优先走精确暂存。/changes 的 schema 增加 id 与 kind，路由内重建工作区双源声明、用 findMcpDeclaration 算出「只含该 id 目标状态」的 legacy servers.yaml 内容，以及「只含该技能状态」的 skills/index.yaml 内容；project-changes.ts 导出 findMcpDeclaration；客户端 controller 与 Panel 提交时携带 id/kind。插件 yarn check EXIT=0，272 tests。
    basis: observation
    createdAt: 2026-09-22T11:04:01.196Z
  - id: ver-ac1
    kind: verification
    content: MCP 声明已支持每-server 文件：store 的 upsert 写 mcp/servers/<id>.yaml（先序列化校验再落盘，保留跨文件回滚），delete 按来源分流，layout 新增 mcpServerDirectory。
    basis: observation
    verification:
      criterionId: ac1
      criterionVersion: 1
      method: project-mcp-config.test.ts 用例验证 upsert 后声明落在 store.serverFilePath(id)，且超限时两个文件均未被修改；yarn check 全绿。
      result: passed
      coverage: 单测：写入路径、超限拒绝、回滚边界
    createdAt: 2026-09-22T11:08:33.382Z
  - id: ver-ac2
    kind: verification
    content: 读配置同时识别 legacy servers.yaml 与 mcp/servers/*.yaml，同名 id 以后者为准。
    basis: observation
    verification:
      criterionId: ac2
      criterionVersion: 1
      method: project-mcp-config.test.ts 新增用例：legacy 里两条均可见 → 编辑其一只写自己的文件且 legacy 不变 → 删掉遮蔽文件后回退到 legacy → 删除 legacy-only 的 id 才重写 legacy。project-changes.test.ts 另有用例验证每个 server 的 paths 指向它真正所在的文件。
      result: passed
      coverage: 单测：双源合并、同名覆盖、删除回退、变更映射 source
    createdAt: 2026-09-22T11:08:33.382Z
  - id: ver-ac3
    kind: verification
    content: 每个 server 一条独立路径，提交其中一个不再连带同文件里的其他 server 变更。
    basis: observation
    verification:
      criterionId: ac3
      criterionVersion: 1
      method: project-changes.test.ts 的集成用例：legacy 文件里同时把两个 server 改为 enabled:false，只提交 alpha——断言 HEAD 里 beta 仍为提交前状态、工作区仍保留两个改动（未被改写）。原生冒烟另断言 MCP 组同时出现 review-fixture / review-second（同一 legacy 文件）与 review-own（独立文件）三张卡片。
      result: passed
      coverage: 真实 git 集成测试 + 原生界面断言
    createdAt: 2026-09-22T11:08:33.382Z
  - id: ver-ac4
    kind: verification
    content: 技能索引的逐技能提交只包含选中技能的状态变更，且不改写工作区。
    basis: observation
    verification:
      criterionId: ac4
      criterionVersion: 1
      method: project-changes.test.ts 的集成用例：skills/index.yaml 里同时把 alpha 与 beta 改为 enabled:false，只提交 alpha——断言 HEAD 为 {alpha:false, beta:true}、工作区仍为 {alpha:false, beta:false}。
      result: passed
      coverage: 真实 git 集成测试
    createdAt: 2026-09-22T11:08:33.382Z
  - id: ver-ac5
    kind: verification
    content: 单测覆盖双源读取、同名覆盖与逐条目暂存构造，yarn check 通过。
    basis: observation
    verification:
      criterionId: ac5
      criterionVersion: 1
      method: "resources/dsh-plugin-project: yarn check EXIT=0，# tests 274 / # pass 274 / # fail 0；日志归档为 artifacts/unit-tests.log。"
      result: passed
      coverage: 274 条测试全绿（含 2 条真实 git 集成用例）
    createdAt: 2026-09-22T11:08:33.382Z
  - id: ver-ac6
    kind: verification
    content: 中英文案、明暗主题、1180/420 宽度的原生验收通过，证据落盘。
    basis: observation
    verification:
      criterionId: ac6
      criterionVersion: 1
      method: DSH_PROJECT_PLUGIN_SOURCE=../dsh-plugin-project yarn run smoke:resources EXIT=0；新增断言要求 MCP 组同时存在 review-fixture / review-second / review-own 三张卡片；8 组截图、result.json 与运行日志已复制到任务 artifacts/。
      result: passed
      coverage: smoke:resources EXIT=0，8 组 locale×theme×width 截图 + 新增 MCP 卡片断言
    createdAt: 2026-09-22T11:08:33.382Z
  - id: done-1
    kind: completion
    content: MCP 拆分与技能索引精确暂存均已实现并验证。
    basis: agent-proposal
    verificationEntryIds:
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - ver-ac6
    createdAt: 2026-09-22T11:08:33.382Z
operations:
  3fc6a4bc33c89fe585681823a507dce23cbf620a107874e55e1abf887bff2d7b:
    fingerprint: 8794899c82654d9802bd04b6c12e88075458bca0a72d77970b45c3ffc6ca54f8
    kind: create
    at: 2026-09-22T10:53:17.316Z
    entryIds: []
  f0f302a2f9ca5bfad0f854cb4b1dad23cdd8671b1fe7d3000bbb0f1dbf611cc4:
    fingerprint: f1c3540b9a4e07141b2bded811a9c9ecf86423355cb607376a08abfba03a8d5f
    kind: update
    at: 2026-09-22T10:56:56.930Z
    entryIds:
      - dec-1
      - prog-1
  a607148bb545a13a01576781286d322b32dd3135e9bf417b2ce0eda566eb26da:
    fingerprint: bd8465d2870d293e8df15f8fb9ca8076aaf3735397e213da5765df83f3d32832
    kind: update
    at: 2026-09-22T11:00:58.933Z
    entryIds:
      - prog-2
  84026f670d1496e0871bf35306789844126a1f25a7056c9800c5fc505aecaece:
    fingerprint: e36b11645986ebfd7cc6971ae2d0c546035524a2c9424de9688c49251f0ac790
    kind: update
    at: 2026-09-22T11:04:01.196Z
    entryIds:
      - prog-3
  fb6c56fe87504aa22c94fe973eba82e3569d620857155d02e57a565f5e024b81:
    fingerprint: 2d36fd520a1d42dca8b3ee58d34988d0b55c73a129f38791a25bedafce8254ee
    kind: update
    at: 2026-09-22T11:08:33.382Z
    entryIds:
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - ver-ac6
      - done-1
criterionVersions:
  ac1: 1
  ac2: 1
  ac3: 1
  ac4: 1
  ac5: 1
  ac6: 1
---

已完成并验证。MCP 声明改为每个 server 一个文件：本机读写走 mcp/servers/<id>.yaml，同时兼容读既有的 mcp/servers.yaml（同名 id 以每-server 文件为准），不做强制迁移；对于仍住在 legacy 文件里的声明，以及技能索引 skills/index.yaml，逐条目提交改为用 git hash-object -w + update-index --cacheinfo 把「只含选中项」的精确字节写进暂存区，全程不改写工作区。关键实现点：GitRun 的 stdin 是关闭的，所以内容经临时文件传递；commitProjectSelection 新增 resolveStaged 回调（带条目下标）让 API 层按 kind/id 计算目标内容；/changes 的 schema 增加 id 与 kind。验证：插件 yarn check EXIT=0（274 tests，含两条真实 git 集成用例：legacy 里两条 server 只提交其一后 HEAD 中另一条保持原状且工作区两个改动完好；技能索引同理）；原生冒烟 smoke:resources EXIT=0，新增断言要求 MCP 组同时出现 review-fixture / review-second（共享 legacy 文件）与 review-own（独立文件）三张卡片，8 组 locale×theme×width 证据已落盘任务 artifacts/。限制：MCP 面板文案尚未更新以说明新写入位置；未提供 legacy 声明的自动迁移动作；改动尚未提交到两个仓库。
