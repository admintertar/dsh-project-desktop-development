---
schemaVersion: 3
directory: 资源卡片 Git 诊断（感叹号）按钮位置与间距修复
id: task-c36a493d-a52c-450f-b8fc-40617545d3a8
title: 卡片诊断（感叹号）按钮位置与间距统一修复
objective: 统一项目卡片操作行中诊断（感叹号）按钮的位置：资源卡片与 MCP 卡片的诊断按钮都排到操作行最后，去掉造成间距异常的多余 auto margin 包裹层，并在无引用后删除 .project-mcp-error-anchor 规则。改动统一落在独立 git worktree，避免主工作树被并行会话 reset 覆盖。
status: completed
createdAt: 2026-09-21T12:15:29.468Z
updatedAt: 2026-09-21T14:08:16.696Z
artifacts:
  - type: file
    path: artifacts/diagnostic-action-order.patch
    description: 两处卡片诊断按钮位置调整的完整补丁，已通过 git apply --check 验证
  - type: note
    description: worktree 载体说明：分支 fix/resource-diagnostic-action-order，路径 resources/.worktrees/dsh-plugin-diag-order，基于插件仓库 HEAD c718651，改动尚未提交（git 身份未配置）。
  - type: commit
    repository: https://github.com/admintertar/dsh-plugin-project.git
    commit: af57d130a49cfe4b3d047e05f2e4eaf59ffbc385
    description: 两处卡片诊断按钮位置与间距修复：资源卡片与 MCP 卡片的感叹号按钮移到操作行末尾，删除不必要的 auto margin 包裹与失去引用的 .project-mcp-error-anchor 规则（主工作树 master，未 push）
  - type: file
    path: artifacts/diag-order-result.json
    description: 96 条断言的完整验收结果（含 16 组采样的按钮顺序、gap、溢出与旧类引用计数）
  - type: file
    path: artifacts/diag-order-zh-light-resource-1180.png
    description: 资源卡片 1180px 实测：感叹号位于行末、与其他按钮同 gap
  - type: file
    path: artifacts/diag-order-zh-light-resource-420.png
    description: 资源卡片 420px 实测：暴露既有窄窗口缺陷（侧边栏未折叠、卡片被压至约 63px、操作行溢出）
archived: false
phase: implementation
brief:
  currentBehavior: 资源卡片操作行为：详情 | 检查 更新 (!诊断) | 绑定 编辑 删除，诊断按钮外层 span 带 .project-mcp-error-anchor{margin-right:auto}，与详情按钮的 margin-right:auto 平分剩余空间，感叹号右侧出现约 190px 空档。MCP 卡片操作行为：(!诊断) | 编辑 删除，诊断按钮被同一条规则推到行首。
  scope: resources/dsh-plugin-project：src/client/ResourcesPanel.tsx、src/client/McpPanel.tsx 的动作顺序，以及 src/client/styles.ts 中失去引用的 .project-mcp-error-anchor 规则。
  constraints:
    - 复用官方 primitives 与既有 IconAction/Tooltip 封装，不新增控件
    - 不改动 .project-mcp-action/.project-mcp-card-footer 基线样式
    - 只在无任何引用后删除 .project-mcp-error-anchor 规则
    - 改动落在独立 worktree 分支，主工作树保持干净
  outOfScope:
    - 资源同步状态标签「需要处理」的语义（Git 不可用时仍显示为同步错误）
    - syncErrors 的黏性清理行为
  acceptanceCriteria:
    - id: c1
      text: 资源卡片中 Git 诊断（感叹号）按钮位于操作行最后一个
      required: true
      version: 2
    - id: c2
      text: 诊断按钮与相邻按钮间距等于 footer 统一 gap，不再出现 auto margin 造成的空档
      required: true
      version: 2
    - id: c3
      text: 中英文、明暗主题与窄窗口下操作行无溢出、无位移
      required: true
      version: 2
    - id: c4
      text: typecheck 通过
      required: true
      version: 2
    - id: c5
      text: MCP 卡片中诊断（感叹号）按钮位于操作行最后一个
      required: true
      version: 1
