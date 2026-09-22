---
schemaVersion: 3
directory: 验收证据不落盘：视觉验收截图写进被忽略的 .runtime 临时目录，任务 artifacts 里没有证据
id: task-914d6756-ba47-4455-bfeb-4e5891a4791b
title: 验收证据不落盘：视觉验收截图写进被忽略的 .runtime 临时目录，任务 artifacts 里没有证据
objective: "记录并定位「任务记录的验收证据不落盘」的系统性缺陷：UI/原生任务声称做了截图或实时 DOM 视觉验收并通过（result: passed），但截图写进壳仓库被 gitignore 的 .runtime/&lt;随机后缀&gt;/ 且随机命名，tasks/&lt;任务&gt;/artifacts/ 里没有任何证据文件，docs/validation.md 的 Local evidence 也直接引用这些临时路径。给出量化证据、影响面与修复方向，供后续排期实现。"
status: active
createdAt: 2026-09-22T02:05:28.055Z
updatedAt: 2026-09-22T02:05:28.055Z
artifacts: []
archived: false
phase: investigation
brief:
  currentBehavior: 验收截图默认落在 resources/dsh-project-desktop/.runtime/<随机后缀>/（如 resource-states-mvg442、guide-frame-P3ag4Q、native-DplPIl），目录名与文件名不含任务名、不被任何 task.md 引用；.gitignore:12 忽略 .runtime/，git 跟踪 0 个文件。tasks/ 下 12 份任务只有 4 份关联了截图（共 9 张），其中 2 份任务的文档反复提到截图却一张都没有。docs/validation.md 有 14 行把 .runtime/<随机名>/ 当作 Local evidence 引用。没有脚本把截图导出到 tasks/。
  scope: 本次只记录缺陷与量化证据，不实现修复。缺陷涉及三处契约：tasks/<任务>/task.md 的 artifacts[type=file] 留档契约、壳仓库 .runtime/ 临时验收产物的生命周期、docs/validation.md 的证据引用惯例。
  constraints:
    - 本次只记录，不补截图、不改代码、不改 memory/working-agreements.md 的验收约定（用户 2026-09-22 明确选择）
    - 不改动既有任务记录的 passed 判定与历史 entries，避免追溯性改写历史结论
    - 官方源码快照（.upstream/）只读，不修改
    - "量化口径可复现：按 task.md 的 artifacts 区块统计 type: file，按 artifacts/ 目录统计图片扩展名"
  outOfScope:
    - 补做 Windows 项目窗口材质任务的真机截图：需 Windows 11 真机，本机为 macOS（Darwin），无法复现
    - 追溯性补齐全部历史任务的截图与 JSON
    - 修改项目验收约定本身（memory/working-agreements.md）
    - 清理或迁移 .runtime/ 下现有 847 张图片
  acceptanceCriteria:
    - id: ac-1
      text: 验收证据（截图/JSON/日志）必须落在 tasks/<任务>/artifacts/ 下，并由该任务 task.md 的 artifacts[type=file] 引用；不得只存在于被 gitignore 的 .runtime/ 临时目录
      required: true
      version: 1
    - id: ac-2
      text: 当某项 verification 条目的 method/coverage 明确声称截图、截屏、DOM 取样等视觉验收时，该任务必须存在对应的 file artifact；否则该条目不得以 passed 收尾，或在 coverage 中显式标注证据未留档及原因
      required: true
      version: 1
    - id: ac-3
      text: docs/validation.md 的 Local evidence 引用不再指向 .runtime/<随机后缀> 这类临时路径，或同时给出已留档副本的稳定路径
      required: false
      version: 1
    - id: ac-4
      text: 存在可执行的机械检查（脚本或 CI 步骤），能报出「verification 声称视觉验收但任务无 file artifact」的不一致清单
      required: false
      version: 1
questions:
  - 修复范围：只约束新任务（新建时要求证据落盘），还是同时要求历史任务补档或标注未留档？
  - 是否引入机械检查拦截「verification 声称视觉验收但无 file artifact」？若引入，放在哪里：插件/壳的检查脚本、项目级脚本，还是任务写入时的校验？
  - 壳仓库 .runtime/ 的定位是否需要明确区分「临时调试产物」与「验收证据」两类，避免后者继续写进被忽略目录？
handoff:
  nextSteps:
    - 确认修复范围（仅新任务约束 / 含历史任务标注或补档）
    - 决定是否加机械检查：扫描 task.md 中 method/coverage 提及截图·截屏·DOM 的 verification 条目，与 artifacts[type=file] 求差集并报错
    - 若补档：先在 macOS 可复现的任务（首次打开自动重建资源目录）试点，把开发壳 CDP 验收的截图从 .runtime/ 复制进该任务 artifacts/ 并登记 file artifact
    - Windows 项目窗口材质任务的截图需在 Windows 11 真机上重跑后才能补，本机 macOS 无法代做
  readBefore:
    - ref-task-material
    - ref-task-restore
    - ref-validation
    - ref-gitignore
  verifyBefore:
    - 修复实现前先复算本任务的量化口径，确认缺口未被历史补档改变
    - 若改动 memory/working-agreements.md 的验收条款，需同时检查既有任务是否需要追溯标注
