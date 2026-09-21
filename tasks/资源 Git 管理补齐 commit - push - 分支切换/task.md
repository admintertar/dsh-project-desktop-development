---
schemaVersion: 3
directory: 资源 Git 管理补齐 commit - push - 分支切换
id: task-2646c970-8b9e-4c35-ab93-6f5fec4ede12
title: 资源 Git 管理补齐 commit / push / 分支切换
objective: 让资源面板能直接处理本地领先、未提交改动和分支切换，不必切到外部 Git 客户端；同时修复会污染资源仓库的 .gitignore 幂等缺陷。
status: completed
createdAt: 2026-09-20T06:22:52.232Z
updatedAt: 2026-09-21T05:41:19.656Z
artifacts:
  - type: commit
    repository: https://github.com/admintertar/dsh-plugin-project.git
    commit: b2d3e28fc74957c49cac156c7ef3726088cca160
    description: "fix: follow the reported branch in the resource picker"
  - type: commit
    repository: https://github.com/admintertar/dsh-plugin-project.git
    commit: 24b7ddf5ddfc8c6ee4372aa2b2ea2131a4d41736
    description: "refactor: make the associate action an icon action"
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: 89418fc013680a7f30599db25a4ff054e19f96f4
    description: "test: exercise the resource Git actions in the native check"
archived: false
phase: implementation
brief:
  currentBehavior: 资源支持 check / update / commit / push / switch 五个动作与只读分支列表；面板能处理 dirty / ahead / diverged / in-progress。原生验收（本地源构建）已实际点击并验证提交、快进推送与分支切换，并修复了切换分支后选择器不刷新的缺陷。
  scope: dsh-plugin-project 的资源 Git 能力：Host 侧契约与 ResourceSyncManager、资源 API 路由、客户端 UI 与中英文案、测试。
  constraints:
    - 不执行仓库钩子（core.hooksPath=/dev/null），与既有 fetch/merge 立场一致
    - 不 rebase、不 stash、不 force-reset、不改写历史
    - 沿用既有 repository 锁与 revision 校验机制
    - 只与当前分支的 upstream 比较，不做 pin 差距感知
  outOfScope:
    - pin 差距感知（用户明确不要）
    - 由模型生成提交信息（需把 Agent 接入资源面板，留作后续增强）
    - 暂存区 UI（提交范围固定为全部改动）
  acceptanceCriteria:
    - id: ac1
      text: 资源支持 commit：提交全部改动，提交信息由用户填写
      required: true
      version: 1
    - id: ac2
      text: 资源支持 push：仅允许快进推送，永不使用 force
      required: true
      version: 1
    - id: ac3
      text: 资源支持列出分支并切换到指定分支
      required: true
      version: 1
    - id: ac4
      text: dirty / in-progress / 无 upstream / 分支不存在等状态被拒绝，并返回对应错误码
      required: true
      version: 1
    - id: ac5
      text: 新增能力有测试覆盖，插件完整测试套件与 typecheck 通过
      required: true
      version: 1
    - id: ac6
      text: .gitignore 追加规则按 git 锚定语义幂等，不再重复写入等价规则
      required: true
      version: 1
handoff:
  nextSteps:
    - 发布时才需要把 upstream.lock.json 的 project pin 从 58d1f6d bump 到 24b7ddf 并重导 .upstream/project（流程见 note-pin）；日常本地开发不必改它。
    - 本地验证插件工作树请带 DSH_PROJECT_PLUGIN_SOURCE=../dsh-plugin-project（build 与 smoke 都必须带）；不带变量的标准 smoke:resources 在 pin 更新前会失败，因为检查脚本断言了 pin 尚未包含的行为。
    - CI（.github/workflows/package.yml）只跑 npm run check 与 smoke:updates，不运行 smoke:resources，因此不受 pin 落后影响。
