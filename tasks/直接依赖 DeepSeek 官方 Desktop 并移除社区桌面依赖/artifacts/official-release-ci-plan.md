# 官方来源 CI 与壳 0.2.0 Stable 发布

## 用户确认

用户最初选择预发布，随后明确改为直接发布自己的 DSH Project Desktop **0.2.0 Stable**（现阶段用户很少）。固定使用 DeepSeek Harness `0.2.0-rc.2`。发布自有 GitHub Releases 并更新 Stable 清单；旧 Home 仍保留且拒绝隐式迁移，发布说明明确列出限制。

## 实施

1. 固定并推送当前 Project 插件提交，更新 `project-source.lock.json`。Shell 在独立 worktree `codex/official-release-ci` 修改。
2. 参考官方 Desktop `package-target.ts` 的三个原生目标、`prepare:runtime`、核心 tarball 集、运行时过滤/校验及搬移后 smoke；仅适配自有主进程、品牌、插件和未签名发行。官方源码不修改。
3. CI 只检出 DeepSeek 官方与本项目插件；Node 24、官方 pnpm frozen lock、Shell/插件 Yarn immutable；Windows 使用 pwsh。三个平台执行源码检查、真实 Electron 和安装产物验证，发布 job 单独持有写权限。
4. 移除还调用社区模块的旧 CI，合并为同一条官方构建验证流程。安装包不得依赖工作区路径或开发插件链接。
5. 正式版仅在三个平台均通过、安装包哈希和构建提交一致后发布。核对 Stable 标记及 latest / update.json 都指向本次发布。记录实际结果，不用本机 macOS 结果代替 Windows/Intel 验证。

## 验证重点

- 错误来源 pin、脏工作树、缺少目标或篡改产物时拒绝发布。
- v2 更新清单按 macOS 架构选包，保留旧 v1 读取能力；0.1.x 手动安装本版。
- 安装包在仓库外运行：欢迎、双项目、真实官方页面、关闭隔离、重开。
- 旧 Stable Home 继续原样保留并明确拒绝隐式迁移。

## CI 首轮修复

- Windows ESM loader 的裸盘符路径改为 file URL。
- 官方 pnpm 打包会异步重写 workspace 依赖，完整 package.json 字段顺序变化使 tarball 哈希不稳定。固定 287 个包的完整配置，核对后仅更新本次官方 tarball 的 integrity；外部依赖图、版本与哈希不变，继续 frozen 安装。
- 本机 143 项壳检查通过；使用重新打包的 Host 完成 frozen 安装、官方 Host/Office 与搬移验证。远端三目标需独立完成，最终状态见发行结果记录。
- Windows 插件检查发现 Skill Provider 返回完整路径，而 Project Skill 根目录仍保留 TEMP 的 8.3 短名。插件统一 Skill 边界和导入路径的原生路径身份；本机 308 项插件检查及壳真实生命周期回归通过，Windows 由下一轮 CI 复核。

## 最终原生时序修复

- Windows 的插件 308 项检查已通过。Electron 44.0.0 在测试窗口 `closed` 事件后立即修改 `nativeTheme.themeSource` 会原生退出 `0xFFFF7003`；不加载 Shell 或官方模块的独立程序在 run `36713000793` 复现。
- 同一程序改为窗口存活时恢复 system，run `36713461113` 通过。正式 smoke 在关闭前验证 light、dark、system 三种主题与真实 DOM，保留取消和销毁检查；移除临时诊断脚本与 workflow。
- Shell 提交 `806c54063d4df6ff492d176fa6826881f0b5bc2f`，本机 143 项检查及真实双项目生命周期通过。最终三平台 run `36713622201` 第 2 次运行全部通过；第 1 次未分配到 GitHub runner，未执行代码。

## 发布结果

- 自有壳 **v0.2.0 Stable** 已发布，Release ID `400040136`，发布 run `36717138776` 成功；非 draft、非 prerelease，`latest` 与 tag 指向最终提交。
- Shell 和插件已快进推送各自 `master`。发布工作流消费三平台同批已验证产物，没有重新构建；主分支推送触发的同提交重复构建已取消。
- 文件：macOS arm64 DMG、macOS x64 DMG、Windows x64 Setup、Windows x64 Portable ZIP，各有 SHA-256，另附自有 `update.json` v2。具体大小、哈希与验收项保存在 `official-release-result.json`。
- 三平台均验证欢迎、双项目、关闭隔离与重开。两个 DMG 另验证挂载、图标、本机可执行文件及启动后的签名完整性；Windows 验证便携包解压搬移启动，未将其描述为 NSIS 交互安装验收。
- 发布后检查版本入口和 latest 的匿名更新清单、四个公开校验文件，以及四个安装文件的匿名访问。
- 旧 Home 迁移、故障恢复和回退演练仍未完成；本次按用户决定先发 Stable，保留数据并拒绝隐式接管。0.1.x 手动安装，任务继续跟踪数据迁移。
