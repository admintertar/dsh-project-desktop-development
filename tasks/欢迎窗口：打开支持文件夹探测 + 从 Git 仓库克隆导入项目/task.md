---
schemaVersion: 3
directory: 欢迎窗口：打开支持文件夹探测 + 从 Git 仓库克隆导入项目
id: task-7be557ec-45bc-48a2-a111-1d3f62b12c8d
title: 欢迎窗口：打开支持文件夹探测 + 从 Git 仓库克隆导入项目
objective: 让欢迎窗口的两条项目入口更实用：(1)「打开」不再要求用户选中 *.agent-project 文件——选择一个文件夹时自动探测其中的项目入口文件，没有就明确提示这不是 agent-project 项目；(2) 新增「克隆仓库」入口（按用户要求排在「新建项目」和「打开」之前），弹窗填写仓库地址与本地目录（父目录 + 可编辑的文件夹名），克隆后自动检测是否为 agent-project 项目，通过则直接打开。改动只落在壳仓库 resources/dsh-project-desktop，复用插件既有的克隆与认证链及官方 UI 原语，插件零改动。
status: completed
createdAt: 2026-09-23T07:12:30.257Z
updatedAt: 2026-09-23T08:18:10.441Z
artifacts:
  - type: file
    path: artifacts/acceptance.md
    description: 验收报告：交付内容（含两类目录记忆）、逐条验收结果、平台归属证据链与已知限制
  - type: file
    path: artifacts/import-en-light.png
    description: 英文浅色主题下的克隆导入弹窗（字段、路径预览）
  - type: file
    path: artifacts/import-en-dark.png
    description: 英文暗色主题下的克隆导入弹窗
  - type: file
    path: artifacts/import-narrow-en-light.png
    description: 英文窄窗口（420×460）下的克隆导入弹窗，无横向溢出
  - type: file
    path: artifacts/guide-acceptance.log
    description: yarn run smoke:guide 原始输出：ok:true，18 项 checks 全绿（含 open-folder-and-repository-import）
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: d6da5b6951b35e5033f79bfaebda3980f6a5fe61
    description: 壳仓库提交：打开文件夹探测、克隆导入与目录记忆（17 个文件）
archived: false
phase: validation
brief:
  scope: resources/dsh-project-desktop：src/windows/guide-window.mjs（打开动作、导入 IPC、defaultDirectory）、src/app/main.mjs（菜单/标题栏打开）、src/app/project-files.mjs（路径分类）、src/app/repository-import.mjs（导入事务）、src/shared/remote-resource.mjs（文件夹名校验/推导）、src/guide/index.tsx 与 CloneRepositoryModal.tsx（工具栏与弹窗）、测试与原生验收脚本、docs/architecture.md。
  constraints:
    - 复用插件的 ResourceCloneManager、ProjectResourceStore、ResourceGitAuthentication 与官方认证弹窗，不另写 git clone，也不启动共享 Host
    - 不修改 .upstream 固定源码，不 bump upstream.lock.json，不发布、不 push
    - Windows/Linux 无法在一个原生对话框里同时选择文件和文件夹，行为差异必须显式处理而不是静默降级
    - 欢迎窗口只管理新建/打开/最近项目；不新增项目内的能力
    - 验收证据必须落盘到任务 artifacts，不能只留在被忽略的 .runtime 目录
  outOfScope:
    - 在项目子目录里递归查找项目文件
    - 克隆后自动初始化一个非 agent-project 仓库（按用户选择：不是项目就回滚）
    - 菜单/托盘的其它入口改造
    - 任何插件侧改动与版本 pin bump
  acceptanceCriteria:
    - id: AC1
      text: 「打开」的原生选择器同时允许文件和文件夹（Windows/Linux 退化为文件夹选择，多项目目录时补一次文件选择），选中文件夹时自动探测根目录唯一的 *.agent-project 入口文件并打开
      required: true
      version: 1
    - id: AC2
      text: 选中目录没有项目文件时，欢迎窗口显示自己的中英文案「这不是 agent-project 项目」，而不是插件只提供的中文提示；目录里有多个项目文件时不静默选择
      required: true
      version: 1
    - id: AC3
      text: 欢迎窗口工具栏顺序为「克隆仓库 / 新建项目 / 打开」，三个按钮都有稳定的语义选择器供验收脚本使用
      required: true
      version: 1
    - id: AC4
      text: 「克隆仓库」弹窗可填写仓库地址、可选分支、本地父目录与文件夹名（默认按 git clone 规则从地址推导，可改），显示最终路径预览与真实克隆阶段/百分比
      required: true
      version: 1
    - id: AC5
      text: 克隆完成后只接受根目录恰好一个 *.agent-project：通过则直接打开项目；没有项目文件时删除刚克隆的内容（完全回滚）；有多个项目文件时保留并在提示中给出路径
      required: true
      version: 1
    - id: AC6
      text: 私有仓库复用既有凭据弹窗与认证链，凭据不落盘；yarn run check 通过，且原生窗口验收覆盖中英文案、暗色主题、窄窗口与 Escape 关闭
      required: true
      version: 1
    - id: AC7
      text: 「克隆仓库」弹窗记住上次使用的本地父目录：浏览选中或成功发起一次导入后即记住，下次打开弹窗（含新窗口）预填该目录；记住的目录已不存在时回退到窗口默认目录
      required: true
      version: 1
    - id: AC8
      text: 项目内的目录选择（资源关联本地文件、资源重定位、技能导入）记住上次使用的目录：下次打开以它为选择器起始位置，只有真正选中才覆盖，取消不改变，目录已不存在时不再使用
      required: true
      version: 1