handoff:
  nextSteps:
    - 发布时（需明确要求）：先 push af57d13 到插件仓库，再把 dsh-project-desktop 的 upstream.lock.json pin 指到该提交并重导 .upstream/project（单独改 lock 会让 CI 在 checkout 阶段失败）
    - 可清理备份：git worktree remove resources/.worktrees/dsh-plugin-diag-order 与 resources/.worktrees/diagnostic-action-order.patch
    - 未处理的既有缺陷：420px 窄窗口下侧边栏未折叠，资源卡片被压至约 63px、操作行按钮溢出卡片边界（与本次改动无关），建议另开任务
  readBefore:
    - resources-panel
    - mcp-panel
    - styles
  verifyBefore:
    - git -C resources/dsh-plugin-project log -1 --format=%H 应为 af57d130a49cfe4b3d047e05f2e4eaf59ffbc385
references:
  - id: resources-panel
    label: ResourcesPanel.tsx（资源卡片诊断按钮）
    type: file
    path: resources/dsh-plugin-project/src/client/ResourcesPanel.tsx
  - id: resource-card
    label: ResourceCard.tsx（footer 布局与同步动作）
    type: file
    path: resources/dsh-plugin-project/src/client/ResourceCard.tsx
  - id: styles
    label: styles.ts（已删除的 auto margin 规则）
    type: file
    path: resources/dsh-plugin-project/src/client/styles.ts
  - id: mcp-panel
    label: McpPanel.tsx（MCP 卡片诊断按钮）
    type: file
    path: resources/dsh-plugin-project/src/client/McpPanel.tsx
