# 欢迎窗口：打开支持文件夹探测 + 从 Git 仓库克隆导入项目

任务：`task-7be557ec-45bc-48a2-a111-1d3f62b12c8d`
仓库：`resources/dsh-project-desktop`（壳）。插件零改动，未 bump `upstream.lock.json`，未提交、未 push。

## 交付内容

| 文件 | 作用 |
| --- | --- |
| `src/app/project-files.mjs` | 新增 `classifyProjectTarget`：把选中路径归类为 `file / none / multiple / invalid / missing`，避免把插件只提供中文的 message 直接抛给用户 |
| `src/shared/remote-resource.mjs` | 新增 `validRepositoryName`、`repositoryFolderName`（按 `git clone` 规则从地址推导文件夹名） |
| `src/app/repository-import.mjs` | 新增 `RepositoryImports` 导入事务：校验 → 交给 `GuideClones` 克隆 → 安装到 `<父目录>/<文件夹名>` → 检测项目文件 → 成功返回 manifest / 回滚 / 保留并报路径 |
| `src/app/last-directories.mjs` | 新增 `LastDirectories`（`userData/last-directories.json`，键 `import` / `resource`；读取时重校目录仍存在，损坏或非法状态文件重命名保留）与共用的 `pickRememberedDirectory`（上次目录作为选择器起始位置，只有真选了才覆盖，取消不动） |
| `src/windows/guide-window.mjs` | 「打开」改为 `openFile + openDirectory`（Windows/Linux 退化为文件夹选择，多项目目录补一次文件选择）；新增 `import-start / import-finish / import-cancel / browse-import-directory`；`state` 返回 `defaultDirectory` 与 `importDirectory` |
| `src/app/main.mjs` | 菜单与窗口标题栏的「打开项目…」走同一套判定与本地化提示 |
| `src/desktop-adapter/native.mjs` | 项目内目录选择（资源页、资源重定位、技能导入）以记住的目录为 `defaultPath`，并在选中后记住 |
| `src/guide/CloneRepositoryModal.tsx` | 新增导入弹窗（地址 / 分支 / 本地目录 / 文件夹名 / 路径预览 / 真实克隆阶段与百分比）；目录初值取上次用过的导入目录 |
| `src/guide/index.tsx` | 工具栏新增「克隆仓库」（顺序：克隆仓库 / 新建项目 / 打开），中英文案与错误码映射 |
| `scripts/native-guide-checks.mjs` 等 | 原生验收新增 `open-folder-and-repository-import`；既有脚本改用 `data-guide-action` 语义选择器 |
| `scripts/native-resource-state-checks.mjs` | Windows 分支断言目录记忆：第一次选择器无 `defaultPath`，第二次的 `defaultPath` 等于上次选中的目录 |
| `tests/repository-import.test.mjs` | 3 条单测：路径分类、文件夹名推导与校验、真实私有 HTTPS 仓库的认证/克隆/回滚/取消 |
| `tests/last-directories.test.mjs` | 4 条单测：记忆往返（含 `resource` 键）、目录消失后不再预填、损坏/非法状态文件被隔离保留、选择器起止点与取消语义 |

## 验收结果

### 1. 自动化（`yarn run check`，EXIT=0）

- 125 个壳单测 + 7 个 recovery + 1 个 safe-mode 全部通过；`verify:upstream`、build、`check-project-files`、`smoke:host` 通过。
- `tests/repository-import.test.mjs` 用 `tests/fixtures/private-git.mjs` 起的真实私有 HTTPS 仓库验证：凭据问答（含一次错误密码后的重试）后克隆成功；导入后目标出现 `<name>.agent-project` 且 `creation-drafts` 清空；`feature/demo` 分支没有项目文件时抛 `repository-not-project` 并删除目标目录（完全回滚）；`cancel` 后无残留；已完成的作业只能提交一次；非法 URL/分支/文件夹名/目录与已存在目标在启动 Git 前被拒绝。
- `tests/last-directories.test.mjs` 验证记忆读写与跨实例生效、目录被删除后不再预填、损坏或非法状态文件被重命名保留且不阻塞窗口，以及 `pickRememberedDirectory` 的起止点与取消语义。

