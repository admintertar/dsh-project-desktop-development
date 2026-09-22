---
schemaVersion: 3
directory: 项目根仓库 Git 管理：概览页「项目仓库」区块
id: task-b4668fd0-d9ca-4d07-80ae-e28045a1ba0a
title: 项目根仓库 Git 管理：概览页「项目仓库」区块
objective: 为项目根仓库（工作区本身）提供与资源一致的 Git 管理能力：在项目概览页新增独立「项目仓库」区块，支持 check / update / commit / push / switch / branches，复用插件既有的 ResourceSyncManager 与 ResourceCard，同时保持「项目根不是托管资源」的既有边界（资源面板、资源计数、任务引用、资源 API 的 resource-project-root 拒绝均不变）。
status: completed
createdAt: 2026-09-22T02:37:47.246Z
updatedAt: 2026-09-22T02:57:43.036Z
artifacts:
  - type: file
    path: artifacts/project-repository-zh-light-1180.png
    description: 概览页「项目仓库」区块：中文 / 浅色 / 1180px
  - type: file
    path: artifacts/project-repository-zh-dark-1180.png
    description: 概览页「项目仓库」区块：中文 / 深色 / 1180px
  - type: file
    path: artifacts/project-repository-en-light-1180.png
    description: 概览页「项目仓库」区块：英文 / 浅色 / 1180px
  - type: file
    path: artifacts/project-repository-en-dark-1180.png
    description: 概览页「项目仓库」区块：英文 / 深色 / 1180px
  - type: file
    path: artifacts/project-repository-zh-light-420.png
    description: 概览页「项目仓库」区块：中文 / 浅色 / 420px 窄窗
  - type: file
    path: artifacts/project-repository-zh-dark-420.png
    description: 概览页「项目仓库」区块：中文 / 深色 / 420px 窄窗
  - type: file
    path: artifacts/project-repository-en-light-420.png
    description: 概览页「项目仓库」区块：英文 / 浅色 / 420px 窄窗
  - type: file
    path: artifacts/project-repository-en-dark-420.png
    description: 概览页「项目仓库」区块：英文 / 深色 / 420px 窄窗
  - type: file
    path: artifacts/project-repository-commit-dialog.png
    description: 从概览页项目仓库卡片打开的提交弹窗（Escape 取消后焦点返回）
  - type: file
    path: artifacts/native-smoke-result.json
    description: 原生冒烟完整结果，含 8 组布局测量与 result 标记
  - type: file
    path: artifacts/native-smoke-run.log
    description: smoke:resources 运行日志（EXIT=0）
archived: false
phase: validation
brief:
  currentBehavior: "资源面板对 resources/ 下 type: git 的资源提供 check / update / commit / push / switch / branches；项目根在 manifest 中被固定声明为 type: local（src/project-files.ts:51），并被 src/resource-scope.ts:12 的 managedResources() 从资源列表、侧栏计数与自动检查中过滤掉；Host 侧 project-resources.ts:102、resource-sync.ts:102、resource-clones.ts:157 对项目根返回 resource-project-root。因此工作区根仓库只能靠 git 命令或第三方客户端提交。"
  scope: dsh-plugin-project：项目根 Git 通道的 Host 契约与 ResourceSyncManager 复用、独立 API 路由、客户端 controller、概览页「项目仓库」区块与卡片、中英双语文案、单元测试。
  constraints:
    - 复用 ResourceSyncManager 的 commit/push/switch/check/update 实现与 ResourceCard 的交互，不另写一套控件
    - 不解除资源 API 的 resource-project-root 拒绝，项目根走独立路由与独立解析
    - 沿用既有立场：不 force、不 rebase、不 stash、不跑 hooks、push 仅快进、只与当前分支 upstream 比较
    - 不对项目根做后台自动轮询，避免自指循环
    - 未经明确要求不 push 到任何远端
  outOfScope:
    - 项目根的 git init 与远端关联（初始化流程）
    - 项目根与 upstream.lock.json pin 的差距感知
    - 暂存区 UI（提交范围仍为全部改动）
  acceptanceCriteria:
    - id: ac1
      text: 概览页新增「项目仓库」区块，展示项目根仓库的名称、路径、分支、远端与同步状态
      required: true
      version: 1
    - id: ac2
      text: 支持 check / update / commit / push / switch / branches，语义与资源 Git 一致（不 force、不 rebase、不 stash、不跑 hooks、push 仅快进）
      required: true
      version: 1
    - id: ac3
      text: 项目根不进入 managedResources：资源面板、侧栏资源计数、任务提交关联与资源 API 的 resource-project-root 拒绝均保持不变
      required: true
      version: 1
    - id: ac4
      text: 中英双语文案、浅色/深色、420px 窄窗口与键盘行为经原生视觉验收，证据落盘到任务 artifacts/
      required: true
      version: 1
    - id: ac5
      text: 新增能力有测试覆盖，yarn run check（typecheck + test + build）通过
      required: true
      version: 1
