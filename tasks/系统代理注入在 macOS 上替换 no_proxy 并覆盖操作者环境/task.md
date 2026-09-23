---
schemaVersion: 3
directory: 系统代理注入在 macOS 上替换 no_proxy 并覆盖操作者环境
id: task-74f13d67-347e-4ccc-a5a3-5ce46b8a29a7
title: 系统代理注入在 macOS 上替换 no_proxy 并覆盖操作者环境
objective: 修复壳「Git 继承本机系统代理」实现（4a9949c，前序任务 task-12cafb34）在无平台分支情况下对 macOS 造成的三处行为回归：no_proxy/NO_PROXY 被硬编码列表整体替换，操作者既有排除项丢失；http_proxy 等四个变量无条件展开在继承环境之后，覆盖操作者显式配置；默认排除列表只含 127.0.0.1，未覆盖整个 127.0.0.0/8 与 [::1]。补回归测试，不改插件、不改 lock、不发布。
status: completed
createdAt: 2026-09-23T01:38:45.954Z
updatedAt: 2026-09-23T01:50:19.262Z
artifacts:
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: 5f7e0a714911552cac9f802ae50362e212a849fb
    description: 系统代理注入不再覆盖操作者环境，no_proxy 改为合并（4 文件 +118/-11）
archived: false
phase: validation
brief:
  currentBehavior: 已实现并本地提交 5f7e0a7：NO_PROXY 补齐 127.0.0.0/8 与 [::1]；新增 mergeNoProxy（默认列表 + 继承环境的 no_proxy/NO_PROXY，按小写去重）与 hasExplicitProxyEnvironment；proxyHostEnvironment(detection, environment) 在操作者已导出代理时只返回合并后的 no_proxy/NO_PROXY，否则连同四个大小写代理变量一起注入；index.mjs 预计算 proxyEnvironment 并据此区分日志。
  scope: resources/dsh-project-desktop/src/desktop-adapter/stable/system-proxy.mjs、src/desktop-adapter/index.mjs、tests/system-proxy.test.mjs、docs/architecture.md
  constraints:
    - 只改壳仓库，插件零改动
    - 不修改 upstream.lock.json、不 bump pin、不 push
    - 保持 Safe Mode 不注入代理的既有语义
    - 未探测到代理或探测不可用时仍不注入任何变量
  outOfScope:
    - 把系统代理例外列表逐个目标透传给 git（resolveProxy 只能按 URL 解析，git 目标动态，本轮不做）
    - Linux 上自绘顶栏与原生菜单 accelerator 的双入口问题
    - 在 Windows 上重跑 yarn check 与真实代理链路验收
  acceptanceCriteria:
    - id: ac-1
      text: proxyHostEnvironment 把操作者既有的 no_proxy/NO_PROXY 与默认排除列表合并（去重、不丢失任一侧）；操作者未设置时结果与现行为一致
      required: true
      version: 2
    - id: ac-2
      text: 操作者已显式设置 http_proxy/https_proxy（任一大写形式）时不注入代理地址，继承值原样保留；no_proxy 仍按合并语义补全，保证 loopback、私网与产品 fixture 不经代理
      required: true
      version: 2
    - id: ac-3
      text: 默认排除列表覆盖整个 127.0.0.0/8 与 [::1]，并保留既有条目（localhost、::1、私网、.local 等）
      required: true
      version: 2
    - id: ac-4
      text: 新增回归测试覆盖 ac-1/ac-2/ac-3，且壳仓库 yarn run test 全绿
      required: true
      version: 2
handoff:
  nextSteps:
    - 补丁已 push 到 dsh-project-desktop origin/master（5f7e0a7，fast-forward）；未 bump pin、未打 tag，因此尚未发布
    - 在 Windows 上重跑一次 yarn check 与真实代理链路，确认本改动没有改变 Windows 上的注入行为（本轮只用单元测试锁定语义）
    - 若要支持「按目标分流」（让系统代理例外对 git 目标生效），需要对每个 remote 调 resolveProxy，属另行设计
  readBefore:
    - ref-system-proxy
    - ref-index
  verifyBefore:
    - cd resources/dsh-project-desktop && yarn check
references:
  - id: ref-system-proxy
    label: 壳系统代理实现
    type: file
    path: resources/dsh-project-desktop/src/desktop-adapter/stable/system-proxy.mjs
  - id: ref-index
    label: Host 启动时的注入点
    type: file
    path: resources/dsh-project-desktop/src/desktop-adapter/index.mjs
  - id: ref-tests
    label: 系统代理测试
    type: file
    path: resources/dsh-project-desktop/tests/system-proxy.test.mjs
  - id: ref-previous-task
    label: 前序任务：Git 不走系统代理
    type: task
    taskId: task-12cafb34-99ae-4443-bc56-08843c00a72a
