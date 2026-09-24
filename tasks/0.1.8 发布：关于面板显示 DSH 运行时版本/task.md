---
schemaVersion: 3
directory: 0.1.8 发布：关于面板显示 DSH 运行时版本
id: task-0349eea4-426b-4e40-b5d9-dbb0f7bf96a7
title: 0.1.8 发布：关于面板显示 DSH 运行时版本
objective: 在关于面板里展示正在运行的 DSH（Harness）版本号，且该版本号与壳版本处于同一行、同一字号；macOS 应用菜单与 Windows/Linux 自绘顶栏两处提供同一原生面板入口。改动验证通过后按 0.1.8 发布（复用远端已存在但从未产出 Release 的 v0.1.8 tag），并把插件 pin 从 e28b0ed 提到 5193e81。
status: completed
createdAt: 2026-09-23T10:53:31.855Z
updatedAt: 2026-09-23T11:42:45.884Z
artifacts:
  - type: file
    path: artifacts/about-panel-0.1.8.png
    description: macOS 关于面板窗口截图（568x332，开发壳 0.1.8）
  - type: file
    path: artifacts/about-panel-ocr.txt
    description: 验收方法与 Vision OCR 输出：版本0.1.8（DSH 0.1.5-rc.2）
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: 2bad7f300efef95e5803f346fb36850a71642947
    description: 壳仓库 0.1.8 发布提交（pin 提到 5193e81、版本号、发布说明、关于面板改动）
  - type: commit
    repository: https://github.com/admintertar/dsh-plugin-project.git
    commit: 5193e8135fa0b27fc43d0a71a0072f3304a02090
    description: 插件 pin 提交（e28b0ed..5193e81：资源卡片领先提交悬停、滚动条空闲淡出、技能索引提交修复）
  - type: url
    url: https://github.com/admintertar/dsh-project-desktop/releases/tag/v0.1.8
    description: 0.1.8 Release 页面（7 个资产：mac universal DMG、win x64 Setup.exe / Portable.zip 及各自 sha256、update.json）
  - type: url
    url: https://github.com/admintertar/dsh-project-desktop/actions/runs/35851476122
    description: Package Desktop 发布构建 run（tag v0.1.8，全部 job 成功并发布）
archived: false
phase: implementation
brief:
  scope: 壳仓库：main.mjs 配置 app.setAboutPanelOptions；native.mjs + shell-titlebar-actions.mjs + shell-titlebar-client.tsx 增加 about action 与顶栏菜单项；单元测试与 docs/architecture.md 同步。发布：upstream.lock.json pin bump、.upstream/project 重导、package.json 版本、docs/releases/0.1.8.md、提交推送与 tag。
  constraints:
    - 不修改固定的官方源码快照；不升级官方运行时（仍为 Harness 0.1.5-rc.2 / Desktop 2.0.11）
    - 共享工作树只提交本次改动文件，不用 git add -A
    - 运行期目录（userData、截图临时文件）放 /tmp，任务 artifacts 只放结论级证据
  acceptanceCriteria:
    - id: ac1
      text: macOS 关于面板在同一版本行显示壳版本与 DSH Harness 版本（实测 OCR 文本为「DSH Project Desktop / 版本0.1.8（DSH 0.1.5-rc.2）」）
      required: true
      version: 1
    - id: ac2
      text: Windows/Linux 自绘顶栏「项目工具 → 关于 DSH Project Desktop」经 Shell titlebar action about 调用同一原生面板（单元测试覆盖 action 路由；本机无 Windows 实机）
      required: true
      version: 1
    - id: ac3
      text: 0.1.8 发布完成：pin 指向已推送的插件提交 5193e81、快照重导且 verify:upstream 通过、yarn check 通过、tag v0.1.8 指向发布提交并触发 CI 打包
      required: true
      version: 1
handoff:
  nextSteps:
    - next-guide-rerun
    - next-windows-about-acceptance
  readBefore:
    - read-release-notes
    - read-architecture
    - read-main
  verifyBefore:
    - verify-release-assets
    - verify-tag-target
