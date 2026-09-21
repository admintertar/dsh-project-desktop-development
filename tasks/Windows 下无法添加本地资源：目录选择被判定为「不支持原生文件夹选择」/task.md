---
schemaVersion: 3
directory: Windows 下无法添加本地资源：目录选择被判定为「不支持原生文件夹选择」
id: task-80df9054-47a3-4916-af95-0c9af2a953d1
title: Windows 下无法添加本地资源：目录选择被判定为「不支持原生文件夹选择」
objective: 让 Windows 桌面版能正常添加本地资源（addLocal）、绑定目录与导入技能：查明 Project 插件 canPick 只认 directoryPicker kind === 'native' 与桌面在 win32 固定 browse 组合的冲突，调研 dsh-desktop 的目录选择实现（browse 面板 + 系统文件夹图标 + Electron dialog.showOpenDialog + 路径校验路由），确定接入点与安全边界并给出实现方案。
status: completed
createdAt: 2026-09-21T07:00:15.426Z
updatedAt: 2026-09-21T11:34:05.975Z
artifacts:
  - type: commit
    repository: https://github.com/admintertar/dsh-plugin-project.git
    commit: 800cc4d30830375f158b3b0a89f4d90cac58f99d
    description: 插件侧实现：pickSource 判定、POST /api/project/pick、资源与技能闸门、客户端取路径分流；仅含本次改动（同文件里其他会话的未提交改动未被纳入）
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: 8716092ec5e0baeb5381c70cd278dc125d838cba
    description: 壳：bump project pin 到 800cc4d、资源面板 Windows 用例、resources-windows.yml
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: 412304d9dcd22d8733154f998011135df457e4ab
    description: 壳：修复资源冒烟在干净 checkout 下 .runtime 不存在导致的 mkdtemp ENOENT，并让失败也写入 result.json
  - type: url
    url: https://github.com/admintertar/dsh-project-desktop/actions/runs/35586284794
    description: Windows 资源面板原生验收（windows-2022，success，artifact resources-windows-412304d…）
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: d3126c906110371bbce4bda8741f3d556eff2e7b
    description: 壳：资源冒烟补绑定目录与技能导入两段 Windows 用例
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: 9a630fee4a3767dc61952c8ed7cd89bd3de07cc5
    description: 壳：技能用例前恢复宽窗口（窄窗口下侧边栏导航不在 DOM）
  - type: url
    url: https://github.com/admintertar/dsh-project-desktop/actions/runs/35591898652
    description: ac-1 + ac-2 的 Windows 原生验收（windows-2022，success，artifact 含 resource-add-local*.png 与 resource-bind-and-skill.png）
archived: false
phase: validation
brief:
  currentBehavior: Windows 桌面版可通过应用内选择添加本地资源、绑定已有资源目录与导入技能：面板不再显示「当前环境不支持原生文件夹选择。」，取路径由 Host 调用 desktopRuntime.pickDirectory() 打开系统文件夹对话框。macOS/Linux 仍走官方 native seam，行为与文案不变。
  scope: 定位并修复 Windows 桌面版无法添加本地资源的问题；范围含 Project 插件 canPick 判定、资源面板/SkillsPanel 交互、以及桌面 browse 选择器返回路径的接入方式。
  outOfScope:
    - 改动官方源码快照
    - 发布仓库或 bump upstream.lock.json 的 pin
    - 重写运行中的 Profile
  acceptanceCriteria:
    - id: ac-1
      text: Windows 桌面版可通过应用内目录选择完成「添加本地资源」并成功写入项目资源
      required: true
      version: 1
    - id: ac-2
      text: 绑定已有资源目录与技能导入在 Windows 上同样可用
      required: true
      version: 1
    - id: ac-3
      text: 路径可信性有兜底校验，不放宽到任意手输路径
      required: true
      version: 1
    - id: ac-4
      text: macOS/Linux 现有 native 流程与文案不回退
      required: true
      version: 1
