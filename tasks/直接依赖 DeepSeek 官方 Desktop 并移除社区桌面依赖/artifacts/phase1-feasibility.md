# 官方 Desktop 0.2.0-rc.2 可行性实验

日期：2026-09-29。状态：官方源码构建、真实 Host、双 Host 隔离和 Project 插件兼容实验通过；壳的完整接入、原位数据迁移、Electron 窗口和安装包仍未验收。

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

这证明官方 Host/WebServer 可重复实例化，但还没有证明两个 Electron 项目窗口、协议 Session、原位数据迁移或安装包。

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
