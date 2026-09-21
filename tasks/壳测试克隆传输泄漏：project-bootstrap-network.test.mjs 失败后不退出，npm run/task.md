---
schemaVersion: 3
directory: 壳测试克隆传输泄漏：project-bootstrap-network.test.mjs 失败后不退出，npm run
id: task-bf50c979-6b1f-4f3c-91f2-e0255fcc4f43
title: 壳测试克隆传输泄漏：project-bootstrap-network.test.mjs 失败后不退出，npm run check 永久挂起
objective: 修复 resources/dsh-project-desktop/tests/project-bootstrap-network.test.mjs 在真实克隆用例失败后不关闭传输、导致 node --test 永不退出、npm run check 永久挂起的缺陷：给出完整证据链与可复现步骤，使该测试在有网络故障时也能正常终止并如实报告失败。
status: completed
createdAt: 2026-09-21T10:00:05.786Z
updatedAt: 2026-09-21T10:20:48.246Z
artifacts:
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: 216d4e414c038544214c29bcd7000c8630184d7c
    description: "test: bound the loopback clone waits so a transport leak cannot hang check"
archived: false
phase: validation
brief:
  currentBehavior: 本机运行 resources/dsh-project-desktop 的 yarn check 时，tests/project-bootstrap-network.test.mjs 的 3 个用例中 2 个以 'test timed out after 15000ms' 失败（#2 cancelling a real clone…、#3 a stalled clone times out…）。旧代码在超时后卡在无界的 `await f.disconnected`：await f.requested 已 resolve、controller.abort() 后产品 pending 在 10ms 内以 AbortError reject，但服务器端 res 'close' 永不触发（TCP 4 秒仍 ESTABLISHED，客户端一侧属 ClashX 代理），测试进程持有 LISTEN/ESTABLISHED socket 永不退出，node --test 等待它，yarn check 永久挂起。2026-09-22 复现：90s alarm 强杀（EXIT=142）。已修复：测试进程隔离 GIT_CONFIG_GLOBAL/GIT_CONFIG_SYSTEM（避开用户级 http.proxy=http://127.0.0.1:7890 劫持 loopback），所有等待有界，每个 finally 有兜底清理；yarn check 现 18 秒 EXIT=0，故障注入与传输泄漏场景均限时失败（EXIT=1）。
  scope: 定位并修复该测试文件在失败路径上的传输/子进程清理，使测试进程能退出；给出证据链与复现步骤。
  constraints:
    - 只改测试与必要的清理逻辑，不改产品行为
    - 修复后 npm run check 在断网/慢网下必须能终止并如实报失败，不得靠放宽 timeout 掩盖
  outOfScope:
    - 真实克隆功能本身的网络健壮性改造
    - CI 侧 timeout 配置调整
  acceptanceCriteria:
    - id: ac1
      text: 给出完整证据链：失败用例、卡住的 pid、socket 状态、进程树
      required: true
      version: 1
    - id: ac2
      text: 修复后 npm run check 在同样网络条件下能终止，退出码如实反映失败
      required: true
      version: 1
    - id: ac3
      text: 补回归验证：断网/慢网下不再挂起
      required: true
      version: 1
handoff:
  nextSteps:
    - 如需在 CI/其他机器上复核：cd resources/dsh-project-desktop && yarn check（本机实测 18 秒 EXIT=0）
    - 跟进 task-18bf5992（Yarn 4.18.0 迁移）时注意：工作区仍有其未提交改动（package.json/.yarnrc.yml/yarn.lock/package-lock.json 删除与 .github 工作流），不要与本次测试修复混在同一提交
    - 若后续怀疑仍有真实传输泄漏：以 1500ms 有界断言为准，超时即报错而不会挂起；可用 project-bootstrap-network-hang 的形状复现
    - Windows 侧未验证（yarn check 报 nativeWindowsTested=false），如需要请在 Windows runner 上跑同一命令
  readBefore:
    - file-test
    - note-fix
    - note-rootcause
    - note-evidence
  verifyBefore:
    - yarn check 是否在有限时间内给出退出码（不是只看日志最后一行）
    - git config --global --get http.proxy 是否仍会劫持 loopback（本机为 http://127.0.0.1:7890）
    - 是否有新的无界 await 引入测试文件
