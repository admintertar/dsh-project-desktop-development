# Windows 菜单可达性探针驱动（一次性诊断，非产品代码）
# 用法: powershell -File drive.ps1
# 前置: <shell>/.cache/runtime/dsh-plugin-desktop/node_modules/electron/dist/electron.exe
#
# 说明：键位全部用 user32!keybd_event 真注入（等价于 SendInput/hardware 路径），
# 每次注入前都用 GetForegroundWindow 证明目标窗口确为前台，否则直接失败退出。
param(
  [string]$ElectronPath = 'D:\dsh-project-desktop-development\resources\dsh-project-desktop\.cache\runtime\dsh-plugin-desktop\node_modules\electron\dist\electron.exe'
)

$ErrorActionPreference = 'Stop'
$probeDir = $PSScriptRoot
$runDir = Join-Path $probeDir 'run'
$evidenceDir = Join-Path (Split-Path -Parent $probeDir) 'evidence'
if (Test-Path $runDir) { Remove-Item -Recurse -Force $runDir -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path $runDir, $evidenceDir | Out-Null
$statePath = Join-Path $runDir 'state.json'
$cmdPath = Join-Path $runDir 'cmd.json'
$logPath = Join-Path $evidenceDir 'alt-menu-probe.log'
$transcript = New-Object System.Collections.Generic.List[string]

function Say([string]$text) {
  $line = "[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss.fff'), $text
  $transcript.Add($line)
  Write-Host $line
  [System.IO.File]::WriteAllLines($logPath, $transcript)
}

if (-not (Test-Path $ElectronPath)) { throw "electron.exe not found: $ElectronPath" }

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class ProbeNative {
  [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
  [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
  [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
}
"@

# ---- 键位定义（scan code 用真实键盘扫描码；0xA5/0x38 右 Alt 带 EXTENDEDKEY 位）
$EXTENDED = 1; $SCANCODE = 8
$K_CTRL  = @{vk = 0xA2; scan = 0x1D; flags = 0}
$K_SHIFT = @{vk = 0xA0; scan = 0x2A; flags = 0}
$K_ALT_L = @{vk = 0xA4; scan = 0x38; flags = 0}
$K_ALT_G = @{vk = 0x12; scan = 0x38; flags = 0}
$K_ALT_S = @{vk = 0x00; scan = 0x38; flags = $SCANCODE}
$K_ALT_R = @{vk = 0xA5; scan = 0x38; flags = $EXTENDED}
$K_F10   = @{vk = 0x79; scan = 0x44; flags = 0}
$K_N     = @{vk = 0x4E; scan = 0x31; flags = 0}
$K_O     = @{vk = 0x4F; scan = 0x18; flags = 0}
$K_W     = @{vk = 0x57; scan = 0x11; flags = 0}
$K_R     = @{vk = 0x52; scan = 0x13; flags = 0}

function Key([hashtable]$k, [bool]$up) {
  $flags = [uint32]$k.flags
  if ($up) { $flags = $flags -bor 2 }
  [ProbeNative]::keybd_event([byte]$k.vk, [byte]$k.scan, $flags, [UIntPtr]::Zero)
}

function Tap-Key([hashtable]$k, [int]$holdMs = 90) {
  Key $k $false
  Start-Sleep -Milliseconds $holdMs
  Key $k $true
  Start-Sleep -Milliseconds 80
}

function Send-Combo([hashtable[]]$keys) {
  foreach ($k in $keys) { Key $k $false; Start-Sleep -Milliseconds 45 }
  for ($i = $keys.Count - 1; $i -ge 0; $i--) { Key $keys[$i] $true; Start-Sleep -Milliseconds 45 }
}

function Focus-Window([IntPtr]$hwnd) {
  [ProbeNative]::ShowWindow($hwnd, 9) | Out-Null
  if ([ProbeNative]::GetForegroundWindow() -eq $hwnd) { return $true }
  [ProbeNative]::SetForegroundWindow($hwnd) | Out-Null
  Start-Sleep -Milliseconds 250
  if ([ProbeNative]::GetForegroundWindow() -eq $hwnd) { return $true }
  $fgPid = [uint32]0
  $fgThread = [ProbeNative]::GetWindowThreadProcessId([ProbeNative]::GetForegroundWindow(), [ref]$fgPid)
  $curThread = [ProbeNative]::GetCurrentThreadId()
  [ProbeNative]::AttachThreadInput($curThread, $fgThread, $true) | Out-Null
  [ProbeNative]::BringWindowToTop($hwnd) | Out-Null
  [ProbeNative]::SetForegroundWindow($hwnd) | Out-Null
  [ProbeNative]::AttachThreadInput($curThread, $fgThread, $false) | Out-Null
  Start-Sleep -Milliseconds 250
  return ([ProbeNative]::GetForegroundWindow() -eq $hwnd)
}

$script:seq = 0
function Read-State() {
  if (-not (Test-Path $statePath)) { return $null }
  for ($i = 0; $i -lt 25; $i++) {
    try { return (Get-Content $statePath -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { Start-Sleep -Milliseconds 60 }
  }
  throw 'state.json unreadable'
}

function Invoke-Probe([string]$cmd, $arg = $null, [string]$label = 'A') {
  $script:seq++
  $payload = [ordered]@{seq = $script:seq; cmd = $cmd; label = $label}
  if ($null -ne $arg) { $payload.arg = $arg }
  [System.IO.File]::WriteAllText($cmdPath, ($payload | ConvertTo-Json -Compress), (New-Object System.Text.UTF8Encoding($false)))
  $deadline = (Get-Date).AddSeconds(25)
  while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 90
    $st = Read-State
    if (-not $st) { continue }
    $hit = $st.steps | Where-Object { $_.name -eq 'result' -and $_.seq -eq $script:seq } | Select-Object -First 1
    if ($hit) { return $hit.result }
  }
  Say "WARN probe command timed out: $cmd (label=$label, seq=$script:seq)"
  return $null
}

function Snap([string]$name, [string]$label = 'A') {
  $r = Invoke-Probe 'snapshot' $null $label
  if ($null -eq $r) { Say ("SNAP {0,-30} <no result: window gone?>" -f $name); return $null }
  if ($r.error) { Say ("SNAP {0,-30} ERROR {1}" -f $name, $r.error); return $r }
  $c = $r.counters
  Say ("SNAP {0,-30} label={1} menuBarVisible={2,-5} autoHide={3,-5} focused={4,-5} bounds={5}x{6}@{7},{8} content={9}x{10} inner={11}x{12} hdrTop={13} N/O/W/rel={14}/{15}/{16}/{17}" -f `
    $name, $r.label, $r.isMenuBarVisible, $r.isMenuBarAutoHide, $r.isFocused,
    $r.bounds.width, $r.bounds.height, $r.bounds.x, $r.bounds.y,
    $r.contentBounds.width, $r.contentBounds.height,
    $r.renderer.iw, $r.renderer.ih, $r.renderer.headerTop,
    $c.newProject, $c.openProject, $c.closeProject, $c.reloads)
  return $r
}

function Capture([string]$name, [string]$label = 'A') {
  $r = Invoke-Probe 'capture' $name $label
  if ($null -eq $r) { Say "CAPTURE $name <failed>"; return }
  if ($r.error) { Say "CAPTURE $name ERROR $($r.error)"; return }
  Say ("CAPTURE {0,-30} image={1}x{2} k={3} files={4}" -f $name, $r.image.width, $r.image.height, $r.k, (($r.written | ForEach-Object { $_.file }) -join ', '))
}

function Select-Window([string]$label, [IntPtr]$hwnd) {
  Invoke-Probe 'focus' $null $label | Out-Null
  Start-Sleep -Milliseconds 250
  $ok = Focus-Window $hwnd
  Say "foreground proof [$label]: GetForegroundWindow==hwnd -> $ok"
  if (-not $ok) { throw "window $label could not be proven foreground; refusing to inject keys" }
}

# ------------------------------------------------------------------ 运行
$env:PROBE_DIR = $runDir
$env:PROBE_EVIDENCE = $evidenceDir
Say "electron: $ElectronPath"
Say "evidence: $evidenceDir"
$proc = Start-Process -FilePath $ElectronPath -ArgumentList "`"$probeDir`"" -PassThru `
  -RedirectStandardOutput (Join-Path $runDir 'electron-stdout.log') `
  -RedirectStandardError (Join-Path $runDir 'electron-stderr.log')
Say "started electron pid=$($proc.Id)"

$deadline = (Get-Date).AddSeconds(40)
$st = $null
while ((Get-Date) -lt $deadline) {
  Start-Sleep -Milliseconds 250
  $st = Read-State
  if ($st -and $st.windows -and $st.windows.A.hwnd) { break }
}
if (-not $st -or -not $st.windows.A.hwnd) { throw 'probe windows never became ready' }
Say "electron=$($st.electron) chrome=$($st.chrome) node=$($st.node) os=$($st.osRelease)"
foreach ($d in $st.displays) { Say ("display id={0} bounds={1}x{2}@{3},{4} scaleFactor={5} workArea={6},{7} {8}x{9}" -f $d.id, $d.bounds.width, $d.bounds.height, $d.bounds.x, $d.bounds.y, $d.scaleFactor, $d.workArea.x, $d.workArea.y, $d.workArea.width, $d.workArea.height) }

$hwndA = [IntPtr][int64]$st.windows.A.hwnd
$hwndB = [IntPtr][int64]$st.windows.B.hwnd
$results = @{}

# ---- 窗口 A：产品同款窗口选项
Select-Window 'A' $hwndA
$results.A_baseline = Snap 'A-baseline'
Capture '01-A-baseline' 'A'

$results.A_altL = $(Tap-Key $K_ALT_L; Start-Sleep -Milliseconds 500; Snap 'A-after-left-Alt')
$results.A_altL2 = $(Tap-Key $K_ALT_L; Start-Sleep -Milliseconds 500; Snap 'A-after-left-Alt-2nd')
$results.A_altGeneric = $(Tap-Key $K_ALT_G; Start-Sleep -Milliseconds 500; Snap 'A-after-VK_MENU')
$results.A_altScanOnly = $(Tap-Key $K_ALT_S; Start-Sleep -Milliseconds 500; Snap 'A-after-Alt-scanonly')
$results.A_f10 = $(Tap-Key $K_F10; Start-Sleep -Milliseconds 500; Snap 'A-after-F10')
$results.A_altR = $(Tap-Key $K_ALT_R; Start-Sleep -Milliseconds 500; Snap 'A-after-right-Alt')
Capture '02-A-after-alt-variants' 'A'

# 强制显示菜单栏：看它与 40px 自定义标题栏的关系（下压内容 or 覆盖）
Invoke-Probe 'setMenuBarVisibility' $true 'A' | Out-Null
Start-Sleep -Milliseconds 500
$results.A_menuForcedVisible = Snap 'A-menu-forced-visible'
Capture '03-A-menu-forced-visible' 'A'
Invoke-Probe 'setMenuBarVisibility' $false 'A' | Out-Null
Start-Sleep -Milliseconds 400
$results.A_menuForcedHidden = Snap 'A-menu-forced-hidden'

# 菜单栏 auto-hide 时 accelerator 是否仍生效
Send-Combo @($K_CTRL, $K_SHIFT, $K_N); Start-Sleep -Milliseconds 700
$results.A_accelNew = Snap 'A-accel-CtrlShiftN'
Send-Combo @($K_CTRL, $K_O); Start-Sleep -Milliseconds 700
$results.A_accelOpen = Snap 'A-accel-CtrlO'
Send-Combo @($K_CTRL, $K_R); Start-Sleep -Milliseconds 1500
$results.A_accelReload = Snap 'A-accel-CtrlR'

# 对齐官方 win32：removeMenu() 之后 accelerator 是否还活着
Invoke-Probe 'removeMenu' $null 'A' | Out-Null
Start-Sleep -Milliseconds 500
$results.A_afterRemoveMenu = Snap 'A-after-removeMenu'
Send-Combo @($K_CTRL, $K_SHIFT, $K_N); Start-Sleep -Milliseconds 700
$results.A_removeMenuAccelNew = Snap 'A-post-removeMenu-CtrlShiftN'
Send-Combo @($K_CTRL, $K_O); Start-Sleep -Milliseconds 700
$results.A_removeMenuAccelOpen = Snap 'A-post-removeMenu-CtrlO'
Send-Combo @($K_CTRL, $K_R); Start-Sleep -Milliseconds 1500
$results.A_removeMenuAccelReload = Snap 'A-post-removeMenu-CtrlR'
$results.A_removeMenuAlt = $(Tap-Key $K_ALT_L; Start-Sleep -Milliseconds 500; Snap 'A-post-removeMenu-left-Alt')
$results.A_removeMenuF10 = $(Tap-Key $K_F10; Start-Sleep -Milliseconds 500; Snap 'A-post-removeMenu-F10')
Capture '04-A-post-remove-menu' 'A'

# ---- 窗口 B：对照组（标准系统边框 + autoHideMenuBar）
Select-Window 'B' $hwndB
$results.B_baseline = Snap 'B-baseline' 'B'
$results.B_altL = $(Tap-Key $K_ALT_L; Start-Sleep -Milliseconds 500; Snap 'B-after-left-Alt' 'B')
$results.B_f10 = $(Tap-Key $K_F10; Start-Sleep -Milliseconds 500; Snap 'B-after-F10' 'B')
Invoke-Probe 'setMenuBarVisibility' $true 'B' | Out-Null
Start-Sleep -Milliseconds 500
$results.B_menuForcedVisible = Snap 'B-menu-forced-visible' 'B'
Capture '05-B-menu-forced-visible' 'B'
Invoke-Probe 'setMenuBarVisibility' $false 'B' | Out-Null
Start-Sleep -Milliseconds 300

# ---- 窗口 A：Ctrl+W 行为（记录用，服务姊妹任务；放在最后以防窗口被关掉）
Select-Window 'A' $hwndA
Send-Combo @($K_CTRL, $K_W); Start-Sleep -Milliseconds 1200
$results.A_afterCtrlW = Snap 'A-after-CtrlW'

$final = Read-State
$lastCounters = $results.A_afterCtrlW
if (-not $lastCounters) { $lastCounters = $results.A_removeMenuAlt }
Say ("FINAL counters new/open/close/welcome/reloads = {0}/{1}/{2}/{3}/{4}" -f `
  $lastCounters.counters.newProject, $lastCounters.counters.openProject, $lastCounters.counters.closeProject, $lastCounters.counters.welcome, $lastCounters.counters.reloads)

Invoke-Probe 'quit' | Out-Null
Start-Sleep -Milliseconds 800
if (-not $proc.HasExited) { $proc.Kill() }
foreach ($pair in @(@('alt-menu-probe-state.json', $final), @('alt-menu-probe-summary.json', $results))) {
  [System.IO.File]::WriteAllText((Join-Path $evidenceDir $pair[0]), ($pair[1] | ConvertTo-Json -Depth 12), (New-Object System.Text.UTF8Encoding($false)))
}
Copy-Item $statePath (Join-Path $evidenceDir 'alt-menu-probe-state.raw.json') -Force
Say "done -> $evidenceDir"
