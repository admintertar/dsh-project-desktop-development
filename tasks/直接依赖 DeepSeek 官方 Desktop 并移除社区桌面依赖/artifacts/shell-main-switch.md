# Shell 主进程直接接入官方 Desktop

日期：2026-09-30。分支：`codex/direct-official-desktop`。

Shell 本地提交：`4e13cc8`（切换 Shell 主进程与开发构建到 DeepSeek 官方 Desktop）；未推送、未发布。

## 本阶段结论

正式 `src/app/main.mjs` 已启动固定官方 Desktop/Host/Web，Shell 负责项目与窗口，Project 插件负责主窗口中的项目页面。
setup/build/start/check 的当前模块图不再加载 Anywhere Labs 社区 Desktop，没有社区 fallback。
旧社区适配文件与旧测试仍保留为删除审计材料，不等于整个仓库/安装包迁移已完成。

- 官方来源：`deepseek-ai/deepseek-harness`，`dsh-v0.2.0-rc.2`，`639ed015397290b3745d163aafe02ffee4aa3f84`。
- Project 开发候选提交：`a33cdb8483b0304b153e6cbb964568c14b168b12`；本轮未修改其源码、未推送候选 pin。
- 环境：macOS arm64，使用完整官方未签名运行 payload；Project 仍是经过校验的本地开发链接。

## 变更

1. main 从约 670 行社区/官方分支收口为官方入口，保留欢迎、创建、打开、最近项目、菜单、托盘与窗口状态。
   移除社区 Profile、恢复助手、安全模式及空更新操作；失败项目回到欢迎页重试。
2. 逐项目创建官方 `dsh-app-boot` Profile 与 `DesktopHostProcess`；隔离 Home、端口、认证与 Session。
   原生关闭交回 ProjectWorkspace，支持重开同一持久化分区；清理失败保留所有权，阻止竞争 Host。
3. 官方快捷键、目录选择、Welcome backend、账号/浏览器/权限 helper 从固定源码构建。
   最小适配仅改变 IPC 所属窗口、Platform 分区命名空间与 Shell 窗口生命周期。
   API Key/语言读取真实 Host，空项目仍报告未配置 API Key。
4. 共享主题通过官方 settings RPC 写入并校验 revision；忽略早于 Host 最新设置的 renderer 启动色，
   修复队列重入导致的启动等待和重开时主题回退。
5. 欢迎页的布局归 Shell，自有布局不再 import 社区样式/AdvancedFrame；控件和主题仍复用官方，资源组件仍复用插件。
6. 默认 setup 固定来源并调用插件自己的 setup/build，build 验证主进程/引导页来源，start 校验 runtime 清单。
   `upstream.lock.json` 仅保留历史用途。旧原生测试 flags 被拒绝，避免误用真实用户数据。

## 已运行的验证

- Shell `yarn run check`：官方构建、**105 项现行测试**与项目文件保护检查全部通过。
- Project `yarn run check`：类型检查、**307 项测试**与构建全部通过。
- 官方完整 payload 重新构建、官方原生/Host/Office 检查及搬移检查通过；清单重新校验通过。
- `yarn smoke:official-shell` 从正式 main 启动，验证：
  - 欢迎页和原生菜单共用创建窗口，草稿保留；真正通过创建服务生成项目并打开主窗口。
  - 引导页中英文、明暗、420px 窄布局、底部操作可见、键盘分隔线与取消。
  - 两个官方 Host/Session；两个 Project 页面完成渲染、项目 snapshot 接口可用。
  - API Key 实际为 false；官方快捷键 IPC 为 ready；设备信息是官方返回值。
  - A 的请求不能携带 Cookie 访问 B；原生关闭 A 后 B 可用，A 重开/重启复用 Session 并更换 Host。
  - 多窗口主题即时同步，重开继承；旧 Stable 测试副本被拒绝且原字节未变。
  - 关闭后 IPC owner 为 0、协议处理器释放；本轮 Electron/Host 正常退出，Renderer 错误列表为空。

105 项是迁移后的现行测试集合。12 份社区专用测试改为 `*.legacy.mjs` 原样保存，不计入通过数量；
它们要求的 HostRpc、Profile/Recovery、窗口材质字段或旧打包路径已经退休，未通过恢复社区依赖来满足旧断言。

页面证据直接从已知 WebContents 捕获并结合实时 DOM 检查，不以桌面坐标判断前台窗口或系统材质。
未据此宣称原生系统合成层的视觉验收完成。全部运行目录位于 TEMP；任务只收录下列结论证据：

- [机器结果](official-shell-main/result.json)
- [欢迎页](official-shell-main/welcome.png)
- [官方窗口中的 Project 页面与深色主题](official-shell-main/beta-dark.png)

## 剩余关卡

- **主窗口功能验收**：活跃/计划任务的关闭确认、快捷键编辑/物理按键、真实登录后的账号页面、浏览器和麦克风、
  `dsh://open` 操作系统入口；当前已接入 helper 不代表这些完整交互已通过。
- **插件行为**：Tasks/Resources/Memory/skills/MCP 的写入、调用、会话与工作区替换继续按职责验收。
- **真实数据迁移**：本阶段仅拒绝接管旧 Home，尚未迁移 Stable 会话、设置、凭据与回退。真实用户数据未修改。
- **发行闭包**：消除 Project 的开发路径与完整退休历史适配；CI、签名/打包、更新、自有应用身份、原位替换与回退。
  `package:mac`/`package:win` 目前明确停止，不会落回社区打包流程。
- **平台**：Windows x64、macOS Intel/Universal 均未通过此阶段原生验收。

当前任务保持 active；不能将本阶段结果标成可发布或正式替换 Stable。
