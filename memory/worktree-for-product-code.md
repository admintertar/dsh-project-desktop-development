# 改产品代码走独立 git worktree（用户约定）

## 规则

**要修改产品代码时，先在独立 `git worktree` 里改，不要在 `resources/dsh-project-desktop` / `resources/dsh-plugin-project` 的主工作树上直接改。**

- 产品代码 = 会被打包/发布的东西：`src/**`、`scripts/**`（构建、打包、冒烟检查）、`tests/**`、`docs/**`、配置与 lock。
- 主工作树是**多会话共享**资源：别的会话随时可能 `git add` / `git commit` / 继续编辑（实测同一时刻有 4 个文件被另一会话改着）。
  在主工作树上直接改产品代码，既容易被别人的 `git add -A` 卷进提交，也会把半成品状态暴露给别人的构建与冒烟。
- 独立 worktree 里改完 → 在 worktree 内跑 `yarn check`（必要时 `yarn smoke:*`）→ 回到主工作树只做**精确暂存**（逐个路径 `git add`，看 `git diff --cached --stat` 核对）→ 提交。

## 例外

- 只改**验证脚本的断言/等待方式**这类不进入产物、且不改变产品行为的改动，可以在主工作树上直接改并提交（例如 `scripts/native-guide-checks.mjs` 里的 `Promise.race` 等待修复）。
- 纯任务记录与证据（`tasks/**`、`memory/**`）照常直接写。

## 有用的命令

```powershell
# 建立隔离 worktree（分支名自取；放主工作树之外或忽略目录）
git -C resources/dsh-project-desktop worktree add ..\wt-dsh-<topic> -b fix/<topic>
# 在 worktree 内验证
cd ..\wt-dsh-<topic>; yarn check
# 收工：主工作树里精确提交自己的文件，再移除 worktree
git -C resources/dsh-project-desktop add <自己的文件...>
git -C resources/dsh-project-desktop worktree remove ..\wt-dsh-<topic>
```

Windows 注意：worktree 内跑壳的 `yarn check` 需要 `node_modules`/`.upstream`/`.yarn` 可达（可用 junction），且 `.runtime` 必须是**真实目录**而不是 junction——否则壳里对临时路径的断言会拿主 checkout 去比较而失败（见 `resources/dsh-project-desktop/docs/validation.md` 的 Failed approaches）。
