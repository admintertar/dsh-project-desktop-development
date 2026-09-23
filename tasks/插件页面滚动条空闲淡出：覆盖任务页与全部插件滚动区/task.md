---
schemaVersion: 3
directory: 插件页面滚动条空闲淡出：覆盖任务页与全部插件滚动区
id: task-90bd296f-c01e-4707-8330-28fc2b57ea5d
title: 插件页面滚动条空闲淡出：覆盖任务页与全部插件滚动区
objective: 把壳引导窗口已有的「滚动条空闲 800ms 后淡出」扩展到 dsh-plugin-project 的全部插件滚动区：实现共享的空闲淡出控制器与生成样式（保留 scrollbar-gutter 稳定槽、不改布局、尊重 prefers-reduced-motion），补自动化测试，做原生视觉验收，并同步两份前端规范的范围口径。
status: completed
createdAt: 2026-09-23T03:21:01.650Z
updatedAt: 2026-09-23T03:30:29.345Z
artifacts:
  - type: file
    path: artifacts/native-acceptance.md
    description: 原生验收报告：探针做法、逐容器结果、未覆盖项与过程中修复的问题
  - type: file
    path: artifacts/native-scrollbar-report.json
    description: 探针完整结果 JSON（每个容器的 geometry、markedWhileScrolling、reducedMotion）
  - type: file
    path: artifacts/native-tasks-idle.png
    description: 任务页空闲态截图（2560x1280）
  - type: file
    path: artifacts/native-tasks-dark-idle.png
    description: 任务页暗色主题截图（2560x1280）
  - type: file
    path: artifacts/native-tasks-narrow-idle.png
    description: 任务页窄窗口截图（1800x1280）
  - type: file
    path: artifacts/native-dialog-idle.png
    description: 长设置弹窗空闲态截图（2560x1280）
  - type: commit
    repository: https://github.com/admintertar/dsh-plugin-project.git
    commit: 03662ad7f775e581881f4a24f2827a0febccd7c8
    description: 插件实现、单测与插件前端规范更新（master）
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: 33bdfb5aa10b69943a9b5929cdd8ce6ad053d67e
    description: 壳规范口径更新与原生验收探针 scripts/probe-scrollbar-native.mjs
archived: false
phase: validation
brief:
  currentBehavior: 「滚动条只在真实滚动时显示，停止 800ms 后 180ms 淡出」此前只实现在壳引导窗口 GuideFrame（.guideBody/.welcomeNav/.createNav）；插件页面（含任务页）沿用官方 ui-theme 的常驻滚动条皮肤，从未实现空闲淡出。
  scope: 插件客户端新增共享滚动条空闲淡出控制器（src/client/scrollbar-auto-hide.ts）与由同一清单生成的滚动条样式；登记全部插件滚动容器；补单元测试；在真实 Electron 项目窗口做原生验收（任务列表/详情、页面面板、长弹窗、暗色主题）；同步插件与壳的前端规范。
  constraints:
    - 只改可见性：不移除 scrollbar-gutter:stable，不改变内容宽度、坐标与滚动槽
    - 不动官方聊天、官方侧栏与官方弹窗的滚动条
    - 不引入新的运行时依赖，复用 fixed stable 的官方滚动条变量与主题色
    - 并发会话正在同一插件工作树实现记忆功能，本次改动在隔离 git worktree 分支 scrollbar-idle-fade 上完成
  outOfScope:
    - 官方聊天、官方侧栏与官方弹窗等官方表面的滚动条
    - 表单控件（textarea）内部的滚动条
  acceptanceCriteria:
    - id: ac1
      text: 插件全部登记滚动容器空闲 800ms 后滚动条透明，真实滚动时立即显示，停止后 180ms 淡出，拖动滑块期间保持可见
      required: true
      version: 1
    - id: ac2
      text: 淡出只改变可见性：容器与内容的 clientWidth/offsetWidth/gutter/坐标在显示与隐藏前后一致
      required: true
      version: 1
    - id: ac3
      text: 减少动态效果偏好下不做过渡，直接按空闲/滚动状态切换可见性；prefers-reduced-motion 规则可被测试固定
      required: true
      version: 1
    - id: ac4
      text: 官方聊天、官方侧栏与官方弹窗保持官方常驻滚动条，插件控制器只匹配插件清单容器
      required: true
      version: 1
    - id: ac5
      text: 新增可滚动区域必须登记清单；测试会校验每个 scrollbar-gutter:stable 容器与清单一致
      required: true
      version: 1
    - id: ac6
      text: dsh-plugin-project 的 yarn run check 通过，且原生验收证据（报告、截图、实时 DOM 断言）落盘到任务 artifacts
      required: true
      version: 1