handoff:
  nextSteps:
    - 发布时才需要：先 push 插件提交，再把 resources/dsh-project-desktop/upstream.lock.json 的 project.commit/tree 指到该已推送提交，删除 .upstream/project 后重导并跑 yarn run verify:upstream（顺序见 memory/working-agreements.md）。
    - 若要修 420px 窄窗下概览主面板被侧栏挤压的既有布局问题，另开任务：项目仓库与既有资源区块的 section scrollWidth 都会超过 clientWidth（150/133 与 165/133），body 本身不溢出。
    - 壳仓库 scripts/native-resource-state-checks.mjs 的验收扩展目前是未提交改动，需要随壳一起提交。
references: []
entries:
  - id: inv-1
    kind: progress
    content: "调研结论（代码级证据）：项目根被四道关卡系统性排除在 Git 管理之外——(1) project-files.ts:51 新建 manifest 时根资源固定为 type: local；(2) client/ResourcesPanel.tsx:122 与 client/ResourceCard.tsx:90 的 Git 动作只在 type === 'git' && status === 'ready' 时渲染；(3) resource-scope.ts:12 的 managedResources() 把路径等于项目根的条目整个滤掉，用于 ResourcesPanel:35/246、sidebar-counts:14、index.tsx:859、resource-clones:73、resource-sync:356；(4) project-resources.ts:102、resource-sync.ts:102、resource-clones.ts:157 对项目根返回 resource-project-root，文案 resource-locales.ts:84 明确写「项目仓库与资源分开管理，不能在资源中修改」。现有 4 个 Git 相关任务全部只覆盖 resources/ 下的资源，没有一条覆盖项目根。"
    basis: observation
    createdAt: 2026-09-22T02:37:47.246Z
  - id: dec-1
    kind: decision
    content: 位置选定：项目概览页新增独立「项目仓库」区块（与「环境」「资源」并列），而不是资源面板首卡、项目设置弹窗或侧栏新菜单。理由：概览已在「环境」卡片展示 project.root 且其刷新会连带刷新资源快照（index.tsx:861）；新区块走独立数据源，不触碰 managedResources 与资源计数；设置弹窗受前端规范第 3、4 条「长弹窗只有一个正文滚动区」约束，不适合放提交表单。
    basis: user-request
    createdAt: 2026-09-22T02:37:47.246Z
  - id: dec-2
    kind: decision
    content: Host 通道设计：项目根走独立路由 /api/project/repository（GET 状态、POST 动作、GET /branches、GET /changes），不复用 /api/project/resources 的 id 语义；ResourceSyncManager 增加项目根条目解析（用 inspectResourceGit 探测工作树根与 origin），把 start() 的公共部分抽成 begin()，并让 mutate()/execute() 的 current() 通过注入的 resolver 解析条目，从而复用同一套 commit/push/switch/check/update 实现。资源 API 的 resource-project-root 拒绝保持不变。
    basis: agent-proposal
    createdAt: 2026-09-22T02:37:47.246Z
  - id: dec-3
    kind: decision
    content: UI 设计：复用 ResourceCard（含只读详情弹窗、提交弹窗、分支选择器、诊断与文案），新增可选 kindLabel 覆盖 Tag 文案为「项目仓库」；项目根不是 Git 工作树时区块只显示提示文案，不渲染卡片，避免扩展 ResourceGitSync 状态机。
    basis: agent-proposal
    createdAt: 2026-09-22T02:37:47.246Z
  - id: prog-1
    kind: progress
    content: 实现落点：插件新增 src/client/project-repository-controller.ts 与 src/client/ProjectRepositoryCard.tsx；resource-contract.ts 新增 ProjectRepositoryView（含 revision 与可选 repository）；resource-sync.ts 新增 projectRootItem/rootItem/startProjectRoot/projectRootStatus/projectRootBranches/projectRootChanges，并把 start() 的公共部分抽成 begin(item, action, revision, interactive, input, key, resolve)，mutate()/execute() 的 current() 改为调用注入的 resolver；resource-api.ts 新增 /api/project/repository 的 GET/POST 与 /branches、/changes；ResourceCard 新增可选 kindLabel；概览页在「资源」区块之前插入「项目仓库」区块（index.tsx），并让顶部刷新同时刷新它；locales.ts 新增 projectRepository 与 projectRepositoryUnavailable 中英文案。
    basis: observation
    createdAt: 2026-09-22T02:57:43.036Z
  - id: ver-ac1
    kind: verification
    content: 概览页「项目仓库」区块在真实 Electron 窗口渲染正确。
    basis: observation
    verification:
      criterionId: ac1
      criterionVersion: 1
      method: smoke:resources（DSH_PROJECT_PLUGIN_SOURCE=../dsh-plugin-project）在真实 Electron 项目窗口读实时 DOM，断言概览页 section h2 = 「项目仓库」/「Project repository」、卡片 Tag 文案、分支 main、路径「项目根目录」与远端 project；8 组 locale×theme×width 截图落盘。
      result: passed
      coverage: zh/en × light/dark × 1180/420，共 8 组
    createdAt: 2026-09-22T02:57:43.036Z
  - id: ver-ac2
    kind: verification
    content: check / update / commit / push / switch / branches 复用资源 Git 实现与安全立场。
    basis: observation
    verification:
      criterionId: ac2
      criterionVersion: 1
      method: tests/project-repository.test.ts：changes 列出未跟踪文件、commit 写入真实提交并使工作树变净、branches 列出本地分支、dirty 时 switch 被拒、clean 后 switch 改变 HEAD、check 走共享状态机并返回 git-no-upstream、过期 revision 返回 revision-conflict、非 Git 根返回 resource-unavailable；实现层复用 ResourceSyncManager 的 commit/push/switch/execute（不 force、不 rebase、不 stash、core.hooksPath=/dev/null、push 仅快进）。
      result: passed
      coverage: 6 个新单测 + 共享实现路径
    createdAt: 2026-09-22T02:57:43.036Z
  - id: ver-ac3
    kind: verification
    content: 项目根仍不是托管资源，既有边界与拒绝语义不变。
    basis: observation
    verification:
      criterionId: ac3
      criterionVersion: 1
      method: tests/project-repository.test.ts 断言 snapshot(false).resources.length === 0 且不含 root 路径；tests/resource-api.test.ts 断言 /api/project/resources 的 /sync 对 id=root 仍返回 409 resource-project-root，而新路由 /api/project/repository 独立鉴权（401/403/405/422）；原生冒烟断言资源计数仍为 2、资源页无 root 卡片、资源卡片与项目仓库卡片分别标注 Git 与「项目仓库」。
      result: passed
      coverage: Host 快照、资源 API 拒绝、原生 UI 计数与列表
    createdAt: 2026-09-22T02:57:43.036Z
  - id: ver-ac4
    kind: verification
    content: 中英文案、主题、窄窗与键盘行为经原生视觉验收，证据落盘。
    basis: observation
    verification:
      criterionId: ac4
      criterionVersion: 1
      method: "smoke:resources 在 zh/en × light/dark × 1180/420 下断言区块与卡片文案、body 无横向溢出、卡片左右边缘在视口内；在 en/light/1180 下从概览页卡片打开提交弹窗（截图）并断言 Escape 取消后 document.activeElement 的 aria-label 回到「Commit changes: …」；9 张 PNG、result.json 与运行日志写入 tasks/项目根仓库 Git 管理：概览页「项目仓库」区块/artifacts/。"
      result: passed
      coverage: zh/en × light/dark × 1180/420 + 提交弹窗键盘焦点
    createdAt: 2026-09-22T02:57:43.036Z
  - id: ver-ac5
    kind: verification
    content: 插件 typecheck、测试与构建全部通过。
    basis: observation
    verification:
      criterionId: ac5
      criterionVersion: 1
      method: cd resources/dsh-plugin-project && yarn check（typecheck + tsx --test + build），258 tests / 0 fail / EXIT=0；新增 tests/project-repository.test.ts 与 resource-api.test.ts 的项目根路由用例。
      result: passed
      coverage: 全量 258 个测试与构建
    createdAt: 2026-09-22T02:57:43.036Z
  - id: done-1
    kind: completion
    content: 验收标准 ac1–ac5 全部通过，项目根仓库 Git 管理已在概览页可用；插件与壳改动未提交、未 push，发布时才需要 bump pin。
    basis: agent-proposal
    verificationEntryIds:
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
    createdAt: 2026-09-22T02:57:43.036Z
