# 项目工作约定与验证流程

## 仓库边界

- 插件功能（project / resource / task / skill / MCP / memory）在 `resources/dsh-plugin-project`。
- 窗口与应用层（Electron shell、窗口动作）在 `resources/dsh-project-desktop`。
- 官方源码快照只读，不修改。

## 验证

- 源码改动后运行：`cd resources/dsh-plugin-project && npm run check`（typecheck + test + build）。
- UI 改动不能只靠测试与构建，必须做原生视觉验收：中英文案、主题状态、窄窗口、键盘行为。

## 目录约定

- `.agent-project/`：项目元数据；`local.yaml`、`task-sources.yaml`、`resource-transaction.json` 属机器本地文件，已被忽略。
- `tasks/<任务名>/task.md`：v3 任务记录，附件放在同目录 `artifacts/`；任务身份不依赖会话。
- `memory/`：知识文档；只有 manifest 中 `memory[]` 声明的文件会被加载（单篇上限 64 KB，合计上限 128 KB）。
- `skills/`、`mcp/`：项目级能力目录。

## 禁止事项

未经明确要求，不重写运行中的 Profile、不发布仓库、不改变仓库可见性、不 push 到上游。
