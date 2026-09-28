---
schemaVersion: 3
directory: Desktop 2.0.15 升级迁移与 0.1.11 发布
id: task-520a5ee5-3ffb-4a29-ae38-4e258084522b
title: Desktop 2.0.15 升级迁移与 0.1.11 发布
objective: 将 0.1.10 使用的 Desktop 2.0.11 / Harness 0.1.5-rc.2 迁移到固定的 Desktop 2.0.15 / Harness 0.1.7-rc.2，升级 Project 插件并修复壳的窗口、设置与安装包兼容问题；完成源码、原生界面、Windows/macOS 安装包及 Intel 验收，发布 0.1.11，并记录合并状态。
status: completed
createdAt: 2026-09-28T10:03:30.000Z
updatedAt: 2026-09-28T10:39:40.000Z
artifacts:
  - type: file
    path: artifacts/desktop-2.0.15-upgrade-plan.md
    description: 从壳仓库 docs/plans 迁入的 Desktop 2.0.15 升级实施计划原文
  - type: commit
    repository: https://github.com/admintertar/dsh-plugin-project.git
    commit: 454e6bc0a27a897cc3415784932e74a29791d22e
    description: Project 插件固定提交：Desktop 2.0.15 适配、侧栏快捷键注入及运行时 peer 依赖声明
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: f4c56dcd0eafbf636a7ef53c44f73f494822306c
    description: 壳迁移到 Desktop 2.0.15 / Harness 0.1.7-rc.2，并适配窗口材质等上游契约
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: 9fb72f34f0d3fc0022889f0e85c03b8b72b48944
    description: 0.1.11 实际发布提交：补齐 Project 与 Host 的打包生产依赖
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: 041aa4488c12829f2a9cb9657781dc453e1f5f1b
    description: 壳仓库 PR #1 合并到远端 master
  - type: commit
    repository: https://github.com/admintertar/dsh-plugin-project.git
    commit: 17e8771da5ff693d7b72c11b868bbeb4c2c56334
    description: Project 插件仓库 PR #1 合并到远端 master，包含发布固定提交 454e6bc
  - type: url
    url: https://github.com/admintertar/dsh-project-desktop/actions/runs/36403488260
    description: 0.1.11 完整发布流水线：Windows、macOS 通用包、Intel DMG 与发布均成功
  - type: url
    url: https://github.com/admintertar/dsh-project-desktop/releases/tag/v0.1.11
    description: 公开 Release：Windows Setup/Portable、macOS universal DMG、三份 SHA-256 与 update.json
archived: false
phase: validation
brief:
  currentBehavior: 升级前的 0.1.10 固定 Desktop 2.0.11 / Harness 0.1.5-rc.2。切换到 2.0.15 后，上游内部契约改变，实际打开设置、任务侧栏和项目窗口时暴露兼容问题；最初的安装包还因生产依赖缺失而无法加载 Project API。
  scope: 两个公开仓库中的稳定版 source pin、Project 插件适配、Shell 窗口与设置适配、真实界面和打包验收、0.1.11 发布说明与 GitHub Release，以及壳仓库合并记录。
  constraints:
    - 官方 Desktop 与 Harness 源码快照只读，固定 commit、tree 和已安装版本需一致。
    - 先推送 Project 插件提交，再更新 Shell 的 upstream.lock.json，重导 Project 快照并运行 verify:upstream；发布构建只使用固定提交。
    - 源码检查与真实界面、安装包启动验收分别记录，不能用 macOS 验收替代 Windows 或 Intel 验收。
    - 原有任务和用户未提交改动保持不变；本任务只记录已核实的迁移与发布事实。
  outOfScope:
    - Apple Developer ID 公证和 Windows 代码签名；本版 macOS 为 ad-hoc 签名且未公证，Windows 未签名。
    - Project 插件其他功能开发与既有任务的归档。
  acceptanceCriteria:
    - id: stable-pins
      text: upstream.lock.json 固定 Desktop 2.0.15、Harness 0.1.7-rc.2 和已推送的 Project 提交及树；重新导出的来源通过 verify:upstream。
      required: true
      version: 1
    - id: compatibility
      text: 窗口材质与桌面设置样式恢复，Project 任务侧栏快捷键可用，macOS 目录选择器 IPC 契约得到适配；安装版能加载 Project API。
      required: true
      version: 1
    - id: source-checks
      text: Project 插件 yarn check 与 Shell yarn check 通过，并有真实 Electron 界面操作的验证记录。
      required: true
      version: 1
    - id: packaged-checks
      text: Windows 安装包、macOS 通用 DMG 的迁移后启动验收和 Intel 对同一份 DMG 的启动验收全部通过。
      required: true
      version: 1
    - id: release-and-merge
      text: v0.1.11 指向发布提交，Release 七个资产与公开 update.json 可访问；壳与插件升级分支均已合并到各自远端 master。
      required: true
      version: 1