questions: []
handoff:
  nextSteps:
    - 壳仓库已提交为 d6da5b6951b35e5033f79bfaebda3980f6a5fe61（master），但尚未 push：push 后 guide-windows.yml 与 resources-windows.yml 会因 paths 命中而自动在 windows-2022 上跑。
    - Windows 实机/CI 验证由独立任务 task-7af5d595 跟踪（W1–W7）。
    - macOS/Linux 的目录选择保留 auto 后端（可能走官方 native），本项目不介入，行为差异已写入 docs/architecture.md。
    - 需要原生验收时，请在独占前台的桌面会话下跑：抢焦点会让 hasFocus 与分隔线检查变红。
  readBefore:
    - repository-import
    - guide-window
    - clone-modal
    - last-directories
  verifyBefore:
    - cd resources/dsh-project-desktop && yarn run check
    - cd resources/dsh-project-desktop && yarn run smoke:guide（独占前台，勿切窗口）
references:
  - id: repository-import
    label: 克隆导入事务（校验/安装/检测/回滚）
    type: file
    path: resources/dsh-project-desktop/src/app/repository-import.mjs
  - id: guide-window
    label: 欢迎窗口主进程：打开动作与导入 IPC
    type: file
    path: resources/dsh-project-desktop/src/windows/guide-window.mjs
  - id: clone-modal
    label: 克隆仓库弹窗
    type: file
    path: resources/dsh-project-desktop/src/guide/CloneRepositoryModal.tsx
  - id: last-directories
    label: 目录记忆（导入 + 项目内选择）
    type: file
    path: resources/dsh-project-desktop/src/app/last-directories.mjs
