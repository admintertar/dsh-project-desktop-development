# Fifth, focused Windows probe run (one-off diagnostic, not product code).
#  A) Decisive menu-bar question: with the product's exact window options (titleBarStyle:'hidden'
#     + titleBarOverlay + autoHideMenuBar:true), can a native menu bar be displayed at all once
#     the window's menu is assigned explicitly (setMenu) and visibility is forced?
#     Window B (standard frame) is the positive control that reproduces the run-3 success.
#  B) Tray menu content: popUpContextMenu() on a tray icon carrying the proposed menu
#     (New / Open / Recent / Welcome), screenshotted while open.
# ASCII-only on purpose: Windows PowerShell 5.1 reads BOM-less .ps1 as ANSI.
param(
  [string]$ElectronPath = 'D:\dsh-project-desktop-development\resources\dsh-project-desktop\.cache\runtime\dsh-plugin-desktop\node_modules\electron\dist\electron.exe',
  [string]$ProductTrayIcon = 'D:\dsh-project-desktop-development\resources\dsh-project-desktop\assets\tray\tray-icon-blue.png'
)

$ErrorActionPreference = 'Stop'
$probeDir = $PSScriptRoot
$runDir = Join-Path $probeDir 'run5'
$evidenceDir = Join-Path (Split-Path -Parent $probeDir) 'evidence'
if (Test-Path $runDir) { Remove-Item -Recurse -Force $runDir -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path $runDir, $evidenceDir | Out-Null
$statePath = Join-Path $runDir 'state.json'
$cmdPath = Join-Path $runDir 'cmd.json'
$logPath = Join-Path $evidenceDir 'alt-menu-probe-run5.log'
$transcript = New-Object System.Collections.Generic.List[string]

function Say([string]$text) {
  $line = "[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss.fff'), $text
  $transcript.Add($line); Write-Host $line; [System.IO.File]::WriteAllLines($logPath, $transcript)
}
if (-not (Test-Path $ElectronPath)) { throw "electron.exe not found: $ElectronPath" }

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Text;
public static class ProbeNative5 {
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
"@ -ReferencedAssemblies System.Drawing
[ProbeNative5]::SetProcessDPIAware() | Out-Null

$SCREEN_W = [ProbeNative5]::GetSystemMetrics(78); $SCREEN_H = [ProbeNative5]::GetSystemMetrics(79)
$K_ESC = @{vk = 0x1B; scan = 0x01; flags = 0}
$K_ALT_L = @{vk = 0xA4; scan = 0x38; flags = 0}
$K_F10 = @{vk = 0x79; scan = 0x44; flags = 0}

function Key([hashtable]$k, [bool]$up) { $flags = [uint32]$k.flags; if ($up) { $flags = $flags -bor 2 }; [ProbeNative5]::keybd_event([byte]$k.vk, [byte]$k.scan, $flags, [UIntPtr]::Zero) }
function Tap-Key([hashtable]$k, [int]$holdMs = 90) { Key $k $false; Start-Sleep -Milliseconds $holdMs; Key $k $true; Start-Sleep -Milliseconds 80 }
function Class-Of([IntPtr]$h) { if ($h -eq [IntPtr]::Zero) { return '<null>' }; $sb = New-Object System.Text.StringBuilder 256; [ProbeNative5]::GetClassName($h, $sb, 256) | Out-Null; return $sb.ToString() }
function Focus-Window([IntPtr]$hwnd) {
  [ProbeNative5]::ShowWindow($hwnd, 9) | Out-Null
  if ([ProbeNative5]::GetForegroundWindow() -eq $hwnd) { return $true }
  [ProbeNative5]::SetForegroundWindow($hwnd) | Out-Null
  Start-Sleep -Milliseconds 250
  if ([ProbeNative5]::GetForegroundWindow() -eq $hwnd) { return $true }
  $fgPid = [uint32]0
  $fgThread = [ProbeNative5]::GetWindowThreadProcessId([ProbeNative5]::GetForegroundWindow(), [ref]$fgPid)
  $curThread = [ProbeNative5]::GetCurrentThreadId()
  [ProbeNative5]::AttachThreadInput($curThread, $fgThread, $true) | Out-Null
  [ProbeNative5]::BringWindowToTop($hwnd) | Out-Null
  [ProbeNative5]::SetForegroundWindow($hwnd) | Out-Null
  [ProbeNative5]::AttachThreadInput($curThread, $fgThread, $false) | Out-Null
  Start-Sleep -Milliseconds 250
  return ([ProbeNative5]::GetForegroundWindow() -eq $hwnd)
}
function Save-Region([string]$path, [int]$x, [int]$y, [int]$w, [int]$h) {
  $bmp = New-Object System.Drawing.Bitmap($w, $h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($x, $y, 0, 0, $bmp.Size)
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
}

$script:seq = 0
function Read-State() {
  if (-not (Test-Path $statePath)) { return $null }
  for ($i = 0; $i -lt 25; $i++) { try { return (Get-Content $statePath -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { Start-Sleep -Milliseconds 60 } }
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
  if ($null -eq $r) { Say ("SNAP {0,-40} <no result>" -f $name); return $null }
  if ($r.error) { Say ("SNAP {0,-40} ERROR {1}" -f $name, $r.error); return $r }
  Say ("SNAP {0,-40} label={1} menuBarVisible={2,-5} autoHide={3,-5} focused={4,-5} bounds={5}x{6} content={7}x{8} inner={9}x{10}" -f `
    $name, $r.label, $r.isMenuBarVisible, $r.isMenuBarAutoHide, $r.isFocused, $r.bounds.width, $r.bounds.height,
    $r.contentBounds.width, $r.contentBounds.height, $r.renderer.iw, $r.renderer.ih)
  return $r
}
function Capture([string]$name, [string]$label = 'A') {
  $r = Invoke-Probe 'capture' $name $label
  if ($null -eq $r) { Say "CAPTURE $name <failed>"; return $null }
  if ($r.error) { Say "CAPTURE $name ERROR $($r.error)"; return $null }
  Say ("CAPTURE {0,-40} image={1}x{2}" -f $name, $r.image.width, $r.image.height)
  return $r
}

# ------------------------------------------------------------------ run
$env:PROBE_DIR = $runDir
$env:PROBE_EVIDENCE = $evidenceDir
$proc = Start-Process -FilePath $ElectronPath -ArgumentList "`"$probeDir`"" -PassThru `
  -RedirectStandardOutput (Join-Path $runDir 'electron-stdout.log') `
  -RedirectStandardError (Join-Path $runDir 'electron-stderr.log')
Say "started electron pid=$($proc.Id)"
$deadline = (Get-Date).AddSeconds(40)
$st = $null
while ((Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 250; $st = Read-State; if ($st -and $st.windows -and $st.windows.A.hwnd) { break } }
if (-not $st -or -not $st.windows.A.hwnd) { throw 'probe windows never became ready' }
$hwndA = [IntPtr][int64]$st.windows.A.hwnd
$hwndB = [IntPtr][int64]$st.windows.B.hwnd
$scale = [double]$st.displays[0].scaleFactor
$results = @{}

# ---- A) can the product window ever show a menu bar?
Focus-Window $hwndA | Out-Null
$results.A_baseline = Snap 'A-product-baseline'
$r = Invoke-Probe 'applyMenu' $null 'A'
Say ("A.setMenu(appMenu) -> $($r | ConvertTo-Json -Compress)")
Start-Sleep -Milliseconds 700
$results.A_afterSetMenu = Snap 'A-product-after-setMenu'
$r = Invoke-Probe 'setMenuBarVisibility' $true 'A'
Say ("A.setMenuBarVisibility(true) -> $($r | ConvertTo-Json -Compress)")
Start-Sleep -Milliseconds 900
$results.A_afterVisibilityTrue = Snap 'A-product-after-visibility-true'
Capture '60-A-product-visibility-true' 'A'
$r = Invoke-Probe 'setAutoHideMenuBar' $false 'A'
Say ("A.setAutoHideMenuBar(false) -> $($r | ConvertTo-Json -Compress)")
Start-Sleep -Milliseconds 900
$results.A_afterAutoHideFalse = Snap 'A-product-autoHide-false'
Capture '61-A-product-autoHide-false' 'A'
$results.A_alt = $(Tap-Key $K_ALT_L; Start-Sleep -Milliseconds 500; Snap 'A-product-left-Alt')
$results.A_f10 = $(Tap-Key $K_F10; Start-Sleep -Milliseconds 500; Snap 'A-product-F10')
Capture '62-A-product-after-keys' 'A'

# ---- positive control: standard-frame window B
Focus-Window $hwndB | Out-Null
$r = Invoke-Probe 'applyMenu' $null 'B'
Say ("B.setMenu(appMenu) -> $($r | ConvertTo-Json -Compress)")
Start-Sleep -Milliseconds 500
Invoke-Probe 'setMenuBarVisibility' $true 'B' | Out-Null
Start-Sleep -Milliseconds 900
$results.B_control = Snap 'B-control-menu-bar' 'B'
Capture '63-B-control-menu-bar' 'B'
$results.B_controlAlt = $(Tap-Key $K_ALT_L; Start-Sleep -Milliseconds 500; Snap 'B-control-after-left-Alt' 'B')
Capture '64-B-control-after-alt' 'B'

# ---- B) tray menu content for the proposed menu
$r = Invoke-Probe 'trayCreate' $ProductTrayIcon 'A'
Say ("TRAY create(product icon) -> $($r | ConvertTo-Json -Compress)")
Start-Sleep -Milliseconds 1200
[ProbeNative5]::SetCursorPos([int]($SCREEN_W / 2), [int]($SCREEN_H / 2)) | Out-Null
Start-Sleep -Milliseconds 200
$r = Invoke-Probe 'trayPopup' $null 'A'
Say ("TRAY popUpContextMenu() -> $($r | ConvertTo-Json -Compress)")
Start-Sleep -Milliseconds 400
$popup = [ProbeNative5]::FindWindow('#32768', $null)
Say ("TRAY popup FindWindow('#32768')={0} class='{1}'" -f $popup, (Class-Of $popup))
$shot = Join-Path $evidenceDir '65-tray-proposed-menu.png'
Save-Region $shot ([int]($SCREEN_W / 2 - 100)) ([int]($SCREEN_H / 2 - 100)) 700 600
Say "TRAY menu screenshot -> 65-tray-proposed-menu.png"
Tap-Key $K_ESC 60 | Out-Null
Start-Sleep -Milliseconds 300
Invoke-Probe 'trayDestroy' $null 'A' | Out-Null

$final = Read-State
Invoke-Probe 'quit' | Out-Null
Start-Sleep -Milliseconds 600
if (-not $proc.HasExited) { $proc.Kill() }
[System.IO.File]::WriteAllText((Join-Path $evidenceDir 'alt-menu-probe-run5-state.json'), ($final | ConvertTo-Json -Depth 12), (New-Object System.Text.UTF8Encoding($false)))
[System.IO.File]::WriteAllText((Join-Path $evidenceDir 'alt-menu-probe-run5-summary.json'), ($results | ConvertTo-Json -Depth 12), (New-Object System.Text.UTF8Encoding($false)))
Say "done -> $evidenceDir"
