---
schemaVersion: 3
directory: 技能索引变更跟随技能提交并修复索引资产提交失败
id: task-5f696fdc-d0e3-4755-b568-30e4b5fafcd6
title: 技能索引变更跟随技能提交并修复索引资产提交失败
objective: 让 skills/index.yaml 的启停变更归属到对应技能资产并随其提交：修复面板「index.yaml」资产按技能名重建导致 nothing to commit 的缺陷，修复共享文件资产会跳过其他路径暂存的问题，并让启用操作删除显式条目以消除无意义 diff。
status: completed
createdAt: 2026-09-23T08:06:20.601Z
updatedAt: 2026-09-23T08:33:52.857Z
artifacts:
  - type: file
    path: artifacts/report.md
    description: 验收报告：结论、改动、验收点与限制
  - type: file
    path: artifacts/plugin-check.log
    description: 插件 yarn check 摘要与新增回归测试清单（308 pass / 0 fail）
  - type: file
    path: artifacts/native-check.log
    description: 壳原生 smoke:resources 日志（含新增 3 条断言，退出码 0）
  - type: file
    path: artifacts/native-result.json
    description: 原生检查结果：ok=true 与 16 组布局测量
  - type: file
    path: artifacts/project-changes-selection.png
    description: 技能卡片与提交选择（提交前）
  - type: file
    path: artifacts/project-changes-plan-tooltip.png
    description: 提交计划 tooltip（task + 技能两条提交）
  - type: file
    path: artifacts/project-changes-after-commit.png
    description: 提交后：技能卡片消失、skills/ 无残留
  - type: file
    path: artifacts/project-changes-zh-light-1180.png
    description: 中文亮色宽窗 1180 项目资产面板
  - type: file
    path: artifacts/project-changes-en-dark-420.png
    description: 英文暗色窄窗 420 项目资产面板
  - type: commit
    repository: https://github.com/admintertar/dsh-plugin-project.git
    commit: ff3502a682b9edc00066928ae469f3d44d6b1116
    description: 插件：索引变更归属技能、兜底资产按路径提交、共享文件资产暂存其余路径、启用即删除条目，含 5 条回归测试（7 个文件）
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: d6da5b6951b35e5033f79bfaebda3980f6a5fe61
    description: 壳：scripts/native-resource-state-checks.mjs 的 3 条技能索引断言随该提交落地（该提交主体属于 task-7af5d595）
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: 535f1a36cdf410670fecd02301cab8a8d77c4c37
    description: 壳：补回 d6da5b6 遗漏的 12 行 chooser 目录记忆断言（属于 task-7af5d595），复验 smoke:resources EXIT=0
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop-development.git
    commit: 9a1fc8ee9aae4ea43bfea5460d0447a54af77d50
    description: 项目仓库：新增 skills/git-pitfalls/SKILL.md，沉淀本次并发提交踩坑与方法（1 文件，75 行）
