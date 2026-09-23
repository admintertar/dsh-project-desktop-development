---
schemaVersion: 3
directory: Windows 实机验证：打开探测、克隆导入与目录记忆
id: task-7af5d595-cad0-4494-bc80-ccd37002512f
title: Windows 实机验证：打开探测、克隆导入与目录记忆
objective: 在真实 Windows 上验证 task-7be557ec 的三块改动并给出平台结论：(1)「打开」在 Windows 上退化为文件夹选择器时的行为——唯一入口直接打开、没有入口给出本地化提示、多个入口补一次只选文件的对话框；(2)「克隆仓库」导入事务在 Windows 上的端到端表现——目标路径分隔符与文件夹名校验、成功打开、非项目回滚、私有仓库凭据；(3) 目录记忆在 Windows 上生效（Windows 走 browse 后端落到壳的 pickDirectory）。本轮只做验证与记录，不在 Windows 上顺手改代码；发现缺陷另开任务。
status: completed
createdAt: 2026-09-23T08:07:16.828Z
updatedAt: 2026-09-23T13:04:31.117Z
artifacts:
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: d6da5b6951b35e5033f79bfaebda3980f6a5fe61
    description: 待验证的壳仓库提交（打开探测、克隆导入、目录记忆、focused 扩展），尚未 push
  - type: file
    path: artifacts/windows-verification.md
    description: Windows 实机验证报告（第 5 节 D1 修复与重跑、第 6 节手工验收、第 7 节 W6 本轮不做）
  - type: commit
    repository: https://github.com/admintertar/dsh-project-desktop.git
    commit: ee21ec2825c0f06902ffd181ccdf25b8a212b0bd
    description: D1 修复（只改验证脚本：与 closed 竞争后再等待），修复后 Windows 上 smoke:guide:focused / smoke:resources / 两侧 yarn check 全部 EXIT=0
archived: false
phase: validation
brief:
  currentBehavior: 已在真实 Windows（NT 10.0.26200 / AMD64、Node 22.23.2、Windows PowerShell 5.1）上执行验证，被测是工作树干净的 2bad7f3（含 d6da5b6 的改动）。前置修复：.upstream/project 曾是落后一个提交的陈旧快照（实测 tree 880e45f8 = 插件 dd85e1a），verify:upstream 直接失败；按 lock 的 5193e81 重导并先校验 tree = dcd0f0e8 后再替换。结果：W1 通过（yarn check EXIT=0，125+7+1，smoke:host 也过）；W2 通过（yarn smoke:resources EXIT=0，win32 专有目录记忆断言全跑：第一次无 defaultPath、第二次等于上次选中目录，userData 落盘 last-directories.json）；W5 通过（导入目录预填与 last-directories.json 的 import 键）；W3/W4 部分通过（唯一入口文件夹、空文件夹本地化文案、导入弹窗端到端 9 项 PASS 已实机确认；「多个 .agent-project 补选文件」分支挂死，非项目回滚与私有凭据未走到）；W6 无法验证（注册表无 .agent-project 关联、未安装带关联的候选构建）。缺陷 D1（未修，阻塞自动验证）：多入口补选分支里 open() 已调用、窗口随后消失但 'closed' 不到达调用方，yarn smoke:guide:focused 因此挂死而非失败（复现 3 次），其后置的导入断言永不执行，CI 只能被 job timeout 杀掉。
  scope: resources/dsh-project-desktop 的 Windows 路径：src/windows/guide-window.mjs（open 退化与补选文件、import-* 、browse-import-directory）、src/app/main.mjs（pickOpen）、src/app/repository-import.mjs、src/app/last-directories.mjs、src/desktop-adapter/native.mjs（pickDirectory 记忆）、scripts/native-guide-checks.mjs 与 scripts/native-resource-state-checks.mjs、.github/workflows/guide-windows.yml 与 resources-windows.yml。
  constraints:
    - 本机只有 macOS arm64，Windows 行为只能由 Windows 实机或 windows-2022 runner 给出结论
    - 不改官方快照、不改动运行中的 Profile；验证阶段只跑命令与人为操作，发现问题另开任务或回退源任务
    - Windows 上需先 git config core.autocrlf false、core.longpaths true（两个 workflow 已设置），长路径与 CRLF 会直接影响构建与断言
    - 验证证据只落 tasks/<任务>/artifacts/ 的结论级文件，运行期目录一律放 %TEMP% 或 .runtime/
  outOfScope:
    - 修复在 Windows 上发现的缺陷（除非用户另行要求；发现后先在 src/desktop-adapter/native.mjs 等位置记录复现与证据）
    - Linux 实机验证
    - 发布、打包产物验收与 pin bump
  acceptanceCriteria:
    - id: W1
      text: 在 Windows 上 yarn run check 通过（125 + 7 + 1），无平台专有失败
      required: true
      version: 1
    - id: W2
      text: 在 Windows 上 yarn run smoke:resources 通过，含新增断言：资源页第一次目录选择器无 defaultPath、第二次的 defaultPath 等于上次选中的目录
      required: true
      version: 2
    - id: W3
      text: 欢迎窗口「打开」在 Windows 上只弹出文件夹选择器：含唯一 .agent-project 的文件夹直接打开；空文件夹显示「不是 agent-project 项目」；含多个 .agent-project 的文件夹补一次只选文件的对话框，取消则无动作、不报错
      required: true
      version: 1
    - id: W4
      text: 克隆导入弹窗在 Windows 上端到端：公开仓库克隆后文件夹名自动推导、目标出现 <name>.agent-project 并直接打开；非 agent-project 仓库提示后回滚删除；私有仓库弹出凭据弹窗
      required: true
      version: 1
    - id: W5
      text: 导入目录记忆在 Windows 上生效：选定父目录并导入后，关闭再打开弹窗预填该目录；userData 下生成 last-directories.json
      required: true
      version: 1
    - id: W7
      text: 决定是否把 checkRepositoryImport 加进 --focused（已决定加进，并在 Windows 实机跑通）
      required: false
      version: 2
