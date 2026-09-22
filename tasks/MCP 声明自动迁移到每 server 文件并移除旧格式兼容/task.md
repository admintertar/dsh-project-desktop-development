---
schemaVersion: 3
directory: MCP 声明自动迁移到每 server 文件并移除旧格式兼容
id: task-24cc34e0-f655-4f01-bd3c-820ffe09319f
title: MCP 声明自动迁移到每 server 文件并移除旧格式兼容
objective: 把 MCP 声明迁移到每-server 文件并彻底移除旧格式兼容：项目打开时自动把 mcp/servers.yaml 拆成 mcp/servers/<id>.yaml（先全部写入成功再删旧文件，失败则保留），之后只读新格式；同时删除为实现双源兼容而保留的 legacy 读取、shared 标记与 legacy 精确暂存代码，并补齐单测与原生验收。
status: completed
createdAt: 2026-09-22T11:10:13.753Z
updatedAt: 2026-09-22T11:20:53.683Z
artifacts:
  - type: file
    path: artifacts/project-changes-zh-light-1180.png
    description: 中文/浅色/1180px：任务、技能、MCP 三组卡片（均为新格式）
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
    description: 提交后：资产离开审阅
  - type: file
    path: artifacts/native-smoke-result.json
    description: 原生冒烟完整结果
  - type: file
    path: artifacts/native-smoke-run.log
    description: smoke:resources 运行日志（EXIT=0）
  - type: file
    path: artifacts/unit-tests.log
    description: 插件 yarn check 日志（275 tests 全绿）
archived: false
phase: validation
brief:
  currentBehavior: 上一轮实现了 mcp/servers/<id>.yaml 与 mcp/servers.yaml 双源读取（同名 id 以每-server 文件为准）且不迁移。旧文件里的声明仍能工作，但代码里保留了 legacy 读取分支、shared 标记与专门为 legacy 文件服务的 hash-object 暂存路径。
  scope: dsh-plugin-project：MCP 声明的迁移与存储层、变更映射、资源 API 的上下文读取、单元测试与原生验收。
  constraints:
    - 迁移先写全部新文件、全部成功后才删旧文件；任一失败保留旧文件不动
    - 迁移幂等：旧文件不存在或无法解析时不做任何写入，也不报错阻断项目打开
    - 迁移后旧文件删除会出现在「项目资产」里，作为迁移的可见结果（或者被显式忽略，二选一并保持一致）
    - mcp/local.yaml（gitignored 本机值）不参与迁移也不改动
    - 沿用既有 Git 立场：不 force、不 rebase、不 stash、不跑 hooks
  outOfScope:
    - 技能索引 skills/index.yaml 的存储方式（它仍靠 hash-object 精确暂存，本次不动）
    - mcp/local.yaml 的格式或拆分
    - 为旧版本 DSH 提供反向兼容
  acceptanceCriteria:
    - id: ac1
      text: 打开含 mcp/servers.yaml 的项目时，为每个 server 生成 mcp/servers/<id>.yaml，全部写入成功后再删除旧文件
      required: true
      version: 1
    - id: ac2
      text: 迁移幂等：重复打开不再产生变更；无 server 的空旧文件也会被清理
      required: true
      version: 1
    - id: ac3
      text: 只读新格式：删掉双源读取、shared 标记与 legacy 精确暂存路径；每个 server 一条独立路径
      required: true
      version: 1
    - id: ac4
      text: 迁移失败不破坏旧文件：先写新文件、全部成功才删，任一失败则保留旧文件
      required: true
      version: 1
    - id: ac5
      text: 单测覆盖迁移、幂等、失败保护与变更映射；yarn check 通过
      required: true
      version: 1
    - id: ac6
      text: 原生验收（中英文案/明暗主题/窄窗口）通过，证据落盘到任务 artifacts/
      required: true
      version: 1
handoff:
  nextSteps:
    - 本次改动已提交但未推送：插件 5e6e280（迁移与去兼容）、7fa9925（测试与示例项目适配）；壳 3ffa8ab、00f6580（原生验收 fixture）。要不要推送等用户决定。
    - 破坏性变更的发布说明：旧版 DSH 将读不到迁移后的声明，写下一版发布说明时需要明确告知。
    - 如需把这些带进发布：按 desktop-release 技能走 pin bump → 重导快照 → verify:upstream → 中英双语发布说明 → 推 tag。
    - 可选跟进：为迁移写一条可见提示或日志（目前迁移是静默的，只在工作区产生删除与新增变更）。