handoff:
  readBefore:
    - upgrade-plan
    - release-notes
  verifyBefore:
    - 对照两个公开仓库的远端 master 与 upstream.lock.json 的 Project commit；确认发布 tag 和 CI run 36403488260。
references:
  - id: upgrade-plan
    label: Desktop 2.0.15 升级计划
    type: file
    path: tasks/Desktop 2.0.15 升级迁移与 0.1.11 发布/artifacts/desktop-2.0.15-upgrade-plan.md
  - id: release-notes
    label: 0.1.11 中英双语发布说明
    type: url
    url: https://github.com/admintertar/dsh-project-desktop/blob/master/docs/releases/0.1.11.md
  - id: stable-lock
    label: master 上的稳定版来源锁
    type: url
    url: https://github.com/admintertar/dsh-project-desktop/blob/master/upstream.lock.json
  - id: shell-merge
    label: 壳升级合并 PR #1
    type: url
    url: https://github.com/admintertar/dsh-project-desktop/pull/1
  - id: plugin-merge
    label: Project 插件升级合并 PR #1
    type: url
    url: https://github.com/admintertar/dsh-plugin-project/pull/1
entries:
  - id: select-upstream
    kind: decision
    content: 从 0.1.10 的 Desktop 2.0.11 / Harness 0.1.5-rc.2 迁到 Desktop 2.0.15 / Harness 0.1.7-rc.2；核对官方 commit、source tree、runtime inventory 与 Guide 来源树，只通过 Shell 的 upstream.lock.json 和导出的只读快照引用上游。
    basis: user-request
    referenceIds:
      - upgrade-plan
      - stable-lock
    createdAt: 2026-09-28T10:03:30.000Z
  - id: plugin-migration
    kind: progress
    content: Project 插件先按新的 Harness 版本更新 peer/dev 依赖和锁文件，再适配 Desktop 客户端注入；补齐官方 ExpandButton 所需的 shortcuts，解决任务页侧栏 useShortcuts is not a function。固定插件提交先推送，再由 Shell pin 到精确 commit/tree。
    basis: observation
    createdAt: 2026-09-28T10:03:30.000Z
  - id: shell-migration
    kind: progress
    content: Shell 迁移窗口、Profile、Host 与更新适配：补全官方窗口运行时字段和材质刷新契约以避免 refreshThemeMaterial 异常及设置页材质能力丢失；构建中保留 settings.css，注册 macOS 原生目录选择器 IPC，并调整 2.0.15 的 UI/Host 验收。
    basis: observation
    createdAt: 2026-09-28T10:03:30.000Z
  - id: packaged-regression
    kind: progress
    content: 首轮 Windows/macOS 安装版虽能启动，Project snapshot 返回 404。Windows 诊断定位到插件入口缺 @deepseek-ai/schemastery、Host 缺 ajv-formats；插件补齐 schemastery 与 dsh-scope 的 peer 声明，Shell 打包生产依赖补入 ajv-formats，之后以固定的插件提交 454e6bc 重跑完整流水线。
    basis: observation
    createdAt: 2026-09-28T10:03:30.000Z
  - id: verify-stable-pins
    kind: verification
    content: master 的 lock 固定 Desktop commit 08f1794、Harness commit 477b4f4、Project commit 454e6bc/tree 9fadbd9；Shell 本地 yarn check 的 verify:upstream 阶段通过。
    basis: observation
    verification:
      criterionId: stable-pins
      criterionVersion: 1
      method: 核对 origin/master:upstream.lock.json、固定来源树与 yarn check 输出
      result: passed
      coverage: Desktop、Harness、Project 的精确 pin 与来源完整性
    createdAt: 2026-09-28T10:03:30.000Z
  - id: verify-compatibility
    kind: verification
    content: 隔离 Electron 演示窗口确认桌面设置样式和任务侧栏恢复；macOS 目录选择器 IPC 的注册、同源校验与窗口关闭清理由源码确认；最终 Windows/macOS 打包版均通过 /api/project/snapshot 的安装检查。未单独留存系统目录对话框截图。
    basis: observation
    verification:
      criterionId: compatibility
      criterionVersion: 1
      method: 原生窗口交互、IPC 契约核对、smoke:updates 与 CI 安装版 verify-installation
      result: passed
      coverage: 设置样式、侧栏快捷键、目录选择器 IPC、Project 页面/API 加载
    createdAt: 2026-09-28T10:03:30.000Z
  - id: verify-source-checks
    kind: verification
    content: Project 插件在 Node 22 下 yarn check 通过（308 个测试）；Shell 在固定新 pin 下 yarn check 通过，涵盖来源校验、构建、应用测试、恢复、安全模式与双 Host 冒烟。
    basis: observation
    verification:
      criterionId: source-checks
      criterionVersion: 1
      method: 两仓库 yarn check；0.1.11 发布说明中的 Electron 演示验证
      result: passed
      coverage: 插件类型/测试/构建、Shell 源码回归与真实窗口操作
    createdAt: 2026-09-28T10:03:30.000Z
  - id: verify-packaged-checks
    kind: verification
    content: Package Desktop run 36403488260 的 Windows x64、macOS universal 及 Intel DMG 验收 job 均 success；安装版实际打开两个独立 Project Host，Project snapshot 返回 200。
    basis: observation
    verification:
      criterionId: packaged-checks
      criterionVersion: 1
      method: GitHub Actions Package Desktop run 36403488260 的原生安装包启动与 Intel 重启验证
      result: passed
      coverage: Windows Setup/Portable、macOS universal DMG、Intel 同一份 DMG
    createdAt: 2026-09-28T10:03:30.000Z
  - id: verify-release-and-merge
    kind: verification
    content: v0.1.11 tag 指向 9fb72f3；Release 非 draft，含 7 个资产，流水线验证匿名公开 update.json（ok=true）。壳 master 的合并提交为 041aa44，包含 9fb72f3；插件 master 的合并提交为 17e8771，包含发布固定的 454e6bc。
    basis: observation
    referenceIds:
      - shell-merge
      - plugin-merge
    verification:
      criterionId: release-and-merge
      criterionVersion: 1
      method: git ls-remote、GitHub Release 资产与工作流结果、两仓库 origin/master 祖先检查
      result: passed
      coverage: 公开发布、更新清单与壳/插件两个 master 合并
    createdAt: 2026-09-28T10:03:30.000Z
  - id: completion
    kind: completion
    content: Desktop 2.0.15 / Harness 0.1.7-rc.2 迁移、0.1.11 发布，以及壳和插件两个 master 合并均已完成。
    basis: observation
    verificationEntryIds:
      - verify-stable-pins
      - verify-compatibility
      - verify-source-checks
      - verify-packaged-checks
      - verify-release-and-merge
    createdAt: 2026-09-28T10:03:30.000Z
operations: {}
criterionVersions:
  stable-pins: 1
  compatibility: 1
  source-checks: 1
  packaged-checks: 1
  release-and-merge: 1
---

从 0.1.10 的 Desktop 2.0.11 / Harness 0.1.5-rc.2 迁移到固定的 Desktop 2.0.15 / Harness 0.1.7-rc.2，步骤依次为：核对并重算上游 pin 与树、升级 Project 插件、适配 Shell 的窗口和设置契约、做源码与真实界面检查、修复安装版 Project/Host 依赖缺失、完成 Windows/macOS/Intel 打包验收，最后发布 v0.1.11。Release 和公开更新清单已验证；壳升级 PR #1（041aa44）与插件升级 PR #1（17e8771）均已合并到各自远端 master。
