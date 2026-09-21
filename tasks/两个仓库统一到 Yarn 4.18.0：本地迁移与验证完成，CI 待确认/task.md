---
schemaVersion: 3
directory: 两个仓库统一到 Yarn 4.18.0：本地迁移与验证完成，CI 待确认
id: task-18bf5992-805a-4bd8-9514-8ecef5f1ac55
title: 两个仓库统一到 Yarn 4.18.0：本地迁移与验证完成，CI 待确认
objective: "把 resources/dsh-plugin-project 与 resources/dsh-project-desktop 的仓库层包管理器从 npm 统一为 Yarn 4.18.0，与官方 Desktop 外层工具链（dsh-desktop-source 根 package.json 的 packageManager: yarn@4.18.0）一致；本地 install/setup/check 验证通过，CI 工作流与文档迁移在用户确认后进行。"
status: completed
createdAt: 2026-09-21T10:01:17.775Z
updatedAt: 2026-09-21T11:15:27.487Z
artifacts:
  - type: file
    path: artifacts/plugin-yarn-install.log
    description: plugin corepack yarn install 输出（EXIT=0）
  - type: file
    path: artifacts/plugin-yarn-check.log
    description: plugin corepack yarn check（typecheck+test+build）全绿输出
  - type: file
    path: artifacts/desktop-yarn-check.log
    description: desktop corepack yarn check：verify:upstream 与 build 通过，project-bootstrap-network 两个用例超时
  - type: file
    path: artifacts/desktop-verify-stages.log
    description: desktop 排除既有挂起文件后各阶段重跑：82 ok / 0 failed，recovery/safe-mode/project-files/smoke:host 全 EXIT=0
  - type: file
    path: artifacts/plugin-runtime-yarn-setup.log
    description: 用 yarn 逻辑重建 .dev/runtime 的 setup 输出（275 个官方包，npm 独有包缺失=0）
  - type: file
    path: artifacts/plugin-check-after-runtime.log
    description: 重建运行时后的 plugin yarn check 回归（EXIT=0）
  - type: file
    path: artifacts/desktop-check-via-compat.log
    description: 通过 yarn run test:desktop 跑完整 Shell check：78 pass / 0 fail，含 recovery、safe-mode 与 smoke:host，总 EXIT=0
archived: false
phase: implementation
brief:
  currentBehavior: 两个仓库仓库层使用 npm（package-lock.json；plugin node_modules 90M、desktop 43M）。官方 Desktop 源码快照外层用 Yarn 4.18.0（.yarnrc.yml 用 nodeLinker=node-modules），其内层 deepseek-harness 用 pnpm；我们的运行时开发 Profile 已用 pnpm 11.8.0（nodeLinker=hoisted）。迁移后仓库层统一为 Yarn 4.18.0。
  scope: 两个仓库的 package.json（packageManager / dependenciesMeta / 脚本）、新增 .yarnrc.yml、.gitignore，yarn.lock 取代 package-lock.json。
  constraints:
    - nodeLinker 必须是 node-modules：scripts/package-dependencies.mjs 复用官方 app-builder-lib 的 TraversalNodeModulesCollector 遍历物理 node_modules 树，符号链接布局会破坏依赖收集。
    - "enableScripts: false 配合 dependenciesMeta.built 白名单（plugin: esbuild+fsevents；desktop: esbuild），与官方 .yarnrc.yml 模式一致。"
    - 不修改官方源码快照，不改变 Profile 层 pnpm 机制，不执行 corepack enable 修改全局环境。
    - README 的 install → setup → check 流程必须保持：setup.mjs 会把 node_modules/@deepseek-ai 变成指向 .dev/runtime 的符号链接。
  outOfScope:
    - CI 三个工作流（package.yml / guide-windows.yml / resources-windows.yml）的 npm→yarn 迁移：待用户确认。
    - README/docs 中 npm 命令文案：待确认。
    - plugin 代码内硬编码的 npm 调用（scripts/setup.mjs:47 安装 .dev/runtime、scripts/check-compatibility.mjs:10）。
    - 运行时 Profile 的 pnpm 与 recovery 测试的 pnpm store 校验：不属于仓库层。
    - corepack enable 启用全局 yarn 4：需用户决定。
  acceptanceCriteria:
    - id: ac1
      text: "两个仓库声明 packageManager: yarn@4.18.0 且 .yarnrc.yml 设置 nodeLinker: node-modules"
      required: true
      version: 1
    - id: ac2
      text: dsh-plugin-project 的 yarn check（typecheck+test+build）在 Yarn 4 下通过
      required: true
      version: 1
    - id: ac3
      text: dsh-project-desktop 的 verify:upstream、build、测试、recovery、safe-mode、project-files、smoke:host 在 Yarn 4 下通过（project-bootstrap-network.test.mjs 为已登记既有缺陷）
      required: true
      version: 1
    - id: ac4
      text: CI 三个工作流迁移到 corepack / yarn install --immutable 并通过（待用户确认后进行）
      required: true
      version: 1