entries:
  - id: d1
    kind: decision
    content: 根因：ResourceCard.tsx 的 .project-resource-details-action 已有 margin-right:auto，ResourcesPanel.tsx 中诊断按钮外层 span 又带 .project-mcp-error-anchor{margin-right:auto}，两个 auto margin 平分剩余空间，在感叹号右侧切出空档。
    basis: observation
    createdAt: 2026-09-21T12:15:29.468Z
  - id: p1
    kind: progress
    content: ResourcesPanel.tsx：把 item.git.diagnostic 的 IconAction 从 children 首位移动到 remove 动作之后（操作行末尾），并删除只为 margin 存在的外层 span；IconAction 已自带 project-mcp-action-anchor。
    basis: agent-proposal
    createdAt: 2026-09-21T12:15:29.468Z
  - id: v1
    kind: verification
    content: yarn typecheck 通过（EXIT=0，无输出）。
    basis: observation
    verification:
      criterionId: c4
      criterionVersion: 1
      method: node + corepack yarn 4.18.0 运行 yarn typecheck
      result: passed
      coverage: 仅类型检查；不含构建与真实界面验收
    createdAt: 2026-09-21T12:15:29.468Z
  - id: n1
    kind: progress
    content: 插件工作树曾在 2026-09-21 20:14:17 被并行会话执行 git reset --hard HEAD 覆盖，改动已被重做一次；备份 patch 位于 %TEMP%\dsh-resource-diagnostic-order.patch。
    basis: observation
    createdAt: 2026-09-21T12:15:29.468Z
  - id: s1
    kind: scope
    content: 范围扩展：MCP 卡片中同款诊断按钮一并移到最后；改动载体从主工作树改为 worktree 分支 fix/resource-diagnostic-action-order（resources/.worktrees/dsh-plugin-diag-order）。
    basis: user-request
    reason: 用户要求两处保持一致，且主工作树曾被并行会话 reset 覆盖。
    createdAt: 2026-09-21T12:18:44.950Z
  - id: p2
    kind: progress
    content: McpPanel.tsx：hasError 诊断按钮从 footer 首位移到 delete 之后，去掉 project-mcp-error-anchor 类，保留 project-mcp-action-anchor。styles.ts：删除已无任何引用的 .project-mcp-error-anchor{margin-right:auto}。
    basis: agent-proposal
    createdAt: 2026-09-21T12:18:44.950Z
  - id: p3
    kind: progress
    content: 改动导出为 UTF-8 patch 并双向验证：git apply --check 对干净 master 工作树 EXIT=0，git apply --reverse --check 对 worktree EXIT=0。主工作树中重复的一版改动已用 git checkout 还原，工作树干净。
    basis: observation
    createdAt: 2026-09-21T12:18:44.950Z
  - id: v2
    kind: verification
    content: worktree 内 git diff 确认：资源卡片的 item.git.diagnostic IconAction 位于 remove 之后，是 children 最后一项。
    basis: observation
    verification:
      criterionId: c1
      criterionVersion: 2
      method: git -C <worktree> diff 检查 JSX 顺序
      result: passed
      coverage: 静态审阅 worktree diff；未做真实界面验收
    createdAt: 2026-09-21T12:18:49.461Z
  - id: v3
    kind: verification
    content: worktree 内 git diff 确认：McpPanel 的 hasError 诊断按钮位于 delete 之后，是 footer 最后一项；grep 确认 project-mcp-error-anchor 在 src 下已无引用。
    basis: observation
    verification:
      criterionId: c5
      criterionVersion: 1
      method: git diff 检查 JSX 顺序 + grep 引用
      result: passed
      coverage: 静态审阅 worktree diff 与全仓引用检索；未做真实界面验收
    createdAt: 2026-09-21T12:18:49.461Z
  - id: v4
    kind: verification
    content: 在 worktree 内（node_modules 以 junction 指向主工作树依赖）运行 tsc --noEmit，EXIT=0，无输出。
    basis: observation
    verification:
      criterionId: c4
      criterionVersion: 2
      method: node node_modules/typescript/bin/tsc --noEmit（worktree 内）
      result: passed
      coverage: 仅类型检查；不含构建与真实界面验收
    createdAt: 2026-09-21T12:18:49.461Z
  - id: p4
    kind: progress
    content: 按用户要求把 worktree 的改动合并回主工作树：用 git apply 将 patch 应用到 resources/dsh-plugin-project 工作区，三个文件与 worktree 副本 SHA256 逐字节一致（未提交，保持在未暂存状态）。
    basis: user-request
    createdAt: 2026-09-21T13:35:23.948Z
  - id: v5
    kind: verification
    content: 合并后主工作树运行 yarn typecheck（node 22.23.2 + corepack yarn 4.18.0），EXIT=0，无输出；src 下 project-mcp-error-anchor 引用数为 0。
    basis: observation
    verification:
      criterionId: c4
      criterionVersion: 2
      method: yarn typecheck（主工作树）
      result: passed
      coverage: 仅类型检查与引用检索；不含构建与真实界面验收
    createdAt: 2026-09-21T13:35:23.948Z
  - id: p5
    kind: progress
    content: "按用户要求提交三个文件（McpPanel.tsx、ResourcesPanel.tsx、styles.ts）为 af57d13（fix: end the card action row with its diagnostic action），9+/7-；提交后工作树干净，未 push。"
    basis: user-request
    createdAt: 2026-09-21T14:00:59.975Z
  - id: p6
    kind: progress
    content: 原生验收通过（ok=true，96 条断言 0 失败，退出码 0）。方式：用壳自身的 openNativeProject 启动真实 Host/Renderer 项目窗口（DSH_PROJECT_PLUGIN_SOURCE 指向本地插件工作区并重新编译），全程读实时 DOM 几何（getBoundingClientRect + computed gap），不以截图像素作为判据。覆盖 zh/en × light/dark × 1180/420 共 8 组。
    basis: observation
    createdAt: 2026-09-21T14:07:10.047Z
  - id: v6
    kind: verification
    content: "资源卡片（Diag order-backend，带 Git 诊断）DOM 顺序为：资源详情 | 更新资源 | 关联远端 | 绑定目录 | 编辑资源 | 移除资源 | 诊断（错误文案）。诊断按钮为最后一项，普通动作均以 “: <资源名>” 结尾。"
    basis: observation
    verification:
      criterionId: c1
      criterionVersion: 2
      method: 真实窗口 executeJavaScript 读取 footer 按钮顺序（aria-label 序列）
      result: passed
      coverage: 8 组采样（zh/en × light/dark × 1180/420）
    createdAt: 2026-09-21T14:07:10.047Z
  - id: v7
    kind: verification
    content: 除 “详情” 后的设计性留白（1180px 下 142~153px，由 .project-resource-details-action 的 margin-right:auto 有意保留）外，8 组采样的所有相邻按钮间距均为 2px，等于 footer 的 columnGap；footerScroll 均为 0，旧的 .project-mcp-error-anchor 引用计数均为 0。
    basis: observation
    verification:
      criterionId: c2
      criterionVersion: 2
      method: footer 内按钮 getBoundingClientRect 逐对差值 + computed columnGap
      result: passed
      coverage: 8 组采样；详情后的设计性留白不列入断言，已单独说明
    createdAt: 2026-09-21T14:07:10.047Z
  - id: v8
    kind: verification
    content: 8 组采样均为 bodyScroll <= 0（页面无横向溢出）；中英文案同时验证：诊断按钮标签为中文 “请选择具有有效远端的 Git 工作区根目录。” / 英文 “Select a Git working-tree root with a valid origin.”，明暗主题下取色正常。
    basis: observation
    verification:
      criterionId: c3
      criterionVersion: 2
      method: 窗口尺寸/主题/语言切换后读取 document.body.scrollWidth 与按钮可访问名
      result: passed
      coverage: zh/en × light/dark 四组合 × 1180/420 两宽度
    createdAt: 2026-09-21T14:07:10.047Z
  - id: v9
    kind: verification
    content: MCP 卡片（serverName=verify，错误态）DOM 顺序为：编辑 | 删除 | 连接错误详情；错误图标（svg.project-mcp-error-icon）仅出现在最后一个按钮上，相邻间距均为 2px，无溢出。
    basis: observation
    verification:
      criterionId: c5
      criterionVersion: 1
      method: 真实窗口读取 footer 按钮顺序与错误图标归属 + 间距
      result: passed
      coverage: 8 组采样
    createdAt: 2026-09-21T14:07:10.047Z
  - id: n2
    kind: progress
    content: 验收中发现既有缺陷（与本次改动无关，按钮集合与总宽未变）：窗口宽度 420px 时侧边栏未折叠，主内容区仅剩约 100px，资源卡片被压到约 63px，操作行按钮溢出卡片边界（footer clientWidth 43px，按钮总宽约 212px；因 justify-content:flex-end 溢出发生在左侧，scrollWidth 检测不到，page 也未横向溢出）。建议另开任务处理窄窗口布局。
    basis: observation
    createdAt: 2026-09-21T14:07:10.047Z
  - id: p7
    kind: progress
    content: 用户在自己的环境中确认修复已生效（人工验收通过）。
    basis: user-request
    createdAt: 2026-09-21T14:08:16.696Z
  - id: done1
    kind: completion
    content: 任务完成：资源卡片与 MCP 卡片的诊断（感叹号）按钮均排到操作行末尾，间距恢复为 footer 统一 2px gap，失去引用的 .project-mcp-error-anchor 规则已删除；改动已提交 af57d13，静态检查与真实窗口 DOM 验收均通过，用户人工确认。
    basis: observation
    verificationEntryIds:
      - v4
      - v5
      - v6
      - v7
      - v8
      - v9
    createdAt: 2026-09-21T14:08:16.696Z
