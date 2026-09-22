---
schemaVersion: 3
directory: 打开项目时 Host boot 超时误报为「DSH Host call cancelled or timed out」
id: task-637a1129-b6c0-4c28-9462-8a66c5283203
title: 打开项目时 Host boot 超时误报为「DSH Host call cancelled or timed out」
objective: 消除 DSH Project Desktop 打开项目时的高频启动失败误报：Host boot 的 RPC 预算（30 秒）小于依赖物化的合法预算（120 秒），导致首次/慢速启动被报成「DSH Host call cancelled or timed out」并进入恢复助手。先放宽超时预算并固定回归断言，同时记录结构性修复方向。
status: completed
createdAt: 2026-09-22T07:49:47.527Z
updatedAt: 2026-09-22T08:43:20.465Z
artifacts:
  - type: file
    path: artifacts/yarn-check.log
    description: yarn run check 完整日志（300000ms 版本；EXIT=0）
  - type: file
    path: artifacts/hostrpc-timeout-probe.txt
    description: HostRpc.call 第四参数行为探针
  - type: file
    path: artifacts/verification-summary.md
    description: 验证摘要
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: ca85dfc48980a97a9d3012230e99289422c10ac1
    description: "fix: 放宽 Host 启动超时（300000/120000）"
  - type: file
    path: artifacts/profile-and-boot-timing.md
    description: 耗时探针：首次 pnpm install 556ms、完整 boot 2.5–3.0s
  - type: file
    path: artifacts/boot-timing-macos-arm64.md
    description: macOS arm64 本地基准
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: 1cf636f64ee09e24a84b16b0ef85365750451daf
    description: "test: 增加项目启动耗时的 Windows CI 探针"
  - type: file
    path: artifacts/ci-windows-probe-summary.md
    description: Windows CI 结果汇总：boot 5.5–7.1s、打包版 10–12s，未复现 30s
  - type: file
    path: artifacts/ci-source-build-timing.txt
    description: CI 分阶段耗时原始输出
  - type: file
    path: artifacts/ci-packaged-probe.txt
    description: CI 便携版两次判定 JSON
  - type: file
    path: artifacts/ci-windows-io-environment.txt
    description: CI Windows IO 环境
  - type: file
    path: artifacts/yarn-check-after-convergence.log
    description: 收敛到 120000ms 后的 yarn run check 日志（EXIT=0）
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: 1349092733e39565259e8720301e646e8f044b46
    description: "fix: 把 boot 超时从 300 秒收敛到 120 秒"
archived: false
phase: validation
brief:
  currentBehavior: "项目壳建 HostRpc 时默认超时 30000ms（src/desktop-adapter/index.mjs，原第 79 行），而 rpc.call('boot', …)（原第 92 行）没有传第四个 timeoutMs 参数，因此 boot 只有 30 秒；等待 Host 子进程 {ready:true} 同样是 30 秒。超时后官方 HostRpc 对超时与被取消共用同一句 reject『DSH Host call cancelled or timed out』（host-rpc.ts:33），错误被标上 failureStage='host-boot'（native.mjs:45/194），恢复助手据此显示『启动停止位置: 启动插件服务』。**2026-09-22 实测修正**：boot 内部的首次 pnpm install 实测仅 556ms（lockfile 只含一个 link: 依赖、无 registry 包），完整 startProjectHost 在 macOS x64 上首次 3775ms、二次 2475ms。因此『30 秒预算小于 120 秒物化预算导致必然超时』的原假设不成立；Windows 上 30 秒超时的真实原因仍未确证。"
  scope: resources/dsh-project-desktop 的 Host 启动超时预算（src/desktop-adapter/index.mjs）及对应回归测试；不改固定官方源码。
  constraints:
    - 不修改固定官方源码快照 resources/dsh-desktop-source，host-rpc.ts 的错误文案不可改
    - 不改动 boot RPC 参数契约与恢复助手的阶段语义
    - 不放宽无关的控制调用超时，避免掩盖真实卡死
  outOfScope:
    - 把依赖物化移出 boot 关键路径（方案 D）
    - 让超时取消真正中断 pnpm 安装
    - Windows 上被中断的 pnpm 残留进程问题
    - 官方 host-rpc.ts 区分超时与取消两种文案
  acceptanceCriteria:
    - id: ac1
      text: boot 调用带显式超时预算，且该预算不小于官方依赖物化默认上限 120 秒
      required: true
      version: 1
    - id: ac2
      text: 等待 Host 子进程 ready 的预算被放宽，且与 boot 预算分离为具名常量
      required: true
      version: 1
    - id: ac3
      text: 通用控制调用（theme/settings/stop）的超时保持原值不变
      required: true
      version: 1
    - id: ac4
      text: 回归测试按源码文本固定两个预算，回退改动即测试失败
      required: true
      version: 1
    - id: ac5
      text: resources/dsh-project-desktop 的 yarn check 通过
      required: true
      version: 1
    - id: ac6
      text: 记录原生视觉验收步骤；未在 Windows 实际执行前不得声称该验收通过
      required: false
      version: 1
