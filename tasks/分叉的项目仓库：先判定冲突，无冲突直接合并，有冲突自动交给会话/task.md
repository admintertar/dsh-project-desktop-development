---
schemaVersion: 3
directory: 分叉的项目仓库：先判定冲突，无冲突直接合并，有冲突自动交给会话
id: task-664c652d-4527-4379-9254-bfd83ddaf6a5
title: 分叉的项目仓库：先判定冲突，无冲突直接合并，有冲突自动交给会话
objective: 让「项目资产」的更新在项目仓库分叉时也能推进分支：无冲突直接合并（保留合并提交），有冲突则不落地任何改动（工作区与 index 完整回滚、不留 MERGE_HEAD）并自动创建项目会话、把冲突文件清单与约束写进 composer 草稿交给 AI；含 Host/Client 改动、单元测试与原生界面验收。
status: completed
createdAt: 2026-09-22T14:12:39.801Z
updatedAt: 2026-09-22T14:12:52.260Z
artifacts:
  - type: file
    path: artifacts/project-assets-merged.png
    description: 原生验收：分叉且两边改不同文件时，点「更新资源」原地合并，状态变「本地领先 2 个提交」、推送按钮出现，没有跳到会话
  - type: file
    path: artifacts/project-assets-conflict.png
    description: 原生验收：两边改同一文件时点击更新，面板自动切到新会话，composer 草稿里带着冲突文件清单、项目根与分支名
  - type: file
    path: artifacts/smoke-resources-result.json
    description: "smoke:resources 运行结果（ok: true，包含项目资产与资源同步的全部布局测量）"
  - type: commit
    repository: https://github.com/admintertar/dsh-plugin-project
    commit: 2dd22d309f87ef77d30f54299fd15948cab2f990
    description: 插件：分叉时先判定冲突，再决定直接合并还是交给会话（15 文件 +327/-57，本地提交未 push）
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop
    commit: 9e16309fff763ad7746da230133f05441222c5e6
    description: 壳：原生验收覆盖分叉合并与冲突交给会话（本地提交未 push）
archived: false
phase: validation
brief:
  currentBehavior: 项目根与远端分叉时，Host 的 update 只做 fetch + merge --ff-only，对分叉直接拒绝；面板只能提示「请先在 Git 中处理分支分叉」，产品内没有任何出路（轻则灰按钮，重则推送被拒）。
  scope: 插件 Host（resource-sync / resource-api / resource-contract）、Client（ProjectChangesPanel / resource-ui / project-changes-controller / 新增 merge-conflict / index 注入）、中英文案与单测；壳验收脚本 scripts/native-resource-state-checks.mjs。
  constraints:
    - 冲突必须完整回滚：绝不把半合并状态（MERGE_HEAD、冲突标记）留给用户或后续会话
    - 不自动 push；合并结果仍由用户在「项目资产」面板提交与推送
    - 工作区不干净、Git 操作进行中仍然拒绝更新
    - 会话只预填 composer 草稿，不代替用户发送消息
  outOfScope:
    - 提供 rebase 作为合并方式（目前固定 merge，保留合并提交）
    - 由 AI 自动解决冲突并自动提交/推送
    - 资源仓库（非项目根）的冲突交给会话（本次仅项目资产面板）
  acceptanceCriteria:
    - id: ac-1
      text: 项目仓库与远端分叉时，「更新资源」直接合并（保留合并提交）：两边提交都在、工作区干净、状态变为「本地领先 N 个提交」，且不会打开会话
      required: true
      version: 1
    - id: ac-2
      text: 两边改过同一文件时，点击更新不改变仓库（HEAD 不变、无 MERGE_HEAD、工作区干净、无冲突标记），并自动创建项目会话、把冲突文件清单写进 composer 草稿后切过去
      required: true
      version: 1
    - id: ac-3
      text: 两个仓库 yarn check 全绿，原生验收 smoke:resources 在真实 Electron + 真实远端下通过（含上述两个场景）
      required: true
      version: 1
handoff:
  nextSteps:
    - 发布时：先 push 插件 2dd22d3，再把 upstream.lock.json 的 project.commit/tree 指到该提交并重导 .upstream/project，然后 push 壳（当前壳还有另一条未 push 的提交 bc6087c 与 9e16309）
    - 可选后续：把「冲突交给会话」扩展到资源仓库（现在只有项目资产面板）；以及支持 rebase 作为另一种合并方式
    - 可选后续：合并完成后如果需要，可一键推送（目前推送仍需用户手动点）
  readBefore:
    - ref-sync
    - ref-conflict
    - ref-panel
  verifyBefore:
    - ref-smoke
references:
  - id: ref-sync
    label: 插件：分叉合并与冲突回滚（Host）
    type: file
    path: resources/dsh-plugin-project/src/resource-sync.ts
  - id: ref-conflict
    label: 插件：冲突交给会话的准备器
    type: file
    path: resources/dsh-plugin-project/src/client/merge-conflict.ts
  - id: ref-panel
    label: 插件：项目资产面板的更新入口与冲突分发
    type: file
    path: resources/dsh-plugin-project/src/client/ProjectChangesPanel.tsx
  - id: ref-smoke
    label: 壳：原生验收脚本（含分叉合并与冲突场景）
    type: file
    path: resources/dsh-project-desktop/scripts/native-resource-state-checks.mjs
