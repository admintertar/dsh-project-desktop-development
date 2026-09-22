---
schemaVersion: 3
directory: 项目资产变更审阅：按任务-技能-记忆-MCP 分组提交
id: task-061b9b3a-15bc-47c3-a54f-016e58130124
title: 项目资产变更审阅：按任务/技能/记忆/MCP 分组提交
objective: 把项目概览页的项目根 Git 能力从「仓库级提交」改造为「项目资产级变更审阅」：按任务/技能/记忆/MCP/其他文件分组列出新增、更新、删除的条目卡片，逐条勾选后只提交选中项，提交信息按资产类型自动生成；分支、领先落后与推送降级为区块顶部的同步状态行与详情入口。底层仍复用项目根仓库 Git，但用户面对的是项目资产而非文件 diff。
status: completed
createdAt: 2026-09-22T03:18:33.678Z
updatedAt: 2026-09-22T09:11:54.556Z
artifacts:
  - type: file
    path: artifacts/project-changes-zh-light-1180.png
    description: 进行中反馈（转圈 + 进行时文案）与最新布局
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
    description: 工具栏：全选 / 清空 / 提交按钮
  - type: file
    path: artifacts/project-changes-after-commit.png
    description: 提交后：两个资产离开审阅
  - type: file
    path: artifacts/native-smoke-result.json
    description: 原生冒烟完整结果（含 section 诊断行）
  - type: file
    path: artifacts/native-smoke-run.log
    description: smoke:resources 运行日志（EXIT=0）
  - type: file
    path: artifacts/project-changes-plan-tooltip.png
    description: 提交按钮悬浮气泡（按钮右侧）
archived: false
phase: validation
brief:
  currentBehavior: 项目概览页的「项目仓库」区块把项目根当成普通 Git 仓库：显示分支/dirty/领先落后，提交固定为全部改动且提交信息由用户手填，不区分仓库里装的是任务、技能、记忆还是 MCP，也不支持选择性提交。
  scope: dsh-plugin-project：项目根变更的资产级映射（tasks/skills/memory/mcp/其他文件）、按路径提交的 Host 能力、概览页「项目变更」审阅视图与同步状态行、中英双语文案、单元测试与原生验收。
  constraints:
    - 提交路径必须限制在项目根内：拒绝绝对路径、.. 段与控制字符
    - 同一文件内的多条变更（mcp/servers.yaml、skills/index.yaml）无法分开提交，UI 必须写明
    - 沿用既有 Git 立场：不 force、不 rebase、不 stash、不跑 hooks、push 仅快进
    - 未经明确要求不 push 到任何远端
  outOfScope:
    - 项目根的 git init 与远端关联
    - 暂存区（index）级别的手工编辑；选择粒度止于条目对应的路径集合
    - 记忆条目的新增入口（既有缺陷，另行排期）
  acceptanceCriteria:
    - id: ac1
      text: 概览页新增「项目变更」区块：按任务/技能/记忆/MCP/其他文件分组，每条目一张卡片并标明新增/更新/删除
      required: true
      version: 1
    - id: ac2
      text: 每条卡片可勾选，支持只提交选中项；提交信息按资产类型自动生成且可编辑
      required: true
      version: 1
    - id: ac3
      text: 底层仍是项目根仓库 Git（不 force/rebase/stash、不跑 hooks）；分支/推送/同步降级为区块顶部状态行与详情入口
      required: true
      version: 1
    - id: ac4
      text: 无法识别的文件进入「其他文件」组且默认不勾选，不静默丢弃任何变更
      required: true
      version: 1
    - id: ac5
      text: 中英文案、浅色/深色、窄窗口与键盘行为经原生视觉验收，证据落盘到任务 artifacts/
      required: true
      version: 1
    - id: ac6
      text: 变更映射与提交路径校验有测试覆盖，yarn run check（typecheck + test + build）通过
      required: true
      version: 1
handoff:
  nextSteps:
    - 环境陷阱（重要）：壳加载的插件产物在 .cache/runtime/dsh-plugin-project，不带 DSH_PROJECT_PLUGIN_SOURCE 的壳构建（普通 yarn check / 并发会话）会把它覆盖成 pin 版本，于是开发中的界面会“缺一块”。排查时先比对产物标记（如 grep -c project-change-card .cache/runtime/dsh-plugin-project/lib/client.js），必要时重新带变量 build。
    - 真实工作区复验：在仓库详情里点「检查更新」与「推送提交」确认成功路径（fixture 远端不可达，需人工确认；推送会真写到 GitHub）。
    - 发布时才需要：先 push 插件提交，再把 upstream.lock.json 的 project.commit/tree 指到该已推送提交，删除 .upstream/project 后重导并跑 yarn run verify:upstream。
    - 本地已提交待推送：插件 0dc817e、7f7c986、51c8524；壳 47282ef、4d80d42、31f319b。
    - 验收手法备注：隐藏窗口下 sendInputEvent 的连续合成按键会偶发丢失，两次连续按键应改用一次按键 + 一次 click。
    - MCP 多 server 共享 mcp/servers.yaml：各自成为一个提交但每个提交都带上整个文件，需 partial staging 才能路径级隔离。