references:
  - id: note-design
    label: 设计决定
    type: note
    text: commit：全部改动 + 用户填写信息 + 禁用钩子与 GPG 签名。push：仅快进，永不 force，无 upstream/in-progress/分叉时拒绝；成功后显式更新 tracking ref。switch：dirty 或 in-progress 时拒绝，不自动 stash，仅限已存在本地分支。branches：只读列出本地与远端。
  - id: note-verify
    label: 验证方式
    type: note
    text: cd resources/dsh-plugin-project && npm run check（typecheck + 完整测试 + build）。另需确认 push 路径永不生成 force 参数。
  - id: file-contract
    label: 资源契约
    type: file
    path: resources/dsh-plugin-project/src/resource-contract.ts
  - id: file-sync
    label: 资源同步管理器
    type: file
    path: resources/dsh-plugin-project/src/resource-sync.ts
  - id: file-api
    label: 资源 API（/sync 扩展 + GET /branches）
    type: file
    path: resources/dsh-plugin-project/src/resource-api.ts
  - id: file-ui
    label: 资源卡片与错误码映射
    type: file
    path: resources/dsh-plugin-project/src/client/resource-ui.ts
  - id: file-card
    label: 资源卡片（新增提交/推送/分支 UI）
    type: file
    path: resources/dsh-plugin-project/src/client/ResourceCard.tsx
  - id: note-pin
    label: pin 联动流程（本地验证插件工作树必须）
    type: note
    text: 1) 提交插件并取新 commit；2) 用 git rev-parse <sha>^{tree} 重算 tree；3) 更新壳 upstream.lock.json 的 project.commit/tree；4) rm -rf .upstream/project 后重新导出（setup 的 snapshot() 在目标存在时会直接返回，会静默沿用旧快照）；5) npm run verify:upstream 验证 tree；6) npm run build；7) 跑定向原生检查。