entries:
  - id: n1
    kind: progress
    content: 插件的 findProjectFile/resolveProjectFile 早已支持传目录并自动探测入口文件，真正的限制只在两处对话框：guide-window 的 open 动作与 main.mjs 的 pickOpen 都用了 properties:['openFile'] + *.agent-project 过滤，因此用户无法选择文件夹。
    basis: observation
    createdAt: 2026-09-23T07:12:30.257Z
  - id: n2
    kind: decision
    content: 打开路径先由壳的 classifyProjectTarget 分类（file / none / multiple / invalid / missing），再交给固定插件解析，这样「没有项目文件」「多个项目文件」能用欢迎窗口自己的中英文案呈现；错误码走已有的 guideErrorText 映射，不再把插件的中文 message 直接显示给英文用户。
    basis: agent-proposal
    createdAt: 2026-09-23T07:12:30.257Z
  - id: n3
    kind: decision
    content: 「克隆仓库」不自写 git clone，而是新增 RepositoryImports 事务复用 GuideClones（进而复用插件的 ResourceCloneManager 与认证链）：在选定父目录下为 <仓库名> 新建目标，校验后克隆到临时 draft，完成后复制到目标并检测项目文件。用户选择「不是项目就完全回滚」，因此没有项目文件时删除刚克隆的目录；有多个项目文件时保留（否则会丢用户仍可手动打开的内容）并在提示里给出路径。
    basis: user-request
    createdAt: 2026-09-23T07:12:30.257Z
  - id: n4
    kind: scope
    content: 工具栏顺序确定为「克隆仓库 / 新建项目 / 打开」，并给三个按钮加 data-guide-action（clone/new/open），让既有验收脚本改用语义选择器而不是位置，避免以后再调顺序时再次集体失效。
    basis: user-request
    reason: 用户在同一次需求中追加了工具栏顺序要求：克隆仓库、新建项目、打开。
    createdAt: 2026-09-23T07:12:30.257Z
  - id: n5
    kind: progress
    content: 实现完成：src/app/repository-import.mjs（校验/安装/检测/回滚）、src/app/project-files.mjs classifyProjectTarget、src/shared/remote-resource.mjs validRepositoryName+repositoryFolderName、guide-window 的 open 改造与 import-start/import-finish/import-cancel、main.mjs pickOpen、CloneRepositoryModal.tsx 与中英文案；新增 tests/repository-import.test.mjs（3 条，含真实私有 HTTPS 仓库 + 凭据重试）。
    basis: observation
    createdAt: 2026-09-23T07:12:30.257Z
  - id: v1
    kind: verification
    content: AC1：打开动作的对话框 properties 断言为 ['openFile','openDirectory']；只含一个 .agent-project 的文件夹被打开（目标为目录本身）；单元测试覆盖 classifyProjectTarget 的 file/none/multiple/invalid/missing 五种分类。
    basis: observation
    verification:
      criterionId: AC1
      criterionVersion: 1
      method: 真实验收窗口实时 DOM 断言 + node:test
      result: passed
      coverage: 原生窗口（scripts/native-guide-checks.mjs checkRepositoryImport 第一个场景）+ tests/repository-import.test.mjs 第 1 条
    createdAt: 2026-09-23T07:13:44.680Z
  - id: v7
    kind: verification
    content: AC2：空文件夹时欢迎窗口显示自己的中文文案「…不是 agent-project 项目…」；多项目文件夹在 macOS 报 project-ambiguous 并显示英文文案「several .agent-project files」，不静默选择任何一个；非 macOS 平台走补选文件分支。
    basis: observation
    verification:
      criterionId: AC2
      criterionVersion: 1
      method: 实时 DOM 文本断言（错误码经 guideErrorText 映射）
      result: passed
      coverage: 原生窗口 checkRepositoryImport 第二、三个场景（中/英文案）
    createdAt: 2026-09-23T07:13:44.680Z
  - id: v2
    kind: verification
    content: AC3：原生验收断言 data-guide-action 顺序为 ['clone','new','open']，文案分别为「克隆仓库 / 新建项目 / 打开…」；两个既有脚本（native-guide-loading-checks、native-guide-checks）已改用语义选择器，不再依赖按钮位置。
    basis: observation
    verification:
      criterionId: AC3
      criterionVersion: 1
      method: 实时 DOM 断言
      result: passed
      coverage: 原生窗口 checkRepositoryImport 工具栏断言 + yarn run smoke:guide 中 checkGuideLoading 通过
    createdAt: 2026-09-23T07:13:44.680Z
  - id: v3
    kind: verification
    content: AC4：弹窗标题中英断言、空表单校验提示、地址→文件夹名自动推导（imported-project）、路径预览结尾断言、克隆中进度行显示插件阶段「接收对象 42%」。
    basis: observation
    verification:
      criterionId: AC4
      criterionVersion: 1
      method: 实时 DOM 断言 + capturePage 截图
      result: passed
      coverage: 原生窗口 checkRepositoryImport 导入弹窗场景（中/英/暗色/窄窗口）
    createdAt: 2026-09-23T07:13:44.680Z
  - id: v4
    kind: verification
    content: AC5：真实私有 HTTPS 仓库导入后目标出现 Product.agent-project 并清空 creation-drafts；feature/demo 分支无项目文件时 finish 抛 repository-not-project 且目标目录被删除；cancel 后无残留。原生验收用确定性 clone job 验证成功后直接打开项目窗口。
    basis: observation
    verification:
      criterionId: AC5
      criterionVersion: 1
      method: node:test 端到端克隆/回滚/取消 + 原生 DOM 断言
      result: passed
      coverage: tests/repository-import.test.mjs 第 3 条（真实 Git + 真实 HTTP 认证）+ 原生 checkRepositoryImport 打开路径
    createdAt: 2026-09-23T07:13:44.680Z
  - id: v5
    kind: verification
    content: AC6：privateGitFixture 私有仓库经凭据问答（含一次错误密码重试）克隆成功，且目标 .git/config 不含令牌；yarn run check EXIT=0（121+7+1 测试）；原生验收覆盖英文暗色弹窗截图、Escape 关闭、420×460 窄窗口无横向溢出。
    basis: observation
    verification:
      criterionId: AC6
      criterionVersion: 1
      method: node:test + yarn run check + 实时 DOM 断言与截图
      result: passed
      coverage: tests/repository-import.test.mjs 第 3 条 + yarn run check 全绿 + 原生英文/暗色/窄窗口/Escape 断言
    createdAt: 2026-09-23T07:13:44.680Z
  - id: v6
    kind: verification
    content: smoke:guide 整体仍为 EXIT=1：既有 checkGuideFrame 需要 OS 级前台焦点，当前桌面被已安装的 DSH Project Desktop.app 占用；在未包含本改动的基线上同一命令同样失败（位置更早），git stash pop 已恢复。该限制已写入 artifacts/acceptance.md，不影响本次新增检查的结论。
    basis: observation
    verification:
      criterionId: AC6
      criterionVersion: 1
      method: 对照实验（stash 基线跑同一命令）
      result: passed
      coverage: git stash 基线对照 + ps 确认已安装 app 运行中
    createdAt: 2026-09-23T07:13:44.680Z
  - id: c1
    kind: completion
    content: 完成：AC1–AC6 均已实现并有通过证据（v1、v7、v2–v6），证据已归档到本任务 artifacts（报告 + 三张截图 + smoke 日志）。剩余限制已写入 summary、questions 与 handoff。
    basis: observation
    verificationEntryIds:
      - v1
      - v7
      - v2
      - v3
      - v4
      - v5
      - v6
    createdAt: 2026-09-23T07:13:44.680Z
  - id: n6
    kind: decision
    content: Windows/Linux 上「打开」保持文件夹选择器，不额外提供显式的「选文件」入口。依据：(1) Electron 官方文档明确 Windows/Linux 无法在同一个对话框里既选文件又选目录，设 ['openFile','openDirectory'] 只显示目录选择器（https://www.electronjs.org/docs/latest/api/dialog）；(2) Windows/macOS 安装包已注册 .agent-project 文件关联（scripts/package-windows.mjs 的 fileAssociations），资源管理器双击或「打开方式」经壳的 second-instance 直接打开项目，“选文件”这条路仍然存在；(3) 壳内的判定本来就是同一个动作（传文件直接打开、传文件夹探测本级唯一入口），不需要第二套逻辑。用户已知情并确认保持现状。
    basis: user-request
    createdAt: 2026-09-23T07:26:24.434Z
  - id: change-06c572d4-9497-4a5e-9ea5-75bdc62cec07
    kind: decision
    content: completed → active
    reason: 用户在同一需求中追加：克隆仓库弹窗需要记住上次使用的父目录。需要新增验收标准 AC7 并补齐对应验收证据，因此重开任务进行这一轮增量工作。
    createdAt: 2026-09-23T07:48:01.554Z
  - id: n8
    kind: scope
    content: 新增验收标准 AC7（克隆导入弹窗记住上次使用的父目录）。原 brief 的 AC4 只要求弹窗能填写父目录，未包含“记住”。
    basis: user-request
    reason: 用户在同一次需求中追加：克隆仓库弹窗需要记住上次使用的父目录。
    createdAt: 2026-09-23T07:48:27.611Z
  - id: n7
    kind: progress
    content: 目录记忆实现：新增 src/app/guide-directories.mjs（GuideDirectories，存 userData/guide-directories.json，读取时重校目录是否存在，损坏/非法文件重命名保留）；guide-window 新增 browse-import-directory（以记忆值为 defaultPath，选中即记住）并在 import-start 成功后记住实际使用的父目录；state 下发 importDirectory；弹窗目录初值取 importDirectory ?? defaultDirectory，打开弹窗前先 refresh 一次以拿到最新记忆；新增 tests/guide-directories.test.mjs（3 条）。
    basis: observation
    createdAt: 2026-09-23T07:48:27.611Z
  - id: v8
    kind: verification
    content: AC7：原生验收断言无记忆时目录初值为窗口默认目录（Defaults）、一次导入后新窗口弹窗预填上次的 destination、点「浏览」选中的 Picked 立即生效并在关闭重开后仍然预填；单元测试覆盖记忆往返、目录被删后不再预填、损坏/非法状态文件隔离保留。
    basis: observation
    verification:
      criterionId: AC7
      criterionVersion: 1
      method: 实时 DOM 断言（目录输入框的值）+ node:test
      result: passed
      coverage: 原生窗口 checkRepositoryImport 新增场景（三处预填断言）+ tests/guide-directories.test.mjs 3 条
    createdAt: 2026-09-23T07:48:27.611Z
  - id: v9
    kind: verification
    content: 在一次无人干扰的桌面会话下重跑 yarn run smoke:guide 得到 EXIT=0、ok:true，18 项 checks 全部通过（含透明的分隔线 hover/drag 与新增的 open-folder-and-repository-import）；随后 yarn run check EXIT=0（124+7+1 测试）。之前观察到的分隔线颜色失败与 hasFocus 超时已确认由运行期间抢焦点造成，不是回归。
    basis: observation
    verification:
      criterionId: AC6
      criterionVersion: 1
      method: 无干扰的原生全量运行（无人抢焦点）
      result: passed
      coverage: 完整 smoke:guide 输出 result.json + yarn run check 日志
    createdAt: 2026-09-23T07:48:27.611Z
  - id: c2
    kind: completion
    content: 完成：AC1–AC7 均有通过证据（v1、v7、v2–v6、v8、v9），证据已用最后一轮数据覆盖归档（报告 + 三张截图 + 全绿 smoke 日志）。资源页目录记忆作为待定问题保留。
    basis: observation
    verificationEntryIds:
      - v1
      - v7
      - v2
      - v3
      - v4
      - v5
      - v6
      - v8
      - v9
    createdAt: 2026-09-23T07:48:27.611Z
  - id: change-f4b390ee-31ae-4d70-89f4-c39d1c906b83
    kind: decision
    content: completed → active
    reason: 用户追加需求：资源页/技能页的目录选择也要记住上次使用的目录。需要新增验收标准 AC8、补验收证据（含 Windows 分支断言）并更新已落地的模块名，因此重开任务做这一轮增量。
    createdAt: 2026-09-23T08:03:06.427Z
  - id: n9
    kind: scope
    content: 新增验收标准 AC8（项目内目录选择记住上次目录）。背景：资源页的“关联本地文件”、资源重定位与技能导入共用插件 pickDirectory，而它自始至终不传 defaultPath。
    basis: user-request
    reason: 用户追加：资源页/技能页的目录选择也要记住上次目录。
    createdAt: 2026-09-23T08:03:22.337Z
  - id: n10
    kind: progress
    content: AC8 实现：src/app/guide-directories.mjs 更名为 src/app/last-directories.mjs（类 LastDirectories，keys 增加 resource，状态文件 last-directories.json），并抽出共用的 pickRememberedDirectory(state, key, open)；native.mjs 的 runtime.pickDirectory（资源页/重定位/技能导入的落脚点）与 guide-window 的 browse-import-directory 都改用它；tests/last-directories.test.mjs 增至 4 条。
    basis: observation
    createdAt: 2026-09-23T08:03:22.337Z
  - id: n11
    kind: decision
    content: 平台归属核实：固定 Desktop 的 profile.ts 在 win32 上禁用 directory-picker（auto 后端）并插入 dsh-host-directory-picker-browse，Host 侧 directoryPicker 能力位为 browse，插件的 pickSource 因此返回 desktop，目录选择落到壳自有的 pickDirectory —— 即目录记忆在 Windows 上生效；macOS/Linux 保留 auto 后端（按平台探测，Linux 看 zenity/kdialog），走 native 时由官方选择器负责。既有的 native-resource-state-checks.mjs 也只在 win32 上替换 dialog，与该结论一致。
    basis: observation
    createdAt: 2026-09-23T08:03:22.337Z
  - id: v10
    kind: verification
    content: AC8 单元测试：tests/last-directories.test.mjs 4 条涵盖记忆往返（含 resource 键）、目录被删后不再预填、损坏/非法状态文件隔离保留、pickRememberedDirectory 的起止点与取消不覆盖；yarn run check EXIT=0（125+7+1）。
    basis: observation
    verification:
      criterionId: AC8
      criterionVersion: 1
      method: node:test + 完整 check
      result: passed
      coverage: tests/last-directories.test.mjs（4 条）+ yarn run check 全绿
    createdAt: 2026-09-23T08:03:22.337Z
  - id: v11
    kind: verification
    content: AC8 端到端：重构后重跑 yarn run smoke:guide EXIT=0、ok:true，18 项 checks 全绿（含 open-folder-and-repository-import 里的三处目录预填断言），证明 browse-import-directory 改用 pickRememberedDirectory 后无回归；另在 native-resource-state-checks.mjs 的 Windows 分支新增端到端断言（第一次选择器无 defaultPath、第二次的 defaultPath 等于上次选中的目录），随 smoke:host 在 Windows 上执行，本机 macOS 不走该分支。
    basis: observation
    verification:
      criterionId: AC8
      criterionVersion: 1
      method: 原生 smoke:guide 全量运行 + Windows 分支实时 DOM/参数断言（待实机）
      result: passed
      coverage: 本机：yarn run smoke:guide 全绿；Windows 分支断言已入脚本但本机未执行（待实机/CI）
    createdAt: 2026-09-23T08:03:22.337Z
  - id: c3
    kind: completion
    content: 完成：AC1–AC8 均有通过证据（v1、v7、v2–v6、v8–v11）；证据已用最后一轮运行覆盖归档（报告 + 三张截图 + 全绿 smoke 日志，共 5 个文件 528K）。唯一保留的限定：Windows 实机未跑（该平台的新增断言与 openFile+openDirectory 退化分支等 CI/实机确认）。
    basis: observation
    verificationEntryIds:
      - v1
      - v7
      - v2
      - v3
      - v4
      - v5
      - v6
      - v8
      - v9
      - v10
      - v11
    createdAt: 2026-09-23T08:03:22.337Z
  - id: n12
    kind: progress
    content: 已按用户要求提交壳仓库改动：commit d6da5b6951b35e5033f79bfaebda3980f6a5fe61（master，17 个文件，+789/-44）。未 push、未 bump pin。提交后工作树干净。
    basis: user-request
    createdAt: 2026-09-23T08:18:10.441Z