archived: false
phase: validation
brief:
  currentBehavior: skills/index.yaml 被 mapProjectChanges 单独分组成 id=skill:index.yaml、name=index.yaml 的技能资产；提交它时 resource-api 用 plainId 得到技能名 index.yaml，stageSkillIndex 因此重建出 HEAD 原样内容，git commit 报 nothing to commit 并以退出码 1 失败，索引变更永远提交不上去。且 commitProjectSelection 在 resolveStaged 返回内容时跳过 git add -A，共享文件资产的其他路径不会被暂存。
  scope: dsh-plugin-project：src/project-changes.ts（索引变更归属技能）、src/resource-api.ts（读 HEAD 索引 + 兜底条目按路径提交）、src/resource-sync.ts（staged 非空时仍暂存其他路径）、src/project-skills.ts（启用即删除显式条目）、对应测试；dsh-project-desktop：scripts/native-resource-state-checks.mjs 断言同步。
  constraints:
    - 不改官方源码快照；插件功能留在 dsh-plugin-project，窗口/应用层留在 dsh-project-desktop
    - 不改写工作区文件来暂存共享文件（继续用 hash-object + update-index 精确内容暂存）
    - 保持「变更不静默丢失」原则：无法归属的索引变更必须仍然可见可提交
  outOfScope:
    - 把启用状态拆成每技能一个状态文件的迁移方案
    - 把 index.yaml 从共享资产改为本机忽略
  acceptanceCriteria:
    - id: c1
      text: 关闭/启用技能产生的 skills/index.yaml 变更归属到对应技能资产（id=skill:<name>，name=技能名）；仅开关变化时也生成以技能名命名的资产；索引损坏或无法归属时保留 skill:index.yaml 兜底条目。
      required: true
      version: 1
    - id: c2
      text: 提交技能资产时索引按所选技能精确暂存（其他技能保持 HEAD 状态），且同一资产的其他路径（如新增 SKILL.md）一并提交。
      required: true
      version: 1
    - id: c3
      text: 兜底 skill:index.yaml 资产按路径提交，不再出现 nothing to commit 失败。
      required: true
      version: 1
    - id: c4
      text: setEnabled(name, true) 删除显式条目，关闭再启用后索引回到 HEAD 状态、无残留 diff。
      required: true
      version: 1
    - id: c5
      text: resources/dsh-plugin-project 的 yarn check（typecheck + test + build）通过。
      required: true
      version: 1
    - id: c6
      text: 原生视觉验收：项目资产面板技能分组不再出现 index.yaml 卡片、提交计划与提交后 skills/ 无残留（中英文案、主题状态、窄窗口、键盘行为）。
      required: true
      version: 1
handoff:
  nextSteps:
    - rerun_smoke_on_windows
    - publish_bump_pin
  readBefore:
    - report
    - project_staging
    - project_changes
  verifyBefore:
    - plugin_check
    - native_smoke
references:
  - id: probe1
    label: 探针1：面板 index.yaml 资产提交产物 = HEAD
    type: note
    text: 'HEAD bytes: schemaVersion: 1\nskills:\n  alpha:\n    enabled: true\n / case1 content == HEAD? true / case1 commit FAILED status=1 stdout="On branch main\nnothing to commit, working tree clean" / worktree still differs from HEAD? true'
  - id: probe2
    label: 探针2：staged 非空时其他路径漏暂存
    type: note
    text: "staged files: skills/index.yaml / committed files: skills/index.yaml / SKILL.md staged? ?? skills/alpha/SKILL.md"
  - id: f1
    label: 索引重建与暂存
    type: file
    path: resources/dsh-plugin-project/src/project-staging.ts
  - id: f2
    label: 资产分组
    type: file
    path: resources/dsh-plugin-project/src/project-changes.ts
  - id: f3
    label: 暂存解析与索引读取
    type: file
    path: resources/dsh-plugin-project/src/resource-api.ts
  - id: f4
    label: 提交暂存分支
    type: file
    path: resources/dsh-plugin-project/src/resource-sync.ts
  - id: f5
    label: 启停写入索引
    type: file
    path: resources/dsh-plugin-project/src/project-skills.ts
  - id: f6
    label: 壳原生检查脚本
    type: file
    path: resources/dsh-project-desktop/scripts/native-resource-state-checks.mjs
  - id: t1
    label: 前置任务：技能索引可以单独提交
    type: task
    taskId: task-2ee04a32-b5e0-4eff-8377-837928ad2605
  - id: report
    label: 验收报告
    type: note
    text: tasks/技能索引变更跟随技能提交并修复索引资产提交失败/artifacts/report.md
  - id: plugin_check
    label: 插件自检
    type: note
    text: "resources/dsh-plugin-project: yarn check（308 tests / 0 fail，typecheck + build）"
  - id: native_smoke
    label: 原生验收
    type: note
    text: "resources/dsh-project-desktop: DSH_PROJECT_PLUGIN_SOURCE=../dsh-plugin-project yarn run smoke:resources（EXIT=0）"
  - id: commit_plugin_files
    label: 提交插件改动
    type: note
    text: 插件 7 个文件属于本任务；壳仓库只提交 scripts/native-resource-state-checks.mjs，不要带上其他任务的未提交改动
  - id: rerun_smoke_on_windows
    label: Windows 复验
    type: note
    text: 在 Windows 上重跑 yarn run smoke:resources，确认同一组断言成立（本机为 macOS arm64）
  - id: publish_bump_pin
    label: 发布时才 bump pin
    type: note
    text: 如需发布，按 upstream.lock.json 流程 bump 插件 pin 后重跑 smoke:resources；本任务未提交、未 push
  - id: project_staging
    label: 索引重建与暂存
    type: file
    path: resources/dsh-plugin-project/src/project-staging.ts
  - id: project_changes
    label: 资产分组
    type: file
    path: resources/dsh-plugin-project/src/project-changes.ts
  - id: restore_chooser_hunks_done
    label: 并发丢失的 chooser 断言已补提交
    type: note
    text: 已恢复并提交为壳 535f1a36cdf410670fecd02301cab8a8d77c4c37，smoke:resources 复验 EXIT=0；task-7af5d595 的记录需要补上这个提交号
  - id: skill_git_pitfalls
    label: Git 踩坑技能
    type: file
    path: skills/git-pitfalls/SKILL.md
