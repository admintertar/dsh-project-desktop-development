---
schemaVersion: 3
directory: 直接依赖 DeepSeek 官方 Desktop 并移除社区桌面依赖
id: task-37502cbe-09ad-41ca-9faa-0d9ac69a50b1
title: 直接依赖 DeepSeek 官方 Desktop 并移除社区桌面依赖
objective: 以 DeepSeek 官方 deepseek-harness/apps/desktop 为唯一 Desktop/Harness 来源，直接替换现有社区 Desktop Stable；保留项目级多窗口隔离、Project 插件能力、原应用身份和用户数据，并完成可回退迁移及跨平台验收。
status: active
createdAt: 2026-09-28T10:27:28.000Z
updatedAt: 2026-09-30T02:08:31.000Z
artifacts:
  - type: file
    path: artifacts/design.md
    description: 官方 Desktop 原位替换方案；包含架构选择、数据与发行策略、实施阶段和最终验收。
  - type: file
    path: artifacts/issues.md
    description: 迁移问题清单；包含 14 个问题、待证实的官方契约和社区模块到官方基线的初步映射。
  - type: file
    path: artifacts/phase1-feasibility.md
    description: 官方 0.2.0-rc.2 来源 pin、构建、真实 Host、双 Host 与临时双 Electron 窗口隔离、Project 插件兼容实验结果与未完成项。
  - type: file
    path: artifacts/official-window-probe/result.json
    description: 临时双 Electron 窗口实验结果，不含认证 Cookie。
  - type: file
    path: artifacts/official-window-probe/window-A.png
    description: 官方 Web 在临时项目窗口 A 中的真实截图。
  - type: file
    path: artifacts/official-window-probe/window-B.png
    description: 官方 Web 在临时项目窗口 B 中的真实截图。
  - type: file
    path: artifacts/official-project-plugin-probe/result.json
    description: 官方 Host/Web 加载两个独立 Project 插件空项目的临时窗口结果。
  - type: file
    path: artifacts/official-project-plugin-probe/window-A.png
    description: 官方 Web 中 Project 插件临时窗口 A 的真实截图。
  - type: file
    path: artifacts/official-project-plugin-probe/window-B.png
    description: 官方 Web 中 Project 插件临时窗口 B 的真实截图。
  - type: file
    path: artifacts/official-runtime-probe/runtime-result.json
    description: macOS arm64 官方未签名运行目录的来源、完整性及原生验证结果，不含认证信息。
  - type: file
    path: artifacts/official-runtime-probe/result.json
    description: 使用官方运行目录及本地 Project 插件的双 Electron 窗口实验结果。
  - type: file
    path: artifacts/official-runtime-probe/window-A.png
    description: 官方运行目录启动 Project 插件临时窗口 A 的真实截图。
  - type: file
    path: artifacts/official-runtime-probe/window-B.png
    description: 官方运行目录启动 Project 插件临时窗口 B 的真实截图。
