# Windows CI 与 Windows 开发踩坑记录

本文记录把 `dsh-project-desktop` 的 Windows 支持从「本地能跑」补到「CI 全绿」过程中踩到的坑，
含每个坑的**判定方法**与最终修法，避免重复排查。相关提交见 `resources` 下两个仓库的历史。

## 为什么这些坑此前不可见

- CI 的 Windows 作业（`resources-windows.yml`）**只构建插件、从不运行插件自己的测试套件**。
  现已补上 `Export the pinned official runtime for the Project plugin` 与
  `Verify the Project plugin on Windows` 两步。
- 本地 macOS 开发机能通过，是因为 macOS **恰好避开了**下面这些 Windows 语义：
  路径长度富余、没有 8.3 短名、`chmod` 真的生效、窗口边框不吃内容区宽度、
  也没有 `corepack enable` 生成的 pnpm shim。
- 因此「本地绿、CI 红」时，**先怀疑本地恰好绕过了某个平台语义**，而不是先怀疑代码逻辑。

## 一、CI 工具链与 Yarn 环境

### 1.1 GNU tar 把 `-C D:\...` 当远程主机

- **现象**：`tar: Cannot connect to D: resolve failed`，退出码 128。
- **根因**：CI 的 `defaults.run.shell: bash` 是 Git Bash，PATH 里 `usr/bin` 在前，`tar` 是 GNU tar；
  GNU tar 会把 `-f`/`-C` 值里的冒号读成 `host:path`。
- **判定**：本地把 `C:\Program Files\Git\usr\bin` 放到 PATH 最前即可复现（bsdtar 则正常）。
- **修法**：不要给 tar 传绝对 Windows 路径，改为在目标目录内用相对文件名解包：
  `execFileSync('tar', ['-xf', 'runtime.tar'], {cwd: snapshot})`。
- **壳侧不受影响**：壳的 `setup.mjs` 一直用 `['-xf', '-']` + `cwd`，所以只有插件那一处踩中。

### 1.2 `corepack.cmd` 不能脱离 shell 被 spawn

- **现象**：`yarn run setup` 以退出码 1 结束，**完全没有输出**。
- **根因**：Node 22 在 CVE-2024-27980 之后禁止 `shell: false` 直接 spawn `.cmd`；
  `spawnSync('corepack.cmd', ...)` 返回 `status=null`、`error.code=EINVAL`，
  随后 `if (status !== 0) process.exit(1)` 静默退出。
- **判定**：`spawnSync('corepack.cmd', ['--version'], {stdio:'inherit'})` 复现 `EINVAL`。
- **修法**：Windows 上传 `shell: process.platform === 'win32'`。
- **教训**：**"命令没有任何输出却失败"** 在 Windows 上通常意味着 spawn 阶段就失败了，
  而不是被测逻辑失败。

### 1.3 `CI=true` 会打开 immutable 安装

- **现象**：`YN0028: The lockfile would have been modified by this install, which is explicitly forbidden.`
- **根因**：插件 `setup.mjs` 会在 `.dev/runtime` 里**故意播一个空 `yarn.lock`** 作为项目边界，
  随后的 `yarn install` 必须填充它；而 CI 导出 `CI=true`，Yarn 因此默认开启 immutable 安装。
- **判定**：本地 **`CI=true` + 清空 `.dev/runtime`** 可精确复现；不清空则永远看不到
  （那个 lockfile 早已是几百 KB 的满文件）。
- **修法**：只为这一次安装传 `YARN_ENABLE_IMMUTABLE_INSTALLS: 'false'`
  （官方 Desktop 处理同一问题时用的也是这个开关）。

### 1.4 corepack 的 pnpm shim 与 `packageManager` 冲突

- **现象**：恢复模式下卸载插件失败，stderr 是
  `This project is configured to use yarn because ...package.json has a "packageManager" field`。
- **根因**：profile 目录位于壳仓库 `.runtime/` 之下，corepack 向上找到壳的
  `packageManager: yarn@4.18.0`，于是拒绝执行 pnpm。
- **修法**：**不要移除 pnpm shim**（`smoke:profiles` 依赖它）。真正原因是隔离 shim 没生成成功，
  见 2.1 —— 修好长路径后 pnpm 自然可用。

## 二、Windows 文件系统语义

### 2.1 8.3 短名：`fs.realpathSync` 不展开，git 会展开

- **现象**：Windows CI 上插件测试一次挂 51 个，错误是 `resource-git-invalid` 与
  `task-commit-resource-unavailable`，本地全绿。
- **根因**：Node 的 `fs.realpathSync` 在 Windows 上**不展开 8.3 短名**，
  而 `git rev-parse --show-toplevel` 返回**展开后的长名**。
  CI runner 的 `os.tmpdir()` 是 `C:\Users\RUNNER~1\AppData\Local\Temp`，
  于是「两个 realpath 必须相等」的校验必然失败。
