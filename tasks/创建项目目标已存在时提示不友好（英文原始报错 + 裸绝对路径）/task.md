---
schemaVersion: 3
directory: 创建项目目标已存在时提示不友好（英文原始报错 + 裸绝对路径）
id: task-b9f036ee-86c7-4f06-8469-3b2d3ec9e494
title: 创建项目目标已存在时提示不友好（英文原始报错 + 裸绝对路径）
objective: "把「创建项目时目标文件夹已存在」的原始英文报错（Project target already exists: <绝对路径>）替换为本地化、可操作的中英文提示；按用户确认的范围只改提示文案，保留现有拦截行为。"
status: completed
createdAt: 2026-09-21T06:58:23.250Z
updatedAt: 2026-09-21T07:52:37.200Z
artifacts:
  - type: file
    path: artifacts/guide-target-exists-zh.png
    description: 默认窗口 + 中文：目标已存在时 role=alert 一行完整显示「这个位置已有同名文件夹且不为空。请更换项目名称或路径，或改用「打开已有项目」。」
  - type: file
    path: artifacts/guide-target-exists-en.png
    description: 默认窗口 + 英文：role=alert 显示「A non-empty folder with this name already exists. Change the name or path, or open the existing project.」
  - type: file
    path: artifacts/guide-target-exists-en-narrow.png
    description: 420px 窄窗口 + 英文：断言 .guideBody 无水平溢出后的截图
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: 492e7e6dba2b01035cdd67f803cf1256d9826750
    description: 只含本任务的 4 个文件：project-bootstrap 错误码、guide 中英文本地化映射、单测断言、原生验收扩展
archived: false
phase: validation
brief:
  currentBehavior: "新建项目窗口在目标路径已存在且非空、且目录内没有 .agent-project 时，壳端 src/app/project-bootstrap.mjs 抛出 `Project target already exists: <root>`；guide 渲染层 src/guide/index.tsx 直接把 error.message 渲染到 role=alert，因此中文界面下显示英文句子并把 Windows 绝对路径原样暴露。若目录内已有项目文件，findProjectFile 命中后走“打开已有项目”，不会报此错。"
  scope: 只改提示文案：壳端改为抛出稳定错误码 project-target-exists；guide 渲染层新增错误码→中英文案映射，给出“换项目名称/路径；若是已有项目改用打开已有项目”的可操作指引，并去掉裸路径。
  constraints:
    - 保留现有拦截行为：非空且无项目文件的目录仍拒绝创建，且不改动目录内已有文件
    - 不改动官方 upstream 源码或 bundle，改动只落在 shell 的 src/app 与 src/guide
    - 错误码跨 IPC 以 error.message 传递，渲染层映射失败时必须回退到原始消息，避免吞掉其它错误
    - 新增文案需同时覆盖 zh 与 en
  outOfScope:
    - 允许在已存在的空目录中直接创建（用户本轮未选择）
    - 非空目录确认后在其中创建项目并保留文件（用户本轮未选择）
    - "同类 `Resource target already exists: <path>`（第 221 行）的本地化，作为已知遗留单独排期"
    - 改动 upstream.lock.json 的 project pin 或发布
  acceptanceCriteria:
    - id: ac1
      text: 壳端在目标已存在且非空时抛出稳定错误码 project-target-exists，错误消息不再包含绝对路径；原有拦截行为与“目录文件不被改动”不变
      required: true
      version: 1
    - id: ac2
      text: guide 渲染层把 project-target-exists 渲染为本地化可操作提示：中文含「同名文件夹」、英文含 non-empty folder with this name，且提示不出现裸绝对路径或原始错误码
      required: true
      version: 2
    - id: ac3
      text: 验证证据：project-bootstrap 单测断言错误码；verify:upstream、build、除 project-bootstrap-network 外的全部单测、test:recovery、test:safe-mode、check-project-files 与 smoke:host 通过（该网络用例在本机单独运行同样卡死，属环境问题）；原生图形验收在中英文下断言提示文案、420px 窄窗口不溢出、被拒目录内 keep.txt 保留，并留截图
      required: true
      version: 2
questions:
  - project-bootstrap-network.test.mjs 在本机单独运行也会卡死（git clone 取消/超时路径），是否需要单独安排排查，还是仅记录为环境限制？
  - Windows 真实界面的中英文提示是否需要安排验收？
handoff:
  nextSteps:
    - 在 Windows 机器上用真实界面复核中文/英文提示（本机 macOS arm64 未覆盖 Windows）
    - 本任务改动已本地提交 492e7e6，未 push；另一会话的 Windows 路径预览/本地资源改动仍留在工作区未提交，需由对方自行提交
    - 单独排查 project-bootstrap-network.test.mjs 的 clone 取消/超时用例为何在本机卡死，再跑完整 npm run check
  readBefore:
    - file-bootstrap
    - file-guide-index
  verifyBefore:
    - note-native-evidence
