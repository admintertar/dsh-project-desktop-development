---
schemaVersion: 3
directory: Windows 实机验证：打开探测、克隆导入与目录记忆
id: task-7af5d595-cad0-4494-bc80-ccd37002512f
title: Windows 实机验证：打开探测、克隆导入与目录记忆
objective: 在真实 Windows 上验证 task-7be557ec 的三块改动并给出平台结论：(1)「打开」在 Windows 上退化为文件夹选择器时的行为——唯一入口直接打开、没有入口给出本地化提示、多个入口补一次只选文件的对话框；(2)「克隆仓库」导入事务在 Windows 上的端到端表现——目标路径分隔符与文件夹名校验、成功打开、非项目回滚、私有仓库凭据；(3) 目录记忆在 Windows 上生效（Windows 走 browse 后端落到壳的 pickDirectory）。本轮只做验证与记录，不在 Windows 上顺手改代码；发现缺陷另开任务。
status: active
createdAt: 2026-09-23T08:07:16.828Z
updatedAt: 2026-09-23T08:18:21.375Z
artifacts:
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: d6da5b6951b35e5033f79bfaebda3980f6a5fe61
    description: 待验证的壳仓库提交（打开探测、克隆导入、目录记忆、focused 扩展），尚未 push
archived: false
phase: validation
brief:
  currentBehavior: 三块改动已在 macOS arm64 上全部验证：yarn run check EXIT=0（125+7+1），yarn run smoke:guide EXIT=0、18 项 checks 全绿。Windows 的分支从未在实机上执行过：openFile+openDirectory 退化为文件夹选择、多项目目录补选文件、browse 后端落到壳 pickDirectory 的目录记忆、以及 native-resource-state-checks.mjs 的 Windows 专有分支（本机直接跳过）。CI 覆盖已补齐：smoke:guide 的 --focused 集合里已加入 checkRepositoryImport（本机 yarn run smoke:guide:focused EXIT=0，checks 为 ['open-folder-and-repository-import','create-guide-project-path-preview-separator']），因此 guide-windows.yml 现在会跑欢迎窗口的文件夹探测、多项目补选与克隆导入；resources-windows.yml 继续跑 smoke:resources 覆盖目录记忆断言。
  scope: resources/dsh-project-desktop 的 Windows 路径：src/windows/guide-window.mjs（open 退化与补选文件、import-* 、browse-import-directory）、src/app/main.mjs（pickOpen）、src/app/repository-import.mjs、src/app/last-directories.mjs、src/desktop-adapter/native.mjs（pickDirectory 记忆）、scripts/native-guide-checks.mjs 与 scripts/native-resource-state-checks.mjs、.github/workflows/guide-windows.yml 与 resources-windows.yml。
  constraints:
    - 本机只有 macOS arm64，Windows 行为只能由 Windows 实机或 windows-2022 runner 给出结论
    - 不改官方快照、不改动运行中的 Profile；验证阶段只跑命令与人为操作，发现问题另开任务或回退源任务
    - Windows 上需先 git config core.autocrlf false、core.longpaths true（两个 workflow 已设置），长路径与 CRLF 会直接影响构建与断言
    - 验证证据只落 tasks/<任务>/artifacts/ 的结论级文件，运行期目录一律放 %TEMP% 或 .runtime/
  outOfScope:
    - 修复在 Windows 上发现的缺陷（除非用户另行要求；发现后先在 src/desktop-adapter/native.mjs 等位置记录复现与证据）
    - Linux 实机验证
    - 发布、打包产物验收与 pin bump
  acceptanceCriteria:
    - id: W1
      text: 在 Windows 上 yarn run check 通过（125 + 7 + 1），无平台专有失败
      required: true
      version: 1
    - id: W2
      text: 在 Windows 上 yarn run smoke:resources 通过，含新增断言：资源页第一次目录选择器无 defaultPath、第二次的 defaultPath 等于上次选中的目录（或 resources-windows.yml 的 artifact 为绿）
      required: true
      version: 1
    - id: W3
      text: 欢迎窗口「打开」在 Windows 上只弹出文件夹选择器：含唯一 .agent-project 的文件夹直接打开；空文件夹显示「不是 agent-project 项目」；含多个 .agent-project 的文件夹补一次只选文件的对话框，取消则无动作、不报错
      required: true
      version: 1
    - id: W4
      text: 克隆导入弹窗在 Windows 上端到端：公开仓库克隆后文件夹名自动推导、目标出现 <name>.agent-project 并直接打开；非 agent-project 仓库提示后回滚删除；私有仓库弹出凭据弹窗
      required: true
      version: 1
    - id: W5
      text: 导入目录记忆在 Windows 上生效：选定父目录并导入后，关闭再打开弹窗预填该目录；userData 下生成 last-directories.json
      required: true
      version: 1
    - id: W6
      text: 资源管理器双击 .agent-project 文件能经 second-instance 打开对应项目
      required: true
      version: 1
    - id: W7
      text: 决定是否把 checkRepositoryImport 加进 --focused（guide-windows.yml 目前只跑 checkGuide，欢迎窗口的退化分支与克隆导入在 CI 上无覆盖）
      required: false
      version: 1
