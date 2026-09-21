# dsh-project-desktop-development

[English](README.en.md) · 简体中文

`dsh-project-desktop` 的开发工作区。这里保存项目元数据、任务记录与工作约定，供 DSH 的 Project 能力加载；**产品源码不在此仓库**。

## 目录结构

```text
.
├── AGENT.md                                      # 项目级 Agent 指令入口
├── dsh-project-desktop-development.agent-project # 项目清单：资源与记忆声明
├── memory/working-agreements.md                  # 工作约定与验证流程（会加载进上下文）
├── tasks/<任务名>/task.md                        # v3 任务记录，附件在同目录 artifacts/
├── skills/index.yaml                             # 项目级技能（当前为空）
├── mcp/servers.yaml                              # 项目级 MCP（当前为空）
└── resources/                                    # 关联仓库的检出目录，不纳入版本控制
```

## 关联仓库

产品源码在两个独立仓库中维护；本工作区的 `resources/` 只是它们的检出位置，已由 `.gitignore` 排除，不会随本仓库分发：

- [dsh-project-desktop](https://github.com/admintertar/dsh-project-desktop) — Electron 壳与应用层：项目启动体验、多窗口隔离、恢复与安全模式、更新适配。
- [dsh-plugin-project](https://github.com/admintertar/dsh-plugin-project) — project / resource / task / skill / MCP / memory 插件。

两者基于公开上游构建，上游源码以固定提交只读引用：

- [deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness)（MIT）
- [anywhere-labs/dsh-desktop](https://github.com/anywhere-labs/dsh-desktop)（MIT）

本项目为独立项目，不是 DeepSeek 或 Anywhere Labs 的官方发行版。

## 任务记录

`tasks/<任务名>/task.md` 是独立于会话的工作记录，包含目标、验收标准、证据链与验证结果；附件（截图等）放在同目录 `artifacts/`。记录中的本机路径已隐去。

## 许可

本仓库自有内容保留所有权利，详见 [LICENSE](LICENSE)。公开可读不等于授予使用、修改或再分发许可。
