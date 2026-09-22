---
schemaVersion: 3
directory: Git 不走系统代理：壳检测本机代理并注入 Host-Git 环境
id: task-12cafb34-99ae-4443-bc56-08843c00a72a
title: Git 不走系统代理：壳检测本机代理并注入 Host/Git 环境
objective: 让产品在打开项目时自动检测本机系统代理（WinINET/PAC）、预检其可用性，并把可用的代理以环境变量形式注入项目 Host，使插件启动的所有 Git 命令（clone/fetch/push）与 Git LFS 都经由该代理；代理不可用时保持直连、不拖慢 Git 超时。改动只落在壳（resources/dsh-project-desktop），插件零改动。
status: completed
createdAt: 2026-09-22T17:00:15.869Z
updatedAt: 2026-09-22T17:05:48.405Z
artifacts:
  - type: file
    path: artifacts/verification.md
    description: 验收证据报告：缺陷事实、改动面、四条证据链、契约落实位置、全量校验结果与五条未覆盖局限
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: 4a9949cb3ac2b2a5659f3cbe820c1153dc77ab73
    description: 壳：Git 继承本机系统代理（system-proxy.mjs + supervisor 注入 + runtime.resolveProxy + 8 例单测），4 文件 +285/-2，已本地提交未 push
archived: false
phase: validation
brief:
  currentBehavior: "壳从不读取系统代理。Git for Windows 是 libcurl+schannel，不读 WinINET 注册表，也不继承任何 http_proxy 环境变量；本机 Clash 在 127.0.0.1:7890 正常，但 git push/fetch 直连 github 在 21.2s 后失败（fatal: Failed to connect to github.com:443 after 21070 ms），而同期浏览器/Electron 正常。实测只有仓库本地配置了 http.proxy 的 dsh-project-desktop 能推，根仓库与 dsh-plugin-project 都不能。"
  scope: resources/dsh-project-desktop：新增 stable/system-proxy.mjs（解析 Chromium resolveProxy 结果、loopback 预检、结果缓存、环境变量构造与地址脱敏）；index.mjs 在 fork Host 前探测并注入 http_proxy/https_proxy/HTTP_PROXY/HTTPS_PROXY/no_proxy；native.mjs 把 electron.session.defaultSession.resolveProxy 作为 runtime.resolveProxy 暴露给宿主 supervisor；新增 tests/system-proxy.test.mjs。
  constraints:
    - 插件仓库不改，因此不涉及 upstream.lock.json 的 pin bump
    - Safe Mode 继续不继承代理（safeHostEnvironment 的既有约定）
    - 注入只能通过子进程环境变量，不改写操作者本人的 git config
    - 代理不可用时降级直连，不用代理拖长 Git 超时
    - Precheck 预算必须留在既有 Host boot 预算内（测得 ~10ms）
    - loopback 与私网目标经 no_proxy 排除，避免劫持测试 fixture 与本地服务
  outOfScope:
    - 设置界面里的代理开关或手动代理输入
    - SOCKS 之外的企业 PAC 认证代理、SSH remote 的 ProxyCommand
    - 把 git http.proxy 写进项目 .git/config 或用户全局配置
    - Windows 之外平台的代理读取（macOS/ Linux 走同一 resolveProxy 接口但本轮未做原生验收）
  acceptanceCriteria:
    - id: ac-1
      text: 本机存在可用系统代理时，打开项目窗口后 Git 命令经代理；壳日志打印所解析到的代理地址与探测结论
      required: true
      version: 1
    - id: ac-2
      text: 系统代理解析不出来、为 DIRECT 或本地代理端口不可达时，不注入任何代理变量，Git 保持直连且不额外消耗超时
      required: true
      version: 1
    - id: ac-3
      text: Safe Mode 的 Host 环境仍不包含任何代理变量
      required: true
      version: 1
    - id: ac-4
      text: loopback 与私网目标（含测试 fixture 的 127.0.0.1 clone）不被代理，既有 project-bootstrap-network 测试继续通过
      required: true
      version: 1
    - id: ac-5
      text: 诊断只暴露代理地址，不泄露凭据（userinfo 被剥离）
      required: true
      version: 1
    - id: ac-6
      text: resources/dsh-project-desktop 的 yarn check 全绿（typecheck/build/test/recovery/safe-mode/check-project-files/smoke:host）
      required: true
      version: 1
