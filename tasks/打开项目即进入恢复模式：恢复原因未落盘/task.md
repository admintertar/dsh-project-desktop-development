---
schemaVersion: 3
directory: 打开项目即进入恢复模式：恢复原因未落盘
id: task-de10cf55-5022-4204-8db7-888500c1d1ed
title: 打开项目即进入恢复模式：恢复原因未落盘
objective: 定位「打开项目时自动进入恢复模式」的证据链，并让壳把每次进入恢复的原因（来源/是否手动/只读降级/失败阶段与详情/会话阶段/manifest）持久化到项目状态目录，使该原因在恢复窗口关闭后仍可从日志读到；本次不再依赖官方恢复助手窗口的 query 参数。改动落在 resources/dsh-project-desktop（壳），并通过 yarn check。
status: completed
createdAt: 2026-09-22T12:41:10.520Z
updatedAt: 2026-09-22T12:47:59.666Z
artifacts: []
archived: false
phase: validation
brief:
  currentBehavior: 壳只在两种自动路径下打开官方恢复助手：workspace.restore() 后 workspace.failures() 里残留的 failed/recovering/opening 阶段，或 restore 打开在 Host fork 之前失败（main.mjs showProfileSurface）。恢复原因只作为 base64url 的窗口 query 参数交给官方 recovery.html，窗口一关即消失；Host 日志要等 Host 被 fork 之后才可能有内容（2026-09-22 那次失败在 fork 之前，因此当天没有 dsh-2026-09-22.log），壳自身又没有主进程日志。本任务已把该原因追加到项目状态目录的 recovery-events.jsonl（含来源、requested、只读降级、阶段、详情、会话阶段、manifest 路径），窗口关闭后仍可从日志读到。
  scope: 新增 src/app/recovery-journal.mjs（有界追加 <state>/recovery-events.jsonl、可读可测、写失败不抛）；在 main.mjs 的 showProfileSurface 统一记录，并给全部进入恢复的调用点标注来源；补 tests/recovery-journal.test.mjs；在 docs/architecture.md 记录该新增。
  constraints:
    - 不修改官方恢复助手实现；原因仍按官方契约传给窗口
    - 落盘失败只 console.error 一行，绝不改变或阻塞恢复行为
    - 不改 upstream.lock.json、不 touch .upstream/、不 push
  outOfScope:
    - 让已安装的 0.1.3 立即生效（需要重新 build + 打包安装）
    - 启动时自动清除陈旧 failed 阶段（属行为变更，需单独确认）
    - 把该文件并入官方诊断包（官方导出器只收 dsh-<日期>.log 命名的日志）
  acceptanceCriteria:
    - id: ac1
      text: 进入恢复时把原因追加到 <state>/recovery-events.jsonl，窗口关闭后仍可读回（含来源、requested、只读降级、failureStage、failureDetail、会话阶段、manifestPath）
      required: true
      version: 1
    - id: ac2
      text: 日志文件有界（字节数触发压缩 + 最多保留最近 N 条），写入失败不抛异常、不影响恢复
      required: true
      version: 1
    - id: ac3
      text: yarn check 全绿（EXIT=0）
      required: true
      version: 1
    - id: ac4
      text: 文档记录该新增（docs/architecture.md 恢复段落）
      required: true
      version: 1
handoff:
  nextSteps:
    - 如需在实机复现时读到该日志：cd resources/dsh-project-desktop && yarn package:win 后安装（当前安装版 0.1.3 不含本改动）
    - 若要保留本次改动：本地提交这 4 个文件（未 push）；提交前确认 .upstream/project 按 pin 重导、.cache 依赖缓存重建是期望的工作区状态
    - 可选后续（需明确授权）：启动恢复时先做一次真实打开自愈陈旧 failed 阶段，避免又出现『打开项目即进恢复模式、但项目其实健康』
  readBefore:
    - file-journal
    - file-architecture
  verifyBefore:
    - yarn check 全绿（EXIT=0）
    - yarn verify:upstream 通过：.upstream/project 树必须等于 lock pin 的 d1040404
references:
  - id: file-journal
    label: 恢复原因日志模块
    type: file
    path: resources/dsh-project-desktop/src/app/recovery-journal.mjs
  - id: file-architecture
    label: 架构文档恢复段落
    type: file
    path: resources/dsh-project-desktop/docs/architecture.md
