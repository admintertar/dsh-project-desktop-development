---
name: git-pitfalls
description: 多会话共享同一工作树时的 Git 踩坑手册：并发 git add -A 与别人的提交撞车、只提交自己 hunk 的安全拆法（git apply --cached，绝不重置工作树文件）、用 hash-object + update-index 精确改 index、nothing to commit 的判定与报错出口、status/reflog/show :path 的现场还原手法，以及本仓库「不 push、lock 与插件 push 必须同一动作」的提交纪律。
whenToUse: 在本项目的 Git 仓库里提交改动、只提交自己那部分文件或 hunk、怀疑别人的未提交改动混进自己的提交或从工作树消失、遇到 nothing to commit 或工作树突然变干净、中文路径显示成八进制转义时。
---

# Git 踩坑手册（多会话共享工作树）

前提：本项目的两个仓库（`resources/dsh-plugin-project`、`resources/dsh-project-desktop`）常被**多个会话同时**操作，
工作树是共享资源 —— 另一个 Agent 随时可能执行 `git add -A && git commit`。下面的规则都围绕这个前提。

## 第一原则

**不要在共享工作树上「重置后再重放」。** 想只提交自己那部分时，改 **index**（`git apply --cached`），不要改工作树文件。
一旦把文件重置成 HEAD 版，另一个会话的 `git add -A` 就可能把这个中间状态当成终态提交，
别人的 hunk 会被挤出工作树并丢失。

## 一、并发提交撞车（本次实测）

- **现场**：为从混着两组改动的文件里只提交自己的 hunk，先 `cp` 备份，再
  `git show HEAD:<file> > <file>` 把工作树重置成 HEAD 版、只重放自己的改动。就在这个窗口里，另一会话执行了 `git add -A && git commit`。
- **结果**：我的 hunk 进了那个提交（表面顺利），但同一文件里别人的 12 行断言被排除在提交之外，
  且已从工作树消失 —— 提交信息声称该功能已完成，实际验收断言不在版本库里。
- **正确做法**：只改 index、不碰工作树：
  ```sh
  git diff -- <file> > /tmp/all.patch     # 完整改动
  # 从中挑出属于自己的 hunk 写成 /tmp/mine.patch（保留 diff --git 头）
  git apply --cached /tmp/mine.patch      # 只改 index，工作树保持原样（含别人的改动）
  git diff --cached --stat                # 确认 index 里只有自己的
  git commit -m '...'
  git status --porcelain                  # 别人的改动仍是未暂存状态，安全
  ```
- **兜底**：任何要改工作树的实验前先 `cp <file> /tmp/<file>.bak`。本次正是靠备份把那 12 行救回来。
- **补救**：`git reflog` 还原时间线，把备份与 `git show HEAD:<file>` 对比，重新 apply 丢失的 hunk，
  再补一个提交，提交信息写清「补回 X 遗漏的 N 行」。

## 二、只提交自己的文件

- **不要用 `git add -A` / `git add .`**：共享工作树里通常还躺着别的任务的改动。逐个列路径
  `git add <file1> <file2> ...`，再用 `git diff --cached --stat` 核对。
- 提交前先看**全量** `git status --porcelain`：`M ` 表示已暂存、` M` 只是工作树改动、`??` 未跟踪。
  第一位是 index、第二位是工作树，最容易看反。
- 提交后核对 `git show --stat --oneline HEAD`：文件数与行数要符合预期，多出来的就是夹带了别人的改动。

## 三、不动工作树也能改 index（本仓库的核心技巧）

共享文件的精确暂存就是这套做法：**把精确字节写进 index，工作树与其余审阅状态都不动**。

```sh
printf '%s' "$content" > /tmp/blob
blob=$(git hash-object -w -- /tmp/blob)          # 只写 blob，不改 index
git update-index --add --cacheinfo 100644 "$blob" skills/index.yaml
git commit --no-verify -m '...'
```

- 基准内容用 `git show HEAD:<path>` 读；该文件在 HEAD 不存在时命令会失败，要容错
  （`git show HEAD:path 2>/dev/null || true`）。
- `git show :<path>` 读 **index** 版本，`git show HEAD:<path>` 读 HEAD 版本，别混。
- 只 stage 共享文件时，**同一资产的其他路径仍要 `git add`**。`resource-sync.ts` 的 `resolveStaged`
  分支就踩过：一旦返回了精确内容就跳过 `git add -A`，同一资产里新增的 `SKILL.md` 不会被提交。

## 四、提交失败的语义

- `nothing to commit, working tree clean`：index 与 HEAD **没有差异**。典型来源是「按技能名重建共享文件」
  却重建出了 HEAD 原样内容。**它写在 stdout、退出码 1，stderr 往往为空** —— 只读 stderr 会误判成成功或莫名的失败。
- 脚本里用 `-c commit.gpgsign=false -c core.hooksPath=/dev/null` 避免签名与 hook 干扰；
  要在输出里看到中文路径（而不是 `\344\270\255` 这类八进制转义）再加 `-c core.quotePath=false`。
- 提交/合并需要 Git 身份；缺 `user.name` / `user.email` 时先 `git config`，否则报错很难懂。

## 五、本仓库的提交纪律

- 未经明确要求：**不 push、不发布、不改仓库可见性**。
- `upstream.lock.json` 的 pin 与插件 push **必须同一动作**：pin 指向未推送的提交会让 CI 在 checkout 阶段直接失败。
- 发布才 bump pin；bump 后删掉 `.upstream/project` 重新导出，最后 `yarn run verify:upstream` 校验。
- 任务记录用 `type: commit` 链接提交（仓库 URL + 完整 hash），不要复制源码进任务目录。
