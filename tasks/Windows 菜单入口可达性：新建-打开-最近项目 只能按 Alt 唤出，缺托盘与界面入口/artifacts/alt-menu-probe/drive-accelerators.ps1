# Native acceptance for the window-level accelerators (one-off diagnostic, not product code).
#
# Acceptance criterion c2: "if Ctrl+Shift+N / Ctrl+O / Ctrl+W stay bound, their binding must not
# depend on the global application menu". On Windows the shell no longer registers those
# accelerators in the application menu (main.mjs fileAccelerator), so any working chord below
# proves the window-level binding (src/app/window-accelerators.mjs) is doing the work.
# ASCII-only on purpose: Windows PowerShell 5.1 reads BOM-less .ps1 as ANSI.
param([string]$TitleLike = '*欢迎*')

$ErrorActionPreference = 'Stop'
$probeDir = $PSScriptRoot
$evidenceDir = Join-Path (Split-Path -Parent $probeDir) 'evidence'
New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null
$logPath = Join-Path $evidenceDir 'window-accelerators-native.log'
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
public static class AccNative {
  [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
  [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool f);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int n);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] public static extern IntPtr FindWindow(string c, string w);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@ -ReferencedAssemblies System.Drawing
[AccNative]::SetProcessDPIAware() | Out-Null

