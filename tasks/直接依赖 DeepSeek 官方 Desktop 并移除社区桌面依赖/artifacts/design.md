# 直接接入官方 Desktop 的迁移方案（草案）

> 2026-09-30 主进程阶段更新：正式 Shell 及默认 setup/build/start/check 已切到官方 0.2.0-rc.2，
> 双项目生命周期和真实引导页检查通过。详见 [Shell 主进程切换报告](shell-main-switch.md)。
> 下方此前的“正式 main 尚未接入”属于历史阶段；安装包、CI、数据迁移与完整功能验收仍未完成。

日期：2026-09-28；2026-09-29 更新官方候选基线至 rc.2。状态：阶段 1 官方 Host 与临时双 Electron 窗口实验通过，尚未修改 Stable 应用实现。问题清单见 [迁移问题点](issues.md)。

## 目标与边界

### 2026-09-30 用户明确的职责边界

| 所属层 | 负责内容 |
| --- | --- |
| 我们的 Shell | 多窗口、欢迎页、创建/打开/切换项目、应用菜单；打开项目时承载官方主界面，并提供必要的逐项目 Host、数据与 Session 隔离 |
| 我们的 Project 插件 | 官方主窗口内的项目资源、任务、记忆、Skills、MCP 等页面，以及工作区替换 |
| DeepSeek 官方 Desktop/Harness | 官方主界面和聊天、模型、设置、工具执行等官方能力，直接复用固定官方源码与包 |

Anywhere Labs `dsh-desktop` 及其私有模块全部退出目标依赖图。旧模块清单只用于定位要删除的调用，不能成为必须兼容、逐项移植或保留社区运行回退路径的需求。社区独有的 Profile 选择/创建、恢复助手等界面不作为本轮主进程切换的前置条件；按上述职责完成“壳打开项目 → 官方主界面 → Project 插件”。正式替换前仍须处理用户数据迁移与回退，保留数据不等于保留社区运行实现。

下一版直接替换现有 `dsh-project-desktop` Stable 安装，继续使用原应用身份、用户数据目录、项目文件和发布入口。截至本方案形成时，**已发布基线是壳 `0.1.11`、社区 Desktop `2.0.15`、官方 Harness `0.1.7-rc.2`**（见 [已完成的升级任务](../../Desktop%202.0.15%20升级迁移与%200.1.11%20发布/task.md)）；本地 `resources/dsh-project-desktop` 检出仍停在旧版，不能以该工作树的锁文件代表已发布基线。运行、构建、测试、打包及 CI 的 Desktop/Harness 来源统一为 `deepseek-ai/deepseek-harness` 的一个完整提交，其中 Desktop 源码取自 `apps/desktop`。配套 `dsh-plugin-project` 也不得再从 Anywhere Labs 的 `dsh-desktop` 获取源码、依赖缓存或兼容信息。

