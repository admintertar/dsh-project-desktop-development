---
schemaVersion: 3
directory: 资源缺失时克隆操作改用图标按钮并说明需要克隆
id: task-8c104113-bd62-425b-999e-81586281e42a
title: 资源缺失时克隆操作改用图标按钮并说明需要克隆
objective: 把资源卡片操作栏里「克隆」文字按钮改为与相邻操作一致的图标按钮，并用 Tooltip 说明资源尚未克隆、克隆会检出到项目内目标目录；附源码改动、yarn check 与原生视觉验收证据。
status: completed
createdAt: 2026-09-23T13:11:50.476Z
updatedAt: 2026-09-23T13:13:11.938Z
artifacts:
  - type: file
    path: artifacts/report.md
    description: 改动前后的代码逻辑、验证方法与结论、遗留项与复现命令
  - type: file
    path: artifacts/probe-result.json
    description: 原生探针完整输出：4 轮文案、按钮几何（aria/text/尺寸/圆角/颜色/禁用态）、窄窗口测量与 windowFocused
  - type: file
    path: artifacts/clone-icon-row-zh-dark.png
    description: 中文深色：操作栏为 4 个图标动作，不再有「克隆」文字按钮
  - type: file
    path: artifacts/clone-tooltip-zh-dark.png
    description: 中文深色：键盘 focus 时显示「尚未克隆到项目内。克隆会把仓库检出到项目内的目标目录。」
  - type: file
    path: artifacts/clone-tooltip-en-light.png
    description: 英文浅色：同一条 Tooltip 的英文文案
  - type: file
    path: artifacts/clone-icon-row-en-light-narrow.png
    description: 英文浅色 420px 窄窗口：图标行完整、页面无横向溢出
  - type: commit
    repository: https://github.com/admintertar/dsh-plugin-project.git
    commit: d45b54fca4e3928e0c23d7ceec9ac654ff2d9413
    description: "fix(resources): clone a missing resource from an icon action with a reason tooltip（主工作树 master 上的落地提交）"
archived: false
phase: validation
brief:
  currentBehavior: resources/dsh-plugin-project/src/client/ResourcesPanel.tsx 第 134-135 行（改动前）在 item.type === 'git' && item.url && item.status !== 'ready' && !item.external 时渲染 <Button size="sm">{t('resourceClone')}</Button>：操作栏里唯一的文字动作（详情按钮除外），宽度、圆角与提示方式都和相邻的关联远端/绑定目录/编辑/移除图标按钮不一致，且没有说明为什么需要克隆。
  scope: resources/dsh-plugin-project 的 src/client/ResourcesPanel.tsx（IconAction 支持 tooltip、克隆动作改图标按钮）与 src/resource-locales.ts（新增 resourceCloneBody 中英文案）。
  constraints:
    - 复用固定官方 primitives 图标与 Tooltip，沿用既有 IconAction/卡片样式，不新增私有控件
    - 保持原禁用条件（locked/cloneActive/canClone）、克隆弹窗与关闭后焦点返回行为
    - 中英文案同步；不改变 Host 侧克隆逻辑与资源状态判定
  outOfScope:
    - 克隆执行流程、资源状态判定、卡片网格与窄窗口布局重构
    - 其它图标操作在禁用态是否显示 Tooltip
  acceptanceCriteria:
    - id: C1
      text: 目录缺失/需要绑定目录且有 url 的 Git 资源，操作栏中的克隆动作是图标按钮：无文字、28×28、与相邻图标操作同圆角同色
      required: true
      version: 1
    - id: C2
      text: 该按钮的 Tooltip 在中英文下说明资源尚未克隆、克隆会检出到项目内目标目录，键盘 focus 与 hover 均可显示
      required: true
      version: 1
    - id: C3
      text: 点击图标仍打开克隆弹窗，Escape 关闭后焦点回到该图标按钮
      required: true
      version: 1
    - id: C4
      text: yarn check（typecheck+308 测试+build）全绿；原生探针在中英文×浅色深色×1180/420 窗口下通过且无页面横向溢出
      required: true
      version: 1
handoff:
  nextSteps:
    - bump-upstream-lock-pin-at-release
    - swap-icon-or-wording-then-rerun-yarn-check-and-native-probe
  readBefore: []
  verifyBefore: []