handoff:
  nextSteps:
    - 需要发布时才 bump：把 resources/dsh-project-desktop/upstream.lock.json 的 project pin 指到插件已推送提交，重导 .upstream/project 后跑 yarn run verify:upstream
    - 两个仓库的提交目前只在本地（插件 03662ad、壳 33bdfb5），push 需要明确授权
    - 若要把 scripts/probe-scrollbar-native.mjs 纳入壳的 smoke 体系，先决定它在未含本改动的 pin 版本上应如何失败
  readBefore:
    - native-acceptance
  verifyBefore:
    - plugin-yarn-check
    - native-scrollbar-probe
references:
  - id: native-acceptance
    label: 原生验收报告
    type: file
    path: artifacts/native-acceptance.md
  - id: plugin-yarn-check
    label: 插件检查命令
    type: note
    text: cd resources/dsh-plugin-project && yarn run check
  - id: native-scrollbar-probe
    label: 原生探针重跑
    type: note
    text: cd resources/dsh-project-desktop && DSH_PROJECT_PLUGIN_SOURCE=<plugin checkout> yarn run build，然后用 node 运行 scripts/probe-scrollbar-native.mjs
entries:
  - id: prog-1
    kind: progress
    content: 定位要求出处：该可见性规则只写在壳 docs/frontend-guidelines.md:48 与 docs/architecture.md:78，且被限定为引导窗口（「不影响主项目窗口和官方弹窗」）；插件规范只有一句「不据此修改所有官方滚动条」。任务页滚动条不隐藏不是漏改类名，而是该行为从未实现到项目窗口。
    basis: observation
    createdAt: 2026-09-23T03:21:01.650Z
  - id: prog-2
    kind: progress
    content: 发现 dsh-plugin-project 工作树有另一会话正在实现的记忆功能未提交改动（styles.ts、client/index.tsx、tests/client-styles.test.ts 等），与本改动文件重叠。经确认改用隔离 git worktree（/tmp/dsh-scrollbar-worktree，分支 scrollbar-idle-fade，基于 dd85e1a）实现，主工作树保持原样。
    basis: user-request
    createdAt: 2026-09-23T03:21:01.650Z
  - id: prog-3
    kind: progress
    content: 实现：新增 src/client/scrollbar-auto-hide.ts（登记 12 个滚动容器 + document 级 capture scroll 控制器，800ms 空闲后移除标记，dispose 清理定时器/标记/监听）；styles.ts 由同一清单生成 @property --project-scrollbar-alpha、空闲/滚动 alpha 规则、thumb/hover/active 与 prefers-reduced-motion 规则；client/index.tsx 在 client lifecycle 中安装并随 effect 释放。
    basis: agent-proposal
    createdAt: 2026-09-23T03:21:01.650Z
  - id: prog-4
    kind: progress
    content: 原生验收发现并修复两个实现缺陷：@property 的 inherits:false 让 ::-webkit-scrollbar-thumb 解析到初始值（宿主 alpha 已为 1 但滑块仍透明），改为 inherits:true 并为每个容器显式声明 0；探针侧修正 0.5px 卡片边框导致的 gutter 期望值，以及面板切换恢复滚动位置留下的短暂标记。
    basis: observation
    createdAt: 2026-09-23T03:21:01.650Z
  - id: prog-5
    kind: progress
    content: 原生验收最终一轮全绿（PROBE_EXIT=0，failures 为空）：任务列表、任务详情、长设置弹窗正文、记忆页 .project-panel、暗色主题任务列表、760px 窄窗口的任务列表与详情，逐项断言空闲透明/滚动立即显示/几何不变/1.1s 后淡出；CDP 模拟 prefers-reduced-motion 后 transitionDuration 为 0s。侧栏会话列表、资源页、工具页因 fixture 未产生溢出记为 not-overflowing。
    basis: observation
    createdAt: 2026-09-23T03:30:29.345Z
  - id: prog-6
    kind: progress
    content: 并发会话的记忆功能先落在 8db85fe；随后把隔离 worktree 分支以 git apply --3way 叠加到主工作树（无冲突），合并后插件 yarn run check 301 tests / 0 fail / exit 0，已提交为 03662ad；壳仓库 docs 与探针提交为 33bdfb5，yarn run check 通过。隔离 worktree 与临时分支已清理。
    basis: observation
    createdAt: 2026-09-23T03:30:29.345Z
  - id: ver-ac1
    kind: verification
    content: ac1：空闲 800ms 后滑块透明、真实滚动立即显示、停止后 180ms 淡出。原生探针在 7 个可溢出表面通过（任务列表/任务详情/长设置弹窗正文/记忆页/暗色主题/窄窗口列表/窄窗口详情），另有 5 个控制器单测覆盖标记增删与计时器重置。
    basis: observation
    verification:
      criterionId: ac1
      criterionVersion: 1
      method: 真实 Electron 项目窗口实时 DOM 断言 + happy-dom 控制器单测
      result: passed
      coverage: 覆盖任务列表、任务详情、长设置弹窗正文、记忆页页面面板、暗色主题与 760px 窄窗口；拖动滑块保持可见由 ::-webkit-scrollbar-thumb:active 规则与单测断言覆盖，未做按住滑块的程序化模拟。
    createdAt: 2026-09-23T03:30:29.345Z
  - id: ver-ac2
    kind: verification
    content: ac2：淡出只改变可见性。探针在空闲、滚动中、淡出后三次采样 clientWidth/offsetWidth/gutter/left/width/top/height，全部在 0.5px 容差内一致；scrollbar-gutter 计算值为 stable 且至少保留 8px 滚动槽（详情容器含 0.5px 卡片边框，实测 9px）。
    basis: observation
    verification:
      criterionId: ac2
      criterionVersion: 1
      method: 原生探针逐项几何断言
      result: passed
      coverage: 每个采样容器均比对容器与内容的几何；未覆盖未溢出容器（侧栏会话列表、资源页、工具页）。
    createdAt: 2026-09-23T03:30:29.345Z
  - id: ver-ac3
    kind: verification
    content: "ac3：减少动态效果偏好下不做过渡。通过 CDP Emulation.setEmulatedMedia 设置 prefers-reduced-motion: reduce 后，任务列表的 transitionDuration 为 0s（与生成的 @media(prefers-reduced-motion:reduce){...transition:none} 规则一致）。"
    basis: observation
    verification:
      criterionId: ac3
      criterionVersion: 1
      method: CDP 媒体模拟 + 计算样式断言
      result: passed
      coverage: 在真实渲染进程验证规则生效；未逐容器重复采样。
    createdAt: 2026-09-23T03:30:29.345Z
  - id: ver-ac4
    kind: verification
    content: ac4：官方表面保持官方滚动条。控制器只在 event.target 匹配登记清单时打标记；单测用 official-chat-surface 断言非清单元素滚动不产生标记与计时器，document 级 scroll 目标被忽略；探针记录滚动时 data-project-scrolling 元素数量。
    basis: observation
    verification:
      criterionId: ac4
      criterionVersion: 1
      method: 控制器单测 + 原生探针标记计数
      result: passed
      coverage: 官方聊天/官方弹窗未在原生中直接滚动采样，仅由选择器限定与非清单元素用例覆盖。
    createdAt: 2026-09-23T03:30:29.345Z
  - id: ver-ac5
    kind: verification
    content: ac5：清单防漂移。tests/client-styles.test.ts 双向断言 styles 中每个 scrollbar-gutter:stable 规则的选择器都在 PROJECT_SCROLL_SURFACE_SELECTORS 中，且清单每项都有对应 gutter 规则（当前 12/12）。
    basis: observation
    verification:
      criterionId: ac5
      criterionVersion: 1
      method: 单元测试（styles 文本与清单双向比对）
      result: passed
      coverage: 覆盖全部 12 个登记容器。
    createdAt: 2026-09-23T03:30:29.345Z
  - id: ver-ac6
    kind: verification
    content: ac6：检查与证据。合并后的主工作树 yarn run check 通过（301 tests / 0 fail / exit 0，日志 /tmp/main-check-merged.log）；壳仓库 yarn run check 通过（exit 0）；原生验收报告、结果 JSON 与 4 张截图已落盘到任务 artifacts，运行期 userData 留在壳仓库被忽略的 .runtime/。
    basis: observation
    verification:
      criterionId: ac6
      criterionVersion: 1
      method: yarn run check（两仓库）+ artifacts 落盘核对
      result: passed
      coverage: macOS x64 开发机；未做 Windows/macOS arm64 验收。
    createdAt: 2026-09-23T03:30:29.345Z
  - id: done-1
    kind: completion
    content: 实现、单测、原生验收与规范同步全部完成，两个仓库均已提交且检查通过。
    basis: agent-proposal
    verificationEntryIds:
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - ver-ac6
    createdAt: 2026-09-23T03:30:29.345Z
