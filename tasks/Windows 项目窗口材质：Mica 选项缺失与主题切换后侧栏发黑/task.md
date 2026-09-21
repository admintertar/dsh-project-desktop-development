---
schemaVersion: 3
directory: Windows 项目窗口材质：Mica 选项缺失与主题切换后侧栏发黑
id: task-40452064-f1b4-4a74-ac60-00798fecc6b9
title: Windows 项目窗口材质：Mica 选项缺失与主题切换后侧栏发黑
objective: 修复 Windows 项目窗口「窗口材质」缺少 Mica 选项、以及切换到浅色主题后左侧导航栏残留深色（发黑）两个缺陷，两者都位于壳对官方对象的自有替换边界上并且都静默失效；给出根因证据、按官方做法修复、补回归测试与文档判例，并记录排查过程中的弯路。
status: completed
createdAt: 2026-09-21T14:00:50.205Z
updatedAt: 2026-09-21T14:24:20.210Z
artifacts:
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop
    commit: b2e5e50097267c3b0f856b584193c740299b8406
    description: 项目 runtime 补上 windowsBuild：恢复 Mica 选项与材质
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop
    commit: 38a4a839fa0c7f6d8d9b714ed94d10c89df1d8d4
    description: 主题切换后重涂窗口材质，修浅色主题下左栏发黑
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop
    commit: 30c3ed6275d497e6ffc2dd92c566c70a869da96d
    description: docs/validation.md：Windows 材质验收与失败路径记录
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop
    commit: 83165242e21d9c290eb7eedb85b6732bdb313bdc
    description: AGENTS.md：原生表面排查先证明前台窗口、再谈像素
archived: false
phase: validation
brief:
  currentBehavior: 修复前：Windows 项目窗口设置页「窗口材质」下拉只有「纯色背景」，没有 Mica；手工把 windowsMaterial 写成 mica 也不生效（材质被回落为 off）。切到浅色主题后左侧导航栏保持深色（DWM 旧调色板），右侧内容区正常变浅。
  scope: resources/dsh-project-desktop：src/desktop-adapter/native.mjs（补 windowsBuild、恢复官方材质重涂步骤）、新增 src/windows/window-material-refresh.mjs、新增 tests/windows-build-capability.test.mjs 与 tests/window-material-refresh.test.mjs、AGENTS.md（替换官方实现先复制再裁剪规则）、docs/architecture.md（字段契约与副作用两个判例）、docs/validation.md（Windows 材质验收与踩坑记录）。
  constraints:
    - 官方源码快照只读，不修改 .upstream 下任何文件
    - 官方已有实现优先复用：材质门槛走官方 window-material 探针，材质重涂走官方 electronPlatformStrategy().refreshThemeMaterial，不自己写 setBackgroundMaterial 分支
    - 保留壳的职责分工：SharedTheme 继续独占 nativeTheme.themeSource，壳的 setThemeSource 只重涂材质、不设主题
    - 不新增 CSS 覆盖来掩盖问题；侧栏透明是官方设计，不在壳里改成实色
    - 官方内部导入必须留在 src/desktop-adapter/ 边界内
  outOfScope:
    - macOS 侧栏 vibrancy 的同等验收（未在 macOS 上复跑）
    - 重新打包安装版应用以携带修复（当前安装版仍是旧 shell）
    - 把材质相关的官方图形行为纳入 CI 验收
  acceptanceCriteria:
    - id: ac-1
      text: "Windows 11 build ≥ 22621 上设置页「窗口材质」出现 Mica 选项，选择后写入项目 Home 的 windowsMaterial: mica"
      required: true
      version: 1
    - id: ac-2
      text: 材质生效时窗口合成 Mica；深色→浅色→深色来回切换后左侧栏跟随主题，不再残留深色调色板
      required: true
      version: 1
    - id: ac-3
      text: yarn check 全绿（verify:upstream、build、全部 tests、recovery、safe-mode、check-project-files、smoke:host）
      required: true
      version: 1
    - id: ac-4
      text: 回归测试覆盖两个缺陷：快照契约与静默降级、材质重涂的三种缺失场景与钩子守卫（防止被改回空实现）
      required: true
      version: 1
    - id: ac-5
      text: AGENTS.md 与 docs/architecture.md 记录规则与两个判例，docs/validation.md 记录 Windows 验收与踩坑
      required: true
      version: 1
