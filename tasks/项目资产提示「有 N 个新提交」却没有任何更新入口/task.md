---
schemaVersion: 3
directory: 项目资产提示「有 N 个新提交」却没有任何更新入口
id: task-888f1cfb-0cae-4423-b5b1-76f76c11c2f6
title: 项目资产提示「有 N 个新提交」却没有任何更新入口
objective: 修复「项目资产」面板在项目根仓库落后于远端时只显示「有 N 个新提交」、却不提供更新（fast-forward）入口的缺陷：查明根因（面板自造了一套同步状态判断并漏掉 update 动作），改为复用资源卡的更新动作与可用性规则，补齐单元测试与原生界面验收。
status: completed
createdAt: 2026-09-22T13:28:56.475Z
updatedAt: 2026-09-22T13:29:26.179Z
artifacts:
  - type: file
    path: artifacts/project-assets-update-blocked.png
    description: 英文 + 脏工作区：详情里「Update resource」存在但禁用，状态行给出 resourceSyncDirtyBody 说明（窄窗口 420px）
  - type: file
    path: artifacts/project-assets-updated.png
    description: 英文宽窗口：更新成功后状态「Up to date」，更新按钮随 behind=0 消失，仓库动作说明已含 update
  - type: file
    path: artifacts/smoke-resources-result.json
    description: "smoke:resources 运行结果 result.json（ok: true，含四组 locale/theme/宽度的布局测量）"
  - type: commit
    repository: https://github.com/admintertar/dsh-plugin-project
    commit: 82bca7ebb4e17524969086134ae1b2f8ab35dacd
    description: 插件：项目仓库详情补上「更新」入口（9 文件 +143/-33，本地提交未 push）
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop
    commit: bc6087c282456dd5d4862a88f355989561096375
    description: 壳：原生验收覆盖项目仓库详情里的「更新」（1 文件 +94/-1，本地提交未 push）
archived: false
phase: validation
brief:
  currentBehavior: 项目资产面板（概览页）在标题处显示同步状态 Tag，例如「有 18 个新提交」；点击该 Tag 打开的「仓库详情」弹窗 footer 只有「检查更新」「推送提交」「关闭」，没有任何拉取/更新入口。资源卡（Resources 页）有同名的更新按钮，项目根仓库没有。
  scope: 插件 UI 与契约：src/client/ProjectChangesPanel.tsx、src/client/resource-ui.ts、src/client/ResourceCard.tsx、src/project-changes.ts、src/resource-api.ts、src/locales.ts，以及对应测试；壳验收脚本 scripts/native-resource-state-checks.mjs。
  constraints:
    - 不改 Host 的 Git 安全规则：更新仍是 fetch + merge --ff-only，脏工作区/历史分叉/进行中一律拒绝
    - 复用资源卡既有的可用性规则与文案，不再维护第二套同步状态判断
    - 文案中英双语同步
  outOfScope:
    - 不新增 pull/rebase/stash 等其它历史改写动作
    - 不改动已安装版与发布产物，不 push 仓库
    - 英文「{count} new commits」在 count=1 时的单复数表述（既有文案，本次未改）
  acceptanceCriteria:
    - id: ac-1
      text: 项目根仓库落后于远端时，「仓库详情」提供「更新资源 / Update resource」，点击后仓库快进到最新（工作区文件随之更新，状态回到「已是最新 / Up to date」）
      required: true
      version: 1
    - id: ac-2
      text: 不可更新的状态（工作区不干净、历史分叉、检查/更新进行中）下按钮存在但禁用，且详情里说明原因；窄窗口下弹窗不出现横向溢出
      required: true
      version: 1
    - id: ac-3
      text: 两个仓库 yarn check 全绿，原生验收 smoke:resources 在真实 Electron 界面下通过
      required: true
      version: 1
handoff:
  nextSteps:
    - 需要发布时：先 push 插件 82bca7e → 再把 resources/dsh-project-desktop/upstream.lock.json 的 project.commit 与 tree 指到该提交并重导 .upstream/project（先删旧快照、再跑 setup）→ 最后 push 壳。顺序颠倒会让 CI 在 checkout 阶段失败。
    - 如需让已安装版带上此修复，需重新打包并安装（当前安装版仍是旧 shell + 旧插件）。
    - 可选后续：英文「{count} new commits」在 count=1 时显示「1 new commits」，可改成中性表述或加复数处理。
  readBefore:
    - ref-panel
    - ref-rules
    - ref-smoke
  verifyBefore:
    - ref-smoke
    - note-release
references:
  - id: ref-panel
    label: 插件：项目资产面板与仓库详情
    type: file
    path: resources/dsh-plugin-project/src/client/ProjectChangesPanel.tsx
  - id: ref-rules
    label: 插件：资源同步可用性与说明的共享规则
    type: file
    path: resources/dsh-plugin-project/src/client/resource-ui.ts
  - id: ref-smoke
    label: 壳：原生资源状态验收脚本（含本次新增段）
    type: file
    path: resources/dsh-project-desktop/scripts/native-resource-state-checks.mjs
  - id: note-release
    label: 发布顺序提醒
    type: note
    text: 先 push 插件提交，再 bump shell 的 upstream.lock.json（project.commit/tree）并重导 .upstream/project，最后 push 壳。