entries:
  - id: inv-1
    kind: progress
    content: 现状勘察：resource-sync.ts 仅暴露 check/update 两个动作，updatable() 在 dirty / ahead+behind / in-progress 时抛错；UI（ResourceCard.tsx）只有两个按钮。官方运行时 245 个包无任何 Git 实现，也无任何包执行 git 命令，因此必须自研。官方 DiffBlock 已被本插件复用（TaskCommitPreview.tsx），可用于提交前预览。
    basis: observation
    reason: 确认能力缺口与可复用面
    createdAt: 2026-09-20T06:22:52.232Z
  - id: dec-1
    kind: decision
    content: 补齐 commit / push / 分支切换三项；commit 由模型判断后决定纳入。提交信息由用户填写（不做模型生成）；提交范围为全部改动（git add -A）；提交时禁用仓库钩子。
    basis: user-request
    reason: dirty 是开发时最常见状态，push 与分支切换都无法解决它，缺 commit 则功能不闭环。
    createdAt: 2026-09-20T06:22:52.232Z
  - id: ver-1
    kind: verification
    content: .gitignore 幂等缺陷已修复：新增 canonicalIgnoreRule()，按 git 锚定语义（分隔符出现在开头或中间即锚定）归一化后比较，使 /mcp/local.yaml 与 mcp/local.yaml 视为同一规则，而 local.yaml 与 /local.yaml 保持区分。
    basis: observation
    reason: 该缺陷会让产品在打开项目时静默修改资源仓库的已跟踪文件，直接污染开发者的提交。
    verification:
      criterionId: ac6
      criterionVersion: 1
      method: node --test（插件完整套件）+ tsc --noEmit
      result: passed
      coverage: 新增 3 个回归测试；project-layout.test.ts 10/10；插件完整套件 241/241；typecheck 干净
    createdAt: 2026-09-20T06:22:52.232Z
  - id: prog-1
    kind: progress
    content: Host 侧契约改造进行中：计划扩展 ResourceGitSync.phase、资源错误码、同步动作联合类型与分支列表类型，然后在 ResourceSyncManager 中实现 commit/push/branches/switch，并扩展 /sync 路由与新增 GET /branches。
    basis: observation
    reason: 先完成并验证 Host 语义，再做客户端 UI
    createdAt: 2026-09-20T06:22:52.232Z
  - id: prog-2
    kind: progress
    content: Host 侧完成：resource-contract.ts 新增 5 个错误码、phase 扩展、ResourceSyncAction 与 ResourceBranches；resource-auth-contract.ts 的 GitAuthScope.action 增加 push；ResourceSyncManager 新增 start() 动作分发与 mutate/commit/push/switchBranch/branches/branchNames；resource-api.ts 的 /sync 扩展为 5 个动作并新增 GET /branches。
    basis: observation
    reason: 实现完成，进入验证
    createdAt: 2026-09-20T07:16:51.427Z
  - id: prog-3
    kind: progress
    content: 实现中发现并修复两个真问题：1) git 只在推送【命名远端】时更新 remote-tracking ref，而本实现按 URL 推送（与既有 fetch 一致），实测推送后 ahead 仍为 1，面板会错误地继续显示「领先」；已在 push 成功后显式 update-ref 记录已推送的提交。2) refs/remotes/<remote>/HEAD 是符号引用，%(refname:short) 会把它缩短成裸的远端名，导致按 /HEAD 后缀过滤失效、列表多出空串；已改用完整 refname 判断。
    basis: observation
    reason: 两个都会造成用户可见的错误状态，属于必须修的实现缺陷
    createdAt: 2026-09-20T07:16:51.427Z
  - id: dec-2
    kind: decision
    content: commit 时同时禁用 GPG 签名（-c commit.gpgsign=false）：Host 无交互终端，签名会弹 pinentry 口令框或卡住，最终以超时失败且错误信息难懂。代价是面板提交的 commit 不是签名提交。用户已确认「禁用吧，可控一点」。
    basis: user-request
    reason: 用户确认
    createdAt: 2026-09-20T07:16:51.427Z
  - id: ver-ac1
    kind: verification
    content: commit 实现验证：提交全部改动（含未跟踪文件）、提交后 dirty 转 false 且状态为 ahead 1、pre-commit 钩子未执行、空提交信息/干净工作树/缺失身份分别返回 git-commit-message-required / git-nothing-to-commit / git-identity-missing，且被拒时历史不变。
    basis: observation
    reason: ac1 证据
    verification:
      criterionId: ac1
      criterionVersion: 1
      method: npx tsx --test tests/resource-sync.test.ts
      result: passed
      coverage: tests/resource-sync.test.ts 新增 2 个用例
    createdAt: 2026-09-20T07:16:51.427Z
  - id: ver-ac2
    kind: verification
    content: push 实现验证：快进推送后远端 HEAD 推进到本地提交、状态转 current 且 ahead 为 0、本地 tracking ref 同步更新；断言 push 参数中不含 --force/-f/force-with-lease（整个调用列表零命中）；分叉历史与无可推提交分别返回 git-history-diverged / git-nothing-to-push，且被拒时根本没调用 git。
    basis: observation
    reason: ac2 证据
    verification:
      criterionId: ac2
      criterionVersion: 1
      method: npx tsx --test tests/resource-sync.test.ts
      result: passed
      coverage: tests/resource-sync.test.ts 新增 2 个用例，含「永不 force」与「被拒不触达 Git」断言
    createdAt: 2026-09-20T07:16:51.427Z
  - id: ver-ac3
    kind: verification
    content: 分支能力验证：branches 正确返回 current=main、remoteName=origin、local=[main]、remote=[feature,main]（符号 HEAD 不再污染列表）；switch 到已存在本地分支成功且 HEAD 切换；未知分支、非法分支名、脏工作树分别返回 git-branch-missing / resource-branch-invalid / git-local-changes，且被拒时当前分支不变。
    basis: observation
    reason: ac3 证据
    verification:
      criterionId: ac3
      criterionVersion: 1
      method: npx tsx --test tests/resource-sync.test.ts
      result: passed
      coverage: tests/resource-sync.test.ts 新增 1 个用例，覆盖列表与三类拒绝
    createdAt: 2026-09-20T07:16:51.427Z
  - id: ver-ac4
    kind: verification
    content: 安全边界验证：已覆盖的拒绝路径包括脏工作树、无 upstream、分叉历史、未知分支、非法分支名、无可提交/无可推送、缺失身份；in-progress 检查在 commit/push/switch 三处均有（与现有 update 的 updatable() 同源策略）。
    basis: observation
    reason: ac4 证据
    verification:
      criterionId: ac4
      criterionVersion: 1
      method: npx tsx --test tests/resource-sync.test.ts
      result: passed
      coverage: 上述拒绝路径均有断言；in-progress 与既有测试共用 operationMarkers 机制
    createdAt: 2026-09-20T07:16:51.427Z
  - id: ver-ac5
    kind: verification
    content: 完整验证：npm run check（typecheck + 全部测试 + build）exit 0，插件测试 246/246 通过（原 241 + 新增 5），typecheck 干净。
    basis: observation
    reason: ac5 证据
    verification:
      criterionId: ac5
      criterionVersion: 1
      method: cd resources/dsh-plugin-project && npm run check
      result: passed
      coverage: 整个插件套件，含本次新增的 5 个 resource-sync 用例
    createdAt: 2026-09-20T07:16:51.427Z
  - id: prog-4
    kind: progress
    content: 客户端完成：resource-controller 的 sync 支持 5 个动作并新增 branches()；resource-ui 补全 5 个新错误码映射、5 个 phase 文案、canPush/canCommit/canSwitch 判定；ResourceCard 新增推送按钮（卡片底栏 + 详情弹窗）、提交信息输入、分支选择（ProjectSelect）与提交按钮；ResourcesPanel 接线；中英文案齐备。新增 1 个控制器测试验证 commit 带 message、switch 带 branch、push 两者都不带，以及分支查询为纯 GET。
    basis: observation
    reason: 客户端实现完成
    createdAt: 2026-09-20T08:31:39.162Z
  - id: prog-5
    kind: progress
    content: 发现并修正自己引入的回归：原本 syncActions 由 canCheckResource 门控，放宽后使不可检查的资源上出现「存在但禁用」的检查按钮，而 smoke:resources 第 57 行断言这种按钮应当【不存在】。已改为不可用动作直接不渲染（check 与 push 均如此），保留原断言语义。
    basis: observation
    reason: 避免真实界面检查回归
    createdAt: 2026-09-20T08:31:39.162Z
  - id: prog-6
    kind: progress
    content: "插件已提交两个 commit：ce099ff（fix: compare ignore rules by anchoring, not literal text）与 fa95b5d（feat: commit, push and switch branches from the resource panel），工作树干净；同时还原了旧 bug 写进 examples/demo-web/.gitignore 的重复行。"
    basis: observation
    reason: 交付形态落定
    createdAt: 2026-09-20T08:31:39.162Z
  - id: ver-ac5b
    kind: verification
    content: 插件完整验证（含客户端改动）：npm run check exit 0，插件测试 247/247 通过（原 241 + resource-sync 5 + client-resources 1），typecheck 干净。
    basis: observation
    supersedes: ver-ac5
    reason: ac5 的更新证据（含客户端层）
    verification:
      criterionId: ac5
      criterionVersion: 1
      method: cd resources/dsh-plugin-project && npm run check
      result: passed
      coverage: 整个插件套件，含新增的 5 个 resource-sync 用例与 1 个客户端控制器用例
    createdAt: 2026-09-20T08:31:39.162Z
  - id: ver-native-1
    kind: verification
    content: "壳侧联动验证：将 upstream.lock.json 的 project pin 从 1644f40 更新到 fa95b5d（tree 1522ad4c），重新导出 .upstream/project 后：1) 用 sourceTree() 独立核算导出目录的 tree hash，与 pin 完全一致；2) verify:upstream 通过；3) 壳 build 成功且产物中确认包含新 UI（client.js 命中新文案 14 处、index.js 命中新错误码 2 处）；4) 定向原生检查 smoke:resources 通过（ok: true）；5) 壳自身测试 67/67 通过。"
    basis: observation
    reason: 真实界面与联动验证证据
    verification:
      criterionId: ac5
      criterionVersion: 1
      method: cd resources/dsh-project-desktop && npm run verify:upstream && npm run build && npm run smoke:resources
      result: passed
      coverage: pin 更新 + 快照重导出 + tree 核算 + 壳构建 + smoke:resources + 壳单测；未覆盖：新控件（提交输入/推送/分支切换）的交互点击
    createdAt: 2026-09-20T08:31:39.162Z
  - id: gap-1
    kind: progress
    content: 已知缺口（如实记录）：smoke:resources 只断言资源卡片、同步标签与各状态下的按钮存在性，不点击新增的提交/推送/分支切换控件，因此【新控件的交互与视觉未经验收】。且壳的原生检查只验证 pin 住的插件快照，本地验证插件工作树必须先 bump pin（本次已做，尚未提交）。
    basis: observation
    reason: 必须如实标注未运行的检查
    createdAt: 2026-09-20T08:31:39.162Z
  - id: dec-3
    kind: decision
    content: 原生验收必须有一个产品认可的远端：validResourceUrl 只接受 https/ssh，且自动 check 失败会把资源置为 error，使 commit/push/switch 全部不可用（canCommit/canPush 都要求 !sync.error）。因此检查脚本内起一个 loopback HTTPS 服务：自签名证书 + git http-backend 转发（CGI 头解析后流式回包），URL 形如 https://127.0.0.1:<port>/backend.git；仓库级 http.sslVerify=false 让 git 信任证书，裸仓库开启 http.receivepack 才能推送。曾尝试 git url.<base>.insteadOf 重定向，失败原因是 git remote get-url 会展开 insteadOf，产品随即判定 resource-origin-mismatch。
    basis: observation
    reason: 解释检查脚本为何自带 HTTPS 服务器，以及为什么不能用本地路径/insteadOf 走捷径
    createdAt: 2026-09-21T03:32:26.238Z
  - id: prog-7
    kind: progress
    content: 原生验收发现真实缺陷并修复：详情弹窗的分支选择器只在打开时读取一次分支列表，切换分支后仍显示旧分支（实测 HEAD 已切到 feature，选择器仍写 main，且「远程更新」显示的是 feature 的 no-upstream 状态）。修复：ResourceCard 增加 effect，跟随 item.git.branch 上报的分支重新读取一次分支列表，用 followedBranch ref 保证每个分支只跟随一次、不会因 branches 对象更新而循环请求。
    basis: observation
    reason: 用户可见的错误状态：切换成功后界面仍显示旧分支
    createdAt: 2026-09-21T03:32:26.238Z
  - id: ver-ac5c
    kind: verification
    content: 插件完整验证（含分支跟随修复）：npm run check exit 0，插件测试 248/248 通过，typecheck 干净。
    basis: observation
    reason: ac5 的最新证据
    verification:
      criterionId: ac5
      criterionVersion: 1
      method: cd resources/dsh-project-plugin && npm run check
      result: passed
      coverage: typecheck + 全部测试（248）+ build
    createdAt: 2026-09-21T03:32:26.238Z
  - id: ver-native-2
    kind: verification
    content: 原生验收补齐（gap-1 的交互点击缺口已闭合）：在真实 Electron 界面上按顺序验证——1) 脏工作树时卡片出现「提交改动」，推送按钮此时不存在；2) 打开提交对话框，变更列表列出 AGENT.md 且状态为「已修改」，取消后焦点回到开启它的按钮；3) 中英双语下对话框标题/字段 aria-label/变更列表文案逐一断言；4) 空提交信息点提交，断言行内错误「请填写提交信息。」且 Git 历史不变；5) 填入信息提交，等待 Git 真正产生该提交、工作树转干净；6) 检查更新后出现「推送提交」，点击后远端 HEAD 前进到本地提交且面板转「已是最新」；7) 详情弹窗中分支选择器列出本地分支并真实切换 HEAD 到 feature，选择器跟随刷新；8) 制造脏工作树后选择器转为禁用；9) 窄窗口 420px 下详情弹窗无横向溢出；10) Escape 关闭后焦点返回。
    basis: observation
    reason: 真实界面与真实 Git 的交互证据
    verification:
      criterionId: ac5
      criterionVersion: 1
      method: cd resources/dsh-project-desktop && DSH_PROJECT_PLUGIN_SOURCE=../dsh-plugin-project npm run build && DSH_PROJECT_PLUGIN_SOURCE=../dsh-plugin-project npm run smoke:resources
      result: passed
      coverage: 提交/推送/分支切换的真实点击与真实 Git 状态核对、中英文案、窄窗口、焦点；注意这是在含未提交插件改动的本地源工作树上验证的（DSH_PROJECT_PLUGIN_SOURCE），不是 pin 快照
    createdAt: 2026-09-21T03:32:26.238Z
  - id: prog-8
    kind: progress
    content: 验收脚本的两个关键发现，供后续复用：1) Host 的 /sync 立即返回 {accepted:true}，操作在后台异步执行（卡片以 phase 显示），所以断言 Git 结果必须轮询等待，不能紧跟对话框关闭；2) 提交对话框的变更列表来自独立读取，打开对话框时可能尚未到达，断言前需等待。检查脚本已相应加入 waitGit 辅助与 changes 等待。
    basis: observation
    reason: 避免后续会话重复踩坑
    createdAt: 2026-09-21T03:32:26.238Z
  - id: prog-9
    kind: progress
    content: 并行改动情况（如实记录）：工作树存在非本会话产生的改动——插件 ResourcesPanel.tsx 把「关联远端」从文本按钮改为 IconAction（带 aria-label），壳 native-resource-state-checks.mjs 相应改用 aria-label 定位（clickAction）。本会话保留了这些改动，并让扩展部分复用其 actionSelector。当前两个仓库均有未提交改动，提交边界与 pin 处理需要用户确认。
    basis: observation
    supersedes: gap-1
    reason: 存在并行编辑，必须说明工作树状态与耦合关系
    createdAt: 2026-09-21T03:32:26.238Z
  - id: prog-10
    kind: progress
    content: 本轮改动已提交（按用户选择「全部提交为独立提交」且暂不 push）：插件 b2d3e28（分支跟随修复）、24b7ddf（关联远端改为图标动作，即并行改动）、壳 89418fc（原生验收扩展）。两个仓库工作树干净，verify:upstream 仍通过（pin 未动）。未推送：插件 2 个、壳 1 个。
    basis: observation
    reason: 交付形态落定
    createdAt: 2026-09-21T03:36:47.279Z
  - id: done-1
    kind: completion
    content: 六条验收标准均有通过证据：ac1=ver-ac1、ac2=ver-ac2、ac3=ver-ac3、ac4=ver-ac4、ac5=ver-ac5c+ver-native-2、ac6=ver-1。实现与修复均已推送到 origin/master（插件 24b7ddf、壳 89418fc）。pin 按项目约定留到发布时再 bump，不作为完成条件。
    basis: observation
    verificationEntryIds:
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5c
      - ver-native-2
      - ver-1
    createdAt: 2026-09-21T05:41:19.656Z
