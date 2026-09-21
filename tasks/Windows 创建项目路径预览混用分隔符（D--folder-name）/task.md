---
schemaVersion: 3
directory: Windows 创建项目路径预览混用分隔符（D--folder-name）
id: task-cb5e0cb7-db1c-44f2-8915-764d907a95de
title: Windows 创建项目路径预览混用分隔符（D:\folder/name）
objective: 修复 Windows 上「新建项目」引导的路径预览把硬编码的 "/" 接在反斜杠目录之后、显示成 D:\DevelopProjiectluss/uss 的缺陷：预览改为按平台分隔符拼接，与 node:path.join 实际创建的路径一致；同一处硬编码拼接一并清理。实际创建路径与校验逻辑不变。
status: completed
createdAt: 2026-09-21T07:41:22.555Z
updatedAt: 2026-09-21T08:17:43.238Z
artifacts:
  - type: file
    path: artifacts/guide-selection-en.png
    description: macOS arm64 原生聚焦用例的引导窗口截图：Project path 预览为单一 / 分隔的 /…/Edited location/Guide project
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop
    commit: a485b5ce0bb10639edc645d1f918c76e773c9f30
    description: "fix: preview the Windows project path with the platform separator（仅含本人 5 个文件：project-path 纯函数与测试、ProjectPathField/guide-window 分隔符、native-guide-checks 精确断言）"
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop
    commit: d40e19a0578c9735a00a90318e1bc3f8eb3e7ec0
    description: "ci: verify the create guide on a Windows runner（新增 windows-2022 workflow + smoke:guide:focused 聚焦入口）"
  - type: url
    url: https://github.com/admintertar/dsh-project-desktop/actions/runs/35576067920
    description: Windows 原生验收 CI run（Verify Guide on Windows，head d40e19a）：windows-2022 上跑 npm run smoke:guide:focused 并上传引导窗口截图与 result.json
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop
    commit: 271d47305368a3e7be4d3b87104e763d54277c5b
    description: "ci: include the hidden runtime evidence in the Windows guide artifact（include-hidden-files: true；产物从 0 变为 228 KB）"
  - type: url
    url: https://github.com/admintertar/dsh-project-desktop/actions/runs/35576532201
    description: Windows 原生验收成功 run（head 271d473）：plan 与 Create guide on windows-2022 均 success，产物 guide-windows-271d473... 228504 字节（截图 + result.json）
archived: false
phase: implementation
brief:
  currentBehavior: src/guide/index.tsx 的 ProjectPathField 直接渲染 {directory}/{projectName}。Windows 下 directory 来自 app.getPath('documents') 或原生目录选择器（反斜杠），预览因此显示为 D:\DevelopProjiectluss/uss；src/windows/guide-window.mjs 也用模板字符串 ${directory}/... 拼接文件名。
  scope: resources/dsh-project-desktop 创建引导的路径预览（ProjectPathField）与 guide-window.mjs 中同类的硬编码分隔符拼接；不触碰实际创建路径计算与校验。
  constraints:
    - 创建引导渲染进程运行在 sandbox + contextIsolation 下，没有 node:path，平台分隔符只能取 chrome.platform
    - Windows 预览必须与 node:path.join 的创建结果一致（统一反斜杠），非 Windows 保持原样
    - 不改变实际创建路径、目标校验与资源相对路径（resources/name 有意使用可移植的 /）
  outOfScope:
    - 资源草稿的仓库相对路径 resources/name（有意跨平台使用 /）
    - 项目实际创建目录的计算与已存在目标校验
    - 目录输入框本身的值归一化
  acceptanceCriteria:
    - id: c1-windows-separator
      text: Windows 预览统一使用反斜杠且不混用：普通目录、正斜杠输入、末尾分隔符、驱动器根 C:\ 与 UNC 路径
      required: true
      version: 1
    - id: c2-posix-unchanged
      text: 非 Windows 预览与改动前一致（/ 分隔），macOS 真实引导窗口用例通过
      required: true
      version: 1
    - id: c3-build
      text: npm run build 通过并重新生成 dist/guide bundle；除环境相关的 project-bootstrap-network.test.mjs 外单元测试全绿
      required: true
      version: 1
    - id: c4-windows-native
      text: Windows 机器上原生确认预览显示为 D:\...\name
      required: false
      version: 1