handoff:
  nextSteps:
    - 本次交付已本地提交（壳 4a9949c），未 push、未发布；如需发布需明确要求
    - 发布时的固定顺序：先 push 插件提交 → 再把 upstream.lock.json 的 project.commit/tree 指向已推送提交 → 重导 .upstream/project → yarn run verify:upstream；本次插件仓库零改动，只有壳需要发布
    - 插件仓库仍是脏的：src/client/ProjectChangesPanel.tsx（操作者自己的改动：commitError 提示移到提交按钮下方）待操作者自行提交
    - 若要彻底在 Host 进程内证明 git 走代理，需要管理员权限读取 utilityProcess 环境块，或在插件侧临时记录子进程 env（本轮未做）
  readBefore:
    - ref-system-proxy
    - ref-plugin-git-env
    - ref-safe-mode
  verifyBefore:
    - yarn-check
    - dev-shell-proxy-log
    - proxy-off-downgrade
references:
  - id: ref-system-proxy
    label: 壳侧系统代理模块
    type: file
    path: resources/dsh-project-desktop/src/desktop-adapter/stable/system-proxy.mjs
  - id: ref-test
    label: 系统代理单测
    type: file
    path: resources/dsh-project-desktop/tests/system-proxy.test.mjs
  - id: ref-supervisor
    label: Host supervisor 注入点
    type: file
    path: resources/dsh-project-desktop/src/desktop-adapter/index.mjs
  - id: ref-related-task
    label: 相关既有任务：壳测试克隆传输泄漏（本机代理劫持 127.0.0.1 fixture）
    type: task
    taskId: task-bf50c979-6b1f-4f3c-91f2-e0255fcc4f43
  - id: ref-note-proxy-hijack
    label: 已知陷阱：用户级 http.proxy 会劫持 127.0.0.1 上的测试 fixture（已用 no_proxy 处理）
    type: note
    text: tests/project-bootstrap-network.test.mjs 头部注释记录了该陷阱；本次改动新增的 no_proxy 必须显式包含 localhost/127.0.0.1/::1 与私网段。
  - id: ref-plugin-git-env
    label: 插件唯一的 git 执行点（从 process.env 构造子进程环境，只剥离 GIT_*/DSH_GIT_AUTH_*/SSH_ASKPASS）
    type: file
    path: resources/dsh-plugin-project/src/resource-git.ts
  - id: ref-safe-mode
    label: Safe Mode 环境白名单（仍然不继承代理）
    type: file
    path: resources/dsh-project-desktop/src/desktop-adapter/stable/safe-mode.mjs