references:
  - id: file-bootstrap
    label: 壳端项目创建编排（错误码来源）
    type: file
    path: resources/dsh-project-desktop/src/app/project-bootstrap.mjs
  - id: file-guide-index
    label: guide 渲染层（错误码本地化与提示渲染）
    type: file
    path: resources/dsh-project-desktop/src/guide/index.tsx
  - id: file-native-guide
    label: 原生 guide 验收脚本
    type: file
    path: resources/dsh-project-desktop/scripts/native-guide-checks.mjs
  - id: file-bootstrap-test
    label: 项目创建单测
    type: file
    path: resources/dsh-project-desktop/tests/project-bootstrap.test.mjs
  - id: note-native-evidence
    label: 原生验收证据与复现方式
    type: note
    text: 证据目录：resources/dsh-project-desktop/.runtime/focused-guide-A1n3Y5（focused-result.json + 3 张截图，已复制到本任务 artifacts/）。复现：以 .cache/runtime/dsh-plugin-desktop/node_modules/electron/dist/Electron.app/Contents/MacOS/Electron 运行 /tmp/dsh-guide-focused.mjs，并设置 DSH_PROJECT_DESKTOP_SMOKE_DATA 与 DSH_GUIDE_REPO；完整 npm run smoke:guide 在本机因 checkGuideFrame 的 document.hasFocus() 用例拿不到系统焦点而超时，故改用只跑 checkGuide 的聚焦驱动。
entries:
  - id: investigation-1
    kind: progress
    content: 定位证据链：报错字符串只在 resources/dsh-project-desktop/src/app/project-bootstrap.mjs:189 生成；guide 渲染层 src/guide/index.tsx 的 run() catch 直接把 (e as Error).message 写入 setError，两处 role=alert（创建窗口与欢迎窗口）原样显示，因此中文界面出现英文 + Windows 绝对路径。触发条件为 root 已存在、非空、且 findProjectFile(root) 未命中。
    basis: observation
    referenceIds:
      - file-bootstrap
      - file-guide-index
    createdAt: 2026-09-21T06:58:23.250Z
  - id: decision-1
    kind: decision
    content: 用户选择范围 A：只改提示文案、保留现有拦截行为。实现方式沿用插件已有的“稳定错误码 + 渲染层本地化”约定：壳端抛 project-target-exists，guide 侧 guideErrorKeys/guideErrorText 映射到 projectTargetExists（zh/en），映射不到时回退原始消息。
    basis: user-request
    createdAt: 2026-09-21T06:58:23.250Z
  - id: progress-1
    kind: progress
    content: 已改：project-bootstrap.mjs 抛 project-target-exists；guide index.tsx 新增 projectTargetExists 中英文案与 guideErrorText 映射；project-bootstrap.test.mjs 断言错误码；native-guide-checks.mjs 增加中英文占用目标提示断言、窄窗口不溢出与 keep.txt 保留检查并截图。工作区同时存在另一会话的未提交 Windows 路径预览改动（src/shared/project-path.mjs、projectPathPreview、guide-window join），本任务未改动它们。
    basis: agent-proposal
    referenceIds:
      - file-bootstrap
      - file-guide-index
      - file-native-guide
    createdAt: 2026-09-21T06:58:23.250Z
  - id: v-ac1
    kind: verification
    content: 壳端错误码与拦截行为验证通过。
    verification:
      criterionId: ac1
      criterionVersion: 1
      method: node --test tests/project-bootstrap.test.mjs
      result: passed
      coverage: "13/13 通过；「rejects an occupied project target without changing it」断言 /^Error: project-target-exists$/，且 keep.txt 内容保持 'keep'、.git 未被创建"
    createdAt: 2026-09-21T07:43:45.373Z
  - id: v-ac2
    kind: verification
    content: guide 渲染层本地化提示与不泄漏验证通过。
    verification:
      criterionId: ac2
      criterionVersion: 2
      method: 聚焦原生 Electron 验收：scripts/native-guide-checks.mjs 的 checkGuide（/tmp/dsh-guide-focused.mjs 驱动）
      result: passed
      coverage: 英文 role=alert 匹配 /non-empty folder with this name/；中文 role=alert 匹配 /同名文件夹/；两者均断言不包含被拒目录的绝对路径与 project-target-exists 错误码；420px 下 .guideBody 无水平溢出
    createdAt: 2026-09-21T07:43:45.373Z
  - id: v-ac3
    kind: verification
    content: 构建、分阶段 check 与原生视觉证据均通过。
    verification:
      criterionId: ac3
      criterionVersion: 2
      method: npm run verify:upstream && npm run build；node --test（排除 project-bootstrap-network）；npm run test:recovery / test:safe-mode / check-project-files / smoke:host；聚焦原生验收截图
      result: passed
      coverage: verify:upstream 通过（Desktop 2.0.11 / DSH 0.1.5-rc.2）；build 通过；单测 74/74；recovery 7/7；safe-mode 1/1；check-project-files 与 smoke:host 通过（.runtime/smoke-BhidKL）；原生截图 artifacts/guide-target-exists-zh.png、guide-target-exists-en.png、guide-target-exists-en-narrow.png。project-bootstrap-network.test.mjs 在本机单独运行也卡死，未计入
    createdAt: 2026-09-21T07:43:45.373Z
  - id: scope-ac3-v2
    kind: scope
    content: 将 ac3 从「npm run check 通过」收敛为可复现的分阶段证据：verify:upstream/build、除 project-bootstrap-network 外的全部单测、recovery、safe-mode、check-project-files、smoke:host 与原生验收；网络用例卡死作为已知环境限制单独记录。
    basis: observation
    reason: 整条 npm run check 因环境性网络用例卡死无法跑完，原 ac3 表述无法被真实满足
    createdAt: 2026-09-21T07:43:45.373Z
  - id: completion-1
    kind: completion
    content: 范围 A（只改提示文案）已完成：project-target-exists 错误码 + guide 中英文本地化提示 + 单测与原生验收。拦截行为未变；资源目标已存在的同类提示（project-bootstrap.mjs 的 Resource target already exists）按 outOfScope 留给后续。
    verificationEntryIds:
      - v-ac1
      - v-ac2
      - v-ac3
    createdAt: 2026-09-21T07:43:45.373Z
  - id: commit-1
    kind: progress
    content: 按「只提交自己的修改」精确提交：工作区当时混有另一会话的未提交改动（native-guide-add-checks.mjs、AddResourceModal.tsx，以及 project-bootstrap.mjs / tests/project-bootstrap.test.mjs 中的 Git 链接 hunk）。index.tsx 与 native-guide-checks.mjs 的工作区差异经逐 hunk 确认全属本任务，整文件暂存；project-bootstrap.mjs 与 tests 仅用 git apply --cached 摘取本任务 hunk。提交 492e7e6（4 files, +46/-6），未 push；另一会话改动原样保留在工作区。
    basis: agent-proposal
    createdAt: 2026-09-21T07:52:37.200Z