references:
  - id: ref-locale
    label: nativePickerUnavailable 中英文案
    type: file
    path: resources/dsh-plugin-project/src/capability-locales.ts
  - id: ref-resource-api
    label: canPick / requirePicker 服务端闸门
    type: file
    path: resources/dsh-plugin-project/src/resource-api.ts
  - id: ref-resource-panel
    label: 资源面板提示与按钮禁用
    type: file
    path: resources/dsh-plugin-project/src/client/ResourcesPanel.tsx
  - id: ref-project-api
    label: 技能导入的 canImport 闸门
    type: file
    path: resources/dsh-plugin-project/src/project-api.ts
  - id: ref-profile
    label: 桌面 win32 固定 browse 组合
    type: file
    path: resources/dsh-desktop-source/dsh-plugin-desktop/src/profile.ts
  - id: ref-note
    label: 桌面兼容模式说明：Windows 不加载 koffi worker
    type: file
    path: resources/dsh-desktop-source/.agents/notes/implemented/architecture/2026-08-15-desktop-compatibility-mode.md
  - id: ref-lock
    label: 壳 pin 的桌面提交 01fa59e
    type: file
    path: resources/dsh-project-desktop/upstream.lock.json
  - id: ref-guide-window
    label: 壳向导：创建项目/添加资源的原生选目录 IPC
    type: file
    path: resources/dsh-project-desktop/src/windows/guide-window.mjs
  - id: ref-shell-native
    label: 壳主进程原生选择器与校验实现
    type: file
    path: resources/dsh-project-desktop/src/desktop-adapter/native.mjs
  - id: ref-host-bridge
    label: Host 进程 desktopRuntime 桥（含 native:pickDirectory）
    type: file
    path: resources/dsh-desktop-source/dsh-plugin-desktop/src/host-runtime-bridge.ts
  - id: ref-browse-patch
    label: browse 面板补丁：使用 Windows 选择文件夹 + 校验
    type: file
    path: resources/dsh-desktop-source/patches/dsh-client-ui-directory-picker-browse@0.1.5-rc.2.patch
  - id: ref-picker-route
    label: 桌面同源选择/校验路由
    type: file
    path: resources/dsh-desktop-source/dsh-plugin-desktop/src/directory-picker-route.ts
  - id: ref-admission
    label: 桌面工作区准入策略（Windows 卷校验）
    type: file
    path: resources/dsh-desktop-source/dsh-plugin-desktop/src/workspace-admission.ts
  - id: ref-window-actions
    label: 插件已在用 desktopRuntime 探测（先例）
    type: file
    path: resources/dsh-plugin-project/src/window-actions.ts
  - id: ref-shell-profile
    label: 壳 profile：禁用 desktop-shell 并替换为 project-desktop-shell
    type: file
    path: resources/dsh-project-desktop/src/desktop-adapter/stable/profile.mjs
