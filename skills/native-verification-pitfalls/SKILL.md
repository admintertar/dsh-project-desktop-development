---
name: native-verification-pitfalls
description: 原生测试与验收踩坑手册：先弄清判定器在验证什么（别拿 35 项全景 smoke 当回归判定器）、为什么「主树通过 / worktree 失败」不是干净对照（.cache 是 junction，两棵树共用产物）、worktree 里为什么验证不了壳的 Host 插件改动、空 worktree 必须先 build、A/B 必须复刻被测代码的执行路径（否则量到的是实验装置的差异）、正交变量与独立目标目录、用 Shell COM/Win32 IsWindowVisible 与实时 DOM 做客观判定而不是肉眼和截图，以及修复类改动的三层验证（纯函数单测 → 真实进程探针 → 端到端，做不到就如实写明未覆盖）。
whenToUse: 跑 smoke:* / probe:* 或任何原生 Electron 验收时；判断某次测试失败是不是自己改动引入的；需要在新 worktree 里验证壳或插件改动；设计 A/B 对照实验；需要客观证明「窗口/界面/文件管理器真的动了」；写修复的验证证据时。
---

# 原生测试与验收踩坑手册

## 零、第一原则：先弄清判定器在验证什么

**拿整个全景验收脚本当「我的改动是否回归」的判定器，是本次最大的时间浪费来源。**

`yarn smoke:native`（`scripts/smoke-native.mjs` → `src/app/main.mjs` 的 `--native-smoke` 分支 → `scripts/native-smoke-case.mjs`）
是一次**35 项端到端全景验收**：欢迎窗口、创建向导、远端克隆、双项目窗口、顶栏菜单、主题/语言、模型页、
崩溃隔离、恢复助手、检查点恢复、重启确认、安全模式……被测改动通常只涉及其中一两项。

实测代价：为验证「启动埋点」这一个改动，反复运行 `smoke:native`，而每次失败都发生在
`scripts/native-restart-checks.mjs:39` 的 `waitDialog`（等官方重启确认对话框）——与埋点毫无关系。

规则：

1. 跑之前先读三个文件：入口脚本、主进程的 smoke 分支、失败点所在的子检查脚本；写下「它验证什么、失败点属于哪一项」。
2. 失败签名要精确到 **文件:行 + 标签**。本项目的 `until(check, label)` 会把 label 带进
   `Timed out: <label>`（例如 `Timed out: official restart confirmation 1`），别停在「smoke 挂了」。
3. 单项验证优先用窄探针（`probe:*`），而不是全景脚本。

## 一、「主树通过 / worktree 失败」不是干净对照

`.cache`、`.upstream`、`node_modules`、`.yarn` 在本项目里常是指向主 checkout 的 **junction**，
两棵树因此共用同一份构建产物 —— 在主树跑的「基线」很可能也是改过的 bundle。

- 实测：`dist/project-files.mjs` 在三棵树里的哈希各不相同（9272 / 9437 / 9597 字节），
  而 `.cache/runtime/dsh-project-shell` 只有一份。
- 真正的对照只有两种：**同一路径下切换代码**（stash / checkout / 复制文件），或**确认产物来源**后再下结论。
- 判断某次失败是否自己引入时，先把「与代码无关的差异」逐个排掉并**记下来**（回退可疑文件、清残留进程、换路径……），
  本次正是靠「回退 `native.mjs` 后同样失败」把它排除的。

## 二、worktree 里验证不了壳的 Host 插件改动

`.cache/runtime/dsh-project-shell/index.mjs` 的内容是一行：

```js
export * from '../../../src/desktop-adapter/stable/shell-host.mjs';
```

`.cache` 是指向主 checkout 的 junction → 这个相对路径解析回**主树**的 `src/`。
于是 worktree 里起的 Host 加载的是**主树的** `shell-host.mjs`：在 worktree 里断言「我们的 Host 插件接线生效」必然失败，
而且失败原因与代码无关。

- 受影响的：经 `dsh-project-shell` 间接加载的 Host 侧插件（`shell-host.mjs`、`windows-reveal.mjs` 的接线等）。
- 不受影响的：由 `repository` 直接加载的（`src/app/main.mjs`、`scripts/*`）——`node scripts/smoke-native.mjs` 用的是 worktree 的 `repository`，验证有效。
- 结论：**改 Host 侧插件就在主树验证**（提交后跑探针），或在 worktree 用独立 `.cache`（拷贝代价高，通常不值得）。

## 三、空 worktree 必须先 build

未构建的 worktree 起 Electron 会抛
`ERR_MODULE_NOT_FOUND: <worktree>/dist/project-files.mjs`，并弹出原生错误框
**「App threw an error during load」** —— 用户会看到这个框，别把它当成产品崩溃。
先 `yarn build`，或直接跑完整的 `yarn check`。

## 四、A/B 必须复刻被测代码的执行路径

**实测教训**：为了判断 explorer 为什么不开窗，先用 PowerShell
`Start-Process -FilePath explorer.exe -ArgumentList '/select,', $url` 做对照，得出
「`file://` URL 打不开、真实路径能打开」的结论 —— 并据此写进了任务记录。
改用与官方**完全相同**的 Node `execFile` 重做后，4 组正交实验显示：

