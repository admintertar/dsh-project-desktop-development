# 项目工作约定与验证流程

## 模型约束
思考请使用中文

## 仓库边界

- 插件功能（project / resource / task / skill / MCP / memory）在 `resources/dsh-plugin-project`。
- 窗口与应用层（Electron shell、窗口动作）在 `resources/dsh-project-desktop`。
- 官方源码快照只读，不修改。

## 验证

- 源码改动后运行：`cd resources/dsh-plugin-project && yarn run check`（typecheck + test + build）。
- UI 改动不能只靠测试与构建，必须做原生视觉验收：中英文案、主题状态、窄窗口、键盘行为。

## 长任务与后台作业（禁止空转等待）

**实测代价**：20 个历史会话中，`job_output` 对「无输出」作业的等待共 **38 次、累计 173.9 分钟**；
其中单个作业最长空转 48.9 分钟（`yarn run check` 正常只要 ~35 秒）。同期 96 条命令把输出管道进 `tail/head`。

**根因**：`cmd | tail -N` 里的 `tail` 必须读到 EOF 才能输出最后 N 行，
所以**后台运行时它永远不产生增量输出**，`job_output` 只会一直返回 `(no new output) [status: running]`；
同时管道的退出码是 `tail` 的 `0`，会掩盖真实失败（历史上有 875 条管道命令没有捕获真实退出码）。

### 硬规则

1. **禁止**把「管道进 `tail`/`head`」的命令用 `run_in_background: true` 启动。长任务改为落盘：
   `cmd > /tmp/<name>.log 2>&1; echo "EXIT=$?"`，再用 `job_output` 增量读，或另起一次**前台**调用 `tail -30 /tmp/<name>.log`。
2. **禁止**用 `| tail` 收尾而不捕获退出码。必须写成 `cmd 2>&1 | tail -30; echo "EXIT=${PIPESTATUS[0]}"`，或干脆不接管道。
3. **等待要短、要有梯度**：单次 `job_output wait:true` 的 `timeout_ms` 不超过 **120000**，按 30s → 60s → 120s 递进探测。
4. **连续两次 `(no new output)` 即判定卡死**，不再追加等待。处置顺序：
   `job_list` 看状态 → 前台 `tail -5 /tmp/<name>.log` 看落盘进度 → `ps` 确认进程是否还活着 → 必要时 `job_kill` 换策略重跑。
5. 基准量级：`resources/dsh-plugin-project` 的 `yarn check` ≈ 40 秒，`resources/dsh-project-desktop` 的 `yarn check` ≈ 35 秒
   （两仓库已统一到 Yarn 4.18.0，`yarn run check` 亦可触发，但以 `yarn check` 为准）。远超该量级即视为卡死。
6. 给长命令加硬超时：macOS **没有** GNU `timeout`，用 `gtimeout`（coreutils）或 `perl -e 'alarm 300; exec @ARGV' -- cmd`。

## 目录约定

- `.agent-project/`：项目元数据；`local.yaml`、`task-sources.yaml`、`resource-transaction.json` 属机器本地文件，已被忽略。
- `tasks/<任务名>/task.md`：v3 任务记录，附件放在同目录 `artifacts/`；任务身份不依赖会话。
- `memory/`：知识文档；只有 manifest 中 `memory[]` 声明的文件会被加载（单篇上限 64 KB，合计上限 128 KB）。
- `skills/`、`mcp/`：项目级能力目录。

### artifacts 只放结论级证据（运行期状态不进任务目录）

**实测代价**：一个原生验收任务把 Electron 探针的 `userData` 与运行目录写进了 `tasks/<任务>/artifacts/<探针>/run*/`，
Chromium 缓存把它撑到 **419 个文件**；项目资产提交直接报 **「请求超过 64 KiB，请缩小配置内容。」**
（419 条路径 × ~150 字符 ≈ 60 KB+，明细清单本身就超了请求体上限）。清理到 38 个文件后才正常。

硬规则：

1. 探针/冒烟/开发壳的**运行期目录一律放 `%TEMP%`**（或仓库被忽略的 `.runtime/`），绝不放进 `tasks/<任务>/artifacts/`。
   典型雷区：`app.setPath('userData', <任务目录>)`、`--remote-debugging-port` 的 profile、Playwright/Electron 的 `user-data`、
   下载缓存、`node_modules`、解包产物。
2. `artifacts/` 里只放**结论级证据**：一份报告 + 每个结论 1~2 张截图 + 关键日志/JSON。过程截图（同一效果的中间版本）随手删。
3. 放证据前后各查一次数量与体积，超标先瘦身再提交：
   ```powershell
   (Get-ChildItem tasks\<任务> -Recurse -File -Force | Measure-Object).Count
   ```
4. 任务记录的 artifacts 索引引用的文件必须真实存在；删除时同步索引，或只删未被索引引用的文件。

## 本地插件 UI 迭代

改插件界面**不要**走「提交 → bump lock → 重新导出 `.upstream/project` → 构建」那套，用开发期开关直接从本地工作区编译：

```sh
cd resources/dsh-project-desktop
DSH_PROJECT_PLUGIN_SOURCE=../dsh-plugin-project yarn run build
DSH_PROJECT_DESKTOP_USER_DATA=/tmp/dsh-dev-shell yarn start -- /path/to/project
```

- 未提交的插件改动立即进入壳。每次改完重新 build，壳刷新页面即可；仍加载旧 bundle 时重启壳。
- 该开关只影响开发：跳过固定树校验（改为仓库身份校验 + 警告），把 `projectLocalSource` 写进 `dist/build.json`，**打包流程在设置它时直接拒绝**。
- 壳的原生冒烟（`smoke:*`）验证的是 lock 里的插件提交而非工作树；要验证本地改动需同时设置该变量。
- 并行启动开发壳必须用 `DSH_PROJECT_DESKTOP_USER_DATA` 隔离 userData：已安装的 app 持有默认目录的单实例锁，直接 `yarn start` 会静默退出。

## 版本 pin 与发布

- `resources/dsh-project-desktop/upstream.lock.json` 的 `project.commit/tree` 决定壳构建与打包使用哪个插件提交。日常插件开发不必改它，**发布时才 bump**。
- **改 lock 和 push 插件必须是同一个动作。** `scripts/ci-plan.mjs` 把 pin 直接作为 GitHub Actions checkout 的 `ref`，pin 指向未推送的提交会让打包工作流在 checkout 阶段直接失败。正确顺序：先 push 插件提交 → 把 lock 指到已推送的提交 → 再 push 壳。
- pin 落后期间 CI 验的是「壳 + 旧插件」，壳与新插件的组合要等 bump 后才第一次被 CI 验证。建议在候选发布时就 bump，而不是最终 publish 时才 bump。
- bump 后必须重算并重导：`git -C resources/dsh-plugin-project rev-parse <commit>^{tree}` 得到 tree；再删除 `.upstream/project` 后重新导出（`scripts/setup.mjs` 的 snapshot 在目标已存在时会静默跳过，直接跑 setup 会沿用旧快照）；最后 `yarn run verify:upstream` 校验。

## 禁止事项

未经明确要求，不重写运行中的 Profile、不发布仓库、不改变仓库可见性、不 push 到上游。

