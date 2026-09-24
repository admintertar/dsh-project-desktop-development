---
schemaVersion: 3
directory: 资源标签悬停气泡去掉重复的「本地领先 n 个提交」计数行
id: task-51293d08-178a-4618-9ec6-a2302f33e504
title: 资源标签悬停气泡去掉重复的「本地领先 n 个提交」计数行
objective: 资源卡片与项目资产面板的同步标签在「本地领先 n 个提交」状态下，悬停气泡只列领先的具体提交，不再重复标签已经写着的计数文案「本地领先 n 个提交」；超过上限仍以「另有 n 个本地提交」收尾，其他状态悬停文案不变。含插件纯函数改动、单测/类型/构建、壳原生悬停断言与中英双语截图验收。
status: completed
createdAt: 2026-09-24T10:10:06.055Z
updatedAt: 2026-09-24T10:11:16.126Z
artifacts:
  - type: file
    path: artifacts/report.md
    description: 验收报告：改动、验证命令与结果、证据清单、pin/push 注意事项与未覆盖项
  - type: file
    path: artifacts/resource-ahead-commits-tooltip-zh.png
    description: 原生验收截图（中文）：标签仍写「本地领先 1 个提交」，气泡只显示 a74938a panel commit
  - type: file
    path: artifacts/resource-ahead-commits-tooltip-en.png
    description: 原生验收截图（英文）：标签仍写「1 local commits」，气泡只显示 a74938a panel commit
  - type: file
    path: artifacts/result.json
    description: "smoke:resources 结果（ok: true，含各语言/主题/宽度布局测量）"
  - type: commit
    repository: https://github.com/admintertar/dsh-plugin-project
    commit: 4633866e9bec79038dd09be84876b0718d56ba4f
    description: 插件：resourceSyncTooltip 不再重复标签计数行（resource-ui.ts + tests/client-resources.test.ts，主工作树精确暂存提交，未 push）
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop
    commit: 12d553aa3319f13060f2a695fcf302ad763bf2d3
    description: 壳：原生悬停断言改为严格等于「<短 hash> <标题>」（scripts/native-resource-state-checks.mjs，未 push）
archived: false
phase: validation
brief:
  currentBehavior: resourceSyncTooltip 在 ahead 且拿到领先提交时返回「标签\n每条提交一行」，气泡第一行与标签文案重复（截图 red box 所指）。
  scope: 插件 src/client/resource-ui.ts 的 resourceSyncTooltip 输出与 tests/client-resources.test.ts 断言；壳 scripts/native-resource-state-checks.mjs 的悬停原生断言与截图。
  constraints:
    - 复用官方 Tooltip 与既有 resourceSyncTooltip，不新造控件
    - Host 侧 aheadCommits 契约与读取逻辑不变
    - 验证脚本断言改动可在主工作树直接提交，产品代码在独立 worktree 修改
  outOfScope:
    - Host 读取领先提交的上限与失败兜底
    - 标签文案 resourceSyncAhead 与 tone
    - upstream.lock.json 的插件 pin bump（需与 push 同一动作）
  acceptanceCriteria:
    - id: hover-commits-only
      text: ahead 状态悬停气泡只列领先提交（每条一行），不再出现标签文案「本地领先 n 个提交」；超过上限仍以「另有 n 个本地提交」收尾
      required: true
      version: 1
    - id: tag-unchanged
      text: 资源卡片与项目资产面板的标签文案、tone 与其余状态的「标签 · 说明」悬停均不变
      required: true
      version: 1
    - id: automated
      text: resources/dsh-plugin-project 的 yarn check（typecheck + test + build）通过
      required: true
      version: 1
    - id: native-acceptance
      text: 原生验收：真实窗口悬停资源卡片 ahead 标签，气泡文本严格等于「<短 hash> <标题>」且标签仍显示计数，中英各一张截图
      required: true
      version: 1
handoff:
  nextSteps:
    - push 插件 4633866 → 把 upstream.lock.json 的 project.commit/tree 指到它（tree 用 git rev-parse 4633866^{tree}）→ 删除 .upstream/project 后重导快照 → verify:upstream → 再 push 壳 12d553a，否则 CI 的 Verify Resources on Windows 会用壳+旧插件跑新断言而失败
    - 如需更强证据：补一张项目资产面板标签悬停的原生截图，以及暗色/420px 窄窗口下的气泡布局核对
  readBefore:
    - report
    - tooltip-src
    - smoke-script
  verifyBefore:
    - resources/dsh-plugin-project 的 yarn check
    - DSH_PROJECT_PLUGIN_SOURCE=<插件树> resources/dsh-project-desktop 的 yarn smoke:resources
