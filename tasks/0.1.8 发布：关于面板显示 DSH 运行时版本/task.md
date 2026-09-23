---
schemaVersion: 3
directory: 0.1.8 发布：关于面板显示 DSH 运行时版本
id: task-0349eea4-426b-4e40-b5d9-dbb0f7bf96a7
title: 0.1.8 发布：关于面板显示 DSH 运行时版本
objective: 在关于面板里展示正在运行的 DSH（Harness）版本号，且该版本号与壳版本处于同一行、同一字号；macOS 应用菜单与 Windows/Linux 自绘顶栏两处提供同一原生面板入口。改动验证通过后按 0.1.8 发布（复用远端已存在但从未产出 Release 的 v0.1.8 tag），并把插件 pin 从 e28b0ed 提到 5193e81。
status: active
createdAt: 2026-09-23T10:53:31.855Z
updatedAt: 2026-09-23T10:55:20.677Z
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
references:
  - id: release-commit-url
    label: 壳仓库 v0.1.8 发布提交页面
    type: url
    url: https://github.com/admintertar/dsh-project-desktop/commit/2bad7f300efef95e5803f346fb36850a71642947
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
criterionVersions:
  ac1: 1
  ac2: 1
  ac3: 1
---