- **判定**（可复用的手法）：**让 CI 自己打印真相**——临时加一步诊断，输出
  `os.tmpdir()`、`realpathSync(路径)`、`git rev-parse --show-toplevel` 与 `EQUAL` 的真值。
  本机也可直接验：`fs.realpathSync('C:\\PROGRA~1')` 原样返回，`.native` 才得到 `C:\Program Files`。
- **修法**：**两个路径互相比较**时统一用 `fs.realpathSync.native`；
  涉及 `relative()`/`within()` 的边界判断也要先把两侧都规范化。
- **反面提醒**：**检测符号链接**的写法 `realpathSync(x) !== x` 必须**保持 JS 版**——
  换成 `.native` 会把短名展开成长名，从而把普通路径误判成符号链接。

### 2.2 长路径上限

- **现象**：`smoke:profiles` 失败；DSH 生成的隔离 pnpm shim 目录为空。
- **根因**：`LongPathsEnabled=0` 时写入上限约 320 字符（Node 的 `\\?\` 前缀把 260 抬了一点但不够），
  而 profiles 的临时路径长达 329 字符。
- **判定**：路径长度探针（308 成功、358 `ENOENT`）+ 检查目标目录是否为空。
- **修法**：启用 `LongPathsEnabled=1`（需管理员；进程启动时读取，不必重启整机）。
  本机另需 `git config --global core.longpaths true`，否则 `git worktree remove` 会报
  `Filename too long`。

### 2.3 不能删除仍被进程占用的目录

- **现象**：`EPERM ... rm`，且 `$TEMP` 里堆积残留 fixture 目录。
- **根因**：Windows 不允许删除仍被任何进程持有的目录（Unix 允许）；
  `rmSync` 的 `force` 只忽略 ENOENT，**不重试 EPERM**。
- **判定**：`$TEMP` 里的残留目录稍后手动都能删掉 → 说明只是测试运行期间被短暂锁定。
- **修法**：fixture 清理改为**尽力而为**（失败只警告），必要时加 `maxRetries`/`retryDelay`。

### 2.4 其他 Windows 特有约束

- **文件名不允许控制字符**：用 `名称\twith space\nfile.txt` 这类文件名的用例在 Windows 必然 `ENOENT`。
- **`chmod` 只能切只读位**：`statSync().mode & 0o777` 恒为 `0o666`（或只读时的 `0o444`），
  断言 `0o600`/`0o640` 永远不成立。
- **`core.autocrlf=true` 会污染工作树**：`git archive` 与检出都会得到 CRLF，
  使字节数断言与 tree hash 校验失败。统一 `core.autocrlf=false` 并重写工作树。

## 三、窗口与原生界面

- **窗口边框吃掉内容区尺寸**：200% DPI 下 `setSize(1180, 820)` 与 `setContentSize(1180, 820)`
  都让 `innerWidth` 恒为 1179（`outerWidth` 1192）。精确断言 `innerWidth === 1180` 在 Windows 上
  **物理上不可能成立**；正确做法是容忍 ±2，或干脆**基于 UI 的实际状态**判断
  （例如用 `data-guide-compact` 是否存在，而不是用请求宽度推断断点）。
- **原生菜单结构不同**：macOS 把「退出 <App 名>」放在顶部应用菜单，Windows 靠窗口框架关闭、
  没有该项。断言应校验可移植的部分（「编辑/视图/窗口」的本地化文案）。
- **前台窗口**：同时开着多个窗口（安装版、开发壳）时，固定屏幕坐标取样只会量到最上层那个；
  优先读目标的实时 DOM 与计算样式，不要从截图反推表面。

## 四、可复用的排查手法

1. **让 CI 打印真相**：临时诊断步骤（打印路径、`git` 原始输出、`EQUAL` 之类的布尔值），
   定位后立刻移除。
2. **本地按 CI 的精确条件复现**：`CI=true`、把 GNU tar 放到 PATH 最前、shallow clone、
   空 yarn 缓存。能复现就能直接调试。
3. **本地无法复现时，先找「本地恰好避开了什么」**：长名 vs 短名、有缓存 vs 无缓存、
   有代理 vs 无代理。
4. **读 CI 日志的办法**：日志 API 对匿名请求返回 403；本机可用
   `git credential fill` 取出已存凭据（GitHub Desktop 的 OAuth token 即可），
   再带 `Authorization: Bearer` 调 `api.github.com`（`github.com` 直连可能被阻断，
   而 `api.github.com` 往往仍可达）。
5. **发布说明的机制**：`scripts/publish-release.mjs` 读取 `docs/releases/<version>.md` 作为
   Release 说明；该文件缺失时 Release 只剩下载链接（0.1.3 即如此）。
