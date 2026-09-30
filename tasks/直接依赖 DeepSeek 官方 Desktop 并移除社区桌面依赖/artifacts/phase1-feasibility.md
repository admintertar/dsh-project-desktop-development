# 官方 Desktop 0.2.0-rc.2 可行性实验

日期：2026-09-29；2026-09-30 补充 macOS arm64 运行目录验收。状态：官方源码构建、完整未签名开发运行目录、真实 Host、双 Host 隔离、临时双 Electron 窗口和 Project 插件基础界面实验通过；壳的完整接入、原位数据迁移和安装包仍未验收。

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

随后把插件接入上述临时官方 Profile，运行 `scripts/probe-official-electron-window.mjs ../deepseek-harness-official-021 --two --plugin ../dsh-plugin-project`。首次真实窗口发现 macOS 官方 `0.2.0-rc.2` 的 SidebarRoot 在品牌行前增加窗口拖动栏，并把品牌按钮改为普通 `span`；插件原先的 DOM 假设抛错，Project 页面停在加载态。插件提交 `4920ac46c47a4b95090cef11151171b234db9081` 改为按官方 workspaces 席位定位侧栏根节点，只拦截确实存在的品牌按钮，保留 macOS 拖动行为。修复后以固定官方 Host/Web 和两个临时 `.agent-project`，两个窗口分别显示 Probe A、Probe B 的项目概览与 Tasks/Resources/Memory/skills/MCP 入口；A 强制销毁后 B 继续运行，渲染器无 error 日志。插件 `yarn run check` 为类型检查、309 个测试和构建全部通过。结果与截图见 [Project 窗口 A](official-project-plugin-probe/window-A.png)、[Project 窗口 B](official-project-plugin-probe/window-B.png)、[机器结果](official-project-plugin-probe/result.json)。

这只验证空项目的基础页面和入口可加载。Tasks、Resources、Memory、skills、MCP 的写入/调用，聊天会话、插件安装、Profile 切换、快捷键、设置及跨平台交互仍需分别验收；探针直接链接本地插件构建，不是正式安装包或干净目录构建闭包。

## 2026-09-29：Project 插件默认开发来源切换

Project 插件的 `upstream.json` 现直接固定 DeepSeek 官方 `dsh-v0.2.0-rc.2`、提交 `639ed015397290b3745d163aafe02ffee4aa3f84`、Desktop tree 和 `pnpm-lock.yaml` blob；默认 `yarn run setup -- --desktop <官方源码>` 校验 HEAD、tag、树、锁、版本、构建输出以及跟踪文件无修改，再把开发包链接到官方 pnpm 工作区。旧社区源码和现行 Shell 社区锁均被拒绝。插件中英 README 与开发说明已改为官方构建命令；候选专用来源锁和 setup 入口已移除。

在本机固定官方工作树上真实运行默认 setup 成功。插件 `yarn run check` 通过：类型检查、307 项测试、构建；新增来源校验测试覆盖错误 pin、污染工作树和 HEAD 偏离。旧 Shell `test:compatibility --desktop-only` 按预期因来源锁不符停止。此次只改变插件的默认开发来源与防混用门槛；插件的历史 Electron 回归材料仍含社区接口，Shell 正式运行、CI、打包和原位数据迁移尚未完成。开发链接依赖本机官方工作区，不等于干净目录发行闭包。

首次运行 `yarn start` 时，旧 `.dev/projects/<project-key>/` Profile 的 `@deepseek-ai` 链接仍指向 `rc.1`，官方 Host 拒绝加载不兼容的 Session 插件。现将**开发 Profile** 放在 `.dev/projects/<official-commit>/<project-key>/`，保留旧目录不改写。新 Profile 启动无错误，6.5 秒后的 loopback HTTP 请求返回预期的未认证 `401`，证明 Web Host 已监听；未测试登录后的完整 Web 操作。此隔离只针对插件本地开发目录，不能代替正式 Stable 用户数据迁移。

## 尚未完成的接入边界

2026-09-29 增量：临时探针中已验证的 `dsh-app` 静态资源/HTTP 转发与 WebSocket 凭据限制，已提取到 Shell 的 `src/desktop-adapter/official/web-session.mjs`；另有可复用的主 Frame 所属关系校验模块和单测。新增 3 项适配器测试，覆盖不同项目 Cookie/Host/Session、错误 WebContents、错误 Host、错误 Origin 和 preload IPC 文档；真实官方 `rc.2` 双 Host、双 Electron 窗口加 Project 插件探针重新通过，A 强制销毁后 B 存活。`yarn run check` 仍在旧社区快照树与旧锁不一致处停止，尚未触及此模块。正式 `src/app/main.mjs` 还没有调用新模块，不能将本次探针算作正式 Shell 接入。

