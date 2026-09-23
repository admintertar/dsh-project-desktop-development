---
schemaVersion: 3
directory: 资源卡片「本地领先 n 个提交」悬停显示领先的具体提交
id: task-5fdcf6d6-7671-4f1e-bc1e-c8ea9ae24503
title: 资源卡片「本地领先 n 个提交」悬停显示领先的具体提交
objective: 资源页面（资源卡片）与项目资产面板的同步标签在状态为「本地领先 n 个提交」时，鼠标悬停要能看到领先的是哪些提交：Host 在检查时读取领先提交（hash + 标题），客户端悬停文本按「标签 + 每行一个提交」显示，超过上限时用「另有 n 个本地提交」收尾；含契约、Host、Client、中英文案、单元测试与原生界面验收。
status: completed
createdAt: 2026-09-23T06:42:40.407Z
updatedAt: 2026-09-23T06:49:30.050Z
artifacts:
  - type: file
    path: artifacts/report.md
    description: 验收报告：结论、实现要点、验证命令与结果、证据清单与未覆盖项
  - type: file
    path: artifacts/resource-ahead-commits-tooltip-zh.png
    description: 原生验收：中文界面悬停资源卡片「本地领先 1 个提交」，气泡显示 <hash> panel commit
  - type: file
    path: artifacts/resource-ahead-commits-tooltip-en.png
    description: 原生验收：英文界面同一位置，气泡显示 <hash> panel commit
  - type: file
    path: artifacts/result.json
    description: "smoke:resources 运行结果（ok: true，含各语言/主题/宽度的布局测量）"
  - type: commit
    repository: https://github.com/admintertar/dsh-plugin-project
    commit: e28b0edeb502e5a94f050d011cf43bfc9cef6229
    description: 插件：Host 读取领先提交并随快照下发，资源卡片与项目资产面板悬停显示提交列表（8 文件，含单测；已提交，未 push）
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop
    commit: 544c721d6eea52379a0726f91b117350d06fd9e5
    description: 壳：资源状态原⽣冒烟新增资源卡片领先标签的中英双语悬停断言与截图（已提交，未 push）
archived: false
phase: validation
brief:
  currentBehavior: 同步标签只显示计数「本地领先 n 个提交」（英文 {count} local commits）；ResourceGitSync 只有 ahead/behind 数字，没有提交内容，悬停只看到标签与状态说明，无法知道领先了哪些提交。
  scope: 插件：resource-contract（新增 ResourceGitCommit 与 aheadCommits）、resource-sync（inspect 读取领先提交，上限 20）、client/resource-ui（resourceSyncTooltip）、client/ResourceCard 与 client/ProjectChangesPanel（悬停文案）、resource-locales（resourceSyncAheadMore 中英）、tests/client-resources.test.ts 与 tests/resource-sync.test.ts；壳：scripts/native-resource-state-checks.mjs 增加资源卡片领先标签的悬停原生验收。
  constraints:
    - "复用官方 Tooltip（white-space: pre-line 支持多行），不新造悬浮控件"
    - 领先提交列表由 Host 读取并随快照返回，读取失败不能让同步状态变成错误
    - 列表上限 20 条，剩余数量用中英文案说明，不静默丢弃
    - 只有 checked（已完成远端检查）时才随快照返回 aheadCommits，与 ahead 计数保持一致
  acceptanceCriteria:
    - id: host-ahead-commits
      text: 检查后 ahead 分支的快照带上领先提交（新→旧，最多 20 条，hash + 标题）；未领先时字段缺失
      required: true
      version: 1
    - id: client-hover
      text: 悬停「本地领先 n 个提交」显示标签行 + 每条提交一行；超过 20 条时以「另有 n 个本地提交」结尾；其他状态保持原来的 标签 · 说明
      required: true
      version: 1
    - id: bilingual
      text: 中英文案均可用且与既有标签一致（1 local commits / 本地领先 1 个提交）
      required: true
      version: 1
    - id: automated
      text: resources/dsh-plugin-project 的 yarn run check（typecheck + test + build）通过
      required: true
      version: 1
    - id: native-acceptance
      text: 原生窗口验收：真实资源卡片悬停出现提交列表，中英双语截图，无窗口/布局异常
      required: true
      version: 1