entries:
  - id: e-root-cause
    kind: progress
    content: 根因：ProjectChangesPanel 自己维护了一套 syncSummary 状态判断，并在「仓库详情」footer 里手写了检查/推送两个动作，漏掉了资源卡早已存在的 update。Host 侧 POST /api/project/repository 与 ProjectChangesController.sync 一直支持 update（RepositorySyncAction = Exclude<ResourceSyncAction,'commit'>），因此只缺界面入口。
    basis: observation
    createdAt: 2026-09-22T13:28:56.475Z
  - id: e-implementation
    kind: progress
    content: 实现：ProjectChangesSnapshot.sync 复用 ResourceGitSync 并由 Host 透传完整同步状态；新增共享 resourceSyncDescription；ProjectChangesPanel 的状态徽标改为复用 resourceSyncLabel，详情 footer 在 behind>0（或更新进行中）时显示「更新资源」，禁用条件与资源卡一致（canUpdateResource）；详情状态行补充禁用原因说明；changeCommitHintBody 补上「更新」。
    basis: agent-proposal
    createdAt: 2026-09-22T13:28:56.475Z
  - id: v-ac1
    kind: verification
    content: ac-1 验证：在真实 Electron 界面里给项目根接上 loopback HTTPS Git 远端，让远端新增一个提交后点「检查更新」，状态变为「有 1 个新提交」且 footer 出现可用的「更新资源」；点击后状态回到「已是最新」，工作区 AGENT.md 变为远端内容（waitGit 断言）。
    basis: observation
    verification:
      criterionId: ac-1
      criterionVersion: 1
      method: yarn run smoke:resources（真实 Electron + 本地 HTTPS git-backend 远端 + 实时 DOM 断言）
      result: passed
      coverage: 原生界面 zh/en；smoke:resources 脚本 native-resource-state-checks.mjs 新增段；证据 project-assets-updated.png
    createdAt: 2026-09-22T13:29:26.179Z
  - id: v-ac2
    kind: verification
    content: ac-2 验证：制造未跟踪文件后重新检查，详情里「更新资源」（英文 Update resource）仍存在但 disabled=true，且状态行给出 resourceSyncDirtyBody 说明；窄窗口 420px 下弹窗无横向溢出（scrollWidth<=clientWidth 且 body 无溢出）。可用性规则由新增单测覆盖（脏工作区/inProgress/phase/error/diverged 均不可更新）。
    basis: observation
    verification:
      criterionId: ac-2
      criterionVersion: 1
      method: yarn run smoke:resources + yarn check（插件 node --test）
      result: passed
      coverage: 原生界面 en + 420px 窄窗口；单测 client-resources.test.ts；证据 project-assets-update-blocked.png
    createdAt: 2026-09-22T13:29:26.179Z
  - id: v-ac3
    kind: verification
    content: ac-3 验证：resources/dsh-plugin-project yarn check EXIT=0（typecheck + 279 tests + build）；resources/dsh-project-desktop yarn check EXIT=0（verify:upstream + build + tests + recovery + safe-mode + check-project-files + smoke:host）。
    basis: observation
    verification:
      criterionId: ac-3
      criterionVersion: 1
      method: yarn check（两仓库）
      result: passed
      coverage: 两个仓库完整 check；日志 dsh-plugin-check2.log 与 dsh-shell-check.log 均为 EXIT=0
    createdAt: 2026-09-22T13:29:26.179Z
  - id: e-completion
    kind: completion
    content: 三条验收标准均已由当前证据通过；代码已本地提交（插件 82bca7e、壳 bc6087c），未 push、未 bump lock、未重新打包。
    basis: agent-proposal
    verificationEntryIds:
      - v-ac1
      - v-ac2
      - v-ac3
    createdAt: 2026-09-22T13:29:26.179Z
operations:
  8487118ea6c38c77621a5ea0413b4a5a3324805fcb5c28cef3eb95473b4291ac:
    fingerprint: b4361c76970d11f85682eee164057964a239ca70594428dd066db424a103eaff
    kind: create
    at: 2026-09-22T13:28:56.475Z
    entryIds:
      - e-root-cause
      - e-implementation
  6e5579553b82ee930a5b6c89aacbad95ec37205e1b5ec0bd191ed0b53ad831e8:
    fingerprint: 0995beeb3d1646dc09b18d127abc1351f4a89f7f6519bfff4256aa3959890809
    kind: update
    at: 2026-09-22T13:29:26.179Z
    entryIds:
      - v-ac1
      - v-ac2
      - v-ac3
      - e-completion
criterionVersions:
  ac-1: 1
  ac-2: 1
  ac-3: 1
---

「项目资产」面板的仓库详情已补上更新入口：项目根落后时 footer 出现「更新资源 / Update resource」，点击后 fetch + merge --ff-only 快进，状态回到「已是最新 / Up to date」，工作区文件随之更新；工作区不干净等不可更新状态按钮禁用且详情说明原因。根因是面板自造了一套同步状态判断并手写了检查/推送两个动作，漏掉了资源卡早有的 update（Host 与 controller 一直支持）。改动：插件 82bca7e（9 文件，+143/-33，未 push）、壳 bc6087c（验收脚本，未 push）。验证：插件 yarn check EXIT=0（279 tests，含新增的项目根 update 真实快进、控制器 update 动作、可用性与说明规则）；壳 yarn check EXIT=0；原生 smoke:resources 在真实 Electron + 真实 loopback HTTPS Git 远端下通过，中英文与禁用态、窄窗口（420）均断言通过，截图见 artifacts。未覆盖：英文「1 new commits」单复数（既有文案，见 outOfScope）；已安装版仍为旧 shell。