“直接依赖官方”在这里指固定官方 Git 提交、校验源码树、构建官方模块与官方发布包。官方 `apps/desktop/package.json` 标记为 `private: true`，不能把 `@deepseek-ai/dsh-desktop` 当成公开 npm 库直接安装。2026-09-29 核实官方当前最新公开版是 [`dsh-v0.2.0-rc.2`](https://github.com/deepseek-ai/deepseek-harness/releases/tag/dsh-v0.2.0-rc.2)，固定提交 `639ed015397290b3745d163aafe02ffee4aa3f84`；根包、`apps/desktop` 和 `apps/desktop-host` 均为 `0.2.0-rc.2`。候选 `apps/desktop` tree 是 `12703a7e1aecef2fa5ba105058e96b5769329b4d`，仓库锁文件 blob 是 `6c7ce04c19349c2d5060f15a11eef5b642da0f50`。该版仍是 RC，先做官方构建、插件兼容和数据迁移验证，不跟随浮动 `master`。

保留现有独立壳，不复制官方 `main.ts` 后长期维护分叉。现有 [开发约束](../../../resources/dsh-project-desktop/AGENTS.md)要求单一 Electron 主进程管理项目级窗口、Host、DSH Home、Profile 和 Chromium 分区；此约束继续成立。项目内 Tasks、Resources、Memory、skills、MCP 由配套 Project 插件负责。

## 方案选择

| 路径 | 结果 | 判断 |
| --- | --- | --- |
| 以官方 `apps/desktop` 应用源码为基础直接改成多项目版 | 需要持续合并官方 `main.ts` 的应用级改动 | 不符合独立壳约束，维护面过大 |
| 改接 Anywhere Labs Next 再叠加项目功能 | 能借用现成适配，但运行/构建仍依赖社区 Desktop | 不符合本次目标 |
| 保留我们的应用层，固定并复用官方 Desktop 源码和官方 DSH 包 | 官方升级影响集中在适配层，项目所有权继续由壳控制 | **采用** |

## 目标结构

```text
现有项目欢迎页 / 项目文件 / ProjectWorkspace / 更新入口
                         │
             我们的项目级 Electron 控制器
                ├─ 项目 A：窗口 + Session + Host + DSH Home + Profile
                └─ 项目 B：窗口 + Session + Host + DSH Home + Profile
                         │
         官方 apps/desktop 的可复用源码与安全契约
                         │
       官方 Web 前端 + 官方 Harness runProfile/WebServer
                         │
                  dsh-plugin-project
```

主进程仍由我们拥有，沿用 [`ProjectWorkspace`](../../../resources/dsh-project-desktop/src/app/project-workspace.mjs) 对每个项目的开关、重启和恢复进行串行协调。每个项目创建自己的 Host、随机 loopback 端口、认证凭据、持久化分区与 `dsh-app://app` 协议处理器；仅该项目的主 Frame 可获得对应 Host 的原生能力。具体可复用的官方模块以源码核查与原生实验为准，优先考察 `host-process.ts`、`backend-controller.ts`、`web-document.ts`、preload、平台能力和官方 Web 前端。官方 `main.ts` 目前围绕一个 `mainWindow` 和一个 `profiles/desktop`，不能直接作为多项目主进程。

Host 使用官方 `@deepseek-ai/dsh/profile-boot` 的 `runProfile` 和真实 WebServer。Project 插件已适配固定官方 `0.2.0-rc.2`，继续验证独立的安装、构建和运行闭包。欢迎页管理项目列表和创建；项目窗口承载完整官方 Web 前端，并加载 Project 插件替换工作区。按职责验证壳的项目流程、插件页面和官方原有能力；不以社区私有模块的功能清单重建另一套 Desktop。

## 数据与发行策略

这是**原位替换**：正式版沿用现有 app ID、产品名、单实例身份、`dsh-project-desktop` 用户数据根目录及 `.agent-project` 项目格式。开发和候选版只能在数据副本中验证；正式首次启动在打开任何项目 Host 前执行预检与迁移。

迁移器先锁定项目状态，记录源版本和可恢复日志，备份该项目的 `dsh` Home、Profile/选择状态与壳设置，在副本中完成官方新格式的 Profile/插件调整和校验，成功后再切换。失败时保持旧数据可恢复，停止该项目启动并显示具体原因；其他项目继续可用。项目根目录、Memory 和 Resources 不参与自动重写。先用真实旧版项目副本证明登录状态、会话、设置、第三方插件及 Project 插件数据的行为，再决定哪些状态需要显式迁移。回退需要旧安装包与迁移前备份配对验证，不能假设旧版能读新格式。

候选版内部可称 Next，但现有更新清单只接受 `stable` 通道和 `x.y.z` 版本。正式替换版应在全部验收通过后以新的稳定版本发布，并由现有 Stable 更新入口发现；预发布构建不进入自动更新清单。发布前保持旧 Stable 安装包及数据恢复方案可用。

## 实施阶段与关口

1. **官方依赖可行性实验。** 固定官方提交及源码树；在 macOS/Windows CI 使用官方仓库自己的依赖锁安装并构建 `apps/desktop` 和 Web 前端。证明一个临时项目可用官方 Host、协议、前端完整启动，且构建闭包中没有社区 Desktop。此关口失败时先解决构建来源，不迁移业务代码。
2. **Shell 主进程切换。** 保留自有欢迎页、创建/打开/切换项目、多窗口与菜单逻辑，使用官方 Host、主界面、preload 与协议，接入 Project 插件；删除当前路径中的社区导入和社区启动分支。复用应用级 ProjectWorkspace 验证双项目启动、关闭、重开与故障隔离。社区独有界面及旧私有 RPC 的复刻不属于此步骤。
3. **Project 插件兼容。** 在配套仓库删除社区 Desktop 的开发依赖路径，核对现有 `0.1.7-rc.2` peer 与新官方构建闭包；若官方提交改变包契约则精确适配。验证 Tasks、Resources、Memory、skills、MCP、项目市场、模型设置、第三方插件装卸与 Profile 切换。任何功能只在完整行为验收后标为完成。
4. **旧数据原位迁移。** 制作旧版真实项目样本与迁移矩阵；实现备份、迁移日志、失败恢复和回退演练。逐项验证默认及额外 Profile、设置、会话、插件、项目资源，确认项目根目录不被意外修改。
5. **打包与正式替换。** 重写 setup/源码校验/构建/打包/CI，使之仅拉取官方仓库与配套插件；保留应用身份与更新清单契约。完成 macOS Universal、Windows x64 安装和真实图形验收，再开放 Stable 更新清单。

每一阶段以可复现命令、固定提交、测试结果和问题清单状态收口。实施时更新 `AGENTS.md`、架构、开发、打包及第三方来源说明，使“只支持旧 Stable 锁”的旧约束与新基线一致。

## 最终验收

- 源码锁、构建输入、依赖图、安装包和 CI 均可追溯到同一个官方 Harness/Desktop 提交与配套 Project 插件提交；不再引用 Anywhere Labs Desktop 仓库或其包/缓存。
- 旧版用户通过现有安装与更新路径升级；项目列表和项目文件保持；迁移失败时旧数据可恢复。
- 两个项目同时运行且各自拥有 Host、Profile、浏览器分区、认证及恢复生命周期；一个项目的故障不影响另一个。
- 壳的欢迎、创建/打开/切换项目、多窗口和应用菜单，官方主界面原有能力，以及 Project 插件页面和工作区替换，在真实 Electron 窗口验收；macOS 与 Windows 安装包各自验收。社区独有实现不构成功能等价基线。
- 文档、许可证及第三方来源信息与实际产物一致。历史发布说明可保留历史事实，但不能成为构建或运行依赖。

## 当前进度

阶段 1 已固定官方来源并通过源码构建、真实 Host、双 Host 隔离及临时双 Electron 窗口实验；Project 插件已通过官方 `0.2.0-rc.2` 的类型检查、测试和构建，并在临时双窗口显示两个独立空项目的基础界面。Shell 已提取 `dsh-app` Session 与 IPC 所属关系适配器，建立可校验的官方开发输入映射，并通过上游打包工具生成和搬移 287 个第一方核心 tarball。2026-09-30 已完成 macOS arm64 未签名开发运行目录，加入固定外部依赖、Electron、Web/preload、原生资源与 primary runtime；搬移前后官方原生/Host/Office smoke 和 payload 双窗口加 Project 插件验证通过。探针控制脚本仍读固定官方源码 helper，插件仍为本地开发链接；正式 Shell、插件发行依赖、其他平台和签名打包待完成。可复现命令、截图与限制见 [可行性实验](phase1-feasibility.md)。现行 Stable 的运行、setup、打包和 CI 仍依赖社区 Desktop，不能据此宣称替换完成。下一步将官方运行目录接入正式主进程的项目生命周期，再验证双项目窗口和 Project 插件行为；旧数据及发布验收按上列关口继续。