entries:
  - id: e1
    kind: progress
    content: 根因确认（实测）：本机 WinINET 系统代理 ProxyEnable=1 / 127.0.0.1:7890（Clash），但 HTTP_PROXY 环境变量不存在、git 全局与 system config 无 proxy、netsh winhttp 为 Direct access；git 2.55.0.windows.5 + schannel 直连 github 21.2s 失败，加 -c http.proxy=http://127.0.0.1:7890 后 0.9s 成功。对照：只有 resources/dsh-project-desktop/.git/config 里配置过代理。
    basis: observation
    createdAt: 2026-09-22T17:00:15.869Z
  - id: e2
    kind: decision
    content: 探测落在壳侧：Electron 43 的 session.defaultSession.resolveProxy('https://github.com/') 返回 PROXY 127.0.0.1:7890，而对 127.0.0.1 目标返回 DIRECT（已用真实 Electron 主进程探针验证）；因此不需要自己解析注册表，也不存在 loopback 被 PAC 劫持的问题。
    basis: agent-proposal
    createdAt: 2026-09-22T17:00:15.869Z
  - id: e3
    kind: decision
    content: 注入方式是 Host 子进程环境变量而不是 git config：一次注入覆盖插件 spawn 的全部 Git、Git LFS（读 HTTP_PROXY/HTTPS_PROXY）与其它 bundled 工具，且不写操作者本人的 Git 配置。大小写两套都设，因为 Windows 环境块大小写不敏感而读取方偏好不同。
    basis: agent-proposal
    createdAt: 2026-09-22T17:00:15.869Z
  - id: e4
    kind: progress
    content: "实现落地：新增 src/desktop-adapter/stable/system-proxy.mjs（parseProxyAnswer/probeProxy/detectSystemProxy/proxyHostEnvironment/redactProxy + NO_PROXY），index.mjs 在 spawnHost 前 await detectSystemProxy({resolveProxy: nativeRuntime?.resolveProxy}) 并把 proxyHostEnvironment(proxy) 展开在继承环境之后，native.mjs 暴露 runtime.resolveProxy。"
    basis: observation
    createdAt: 2026-09-22T17:00:15.869Z
  - id: e5
    kind: progress
    content: "原生验收（真实开发壳）：DSH_PROJECT_PLUGIN_SOURCE=../dsh-plugin-project + 隔离 userData 启动壳并打开项目窗口，stdout 打印 `System proxy: http://127.0.0.1:7890 (connected)`，项目窗口 `dsh-project-desktop-development` 正常打开。配合 Electron 43 resolveProxy 探针（github => PROXY 127.0.0.1:7890，127.0.0.1 => DIRECT）证明探测链在真实环境成立。"
    basis: observation
    createdAt: 2026-09-22T17:01:57.722Z
  - id: e6
    kind: verification
    content: "ac-1 通过：真实开发壳日志 `System proxy: http://127.0.0.1:7890 (connected)`；Electron resolveProxy 探针对 github 返回 PROXY、对 127.0.0.1 返回 DIRECT。"
    verification:
      criterionId: ac-1
      criterionVersion: 1
      method: native-shell-dev-log + electron-resolveproxy-probe
      result: passed
      coverage: 真实 Electron 环境下的探测与注入链，未在 Host 进程内直接观测 git 子进程
    createdAt: 2026-09-22T17:01:57.722Z
  - id: e7
    kind: verification
    content: ac-2 通过：单测覆盖 DIRECT / 无 resolver / resolver 抛错 / 本地端口 refused / 超时五种情形，均返回 proxied:false 且 proxyHostEnvironment 为 {}；真实本地 TCP 预检仅毫秒级，超时上限 500ms。
    verification:
      criterionId: ac-2
      criterionVersion: 1
      method: unit-test
      result: passed
      coverage: 降级路径由单测与 fake socket 覆盖，未在生产中制造代理宕机场景
    createdAt: 2026-09-22T17:01:57.722Z
  - id: e8
    kind: verification
    content: ac-3 通过：index.mjs 源码断言 Safe Mode 分支不调用 detectSystemProxy，且环境构造仍为 safeHostEnvironment(process.env) 后再展开空代理对象；safeHostEnvironment 白名单未改动。
    verification:
      criterionId: ac-3
      criterionVersion: 1
      method: source-contract-assertion
      result: passed
      coverage: 源码契约断言 + 既有 safe-mode 检查，未实机启动 Safe Mode
    createdAt: 2026-09-22T17:01:57.722Z
  - id: e9
    kind: verification
    content: ac-4 通过：NO_PROXY 含 localhost/127.0.0.1/::1 与私网段并有单测断言；yarn check 中 project-bootstrap-network 的三个 loopback 真实克隆用例（含取消后断连）全部通过。
    verification:
      criterionId: ac-4
      criterionVersion: 1
      method: unit-test + existing-bootstrap-network-tests
      result: passed
      coverage: 既有 fixture 测试 + 常量断言
    createdAt: 2026-09-22T17:01:57.722Z
  - id: e10
    kind: verification
    content: ac-5 通过：redactProxy 剥离 userinfo 并有单测（http://user:secret@proxy.corp:8080 → http://proxy.corp:8080）；日志只经 redactProxy 输出。
    verification:
      criterionId: ac-5
      criterionVersion: 1
      method: unit-test
      result: passed
      coverage: 单测覆盖
    createdAt: 2026-09-22T17:01:57.722Z
  - id: e11
    kind: verification
    content: ac-6 通过：cd resources/dsh-project-desktop && yarn check → EXIT=0，tests 115/115（含新增 8 例）、recovery 7/7、safe-mode 1/1、check-project-files 通过、smoke:host 通过。
    verification:
      criterionId: ac-6
      criterionVersion: 1
      method: yarn check
      result: passed
      coverage: 全量校验，Windows 本机；macOS/Linux 未跑
    createdAt: 2026-09-22T17:01:57.722Z
  - id: e12
    kind: completion
    content: 实现完成：壳在打开项目时解析本机系统代理、预检可用性并注入 Host 环境（ac-1..ac-6 全部通过）。交付物：壳工作树 4 个文件（1 新增模块、1 新增测试、index.mjs 与 native.mjs 修改），未提交未 push；插件仓库零改动。证据报告见 artifacts/verification.md。
    verificationEntryIds:
      - e6
      - e7
      - e8
      - e9
      - e10
      - e11
    createdAt: 2026-09-22T17:01:57.722Z
  - id: e13
    kind: progress
    content: 交付已提交到壳仓库本地 master：4a9949cb3ac2b2a5659f3cbe820c1153dc77ab73（4 文件 +285/-2，未 push）。首次提交的中文信息被 PowerShell 5.1 的 Out-File -Encoding UTF8 写入了 BOM，经 git commit --amend 以无 BOM 文件重写修正（对照本仓库 86868eb 同类 BOM 修复）。插件仓库那处未提交改动（ProjectChangesPanel.tsx 把 commitError 提示移到提交按钮下方）属操作者自己的改动，按指示未动、未提交。
    basis: observation
    createdAt: 2026-09-22T17:05:48.405Z
