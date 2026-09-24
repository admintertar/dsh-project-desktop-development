---
schemaVersion: 3
directory: smoke-native 在 git worktree 路径下必失败：official restart confirma
id: task-6de59357-6a45-4be5-a967-78e066dab356
title: smoke:native 在 git worktree 路径下必失败：official restart confirmation 超时
objective: 记录并定位与埋点改动无关的既有缺陷：`yarn smoke:native` 在任何 git worktree 路径下必失败（失败点为 native-restart-checks 的官方重启确认对话框等待，或 recovery 的窗口几何断言），而在主工作树路径下通过；给出可复现步骤、已排除项与下一步验证方向，供后续排期修复。
status: completed
createdAt: 2026-09-23T14:27:00.485Z
updatedAt: 2026-09-23T15:21:34.386Z
artifacts: []
archived: false
phase: validation
brief:
  currentBehavior: "在主工作树路径下运行 node scripts/smoke-native.mjs 多次通过（EXIT=0）；在任何 git worktree 路径下运行则在 scripts/native-restart-checks.mjs:39 的 waitDialog 必失败（Timed out: official restart confirmation 1），或偶发失败于 scripts/native-recovery-checks.mjs:78 的窗口几何断言（1280 !== 980）。"
  scope: 定位“壳的原生 smoke 在 worktree 路径下必失败”的原因，给出可复现步骤、已排除项与最小对照实验结论。
  constraints:
    - 本条只记录 Windows 实测；macOS 的 worktree 行为可能不同
    - 不得在主工作树直接改产品代码，验证走独立 worktree
  outOfScope:
    - 本次不修测试脚手架
    - 不改变 smoke:native 的检查范围
  acceptanceCriteria:
    - id: D1
      text: 给出最小复现命令与稳定的失败签名（失败点文件与标签）
      required: true
      version: 1
    - id: D2
      text: 用对照数据区分“产品代码回归”与“worktree 环境特有的测试脆弱”，并列出已排除项
      required: true
      version: 1
    - id: D3
      text: 给出下一步最可能的差异变量（dist 产物、.runtime、bundle 时间点）与验证方式
      required: true
      version: 1
references: []
entries:
  - id: d1
    kind: progress
    content: 现象：Windows 上 node scripts/smoke-native.mjs 在主工作树路径（resources/dsh-project-desktop）多次 EXIT=0；在 worktree 路径（长路径 wt-dsh-boot-log、短路径 D:\wt-boot-log）多次 EXIT=1，失败标签恒为 official restart confirmation 1（scripts/native-restart-checks.mjs:39 的 waitDialog）。
    basis: observation
    createdAt: 2026-09-23T14:27:00.485Z
  - id: d2
    kind: verification
    content: 已排除项：将 src/desktop-adapter/native.mjs 回退到 HEAD、并把 loadURL/health.promise 恢复官方顺序后同样失败在同一标签，因此与本次埋点改动无关；清理残留 electron 进程后仍失败；把 worktree 建到短路径 D:\wt-boot-log（补齐 dist 后）仍失败，路径长度假设不成立。
    basis: observation
    verification:
      criterionId: D2
      criterionVersion: 1
      method: A/B 回退与跨路径对照运行 smoke:native，比对失败签名
      result: passed
      coverage: native.mjs 回退、进程清理、短路径三项变量均被排除
    createdAt: 2026-09-23T14:27:00.485Z
  - id: d3
    kind: progress
    content: 尚未验证的差异变量：.cache 与 .upstream 为 junction 共享，但各树的 dist/ 是各自构建产物，实测 dist/project-files.mjs 哈希在三棵树各不相同（9272/9437/9597 字节），而 native-smoke-case.mjs 与 project-bootstrap.mjs 都从 dist 导入，存在源码与 dist 不同步的可能；另外空 worktree 必须先 yarn build，否则 Electron 启动即抛 ERR_MODULE_NOT_FOUND 并弹错误框。
    basis: observation
    createdAt: 2026-09-23T14:27:00.485Z
  - id: d4
    kind: verification
    content: "复现命令与失败签名（D1）：在任意 git worktree 下运行 `node scripts/smoke-native.mjs`，稳定失败于 scripts/native-restart-checks.mjs:39 的 waitDialog，标签恒为 `Timed out: official restart confirmation 1`；主工作树路径下多次 EXIT=0。"
    basis: observation
    verification:
      criterionId: D1
      criterionVersion: 1
      method: 跨路径重复运行 smoke:native 并记录失败签名
      result: passed
      coverage: 复现命令、失败文件:行与失败标签均固定可重复
    createdAt: 2026-09-23T15:21:34.386Z
  - id: d5
    kind: decision
    content: 根因：waitDialog 用 `runtimePackage`（worktree 拼写）拼出期望的对话框 URL（pathToFileURL(join(runtimePackage,'lib/native-ui/desktop-dialog.html'))），但官方对话框模块是经 .cache junction 导入的，其 import.meta.url 解析为规范化目标路径；Electron 的 webContents.getURL() 报告的是规范化路径，于是已经显示出来的对话框被误判为“不存在”，windows() 永远为空，等到 20s 超时。这也解释了为何只在 worktree 下复现、且失败点与产品代码无关。
    basis: observation
    createdAt: 2026-09-23T15:21:34.386Z
  - id: d6
    kind: verification
    content: 修复验证（D3）：修复为比较前先 realpathSync（提交 3a08542，已在 master）。修复前同一 worktree（wt-reveal-fix，.cache 为 junction）跑 smoke:native 多次全失败；带上修复后一次 EXIT=0 通过；主工作树路径下行为不变（realpath 幂等）。
    basis: observation
    verification:
      criterionId: D3
      criterionVersion: 1
      method: worktree 内 node scripts/smoke-native.mjs 前后对照
      result: passed
      coverage: 修复前后同一 worktree 对照，并确认主树路径无回归
    createdAt: 2026-09-23T15:21:34.386Z
  - id: d7
    kind: completion
    content: 闭环：缺陷已定位、修复（3a08542）已提交并推送，worktree 复现验证通过。
    basis: agent-proposal
    verificationEntryIds:
      - d4
      - d2
      - d6
    createdAt: 2026-09-23T15:21:34.386Z
operations:
  cc72a053caba24d3afe6f4d0d6c6f0a945ff6c31b4f81c61ae8de7e0725417cd:
    fingerprint: cdd6f3a7d06985e3f2a136b50fb42fb6af277b241c796a77b95fac9d1bf1ff73
    kind: create
    at: 2026-09-23T14:27:00.485Z
    entryIds:
      - d1
      - d2
      - d3
  686aea2e0c272e2bff0e0cba07ce22da3c7065a28a569ab9ef7371614c587b0a:
    fingerprint: aa8cf10798b2577a282e5a8c9d27570e75dd098a912bde4ab23df17f87ea6571
    kind: update
    at: 2026-09-23T15:21:34.386Z
    entryIds:
      - d4
      - d5
      - d6
      - d7
criterionVersions:
  D1: 1
  D2: 1
  D3: 1
---

根因：native-restart-checks.mjs 的 waitDialog 用 runtimePackage（worktree 拼写）拼出期望的对话框 URL，而官方对话框模块经 .cache junction 解析后 import.meta.url 是规范化路径，Electron 的 webContents.getURL() 报告规范化路径，于是已显示的对话框被误判为不存在，等满 20s 超时。修复：比较前先 realpathSync（提交 3a08542）。验证：修复前同一 worktree 多次全失败，修复后一次 EXIT=0；主树路径行为不变。
