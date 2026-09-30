# 官方关闭确认接入与验证

日期：2026-09-30。分支：`codex/direct-official-desktop`。

Shell 本地提交：`814fa1a`（接入官方任务关闭确认并完善项目退出清理）；未推送、未发布。

## 实现

固定官方版本仍为 `dsh-v0.2.0-rc.2` / `639ed015397290b3745d163aafe02ffee4aa3f84`。
从只读官方 `apps/desktop/src/quit-confirmation.ts` 编译并直接复用 `DesktopQuitConfirmation`，
没有引入 Anywhere Labs 的对话框、Profile 或恢复模块。

- 关闭窗口、关闭项目、重启项目：只检查该项目的真实 `DesktopHostProcess.inspectQuit()`。
- 退出应用：等待已受理的项目操作，汇总全部 Host 的运行任务与计划提醒，确认前不停止任何项目。
- 空闲项目：沿用官方规则，直接关闭；有任务或检查失败：显示官方原生确认。
- 相同项目的重复动作共用一次决定，不把相反动作排到确认后误操作新 Host；不同项目的弹窗顺序显示。
- 取消保留窗口、Host、会话恢复集合与任务；弹窗异常不会把仍运行的项目标成失败。
- 只适配应用名称及“关闭/重启此项目”的文案。官方按钮顺序、默认键、取消和检查语义保留。
- 关闭前同时等待已进入的元数据请求及单向主题通知，避免 Host 先停止而留下读取错误。
- 撤销所属 Session 的在途 HTTP 转发，复用官方 Request.signal 取消通道；正常关闭的取消返回 410，其他项目的请求继续完成。

## 验证

源码检查：Shell `yarn run check` **114/114**；Project 插件 `yarn run check` **307/307**。
新增检查覆盖取消后继续工作、打开与退出并发、重复动作、失败 Host 与计划提醒汇总、对话框失败及销毁。
完整官方运行目录已重新构建，并通过其原生、Host、Office 及搬移检查。

原生平台：**macOS arm64**。`yarn smoke:official-close` 通过正式 main 启动两个临时项目：

1. Alpha 在真正的 Jobs 服务中注册可取消的后台任务；Beta 显式启用同一固定官方 Schedule 服务并创建一小时后的提醒。
   没有模拟 Host 的检查结果，没有模型调用，默认生产 Profile 不增加测试模块。
2. Alpha 原生窗口关闭取消、重启取消后，两项目的 snapshot 接口仍可用。
3. 确认 Alpha 重启后，Host 地址改变，Beta 保持可访问。
4. Beta 仅显示计划提醒警告；取消关闭后保持运行。
5. 应用退出汇总运行任务与计划提醒；取消后可以再次打开已有项目。
6. 确认关闭 Beta 后，仅移除 Beta 的运行及恢复记录；Alpha 保持运行。
7. 从正式 `before-quit` 入口确认退出，Host 与 IPC owner 全部释放，Alpha 保留在下次恢复集合中。

通过原生应用的无障碍树确认当前警告窗口，并实际查看截图：英文/中文内容完整，浅色/深色正常，
项目窗口为 520×600 时原生弹窗操作可见；Escape 取消和 Enter 确认均实测。
整个交互在临时目录完成，任务只收录[结论 JSON](official-close-result.json)，不收录 token 或 Chromium 缓存。

关闭收尾修正后再运行正式 `yarn smoke:official-shell`：欢迎/创建、空闲双项目、关闭/重开/重启、主题同步与清理全部通过，
退出码为 0，日志不再出现 Host 已关闭导致的 fetch 错误。[最终回归结果](official-close-regression.json)。

## 边界与后续

本轮没有修改 Project 插件或官方源码，没有迁移真实 Stable 数据、推送或发布。
Windows/macOS Intel 原生验收、登录后浏览器/账号/麦克风、完整快捷键交互、`dsh://open`、
插件业务验收、发行依赖闭包、CI/打包/更新与数据迁移回退继续保留在任务中。
本检查覆盖用户发起的关闭/重启/退出；不把它视为操作系统注销或强制终止验收。
