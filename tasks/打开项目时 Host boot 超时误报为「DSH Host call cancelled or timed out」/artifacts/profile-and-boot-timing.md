# 探针：首次打开到底跑了什么、花了多久（2026-09-22，macOS arm64）

本文件修正此前"30 秒预算 < 120 秒物化预算，所以首次打开必然超时"的假设。
实测显示那个 pnpm install 是**亚秒级**，不足以触发 30 秒超时。

## 探针 1：Profile 准备（含首次 pnpm install）

脚本 `.runtime/first-install-probe.mjs`，对全新 `stateDirectory` 调用
`prepareProjectProfile(manifestPath, stateDirectory)` 两次并计时。

```
FIRST_OPEN_ms=556   (includes first pnpm install)
SECOND_OPEN_ms=55   (lockfile already present)
lockfile=true
```

`pnpm-lock.yaml` 全文（注意：**没有任何 registry 包**）：

```yaml
lockfileVersion: '9.0'

settings:
  autoInstallPeers: false
  excludeLinksFromLockfile: false

importers:

  .:
    devDependencies:
      dsh-plugin-project:
        specifier: link:./.project-plugin
        version: link:.project-plugin
```

`profile/node_modules` 条目（pnpm 元数据 + 两个符号链接）：

```
.modules.yaml
.package-map.json
.pnpm
.pnpm-workspace-state-v1.json
dsh-plugin-project      -> .project-plugin
dsh-project-shell       -> <repo>/.cache/runtime/dsh-project-shell
```

`.project-plugin/node_modules`（插件直接依赖，全部指向打包缓存，不下载）：

```
@modelcontextprotocol
yaml
zod
```

结论：首次 install 的工作量 = 解析一个 `link:` 依赖 + 生成 lockfile 与 pnpm 元数据
+ 建符号链接。**没有网络下载**（`autoInstallPeers: false`、`link:` 不解析其依赖，
插件的传递依赖由打包好的 `.cache/project-dependencies` 承担）。

## 探针 2：完整 Host 启动（startProjectHost）

脚本 `.runtime/host-boot-probe.mjs`，对同一 `stateDirectory` 调用
`startProjectHost({manifestPath, projectRoot, stateDirectory})` 两次并计时。
这条路径包含 profile 准备、Host 子进程 fork 与顶层 import、官方 `boot()` 组装
插件树、loopback Web server、渲染认证换取 Cookie。

```
FIRST_startProjectHost_ms=3775  tools=4  port=59471
FIRST_close_ms=38
SECOND_startProjectHost_ms=2475  tools=4  port=59489
SECOND_close_ms=40
```

## 解读

- macOS arm64 上，完整 boot 约 **2.5–3.0 秒**，距 30 秒预算有 10 倍以上余量。
- 因此 30 秒超时**不可能**由"首次 pnpm install"造成，原假设作废。
- 用户环境是 Windows（企业域账户 + `%APPDATA%` 用户目录）。30 秒超时的真实来源
  尚未确证，候选（均需 Windows 实测）：
  1. 用户目录 IO：`AppData\Roaming` 在域环境可能被文件夹重定向/漫游同步；
  2. Windows Defender 首次扫描：Host 子进程冷启动要 import 数百个 JS 文件；
  3. Electron utilityProcess 冷启动 + 首次 pnpm 进程（19MB bundle）在 Windows 上的开销；
  4. 并非"慢"而是"卡住"——官方 `HostRpc` 对超时与被取消共用同一句 reject，
     单看错误文案无法区分。

## 对已落地改动的影响

`HOST_BOOT_TIMEOUT_MS=300000` / `HOST_READY_TIMEOUT_MS=120000` 本身仍成立
（把"慢"与"错"区分开，避免正常慢启动被报成失败），但**理由需要改写**：
它不是在覆盖一个 120 秒的物化预算，而是在为一个尚未实测分布的 Windows 冷启动留余量。
若 Windows 实测 boot 在 5–15 秒量级，300 秒偏大，宜向官方 Desktop 的 120 秒收敛。
