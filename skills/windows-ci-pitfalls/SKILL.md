---
name: windows-ci-pitfalls
description: 处理「macOS 上通过、Windows 上失败」的排查手册。覆盖 GNU tar 的绝对路径、corepack.cmd 的 spawn 限制、CI=true 的 immutable 安装、8.3 短名下的路径比较、长路径上限、被占用的目录不可删、chmod 与文件名约束、窗口边框与高 DPI、原生菜单差异，并给出让 CI 打印真相与读取 CI 日志的具体做法。
whenToUse: 当改动在 macOS 上验证通过、却在 Windows CI（Verify Resources on Windows / Verify Guide on Windows / Package Desktop）或本地 Windows 上失败，或需要在 Windows 上新增原生冒烟、修改 CI 步骤、编写路径比较与文件断言时。
---

# Windows CI 与 Windows 开发排查

Windows 上的失败大多不是逻辑错误，而是**平台语义差异**。先按下面的分类定位，再动手改代码。

## 第一原则

「本地 macOS 绿、Windows CI 红」时，**先找出本地恰好绕过了什么**，而不是怀疑代码逻辑。
常见的绕过来源：路径长度富余、没有 8.3 短名、`chmod` 真的生效、窗口边框不吃内容区宽度、
本地没有 `corepack enable` 生成的 pnpm shim、本地有缓存而 CI 没有。

另一个前提：CI 的 Windows 作业过去**只构建插件、从不运行它自己的测试套件**，
所以插件测试里的平台缺陷可以长期潜伏。现在 `resources-windows.yml` 已补上
`Export the pinned official runtime for the Project plugin` 与 `Verify the Project plugin on Windows`。

## 一、工具链与 Yarn

### GNU tar 会把 `-C D:\...` 当远程主机

- **症状**：`tar: Cannot connect to D: resolve failed`，退出码 128。
- **原因**：CI 的 `defaults.run.shell: bash` 是 Git Bash，PATH 中 `usr/bin` 在前，`tar` 是 GNU tar；
  它把 `-f`/`-C` 值里的冒号读成 `host:path`。
- **复现**：把 `C:\Program Files\Git\usr\bin` 放到 PATH 最前；bsdtar 正常。
- **修法**：不要传绝对 Windows 路径，改为在目标目录内用相对文件名：
  `execFileSync('tar', ['-xf', 'runtime.tar'], {cwd: snapshot})`。

### `corepack.cmd` 不能脱离 shell 被 spawn

- **症状**：命令以退出码 1 结束且**完全没有输出**。
- **原因**：Node 22 在 CVE-2024-27980 之后禁止 `shell: false` 直接 spawn `.cmd`；
  `spawnSync('corepack.cmd', ...)` 得到 `status=null`、`error.code=EINVAL`，
  紧接着的 `if (status !== 0) process.exit(1)` 静默退出。
- **判据**：**「没有任何输出却失败」** 在 Windows 上通常意味着 spawn 阶段就失败了。
- **修法**：`shell: process.platform === 'win32'`。

### `CI=true` 会打开 immutable 安装

- **症状**：`YN0028: The lockfile would have been modified by this install, which is explicitly forbidden.`
- **原因**：插件 `setup.mjs` 会在 `.dev/runtime` 播一个**空 `yarn.lock`** 作为项目边界，
  随后的 `yarn install` 必须填充它；CI 的 `CI=true` 让 Yarn 默认 immutable。
- **复现**：**`CI=true` + 清空 `.dev/runtime`**。不清空就永远看不到（本地 lockfile 早已填满）。
- **修法**：只为这一次安装传 `YARN_ENABLE_IMMUTABLE_INSTALLS: 'false'`。

### corepack 的 pnpm shim 与 `packageManager` 冲突

- **症状**：恢复模式卸载插件失败，stderr 含
  `This project is configured to use yarn because ... has a "packageManager" field`。
- **原因**：profile 目录在壳仓库 `.runtime/` 之下，corepack 向上找到壳的 `packageManager`。
- **修法**：**不要移除 pnpm shim**。真正原因通常是隔离 shim 没写成功（见「长路径上限」），
  修好长路径后 pnpm 自然可用。

## 二、文件系统语义

### 8.3 短名：`fs.realpathSync` 不展开，git 会展开

- **症状**：一次挂几十个用例，错误是 `resource-git-invalid`、`task-commit-resource-unavailable`，
  或本应报 `target-tracked` 却变成 `clone-failed`；本地全绿。
