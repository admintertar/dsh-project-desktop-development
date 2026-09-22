---
name: desktop-release
description: DSH Project Desktop 的发布手册：发布三件套（版本号、插件 pin、双语发布说明）、pin bump 与快照重导、推 tag 即自动发布、用 replace_existing 覆盖重发，以及在没有 gh 的情况下查询打包进度与读取 CI 日志。
whenToUse: 当需要发布 dsh-project-desktop 的新版本（bump 插件 pin、改 package.json 版本、写 docs/releases/<version>.md、打 tag、覆盖已发布的版本），或需要查询 Package Desktop 的运行状态、判断某次改动会不会带起打包与发布时。
---

# DSH Project Desktop 发布手册

发布 = **三件套一起改**，然后**推 tag**。tag 一推，构建与发布都会自动发生。

## 一、发布三件套

| 文件 | 改什么 |
|---|---|
| `resources/dsh-project-desktop/package.json` | `version` 提升到目标版本 |
| `resources/dsh-project-desktop/upstream.lock.json` | `project.commit` 指向**已推送到远端**的插件提交，`project.tree` 用该提交的 tree |
| `resources/dsh-project-desktop/docs/releases/<version>.md` | 发布说明；这个文件缺失时 Release 只剩下载链接（0.1.3 的教训） |

## 二、前置检查（顺序不能反）

1. **插件提交必须已经在远端**。CI 把 pin 当作 checkout 的 `ref`，pin 指向未推送的提交会让打包在 checkout 阶段直接失败。
   ```sh
   git -C resources/dsh-plugin-project branch -r --contains <commit>
   ```
2. **两个仓库工作树干净**，该推的都推了。
3. **算 tree，并逐字核对仓库 URL**（照抄极易出错）：
   ```sh
   git -C resources/dsh-plugin-project rev-parse <commit>^{tree}
   git -C resources/dsh-plugin-project remote get-url origin   # 与 lock 里的 repository 比对
   ```

## 三、标准流程

```sh
# 1) bump lock：手改 upstream.lock.json 的 project.commit 与 project.tree
# 2) 重导快照 —— setup 在目标已存在时会静默跳过，必须先删
cd resources/dsh-project-desktop
rm -rf .upstream/project && mkdir -p .upstream/project
git -C ../dsh-plugin-project archive --format=tar <commit> | tar -xf - -C .upstream/project
yarn run verify:upstream

# 3) 改 package.json 版本，写 docs/releases/<version>.md（中英双语）
# 4) 提交并推送
git add -A && git commit -m "chore: 发布 X.Y.Z" && git push origin master

# 5) 打 tag 就是发布
git tag vX.Y.Z && git push origin vX.Y.Z
```

## 四、触发语义

- `push: tags: ['v*']` → 构建**并且自动发布**。工作流里是
  `PACKAGE_PUBLISH: ${{ inputs.publish || startsWith(github.ref, 'refs/tags/v') }}`，
  所以**推 tag 就等于发布**，不存在「只构建不发布」的 tag 路径。
- `workflow_dispatch` 输入：
  - `platform`：`all` / `mac` / `win`
  - `publish`：是否发布到 Releases（**要求 all 才允许**）
  - `replace_existing`：覆盖已有 release 并移动它的 tag（**显式重发才用**）
- **时长基准：两个平台约 20–25 分钟**（构建 + DMG 校验 + 上传）。慢是正常的，不要误判为卡死。

## 五、覆盖重发（版本已发布，但内容要换）

不要手动 `git tag -f`。用一次 dispatch 让脚本自己做完：

```sh
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/<owner>/<repo>/actions/workflows/package.yml/dispatches" \
  -d '{"ref":"master","inputs":{"platform":"all","publish":"true","replace_existing":"true"}}'
# HTTP 204 = 已接受
```

`scripts/publish-release.mjs` 会：把旧 release 改名归档并转 draft → **强制移动 tag 到本次构建的提交** → 上传候选并逐个校验 → 发布；
**任何一步失败都会回滚**（tag 移回原提交、旧 release 恢复）。对 immutable 的 release 会直接拒绝。

## 六、发布说明规范

- 路径固定 `docs/releases/<version>.md`，由 `publish-release.mjs` 读作 Release 说明，并自动追加下载链接与校验和段落。
- **中英双语**：标题写 `… — 中文名 / English name`，正文先完整中文、再完整 English，两边内容一致。
- 诚实列出**已知限制**与未覆盖项；安装包未签名（macOS ad-hoc、Windows 未签名）要写明。

## 七、查 CI 进度与读日志（没有 gh 时）

匿名 `api.github.com` 可用但**很快限流**（60 次/小时）。限流后响应体里没有 `status` 字段，
轮询会打出一串 `None None`——看到这个就该换认证请求（限额 5000/小时）：

```sh
PW=$(security find-internet-password -s github.com -w)   # macOS 钥匙串；GitHub Desktop 存的 OAuth token 同样可用
curl -s -H "Authorization: Bearer $PW" \
  "https://api.github.com/repos/<owner>/<repo>/actions/runs/<id>/jobs"
```

- **job 日志与 artifact 必须认证**：匿名下载分别返回 403 与 401。
- run 号**按工作流各自独立**（`Package Desktop #20` 与 `Verify Resources on Windows #20` 是两条），引用时带上工作流名或 run id。
- 监控用后台作业轮询并在结束时读结果，不要在前台反复短等。

## 八、踩过的坑

- **`upstream.lock.json` 的 `repository` 写错**（例如把 `dsh-plugin-project` 写成 `dsh-project-plugin`）：CI 在 checkout 阶段失败。改完务必与插件 remote 逐字比对。
- **改 lock 和 push 插件必须是同一个动作**：只改 lock 不推插件，等于让 CI checkout 一个远端不存在的 ref。
- **发布提交会带起额外工作流**：`resources-windows.yml` 与 `probe-boot-timing.yml` 都监听 master push，且 paths 含 `package.json` / `upstream.lock.json`，所以清理它们的红是发布的一部分，不是误触。
- **`package.yml` 只跑 `smoke:updates`**，不跑资源冒烟——所以资源冒烟的红不会阻塞发布，反之发布改动也不该被资源冒烟的红挡住。
- **普通 `yarn check` 会覆盖本地插件产物**：壳加载的是 `.cache/runtime/dsh-plugin-project`，不带 `DSH_PROJECT_PLUGIN_SOURCE` 的构建会把它换成 pin 版本，于是开发中的界面「缺一块」，严重时开发壳启动即崩（`renderSlot('root') before any 'root' registration`）。排查先比对标记：

  ```sh
  grep -c project-change-card resources/dsh-project-desktop/.cache/runtime/dsh-plugin-project/lib/client.js
  ```

  为 0 说明是 pin 版，需要带 `DSH_PROJECT_PLUGIN_SOURCE` 重新 build。