entries:
  - id: e1
    kind: progress
    content: "证据链已确认：① 提示文案是 capability-locales.ts 的 nativePickerUnavailable，仅在 ResourcesPanel 的 !canPick 时渲染；② canPick 由 resource-api.ts 判定 directoryPicker.capability().kind === 'native'，addLocal/bind/inspect 均 requirePicker()，否则 409；③ 桌面 profile.ts 在 platform === 'win32' 时禁用 auto picker row 并插入 browse 后端与 browse 前端，browse 包注册 kind: 'browse'；④ 壳 upstream.lock.json 的 desktop.commit = 01fa59e6688d82fa34b59fc507e3a6f5d695fa17 正是含该 win32 分支的提交。因此 Windows 上插件判定「没有原生选择器」并禁用整条本地资源流程。"
    basis: observation
    referenceIds:
      - ref-locale
      - ref-resource-api
      - ref-resource-panel
      - ref-profile
      - ref-lock
    createdAt: 2026-09-21T07:00:15.426Z
  - id: e2
    kind: progress
    content: 影响面：资源面板「添加本地资源」「绑定目录」、/inspect、技能导入（project-api.ts canImport）全部被挡；Git 资源按 URL 克隆/关联不受影响（canClone 只看 git 是否可用）。桌面在 Windows 上实际提供了可用选择路径（browse 面板 + 系统文件夹图标 → Electron dialog.showOpenDialog + 同源校验路由），与插件闸门不匹配。
    basis: observation
    referenceIds:
      - ref-project-api
      - ref-resource-api
    createdAt: 2026-09-21T07:00:15.426Z
  - id: e3
    kind: progress
    content: "调研 dsh-desktop 实现：① win32 不挂载 koffi 驱动的上游 native 后端，改用 browse 后端（kind: 'browse'）+ browse 前端；② 桌面用 yarn patch 给 browse 面板注入一个「使用 Windows 选择文件夹」图标按钮，以及 openDirectory 前的 validateDirectory 钩子，二者仅在 URL 带 dsh-desktop-platform=win32 时注入；③ 图标按钮调用 window.__DSH_DESKTOP_PICK_DIRECTORY__（由桌面 client 模块安装），经同源 POST 路由到 Electron dialog.showOpenDialog；④ 选中路径先过 validateDirectory（ElectronWorkspaceAdmission：Windows 可移除卷/不支持文件系统策略，返回 allowed 才 onOpen）。因此 Windows 上 browse 面板本身是一条可用的、带策略校验的选择路径。"
    basis: observation
    referenceIds:
      - ref-browse-patch
      - ref-picker-route
      - ref-admission
      - ref-profile
    createdAt: 2026-09-21T07:05:14.109Z
  - id: e4
    kind: progress
    content: 回答「为何创建项目能选、添加资源不能」：创建项目与向导内的添加资源走壳自己的 guide 窗口（guide-window.mjs 的 choose / browse-location / pick-resource IPC），直接在 Electron 主进程 dialog.showOpenDialog({properties:['openDirectory']})，不经过 DSH directoryPicker seam，也不经过插件 canPick；项目创建完成后资源面板的添加资源是 DSH web 客户端插件流程，受 canPick 闸门限制。同一功能存在两套实现，Windows 上只有壳那一套可用。
    basis: observation
    referenceIds:
      - ref-guide-window
      - ref-shell-native
      - ref-resource-panel
    createdAt: 2026-09-21T07:05:14.109Z
  - id: e5
    kind: progress
    content: 关键接入点：桌面已把同一个原生选择器桥接给 DSH Host 进程——desktopRuntime.pickDirectory()（host-runtime-bridge.ts:99 → native:pickDirectory RPC → 壳 native.mjs:91 dialog.showOpenDialog）与 desktopRuntime.validateDirectory(path) 对插件所在 Host 上下文可见；插件已有 ctx.get('desktopRuntime') 探测先例（window-actions.ts 的 workspaceWindows）。因此插件可在 win32 上改用桌面运行时提供的原生选择器，而不依赖 seam 的 kind。
    basis: observation
    referenceIds:
      - ref-host-bridge
      - ref-shell-native
      - ref-window-actions
    createdAt: 2026-09-21T07:05:14.109Z
  - id: e6
    kind: decision
    content: 修复方向（待用户确认，尚未实现）：方案 A（推荐，插件侧）把 canPick/canImport 的判据从「seam kind === 'native'」扩展为「native，或桌面运行时提供 pickDirectory」，并在 browse 场景下由 Host 侧调用 desktopRuntime.pickDirectory() 取路径，保持「路径必须来自主机显示器上的 OS 对话框」这一原有环境语义，避免对普通远程 browse 部署放开任意路径。方案 B（桌面侧）在 win32 用桌面自有的 native 后端（Electron dialog 而非 koffi）替换 browse 对，插件零改动，但改动落在被 pin 的桌面插件上，需跨仓库与重新 pin。方案 C 无条件接受 browse，会弱化现有安全姿态，不建议。
    basis: agent-proposal
    referenceIds:
      - ref-resource-api
      - ref-project-api
      - ref-host-bridge
    createdAt: 2026-09-21T07:05:14.109Z
  - id: e7
    kind: progress
    content: "补充关键发现（影响方案选择）：项目壳在 profile 里禁用 desktop-shell 行（name: dsh-plugin-desktop，其客户端 client/index.ts:102-107 才安装 __DSH_DESKTOP_PICK_DIRECTORY__ / __DSH_DESKTOP_VALIDATE_DIRECTORY__），替换为 project-desktop-shell。实测 .cache/runtime/dsh-project-shell/client.js 对 PICK_DIRECTORY 的引用数为 0，而 .cache/runtime/dsh-plugin-desktop/lib/client.js 为 5。而项目窗口 URL 由 desktopRendererUrl 生成、win32 必带 dsh-desktop-platform=win32，所以 browse 面板补丁会注入 pickNativeDirectory / validateDirectory，但两个 window 桥都不存在——点击「使用 Windows 选择文件夹」或「打开」都会抛 DSH Desktop ... unavailable。结论：Windows 上不能依赖 uiWorkspace.pickDirectory() 的 browse 面板取路径；唯一可靠通道是 Host 侧 desktopRuntime.pickDirectory()（host-runtime-bridge.ts:99 → native:pickDirectory → 壳 native.mjs:91 dialog.showOpenDialog，与创建项目同一对话框）。该结论需在 Windows 上实测确认。"
    basis: observation
    referenceIds:
      - ref-host-bridge
      - ref-shell-native
      - ref-browse-patch
      - ref-shell-profile
    createdAt: 2026-09-21T07:13:11.484Z
  - id: e8
    kind: decision
    content: 基于 e7 收敛方案：推荐在插件侧实现服务端驱动的选目录——新增受同一鉴权/同源约束的取路径入口（Host 调用 desktopRuntime.pickDirectory()）或在 inspect 动作内完成 pick+inspect，canPick/canImport 判据改为 native 或 desktopRuntime.pickDirectory 存在。这样路径确实来自主机显示器上的 OS 对话框，原有安全语义不变，也不依赖已损坏的 browse 面板桥；macOS/Linux 的 native 流程保持原样。
    basis: agent-proposal
    referenceIds:
      - ref-resource-api
      - ref-project-api
      - ref-host-bridge
      - ref-shell-native
    supersedes: e6
    createdAt: 2026-09-21T07:13:11.484Z
  - id: e9
    kind: progress
    content: 实现完成（插件侧，方案 A，用户选定「与 native 同等姿态」不加白名单）：① 新增 src/directory-pick.ts：pickSource(ctx) 返回 'native' | 'desktop' | null（seam kind === 'native' 优先，否则看 desktopRuntime.pickDirectory），pickDesktopDirectory(ctx) 负责调起；② project-api.ts 新增 POST /api/project/pick（仅 desktop 源，同一鉴权+同源 JSON），canImport 改判 pickSource，skills 快照增加 pickSource；③ resource-api.ts 的 canPick 改判 pickSource，快照透传 pickSource；④ 快照类型 ResourcesSnapshot / SkillsSnapshot 增加 pickSource；⑤ 新增客户端 src/client/pick-directory.ts：native 走 ctx.uiWorkspace.pickDirectory()，desktop 走 /api/project/pick，其余保持原有拒绝；⑥ ResourcesPanel / SkillsPanel 按各自快照的 pickSource 调用。未改动 macOS/Linux 的 native 分支。
    basis: agent-proposal
    createdAt: 2026-09-21T08:00:37.963Z
  - id: e10
    kind: verification
    content: 验证（自动化）：npm run check 全绿——typecheck 通过、252/252 测试通过、build 成功。新增测试：tests/client-pick-directory.test.ts（native 委派、desktop 取路径/取消/错误白名单）；resource-api.test.ts 补 native/browse+desktopRuntime/browse+无 desktopRuntime 三态与 addLocal/inspect；project-api.test.ts 补技能 canImport/pickSource 三态、pick 路由鉴权与取消。测试曾拓出真实缺陷：客户端 helper 会回显 Host 任意错误文本，已改为白名单（secret-fixture → operation-failed）。另用 DSH_PROJECT_PLUGIN_SOURCE=../dsh-plugin-project 构建壳验证集成，构建通过（验证后已恢复 pin 构建）。
    basis: observation
    verification:
      criterionId: ac-3
      criterionVersion: 1
      method: npm run check（typecheck + 252 tests + build）+ 代码审查
      result: passed
      coverage: 取路径改为 Host 调用 desktopRuntime.pickDirectory()，客户端不再手输路径；新路由沿用 requireAuthenticatedRequest 的同源+JSON 约束；按用户决定与 native 保持同等姿态，未加短时白名单。
    createdAt: 2026-09-21T08:00:37.963Z
  - id: e11
    kind: verification
    content: 验证（回归）：pickSource 为 'native' 时仍走官方 ctx.uiWorkspace.pickDirectory()，面板文案与禁用逻辑（canPick/canImport）未变；新增单测覆盖 native 委派与 native 下 pick 路由 409。macOS/Linux 的原生视觉验收尚未执行（本机无法覆盖 Windows 路径）。
    basis: observation
    verification:
      criterionId: ac-4
      criterionVersion: 1
      method: 单元测试 + 壳集成构建（DSH_PROJECT_PLUGIN_SOURCE）
      result: passed
      coverage: 自动化部分已覆盖；原生视觉验收待补。
    createdAt: 2026-09-21T08:00:37.963Z
  - id: e12
    kind: progress
    content: 已提交到 resources/dsh-plugin-project 的 master：800cc4d30830375f158b3b0a89f4d90cac58f99d，15 个文件（+188/-24）。提交前逐文件核对，发现 src/client/ResourcesPanel.tsx 与 tests/client-resources.test.ts 里混有另一会话未提交的 detectedResourceType 改动（同批还有未提交的 src/client/resource-ui.ts、src/project-resources.ts、tests/project-resources.test.ts）；用 git hash-object + update-index --cacheinfo 只暂存了自己的 hunk，未纳入他人改动，这些文件在工作区仍保持未提交。未 push（需明确授权）。
    basis: observation
    createdAt: 2026-09-21T08:09:56.305Z
  - id: e13
    kind: verification
    content: 对提交本身（而非工作区）做独立验证：git worktree 检出 800cc4d + node_modules 软链，npm run typecheck 通过、npm test 250/250 通过（比工作区的 252 少 2 个，因为他人未提交的测试不在该提交内），证明提交内容自洽。
    basis: observation
    verification:
      criterionId: ac-3
      criterionVersion: 1
      method: git worktree 隔离检出 + npm run typecheck + npm test
      result: passed
      coverage: 针对提交 800cc4d 的隔离验证：typecheck 通过、250/250 测试通过；仍待 Windows 原生验收（ac-1/ac-2）与 macOS 视觉验收（ac-4）。
    createdAt: 2026-09-21T08:09:56.305Z
  - id: e14
    kind: progress
    content: Windows CI 原生验收通过：提交 412304d 上的 Verify Resources on Windows（run 35586284794）在 windows-2022 上 success，步骤 15 build、16「Verify the resource panel adds a local directory on Windows」、17 上传证据全部成功；artifact resources-windows-412304d9dcd22d8733154f998011135df457e4ab（~530 KB，含 resource-add-local.png 与 result.json）已生成。同一 push 的 Verify Guide on Windows 也 success。artifact 下载需登录（API 返回 401），证据需在 GitHub 页面查看。
    basis: observation
    createdAt: 2026-09-21T10:08:58.293Z
  - id: e15
    kind: verification
    content: 验收：ac-1 已在真实 Windows 上通过——面板不再显示「当前环境不支持原生文件夹选择。」、选择按钮可用、假对话框返回的目录回填到路径与名称、保存后 manifest 出现 name=picked-resource type=local 的资源。链路为 renderer → POST /api/project/pick → desktopRuntime.pickDirectory → native:pickDirectory RPC → 壳 native.mjs dialog.showOpenDialog（仅 OS 对话框被替身替换，Host/RPC/面板/Git 均为真实）。
    basis: observation
    verification:
      criterionId: ac-1
      criterionVersion: 1
      method: GitHub Actions windows-2022 上 npm run smoke:resources（run 35586284794）
      result: passed
      coverage: Windows 真实 Electron + 真实 Host/Renderer 的端到端用例，中英文案与保存写入均已断言。
      reason: 已通过并上传证据
    createdAt: 2026-09-21T10:08:58.293Z
  - id: e16
    kind: verification
    content: ac-2（绑定已有资源目录 + 技能导入）尚未在 Windows 实测：两者走同一个 pickSource 闸门与同一个取路径入口，单测已覆盖 native / browse+desktopRuntime / browse+无 desktopRuntime 三态与 native 下 409，但 Windows 上的真实点击未覆盖。补齐需在 native-resource-state-checks.mjs 加绑定目录与技能导入两段用例并再跑一轮 Windows CI。
    basis: observation
    verification:
      criterionId: ac-2
      criterionVersion: 1
      method: 待补：Windows smoke 用例
      result: not-run
      coverage: 仅单元测试覆盖闸门三态；Windows 原生点击未执行。
      reason: 用例尚未编写，需再跑一轮 Windows CI 才能给出原生证据
    createdAt: 2026-09-21T10:08:58.293Z
  - id: e17
    kind: verification
    content: ac-2 补齐并在 Windows 上实测通过：提交 9a630fe 的 Verify Resources on Windows（run 35591898652）success，result.json ok=true（8 组测量）。证据截图 resource-bind-and-skill.png 显示技能面板中 picked-skill 已导入并启用（描述 Windows picker fixture），资源计数为 1（绑定后的资源仍在）；绑定用例把 picked-resource 的路径改为 rebound-resource 也已断言通过。
    basis: observation
    verification:
      criterionId: ac-2
      criterionVersion: 1
      method: GitHub Actions windows-2022 上 yarn smoke:resources（run 35591898652）
      result: passed
      coverage: 绑定已有资源目录 + 技能导入均在 Windows 真实 Electron/Host/面板上点击完成，取路径走 /api/project/pick → desktopRuntime.pickDirectory。
      reason: 已通过并上传证据
    createdAt: 2026-09-21T11:12:17.831Z
  - id: e18
    kind: progress
    content: ac-2 用例经历两次 CI 失败并修复：① d3126c9（run 35590581875）失败——假对话框硬编码返回 picked-resource，绑定/技能用例拿不到各自目录；改为可变的 nextPick 后重跑。② f958666（run 35591305651）失败——绑定用例已通过（dump 里路径已变 rebound-resource），但技能用例在 420px 窄窗口下找不到侧边栏「技能」按钮（面板导航不在 DOM）；在切面板前恢复 1180px 后通过。失败诊断全靠上一轮加的「失败也写 result.json（含页面文本）」才快速定位。
    basis: observation
    createdAt: 2026-09-21T11:12:17.831Z
  - id: e19
    kind: completion
    content: 完成。交付：插件 800cc4d（pickSource 判定 + POST /api/project/pick + 资源/技能闸门 + 客户端取路径分流）；壳 8716092（pin bump、资源面板 Windows 用例、resources-windows.yml）、412304d（干净 checkout 下 .runtime 缺失导致 mkdtemp ENOENT，并让失败写入 result.json）、d3126c9/f958666/9a630fe（ac-2 的绑定与技能用例及两次修复）。验证：Windows CI run 35586284794（ac-1）与 35591898652（ac-2）均 success 并上传截图与 result.json；本机 yarn smoke:resources 多次 EXIT=0；插件单测 250/250（隔离提交）与 252/252（工作区）。限制：CI 中 OS 文件夹对话框为替身（无人点击，不可避免）；macOS/Linux 逐张截图的视觉核对未执行（用户决定跳过）；改动已在两仓库 origin/master 并被壳 pin 包含，无需额外 bump。
    basis: observation
    verificationEntryIds:
      - e15
      - e17
      - e10
      - e11
      - e13
    createdAt: 2026-09-21T11:34:05.975Z
