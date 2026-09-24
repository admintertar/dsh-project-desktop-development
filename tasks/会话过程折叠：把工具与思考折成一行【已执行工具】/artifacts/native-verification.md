# 已放弃：会话过程折叠【已执行工具】

**结论：功能不要了。** 用户于 2026-09-24 明确要求撤销，四个提交已从本地 `master` 回退，
代码与文档均不存在，仓库回到与 `origin/master` 一致的 `d45b54f`。

## 撤销动作

| 提交 | 内容 | 状态 |
| --- | --- | --- |
| `0b23f00` | 初版：把工具与思考折成一行【已执行工具】 | 已回退 |
| `e30038d` | 修复：收敛后表头不再消失 | 已回退 |
| `8b0fd2f` | 文档：对话节点覆盖清单与测试提示词 | 已回退 |
| `f53749b` | 分段：叙述也折、每段一行 | 已回退 |

撤销方式：`git reset --hard d45b54f`（只动本地，四个提交从未 push，`origin/master` 本就在 `d45b54f`）。
新增文件 `src/client/transcript-fold.ts`、`src/client/TranscriptFoldRow.tsx`、
`tests/client-transcript-fold.test.ts`、`docs/transcript-coverage-prompts.md` 均已不存在。
壳产物 `resources/dsh-project-desktop/dist/build.json` 已重建为纯钉版（无 `projectLocalSource`）。
回退后 `resources/dsh-plugin-project` 的 `yarn check` 通过：308 测试全绿（等于改动前基线）。

如需恢复（仅供万一）：`git reset --hard f53749b` 可回到完整的分段版本；
四个 SHA 也在 git reflog 中。

## 为什么放弃（据实记录，不美化）

用户先要「运行中也折成一行」，中途改为「推理中展开、出结果收起」，最后给出伪代码要求
「每个『干活+说话』单元各自一行、过程叙述也折、只留最终结果」。

实际实现走了四轮才对上：前两轮我**没有先读真实 DOM 就按猜的分段模型动手**，两次返工。
最后一轮（`f53749b`）在真壳里验证行为是对的——84 行长回合整体收起、叙述不再外露、最终回答保留——
但用户随即决定不再继续这个方向。

## 保留的技术结论（有价值，别丢）

这些是实测出来的官方契约，跟本功能存废无关，下次动会话视图仍适用：

1. **过程行 kind 的真实集合**是 `tool-call` / `assistant-step` / `context` / `command` /
   `compaction` / `manual-compaction` / `model-retry` / `unknown`。
   官方 bundle 里的 fallback 字面量写的是 `tool-result` / `unknown-surface`，**照抄它会一行都折不到**。
   权威来源是官方 `conversation.chat.node` 的渲染器注册键。
2. **推理块的真实标记是 `[data-variant="think"]`**。`[data-turn-process-inline]` 只在官方折叠窗口
   打开后才出现，运行中取不到。
3. **`hidden` 属性归官方 `useSearchableHidden` 的 layout effect 所有**。外部代码只能移除、
   绝不能把取到的值写回——运行中取到的一定是 `hidden="until-found"`，写回会覆盖官方刚清掉的状态，
   表现为「表头在回合结束时自己消失」。
4. **判定元素可见性不能用 `offsetWidth`**：`hidden="until-found"` 走 `content-visibility: hidden`，
   `offsetWidth` 仍大于 0。
5. **官方在历史分页未加载完（`historyIncomplete`）时会抑制自己的折叠窗口**，
   同一回合点「加载更早」前后行为不同，不先补全历史就会误判成 bug。
6. **官方每个回合只有一个 `turn-process` 节点**，开合状态按 `answerStep` 存在一个键里。
   想要「每段一个折叠行」必须自造分组——这是插件在跟官方模型较劲，成本高。
7. **`data-turn-process-member` 只表示「官方此刻拥有该行的过程呈现」**，
   不表示「官方正在隐藏它」；官方展开态下成员行同样带这个标记但完全可见。
8. **对话节点共 15 种**：`system-prompt` / `user` / `steering` / `turn-process` / `turn-error` /
   `turn-max-tokens` / `turn-tail`（这七种独立，永远不进折叠），
   以及 `tool-call` / `assistant-step` / `context` / `command` / `compaction` /
   `manual-compaction` / `model-retry` / `unknown`（这八种是过程成员）。

原生验收的做法也可复用：真实 Electron 壳 + 隔离的真实 DSH 状态副本
（`DSH_PROJECT_DESKTOP_USER_DATA`）+ `--remote-debugging-port` 读**实时 DOM**，
逐帧采样流式过程。截图会骗人，`offsetWidth` 会骗人，实时 DOM 属性不会。