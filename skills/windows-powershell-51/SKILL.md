---
name: windows-powershell-51
description: 本机只有 Windows PowerShell 5.1（没有 pwsh）时的踩坑手册：UTF-8 BOM 与 ANSI 解码把 JSON/中文写坏、Start-Process 引号导致静默失败、Invoke-WebRequest 缺 -UseBasicParsing、git 直连 github 超时但系统代理可用、批量杀进程触发作业保护、DPI 与前台证明、后台作业落盘读法等。
whenToUse: 在 Windows 上用 powershell.exe 5.1 跑命令或写 .ps1 辅助脚本、用 PowerShell 改文本/JSON 文件、从 PowerShell 调 git push 与 GitHub API、做原生窗口探针与截图、或排查「本机能跑、CI 却失败」的编码问题时。
---

# Windows PowerShell 5.1 踩坑手册

前提：本机**没有 `pwsh`**（`pwsh` 命令不存在），一切脚本都跑在 Windows PowerShell 5.1
（`powershell.exe`，`$PSVersionTable.PSEdition = Desktop`）。PS7 专属的语法与参数一律不可用：
`-Encoding utf8NoBOM`、`??`、三元 `? :`、`-Parallel`、`Get-Content -AsByteStream` 等。

## 一、编码（最高频，且会一路坏到 CI）

### `Set-Content -Encoding UTF8` 会写 BOM

- **症状**：CI/Node 读这个 JSON 直接炸 —— `SyntaxError: Unexpected token 'ï»¿', "ï»¿{"name"... is not valid JSON`。
  实测代价：`package.json` 被写入 BOM 后，`Package Desktop` 在 **plan 阶段 1 分钟就失败**
  （`scripts/ci-plan.mjs:27` 的 `JSON.parse`），白等一次发布。
- **原因**：PS 5.1 的 `-Encoding UTF8` = **带 BOM**（PS7 才是无 BOM）。
- **修法**：用 .NET 显式无 BOM：
  ```powershell
  $noBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $text, $noBom)
  ```
- **自查**（改完立刻查，别等 CI）：
  ```powershell
  $b = [System.IO.File]::ReadAllBytes($path)
  ($b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF)   # True = 有 BOM，必须去掉
  ```

### `Get-Content -Raw` 按 ANSI 解码，往返一次就把中文写坏

- **症状**：读进来再写回，中文全变乱码（`# 0.1.7 鈥?Windows 椤舵爮…`）。**原文件本来是好的**，是这次往返弄坏的。
- **原因**：无 BOM 的 UTF-8 文件被当 ANSI（GBK）解码。
- **修法**：`Get-Content -Raw -Encoding UTF8`；更稳的是**不要用 PowerShell 往返文本** ——
  用编辑工具（edit/write）或 .NET API。
- **判据**：输出里出现 `鈥`、`锛`、`涓`、`锟` 这类字，就是解码错了。

### `.ps1` 脚本自身的编码

- 无 BOM 且含中文注释 → PS 5.1 按 ANSI 解码 → 报 `意外的标记")"` 之类**解析错误**（代码其实没问题）。
- **修法**：脚本存 **UTF-8 with BOM**（`New-Object System.Text.UTF8Encoding($true)`），或正文/注释全部只用 ASCII。

## 二、进程与启动

### `Start-Process` 的路径参数要自己加引号

- **症状**：被启动的程序**静默 `exit 1`、零输出**。
- **修法**：`-ArgumentList "`"$path`""`（含空格或中文的路径必踩）。
- 判据：Windows 上「**没有任何输出却失败**」通常意味着 spawn/参数阶段就失败了。

### 禁止批量杀进程

- **症状**：`Get-CimInstance Win32_Process | Where-Object {...} | Stop-Process` 之后，工具直接报
  `Windows Job runner exited with exit code 4294967295 before proving its managed range empty`，命令结果全丢。
- **原因**：筛选面太大，杀到了 harness 作业跟踪范围内的进程。
- **修法**：
  1. 只杀**自己启动的那棵树**（`Start-Process` 返回的 pid + 其子孙）；
  2. 或用工具自带的 `job_kill`；
  3. 需要同时存在多个同类窗口时，**用不同标题/不同项目路径隔离**，而不是清理进程。

