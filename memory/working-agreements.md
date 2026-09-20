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

## 本地插件 UI 迭代

改插件界面**不要**走「提交 → bump lock → 重新导出 `.upstream/project` → 构建」那套，用开发期开关直接从本地工作区编译：

```sh
cd resources/dsh-project-desktop
DSH_PROJECT_PLUGIN_SOURCE=../dsh-plugin-project npm run build
DSH_PROJECT_DESKTOP_USER_DATA=/tmp/dsh-dev-shell npm start -- /path/to/project
```

- 未提交的插件改动立即进入壳。每次改完重新 build，壳刷新页面即可；仍加载旧 bundle 时重启壳。
- 该开关只影响开发：跳过固定树校验（改为仓库身份校验 + 警告），把 `projectLocalSource` 写进 `dist/build.json`，**打包流程在设置它时直接拒绝**。
- 壳的原生冒烟（`smoke:*`）验证的是 lock 里的插件提交而非工作树；要验证本地改动需同时设置该变量。
- 并行启动开发壳必须用 `DSH_PROJECT_DESKTOP_USER_DATA` 隔离 userData：已安装的 app 持有默认目录的单实例锁，直接 `npm start` 会静默退出。

## 版本 pin 与发布

- `resources/dsh-project-desktop/upstream.lock.json` 的 `project.commit/tree` 决定壳构建与打包使用哪个插件提交。日常插件开发不必改它，**发布时才 bump**。
- **改 lock 和 push 插件必须是同一个动作。** `scripts/ci-plan.mjs` 把 pin 直接作为 GitHub Actions checkout 的 `ref`，pin 指向未推送的提交会让打包工作流在 checkout 阶段直接失败。正确顺序：先 push 插件提交 → 把 lock 指到已推送的提交 → 再 push 壳。
- pin 落后期间 CI 验的是「壳 + 旧插件」，壳与新插件的组合要等 bump 后才第一次被 CI 验证。建议在候选发布时就 bump，而不是最终 publish 时才 bump。
- bump 后必须重算并重导：`git -C resources/dsh-plugin-project rev-parse <commit>^{tree}` 得到 tree；再删除 `.upstream/project` 后重新导出（`scripts/setup.mjs` 的 snapshot 在目标已存在时会静默跳过，直接跑 setup 会沿用旧快照）；最后 `npm run verify:upstream` 校验。

## 禁止事项

未经明确要求，不重写运行中的 Profile、不发布仓库、不改变仓库可见性、不 push 到上游。
