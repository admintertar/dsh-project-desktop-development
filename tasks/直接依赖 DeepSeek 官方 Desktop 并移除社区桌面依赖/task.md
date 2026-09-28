---
schemaVersion: 3
directory: 直接依赖 DeepSeek 官方 Desktop 并移除社区桌面依赖
id: task-37502cbe-09ad-41ca-9faa-0d9ac69a50b1
title: 直接依赖 DeepSeek 官方 Desktop 并移除社区桌面依赖
objective: 以 DeepSeek 官方 deepseek-harness/apps/desktop 为唯一 Desktop/Harness 来源，直接替换现有社区 Desktop Stable；保留项目级多窗口隔离、Project 插件能力、原应用身份和用户数据，并完成可回退迁移及跨平台验收。
status: active
createdAt: 2026-09-28T10:27:28.000Z
updatedAt: 2026-09-28T10:36:37.000Z
artifacts:
  - type: file
    path: artifacts/design.md
    description: 官方 Desktop 原位替换方案；包含架构选择、数据与发行策略、实施阶段和最终验收。
  - type: file
    path: artifacts/issues.md
    description: 迁移问题清单；包含 12 个问题、待证实的官方契约和社区模块到官方基线的初步映射。
archived: false
phase: design
brief:
  currentBehavior: 已发布壳 0.1.11 仍固定 Anywhere Labs Desktop 2.0.15 和官方 Harness 0.1.7-rc.2。壳运行时大量调用社区 Desktop 私有模块；Project 插件的开发 setup 和来源锁也仍指向社区仓库。之前的 2.0.15 升级与 0.1.11 发布已完成，本任务是移除社区 Desktop 这一中间层。
  scope: 从固定的 DeepSeek 官方 Git 提交构建 apps/desktop 与官方 DSH 包，改造两个公开仓库的 Host、窗口、Profile、恢复、插件、setup、打包和 CI；对现有安装与项目数据做原位迁移并完成 macOS/Windows/Intel 验收。方案与问题清单先作为本任务产物，本轮不启动代码实施。
  constraints:
    - Desktop/Harness 的运行、构建、测试、CI 和安装包来源只允许固定的 deepseek-ai/deepseek-harness 提交；不得依赖 Anywhere Labs 的 Desktop 包、源码快照或缓存。
    - 保持独立 Shell，不维护官方 Desktop fork；单一主进程下每个项目的窗口、Host、DSH Home、Profile 和 Chromium 分区仍需隔离。
    - 直接替换当前 Stable，沿用应用身份、用户数据根、项目文件和更新入口；正式迁移前先在副本验证，失败时必须可恢复旧数据。
    - 不静默删除现有用户可见功能；官方未提供项目级界面时，由壳基于官方组件实现并做真实窗口验收。
    - 不修改官方源码快照；全部上游来源固定 commit、校验树和依赖锁。
  outOfScope:
    - 将 Anywhere Labs Next 作为运行或构建依赖。
    - 新建与 Stable 并行安装的另一套应用身份或共享数据目录。
    - 本轮直接发布新版本或实施应用代码；先完成任务化与方案评审。
  acceptanceCriteria:
    - id: official-source
      text: 两仓库的来源锁、安装与构建闭包、CI checkout、运行时导入和安装包均可追溯到同一固定官方 Harness/Desktop 提交及配套 Project 插件提交；无 Anywhere Labs Desktop 依赖，从干净工作目录可复现。
      required: true
      version: 1
    - id: multi-project
      text: 两个项目同时运行时窗口、Host、Profile、认证、协议 Session 和恢复生命周期互不串线；一个项目故障不影响另一个，并有真实 Electron 验证。
      required: true
      version: 1
    - id: feature-parity
      text: 官方 Web 前端及现有 Profile 选择、恢复、设置、终端、诊断、更新、项目市场和 Project 插件的 Tasks、Resources、Memory、skills、MCP 能力完成行为对照和真实窗口验收。
      required: true
      version: 1
    - id: data-migration
      text: 从已发布 0.1.11 项目数据原位升级有备份、迁移日志、故障恢复及旧包回退演练；项目列表、项目文件和项目根数据保持完整。
      required: true
      version: 1
    - id: package-validation
      text: Shell 与 Project 插件的源码检查通过，macOS Universal、Windows x64 安装包及 Intel 对同一 DMG 的启动验收通过；安装包内的官方依赖与许可证审计通过。
      required: true
      version: 1
    - id: replacement-release
      text: 正式替换版沿用既有 app ID、数据路径及 Stable 更新清单契约，旧版客户端能发现和安装；公开发布前保留旧版安装包与配对的数据恢复方案。
      required: true
      version: 1