archived: false
phase: implementation
brief:
  currentBehavior: 已发布壳 0.1.11 仍固定 Anywhere Labs Desktop 2.0.15 和官方 Harness 0.1.7-rc.2。壳运行时大量调用社区 Desktop 私有模块；Project 插件的开发 setup 和来源锁也仍指向社区仓库。之前的 2.0.15 升级与 0.1.11 发布已完成，本任务是移除社区 Desktop 这一中间层。
  scope: 从固定的 DeepSeek 官方 Git 提交构建 apps/desktop 与官方 DSH 包，改造两个公开仓库的 Host、窗口、Profile、恢复、插件、setup、打包和 CI；对现有安装与项目数据做原位迁移并完成 macOS/Windows/Intel 验收。已开始阶段 1 可行性验证，最终替换须满足全部验收条件。
  constraints:
    - Desktop/Harness 的运行、构建、测试、CI 和安装包来源只允许固定的 deepseek-ai/deepseek-harness 提交；不得依赖 Anywhere Labs 的 Desktop 包、源码快照或缓存。
    - 保持独立 Shell，不维护官方 Desktop fork；单一主进程下每个项目的窗口、Host、DSH Home、Profile 和 Chromium 分区仍需隔离。
    - 直接替换当前 Stable，沿用应用身份、用户数据根、项目文件和更新入口；正式迁移前先在副本验证，失败时必须可恢复旧数据。
    - 不静默删除现有用户可见功能；官方未提供项目级界面时，由壳基于官方组件实现并做真实窗口验收。
    - 不修改官方源码快照；全部上游来源固定 commit、校验树和依赖锁。
  outOfScope:
    - 将 Anywhere Labs Next 作为运行或构建依赖。
    - 新建与 Stable 并行安装的另一套应用身份或共享数据目录。
    - 在迁移、跨平台验收与回退演练完成前发布替换版。
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
    - 已完成插件官方来源切换、Session 适配器和 macOS arm64 未签名官方运行目录；搬移前后原生/Host/Office smoke 及 payload 双窗口加 Project 插件通过。下一步将 Host、Session、dsh-app 与逐项目 IPC 接入正式 Shell 的项目生命周期，并将插件开发链接替换为固定发行依赖闭包；随后切换来源锁、setup/build/CI，审计无社区 Desktop 输入。
    - Project 插件默认 setup 与 upstream.json 已切换到固定官方 0.2.0-rc.2；接着清理历史社区 Electron 适配材料，并验证 Tasks、自动化可选包、Resources、Memory、skills、MCP 的真实行为。
    - 逐批替换壳的 Host、窗口、Profile 与恢复适配，随后进行旧数据迁移、打包和跨平台验收。
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
  - id: phase1
    label: 官方 0.2.0-rc.2 可行性实验
    type: file
    path: tasks/直接依赖 DeepSeek 官方 Desktop 并移除社区桌面依赖/artifacts/phase1-feasibility.md
  - id: completed-upgrade
    label: 已完成的 Desktop 2.0.15 与 0.1.11 升级任务
    type: task
    taskId: task-520a5ee5-3ffb-4a29-ae38-4e258084522b
  - id: official-desktop
    label: DeepSeek 官方 Desktop 源码
    type: url
    url: https://github.com/deepseek-ai/deepseek-harness/tree/master/apps/desktop
  - id: official-release
    label: DeepSeek Harness 0.2.0-rc.2 官方发布
    type: url
    url: https://github.com/deepseek-ai/deepseek-harness/releases/tag/dsh-v0.2.0-rc.2
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
  - id: historical-plan-relocated
    kind: progress
    content: 壳仓库 docs/plans 中最后一份 Desktop 2.0.15 升级计划已按用户要求迁到对应的已完成任务产物；本任务的两份官方 Desktop 迁移文档继续保存在本任务产物中。
    basis: user-request
    referenceIds:
      - completed-upgrade
      - design
      - issues
    createdAt: 2026-09-28T10:39:40.000Z
  - id: official-020-candidate
    kind: decision
    content: 用户指出官方 DSH 已更新到 0.2；核实当前最新公开 tag 为 dsh-v0.2.0-rc.2，固定 commit 639ed015397290b3745d163aafe02ffee4aa3f84 用于迁移实验，不跟随 master 浮动；此前 rc.1 候选已被 rc.2 supersede。
    basis: user-request
    referenceIds:
      - official-release
      - phase1
    createdAt: 2026-09-29T09:32:10.000Z
  - id: phase1-source-and-host
    kind: progress
    content: 在 codex/direct-official-desktop 分支增加候选来源 pin 和校验脚本；官方锁文件安装与 build:official 通过，官方真实 Host 验收通过。独立探针确认两个 Host 可同时启动、端口不同、跨项目 Cookie 不得访问、单个 Host 停止不影响另一个。壳 Electron 窗口、插件、现有数据、CI 和安装包尚未迁移，现行 Stable 锁仍指社区 Desktop。
    basis: observation
    referenceIds:
      - phase1
      - issues
    createdAt: 2026-09-29T09:32:10.000Z
  - id: plugin-020-candidate
    kind: progress
    content: Project 插件候选分支把 Harness peer 与开发依赖更新为 0.2.0-rc.2，锁定同一官方提交，适配官方 Sidebar 注入契约变化，并增加仅用官方工作区源码包的开发准备脚本；在该组合上 yarn run check 通过（类型检查、308 个测试和构建）。默认 setup、upstream.json、壳运行链与打包链仍依赖社区 Desktop，原生插件行为尚未验收。
    basis: observation
    referenceIds:
      - phase1
      - issues
    createdAt: 2026-09-29T10:20:00.000Z
  - id: official-two-electron-windows
    kind: progress
    content: 从固定官方 0.2.0-rc.2 构建启动两个临时 Electron 项目窗口，各自拥有 Host、认证 Cookie、dsh-app Session、分区和主 Frame IPC 映射；官方 Web 基础界面均完成 boot/transport，强制销毁 A 后 B 继续运行。截图和不含 Cookie 的结果已保存到任务 artifacts。尚未接入 Stable Shell、Project 插件或旧数据；用户正常关闭、恢复及跨项目安全场景仍待验证。
    basis: observation
    referenceIds:
      - phase1
      - issues
    createdAt: 2026-09-29T11:13:22.000Z
  - id: official-project-plugin-windows
    kind: progress
    content: 将候选 Project 插件链接到固定官方 0.2.0-rc.2 的两个临时 Profile，真实窗口首次暴露 macOS SidebarRoot 结构变化导致 Project 页面报错；插件已修复并以 309 项测试和构建验证。再次运行两个真实窗口时分别显示 Probe A/B 项目概览和能力入口，A 强制销毁后 B 存活且渲染器无 error。此结果不覆盖写入行为、正式 Shell、默认 setup、打包或旧数据迁移。
    basis: observation
    referenceIds:
      - phase1
      - issues
    createdAt: 2026-09-29T11:35:04.000Z
  - id: plugin-default-official-source
    kind: progress
    content: Project 插件默认 upstream.json、setup、开发包链接和中英开发说明已切换到固定 DeepSeek 官方 0.2.0-rc.2；校验 HEAD、tag、Desktop tree、pnpm 锁和干净工作树，拒绝旧社区源码及旧 Shell 锁。固定官方工作树 setup 成功，yarn run check 通过（类型检查、307 项测试、构建）。历史 Electron 回归材料和 Shell 正式运行、CI、打包、数据迁移仍未切换；不宣称零社区依赖验收完成。
    basis: observation
    referenceIds:
      - phase1
      - issues
    createdAt: 2026-09-29T12:10:43.000Z
  - id: official-session-adapter
    kind: progress
    content: 从临时探针提取官方 dsh-app 的逐项目 Electron Session/HTTP/WebSocket 适配器到 Shell，并保留可复用的主 Frame IPC 所属关系校验；3 项隔离测试通过。用固定官方 0.2.0-rc.2 的双 Host、双窗口与 Project 插件探针复验通过，A 强制销毁后 B 存活。正式 main.mjs 尚未接入，Shell check 仍被旧社区快照与锁树不一致阻断，不能计作正式迁移完成。
    basis: observation
    referenceIds:
      - phase1
      - issues
    createdAt: 2026-09-29T12:28:00.000Z
  - id: shell-build-layout-blocker
    kind: finding
    content: 核对正式 Shell 构建输入确认官方 apps/desktop 私有包 @deepseek-ai/dsh-desktop、独立 desktop-host、lib/main.js 和 Web dist 与当前社区 dsh-plugin-desktop/vendor runtime/manifest 构建闭包不兼容；直接改 upstream.lock.json 会在 verify-upstream 或 build.mjs 失败。下一步需先完成官方源码/Host/Web dist 到 Shell 构建输入映射，再接正式 main.mjs。
    basis: observation
    referenceIds:
      - issues
      - phase1
    createdAt: 2026-09-29T12:34:00.000Z
  - id: official-source-lock-name
    kind: progress
    content: Shell 的官方探针来源锁与校验脚本统一命名为 official-source.lock.json、verify-official-source.mjs；固定官方 0.2.0-rc.2 工作树校验复测通过。已发布 Stable 的 upstream.lock.json 仍保留社区来源，等待正式构建输入映射完成后切换。
    basis: observation
    referenceIds:
      - phase1
    createdAt: 2026-09-29T12:39:00.000Z
  - id: official-development-input-map
    kind: progress
    content: Shell 增加固定官方 0.2.0-rc.2 的 Desktop/Host/CLI/Web 构建输入映射及忽略目录暂存，清单记录 199 个文件（196 个 Web 文件）的 SHA-256，读取前拒绝符号链接及改动；5 项定向测试、双 Host、双 Electron 窗口加 Project 插件探针通过，A 销毁后 B 存活。Host/CLI 与 pnpm 依赖仍链接本机官方工作树，此阶段只是开发输入验证，不是可搬移安装包；正式 main.mjs、旧来源锁、setup、CI、打包及用户数据尚未迁移。
    basis: observation
    referenceIds:
      - phase1
      - issues
    createdAt: 2026-09-30T01:24:29.000Z
  - id: official-core-package-set
    kind: progress
    content: 调用固定官方 0.2.0-rc.2 的 release:pack、私有 Desktop Host pack、native entry pack 和 prepare-package-set.ts，生成 287 个 Desktop 核心第一方 tarball；Shell 新命令记录来源 pin 与描述文件哈希，官方验证器检查 tarball 大小和 SHA-512。复制集合到另一临时目录后校验通过，篡改一个包后被拒绝。该集合尚不含外部 npm 依赖、原生资源和 primary runtime，不能计作可安装包；正式运行、CI、用户数据未修改。
    basis: observation
    referenceIds:
      - phase1
      - issues
    createdAt: 2026-09-30T01:35:29.000Z
  - id: official-unsigned-runtime
    kind: progress
    content: Shell 从 287 个官方核心 tarball 和固定 mac-arm64 生产依赖锁组装完整未签名开发运行目录，包含 Host/CLI、Electron、Web/preload、原生模块及 Node/Python/pnpm 和 Office；清单 19,358 项，拒绝工作区外链。搬移前后官方原生/Host/Office smoke、payload 双窗口和双窗口加本地 Project 插件通过，A 强制销毁后 B 存活；9 项官方适配测试通过。修正 primary runtime 检查继承 Yarn cwd 和复用安装目录导致 pnpm 不退出的问题。正式 Shell check 仍被旧社区缓存树不匹配阻断；正式主进程、插件发行依赖、其他平台、数据迁移和发布尚未完成。
    basis: observation
    referenceIds:
      - phase1
      - issues
    createdAt: 2026-09-30T02:08:31.000Z
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
