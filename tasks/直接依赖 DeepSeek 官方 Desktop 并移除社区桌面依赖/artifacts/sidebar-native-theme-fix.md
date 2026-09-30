# 深色侧栏发灰：原生主题同步修复

## 结论

用户在白条修复后发现整块深色侧栏仍发灰。实时 DOM 已使用官方深色侧栏样式，但 Electron `nativeTheme.themeSource` 仍为 `system`，`shouldUseDarkColors=false`，系统当前为浅色；深色半透明涂层因此叠在浅色原生 vibrancy 上。

固定官方 `ui-theme/ThemeRuntime.setTheme` 先发布 DOM 主题，同时通过 `ConfigForm` 异步保存。Shell 原来只读一次 `settings/describe`，当读到旧值时就丢弃唯一一次 `native-theme-set` 通知，因此用户界面变暗后原生材质与应用共享偏好没有同步。

## 修复

Shell 提交 `0fb78c2`：

- 在最多 10 秒内等待官方保存值与通知一致，再应用 SharedTheme/nativeTheme。沿用官方设置与窗口材质。
- 新通知取消过时读取及等待；项目关闭取消在途主题同步。读取超时/失败不会写入共享偏好。
- 继续校验启动临时主题，避免重开窗口把全局选择覆盖。
- 官方源码、侧栏背景 CSS 和用户系统外观设置均未修改。

## 验证

- Shell `yarn run check` 通过：118/118 测试、构建和项目文件检查。新增异步保存、过时通知、关闭取消、未保存超时四个回归测试。
- 插件 `yarn run check` 通过：类型检查、307/307 测试、构建。
- macOS arm64 官方 0.2.0-rc.2 真窗口：先由 AX 证明当前“Sidebar 验证”窗口，从官方设置选择深色，Escape 关闭设置。原生截图侧栏恢复深色玻璃；Inspector 读到 nativeTheme=dark、nativeDark=true，另一个项目的 DOM 深色且媒体查询也为 true，共享文件记录 dark。
- 扩展正式 `smoke:official-shell`：双项目深色/浅色/跟随系统与 nativeTheme 一致；关闭重开、重启、另一个项目存活、最终资源释放通过，Renderer errors=[]。
- 原生探针和 userData 全部位于系统 TEMP；结果摘要见同目录 `sidebar-native-theme-result.json`。未执行 Windows/macOS Intel 材质验收。

开发壳已重启加载本次修复，保留原有开发窗口供用户验证。未推送、未发布。

## 验收补充

上次白条验收确认的是装饰渐变消失，未核对 nativeTheme 与 Renderer 明暗是否一致，因此漏掉本问题。以后玻璃材质主题验收同时核对实际前台窗口、DOM 主题、原生 shouldUseDarkColors 与共享持久化值。
