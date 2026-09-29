# 官方 Desktop 0.2.0-rc.2 可行性实验

日期：2026-09-29。状态：官方源码构建、真实 Host、双 Host 隔离、临时双 Electron 窗口和 Project 插件兼容实验通过；壳的完整接入、原位数据迁移和安装包仍未验收。

## 当前官方版本

- 官方仓库：[deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness)
- 当前最新公开 tag：[`dsh-v0.2.0-rc.2`](https://github.com/deepseek-ai/deepseek-harness/releases/tag/dsh-v0.2.0-rc.2)
- commit：`639ed015397290b3745d163aafe02ffee4aa3f84`
- `apps/desktop` tree：`12703a7e1aecef2fa5ba105058e96b5769329b4d`
- `pnpm-lock.yaml` blob：`6c7ce04c19349c2d5060f15a11eef5b642da0f50`
- 官方根包、Desktop、Desktop Host 和 Web 包版本均为 `0.2.0-rc.2`。
- `apps/desktop` 仍是 `private: true` 的 workspace 包，不能当作公开 npm Desktop 包直接安装，必须按官方源码和锁文件构建。

此前验证的 `dsh-v0.2.0-rc.1`（commit `4878cdabd87d4041bdaff61d04c966883b9fd07a`）已被 `rc.2` supersede。两个仓库的候选锁现已统一更新为 `rc.2`，不会跟随浮动 `master`。

## rc.2 相对 rc.1 的迁移提示

`rc.2` 不是只改版本号。官方 Desktop/Host 增加或调整了 CLI、登录 Shell 环境、调度和打包相关实现，Desktop Host 的入口和打包闭包需要按 `rc.2` 重新接入。官方右侧 Sidebar 的注入契约也移除了旧的 `bindService`，改为 `measureRoom` 与 `reportAutoFullscreen`；Project 插件已完成这一处适配。

自动化任务仍是可选插件能力。正式迁移前仍需确认 Tasks、定时任务及项目级入口的安装默认值，不能因为官方主线新增功能就假定壳已具备功能等价。

## 官方源码实验

在从 `rc.2` 固定提交检出的干净工作树，以 Node 22.19.0、pnpm 11.7.0 运行：

```sh
pnpm install --frozen-lockfile --reporter=append-only
pnpm run build:official
pnpm exec vitest run --config vitest.e2e.config.ts apps/desktop/tests/welcome-flow.e2e.ts
```

结果：

- 官方锁文件安装成功；供应链策略校验通过。
- `build:official` 成功，产出 `apps/desktop/lib/main.js`、`apps/desktop-host/lib/index.js`、`apps/web/dist/index.html`，并记录 347 个客户端构建产物。
- 官方真实 Host 验收通过：1 个测试文件、1 个测试通过，覆盖 Profile、WebServer、账号状态与 Host 重启。
- 日志只保存在本机忽略目录 `.runtime/official-021/`，不提交可能含临时认证 URL 的原始日志。

## 双 Host 隔离实验

用壳分支的 `scripts/probe-official-two-hosts.mjs`，从同一 `rc.2` 官方构建创建两个临时 Profile 和 Host。实验通过：

- 两个 Host 同时启动，使用不同 loopback 端口；
- A 的 Cookie 不能访问 B 的页面；
- 停止 A 后 B 仍返回 HTTP 200；
- 实验使用临时目录，退出后清理，没有接触现有用户数据。

这一步证明官方 Host/WebServer 可重复实例化；Electron 项目窗口与协议 Session 随后按下节单独验证，原位数据迁移和安装包仍未验证。

## 官方协议与临时 Electron 窗口实验

官方有两个用途不同的协议。`apps/desktop/src/main.ts` 将 `dsh://open` 注册为操作系统唤起入口；真正的应用 Web 文档加载于 `dsh-app://app/`。`apps/desktop/src/web-document.ts` 提供本地静态文件，并将非静态请求连同主进程持有的 Cookie 转发给 Host；官方主进程还为 WebSocket 改写 Origin 和 Cookie。迁移壳时，`dsh://open` 仍只负责唤起，逐项目的 `dsh-app` 请求必须在各自 Electron Session 中注册和认证。

壳的 `scripts/probe-official-electron-window.mjs` 和 `scripts/official-electron-window-main.ts` 以固定官方源码构建临时 Electron 主进程，不修改官方工作树或用户 Profile。探针先检查官方工作树的 HEAD、干净状态、Desktop tree 和锁文件 blob，再从官方 `DesktopHostProcess`、`web-document.ts`、`preload-app.cjs` 及 Web dist 启动窗口。验证命令（Node 22.19.0；官方源码先运行 `pnpm run build:official`）：

```sh
cd resources/dsh-project-desktop
PATH=/Users/ping/.nvm/versions/node/v22.19.0/bin:$PATH \
  /Users/ping/.nvm/versions/node/v22.19.0/bin/node \
  --import ../deepseek-harness-official-021/node_modules/tsx/dist/loader.mjs \
  scripts/probe-official-electron-window.mjs ../deepseek-harness-official-021 --two
```

结果：两个真实窗口均完成官方 Web boot 与 transport，显示完整基础界面；Host 分别监听不同的 loopback 端口，窗口使用不同 `persist:` 分区与 WebContents ID。强制销毁 A 后，B 的渲染器仍能执行并保持传输状态。截图及不含 Cookie 的机器结果分别在 [窗口 A](official-window-probe/window-A.png)、[窗口 B](official-window-probe/window-B.png)、[结果](official-window-probe/result.json)。这只证明临时骨架可行，尚未证明正式 Shell 的生命周期、用户主动关闭行为、Project 插件、跨项目 IPC 攻击拦截或旧数据恢复。临时探针的快捷键 IPC 返回禁用状态，正式适配必须逐项目接入官方 `keyboard.ts`。

实现中遇到两点：默认 Node 20.19.0 无法运行官方 Host，须显式使用 Node 22.19.0；Electron ESM 主入口不能在顶层等待 `app.whenReady()`，否则 ready 不会到达。临时窗口首次用普通 `close()` 测试存活时被官方页面的关闭流程阻塞，改用 `destroy()` 验证强制故障隔离；正常关闭与确认流程仍是待验证项。

## Project 插件实验

Project 插件候选分支现已：

- 将 peer/dev 依赖和 Yarn 锁更新为官方 `0.2.0-rc.2`；
- 将官方候选锁更新到同一 commit、Desktop tree 和 `pnpm-lock.yaml` blob；
- 通过 `scripts/setup-official-candidate.mjs` 将开发包解析到 `rc.2` 官方源码工作区；
- 适配官方 Sidebar 注入契约变化，移除 `bindService`，提供隔离 Task root store 所需的 `measureRoom` 和 `reportAutoFullscreen` 空实现。

执行 `yarn run typecheck`、`yarn run test`、`yarn run build` 的结果：类型检查通过、308 个测试通过、构建通过。首次安装因 Yarn 24 小时新包隔离拒绝 `rc.2`，实验只用一次性 `YARN_NPM_MINIMAL_AGE_GATE=0 yarn install` 解锁精确版本；仓库配置没有放宽该策略。

## 尚未完成的接入边界

- Shell 的 `upstream.lock.json`、默认 setup、打包脚本、CI 和运行时仍含 Anywhere Labs 社区 Desktop；当前阶段不宣称零社区依赖已实现。
- Shell 的 `src/desktop-adapter/stable/` 仍调用社区私有模块，必须逐批替换为官方 `apps/desktop`/`apps/desktop-host` 入口或壳自己的适配层。
- 官方 Desktop 仍以应用级窗口和 `profiles/desktop` 为中心；项目壳必须继续负责逐项目 Profile 目录、Host 进程、端口、认证 Cookie、Electron Session 和窗口生命周期。
- 仍需完成官方功能与 Project Tasks/Resources/Memory/skills/MCP 的行为对照、旧数据迁移及回退、macOS Universal/Windows x64 打包、Intel 启动和安装升级验收。
- 旧 Stable 缓存与现行社区锁不一致时，`yarn run check` 会在 `verify:upstream` 停止；这不能作为官方 `rc.2` 迁移失败的证据。后续应在移除旧校验链后从干净目录验证。
- 本轮单独执行 Shell `yarn run test` 为 146 项中 144 通过、2 失败：旧社区缓存缺少 `project-update-download.js`，且旧 Windows material 测试期望的 URL 字段与当前缓存不符。两项都通过旧 `stable/modules.mjs` 读取缓存，与新增官方窗口探针无调用关系；不能把它们计作官方接入通过，正式切换后须重新跑完整检查。