questions:
  - Windows 断言已在 CI 通过；剩下的只是人工目视截图（需登录 GitHub 下载 run 35576532201 的产物，本机无 gh/token 无法代下载）。
  - 工作区仍有另一会话在途改动（AddResourceModal.tsx、native-guide-add-checks.mjs、project-bootstrap.mjs、tests/project-bootstrap.test.mjs），未纳入本次提交。
handoff:
  nextSteps:
    - 登录 GitHub 打开 run 35576532201 下载产物 guide-windows-271d473...，目视确认 guide-selection-en.png 中 Project path 预览为 D:\...\name（本机无 gh/token，无法代下载）
  readBefore:
    - frontend-guidelines
    - project-path-helper
  verifyBefore:
    - https://github.com/admintertar/dsh-project-desktop/actions/runs/35576532201
references:
  - id: frontend-guidelines
    label: Shell 前端规范
    type: file
    path: resources/dsh-project-desktop/docs/frontend-guidelines.md
  - id: project-path-helper
    label: 路径预览纯函数
    type: file
    path: resources/dsh-project-desktop/src/shared/project-path.mjs
entries:
  - id: finding-root-cause
    kind: progress
    content: 根因：src/guide/index.tsx:182（改前）的路径预览把硬编码 "/" 直接拼在目录后：{directory}/{projectName || 'project'}。Windows 上 directory 是反斜杠路径（默认 app.getPath('documents')，或原生 dialog.showOpenDialog 返回的 D:\...），因此显示成 D:\DevelopProjiectluss/uss；末尾带分隔符时还会出现 \/ 双分隔符。src/windows/guide-window.mjs:122,134 存在同类模板字符串拼接（basename(`${directory}/...`)），Windows 上 basename 恰好能处理两种分隔符，所以没有可见症状，但属于同一模式。资源草稿的 resources/name 是仓库相对路径，跨平台使用 / 是有意设计，不属于本缺陷。
    basis: observation
    createdAt: 2026-09-21T07:41:22.555Z
  - id: fix-platform-preview
    kind: progress
    content: 修复：新增纯函数 src/shared/project-path.mjs 的 projectPathPreview(directory, name, platform)，按 platform === 'win32' 统一反斜杠（与 node:path.join 在 win32 的行为一致），并保留驱动器根与 / 根、去掉末尾分隔符；ProjectPathField 新增 platform 属性，由 Guide 传入 frameState.chrome.platform（渲染进程已有的平台来源，无需新 IPC）。guide-window.mjs 两处改为 join(directory, ...)。
    basis: agent-proposal
    createdAt: 2026-09-21T07:41:22.555Z
  - id: ver-unit-separator
    kind: verification
    content: 单元测试：新增 tests/project-path.test.mjs，3 个用例全通过。覆盖 win32 普通目录（D:\DevelopProjiectluss\uss）、正斜杠输入归一为反斜杠、末尾分隔符、驱动器根 C:\app、UNC \\server\share\team\app、空名称；以及 posix 目录/根/末尾分隔符与空目录不产生前导分隔符。
    basis: observation
    verification:
      criterionId: c1-windows-separator
      criterionVersion: 1
      method: node --test tests/project-path.test.mjs
      result: passed
      coverage: c1 的全部列举情形 + posix 对照，3/3 通过
    createdAt: 2026-09-21T07:42:03.549Z
  - id: ver-native-macos
    kind: verification
    content: 原生验收：scripts/native-guide-checks.mjs 的 checkGuide 新增精确断言 document.querySelector('.projectPathPreview').textContent === join(editedLocation, 'Guide project')，在 macOS arm64 真实 Electron 引导窗口运行通过（临时 harness 位于 .runtime，仅跑 checkGuide；完整 smoke:guide 的 checkGuideFrame 需要真实 OS 窗口焦点，在本会话环境会超时）。截图见 artifacts/guide-selection-en.png，预览显示为 /…/fixtures/AgentIDE/Edited location/Guide project。
    basis: observation
    verification:
      criterionId: c2-posix-unchanged
      criterionVersion: 1
      method: Electron 原生聚焦用例（checkGuide + .projectPathPreview 精确断言）+ 截图
      result: passed
      coverage: 非 Windows 行为未变；预览与实际创建根一致（用例后面还断言 createdRoot === join(editedLocation, 'Guide project')）
    createdAt: 2026-09-21T07:42:03.549Z
  - id: ver-build-regression
    kind: verification
    content: 构建与回归：npm run check 的 verify:upstream 与 build 阶段通过（dist/guide/index.js 于 15:03 重新生成）；排除 tests/project-bootstrap-network.test.mjs 后的单元测试 74/74 通过。project-bootstrap-network.test.mjs 在本会话沙箱内单独运行也直接挂起（loopback HTTPS 克隆夹具），与本改动无关，属环境限制。
    basis: observation
    verification:
      criterionId: c3-build
      criterionVersion: 1
      method: npm run build（经 npm run check 前两阶段）+ node --test（除 project-bootstrap-network.test.mjs）
      result: passed
      coverage: bundle 重新生成 + 除环境挂起文件外全部单元测试通过
    createdAt: 2026-09-21T07:42:03.549Z
  - id: ver-windows-pending
    kind: verification
    content: c4 未运行：本机为 macOS arm64，无法完成 Windows 原生视觉确认；按仓库约定不得用 macOS 结果推断 Windows 验收。
    basis: observation
    verification:
      criterionId: c4-windows-native
      criterionVersion: 1
      method: 需要在 Windows 上运行聚焦原生用例
      result: not-run
      coverage: 未在 Windows 机器上打开真实引导窗口
      reason: 无 Windows 运行环境
    createdAt: 2026-09-21T07:42:03.549Z
  - id: completion-path-preview
    kind: completion
    content: 完成：路径预览改为按平台分隔符拼接（src/shared/project-path.mjs + ProjectPathField 的 platform 属性），guide-window.mjs 两处改用 join()；Windows 逻辑由单元测试覆盖，macOS 原生用例无回归。
    basis: observation
    verificationEntryIds:
      - ver-unit-separator
      - ver-native-macos
      - ver-build-regression
    createdAt: 2026-09-21T07:42:03.549Z
  - id: commit-a485b5c
    kind: progress
    content: 已提交为壳仓库 a485b5ce0bb10639edc645d1f918c76e773c9f30（master），仅包含本次改动 5 个文件。提交用 git apply --cached 只暂存了 index.tsx 与 native-guide-checks.mjs 中属于本缺陷的 hunk；工作区仍保留另一会话在 project-bootstrap.mjs / AddResourceModal.tsx / native-guide-add-checks.mjs / tests/project-bootstrap.test.mjs 及两文件其余 hunk 的在途改动，未被提交。未 push。
    basis: observation
    createdAt: 2026-09-21T07:48:26.114Z
  - id: ci-windows-workflow
    kind: progress
    content: 按用户选择的方案 A 推送 master（89418fc..d40e19a），同时发布另一会话已完成的 492e7e6（用户明确选择包含它）。新增 .github/workflows/guide-windows.yml：在 windows-2022 上按 package.yml 同样方式导入固定源码（ci-plan.mjs 解析 pin）、构建 guide bundle、执行 npm run smoke:guide:focused 并上传 .runtime/guide-frame-* 的截图与 result.json；触发条件为 push 到 master 的相关路径或手动 dispatch。为此给 smoke-guide.mjs / native-guide-case.mjs 加了 --focused（只跑 checkGuide，跳过需要真实窗口焦点的 frame 检查），并新增 npm script smoke:guide:focused；本地 macOS 先验证该入口通过（result.json platform=darwin）。
    basis: agent-proposal
    createdAt: 2026-09-21T08:08:12.594Z
  - id: ver-windows-ci
    kind: verification
    content: "c4 Windows 原生验收通过：GitHub Actions windows-2022 run 35576532201 中，步骤 Verify the create guide project path preview on Windows（npm run smoke:guide:focused）success，上传产物 guide-windows-271d47305368a3e7be4d3b87104e763d54277c5b（228504 字节，含 guide-selection-en.png 与 result.json）。该步骤跑的是真实 Windows Electron 引导窗口，断言 document.querySelector('.projectPathPreview').textContent === path.join(editedLocation, 'Guide project')；在 win32 下 join 产出反斜杠路径，若预览仍是混用分隔符该断言必失败。首轮 run 35576067920 步骤已通过，但产物为 0（actions/upload-artifact 默认不上传隐藏目录 .runtime），已用 include-hidden-files: true 修复并重跑。"
    basis: observation
    verification:
      criterionId: c4-windows-native
      criterionVersion: 1
      method: GitHub Actions windows-2022 run 35576532201：npm run smoke:guide:focused + 产物上传
      result: passed
      coverage: 真实 Windows x64 runner 上的引导窗口断言通过 + 截图/result.json 产物已生成；截图本身需登录下载后目视确认
    createdAt: 2026-09-21T08:16:39.113Z