questions:
  - 官方 apps/desktop 的 private 包与构建产物中哪些模块可直接复用，哪些需从同一固定提交按源码构建？先做可行性实验，不预设接口稳定。
  - 官方桌面只有应用级 mainWindow 与 profiles/desktop；项目级 Profile 选择、创建和恢复界面应如何复用官方底层能力并维持功能等价？
  - 已发布 0.1.11 的数据转入官方 Desktop 运行方式时，哪些 Profile、设置、会话和插件状态需要显式迁移与回退处理？
handoff:
  nextSteps:
    - 先审阅方案和 12 个问题点，确认官方源码复用边界与正式版功能等价门槛。
    - 执行方案第 1 阶段：固定官方提交，验证官方 apps/desktop 构建及单项目 Host/前端启动，审计无社区 Desktop 构建输入。
    - 可行性关口通过后再拆分双项目运行、插件兼容、旧数据迁移和打包发行工作。
  readBefore:
    - design
    - issues
    - completed-upgrade
  verifyBefore:
    - 对照已发布 0.1.11 的远端 upstream.lock.json 和配套插件提交；本地 resources 检出可能落后，不能把旧检出当现行版本。
    - 先证明官方依赖的构建与单项目原生启动，再修改现有 Stable 安装或用户数据。
references:
  - id: design
    label: 官方 Desktop 原位替换方案
    type: file
    path: tasks/直接依赖 DeepSeek 官方 Desktop 并移除社区桌面依赖/artifacts/design.md
  - id: issues
    label: 迁移问题点与验证清单
    type: file
    path: tasks/直接依赖 DeepSeek 官方 Desktop 并移除社区桌面依赖/artifacts/issues.md
  - id: completed-upgrade
    label: 已完成的 Desktop 2.0.15 与 0.1.11 升级任务
    type: task
    taskId: task-520a5ee5-3ffb-4a29-ae38-4e258084522b
  - id: official-desktop
    label: DeepSeek 官方 Desktop 源码
    type: url
    url: https://github.com/deepseek-ai/deepseek-harness/tree/master/apps/desktop
entries:
  - id: target
    kind: decision
    content: 用户要求直接替换现有 Stable，完全移除 Anywhere Labs 社区 Desktop 依赖，以 DeepSeek 官方 deepseek-harness/apps/desktop 为唯一 Desktop/Harness 来源；先整理方案和问题点为项目任务。
    basis: user-request
    referenceIds:
      - official-desktop
      - design
    createdAt: 2026-09-28T10:27:28.000Z
  - id: plan-recorded
    kind: progress
    content: 已形成官方 Desktop 原位替换方案和 12 项问题清单；已核对任务界面的已完成 0.1.11 升级任务，当前任务独立跟踪移除社区 Desktop 的后续迁移。本轮仅登记任务和文档，不宣称应用实现或迁移验收完成。
    basis: observation
    referenceIds:
      - design
      - issues
      - completed-upgrade
    createdAt: 2026-09-28T10:27:28.000Z
  - id: docs-relocated
    kind: progress
    content: 两份 2026-09-28 官方 Desktop 迁移文档已以本任务 artifacts/design.md 和 artifacts/issues.md 为唯一项目内副本；已清理壳仓库 docs/plans 下对应的重复草稿。2026-09-27 的 Desktop 2.0.15 升级计划属于已完成的旧任务，仍保留原位。
    basis: observation
    referenceIds:
      - design
      - issues
      - completed-upgrade
    createdAt: 2026-09-28T10:36:37.000Z
operations: {}
criterionVersions:
  official-source: 1
  multi-project: 1
  feature-parity: 1
  data-migration: 1
  package-validation: 1
  replacement-release: 1
---

从已发布 0.1.11（社区 Desktop 2.0.15、官方 Harness 0.1.7-rc.2）出发，改为固定 DeepSeek 官方 `apps/desktop` 源码与官方包，原位替换现有安装。先做官方构建与单项目启动实验，再推进双项目隔离、Project 插件、旧数据迁移和跨平台发布；每一步按两份任务产物中的问题点验收。