- **原因**：Node 的 `fs.realpathSync` 在 Windows 上**不展开 8.3 短名**，
  而 `git rev-parse --show-toplevel` 返回**展开后的长名**。CI runner 的
  `os.tmpdir()` 是 `C:\Users\RUNNER~1\AppData\Local\Temp`，两侧因此不相等。
- **本机验证**：`fs.realpathSync('C:\\PROGRA~1')` 原样返回；`.native` 得到 `C:\Program Files`。
- **修法**：**两个路径互相比较**时统一用 `fs.realpathSync.native`；
  用 `relative()`/`within()` 做边界判断前，也先把两侧规范化。
- **反例警告**：检测符号链接的 `realpathSync(x) !== x` 必须**保持 JS 版**——
  换成 `.native` 会把短名展开成长名，把普通路径误判为符号链接。

### 长路径上限

- **症状**：冒烟失败，且 DSH 生成的隔离 pnpm shim 目录为**空**。
- **原因**：`LongPathsEnabled=0` 时写入上限约 320 字符（Node 的 `\\?\` 前缀只把 260 抬了一点），
  而深层临时路径可达 329 字符。
- **修法**：启用 `LongPathsEnabled=1`（需管理员；进程启动时读取，不必重启整机）。
  本机还需 `git config --global core.longpaths true`，否则 `git worktree remove` 报 `Filename too long`。

### 被进程占用的目录不能删

- **症状**：`EPERM ... rm`，`$TEMP` 里堆积残留 fixture 目录。
- **原因**：Windows 不允许删除仍被持有的目录（Unix 允许）；`rmSync` 的 `force` 只忽略 ENOENT，
  **不重试 EPERM**。
- **判据**：残留目录稍后手动都能删掉 → 说明只在运行期间被短暂锁定。
- **修法**：清理改为**尽力而为**（失败只警告），必要时加 `maxRetries`/`retryDelay`。

### 其他约束

- **文件名不允许控制字符**：含 `\n`/`\t` 的文件名在 Windows 必然 `ENOENT`。
- **`chmod` 只能切只读位**：`statSync().mode & 0o777` 恒为 `0o666`（只读时 `0o444`），
  断言 `0o600`/`0o640` 永远不成立；用 `skip: process.platform === 'win32'` 或条件断言。
- **`core.autocrlf=true` 污染工作树**：`git archive` 与检出都得到 CRLF，使字节断言与 tree hash 校验失败。
  统一 `core.autocrlf=false`，并强制重写工作树（`git rm --cached -r .` + `git reset --hard`）。

## 三、窗口与原生界面

- **窗口边框吃掉内容区尺寸**：高 DPI 下 `setSize(1180, 820)` 与 `setContentSize(1180, 820)`
  都让 `innerWidth` 恒为 1179（`outerWidth` 1192）。精确断言在 Windows 上**物理不可能成立**；
  改为容忍 ±2，或**基于 UI 的实际状态**判断（例如读 `data-guide-compact`，而不是用请求宽度推推断点）。
- **原生菜单结构不同**：macOS 把「退出 <App 名>」放在顶部应用菜单，Windows 靠窗口框架关闭。
  断言只校验可移植部分（「编辑/视图/窗口」的本地化文案）。
- **前台窗口**：多窗口并存时，固定屏幕坐标取样只会量到最上层那个；
  优先读目标的实时 DOM 与计算样式，不要从截图反推表面。

## 四、排查手法

1. **让 CI 打印真相**：临时加一步诊断，打印 `os.tmpdir()`、`git` 原始输出、路径与 `EQUAL` 之类的布尔值；
   定位后立刻移除。这比反复推测快得多。
2. **按 CI 的精确条件本地复现**：`CI=true`、把 GNU tar 放到 PATH 最前、shallow clone、空 yarn 缓存。
   能复现就能直接调试。
3. **本地无法复现时**，回到第一原则：列出本地与 CI 的差异清单，逐项排除。
4. **读 CI 日志**：日志 API 对匿名请求返回 403；可用 `git credential fill` 取出本机已存凭据
   （GitHub Desktop 的 OAuth token 即可），带 `Authorization: Bearer` 调 `api.github.com`。
   `github.com` 直连可能被阻断，而 `api.github.com` 往往仍可达。
5. **发布说明机制**：`scripts/publish-release.mjs` 读取 `docs/releases/<version>.md` 作为 Release 说明；
   该文件缺失时 Release 只剩下载链接。改动原生行为或平台支持时，记得同时写该文件。