references:
  - id: ref-native
    label: 壳的 native runtime 与窗口实现
    type: file
    path: resources/dsh-project-desktop/src/desktop-adapter/native.mjs
  - id: ref-refresher
    label: 材质重涂决策模块
    type: file
    path: resources/dsh-project-desktop/src/windows/window-material-refresh.mjs
  - id: ref-test-capability
    label: 快照契约与静默降级测试
    type: file
    path: resources/dsh-project-desktop/tests/windows-build-capability.test.mjs
  - id: ref-test-refresh
    label: 材质重涂测试
    type: file
    path: resources/dsh-project-desktop/tests/window-material-refresh.test.mjs
  - id: ref-agents
    label: 替换官方实现先复制再裁剪规则
    type: file
    path: resources/dsh-project-desktop/AGENTS.md
  - id: ref-arch
    label: 架构文档中的字段契约与副作用判例
    type: file
    path: resources/dsh-project-desktop/docs/architecture.md
  - id: ref-validation
    label: Windows 材质验收与踩坑记录
    type: file
    path: resources/dsh-project-desktop/docs/validation.md
  - id: ref-official-runtime
    label: 官方 ElectronDesktopRuntime.setThemeSource（材质重涂依据）
    type: file
    path: resources/dsh-desktop-source/dsh-plugin-desktop/src/electron-runtime.ts
  - id: ref-official-options
    label: 官方 window-options 的 Windows mica 分支
    type: file
    path: resources/dsh-desktop-source/dsh-plugin-desktop/src/window-options.ts
  - id: ref-official-styles
    label: 官方 styles.ts（材质生效时侧栏透明）
    type: file
    path: resources/dsh-desktop-source/dsh-plugin-desktop/src/client/styles.ts