questions:
  - 验证走哪条路：push 到 master 让两个 Windows workflow 自动跑（需先提交本轮改动），还是把工作树带到 Windows 实机手工跑？
  - Windows 实机是否方便做手工界面验收（W3–W6），还是只跑自动部分？
handoff:
  nextSteps:
    - 改动已提交为 d6da5b6951b35e5033f79bfaebda3980f6a5fe61（master），尚未 push。push 后两个 Windows workflow 会自动触发；也可用 workflow_dispatch 手动触发。
    - Windows 上优先跑自动部分：yarn run smoke:guide（完整模式，含 checkRepositoryImport 与 checkGuideFrame）与 yarn run smoke:resources；若 checkGuideFrame 因机器焦点失败，用 yarn run smoke:guide:focused 加上手工 W3–W6。
    - 手工部分（W3–W6）：打开动作的退化与补选文件、克隆导入的三种结局与私有仓库凭据、导入目录预填、资源管理器双击 .agent-project。
    - 证据回写本任务 artifacts：每个结论 1–2 张截图 + 关键日志，运行期目录放 %TEMP% 或 .runtime/。
  readBefore:
    - guide-window
    - last-directories
    - native
    - guide-windows
    - resources-windows
  verifyBefore:
    - cd resources/dsh-project-desktop && yarn run check
    - cd resources/dsh-project-desktop && yarn run smoke:guide:focused
    - cd resources/dsh-project-desktop && yarn run smoke:resources
references:
  - id: source-task
    label: 源任务：欢迎窗口打开/克隆导入 + 目录记忆（macOS 已验证）
    type: task
    taskId: task-7be557ec-45bc-48a2-a111-1d3f62b12c8d
  - id: guide-window
    label: 欢迎窗口：open 退化与补选文件、import-*、browse-import-directory
    type: file
    path: resources/dsh-project-desktop/src/windows/guide-window.mjs
  - id: last-directories
    label: 目录记忆（import / resource 两个键）
    type: file
    path: resources/dsh-project-desktop/src/app/last-directories.mjs
  - id: native
    label: 项目内目录选择（资源页/重定位/技能导入）的落脚点
    type: file
    path: resources/dsh-project-desktop/src/desktop-adapter/native.mjs
  - id: guide-windows
    label: CI：windows-2022 跑 smoke:guide:focused（已包含 checkRepositoryImport）
    type: file
    path: resources/dsh-project-desktop/.github/workflows/guide-windows.yml
  - id: resources-windows
    label: CI：windows-2022 跑 smoke:resources（含新增目录记忆断言）
    type: file
    path: resources/dsh-project-desktop/.github/workflows/resources-windows.yml
