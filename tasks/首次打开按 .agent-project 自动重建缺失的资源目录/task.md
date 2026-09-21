---
schemaVersion: 3
directory: 首次打开按 .agent-project 自动重建缺失的资源目录
id: task-a9998e4c-b2ad-4306-a9c9-2fe661f347ac
title: 首次打开按 .agent-project 自动重建缺失的资源目录
objective: 修复「全新检出（resources/ 被 .gitignore 排除）后第一次打开项目，资源页始终提示『目录缺失』且必须手动克隆」的缺陷：项目窗口打开后，由壳按项目定义自动补齐缺失的 Git 资源目录，复用插件既有的 clone API（进度、认证、失败语义），不阻塞项目窗口打开。
status: completed
createdAt: 2026-09-21T14:22:49.733Z
updatedAt: 2026-09-21T14:29:00.843Z
artifacts:
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: 7bfa08d57dbb80e494d07b0412134b708cc4fbcb
    description: 壳：新增 src/app/resource-restore.mjs 与 4 项单元测试，在 createProject 的非安全/非 testing 分支接入自动重建，并更新架构与目录结构文档。
archived: false
phase: validation
brief:
  currentBehavior: 全新检出后项目根下没有 resources/ 目录（根 .gitignore 排除了 /resources/ 与两个资源仓库）。插件 readProject 对 ENOENT 只返回 status='missing'，资源卡片显示「目录缺失」，重建只能由用户在资源页手动点击克隆。
  scope: 壳（dsh-project-desktop）在项目打开成功后检测 manifest 声明、类型 git、带 url、目录缺失、无本机绑定且没有既有 clone 作业的资源，经 Host 的 /api/project/resources 与 /api/project/resources/clone 串行重建；不修改插件源码。
  constraints:
    - 插件拥有资源，壳只复用其 HTTP API，不复制克隆实现
    - 一次只允许一个克隆作业（插件 clone-busy），必须串行等待作业终结
    - 安全模式、自检与测试模式不得触发自动重建
    - 机器本地绑定（.agent-project/local.yaml）或项目外绑定目录是用户决定，不得自动重建
  outOfScope:
    - 安装版打包与发布
    - 首次打开进入恢复模式的启动失败体验（另议）
    - 资源页 UI 文案改动
  acceptanceCriteria:
    - id: ac-1
      text: 打开项目后，满足条件的缺失 Git 资源被自动重建，无需用户点击
      required: true
      version: 1
    - id: ac-2
      text: 重建不阻塞项目窗口打开；失败不影响项目可用，并可由用户在资源页手动重试
      required: true
      version: 1
    - id: ac-3
      text: 安全模式、testing/自检模式、本机绑定与外部资源都不触发自动重建
      required: true
      version: 1
    - id: ac-4
      text: 单元测试覆盖候选筛选与 clone 请求契约；原生验收确认真实窗口中资源由「目录缺失」变为 ready
      required: true
      version: 1
questions:
  - 首次打开进入恢复模式的启动失败体验是否需要一并改善（例如在 Host 启动失败时给出可操作的本地构建提示）？
handoff:
  nextSteps:
    - 如需日常安装版带上此修复：重新打包并在 Windows 安装后复验一次资源自动重建（当前安装版仍是旧 shell）
    - 另议项：首次打开进入恢复模式的启动失败体验（Host 启动失败时给出可操作的本地构建或缓存提示）
  readBefore:
    - resource-restore-module
    - main-create-project
    - architecture-resources
  verifyBefore:
    - shell-yarn-check
    - reopen-after-resource-delete
references:
  - id: resource-restore-module
    label: 资源自动重建模块（壳）
    type: note
    text: resources/dsh-project-desktop/src/app/resource-restore.mjs
  - id: main-create-project
    label: 打开项目的自动重建入口
    type: note
    text: resources/dsh-project-desktop/src/app/main.mjs 的 createProject：非 safeMode 且非 testing 分支调用 restoreMissingResources
  - id: architecture-resources
    label: 架构文档的资源重建段落
    type: note
    text: resources/dsh-project-desktop/docs/architecture.md
  - id: shell-yarn-check
    label: 壳完整回归命令
    type: note
    text: cd resources/dsh-project-desktop && yarn check（PATH 需含 Git 的 usr/bin，否则 guide-clones 测试因 openssl ENOENT 失败）
  - id: reopen-after-resource-delete
    label: 手工复现步骤
    type: note
    text: 删掉项目的 resources/<资源名> 与该项目 DSH Home 的 dsh/project-resources 记录，重开项目，观察资源卡片自动恢复
