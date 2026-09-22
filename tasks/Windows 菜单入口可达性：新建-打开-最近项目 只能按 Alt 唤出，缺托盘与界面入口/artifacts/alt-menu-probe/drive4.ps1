# Fourth, focused Windows probe run (one-off diagnostic, not product code).
#  A) Product-order menu application: the shell re-applies Menu.setApplicationMenu() *after*
#     windows exist (refreshMenus). Does the native menu bar (and therefore Alt) start working
#     only in that order? This decides whether the earlier negative Alt result is a probe artifact.
#  B) Geometry: where does a real menu bar draw on a custom-title-bar window (40px overlay)?
#  C) Tray: unconditional screenshots around right-clicks, because Windows 11 tray menus are not
#     reliably found by the classic #32768 popup class.
# ASCII-only on purpose: Windows PowerShell 5.1 reads BOM-less .ps1 as ANSI.
param(
  [string]$ElectronPath = 'D:\dsh-project-desktop-development\resources\dsh-project-desktop\.cache\runtime\dsh-plugin-desktop\node_modules\electron\dist\electron.exe'
)

$ErrorActionPreference = 'Stop'
$probeDir = $PSScriptRoot
$runDir = Join-Path $probeDir 'run4'
$evidenceDir = Join-Path (Split-Path -Parent $probeDir) 'evidence'
if (Test-Path $runDir) { Remove-Item -Recurse -Force $runDir -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path $runDir, $evidenceDir | Out-Null
$statePath = Join-Path $runDir 'state.json'
$cmdPath = Join-Path $runDir 'cmd.json'
$logPath = Join-Path $evidenceDir 'alt-menu-probe-run4.log'
$transcript = New-Object System.Collections.Generic.List[string]

function Say([string]$text) {
  $line = "[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss.fff'), $text
  $transcript.Add($line)
  Write-Host $line
  [System.IO.File]::WriteAllLines($logPath, $transcript)
}
if (-not (Test-Path $ElectronPath)) { throw "electron.exe not found: $ElectronPath" }

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Text;
public static class ProbeNative4 {
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
  public static int[] DiffBox(string pathA, string pathB, int x0, int x1, int y0, int y1) {
    using (Bitmap a = new Bitmap(pathA))
    using (Bitmap b = new Bitmap(pathB)) {
      int w = Math.Min(a.Width, b.Width), h = Math.Min(a.Height, b.Height);
      if (x1 > w) x1 = w; if (y1 > h) y1 = h; if (y0 < 0) y0 = 0;
      Rectangle rect = new Rectangle(0, 0, w, h);
      BitmapData da = a.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
      BitmapData db = b.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
      int stride = Math.Abs(da.Stride);
      byte[] ba = new byte[stride * h]; byte[] bb = new byte[stride * h];
      Marshal.Copy(da.Scan0, ba, 0, ba.Length); Marshal.Copy(db.Scan0, bb, 0, bb.Length);
      int minX = int.MaxValue, minY = int.MaxValue, maxX = -1, maxY = -1, count = 0;
      for (int y = y0; y < y1; y++) for (int x = x0; x < x1; x++) {
        int i = y * stride + x * 4;
        int d = Math.Abs(ba[i] - bb[i]) + Math.Abs(ba[i + 1] - bb[i + 1]) + Math.Abs(ba[i + 2] - bb[i + 2]);
        if (d > 48) { count++; if (x < minX) minX = x; if (y < minY) minY = y; if (x > maxX) maxX = x; if (y > maxY) maxY = y; }
      }
      a.UnlockBits(da); b.UnlockBits(db);
      return new int[] {minX, minY, maxX, maxY, count};
    }
  }
}
"@ -ReferencedAssemblies System.Drawing
[ProbeNative4]::SetProcessDPIAware() | Out-Null

$SCREEN_W = [ProbeNative4]::GetSystemMetrics(78); $SCREEN_H = [ProbeNative4]::GetSystemMetrics(79)
$RIGHTDOWN = 0x0008; $RIGHTUP = 0x0010; $LEFTDOWN = 0x0002; $LEFTUP = 0x0004
$K_ESC = @{vk = 0x1B; scan = 0x01; flags = 0}
$K_ALT_L = @{vk = 0xA4; scan = 0x38; flags = 0}
$K_F10 = @{vk = 0x79; scan = 0x44; flags = 0}

function Key([hashtable]$k, [bool]$up) {
  $flags = [uint32]$k.flags; if ($up) { $flags = $flags -bor 2 }
  [ProbeNative4]::keybd_event([byte]$k.vk, [byte]$k.scan, $flags, [UIntPtr]::Zero)
}
function Tap-Key([hashtable]$k, [int]$holdMs = 90) { Key $k $false; Start-Sleep -Milliseconds $holdMs; Key $k $true; Start-Sleep -Milliseconds 80 }
function Class-Of([IntPtr]$h) {
  if ($h -eq [IntPtr]::Zero) { return '<null>' }
  $sb = New-Object System.Text.StringBuilder 256
  [ProbeNative4]::GetClassName($h, $sb, 256) | Out-Null
  return $sb.ToString()
}
function Focus-Window([IntPtr]$hwnd) {
  [ProbeNative4]::ShowWindow($hwnd, 9) | Out-Null
  if ([ProbeNative4]::GetForegroundWindow() -eq $hwnd) { return $true }
  [ProbeNative4]::SetForegroundWindow($hwnd) | Out-Null
  Start-Sleep -Milliseconds 250
  if ([ProbeNative4]::GetForegroundWindow() -eq $hwnd) { return $true }
  $fgPid = [uint32]0
  $fgThread = [ProbeNative4]::GetWindowThreadProcessId([ProbeNative4]::GetForegroundWindow(), [ref]$fgPid)
  $curThread = [ProbeNative4]::GetCurrentThreadId()
  [ProbeNative4]::AttachThreadInput($curThread, $fgThread, $true) | Out-Null
  [ProbeNative4]::BringWindowToTop($hwnd) | Out-Null
  [ProbeNative4]::SetForegroundWindow($hwnd) | Out-Null
  [ProbeNative4]::AttachThreadInput($curThread, $fgThread, $false) | Out-Null
  Start-Sleep -Milliseconds 250
  return ([ProbeNative4]::GetForegroundWindow() -eq $hwnd)
}
function Save-Region([string]$path, [int]$x, [int]$y, [int]$w, [int]$h) {
  $bmp = New-Object System.Drawing.Bitmap($w, $h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($x, $y, 0, 0, $bmp.Size)
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
}
function Click([int]$x, [int]$y, [bool]$right) {
  [ProbeNative4]::SetCursorPos($x, $y) | Out-Null
  Start-Sleep -Milliseconds 220
  $down = if ($right) { $RIGHTDOWN } else { $LEFTDOWN }
  $up = if ($right) { $RIGHTUP } else { $LEFTUP }
  [ProbeNative4]::mouse_event($down, 0, 0, 0, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 80
  [ProbeNative4]::mouse_event($up, 0, 0, 0, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 500
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
  if ($null -eq $r) { Say ("SNAP {0,-38} <no result>" -f $name); return $null }
  if ($r.error) { Say ("SNAP {0,-38} ERROR {1}" -f $name, $r.error); return $r }
  Say ("SNAP {0,-38} label={1} menuBarVisible={2,-5} autoHide={3,-5} focused={4,-5} bounds={5}x{6} content={7}x{8} inner={9}x{10} counters N/O/W/rel={11}/{12}/{13}/{14}" -f `
    $name, $r.label, $r.isMenuBarVisible, $r.isMenuBarAutoHide, $r.isFocused, $r.bounds.width, $r.bounds.height,
    $r.contentBounds.width, $r.contentBounds.height, $r.renderer.iw, $r.renderer.ih,
    $r.counters.newProject, $r.counters.openProject, $r.counters.closeProject, $r.counters.reloads)
  return $r
}
function Capture([string]$name, [string]$label = 'A') {
  $r = Invoke-Probe 'capture' $name $label
  if ($null -eq $r) { Say "CAPTURE $name <failed>"; return $null }
  if ($r.error) { Say "CAPTURE $name ERROR $($r.error)"; return $null }
  Say ("CAPTURE {0,-38} image={1}x{2}" -f $name, $r.image.width, $r.image.height)
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
$hwndC = [IntPtr][int64]$st.windows.C.hwnd
$scale = [double]$st.displays[0].scaleFactor
$results = @{}

# ---- A) product-order menu application
Focus-Window $hwndA | Out-Null
$results.order_beforeReapply = Snap 'A-order-before-reapply'
$r = Invoke-Probe 'reapplyAppMenu' $null 'A'
Say ("REAPPLY Menu.setApplicationMenu() with window already open -> $($r | ConvertTo-Json -Compress)")
Start-Sleep -Milliseconds 800
$results.order_afterReapply = Snap 'A-order-after-reapply'
Capture '40-A-after-reapply-app-menu' 'A'
$results.order_alt1 = $(Tap-Key $K_ALT_L; Start-Sleep -Milliseconds 500; Snap 'A-reapply-left-Alt-1')
Capture '41-A-reapply-after-alt1' 'A'
$results.order_alt2 = $(Tap-Key $K_ALT_L; Start-Sleep -Milliseconds 500; Snap 'A-reapply-left-Alt-2')
Capture '42-A-reapply-after-alt2' 'A'
$results.order_f10 = $(Tap-Key $K_F10; Start-Sleep -Milliseconds 500; Snap 'A-reapply-F10')
Invoke-Probe 'removeMenu' $null 'A' | Out-Null
Start-Sleep -Milliseconds 500
$results.order_afterRemoveMenu = Snap 'A-reapply-after-removeMenu'
$results.order_altAfterRemoveMenu = $(Tap-Key $K_ALT_L; Start-Sleep -Milliseconds 500; Snap 'A-reapply-removeMenu-left-Alt')
Capture '43-A-reapply-after-removeMenu' 'A'

# ---- B) geometry on the custom-title-bar window C
Focus-Window $hwndC | Out-Null
$results.geomC_before = Snap 'C-geom-before' 'C'
$r = Invoke-Probe 'applyMenu' $null 'C'
Say ("APPLY C.setMenu(appMenu) -> $($r | ConvertTo-Json -Compress)")
Start-Sleep -Milliseconds 900
$results.geomC_afterSetMenu = Snap 'C-geom-after-setMenu' 'C'
$r = Invoke-Probe 'setMenuBarVisibility' $true 'C'
Start-Sleep -Milliseconds 900
$results.geomC_afterVisibleTrue = Snap 'C-geom-after-visibility-true' 'C'
Capture '44-C-menu-bar-visible' 'C'
$results.geomC_alt = $(Tap-Key $K_ALT_L; Start-Sleep -Milliseconds 500; Snap 'C-geom-after-left-Alt' 'C')
Capture '45-C-after-left-Alt' 'C'

# ---- C) tray: unconditional screenshots around right-clicks (Windows 11 tray menus)
$beforeFile = Join-Path $evidenceDir '50-desktop-before-tray-clicks.png'
Save-Region $beforeFile ([math]::Max(0, $SCREEN_W - 1400)) ([math]::Max(0, $SCREEN_H - 300)) ([math]::Min(1400, $SCREEN_W)) ([math]::Min(300, $SCREEN_H))
foreach ($cx in @(2999, 2956)) {
  $cy = $SCREEN_H - 48
  Say "TRAY right-click at physical ($cx,$cy)"
  Click $cx $cy $true
  $popup = [ProbeNative4]::FindWindow('#32768', $null)
  $fg = [ProbeNative4]::GetForegroundWindow()
  Say ("TRAY after right-click: FindWindow('#32768')={0} foregroundClass='{1}'" -f $popup, (Class-Of $fg))
  $shot = Join-Path $evidenceDir ("51-tray-after-rightclick-x{0}.png" -f $cx)
  Save-Region $shot ([math]::Max(0, $SCREEN_W - 1400)) ([math]::Max(0, $SCREEN_H - 900)) ([math]::Min(1400, $SCREEN_W)) ([math]::Min(900, $SCREEN_H))
  Say "TRAY screenshot -> $(Split-Path -Leaf $shot)"
  # dismiss whatever opened
  Tap-Key $K_ESC 60 | Out-Null
  Start-Sleep -Milliseconds 500
}

$final = Read-State
Invoke-Probe 'quit' | Out-Null
Start-Sleep -Milliseconds 600
if (-not $proc.HasExited) { $proc.Kill() }
[System.IO.File]::WriteAllText((Join-Path $evidenceDir 'alt-menu-probe-run4-state.json'), ($final | ConvertTo-Json -Depth 12), (New-Object System.Text.UTF8Encoding($false)))
[System.IO.File]::WriteAllText((Join-Path $evidenceDir 'alt-menu-probe-run4-summary.json'), ($results | ConvertTo-Json -Depth 12), (New-Object System.Text.UTF8Encoding($false)))
Say "done -> $evidenceDir"
