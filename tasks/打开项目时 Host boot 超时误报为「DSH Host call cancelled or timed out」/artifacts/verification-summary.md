# 验证摘要：Host boot 超时预算放宽

日期：2026-09-22
改动仓库：`resources/dsh-project-desktop`（自有壳，未改固定官方源码）

## 环境

| 项 | 值 |
| --- | --- |
| 平台 | macOS arm64（Apple Silicon，**未测 Windows**） |
| Node | v22.19.0（nvm） |
| Yarn | 4.18.0（packageManager 经 corepack 解析） |
| Desktop（固定） | 2.0.11 |
| Harness（固定） | 0.1.5-rc.2 |

## 改动

`src/desktop-adapter/index.mjs`：

- 新增 `HOST_BOOT_TIMEOUT_MS = 300_000`，作为 `rpc.call('boot', …, undefined, HOST_BOOT_TIMEOUT_MS)` 的第四个参数（原为省略，落到 HostRpc 默认 30 000ms）。
- 新增 `HOST_READY_TIMEOUT_MS = 120_000`，替换等待 `{ready:true}` 的 `AbortSignal.timeout(30000)` 字面量。
- `new HostRpc(…, 30000)` 控制调用默认值、`rpc.call('stop', [], AbortSignal.timeout(5000))`、`project:theme:*` 调用均未改动。

新增 `tests/host-boot-timeout.test.mjs`：按源码文本固定上述两个预算与三个未改动点。

## 命令与结果

| 命令 | 结果 | 证据文件 |
| --- | --- | --- |
| `node --test tests/host-boot-timeout.test.mjs` | 3/3 pass，EXIT=0 | 见下方摘录 |
| `yarn run check` | EXIT=0；主测试 93/93、recovery 7/7、safe-mode 1/1；smoke:host 14 项检查全通过 | `yarn-check.log` |
| `node .runtime/hostrpc-timeout-probe.mjs` | 第四参数按 150ms 生效，reject 文案 `"DSH Host call cancelled or timed out"` | `hostrpc-timeout-probe.txt` |

新测试输出摘录：

```
# tests 3
# pass 3
# fail 0
```

行为探针输出：

```
RESULT=rejected elapsedMs=152 message="DSH Host call cancelled or timed out"
```

探针的 `elapsedMs=152` 对应传入的 150ms 预算，证明 `HostRpc.call` 的第四个位置参数确实是 `timeoutMs`，且超时 reject 的文案正是用户截图中的那一句——错误来源闭环。

## 断言有效性（反向校验）

对「回退后的源码文本」执行测试内的三条正则，均被拒绝：

```
boot assertion rejects the old 3-arg call: true
ready assertion rejects the old literal: true
control assertion rejects a widened default: true
```

## 证据边界（未覆盖）

- `smoke:host` 报告 `"nativeWindowsTested": false`；本机为 macOS arm64，**不能据此声称 Windows 通过**。
- 原生视觉验收（Windows 上首次打开项目不再弹恢复助手）**未执行**，属 `not-run`。
- `yarn check` 运行时工作区存在并行会话对 `scripts/native-resource-state-checks.mjs` 的未提交改动；该文件不参与 `check` 链路（它服务 `smoke:resources`），不影响本次结果。
- 本次只放宽预算，**未**改变「依赖物化仍在 boot 关键路径内」与「超时后 close() 会 kill Host、中断 pnpm」这两件事；慢启动只是不再被误报为失败。