entries:
  - id: inv-1
    kind: progress
    content: 现象与第一轮定位：用户截图显示桌面设置「窗口材质」下拉只有「纯色背景」。追链路确认该设置页是壳自己的 src/desktop-adapter/stable/settings-client.tsx:77-80，选项由 environment.micaSupported 决定；micaSupported 来自官方 parseDesktopClientEnvironment 读 URL 上的 dsh-desktop-mica 标记；该标记由 shell-host.mjs:47 调官方 desktopRendererUrl(..., runtime.windowsBuild) 写出（index.ts:203-205），而 runtime 是壳在 native.mjs 里自建的普通对象。
    basis: observation
    referenceIds:
      - ref-native
      - ref-official-options
    createdAt: 2026-09-21T14:00:50.205Z
  - id: inv-2
    kind: decision
    content: 根因一确认：壳的 native runtime 对象没有任何 windowsBuild 字段（本地与已安装副本全文 0 次出现），而官方 ElectronDesktopRuntime 在构造函数里自行解析它（electron-runtime.ts:129）；官方 runtimeSnapshot 取 runtime.windowsBuild，因而送出 undefined，windowsSupportsMica(undefined) 为假，写出 dsh-desktop-mica=0。第二个后果由 shell-host.mjs:46 的 effectiveDesktopWindowMaterial 承担：已持久化的 mica 被当作系统不支持，回落为 off，即选项不显示、写了也不生效。对照：入口窗口走 guide-window-options.mjs:8-11 自行传入 windowsBuildNumber()，所以只有项目窗口受影响。
    basis: observation
    referenceIds:
      - ref-native
      - ref-official-runtime
    createdAt: 2026-09-21T14:00:50.205Z
  - id: impl-1
    kind: progress
    content: 修复一：在 native.mjs 里从官方 window-material 读 windowsBuildNumber 并放进自有 runtime（与官方构造写法一致）。改动在 git worktree（分支 fix/mica-windows-build）中完成并验证，随后合并回主工作树。
    basis: agent-proposal
    referenceIds:
      - ref-native
    createdAt: 2026-09-21T14:00:50.205Z
  - id: inv-3
    kind: progress
    content: "用户复验：Mica 选项出现且写入项目 Home（windowsMaterial: mica），但反馈浅色主题下左侧栏发黑。第二轮排查：CDP 读到侧栏 .dshDesktopSidebarSurface 计算背景为 rgba(0,0,0,0) 全透明、对话区为 rgb(255,255,255)，与官方 styles.ts:16-17 一致（材质生效时侧栏透明、material=off 时才回落成 --dsw-alias-bg-layer-1）。强制把 data-dsh-desktop-material 改成 off，侧栏立刻回落实色、黑块消失，证明黑来自窗口那层合成而非 DOM。"
    basis: observation
    referenceIds:
      - ref-official-styles
    createdAt: 2026-09-21T14:00:50.205Z
  - id: inv-4
    kind: decision
    content: "根因二确认：采样时间线显示用户在 37s 切主题后侧栏在 41.7-44.3s 稳定在 #737373，同时内容区为 #FFFFFF——即页面配色已跟随主题、窗口材质仍停在旧调色板。对应官方 electron-runtime.ts:477-486：setThemeSource 除了设 nativeTheme.themeSource，还要 generation.refreshThemeMaterial()，注释明确 Windows 会保留上一次 DWM Mica 调色板直到窗口重组。壳里 native.mjs 的 setThemeSource 曾是空实现（注释称 SharedTheme 是唯一原生外观所有者），所以实时换主题从不重涂材质。"
    basis: observation
    referenceIds:
      - ref-native
      - ref-official-runtime
    createdAt: 2026-09-21T14:00:50.205Z
  - id: impl-2
    kind: progress
    content: 修复二：按官方做法恢复那一步——setThemeSource() {refreshWindowMaterial()}，仍不设 nativeTheme（SharedTheme 继续独占），重涂走官方 electronPlatformStrategy().refreshThemeMaterial(window, spec.material)，并在首次上屏 window.once('show') 时也重涂一次（Windows 缓存的正是首次合成那次调色板）。决策逻辑抽到 src/windows/window-material-refresh.mjs 以便单测。
    basis: agent-proposal
    referenceIds:
      - ref-native
      - ref-refresher
    createdAt: 2026-09-21T14:00:50.205Z
  - id: ver-1
    kind: verification
    content: "Windows 11 Pro 25H2 build 26200.9457 真机验收：材质行出现 Mica 并持久化为 windowsMaterial: mica；窗口合成 Mica；深色→浅色→深色来回切换后侧栏跟随主题、不再残留深色。用户复验确认修复。渲染端 URL 经 CDP 读到 dsh-desktop-material=mica。"
    basis: observation
    verification:
      criterionId: ac-1
      criterionVersion: 1
      method: Windows 原生界面操作 + CDP 读取窗口 URL 与 DOM 计算样式 + 逐窗口置前截屏取样
      result: passed
      coverage: 覆盖选项存在、持久化、材质生效、主题来回切换；未覆盖重新打包后的安装版（安装版仍是旧 shell）
    createdAt: 2026-09-21T14:00:50.205Z
  - id: ver-2
    kind: verification
    content: yarn check（Windows，DSH_PROJECT_PLUGIN_SOURCE 指向本地插件工作区）EXIT=0：verify:upstream 通过（Desktop 2.0.11 / DSH 0.1.5-rc.2）、build 通过、tests 86 pass 86 fail 0、recovery 7/7、safe-mode 1/1、check-project-files 通过、smoke:host 通过。另在合并前的新 pin（插件 634e921）上单独复跑过一次全绿。
    basis: observation
    verification:
      criterionId: ac-3
      criterionVersion: 1
      method: yarn check
      result: passed
      coverage: 覆盖完整 headless 门禁；图形部分仍以真机验收为准（smoke:host 自报不覆盖材质）
    createdAt: 2026-09-21T14:00:50.205Z
  - id: ver-3
    kind: verification
    content: 回归测试：tests/windows-build-capability.test.mjs 4 用例（快照契约、URL 标记、静默降级、字段来源守卫）与 tests/window-material-refresh.test.mjs 4 用例（正常重涂、三种缺失场景静默、材质值透传、钩子守卫）。做过反向验证：临时删掉 windowsBuild 那一行后第 4 个用例变红，确认守卫有效。
    basis: observation
    verification:
      criterionId: ac-4
      criterionVersion: 1
      method: node --test + 变异验证（移除修复后确认测试变红）
      result: passed
      coverage: 覆盖壳侧两半链路与钩子接线；渲染端 micaSupported 由官方 pinned client-environment.spec.ts 覆盖，未重复实现
    createdAt: 2026-09-21T14:00:50.205Z
  - id: ver-4
    kind: verification
    content: 文档：AGENTS.md 增中英文各一条「替换或重写官方实现时先照搬完整行为与副作用再叠加裁剪」规则；docs/architecture.md 记录字段契约与材质重涂两个判例；docs/validation.md 新增 Windows Mica 材质验收小节与「Failed approaches」小节。
    basis: observation
    verification:
      criterionId: ac-5
      criterionVersion: 1
      method: 文件审阅
      result: passed
      coverage: 覆盖规则、判例、验收记录与踩坑清单
    createdAt: 2026-09-21T14:00:50.205Z
  - id: pit-1
    kind: progress
    content: 踩坑 1（代价最大）：屏幕上有多个窗口叠放（用户已安装 app、安装版项目窗口、开发壳的窗口），按屏幕固定坐标取样实际测到的是最上层窗口，导致同一坐标先后得出「侧栏是白的」与「侧栏是黑的」两个矛盾结论，我据此一度以为问题不可复现、甚至怀疑用户截图。纠正方式：先用 Get-Process MainWindowTitle/MainWindowHandle 或 CDP 的 windowId 确认目标窗口，再 AppActivate 按 PID 置前后取样；能读 DOM 就不要靠像素推断。结论：没有证明过前台窗口的屏幕取样不算证据。
    basis: observation
    createdAt: 2026-09-21T14:00:50.205Z
  - id: pit-2
    kind: progress
    content: "踩坑 2：把用户发来的截图当像素源。会话里的预览是降采样（2529x1658 → 987x647）且文字抗锯齿会扩散，密集区域（项目会话列表）平均下来会呈现出像背景色的大块色值，我据此误判「侧栏是 #737373」。要么取真实屏幕截图，要么读实时 DOM。"
    basis: observation
    createdAt: 2026-09-21T14:00:50.205Z
  - id: pit-3
    kind: progress
    content: 踩坑 3：git worktree 里跑 check 的两个环境陷阱。(a) 为补齐依赖做的 junction 里 .runtime 不能是 junction——check 会断言 .runtime 下的临时路径，junction 让它指回主检出导致路径断言失败（其余 node_modules/.upstream/.yarn 用 junction 无妨）。(b) 需要把 git 与 openssl 放进 PATH：tests/fixtures/private-git.mjs 自行签发 CA，缺 openssl 时三个 guide-clone 用例会以环境原因失败，看起来像代码回归。
    basis: observation
    createdAt: 2026-09-21T14:00:50.205Z
  - id: pit-4
    kind: progress
    content: 踩坑 4：想通过 CDP 调整窗口尺寸来验证合成，结果 Electron 未实现 Browser.getWindowForTarget/Browser.setWindowBounds（-32601），该路不通；要改窗口几何应从应用代码或开发壳调用 BrowserWindow。
    basis: observation
    createdAt: 2026-09-21T14:00:50.205Z
  - id: pit-5
    kind: progress
    content: 踩坑 5：用 PowerShell 回写源码文件时加了 BOM 并把 native.mjs 里的中文诊断文案写成乱码（改完 git diff 才暴露）。已 git checkout 恢复后用文件工具重新打补丁，并核对首字节与 diff。源码改动一律用文件工具，改完必须看 git diff。
    basis: observation
    createdAt: 2026-09-21T14:00:50.205Z
  - id: pit-6
    kind: progress
    content: 踩坑 6（工作树并发）：在 worktree 里工作期间，主工作树被另一会话推进了三个提交（含把插件 pin bump 到 634e921）。没有直接合并，而是把新 master 合进分支、在新 pin 上重新验证，再快进 master，避免把「壳 + 新插件」组合的首次验证留给 CI。
    basis: observation
    createdAt: 2026-09-21T14:00:50.205Z
  - id: limit-1
    kind: progress
    content: 限制与遗留：当前已安装的 DSH Project Desktop 仍是旧 shell（resources/app 下的 native.mjs 无这两处修复），要带修复必须重新打包安装；macOS 侧的透明材质（vibrancy）未做同等验收；smoke:host 自报不覆盖材质图形表现，材质验收目前只能是真机人工检查。
    basis: observation
    createdAt: 2026-09-21T14:00:50.205Z
  - id: ver-5
    kind: verification
    content: "主题切换验收：修复后（38a4a83）在 Windows 真机上从浅色切到深色再切回浅色，左侧栏随主题跟随、不再残留旧的深色调色板，用户确认「修复了」。修复前的对照证据是采样时间线：切主题后侧栏停在 #737373、内容区已变 #FFFFFF。"
    basis: observation
    referenceIds:
      - ref-native
      - ref-refresher
    verification:
      criterionId: ac-2
      criterionVersion: 1
      method: Windows 真机界面操作 + 逐窗口置前截屏取样 + 用户复验
      result: passed
      coverage: 覆盖深浅主题来回切换与侧栏跟随；未覆盖 macOS 的 transparent/vibrancy 路径，也未覆盖重新打包后的安装版
    createdAt: 2026-09-21T14:01:13.105Z
  - id: impl-3
    kind: progress
    content: 交付位置：三项均已提交到 dsh-project-desktop master（b2e5e50 代码+测试、38a4a83 材质重涂修复+测试+架构判例、30c3ed6 验证文档），工作树干净，无未提交改动。
    basis: agent-proposal
    createdAt: 2026-09-21T14:01:13.105Z
  - id: done-1
    kind: completion
    content: 任务完成：两个 Windows 项目窗口材质缺陷均已修复、验证并沉淀。①Mica 选项缺失：自有 runtime 漏官方 windowsBuild，已改为从官方 window-material 探针取值（b2e5e50）；②浅色主题下侧栏发黑：自有 setThemeSource 缺少官方换主题时的材质重涂，已按官方 electronStrategy.refreshThemeMaterial 恢复并在首次上屏也重涂（38a4a83）。验收：Windows 11 build 26200 真机通过（选项出现并持久化、材质合成、深浅来回切换侧栏跟随主题），yarn check EXIT=0（86 tests + recovery 7 + safe-mode 1 + smoke:host）。沉淀：AGENTS.md 两条规则（替换官方实现先复制行为与副作用；原生表面排查先证明前台窗口）、docs/architecture.md 两个判例、docs/validation.md 验收小节 + Failed approaches、任务内 6 条踩坑记录。
    basis: agent-proposal
    verificationEntryIds:
      - ver-1
      - ver-5
      - ver-2
      - ver-3
      - ver-4
    createdAt: 2026-09-21T14:24:03.035Z
