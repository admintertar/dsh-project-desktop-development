# 官方侧栏更新入口接入与验收

## 结论

Shell 已本地提交 `a9fae5b`，原样复用固定 DeepSeek 官方 `0.2.0-rc.2` 的侧栏底部更新入口、更新状态和确认弹窗；更新源仍为本项目的 GitHub Release。未 push 或发布。

官方 Web 本来就包含 `DesktopUpdateIndicator` / `DesktopUpdateBadge`，原壳的 updates-status 固定返回 idle 才导致入口隐藏。现在接入真实应用级 status/open/subscribe；新版本、百分比、校验、准备安装和失败重试均由官方组件渲染。空闲状态按官方规则隐藏，可由菜单/托盘手动检查。

## 复用与自有适配

- 从固定官方源码构建 `DesktopUpdateCoordinator`、`DesktopUpdateSchedule`、`DesktopUpdateDialog`、`DesktopUpdateOverlays`、presentation 和原始 preload/renderer assets，全部进入自有 dist 与来源清单。官方源码与 runtime 未修改，没有社区 Desktop 依赖。
- 官方协调器负责完整版本检查与下载事件状态；`ProjectReleaseUpdater` 仅适配自己的 update.json、固定版本安装包与下载流。下载前复核确认时的版本/commit/资产；包大小和 SHA-256 通过后才原子落盘，安装交接前再次校验文件。
- 全应用只有一个更新操作/弹窗，所有项目看到同一进度。更新的长操作不占住项目退出所需的 IPC；关闭弹窗所属项目会主动取消弹窗，避免官方单窗口假设在多窗口壳里留下等待。
- 官方弹窗使用自己的 default Session 和 shell 文档白名单，不接入项目 Host；其他窗口无法响应其确认。快捷键沿用官方 overlay input 状态。
- 自有发布格式保留：macOS 确认后打开 DMG，文案明确手动拖入应用程序；Windows 先确认/关闭所有项目，再交接 NSIS 安装程序，启动失败恢复项目。未更换成官方原版安装包。

## 验证范围

平台：macOS arm64。Shell `yarn check` 140 项通过，含新增的完整性、篡改、元数据边界与失败清理测试。最终 `smoke:official-shell` 的创建、双项目、关闭/重开/重启、主题、浏览器与 owner 清理回归通过，无 Renderer 错误。

`smoke:official-updates` 使用真实 Electron、官方协调器、预加载、Web 控件和更新弹窗，仅把发行网络替换为临时夹具，并截获最终安装交接：

- 最新版本提示、网络失败、双窗口状态同步。
- 手动下载确认的 Escape 取消不启动下载；两窗口同时操作只显示同一弹窗。
- 关闭弹窗所属项目后正常结束，重开读取当前更新状态，其他项目存活。
- 实际点击侧栏按钮、下载失败后重试、两窗口百分比同步。
- 安装确认取消后保留 ready；重启项目读取同一 ready；再次明确确认才交接已校验的安装包。
- 中文深色、英文浅色、窄窗口更新入口与无横向溢出。命中测试使用实际可见 DOM 坐标，再发送原生鼠标/键盘事件。

所有临时安装包只用于本机夹具，未执行或安装。Windows/Intel 以及签名发行包的真实安装交接仍待相应平台验收；本轮不宣称正式发布完成。

## 证据

- `official-update-sidebar-zh.png`：真实中文深色窗口左下角截图裁剪，展示“新版本”的官方按钮。
- `official-update-progress-en.png`：真实英文浅色窗口中同一位置的下载百分比。
- `official-update-sidebar-result.json`：140 项检查、原生更新和生命周期回归摘要。

用户开发壳沿用原 userData 重启，账号与项目状态保留；当前版本若没有更新，底部入口按官方规则隐藏，不伪造新版本状态。

当前开发壳复查：两个项目窗口均保留登录，更新状态均为 idle；通过 Electron 网络访问自己的公开 update.json 返回 HTTP 200，latestVersion 为 0.1.11，与当前壳版本相同。手动检查菜单已存在。没有新版本提示符合官方隐藏规则。