references: []
entries:
  - id: impl
    kind: progress
    content: 契约新增 ResourceGitCommit 与 ResourceGitSync.aheadCommits；resource-sync 的 inspect 在 ahead>0 时用 git log --max-count 20 --format=%H%x1f%s%x00 <head> --not <upstreamHead> 读取领先提交，读取失败只丢列表；view 仅在 checked 且列表非空时下发。客户端新增 resourceSyncTooltip（resource-ui.ts），ResourceCard 与 ProjectChangesPanel 的标签悬停改用它，新增中英 resourceSyncAheadMore。
    basis: observation
    createdAt: 2026-09-23T06:44:44.836Z
  - id: verify-host
    kind: verification
    content: tests/resource-sync.test.ts 新用例：未领先时 aheadCommits 缺失；22 个本地提交时列表 20 条、首条为最新 HEAD（local 22）、末条为 local 3，证明新→旧与截断。
    basis: observation
    verification:
      criterionId: host-ahead-commits
      criterionVersion: 1
      method: corepack yarn test（真实 git fixture，resources/dsh-plugin-project）
      result: passed
      coverage: 覆盖 ahead 读取、顺序、上限与未领先时字段缺失；未覆盖 git log 失败等异常路径（仅以 catch 兜底）
    createdAt: 2026-09-23T06:44:44.836Z
  - id: verify-client
    kind: verification
    content: tests/client-resources.test.ts 新用例：1 条/多条提交拼行、ahead=22 且只给 2 条时以 resourceSyncAheadMore 收尾、其他状态与 undefined 保持「标签 · 说明」。
    basis: observation
    verification:
      criterionId: client-hover
      criterionVersion: 1
      method: corepack yarn test（node:test + 纯函数断言）
      result: passed
      coverage: 覆盖拼行、截断收尾与回退文案；多行渲染由原生用例另证
    createdAt: 2026-09-23T06:44:44.836Z
  - id: verify-i18n
    kind: verification
    content: 原生 smoke 在真实资源卡片上分别以 en（1 local commits）与 zh（本地领先 1 个提交）悬停，断言 tooltip 文本严格等于「标签\n<hash> panel commit」。
    basis: observation
    verification:
      criterionId: bilingual
      criterionVersion: 1
      method: DSH_PROJECT_PLUGIN_SOURCE=../dsh-plugin-project corepack yarn smoke:resources（真实 Electron 窗口，executeJavaScript 读实时 DOM）
      result: passed
      coverage: 覆盖中英标签与提交行；未覆盖其他语言的本地化（产品仅中英）
    createdAt: 2026-09-23T06:44:44.836Z
  - id: verify-automated
    kind: verification
    content: resources/dsh-plugin-project 运行 corepack yarn check（typecheck + test + build）返回 EXIT=0，303 个测试全通过。
    basis: observation
    verification:
      criterionId: automated
      criterionVersion: 1
      method: corepack yarn check，日志 /tmp/plugin-check.log
      result: passed
      coverage: typecheck、全部单测与浏览器/Host 构建
    createdAt: 2026-09-23T06:44:44.836Z
  - id: verify-native
    kind: verification
    content: "smoke:resources 返回 ok: true（EXIT=0），新增断言要求资源卡片悬停气泡高度 ≥ 2 行（20px 行高）且左右边界在窗口内；中英两张截图与 result.json 已存入 artifacts。"
    basis: observation
    verification:
      criterionId: native-acceptance
      criterionVersion: 1
      method: 原生 Electron 冒烟（scripts/native-resource-state-checks.mjs），窗口 show+focus 后 sendInputEvent mouseMove 悬停
      result: passed
      coverage: 覆盖资源卡片中英双语悬停、多行渲染与不溢出；未覆盖 420px 窄窗口悬停与项目资产面板标签
    createdAt: 2026-09-23T06:44:44.836Z
  - id: done
    kind: completion
    content: 全部必选验收标准已通过：Host 领先提交、客户端多行悬停、中英双语、yarn check、原生界面验收。
    basis: observation
    verificationEntryIds:
      - verify-host
      - verify-client
      - verify-i18n
      - verify-automated
      - verify-native
    createdAt: 2026-09-23T06:44:44.836Z
  - id: commits
    kind: progress
    content: "已提交：插件 e28b0ed（feat: 资源卡片悬停显示领先的本地提交）、壳 544c721（feat: 原生验收资源卡片悬停显示领先提交）；两仓库工作树干净，均未 push。upstream.lock.json 的插件 pin 未 bump（日常开发不需要，发布时再改）。"
    basis: observation
    createdAt: 2026-09-23T06:49:30.050Z
operations:
  fd389a4b7383a2329fffc8f945ac97db7d8c1210420ab803b72417a4a931c155:
    fingerprint: d3ecec0e6cc7d07f185951a4364f438b6fa4288319036d667909cf9e71be99ba
    kind: create
    at: 2026-09-23T06:42:40.407Z
    entryIds: []
  1c4cf0671bfc09b053e8bae0132a87f428b227966cd0703bdd54b862b648cc2c:
    fingerprint: 70393d321a00ffb830b1680ea5e93ea8c3c56de4de73552c175a03cd51fef37d
    kind: update
    at: 2026-09-23T06:44:44.836Z
    entryIds:
      - impl
      - verify-host
      - verify-client
      - verify-i18n
      - verify-automated
      - verify-native
      - done
  12ba9987689cde5c7d51a533091303daff579d816aebc33e400fc164467660f3:
    fingerprint: 050a863d0f139d668d96a34c5f5a2a2ccdfdfb2e7a779f0a9a67cb40d22adb2f
    kind: update
    at: 2026-09-23T06:49:30.050Z
    entryIds:
      - commits
criterionVersions:
  host-ahead-commits: 1
  client-hover: 1
  bilingual: 1
  automated: 1
  native-acceptance: 1
---

已实现、验收并提交：Host 在检查到 ahead 时读取领先提交（新→旧，最多 20 条，hash + 标题）随快照下发；资源卡片与项目资产面板的同步标签悬停改为多行提示（标签行 + 每行一个提交，超出以中英「另有 n 个本地提交」收尾），其他状态保持原「标签 · 说明」。插件 yarn check 通过（303 单测），原生 smoke:resources 通过并新增资源卡片中英双语悬停断言，壳 yarn check 通过。提交：插件 e28b0ed、壳 544c721（均未 push，pin 未 bump）。限制：截图为 1180×820 宽窗口，未做像素级人工阅图（由实时 DOM 文本与气泡高度断言替代），项目资产面板标签未单独做原生悬停用例。
