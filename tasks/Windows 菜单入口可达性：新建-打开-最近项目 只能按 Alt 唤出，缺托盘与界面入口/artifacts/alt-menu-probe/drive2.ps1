# Second, focused Windows probe run (one-off diagnostic, not product code).
#  A) Validate the isMenuBarVisible() oracle: force a real menu bar (setAutoHideMenuBar(false))
#     and measure how it lays out against the 40px custom title bar (titleBarOverlay).
#  B) Tray feasibility: create a real tray icon with the product icon + the proposed menu
#     (New / Open / Recent), then prove whether the icon is directly visible in the
#     notification area and whether a single right-click opens the menu.
# ASCII-only on purpose: Windows PowerShell 5.1 reads BOM-less .ps1 as ANSI.
param(
  [string]$ElectronPath = 'D:\dsh-project-desktop-development\resources\dsh-project-desktop\.cache\runtime\dsh-plugin-desktop\node_modules\electron\dist\electron.exe',
  [string]$TrayIcon = 'D:\dsh-project-desktop-development\resources\dsh-project-desktop\assets\tray\tray-icon-blue.png'
)

$ErrorActionPreference = 'Stop'
$probeDir = $PSScriptRoot
$runDir = Join-Path $probeDir 'run2'
$evidenceDir = Join-Path (Split-Path -Parent $probeDir) 'evidence'
if (Test-Path $runDir) { Remove-Item -Recurse -Force $runDir -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path $runDir, $evidenceDir | Out-Null
$statePath = Join-Path $runDir 'state.json'
$cmdPath = Join-Path $runDir 'cmd.json'
$logPath = Join-Path $evidenceDir 'alt-menu-probe-run2.log'
$transcript = New-Object System.Collections.Generic.List[string]

function Say([string]$text) {
  $line = "[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss.fff'), $text
  $transcript.Add($line)
  Write-Host $line
  [System.IO.File]::WriteAllLines($logPath, $transcript)
}

if (-not (Test-Path $ElectronPath)) { throw "electron.exe not found: $ElectronPath" }
if (-not (Test-Path $TrayIcon)) { throw "tray icon not found: $TrayIcon" }

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public static class ProbeNative2 {
  [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
  [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, UIntPtr dwExtraInfo);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
  [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
  [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
  [DllImport("user32.dll")] public static extern IntPtr FindWindow(string cls, string win);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(IntPtr hWnd, StringBuilder sb, int max);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern int GetSystemMetrics(int index);
}
"@

# Must happen before any GDI/screen query so screen capture uses physical pixels.
[ProbeNative2]::SetProcessDPIAware() | Out-Null

$K_ESC = 0x1B; $K_ALT_L = @{vk = 0xA4; scan = 0x38; flags = 0}; $K_F10 = @{vk = 0x79; scan = 0x44; flags = 0}
$RIGHTDOWN = 0x0008; $RIGHTUP = 0x0010

function Key([hashtable]$k, [bool]$up) {
  $flags = [uint32]$k.flags
  if ($up) { $flags = $flags -bor 2 }
  [ProbeNative2]::keybd_event([byte]$k.vk, [byte]$k.scan, $flags, [UIntPtr]::Zero)
}
function Tap-Key([hashtable]$k, [int]$holdMs = 90) {
  Key $k $false; Start-Sleep -Milliseconds $holdMs; Key $k $true; Start-Sleep -Milliseconds 80
}
function Class-Of([IntPtr]$h) {
  if ($h -eq [IntPtr]::Zero) { return '<null>' }
  $sb = New-Object System.Text.StringBuilder 256
  [ProbeNative2]::GetClassName($h, $sb, 256) | Out-Null
  return $sb.ToString()
}
function Focus-Window([IntPtr]$hwnd) {
  [ProbeNative2]::ShowWindow($hwnd, 9) | Out-Null
  if ([ProbeNative2]::GetForegroundWindow() -eq $hwnd) { return $true }
  [ProbeNative2]::SetForegroundWindow($hwnd) | Out-Null
  Start-Sleep -Milliseconds 250
  if ([ProbeNative2]::GetForegroundWindow() -eq $hwnd) { return $true }
  $fgPid = [uint32]0
  $fgThread = [ProbeNative2]::GetWindowThreadProcessId([ProbeNative2]::GetForegroundWindow(), [ref]$fgPid)
  $curThread = [ProbeNative2]::GetCurrentThreadId()
  [ProbeNative2]::AttachThreadInput($curThread, $fgThread, $true) | Out-Null
  [ProbeNative2]::BringWindowToTop($hwnd) | Out-Null
  [ProbeNative2]::SetForegroundWindow($hwnd) | Out-Null
  [ProbeNative2]::AttachThreadInput($curThread, $fgThread, $false) | Out-Null
  Start-Sleep -Milliseconds 250
  return ([ProbeNative2]::GetForegroundWindow() -eq $hwnd)
}
function Save-Region([string]$path, [int]$x, [int]$y, [int]$w, [int]$h) {
  $bmp = New-Object System.Drawing.Bitmap($w, $h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($x, $y, 0, 0, $bmp.Size)
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
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
  if ($null -eq $r) { Say ("SNAP {0,-32} <no result>" -f $name); return $null }
  if ($r.error) { Say ("SNAP {0,-32} ERROR {1}" -f $name, $r.error); return $r }
  $c = $r.counters
  Say ("SNAP {0,-32} label={1} menuBarVisible={2,-5} autoHide={3,-5} focused={4,-5} bounds={5}x{6} content={7}x{8} inner={9}x{10} N/O/W/rel={11}/{12}/{13}/{14}" -f `
    $name, $r.label, $r.isMenuBarVisible, $r.isMenuBarAutoHide, $r.isFocused, $r.bounds.width, $r.bounds.height,
    $r.contentBounds.width, $r.contentBounds.height, $r.renderer.iw, $r.renderer.ih,
    $c.newProject, $c.openProject, $c.closeProject, $c.reloads)
  return $r
}
function Capture([string]$name, [string]$label = 'A') {
  $r = Invoke-Probe 'capture' $name $label
  if ($null -eq $r) { Say "CAPTURE $name <failed>"; return }
  if ($r.error) { Say "CAPTURE $name ERROR $($r.error)"; return }
  Say ("CAPTURE {0,-32} image={1}x{2} k={3}" -f $name, $r.image.width, $r.image.height, $r.k)
}

# ------------------------------------------------------------------ run
$env:PROBE_DIR = $runDir
$env:PROBE_EVIDENCE = $evidenceDir
Say "electron: $ElectronPath"
Say "tray icon: $TrayIcon"
Say ("process DPI aware: virtual screen = {0}x{1}" -f [ProbeNative2]::GetSystemMetrics(78), [ProbeNative2]::GetSystemMetrics(79))
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
$hwndA = [IntPtr][int64]$st.windows.A.hwnd
$hwndB = [IntPtr][int64]$st.windows.B.hwnd
$scale = [double]$st.displays[0].scaleFactor
$screenW = [ProbeNative2]::GetSystemMetrics(78)
$screenH = [ProbeNative2]::GetSystemMetrics(79)
$results = @{}

Focus-Window $hwndA | Out-Null
$results.oracle_baselineAutoHide = Snap 'A-oracle-baseline'
# Force a real menu bar: setAutoHideMenuBar(false) is the only reliable way on Windows.
$r = Invoke-Probe 'setAutoHideMenuBar' $false 'A'
Say ("SET setAutoHideMenuBar(false) -> $($r | ConvertTo-Json -Compress)")
Start-Sleep -Milliseconds 600
$results.oracle_menuBarShown = Snap 'A-menubar-shown'
Capture '10-A-menubar-shown' 'A'
$results.oracle_altHides = $(Tap-Key $K_ALT_L; Start-Sleep -Milliseconds 500; Snap 'A-menubar-shown-left-Alt')
$results.oracle_f10 = $(Tap-Key $K_F10; Start-Sleep -Milliseconds 500; Snap 'A-menubar-shown-F10')
$r = Invoke-Probe 'setAutoHideMenuBar' $true 'A'
Say ("SET setAutoHideMenuBar(true) -> $($r | ConvertTo-Json -Compress)")
Start-Sleep -Milliseconds 500
$results.oracle_backToAutoHide = Snap 'A-back-to-autohide'
$r = Invoke-Probe 'setMenuBarVisibility' $true 'A'
Start-Sleep -Milliseconds 500
$results.oracle_visibilityTrueWhileAutoHide = Snap 'A-setMenuBarVisibility-true'

# Control window B (standard frame): same oracle
Focus-Window $hwndB | Out-Null
$results.oracleB_before = Snap 'B-oracle-before' 'B'
Invoke-Probe 'setAutoHideMenuBar' $false 'B' | Out-Null
Start-Sleep -Milliseconds 600
$results.oracleB_menuBarShown = Snap 'B-menubar-shown' 'B'
Capture '11-B-menubar-shown' 'B'
Invoke-Probe 'setAutoHideMenuBar' $true 'B' | Out-Null

# ---- Tray feasibility
$r = Invoke-Probe 'trayCreate' $TrayIcon 'A'
Say ("TRAY create -> $($r | ConvertTo-Json -Compress)")
Start-Sleep -Milliseconds 1200
$info = Invoke-Probe 'trayInfo' $null 'A'
Say ("TRAY info -> $($info | ConvertTo-Json -Compress)")
Capture '12-tray-with-probe-icon' 'A'
Start-Sleep -Milliseconds 400

if ($info -and $info.bounds -and $info.bounds.width -gt 0) {
  $cx = [int][math]::Round(($info.bounds.x + $info.bounds.width / 2) * $scale)
  $cy = [int][math]::Round(($info.bounds.y + $info.bounds.height / 2) * $scale)
  Say "TRAY right-click at physical ($cx,$cy); tray bounds (DIP) = $($info.bounds | ConvertTo-Json -Compress)"
  [ProbeNative2]::SetCursorPos($cx, $cy) | Out-Null
  Start-Sleep -Milliseconds 250
  [ProbeNative2]::mouse_event($RIGHTDOWN, 0, 0, 0, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 80
  [ProbeNative2]::mouse_event($RIGHTUP, 0, 0, 0, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 450
  $popup = [ProbeNative2]::FindWindow('#32768', $null)
  $fg = [ProbeNative2]::GetForegroundWindow()
  Say ("TRAY popup check: FindWindow('#32768')={0} (class='{1}') foreground=0x{2:x} (class='{3}')" -f `
    $popup, (Class-Of $popup), [int64]$fg, (Class-Of $fg))
  $shot = Join-Path $evidenceDir '13-tray-context-menu-open.png'
  Save-Region $shot ([math]::Max(0, $screenW - 1400)) ([math]::Max(0, $screenH - 900)) ([math]::Min(1400, $screenW)) ([math]::Min(900, $screenH))
  Say "TRAY screenshot while menu open -> 13-tray-context-menu-open.png"
  Tap-Key $K_ESC 60 | Out-Null
  Start-Sleep -Milliseconds 400
  $after = [ProbeNative2]::FindWindow('#32768', $null)
  Say "TRAY popup after Escape: FindWindow('#32768')=$after"
} else {
  Say 'TRAY icon bounds unavailable: the icon is probably hidden in the Windows 11 overflow flyout'
  $shot = Join-Path $evidenceDir '13-tray-region-after-create.png'
  Save-Region $shot ([math]::Max(0, $screenW - 1400)) ([math]::Max(0, $screenH - 400)) ([math]::Min(1400, $screenW)) ([math]::Min(400, $screenH))
}
Invoke-Probe 'trayDestroy' $null 'A' | Out-Null

# ---- clearMenu oracle: does an empty application menu leave accelerators dead?
Focus-Window $hwndA | Out-Null
Invoke-Probe 'clearMenu' $null 'A' | Out-Null
Start-Sleep -Milliseconds 400
$results.clearedMenu = Snap 'A-cleared-menu'

$final = Read-State
Invoke-Probe 'quit' | Out-Null
Start-Sleep -Milliseconds 600
if (-not $proc.HasExited) { $proc.Kill() }
[System.IO.File]::WriteAllText((Join-Path $evidenceDir 'alt-menu-probe-run2-state.json'), ($final | ConvertTo-Json -Depth 12), (New-Object System.Text.UTF8Encoding($false)))
[System.IO.File]::WriteAllText((Join-Path $evidenceDir 'alt-menu-probe-run2-summary.json'), ($results | ConvertTo-Json -Depth 12), (New-Object System.Text.UTF8Encoding($false)))
Say "done -> $evidenceDir"