questions:
  - W6 已按你的决定移出本任务验收标准；将来做了文件关联后，需要另开一次双击验收（步骤已留在报告第七节）。
handoff:
  nextSteps:
    - 推送已完成：壳仓库 master 已与 origin/master 一致（74a82e6，包含 D1 修复 ee21ec2）；无待推送提交。
    - CI 已验证：Guide on Windows run 35863134305 与 Resources on Windows run 35863134327 在 74a82e6 上均 success（修复前 2bad7f30 的两次为 cancelled）。
    - 遗留（已不在本任务验收标准内）：W6 双击 .agent-project 需先给候选构建带上文件关联，再双击验证 second-instance 转发（报告第七节与 w17）。
    - 环境提醒：只要 .upstream/project 不是从 lock 的 commit 导出，verify:upstream 就会失败；重导方法见 artifacts/windows-verification.md 第一节（先导出到 %TEMP% 校验 tree 再替换）。
    - 工具提醒：后台作业里的 Electron 探针不要写 stdout（未排空管道会 EPIPE 并卡死主进程）；只落盘 .runtime/*.trace。
    - 工作方式约定：修改产品代码（src/ 等）时开独立 git worktree（见 memory/worktree-for-product-code.md）。
  readBefore:
    - windows-verification
  verifyBefore:
    - cd resources/dsh-project-desktop && yarn check
    - cd resources/dsh-project-desktop && yarn smoke:resources
    - cd resources/dsh-project-desktop && yarn smoke:guide:focused
references:
  - id: source-task
    label: 源任务：欢迎窗口打开/克隆导入 + 目录记忆（macOS 已验证）
    type: task
    taskId: task-7be557ec-45bc-48a2-a111-1d3f62b12c8d
  - id: guide-window
    label: 欢迎窗口：open 退化与补选文件、import-*、browse-import-directory
    type: file
    path: resources/dsh-project-desktop/src/windows/guide-window.mjs
  - id: last-directories
    label: 目录记忆（import / resource 两个键）
    type: file
    path: resources/dsh-project-desktop/src/app/last-directories.mjs
  - id: native
    label: 项目内目录选择（资源页/重定位/技能导入）的落脚点
    type: file
    path: resources/dsh-project-desktop/src/desktop-adapter/native.mjs
  - id: guide-windows
    label: CI：windows-2022 跑 smoke:guide:focused（已包含 checkRepositoryImport）
    type: file
    path: resources/dsh-project-desktop/.github/workflows/guide-windows.yml
  - id: resources-windows
    label: CI：windows-2022 跑 smoke:resources（含新增目录记忆断言）
    type: file
    path: resources/dsh-project-desktop/.github/workflows/resources-windows.yml
  - id: windows-verification
    label: Windows 实机验证报告与证据清单
    type: file
    path: tasks/Windows 实机验证：打开探测、克隆导入与目录记忆/artifacts/windows-verification.md
  - id: defect-d1
    label: 缺陷 D1：多 .agent-project 文件夹的 Windows 补选分支挂死（根因已确认）
    type: note
    text: 根因（实机确认）：对「在本次调用过程中被关闭的窗口」调 webContents.executeJavaScript，Promise 永不 settle。scripts/native-guide-checks.mjs:343 的 await clickOpen(window) 正好命中：引导窗口处理完 open 后会在 setImmediate 里 window.close()（src/windows/guide-window.mjs:258），应答还没送出窗口就没了。表现：yarn smoke:guide:focused 在 Windows 上挂死而非失败（主进程存活、心跳继续、断言永不继续），CI 只能被 job timeout 杀掉，且 checkRepositoryImport 里排在后面的导入断言永不执行。修法：第 343 行改用 Promise.race([ambiguousOpened, clickOpen(window)]) 或复用同文件第 15-25 行的 clickAndWaitForClose。macOS 不走补选分支（第 336-339 行只报错不关窗），所以从未暴露。
entries:
  - id: w1
    kind: progress
    content: 任务建立时的事实：(1) 源改动全部只在工作树，未提交、未 push，因此 CI/实机验证前必须先让改动可用（推荐：提交并 push 到 master，两个 Windows workflow 的 paths 均覆盖本次改动文件）；(2) guide-windows.yml 跑的是 corepack yarn run smoke:guide:focused，而 focused 只执行 checkGuide（scripts/native-guide-case.mjs:24），不包含 checkRepositoryImport，所以欢迎窗口的文件夹探测、多项目补选与导入目录预填在 Windows CI 上当前无覆盖；(3) resources-windows.yml 跑 corepack yarn run smoke:resources（native-resource-state-checks.mjs），该 job 的 paths 包含 src/app/**、src/desktop-adapter/** 与该脚本，因此本轮改动会触发它，新增的目录记忆断言（第一次无 defaultPath、第二次等于上次选中的目录）会在 Windows 上自动执行。
    basis: observation
    createdAt: 2026-09-23T08:07:16.828Z
  - id: w2
    kind: progress
    content: 任务分两阶段：先在 Windows 上跑自动部分（yarn run check + smoke:resources + 完整 smoke:guide），再按 W3–W6 做手工界面验收。smoke:guide 完整模式里的 checkGuideFrame 依赖 OS 前台焦点（Windows runner 不可靠，因此 CI 只跑 focused），实机上若因焦点失败需区分环境干扰与真回归。
    basis: observation
    createdAt: 2026-09-23T08:07:16.828Z
  - id: w3
    kind: progress
    content: 已把 checkRepositoryImport 加入 smoke:guide 的 --focused 集合（scripts/native-guide-case.mjs）：focused 分支现在先跑 checkRepositoryImport 再跑 checkGuide，checks 列表为 ['open-folder-and-repository-import','create-guide-project-path-preview-separator']，并更新了文件头对 focused 范围的注释。本机验证：yarn run smoke:guide:focused EXIT=0（.runtime/guide-frame-45Ezrx）。该脚本在 guide-windows.yml 的 paths 列表里，push 后 CI 会跑它；非 darwin 的补选分支断言（clickOpen → 二次文件对话框 → opened 为补选的那个文件）因此首次在 Windows 上执行。
    basis: user-request
    createdAt: 2026-09-23T08:09:13.491Z
  - id: w4
    kind: verification
    content: W7（可选）已做出决定并完成：将 checkRepositoryImport 纳入 --focused。本机 focused 模式跑通，证明该检查不依赖前台焦点、在精简集合下可独立运行；真正的 Windows 结论仍待实机/CI 执行 W3–W5。
    basis: observation
    verification:
      criterionId: W7
      criterionVersion: 1
      method: 本机 focused 模式运行 + 工作流 paths 核对
      result: passed
      coverage: 本机 yarn run smoke:guide:focused 全绿 + guide-windows.yml 的 paths 包含 scripts/native-guide-case.mjs
    createdAt: 2026-09-23T08:09:13.491Z
  - id: w5
    kind: progress
    content: 待验证的改动已提交为壳仓库 d6da5b6951b35e5033f79bfaebda3980f6a5fe61（master，17 个文件），尚未 push。push 到 master 后 guide-windows.yml 与 resources-windows.yml 会因 paths 命中而自动在 windows-2022 上运行，即为本任务的自动部分（W1–W5 的自动化部分）。
    basis: user-request
    createdAt: 2026-09-23T08:18:21.375Z
  - id: w6
    kind: progress
    content: 前置环境修复：.upstream/project 是陈旧快照（实测 tree 880e45f8d4d1bf8719de0bd2ee0d785d6e916d63 = 插件提交 dd85e1a 的 tree），lock 的 dcd0f0e8… 与 5193e81^{tree} 一致，桌面快照 .upstream/desktop/dsh-plugin-desktop 实测 2840b043… 与 lock 一致。按 lock 的 commit 用 git archive 重新导出到 %TEMP% 先验证 tree 相等，再替换快照（陈旧副本留在 %TEMP%\stale-project-485a4771）。修复后 verify:upstream 与全部检查可跑；这也证明 source-integrity.mjs 的 tree 算法在 Windows 上与 Git 一致（非平台差异）。
    basis: observation
    createdAt: 2026-09-23T12:23:16.909Z
  - id: w7
    kind: verification
    content: W1 在 Windows 实机通过：yarn check EXIT=0，125+7+1 全绿，smoke:host 双 Host 冒烟也通过，无平台专有失败。
    basis: observation
    verification:
      criterionId: W1
      criterionVersion: 1
      method: cd resources/dsh-project-desktop && yarn check（日志落盘后读计数）
      result: passed
      coverage: 完整 check 链：verify:upstream + build + 125 应用测试 + 7 恢复 + 1 安全模式 + check-project-files + smoke:host；证据 artifacts/w1-check.log
    createdAt: 2026-09-23T12:23:27.846Z
  - id: w8
    kind: verification
    content: W2 在 Windows 实机通过：yarn smoke:resources EXIT=0，win32 专有分支全部执行；第一次选择器无 defaultPath、第二次 defaultPath 等于上次选中的 picked-resource，userData 落盘 last-directories.json（resource 键）。
    basis: observation
    verification:
      criterionId: W2
      criterionVersion: 1
      method: cd resources/dsh-project-desktop && yarn smoke:resources
      result: passed
      coverage: scripts/native-resource-state-checks.mjs:695-760 的 win32 分支：添加资源/绑定目录/技能导入都走 desktop-runtime 选择器，含目录记忆两条断言；证据 artifacts/w2-resource-states-result.json、w2-last-directories.json、w2-resource-add-local.png、w2-resource-bind-and-skill.png
    createdAt: 2026-09-23T12:23:27.846Z
  - id: w9
    kind: verification
    content: W5 在 Windows 实机通过：导入弹窗关闭再打开预填上次导入目录；「浏览」选中的目录在克隆开始前即被记住；落盘 last-directories.json 的 import 键。
    basis: observation
    verification:
      criterionId: W5
      criterionVersion: 1
      method: 与 checkRepositoryImport 同桩同断言的 Windows 探针（.runtime/diag-import-win.mjs，9/9 PASS）
      result: passed
      coverage: 'PASS 7（新弹窗预填上次 destination）、PASS 8（browse 立即记住 + Escape 不导入）、落盘 {"import": …\\Picked}；证据 artifacts/w3-w5-import-trace.log、w3-w5-import-results.json、w3-w5-last-directories.json'
    createdAt: 2026-09-23T12:23:27.846Z
  - id: w10
    kind: progress
    content: 缺陷 D1（阻塞自动验证，未修）：Windows 上「多个 .agent-project」的补选分支挂死。yarn smoke:guide:focused 只有一行证据路径输出、进程存活 CPU 近 0（7 分钟与 240 秒看门狗各一次）；分段桩定位到进入 ambiguous 分支后再无进展（+1152ms 之后 heartbeat windows=0）；最小隔离复现显示两次对话框都被调用（['openFile','openDirectory'] 然后 ['openFile']）、open() 已带正确路径被调用，但窗口的 closed 事件不到达调用方，await 永久挂起。对应源码 src/windows/guide-window.mjs:241-246 与 scripts/native-guide-checks.mjs:341-345。后面的导入断言因此永不执行，CI 只会被 job timeout 杀掉。
    basis: observation
    createdAt: 2026-09-23T12:23:27.846Z
  - id: w11
    kind: progress
    content: W3 部分通过（实机）：唯一 .agent-project 的文件夹直接打开且选择器属性确为 ['openFile','openDirectory']；空文件夹显示「这个文件夹不是 agent-project 项目：没有找到 .agent-project 项目文件。」；「多个 .agent-project 补选一次只选文件的对话框」按 D1 挂死，未通过。W4 部分通过：导入弹窗端到端 9 项 PASS（空表单自校验、URL 推导文件夹名 imported-project（Windows 分隔符预览）、真实阶段进度「接收对象 42%」、安装 <name>.agent-project 并直接打开、中英文/深浅色/Escape/420px 窄窗）；「非 agent-project 回滚删除」「私有仓库凭据弹窗」本轮未执行。W6 无法验证：scripts/package-windows.mjs:27 声明了文件关联，但本机注册表（HKCU FileExts 与 HKCR）都没有 .agent-project 关联，未安装带关联的候选构建。
    basis: observation
    createdAt: 2026-09-23T12:23:27.846Z
  - id: w12
    kind: progress
    content: 工具环境陷阱（非产品缺陷，已规避）：后台作业里探针向未排空的 stdout 写日志会抛 EPIPE，Electron 主进程未捕获异常弹出模态「A JavaScript error occurred in the main process」并停止推进，表现为「窗口一闪而逝后卡死」。正式检查脚本只用 console.log，故不受影响；探针改为只落盘 .runtime/*.trace。
    basis: observation
    createdAt: 2026-09-23T12:23:27.846Z
  - id: w13
    kind: progress
    content: 证据已落盘：tasks/<任务>/artifacts/windows-verification.md（完整报告）+ w1-check.log、w2-resource-states-result.json、w2-last-directories.json、w2-resource-add-local.png、w2-resource-bind-and-skill.png、w3-w5-import-trace.log、w3-w5-import-results.json、w3-w5-last-directories.json、w3-w5-windows-import-probe.mjs、w3-ambiguous-hang-trace.log、w3-ambiguous-isolated-trace.log、w3-smoke-guide-focused-hang.log，共 13 个文件 / ≈382 KB。未修改任何仓库源码（git status 干净），运行期目录全部在 %TEMP% 与被忽略的 .runtime/。
    basis: observation
    createdAt: 2026-09-23T12:23:27.846Z
  - id: w14
    kind: progress
    content: D1 根因已在实机确认（修正之前的描述）：对「在本次调用过程中被关闭的窗口」调 webContents.executeJavaScript，Promise 永不 settle。最小复现只做一件事——await contents.executeJavaScript('...button[data-guide-action=open].click()')——点击执行了、两次对话框都返回、窗口也关了（同次运行的 'closed' 观察可见），但其后第一行日志从未出现，而主进程 setInterval 心跳仍在继续（heartbeat windows=0），即主进程没死、只是这个 Promise 悬着。对应 scripts/native-guide-checks.mjs:343 的 await clickOpen(window)（clickOpen 定义在第 304 行），而引导窗口处理完 open 后会在 setImmediate 里 window.close()（src/windows/guide-window.mjs:258）；同文件的 clickAndWaitForClose（第 15-25 行）已用 Promise.race 处理这种情况，补选分支漏了。建议修法：第 343 行改为 await Promise.race([ambiguousOpened, clickOpen(window)]) 或复用 clickAndWaitForClose。新证据：artifacts/d1-executejavascript-hang-trace.log、d1-executejavascript-hang-probe.mjs。
    basis: observation
    createdAt: 2026-09-23T12:30:29.593Z
  - id: w15
    kind: progress
    content: D1 已修复并提交为壳仓库 ee21ec2（只改验证脚本 scripts/native-guide-checks.mjs：把 await clickOpen(window) 改为 await Promise.race([ambiguousOpened, clickOpen(window)]) 后再 await ambiguousOpened；产品代码一行未动）。修复后 Windows 实机重跑：yarn smoke:guide:focused EXIT=0（checks 为 open-folder-and-repository-import + create-guide-project-path-preview-separator，.runtime/guide-frame-bCutlm）；yarn smoke:resources EXIT=0（.runtime/resource-states-DjfOp0）；壳 yarn check EXIT=0（125+7+1）；插件工作树 yarn check EXIT=0（308 tests / 301 pass / 7 skip / 0 fail）。未 push。
    basis: user-request
    createdAt: 2026-09-23T13:02:31.636Z
  - id: w16
    kind: progress
    content: 用户在同一台 Windows 实机用开发壳（DSH_PROJECT_PLUGIN_SOURCE=..\dsh-plugin-project + 隔离 userData）按手工清单验收，fixture 在 %TEMP%\dsh-manual-acceptance，结论：全部通过、没有发现问题。覆盖：文件夹选择器退化、唯一入口直接打开、空文件夹中文提示、多入口补选文件、第二次对话框取消后无动作、克隆导入表单校验与文件夹名推导（Windows 分隔符预览）、导入进度与自动打开、非项目仓库回滚、同名目标拒绝、私有仓库凭据弹窗、导入目录记忆（含「浏览」立即记住）与 last-directories.json 落盘、中英文/深浅色/窄窗口。如实记录：本轮手工验收没有留下截图/录屏（artifacts/manual/ 不存在），该结论来源是用户口头确认；对应的自动断言已在 w15 全绿。
    basis: user-request
    createdAt: 2026-09-23T13:02:31.636Z
  - id: w17
    kind: progress
    content: W6（资源管理器双击 .agent-project 经 second-instance 打开）本轮不验证：用户决定先不做文件关联，也不安装候选构建。本机现状已核实：打包脚本 scripts/package-windows.mjs:27 声明了关联，但注册表 HKCU\...\Explorer\FileExts 与 HKCR 下都没有 .agent-project，已装的是 0.1.8。若将来要验：安装带关联的候选构建后双击 <name>.agent-project，确认第二个实例把路径交给已运行实例（src/app/main.mjs:385-390）并打开对应项目窗口。
    basis: user-request
    createdAt: 2026-09-23T13:02:31.636Z
  - id: w18
    kind: verification
    content: W3 在 Windows 实机通过：唯一入口文件夹直接打开、选择器属性为 ['openFile','openDirectory']；空文件夹显示「这个文件夹不是 agent-project 项目：没有找到 .agent-project 项目文件。」；多入口文件夹补一次只选文件的对话框（选 One.agent-project 即打开）；第二次对话框取消后无动作、不报错。
    basis: observation
    verification:
      criterionId: W3
      criterionVersion: 1
      method: yarn smoke:guide:focused（Windows 实机）+ 用户手工界面验收
      result: passed
      coverage: 自动：修复后 yarn smoke:guide:focused EXIT=0（checkRepositoryImport 的 4 个分支全部跑到）；手工：用户用开发壳 + %TEMP%\dsh-manual-acceptance 的 01-single/02-empty/03-multi 逐项验收通过。
      reason: D1 修复后本机 smoke:guide:focused 首次跑完整个 checkRepositoryImport 并 EXIT=0；手工验收由用户在同一台机器上完成并确认无问题。
    createdAt: 2026-09-23T13:02:31.636Z
  - id: w19
    kind: verification
    content: W4 在 Windows 实机通过：公开仓库导入推导文件夹名并在父目录下安装 <name>.agent-project 后直接打开；非 agent-project 仓库提示后回滚删除；私有仓库弹出凭据弹窗。
    basis: observation
    verification:
      criterionId: W4
      criterionVersion: 1
      method: Windows 探针 + yarn smoke:guide:focused + 用户手工界面验收
      result: passed
      coverage: 自动：与 checkRepositoryImport 同桩的探针 9/9 PASS（校验、推导名、Windows 分隔符预览、真实阶段进度、安装并打开）+ 修复后 focused 全绿；手工：用户按清单跑完全部导入场景（含回滚、同名目标拒绝、私有仓库凭据）无问题。
      reason: 自动部分（导入弹窗端到端）在实机探针与 focused 检查中均通过；回滚、同名目标、私有凭据属于只能手工触发的场景，由用户按清单验收确认。
    createdAt: 2026-09-23T13:02:31.636Z
  - id: w20
    kind: verification
    content: W6 本轮不适用（用户决定先不做文件关联、不装候选构建）；验收方式与前置条件已记在 w17，将来需要时可另行验收。
    basis: user-request
    verification:
      criterionId: W6
      criterionVersion: 1
      method: 用户决定暂不验收 + 注册表/打包脚本核实
      result: not-applicable
      coverage: 本轮不验证：注册表无 .agent-project 关联，无法从资源管理器双击；已在报告中留下后续验收步骤（装带关联的构建后双击，观察 second-instance 将路径交给运行中实例）。
      reason: 用户明确本轮不做文件关联、不安装候选构建；缺少关联时该场景在本机无法复现，故不适用而不是失败。
    createdAt: 2026-09-23T13:02:31.636Z
  - id: w22
    kind: scope
    content: 范围调整：验收项 W6（双击 .agent-project 经 second-instance 打开）移出本任务验收标准。理由：它需要先安装带 .agent-project 关联的候选构建，而本任务 outOfScope 已排除打包产物验收，用户也确认本轮不验收该场景；本机注册表确实无任何关联。保留：验收方式与前置条件已写入报告第七节与 w17，需要时可在带关联的构建上单独验收。
    basis: user-request
    referenceIds: []
    reason: W6 的前置条件（打包/安装带文件关联的构建）不在本任务范围内，用户确认本轮不验收；不移出会让任务永远无法完成。
    createdAt: 2026-09-23T13:02:53.083Z
  - id: w24
    kind: verification
    content: W2 v2（验收文本去掉「或 CI artifact 为绿」的替代口径后重新确认）在 Windows 实机通过：yarn smoke:resources EXIT=0，win32 专有分支全部执行，第一次选择器无 defaultPath、第二次 defaultPath 等于上次选中的 picked-resource，userData 落盘 last-directories.json（resource 键）。修复 D1 后于 2026-09-23 重跑仍为 EXIT=0（%TEMP% 侧日志与 .runtime/resource-states-DjfOp0）。
    basis: observation
    verification:
      criterionId: W2
      criterionVersion: 2
      method: cd resources/dsh-project-desktop && yarn smoke:resources（修复前后各一次）
      result: passed
      coverage: scripts/native-resource-state-checks.mjs:695-760 的 win32 分支：添加资源/绑定目录/技能导入都走 desktop-runtime 选择器，含目录记忆两条断言；证据 artifacts/w2-resource-states-result.json、w2-last-directories.json、w2-resource-add-local.png、w2-resource-bind-and-skill.png
      reason: 验收文本仅去掉了「或 resources-windows.yml 的 artifact 为绿」这一替代口径，判定内容未变；两次本机运行均 EXIT=0。
    createdAt: 2026-09-23T13:03:05.694Z
  - id: w25
    kind: verification
    content: W7 v2（验收文本改为「已决定加进，并在 Windows 实机跑通」后重新确认）通过：checkRepositoryImport 已在 scripts/native-guide-case.mjs 的 focused 集合里，修复 D1 后 Windows 实机 yarn smoke:guide:focused EXIT=0，checks 为 open-folder-and-repository-import + create-guide-project-path-preview-separator。
    basis: observation
    verification:
      criterionId: W7
      criterionVersion: 2
      method: Windows 实机 yarn smoke:guide:focused + 工作流 paths 核对
      result: passed
      coverage: guide-windows.yml 的 paths 覆盖 scripts/native-guide-case.mjs；本机 focused 修复前挂死、修复后 EXIT=0（.runtime/guide-frame-bCutlm）。
      reason: 验收文本只是把当时的待决定改成已决定并实机验证，判定内容未变；窗口探测、多项目补选与导入在 Windows 上均已随 focused 一起跑通。
    createdAt: 2026-09-23T13:03:05.694Z
  - id: w26
    kind: completion
    content: Windows 实机验证收尾：必需验收项均有当前版本下的通过证据（W1 w7、W2 v2 w24、W3 w18、W4 w19、W5 w9），可选 W7 v2 已通过（w25），W6 经用户决定移出验收标准（w22）；D1 已修复（ee21ec2）并在修复后重跑 focused/resources/两侧 check 全绿（w15），用户手工验收确认无问题（w16）。任务目标——在真实 Windows 上给出三块改动的平台结论——已达成。
    basis: agent-proposal
    verificationEntryIds:
      - w7
      - w24
      - w18
      - w19
      - w9
      - w25
    createdAt: 2026-09-23T13:03:12.013Z
  - id: w27
    kind: progress
    content: 外部验证（windows-2022 CI）已跟到位：壳仓库 ee21ec2（D1 修复）已随 74a82e6 推送到 origin/master（本地与远程一致，无待推送提交）。“Verify Guide on Windows” 在 74a82e6 上 success（run 35863134305，12:52:12Z→12:54:32Z），其中 “Verify the create guide project path preview on Windows”（corepack yarn run smoke:guide:focused）与 “Upload guide evidence” 均为 success；“Verify Resources on Windows” 也 success（run 35863134327）。对照：同一 workflow 在修复前的 2bad7f30 上两次均 cancelled（35856054742、35851464588）——即在 D1 挂死下被取消/超时，修复后首次跑通。
    basis: observation
    createdAt: 2026-09-23T13:04:20.804Z
operations:
  2e57ae13d9d855c084b0d4f559de1948ebb5a891d105734e9cd9fcfd159c8492:
    fingerprint: e83f92eb6fdb8e31ebe052910812971f1075677b755892afc5786b32292c38b9
    kind: create
    at: 2026-09-23T08:07:16.828Z
    entryIds:
      - w1
      - w2
  274b40bfdef3f2f176555a0d444554f0e677c1969ad181ee71ebb670dab7dc60:
    fingerprint: 552ad90243fcc92ae37ca214e7f8ed8b2b30d8903b9c027025949f767549080e
    kind: update
    at: 2026-09-23T08:09:13.491Z
    entryIds:
      - w3
      - w4
  0acd410768193553a565b4a2efc16afe1d03e1005904c387e16a6a1547067604:
    fingerprint: 3b058c52a12ccb0e3e130b323a2014a00cceb1409ff034439b573956fd91912e
    kind: update
    at: 2026-09-23T08:09:19.280Z
    entryIds: []
  0c00876fb91e6338bb127c4d8d5d5dad11252d4e14d03281c766c2d0b18fcbc7:
    fingerprint: ef85f128779b59a80f540145739e6783a9a7bcd5e021a6a151da6a5187bef44b
    kind: update
    at: 2026-09-23T08:18:21.375Z
    entryIds:
      - w5
  c817bfe3934de2077726414104c63921cee3cb50a1bb5bd7c8cbb99f76d2f61d:
    fingerprint: 549414a7d103e630bc2fab4a18e79fb3961a5eba861cff7b1cf708cc12e73099
    kind: update
    at: 2026-09-23T12:23:16.909Z
    entryIds:
      - w6
  0967df581210b4ef4aadba98f058c9f61c180445665cb42a9e6b8ddfb7e424d2:
    fingerprint: 7066d227346e61cdc75b50822c29ba5663a5cc638695a37d53c9d32cd5afe3d6
    kind: update
    at: 2026-09-23T12:23:27.846Z
    entryIds:
      - w7
      - w8
      - w9
      - w10
      - w11
      - w12
      - w13
  6f9310f1f2e12cb26b36d4be29501199ffbe9267191110f504852180ce914f88:
    fingerprint: d41d4fdae38575646acf23d7fc47b6060851d2c2bddb0cfbb82ab6a37f8babfc
    kind: update
    at: 2026-09-23T12:23:42.746Z
    entryIds: []
  9997bfad563643da0cc3a2c033386cb1ef93ea1c1d996dbdc11d1268fb664515:
    fingerprint: def3e79755a68a18329cbdb727a80dcb1d061e5d5f9e7a2a13ba77609923b0db
    kind: update
    at: 2026-09-23T12:30:29.593Z
    entryIds:
      - w14
  b64506c022691a5b7fa12bb134df29d7b18daa7438202962181d52e12b134a55:
    fingerprint: 2cf6fdfbe7c800693646b71d3666551a3f4399076eae76143f38fa04839f2fbe
    kind: update
    at: 2026-09-23T13:02:31.636Z
    entryIds:
      - w15
      - w16
      - w17
      - w18
      - w19
      - w20
  5d2eda9c82f3fd3b83b2738a77509a835c568332e5b212d3c2b251ced59971f2:
    fingerprint: b98234cb6c4cc9afc9142d2d361438453f7e0b8a297214238ad2c489b96834a9
    kind: update
    at: 2026-09-23T13:02:53.083Z
    entryIds:
      - w22
  ce27b8e05f9b980bcdba75735c294a55f09d926b5fd512c3672a2e9aef6e9e34:
    fingerprint: f210a9f643cc1f3c4e2f1499ad32493c83dac1dc51349fefaa56eb5fd58323a5
    kind: update
    at: 2026-09-23T13:03:05.694Z
    entryIds:
      - w24
      - w25
  372679003bd011649969d3205957fd4f52f520cc3487f91686520e3fbb6eb15d:
    fingerprint: 5de663a6fced48a09ca4bb88e2f155c413b48adc502c30aab8efeb6bc3fd7061
    kind: update
    at: 2026-09-23T13:03:12.013Z
    entryIds:
      - w26
  c3a7b84873d6b55744b4ce14e4bdb834a92bea36af00ef8ef7bf95a2b23ab765:
    fingerprint: b2ed3a2a96bbe73825c08ad7b38c4634602127afb89174b7d4445df48ab11a1c
    kind: update
    at: 2026-09-23T13:04:20.804Z
    entryIds:
      - w27
  1f2bda83a3048a08e287578ba5273202b4b22dc77e6a238abbb7893c238fac41:
    fingerprint: 6c40a9e4f1550509f426e43547882c502b26d018fc20aa3c4f32d2dab8d67172
    kind: update
    at: 2026-09-23T13:04:31.117Z
    entryIds: []
criterionVersions:
  W1: 1
  W2: 2
  W3: 1
  W4: 1
  W5: 1
  W6: 1
  W7: 2
---

Windows 实机验证完成（含 CI 外部验证）。机器：Windows 11（NT 10.0.26200/AMD64）、Node 22.23.2、Windows PowerShell 5.1；被测：壳 2bad7f3（含 d6da5b6 的改动），修复提交 ee21ec2，已随 74a82e6 推送到 origin/master。前置修复：.upstream/project 曾是落后一个提交的陈旧快照导致 verify:upstream 失败，按 lock 的 5193e81 重导并先校验 tree 再替换。结果：W1 通过（yarn check EXIT=0，125+7+1，smoke:host 也过）；W2 通过（smoke:resources EXIT=0，win32 目录记忆断言全跑并落盘 last-directories.json）；W3 通过（唯一入口直接打开、空文件夹中文提示、多入口补选文件、取消无动作——自动 focused + 用户手工双确认）；W4 通过（导入表单校验/文件夹名推导/Windows 分隔符预览/真实阶段进度/安装并打开，以及回滚、同名目标拒绝、私有仓库凭据，由用户手工确认）；W5 通过（导入目录预填与 last-directories.json 的 import 键）；W7 通过（checkRepositoryImport 已入 focused 集合并实机跑通）；W6 经用户决定移出验收标准（前置条件属打包产物验收，已写入报告第七节与 w17，将来可单独验收）。过程中发现并修复 D1：非 darwin 补选分支对「在调用中被关闭的窗口」await executeJavaScript 导致 Promise 永不 settle，smoke:guide:focused 在 Windows 上挂死（CI 只能等 job timeout）；修法为与 closed 竞争（只改验证脚本 scripts/native-guide-checks.mjs，产品代码未动）。CI 外部验证：74a82e6 上 Guide/Resources 两个 Windows workflow 均 success（run 35863134305 / 35863134327），而修复前的 2bad7f30 上 Guide workflow 两次 cancelled——D1 影响的直接对照。证据：artifacts/windows-verification.md + 15 个结论级文件（共 16 个文件 / ≈422 KB）。遗留：手工验收没有截图留档（口头确认）。
