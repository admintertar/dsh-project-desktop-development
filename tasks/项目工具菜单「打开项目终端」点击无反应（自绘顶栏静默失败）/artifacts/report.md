# 项目工具 → 打开项目终端：点击无反应 — 定位与修复

## 症状

Windows 项目窗口里点「菜单栏 → 项目工具 → 打开项目终端」没有任何反应：不开终端、不报错、不弹框。
同一个菜单里其它项（重启、安全模式、关于…）正常。

## 根因

Windows 上原生菜单栏不可达（`GetMenu(hwnd) == 0`，Alt/F10/`setMenuBarVisibility` 全部无效），
菜单是壳自绘的标题栏（`src/desktop-adapter/stable/shell-titlebar-client.tsx`），点击走官方
renderer bridge 的字符串动作 `'terminal'`，最终落到壳自己的 `runtime.openTerminal()`。

壳调用官方 `openDesktopTerminal` 时漏传了官方契约里**必需**的 `spawn`
（`DesktopTerminalOptions.spawn`，官方 `electron-runtime.ts` 传的是 `node:child_process.spawn`）。
官方实现在启动进程处直接 `options.spawn(...)`，因此必然抛
`TypeError: options.spawn is not a function`。

这个错误到不了用户眼前，有三层原因叠加：

1. 官方 dispatcher 是 `case 'terminal': actions.openTerminal(); return` —— 不 `await`、不捕获，
   同步抛错只变成 IPC 的 rejected promise；
2. 自绘菜单的 `run()` 只 `console.error`；
3. 壳的 `runtime.openTerminal()` 既没有官方那样的 `try/catch`，也没有官方
   `reportTerminalLaunchError` 的错误弹窗。

结果就是「点了没反应」。同一处契约缺失在 `stable/project-native-windows.mjs`（项目恢复窗口的
打开终端入口）也存在。

实测复现（探针复刻壳的真实调用参数）：

```
case A（现状，无 spawn）: THREW TypeError - options.spawn is not a function
case B（同参数 + 注入 spawn）: LAUNCHED cmd.exe ["/D","/S","/C","launch.cmd"] cwd=<stateDir> windowsHide=true
```

## 修复

- 新增 `src/desktop-adapter/terminal-launch.mjs`：一处凑齐官方 `DesktopTerminalOptions`
  （`spawn` 默认 `node:child_process.spawn` + `onLaunchError`），并把**同步抛错与异步启动失败**
  统一交给调用方的 reporter。缺字段这类静默失效从此不可能再出现。
- `native.mjs` 与 `stable/project-native-windows.mjs` 的 `openTerminal` 改用它；失败时复用官方
  `desktopNativeCopy` 文案 + 官方 `showDesktopMessageBox` 弹错误框（与官方
  `reportTerminalLaunchError` 同款），不再静默。
- 「正在启动」这类前置失败也走同一个弹框，而不是抛进 IPC 黑洞。

## 顺带修好 / 顺带发现

1. **「编辑」菜单没有快捷键文本**：自绘菜单从引入（f6452bf）起只有「文件」有快捷键，编辑/视图
   从来没有。已按 Electron win32 role 默认值补上编辑菜单：
   `Ctrl+Z / Ctrl+Y / Ctrl+X / Ctrl+C / Ctrl+V / Ctrl+A`（role 默认值由探针从固定 Electron
   43.3.0 读回，不是抄来的）。
2. **原生冒烟在 Windows 上根本跑不起来**：`native-guide-checks.mjs` 用
   `item.accelerator === 'CmdOrCtrl+Shift+N'` 找「新建项目」，而 f6452bf 之后 Windows 端 File 菜单
   故意不注册 accelerator（改由 `window-accelerators.mjs` 装窗口级绑定）。所以 `smoke:native`
   在 Windows 上第一步就断言失败，任何菜单/终端回归都测不到 —— 这也是本缺陷能溜过去的原因之一。
   已改为 accelerator 优先、label 回退。
3. **自绘标题栏不跟随语言切换**：它原来读 `document.documentElement.lang`，实测把应用语言切成英文后
   该属性仍是 `zh-CN`，标题栏继续显示中文。已改为使用官方 locale 服务
   （`ctx.locale.register('project.shell', …)` + `ctx.locale.bind`，slot 声明 `locale`），
   文案（含新增快捷键列）随语言实时更新。

## 验证

| 证据 | 命令 | 结果 |
| --- | --- | --- |
| 契约回归（4 项） | `yarn test` | 129/129 通过；其中「官方实现缺 spawn 必抛错」把这次根因钉死 |
| 原生菜单冒烟 | `yarn smoke:native` | 通过，含新增 `titlebar-menu-entries-and-edit-accelerators` |
| 快捷键真实性 | 冒烟内 `sendInputEvent` | Ctrl+A 真实到达焦点输入框（selection 0..5），打印的快捷键不是装饰 |
| 真实点击 | 开发壳 + CDP 点击菜单 | 点击后出现 `WindowsTerminal`（标题 `DSH Desktop`）= 终端真的打开；无错误弹窗 |
| 视觉 | `project-tools-menu.png` / `edit-menu-zh.png` | 菜单可打开；编辑菜单 6 项均带快捷键列 |

视图菜单快捷键实测（同一真实窗口）：F11 ✅、Ctrl+Shift+I ✅、Ctrl+R ❌、Ctrl+加减/0 ❌。
因此**没有**给视图菜单打印快捷键文本 —— 打印不生效的键是假承诺，要打印必须先像
`window-accelerators.mjs` 那样给这些命令装窗口级绑定。

## 仍未做（建议排期）

1. 视图菜单：为 reload/zoom 安装窗口级绑定，然后才打印 `Ctrl+R`/`Ctrl+0`/`Ctrl+=`/`Ctrl+-`
   （F11 与 Ctrl+Shift+I 可直接打印）。
2. `smoke:native` 未进 CI（`.github/workflows/package.yml` 只跑 `yarn check` 与
   `smoke:updates`）。当前 Windows 上必须手工跑，回归护栏弱；契约测试已随 `yarn test` 进 CI。