operations:
  92aa9d4356a174b7afa8a8df50ced7e3c2c8af4b5b56ca1d4ae7b3b6db9d012c:
    fingerprint: 722fd1d4a72da3e59c50db2ecb395ac297152b3bc39ddc88ced41955ea1987f5
    kind: create
    at: 2026-09-20T06:22:52.232Z
    entryIds:
      - inv-1
      - dec-1
      - ver-1
      - prog-1
  7478e635f86b6c02660b7acd0ad876d9f247a82e1ced6a5fcb3942bf46e4b6c6:
    fingerprint: bd6845b505aea571febea0a8767b4677abbbf51a0bc3aedc23f179c90249dec3
    kind: update
    at: 2026-09-20T07:16:51.427Z
    entryIds:
      - prog-2
      - prog-3
      - dec-2
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
  fdf88880ad7e1c6e7cacf104d76b5dfbab465df3e4be18612c25d780ebdea296:
    fingerprint: 1ec7fadb43aff80d86aa57756dbc16b8cb4e3b3a17888de94fbce1b022266c31
    kind: update
    at: 2026-09-20T08:31:39.162Z
    entryIds:
      - prog-4
      - prog-5
      - prog-6
      - ver-ac5b
      - ver-native-1
      - gap-1
  5e2b2f1ce4e969c13a19d8f25dffed55e58e41e95b3978f5df4ad380aea2a0b4:
    fingerprint: 1d788509ad5cc99184c0caec58360f1045f563bbd197882fa1ab0a3951e63145
    kind: update
    at: 2026-09-21T03:32:26.238Z
    entryIds:
      - dec-3
      - prog-7
      - ver-ac5c
      - ver-native-2
      - prog-8
      - prog-9
  6898823c4078c3583d375ba4149e15d620c9b9edc23ab2431775447bd4ab04fc:
    fingerprint: 5ade210e7e7367f76ac1ccde9acd7720a3ecb3e25a24b47c7f3a9ef6592d3b7e
    kind: update
    at: 2026-09-21T03:36:47.279Z
    entryIds:
      - prog-10
  f07954bdb990870294444de188c3c57c7985cd3e8a1ef216df7b7b5cd6c96f85:
    fingerprint: 5171a871b231d30a782669970817310abf15652e64f255eb1b359cffaaf75b66
    kind: update
    at: 2026-09-21T05:41:19.656Z
    entryIds:
      - done-1
criterionVersions:
  ac1: 1
  ac2: 1
  ac3: 1
  ac4: 1
  ac5: 1
  ac6: 1
---

资源面板的 commit / push / 分支切换与分支列表已实现、验证并推送：插件 b2d3e28（分支跟随修复）与 24b7ddf（关联远端图标化）、壳 89418fc（原生验收扩展）均已在 origin/master。插件 npm run check 248/248 通过；原生验收在真实 Electron 界面上实际点击并核对了提交、快进推送、分支切换、中英文案、420px 窄窗口与焦点返回，并由此发现并修复了「切换分支后选择器不刷新」的缺陷。.gitignore 幂等修复随 ce099ff 交付。限制与边界：upstream.lock.json 的 project pin 仍是 58d1f6d——按项目约定日常开发不 bump、发布时才 bump，因此本地不带 DSH_PROJECT_PLUGIN_SOURCE 的标准 smoke:resources 会失败（检查脚本断言了 pin 尚未包含的行为），本地验证请带该变量；CI 不运行 smoke:resources，不受影响。壳测试 project-bootstrap-network.test.mjs 在本机沙箱下超时（loopback Git 传输），与本任务无关。
