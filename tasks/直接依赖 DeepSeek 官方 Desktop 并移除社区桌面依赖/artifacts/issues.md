# 官方 Desktop 原位替换：问题点与验证清单

> 2026-09-30 主进程阶段更新：正式 Shell 及默认 setup/build/start/check 已切到官方 0.2.0-rc.2，
> 双项目生命周期和真实引导页检查通过。详见 [Shell 主进程切换报告](shell-main-switch.md)。
> 下方此前的“正式 main 尚未接入”属于历史阶段；安装包、CI、数据迁移与完整功能验收仍未完成。

日期：2026-09-28；2026-09-29 更新官方候选版本。状态：调研记录；“待验证”表示尚无通过的原生或迁移实验。对应方案见 [迁移设计](design.md)。

| ID | 级别 | 问题与现有证据 | 首个解决关口 |
| --- | --- | --- | --- |
| O01 | 阻断 | 官方 `apps/desktop` 包为 `private: true`；已发布 `0.1.11` 的来源锁仍固定社区 `dsh-plugin-desktop@2.0.15`。已从固定官方 `0.2.0-rc.2` 提交完成源码构建、Host、双 Host 和临时双 Electron 窗口实验；壳安装包和完整构建闭包仍待证明。 | 官方依赖可行性实验 |
| O02 | 阻断 | 官方当前 `main.ts` 只有应用级 `mainWindow`，`paths.ts` 固定一个 `profiles/desktop`。临时探针已让两个官方 Web 窗口各有 Host 与 Session，A 强制销毁后 B 存活；正式 Shell 的多项目生命周期仍未接入。 | 双项目运行骨架 |
| O03 | 阻断 | 当前 [`src/desktop-adapter/native.mjs`](../../../resources/dsh-project-desktop/src/desktop-adapter/native.mjs) 和 `stable/` 大量调用社区私有模块。用户已明确这些模块全部弃用；按 Shell/Project 插件/官方 Desktop 的职责重接入口，旧调用清单用于删除审计，不是逐项兼容需求。 | 删除社区调用，接通壳到官方主界面 |
| O04 | 阻断 | `dsh-plugin-project` 候选分支已改到官方 `0.2.0-rc.2`，适配 Sidebar 注入与 macOS `SidebarRoot` DOM，并在临时双 Electron 窗口显示独立 Project 概览。默认 `upstream.json` 与 setup 现只接受固定官方源码；类型检查、307 项测试、构建通过。历史 `desktop-runtime.ts` 与 Electron 回归材料仍使用社区接口；Tasks/Resources/Memory/skills/MCP 写入行为和打包兼容尚未证明。 | 插件兼容实验 |
| O05 | 阻断 | 旧项目 DSH Home 在 `userData/projects/<hash>/dsh`。已发布版虽使用官方 Harness `0.1.7-rc.2`，Profile、设置与插件组合仍由社区 Desktop `2.0.15` 管理；切到官方 `apps/desktop` 的启动和安装逻辑时，没有针对项目级 Home 的现成迁移保证。 | 旧项目副本迁移/回退实验 |
| O06 | 高 | `dsh-app://app` 在所有项目窗口使用同一 Origin；逐项目 Session 转发和主 Frame IPC 适配器均已接入真实探针，单测覆盖错误 WebContents、Host、Origin、旧 Cookie 与重复注册拒绝。已补齐 Session/IPC 释放，并在官方 payload 双窗口加 Project 插件中验证 A 同分区重开、B 存活、旧清理不影响新所有者和最终注册清空。尚需在正式 Shell 验证 Host 重启、跨项目凭据、重定向、外链和恢复窗口不能串线。`dsh://open` 仅是操作系统唤起入口。 | 窗口 Session 重开已验证；继续正式 Shell 生命周期与安全验收 |
| O07 | 范围已收敛 | 官方没有社区版的 Profile 选择/创建及恢复助手窗口。用户明确社区私有模块全部不用；本轮复用官方能力并保证逐项目运行隔离，不为社区独有窗口补一套替代实现。旧 Profile 数据的处理仍归 O05/O10 的迁移验收。 | 不阻断主进程切换；数据迁移单独验证 |
| O08 | 高 | 插件默认 setup 已切换官方源码；Shell 的 [`scripts/setup.mjs`](../../../resources/dsh-project-desktop/scripts/setup.mjs)、[`scripts/verify-upstream.mjs`](../../../resources/dsh-project-desktop/scripts/verify-upstream.mjs)、[`scripts/build.mjs`](../../../resources/dsh-project-desktop/scripts/build.mjs)、打包脚本和多条 GitHub Actions 工作流仍从社区仓库导出源码、依赖缓存并校验其版本。删除运行时代码引用还不足以实现零社区依赖。 | 构建闭包与安装包审计 |
| O09 | 高 | 当前更新清单只接受 `channel: stable` 和 `x.y.z`；直接替换时旧 Stable 客户端不会接受 `-next` 版本。需明确候选版测试方式和正式版版本号，并验证旧客户端发现及安装新包。 | 发布/更新演练 |
| O10 | 高 | 新旧版本使用同一应用数据根；迁移失败、断电或用户重装旧包时可能读到半迁移数据。需要备份、迁移日志、原子切换或等价恢复机制，并实测回退。 | 破坏性故障注入 |
| O11 | 中 | 当前欢迎页和模型页仍从社区 Desktop 与官方 Harness 源码构建组件，官方 Web 前端的扩展入口和首次引导机制不同。要保留完整官方界面和项目插件入口，不能只用 CSS 隐藏不适用功能。 | 真实窗口 UI 验收 |
| O12 | 中 | 社区来源仍写在 README、`AGENTS.md`、架构文档、`THIRD_PARTY_NOTICES.md` 和插件开发说明。实施后须按实际依赖更新说明，同时保留必要历史归属。 | 文档/许可审计 |
| O13 | 高 | 官方 `dsh-v0.2.0-rc.2` 相对现有 `0.1.7-rc.2` 将自动化任务移到可选插件包。需核对 Project 插件的任务界面、任务记录和定时能力在新组合中的入口与安装默认值，防止原位升级后功能消失。 | 插件兼容与旧数据验收 |
| O14 | 阻断 | 已从 287 个官方核心 tarball 与固定生产锁组装 macOS arm64 未签名开发运行目录，包含 Host/CLI 外部依赖、Electron、Web/preload、原生资源和 Node/Python/pnpm；19,358 项清单含 14 条包内链接，搬移前后官方原生/Host/Office smoke 均通过，payload 双窗口加 Project 插件通过。探针控制脚本仍读固定官方源码，插件仍用开发链接；正式 `build.mjs`、`upstream.lock.json`、安装包和 CI 仍走社区布局，其他平台锁与签名尚未完成。 | arm64 开发运行闭包已验证；接入正式 Shell 与插件发行依赖并扩展平台 |