operations:
  10d87550b1707a14e47c5bfdd1cb29aa88bc2b21280fdb43eb2a236bb94e19b8:
    fingerprint: 4d72fcb05b2470bc324836c0fdf5f5bfe2be20d5e2ce97684bd2c84f516d223e
    kind: create
    at: 2026-09-23T07:12:30.257Z
    entryIds:
      - n1
      - n2
      - n3
      - n4
      - n5
  201ad4cc48ad8a2c88491c11031626c7579950ee1580a59963500b6dd02a315b:
    fingerprint: 2a95360be4aea9862202649d14bd2d2a1398c30c986de8ec692d8c6fde02f625
    kind: update
    at: 2026-09-23T07:13:44.680Z
    entryIds:
      - v1
      - v7
      - v2
      - v3
      - v4
      - v5
      - v6
      - c1
  6064f2b5d4b9f63c1c58f28b941278729f92df235c7b3922c355aa7daa62eb37:
    fingerprint: 16f4b32d45358fbd4eb6f88a2fbe0cf120de3174c68975d75a5bee5d0ccc6af5
    kind: update
    at: 2026-09-23T07:26:24.434Z
    entryIds:
      - n6
  3e2ab23bdb1577842187a77ac61ac173a6a69fbc5ca17b3744d92f8c8d32a699:
    fingerprint: 05ed0846e03b294228e37aa835529983133a050955b6a3ec84f43298e42d23a4
    kind: update
    at: 2026-09-23T07:48:01.554Z
    entryIds:
      - change-06c572d4-9497-4a5e-9ea5-75bdc62cec07
  a671672be17c05bbac0aac0fd6b44895ebf361074ec30053c9e1555090f14832:
    fingerprint: a54f06e7841af30d5bf258ec64a6f07ad660042309903420ada444a825b13cbf
    kind: update
    at: 2026-09-23T07:48:27.611Z
    entryIds:
      - n8
      - n7
      - v8
      - v9
      - c2
  6e9c051a1a4125dc0115ad1f809080cdd45a511d91b9889bc9212d5a0aae88e7:
    fingerprint: 968c87761c5b88cdc571febe7b50691516d61a44ddb6219955a791b71ec428ac
    kind: update
    at: 2026-09-23T08:03:06.427Z
    entryIds:
      - change-f4b390ee-31ae-4d70-89f4-c39d1c906b83
  c94f69264c27300650b84192f46939a302087d72a02e4b63aa3b9dd0eb2bc4df:
    fingerprint: 17d2df06ef6a0e4cb8a92a4bad66a45a59a0e247d6a86fc1b441e91ff99808a0
    kind: update
    at: 2026-09-23T08:03:22.337Z
    entryIds:
      - n9
      - n10
      - n11
      - v10
      - v11
      - c3
  cd623076b3c18daede67cb8e8994cd051766c39a7a60ed27de0c585a16e7d8b9:
    fingerprint: 80cf3f528b00e02ff0a40c5d03bf73eaea2238ae76c1a82a354a258bb16450fb
    kind: update
    at: 2026-09-23T08:18:10.441Z
    entryIds:
      - n12