entries:
  - id: v-ac1
    kind: verification
    content: 满足条件的缺失 Git 资源在打开后被自动重建：隔离 userData 的开发壳打开全新检出状态的项目（resources/ 与 DSH Home 的 project-resources 记录都已清空），资源卡片由「目录缺失」在 8 秒内变为「尚未检查」，resources/exp-resource-a/ 重建完成，.gitignore 追加 /resources/exp-resource-a/，插件作业记录 status=completed、path=resources/exp-resource-a、existing=true。
    verification:
      criterionId: ac-1
      criterionVersion: 1
      method: 真实开发壳（DSH_PROJECT_DESKTOP_USER_DATA 隔离）+ CDP Runtime.evaluate 读渲染进程实时 DOM；检查工作树目录、.gitignore 与插件 operations.json
      result: passed
      coverage: 全新检出场景端到端；未覆盖需要凭据的私有远端（该路径由插件既有认证流程负责）
    createdAt: 2026-09-21T14:26:44.808Z
  - id: v-ac2
    kind: verification
    content: 重建不阻塞打开且失败可恢复：项目窗口在克隆发生前即可读 DOM，克隆在后台完成；单元测试覆盖 clone 被拒（409 clone-busy）、Host 抛错（项目关闭）与作业永不终结三类失败，均只记录不抛出，资源保持缺失并可由资源页手动重试。
    verification:
      criterionId: ac-2
      criterionVersion: 1
      method: CDP 观测打开与克隆的先后；node --test tests/resource-restore.test.mjs
      result: passed
      coverage: 失败路径为单元级；真实窗口只验收了成功路径
    createdAt: 2026-09-21T14:26:44.808Z
  - id: v-ac3
    kind: verification
    content: 不误触发：restoreMissingResources 只在 createProject 的非 safeMode 且非 testing 分支调用；候选筛选排除本机绑定（bound）、项目外目录（external）、非 Git、无 url、无 declaredPath 以及已有克隆作业的资源。
    verification:
      criterionId: ac-3
      criterionVersion: 1
      method: 代码路径审查 + 单元测试（候选筛选与 canClone=false 不发请求）
      result: passed
      coverage: 安全模式与 testing 分支由调用点保证，未单独跑安全模式原生用例
    createdAt: 2026-09-21T14:26:44.808Z
  - id: v-ac4
    kind: verification
    content: 测试与原生验收齐备：新增 4 项单元测试（筛选规则、clone 请求契约含 declaredPath/expectedRevision/origin、canClone=false 与已有作业不请求、失败不抛），yarn check EXIT=0（90 tests / recovery 7 / safe-mode 1 / smoke:host）。
    verification:
      criterionId: ac-4
      criterionVersion: 1
      method: node --test；yarn check；CDP 原生 DOM 验收
      result: passed
      coverage: 本机 Windows 实测；未在 macOS 复核
    createdAt: 2026-09-21T14:26:44.808Z
  - id: done-resource-restore
    kind: completion
    content: 四项 required 验收标准全部通过：壳在打开项目后自动重建缺失的 Git 资源目录（7bfa08d），单测与完整 check 全绿，真实窗口的实时 DOM 记录了「目录缺失→就绪」的完整转换。未 push、未重新打包。
    verificationEntryIds:
      - v-ac1
      - v-ac2
      - v-ac3
      - v-ac4
    createdAt: 2026-09-21T14:26:44.808Z
  - id: pushed-7bfa08d
    kind: progress
    content: 已按用户明确要求 push 到 origin/master：c569728..7bfa08d（fast-forward，无落后提交），壳仓库工作树干净、插件仓库无改动。
    createdAt: 2026-09-21T14:29:00.843Z
operations:
  664260995c9cd12b7394ca41b3c7a6a439a9383a7cf8957b55ba6a13c9c8c7bb:
    fingerprint: 4fbe148b0ac632b907fcee2fe35b81d672f5d3ef4509575891b7b8c9e00b1896
    kind: create
    at: 2026-09-21T14:22:49.733Z
    entryIds: []
  c2f513592c2930e254b3caf1235464a9e1b2545cbe48ca21a35ebb8626f4e2ac:
    fingerprint: 8e5ce5845ad1b473291eee40db4289b11db130b45455708fb62bc76589c279b1
    kind: update
    at: 2026-09-21T14:26:44.808Z
    entryIds:
      - v-ac1
      - v-ac2
      - v-ac3
      - v-ac4
      - done-resource-restore
  ca1f5d689ee7cd28e720ebb613daa5d3671dca28e82f9d17c97c3968647f0ace:
    fingerprint: e75bf142b762f0d67d64037b10666a28615992798b1cd39782468baccccfe171
    kind: update
    at: 2026-09-21T14:29:00.843Z
    entryIds:
      - pushed-7bfa08d
criterionVersions:
  ac-1: 1
  ac-2: 1
  ac-3: 1
  ac-4: 1
---

已实现并验证：项目窗口进入 open 后，壳按项目定义自动重建缺失的 Git 资源目录，复用插件的 /api/project/resources 快照与 /api/project/resources/clone 接口，串行等待作业终结（插件一次只允许一个克隆），不阻塞打开。提交 7bfa08d（壳 master，未 push）。验证：4 项新单测通过；yarn check EXIT=0（90 tests / recovery 7 / safe-mode 1 / smoke:host）；原生验收用隔离 userData 的开发壳 + CDP 读实时 DOM，资源卡片 8 秒内从「目录缺失」变为「尚未检查」，目录、.gitignore 规则与作业记录三处一致。限制：未 push、未重新打包（安装版仍是旧 shell）；「首次打开进入恢复模式」的启动失败体验按用户确认单独另议，不在本次范围。
