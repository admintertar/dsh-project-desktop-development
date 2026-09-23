# 记忆写入路径：实现与验收证据 / Memory write path evidence

任务：`task-e3ccde1c-c8e5-4062-a5ae-7640d2682230`
范围确认：用户选择「全量：API create/delete + 面板新增/删除 + Agent 记忆工具 + 测试」。
实现提交：见任务记录 `commit-write-path`（`resources/dsh-plugin-project`）。

## 1. 实现了什么

| 层 | 变化 |
| --- | --- |
| 模型 `src/project.ts` | 新增 `createProjectMemory()` / `deleteProjectMemory()`；保留 64 KB 单篇、128 KB 总量、`memory/` 路径限制与真实目录（禁止软链）校验；文件与 manifest 声明一起写入，manifest 失败时回滚刚建的文件 |
| HTTP `src/project-api.ts` | `POST /api/project/memory` 支持 `create` / `update` / `delete`；单篇 > 64 KB 仍回复 `413 body-too-large`；删除动作不需要 content |
| Agent 工具 `src/memory-tools.ts` | `project_memory_list` / `create` / `update` / `delete`，与 `project_task_*` 一致：写操作要求调用会话的 `cwd` 等于项目根，读操作幂等；工具页归入「项目工具」分组 |
| 面板 `src/client/MemoryPanel.tsx` | 新增「新增知识文档」入口（斜体虚线加号按钮）与每张卡片的删除图标；新增弹窗（名称 + Markdown 原文 + 字节计数），删除走官方确认弹窗；中英文案、无障碍名称、Escape 关闭 |
| 共享适配 `src/tool-schema.ts` | 把 task 工具的 schema 投影抽成共享模块，memory 工具复用 |

## 2. 自动化验证

`cd resources/dsh-plugin-project && yarn run check` → `EXIT=0`（typecheck + test + build）。

- 293 个测试全通过（本轮新增 7 个记忆相关测试）。
- `tests/project.test.ts`：创建同时写文件与声明；重复 id / 重复路径 / 非法 id / 已存在文件被拒；64 KB 与 128 KB 上限；绝对路径、`..`、反斜杠、`memory//` 等越界路径被拒且无副作用；`memory/` 为软链时拒绝；删除只删声明与未被共享的文档。
- `tests/project-api.test.ts`：`create`（显式 id、匿名自动派生 id、越界路径 422、超限 413）与 `delete`（删除后 manifest 与文件同步、重复删除 422）。
- `tests/memory-tools.test.ts`：四个工具注册名、创建/列举/更新/删除闭环、越权会话与外部 cwd 被拒、超限与越界被拒。

## 3. 原生视觉验收（macOS arm64，Electron 开发壳）

方法：`DSH_PROJECT_PLUGIN_SOURCE=../dsh-plugin-project yarn run build` 后用隔离 userData 打开真实项目窗口（`hidden` + `showInactive`），断言基于**实时 DOM**，并按 1180 / 420 两种宽度截图。

四个组合（en/zh × light/dark）各通过以下断言：

1. 进入「Memory / 记忆」，种子文档卡片渲染 Markdown，编辑与删除图标带 `aria-label`（`Edit Native guide` / `删除Native guide`）。
2. 键盘：打开新增弹窗后焦点在弹窗内；`Escape` 关闭且不产生文档。
3. 新增：填写名称与 Markdown 原文，点固定底部的「Create / 创建」→ 卡片数 1→2，卡片名与内容出现（含中文名「发布约定」）。
4. 编辑：卡片内联编辑保存后回到渲染视图，新文本出现在卡片中。
5. 布局：两种宽度下 `document.body` 与面板均无横向溢出。
6. 删除：官方确认弹窗文案为「Delete knowledge document? / 删除知识文档？」，确认后卡片数 2→1，`memory/release-decisions.md`（或中文名的 `memory/memory.md`）与 manifest 声明同时消失。

截图（结论级）：`memory-en-light-1180.png`、`memory-zh-dark-1180.png`、`memory-en-light-420.png`、`memory-zh-dark-420.png`；
逐项布局与删除结论：`native-result.json`。

未覆盖 / 限制：

- 本次模型不支持读图，PNG 只作为人工复核证据，未由 Agent 逐像素检查；界面行为结论全部来自实时 DOM 断言。
- Agent 记忆工具只经工具运行时测试验证，未在真实对话轮次中调用。
- 验收期间另一会话正占用共享开发壳构建（`dist/build.json` 指向 `/tmp/dsh-scrollbar-worktree`）；本轮先按其源码快照备份、用本插件源码重建后再验收，结束后已用 `/tmp/dsh-scrollbar-worktree` 重建还原。