references: []
entries:
  - id: dec-0
    kind: decision
    content: 用户决定：MCP 声明自动迁移到每-server 文件，并且不再兼容旧的 mcp/servers.yaml 格式。
    basis: user-request
    createdAt: 2026-09-22T11:10:13.753Z
  - id: dec-1
    kind: decision
    content: 实施要点：(1) 迁移放在 ensureProjectLayout 里，先逐个写入 mcp/servers/<id>.yaml，全部成功后才删除 mcp/servers.yaml，任一失败保留旧文件；(2) 迁移幂等，无法解析的旧文件不阻断项目打开；(3) 删除 readLegacyServers/commitLegacy、变更映射里的 legacy 分支与 shared 标记、project-staging 的 stageMcpDeclaration（skills/index.yaml 的 stageSkillIndex 保留）；(4) 迁移后的旧文件删除若落入「其他文件」会造成噪音，计划在变更映射里显式跳过 mcp/servers.yaml。
    basis: agent-proposal
    createdAt: 2026-09-22T11:10:13.753Z
  - id: prog-1
    kind: progress
    content: 迁移与去兼容的实现已落地且编译通过（无 TS 错误）：ProjectMcpConfigStore 构造时调用 migrateLegacyDeclarations（先逐个写 mcp/servers/<id>.yaml，已存在的同名文件不覆盖，全部写完后 rmSync 旧文件；解析失败则原样保留不阻断）；readState 只读每-server 文件；delete 只删自己的文件；project-layout 不再创建 servers.yaml；project-changes 删除了 MCP_DECLARATION/shared 与 legacy 分支并显式跳过 mcp/servers.yaml；resource-api 只读目录、resolveStaged 仅保留技能索引；project-staging 只留 stageSkillIndex；locales 更新了 mcpPanelBody 并删掉 changeSharedFile。
    basis: observation
    createdAt: 2026-09-22T11:13:28.581Z
  - id: prog-2
    kind: progress
    content: 但 yarn check 仍为红：274 tests / 263 pass / 11 fail。失败清单：project api preserves, replaces and clears MCP secrets…；a declaration change with no server-level difference still appears in the review；an existing single-file declaration is migrated to one file per server；new project files initialize shareable metadata…；project capability directories are created without replacing existing content；a new gitignore respects umask…；project mcp config rejects duplicate identities…；project mcp config validates URL, timeout, reconnect and secret placement；project mcp config rolls back the public file…；project mcp config reads the legacy file and lets a per-server file shadow it by id；Demo Web capabilities survive reopening without rewriting project files。已定位两个原因：(1) 迁移测试的 server 数据缺 transport/command 等必填字段，publicSchema.parse 失败后走了「保留旧文件」分支，属测试数据问题（但该静默路径需复查）；(2) 「声明字节变了但声明未变」的兜底条目期待 1 条却得 0 条，可能是实现缺陷，需读代码确认。原生验收尚未重启。
    basis: observation
    createdAt: 2026-09-22T11:13:28.581Z
  - id: ver-ac1
    kind: verification
    content: 迁移实现：ProjectMcpConfigStore 构造时调用 migrateLegacyDeclarations——先对每个声明写 mcp/servers/<id>.yaml（已存在同名文件则跳过），全部写完后才 rmSync 旧文件；旧文件无法解析时原样保留且不抛错。测试用「两个合法声明 + 重复打开 + 空旧文件」三种情形覆盖。
    basis: observation
    verification:
      criterionId: ac1
      criterionVersion: 1
      method: "project-mcp-config.test.ts：写入含两个合法声明的 mcp/servers.yaml，构造 store 后断言旧文件消失、两个新文件存在且 list() 顺序与内容不变；再次构造 store 断言结果一致；另一个用例写入 servers: [] 断言旧文件同样被清理且不产生服务器。"
      result: passed
      coverage: 单测：迁移、幂等、空文件清理
    createdAt: 2026-09-22T11:20:53.683Z
  - id: ver-ac2
    kind: verification
    content: 幂等与空旧文件清理均已覆盖，且迁移不依赖是否还有声明。
    basis: observation
    verification:
      criterionId: ac2
      criterionVersion: 1
      method: 同一用例内二次构造 store 后断言 list() 不变且旧文件仍不存在；空声明用例断言 list() 为空且旧文件被删除。
      result: passed
      coverage: 单测：重复打开无副作用、空旧文件被清理
    createdAt: 2026-09-22T11:20:53.683Z
  - id: ver-ac3
    kind: verification
    content: 只读新格式：双源读取、shared 标记与 legacy 精确暂存全部删除；旧文件在变更映射里被显式跳过。
    basis: observation
    verification:
      criterionId: ac3
      criterionVersion: 1
      method: project-changes.test.ts：三个声明分居三个文件时每个条目的 paths 恰好是自己的文件；新增用例断言 mcp/servers.yaml 无论 deleted 还是 modified 都产生 0 条条目。resource-api 的上下文与 resolveStaged 已只剩新格式与技能索引路径。
      result: passed
      coverage: 单测：每个声明一条独立路径，旧文件不成为资产
    createdAt: 2026-09-22T11:20:53.683Z
  - id: ver-ac4
    kind: verification
    content: 迁移失败不破坏旧文件：无法解析时既不改写也不删除，且不抛错阻断项目打开。
    basis: observation
    verification:
      criterionId: ac4
      criterionVersion: 1
      method: "project-mcp-config.test.ts 用例写入非法声明（- {id: broken}），构造 store 后断言旧文件仍存在、list() 为空、构造过程未抛错。"
      result: passed
      coverage: 单测：非法旧文件保持原样
    createdAt: 2026-09-22T11:20:53.683Z
  - id: ver-ac5
    kind: verification
    content: 单测与示例项目全部适配新格式，yarn check 通过。
    basis: observation
    verification:
      criterionId: ac5
      criterionVersion: 1
      method: "resources/dsh-plugin-project: yarn check EXIT=0，# tests 275 / # pass 275 / # fail 0，日志归档为 artifacts/unit-tests.log。示例项目改用 mcp/servers/.gitkeep 保留目录并删除空的旧文件。"
      result: passed
      coverage: 275 条测试全绿（含迁移/幂等/失败保护/变更映射用例）
    createdAt: 2026-09-22T11:20:53.683Z
  - id: ver-ac6
    kind: verification
    content: 原生验收通过，fixture 已改用每-server 文件，证据落盘。
    basis: observation
    verification:
      criterionId: ac6
      criterionVersion: 1
      method: DSH_PROJECT_PLUGIN_SOURCE=../dsh-plugin-project yarn run smoke:resources EXIT=0；fixture 把 review-fixture / review-second / review-own 写成三个独立文件并断言三张卡片同时出现；8 组截图、result.json、运行日志与单测日志已归档到任务 artifacts/（14 个文件）。
      result: passed
      coverage: smoke:resources EXIT=0，8 组 locale×theme×width + 三张 MCP 卡片断言
    createdAt: 2026-09-22T11:20:53.683Z
  - id: done-1
    kind: completion
    content: MCP 每-server 迁移与去兼容已实现并通过单测与原生验收。
    basis: agent-proposal
    verificationEntryIds:
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - ver-ac6
    createdAt: 2026-09-22T11:20:53.683Z
