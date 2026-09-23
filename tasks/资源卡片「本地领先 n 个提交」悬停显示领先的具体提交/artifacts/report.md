# 资源卡片「本地领先 n 个提交」悬停显示领先提交 — 验收报告

日期：2026-09-23 | 平台：macOS x64 | Node 22.19.0 | Yarn 4.18.0 | 插件工作树 + 开发期 `DSH_PROJECT_PLUGIN_SOURCE`

## 结论

资源页面（资源卡片）与项目资产面板的同步标签在 `ahead` 状态下，悬停会显示领先的本地提交：
第一行是标签本身（`本地领先 3 个提交` / `3 local commits`），随后每条提交一行（7 位短 hash + 提交标题）；
超过 Host 上限 20 条时以 `另有 n 个本地提交` / `n more local commits` 结尾。其他同步状态保持原来的 `标签 · 说明` 单行提示。

## 实现

- `src/resource-contract.ts`：新增 `ResourceGitCommit {hash, subject}` 与 `ResourceGitSync.aheadCommits`。
- `src/resource-sync.ts`：`inspect()` 在 `ahead > 0` 时用 `git log --max-count 20 --format=%H%x1f%s%x00 <head> --not <upstreamHead>` 读取领先提交（新→旧，NUL 分记录，任意标题字符安全）；读取失败只丢列表，不让同步状态变成错误。`view()` 仅在已完成远端检查（`checked`）且列表非空时随快照返回，与 `ahead` 计数同源。
- `src/client/resource-ui.ts`：`resourceSyncTooltip()` 组装多行提示；官方 `Tooltip` 的气泡 CSS 是 `white-space: pre-line`，`\n` 直接换行。
- `src/client/ResourceCard.tsx`、`src/client/ProjectChangesPanel.tsx`：标签悬停改用该函数。
- `src/resource-locales.ts`：新增 `resourceSyncAheadMore` 中英条目。

## 验证

| 检查 | 命令 | 结果 |
| --- | --- | --- |
| 插件 typecheck + 303 个单测 + build | `corepack yarn check`（`resources/dsh-plugin-project`） | EXIT=0，303 pass / 0 fail |
| 原生资源状态验收 | `DSH_PROJECT_PLUGIN_SOURCE=../dsh-plugin-project corepack yarn smoke:resources`（`resources/dsh-project-desktop`） | EXIT=0，`ok: true` |

新增用例：

- `tests/resource-sync.test.ts`：未领先时无 `aheadCommits`；22 个本地提交时列表恰好 20 条、首条为最新 HEAD、末条为第 3 个提交（新→旧 + 截断）。
- `tests/client-resources.test.ts`：1 条/多条拼行、22 条时以 `resourceSyncAheadMore` 收尾、其他状态保持 `标签 · 说明`。
- `scripts/native-resource-state-checks.mjs`：真实资源卡片 `本地领先 1 个提交` 悬停后，tooltip 文本严格等于 `标签\n<hash> panel commit`（中英各一次），并断言气泡高度 ≥ 2 行（20px 行高）且不超出窗口。

## 证据

- `resource-ahead-commits-tooltip-zh.png`：中文界面悬停资源卡片领先标签。
- `resource-ahead-commits-tooltip-en.png`：英文界面同一位置。
- `result.json`：smoke:resources 运行结果（`ok: true`，含各语言/主题/窄窗口的布局测量）。

## 未覆盖 / 限制

- 截图来自 1180×820 宽窗口；窄窗口（420px）悬停未单独截图，但 tooltip 的窗口内边界与 50vw 上限由既有组件规则保证。
- 未做像素级人工阅图（本次执行模型不支持读图）；多行渲染由实时 DOM 文本断言 + 气泡高度断言 + 官方 `pre-line` 规则共同支撑。
- 项目资产面板的仓库标签共用同一函数，未单独做原生悬停用例。