handoff:
  nextSteps:
    - 把 README.md、README.en.md 与 docs/*.md 中约 20 处 npm 命令文案改为 yarn run（本次未做）。
    - 决定是否执行 corepack enable：本地 yarn 仍为 Classic 1.22.22，日常需用 corepack yarn 或启用 shim。
    - plugin 新增的 scripts/smoke-environment.mjs 属防御性改动（未修复 Windows 失败），建议保留。
    - plugin 的 native-resource-state-checks.mjs（d3126c9）在 Windows CI 仍失败，属 task-80df9054 范畴。
references: []
entries:
  - id: e1
    kind: progress
    content: 排查结论：仓库层用 npm，官方外层用 Yarn 4.18.0，官方内层 deepseek-harness 与我们的运行时 Profile 用 pnpm。打包兼容性上 Yarn 的 nodeLinker=node-modules 与 pnpm 的 node-linker=hoisted 对称，均保留物理扁平 node_modules。
    basis: observation
    createdAt: 2026-09-21T10:01:17.775Z
  - id: e2
    kind: decision
    content: 选择 Yarn 4.18.0 而非 pnpm：与官方外层一致，CI 已存在 corepack enable，且两仓库无原生模块耦合（根 package.json 无 fs-ext/node-pty），仅 esbuild/fsevents 需要构建白名单。
    basis: user-request
    reason: 用户明确选择「按排查结论统一到 Yarn 4.18.0」
    createdAt: 2026-09-21T10:01:17.775Z
  - id: e3
    kind: progress
    content: 迁移踩坑记录：删除 node_modules 后只跑 install，tsc 会报大量 Cannot find module '@deepseek-ai/dsh-*'。根因是这些官方包由 scripts/setup.mjs:64 建立的符号链接 node_modules/@deepseek-ai -> .dev/runtime/node_modules/@deepseek-ai 提供，不是 npm/yarn 安装的；补跑 setup 后恢复（245 个包）。
    basis: observation
    createdAt: 2026-09-21T10:01:17.775Z
  - id: e4
    kind: verification
    content: plugin 验证：yarn install EXIT=0；setup EXIT=0；yarn check EXIT=0 全绿。另实测重跑 yarn install 不会破坏 setup 的符号链接（仍为链接、245 包可见）。
    basis: observation
    verification:
      criterionId: ac2
      criterionVersion: 1
      method: corepack yarn check（/tmp/yarn-plugin-check2.log）
      result: passed
      coverage: typecheck + test + build 全阶段
    createdAt: 2026-09-21T10:01:17.775Z
  - id: e5
    kind: verification
    content: desktop 验证：yarn install EXIT=0；verify:upstream 与 build 通过；测试 82 ok / 0 failed；test:recovery、test:safe-mode、check-project-files、smoke:host 全部 EXIT=0。打包依赖收集（TraversalNodeModulesCollector 的 manual traversal）在 Yarn 布局下通过。
    basis: observation
    verification:
      criterionId: ac3
      criterionVersion: 1
      method: corepack yarn check 及各阶段单独重跑（/tmp/yarn-desktop-check.log、/tmp/desktop-verify.log）
      result: passed
      coverage: 除 project-bootstrap-network.test.mjs 外全部阶段
    createdAt: 2026-09-21T10:01:17.775Z
  - id: e6
    kind: progress
    content: 既有缺陷确认（非迁移引入）：tests/project-bootstrap-network.test.mjs 的 loopback Git fixture 在本机挂起。docs/validation.md:437-440 已记载 pristine HEAD 同样挂起；单独复现被 75s 硬超时杀掉（EXIT=142）；该缺陷已由 task-bf50c979 独立登记。
    basis: observation
    createdAt: 2026-09-21T10:01:17.775Z
  - id: e7
    kind: progress
    content: 验证日志已归档为附件：plugin install/check、desktop check、desktop 分阶段重跑。ac1/ac2/ac3 均有可复查证据；ac4（CI）未开始，等用户确认。
    basis: observation
    createdAt: 2026-09-21T10:01:26.007Z
  - id: e8
    kind: progress
    content: "CI 已迁移：.github/workflows/ 三个文件（package.yml、guide-windows.yml、resources-windows.yml）移除 setup-node 的 cache: npm；两处 npm ci → corepack yarn install --immutable；npm run setup/check/build/smoke:* → corepack yarn run …；yarn 缓存 key 改为 hashFiles 三个 lockfile。验证：无 npm 残留、三份 YAML 均解析通过、两仓库 --immutable install 均 EXIT=0。"
    basis: user-request
    createdAt: 2026-09-21T10:08:36.653Z
  - id: e9
    kind: progress
    content: Yarn 版本结论：@yarnpkg/cli-dist 的 latest 即 4.18.0（2026-07-29），也是最新一个 4.x，与官方 pin 一致，无需升级。
    basis: observation
    createdAt: 2026-09-21T10:08:36.653Z
  - id: e10
    kind: progress
    content: CI 生效的硬前提（阻塞 ac4 的验证）：workflow 从 upstream.lock.json 的 project_commit=800cc4d3 checkout 插件，该提交只有 package-lock.json。必须先 push 插件（含 yarn.lock/packageManager）→ bump lock 的 project.commit 与 tree → 再 push 壳，否则 CI 的 corepack yarn install --immutable 在插件目录必定失败。未获 push 授权，本轮不执行。
    basis: observation
    createdAt: 2026-09-21T10:08:36.653Z
  - id: e11
    kind: progress
    content: --immutable 警告（YN0002）：两仓库均报告传递 peerDependencies 未被提供（插件 16 项 @deepseek-ai/*，壳 1 项 react）。不影响 install 退出码，运行时由 setup 的符号链接补齐；迁移后新增的噪音，已记录。
    basis: observation
    createdAt: 2026-09-21T10:08:36.653Z
  - id: e12
    kind: progress
    content: 代码内 npm 调用已清除：setup.mjs 的 .dev/runtime 安装改为 corepack yarn install（overrides→resolutions、265 个 tarball 全部作为直接依赖、补 @deepseek-ai/cordis-plugin-group@1.0.2、空 yarn.lock 声明项目边界、.yarnrc.yml 固定 nodeLinker=node-modules + enableScripts=false）；check-compatibility.mjs 改为通过 corepack 调用 yarn；同步 start.mjs、project-shell-development.ts 文案与其测试断言、desktop.integration.ts 文案。scripts/ 与 src/ 已无 npm 调用。
    basis: user-request
    createdAt: 2026-09-21T10:21:33.273Z
  - id: e13
    kind: decision
    content: 两个关键发现：(1) Yarn 4 从最近 lockfile 推断项目边界，.dev/runtime 需一个空 yarn.lock 才不会被视为插件的未声明 workspace；(2) Yarn 4 把字面 “--” 转发给脚本（npm 会吞掉），导致 parseArgs 把 --desktop-source 当作位置参数——已让 setup.mjs/check-compatibility.mjs 过滤 “--”，同时 CI 的 corepack yarn run setup -- … 能正常工作。
    basis: observation
    createdAt: 2026-09-21T10:21:33.273Z
  - id: e14
    kind: verification
    content: 运行时重建验证：yarn 版 .dev/runtime 得到 275 个 @deepseek-ai 包（npm 版 245），npm 独有的包缺失数为 0，cordis-plugin-group=1.0.2 到位，符号链接恢复正常。
    basis: observation
    verification:
      criterionId: ac2
      criterionVersion: 1
      method: corepack yarn run setup 重建 + 包集合 diff（artifacts/plugin-runtime-yarn-setup.log）
      result: passed
      coverage: 依赖完整性与符号链接
    createdAt: 2026-09-21T10:21:33.273Z
  - id: e15
    kind: verification
    content: 端到端回归：重建后 plugin yarn check EXIT=0；corepack yarn run test:desktop -- ../dsh-project-desktop 完整跑完 Shell check，78 pass / 0 fail（含 recovery 7、safe-mode 1、smoke:host），总 EXIT=0。本次 project-bootstrap-network 也通过，进一步证明其挂起是 intermittent。
    basis: observation
    verification:
      criterionId: ac3
      criterionVersion: 1
      method: corepack yarn check + corepack yarn run test:desktop（artifacts/plugin-check-after-runtime.log、artifacts/desktop-check-via-compat.log）
      result: passed
      coverage: plugin 与 shell 双仓库
    createdAt: 2026-09-21T10:21:33.273Z
  - id: e16
    kind: progress
    content: "已提交并推送：plugin c830a46（chore: 统一包管理器到 Yarn 4.18.0）、shell cf20264（含 CI 迁移、pin bump、version 0.1.3）。已创建并推送 tag v0.1.3（指向 cf20264），触发 Package Desktop 工作流。"
    basis: user-request
    createdAt: 2026-09-21T10:26:16.891Z
  - id: e17
    kind: decision
    content: 发布前发现并修复了 5 处 Yarn 4 “--” 参数解析缺陷（npm 吞掉 “--”、Yarn 4 原样转发）：shell/setup.mjs（CI 直接调用，阻塞发布）、plugin/setup.mjs、plugin/desktop.ts、plugin/start.mjs、shell/setup-electron.mjs、shell/sign-macos.mjs；全部改为过滤 “--”，使带与不带 “--” 两种写法都可用。
    basis: observation
    createdAt: 2026-09-21T10:26:16.891Z
  - id: e18
    kind: verification
    content: 发布前回归：plugin yarn check EXIT=0；shell yarn check（verify:upstream + build + test + recovery + safe-mode + project-files + smoke:host）EXIT=0；重导快照后 verify:upstream 确认 “Official stable source intact”。CI 已启动：Package Desktop（v0.1.3）queued，Guide/Resources Windows 由 master push 触发。
    basis: observation
    verification:
      criterionId: ac4
      criterionVersion: 1
      method: corepack yarn check（两仓库）+ GitHub Actions API 查询
      result: passed
      coverage: 发布候选状态与 CI 触发
    createdAt: 2026-09-21T10:26:16.891Z
  - id: e19
    kind: decision
    content: Windows smoke:updates 根因定位（与包管理器迁移无关）：native-update-case.mjs 英文主题下载段落把下载完成对话框写成 choose(0)。该对话框在 Windows 上是 [重启并安装, 稍后]（project-updates.mjs:127），索引 0 会启动安装程序：install() → app.quit() → main.mjs 的 before-quit 中 workspace.shutdown() 关闭全部项目 Host，紧接着同一用例对已关闭 Host 调用 selectTheme，报 “DSH Host channel closed”。macOS 同一对话框只有一个确定按钮，所以该写法在 macOS 上无害。
    basis: observation
    createdAt: 2026-09-21T11:15:27.487Z
  - id: e20
    kind: progress
    content: 两个被证伪的假设（记录以避免重走）：5e1e7e8 为 GUI 子进程剔除包管理器启动器环境（BERRY_BIN_FOLDER/npm_execpath/PATH）后 Windows 仍稳定失败；setup.mjs 排除 yarn 记账文件的过滤修复同样无效。真正根因是 UI 测试选错对话框按钮。
    basis: observation
    createdAt: 2026-09-21T11:15:27.487Z
  - id: e21
    kind: progress
    content: 该失败为何此时才暴露：那段英文下载用例是 v0.1.2 之后新增的（git diff v0.1.2 HEAD 显示 +56 行），而 master push 不触发 package.yml，只有 tag 才触发，所以直到发布 v0.1.3 才第一次在 Windows 上执行到它。
    basis: observation
    createdAt: 2026-09-21T11:15:27.487Z
  - id: e22
    kind: decision
    content: "修复：e33ac4e 将该处改为与同文件 line 139/200 一致的 choose(darwin ? 0 : 1)；本地 macOS smoke:updates 仍 EXIT=0（ok:true）后，删除并重推 tag v0.1.3。"
    basis: observation
    createdAt: 2026-09-21T11:15:27.487Z
  - id: e23
    kind: verification
    content: 发布成功：CI run 35590957271 completed/success，plan、Package mac-universal、Package win-x64、Verify universal DMG on Intel、Publish verified release 全部 success。GitHub Release v0.1.3 已发布（draft=false, prerelease=false, published=2026-09-21T11:13:45Z，7 个资产：mac-universal.dmg 290.7MB、win-x64-Setup.exe 138.3MB、win-x64-Portable.zip 222.5MB 及三个 sha256 与 update.json）。
    basis: observation
    verification:
      criterionId: ac4
      criterionVersion: 1
      method: GitHub Actions API 查询 run 35590957271 与 releases/tags/v0.1.3
      result: passed
      coverage: 两个仓库 CI 迁移 + 完整发布链路
    createdAt: 2026-09-21T11:15:27.487Z
  - id: e26
    kind: verification
    content: "ac1 核实：dsh-plugin-project 与 dsh-project-desktop 的 package.json 均为 packageManager: yarn@4.18.0，.yarnrc.yml 均为 nodeLinker: node-modules + enableScripts: false，yarn.lock 存在，package-lock.json 已删除。"
    basis: observation
    verification:
      criterionId: ac1
      criterionVersion: 1
      method: 读取两仓库 package.json / .yarnrc.yml 并确认 lockfile 存在性
      result: passed
      coverage: 两个仓库的包管理器声明与 linker 配置
    createdAt: 2026-09-21T11:15:27.487Z
  - id: e24
    kind: completion
    content: 目标完成：四项验收标准均有可复查证据——ac1（e26）、ac2（e14）、ac3（e15）、ac4（e23）。
    basis: observation
    verificationEntryIds:
      - e26
      - e14
      - e15
      - e23
    createdAt: 2026-09-21T11:15:27.487Z
operations:
  ac7341d40c26f594b54e18f84469c3c7deda5fbd16e2716e56d8cdfadaeecfdc:
    fingerprint: b8f7ff6f69f266cabb0d3e9afa9821c26e9f30d706a87d467c90704f4ab3dc8a
    kind: create
    at: 2026-09-21T10:01:17.775Z
    entryIds:
      - e1
      - e2
      - e3
      - e4
      - e5
      - e6
  bf380306431f11eb6ec3fc3492aa1426176b9ac99b9d8a7cfe5c9f58765e3e15:
    fingerprint: 7f24c36ab3b450b9a6231e6f43077d15bbad31e84444653c823444e67278b77a
    kind: update
    at: 2026-09-21T10:01:26.007Z
    entryIds:
      - e7
  44b02d3e9db301765af4d3c19da0e64802bba566f8e407d7b93a5f6300964459:
    fingerprint: 2193c2d83fe90563033c1eb214861be13294d04eb14b0480aad62d628ba3012b
    kind: update
    at: 2026-09-21T10:08:36.653Z
    entryIds:
      - e8
      - e9
      - e10
      - e11
  83ab9aae0174ae3a42b3ab63b11127c5721799a73451709a100174750daff277:
    fingerprint: 7472bca93422de915d0198a472a20a236f255380bd1deb23333e088966df00ae
    kind: update
    at: 2026-09-21T10:21:33.273Z
    entryIds:
      - e12
      - e13
      - e14
      - e15
  01d763dc8f91aa092e69e7cd37f8b605a88c44916875bb5cb08826c99f5da125:
    fingerprint: 961feeea64d95e724eae868a65cbbabaa4129f7f0713e069784959446a384660
    kind: update
    at: 2026-09-21T10:26:16.891Z
    entryIds:
      - e16
      - e17
      - e18
  1fb31c8f4265139708ca22398d5ff78fe26986c0e81205970dee852e33e839b6:
    fingerprint: 672d0c216c9497154caa580d6ca5ff546a05b87189bf79348db93e0d115d9d53
    kind: update
    at: 2026-09-21T11:15:27.487Z
    entryIds:
      - e19
      - e20
      - e21
      - e22
      - e23
      - e26
      - e24
criterionVersions:
  ac1: 1
  ac2: 1
  ac3: 1
  ac4: 1
---

两个仓库的仓库层包管理器已统一到 Yarn 4.18.0（package-lock.json → yarn.lock，.yarnrc.yml 用 nodeLinker=node-modules，enableScripts=false + dependenciesMeta 白名单；代码内 npm 调用改为 corepack；CI 三个工作流迁移到 yarn install --immutable），并成功发布 GitHub Release v0.1.3（mac universal DMG、win x64 Setup 与 Portable ZIP、三个 sha256 与 update.json，共 7 个资产）。阻塞发布的 Windows smoke:updates 失败经定位为 native-update-case.mjs 中一行未做平台区分的对话框按钮索引（v0.1.2 之后新增、从未在 Windows CI 跑过），与包管理器迁移无关，已由 e33ac4e 修复。遗留：README/docs 的 npm 文案尚未改写；全局 corepack enable 未执行。