operations:
  4ed99e81816e103e1bf1a46ae13582258665a99e25edc9c7c8a67e9978e2ba39:
    fingerprint: 3688996d1c9de28bfb8030b1f3469ddcee31bdf61bc1b7de96a5e895c82e01f6
    kind: create
    at: 2026-09-22T11:10:13.753Z
    entryIds:
      - dec-0
      - dec-1
  2ee2077139f927c3bd67e37c32b3d008cd9d036af15bf8666d4b480eb0f9e6de:
    fingerprint: 166fa6c25ab4f8970b8a3906da40a29592a7cb9bb04ada8068f966db53630775
    kind: update
    at: 2026-09-22T11:13:28.581Z
    entryIds:
      - prog-1
      - prog-2
  d0bbacbcec488928a950c2991557b80ae153bb7cbbccfdaa859a21deee9b7aa9:
    fingerprint: 79511d145de92df231213419bc02eb9de6576e3810f33e63e992d9af8d34062e
    kind: update
    at: 2026-09-22T11:20:53.683Z
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

已完成并验证。MCP 声明现在一个 server 一个文件（mcp/servers/<id>.yaml）：项目打开时自动把旧的 mcp/servers.yaml 拆分过去——先逐个写入新文件（同名不覆盖），全部成功后才删除旧文件；旧文件无法解析时原样保留且不阻断项目打开；空旧文件也会被清理。读取、删除、变更映射与 API 上下文全部只认新格式，为此删除了双源读取、shared 标记、legacy 精确暂存路径与相关文案；mcp/servers.yaml 在变更映射里被显式跳过，迁移残留不会变成待审阅资产。技能索引 skills/index.yaml 的逐技能精确暂存（git hash-object -w + update-index --cacheinfo）保持不变。验证：插件 yarn check EXIT=0（275 tests，含迁移、幂等、空文件、失败保护、变更映射路径隔离与技能索引精确提交等用例）；原生冒烟 smoke:resources EXIT=0，fixture 改为三个独立声明文件并断言三张 MCP 卡片，8 组 locale×theme×width 证据已落盘任务 artifacts/。示例项目已迁移并保留 mcp/servers/ 目录，文档与类型注释同步更新。限制：迁移是静默的（没有界面提示），且这是破坏性变更——迁移后旧版本 DSH 读不到这些声明；所有改动已提交但未推送。