同日核对 Shell 构建输入发现，官方 `apps/desktop` 是私有包 `@deepseek-ai/dsh-desktop`，主入口在 `lib/main.js`，Host 是独立的 `@deepseek-ai/dsh-desktop-host`；现行 Shell 却要求 `dsh-plugin-desktop/package.json`、`vendor/dsh-runtime/<version>/manifest.json`、社区 `src` 目录和旧模块树。两套布局不兼容，直接改锁会在来源校验或构建阶段失败。下一关必须先实现官方源码/Host/Web dist 到 Shell 构建闭包的映射，再接正式主进程；目前不能把正式 Shell `yarn run check` 的失败归因于官方 Host 本身。

Shell 中用于官方探针的来源锁和校验入口已从 `official-candidate.*` 统一命名为 `official-source.*`，并复测固定官方 `rc.2` 工作树校验通过。旧 `upstream.lock.json` 仍记录已发布 Stable 的社区来源；只有正式构建与运行链完成映射后才能切换该锁。

### 官方开发构建输入映射

Shell 新增 `src/desktop-adapter/official/build-inputs.mjs`，在固定官方 `rc.2` 工作树中校验 Desktop、Desktop Host、CLI、Web 包名和版本、pnpm 版本以及已构建的入口。`scripts/prepare-official-development.mjs` 将官方 Web dist、preload、许可证和从官方 `web-document.ts` 编译的 ESM 模块放入忽略目录 `.cache/official-development/`。清单 `inputs.json` 记录来源 pin、Host/CLI 工作树路径及每个暂存文件的 SHA-256；消费前会重新枚举文件、拒绝符号链接并验证哈希。

Node 22.19.0 下重新准备目录成功：共 199 个文件，其中 196 个是 Web 文件。构建输入、暂存篡改及 Session/IPC 的 5 项定向测试通过；双 Host 探针再次确认跨项目 Cookie 被拒绝，停止 A 不影响 B；双 Electron 窗口加 Project 插件探针再次确认两个窗口 boot/transport 均成功，销毁 A 后 B 存活。Shell `yarn run check` 仍在旧社区源码缓存的树 hash 不符处停止，尚未执行到新官方路径。这些探针只证明本机固定官方工作树的开发输入映射可用。清单中的 Host/CLI 是绝对工作树路径，pnpm 依赖也从该工作树解析；尚未形成可复制到另一台机器的安装包，未替换正式 Shell `src/app/main.mjs`、`upstream.lock.json`、setup、CI 或打包链。构建输出属于本机忽略文件，目前哈希用于检测暂存后改动，不等于已有官方发布产物校验值。

### 官方第一方包集合实验

从同一固定官方 `rc.2` 工作树，调用上游 `release:pack` 构建 318 个 DSH family tarball 和 9 个 vendor tarball，再打包私有 Desktop Host、native system entry，最后调用上游 `prepare-package-set.ts` 只保留 Desktop Host/DSH 所需闭包。Shell 的 `yarn run prepare:official-package-set -- ../deepseek-harness-official-021` 将这些步骤封装在忽略目录中，输出 `desktop-packages.json`、287 个 tarball 和 `source.json`（固定提交、Desktop tree、依赖锁 blob、描述文件 SHA-256）。上游 `verifyDesktopCorePackageSet` 检查每个 tarball 的大小与 SHA-512。

本机验证输出 287 个第一方包；将整个包集合复制到另一临时目录后，官方校验器仍通过，修改其中一个 tarball 的字节后校验失败。它证明第一方包集合本身不依赖原工作树路径；外部 npm 依赖、原生二进制、pnpm 和 primary runtime 的后续组装见下一节。包集合自身**不是完整安装包**，正式 Shell 的 Host、窗口、旧数据与 CI 均未接入这个集合。

### 2026-09-30：macOS arm64 完整开发运行目录

Shell 新增 `prepare:official-runtime`，先校验固定官方源码与核心包集合，再调用官方 `prepare:runtime`。`official-runtime-worker.mjs` 依据官方 `apps/desktop/scripts/prepare-dsh.ts`，复用其元数据、生产安装策略、文件过滤、manifest 整理、完整性清单及原生/Host/Office smoke。官方 macOS 脚本要求 Developer ID 签名；开发适配暂省略签名，产物明确标为 `official-unsigned-development-runtime`、`signed:false`，不能作为发布包。