entries:
  - id: finding-macos
    kind: progress
    content: 评审 09-19~09-23 的平台特化提交后确认：唯一在 macOS 上真实生效且无平台隔离的优化是 4a9949c 的系统代理注入。本机 scutil --proxy 实测 HTTP/HTTPS/SOCKS 均启用且指向 127.0.0.1:7890；当前 Host 导出的 NO_PROXY 与代码常量逐字一致，证明该路径在 macOS 上确实运行。
    basis: observation
    referenceIds:
      - ref-system-proxy
      - ref-previous-task
    createdAt: 2026-09-23T01:38:45.954Z
  - id: finding-noproxy-replaced
    kind: progress
    content: 风险一：proxyHostEnvironment 把 no_proxy/NO_PROXY 写成硬编码 NO_PROXY，整体替换而非合并。本机系统代理 ExceptionsList 含 muyuan.do、timestamp.apple.com、*.local 等例外，而注入后的 NO_PROXY 不含它们，因此这些目标本应直连的 git 流量会被送进 127.0.0.1:7890。
    basis: observation
    referenceIds:
      - ref-system-proxy
    createdAt: 2026-09-23T01:38:45.954Z
  - id: finding-env-override
    kind: progress
    content: 风险二：index.mjs 中 proxyHostEnvironment(proxy) 展开在 process.env 之后，操作者显式设置的 http_proxy/no_proxy 会被系统代理探测结果覆盖；通用工具语义是显式环境优先。
    basis: observation
    referenceIds:
      - ref-index
    createdAt: 2026-09-23T01:38:45.954Z
  - id: finding-loopback
    kind: progress
    content: 风险三：NO_PROXY 只排除 127.0.0.1，未覆盖 127.0.0.0/8 其余地址与 [::1]，非 .1 的本地 loopback 服务会被送进代理。
    basis: observation
    referenceIds:
      - ref-system-proxy
      - ref-tests
    createdAt: 2026-09-23T01:38:45.954Z
  - id: scope-refined
    kind: scope
    content: 范围补充 docs/architecture.md 的注入语义记录；ac-2 细化为「不注入代理地址、但仍按合并语义补全 no_proxy」，因为完全不注入会让未自行排除 loopback 的操作者把本地服务与产品 fixture 送进代理。另重导了与 pin 不一致的本地 .upstream/project 快照（7fa9925 → dd85e1a，tree 880e45f8 已核实），使完整 yarn check 可跑。
    basis: agent-proposal
    reason: 实现细化后 ac-2 原文会引入新的连通性风险，且需要同步架构文档与本地快照环境。
    createdAt: 2026-09-23T01:41:58.850Z
  - id: impl-merge
    kind: progress
    content: 补丁已实现并本地提交 5f7e0a714911552cac9f802ae50362e212a849fb（4 文件 +118/-11，未 push）：system-proxy.mjs 新增 mergeNoProxy 与 hasExplicitProxyEnvironment，proxyHostEnvironment 接收继承环境并区分「注入」与「仅补全排除」；默认排除补 127.0.0.0/8 与 [::1]；index.mjs 预计算 proxyEnvironment 并如实记录日志；docs/architecture.md 记录注入语义。
    basis: observation
    createdAt: 2026-09-23T01:42:07.584Z
  - id: verify-ac1
    kind: verification
    content: ac-1 通过：新增用例「operator exclusions survive the injection instead of being replaced by the defaults」证明 corp.example.com、.internal、muyuan.do 与默认排除项同时存在，两侧 casing 一致且代理地址未被丢弃；mergeNoProxy() 在无继承值时逐字等于原 NO_PROXY。
    verification:
      criterionId: ac-1
      criterionVersion: 2
      method: node --test tests/system-proxy.test.mjs（11/11）
      result: passed
      coverage: tests/system-proxy.test.mjs 新增用例（含 mergeNoProxy 的大小写去重与顺序断言）
    createdAt: 2026-09-23T01:42:07.584Z
  - id: verify-ac2
    kind: verification
    content: ac-2 通过（细化后语义）：新增用例「an operator-exported proxy is kept and only the exclusions are enforced」对 http_proxy/https_proxy/HTTP_PROXY/HTTPS_PROXY 逐一断言不返回代理地址、且仍含 localhost 排除；hasExplicitProxyEnvironment 对空白值与无关变量返回 false，对 http_proxy/HTTPS_PROXY 返回 true。
    verification:
      criterionId: ac-2
      criterionVersion: 2
      method: node --test tests/system-proxy.test.mjs（11/11）
      result: passed
      coverage: 四个大小写代理变量 + hasExplicitProxyEnvironment 的正反例
    createdAt: 2026-09-23T01:42:07.584Z
  - id: verify-ac3
    kind: verification
    content: ac-3 通过：新增用例「the default exclusions cover the whole loopback block, not just 127.0.0.1」断言 localhost、127.0.0.1、127.0.0.0/8、::1、[::1] 均在默认列表内。
    verification:
      criterionId: ac-3
      criterionVersion: 2
      method: node --test tests/system-proxy.test.mjs（11/11）
      result: passed
      coverage: NO_PROXY 常量条目
    createdAt: 2026-09-23T01:42:07.584Z
  - id: verify-ac4
    kind: verification
    content: ac-4 通过：壳仓库完整 yarn check EXIT=0——verify:upstream（重导后快照 tree=880e45f8 与 pin 一致）+ build（pin 快照正常构建）+ 118/118 tests（原 115 + 新增 3）+ recovery 7/7 + safe-mode 1/1 + check-project-files + smoke:host。
    verification:
      criterionId: ac-4
      criterionVersion: 2
      method: cd resources/dsh-project-desktop && yarn check（EXIT=0）
      result: passed
      coverage: 壳仓库全部检查链路，macOS arm64 本机
    createdAt: 2026-09-23T01:42:07.584Z
  - id: completion
    kind: completion
    content: 四项验收标准均已通过并在 macOS 上完成完整 yarn check；补丁本地提交 5f7e0a7，未 push、未 bump pin。剩余限制见 summary 与 handoff。
    verificationEntryIds:
      - verify-ac1
      - verify-ac2
      - verify-ac3
      - verify-ac4
    createdAt: 2026-09-23T01:42:07.584Z
  - id: push-master
    kind: progress
    content: 已按用户要求 push 到壳仓库 origin/master：4111f2f..5f7e0a7，fast-forward，origin/master 无领先提交（push 前先 fetch 确认）。未 bump upstream.lock.json、未 push 插件、未打 tag，因此未进入发布流程。fetch 时新拉到远端已有的 v0.1.7/v0.1.8 tag。
    basis: observation
    createdAt: 2026-09-23T01:50:19.262Z
