# 官方 Desktop 0.2.0-rc.1 可行性实验

日期：2026-09-29。状态：官方源码构建与独立 Host 实验通过；壳接入、插件适配和安装包尚未验收。

## 固定来源

- 官方仓库：`https://github.com/deepseek-ai/deepseek-harness.git`
- 发布 tag：`dsh-v0.2.0-rc.1`；公开 Release 发布于 2026-09-28 12:36:21 UTC，属于预发布版。
- commit：`4878cdabd87d4041bdaff61d04c966883b9fd07a`
- `apps/desktop` tree：`7d069c01368b0df933e3c1d07b95a80d5dd80bd7`
- `pnpm-lock.yaml` blob：`14a4b5454671dd5e0807f24fe79b2cbd94d063fc`
- 官方根包、Desktop 与 Desktop Host 的版本均为 `0.2.0-rc.1`。`apps/desktop` 是 private workspace 包，需按官方源码和锁文件构建。

壳分支的 `official-candidate.lock.json` 和 `scripts/verify-official-candidate.mjs` 记录并验证上述 Git 对象与发布 tag。此候选锁独立于现行 `upstream.lock.json`：后者仍用于已发布 Stable，在 Host、插件和打包链改造完成前不能提前切换。

## 实验结果

在从官方提交检出的干净工作树，以 Node 22.19.0、pnpm 11.7.0 运行。来源校验需要本地有 `dsh-v0.2.0-rc.1` tag；若是无 tag 检出，先从官方 origin 获取该 tag：

```sh
git fetch --no-tags origin 'refs/tags/dsh-v0.2.0-rc.1:refs/tags/dsh-v0.2.0-rc.1'
pnpm install --frozen-lockfile --reporter=append-only
pnpm run build:official
pnpm exec vitest run --config vitest.e2e.config.ts apps/desktop/tests/welcome-flow.e2e.ts
```

结果：官方锁文件安装成功；`build:official` 成功，产出 `apps/desktop/lib/main.js`、`apps/desktop-host/lib/index.js`、`apps/web/dist/index.html`，并记录 347 个客户端构建产物；官方真实 Host 验收 1 个文件、1 个测试通过，覆盖 Profile、WebServer、账号状态与 Host 重启。构建日志只在本机忽略目录 `.runtime/official-020/`，本报告记录结论，不提交带临时认证 URL 的原始日志。

另用壳分支的 `scripts/probe-official-two-hosts.mjs` 从同一官方构建创建两个临时 Profile 和 Host，均加载官方 Web 页面。两个 Host 使用不同 loopback 端口；A 的 Cookie 请求 B 不得到成功页面；停止 A 后 B 仍返回 HTTP 200。探针退出后清理临时目录，未使用现有用户数据。

Project 插件分支将 Harness peer 和开发依赖精确改为 `0.2.0-rc.1`，并增加同一官方候选锁及 `scripts/setup-official-candidate.mjs`。脚本检查 Git 对象和官方构建产物，再把开发用的 `@deepseek-ai` 包解析到官方源码工作区；原有本地依赖目录会保存。在插件仓库执行 `yarn run setup:official-candidate -- <官方源码目录>` 后运行 `yarn run check`，类型检查、308 个测试和构建通过。旧 `.dev/runtime` 包链接曾造成错误的类型检查结果，已在实验中识别并隔离。

## 接入边界

官方 `apps/desktop/src/main.ts` 仍以一个应用窗口和 `profiles/desktop` 为中心，不能直接代替项目壳的主进程。官方 Host 本身可重复实例化；项目壳需要负责逐项目 Profile 目录、进程、端口、认证 Cookie、Electron Session 和窗口生命周期。探针只验证了 Host、WebServer 与 Cookie 的隔离，**尚未验证两个 Electron 项目窗口、协议 Session、原位数据迁移或安装包**。

官方 `0.2.0-rc.1` 将自动化任务移到可选插件包；Project 插件的候选 peer 已改为 `0.2.0-rc.1`，但既有 `upstream.json` 和默认开发 setup 仍指向 Anywhere Labs。后续须替换默认 setup，确认 Tasks 与定时能力的入口，再替换壳的社区 Desktop 私有模块。壳的 `upstream.lock.json`、打包、CI 和运行时仍含社区依赖，本阶段不宣称零社区依赖已实现。

本地执行壳的 `yarn run check` 时，现存 `.upstream/desktop` 缓存树与已发布锁中的 `2.0.15` tree 不一致，检查在 `verify:upstream` 即停止。这是本地旧缓存状态，不能据此判断新适配是否通过；本阶段的官方候选来源校验和双 Host 实验分别已通过。官方 `0.2.0-rc.1` 发布不足一天时，Yarn 的 24 小时新包隔离阻止首次安装，插件实验只在本机用一次性 `YARN_NPM_MINIMAL_AGE_GATE=0` 完成精确版本安装；仓库配置没有放宽该策略，最终 CI 仍须按正式锁和来源验证。