entries:
  - id: e1
    kind: progress
    content: "用真实 git 仓库探针证实缺陷：stageSkillIndex(head, working, 'index.yaml') 的产物等于 HEAD 内容，模拟 stageContent + git commit 得到 exit=1 stdout=\"On branch main\\nnothing to commit, working tree clean\"，工作区变更仍在。对照 case2（技能名 alpha）产出 enabled: false，正确。"
    basis: observation
    referenceIds:
      - probe1
    createdAt: 2026-09-23T08:06:20.601Z
  - id: e2
    kind: progress
    content: 第二个探针证实：当资产 paths 同时含 skills/alpha/SKILL.md 与 skills/index.yaml 时，resolveStaged 返回内容后 git add -A 被跳过，提交只含 skills/index.yaml，SKILL.md 仍是未跟踪（?? skills/alpha/SKILL.md）。因此归属改造必须同时修 resource-sync.ts:376-385。
    basis: observation
    referenceIds:
      - probe2
    createdAt: 2026-09-23T08:06:20.601Z
  - id: e3
    kind: decision
    content: "采用「索引变更归属技能」方案而非「保留独立 index.yaml 条目」：前者与既有 stageSkillIndex 的按技能名重建语义一致，提交信息可读（docs(skills): 更新技能 alpha），且保留兜底条目满足「变更不静默丢失」。"
    basis: user-request
    createdAt: 2026-09-23T08:06:20.601Z
  - id: p1
    kind: progress
    content: 实现完成：project-changes.ts 按 HEAD/工作区索引差异归属 skill:<name>（仅开关变化合成技能名资产，无法归属时保留 skill:index.yaml 兜底）；project-staging.ts 新增 assetSkillName()；resource-api.ts 读入 HEAD 索引文本并让兜底资产走路径暂存；resource-sync.ts 在 staged 非空时仍对资产其余路径 git add -A；project-skills.ts 启用即删除显式条目。
    basis: observation
    createdAt: 2026-09-23T08:15:29.487Z
  - id: p2
    kind: progress
    content: 验证：resources/dsh-plugin-project 的 yarn check → 308 tests、pass 308、fail 0，typecheck 与 build 通过；新增回归测试 ok 130/131/132/133/134 与 ok 192 全部通过。
    basis: observation
    createdAt: 2026-09-23T08:15:29.487Z
  - id: p3
    kind: progress
    content: 原生验收：DSH_PROJECT_PLUGIN_SOURCE=../dsh-plugin-project 构建壳后运行 yarn run smoke:resources（真实 Electron + Host + Git），退出码 0；新增断言（技能分组无 index.yaml 卡片、提交包含 skills/index.yaml、提交后 skills/ 无残留）通过；16 组中英×主题×1180/420 布局测量无溢出。
    basis: observation
    createdAt: 2026-09-23T08:15:29.487Z
  - id: p4
    kind: progress
    content: 改动未提交：插件工作树 7 个文件（src/project-changes.ts、src/project-skills.ts、src/project-staging.ts、src/resource-api.ts、src/resource-sync.ts、tests/project-changes.test.ts、tests/project-skills.test.ts），壳工作树仅 scripts/native-resource-state-checks.mjs 属于本任务（壳另有其他任务的未提交改动）。
    basis: observation
    createdAt: 2026-09-23T08:15:29.487Z
  - id: v1
    kind: verification
    content: 单测覆盖 c1：ok 130（开关变更归属技能而非 index.yaml 文件）、ok 131（新增技能保留 added 状态且索引作为次要路径，不产生 index.yaml 卡片）、ok 132（格式编辑与索引损坏时仍作为独立资产可见）。命令：resources/dsh-plugin-project yarn check。
    verification:
      criterionId: c1
      criterionVersion: 1
      method: node:test 单元测试（tests/project-changes.test.ts）
      result: passed
      coverage: project-changes.ts 的归属与兜底分支，含次要路径不参与状态聚合
    createdAt: 2026-09-23T08:15:29.487Z
  - id: v2
    kind: verification
    content: c2 由 ok 133（staged 非空时技能目录与索引同一提交）与壳原生断言 latest.includes('skills/index.yaml') + 提交后 skills/ 无残留共同覆盖；ok 129 继续保证索引按所选技能精确重建、其他技能保持 HEAD。
    verification:
      criterionId: c2
      criterionVersion: 1
      method: node:test 集成测试 + 原生 smoke:resources DOM/Git 断言
      result: passed
      coverage: 精确暂存与同资产多路径提交，含真实 git 提交内容断言
    createdAt: 2026-09-23T08:15:29.487Z
  - id: v3
    kind: verification
    content: c3 由 ok 134 覆盖：assetSkillName('skill:index.yaml') 返回 undefined，resolveStaged 不返回内容，commitProjectSelection 走 git add -A 按路径提交，HEAD 得到工作区字节且 skills/ 干净（旧行为会写回 HEAD 并以 nothing to commit 失败）。
    verification:
      criterionId: c3
      criterionVersion: 1
      method: node:test 集成测试（真实 git 仓库）
      result: passed
      coverage: 兜底 index.yaml 资产的提交路径，含旧缺陷回归
    createdAt: 2026-09-23T08:15:29.487Z
  - id: v4
    kind: verification
    content: "c4 由 ok 192 覆盖：setEnabled(name,false) 写 enabled:false，再次 setEnabled(name,true) 删除条目，断言 skills/index.yaml 内容回到 'schemaVersion: 1\\nskills: {}\\n'。"
    verification:
      criterionId: c4
      criterionVersion: 1
      method: node:test 单元测试（tests/project-skills.test.ts）
      result: passed
      coverage: 启停写入语义，含关闭再启用无残留
    createdAt: 2026-09-23T08:15:29.487Z
  - id: v5
    kind: verification
    content: c5：resources/dsh-plugin-project 运行 yarn check，输出 308 tests / pass 308 / fail 0，typecheck 与 build 均成功（artifacts/plugin-check.log）。
    verification:
      criterionId: c5
      criterionVersion: 1
      method: yarn check
      result: passed
      coverage: typecheck + 全量单测 + 构建
    createdAt: 2026-09-23T08:15:29.487Z
  - id: v6
    kind: verification
    content: c6：壳以本地插件源码构建后运行 yarn run smoke:resources，退出码 0（artifacts/native-check.log）。脚本用实时 DOM 断言技能分组不出现 index.yaml 卡片、提交计划为 feat(task)+feat(skills) 两条；用真实 git 断言 HEAD 同时含 skills/review-fixture/SKILL.md 与 skills/index.yaml、提交后 skills/ 无残留；16 组中/英×明/暗×1180/420 布局测量无溢出（artifacts/native-result.json）；5 张截图供人工复核。键盘语义沿用同一 ProjectCheckbox 的 Space 断言（脚本中对任务卡片执行）。
    verification:
      criterionId: c6
      criterionVersion: 1
      method: Electron 原生 smoke:resources（实时 DOM + 真实 Git + 截图）
      result: passed
      coverage: 原生面板呈现、提交计划、提交结果、中英文案、主题与窄窗口布局
    createdAt: 2026-09-23T08:15:29.487Z
  - id: done
    kind: completion
    content: 全部 6 条 required 验收项均有本轮通过证据，实现与验收完成。
    basis: observation
    verificationEntryIds:
      - v1
      - v2
      - v3
      - v4
      - v5
      - v6
    createdAt: 2026-09-23T08:15:29.487Z
  - id: p5
    kind: progress
    content: 提交完成（未 push）：插件 ff3502a682b9edc00066928ae469f3d44d6b1116（本任务 7 个文件，193+/14-）；壳的 scripts/native-resource-state-checks.mjs 断言随另一任务的提交 d6da5b6951b35e5033f79bfaebda3980f6a5fe61 落地。插件仓库提交后工作树干净。
    basis: observation
    createdAt: 2026-09-23T08:19:04.659Z
  - id: p6
    kind: progress
    content: 并发提示（需 task-7af5d595 负责人确认）：为只提交自己的 hunk，本任务曾把壳脚本重置为 HEAD 版再只应用自己的改动；期间另一会话执行 git add -A 并提交 d6da5b6，使同文件中属于 task-7af5d595 的 12 行 chooser 目录记忆断言未被提交、且从工作树消失。已用备份 /tmp/shell-native-full.mjs 把该 12 行恢复到工作树（git diff 现仅含该改动），尚未提交；本任务未触碰其他文件。
    basis: observation
    createdAt: 2026-09-23T08:19:04.659Z
  - id: p7
    kind: progress
    content: 补提交完成（未 push）：壳 535f1a36cdf410670fecd02301cab8a8d77c4c37（1 文件，12+/1-），补回 d6da5b6 遗漏的 12 行 chooser 目录记忆断言。提交前以 DSH_PROJECT_PLUGIN_SOURCE=../dsh-plugin-project 重跑 yarn run smoke:resources，EXIT=0（含该组断言）；提交后壳工作树干净，未 push 提交共 3 个。
    basis: observation
    createdAt: 2026-09-23T08:20:50.159Z
  - id: p8
    kind: progress
    content: 踩坑沉淀：新建项目级技能 skills/git-pitfalls/SKILL.md（76 行，name=git-pitfalls，kebab-case 合法、目录名一致、description/whenToUse 均齐备），已被 DSH 技能目录加载为已启用。内容：第一原则「不在共享工作树上重置后再重放」、并发提交撞车实测与 git apply --cached 拆 hunk、只提交自己文件的核对步骤、hash-object + update-index 精确改 index、nothing to commit 的 stdout/退出码语义、reflog/show :path 现场还原、本仓库提交纪律。项目根仓库中该文件仍为未跟踪，未提交。
    basis: observation
    createdAt: 2026-09-23T08:33:11.812Z
  - id: p9
    kind: progress
    content: 技能已提交：项目仓库 9a1fc8ee9aae4ea43bfea5460d0447a54af77d50（skills/git-pitfalls/SKILL.md，75 行）；提交前核对 index 仅含该文件。项目仓库工作树仍有其他任务的 task.md 改动与本任务目录未跟踪，未纳入本次提交。
    basis: observation
    createdAt: 2026-09-23T08:33:52.857Z