references: []
entries:
  - id: e1
    kind: progress
    content: 定位：ResourcesPanel.tsx 的克隆动作为文字 Button，同排其它动作为 IconAction 图标按钮（带 Tooltip），构成 UI 一致性缺陷。
    basis: observation
    createdAt: 2026-09-23T13:11:50.476Z
  - id: e2
    kind: decision
    content: 图标选用官方 IconDownloadOutline16（克隆=从远端取回本地；该图标在 ready 状态的卡片上用于「更新资源」，与克隆按钮不会同屏出现），文案新增资源级 locale key resourceCloneBody，中英文同步。
    basis: agent-proposal
    createdAt: 2026-09-23T13:11:50.476Z
  - id: e3
    kind: progress
    content: 按项目约定在独立 worktree resources/.worktrees/dsh-resource-clone-action（分支 fix/resource-clone-icon-action）改动并验证，共享主工作树保持在 5193e81 干净状态。
    basis: user-request
    createdAt: 2026-09-23T13:11:50.476Z
  - id: v1
    kind: verification
    content: 'C1 已在真实 Electron 窗口的实时 DOM 上验证：4 轮（en/zh × light/dark，1180px）中，存在 button[aria-label="克隆: Clone action-backend"]（en 为 Clone:），textContent 为空，28×28，class 含 project-mcp-action，与相邻图标动作圆角一致、启用态颜色一致；同一行仍有文字按钮「详情」，说明只有克隆动作被改为图标。'
    basis: observation
    verification:
      criterionId: C1
      criterionVersion: 1
      method: 原生探针（%TEMP%\clone-action-probe）executeJavaScript 读取 footer 按钮的 aria-label/textContent/getBoundingClientRect/getComputedStyle
      result: passed
      coverage: en/zh × light/dark 共 4 轮全部通过；按钮几何与颜色数据见 artifacts/probe-result.json 的 row 字段
    createdAt: 2026-09-23T13:13:11.938Z
  - id: v2
    kind: verification
    content: C2 已验证：按钮 focus() 后出现官方 [role=tooltip]，文本与 resourceCloneBody 中英文案逐字一致；blur() 后气泡消失。窗口先用 show()/moveTop()/focus() 取得前台，探针记录 document.hasFocus() === true，满足「先证明前台窗口再用实时 DOM 采样」。
    basis: observation
    verification:
      criterionId: C2
      criterionVersion: 1
      method: 原生探针 focus 触发官方 Tooltip 并比对文本，截图留证
      result: passed
      coverage: 4 轮文案均匹配；截图 artifacts/clone-tooltip-zh-dark.png、artifacts/clone-tooltip-en-light.png
    createdAt: 2026-09-23T13:13:11.938Z
  - id: v3
    kind: verification
    content: C3 已验证：点击图标打开真实克隆弹窗（弹窗文案含「克隆」/「Clone」），Escape 关闭后 document.activeElement 的 aria-label 回到该图标按钮。
    basis: observation
    verification:
      criterionId: C3
      criterionVersion: 1
      method: 原生探针点击后断言 [role=dialog] 文本，Escape 后读取 document.activeElement
      result: passed
      coverage: 4 轮均通过；弹窗状态另有 clone-dialog-*.png（运行期证据，未入库）
    createdAt: 2026-09-23T13:13:11.938Z
  - id: v4
    kind: verification
    content: C4 已验证：worktree 内 yarn check 退出码 0（308 tests / 301 pass / 7 skip / 0 fail，含 typecheck 与 build）；原生探针在 1180px 与 420px 两种宽度下均无页面横向溢出、footer 无溢出、5 个动作都在视口内且可见。
    basis: observation
    verification:
      criterionId: C4
      criterionVersion: 1
      method: resources/.worktrees/dsh-resource-clone-action 内 yarn check；原生探针几何测量（scrollWidth/getBoundingClientRect）
      result: passed
      coverage: check 日志落盘 %TEMP%\check-clone-action.log；窄窗口数据见 artifacts/probe-result.json 的 narrow 字段
    createdAt: 2026-09-23T13:13:11.938Z
  - id: c1
    kind: completion
    content: 克隆动作已改为带说明的图标按钮并落地：源码提交 d45b54f（主工作树 master），zh/en 文案与 Tooltip 行为、克隆弹窗与焦点返回、窄窗口几何均有自动化与真实窗口证据；遗留项是发布时才需要 bump upstream.lock.json 的 pin，以及 420px 下卡片被 grid 压到约 43.6px 的既有布局现象（与本次改动无关）。
    basis: observation
    verificationEntryIds:
      - v1
      - v2
      - v3
      - v4
    createdAt: 2026-09-23T13:13:11.938Z
operations:
  952f54b1dc34bb58f7828c44f3bcc7f06e6013eee8e5e6d3259b0ce982579e52:
    fingerprint: 31020acc584f5948fe133d6b070b89ee661385c9d04f0f579a5e79dd6bfe35d3
    kind: create
    at: 2026-09-23T13:11:50.476Z
    entryIds:
      - e1
      - e2
      - e3
  47c700051386eb0dccf73e4af224118f7ddcdacde04ad92c3f8d16c839e82ecd:
    fingerprint: 84d317162f6daf0983d5600ccdaef4e1d1fe6985b90675e7636e7e99b3afaace
    kind: update
    at: 2026-09-23T13:13:11.938Z
    entryIds:
      - v1
      - v2
      - v3
      - v4
      - c1
criterionVersions:
  C1: 1
  C2: 1
  C3: 1
  C4: 1
---

已修复并落地：资源未就绪（目录缺失/需要绑定目录/不可用）且有 url 的 Git 资源，卡片操作栏里的克隆动作由文字按钮改为官方 IconDownloadOutline16 图标按钮，复用同一 IconAction 的 28×28 与 Tooltip；新增 resourceCloneBody 中英文案作为提示（「尚未克隆到项目内。克隆会把仓库检出到项目内的目标目录。」/「Not in this project yet. Cloning checks the repository out into the project directory.」），禁用时提示仍可读。worktree 内 yarn check 全绿（301 pass/0 fail），真实 Electron 前台窗口的探针在 en/zh × light/dark × 1180/420 全部通过。已在插件主工作树 5193e81 之上提交 d45b54f，随后把壳 dist 恢复为固定插件构建（dist/build.json 不再带 projectLocalSource）。