criterionVersions:
  AC1: 1
  AC2: 1
  AC3: 1
  AC4: 1
  AC5: 1
  AC6: 1
  AC7: 1
  AC8: 1
---

三条需求均已实现、验证并归档：(1)「打开」的原生选择器现在同时允许文件夹，选中文件夹时自动探测根目录唯一的 *.agent-project 并打开，没有项目文件时用欢迎窗口自己的中英文案提示，多项目目录不静默选择（macOS 直接报错、Windows/Linux 补一次文件选择）；(2)「克隆仓库」入口按用户要求排在「新建项目」「打开」之前，弹窗填写地址/可选分支/本地父目录/文件夹名（按 git clone 规则自动推导、可改）并显示路径预览与真实克隆阶段百分比，克隆完成后只接受根目录恰好一个 *.agent-project：通过则直接打开项目，没有项目文件时删除刚克隆的内容（完全回滚），多个项目文件时保留并给出路径；私有仓库复用既有凭据弹窗与认证链；(3) 目录记忆统一到 src/app/last-directories.mjs（userData/last-directories.json，读取时重校目录仍存在，损坏状态文件重命名保留）：欢迎窗口导入弹窗用 import 键，资源/资源重定位/技能导入共用 resource 键，由共用的 pickRememberedDirectory 实现“上次目录当起始位置、只有真选了才覆盖、取消不动”；核实到 Windows 正是走 browse 后端落到壳 pickDirectory 的平台，因此记忆在 Windows 上生效。实现全部落在壳仓库，插件零改动、未 bump pin，已提交为 d6da5b6951b35e5033f79bfaebda3980f6a5fe61（master，17 个文件），尚未 push。验证：yarn run check EXIT=0（125+7+1 测试）；yarn run smoke:guide EXIT=0、ok:true，18 项 checks 全绿；yarn run smoke:guide:focused EXIT=0（focused 现已包含 checkRepositoryImport）。限制：未在 Windows 实机验证（由 task-7af5d595 跟踪）；macOS/Linux 走 auto 后端，本项目不介入。
