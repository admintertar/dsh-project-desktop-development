# Windows 实机验证结论：打开探测、克隆导入与目录记忆

验证机器：Windows 11（NT 10.0.26200，AMD64）、Node.js v22.23.2、Windows PowerShell 5.1（无 pwsh）。
被测提交：壳仓库 `2bad7f300efef95e5803f346fb36850a71642947`（工作树干净），
其中包含本任务待验证改动 `d6da5b6951b35e5033f79bfaebda3980f6a5fe61`；后续修复提交 `ee21ec2`（只改验证脚本）。
验证期间只运行命令与探针，未修改产品源码（探针全部放在被忽略的 `.runtime/`）。

## 一、环境前置修复：插件快照曾落后一个提交（必须先修，否则一切验证都跑不起来）

`yarn check` 的第一步 `verify:upstream` 在本机直接失败：

```
Error: Upstream source changed: ...\.upstream\project
Expected dcd0f0e8305a7dce4f4ce587b7ef4483d0819751; found 880e45f8d4d1bf8719de0bd2ee0d785d6e916d63
```

- `.upstream/desktop/dsh-plugin-desktop` 的实测 tree 与 lock 完全一致（`2840b043…`），所以桌面上游快照没问题。
- `.upstream/project` 的实测 tree `880e45f8…` 正是插件提交 **`dd85e1a`**（pin 的上一个提交 `5193e81` 的父提交）的 tree；
  lock 的 `project.tree = dcd0f0e8…` 与插件仓库 `5193e81^{tree}` 完全一致。结论：快照是从旧提交导出的，属于陈旧快照。
- 修复：删除陈旧快照，按 lock 的 commit 用 `git archive` 重新导出，**先验证新导出 tree 与 lock 相等再替换**（脚本 `.runtime/reexport-project.ps1`）。
  重新导出后实测 tree = `dcd0f0e8305a7dce4f4ce587b7ef4483d0819751`，与 lock 完全一致；
  这也顺带证明 `scripts/source-integrity.mjs` 的 tree 算法在 Windows 上与 Git 一致（不是平台差异）。
- 陈旧快照保留在 `%TEMP%\stale-project-485a4771`（可删），未进入仓库。

## 二、自动部分

### W1 `yarn run check` —— 通过

`cd resources/dsh-project-desktop && yarn check` EXIT=0，日志 `artifacts/w1-check.log`：

| 阶段 | tests | pass | fail |
| --- | --- | --- | --- |
| `node --test tests/*.test.mjs` | 125 | 125 | 0 |
| `test:recovery` | 7 | 7 | 0 |
| `test:safe-mode` | 1 | 1 | 0 |

`smoke:host`（真实双 Host）也通过（日志尾部 `Project creation, existing-file preservation, ambiguous directory refusal and recent-project history operations passed.`）。
无平台专有失败。

### W2 `yarn run smoke:resources` —— 通过（含 Windows 专有目录记忆断言）

`yarn smoke:resources` EXIT=0；结果 `artifacts/w2-resource-states-result.json`。
Windows 专有分支（`process.platform === 'win32'`，`scripts/native-resource-state-checks.mjs:695-760`）全部执行并通过，其中包括本任务新增的目录记忆断言：

- 第一次「选择目录…」的 `options.defaultPath` 为 `undefined`（尚无记忆）；
- 第二次的 `defaultPath` 等于上一次选中的 `…\Resource states\picked-resource`；
- 本地资源「添加资源 → 选择目录」与「绑定目录」都走 desktop-runtime 选择器，未出现「当前环境不支持原生文件夹选择」；
- 技能导入走同一选择器；
- userData 下落盘 `last-directories.json`：`{"version":1,"paths":{"resource":"…\\picked-resource"}}`
  （证据 `artifacts/w2-last-directories.json`，截图 `w2-resource-add-local.png`、`w2-resource-bind-and-skill.png`）。
- 资源清单确实写入了 `picked-resource`（type local，path `rebound-resource`）。

顺带确认 W7 的 CI 范围判断：`guide-windows.yml` 只跑 `smoke:guide:focused`，而 focused 分支先跑 `checkRepositoryImport`
（`scripts/native-guide-case.mjs:27`），所以欢迎窗口的文件夹探测/补选/导入在 CI 上确实有覆盖——但见下面的缺陷。

## 三、发现的缺陷（阻塞自动验证，未修）

### D1（阻塞）：多 `.agent-project` 文件夹的「补选文件」分支在 Windows 上挂死

**根因（实机确认）**：**对在调用过程中被关闭的窗口调 `webContents.executeJavaScript`，这个 Promise 永不 settle。**