entries:
  - id: e-decision
    kind: progress
    content: 根因与决策：产品过去只做 fetch + merge --ff-only，分叉时没有任何写入路径（全仓库无 merge/rebase 写入），因此既不能更新也不能推送，只能去命令行。用户要求：先判定冲突——无冲突直接合并，有冲突自动开一个会话交给 AI。
    basis: observation
    createdAt: 2026-09-22T14:12:39.801Z
  - id: e-implementation
    kind: progress
    content: 实现：Host 在分叉时执行 merge（保留合并提交），冲突则先读出 unmerged 路径再 merge --abort 完整回滚，并把 {status:'merged'|'conflict', files} 作为动作结果随响应返回；可用性规则扩展为 behind|diverged（dirty/inProgress 仍拒绝）。Client 在更新返回 conflict 时调用新的 MergeConflictController：创建项目会话 → 写 composer 草稿（含冲突清单、项目根、分支、约束）→ 切过去，由用户自己提交给 AI。
    basis: agent-proposal
    createdAt: 2026-09-22T14:12:39.801Z
  - id: v-ac1
    kind: verification
    content: ac-1 验证：单测 resource-sync.test.ts「a diverged branch is merged, keeping both the local and the remote commits」断言返回 {status:'merged'}、HEAD^1 为本地提交、HEAD^2 为远端提交、两边的文件都在、工作区干净；原生验收在真实界面用 loopback HTTPS 远端造分叉（本地提交 local-only.txt / 远端提交 remote-only.txt），点「更新资源」后状态变「本地领先 2 个提交」、面板未跳到会话，截图 artifacts/project-assets-merged.png。
    basis: observation
    verification:
      criterionId: ac-1
      criterionVersion: 1
      method: yarn check（插件 node --test）+ yarn run smoke:resources
      result: passed
      coverage: 单测 + 真实 Electron 界面（zh，1180px）
    createdAt: 2026-09-22T14:12:52.260Z
  - id: v-ac2
    kind: verification
    content: ac-2 验证：单测「a conflicting merge is reported and rolled back completely, never leaving a half-merged tree」断言返回 {status:'conflict', files:['README.md']}、HEAD 不变、无 .git/MERGE_HEAD、git status 干净、文件内容不变，且手工解决后重试可合并；原生验收里两边改同一文件后点更新，断言仓库未被改动（HEAD 不变、无 MERGE_HEAD、status 干净、AGENT.md 仍为本地内容），并且窗口已切到新会话、composer 草稿包含冲突文件 AGENT.md、项目根与分支名，截图 artifacts/project-assets-conflict.png。
    basis: observation
    verification:
      criterionId: ac-2
      criterionVersion: 1
      method: yarn check（插件 node --test）+ yarn run smoke:resources
      result: passed
      coverage: 单测 + 真实 Electron 界面（zh，读实时 DOM 与真实 Git 状态）
    createdAt: 2026-09-22T14:12:52.260Z
  - id: v-ac3
    kind: verification
    content: ac-3 验证：resources/dsh-plugin-project yarn check EXIT=0（typecheck + 285 tests + build，新增 merge-conflict 会话准备器 4 项、控制器返回合并结果、可用性规则）；resources/dsh-project-desktop yarn check EXIT=0；smoke:resources 在真实 Electron + loopback HTTPS Git 远端下 EXIT=0。
    basis: observation
    verification:
      criterionId: ac-3
      criterionVersion: 1
      method: yarn check（两仓库）+ yarn run smoke:resources
      result: passed
      coverage: 两仓库完整 check + 原生验收；日志 dsh-plugin-check3.log、dsh-shell-check2.log、dsh-smoke-merge.log
    createdAt: 2026-09-22T14:12:52.260Z
  - id: e-completion
    kind: completion
    content: 三条验收标准均已通过并留有证据；代码已本地提交（插件 2dd22d3、壳 9e16309），未 push、未 bump lock。开发壳已用本地插件源重建并启动，供用户目视确认。
    basis: agent-proposal
    verificationEntryIds:
      - v-ac1
      - v-ac2
      - v-ac3
    createdAt: 2026-09-22T14:12:52.260Z
operations:
  0b742b05981caa52b22edaff39fe2fd88118257ac434473acce4b824d0d310f1:
    fingerprint: f85f1860ccb9d68d53d481cfde735c013402043cc4befa89644eb22b31843725
    kind: create
    at: 2026-09-22T14:12:39.801Z
    entryIds:
      - e-decision
      - e-implementation
  6755687f47f99cd191d73c77a967d25dfde6289c681b584cb28618b295740eee:
    fingerprint: 43701aa28b8793dd512099566ce5cd40b7d2acf649e55bfd3c16ac3fb8cffc71
    kind: update
    at: 2026-09-22T14:12:52.260Z
    entryIds:
      - v-ac1
      - v-ac2
      - v-ac3
      - e-completion
criterionVersions:
  ac-1: 1
  ac-2: 1
  ac-3: 1
---

项目仓库分叉时不再是死路：点「更新资源」会先判定冲突——无冲突直接 merge（保留合并提交，两边提交都在、工作区干净、状态变「本地领先 N 个提交」）；有冲突则先读出 unmerged 路径、再 merge --abort 完整回滚，绝不留下半合并状态，并自动创建项目会话、把冲突清单/项目根/分支与「不 push、保留双方改动」的约束写进 composer 草稿后切过去，由用户自己提交给 AI。改动：插件 2dd22d3（15 文件，+327/-57，未 push）、壳 9e16309（验收脚本，未 push）。验证：插件 yarn check EXIT=0（285 tests，含分叉合并、冲突回滚、会话准备器 4 项、控制器返回合并结果）；壳 yarn check EXIT=0；原生 smoke:resources 在真实 Electron + loopback HTTPS 远端下 EXIT=0，两个场景均读实时 DOM 与真实 Git 状态并留截图。未覆盖（见 outOfScope）：rebase 选项、资源仓库的冲突交接、AI 自动解决后自动提交/推送。