references:
  - id: file-test
    label: 卡住的测试文件
    type: file
    path: resources/dsh-project-desktop/tests/project-bootstrap-network.test.mjs
  - id: note-evidence
    label: 证据链（实测）
    type: note
    text: '1) 后台运行 `{ npm run check; echo "EXIT=$?"; } > /tmp/dsh-check.log 2>&1`，日志在 17:50 达到 5202 字节后连续 4 分钟以上零增长，最后输出为 project-bootstrap-network.test.mjs 的 #15 not ok。2) 进程树：bash -> npm run check -> sh -c (check 串联) -> node --test <18 个测试文件> (pid 63435) -> node tests/project-bootstrap-network.test.mjs (pid 63441)。3) lsof -p 63441 显示 4 个未关闭的回环 socket：12u IPv4 localhost:61023 (LISTEN)、13u IPv4 localhost:61147 (LISTEN)、14u IPv4 localhost:61023->localhost:61028 (ESTABLISHED)、16u IPv4 localhost:61147->localhost:61149 (ESTABLISHED)。4) 该文件只有 3 个用例（第 51/72/91 行），全部已输出结果，进程仍不退出 => 失败路径未关闭克隆传输。5) 对照：同一命令用管道 `npm run check 2>&1 | tail -80` 后台运行时，因 tail 需读到 EOF 才输出，agent 侧看到的是 48.9 分钟完全无输出、状态一直 running。'
  - id: note-repro
    label: 复现步骤
    type: note
    text: |-
      cd resources/dsh-project-desktop && node --test tests/project-bootstrap-network.test.mjs
      在本机（GitHub 连通性差）该命令会打印 2 个 testTimeoutFailure 后永不退出；Ctrl-C 才能结束。加 lsof 确认残留 LISTEN/ESTABLISHED 回环 socket。
  - id: note-verify
    label: 验证方式
    type: note
    text: 修复后：1) 单独运行 `node --test tests/project-bootstrap-network.test.mjs` 必须在有限时间内退出并给出非零退出码；2) 完整 `npm run check` 在同样网络条件下必须终止，EXIT 非 0；3) 断网（或用不可达远端）重跑同样必须终止。
  - id: note-fix
    label: 修复内容与验证（实测）
    type: note
    text: "修复提交 216d4e414c038544214c29bcd7000c8630184d7c（test: bound the loopback clone waits so a transport leak cannot hang check）。改动范围仅测试文件：(1) tests/project-bootstrap-network.test.mjs 在进程级设置 GIT_CONFIG_GLOBAL=/dev/null、GIT_CONFIG_SYSTEM=/dev/null（不覆盖已有值），新增 within(promise, ms, message) 有界等待，f.requested/rejected/disconnected/observed 全部包上界，每个 finally 先 controller.abort()+f.release() 再以有界 await 结算并 cleanup；(2) 新增 tests/project-bootstrap-network-hang.test.mjs 作为回归守卫：fixture 的断连信号永不出现，断言 1500ms 有界报告（恒过用例，证明泄漏时不会无限等待）。验证：单文件 node --test 连续 3 次 1-2 秒 EXIT=0；yarn check 18 秒 EXIT=0，nativeWindowsTested=false；故障注入（把 f.requested 的 8s 上界改成 1ms）EXIT=1 且 1 秒内报 'the redirected clone never reached the fixture server'。"
  - id: note-rootcause
    label: 根因（实测）
    type: note
    text: "卡点是旧代码第 82/97 行的无界 `await f.disconnected`。分阶段诊断（/tmp/diag-clone.mjs）：[0.25s] RACE requested -> settled；controller.abort() 后 [0.26s] RACE rejected -> settled（AbortError），但 [6.26s] RACE disconnected -> timeout——产品侧 kill 正确，服务器端 close 探测不可靠。socket 证据（/tmp/diag2.mjs）：abort 后 1s 与 4s，lsof 显示 `ClashX 1164 ... 127.0.0.1:54195->127.0.0.1:54193 (ESTABLISHED)` 与 `node ... 54193->54195 (ESTABLISHED)`，即客户端一侧是系统代理 ClashX 在保持连接；`git config --global --get http.proxy` = http://127.0.0.1:7890（https.proxy 同），把测试重定向到 127.0.0.1 的 clone 也代理了。隔离该配置后（/tmp/diag3.mjs，GIT_CONFIG_GLOBAL=/dev/null）断连在 10ms 内：abort 后立即 'SERVER res close'、settled: rejected:AbortError、disconnected within 3s? YES。旧代码没有 finally 兜底的原因：测试超时后 node:test 取消该测试但 await 链未结束，fixture 的 release 无人调用、cleanup 未执行，server 与 socket 一直持有，故 node --test 不退出。"