operations:
  af457cef55da2b3ac064eac409fe0e912b9dc4ec11ae59842d3b6e6f2dd01bef:
    fingerprint: 1bdbb478442308e6bfecbbfece9b53c7357b18e6127f4fd00806ad10ef9d41f4
    kind: create
    at: 2026-09-22T02:37:47.246Z
    entryIds:
      - inv-1
      - dec-1
      - dec-2
      - dec-3
  40e8db66bcf002848aa7014a3a9352e112272a466af145ddf831707d55bed0b0:
    fingerprint: 1f7ffd75c985e2cc8ddc4f1aaea9a71da37a76f8dcbfbfbc477a1865e7a8db9e
    kind: update
    at: 2026-09-22T02:57:43.036Z
    entryIds:
      - prog-1
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - done-1
criterionVersions:
  ac1: 1
  ac2: 1
  ac3: 1
  ac4: 1
  ac5: 1
---

已实现并验证：项目概览页新增独立「项目仓库」区块，复用 ResourceCard 与 ResourceSyncManager，提供 check / update / commit / push / switch / branches。Host 新增独立路由 /api/project/repository（GET 状态、POST 动作、GET /branches、GET /changes），项目根条目由 inspectResourceGit 从工作树根与 origin 解析；ResourceSyncManager 把 start() 抽成 begin() 并注入 resolver，使项目根与资源共用同一套 commit/push/switch/check/update 实现。资源 API 的 resource-project-root 拒绝、managedResources 过滤、资源计数与任务引用均未改动。验证：插件 yarn check（typecheck + 258 tests + build）EXIT=0；原生冒烟 smoke:resources（带 DSH_PROJECT_PLUGIN_SOURCE）EXIT=0，在真实 Electron 窗口读实时 DOM 覆盖 zh/en × light/dark × 1180/420 共 8 组，断言区块标题、Tag「项目仓库」、分支 main、无 body 横向溢出、卡片在视口内，并验证提交弹窗 Escape 取消后焦点返回触发按钮；9 张截图、result.json 与运行日志已落盘 artifacts/。限制：(1) 420px 窄窗下概览主面板被侧栏挤压（项目仓库 section scrollWidth 150 / clientWidth 133），但既有「资源」区块同样如此（165/133），非本改动引入，未在本任务修复；(2) 插件与壳的改动均未提交、未 push，发布时才需要 bump upstream.lock.json 的 project pin。