references:
  - id: ref-validation
    label: 壳仓库验收文档：Local evidence 指向 .runtime 随机临时路径
    type: file
    path: resources/dsh-project-desktop/docs/validation.md
  - id: ref-gitignore
    label: 根 .gitignore：第 12 行忽略 .runtime/，导致验收截图不入库
    type: file
    path: .gitignore
  - id: ref-agreements
    label: 项目工作约定：要求原生视觉验收，但未要求证据落盘
    type: file
    path: memory/working-agreements.md
  - id: ref-task-material
    label: 案例：声称逐窗口截屏取样但零留档的任务
    type: file
    path: tasks/Windows 项目窗口材质：Mica 选项缺失与主题切换后侧栏发黑/task.md
  - id: ref-task-restore
    label: 案例：声称 CDP 实时 DOM 验收但零留档的任务
    type: file
    path: tasks/首次打开按 .agent-project 自动重建缺失的资源目录/task.md
entries:
  - id: ev-1
    kind: progress
    content: 量化缺口（扫描 tasks/*/task.md 与各自 artifacts/ 目录）：12 份任务中只有 4 份有截图，共 9 张；8 份零截图。逐任务对照「verification 条目数 / 留档 file 数 / 文档提及截图次数 / artifacts 实际 png 数」：Windows 下无法添加本地资源 6/0/3/0；Windows 项目窗口材质 5/0/5/0；Windows 创建项目路径预览 5/1/9/1；资源 Git 管理 10/0/0/0；资源卡片 Git 诊断 9/4/1/2；首次打开自动重建资源目录 4/0/0/0；创建项目目标已存在 3/3/7/4；更新下载阶段欢迎窗口 7/2/3/2；两个仓库 Yarn 4.18.0 7/7/0/0；Agent 空转治理 3/0/0/0；壳测试克隆传输泄漏 3/0/0/0；记忆功能不可达 0/0/0/0。
    basis: observation
    referenceIds:
      - ref-agreements
    createdAt: 2026-09-22T02:05:28.055Z
  - id: ev-2
    kind: progress
    content: "两处「文档反复提截图、实际零留档」的典型案例：①Windows 项目窗口材质任务的 verification 条目 method 写明「Windows 原生界面操作 + CDP 读取窗口 URL 与 DOM 计算样式 + 逐窗口置前截屏取样」、result: passed，但 artifacts 只有 4 个 commit，连 artifacts/ 目录都不存在，文档正文出现 5 次截图/截屏字样；②首次打开自动重建资源目录任务的 method 写明「真实开发壳 + CDP Runtime.evaluate 读渲染进程实时 DOM」、result: passed，artifacts 只有 1 个 commit，同样没有 artifacts/ 目录。这正是「任务声称带截图证据、实际一张都看不到」的直接原因。"
    basis: observation
    referenceIds:
      - ref-task-material
      - ref-task-restore
    createdAt: 2026-09-22T02:05:28.055Z
  - id: ev-3
    kind: progress
    content: 截图真实去向：resources/dsh-project-desktop/.runtime/ 下有 93 个随机后缀目录、847 张 png（native-* 340 张、guide-frame-* 149 张、guide-add-* 40 张、updates-* 63 张、resource-states-* 70 张，另有 smoke-*、project-files-* 等）。根 .gitignore:12 为 .runtime/，git ls-files .runtime 结果为 0，即全部未跟踪。目录名（如 mvg442、PX9vGk、DplPIl）与文件名均不含任务标识，无法从任务反查，清理或换机即永久丢失。另确认 scripts/ 下没有任何把截图导出到 tasks/ 的脚本。
    basis: observation
    referenceIds:
      - ref-gitignore
    createdAt: 2026-09-22T02:05:28.055Z
  - id: ev-4
    kind: progress
    content: "文档层面的证据引用同样指向临时路径：壳仓库 docs/validation.md 有 14 行以 .runtime/<随机名>/ 作为 Local evidence，例如「Local evidence: .runtime/smoke-xrZelR」「evidence: .runtime/native-DplPIl/result.json」「Screenshots: .runtime/guide-frame-P3ag4Q/*-loading-*.png」「Result: .runtime/guide-frame-P3ag4Q/result.json」。这些是验收记录中唯一指向证据的位置，但全部是被 gitignore 的随机临时路径，文档的「可复核」承诺在换机后不成立。"
    basis: observation
    referenceIds:
      - ref-validation
    createdAt: 2026-09-22T02:05:28.055Z
  - id: ev-5
    kind: progress
    content: 与项目约定的张力：memory/working-agreements.md 要求「UI 改动不能只靠测试与构建，必须做原生视觉验收：中英文案、主题状态、窄窗口、键盘行为」，但没有任何条款要求验收证据落盘并关联到任务 artifacts。因此 verification 条目可以仅凭自述以 passed 收尾，机制上无法区分「真的做了原生验收」与「声称做了」。
    basis: observation
    referenceIds:
      - ref-agreements
    createdAt: 2026-09-22T02:05:28.055Z
  - id: dec-1
    kind: decision
    content: 用户 2026-09-22 明确选择「先只把现状记录下来，不动文件」：本次仅建立本任务记录，不补截图、不改代码、不改 memory/working-agreements.md 的验收约定，修复方案留待后续排期。据此本任务停在 investigation 阶段。
    basis: user-request
    referenceIds: []
    createdAt: 2026-09-22T02:05:28.055Z
operations:
  39573470946c419a5909cb7c60ab7bcec05eb81abb49fe63cc3424c5a96af9ce:
    fingerprint: 11159386d18a17d9a14161ce833fbf0d7c6a433e91cd09e7ba01195013e6bd19
    kind: create
    at: 2026-09-22T02:05:28.055Z
    entryIds:
      - ev-1
      - ev-2
      - ev-3
      - ev-4
      - ev-5
      - dec-1
criterionVersions:
  ac-1: 1
  ac-2: 1
  ac-3: 1
  ac-4: 1
---


