# 资源标签悬停气泡去掉重复的「本地领先 n 个提交」

## 结论

资源卡片 / 项目资产面板的同步标签在 `ahead` 状态下，悬停气泡**只列领先的提交**（每条一行），
不再重复标签已经写着的「本地领先 n 个提交」；超过 20 条时仍以中英「另有 n 个本地提交」/
「{count} more local commits」收尾，其余状态保持原来的「标签 · 说明」。卡片上的橙色标签文案不变。

## 改动

| 位置 | 改动 |
| --- | --- |
| `dsh-plugin-project/src/client/resource-ui.ts` | `resourceSyncTooltip` 在提交列表非空时不再把 `label` 作为首行；注释同步说明「不重复标签文案」 |
| `dsh-plugin-project/tests/client-resources.test.ts` | 两条 ahead 断言去掉 `label\n` 前缀，用例名与注释改为「不重复标签」 |
| `dsh-project-desktop/scripts/native-resource-state-checks.mjs` | 原生悬停断言由 `标签\n<short hash> <标题>` 改为严格等于 `<short hash> <标题>`（相等同时证明提交被列出、计数行没有重复出现）；气泡高度断言由 ≥2 行改为 ≥1 行 |

未改：Host 侧 `aheadCommits` 读取与契约、标签文案与 tone、`resourceSyncAheadMore` 文案。

## 验证

1. **插件单测/类型/构建（worktree 内）**
   `yarn check` → EXIT=0，308 个测试全部通过（日志 `/tmp/plugin-check-tooltip.log`）。
   其中 `tests/client-resources.test.ts` 断言 ahead 悬停文本为 `aaaaaaa first\nbbbbbbb second`、
   截断时为 `…\nresourceSyncAheadMore`，其他状态仍为 `label · description`。
   操作入口是纯函数 `resourceSyncTooltip`，回调形参 `label` 现在只用于回退分支。
2. **原生实时 DOM 验收（真实 Electron 窗口）**
   `DSH_PROJECT_PLUGIN_SOURCE=<worktree> yarn build` → `yarn smoke:resources` → EXIT=0，`ok: true`。
   断言在真实资源卡片上（`Resource states-backend`，本地领先 1 个提交）悬停，气泡 `textContent`
   严格等于 `<hash> panel commit`，中英各一次；并用 `capturePage` 留下截图：
   - `resource-ahead-commits-tooltip-zh.png`：标签仍写「本地领先 1 个提交」，气泡只有 `a74938a panel commit`
   - `resource-ahead-commits-tooltip-en.png`：标签仍写「1 local commits」，气泡只有 `a74938a panel commit`
   截图里可同时看到「标签保留、气泡不再重复」两件事，即本次改动的两侧边界。
3. **证据与提交的对应关系**
   原生验收用的 worktree 源码与插件提交 `4633866` 的两处文件 `git hash-object` 逐字节相同
   （`resource-ui.ts` = `e13c04b2…`、`client-resources.test.ts` = `9b6bb874…`），因此截图对应的是该提交。
4. **环境复原**：验收后已用不带 `DSH_PROJECT_PLUGIN_SOURCE` 的 `yarn build` 把壳的 `.cache/runtime`
   恢复成锁定插件构建（`dist/build.json` 已无 `projectLocalSource`），worktree 与其分支已移除。

## 证据清单

- `artifacts/report.md`（本文件）
- `artifacts/resource-ahead-commits-tooltip-zh.png`、`artifacts/resource-ahead-commits-tooltip-en.png`
- `artifacts/result.json`（`smoke:resources` 全量结果：`ok: true`，含各语言/主题/宽度布局测量）

探针运行期目录（Electron `userData`、`.runtime/resource-states-*`）留在壳仓库被忽略的 `.runtime/` 下，未进任务目录。

## 未覆盖 / 注意事项

- **pin 与 push 必须同一动作**：壳的原生断言现在要求新插件，而 `upstream.lock.json` 的
  `project.commit` 仍是 `d45b54f`。两个提交都未 push；推送时应先 push 插件 `4633866`，
  再把 lock 指到它并重导 `.upstream/project`（`verify:upstream` 通过后）再 push 壳，
  否则 CI 的 `Verify Resources on Windows` 会用「壳 + 旧插件」跑新断言而失败。
- 项目资产面板的同一处悬停文案（`ProjectChangesPanel`）本次只做了纯函数级覆盖，**没有**单独的原生悬停截图。
- 未验证主题（明/暗）× 窄窗口下的气泡布局；气泡仍复用官方 `Tooltip`，行数与宽度由官方布局决定。
- 上一轮遗留：`aheadCommits` 上限 20 条这一路径没有新的原生用例（仍由 `tests/resource-sync.test.ts` 覆盖）。