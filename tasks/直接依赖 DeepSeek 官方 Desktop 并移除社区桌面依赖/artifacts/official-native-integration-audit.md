# 官方原生接入查漏与实施记录

目标：对照固定 DeepSeek `0.2.0-rc.2` 的 Desktop 主进程与 preload，补齐 Shell 职责内的原生能力；不恢复 Anywhere Labs 社区模块。

## 实施计划

1. `official/account-session.mjs`：复用官方 `backend.account.watch`，按尝试去重打开授权页，追加当前主题，失败/过期/成功返回所属窗口；关闭项目释放订阅。PKCE、凭据、回调仍由官方 Host 处理。
2. `official/deep-links.mjs` 与 `app/main.mjs`：接入精确的 `dsh://open`，处理 macOS open-url、Windows second-instance 与启动参数；启动前排队，多项目优先定位最近登录项目，关闭后回退可用窗口。开发运行默认不抢占已安装应用的协议注册。
3. 编译官方 `login-shell-environment.ts`，全应用共享一次读取，传给各 Host，最终覆盖项目 Home/Profile。退出取消探针，不记录环境或授权 URL。
4. `official/windows-chrome.mjs`、`project-ipc.mjs`、`project-window.mjs`：官方 40px titlebar overlay，验证 appearance/menu 参数、窗口所属关系、缩放坐标，编辑菜单使用官方 sendEditingKey；应用菜单复用 Shell 项目命令。
5. 覆盖登录去重/隔离/销毁、协议排队、菜单参数/编辑键和环境取消的行为测试；跑完整 `yarn check`，独立重建 runtime 后进行 macOS arm64 原生登录取消与双项目生命周期验证。
6. 更新架构引用、第三方出处及任务结论，在验证后将本轮改动精确集成回开发分支。

## 对照清单

| 能力 | 初始审计结论 |
| --- | --- |
| Host、认证 Cookie、HTTP/WS、逐项目 Home/Profile/Session | 已接 |
| boot、locale、主题、onboarding、device info | 已接 |
| 快捷键、目录选择、全屏、关闭确认 | 已接 |
| 浏览器 guest leases、安全限制和窗口释放 | 直接复用官方 helper；继续核对多项目边界 |
| Platform 用量/充值视图与 private session IPC | 已接，按项目隔离分区 |
| 登录自动打开浏览器、唤回 | 漏接，本轮修复 |
| Finder/Dock 启动读取 login shell 环境 | 漏接，本轮修复 |
| Windows 标题栏/菜单 IPC | 漏接，本轮修复；Windows 实机待验 |
| 官方欢迎页及其专用 IPC | 自有项目欢迎页替代，不属于遗漏 |
| 官方自动更新/强制升级/全局 CLI 安装 | 发行适配待完成，不能用官方更新器覆盖 Shell |
| 安装包/CI/Stable 数据迁移回退 | 现有任务发布门禁，未完成 |
| 社区私有 Profile/Recovery | 按用户要求弃用 |

## 验证与结论

修复已集成到 Shell `codex/direct-official-desktop`，本地提交 `e5318ca`、`5604476`，未推送或发布。官方源码保持只读，插件未改动。

### 已补齐

- 登录主进程订阅：官方状态流自动打开浏览器、链接主题、尝试去重、失败/过期/成功返回所属窗口、关闭释放。
- `dsh://open` 分发：启动排队、macOS open-url、Windows second-instance/argv；仅 packaged 或显式开发标记注册系统协议。协议无项目 id，优先最近有效登录尝试，成功时另直接聚焦所属项目。
- Host 环境：原样编译官方 login shell reader，应用共享一次读取，各项目最后覆盖自己的 Home 与 manifest；退出取消探针。
- Windows caption：官方 40px overlay、appearance/menu IPC、来源与参数验证、缩放坐标和官方编辑键，Application 菜单使用 Shell 的项目命令；关闭时结算 popup 请求。
- 补充系统关机/注销识别，保存应用恢复集合并跳过交互确认；普通关闭继续官方确认。恢复官方右键菜单分隔与 Windows 当前语言。

### 已验证

- 完整 `yarn run check`：128/128，通过构建、测试与项目文件检查。10 项新增测试覆盖账号监听生命周期、多项目唤回、环境读取取消、Windows caption/菜单与系统退出标记。
- 独立重建固定官方 mac-arm64 runtime；原生依赖、Host、Office、搬移检查及 payload 清单验证通过。
- macOS arm64 真实 Shell + 官方 Web + Project：欢迎/创建、双项目、主题、关闭/重开/重启、旧数据拒绝接管、所有 IPC owner/协议释放均通过，Renderer error 为 0。
- 官方登录菜单 → 等待登录弹窗 → 官方在线 auth_init 返回成功 → 主进程监听调用打开授权页 → `dsh://open` 内部分发回原项目 → 官方弹窗取消/auth_cancel 成功。测试在 OS openExternal 边界截获调用，未输入凭据，未完成真实账号授权。
- 相同工作区名在两个项目获得不同浏览器分区；所属 Host 请求被官方 guest policy 阻断；其他项目 Host 拒绝未认证 guest（401/403）。官方 helper 仅直接阻断自己的 Host，其他 Host 仍依赖独立认证；未宣称所有 loopback 网络禁止。
- 结论数据见 `official-native-integration-result.json`，真实官方登录弹窗见 `official-account-waiting.png`。运行数据、凭据及原始日志不进入任务目录。

### 后续验收与边界

1. 用户真实授权成功、重启后凭据恢复、注销/过期、用量及充值页面。当前凭据与 Platform view 原生桥已接，但无真实账号完成记录。
2. 安装版 `dsh://open` 的 OS 注册/浏览器返回联调；普通开发不抢占已安装应用的协议。真实 Windows caption、编辑、缩放、关机/注销和 macOS Intel 待验；本轮只对系统退出事件做行为测试，没有实际关闭操作系统。
3. 完整快捷键编辑、目录拖放、麦克风/浏览器导航弹窗的交互验收；不以 bridge 可调用代替所有 UI 验收。
4. 自有更新器/强制版本策略、全局 CLI 安装、签名打包/CI、固定插件发行闭包、Stable 数据迁移和回退仍是发布门禁。
5. Windows preload 的 mandatory overlay 允许开发无策略时 status 拒绝；当前保持这个明确边界。官方 Welcome/更新/CLI 专用窗口不是漏接清单，不能安装原版官方更新来覆盖 Shell。

当前开发窗口若已运行，仍持有旧主进程模块；本轮修复在重启后加载。

主开发 checkout 的官方运行目录也已按同一构建流程重建并通过 payload 验证；现有窗口仍需重启加载新主进程。