function Title([IntPtr]$h) { $sb = New-Object System.Text.StringBuilder 256; [AccNative]::GetWindowText($h, $sb, 256) | Out-Null; $sb.ToString() }
function Windows() {
  $script:list = @()
  $cb = [AccNative+EnumProc]{ param($h, $l)
    if ([AccNative]::IsWindowVisible($h)) { $t = Title $h; if ($t) { $p = [uint32]0; [AccNative]::GetWindowThreadProcessId($h, [ref]$p) | Out-Null; $script:list += [pscustomobject]@{Hwnd = $h; Pid = $p; Title = $t} } }
    return $true }
  [AccNative]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
  return $script:list
}
function Send([int[]]$vks) {
  foreach ($v in $vks) { [AccNative]::keybd_event([byte]$v, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 50 }
  for ($i = $vks.Length - 1; $i -ge 0; $i--) { [AccNative]::keybd_event([byte]$vks[$i], 0, 2, [UIntPtr]::Zero); Start-Sleep -Milliseconds 50 }
}
function Save-Window([IntPtr]$h, [string]$name) {
  $r = New-Object AccNative+RECT; [AccNative]::GetWindowRect($h, [ref]$r) | Out-Null
  $w = $r.Right - $r.Left; $hh = $r.Bottom - $r.Top
  if ($w -le 0 -or $hh -le 0) { return $null }
  $bmp = New-Object System.Drawing.Bitmap($w, $hh)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($r.Left, $r.Top, 0, 0, $bmp.Size)
  $path = Join-Path $evidenceDir $name
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
  return $name
}
function Prove-Foreground([IntPtr]$h) {
  [AccNative]::ShowWindow($h, 9) | Out-Null
  if ([AccNative]::GetForegroundWindow() -eq $h) { return $true }
  $fgPid = [uint32]0
  $fgThread = [AccNative]::GetWindowThreadProcessId([AccNative]::GetForegroundWindow(), [ref]$fgPid)
  $curThread = [AccNative]::GetCurrentThreadId()
  [AccNative]::AttachThreadInput($curThread, $fgThread, $true) | Out-Null
  [AccNative]::BringWindowToTop($h) | Out-Null
  [AccNative]::SetForegroundWindow($h) | Out-Null
  [AccNative]::AttachThreadInput($curThread, $fgThread, $false) | Out-Null
  Start-Sleep -Milliseconds 300
  return ([AccNative]::GetForegroundWindow() -eq $h)
}

# ---- locate the dev shell welcome window
$deadline = (Get-Date).AddSeconds(45)
$welcome = $null
while ((Get-Date) -lt $deadline -and -not $welcome) {
  Start-Sleep -Milliseconds 500
  $welcome = Windows | Where-Object { $_.Title -like $TitleLike } | Select-Object -First 1
}
if (-not $welcome) { throw "no window matching $TitleLike" }
$shellPid = $welcome.Pid
Say ("welcome window: hwnd={0} pid={1} title='{2}'" -f $welcome.Hwnd, $shellPid, $welcome.Title)
$baseline = @(Windows | Where-Object { $_.Pid -eq $shellPid } | ForEach-Object { $_.Title })
Say ("baseline shell windows: {0}" -f ($baseline -join ' | '))

$results = @{}

# ---- Ctrl+Shift+N must open the create window even though the menu no longer binds it
if (-not (Prove-Foreground $welcome.Hwnd)) { throw 'welcome window is not foreground; refusing to inject keys' }
Say 'foreground proof for Ctrl+Shift+N: True'
Send @(0xA2, 0xA0, 0x4E)
Start-Sleep -Seconds 3
$afterNew = Windows | Where-Object { $_.Pid -eq $shellPid }
$created = $afterNew | Where-Object { $baseline -notcontains $_.Title }
Say ("Ctrl+Shift+N -> new shell windows: {0}" -f (($created | ForEach-Object { $_.Title }) -join ' | '))
$results.ctrlShiftN = @($created | ForEach-Object { $_.Title })
if ($created) {
  $create = $created | Select-Object -First 1
  Say ("create window screenshot: {0}" -f (Save-Window $create.Hwnd '80-native-ctrl-shift-n-create-window.png'))
  [AccNative]::PostMessage($create.Hwnd, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null   # WM_CLOSE
  Start-Sleep -Seconds 2
}

# ---- Ctrl+O must open the project file dialog
if (-not (Prove-Foreground $welcome.Hwnd)) { Say 'WARN welcome window lost the foreground before Ctrl+O' }
else {
  Send @(0xA2, 0x4F)
  Start-Sleep -Seconds 4
  $dialog = [AccNative]::FindWindow('#32770', $null)
  $fg = [AccNative]::GetForegroundWindow()
  Say ("Ctrl+O -> foreground='{0}' dialog(#32770)={1} dialogTitle='{2}'" -f (Title $fg), $dialog, (Title $dialog))
  $results.ctrlO = @{dialog = [int64]$dialog; dialogTitle = (Title $dialog); foreground = (Title $fg)}
  if ($dialog -ne [IntPtr]::Zero) {
    Say ("dialog screenshot: {0}" -f (Save-Window $dialog '81-native-ctrl-o-project-dialog.png'))
    [AccNative]::PostMessage($dialog, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
    Start-Sleep -Seconds 1
  }
}

# ---- Ctrl+W with no open project must be a safe no-op (menu item is disabled in that state)
$beforeClose = @(Windows | Where-Object { $_.Pid -eq $shellPid } | ForEach-Object { $_.Title })
if (Prove-Foreground $welcome.Hwnd) {
  Send @(0xA2, 0x57)
  Start-Sleep -Seconds 3
  $afterClose = @(Windows | Where-Object { $_.Pid -eq $shellPid } | ForEach-Object { $_.Title })
  Say ("Ctrl+W (no project open) -> windows: {0}" -f ($afterClose -join ' | '))
  $results.ctrlW = @{before = $beforeClose; after = $afterClose}
  $still = $afterClose | Where-Object { $_ -like $TitleLike }
  Say ("welcome window survived Ctrl+W: {0}" -f [bool]$still)
  Say ("final screenshot: {0}" -f (Save-Window $welcome.Hwnd '82-native-after-accelerators.png'))
}
else { Say 'WARN welcome window lost the foreground before Ctrl+W' }

[System.IO.File]::WriteAllText((Join-Path $evidenceDir 'window-accelerators-native.json'), ($results | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding($false)))
Say 'done'