operations:
  6aaf86399897703493a6db004f0b7b681e632c2b1114b0daecae779d1953a4b8:
    fingerprint: 004a535c32131806788ca72a8ed9950a2d98f301633e23baf4585d959a6cc316
    kind: create
    at: 2026-09-21T14:00:50.205Z
    entryIds:
      - inv-1
      - inv-2
      - impl-1
      - inv-3
      - inv-4
      - impl-2
      - ver-1
      - ver-2
      - ver-3
      - ver-4
      - pit-1
      - pit-2
      - pit-3
      - pit-4
      - pit-5
      - pit-6
      - limit-1
  2977a82be1fb44597b79706542c9effbe27ba9c3824e1931846815db84fadda0:
    fingerprint: e303a5cbc2561638f4b0c05bb56d687b72b1f549615e378493e8e3b656f77e39
    kind: update
    at: 2026-09-21T14:01:13.105Z
    entryIds:
      - ver-5
      - impl-3
  1a0d68d11c41105fc277523747c429c9f9d393ba99e75f184fe3f4eea11c550a:
    fingerprint: 3012e52dae5e0eb315840d4b0499d7295c96380e34e86d9fa07f4af27549acc2
    kind: update
    at: 2026-09-21T14:24:03.035Z
    entryIds:
      - done-1
  a33c6782280504f4175af3fe2e614a06082e41d1ff1a566b6cc9d2ac024adf53:
    fingerprint: e604833f50c3f15b5f7b1e2c3b3b9c4c806275491a9646afbd5d2da40186d7ed
    kind: update
    at: 2026-09-21T14:24:08.868Z
    entryIds: []
  d26498ae4e1fd02c8be5490a4dc065f7ae8d254c72663a7e6ad19a11ec01ddc9:
    fingerprint: 94db353a0cf0df8488ed63160a756eb36fb5f8fac2aa4121614dadd36be31ae6
    kind: update
    at: 2026-09-21T14:24:11.701Z
    entryIds: []
  d8a9adfc68c692f336180fb2bb5df5b031cc6775d058ae60770c8078f8952abf:
    fingerprint: b0c3efff2659d76df65bd8afabaf1e7bf496998bc8b9143d50ec1222dc25bc4b
    kind: update
    at: 2026-09-21T14:24:20.210Z
    entryIds: []