### 2. 原生窗口验收（`yarn run smoke:guide`，EXIT=0 全绿）

`result.json` 的 `checks` 含 `open-folder-and-repository-import`，与既有 17 项一起全部通过（18 项）。覆盖：

- **AC1**：打开动作的原生对话框 `properties` 断言为 `['openFile','openDirectory']`；选择只含一个 `.agent-project` 的文件夹会打开该文件夹。
- **AC2**：空文件夹 → 欢迎窗口显示中文「…不是 agent-project 项目…」；多项目文件夹在 macOS 抛 `project-ambiguous` 并显示英文文案（Windows/Linux 走补选文件分支）。
- **AC3**：工具栏三个按钮的 `data-guide-action` 顺序断言为 `['clone','new','open']`，文案为「克隆仓库 / 新建项目 / 打开…」。
- **AC4**：弹窗标题中英断言；空表单提交出现校验提示；输入地址后文件夹名自动推导为 `imported-project`，路径预览以 `imported-project` 结尾；克隆中进度行显示插件阶段与百分比（断言「接收对象 42%」）。
- **AC5**：导入完成后目标出现 `<name>.agent-project` 并直接打开该项目；回滚路径由真实 Git 单测覆盖。
- **AC6**：暗色主题弹窗渲染正常、Escape 关闭、420×460 窄窗口无横向溢出；私有仓库认证复用既有弹窗与认证链（单测）。
- **AC7**：无记忆时弹窗目录初值为窗口默认目录；一次导入后**新窗口**的弹窗预填上次用的父目录；点「浏览」选中的目录会被立即记住，关闭再打开仍然预填它。
- **AC8**：`pickRememberedDirectory` 的两个入口共用同一套语义；Windows 分支的端到端断言（第一次无 `defaultPath`、第二次等于上次选中的目录）随 `smoke:host` 在 Windows 上执行。

证据文件：

- `import-en-light.png` / `import-en-dark.png`：英文浅色、暗色导入弹窗
- `import-narrow-en-light.png`：英文窄窗口（420×460）导入弹窗
- `guide-acceptance.log`：`yarn run smoke:guide` 原始输出（`ok: true` 与 18 项 checks）

### 3. 平台归属（`profile.ts` 的证据链）

- **Windows**：固定 Desktop 的 `profile.ts` 在 win32 上禁用 `directory-picker`（auto 后端）并插入 `dsh-host-directory-picker-browse`，Host 侧 `directoryPicker` 能力位为 `browse`，插件的 `pickSource` 因此选 `desktop` —— 资源页的目录选择落在 Shell 自有 runtime 的 `pickDirectory`，本项目新增的目录记忆在 Windows 上生效。
- **macOS / Linux**：保留 auto 后端，由它按平台探测（Linux 还看 zenity/kdialog）决定 native 还是 browse；走 native 时由固定 Desktop 的官方选择器负责，Shell 不介入。

### 4. 已知限制

- 这些检查依赖 OS 级前台焦点。本次已用两次**无人干扰**的运行确认 `yarn run smoke:guide` 全绿；期间若切换窗口（抢焦点），焦点类检查（`document.hasFocus()`）会超时，分隔线检查也会因 `onBlur` 清掉 `data-pointer-focus` 而看到本不该出现的焦点线——这是环境干扰，不是产品回归。
- Windows 的行为由代码证据链（`profile.ts` 的 picker 后端选择、插件的 `pickSource`、既有的 Windows 分支验收脚本注释）支撑，**尚未在 Windows 实机运行**；本机为 macOS arm64。Windows 的 `openFile+openDirectory` 退化分支与新增的记忆断言都要等实机/CI 跑过才算端到端确认。
- macOS/Linux 走 auto 后端时由官方选择器负责，本项目不介入，那里的起始目录沿用官方实现与系统对话框自身的行为。
