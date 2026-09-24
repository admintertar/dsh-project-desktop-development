---
schemaVersion: 3
directory: Windows 打包失败：.cache-project-dependencies 生产依赖为空壳导致 electron-
id: task-c3a4e751-58f6-49f6-a35b-e7d63ada64e6
title: Windows 打包失败：.cache/project-dependencies 生产依赖为空壳导致 electron-builder 收集失败
objective: 记录并修复「Windows 本地打包因 .cache 依赖缓存不完整而失败」的环境问题：给出失败签名、根因、最小修复步骤与验证结果，供后续把该前置检查纳入打包前自检。
status: completed
createdAt: 2026-09-23T14:42:55.245Z
updatedAt: 2026-09-23T15:28:28.150Z
artifacts: []
archived: false
phase: validation
brief:
  currentBehavior: "yarn package:win 在 electron-builder 收集生产依赖时失败：Error: Production dependency @modelcontextprotocol/sdk not found for package dsh-plugin-project；此前 .cache/runtime/dsh-plugin-project/node_modules 也不存在。"
  scope: 记录 .cache 依赖缓存不完整导致 Windows 打包失败的现场与最小修复，供后续排期自动化校验。
  constraints:
    - 不改动 lock 与插件 pin
    - 修复仅限 .cache 缓存目录（可重建，非产品代码）
  outOfScope:
    - 不修 setup.mjs / package-common.mjs 的自动化
    - 不改变打包流程本身
  acceptanceCriteria:
    - id: P1
      text: 记录失败签名与根因（.cache/project-dependencies 中生产依赖为空壳）
      required: true
      version: 1
    - id: P2
      text: 给出可复现的修复步骤与验证方式（yarn package:win 跑通）
      required: true
      version: 1
    - id: P3
      text: 说明为何该故障与源码改动无关及预防方式
      required: true
      version: 1
handoff:
  nextSteps:
    - add-package-preflight-dependency-check
  verifyBefore:
    - yarn-package-win
references: []
entries:
  - id: p1
    kind: progress
    content: 根因：.cache/project-dependencies 下的 @modelcontextprotocol/sdk、yaml、zod 三个生产依赖是空目录（文件数 0），electron-builder 的 TraversalNodeModulesCollector 因此在收集 dsh-plugin-project 生产依赖时找不到包；同时 .cache/runtime/dsh-plugin-project/node_modules 整层缺失。插件仓库自身的 node_modules 中这些包是完整的（sdk 1.30.0 / 698 文件）。
    basis: observation
    createdAt: 2026-09-23T14:42:55.245Z
  - id: p2
    kind: decision
    content: 修复：从 resources/dsh-plugin-project/node_modules 用 robocopy 补齐 .cache/project-dependencies 的三个生产依赖（并给 .cache/runtime/dsh-plugin-project/node_modules 放实体副本供 auditLinks 通过），之后 yarn package:win 一次跑通。注意不能用指向 .cache 的 junction 充当 runtime 依赖：preparePackage.auditLinks 会以 Non-relocatable packaged link 拒绝外链。
    basis: agent-proposal
    createdAt: 2026-09-23T14:42:55.245Z
  - id: p3
    kind: verification
    content: yarn package:win 修复后 EXIT=0：生成 DSH-Project-Desktop-0.1.8-win-x64-Setup.exe（132 MB）与 Portable.zip（213 MB），package-result.json 含 official-renderer-health、chinese-native-menu、packaged-safe-mode、temporary-cleanup、normal-reopen 等安装自检通过项。
    basis: observation
    verification:
      criterionId: P2
      criterionVersion: 1
      method: yarn package:win 全流程运行并读取 package-result.json
      result: passed
      coverage: 打包与安装自检均通过
    createdAt: 2026-09-23T14:42:55.245Z
  - id: p4
    kind: verification
    content: "P1（失败签名与根因）：`yarn package:win` 在 electron-builder 收集生产依赖时以 `Error: Production dependency @modelcontextprotocol/sdk not found for package dsh-plugin-project` 失败（调用栈经 scripts/package-dependencies.mjs:21 的 copyProductionDependencies）；根因是 .cache/project-dependencies 下的 @modelcontextprotocol/sdk、yaml、zod 三个生产依赖是空目录（文件数 0），同时 .cache/runtime/dsh-plugin-project/node_modules 整层缺失。"
    basis: observation
    verification:
      criterionId: P1
      criterionVersion: 1
      method: 重现打包失败 + 统计依赖目录文件数
      result: passed
      coverage: 失败签名、调用栈与空壳目录三层证据齐备
    createdAt: 2026-09-23T15:28:28.150Z
  - id: p5
    kind: verification
    content: P3（为何与源码无关及预防）：该故障只取决于 .cache 这份可重建的依赖缓存，与壳/插件源码及 lock pin 无关（此次修复期间也未改 lock）；预防方式是把「打包前校验 .cache/project-dependencies 中插件 dependencies 的每个包都有 package.json」做成 package-common.mjs 的前置检查，失败时提示重物化而不是等 electron-builder 报 not found。
    basis: observation
    verification:
      criterionId: P3
      criterionVersion: 1
      method: 依赖缓存与源码/lock 的变更范围对照
      result: passed
      coverage: 已说明无关性并给出可机械化的预防点
    createdAt: 2026-09-23T15:28:28.150Z
  - id: p6
    kind: completion
    content: 闭环：根因已定位并修复（robocopy 补齐 .cache/project-dependencies + 给 .cache/runtime/dsh-plugin-project/node_modules 放实体副本），yarn package:win 修复后跑通。后续：把依赖缓存完整性做成打包前置检查。
    basis: agent-proposal
    verificationEntryIds:
      - p4
      - p3
      - p5
    createdAt: 2026-09-23T15:28:28.150Z
operations:
  1ac36a8fad896708d05957307ef073662bf6905673bf11dac3662458b0e1a780:
    fingerprint: 89e8906cf066a3fe050c45d8236004260b3ba8c69e0637691207ff8359a32d07
    kind: create
    at: 2026-09-23T14:42:55.245Z
    entryIds:
      - p1
      - p2
      - p3
  c9dbd0e8f578c6e02cc2df08183696c903342ac57a2d919d238c6bb5acfb4a58:
    fingerprint: 5939e875ac9b0fa4373e3c1e7ee4d994c383959cac32c6378d2906a2095b35f9
    kind: update
    at: 2026-09-23T15:28:28.150Z
    entryIds:
      - p4
      - p5
      - p6
criterionVersions:
  P1: 1
  P2: 1
  P3: 1
---

根因：.cache/project-dependencies 中 @modelcontextprotocol/sdk、yaml、zod 是空壳目录，.cache/runtime/dsh-plugin-project/node_modules 整层缺失，electron-builder 的 TraversalNodeModulesCollector 因此报 Production dependency not found。修复：从 resources/dsh-plugin-project/node_modules robocopy 补齐这三个依赖，并给 runtime 层放实体副本供 auditLinks 通过（不能用指向 .cache 的 junction，会被判 Non-relocatable packaged link）；之后 yarn package:win EXIT=0 并生成 Setup.exe 与 Portable.zip。与源码、lock pin 无关，属可重建缓存不完整。