operations:
  ed90bc14c52506950fd52237b84ce678f0cd27958c4ec127fd1d18dae6a59040:
    fingerprint: 257b5f5c9801b75aae146ed222fe2f6f5aa48f2a134a87161456def6f3a57c64
    kind: create
    at: 2026-09-23T03:21:01.650Z
    entryIds:
      - prog-1
      - prog-2
      - prog-3
      - prog-4
  516f58e3e06a74123f9a67c91d132d8ba28aeef7d6ccf768965d2508e511e025:
    fingerprint: 1ff222d11fbb356e7675ab3d45328331e29a922295821264c9f47cb97fe7165a
    kind: update
    at: 2026-09-23T03:30:29.345Z
    entryIds:
      - prog-5
      - prog-6
      - ver-ac1
      - ver-ac2
      - ver-ac3
      - ver-ac4
      - ver-ac5
      - ver-ac6
      - done-1
criterionVersions:
  ac1: 1
  ac2: 1
  ac3: 1
  ac4: 1
  ac5: 1
  ac6: 1
---

「滚动条空闲 800ms 后淡出」原先只实现在壳引导窗口 GuideFrame，插件页面（含任务页）从未实现。本次在插件侧补齐：新增 src/client/scrollbar-auto-hide.ts，集中登记 12 个插件滚动容器，document 级 capture scroll 在真实滚动时打标记、800ms 空闲后清除；styles.ts 由同一清单生成滚动条规则（@property 注册可动画 alpha，inherits:true 且每个容器显式声明 0；空闲透明、滚动立即显示、停止 180ms 淡出、拖动滑块保持可见、prefers-reduced-motion 直接切换），不改 overflow、稳定槽与内容宽度；client/index.tsx 在 client lifecycle 安装并释放。原生验收在真实 Electron 项目窗口逐容器断言几何不变，覆盖任务列表与详情、长设置弹窗正文、记忆页 .project-panel、暗色主题、760px 窄窗口与 reduced-motion，全部通过；合并后插件 yarn run check 301 tests / 0 fail，壳 yarn run check 通过。限制：侧栏会话列表/资源页/工具页因 fixture 未溢出而未在原生中采样（与已通过容器共用同一清单与规则）；拖动滑块保持可见只由 CSS :active 规则与单测覆盖，未做按住滑块的程序化模拟；官方聊天表面未直接滚动采样，只由「非清单元素不被标记」的单测覆盖。两个仓库的提交均为本地提交，未 push、未 bump pin。