handoff:
  nextSteps:
    - 在故障机上取数（唯一还未完成的关键项）：新建项目或删除 %APPDATA%\dsh-project-desktop\projects\<hash>\dsh\profiles\desktop\pnpm-lock.yaml 后打开，记录双击到窗口出现的时间；看恢复助手详情里的 Host stderr 段
    - 同时采集两个环境事实：该机 AppData 是否为重定向/漫游路径、安全软件是否为项目目录加了排除项
    - 可选对照实验：在 Windows CI job 里用 Set-MpPreference -DisableRealtimeMonitoring $false 重开 Defender 实时保护后重跑探针（CI 当前实时保护为关闭）
    - 若故障机表现为卡住而非慢，转向排查其 AppData 路径特征与安全软件排除项
  readBefore:
    - adapter-index
    - profile-mjs
    - host-entry-mjs
  verifyBefore:
    - Windows 故障机上的实测 boot 耗时（仍未取得，CI 无法代替）
references:
  - id: adapter-index
    label: 项目壳 Host 启动适配器（超时落点）
    type: file
    path: resources/dsh-project-desktop/src/desktop-adapter/index.mjs
  - id: profile-mjs
    label: Profile 准备与首次依赖物化
    type: file
    path: resources/dsh-project-desktop/src/desktop-adapter/stable/profile.mjs
  - id: host-entry-mjs
    label: Host 子进程入口与 boot handler
    type: file
    path: resources/dsh-project-desktop/src/desktop-adapter/stable/host-entry.mjs
