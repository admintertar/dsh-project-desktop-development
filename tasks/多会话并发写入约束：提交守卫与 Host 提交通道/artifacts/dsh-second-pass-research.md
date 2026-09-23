# DSH 第二轮调研：并发写入的真实强制边界

日期：2026-09-23

范围：官方 DSH `0.1.5-rc.2`（项目当前版本）、registry 的 `0.1.5-rc.3` 与
`0.1.7-alpha.2`、官方主分支 `00102833`，以及社区
`deepseek-harness-security-guard`、`dsh-task-worktree`、`dsh-worktree`。
第三方仓库只读取源码和元数据，未安装、未构建、未执行。

## 1. 官方已经提供、可直接复用的能力

`@deepseek-ai/dsh-base` 默认组合已经挂载：

- `dsh-fs-observation-policy`：每个 Agent 分别记录读到的文件版本；未读文件拒绝覆盖，
  读取后被外部改动的文件以 `FS_STALE_VERSION` 拒绝，底层是 CAS。
- `dsh-fs-sandbox`：文件工具按会话的 `SessionHeader.cwd` 限制写入根。
- `dsh-bash-sandbox` / `dsh-pwsh-sandbox`：子进程继承同一文件写入边界。
- `dsh-sandbox-policy`：默认 `workspace-write`。
- `dsh-permission-presets`：默认 `workspace-write + ask`，也提供 `read-only` 与
  `danger-full-access`。
- `ctx.tools.guard()`：在 `tools/pre-execute` 之后执行的单调 deny-only 守卫；可按
  Agent scope 注册。

因此，“他人修改后仍用文件工具覆盖”已有一部分官方机制可复用，不需要重新设计版本
比较。但官方 Agent Teams 设计文档明确承认：Bash、formatter、generator 与外部 writer
会绕过文件工具的 CAS；`writeScopes` 只是诊断，不是锁，也不授权写入。

## 2. 官方明确不提供的能力

官方主分支的 Agent Teams 决策明确写道：worktree isolation 不是 Harness runtime 行为；
自动创建 worktree 被拒绝，因为分支、合并、ignored 文件、工装与清理属于 deployment
决策。

当前版本与最新 alpha 都有以下边界：

- `tools/pre-execute` 只能 `allow` / `deny` / `ask`（alpha 另有 `cancel`），不能改写
  `exec.arguments`。
- `SandboxExecutionPolicy` 只有一个 `workspaceRoot`；`workspace-write` 是“整个根目录 +
  平台临时目录可写”，没有根内的 protected/excluded path。
- 文件沙箱只治理文件效果；网络和进程可见性不在其策略词汇内。
- 官方没有 Git/worktree 产品能力，也没有 Git 命令级策略。

`0.1.5-rc.2 → 0.1.5-rc.3` 的相关公开类型没有变化；`0.1.7-alpha.2` 虽扩展了工具错误
信息、PTC 与异步 sandbox provider，但以上边界仍在。

## 3. 裸 Git 的结论

`tools/pre-execute` 能看到 Bash 的外层 `command` 字符串，因此可以拦截明显的
`git add/commit/reset/push`。但它看不到子进程最终行为；`node -e`、脚本、alias、绝对路径
Git 或任意程序都能产生同样的文件效果。命令字符串规则只能作为纵深防御，不能被描述为
不可绕过的提交边界。

`commit-guard.mjs` 同理：它适合作为 Host 或可信人类调用的提交执行器，但只要通用 Bash
仍可写 `.git`，它就不是“唯一入口”。真正的强制边界必须是：

1. Agent 进程不能写目标仓库的 Git metadata；
2. Host 提交服务在 Agent 沙箱之外持有写权限；
3. `tools/pre-execute` 规则只负责早拒绝和可读诊断。

## 4. linked worktree + DSH 沙箱实测

使用项目当前 `0.1.5-rc.2` 的真实 `LocalSandboxProvider`（macOS Seatbelt，
`enforcement: full`）执行两个最小探针。

### 形态 A：会话 cwd = linked worktree

沙箱 `workspaceRoot` 为 linked worktree。common-dir 位于主 checkout 的 `.git`，在沙箱根
之外。

| 操作 | 结果 |
| --- | --- |
| `printf ok > probe.txt` | 成功 |
| `git add probe.txt` | 失败：无法创建 common-dir 下的 `index.lock`，`Operation not permitted` |
| `git commit --allow-empty ...` | 同样失败 |
| `printf replaced > .git` | 成功 |

说明：形态 A 天然阻止 Agent 写 linked worktree 的 index/refs/objects，但 worktree 根内的
`.git` 指针文件仍可被破坏。该破坏不会授予 common-dir 写权限，却会让 checkout 失联，
因此仍需结构化文件工具守卫或根内 protected-path 沙箱扩展。

### 形态 B：会话 cwd = 项目根，模型用绝对路径操作 linked worktree

沙箱 `workspaceRoot` 仍为项目根；主仓库 `.git` 和项目根下的 worktree 都落在可写范围。

| 操作 | 结果 |
| --- | --- |
| 写 linked worktree 文件后执行 `git -C <worktree> add probe.txt` | 成功，文件进入 index |

所以形态 B 不提供机械 Git metadata 隔离。若产品要求“Agent 只能改文件、只能由 Host
提交”，必须优先形态 A，或扩展 DSH 沙箱支持根内 protected paths；只靠绝对路径纪律不够。

## 5. 社区实现复核

- `deepseek-harness-security-guard` 证明 `tools/pre-execute` + `ctx.tools.guard()` 可产品化，
  但其命令判断仍是字符串/规则特征，不是子进程效果隔离；其 peer range 也不直接匹配当前
  DSH 预发布版本。
- `dsh-task-worktree 0.4.2` 仍未注册提交守卫，仍向 `.gitignore` 追加目录，并以裸 Git
  完成 finish/bring-back；manifest 是 tmp+rename，但没有跨进程锁。
- `dsh-worktree 0.1.0` 仍把 remove 暴露给模型，并把旧版 DSH 基础设施放在
  `dependencies` 中，不适合直接复用。

## 6. 对产品方案的修正

1. 把 `commit-guard` 定位为提交执行器，不再声称仅凭包装命令形成唯一入口。
2. P0 强制点增加“Agent 不能写 Git metadata”；共享主工作树若保留通用 Bash，需要新增
   跨平台 protected-path 沙箱能力，否则只能宣称 best-effort。
3. C4 对文件工具直接复用 `dsh-fs-observation-policy` 的 read-before-write + CAS；Bash、
   formatter 和 generator 必须进入隔离工作树或更强沙箱。
4. P3 若以机械隔离为目标，形态 A（会话 cwd=worktree）应为默认；形态 B 只能作为兼容
   方案。
5. 形态 A 还要保护 worktree 根的 `.git` 文件，并禁止会话切换到
   `danger-full-access`；Windows 后端报告 `partial`，必须单独做实机验收。

## 7. 主要来源

- 官方 Agent Teams 决策：
  <https://github.com/deepseek-ai/deepseek-harness/blob/master/.agents/notes/implemented/feature/2026-08-05-agent-teams.md>
- 官方工具流水线：
  <https://github.com/deepseek-ai/deepseek-harness/tree/master/packages/core/tools>
- 官方文件观察策略：
  <https://github.com/deepseek-ai/deepseek-harness/tree/master/packages/fs/fs-observation-policy>
- 官方沙箱策略与本地后端：
  <https://github.com/deepseek-ai/deepseek-harness/tree/master/packages/sandbox>
- 官方基础组合：
  <https://github.com/deepseek-ai/deepseek-harness/tree/master/packages/bundle/base>