entries:
  - id: w1
    kind: progress
    content: 任务建立时的事实：(1) 源改动全部只在工作树，未提交、未 push，因此 CI/实机验证前必须先让改动可用（推荐：提交并 push 到 master，两个 Windows workflow 的 paths 均覆盖本次改动文件）；(2) guide-windows.yml 跑的是 corepack yarn run smoke:guide:focused，而 focused 只执行 checkGuide（scripts/native-guide-case.mjs:24），不包含 checkRepositoryImport，所以欢迎窗口的文件夹探测、多项目补选与导入目录预填在 Windows CI 上当前无覆盖；(3) resources-windows.yml 跑 corepack yarn run smoke:resources（native-resource-state-checks.mjs），该 job 的 paths 包含 src/app/**、src/desktop-adapter/** 与该脚本，因此本轮改动会触发它，新增的目录记忆断言（第一次无 defaultPath、第二次等于上次选中的目录）会在 Windows 上自动执行。
    basis: observation
    createdAt: 2026-09-23T08:07:16.828Z
  - id: w2
    kind: progress
    content: 任务分两阶段：先在 Windows 上跑自动部分（yarn run check + smoke:resources + 完整 smoke:guide），再按 W3–W6 做手工界面验收。smoke:guide 完整模式里的 checkGuideFrame 依赖 OS 前台焦点（Windows runner 不可靠，因此 CI 只跑 focused），实机上若因焦点失败需区分环境干扰与真回归。
    basis: observation
    createdAt: 2026-09-23T08:07:16.828Z
  - id: w3
    kind: progress
    content: 已把 checkRepositoryImport 加入 smoke:guide 的 --focused 集合（scripts/native-guide-case.mjs）：focused 分支现在先跑 checkRepositoryImport 再跑 checkGuide，checks 列表为 ['open-folder-and-repository-import','create-guide-project-path-preview-separator']，并更新了文件头对 focused 范围的注释。本机验证：yarn run smoke:guide:focused EXIT=0（.runtime/guide-frame-45Ezrx）。该脚本在 guide-windows.yml 的 paths 列表里，push 后 CI 会跑它；非 darwin 的补选分支断言（clickOpen → 二次文件对话框 → opened 为补选的那个文件）因此首次在 Windows 上执行。
    basis: user-request
    createdAt: 2026-09-23T08:09:13.491Z
  - id: w4
    kind: verification
    content: W7（可选）已做出决定并完成：将 checkRepositoryImport 纳入 --focused。本机 focused 模式跑通，证明该检查不依赖前台焦点、在精简集合下可独立运行；真正的 Windows 结论仍待实机/CI 执行 W3–W5。
    basis: observation
    verification:
      criterionId: W7
      criterionVersion: 1
      method: 本机 focused 模式运行 + 工作流 paths 核对
      result: passed
      coverage: 本机 yarn run smoke:guide:focused 全绿 + guide-windows.yml 的 paths 包含 scripts/native-guide-case.mjs
    createdAt: 2026-09-23T08:09:13.491Z
  - id: w5
    kind: progress
    content: 待验证的改动已提交为壳仓库 d6da5b6951b35e5033f79bfaebda3980f6a5fe61（master，17 个文件），尚未 push。push 到 master 后 guide-windows.yml 与 resources-windows.yml 会因 paths 命中而自动在 windows-2022 上运行，即为本任务的自动部分（W1–W5 的自动化部分）。
    basis: user-request
    createdAt: 2026-09-23T08:18:21.375Z
operations:
  2e57ae13d9d855c084b0d4f559de1948ebb5a891d105734e9cd9fcfd159c8492:
    fingerprint: e83f92eb6fdb8e31ebe052910812971f1075677b755892afc5786b32292c38b9
    kind: create
    at: 2026-09-23T08:07:16.828Z
    entryIds:
      - w1
      - w2
  274b40bfdef3f2f176555a0d444554f0e677c1969ad181ee71ebb670dab7dc60:
    fingerprint: 552ad90243fcc92ae37ca214e7f8ed8b2b30d8903b9c027025949f767549080e
    kind: update
    at: 2026-09-23T08:09:13.491Z
    entryIds:
      - w3
      - w4
  0acd410768193553a565b4a2efc16afe1d03e1005904c387e16a6a1547067604:
    fingerprint: 3b058c52a12ccb0e3e130b323a2014a00cceb1409ff034439b573956fd91912e
    kind: update
    at: 2026-09-23T08:09:19.280Z
    entryIds: []
  0c00876fb91e6338bb127c4d8d5d5dad11252d4e14d03281c766c2d0b18fcbc7:
    fingerprint: ef85f128779b59a80f540145739e6783a9a7bcd5e021a6a151da6a5187bef44b
    kind: update
    at: 2026-09-23T08:18:21.375Z
    entryIds:
      - w5
criterionVersions:
  W1: 1
  W2: 1
  W3: 1
  W4: 1
  W5: 1
  W6: 1
  W7: 1
---

Windows 实机验证任务已建立并完成验证前准备：7 条验收项（W1–W7）+ 前置条件已写入，待验证的改动已提交为壳仓库 d6da5b6951b35e5033f79bfaebda3980f6a5fe61（master，17 个文件，尚未 push）。已完成 W7：把 checkRepositoryImport 加入 smoke:guide 的 --focused 集合（checks 为 open-folder-and-repository-import + create-guide-project-path-preview-separator），本机 yarn run smoke:guide:focused EXIT=0；由于 guide-windows.yml 的 paths 包含 scripts/native-guide-case.mjs，push 后 Windows CI 将首次执行欢迎窗口的文件夹探测、多项目目录补选文件与克隆导入/目录预填；resources-windows.yml 则继续自动跑 smoke:resources 的目录记忆断言。仍待 Windows 实机或 windows-2022 runner 给出结论：W1（check）、W2（smoke:resources）、W3–W6（退化行为、克隆导入三种结局与私有凭据、导入目录预填、文件关联双击）。本机为 macOS arm64，不做跨平台结论。