entries:
  - id: evidence-1
    kind: progress
    content: 证据链定位完成：错误文案唯一产地是固定官方 host-rpc.ts:33（超时定时器与 AbortSignal 取消共用同一句 reject），调用方是项目壳 src/desktop-adapter/index.mjs:92 的 rpc.call('boot')，其超时来自同文件:79 的 HostRpc 默认 30000ms。官方 DSH Desktop 壳对同一调用使用 120000ms（dsh-desktop-source/dsh-plugin-desktop/src/host-process.ts:32），本项目壳为 30000ms，属结构性偏紧。
    basis: observation
    createdAt: 2026-09-22T07:49:47.527Z
  - id: evidence-2
    kind: progress
    content: boot 阶段的合法耗时来源：stable/profile.mjs:122-131 首次无 pnpm-lock.yaml 时同步执行 materializeProjectDependencies，官方 profile-materializer 的 DEFAULT_TIMEOUT_MS=120000。30 秒的 RPC 预算会在依赖物化仍在进行时先超时，随后 index.mjs:61-72 的 close() 会 stop/kill Host，使本次安装中断。
    basis: observation
    createdAt: 2026-09-22T07:49:47.527Z
  - id: decision-1
    kind: decision
    content: 本轮只做方案 A（放宽超时）+ 回归断言：给 boot 与 ready 两个等待各自一个具名常量，不动通用控制调用超时，不做结构性改造（把依赖物化移出 boot）。理由是改动面最小、可立即消除误报，且结构性方案需要改 RPC 契约与恢复时序。
    basis: user-request
    createdAt: 2026-09-22T07:49:47.527Z
  - id: progress-1
    kind: progress
    content: 具备端到端验证入口：scripts/smoke-host.mjs 每次使用全新 stateDirectory 真实调用 startProjectHost，会覆盖首次 Profile 创建与依赖物化路径，随 yarn check 的 smoke:host 执行。
    basis: observation
    createdAt: 2026-09-22T07:49:47.527Z
  - id: verify-ac1
    kind: verification
    content: ac1 通过。源码断言测试固定 boot 调用带第四个 timeoutMs 参数且预算 300000 ≥ 官方物化预算 120000；tests/host-boot-timeout.test.mjs 3/3 通过。行为探针进一步证明 HostRpc.call 第四个位置参数确为 timeoutMs（传入 150ms，151ms 后 reject），排除「参数写错位置」这一类集成风险。
    verification:
      criterionId: ac1
      criterionVersion: 1
      method: node --test tests/host-boot-timeout.test.mjs + node .runtime/hostrpc-timeout-probe.mjs
      result: passed
      coverage: 常量值、调用点位置、运行时行为三层
    createdAt: 2026-09-22T07:52:37.859Z
  - id: verify-ac2
    kind: verification
    content: ac2 通过。等待 {ready:true} 的 30 秒字面量已换成具名 HOST_READY_TIMEOUT_MS=120000，与 HOST_BOOT_TIMEOUT_MS 分离；文本断言覆盖。
    verification:
      criterionId: ac2
      criterionVersion: 1
      method: node --test tests/host-boot-timeout.test.mjs
      result: passed
      coverage: 常量声明与等待调用点
    createdAt: 2026-09-22T07:52:37.859Z
  - id: verify-ac3
    kind: verification
    content: ac3 通过。HostRpc 控制调用默认值仍为 30000，stop 仍为 AbortSignal.timeout(5000)，project:theme:* 调用未变；测试含三条守卫断言，并已反向校验能拒绝被放宽/被省略的回退写法。
    verification:
      criterionId: ac3
      criterionVersion: 1
      method: node --test tests/host-boot-timeout.test.mjs + 三条正则对回退文本的反向校验
      result: passed
      coverage: 三处未改动点 + 回退拒绝能力
    createdAt: 2026-09-22T07:52:37.859Z
  - id: verify-ac4
    kind: verification
    content: ac4 通过。新增 tests/host-boot-timeout.test.mjs 已随 yarn test 运行（主测试总数 93，含新增 3 项）。
    verification:
      criterionId: ac4
      criterionVersion: 1
      method: yarn run check 内 yarn test 阶段
      result: passed
      coverage: 测试已接入 yarn test 的 tests/*.test.mjs 通道
    createdAt: 2026-09-22T07:52:37.859Z
  - id: verify-ac5
    kind: verification
    content: ac5 通过。yarn run check EXIT=0：主测试 93/93、recovery 7/7、safe-mode 1/1，smoke:host 14 项检查全通过（two-isolated-hosts 与 close-and-reopen-isolation 证明改动未破坏真实 Host 启停）。
    verification:
      criterionId: ac5
      criterionVersion: 1
      method: cd resources/dsh-project-desktop && yarn run check
      result: passed
      coverage: 完整 check 链，含两个真实 Host 的端到端启动（覆盖首次 Profile 创建与依赖物化路径）
    createdAt: 2026-09-22T07:52:37.859Z
  - id: verify-ac6
    kind: verification
    content: 'ac6 未执行（非必需）。本机为 macOS x64，smoke:host 自带 "nativeWindowsTested": false；Windows 上首次打开项目不再弹恢复助手的原生视觉验收尚未做，不得声称通过。验收步骤已写入 artifacts/verification-summary.md 与 handoff.nextSteps。'
    verification:
      criterionId: ac6
      criterionVersion: 1
      method: 未运行（需 Windows 环境）
      result: not-run
      coverage: 仅记录验收步骤，未执行
      reason: 当前会话仅有 macOS x64 环境，smoke:host 亦自报 nativeWindowsTested=false；Windows 原生视觉验收需在目标机器执行
    createdAt: 2026-09-22T07:52:37.859Z
  - id: completion-1
    kind: completion
    content: 实现与必需验证完成：boot 预算 300000ms、ready 预算 120000ms 落地并用回归测试固定；yarn check 全绿。剩余限制：Windows 原生视觉验收未做；依赖物化仍在 boot 关键路径内、超时后 close() 仍会 kill Host 并中断 pnpm——这两项属 outOfScope，未改变。
    verificationEntryIds:
      - verify-ac1
      - verify-ac2
      - verify-ac3
      - verify-ac4
      - verify-ac5
    createdAt: 2026-09-22T07:52:37.859Z
  - id: commit-1
    kind: progress
    content: 代码改动已本地提交 ca85dfc48980a97a9d3012230e99289422c10ac1（repository https://github.com/admintertar/dsh-project-desktop.git，未 push）：src/desktop-adapter/index.mjs 与 tests/host-boot-timeout.test.mjs，共 2 文件。提交时工作区存在并行会话对 scripts/native-resource-state-checks.mjs 的未提交改动，已刻意不纳入本次提交、也未触碰该文件。
    basis: observation
    createdAt: 2026-09-22T07:53:36.840Z
  - id: timing-1
    kind: progress
    content: "耗时实测（macOS x64，2026-09-22）：首次 pnpm install 556ms、二次（已有 lockfile）55ms；生成的 pnpm-lock.yaml 只含一个 devDependency『dsh-plugin-project: link:./.project-plugin』，无任何 registry 包；node_modules 仅含 pnpm 元数据与 dsh-plugin-project、dsh-project-shell 两个符号链接。插件的传递依赖（zod、yaml、@modelcontextprotocol 等）来自打包的 .cache/project-dependencies，不经 pnpm 下载。"
    basis: observation
    createdAt: 2026-09-22T07:57:53.023Z
  - id: timing-2
    kind: progress
    content: 耗时实测：完整 startProjectHost（含 profile 准备、Host 子进程 fork 与顶层 import、官方 boot() 插件树组装、loopback Web server、渲染认证）在 macOS x64 上首次 3775ms、二次 2475ms，close 约 40ms。距 30 秒预算有 8 倍以上余量。
    basis: observation
    createdAt: 2026-09-22T07:57:53.023Z
  - id: correction-1
    kind: decision
    content: 修正判断：撤回『30 秒预算小于官方物化 120 秒预算导致首次打开必然超时』的因果解释。该 pnpm install 实测亚秒级，不可能是数量级差距的来源。已落地的超时改动本身保留（把『慢』与『错』区分开仍然正确），但理由改写为『为一个尚未实测分布的冷启动留余量』；若 Windows 实测 boot 在 5–15 秒量级，300 秒偏大，宜向官方 Desktop 的 120 秒收敛。
    basis: observation
    createdAt: 2026-09-22T07:57:53.023Z
  - id: open-question-1
    kind: progress
    content: 根因仍未确证，候选均需 Windows 实测：企业域环境 AppData\Roaming 的文件夹重定向/漫游同步导致的 IO 延迟；Windows Defender 首次扫描数百个 JS 模块；Electron utilityProcess 与 19MB pnpm bundle 的冷启动开销；或并非『慢』而是『卡住』（官方 HostRpc 对超时与取消共用同一句文案，无法从错误文案区分）。
    basis: agent-proposal
    createdAt: 2026-09-22T07:57:53.023Z
  - id: correction-2
    kind: progress
    content: 修正事实错误：本开发机为 macOS arm64（Apple Silicon，Darwin 24.6.0，10 cpus），此前证据文档误写为 macOS x64，已更正 artifacts/profile-and-boot-timing.md 与 artifacts/verification-summary.md。该区别重要，因为仓库规约禁止用 macOS x64 结果推断 arm64/Windows 结论。
    basis: observation
    createdAt: 2026-09-22T08:10:35.261Z
  - id: probe-1
    kind: progress
    content: 新增 Windows CI 探针并已触发：commit 1cf636f 加入 scripts/probe-host-boot-timing.mjs（分阶段测 Host entry / Profile 准备 / 完整 boot，仓库内与真实用户数据根各跑一遍）、scripts/probe-packaged-boot.ps1（启动最新便携版打开临时项目，用原生窗口标题区分『项目窗口出现』与『恢复助手出现』，默认用户数据根与隔离本地目录各跑一遍）、.github/workflows/probe-boot-timing.yml（串起两者，结果写进 step summary 与 artifact）。运行：run 35703286344（windows-2022）。
    basis: user-request
    createdAt: 2026-09-22T08:10:35.261Z
  - id: probe-2
    kind: progress
    content: 旁证：同一日期的 Verify Resources on Windows（run 35702870391，31f319b）失败在 Step 18『Verify the resource panel adds a local directory on Windows』，对应另一个正在进行的 Windows 本地目录选择缺陷，与本次超时改动无关（后者只改两个超时常量）。
    basis: observation
    createdAt: 2026-09-22T08:10:35.261Z
  - id: ci-1
    kind: progress
    content: Windows CI 实测（run 35703286344，windows-2022，4 vCPU/16GB，commit 1cf636f）：源码构建 boot 仓库内 6733/5543ms、用户数据根 7065/5539ms（macOS arm64 对照 2990/2535ms）；hostReady 173–175ms；首次 prepareProfile 1.8–2.2s；close 约 100ms。两个位置无显著差异。
    basis: observation
    createdAt: 2026-09-22T08:15:17.866Z
  - id: ci-2
    kind: progress
    content: Windows CI 实测（真实产物）：下载并校验最新便携版 0.1.4（win-x64-Portable.zip），启动后打开临时项目——默认 Roaming userData 下 verdict=project-window elapsed=12s，隔离本地 userData 下 verdict=project-window elapsed=10s；两次均生成 lockfile、pendingRecovery=0，窗口标题里出现项目名而非 Recovery Assistant。30 秒超时在干净 runner 上未能复现。
    basis: observation
    createdAt: 2026-09-22T08:15:17.866Z
  - id: ci-3
    kind: decision
    content: 决定性环境差异：CI runner 的 Defender RealTimeProtectionEnabled=False（实时保护关闭），AppData 未被重定向，卷均为本地 NTFS。企业用户机器通常三者相反，恰好是候选原因。另：干净 CI 上打开已用掉 30 秒预算的 40%，真实企业环境再慢 2.5 倍即撞线，因此放宽超时的改动仍有实际意义。
    basis: observation
    createdAt: 2026-09-22T08:15:17.866Z
  - id: decision-2
    kind: decision
    content: 按用户决定把 HOST_BOOT_TIMEOUT_MS 从 300000 收敛到 120000，与官方 Desktop 壳的 boot 预算一致（commit 1349092）。依据：实测 Windows CI boot 5.5–7.1s、macOS arm64 2.5–3.0s，120s 仍有 17 倍以上余量；300s 在真卡死时白等五分钟。权衡：120s 恰等于官方物化预算，若安装真的跑满 120s 两者会同时到点，届时应缩小物化预算。
    basis: user-request
    createdAt: 2026-09-22T08:39:51.965Z
  - id: verify-ac1-converged
    kind: verification
    content: 收敛后回归：tests/host-boot-timeout.test.mjs 仍通过（断言为『不小于物化预算』，120000 恰好满足）；yarn run check EXIT=0（主测试 93/93、recovery 7/7、safe-mode 1/1、smoke:host 全通过），日志见 artifacts/yarn-check-after-convergence.log。
    basis: observation
    verification:
      criterionId: ac1
      criterionVersion: 1
      method: node --test tests/host-boot-timeout.test.mjs + cd resources/dsh-project-desktop && yarn run check
      result: passed
      coverage: 常量值、断言仍满足、完整 check 链与真实 Host 启停
    createdAt: 2026-09-22T08:39:51.965Z
  - id: completion-2
    kind: completion
    content: 收敛到 120000ms 后的实现为当前状态，再次验证完毕：ac1–ac5 仍成立（ac1 另有 verify-ac1-converged 记录新值），yarn check 全绿；ac6 仍为 not-run（Windows 真实机器未测）。任务保持完成状态。
    verificationEntryIds:
      - verify-ac1
      - verify-ac1-converged
      - verify-ac2
      - verify-ac3
      - verify-ac4
      - verify-ac5
    createdAt: 2026-09-22T08:39:51.965Z
  - id: ci-4
    kind: progress
    content: 回归确认：head 1349092（收敛到 120000ms 的提交）触发的 Probe project boot timing 运行 completed **success**（08:38:44 起，约 4 分钟后完成）。CI 上 boot 约 6.7s，远低于新的 120s 预算，收紧未引入回归；同一 push 触发的 Verify Resources on Windows 属另一个既有缺陷，与本改动无关。
    basis: observation
    createdAt: 2026-09-22T08:43:20.465Z
operations:
  6550e80a579ef283855c457347c671a762e49521c644744e4567fc9a81a08b39:
    fingerprint: fe82cc39bdc6d1066c66a1b697a74e8d191e4c8e071aa94586ea57a313e58143
    kind: create
    at: 2026-09-22T07:49:47.527Z
    entryIds:
      - evidence-1
      - evidence-2
      - decision-1
      - progress-1
  8c0255a57ac68399dc63079d33fd152aba3b29777ae9b243db2fe896c72d9730:
    fingerprint: 3c0bf5a55b881eb89565cc910942c66f054b6db98d560851badb3a2bf20ead96
    kind: update
    at: 2026-09-22T07:52:37.859Z
    entryIds:
      - verify-ac1
      - verify-ac2
      - verify-ac3
      - verify-ac4
      - verify-ac5
      - verify-ac6
      - completion-1
  185ddaed38015ad443d09897f497c5b56a83078fb6d5bc50837465d1f460e055:
    fingerprint: ae7434260fe93af4158b2ca02ce0f9656d4ea4ec3383e8f17883a01843bb2ea2
    kind: update
    at: 2026-09-22T07:53:36.840Z
    entryIds:
      - commit-1
  755f892fe0b0fa2861c098a0059311731b220c58e6dc2e22a2fa46211c082cf2:
    fingerprint: b92e8aea1b9eb52ab426b1bcb994acf19affdb403c320c779466feba761cdcdb
    kind: update
    at: 2026-09-22T07:57:53.023Z
    entryIds:
      - timing-1
      - timing-2
      - correction-1
      - open-question-1
  935c4c48e5397fb4ef9c03eb104ab73a261c483ac4319d1ec9681807d91a38bd:
    fingerprint: 9821398f232da415233eddf03d362f529187f2f269c269c8214f5bf8f62ee929
    kind: update
    at: 2026-09-22T08:10:35.261Z
    entryIds:
      - correction-2
      - probe-1
      - probe-2
  e1d01975cc85596289397279f68e998b3ad6bf1efcf74f4120a9f28eafc394e1:
    fingerprint: 72c32ec2cf6ed6dabd0dc697e847b935f094204534c0e2a3ce636869db908f75
    kind: update
    at: 2026-09-22T08:15:17.866Z
    entryIds:
      - ci-1
      - ci-2
      - ci-3
  bdd5f52812a68cd5c4ddab815dadd2aacc72c63b79e7edf58262c25a8750bf93:
    fingerprint: f87d6e82486797b2b6b4a44f76d8701ba48d72bbcf9b64c1f33de84de39bc1e0
    kind: update
    at: 2026-09-22T08:39:51.965Z
    entryIds:
      - decision-2
      - verify-ac1-converged
      - completion-2
  0571c66ab2e7895891c96ebd7316cdf62a4ffceb7486650e6bbad612d0e94cdf:
    fingerprint: 07fb1ee185b72e87b74da4457f3049b1034f868b8676871474cce39a6e2a5d31
    kind: update
    at: 2026-09-22T08:43:20.465Z
    entryIds:
      - ci-4
criterionVersions:
  ac1: 1
  ac2: 1
  ac3: 1
  ac4: 1
  ac5: 1
  ac6: 1
---

最终状态：HOST_BOOT_TIMEOUT_MS 按用户决定从 300000 收敛到 **120000**（与官方 Desktop 壳对齐，commit 1349092），HOST_READY_TIMEOUT_MS 保持 120000，通用控制调用保持 30000；回归断言与 yarn check 均通过。Windows CI 实测证明：干净 runner 上源码构建 boot 5.5–7.1s、最新便携版 0.1.4 打开项目 10–12s，30 秒超时无法在 CI 复现；关键环境差异是 CI 的 Defender 实时保护关闭且 AppData 未重定向，与用户企业环境相反。因此用户机器上的高频超时应归因于该机器的环境特征（安全软件扫描、漫游/重定向目录、或卡住），需在故障机取数确认。剩余限制：无人工视觉验收；依赖物化仍在 boot 关键路径内；120s 与物化预算相等这一理论边界已记录。