最小复现（探针 `artifacts/d1-executejavascript-hang-probe.mjs`，日志 `d1-executejavascript-hang-trace.log`）：
窗口 `actions rendered` 之后只发一条

```js
await contents.executeJavaScript(`document.querySelector('.actions button[data-guide-action=open]').click()`)
```

点击本身执行了、两次对话框都返回了、窗口也关掉了（同一次运行里另一处按 `closed` 事件等待的观察能看到 `close` / `closed`），
但 `executeJavaScript` 的 Promise 一直没有回来：写在其后的第一行日志（`clicked 打开`）从未出现，
主进程的 `setInterval` 心跳仍在继续（`heartbeat windows=0`）。也就是说，**主进程没死、只是这个 Promise 悬着**。

这正是 `scripts/native-guide-checks.mjs` 挂住的那一句：

```js
// checkRepositoryImport 的非 darwin 补选分支
const ambiguousOpened = destroyed(window);      // 监听 'closed'，带 10s 超时
await clickOpen(window);                        // ← 第 343 行：窗口在这次点击里被自己关闭
await ambiguousOpened;                          // 永远到不了
```

`clickOpen` = `window.webContents.executeJavaScript(...click())`（同文件第 304 行），
而引导窗口的主进程处理完 `open` 后会在 `setImmediate` 里 `window.close()`（`src/windows/guide-window.mjs:258`），
于是这次 `executeJavaScript` 的应答还没送出，窗口就已经销毁 → Promise 悬空 → 检查永久挂起。
同一文件里的 `clickAndWaitForClose`（第 15-25 行）正是为这种情况写的（`Promise.race([closed, executeJavaScript(...click())])`），
`checkGuide` 用它点关闭按钮；补选分支漏了这一层。

**修法（建议，未实施）**：把第 343 行改成与 `closed` 竞争，或直接复用 `clickAndWaitForClose`：

```js
const ambiguousOpened = destroyed(window);
await Promise.race([ambiguousOpened, clickOpen(window)]);
await ambiguousOpened;
```

macOS 因为 `kind === 'multiple'` 只弹一个"几个项目文件"的错误、不关窗口（第 336-339 行），所以这条路径从未在 macOS 上暴露。

`yarn smoke:guide:focused` 在本机 **不失败、不退出**，只有一行 `Guide frame evidence: .runtime/guide-frame-<id>`；
进程存活、CPU 近 0（实测两次：一次 7 分钟、一次 240 秒看门狗超时）。

把该检查逐段复制加桩（探针 `.runtime/diag-import2.mjs`，日志 `artifacts/w3-ambiguous-hang-trace.log`）后定位到停顿点：

```
+110ms start … +1152ms H 空文件夹分支完成
+1152ms I ambiguous phase          ← 进入「多个 .agent-project」分支后再无任何进展
+5114ms heartbeat windows=0        ← 之后窗口数为 0，检查再也没有前进一步
```

隔离复现（探针 `.runtime/diag-ambiguous.mjs`，日志 `artifacts/w3-ambiguous-isolated-trace.log`）：

```
dialog call ["openFile","openDirectory"]           ← 第一次：打开探测，属性符合预期
dialog call ["openFile"]                           ← 第二次：Windows 退化后的补选文件对话框
open called ...\Ambiguous\One.agent-project        ← 目标解析正确，open() 已调用
heartbeat windows=0 …                              ← 窗口随后消失，但 'closed' 事件再也没到达调用方，await 永久挂起
```

同一探针里，唯一入口文件夹（`invoke('open')`）能正常 `open()` 并关闭窗口（`artifacts/w3-w5-import-trace.log` 第 1 条 PASS），
说明这不是探测逻辑本身的问题，而是「补选文件」这条 Windows 专有分支的问题：

- 复位点：`src/windows/guide-window.mjs:241-246`（`kind === 'multiple' && process.platform !== 'darwin'` → `pickProjectFile` → `openProject`）；
- 观察到的现象：文件确实被选中、`open()` 确实被调用，但引导窗口没有向调用方发出 `closed`，
  于是 `scripts/native-guide-checks.mjs:341-345` 的 `await ambiguousOpened` 永久挂起（检查超时逻辑覆盖不到这里）；
- 影响：`smoke:guide:focused` 在 Windows 上会**挂死而不是失败**（CI 只会被 job timeout 杀掉），
  且该检查里排在它后面的导入目录记忆断言永远不会执行；
- 建议的复现命令：`cd resources/dsh-project-desktop && yarn smoke:guide:focused`（本机复现 3 次，均停在同一处）。