references:
  - id: release-commit-url
    label: 壳仓库 v0.1.8 发布提交页面
    type: url
    url: https://github.com/admintertar/dsh-project-desktop/commit/2bad7f300efef95e5803f346fb36850a71642947
  - id: read-release-notes
    label: 0.1.8 发布说明
    type: note
    text: resources/dsh-project-desktop/docs/releases/0.1.8.md（中英双语，含已知限制与 tag 复用备注）
  - id: read-architecture
    label: 架构口径：原生菜单与关于面板
    type: note
    text: resources/dsh-project-desktop/docs/architecture.md 的「官方内部接入清单」段：两处关于入口与 DSH 版本字段的平台差异
  - id: read-main
    label: 关于面板配置实现
    type: note
    text: resources/dsh-project-desktop/src/app/main.mjs：app.whenReady() 后用 app.setAboutPanelOptions 写入壳版本与 lock.harness.version
  - id: next-guide-rerun
    label: 待观察：Guide 重跑
    type: note
    text: Verify Guide on Windows run 24（35856054742，workflow_dispatch，ref master，commit 2bad7f3）；push run 23 卡在 “Verify the create guide project path preview on Windows” 已取消。若再卡，按 Windows CI flake 另立任务。
  - id: next-windows-about-acceptance
    label: 待办：Windows 关于入口实机验收
    type: note
    text: Windows/Linux 自绘顶栏「项目工具 → 关于 DSH Project Desktop」目前只有单测与代码路径证据，可并入 task-7af5d595 的 Windows 实机验证。
  - id: verify-release-assets
    label: 核对 Release v0.1.8 资产
    type: note
    text: https://github.com/admintertar/dsh-project-desktop/releases/tag/v0.1.8：mac-universal DMG + win-x64 Setup.exe / Portable.zip 及各自 .sha256、update.json（共 7 个资产，非 draft）
  - id: verify-tag-target
    label: 核对 tag 指向
    type: note
    text: git ls-remote --tags origin | grep v0.1.8 → v0.1.8 指向 2bad7f300efef95e5803f346fb36850a71642947
entries:
  - id: impl-done
    kind: progress
    content: 实现完成：main.mjs 在 app.whenReady 后用 app.setAboutPanelOptions 统一配置关于面板（applicationName/applicationVersion 来自 product.mjs；macOS 用 version 字段显示 `DSH 0.1.5-rc.2`，Win32/Linux 无构建号字段改用 credits）；native.mjs 增加 about action → app.showAboutPanel()；shell-titlebar-actions.mjs 增加 about id；shell-titlebar-client.tsx 在「项目工具」末尾加「关于 DSH Project Desktop」；tests/shell-titlebar-actions.test.mjs 覆盖 action 路由；docs/architecture.md 记录两处入口与版本来源。工作树只提交本次 9 个文件，未夹带其他会话改动。
    basis: observation
    createdAt: 2026-09-23T10:55:20.677Z
  - id: verify-ac1
    kind: verification
    content: macOS 关于面板验收：开发壳（隔离 userData /tmp/dsh-about-inspect，package.json 0.1.8）+ 主进程 inspector 触发 app.showAboutPanel()，用 CGWindowList 定位 284x166 面板窗口后 screencapture -l 截图，macOS Vision OCR 读出 `DSH Project Desktop` / `版本0.1.8（DSH 0.1.5-rc.2）`——DSH 版本与壳版本同处版本行，即同一字号。证据：artifacts/about-panel-0.1.8.png 与 artifacts/about-panel-ocr.txt。未覆盖：面板视觉细节（对齐/换行）未逐像素核对。
    basis: observation
    verification:
      criterionId: ac1
      criterionVersion: 1
      method: 原生面板截图 + macOS Vision OCR（开发壳 + inspector 触发）
      result: passed
      coverage: macOS 原生关于面板的文本内容与版本行渲染形式
    createdAt: 2026-09-23T10:55:20.677Z
  - id: verify-ac2
    kind: verification
    content: Windows/Linux 顶栏入口：about action 经 shellTitlebarRequest 白名单与 createShellTitlebarActionRunner 路由到 electron.app.showAboutPanel()，单元测试 tests/shell-titlebar-actions.test.mjs 断言 about 到达 handler；yarn check 125 tests / 0 fail。未覆盖：Windows/Linux 实机视觉与原生面板外观（本机无 Windows 实机）。
    basis: observation
    verification:
      criterionId: ac2
      criterionVersion: 1
      method: 单元测试（node --test tests/shell-titlebar-actions.test.mjs，随 yarn check）
      result: passed
      coverage: action 白名单、路由与 handler 调用；不含 Windows 实机渲染
    createdAt: 2026-09-23T10:55:20.677Z
  - id: release-commit
    kind: progress
    content: 发布提交 2bad7f3 已推送到壳仓库 master：pin 从 e28b0ed 提到已推送的插件提交 5193e8135fa0b27fc43d0a71a0072f3304a02090（tree dcd0f0e8305a7dce4f4ce587b7ef4483d0819751，快照重导后 verify:upstream 通过），package.json 0.1.8，新增 docs/releases/0.1.8.md。v0.1.8 远端旧 tag（97fc8ed，从未产出 Release）已删除，新 tag v0.1.8 指向 2bad7f3 并推送，Package Desktop 工作流 35851476122 已触发。
    basis: observation
    createdAt: 2026-09-23T10:55:20.677Z
  - id: verify-ac3
    kind: verification
    content: ac3 验证：Package Desktop（tag v0.1.8，run 35851476122）全部 job 成功 —— plan / Package mac-universal / Package win-x64 / Verify universal DMG on Intel / Publish verified release；GitHub Release v0.1.8 已发布（非 draft，target 2bad7f3），7 个资产：mac-universal DMG 290.8 MB、win-x64 Setup.exe 138.4 MB、win-x64 Portable.zip 222.6 MB 及各自 .sha256、update.json；说明正文 9654 字符（docs/releases/0.1.8.md + 自动追加的下载与校验和）。master push 带起的另外两条：Verify Resources on Windows 成功（run 35851464548，相比上一轮 pin e28b0ed 时的 `the shared Skill index must not appear as its own card` 失败，本版 pin 5193e81 的技能索引提交修复使其转绿）、Probe project boot timing 成功。
    basis: observation
    verification:
      criterionId: ac3
      criterionVersion: 1
      method: GitHub Actions API 查询 run/job 结论 + Releases API 核对资产
      result: passed
      coverage: tag v0.1.8 触发的两平台构建、DMG 校验、自动发布与 Release 资产；不包含 Guide 工作流
    createdAt: 2026-09-23T11:42:28.803Z
  - id: guide-flake
    kind: progress
    content: 遗留：Verify Guide on Windows 的 push run 23（35851464588）自 10:56:41Z 起卡在 “Verify the create guide project path preview on Windows” 约 45 分钟无日志/无状态更新（job 日志 blob 不存在），与上一轮 run 22 同样被取消的现象一致；已取消该 run 并以 workflow_dispatch 重跑（run 24，35856054742，ref master，与发布提交同一 commit）。该工作流不阻塞发布（package.yml 只跑 smoke:updates），且它监听 package.json / upstream.lock.json，因此每次发布都会被带起。
    basis: observation
    createdAt: 2026-09-23T11:42:28.803Z
  - id: completion
    kind: completion
    content: 完成：关于面板现在显示正在运行的 DSH（Harness）版本，与壳版本同处一行、同一字号（macOS version 字段；Win32/Linux 用 credits），macOS 应用菜单与 Windows/Linux 自绘顶栏两处入口共用同一原生面板；插件 pin 提到 5193e81 并发布 0.1.8（复用旧 v0.1.8 tag）。三条验收均有 passed 证据。未含：Windows/Linux 关于入口实机视觉验收、Guide 工作流重跑结果（已另行监控）。
    basis: agent-proposal
    verificationEntryIds:
      - verify-ac1
      - verify-ac2
      - verify-ac3
    createdAt: 2026-09-23T11:42:45.884Z