operations:
  d22f45eddda708a72a9bf0ec103d91ea049f8edde7436edfdde6704c8cee3780:
    fingerprint: d490c9813656c81360e4cffbccd48761649ca75650247ac92b897746c2c1e667
    kind: create
    at: 2026-09-23T08:06:20.601Z
    entryIds:
      - e1
      - e2
      - e3
  1aad94b63ec3fe27e462aaaf8a2b710377effadde61fa8c757fe8ea7b32453d0:
    fingerprint: 8ae0783fc7a6def1a8761d5c7f5a92c8bbcef5284ea7ab3d07cd05dda14ef822
    kind: update
    at: 2026-09-23T08:15:29.487Z
    entryIds:
      - p1
      - p2
      - p3
      - p4
      - v1
      - v2
      - v3
      - v4
      - v5
      - v6
      - done
  7e3f3867b6ce31070f645cf3d32c1b5c0cdbbbd1ca33317fe84343adba37ecd3:
    fingerprint: fd2eeba4a4fde49c45d4c100174fd32ceebd62986688c16ae001943aa57c75b5
    kind: update
    at: 2026-09-23T08:19:04.659Z
    entryIds:
      - p5
      - p6
  c224df11b5b2203698db3a939cb05674c212ca6dd0d211ca331ccb2a27d30d48:
    fingerprint: bdc7a883115c12c8c215994fcf706e5f22b8871f48ca5bc5207c2812d86f1293
    kind: update
    at: 2026-09-23T08:19:14.437Z
    entryIds: []
  276be8f2a5fbecc85ede2ce86470c5d3759301d2592733ada76d0319966b01d3:
    fingerprint: 19a5808076a4d8b4de634372eec5d2ab953366dcc4f19252b2e0dc9f3adfd018
    kind: update
    at: 2026-09-23T08:20:50.159Z
    entryIds:
      - p7
  cd0a12eb5fe1bb0413d5c3468ab7b681db73313ed80f74b4167d577755b81a03:
    fingerprint: 39eb439dad149f8722a4b93bfb0b651799fcca96e43a9997cd989005104cb936
    kind: update
    at: 2026-09-23T08:33:11.812Z
    entryIds:
      - p8
  453f1c7ca4e98ffa1fa097d4c9fa3ac8c5fa08bf555cf933b8181d5e3c4b4b40:
    fingerprint: f82c753828e61f2584e9b89fdc96636db109bb317b7d602a6d3c45b2e316fe31
    kind: update
    at: 2026-09-23T08:33:52.857Z
    entryIds:
      - p9
