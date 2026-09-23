---
schemaVersion: 3
directory: Windows 打包失败：.cache-project-dependencies 生产依赖为空壳导致 electron-
id: task-c3a4e751-58f6-49f6-a35b-e7d63ada64e6
title: Windows 打包失败：.cache/project-dependencies 生产依赖为空壳导致 electron-builder 收集失败
objective: 记录并修复「Windows 本地打包因 .cache 依赖缓存不完整而失败」的环境问题：给出失败签名、根因、最小修复步骤与验证结果，供后续把该前置检查纳入打包前自检。
status: active
createdAt: 2026-09-23T14:42:55.245Z
updatedAt: 2026-09-23T14:42:55.245Z
artifacts: []
archived: false
phase: implementation
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
operations:
  1ac36a8fad896708d05957307ef073662bf6905673bf11dac3662458b0e1a780:
    fingerprint: 89e8906cf066a3fe050c45d8236004260b3ba8c69e0637691207ff8359a32d07
    kind: create
    at: 2026-09-23T14:42:55.245Z
    entryIds:
      - p1
      - p2
      - p3
criterionVersions:
  P1: 1
  P2: 1
  P3: 1
---