references:
  - id: report
    label: 验收报告
    type: file
    path: tasks/资源标签悬停气泡去掉重复的「本地领先 n 个提交」计数行/artifacts/report.md
  - id: tooltip-src
    label: resourceSyncTooltip 实现
    type: file
    path: resources/dsh-plugin-project/src/client/resource-ui.ts
  - id: smoke-script
    label: 壳原生悬停断言
    type: file
    path: resources/dsh-project-desktop/scripts/native-resource-state-checks.mjs
entries:
  - id: scope-confirmed
    kind: decision
    content: 确认改动范围：只去掉悬停气泡里的「本地领先 n 个提交」这一行，卡片上的橙色标签保持原样（用户选择）。
    basis: agent-proposal
    reason: 截图红框圈的是气泡首行，且用户强调「鼠标移动过去之后悬浮显示」，存在「也改标签」的另一种解读，故先确认。
    createdAt: 2026-09-24T10:10:06.055Z
  - id: impl
    kind: progress
    content: resourceSyncTooltip 去掉提交列表非空时的 label 首行：气泡变为「每条提交一行（+ 超出时另有 n 个本地提交）」；resourceSyncLabel 与卡片 Tag 文案未改。同步改 tests/client-resources.test.ts 两条 ahead 断言与用例名。
    basis: observation
    createdAt: 2026-09-24T10:10:06.055Z
  - id: verify-automated
    kind: verification
    content: 独立 worktree（/Volumes/DATA/work-space2/com.github.public/wt-dsh-sync-tooltip，node_modules/.yarn 软链主树）内 yarn check → EXIT=0，308 个测试全通过（/tmp/plugin-check-tooltip.log）。
    basis: observation
    verification:
      criterionId: automated
      criterionVersion: 1
      method: yarn check（Yarn 4.18.0，node 22.19.0）
      result: passed
      coverage: typecheck、全部单测（含新断言：ahead 无 label 首行、截断收尾、其他状态 label · description）与构建
    createdAt: 2026-09-24T10:10:06.055Z
  - id: verify-native
    kind: verification
    content: "DSH_PROJECT_PLUGIN_SOURCE=<worktree> yarn build 后 yarn smoke:resources → EXIT=0、ok: true；断言气泡 textContent 严格等于 `<hash> panel commit`（中英各一次），截图为 zh/en 各一张，均只见提交行、标签仍显示计数。worktree 源码与提交 4633866 的两文件 git hash-object 逐字节相同。"
    basis: observation
    verification:
      criterionId: native-acceptance
      criterionVersion: 1
      method: 原生冒烟 scripts/smoke-resource-states.mjs（executeJavaScript 读实时 DOM + capturePage）
      result: passed
      coverage: 真实 Electron 窗口、真实资源卡片上的中英双语悬停；未覆盖项目资产面板标签与暗色/窄窗口气泡布局
    createdAt: 2026-09-24T10:10:06.055Z
  - id: verify-tag
    kind: verification
    content: 卡片标签与其余状态的悬停未改：resourceSyncLabel / Tag 渲染未触碰；tests/client-resources.test.ts 断言 current、ahead 无列表与 undefined 仍返回「label · description」，原生截图里标签仍显示「本地领先 1 个提交」/「1 local commits」。
    basis: observation
    verification:
      criterionId: tag-unchanged
      criterionVersion: 1
      method: yarn test 断言 + 原生截图人工比对
      result: passed
      coverage: 纯函数断言 + 原生截图核对标签文案与 tone 未变
    createdAt: 2026-09-24T10:10:06.055Z
  - id: commits
    kind: progress
    content: 插件提交 4633866（src/client/resource-ui.ts + tests/client-resources.test.ts，主工作树精确暂存提交）；壳提交 12d553a（仅 scripts/native-resource-state-checks.mjs）。验收后用不带 DSH_PROJECT_PLUGIN_SOURCE 的 yarn build 把壳 .cache/runtime 复原为锁定插件构建，worktree 与分支已删除。两提交均未 push。
    basis: observation
    createdAt: 2026-09-24T10:10:06.055Z
  - id: done
    kind: completion
    content: 全部必选验收标准通过：气泡只列提交、标签未变、插件 yarn check 通过、原生中英双语悬停断言与截图。唯一未完成项：壳原生断言已要求新插件，需在 push 时把 upstream.lock.json 的 project pin 从 d45b54f bump 到 4633866 并重导快照，否则 CI 的 Verify Resources on Windows 会用壳+旧插件跑新断言而失败。
    basis: observation
    verificationEntryIds:
      - verify-automated
      - verify-native
      - verify-tag
    createdAt: 2026-09-24T10:10:06.055Z
  - id: verify-hover-only
    kind: verification
    content: ahead 状态气泡不再出现标签文案：单测断言 resourceSyncTooltip({status:'ahead',ahead:2,aheadCommits:[first,second]}) 严格等于 `aaaaaaa first\nbbbbbbb second`（无 label 首行）；截断用例尾部为 resourceSyncAheadMore；壳原生断言用 textContent 严格相等（expected 不含 label），因此标签计数行一旦回归就会失败。
    basis: observation
    verification:
      criterionId: hover-commits-only
      criterionVersion: 1
      method: yarn check（tests/client-resources.test.ts）+ yarn smoke:resources 严格相等断言
      result: passed
      coverage: 纯函数单测 + 真实窗口原生断言双重覆盖；未覆盖超过 20 条时的原生多行气泡
    createdAt: 2026-09-24T10:11:16.126Z
  - id: evidence-landed
    kind: verification
    content: 验收证据已从壳仓库被忽略的 .runtime/resource-states-y4dzB0 落盘到任务 artifacts：报告 + 中英两张悬停截图 + result.json（共 4 个文件，~320 KB），报告里的文件均真实存在；探针运行期目录未进任务目录。
    basis: observation
    verification:
      criterionId: native-acceptance
      criterionVersion: 1
      method: 文件拷贝 + read_image 阅图 + 文件清单核对
      result: passed
      coverage: 证据落盘与索引一致性；截图内容经人工阅图核对（标签保留、气泡只有提交行）
    createdAt: 2026-09-24T10:11:16.126Z
  - id: done-final
    kind: completion
    content: 四条必选验收标准均通过（气泡只列提交、标签未变、yarn check、原生中英悬停）；提交为插件 4633866 与壳 12d553a（均未 push），后续 push 时需同步 bump upstream.lock.json 的插件 pin。
    basis: observation
    verificationEntryIds:
      - verify-hover-only
      - verify-automated
      - verify-native
      - verify-tag
      - evidence-landed
    createdAt: 2026-09-24T10:11:16.126Z
