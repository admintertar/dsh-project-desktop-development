---
schemaVersion: 3
directory: 上次停在会话视图时重启：root slot 注册顺序错误导致壳退出
id: task-e3ecf7fd-c8eb-484c-bc83-ad4ebe34f3be
title: 上次停在会话视图时重启：root slot 注册顺序错误导致壳退出
objective: 记录并定位「项目窗口重启时若上次停留在会话视图，渲染进程报 renderSlot('root') before any 'root' registration (boot order) 并导致壳以退出码 1 结束」的缺陷：给出可复现步骤、对照实验证据、影响面与修复方向，供后续排期实现。
status: active
createdAt: 2026-09-22T14:41:34.994Z
updatedAt: 2026-09-22T14:41:52.811Z
artifacts:
  - type: file
    path: artifacts/startup-broken-restore-session.log
    description: 报错并退出的启动日志：renderSlot('root') before any 'root' registration (boot order) + Network service crashed，进程退出码 1
  - type: file
    path: artifacts/startup-ok-fresh-userdata.log
    description: 对照：全新隔离 userData（无历史视图/会话）同一构建启动正常，无 renderSlot/Uncaught
  - type: file
    path: artifacts/startup-ok-before-session-created.log
    description: 对照：同一 userData 在创建会话之前的一次正常启动
archived: false
phase: investigation
brief:
  currentBehavior: "开发壳（隔离 userData）在项目窗口上次停留在会话视图时重启：渲染进程报 Project renderer: Error/Uncaught Error: renderSlot('root') before any 'root' registration (boot order)，随后 Network service crashed or was terminated，进程以退出码 1 结束，用户看到窗口一闪即退；同一构建在全新 userData 下启动正常。"
  scope: 壳的窗口启动与“上次视图/会话”恢复路径，以及插件 Client 的 root slot 渲染时机；尚未定位到具体文件。
  constraints:
    - 不改动 .upstream 官方源码，官方 stable 快照保持完整
    - 先用对照实验确定触发条件再动代码，避免把无关回归归因到本缺陷
  outOfScope:
    - 本次不修改代码，只记录与定位（修复另行排期）
    - 已安装版的恢复助手/安全模式路径不在本次范围
  acceptanceCriteria:
    - id: ac-1
      text: 给出稳定复现步骤与对照证据：同一构建在“上次停在会话视图”的 userData 下报错并退出，在全新 userData 下启动正常
      required: true
      version: 1
    - id: ac-2
      text: 定位 root slot 注册与插件渲染的先后顺序为何因“恢复会话视图”而改变（或给出明确的下一次排查入口与已排除项）
      required: true
      version: 1
handoff:
  nextSteps:
    - 下一次排查入口：比对官方 shell-client 注册 root slot 的时机与插件 Client 在“恢复会话视图”时的渲染调用栈（在渲染进程打印 boot 顺序，而不是猜）
    - 确认触发条件的精确边界：是“上次停在会话视图”还是“userData 里存在任何历史会话”（创建会话但不切走、或切回概览后退出，两种都未验）
    - 影响面待查：已安装版是否同样存在（安装版 userData 与开发壳隔离目录不同，恢复路径未必相同）
    - 已排除：与本次插件改动无因果——同一构建在全新 userData 下正常启动（见 artifacts 对照日志）
  readBefore:
    - ref-main
    - ref-client
  verifyBefore:
    - ref-evidence
references:
  - id: ref-main
    label: 壳：项目窗口启动与恢复入口
    type: file
    path: resources/dsh-project-desktop/src/app/main.mjs
  - id: ref-client
    label: 插件：Client 入口（root slot 渲染）
    type: file
    path: resources/dsh-plugin-project/src/client/index.tsx
  - id: ref-evidence
    label: 启动日志对照（artifacts 下三份日志）
    type: note
    text: artifacts/startup-broken-restore-session.log 报错退出；artifacts/startup-ok-fresh-userdata.log 与 artifacts/startup-ok-before-session-created.log 正常。
entries:
  - id: e-repro
    kind: progress
    content: 复现步骤：用隔离 userData 启动开发壳 → 在项目窗口里点「新会话」（切到会话视图）→ 关闭窗口 → 用同一 userData 重新启动。日志出现 renderSlot('root') before any 'root' registration (boot order)，随后进程退出（退出码 1）。
    basis: observation
    createdAt: 2026-09-22T14:41:34.994Z
  - id: e-evidence
    kind: progress
    content: 对照实验：同一构建、同一项目，仅换用全新隔离 userData（无历史视图/会话）启动 —— 日志无 renderSlot/Uncaught，窗口正常渲染项目资产面板。另：同一 userData 在创建会话之前的两次启动（start/start2/start3 日志）也无此错误。因此触发条件与“恢复上次停在的会话视图”相关，与本次插件改动无因果（同一构建在干净 userData 下正常）。
    basis: observation
    createdAt: 2026-09-22T14:41:34.994Z
  - id: v-ac1
    kind: verification
    content: ac-1 验证：证据已归档到 artifacts/——startup-broken-restore-session.log（报错并退出）、startup-ok-fresh-userdata.log（全新 userData 正常）、startup-ok-before-session-created.log（创建会话之前的正常启动）。
    basis: observation
    verification:
      criterionId: ac-1
      criterionVersion: 1
      method: 对照实验：同一构建下不同 userData 的启动日志对比
      result: passed
      coverage: Windows 10.0.26200 + Electron 43（开发壳，隔离 userData）
    createdAt: 2026-09-22T14:41:34.994Z
operations:
  a1f923d64cae1497a5f68c6fa6be480d7631ab4d73dd2fd945e244116378b783:
    fingerprint: 169cbfc6c47640a9fcfe418228ca9bd3137ae373d1d08e3f933affc97b66cf10
    kind: create
    at: 2026-09-22T14:41:34.994Z
    entryIds:
      - e-repro
      - e-evidence
      - v-ac1
  9b387ef7f97256f421cdd1ebb5b5c26429b1405431e28c9c6f94ccb21f48f926:
    fingerprint: 74dc03618ef448373fb9dc543e122e30ceb559ebc79ddb761a29d5ea51f4ce83
    kind: update
    at: 2026-09-22T14:41:52.811Z
    entryIds: []
criterionVersions:
  ac-1: 1
  ac-2: 1
---


