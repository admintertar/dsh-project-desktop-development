# 多窗口共享 DeepSeek 账号：实现与验收

## 结果

按用户确认，仅共享 DeepSeek 登录账号；模型 API Key、第三方授权、Host 认证密钥、Profile、项目会话及 Chromium 分区保持项目独立。

Shell 已本地提交 `4e9bd7e`（分支 `codex/direct-official-desktop`），未推送或发布；本轮未修改 Project 插件，开发构建使用其现有 `90ea335`。官方固定 `0.2.0-rc.2` / `639ed015397290b3745d163aafe02ffee4aa3f84`，官方源码与运行目录未修改。

## 实现

- `shared-account-store.mjs` 在所有 Host 启动前准备 `userData/account/.credentials.yaml`，只收纳官方 `deepseek-account-platform/default` 与 `device` 两条记录。采用官方文件锁、解析器和 0600 原子写入。
- `account-credentials.mjs` 继承官方完整 `LocalCredentialProvider`，仅路由这两条记录；API Key 的环境优先级、引用凭据、其他 records 的存取及官方监听保留。
- 每个项目通过官方账号服务响应共享文件变更，沿用官方 PKCE、授权回调、账号资料、退出确认和撤销逻辑。共享退出同时触发账号任务取消。
- `shared-account-sessions.mjs` 串行协调各窗口的登录和退出。新登录取消其他窗口的旧尝试；退出等待在途提交结束后再次调用官方退出，避免回调晚到导致重新登录。退出弹窗的任务影响汇总所有已打开 Host，查询失败保留未知状态。
- Profile 只在 Host 启动前更新组合：禁用原 credentials provider 并插入自有 provider，保留原配置、注释与 YAML tags。实际官方 patch 算法已验证；其 `name` 字段是断言，不能用于直接替换模块。

## 现有登录迁移

首次仅扫描本壳拥有且来源匹配的官方项目 Home。存在一份已有登录时沿用；存在不同授权记录时明确报冲突，不自行选择。共享存储一经创建即为权威，即便退出后为空也不会从旧项目重新恢复登录。原项目凭据文件保留。

这只覆盖本次官方开发壳的账号迁移，不代表已发布社区 Stable 的完整数据迁移与回退验收。需要回退时必须先停止 Host，再恢复原 Profile 组合；不能让旧壳加载指向新适配器的 Profile。

## 验证

平台：macOS arm64。

| 检查 | 结果与范围 |
| --- | --- |
| Shell `yarn check` | 136 项通过，构建和项目文件检查通过；含 8 项新测试 |
| 官方 provider 实测 | 账号热同步、删除、关闭重开、API Key/Host 密钥隔离、0600 权限通过 |
| 迁移与 Profile 测试 | 单一登录沿用、退出不复活、多授权冲突、官方 patch 实际算法通过 |
| 跨窗口协调测试 | 运行任务聚合、提交与退出排序、官方验证失败不扩散、错误脱敏、关闭等待通过 |
| `smoke:official-account-sharing` | 真实官方 Host/Renderer 与本机 Platform 夹具执行 PKCE、回调及授权交换；一次登录共享 A/B、重启和新开 C，同步退出与 Escape 取消、竞争登录和退出期间回调取消通过 |
| 原生界面 | 原生鼠标点击前定位窗口、检查 DOM 命中；通过官方可见按钮完成临时项目首次引导；中文深色、英文浅色窄窗退出弹窗和 Escape 取消通过 |
| `smoke:official-shell` | 最终代码的欢迎/创建、双项目、关闭/重开/重启、另一窗口存活、主题同步、浏览器隔离和 owner 释放通过，无 Renderer 错误 |
| 用户当前开发壳 | 沿用原 userData 启动 `dsh-project-desktop-development` 与 `Sidebar 验证`；两个官方窗口均为 `credential-stored`、资料 `ready`、同一账号、无首次引导，未要求重新登录 |

账号资料比较只输出状态和相同布尔值，不记录真实身份或凭据。退出与授权竞争测试使用本机夹具；没有退出用户真实账号。最终两张截图已检查，均为可见正式界面，不使用遮罩背后的隐藏控件作为交互证据。

截图与摘要：

- `shared-account-zh-dark.png`：临时项目中文深色界面，底部显示测试账号。
- `shared-account-en-confirm.png`：官方英文浅色窄窗退出确认。
- `shared-account-result.json`：测试、生命周期及已有账号沿用的脱敏结果。

Windows、macOS Intel、签名安装包、平台充值与已发布 Stable 整体迁移不在本轮已验收范围；系统 `dsh://` 关联按用户此前决定暂缓。
