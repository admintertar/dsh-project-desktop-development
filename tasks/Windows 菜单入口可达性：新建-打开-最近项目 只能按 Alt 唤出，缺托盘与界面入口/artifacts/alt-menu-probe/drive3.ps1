# Third, focused Windows probe run (one-off diagnostic, not product code).
#  A) Can a menu bar be made visible at all? Window C is created with autoHideMenuBar:false and
#     the product's custom title bar; window B additionally gets win.setMenu(appMenu).
#  B) Tray reachability: create a synthetic magenta tray icon, then locate it by diffing the
#     notification-area pixels before/after; a second test right-clicks the *installed* app's
#     visible whale icon to see whether its tray context menu opens with one right-click.
# ASCII-only on purpose: Windows PowerShell 5.1 reads BOM-less .ps1 as ANSI.
param(
  [string]$ElectronPath = 'D:\dsh-project-desktop-development\resources\dsh-project-desktop\.cache\runtime\dsh-plugin-desktop\node_modules\electron\dist\electron.exe',
  [string]$ProductTrayIcon = 'D:\dsh-project-desktop-development\resources\dsh-project-desktop\assets\tray\tray-icon-blue.png'
)

$ErrorActionPreference = 'Stop'
$probeDir = $PSScriptRoot
$runDir = Join-Path $probeDir 'run3'
$evidenceDir = Join-Path (Split-Path -Parent $probeDir) 'evidence'
if (Test-Path $runDir) { Remove-Item -Recurse -Force $runDir -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path $runDir, $evidenceDir | Out-Null
$statePath = Join-Path $runDir 'state.json'
$cmdPath = Join-Path $runDir 'cmd.json'
$logPath = Join-Path $evidenceDir 'alt-menu-probe-run3.log'
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
public static class ProbeNative3 {
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

  /** Bounding box of pixels that differ between two PNGs, restricted to [x0,x1). */
  public static int[] DiffBox(string pathA, string pathB, int x0, int x1) {
    using (Bitmap a = new Bitmap(pathA))
    using (Bitmap b = new Bitmap(pathB)) {
      int w = Math.Min(a.Width, b.Width), h = Math.Min(a.Height, b.Height);
      if (x1 > w) x1 = w;
      Rectangle rect = new Rectangle(0, 0, w, h);
      BitmapData da = a.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
      BitmapData db = b.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
      int stride = Math.Abs(da.Stride);
      byte[] ba = new byte[stride * h];
      byte[] bb = new byte[stride * h];
      Marshal.Copy(da.Scan0, ba, 0, ba.Length);
      Marshal.Copy(db.Scan0, bb, 0, bb.Length);
      int minX = int.MaxValue, minY = int.MaxValue, maxX = -1, maxY = -1, count = 0;
      for (int y = 0; y < h; y++) {
        for (int x = x0; x < x1; x++) {
          int i = y * stride + x * 4;
          int d = Math.Abs(ba[i] - bb[i]) + Math.Abs(ba[i + 1] - bb[i + 1]) + Math.Abs(ba[i + 2] - bb[i + 2]);
          if (d > 48) {
            count++;
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
          }
        }
      }
      a.UnlockBits(da);
      b.UnlockBits(db);
      return new int[] {minX, minY, maxX, maxY, count};
    }
  }
}
"@ -ReferencedAssemblies System.Drawing

[ProbeNative3]::SetProcessDPIAware() | Out-Null

$SCREEN_W = [ProbeNative3]::GetSystemMetrics(78)
$SCREEN_H = [ProbeNative3]::GetSystemMetrics(79)
$RIGHTDOWN = 0x0008; $RIGHTUP = 0x0010
$K_ESC = @{vk = 0x1B; scan = 0x01; flags = 0}
$K_ALT_L = @{vk = 0xA4; scan = 0x38; flags = 0}
$K_F10 = @{vk = 0x79; scan = 0x44; flags = 0}

function Key([hashtable]$k, [bool]$up) {
  $flags = [uint32]$k.flags
  if ($up) { $flags = $flags -bor 2 }
  [ProbeNative3]::keybd_event([byte]$k.vk, [byte]$k.scan, $flags, [UIntPtr]::Zero)
}
function Tap-Key([hashtable]$k, [int]$holdMs = 90) {
  Key $k $false; Start-Sleep -Milliseconds $holdMs; Key $k $true; Start-Sleep -Milliseconds 80
}
function Class-Of([IntPtr]$h) {
  if ($h -eq [IntPtr]::Zero) { return '<null>' }
  $sb = New-Object System.Text.StringBuilder 256
  [ProbeNative3]::GetClassName($h, $sb, 256) | Out-Null
  return $sb.ToString()
}
function Focus-Window([IntPtr]$hwnd) {
  [ProbeNative3]::ShowWindow($hwnd, 9) | Out-Null
  if ([ProbeNative3]::GetForegroundWindow() -eq $hwnd) { return $true }
  [ProbeNative3]::SetForegroundWindow($hwnd) | Out-Null
  Start-Sleep -Milliseconds 250
  if ([ProbeNative3]::GetForegroundWindow() -eq $hwnd) { return $true }
  $fgPid = [uint32]0
  $fgThread = [ProbeNative3]::GetWindowThreadProcessId([ProbeNative3]::GetForegroundWindow(), [ref]$fgPid)
  $curThread = [ProbeNative3]::GetCurrentThreadId()
  [ProbeNative3]::AttachThreadInput($curThread, $fgThread, $true) | Out-Null
  [ProbeNative3]::BringWindowToTop($hwnd) | Out-Null
  [ProbeNative3]::SetForegroundWindow($hwnd) | Out-Null
  [ProbeNative3]::AttachThreadInput($curThread, $fgThread, $false) | Out-Null
  Start-Sleep -Milliseconds 250
  return ([ProbeNative3]::GetForegroundWindow() -eq $hwnd)
}
function Save-Region([string]$path, [int]$x, [int]$y, [int]$w, [int]$h) {
  $bmp = New-Object System.Drawing.Bitmap($w, $h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($x, $y, 0, 0, $bmp.Size)
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
}
function RightClick([int]$x, [int]$y) {
  [ProbeNative3]::SetCursorPos($x, $y) | Out-Null
  Start-Sleep -Milliseconds 220
  [ProbeNative3]::mouse_event($RIGHTDOWN, 0, 0, 0, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 80
  [ProbeNative3]::mouse_event($RIGHTUP, 0, 0, 0, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 450
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
  if ($null -eq $r) { Say ("SNAP {0,-34} <no result>" -f $name); return $null }
  if ($r.error) { Say ("SNAP {0,-34} ERROR {1}" -f $name, $r.error); return $r }
  Say ("SNAP {0,-34} label={1} menuBarVisible={2,-5} autoHide={3,-5} bounds={4}x{5} content={6}x{7} inner={8}x{9}" -f `
    $name, $r.label, $r.isMenuBarVisible, $r.isMenuBarAutoHide, $r.bounds.width, $r.bounds.height,
    $r.contentBounds.width, $r.contentBounds.height, $r.renderer.iw, $r.renderer.ih)
  return $r
}
function Capture([string]$name, [string]$label = 'A') {
  $r = Invoke-Probe 'capture' $name $label
  if ($null -eq $r) { Say "CAPTURE $name <failed>"; return $null }
  if ($r.error) { Say "CAPTURE $name ERROR $($r.error)"; return $null }
  Say ("CAPTURE {0,-34} image={1}x{2} k={3}" -f $name, $r.image.width, $r.image.height, $r.k)
  return $r
}

# synthetic 32x32 magenta icon so the new tray icon is unmistakable in a pixel diff
$magentaPath = Join-Path $runDir 'magenta-tray.png'
$bmp = New-Object System.Drawing.Bitmap(32, 32)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::Magenta)
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$g.FillRectangle($brush, 6, 6, 20, 20)
$g.Dispose(); $brush.Dispose()
$bmp.Save($magentaPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Say "synthetic tray icon: $magentaPath"

# ------------------------------------------------------------------ run
$env:PROBE_DIR = $runDir
$env:PROBE_EVIDENCE = $evidenceDir
Say "electron: $ElectronPath"
Say "virtual screen: ${SCREEN_W}x${SCREEN_H}"
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
$hwndC = [IntPtr][int64]$st.windows.C.hwnd
$scale = [double]$st.displays[0].scaleFactor
$results = @{}

# ---- A) can a menu bar be shown at all?
Focus-Window $hwndC | Out-Null
$results.C_baseline = Snap 'C-autoHideMenuBar-false' 'C'
Capture '20-C-autohide-false-baseline' 'C'
$results.C_f10 = $(Tap-Key $K_F10; Start-Sleep -Milliseconds 400; Snap 'C-F10' 'C')
$results.C_alt = $(Tap-Key $K_ALT_L; Start-Sleep -Milliseconds 400; Snap 'C-left-Alt' 'C')
$r = Invoke-Probe 'applyMenu' $null 'C'
Say ("APPLY C.setMenu(appMenu) -> $($r | ConvertTo-Json -Compress)")
Start-Sleep -Milliseconds 500
$results.C_afterApplyMenu = Snap 'C-after-setMenu' 'C'
Capture '21-C-after-setMenu' 'C'
$r = Invoke-Probe 'setMenuBarVisibility' $true 'C'
Start-Sleep -Milliseconds 500
$results.C_afterVisibilityTrue = Snap 'C-after-setMenuBarVisibility-true' 'C'
Capture '22-C-visibility-true' 'C'

Focus-Window $hwndB | Out-Null
$r = Invoke-Probe 'applyMenu' $null 'B'
Say ("APPLY B.setMenu(appMenu) -> $($r | ConvertTo-Json -Compress)")
Start-Sleep -Milliseconds 400
Invoke-Probe 'setMenuBarVisibility' $true 'B' | Out-Null
Start-Sleep -Milliseconds 500
$results.B_afterApplyMenu = Snap 'B-after-setMenu' 'B'
Capture '23-B-after-setMenu' 'B'

Focus-Window $hwndA | Out-Null

# ---- B) tray reachability
Start-Sleep -Milliseconds 500
$before = Capture '30-tray-before-create' 'A'
$r = Invoke-Probe 'trayCreate' $magentaPath 'A'
Say ("TRAY create(magenta) -> $($r | ConvertTo-Json -Compress)")
Start-Sleep -Milliseconds 1500
$after = Capture '31-tray-after-create' 'A'

$trayFileBefore = Join-Path $evidenceDir '30-tray-before-create-tray-area.png'
$trayFileAfter = Join-Path $evidenceDir '31-tray-after-create-tray-area.png'
if ((Test-Path $trayFileBefore) -and (Test-Path $trayFileAfter)) {
  # exclude the left stats overlay and the right clock: only the icon strip is diffed
  $box = [ProbeNative3]::DiffBox($trayFileBefore, $trayFileAfter, 400, 1000)
  Say ("TRAY pixel diff in icon strip: minX={0} minY={1} maxX={2} maxY={3} changedPixels={4}" -f $box[0], $box[1], $box[2], $box[3], $box[4])
  if ($box[4] -gt 50 -and $box[2] -gt $box[0]) {
    Say 'TRAY conclusion: the new icon IS drawn inside the directly visible notification area (no overflow needed)'
  } else {
    Say 'TRAY conclusion: the new icon is NOT drawn in the visible notification area -> Windows put it in the overflow flyout'
  }
} else {
  Say 'TRAY diff skipped: capture files missing'
}

$info = Invoke-Probe 'trayInfo' $null 'A'
Say ("TRAY getBounds() (DIP) -> $($info | ConvertTo-Json -Compress)")
if ($info -and $info.bounds -and $info.bounds.width -gt 0) {
  $cx = [int][math]::Round(($info.bounds.x + $info.bounds.width / 2) * $scale)
  $cy = [int][math]::Round(($info.bounds.y + $info.bounds.height / 2) * $scale)
  Say "TRAY right-click on the magenta icon at physical ($cx,$cy)"
  RightClick $cx $cy
  $popup = [ProbeNative3]::FindWindow('#32768', $null)
  Say ("TRAY popup after right-click on new icon: FindWindow('#32768')={0} class='{1}'" -f $popup, (Class-Of $popup))
  $shot = Join-Path $evidenceDir '32-tray-new-icon-menu.png'
  Save-Region $shot ([math]::Max(0, $SCREEN_W - 1400)) ([math]::Max(0, $SCREEN_H - 900)) ([math]::Min(1400, $SCREEN_W)) ([math]::Min(900, $SCREEN_H))
  if ($popup -ne [IntPtr]::Zero) { Tap-Key $K_ESC 60 | Out-Null; Start-Sleep -Milliseconds 300 }
}
Invoke-Probe 'trayDestroy' $null 'A' | Out-Null
Start-Sleep -Milliseconds 800

# right-click the installed app's visible whale icon (identified from 12-tray-zoom3x.png)
$candidates = @(2999, 3043, 3090, 3151)
foreach ($cx in $candidates) {
  $cy = $SCREEN_H - 48
  Say "TRAY right-click installed-app candidate physical ($cx,$cy)"
  RightClick $cx $cy
  $popup = [ProbeNative3]::FindWindow('#32768', $null)
  Say ("TRAY popup class='{0}' (FindWindow={1})" -f (Class-Of $popup), $popup)
  if ($popup -ne [IntPtr]::Zero) {
    $shot = Join-Path $evidenceDir ("33-installed-tray-menu-x{0}.png" -f $cx)
    Save-Region $shot ([math]::Max(0, $SCREEN_W - 1400)) ([math]::Max(0, $SCREEN_H - 900)) ([math]::Min(1400, $SCREEN_W)) ([math]::Min(900, $SCREEN_H))
    Say "TRAY menu screenshot -> $(Split-Path -Leaf $shot)"
    Tap-Key $K_ESC 60 | Out-Null
    Start-Sleep -Milliseconds 350
    break
  }
}

$final = Read-State
Invoke-Probe 'quit' | Out-Null
Start-Sleep -Milliseconds 600
if (-not $proc.HasExited) { $proc.Kill() }
[System.IO.File]::WriteAllText((Join-Path $evidenceDir 'alt-menu-probe-run3-state.json'), ($final | ConvertTo-Json -Depth 12), (New-Object System.Text.UTF8Encoding($false)))
[System.IO.File]::WriteAllText((Join-Path $evidenceDir 'alt-menu-probe-run3-summary.json'), ($results | ConvertTo-Json -Depth 12), (New-Object System.Text.UTF8Encoding($false)))
Say "done -> $evidenceDir"
