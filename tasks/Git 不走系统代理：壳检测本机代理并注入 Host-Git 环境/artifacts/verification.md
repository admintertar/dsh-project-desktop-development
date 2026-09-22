# Git 不走系统代理：验收证据报告

任务：task-12cafb34-99ae-4443-bc56-08843c00a72a
仓库：`resources/dsh-project-desktop`（壳）。插件仓库未改动，因此不涉及 `upstream.lock.json` 的 pin bump。
日期：2026-09-22 · 机器：Windows 11 build 26200 · Electron 43.3.0 · git 2.55.0.windows.5 · Clash for Windows（127.0.0.1:7890）

---

## 一、缺陷事实（改动前实测）

| 检查项 | 结果 |
| --- | --- |
| WinINET 注册表 `ProxyEnable` / `ProxyServer` | `1` / `127.0.0.1:7890` |
| 端口 7890 | LISTEN，进程 `clash-win64.exe` |
| 环境变量 `HTTP_PROXY` / `HTTPS_PROXY` | 不存在 |
| `git config --global` / `--system` 的 `http.proxy` | 均无 |
| `netsh winhttp show proxy` | Direct access (no proxy server) |
| git system config `http.sslbackend` | `schannel`（libcurl 后端，不读 WinINET） |

对照实验（同一时刻、同一命令）：

```
git -c http.proxy= -c https.proxy= ls-remote --heads origin
  → fatal: Failed to connect to github.com:443 after 21070 ms   EXIT=128  21.2s

git -c http.proxy=http://127.0.0.1:7890 -c https.proxy=http://127.0.0.1:7890 ls-remote --heads origin
  → 0d85b2ad…  refs/heads/master                                EXIT=0    0.9s
```

三个仓库的本地配置差异（本机 push 失败只发生在后两个）：

| 仓库 | 本地 `https.proxy` | 能 push |
| --- | --- | --- |
| `resources/dsh-project-desktop` | 已配 `http://127.0.0.1:7890` | 是 |
| 根仓库 `dsh-project-desktop-development` | 无 | 否 |
| `resources/dsh-plugin-project` | 无 | 否 |

## 二、改动面（只动壳）

| 文件 | 作用 |
| --- | --- |
| `src/desktop-adapter/stable/system-proxy.mjs`（新增） | 解析 Chromium `resolveProxy` 答案、loopback TCP 预检 + 结果缓存、构造注入环境、地址脱敏、`NO_PROXY` 常量 |
| `src/desktop-adapter/index.mjs` | 在 `spawnHost` 前 `await detectSystemProxy({resolveProxy: nativeRuntime?.resolveProxy})`，把 `proxyHostEnvironment(proxy)` 展开在继承环境之后；Safe Mode 分支保持空环境 |
| `src/desktop-adapter/native.mjs` | 暴露 `runtime.resolveProxy: url => electron.session.defaultSession.resolveProxy(url)` |
| `tests/system-proxy.test.mjs`（新增） | 8 个单测：答案解析、注入、不可用降级、缓存、PAC 多值、无代理/无 resolver/解析失败、Safe Mode、脱敏 |

## 三、证据链

### 证据 1 — Electron 能解析本机系统代理，且对 loopback 返回 DIRECT

一次性 Electron 主进程探针（`session.defaultSession.resolveProxy`，真实 Electron 43.3.0）：

```
process.versions.electron = 43.3.0
resolveProxy(https://github.com/)      => PROXY 127.0.0.1:7890
resolveProxy(http://github.com/)       => PROXY 127.0.0.1:7890
resolveProxy(https://127.0.0.1:9/)     => DIRECT
resolveProxy(https://example.invalid/) => PROXY 127.0.0.1:7890
```

结论：壳不需要自行解析注册表/PAC；而且 Chromium 自己就把 loopback 排除在代理之外。

### 证据 2 — 真实开发壳的启动日志（原生验收）

以本地插件源码与隔离 userData 启动开发壳并打开项目窗口：

```
node scripts/start.mjs D:\dsh-project-desktop-development\dsh-project-desktop-development.agent-project
（DSH_PROJECT_PLUGIN_SOURCE=../dsh-plugin-project，DSH_PROJECT_DESKTOP_USER_DATA=%TEMP%\dsh-proxy-verify-ud）

stdout:
  Isolated user data: C:\Users\PING\AppData\Local\Temp\dsh-proxy-verify-ud
  System proxy: http://127.0.0.1:7890 (connected)
窗口标题：dsh-project-desktop-development
```

