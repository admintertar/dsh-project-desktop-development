---
name: desktop-release
description: DSH Project Desktop 官方来源发行手册：版本、固定插件提交、双语说明，三个原生 CI 目标，安装包搬移验收，以及发布同一批已验证产物。适用于 0.2.0 及后续版本。
whenToUse: 发布壳版本、更新插件 pin、检查官方来源 CI、查询发行进度、验证安装包和公开更新清单时。
---

# DSH Project Desktop 发布

## 来源与授权

- 发布的是我们自己的 `admintertar/dsh-project-desktop`；官方仅指 `deepseek-ai/deepseek-harness/apps/desktop`。
- Shell 版本与内置官方 Harness 版本分别维护。0.2.0 Shell 使用官方 0.2.0-rc.2，不把官方版本当成本项目版本。
- 用户明确要求提交/发布时，授权包含必要的自有仓库提交、推送、CI、tag 和 Release；不反复询问已授权的动作。不推 DeepSeek 上游。
- 产品改动在独立 worktree 完成、验证后精确集成。主工作树干净且 HEAD 是 worktree 的祖先时可 fast-forward，保留已验证提交身份。不得夹带其他会话改动。

## 发布三件套

1. `resources/dsh-project-desktop/package.json`：壳版本。
2. `project-source.lock.json`：**先推送插件提交，再固定该 commit**。核对插件 remote 和官方 `upstream.json` 与壳 `official-source.lock.json` 一致。
3. `docs/releases/<version>.md`：中英双语说明、安装方式与实际限制。

旧 `upstream.lock.json` 是社区版历史记录，**不能再改它来驱动官方构建**。不要调用旧社区 setup、safe-mode、profile recovery 或更新 smoke。

## 验证与构建

- 官方来源：`official-source.lock.json` 校验 repo / commit / tag / Desktop tree / pnpm-lock blob。
- 三目标：mac-arm64 / mac-x64 / win-x64，分别在 macos-15 / macos-15-intel / windows-2022 原生执行。
- Node 24，官方 pnpm frozen lock；Shell 与插件 Yarn immutable。Windows 使用 pwsh。
- 官方核心 tarballs → 官方 runtime resources → `official-runtime-locks/<target>` frozen production install → 官方 Host/Office/搬移校验 → Shell 打包。
- 官方 pnpm pack 的完整 package.json 字段顺序会变化，不能把不同构建的 tarball 字节哈希当成相同源码的稳定身份。先核对 `package-manifests.json` 中固定的完整 manifest，再仅绑定当前官方 tarball 的 integrity；外部依赖图、版本及哈希不变，仍使用 frozen 安装。
- 执行 `yarn check`、插件 `yarn check`、`yarn smoke:official-shell`。
- `yarn package:mac` / `yarn package:win` 必须在对应平台、干净 checkout、固定插件来源下执行，拒绝 `DSH_PROJECT_PLUGIN_SOURCE`。
- 最终包搬到仓库外，通过 `--verify-installation` 验证欢迎、双项目、真实 Host、关闭隔离和重开，使用系统 TEMP userData；不访问默认用户数据。

## 发布路径

推荐先推代码触发 **Official Desktop CI and Release**，待三个目标通过，再运行 **Publish Verified Desktop**：

- dispatch 指向同一提交所在分支，`build_run` 填成功的构建 run ID。
- `verify-release-run.mjs` 核对工作流路径、仓库、成功状态与精确 HEAD。
- 发布 job 下载该 run 的安装包，逐项校验三个目标、源码/插件提交、版本、大小、SHA-256 和已打包状态。
- 先上传 draft 并核对 GitHub digest，然后创建版本 tag 并发布；不重新构建。
- 也支持推送与 package.json 一致的 `v*` tag 触发完整构建及发布；不要在已有绿色构建后无故重复跑全部构建。
- 当前 workflow 不暴露覆盖重发。已有 tag/release 冲突时先明确原因，不能静默移动 tag。

## 更新与安装约定

- 更新清单 v2：mac-arm64.dmg、mac-x64.dmg、win-x64-Setup.exe、win-x64-Portable.zip，各有 SHA-256。
- 0.2.0 更新器兼容读取 v1 universal 清单；旧 0.1.x 不识别 v2，升级到 0.2.0 需手动下载安装。
- 0.2.0 由用户明确决定发 Stable。旧社区 Home 迁移未实现，保留并拒绝接管，不宣称旧数据兼容。发布说明必须保留该限制，后续迁移另行验收。
- macOS ad-hoc、未公证；Windows 未签名。不要把这些包描述为厂商签名版本。
- 发布后验证 GitHub release 非 draft、非 prerelease，latest 指向目标版本，公开 `update.json` 的 commit/版本/资产哈希匹配；验证不能只有认证 API，匿名下载也必须可用。

## CI 排查

- GitHub CLI 未登录时，可用已配置的 Git credential helper 为**当前子进程**提供 GH_TOKEN；不把凭据写入文件或输出。
- 查询 run/job 必须带具体 run ID，不把不同 workflow 的编号混用。避免频繁查询；阶段不变时做独立工作或短暂等待。
- 读取失败 job 日志，定位具体阶段；不以 macOS 本机成功推断 Windows/Intel 成功。
- Windows 的 Node `--import` 必须传 `pathToFileURL(...).href`；裸盘符路径会被识别为不支持的 URL 协议。
- Windows Electron 44.0.0 的测试不要在窗口 `closed` 事件后的同一轮微任务立即恢复 `nativeTheme`；独立程序可复现 `0xFFFF7003`。在窗口仍存活时恢复 system 并等待实际 DOM 主题一致，再验证取消与关闭；不要为测试清理时序降级运行时或改官方源码。
- 运行期缓存、完整日志与下载的安装包不进 tasks/artifacts；只保存报告、脱敏摘要及少量必要截图。