operations:
  7e79cf803642f4a9781c9311bf14783af3201b86152e6fe82b6a1552227e9431:
    fingerprint: 94bb98e377a5cff06bacb3545cdef35d5e69d08d01d748003de13caa075659b6
    kind: create
    at: 2026-09-23T01:38:45.954Z
    entryIds:
      - finding-macos
      - finding-noproxy-replaced
      - finding-env-override
      - finding-loopback
  9cb692bc1279a5ea5693f294f816b6c9a02687fbbc627014c5c15cfb7be988d6:
    fingerprint: 77f5591a27781ff614af50db440c28b2b90306f9449e7597dceba52c01130934
    kind: update
    at: 2026-09-23T01:41:58.850Z
    entryIds:
      - scope-refined
  ce584425ad48d8628663421936f5177258aa56a2a328c5fcfb12a7441d1b1555:
    fingerprint: cecf61971908beb833203a1830f8bd668d27559d5012119417de81666df81536
    kind: update
    at: 2026-09-23T01:42:07.584Z
    entryIds:
      - impl-merge
      - verify-ac1
      - verify-ac2
      - verify-ac3
      - verify-ac4
      - completion
  5367857eb29beb4bfb7adf591a293b7a09002cdca392422a2feba90d850c2479:
    fingerprint: da3297bff305f568e4877e9ce7d257adbdbcae059c72fac643499d04b17ff8ac
    kind: update
    at: 2026-09-23T01:50:19.262Z
    entryIds:
      - push-master
criterionVersions:
  ac-1: 2
  ac-2: 2
  ac-3: 2
  ac-4: 2
---

macOS 侧的系统代理注入回归已修复、验证并推送，壳仓库提交 5f7e0a714911552cac9f802ae50362e212a849fb 已在 origin/master（4111f2f..5f7e0a7，fast-forward）。三处改动：(1) no_proxy/NO_PROXY 从「硬编码整体替换」改为「产品默认排除项 + 继承环境既有排除项」的合并，按大小写去重并保留操作者拼写；(2) 操作者已导出 http_proxy/https_proxy（任一大小写）时不再覆盖其代理地址，只强制补全排除列表；(3) 默认排除列表补齐整个 127.0.0.0/8 与 [::1]。Host 启动日志如实区分「注入解析结果」与「沿用继承环境」，docs/architecture.md 记录了新语义。验证：yarn check EXIT=0（verify:upstream + build + 118 tests（新增 3 例）+ recovery 7 + safe-mode 1 + check-project-files + smoke:host）。限制：本轮只在 macOS 上验证，未在 Windows 上重跑；未 bump pin、未打 tag，因此没有触发发布；macOS 上 resolveProxy 返回 SOCKS5 的分支仍未实测（本机无本地 Electron 二进制）；系统代理例外列表本身无法透传给 git 目标，只能在 no_proxy 里保留操作者的显式排除。