证明 `resolveProxy → detectSystemProxy → TCP 预检通过` 这条链在真实 Electron 环境下工作，并产出可诊断的日志。预检耗时未超过 Host boot 预算（本地代理一次 TCP 连接，毫秒级；预检超时上限 500 ms）。

### 证据 3 — git 确实遵守注入的环境变量

```
set http_proxy/https_proxy=http://127.0.0.1:7890
git -c http.proxy= -c https.proxy= ls-remote --heads https://github.com/admintertar/dsh-plugin-project.git
  → d1e1745a1316f71ad80a4fee44ef00fd3fe9b6a0  refs/heads/master   EXIT=0
```

并且插件侧唯一的 Git 执行点确实从宿主环境构造子进程环境：

```ts
// resources/dsh-plugin-project/src/resource-git.ts:32
const env = Object.fromEntries(Object.entries(process.env)
  .filter(([key]) => !key.startsWith('GIT_') && !key.startsWith('DSH_GIT_AUTH_') && !key.startsWith('SSH_ASKPASS')));
```

过滤器只剥离 `GIT_*` / `DSH_GIT_AUTH_*` / `SSH_ASKPASS`，`http_proxy`/`https_proxy`/`HTTP_PROXY`/`HTTPS_PROXY`/`no_proxy` 全部原样传给 git，进而传给 `git-remote-https` 与 git-lfs。

### 证据 4 — 契约约束

| 契约 | 落实位置 |
| --- | --- |
| 代理不可用则降级直连，不拖长 Git 超时 | `probeProxy` 失败 → `proxyHostEnvironment` 返回 `{}`；`ECONNREFUSED/EHOSTUNREACH/ENETUNREACH/ECONNRESET` 与超时都判为不可用 |
| 预检结果缓存，避免每次打开项目重连 | `cache`（TTL 30 s，按代理地址分组） |
| loopback 与私网目标不被代理 | `NO_PROXY` = `localhost,127.0.0.1,::1,0.0.0.0,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,169.254.0.0/16,fc00::/7,fe80::/10,.local` |
| Safe Mode 不继承代理 | `const proxy = safeMode ? {proxied:false, reason:'safe-mode'} : …`，且 `safeHostEnvironment` 白名单未变 |
| 不写操作者本人的 git 配置 | 只注入子进程环境变量，从不调用 `git config` |
| 诊断不泄露凭据 | `redactProxy` 剥离 userinfo；日志只打印 `protocol//host:port` |

### 证据 5 — 全量校验与环境卫生

```
cd resources/dsh-project-desktop && yarn check     EXIT=0
  tests 115 / pass 115 / fail 0      （含新增的 8 个 system-proxy 用例）
  recovery 7 / pass 7
  safe-mode 1 / pass 1
  check-project-files: Project creation, existing-file preservation, ambiguous directory refusal
                       and recent-project history operations passed.
  smoke:host passed（assets 10/10）
```

其中 `project-bootstrap-network.test.mjs`（loopback HTTP fixture 的真实 clone/取消/超时三个用例）继续通过——本次改动没有再次踩坏「用户级代理劫持 127.0.0.1 fixture」这个已知陷阱（历史缺陷见 task-bf50c979）。

就地验证用的 `userData` 放在 `%TEMP%\dsh-proxy-verify-ud`，探针与日志都在 `%TEMP%`，跑完已删除；`tasks/` 目录未写入任何运行期状态。

## 四、局限与未覆盖

1. **未在 Host 进程内部直接观测 git 子进程**：Windows 上非管理员无法通过 WMI 读取其它进程的环境块（实测 `Win32_Process.EnvironmentVariables` 返回 null），因此「Host 环境 → git 子进程」这一段是用证据 3（git 遵守这两个变量）+ 证据 3′（插件从 `process.env` 构造 git 环境）+ 证据 2（真实壳完成探测与注入）合成的，不是在 Host 进程里抓到的实时命令。
2. **仅 Windows 实机验收**：macOS/Linux 走同一 `resolveProxy` 接口与同一注入路径，本轮未做原生验收。
3. **SSH remote 不走该代理**：`http_proxy` 只影响 https 传输；`ssh://` remote 需要 `ProxyCommand`，属未覆盖范围。
4. **PAC 认证代理**：Chromium 能解析出地址，但代理自身的认证（407）不在处理范围内。
5. 代理在线但规则不通（Clash 规则模式下 github 走直连）时，TCP 预检会判为可用而实际仍失败——预检的语义是「本地代理进程是否活着」，不是「该域名是否走得通」。
