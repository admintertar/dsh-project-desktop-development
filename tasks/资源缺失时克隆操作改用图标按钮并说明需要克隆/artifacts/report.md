# 资源缺失时克隆操作改用图标按钮并说明需要克隆

## 现象（用户报告）

资源卡片底部操作栏在资源尚未克隆（状态「目录缺失」）时显示**文字按钮「克隆」**，而同一行的关联远端、绑定目录、编辑、移除都是带 Tooltip 的 28×28 图标按钮：宽度、圆角与提示方式都不一致，而且界面上没有任何地方说明「这条资源为什么要克隆」。

## 改动前的代码逻辑

`resources/dsh-plugin-project/src/client/ResourcesPanel.tsx`（改动前进程在 134-135 行）：

```tsx
{item.type === 'git' && item.url && item.status !== 'ready' && !item.external && <Button size="sm"
  disabled={locked || cloneActive || !state.data?.canClone}
  onClick={event => open(event, 'clone', item)}>{t('resourceClone')}</Button>}
```

- 该分支的触发条件对应 `ManagedResource.status` 的三种未就绪状态：`missing`（目录缺失）、`unbound`（需要绑定目录）、`unavailable`（不可用）；`external`（项目外目录）与无 url 的资源不显示克隆入口。
- 同一操作栏的其它动作统一走本文件的 `IconAction`：官方 `Button.icon` + 官方 `Tooltip`，样式 `project-mcp-action`（28×28、`border-radius:7px`，`styles.ts:136-139`）。
- 卡片正文已有状态标签（`resourceStatusLabel` → `missing` 显示「目录缺失」），但克隆按钮本身既无说明也无法解释「目录缺失」与「克隆」的关系。

## 本次改动

`src/client/ResourcesPanel.tsx`

1. `IconAction` 增加可选 `tooltip`：不传时行为与之前完全一致（沿用 `label`，且按钮禁用时不弹气泡）；传了自定义说明时，气泡在按钮禁用状态下也保留，保证「为什么不能用/为什么需要克隆」始终可读。
2. 克隆入口改为图标按钮：

```tsx
{item.type === 'git' && item.url && item.status !== 'ready' && !item.external &&
  <IconAction label={`${t('resourceClone')}: ${item.name}`} tooltip={t('resourceCloneBody')} icon={<IconDownloadOutline16 />}
    disabled={locked || cloneActive || !state.data?.canClone} action={event => open(event, 'clone', item)} />}
```

- 图标选用官方 `IconDownloadOutline16`（克隆=从远端取回到本地）。它与「更新资源」同用该图标，但两者互斥：更新只在 `status === 'ready'` 的卡片上出现，克隆只在未就绪卡片上出现。
- 无障碍名称仍是动作名 `${克隆|Clone}: <资源名>`，说明进 Tooltip，符合前端规范中「图标按钮使用官方 Tooltip」与「图标按钮必须有可访问名称」两条。

`src/resource-locales.ts`（中英同步新增 key）：

| key | zh | en |
| --- | --- | --- |
| `resourceCloneBody` | 尚未克隆到项目内。克隆会把仓库检出到项目内的目标目录。 | Not in this project yet. Cloning checks the repository out into the project directory. |

禁用条件、克隆弹窗、Escape 关闭后的焦点返回都没有改动。

## 验证

### 自动化：`yarn check`（在独立 worktree `resources/.worktrees/dsh-resource-clone-action` 内，分支 `fix/resource-clone-icon-action`）

```
# tests 308   # pass 301   # fail 0   # skipped 7   EXIT=0
```

（typecheck + 测试 + build 全过；主工作树 `resources/dsh-plugin-project` 全程保持在 `5193e81` 干净状态。）

### 原生视觉与交互验收（真实 Electron 窗口 + 实时 DOM）

探针：`%TEMP%\clone-action-probe\{run,case}.mjs`（一次性脚本，运行期目录在 `%TEMP%`，不进任务目录）。
壳用开发期开关加载本次 worktree 源码构建：

```powershell
$env:DSH_PROJECT_PLUGIN_SOURCE="D:\dsh-project-desktop-development\resources\.worktrees\dsh-resource-clone-action"
yarn build   # resources/dsh-project-desktop，dist/build.json 记录 projectLocalSource
```

用例：真实项目 fixture（`createProjectFromPlan`），manifest 声明一条 Git 资源 `resources/backend`（目录不存在 → `missing`），打开真实项目窗口并让它取得前台（探针记录 `document.hasFocus() === true`，满足「先证明前台窗口再用实时 DOM 采样」的要求）。

覆盖与断言（`en`/`zh` × `light`/`dark` 四轮，每轮 1180 与 420 两种窗口宽度）：

| 断言 | 结果 |
| --- | --- |
| 操作栏中出现 `button[aria-label="克隆: Clone action-backend"]`（en 为 `Clone:`） | 通过 |
| 该按钮 `textContent` 为空（不再是文字按钮） | 通过 |
| 该按钮 28×28、`project-mcp-action`、与相邻图标按钮同圆角、同启用态颜色 | 通过 |
| 同一行仍有文字按钮（「详情」），即只有克隆动作被改成图标 | 通过 |
| 图标 `focus()` 时 `[role=tooltip]` 文本 = 上表 zh/en 文案，`blur()` 后消失 | 通过 |
| 点击图标打开真实克隆弹窗（弹窗文案含「克隆」/「Clone」） | 通过 |
| Escape 关闭后 `document.activeElement` 回到该图标按钮 | 通过 |
| 420px 窄窗口：页面无横向溢出、footer 无溢出、5 个动作都在视口内且可见 | 通过 |

### 证据

| 文件 | 说明 |
| --- | --- |
| `probe-result.json` | 探针完整输出：4 轮文案、按钮几何（aria/text/尺寸/圆角/颜色/禁用态）、窄窗口测量、`windowFocused` |
| `clone-icon-row-zh-dark.png` | 中文深色：操作栏为 4 个图标动作，无「克隆」文字 |
| `clone-tooltip-zh-dark.png` | 中文深色：键盘 focus 时显示「尚未克隆到项目内。克隆会把仓库检出到项目内的目标目录。」 |
| `clone-tooltip-en-light.png` | 英文浅色：同一条 Tooltip |
| `clone-icon-row-en-light-narrow.png` | 英文浅色 420px 窄窗口：图标行完整、无横向溢出 |

## 遗留与未覆盖

- **窄窗口下的既有布局现象（与本次改动无关）**：420px 窗口里资源面板本身只有约 139px 宽、卡片约 43.6px（`.project-mcp-grid` 的轨道宽 `min(363px, 行宽的一半)`，此时约 43.6px），文字「详情」按钮会伸到卡片外——但仍在视口内、页面不横向溢出。网格轨道宽度由 CSS 决定，与按钮是文字还是图标无关，本次改动只会让内容更窄。
- **未逐个验证**其它图标动作（关联远端/绑定目录/编辑/移除）在禁用态是否显示 Tooltip；`IconAction` 仍保持「未传自定义 tooltip 时禁用即不弹气泡」的原行为。
- 未做 macOS 验收；以上均为 Windows（Electron 开发壳，前台真实窗口）。

## 复现命令

```powershell
# 1) 用 worktree 源码构建壳
$env:DSH_PROJECT_PLUGIN_SOURCE="D:\dsh-project-desktop-development\resources\.worktrees\dsh-resource-clone-action"
cd resources\dsh-project-desktop; yarn build
# 2) 跑原生探针（%TEMP% 下的一次性脚本）
node C:\Users\PING\AppData\Local\Temp\clone-action-probe\run.mjs
```