references: []
entries:
  - id: dec-1
    kind: decision
    content: 用户否决了「把项目根当普通 Git 仓库」的呈现：这个仓库里装的是结构化项目资产（任务/技能/记忆/MCP），界面应直接说「新增了一条任务」「某个技能被改了」并逐条询问是否提交，git 是实现细节。已确认方向：改成「项目资产变更」审阅视图，并把上一任务的「项目仓库」卡片降为区块顶部的同步状态行。
    basis: user-request
    createdAt: 2026-09-22T03:18:33.678Z
  - id: inv-1
    kind: progress
    content: "资产布局（代码依据）：任务在 tasks/<directory>/task.md（frontmatter 含 title/status/phase/artifacts，目录名经清洗但与标题不完全相同）；技能在 skills/index.yaml（{skills: {<name>: {enabled}}}）+ skills/<name>/SKILL.md；记忆是 manifest memory[] 声明的 memory/<path>；MCP 在 mcp/servers.yaml（servers: [{id, serverName, ...}]）与 mcp/local.yaml（被 gitignore）。因此条目聚合可以基于 git status 路径前缀 + 既有 ProjectTaskStore/ProjectMcpConfigStore 解析，不需要另写解析器。"
    basis: observation
    createdAt: 2026-09-22T03:18:33.678Z
  - id: dec-2
    kind: decision
    content: 映射设计：按 git status 的仓库相对路径前缀聚合到条目（tasks/<dir> → 任务、skills/<name> → 技能、memory/<path> → 记忆（经 manifest memory[] 映射显示名）、mcp/servers.yaml → 按 server id 拆分展示、其余 → 其他文件）；条目内全为 added/untracked 则为「新增」，全为 deleted 则为「删除」，其余为「更新」。MCP 多个 server 共享一个文件，卡片上明写提交整文件。
    basis: agent-proposal
    createdAt: 2026-09-22T03:18:33.678Z
  - id: prog-1
    kind: progress
    content: 实现落点：新增 src/project-changes.ts（纯映射：路径前缀→任务/技能/记忆/MCP/其他文件，MCP 按 server 拆分，未识别路径保留为 file 条目；safeChangePath 路径校验）与 tests/project-changes.test.ts；resource-sync.ts 新增 commitProjectPaths（git add -A -- <paths> + 不跑 hooks 的 commit，拒绝已暂存内容的 index）并把项目根改为 --untracked-files=all 读取（缓存按模式分开）；resource-contract.ts 新增 git-index-dirty；resource-api.ts 新增 GET/POST /api/project/repository/changes 并从 repositorySchema 移除 commit；project.ts 的 MemoryView 补 path；客户端新增 project-changes-controller.ts 与 ProjectChangesPanel.tsx（同步状态行 + 分组卡片 + 勾选 + 自动提交信息 + 仓库详情弹窗），ProjectControls.tsx 新增 ProjectCheckbox（官方 primitives 未导出 Checkbox，用原生 input + 主题变量适配），删除上一任务的 ProjectRepositoryCard 并回退 ResourceCard 的 kindLabel。
    basis: observation
    createdAt: 2026-09-22T03:30:46.247Z
  - id: ver-ac1
    kind: verification
    content: 概览页按项目资产分组展示变更，而非普通 Git 仓库视图。
    basis: observation
    verification:
      criterionId: ac1
      criterionVersion: 1
      method: smoke:resources 在真实 Electron 窗口读实时 DOM：概览页「项目变更」区块按 任务/技能/MCP/其他文件 分组；任务卡片显示 task.md 的 title（Native review fixture）而非目录名，技能卡片显示 review-fixture，MCP 卡片显示 server 名；8 组 locale×theme×width 截图落盘。
      result: passed
      coverage: zh/en × light/dark × 1180/420，共 8 组
    createdAt: 2026-09-22T03:30:46.247Z
  - id: ver-ac2
    kind: verification
    content: 可勾选条目并只提交选中项，提交信息按类型自动生成。
    basis: observation
    verification:
      criterionId: ac2
      criterionVersion: 1
      method: "原生冒烟：点「清空」后提交按钮 disabled；只勾选任务行 → 提交信息自动变为 feat(task): 收录「Native review fixture」；点提交后真实执行 git commit，git log -1 与该信息一致，git show --name-only HEAD 只包含 tasks/ 路径，未勾选的技能/MCP/其他文件仍在 git status 中。tests/project-changes.test.ts 断言 commitProjectPaths 只 stage 选中路径，并拒绝空选择、不安全路径、空提交信息、过期 revision 与已有暂存内容（git-index-dirty）。"
      result: passed
      coverage: 原生端到端提交 + 7 个 Host 单测
    createdAt: 2026-09-22T03:30:46.247Z
  - id: ver-ac3
    kind: verification
    content: 仓库级操作降级为同步状态行，不再提供「提交全部改动」。
    basis: observation
    verification:
      criterionId: ac3
      criterionVersion: 1
      method: 原生冒烟断言区块顶部只有分支、同步状态、「检查更新」、「仓库详情」与右上角刷新；API 层 repositorySchema 移除 commit 动作，POST /api/project/repository 的 commit 返回 422（tests/resource-api.test.ts）；分支切换保留在「仓库详情」弹窗；提交仍沿用不 force、不 rebase、不 stash、不跑 hooks 的既有约定。
      result: passed
      coverage: 原生 DOM 断言 + API 契约测试
    createdAt: 2026-09-22T03:30:46.247Z
  - id: ver-ac4
    kind: verification
    content: 无法识别的文件进入「其他文件」且默认不勾选，变更不被静默丢弃。
    basis: observation
    verification:
      criterionId: ac4
      criterionVersion: 1
      method: tests/project-changes.test.ts 断言未识别路径进入 file 条目、全删条目报删除、部分删除报更新；safeChangePath 拒绝绝对路径、.. 段、盘符、控制字符与空段。原生冒烟断言「其他文件」组存在（.gitignore、AGENT.md）且其 checkbox 默认未勾选，任务/技能/MCP 默认勾选。
      result: passed
      coverage: 映射单测 + 原生默认选中断言
    createdAt: 2026-09-22T03:30:46.247Z
  - id: ver-ac5
    kind: verification
    content: 中英文案、主题、窄窗与键盘行为经原生视觉验收，证据落盘。
    basis: observation
    verification:
      criterionId: ac5
      criterionVersion: 1
      method: smoke:resources 覆盖 zh/en × light/dark × 1180/420 共 8 组，断言区块与组标题、条目名、状态标签、body 无横向溢出、条目行在视口内；在 zh/dark 组合下用 Electron sendInputEvent 对聚焦后的 checkbox 发送两次 Space，断言勾选状态 false→true 且提交信息随之恢复；11 张 PNG、result.json 与运行日志写入 tasks/项目资产变更审阅：按任务-技能-记忆-MCP 分组提交/artifacts/。
      result: passed
      coverage: 8 组视觉组合 + 2 次 Space 键盘验证
    createdAt: 2026-09-22T03:30:46.247Z
  - id: ver-ac6
    kind: verification
    content: 插件 typecheck、测试与构建全部通过。
    basis: observation
    verification:
      criterionId: ac6
      criterionVersion: 1
      method: cd resources/dsh-plugin-project && yarn check（typecheck + tsx --test + build），266 tests / 0 fail / EXIT=0；新增 tests/project-changes.test.ts（映射、路径校验、按选择提交、拒绝不安全输入）。
      result: passed
      coverage: 266 个测试（较上一任务 +8）与构建
    createdAt: 2026-09-22T03:30:46.247Z
  - id: done-1
    kind: completion
    content: ac1–ac6 全部通过：概览页现在以项目资产（任务/技能/记忆/MCP/其他文件）为单位审阅变更并选择性提交，仓库级操作降为同步状态行与详情入口。
    basis: agent-proposal
    verificationEntryIds:
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - ver-ac6
    createdAt: 2026-09-22T03:30:46.247Z
  - id: prog-2
    kind: progress
    content: 用户反馈三项修正：(1) 区块改名「项目变更」→「项目空间变更」；(2) 条目改为卡片式（网格、选中态边框、底部勾选行）；(3) 追问「其他文件」里的乱码。第三项是真实缺陷：Git 对含非 ASCII 的路径做 C-quoting，中文任务目录被写成八进制转义（tasks/351/241/…），既显示为乱码、又因前缀不匹配而错误落入「其他文件」。
    basis: user-request
    createdAt: 2026-09-22T05:53:54.249Z
  - id: ver-fix-1
    kind: verification
    content: 中文资产目录现在以真实路径进入审阅并归到正确的组。
    basis: observation
    verification:
      criterionId: ac1
      criterionVersion: 1
      method: 修复：inspect 的 status 命令加 -c core.quotePath=false，并新增 unquotePath 解码兜底；tests/project-changes.test.ts 新增非 ASCII 路径用例（tasks/中文任务/task.md → task:中文任务）。原生冒烟用中文目录「中文验收样例」重建 fixture，断言任务卡片名取 task.md 的 title、卡片路径等于 tasks/中文验收样例（无转义），且区块标题为「项目空间变更」；卡片式布局在 8 组 locale×theme×width 下截图。
      result: passed
      coverage: 解码单测 + 原生中文目录断言 + 8 组视觉
    createdAt: 2026-09-22T05:53:54.249Z
  - id: ver-fix-2
    kind: verification
    content: 修正后重新跑通端到端提交与键盘验证。
    basis: observation
    verification:
      criterionId: ac2
      criterionVersion: 1
      method: "smoke:resources EXIT=0：清空→只勾选中文任务卡片→提交信息自动变为 feat(task): 收录「Native review fixture」→提交后 git log -1 一致，且 git show --name-only（脚本侧同样关 quotePath）只含 tasks/中文验收样例/task.md，未勾选的技能/MCP/其他文件仍在工作树；再用两次真实 Space 验证复选框键盘语义。"
      result: passed
      coverage: 真实提交（含中文任务目录）+ 两次 Space
    createdAt: 2026-09-22T05:53:54.249Z
  - id: done-2
    kind: completion
    content: 用户反馈的三项修正（区块改名「项目空间变更」、条目卡片式、中文路径不再转义）均已实现并验证通过。
    basis: agent-proposal
    verificationEntryIds:
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - ver-ac6
      - ver-fix-1
      - ver-fix-2
    createdAt: 2026-09-22T05:53:54.249Z
  - id: prog-3
    kind: progress
    content: 用户重申资产维度：(1) 一张卡片 = 一个资产，且资产可含多个文件（技能是整个技能文件夹、任务是 task.md 加全部附件、MCP 是一条配置）；(2) 卡片要标识新增/更新；(3) 可单独提交也可全选提交；(4) 提交信息应完全自动生成，不需要用户输入。
    basis: user-request
    createdAt: 2026-09-22T05:59:04.013Z
  - id: dec-3
    kind: decision
    content: 确认现有映射已按资产聚合：tasks/<目录> 下所有路径合成一条（task.md + artifacts/*），skills/<技能名>/* 合成一条，MCP 按 server id 一条，记忆每个文档一条；本次新增卡片上的「N 个文件」显示（多文件时才出现，与产物数并列），让「一个资产包含多个文件」可见。
    basis: agent-proposal
    createdAt: 2026-09-22T05:59:04.013Z
  - id: ver-fix-3
    kind: verification
    content: 提交信息已改为完全自动生成、无输入框。
    basis: observation
    verification:
      criterionId: ac2
      criterionVersion: 1
      method: "客户端移除提交信息 textarea 与草稿状态，改为只读展示（标题 + 「按所选资产自动生成」 + 信息文本）；原生冒烟把 fixture 任务改为「task.md + artifacts/evidence.md」两个文件，断言卡片文本包含「2 个文件」，并在清空→只勾该资产后断言只读信息等于 feat(task): 收录「Native review fixture」；提交后 git show --name-only 只含 tasks/中文验收样例 下的两个文件，未勾选的技能/MCP/其他文件仍在工作树。"
      result: passed
      coverage: 原生：多文件资产断言 + 只读自动信息 + 端到端提交
    createdAt: 2026-09-22T05:59:04.013Z
  - id: done-3
    kind: completion
    content: 资产维度、卡片式呈现、多文件归属、自动提交信息均已实现并验证。
    basis: agent-proposal
    verificationEntryIds:
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - ver-ac6
      - ver-fix-1
      - ver-fix-2
      - ver-fix-3
    createdAt: 2026-09-22T05:59:04.013Z
  - id: prog-4
    kind: progress
    content: 用户第三批反馈：(1) 变更卡片样式必须与资源页卡片保持一致（项目有统一要求）；(2) 仓库状态行（分支/领先/检查更新/推送/仓库详情）目前在右侧，应移到左侧。
    basis: user-request
    createdAt: 2026-09-22T06:08:36.770Z
  - id: dec-4
    kind: decision
    content: 一致性做法：不再自建卡片外壳，改用共享适配——卡片用 .project-mcp-card（与工具/MCP/技能/资源卡同一套圆角、边框、hover），body 用 .project-mcp-card-body，footer 用 .project-mcp-card-footer，网格改用 .project-mcp-grid；只保留选中态边框与 footer 左对齐两处语义覆盖。
    basis: agent-proposal
    createdAt: 2026-09-22T06:08:36.770Z
  - id: ver-fix-4
    kind: verification
    content: 卡片样式已与资源/技能/MCP 卡片统一，状态行已左对齐。
    basis: observation
    verification:
      criterionId: ac1
      criterionVersion: 1
      method: 变更卡片复用 .project-mcp-card / .project-mcp-card-body / .project-mcp-card-footer / .project-mcp-grid（与资源页同一套共享样式），仅保留 [data-selected] 边框与 footer 左对齐两处覆盖；状态行右偏的根因是共享的 .project-resource-branch{margin-left:auto}，在 .project-change-sync 内覆盖为 margin-left:0。原生冒烟新增断言：状态行左边缘与区块左边缘相差不超过 2px，并在 zh/en × light/dark × 1180/420 共 8 组下重新截图对照。
      result: passed
      coverage: 原生 DOM 断言 + 8 组视觉对照
    createdAt: 2026-09-22T06:08:36.770Z
  - id: done-4
    kind: completion
    content: 卡片样式统一与状态行左对齐已完成并验证。
    basis: agent-proposal
    verificationEntryIds:
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - ver-ac6
      - ver-fix-1
      - ver-fix-2
      - ver-fix-3
      - ver-fix-4
    createdAt: 2026-09-22T06:08:36.770Z
  - id: prog-5
    kind: progress
    content: 用户第四批反馈：把「分支」与「同步状态标签」从单独的状态行移到「项目空间变更」标题后面，与标题同行。
    basis: user-request
    createdAt: 2026-09-22T06:13:10.761Z
  - id: dec-5
    kind: decision
    content: 结构上把区块标题行交给 ProjectChangesPanel 自己渲染（.project-card-top 内为 .project-change-title[h2 + 分支 + 状态标签] + 刷新按钮），index.tsx 不再重复渲染标题行；仓库动作（检查更新/推送提交/仓库详情）单独一行保留在标题下方。
    basis: agent-proposal
    createdAt: 2026-09-22T06:13:10.761Z
  - id: ver-fix-5
    kind: verification
    content: 分支与同步状态已与标题同行；窄窗下自然换行，已按宽度分级断言。
    basis: observation
    verification:
      criterionId: ac1
      criterionVersion: 1
      method: 原生冒烟在宽面板（≥700px）下断言分支与状态标签的垂直区间与 h2 重叠（即同一行），窄窗下不要求同行（面板仅 133px 时标题会换行，属正常响应式行为）；8 组 locale×theme×width 重新截图。发现并修正了两处测试自身的误判：先按 top 差值比较（字号不同天然差 7px），后改为区间重叠并加宽度门限。
      result: passed
      coverage: 原生 DOM 同行断言（宽面板）+ 8 组视觉
    createdAt: 2026-09-22T06:13:10.761Z
  - id: done-5
    kind: completion
    content: 分支与状态标签已移到标题后，仓库动作保留独立一行。
    basis: agent-proposal
    verificationEntryIds:
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - ver-ac6
      - ver-fix-1
      - ver-fix-2
      - ver-fix-3
      - ver-fix-4
      - ver-fix-5
    createdAt: 2026-09-22T06:13:10.761Z
  - id: prog-6
    kind: progress
    content: 用户指出标题行的样式没有对齐：标题、分支与状态标签垂直方向不一致。
    basis: user-request
    createdAt: 2026-09-22T06:19:16.601Z
  - id: ver-fix-6
    kind: verification
    content: 根因是 h2 的浏览器默认 margin 与未声明的行高，使标题的盒子比其他两个元素高；已设 margin:0 与 line-height:24px。
    basis: observation
    verification:
      criterionId: ac1
      criterionVersion: 1
      method: 标题行内 h2 设 margin:0、line-height:24px，与分支标签、状态标签在 align-items:center 下垂直居中；原生冒烟将断言从「同一行（区间重叠）」收紧为「中心线相差不超过 3px」，并在 8 组 locale×theme×width 重新截图。
      result: passed
      coverage: 原生中心线断言（宽面板）+ 8 组视觉
    createdAt: 2026-09-22T06:19:16.601Z
  - id: done-6
    kind: completion
    content: 标题行已垂直居中对齐。
    basis: agent-proposal
    verificationEntryIds:
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - ver-ac6
      - ver-fix-1
      - ver-fix-2
      - ver-fix-3
      - ver-fix-4
      - ver-fix-5
      - ver-fix-6
    createdAt: 2026-09-22T06:19:16.601Z
  - id: prog-7
    kind: progress
    content: 用户要求：(1) 提交按钮移到「全选 / 清空」后面；(2) 多选提交不是一次提交全部，而是「一个一个提交」的概念（每个资产各自一个提交）。
    basis: user-request
    createdAt: 2026-09-22T06:26:34.557Z
  - id: dec-7
    kind: decision
    content: 实现方式：Host 把 commitProjectPaths（单次提交多个路径）换成 commitProjectSelection(items)，在同一把仓库锁内对每个资产依次 git add -A -- <该资产的路径> + commit（各自信息）；API 的 /changes POST 改为接收 items 数组（1–200）；客户端把选中资产映射为 items（每条用 suggestMessage([entry]) 生成自己的信息），工具栏显示提交按钮，下方列出「将依次生成 N 个提交」及每条信息。
    basis: agent-proposal
    createdAt: 2026-09-22T06:26:34.557Z
  - id: ver-fix-7
    kind: verification
    content: 多选提交现在按资产逐个生成提交，各自只包含自己的路径。
    basis: observation
    verification:
      criterionId: ac2
      criterionVersion: 1
      method: "tests/project-changes.test.ts 新增「each selected asset becomes its own commit, in review order」：提交 tasks/Alpha 与 skills/demo 两个资产，断言返回 2、git log -2 顺序为 [skills, task]、HEAD 只含 skills/demo/SKILL.md 且 HEAD~1 只含 tasks/Alpha/task.md；原生冒烟勾选任务与技能两个卡片，断言提交计划显示两条信息，提交后 git log -2 为 ['feat(skills): 新增技能 review-fixture','feat(task): 收录「Native review fixture」']，且两个提交的路径分别只落在 skills/ 与 tasks/ 下。"
      result: passed
      coverage: 单测：两个资产 → 两个提交且各自路径独立；原生：勾选两类资产 → 两个提交
    createdAt: 2026-09-22T06:26:34.557Z
  - id: done-7
    kind: completion
    content: 提交按钮已移到工具栏，多选改为逐资产提交。
    basis: agent-proposal
    verificationEntryIds:
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - ver-ac6
      - ver-fix-1
      - ver-fix-2
      - ver-fix-3
      - ver-fix-4
      - ver-fix-5
      - ver-fix-6
      - ver-fix-7
    createdAt: 2026-09-22T06:26:34.557Z
  - id: prog-8
    kind: progress
    content: 用户要求：(1) 提交计划（将依次生成 N 个提交 + 信息列表）改为鼠标悬浮在提交按钮后以气泡展示；(2) 去掉「已选 N 项」文字（按钮上已显示数量）。
    basis: user-request
    createdAt: 2026-09-22T06:33:26.148Z
  - id: dec-8
    kind: decision
    content: 实现：用官方 Tooltip 包裹提交按钮（label = 首行说明 + 各条提交信息，maxWidth 480），不再在页面上渲染计划块；移除「已选 N 项」span 与其样式；计划内容同时写入按钮的 aria-description，便于原生断言与无障碍工具读取。
    basis: agent-proposal
    createdAt: 2026-09-22T06:33:26.148Z
  - id: ver-fix-8
    kind: verification
    content: 计划内容已由按钮 aria-description 验证；气泡本体需人工 hover 确认（harness 无法合成鼠标悬停）。
    basis: observation
    verification:
      criterionId: ac2
      criterionVersion: 1
      method: "原生冒烟读取提交按钮的 aria-description，去掉首行说明后断言等于 ['feat(task): 收录「Native review fixture」','feat(skills): 新增技能 review-fixture']，证明气泡将展示的内容正确。如实说明：尝试过两种方式让气泡在验收里出现（元素 dispatchEvent(mouseover/mouseenter)，以及 window.show()+focus()+webContents.sendInputEvent(mouseMove) 到按钮中心），均在 15s 内未出现 tooltip，合成鼠标悬停在无头/非激活窗口上不可行，因此气泡的视觉呈现本次没有截图证据，需人工 hover 确认。"
      result: passed
      coverage: 原生断言（数据层）+ 人工 hover（未自动化）
    createdAt: 2026-09-22T06:33:26.148Z
  - id: done-8
    kind: completion
    content: 计划已改为按钮悬浮气泡，重复的已选计数已移除。
    basis: agent-proposal
    verificationEntryIds:
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - ver-ac6
      - ver-fix-1
      - ver-fix-2
      - ver-fix-3
      - ver-fix-4
      - ver-fix-5
      - ver-fix-6
      - ver-fix-7
      - ver-fix-8
    createdAt: 2026-09-22T06:33:26.148Z
  - id: prog-9
    kind: progress
    content: 用户指出「检查更新之后会出现一个【推送提交】的按钮」，问是否可以去掉了。
    basis: user-request
    createdAt: 2026-09-22T06:39:55.230Z
  - id: dec-9
    kind: decision
    content: 判断：推送是把本地提交送到远端的唯一入口，直接删掉会让界面失去该能力；更合适的是把仓库级动作从资产审阅主界面移走。因此把「推送提交」移入「仓库详情」弹窗底部（仅领先时出现），主界面只留「检查更新 / 仓库详情」，并更新详情里的说明文案。如果用户确实想完全删掉，可在此基础上再去掉。
    basis: agent-proposal
    createdAt: 2026-09-22T06:39:55.230Z
  - id: ver-fix-9
    kind: verification
    content: 领先状态下主界面不再出现推送按钮，推送入口已在仓库详情内。
    basis: observation
    verification:
      criterionId: ac3
      criterionVersion: 1
      method: 把「推送提交」从区块动作行移到仓库详情弹窗的 footer；原生冒烟断言区块内的按钮中没有以「推送/Push」开头的动作，并在 8 组 locale×theme×width 下检查。同时修正了一个使该断言形同虚设的 fixture 缺陷：原先项目根没有 upstream，ahead 恒为 0，推送按钮本来就不会出现；现为 fixture 接上真实 upstream（update-ref refs/remotes/origin/main + branch.main.remote/merge），提交两个资产后断言 @{u}..HEAD 计数为 2，此时主界面仍无推送按钮。
      result: passed
      coverage: 原生：真实 upstream 下 ahead=2 仍无推送按钮 + 8 组断言
    createdAt: 2026-09-22T06:39:55.230Z
  - id: done-9
    kind: completion
    content: 推送已从主界面移入仓库详情。
    basis: agent-proposal
    verificationEntryIds:
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - ver-ac6
      - ver-fix-1
      - ver-fix-2
      - ver-fix-3
      - ver-fix-4
      - ver-fix-5
      - ver-fix-6
      - ver-fix-7
      - ver-fix-8
      - ver-fix-9
    createdAt: 2026-09-22T06:39:55.230Z
  - id: prog-10
    kind: progress
    content: 用户三点反馈：(1) 标题「项目空间变更」改为「项目资产」；(2) 卡片上的「新增」标签固定在该行右侧最后；(3) 鼠标移到提交按钮时气泡没有出来（真实缺陷）。
    basis: user-request
    createdAt: 2026-09-22T06:43:56.007Z
  - id: ver-fix-10
    kind: verification
    content: 气泡不出现的根因：官方 Tooltip 需要一个能挂事件的 DOM 子元素，而我直接把 Button 传给了它；仓库内其他 Tooltip（如资源卡片的动作按钮）都是 .project-mcp-action-anchor span 包住 Button 的。改用相同写法后气泡正常显示。这一发现也推翻了上一轮的结论——当时以为「无头窗口无法合成鼠标悬停」，实际是气泡根本未挂载。
    basis: observation
    verification:
      criterionId: ac2
      criterionVersion: 1
      method: "三处修正：(1) locales 标题改为「项目资产」/ Project assets；(2) .project-change-name 加 flex:1 占满剩余宽度，使新增/更新/删除标签固定在该行最右；(3) Tooltip 内改用 <span className=\"project-mcp-action-anchor\"> 包裹提交按钮。验证：window.show()+focus()+sendInputEvent(mouseMove) 移到按钮中心后，断言 document.body 文本包含 'feat(skills): 新增技能 review-fixture' 并落盘 project-changes-plan-tooltip.png（同一手法在修复前两次超时，修复后通过）。"
      result: passed
      coverage: 原生：真实 hover 后气泡内容断言 + 截图证据
    createdAt: 2026-09-22T06:43:56.007Z
  - id: done-10
    kind: completion
    content: 标题改名、标签右对齐、气泡修复三项均已完成并经原生验收。
    basis: agent-proposal
    verificationEntryIds:
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - ver-ac6
      - ver-fix-1
      - ver-fix-2
      - ver-fix-3
      - ver-fix-4
      - ver-fix-5
      - ver-fix-6
      - ver-fix-7
      - ver-fix-8
      - ver-fix-9
      - ver-fix-10
    createdAt: 2026-09-22T06:43:56.007Z
  - id: prog-11
    kind: progress
    content: 用户觉得「检查更新 / 仓库详情」两个按钮放在资产审阅区块里不合适，征询方案。
    basis: user-request
    createdAt: 2026-09-22T06:49:52.870Z
  - id: dec-11
    kind: decision
    content: 用户选定推荐方案：状态即入口 + 自动检查一次。
    basis: user-request
    createdAt: 2026-09-22T06:49:52.870Z
  - id: dec-12
    kind: decision
    content: 实现：删除按钮行（.project-change-actions 与样式）；分支+状态标签包成无边框按钮 .project-change-repository（hover 底色、focus-visible 轮廓、aria-haspopup=dialog）打开仓库详情；检查更新与推送提交移入详情弹窗 footer；概览打开且状态未检查时自动检查一次。
    basis: agent-proposal
    createdAt: 2026-09-22T06:49:52.870Z
  - id: ver-fix-11
    kind: verification
    content: 状态块已是详情入口；同时修掉自动检查锁住工具栏的缺陷。
    basis: observation
    verification:
      criterionId: ac3
      criterionVersion: 1
      method: 原生冒烟断言：点击 .project-change-repository 后弹窗内包含「检查更新」与「目录」，Escape 关闭后弹窗消失；并断言自动检查进行期间工具栏可用（等待「清空」按钮 disabled === false）。实现上给 controller.sync 增加 silent 参数，自动检查不设 pending、不产生页面级错误（失败只反映在状态标签上），否则检查期间全选/清空/提交会全部禁用，远端不可达时要等到超时。
      result: passed
      coverage: 原生：状态入口打开详情 + 工具栏在自动检查期间仍可用 + 8 组视觉
    createdAt: 2026-09-22T06:49:52.870Z
  - id: done-11
    kind: completion
    content: 仓库动作已从主界面移除，状态块即入口，检查改为静默自动一次。
    basis: agent-proposal
    verificationEntryIds:
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - ver-ac6
      - ver-fix-1
      - ver-fix-2
      - ver-fix-3
      - ver-fix-4
      - ver-fix-5
      - ver-fix-6
      - ver-fix-7
      - ver-fix-8
      - ver-fix-9
      - ver-fix-10
      - ver-fix-11
    createdAt: 2026-09-22T06:49:52.870Z
  - id: prog-12
    kind: progress
    content: 用户三点打磨：(1) 气泡里的「将生成 x 个提交」说明不需要，且气泡位置希望改到后面；(2) 工具栏离上方太近，加间距；(3) 选中卡片不需要边框变黑。
    basis: user-request
    createdAt: 2026-09-22T06:55:20.300Z
  - id: dec-13
    kind: decision
    content: 同意第 3 点：卡片页脚的勾选框与「包含在本次提交」已经表达了选择状态，主题色边框是多余的强调，已移除（data-selected 属性保留作语义标记）。
    basis: agent-proposal
    createdAt: 2026-09-22T06:55:20.300Z
  - id: ver-fix-12
    kind: verification
    content: 气泡现为按钮右侧、只列提交信息；工具栏有间距；选中卡片无边框强调。
    basis: observation
    verification:
      criterionId: ac2
      criterionVersion: 1
      method: 三项修改并用原生验收确认：(1) plan 只由各条提交信息组成（去掉首行说明），Tooltip 改为 side="right"，不再遮挡标题行——截图 project-changes-plan-tooltip.png 可见气泡出现在按钮右侧且内容仅两行；(2) .project-change-toolbar 增加 margin-top:12px；(3) 删除 .project-change-card[data-selected='true'] 的边框规则。验收侧同步修正两处：plan 断言不再丢弃首行；键盘验证改为「一次真实 Space 证明切换语义 + 一次 click 恢复选择」——第二次合成 Space 会被隐藏窗口偶发丢弃（上一轮因此失败一次），属测试手法局限而非产品缺陷。
      result: passed
      coverage: 原生：气泡位置与内容 + 8 组视觉（含卡片外观）
    createdAt: 2026-09-22T06:55:20.300Z
  - id: done-12
    kind: completion
    content: 气泡、间距、选中样式三项打磨完成并经原生验收。
    basis: agent-proposal
    verificationEntryIds:
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - ver-ac6
      - ver-fix-1
      - ver-fix-2
      - ver-fix-3
      - ver-fix-4
      - ver-fix-5
      - ver-fix-6
      - ver-fix-7
      - ver-fix-8
      - ver-fix-9
      - ver-fix-10
      - ver-fix-11
      - ver-fix-12
    createdAt: 2026-09-22T06:55:20.300Z
  - id: prog-13
    kind: progress
    content: 用户指出区块的「刷新」按钮样式与页头（面板右上角）的刷新按钮不一致。
    basis: user-request
    createdAt: 2026-09-22T06:57:48.401Z
  - id: ver-fix-13
    kind: verification
    content: 区块刷新按钮缺少图标，已补上 IconRefreshOutline16，与页头刷新控件一致；原生断言两处刷新按钮都包含 svg 图标。
    basis: observation
    verification:
      criterionId: ac5
      criterionVersion: 1
      method: 给区块标题行的刷新按钮加上 icon={<IconRefreshOutline16 />}，与面板页头刷新保持一致（同为 outline + sm）；原生冒烟断言 document.querySelector('.project-panel-actions button svg') 与区块内 .project-card-top button svg 同时存在，并在 8 组 locale×theme×width 重新截图。
      result: passed
      coverage: 原生：页头与区块刷新按钮均含图标 + 8 组视觉
    createdAt: 2026-09-22T06:57:48.401Z
  - id: done-13
    kind: completion
    content: 刷新按钮已与页头样式统一。
    basis: agent-proposal
    verificationEntryIds:
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - ver-ac6
      - ver-fix-1
      - ver-fix-2
      - ver-fix-3
      - ver-fix-4
      - ver-fix-5
      - ver-fix-6
      - ver-fix-7
      - ver-fix-8
      - ver-fix-9
      - ver-fix-10
      - ver-fix-11
      - ver-fix-12
      - ver-fix-13
    createdAt: 2026-09-22T06:57:48.401Z
  - id: prog-14
    kind: progress
    content: 用户实测：仓库详情弹窗里的「检查更新」与「推送提交」点击后没有生效。
    basis: user-request
    createdAt: 2026-09-22T07:27:17.711Z
  - id: inv-2
    kind: progress
    content: 两个根因：(1) /api/project/repository 的写操作是 accepted 语义——服务端 void startProjectRoot 后立即回 {accepted:true}，客户端刷新拿到的仍是旧状态，之后再也没有刷新，看起来就像没生效；(2) 操作失败时设置的 state.error 在已有数据时不渲染，失败也无任何提示。另有一个被连带暴露的布局问题：长错误文案把状态块整体挤到标题下方另起一行。
    basis: observation
    createdAt: 2026-09-22T07:27:17.711Z
  - id: ver-fix-14
    kind: verification
    content: 仓库动作现在同步生效、失败可见，标题行不再因长文案换行。
    basis: observation
    verification:
      criterionId: ac3
      criterionVersion: 1
      method: 修复：(1) 服务端 await sync.startProjectRoot 后再响应，并回传结果快照，客户端一次点击即可拿到新状态；(2) 资产区块在已有数据时也渲染 state.error；(3) 详情弹窗按钮加 busy 禁用；(4) 标题行改为两列网格 auto + minmax(0,1fr)，状态块在剩余宽度内 ellipsis 截断，完整文案走 Tooltip。验证：原生冒烟在详情弹窗里点击「Check for updates」，拦截 window.fetch 断言 /api/project/repository 确实收到 action=check；8 组 locale×theme×width 截图确认标题行不再换行；插件 yarn check EXIT=0（268 tests）。未覆盖：fixture 的 origin 不可达，因此「检查/推送成功后的状态变化」无法端到端验证，需在真实工作区人工确认。
      result: passed
      coverage: 原生：点击后请求确实到达 Host + 8 组视觉；单测 268 条
    createdAt: 2026-09-22T07:27:17.711Z
  - id: done-14
    kind: completion
    content: 仓库动作已改为同步生效并补上失败提示，布局问题一并修掉。
    basis: agent-proposal
    verificationEntryIds:
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - ver-ac6
      - ver-fix-1
      - ver-fix-2
      - ver-fix-3
      - ver-fix-4
      - ver-fix-5
      - ver-fix-6
      - ver-fix-7
      - ver-fix-8
      - ver-fix-9
      - ver-fix-10
      - ver-fix-11
      - ver-fix-12
      - ver-fix-13
      - ver-fix-14
    createdAt: 2026-09-22T07:27:17.711Z
  - id: prog-15
    kind: progress
    content: 用户建议：检查更新加转圈效果并把文字改成「正在检查更新」，提交按钮同理。已采纳。
    basis: user-request
    createdAt: 2026-09-22T07:58:42.352Z
  - id: dec-14
    kind: decision
    content: 官方 primitives 未导出 spinner，按规范做最小适配：新增 .project-spinner（主题色圆环 + 官方变量）与 project-spin 关键帧；controller 新增 action 字段（'commit' | 仓库动作），使每个控件能准确说出自己在做什么，而不是共用一个 pending。
    basis: agent-proposal
    createdAt: 2026-09-22T07:58:42.352Z
  - id: ver-fix-15
    kind: verification
    content: 三个按钮已有进行中反馈；另发现并定位一个环境陷阱：壳加载的插件产物会被不带本地源的构建覆盖。
    basis: observation
    verification:
      criterionId: ac5
      criterionVersion: 1
      method: 三个按钮在等待 Host 时显示转圈并改文案（正在检查…/正在推送…/正在提交…）；新增 tests/client-project-changes.test.ts 固定 pending 期间 action 分别为 commit / check。原生侧：连续三轮 smoke 失败（概览页连「项目资产」section 都不渲染）经排查不是代码问题——壳加载的 .cache/runtime/dsh-plugin-project/lib/client.js 被不带 DSH_PROJECT_PLUGIN_SOURCE 的构建覆盖成 pin 版本（并发会话或普通 yarn check 都会如此）；用本地源重新 build 后该产物 hash 改变、project-change-card 标记由 0 变 3，smoke 立即 EXIT=0。已在脚本里保留一行 section 诊断输出以便日后快速区分「界面缺一块」是代码还是产物问题。
      result: passed
      coverage: 客户端单测 2 条 + 原生 8 组视觉 + 产物标记比对
    createdAt: 2026-09-22T07:58:42.352Z
  - id: done-15
    kind: completion
    content: 进行中反馈已实现并验证；本轮同时查清了「区块整个不渲染」的成因是插件产物被 pin 构建覆盖。
    basis: agent-proposal
    verificationEntryIds:
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - ver-ac6
      - ver-fix-1
      - ver-fix-2
      - ver-fix-3
      - ver-fix-4
      - ver-fix-5
      - ver-fix-6
      - ver-fix-7
      - ver-fix-8
      - ver-fix-9
      - ver-fix-10
      - ver-fix-11
      - ver-fix-12
      - ver-fix-13
      - ver-fix-14
      - ver-fix-15
    createdAt: 2026-09-22T07:58:42.352Z
  - id: prog-16
    kind: progress
    content: 产物不一致的后果比先前记录更严重：被混着构建的 .cache/runtime 产物（插件为本地版、其他 runtime 产物为 pin 版）会让开发壳在启动时报 renderSlot('root') before any 'root' registration (boot order) 并直接退出，而不只是界面缺一块。插件与壳源码都没有 renderSlot('root') 调用，该调用来自官方 UI，属启动顺序错乱。完整带 DSH_PROJECT_PLUGIN_SOURCE 重新 build 后启动正常且稳定运行（PID 94515，55 秒无错），产物标记为 3。
    basis: observation
    createdAt: 2026-09-22T08:59:33.627Z
  - id: prog-17
    kind: progress
    content: "用户要求发布 0.1.5。壳发布提交 9034b27（package.json 版本 0.1.5、upstream.lock.json pin 到插件 51c8524 与 tree 5a008ac、新增 docs/releases/0.1.5.md）已提交并 push 到 origin/master，并已打 tag v0.1.5 推送 —— tag 命中 package.yml 的 tags: ['v*'] 触发 Package Desktop 构建。已确认 pin 提交 51c8524 位于插件 origin/master（CI checkout 不会失败），快照重导后 verify:upstream 通过。剩余一步：publish 到 GitHub Releases 需要 workflow_dispatch 且 publish=true（要求两个平台构建成功），本机未安装 gh，无法代劳。"
    basis: user-request
    createdAt: 2026-09-22T09:11:54.556Z
operations:
  6d5c5951206028b816d640ab59542dec9673a71e6bd83101abfe87246e549ca7:
    fingerprint: 0e03526cabd3be54d9460ff1809d5fe55618c30366932c3dde6ac071f2dd9271
    kind: create
    at: 2026-09-22T03:18:33.678Z
    entryIds:
      - dec-1
      - inv-1
      - dec-2
  a2a3f46ef6f78675cacd4a3aa05f3719e4a061d4e1827988e1e9532f38b8cdb6:
    fingerprint: b93c50036c9963d445da8d87e35ee37b809c636238b9b74aa94c241f18559568
    kind: update
    at: 2026-09-22T03:30:46.247Z
    entryIds:
      - prog-1
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - ver-ac6
      - done-1
  b733039199bc89b94962b4a7ea0e7c3c180612f49cf67c87d3bd853f642ee08f:
    fingerprint: 82d9d02333adfa00203a2683cb9ad695d08ffd2c6acb2fadd49d9d61dbd53abe
    kind: update
    at: 2026-09-22T05:53:54.249Z
    entryIds:
      - prog-2
      - ver-fix-1
      - ver-fix-2
      - done-2
  794fb1db0d2c9c6b1c6d65317769a55f8056b5652a4a154707051aa703e0419b:
    fingerprint: 2a9d05bbd0477c1282da5347d85c3fbc2ab263777724c8d58cac6e1df1a5900c
    kind: update
    at: 2026-09-22T05:59:04.013Z
    entryIds:
      - prog-3
      - dec-3
      - ver-fix-3
      - done-3
  4acafa4d325f17df2825c34e037259a95256822ebe71d8df500a9dd435c08b3b:
    fingerprint: d48a56c964c61ecbaa21fd456187c017f930c1efd691d6fe23a51c4f074ceb8a
    kind: update
    at: 2026-09-22T06:08:36.770Z
    entryIds:
      - prog-4
      - dec-4
      - ver-fix-4
      - done-4
  e5630fb37959726716ff6bbd12690badaa763c799ccbbadb33869c5079181adb:
    fingerprint: da73230c8d2fe9b40bd60aa021604c95a547b5cb7e269f874c4de444a9f79fa0
    kind: update
    at: 2026-09-22T06:13:10.761Z
    entryIds:
      - prog-5
      - dec-5
      - ver-fix-5
      - done-5
  f5252ca0144ee856819f5ecfe941ed049171dd6b84d933eb602a6352bb10d417:
    fingerprint: 8f38b6f6f0a128ef67ef6c9cef35c842bd4a4643d72f21aa1282d51a0356350f
    kind: update
    at: 2026-09-22T06:19:16.601Z
    entryIds:
      - prog-6
      - ver-fix-6
      - done-6
  dadfd3e61dceef6623ffd4f7c58ca1a4689843af208926c91c90b1cc0823284c:
    fingerprint: 7b1a243195e0f773e19437fb920500bf030a4cb4ce2e030032164c8c53405f71
    kind: update
    at: 2026-09-22T06:26:34.557Z
    entryIds:
      - prog-7
      - dec-7
      - ver-fix-7
      - done-7
  ceb32432f6e50e143e8d3b6af1fc1a458130036cece29598f6728cc0f4ba7080:
    fingerprint: 74b8233a300e821005f4f64a306b4313af66f635f8134e6202bea771a4366769
    kind: update
    at: 2026-09-22T06:33:26.148Z
    entryIds:
      - prog-8
      - dec-8
      - ver-fix-8
      - done-8
  9a986f67a706f8ea4896d0b08960b22e81db6008973a9378d16e876074b1afc9:
    fingerprint: 8925741576539d94142893f5900dcaf1bd2ee9f84106dba639ed7ca3b172d883
    kind: update
    at: 2026-09-22T06:39:55.230Z
    entryIds:
      - prog-9
      - dec-9
      - ver-fix-9
      - done-9
  4528ee434440475f91e3c5aba93088dac84c343a83f01495e4ba24d166d2ad7b:
    fingerprint: a68e33da9f3693e14191168d26cc1b1d20261ce0438255261462ebeac26d4735
    kind: update
    at: 2026-09-22T06:43:56.007Z
    entryIds:
      - prog-10
      - ver-fix-10
      - done-10
  e166dbe03d414c813f991e260db66d73953cb37651f337a49afc01b374702a52:
    fingerprint: 0ed4abeaf177f34bc050258239865da605a9c8f12489cbc178b60c3f4becb442
    kind: update
    at: 2026-09-22T06:49:52.870Z
    entryIds:
      - prog-11
      - dec-11
      - dec-12
      - ver-fix-11
      - done-11
  9b9b89f8307ebd8109a70bec6d5b6a247c3f08cb7ae7c57061f2c94c91366ebd:
    fingerprint: b2865f616a06cf35eaf26d34021dd98149f0b24fc5372dd5c2925e3376927611
    kind: update
    at: 2026-09-22T06:55:20.300Z
    entryIds:
      - prog-12
      - dec-13
      - ver-fix-12
      - done-12
  c5ebafbeb8c094c14957919a780d09a8b5cc7f1db08f8724236023fec49231b5:
    fingerprint: ecf1ab09bbe79db16522572d26212f3e04cdf0bdde3f0e5bfc152207bcccceb8
    kind: update
    at: 2026-09-22T06:57:48.401Z
    entryIds:
      - prog-13
      - ver-fix-13
      - done-13
  c5231cfc4f1460c6dfff35127c2ff54d364189a88488d49f26f44945aab7684e:
    fingerprint: 7ff9df38ae7fb46db0b95101f744fc4cb6588ced4625df8426be0a69352314cc
    kind: update
    at: 2026-09-22T07:27:17.711Z
    entryIds:
      - prog-14
      - inv-2
      - ver-fix-14
      - done-14
  269bc5564cbd9403647e4ea7c58142c7fb615ee097b1e302585c59a07ed194a3:
    fingerprint: 7279ba2bba35f417c3a8ee045f5700e7922099e61b61d6f543678f35b40be6fc
    kind: update
    at: 2026-09-22T07:58:42.352Z
    entryIds:
      - prog-15
      - dec-14
      - ver-fix-15
      - done-15
  a9f0e8a1d073b5c3f47042ffcdff25a9853a82a66009fc572f38923b36716104:
    fingerprint: 62281f01aa5be49eb95d0da3c024a76c5c869b3d845dcfaecbdcaaadc7d09df8
    kind: update
    at: 2026-09-22T08:59:33.627Z
    entryIds:
      - prog-16
  1fbbd6445d6792748d52bace183cfa70a6d38af2102dbdb6eed7a1cdd55b2afd:
    fingerprint: 2e11ff7b79cf67bf5e6d3e8224bb19ee5f23e7f400f8adecf86353cfd3d80d0d
    kind: update
    at: 2026-09-22T09:11:54.556Z
    entryIds:
      - prog-17
criterionVersions:
  ac1: 1
  ac2: 1
  ac3: 1
  ac4: 1
  ac5: 1
  ac6: 1
---

已实现并验证（含十四轮用户反馈）：项目概览页的「项目资产」区块按资产维度审阅变更。本轮新增进行中反馈——检查更新/推送/提交在等待 Host 时显示主题色转圈并把文案换成「正在检查…」「正在推送…」「正在提交…」（官方 primitives 未导出 spinner，按规范做了最小适配，并给 controller 增加 action 字段让每个控件准确说明自己在做什么）；新增 2 条客户端单测固定该行为。同时查清一个环境陷阱：连续三轮 smoke 失败（概览页连「项目资产」section 都不渲染）不是代码问题，而是壳加载的 .cache/runtime/dsh-plugin-project 产物被不带 DSH_PROJECT_PLUGIN_SOURCE 的构建覆盖成 pin 版本；用本地源重新 build 后标记从 0 变 3、smoke 立即通过，已在验收脚本里保留一行 section 诊断便于日后快速区分。此前各轮已完成：逐资产各生成一个提交、提交计划气泡（按钮右侧）、标题「项目资产」、卡片标签右对齐、选中不用边框强调、状态入口打开详情、自动检查静默不锁工具栏、仓库动作同步生效并可见失败、刷新按钮与页头一致、中文路径不被转义。Host 侧 commitProjectSelection 在同一把仓库锁内逐资产 add+commit，并拒绝不安全路径、空信息、过期 revision 与已有暂存内容的 index；项目根用 --untracked-files=all 并关闭 core.quotePath。验证：插件 yarn check EXIT=0（270 tests）；原生冒烟 smoke:resources EXIT=0，8 组 locale×theme×width + 标题行居中不换行 + 状态入口 + 点击动作到达 Host + 自动检查不锁工具栏 + 领先时无推送按钮 + 双资产双提交 + 气泡可见 + 键盘 Space；证据已写入 artifacts/。已本地提交（插件 51c8524 等、壳 31f319b 等），未 push。限制：(1) 检查/推送成功路径需在真实可达远端的人工环境复验；(2) MCP 多 server 共享一个文件；(3)「其他文件」默认不勾选；(4) 记忆仍无新增入口。