未修（任务约定：Windows 上只验证与记录，缺陷另开任务）。

### D2（工具环境，非产品缺陷）：探针写 stdout 触发 EPIPE，把 Electron 主进程卡成模态错误框

后台作业里探针若向未排空的 stdout 管道 `process.stdout.write`，会抛 `EPIPE: broken pipe, write`
（Electron 主进程未捕获异常 → 模态「A JavaScript error occurred in the main process」对话框 → 进程不再推进）。
这是**探针的写法问题**，不是产品代码问题：正式检查脚本只用 `console.log`，且正常运行时管道由终端消费。
处置：探针一律只落盘到 `.runtime/*.trace`，不写 stdout。此处记录是因为它同样会表现为「窗口一闪而逝后卡死」，容易误判为产品缺陷。

## 四、W3–W5 的 Windows 结论（用与正式检查同一套桩的探针取得）

由于 D1 让正式检查在 Windows 上无法走完，另写探针 `.runtime/diag-import-win.mjs`
（与 `checkRepositoryImport` 相同的 Electron/dialog/clone-pool 桩，同样的断言序列，跳过挂死的补选分支），
在本机 Windows 上 **9/9 通过**，日志 `artifacts/w3-w5-import-trace.log`、结果 `artifacts/w3-w5-import-results.json`：

| 结论 | 证据 |
| --- | --- |
| 唯一入口文件夹直接打开，选择器属性退化为 `['openFile','openDirectory']` | PASS 1 |
| 空文件夹在窗口自身语言下报「这个文件夹不是 agent-project 项目：没有找到 .agent-project 项目文件。」 | PASS 2 |
| 导入弹窗空表单报自身校验错误；目标目录初值为窗口默认目录 | PASS 3 |
| 仓库 URL 推导出文件夹名 `imported-project`，路径预览使用 Windows 分隔符 | PASS 4 |
| 克隆进度显示插件真实阶段（接收对象 / 42%） | PASS 5 |
| 完成后在父目录下安装 `<name>.agent-project` 并直接打开 | PASS 6 |
| 关闭再打开弹窗预填上次导入目录 | PASS 7 |
| 「浏览」选中的目录立即被记住（未开始克隆也记住）；Escape 关闭且不导入 | PASS 8 |
| 英文文案、深色主题、Escape、420px 窄窗口不溢出 | PASS 9 |
| 落盘 `last-directories.json`：`{"version":1,"paths":{"import":"…\\Picked"}}` | `artifacts/w3-w5-last-directories.json` |

因此：

- **W3：部分通过。** 唯一入口文件夹、空文件夹文案已在实机确认；「多个 `.agent-project` 补选一次只选文件的对话框」按 D1 失败（挂死）。
- **W4：部分通过。** 弹窗端到端（校验、推导名、预览、进度、安装并打开）已在实机确认；
  「非 agent-project 仓库回滚删除」「私有仓库凭据弹窗」本轮未执行（正式检查挂在 D1，未走到该路径；桩池也不产生真实克隆失败）。
- **W5：通过。** 导入目录记忆在 Windows 上生效，`last-directories.json` 落盘（reopen 验证见 PASS 7/8）。

## 五、D1 修复与修复后重跑（已提交 `ee21ec2`）

修法是让那次点击与窗口关闭竞争（只改验证脚本 `scripts/native-guide-checks.mjs`，产品代码未动）：

```js
const ambiguousOpened = destroyed(window);
await Promise.race([ambiguousOpened, clickOpen(window)]);   // 被关闭的窗口不会回答 executeJavaScript
await ambiguousOpened;
```

修复后在 Windows 上重跑（同一台机器）：

| 命令 | 结果 |
| --- | --- |
| `yarn smoke:guide:focused` | **EXIT=0**，checks 为 `open-folder-and-repository-import` + `create-guide-project-path-preview-separator`（`.runtime/guide-frame-bCutlm`） |
| `yarn smoke:resources` | **EXIT=0**（`.runtime/resource-states-DjfOp0`） |
| `yarn check`（壳） | EXIT=0，125+7+1 |
| `yarn check`（插件，工作树） | EXIT=0，308 tests / 301 pass / 7 skip / 0 fail |

也就是说：多入口补选、其后原本永不执行的导入目录记忆断言、以及英文/深色/窄窗那几组，现在在 Windows 上一次跑完。
提交 `ee21ec2` 只改这一个脚本；未 push（按仓库纪律，push 需明确要求）。

### CI 外部验证（`windows-2022`，修复后首次转绿）

`ee21ec2` 随后随 `74a82e6` 推送到 `origin/master`（本地与远程一致，无待推送提交）。CI 结果：