外部 npm 解析结果登记在 `official-runtime-locks/mac-arm64/`，绑定官方提交、包集合摘要、目标、Electron Node ABI 和 pnpm 版本；以后每次在新目录按 `--prod --frozen-lockfile --trust-lockfile` 安装。目前只登记 macOS arm64 锁，其他平台会在下载前停止。产物写入 Shell 忽略目录 `.cache/official-runtime/mac-arm64/`，约 1.0 GB，包含 Host/CLI 生产依赖、Electron、官方 Web/preload、Node/Python/pnpm、Office 资源和 LICENSE。`dsh/` 有 12,417 个运行文件；全目录清单有 19,358 项及 14 条包内 Electron 框架链接。清单校验文件字节、可执行位与相对链接，拒绝链接回原工作区。

真实验证平台为 **macOS arm64**；Electron Node 为 `24.18.1`，primary runtime Node 为 `24.21.0`、Python 为 `3.12.14`、pnpm 为 `11.7.0`。依次通过：

- 官方 primary runtime 的 Python 包、Office 文档读写、pip check、Node/pnpm 检查。
- 原生模块与工具：koffi、sharp、HTML、PTY、pnpm、grep、glob。
- 真实 Host 与外部 smoke 插件；DOCX/XLSX/PPTX 转 PDF、Office CLI 路径与转换。
- 整体目录搬移后再次通过官方原生/Host/Office smoke。
- 从该目录启动的双 Electron 窗口，以及双窗口加本地 Project 插件；A 强制销毁后 B 存活。
- Shell 的 9 项 `tests/official-*.test.mjs` 与 `git diff --check`。

复现命令（在 Shell 目录，以 Node 22.19.0；已有官方资源时可用 `--reuse-resources`）：

```sh
yarn run prepare:official-runtime -- ../deepseek-harness-official-021
node --import ../deepseek-harness-official-021/node_modules/tsx/dist/loader.mjs \
  scripts/probe-official-electron-window.mjs ../deepseek-harness-official-021 \
  --two --plugin ../dsh-plugin-project --runtime .cache/official-runtime/mac-arm64
node --test tests/official-*.test.mjs
```

实验修正两处：官方 primary runtime 的 `pnpm --version` 会继承 cwd，受 Shell 的 Yarn 配置影响，现放到独立临时 cwd 执行；复用安装目录时 pnpm 打印 Done 后未退出，现恢复每次新建安装目录，仅缓存下载 store 并保留 frozen lock，重新完整运行通过。

证据：[运行目录与原生结果](official-runtime-probe/runtime-result.json)、[双窗口结果](official-runtime-probe/result.json)、[窗口 A](official-runtime-probe/window-A.png)、[窗口 B](official-runtime-probe/window-B.png)。原始日志仅保存在忽略目录，未提交临时 Host Cookie。窗口探针控制脚本仍导入固定官方源码 helper，Project 插件仍为本地开发链接；此结果证明官方运行 payload 的本机闭包和搬移可用性，不证明正式 Shell/插件发行闭包或跨机器、跨平台安装验收。

全量 `yarn run check` 仍在旧社区源码缓存校验处失败：`dsh-plugin-desktop` 树期望 `47d236012452eafa032346f7d0eedacd2a671819`，实际 `2840b04334609734e21adeed431f4274c23c87a0`。正式 `main.mjs`、旧来源锁、setup、CI 和安装包尚未切换，真实用户数据未修改。

### 当前剩余边界

- Shell 的 `upstream.lock.json`、默认 setup、打包脚本、CI 和运行时仍含 Anywhere Labs 社区 Desktop；当前阶段不宣称零社区依赖已实现。
- Shell 的 `src/desktop-adapter/stable/` 仍调用社区私有模块，必须逐批替换为官方 `apps/desktop`/`apps/desktop-host` 入口或壳自己的适配层；临时 Project 插件窗口不改变这一状态。
- 官方 Desktop 仍以应用级窗口和 `profiles/desktop` 为中心；项目壳必须继续负责逐项目 Profile 目录、Host 进程、端口、认证 Cookie、Electron Session 和窗口生命周期。
- 仍需完成官方功能与 Project Tasks/Resources/Memory/skills/MCP 的行为对照、旧数据迁移及回退、macOS Universal/Windows x64 打包、Intel 启动和安装升级验收。
- 旧 Stable 缓存与现行社区锁不一致时，`yarn run check` 会在 `verify:upstream` 停止；这不能作为官方 `rc.2` 迁移失败的证据。后续应在移除旧校验链后从干净目录验证。
- 本轮单独执行 Shell `yarn run test` 为 146 项中 144 通过、2 失败：旧社区缓存缺少 `project-update-download.js`，且旧 Windows material 测试期望的 URL 字段与当前缓存不符。两项都通过旧 `stable/modules.mjs` 读取缓存，与新增官方窗口探针无调用关系；不能把它们计作官方接入通过，正式切换后须重新跑完整检查。