### 只读自动变量

- `$pid`、`$host`、`$error` 等不能赋值：`$pid = 0` 报
  `Cannot overwrite variable PID because it is read-only`。用 `$procId` 这类名字。

### `Get-Process -Name x` 找不到时退出码是 1

- 在 `pwsh -Command` 里最后一句是它，会把整个命令标成失败。用
  `(Get-Process x -ErrorAction SilentlyContinue | Measure-Object).Count`。

## 三、网络与 GitHub

### `Invoke-WebRequest` 必须加 `-UseBasicParsing`

- **症状**：`Windows PowerShell 处于非交互模式。朗读和提示功能不可用。`（POST 时最容易漏，GET 常常顺手写了）。
- **原因**：PS 5.1 的 `Invoke-WebRequest` 默认依赖 IE 引擎。
- **修法**：所有 GET/POST 都加 `-UseBasicParsing`。

### git 直连 github 超时，但系统代理可用

- **症状**：`git push` → `fatal: unable to access 'https://github.com/...': Failed to connect to github.com:443 after 21068 ms`，
  而**同一时刻** `Invoke-WebRequest https://github.com` 返回 200。
- **原因**：系统代理只对部分程序生效。代理记在
  `HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings` 的 `ProxyEnable` / `ProxyServer`（例如 `127.0.0.1:7890`）。
- **修法**：
  ```powershell
  $s = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
  git config http.proxy "http://$($s.ProxyServer)"
  git config https.proxy "http://$($s.ProxyServer)"
  ```
  （写进仓库本地 `.git/config` 即可，不进提交。）
- **代理抖动**（`schannel: failed to receive handshake, SSL/TLS connection failed`）是暂时的：**重试 3 次**；
  注意 `git push` 失败时 `push tag` 可能已经成功，务必分别核对 `git ls-remote origin refs/heads/master`。

### 没有 gh CLI 时取 token

```powershell
$cred  = "protocol=https`nhost=github.com`n`n" | git credential fill 2>$null
$token = ($cred | Where-Object { $_ -like 'password=*' }) -replace '^password=',''
```
- 匿名 `api.github.com` 很快 403（60 次/小时）；带 `Authorization: Bearer $token` 是 5000 次/小时。
- **job 日志与 artifact 必须认证**；日志接口会 302 到签名地址，`-MaximumRedirection 5` 跟着走。

## 四、原生探针与截图

- `SetProcessDPIAware()` 之后再调 `GetWindowRect` / `CopyFromScreen`，坐标才和物理像素一致；
  Electron 侧的 `desktopCapturer` 通常比 GDI 更可靠（含按 DIP 裁剪）。
- 注入按键或截图前**必须证明前台**：`GetForegroundWindow() -eq $hwnd`。抢前台用
  `ShowWindow(SW_RESTORE)` + `AttachThreadInput` + `BringWindowToTop` + `SetForegroundWindow`，
  失败要重试；本机曾把 `Ctrl+R` 误发给用户正在使用的窗口（一次点击只激活窗口、不传递键也是常态）。
- `Add-Type` 内联 C# 用到 `System.Drawing`，必须 `-ReferencedAssemblies System.Drawing`。
- 位图缩放/裁剪显式 `[int]`：`$w*2` 在 PowerShell 里可能被当成数组，`DrawImage` 会报「参数无效」。
- 截图只截窗口矩形不够，先确认窗口 rect 已按 DPI 换算；窗口被移动后要**重新取 rect**（曾因此截到别的窗口）。

## 五、后台作业与输出

- 长命令落盘再增量读：`cmd *> "$env:TEMP\x.log"`；**不要** `| tail`（后台时永不产生增量输出），
  也不要靠管道退出码判断成功。
- 脚本里大量 `Add-Content` 落盘时，`job_output` 只会显示 `(no new output) [status: running]` ——
  这**不是卡死**，去读那个日志文件（`Get-Content $log -Tail 10`）。
- `Write-Host` 不进管道（适合做进度），`Write-Output` 会进返回值管道（函数里混用会让返回值变成数组，
  用 `@()`/`return` 明确收口）。