| 组合 | 命中窗口 | 其中可见 |
|---|---|---|
| `file://` URI + `windowsHide:true`（官方实现） | 1 | **0** |
| 真实路径 + `windowsHide:true` | 1 | **0** |
| `file://` URI + `windowsHide:false` | 1 | **1** |
| 真实路径 + `windowsHide:false` | 1 | **1** |

可见性**只跟随 `windowsHide`**，与 URL 还是路径无关。第一次量到的是**实验装置**的差异，不是被测代码的差异。

规则：执行方式（`execFile` vs `Start-Process`、参数拼接、`windowsHide`、cwd、环境变量）必须与被测代码一致；
做不到就在结论里明说这是近似，不要当成定论。

## 五、正交变量 + 每个组合用独立目标

- explorer `/select` 会**复用**已存在的同目录窗口 → 只看「窗口数量变没变」会误判（本次就吃过：数量不变被当成没动作）。
- 做法：每个组合用一个**独立的新目录**，按 `LocationURL` 区分目标，逐个判定。

## 六、判定要客观：COM / Win32 / 实时 DOM，不是肉眼和截图

- **窗口存在 ≠ 用户看得见**。`Shell.Application.Windows()` 能枚举到窗口，用户的可见性要问 `IsWindowVisible(hwnd)`：
  ```powershell
  Add-Type 'using System;using System.Runtime.InteropServices;public class W{[DllImport("user32.dll")]public static extern bool IsWindowVisible(IntPtr h);}'
  $s = New-Object -ComObject Shell.Application
  $s.Windows() | ForEach-Object { [pscustomobject]@{ Url=$_.LocationURL; Visible=[W]::IsWindowVisible([IntPtr]$_.HWND) } }
  ```
  本次正是靠它拿到「5 个窗口存在但 `visible=False`」这一决定性证据 —— 肉眼只会得出「点了没反应」。
- 界面类结论优先读**实时 DOM / 计算样式**，不要从截图反推（可能被降采样，也可能是别的窗口在上面）。
- 相关：AGENTS.md 的「先证明前台窗口，再谈像素」。

## 七、修复类改动的三层验证

1. **纯函数单测**：把可测逻辑从插件里抽出来（如 `windows-reveal.mjs`），测参数、选项与错误语义。
2. **真实进程探针**：断言「接线生效」，例如在真实 Host 进程里断言适配已安装（`yarn probe:reveal-adapter`）。
   注意这类探针在 worktree 里可能跑不出来（见第二节）。
3. **端到端**（真实点击 / 真实窗口）：成本最高。**做不了就如实写明未覆盖**，不要用前两层冒充第三层。

## 八、测量工具本身会骗你（PowerShell 四例）

- `git archive --format=tar <ref> | tar -xf -`：管道在 PowerShell 里损坏（`Damaged tar archive (bad header checksum)`），
  快照会被导成空目录 → 改成 `git archive -o <file> <ref>` 再 `tar -xf <file>`。
- `git show HEAD:<file> > <file>`：PowerShell 重定向写出 **UTF-16LE**，字节翻倍、`node --check` 报 `Unexpected reserved word`
  → 用 `git checkout -- <file>` 还原，或事先 `Copy-Item` 备份；不要用重定向改源码。
- `"$f.log"` 被解析成 `$f:`（驱动器限定符）→ 写 `"${f}.log"`。
- PowerShell 5.1 没有 `<<<` here-string → 提交信息先写文件，再 `git commit -F <file>`。
- 更全的见技能 `windows-powershell-51`。

## 九、后台作业与退出码

- `cmd | tail` 的后台作业**永远不产生增量输出**（tail 要读到 EOF），且退出码变成 tail 的 0 → 落盘：
  `cmd > <log> 2>&1; echo "EXIT=$?"`。
- 批量清理进程可能**连坐自己的作业链**：本次用 `Stop-Process -Name electron` 清残留，结果自己的后台 pwsh 作业被 killed；
  只杀匹配特定 runtime 路径的进程，或干脆接受不清理。
- 更全的见 AGENT.md 的「长任务与后台作业」硬规则。

## 十、两个实例（可直接对照）

- **worktree 下 `smoke:native` 必失败**：`waitDialog` 用 `runtimePackage`（worktree 拼写）拼出期望的对话框 URL，
  而官方对话框模块经 `.cache` junction 解析后，Electron 的 `webContents.getURL()` 报告的是规范化路径
  → 已显示的对话框被误判为「不存在」，等到 20s 超时（偶发表现为恢复后窗口几何 `1280 !== 980`）。
  修法：比较前 `realpathSync`。同一 worktree 修复前多次失败、修复后一次通过。
- **Windows「在文件资源管理器中显示」点了没反应**：官方 runner 对所有 native 命令用
  `execFile(cmd, args, {windowsHide:true})`，而 `explorer.exe` 是唯一「被启动进程本身就是窗口进程」的场景，
  新窗口被隐藏；同菜单的「用默认应用打开」走 powershell 因而不受影响。
  定位靠 COM/Win32 客观判定 + 4 组正交实验；修法是在壳的 Host 插件里覆盖 `sessionController.revealPath`，改用 `windowsHide:false`。
