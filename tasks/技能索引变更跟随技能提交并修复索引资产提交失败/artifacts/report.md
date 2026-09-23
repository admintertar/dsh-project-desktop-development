# 技能索引变更跟随技能提交 — 验收报告

任务：`task-5f696fdc-d0e3-4755-b568-30e4b5fafcd6`（技能索引变更跟随技能提交并修复索引资产提交失败）

## 结论

`skills/index.yaml` 的启停变更不再作为名为「index.yaml」的独立技能资产出现，而是归属到对应技能资产并随其提交。
原先「勾选该资产提交 → `git commit` 报 nothing to commit」的缺陷已消失；提交技能资产时索引按所选技能精确重建
（其他技能保持 HEAD 状态），且同一资产的其他路径（例如新增的 `SKILL.md`）一并提交。

## 改动

插件 `resources/dsh-plugin-project`：

- `src/project-changes.ts`：按 HEAD 与工作区索引的显式条目差异，把 `skills/index.yaml` 归属到 `skill:<name>`；
  仅开关变化时也会生成以技能名命名的资产；索引损坏或无法归属（如纯格式编辑）时保留 `skill:index.yaml` 兜底条目。
- `src/project-staging.ts`：新增 `assetSkillName()`，把「该资产是否按技能名重建索引」变成可测的纯函数。
- `src/resource-api.ts`：把 HEAD 与工作区的索引文本放进 `ProjectChangeContext`；兜底 `index.yaml` 资产不再按技能名重建。
- `src/resource-sync.ts`：`resolveStaged` 返回内容时，仍对资产中其余路径执行 `git add -A`。
- `src/project-skills.ts`：`setEnabled(name, true)` 删除显式条目，关闭再启用后索引回到 HEAD、无残留 diff。
- `tests/project-changes.test.ts`、`tests/project-skills.test.ts`：新增 5 条回归测试。

壳 `resources/dsh-project-desktop`：

- `scripts/native-resource-state-checks.mjs`：新增 3 条断言——技能分组里不出现 `index.yaml` 卡片、提交内容包含
  `skills/index.yaml`、提交后 `skills/` 无残留；并更新 fixture 注释。
- 壳工作树另有其他任务未提交的改动，本次未触碰。

## 验收

1. 插件单测/构建：`yarn check` → 308 tests、pass 308、fail 0，typecheck 与 build 通过（`plugin-check.log`）。
   其中回归测试：`ok 130`（开关变更归属技能）、`ok 131`（新增技能保留 added 状态，索引作为次要路径）、
   `ok 132`（无法归属时仍可见）、`ok 133`（共享文件资产同时提交其他路径）、
   `ok 134`（兜底索引资产按路径提交，不再写回 HEAD）、`ok 192`（启用即删除条目、无残留）。
2. 原生验收：以 `DSH_PROJECT_PLUGIN_SOURCE=../dsh-plugin-project` 构建壳后运行 `yarn run smoke:resources`
   （真实 Electron 壳 + 真实 Host + 真实 Git），退出码 0（`native-check.log`）。
   - 新增断言全部通过：技能分组无 `index.yaml` 卡片；提交 `skills/index.yaml` 与 `SKILL.md` 同一条提交；提交后 `skills/` 干净。
   - 布局测量 16 组（中/英 × 明/暗主题 × 1180 与 420 窄窗），均无 body 溢出、行未越出视口（`native-result.json`）。
   - 截图：`project-changes-selection.png`、`project-changes-plan-tooltip.png`、`project-changes-after-commit.png`
     （中文亮色宽窗 `project-changes-zh-light-1180.png`、英文暗色窄窗 `project-changes-en-dark-420.png`）。

## 限制

- 本机为 macOS arm64；Windows 结果需另行验证。
- 本会话模型不支持读取图片，验收结论取自脚本对实时 DOM、提交计划与 Git 提交内容的断言，截图供人工复核。
- 原生验收用当前壳工作树（含其他任务未提交改动）构建，不是固定 pin 组合。