operations:
  0afbd8dc6259d483cf74513c4c4a34c005b2292851d3ef7553aa28f642a413c2:
    fingerprint: bd51f436d5c29bd258ea54a08fb0bbbb5e552ab93ce0dfad1116e51ea8ca1580
    kind: create
    at: 2026-09-21T07:41:22.555Z
    entryIds:
      - finding-root-cause
      - fix-platform-preview
  e075ccf4c65a1be12b55d569ffb2783b3785fba5627848630e01b289e7429b2b:
    fingerprint: a179db1ce77192248db484f1dc1ece889211d5740a09f5d665d9d6d6048883b4
    kind: update
    at: 2026-09-21T07:42:03.549Z
    entryIds:
      - ver-unit-separator
      - ver-native-macos
      - ver-build-regression
      - ver-windows-pending
      - completion-path-preview
  e21a2c9554601344906beeb201f19c09e5a12c300ed2ac0d286231e75c14a44f:
    fingerprint: 07388aa0ed01fcbda8dfbe515623e004e205c7e9a1cc9e00e6531e6cfc2a8bf6
    kind: update
    at: 2026-09-21T07:48:26.114Z
    entryIds:
      - commit-a485b5c
  8ff4675778c9ace57598e6fd341a288c4d73f6215b0b2d6ecd2ee16aa3b234dc:
    fingerprint: 78e4e0f708dccd4c54380a8a5ffb78ca5832f4a4756d0a44e8b99b1a5e0925fc
    kind: update
    at: 2026-09-21T08:08:12.594Z
    entryIds:
      - ci-windows-workflow
  9d6f825d59638ed2df2dfce12c0b412c7f737199e334c6d3260963a7b65b0c30:
    fingerprint: 874927517c20dc54affbf5ef50f3e0c6149ce31ce8bdf87f4dfc8de3dcb67899
    kind: update
    at: 2026-09-21T08:16:39.113Z
    entryIds:
      - ver-windows-ci
  615577c107ccb157c0503bc0c970f517fc1060476049cbb026ad41140ed84fd0:
    fingerprint: 915a88cf2054564d32bb90ed955a50d86729e8083f339408e5aaed3a2dcfc938
    kind: update
    at: 2026-09-21T08:17:43.238Z
    entryIds: []
criterionVersions:
  c1-windows-separator: 1
  c2-posix-unchanged: 1
  c3-build: 1
  c4-windows-native: 1
---

缺陷已定位、修复、推送并通过 Windows 原生验收：Windows 创建项目引导的路径预览把硬编码 "/" 接在反斜杠目录之后（D:\\DevelopProjiectluss/uss）。修复为 src/shared/project-path.mjs 的纯函数 projectPathPreview(directory, name, platform)（win32 统一反斜杠，与 node:path.join 一致，保留 C:\\ 与 / 根、去掉末尾分隔符），ProjectPathField 从 frameState.chrome.platform 取平台；guide-window.mjs 两处改用 join()。验收：单测 3/3；macOS 原生聚焦用例通过；新增 windows-2022 workflow + smoke:guide:focused 入口，run 35576532201 在真实 Windows 上跑通精确断言并生成 228 KB 产物（截图 + result.json）。提交：a485b5c（修复）、d40e19a（workflow）、271d473（产物上传修复），均已 push 到 master。遗留：截图需登录 GitHub 下载后目视确认；工作区仍有另一会话在途改动。