operations:
  87bdbd980b1f993620ba1395fdb0322edd4a61ac95f5230ad849c23e2ef916a7:
    fingerprint: e3b8d9b688fef8513229e2ea5520b16604b37c5d10ce01912ab278ac9f0a512a
    kind: create
    at: 2026-09-21T12:15:29.468Z
    entryIds:
      - d1
      - p1
      - v1
      - n1
  a387a562b9dc273e2698627e788196c50a830d0ee2e3c6595cdd81fa765e8d3b:
    fingerprint: f598f77683b2e318960c636f066d1afcc247a9c88a1562bb8bfbd25025a5bd4d
    kind: update
    at: 2026-09-21T12:18:44.950Z
    entryIds:
      - s1
      - p2
      - p3
  2ab75fb7d15d08a1da15fc0a208e28ef1b18eb51c4859b0ec4396d71bcf43198:
    fingerprint: 296c9fd5a6da2bc0d6afdefd43b6f8697a9cca77dccdb04543343dcfa64c4120
    kind: update
    at: 2026-09-21T12:18:49.461Z
    entryIds:
      - v2
      - v3
      - v4
  c7fe3135cf5bd8248de77773a0860bf606eb30a815b14827d273479263d46ed4:
    fingerprint: 1b0816ebee02816dec6774698ca08313dcc313474c775f78b44c3f111b2d6f93
    kind: update
    at: 2026-09-21T13:35:23.948Z
    entryIds:
      - p4
      - v5
  3522c8815a119a0d6c8c999b0317cde5d215f0903ba829e8dc910a901f6c62f7:
    fingerprint: 9a5513c76e752b94de6342443bb8fa8a3442fc603c3fdb27e0886fb77e04a1c9
    kind: update
    at: 2026-09-21T14:00:59.975Z
    entryIds:
      - p5
  7d83e7f8c3b3cc025caa05f400be2a61df0e3b4d9f157f53cc9343bba2f31b53:
    fingerprint: 2ace6cfac09c0c3c2edab4d7835fd62436a62b4d382519369502074ad330a10e
    kind: update
    at: 2026-09-21T14:01:04.155Z
    entryIds: []
  3955eb9bc970bd31dbf134f352d179e4259b41ac67341c424a59bae89a1503b5:
    fingerprint: 6a68738413d0a34110db555675b1849f119c7dd5692d5aace9e29648d2871926
    kind: update
    at: 2026-09-21T14:07:10.047Z
    entryIds:
      - p6
      - v6
      - v7
      - v8
      - v9
      - n2
  3f19883789de15fd5064e1096f87324f668e66c05b8c3b790a7a0e953c581f78:
    fingerprint: c18fb7c7f017c67121c439cd8adccb5cb3e63e9e119e901b1a34251c86b3e6a2
    kind: update
    at: 2026-09-21T14:08:16.696Z
    entryIds:
      - p7
      - done1
criterionVersions:
  c1: 2
  c2: 2
  c3: 2
  c4: 2
  c5: 1
---

两处卡片操作行的诊断（感叹号）按钮已排到操作行末尾，间距恢复为 footer 统一 2px gap；造成空档的 .project-mcp-error-anchor{margin-right:auto} 包裹与失去引用的样式规则均已移除。改动提交为 af57d130a49cfe4b3d047e05f2e4eaf59ffbc385（插件仓库 master，未 push、未 bump 壳 lock）。验证：worktree 与主工作树 typecheck 通过；真实项目窗口（本地插件源编译）在 zh/en × light/dark × 1180/420 共 8 组下读实时 DOM，资源卡片与 MCP 卡片的诊断动作均为最后一项、间距 2px、无溢出、旧类引用为 0，96 条断言 0 失败；用户已在自身环境人工确认。遗留（另议）：420px 窄窗口下侧边栏未折叠导致卡片被压至约 63px、操作行溢出卡片边界，与本次改动无关。