entries:
  - id: ev-evidence
    kind: progress
    content: "证据链（本次恢复原因在旧代码下不可得）：① <state>\\diagnostics\\diagnostics-1790079899578-….zip 于 2026-09-22 20:24:59 自动生成，只有官方恢复助手会在开窗后自动 startDiagnosticExport，证明当时确实弹了恢复面板；② 该包的 logs 只有 09-21 的两个文件，说明失败发生在 Host fork 之前；③ 进程 14772（node.mojom.NodeService 工具进程）创建于 20:25:09，说明 20:25:09 才有第一次 Host fork；④ 项目分区 Local Storage leveldb LOG 20:24:58 首次打开（默认 session 的恢复窗口渲染）；⑤ 20:25:40 写出 slot-1 reason=healthy-startup，项目本身健康。手动入口不可能：唯一的『项目恢复…』菜单项 enabled: Boolean(current)，托盘无该命令，快捷方式无参数。"
    basis: observation
    createdAt: 2026-09-22T12:41:10.520Z
  - id: ev-decision
    kind: decision
    content: 落盘位置选项目状态目录（<userData>/projects/<hash>/recovery-events.jsonl）而不是 logs/ 目录：官方 LogFileSink 以 dsh-<日期>(.error)?(.N)?.log 命名并独占轮转/清理，官方诊断导出器也只收该命名的文件，写进 logs/ 既不进诊断包还可能干扰计数；项目状态目录与该项目 Host 日志相邻，排查时在同一处。
    basis: agent-proposal
    createdAt: 2026-09-22T12:41:10.520Z
  - id: ev-test
    kind: verification
    content: node --test tests/recovery-journal.test.mjs：4/4 通过（round-trip、有界压缩保留最新、目标不可写时返回 undefined 且不抛、损坏行跳过）。
    basis: observation
    verification:
      criterionId: ac1
      criterionVersion: 1
      method: node --test tests/recovery-journal.test.mjs
      result: passed
      coverage: 覆盖 ac1 的写入+读回与 ac2 的有界/容错语义；未覆盖 main.mjs 与官方恢复窗口的端到端联动
    createdAt: 2026-09-22T12:41:10.520Z
  - id: p-repair
    kind: progress
    content: 为让 check 能跑，工作区做了两处修复（与本改动无关，但改动前 check 完全跑不起来）：① .upstream/project 快照内容等于插件提交 6d116e1 的树（bf4ee3bb），而 lock pin 是 7fa9925（d1040404）→ verify:upstream 与 build 第一步就失败；按 AGENTS.md 流程删除后由 pin 重新 git archive 导出，verify:upstream 转为通过。② .cache/runtime/dsh-plugin-desktop 与 .cache/runtime/dsh-project-shell 为空 → build 报 'Run yarn run setup first'；按 README 的 setup 命令（--desktop-source ../dsh-desktop-source --harness-source ../deepseek-harness-source --project-source ../dsh-plugin-project --desktop-dependencies ../dsh-desktop-source/dsh-plugin-desktop/node_modules --project-dependencies ../dsh-plugin-project/node_modules）重建依赖缓存（620 MB / 54006 文件），SETUP_EXIT=0。
    basis: observation
    createdAt: 2026-09-22T12:47:59.666Z
  - id: v-ac1
    kind: verification
    content: ac1 通过：tests/recovery-journal.test.mjs 5/5（含写入即落盘、读回字段完整）；同文件新增源码守卫断言，要求 main.mjs 在 createProjectNativeWindow 之前调用 recordRecoveryEvent，且 startup-restore/open/restart/runtime/safe-mode/safe-mode-exit 六个自动入口都标注 source。
    verification:
      criterionId: ac1
      criterionVersion: 1
      method: node --test tests/recovery-journal.test.mjs（5 通过 0 失败）
      result: passed
      coverage: 覆盖 ①journal 写入/读回 ②main.mjs 接线顺序与来源标注；未覆盖 Electron 原生窗口端到端（smoke:native/smoke:profiles 未跑）
    createdAt: 2026-09-22T12:47:59.666Z
  - id: v-ac2
    kind: verification
    content: ac2 通过：有界语义用 maxBytes 触发压缩 + maxRecords 上限的用例断言（保留最新、文件不超过上限+一条）；目标路径不可写（父为普通文件）时 recordRecoveryEvent 返回 undefined 且不抛，readRecoveryEvents 返回空数组，原文件未被修改；损坏行被跳过。
    verification:
      criterionId: ac2
      criterionVersion: 1
      method: node --test tests/recovery-journal.test.mjs（同文件 5 用例）
      result: passed
      coverage: 覆盖字节上限/记录上限/写入失败/损坏行四种情况
    createdAt: 2026-09-22T12:47:59.666Z
  - id: v-ac3
    kind: verification
    content: "ac3 通过：cd resources/dsh-project-desktop && yarn check，2026-09-22 20:46:38→20:47:21（43 秒）EXIT=0：单测 98/98、test:recovery 7/7、test:safe-mode 1/1、check-project-files 与 smoke:host 均通过（verify:upstream 打印 'Official stable source intact: Desktop 2.0.11, DSH 0.1.5-rc.2'）。"
    verification:
      criterionId: ac3
      criterionVersion: 1
      method: yarn check（日志落盘 $TEMP\dsh-shell-check4.log，CHECK_EXIT=0）
      result: passed
      coverage: 整链包含构建、全部单测、recovery/safe-mode 专项与双 Host 冒烟
    createdAt: 2026-09-22T12:47:59.666Z
  - id: v-ac4
    kind: verification
    content: ac4 通过：docs/architecture.md 恢复段落补充 recovery-events.jsonl 的落盘位置、字段、有界策略、失败不阻塞恢复、以及不进入官方诊断包（导出器只收 dsh-<日期>.log）的原因。
    verification:
      criterionId: ac4
      criterionVersion: 1
      method: docs/architecture.md 文本核对（diff 1 行）
      result: passed
      coverage: 文档与实现一致（字段名、来源取值、文件名）
    createdAt: 2026-09-22T12:47:59.666Z
  - id: c-done
    kind: completion
    content: 恢复原因已落盘并验证完成。壳在打开官方恢复助手前，把 source/requested/readOnly/failureStage/detail/phase/manifestPath 追加到 <项目状态目录>/recovery-events.jsonl（新增 src/app/recovery-journal.mjs：有界、损坏行容忍、写失败只记一行错误不影响恢复）；main.mjs 的全部自动入口标注来源并在窗口创建前落盘；docs/architecture.md 记录新增。改动未提交（4 文件：src/app/main.mjs 与 docs/architecture.md 修改，src/app/recovery-journal.mjs 与 tests/recovery-journal.test.mjs 新增），未 push。
    verificationEntryIds:
      - v-ac1
      - v-ac2
      - v-ac3
      - v-ac4
    createdAt: 2026-09-22T12:47:59.666Z
