# Product-level Windows check on the real dev shell (one-off diagnostic, not product code).
# The dev shell is already running (scripts/start.mjs with an isolated userData); this script
# inspects the *real* welcome window from the outside:
#   - GetMenu()/GetMenuItemCount/GetMenuString: does the window have a Win32 menu attached at all?
#   - GetClientRect() before/after injected Left Alt / F10: does a menu bar take client height?
#   - DPI-aware screenshots of the top strip as visual evidence.
# ASCII-only on purpose: Windows PowerShell 5.1 reads BOM-less .ps1 as ANSI.
param(
  [string]$TitleLike = '*DSH*'
)

$ErrorActionPreference = 'Stop'
$probeDir = $PSScriptRoot
$evidenceDir = Join-Path (Split-Path -Parent $probeDir) 'evidence'
New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null
$logPath = Join-Path $evidenceDir 'devshell-menu-check.log'
$transcript = New-Object System.Collections.Generic.List[string]
function Say([string]$text) {
  $line = "[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss.fff'), $text
  $transcript.Add($line); Write-Host $line; [System.IO.File]::WriteAllLines($logPath, $transcript)
}

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Text;
public static class DevShellNative {
  [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
  [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
  [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern IntPtr GetMenu(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern int GetMenuItemCount(IntPtr hMenu);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetMenuString(IntPtr hMenu, uint uIDItem, StringBuilder lpString, int nMaxCount, uint uFlag);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT r);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(IntPtr hWnd, StringBuilder sb, int max);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  public static int[] DiffBox(string pathA, string pathB, int y1) {
    using (Bitmap a = new Bitmap(pathA)) using (Bitmap b = new Bitmap(pathB)) {
      int w = Math.Min(a.Width, b.Width), h = Math.Min(a.Height, b.Height);
      if (y1 > h) y1 = h;
      Rectangle rect = new Rectangle(0, 0, w, h);
      BitmapData da = a.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
      BitmapData db = b.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
      int stride = Math.Abs(da.Stride);
      byte[] ba = new byte[stride * h]; byte[] bb = new byte[stride * h];
      Marshal.Copy(da.Scan0, ba, 0, ba.Length); Marshal.Copy(db.Scan0, bb, 0, bb.Length);
      int minX = int.MaxValue, minY = int.MaxValue, maxX = -1, maxY = -1, count = 0;
      for (int y = 0; y < y1; y++) for (int x = 0; x < w; x++) {
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
[DevShellNative]::SetProcessDPIAware() | Out-Null

$K_ALT_L = @{vk = 0xA4; scan = 0x38; flags = 0}
$K_F10 = @{vk = 0x79; scan = 0x44; flags = 0}
function Key([hashtable]$k, [bool]$up) { $flags = [uint32]$k.flags; if ($up) { $flags = $flags -bor 2 }; [DevShellNative]::keybd_event([byte]$k.vk, [byte]$k.scan, $flags, [UIntPtr]::Zero) }
function Tap-Key([hashtable]$k, [int]$holdMs = 100) { Key $k $false; Start-Sleep -Milliseconds $holdMs; Key $k $true; Start-Sleep -Milliseconds 120 }

function Describe([IntPtr]$hwnd) {
  $menu = [DevShellNative]::GetMenu($hwnd)
  $count = 0; $labels = @()
  if ($menu -ne [IntPtr]::Zero) {
    $count = [DevShellNative]::GetMenuItemCount($menu)
    for ($i = 0; $i -lt [math]::Min($count, 8); $i++) {
      $sb = New-Object System.Text.StringBuilder 128
      [DevShellNative]::GetMenuString($menu, [uint32]$i, $sb, 128, 0x400) | Out-Null
      $labels += $sb.ToString().Replace('&', '')
    }
  }
  $cr = New-Object DevShellNative+RECT; [DevShellNative]::GetClientRect($hwnd, [ref]$cr) | Out-Null
  $wr = New-Object DevShellNative+RECT; [DevShellNative]::GetWindowRect($hwnd, [ref]$wr) | Out-Null
  $cls = New-Object System.Text.StringBuilder 128
  [DevShellNative]::GetClassName($hwnd, $cls, 128) | Out-Null
  return [ordered]@{
    hwnd = [int64]$hwnd
    className = $cls.ToString()
    menuHandle = [int64]$menu
    menuItemCount = $count
    menuLabels = $labels
    clientRect = "$($cr.Right - $cr.Left)x$($cr.Bottom - $cr.Top)"
    windowRect = "$($wr.Right - $wr.Left)x$($wr.Bottom - $wr.Top)@$($wr.Left),$($wr.Top)"
  }
}

$target = Get-Process | Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -like $TitleLike } | Select-Object -First 1
if (-not $target) { throw "no window matching $TitleLike" }
$hwnd = [IntPtr]$target.MainWindowHandle
Say ("target: pid={0} title='{1}' hwnd={2}" -f $target.Id, $target.MainWindowTitle, $hwnd)
$results = @{}
$results.baseline = Describe $hwnd
Say ("BASELINE menuHandle={0} items={1} labels=[{2}] client={3} window={4} class={5}" -f `
  $results.baseline.menuHandle, $results.baseline.menuItemCount, ($results.baseline.menuLabels -join '|'), `
  $results.baseline.clientRect, $results.baseline.windowRect, $results.baseline.className)

[DevShellNative]::ShowWindow($hwnd, 9) | Out-Null
[DevShellNative]::SetForegroundWindow($hwnd) | Out-Null
Start-Sleep -Milliseconds 400
if ([DevShellNative]::GetForegroundWindow() -ne $hwnd) {
  $fgPid = [uint32]0
  $fgThread = [DevShellNative]::GetWindowThreadProcessId([DevShellNative]::GetForegroundWindow(), [ref]$fgPid)
  $curThread = [DevShellNative]::GetCurrentThreadId()
  [DevShellNative]::AttachThreadInput($curThread, $fgThread, $true) | Out-Null
  [DevShellNative]::BringWindowToTop($hwnd) | Out-Null
  [DevShellNative]::SetForegroundWindow($hwnd) | Out-Null
  [DevShellNative]::AttachThreadInput($curThread, $fgThread, $false) | Out-Null
  Start-Sleep -Milliseconds 300
}
$proven = ([DevShellNative]::GetForegroundWindow() -eq $hwnd)
Say "foreground proof: $proven"
if (-not $proven) { throw 'welcome window is not foreground; refusing to inject keys' }

function Save-Window([string]$name, [int]$x, [int]$y, [int]$w, [int]$h) {
  $bmp = New-Object System.Drawing.Bitmap($w, $h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($x, $y, 0, 0, $bmp.Size)
  $path = Join-Path $evidenceDir $name
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
  return $path
}

$wr = New-Object DevShellNative+RECT; [DevShellNative]::GetWindowRect($hwnd, [ref]$wr) | Out-Null
$w = $wr.Right - $wr.Left; $h = $wr.Bottom - $wr.Top
$shot0 = Save-Window '70-devshell-welcome-baseline.png' $wr.Left $wr.Top $w $h
Say "screenshot $([System.IO.Path]::GetFileName($shot0)) ${w}x${h}@$($wr.Left),$($wr.Top)"

Tap-Key $K_ALT_L
Start-Sleep -Milliseconds 500
$results.afterLeftAlt = Describe $hwnd
Say ("AFTER LEFT ALT menuHandle={0} items={1} client={2}" -f $results.afterLeftAlt.menuHandle, $results.afterLeftAlt.menuItemCount, $results.afterLeftAlt.clientRect)
$shot1 = Save-Window '71-devshell-welcome-after-left-alt.png' $wr.Left $wr.Top $w $h
Say "screenshot $([System.IO.Path]::GetFileName($shot1))"

Tap-Key $K_ALT_L
Start-Sleep -Milliseconds 400
$results.afterLeftAlt2 = Describe $hwnd
Say ("AFTER LEFT ALT #2 client={0}" -f $results.afterLeftAlt2.clientRect)
Tap-Key $K_F10
Start-Sleep -Milliseconds 500
$results.afterF10 = Describe $hwnd
Say ("AFTER F10 menuHandle={0} items={1} client={2}" -f $results.afterF10.menuHandle, $results.afterF10.menuItemCount, $results.afterF10.clientRect)
$shot2 = Save-Window '72-devshell-welcome-after-f10.png' $wr.Left $wr.Top $w $h
Say "screenshot $([System.IO.Path]::GetFileName($shot2))"

$strip = [math]::Min(160, $h)
$d1 = [DevShellNative]::DiffBox($shot0, $shot1, $strip)
$d2 = [DevShellNative]::DiffBox($shot0, $shot2, $strip)
Say ("pixel diff top {0}px: baseline-vs-leftAlt minX={1} minY={2} maxX={3} maxY={4} changed={5}" -f $strip, $d1[0], $d1[1], $d1[2], $d1[3], $d1[4])
Say ("pixel diff top {0}px: baseline-vs-F10     minX={1} minY={2} maxX={3} maxY={4} changed={5}" -f $strip, $d2[0], $d2[1], $d2[2], $d2[3], $d2[4])

[System.IO.File]::WriteAllText((Join-Path $evidenceDir 'devshell-menu-check.json'), ($results | ConvertTo-Json -Depth 8), (New-Object System.Text.UTF8Encoding($false)))
Say 'done'