operations:
  67665eadbc2c7965df2787713d97924384da422a5b1bb5081d1e7b8e502cba9e:
    fingerprint: 9041b478d4f5e88788fb45dbfc60e33935b28e693108f4bf01b4b5b7de0263b7
    kind: create
    at: 2026-09-23T10:53:31.855Z
    entryIds: []
  01ca6798c6de0f037f11f970c671a03c4df3b2d2ca25aa47620207cdb6974eb8:
    fingerprint: b5d7b726c8e235931017c4e7ea8a1095a0ac890d005493e33c699fae9b5b1955
    kind: update
    at: 2026-09-23T10:55:20.677Z
    entryIds:
      - impl-done
      - verify-ac1
      - verify-ac2
      - release-commit
  e2a02124c46feadb5594dc905ca6b5ed9bdd0b11a70460908b91162c99bee6ee:
    fingerprint: ed839761ae6a7d0b923d3ec0053fed80eb2618e1c11c669e84ceddd7a17123f7
    kind: update
    at: 2026-09-23T11:42:28.803Z
    entryIds:
      - verify-ac3
      - guide-flake
  8e834514e2ff10a11bc501bea88e4b93620a6c2a786b48c332c34fce2286775c:
    fingerprint: c6eb04b92e83a0e386c53bd702641680c07d9c403826fceda576d6b9a77d8083
    kind: update
    at: 2026-09-23T11:42:45.884Z
    entryIds:
      - completion
criterionVersions:
  ac1: 1
  ac2: 1
  ac3: 1
---

0.1.8 已发布并验证：关于面板显示正在运行的 DSH 版本（macOS 版本行为「版本 0.1.8（DSH 0.1.5-rc.2）」，与壳版本同字号；Win32/Linux 用 credits 行），macOS 应用菜单与 Windows/Linux 自绘顶栏「项目工具 → 关于 DSH Project Desktop」共用同一原生面板；插件 pin 从 e28b0ed 提到 5193e81，快照重导 + verify:upstream + yarn check 均通过；发布提交 2bad7f3，v0.1.8 tag 重指并推送，Package Desktop 两平台构建、DMG 校验与自动发布全部成功，Release 含 7 个资产与 update.json。已知限制：Windows/Linux 关于入口无实机视觉验收（仅单测与代码路径）；Guide Windows 工作流的 push run 卡死已取消并重跑（不阻塞发布）。