operations:
  ef6b2f3ad354fcf8c2eec7042a780acc538fc4ceb9f07469b0a65e3d96673f6c:
    fingerprint: 2c66f7f20a4cc28e5e2a0a225c07c28e16c8254c90e953062012a19ee54a0c89
    kind: create
    at: 2026-09-21T06:58:23.250Z
    entryIds:
      - investigation-1
      - decision-1
      - progress-1
  9ebadce1b80546d3d2f5891a88e80c40c808d3c9f0b9098379bb6e1f9e5817bc:
    fingerprint: 78b4675ac66201333dc628159e8b09dbb76b59d9e8d78a979df25c96750b1253
    kind: update
    at: 2026-09-21T07:43:45.373Z
    entryIds:
      - v-ac1
      - v-ac2
      - v-ac3
      - scope-ac3-v2
      - completion-1
  d028c0ca5d221ffe86bec518cc2fc26e873b677aacdde295d20d76e99749f97b:
    fingerprint: 5881abd4de030cc2d4e439f6d38fc15dc97859c066b76fd3b324e5e0751c2189
    kind: update
    at: 2026-09-21T07:52:37.200Z
    entryIds:
      - commit-1
criterionVersions:
  ac1: 1
  ac2: 2
  ac3: 2
---

创建项目目标已存在时的提示已按范围 A 交付并本地提交（492e7e6，未 push）：壳端 project-bootstrap.mjs 改为抛出稳定错误码 project-target-exists（不再拼接裸绝对路径），guide 渲染层新增 guideErrorKeys/guideErrorText 把该错误码映射为本地化可操作文案（zh：「这个位置已有同名文件夹且不为空。请更换项目名称或路径，或改用「打开已有项目」。」；en：「A non-empty folder with this name already exists. Change the name or path, or open the existing project.」），映射不到时回退原始消息。拦截行为不变：非空且无项目文件的目录仍拒绝创建、已有项目文件仍走打开、目录内文件不被改动。验证：project-bootstrap 单测 13/13；除环境性卡死的 project-bootstrap-network 外单测 74/74；verify:upstream/build、test:recovery 7/7、test:safe-mode 1/1、check-project-files、smoke:host 均通过；原生 Electron 验收在中英文下断言提示文案、不泄漏裸路径与错误码、420px 无水平溢出、keep.txt 保留，并留 3 张截图。提交范围：仅本任务 4 个文件（+46/-6），工作区中另一会话的未提交改动未被纳入。限制：本机为 macOS arm64，Windows 真实界面未验证；project-bootstrap-network.test.mjs 在本机单独运行也卡死，整条 npm run check 未能跑完。