## 需先证实的官方契约

1. 官方 `apps/desktop` 固定提交的 `tsdown` 产物是否暴露足够的模块；不足时只从同一固定源码编译选定文件，记录 tree hash 与许可证。
2. 官方 Host 的启动参数、认证 Cookie、原生能力、WebServer 绑定和关闭协议能否一对一实例化并服务多个项目；社区 Next 的实现仅作调研参考，不进入依赖图。
3. 临时项目级 `dsh-app://app` Session 已显示官方基础界面；插件、设置、模型、附件、终端与平台能力仍需在正式 Shell 的真实窗口逐项验证。
4. 官方 `DesktopProjectManager`、恢复和安装逻辑能否针对外部项目 Home 使用；若它们假定 `profiles/desktop`，仅复用底层算法，项目范围的编排由壳负责。
5. 官方 `0.2.0-rc.2` 发布包、官方仓库依赖锁、native 模块及 Electron 版本在 macOS Universal 与 Windows x64 上能否形成完整可搬移安装包。

## 旧社区调用的删除审计（不是兼容清单）

| 当前使用的社区模块 | 官方候选基础 | 尚需解决 |
| --- | --- | --- |
| `host-rpc`、`host-runtime-bridge`、`renderer-boot`、`desktop-browser-access` | `apps/desktop/src/host-process.ts`、`backend-controller.ts`、`web-document.ts`，官方 `runProfile`/WebServer | 多 Host、逐项目认证与协议 Session；不能沿用旧 RPC 契约 |
| `profile-manager`、`profile-selection-window`、`profile-create-window` | `apps/desktop/src/project-manager.ts`、`@deepseek-ai/dsh-app-boot` Profile 模板 | 移除社区模块调用，复用官方初始化；不复刻社区选择/创建 UI |
| `startup-recovery-window`、`profile-checkpoint`、`safe-mode` | `apps/desktop/src/fatal-recovery.ts`、官方 Profile 清理及恢复能力 | 移除社区恢复链；逐项目故障隔离及旧数据可恢复性单独验收 |
| `index` 客户端、`settings-client`、`window-options` | 官方 `@deepseek-ai/dsh-web-frontend`、平台 preload/视图模块 | Project 插件入口、模型页、项目设置和窗口材质的完整行为 |
| `update-lifecycle`、`update-download`、原生菜单和诊断模块 | 官方 Desktop 的更新/菜单/诊断实现作为源码参考 | 继续使用我们的 GitHub Release、原应用身份及多项目退出顺序 |

## 审计范围

“不依赖社区 Desktop”的判定覆盖 Shell 与 Project 插件两个仓库：固定锁、源码快照、开发 setup、CI checkout、依赖缓存、构建产物、打包闭包、运行时导入和发布流程。单纯在历史文档中出现社区名称不算依赖；当前仍执行或指向社区源码的路径都必须清除。验收时从干净工作目录构建并检查安装包内容，不依赖开发机已有缓存。