operations:
  8c52353e868a45fc1a04ab8bb7757fe4cde0502beaf9f1a22504e9f27a423e6e:
    fingerprint: 932f213b6d3d9f152b5dd3a2f017a93bb9ab0409ab3971c51e840a2f0eac6250
    kind: create
    at: 2026-09-24T10:10:06.055Z
    entryIds:
      - scope-confirmed
      - impl
      - verify-automated
      - verify-native
      - verify-tag
      - commits
      - done
  12d5ffc313d1839deca2d4f9bed8836d394d027ae83cb9265bf1cc040add7e41:
    fingerprint: 06cc6ff08ff8b03587c31c1b14db8b43cf88e90cee92b74cc7c435b9969cb26b
    kind: update
    at: 2026-09-24T10:11:16.126Z
    entryIds:
      - verify-hover-only
      - evidence-landed
      - done-final
criterionVersions:
  hover-commits-only: 1
  tag-unchanged: 1
  automated: 1
  native-acceptance: 1
---

已实现并验收：resourceSyncTooltip 在 ahead 拿到提交列表时不再输出标签首行，气泡只列提交（超出 20 条以「另有 n 个本地提交」收尾）；卡片标签文案未改。插件 yarn check 通过（308 测试），真实 Electron 窗口原生悬停断言与中英截图通过。插件 4633866、壳 12d553a 均已提交未 push；push 时需同时把 upstream.lock.json 的插件 pin bump 到 4633866 并重导快照。