criterionVersions:
  ac-1: 1
  ac-2: 1
  ac-3: 1
  ac-4: 1
  ac-5: 1
---

两个缺陷均已修复并落到 dsh-project-desktop master（b2e5e50 字段契约、38a4a83 材质重涂），Windows 11 build 26200 真机验收通过：材质行出现 Mica 且写入项目 Home（windowsMaterial: mica），深色→浅色→深色来回切换侧栏跟随主题、不再残留深色。yarn check 全绿（86 tests / recovery 7 / safe-mode 1 / smoke:host，EXIT=0）。两处根因都在「壳用自有对象替换官方实现」这条边界上且都静默失效：①自有 runtime 漏了官方的 windowsBuild，导致 runtimeSnapshot 送出 undefined、dsh-desktop-mica=0、micaSupported 为假，设置页只列「纯色背景」，且已持久化的 mica 被 effectiveDesktopWindowMaterial 按系统不支持回落为 off；②自有 setThemeSource 是空实现，缺少官方在换主题时经平台策略重涂窗口材质这一步，Windows 会保留上一次 DWM Mica 调色板直到窗口重组，于是浅色主题下透明侧栏停在旧调色板而右区跟着变浅。调研过程有明显弯路：两个窗口叠放导致按屏幕坐标取样实为测到最上层窗口，同一坐标先后得出「侧栏是白的」和「侧栏是黑的」两个矛盾结论。