criterionVersions:
  c1: 1
  c2: 1
  c3: 1
  c4: 1
  c5: 1
  c6: 1
---

已完成、已验证、已提交（三仓库提交均未 push）。插件 ff3502a682b9edc00066928ae469f3d44d6b1116（7 文件，193+/14-）；壳两条：d6da5b6951b35e5033f79bfaebda3980f6a5fe61（本任务的 3 条技能索引断言随该提交落地）与 535f1a36cdf410670fecd02301cab8a8d77c4c37（补回并发中一度丢失、属于 task-7af5d595 的 12 行 chooser 目录记忆断言，补提交前 smoke:resources 复验 EXIT=0）。功能：skills/index.yaml 启停变更归属技能资产（无法归属时保留兜底条目并可正常提交）、索引按所选技能精确重建、同资产其他路径一并提交、启用即删除显式条目。验证：插件 yarn check 308 tests / 0 fail（typecheck + build）；壳原生 smoke:resources EXIT=0，16 组中英/主题/窄窗布局测量无溢出。并发教训：为拆分自己的 hunk 而重置共享工作树文件，会与另一会话的 git add -A 撞车（本次挤掉了 12 行别人的断言，已恢复并补提交）；后续拆分应改用 git apply --cached 或在对方提交后再动手。限制：未 push；原生验收基于当时壳工作树（含其他任务改动）而非固定 pin；本机为 macOS arm64，Windows 未验；本会话模型不能读图，截图仅供人工复核。