operations:
  804f01baf923080a04a69043a58d848aaa41d9d0ba3333552c6e71c438e4c9ae:
    fingerprint: 0ffa29555d5861a54fa011f8cb0095f8cef511b03f601f969812d617b0520b26
    kind: create
    at: 2026-09-22T17:00:15.869Z
    entryIds:
      - e1
      - e2
      - e3
      - e4
  8b7228ac2a8ae848315e4fd8c71724636116862bbe9b7d3d0085406679bb2f8c:
    fingerprint: a3d48a73de8b2290c7718c721384c45d67b30196b4d903fd705d9851cae3da0f
    kind: update
    at: 2026-09-22T17:01:57.722Z
    entryIds:
      - e5
      - e6
      - e7
      - e8
      - e9
      - e10
      - e11
      - e12
  c4db41266349194101f508a6164131506e972cd9fdad7e5845458700b191e7c9:
    fingerprint: fe3672334c950c078381bdba6cf02fb922183d4b168f9d126d0fa7c059fc4315
    kind: update
    at: 2026-09-22T17:05:48.405Z
    entryIds:
      - e13
criterionVersions:
  ac-1: 1
  ac-2: 1
  ac-3: 1
  ac-4: 1
  ac-5: 1
  ac-6: 1
---

壳现在会在打开项目时解析本机系统代理并把它注入项目 Host 环境，Git 与 Git LFS 因此走代理；代理缺失、为 DIRECT 或本地端口不可达时完全不注入（保持直连、不拖长超时）。实现：新增 src/desktop-adapter/stable/system-proxy.mjs（parseProxyAnswer/probeProxy/detectSystemProxy/proxyHostEnvironment/redactProxy + NO_PROXY），index.mjs 在 spawnHost 前探测并把代理环境展开在继承环境之后，native.mjs 暴露 runtime.resolveProxy；新增 tests/system-proxy.test.mjs（8 例）。插件仓库零改动，不涉及 pin bump。验收：真实开发壳日志 `System proxy: http://127.0.0.1:7890 (connected)`；yarn check EXIT=0（115+7+1 tests 全过、smoke:host 通过，含 loopback fixture 的 clone 用例）。局限：未在 Host 进程内部直接观测 git 子进程（非管理员无法读其它进程环境块，WMI 返回 null），该段由「git 遵守这两个变量」+「插件从 process.env 构造 git 环境」+「真实壳完成注入」合成；仅 Windows 实机验收；SSH remote 与 PAC 认证代理不在覆盖范围。