operations:
  2c250f1f3ba165ae54f25b946e5c392ca46acc9eb9eb56ac78d4c762560746a9:
    fingerprint: 76ddda6fd1189ad04f3b3ad9980748b5ddde48cce67e1ba7609f7178903fb88a
    kind: create
    at: 2026-09-21T07:00:15.426Z
    entryIds:
      - e1
      - e2
  9a00ff9974fa174323ef9795f279ceda9a4466597f93f6d4b0484d8ce69dbe01:
    fingerprint: a627c1fd99a4e3bc41010fb739fb94703771ff334efe54da348890e2ce4a1507
    kind: update
    at: 2026-09-21T07:05:14.109Z
    entryIds:
      - e3
      - e4
      - e5
      - e6
  48de8b0a55186034bc903058c3e6b00c7d5f9dae4899daa5488435735e81747d:
    fingerprint: e2aa41788e24584185a89c785d9c5e4d01a4bbaa32b666362dea7e8125936556
    kind: update
    at: 2026-09-21T07:13:11.484Z
    entryIds:
      - e7
      - e8
  c043b5a2f8af8a9e6bfce16885b2dcece890ba7d747b705da9c35db46f5f11ca:
    fingerprint: f880f39a3f1a7705541aa85ee24c6ab54e79c4979e97be295d077d1d08ab4487
    kind: update
    at: 2026-09-21T08:00:37.963Z
    entryIds:
      - e9
      - e10
      - e11
  dc5d47782648d00ed75ab85c32f997c674db6d10e2b27f1716c3bc80a398b7a0:
    fingerprint: 7fc59eb0234d03dc3b6631ac6920c90ecbdffd5ede0b182a80b4c14568b32087
    kind: update
    at: 2026-09-21T08:09:56.305Z
    entryIds:
      - e12
      - e13
  1f6f60ee0f71d477d6392294db7ff1232aaf9e6891a83f166e14a938970e92e2:
    fingerprint: c7ed316fd01a70750a3ef4866ef84647ae7d9f7b4573b41b2ec0a22f153bbcbf
    kind: update
    at: 2026-09-21T10:08:58.293Z
    entryIds:
      - e14
      - e15
      - e16
  8c011ab0724930a126c8736e2a8dbdae6d4a7abd7cb48897bc314b7064751649:
    fingerprint: c551043bba4843351ab8b5ecb3da8a8fc4af3bbacd4d8af6deb388dbc132591a
    kind: update
    at: 2026-09-21T11:12:17.831Z
    entryIds:
      - e17
      - e18
  f9936e7989b36c17fe65af2417c1647b8d850edc293ee3a3c1544e408cffbee7:
    fingerprint: c314bed06271bb5f2be193d132e5c33a658d00c65f97dfb4edc259d04256b68a
    kind: update
    at: 2026-09-21T11:34:05.975Z
    entryIds:
      - e19
criterionVersions:
  ac-1: 1
  ac-2: 1
  ac-3: 1
  ac-4: 1
---

Windows 桌面版已能添加本地资源、绑定目录与导入技能：插件把取目录判定从「只认 native seam」改为「native 或桌面运行时 pickDirectory」，新增 POST /api/project/pick 由 Host 调起 desktopRuntime.pickDirectory()（即壳已桥接到 Host 的 Electron 对话框）；壳把 project pin bump 到含该实现的提交，并新增 resources-windows 工作流在 windows-2022 上做真实原生验收。ac-1/ac-2 由两轮 Windows CI 实测通过（run 35586284794、35591898652，artifact 含 resource-add-local*.png 与 resource-bind-and-skill.png），ac-3 保持与 native 同等姿态（服务端发起对话框 + 同源鉴权），ac-4 由 native 分支未改与单测三态覆盖。限制：CI 中 OS 对话框使用替身（无人点击，不可避免）；macOS/Linux 的逐张截图视觉核对按用户决定跳过。