entries:
  - id: inv-hang-1
    kind: progress
    content: "证据链（实测，非推断）：后台运行壳的 npm run check 并落盘到 /tmp/dsh-check.log，日志停在 project-bootstrap-network.test.mjs 的 #15 not ok 后连续 4 分钟以上零增长。进程树 bash -> npm run check -> sh -c -> node --test(63435) -> node tests/project-bootstrap-network.test.mjs(63441)。lsof -p 63441 显示 2 个 LISTEN（localhost:61023、localhost:61147）与 2 个 ESTABLISHED（61023->61028、61147->61149）回环连接未关闭。该文件仅 3 个用例且全部已输出结果，进程仍不退出。"
    basis: observation
    reason: 定位 npm run check 永久挂起的直接原因
    createdAt: 2026-09-21T10:00:05.786Z
  - id: inv-hang-2
    kind: progress
    content: 影响面：npm run check 是项目约定的验证入口（memory/working-agreements.md「验证」章节），其不终止会连带使任何以它为门槛的验证流程卡死。历史会话 session-2d5c8869 因此空等 48.9 分钟；同期 20 个会话中此类无输出等待累计 173.9 分钟。此外 job_kill 只终止包装进程、不杀整棵进程树，残留的 node --test 会继续存活。
    basis: observation
    reason: 评估影响范围与关联缺陷
    createdAt: 2026-09-21T10:00:05.786Z
  - id: inv-hang-3
    kind: decision
    content: 本轮只记录证据链与复现步骤，不改测试代码。修复方向：在该测试文件的失败/超时路径上显式关闭克隆传输与监听 socket（例如在 finally/after 钩子里 destroy 传输、close server），并确保子进程在 timeout 后被杀。
    basis: agent-proposal
    reason: 按用户选择先建任务记录，后续排期实现
    createdAt: 2026-09-21T10:00:05.786Z
  - id: ver-hang-ac1
    kind: verification
    content: "ac1 已验证：证据链完整且可复现——失败用例（project-bootstrap-network.test.mjs #14/#15 均 testTimeoutFailure，该文件仅 3 个用例且全部已输出结果）、卡住 pid（63441）、socket 状态（lsof 显示 2 个 LISTEN + 2 个 ESTABLISHED 回环连接未关闭）、进程树（bash -> npm run check -> sh -c -> node --test 63435 -> node tests/project-bootstrap-network.test.mjs 63441）均已实测记录，详见 note-evidence 与 note-repro。"
    basis: observation
    verification:
      criterionId: ac1
      criterionVersion: 1
      method: 后台运行壳的 npm run check 并落盘到 /tmp/dsh-check.log，观察日志增长停滞；ps 取进程树；lsof -p 取 socket 状态
      result: passed
      coverage: 证据链已完备；ac2/ac3 属修复后验证，尚未开始（本轮只做调查与记录）
    createdAt: 2026-09-21T10:01:24.570Z
  - id: ver-hang-ac2
    kind: verification
    content: "ac2 通过。修复后 resources/dsh-project-desktop 的 yarn check 实测 18 秒 EXIT=0（本轮两次运行：/tmp/yarncheck.log 与 /tmp/yarncheck2.log），不再挂起；单文件 node --test tests/project-bootstrap-network.test.mjs 连续 3 次 1-2 秒 EXIT=0，3/3 用例通过。退出码如实反映失败：故障注入副本（把对 fixture 服务器的有界等待从 8000ms 改为 1ms）EXIT=1 且 1 秒内退出，TAP 报 'not ok 1/2 ... error: the redirected clone never reached the fixture server'；泄漏探针（服务器断连信号永不出现）此前实测 2 秒内 EXIT=1 并报 'the clone transport stayed open for more than 1500ms after the client stopped'。未放宽任何 timeout（保留 15000ms 测试预算）。"
    basis: observation
    verification:
      criterionId: ac2
      criterionVersion: 1
      method: cd resources/dsh-project-desktop && perl -e 'alarm 300; exec @ARGV' -- yarn check，落盘日志后检查 EXIT 与耗时；另跑单文件 3 次与两个故障注入副本对照退出码
      result: passed
      coverage: 覆盖「同样网络条件（含本机代理）下 yarn check 能终止」与「失败时退出码非 0 且原因可见」两点；nativeWindowsTested=false，Windows 侧未验证
    createdAt: 2026-09-21T10:19:35.991Z
  - id: ver-hang-ac3
    kind: verification
    content: ac3 通过。新增回归用例 tests/project-bootstrap-network-hang.test.mjs（恒过）：fixture 的断连信号（never promise）永不 resolve，复刻旧代码卡死的形状，断言有界等待在 1500ms 内以 'the clone transport stayed open after the client stopped' 失败——证明传输泄漏时进程限时结算而不是无限等待；该文件实测 2 秒 EXIT=0、1/1 通过。另有临时泄漏探针（同样永不 resolve，作为真实失败运行）实测 EXIT=1、2 秒退出并如实报 'the clone transport stayed open for more than 1500ms after the client stopped'；克隆根本无法启动的场景（runGit 抛 'git is unavailable'）也限时失败并完成回滚。
    basis: observation
    verification:
      criterionId: ac3
      criterionVersion: 1
      method: 构造两种故障 fixture（断连信号缺失、clone 抛错）运行 node --test 并测耗时与退出码；随后把泄漏场景固化为恒过的回归用例纳入 tests/*.test.mjs
      result: passed
      coverage: 覆盖「传输泄漏/断连不可观测」与「克隆直接失败」两类；真实断网（DNS/连接被拒）未单独构造，但失败路径与 clone 抛错用例同构
    createdAt: 2026-09-21T10:19:35.991Z
  - id: decision-hang-fix
    kind: decision
    content: 修复定性：这不是产品传输泄漏。产品在 abort 后 10ms 内以 AbortError 结束并 kill git 进程组；不可观测的断连来自用户级 git http.proxy（ClashX 127.0.0.1:7890）劫持 loopback 并保持连接，加上测试用无界 await 等待服务器探测。故修复选择「测试侧隔离 git 配置 + 有界等待 + finally 兜底清理」，不改产品代码（符合任务约束「只改测试与必要的清理逻辑」）。隔离使用 GIT_CONFIG_GLOBAL=/dev/null 与 GIT_CONFIG_SYSTEM=/dev/null，仅在未设置时生效且作用于测试进程；已知副作用是 fixture 的 git 不再读取用户/系统配置（本测试不依赖 init.defaultBranch、safe.directory 等）。
    basis: observation
    reason: 用实测证据区分产品缺陷与环境/测试缺陷，避免误改产品行为或靠放宽 timeout 掩盖
    createdAt: 2026-09-21T10:19:35.991Z
  - id: completion-hang-fix
    kind: completion
    content: 三项验收标准均已通过并留证：ac1 证据链（ver-hang-ac1）、ac2 npm run/yarn check 限时终止且退出码如实（ver-hang-ac2）、ac3 回归验证（ver-hang-ac3）。交付物为测试修复提交 216d4e4（两个测试文件），未改产品代码、未放宽 timeout。剩余局限已在 summary/questions 中列出：Windows 未验证（nativeWindowsTested=false）、真实 DNS 断网未单独构造。
    basis: observation
    verificationEntryIds:
      - ver-hang-ac1
      - ver-hang-ac2
      - ver-hang-ac3
    createdAt: 2026-09-21T10:19:35.991Z
  - id: progress-hang-push
    kind: progress
    content: 推送完成：修复提交 216d4e4 已按用户明确要求推送到 origin（https://github.com/admintertar/dsh-project-desktop.git）的 master：`412304d..216d4e4  master -> master`，git ls-remote 确认 refs/heads/master = 216d4e414c038544214c29bcd7000c8630184d7c，本地 HEAD 相同、工作区无未推送提交。推送目标为自有壳仓库，未触及上游 anywhere-labs/dsh-desktop；本次推送仅含 2 个测试文件，Yarn 迁移（task-18bf5992）的未提交改动未混入。
    basis: observation
    createdAt: 2026-09-21T10:20:48.246Z
operations:
  ddfd11bd800eb943aa4886184dd2ce82c86e5874996fa838c79fafd7d71a817b:
    fingerprint: bf494ed6d405d3ca9606e1e6fde5a85eec5698e09f28efa750222d52964c4ccc
    kind: create
    at: 2026-09-21T10:00:05.786Z
    entryIds:
      - inv-hang-1
      - inv-hang-2
      - inv-hang-3
  0ba770921122dd2146c092af00f9942a10b1ea06911a66303ce387c1c925d63f:
    fingerprint: 0efd1bc8b9659dbc9797e664c4ac2cf7aafbe2ca51180d10a00b7b941c6b7ad2
    kind: update
    at: 2026-09-21T10:01:24.570Z
    entryIds:
      - ver-hang-ac1
  aa21150afeb12a1874c43bc17b74362852910e0e008f47272eaa52e1cd33f006:
    fingerprint: 70d72621bf4d3cf36254e57146533b22f75eebdf15f2fa3b2499f57ae028af2a
    kind: update
    at: 2026-09-21T10:19:35.991Z
    entryIds:
      - ver-hang-ac2
      - ver-hang-ac3
      - decision-hang-fix
      - completion-hang-fix
  dacbb63ac188c3243ac7362c93a4d71e7e0f7af7dea180eb32ca19e151972e3e:
    fingerprint: d7aa9917cf643911fb1432671f4f9f069683e9ec708a6f18225782aafd5fb649
    kind: update
    at: 2026-09-21T10:20:48.246Z
    entryIds:
      - progress-hang-push
criterionVersions:
  ac1: 1
  ac2: 1
  ac3: 1
---

已修复并验证：壳测试 project-bootstrap-network.test.mjs 失败后不退出导致 yarn check 永久挂起的缺陷（提交 216d4e4）。根因不是产品传输泄漏——abort 后产品 10ms 内以 AbortError 结束并 kill git 进程组，而是测试用无界 `await f.disconnected` 等待服务器探测断连，而本机用户级 git http.proxy=http://127.0.0.1:7890（ClashX）劫持了测试重定向到 127.0.0.1 的 clone 并保持连接（abort 后 4 秒 TCP 仍 ESTABLISHED），加上超时后 finally 无兜底执行，server 与 socket 被一直持有，node --test 不退出。修复：测试进程隔离 GIT_CONFIG_GLOBAL/GIT_CONFIG_SYSTEM（仅未设置时生效）、所有等待改为有界（within）、每个 finally 先 abort/release 再有界结算并 cleanup；新增 tests/project-bootstrap-network-hang.test.mjs 回归守卫（断连信号永不出现时 1500ms 有界报告、恒过）。验证：yarn check 18 秒 EXIT=0（此前 90s alarm 强杀 EXIT=142）；单文件 3 次 1-2 秒 EXIT=0；故障注入 EXIT=1 且 1 秒内退出并如实报错；泄漏探针 2 秒内 EXIT=1 报「transport stayed open」。未改产品代码、未放宽任何 timeout。局限：Windows 未验证（nativeWindowsTested=false）；真实 DNS 断网未单独构造。
