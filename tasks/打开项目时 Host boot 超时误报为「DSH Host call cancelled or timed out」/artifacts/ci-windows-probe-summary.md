# Windows CI 探针结果（2026-09-22）

Run: [35703286344](https://github.com/admintertar/dsh-project-desktop/actions/runs/35703286344) · commit `1cf636f` · 结论 **success**（两个 job 全部步骤通过）

## 结论一句话

**在干净的 Windows runner 上无法复现 30 秒超时**：源码构建的完整 boot 是 5.5–7.1 秒，最新打包版（0.1.4）打开项目是 **10–12 秒**，两次都正常落在项目窗口而不是恢复助手。但 12 秒已用掉 30 秒预算的 40%，所以放宽超时的改动是必要的兜底。

## 被测环境（关键差异在此）

| 项 | CI 值 | 备注 |
| --- | --- | --- |
| 系统 | Windows Server 2022 `10.0.20348` x64 | |
| CPU / 内存 | 4 vCPU / 16 GB | 核数低于常见开发机 |
| 卷 | C:/D: 均为本地 NTFS | |
| **Defender 实时保护** | **False（关闭）** | 企业用户机器上通常为**开启** |
| **AppData 是否重定向** | **否**（`C:\Users\runneradmin\AppData\Roaming`） | 域账户常被文件夹重定向/漫游 |
| AntivirusEnabled | True | 引擎在，但实时保护未开 |

原始输出见 `ci-windows-io-environment.txt`。

## 源码构建分阶段耗时（ms）

| 阶段 | 仓库内 #1/#2 | 用户数据根 #1/#2 | macOS arm64 对照 |
| --- | --- | --- | --- |
| hostReady（fork + 模块图 + ready） | 175 / 175 | 173 / 174 | 59 / 54 |
| prepareProfile（首次含 pnpm install） | 1799 / 264 | 2180 / 252 | 425 / 77 |
| **boot（完整 startProjectHost）** | **6733 / 5543** | **7065 / 5539** | **2990 / 2535** |
| close | 97 / 95 | 114 / — | 45 / 50 |

要点：

- Windows 比 macOS arm64 慢约 **2.3 倍**，但仍在个位数秒级。
- **仓库内与 `%APPDATA%\Roaming` 无显著差异**（6.7/5.5 对 7.1/5.5），说明干净机器上路径不是变量。
- 首次 `pnpm install` 在 Windows 上约 1.8–2.2 秒（macOS 0.4 秒），同样不构成超时。

完整表格见 `ci-source-build-timing.txt`。

## 打包版打开项目（真实产物 0.1.4）

下载 `DSH-Project-Desktop-0.1.4-win-x64-Portable.zip`（经 update.json 取 URL + sha256 校验），解压直接运行，打开临时项目：

| 运行 | userData | 判定 | 耗时 | lockfile | pendingRecovery |
| --- | --- | --- | --- | --- | --- |
| 默认（Roaming） | `%APPDATA%\dsh-project-desktop` | **project-window** | **12 s** | 已生成 | 0 |
| 隔离（本地目录） | `D:\…\.runtime\packaged\userdata-local` | **project-window** | **10 s** | 已生成 | 0 |

两次的原生窗口标题里都出现了项目名（`probe-roaming` / `probe-local`），**没有**出现 `DSH Desktop Recovery Assistant`。原始判据见 `ci-packaged-probe.txt`。

## 推论

1. **不是代码或依赖在 Windows 上普遍性慢**：干净环境下 10–12 秒完成打开，远低于 30 秒。
2. 因此用户机器上的 30 秒超时是**环境特征**，而不是这个仓库的通用行为。候选（CI 恰好都不具备）：Defender 实时扫描、`AppData` 重定向/漫游同步、网络/虚拟磁盘、公司代理，或并非"慢"而是"卡住"。
3. **放宽超时仍是对的**：干净 CI 已用掉 40% 的预算；真实企业环境再慢 2.5 倍就会撞线，而慢 2.5 倍在开启实时保护 + 漫游目录的机器上很常见。
4. 想在 CI 上逼近用户环境，下一步可做：在同 job 里用 `Set-MpPreference -DisableRealtimeMonitoring $false` 重开实时保护后再跑一次，对比 boot 耗时。这一步尚未执行。