| 运行 | 提交 | 结论 |
| --- | --- | --- |
| [Verify Guide on Windows #35863134305](https://github.com/admintertar/dsh-project-desktop/actions/runs/35863134305) | `74a82e6` | **success**（`Corepack yarn run smoke:guide:focused` 与 `Upload guide evidence` 均 success，12:52:12Z→12:54:32Z） |
| [Verify Resources on Windows #35863134327](https://github.com/admintertar/dsh-project-desktop/actions/runs/35863134327) | `74a82e6` | **success** |
| Verify Guide on Windows #35856054742 / #35851464588 | `2bad7f3`（修复前） | cancelled —— 即在 D1 挂死下被取消/超时 |

这一组对照就是 D1 影响的直接外部证明：同一个 workflow、同一台 runner 镜像，修复前在引导检查上挂到被取消，修复后 2 分 20 秒跑完。

## 六、用户手工验收（2026-09-23，同一台 Windows 实机）

用开发壳（`DSH_PROJECT_PLUGIN_SOURCE=..\dsh-plugin-project` + 隔离 userData）按本任务给出的手工清单执行，
fixture 在 `%TEMP%\dsh-manual-acceptance`（`01-single` / `02-empty` / `03-multi` / `Destination` / `Taken`）。
用户结论：**全部通过，没有发现问题**。

- 覆盖到的：文件夹选择器退化、唯一入口直接打开、空文件夹中文提示、多入口补选文件、
  **第二次对话框取消后无动作**、克隆导入表单校验与文件夹名推导（Windows 分隔符预览）、导入进度与自动打开、
  非项目仓库回滚、同名目标拒绝、私有仓库凭据弹窗、导入目录记忆（含「浏览」立即记住）与
  `last-directories.json` 落盘、中英文/深浅色/窄窗口。
- **证据说明（如实记录）**：本轮手工验收**没有留下截图或录屏**，`artifacts/manual/` 不存在；
  该结论的来源是用户口头确认，属于人工观察，不是可复核的文件证据。
  与之对应的自动断言在第五节已全部绿；如需文件级证据，可在需要时按同一清单补一次截图。

## 七、W6：本轮**不验证**（用户决定先不做文件关联）

- 打包脚本确实声明了关联：`scripts/package-windows.mjs:27`（`fileAssociations: [{ext: 'agent-project', …}]`，NSIS 安装器注册）。
- 本机注册表实测：`.agent-project` 在 `HKCU\…\Explorer\FileExts` 与 `HKCR` 下**都没有**任何关联；
  已安装的是 0.1.8 的 DSH Project Desktop（尚未重新安装带关联的构建）。
- 结论：没有关联就无法从资源管理器双击 `.agent-project`，W6 需在「安装一次当前候选构建」的机器上验证：
  注册后双击 `<name>.agent-project` → 第二个实例把路径交给已运行的实例（`src/app/main.mjs:385-390`）→ 对应项目窗口被打开。
  本轮不安装候选构建（任务约定：不做发布/打包产物验收，且不改动本机已装应用）。

## 八、证据清单

| 文件 | 内容 |
| --- | --- |
| `w1-check.log` | W1 `yarn check` 完整日志（EXIT=0，125+7+1） |
| `w2-resource-states-result.json` | W2 `smoke:resources` 的测量值与清单路径 |
| `w2-last-directories.json` | W2 落盘的目录记忆（`resource` 键） |
| `w2-resource-add-local.png` / `w2-resource-bind-and-skill.png` | W2 Windows 专有选择器与记忆断言时的界面 |
| `w3-w5-import-trace.log` / `w3-w5-import-results.json` | W3–W5 导入探针 9 项 PASS 的逐条日志与结果 |
| `w3-w5-last-directories.json` | W3–W5 探针落盘的目录记忆（`import` 键） |
| `w3-w5-windows-import-probe.mjs` | 生成上述结论的探针源码（与正式检查同桩同断言） |
| `w3-ambiguous-hang-trace.log` | D1 的分段定位日志（停顿在 ambiguous 分支） |
| `w3-ambiguous-isolated-trace.log` | D1 的隔离复现（两次对话框 + `open()` 之后的窗口状态） |
| `d1-executejavascript-hang-trace.log` / `d1-executejavascript-hang-probe.mjs` | D1 根因：对在调用中被关闭的窗口 `executeJavaScript` 永不 settle（心跳继续、Promise 悬空） |
| `w3-smoke-guide-focused-hang.log` | `yarn smoke:guide:focused` 挂死时的原始日志（仅 1 行证据路径） |