operations:
  5482ae222c8551122a97cde3f4d29ab9ccd22bda4f1090d09fa6ed97ce6cfda4:
    fingerprint: 0d3253c777d545f51aab43e305c62a786257a2e19be1a9b92550bd1748efe0fa
    kind: create
    at: 2026-09-22T12:41:10.520Z
    entryIds:
      - ev-evidence
      - ev-decision
      - ev-test
  4de9a7371e35c5bcbbadccff6368ed11edf055096d9b99ebd2986c86be247f9d:
    fingerprint: bf5ee4756d7fe84683aedd9f6981d6c1dd5859db033f1cd2da0209a2bbd13f96
    kind: update
    at: 2026-09-22T12:47:59.666Z
    entryIds:
      - p-repair
      - v-ac1
      - v-ac2
      - v-ac3
      - v-ac4
      - c-done
criterionVersions:
  ac1: 1
  ac2: 1
  ac3: 1
  ac4: 1
---

恢复原因已落盘并验证：壳在打开官方恢复助手之前把 source/requested/readOnly/failureStage/detail/phase/manifestPath 追加到 <项目状态目录>/recovery-events.jsonl（新增 src/app/recovery-journal.mjs：有界、损坏行容忍、写失败只记一行错误且不影响恢复），六个自动入口（startup-restore/open/restart/runtime/safe-mode/safe-mode-exit）都标注来源，docs/architecture.md 记录该契约。验证：yarn check EXIT=0（43 秒；单测 98/98、test:recovery 7/7、test:safe-mode 1/1、check-project-files 与 smoke:host 通过），新增 5 个单测内含 main.mjs 接线源码守卫。为让 check 能运行，工作区另做两处修复：.upstream/project 快照原停留在插件 6d116e1（bf4ee3bb）与 lock pin 不符，已按 pin 7fa9925 重新导出；.cache/runtime 下的依赖缓存原为空，已按 README 的 setup 参数重建（620 MB / 54006 文件）。限制：改动尚未提交（4 文件，未 push）；安装版 0.1.3 不含该日志，需重新打包安装后才能在实机读到；未做 Electron 原生端到端（smoke:native / smoke:profiles 未跑），main.mjs 的恢复窗口联动目前只有源码级守卫与 node --check。
