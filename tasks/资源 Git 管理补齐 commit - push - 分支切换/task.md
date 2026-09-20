---
schemaVersion: 3
directory: 资源 Git 管理补齐 commit - push - 分支切换
id: task-2646c970-8b9e-4c35-ab93-6f5fec4ede12
title: 资源 Git 管理补齐 commit / push / 分支切换
objective: 让资源面板能直接处理本地领先、未提交改动和分支切换，不必切到外部 Git 客户端；同时修复会污染资源仓库的 .gitignore 幂等缺陷。
status: active
createdAt: 2026-09-20T06:22:52.232Z
updatedAt: 2026-09-20T08:31:39.162Z
artifacts: []
archived: false
phase: implementation
brief:
  currentBehavior: 资源只支持 check（fetch 并报告状态）与 update（fetch + 仅快进合并）。面板能显示 dirty / ahead / diverged / in-progress，但唯一可用的 update 在这些状态下被明确拒绝，因此这些状态无法在产品内处理。
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
    - 扩展 native-resource-state-checks.mjs 覆盖新控件：展开资源详情、输入提交信息、断言提交/推送/分支选择的存在与禁用态、中英文案、窄窗口无横向溢出、弹窗关闭后焦点返回
    - 决定是否提交壳侧的 upstream.lock.json pin 更新（当前未提交，壳工作树只有这一个改动）
    - 两个仓库的提交均未推送，需用户明确要求后才推
    - 可选：用官方 DiffBlock 在提交前预览将提交的改动（官方已有能力，本插件已在 TaskCommitPreview 复用）
  readBefore:
    - file-sync
    - file-ui
    - file-card
    - note-pin
  verifyBefore:
    - note-verify
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
criterionVersions:
  ac1: 1
  ac2: 1
  ac3: 1
  ac4: 1
  ac5: 1
  ac6: 1
---


