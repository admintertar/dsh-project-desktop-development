/**
 * Windows 菜单可达性探针（一次性诊断，非产品代码）。
 *
 * 回答的问题：
 *   1. `autoHideMenuBar: true` 时，左 Alt（以及 VK_MENU/F10/右 Alt）能否唤出菜单栏
 *      —— 对应 electron#50050 / #50082 回归；
 *   2. 这个结论是否只与我们的窗口选项有关：另开一个「标准边框 + autoHideMenuBar」
 *      的对照窗口 B；
 *   3. 菜单栏隐藏（auto-hide）时 application menu 的 accelerator 是否仍然生效；
 *   4. 调用 `win.removeMenu()`（官方 win32 策略）之后 accelerator 是否随之失效；
 *   5. 菜单栏出现时与 40px 自定义标题栏（titleBarOverlay）如何争位置，是否下压内容。
 *
 * 窗口 A 刻意复制我们产品窗口的选项：autoHideMenuBar + titleBarStyle:'hidden' + titleBarOverlay。
 * 结论全部来自 Electron 主进程 API（isMenuBarVisible/getContentBounds/...），截图用 desktopCapturer
 * 抓真实屏幕（DPI 正确），不靠固定屏幕坐标反推。
 */
const {app, BrowserWindow, Menu, screen, desktopCapturer, nativeImage, Tray} = require('electron');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const dir = process.env.PROBE_DIR;
const evidenceDir = process.env.PROBE_EVIDENCE || dir;
const statePath = path.join(dir, 'state.json');
const cmdPath = path.join(dir, 'cmd.json');

const counters = {newProject: 0, openProject: 0, closeProject: 0, welcome: 0, reloads: 0};
const state = {
  startedAt: new Date().toISOString(),
  electron: process.versions.electron,
  chrome: process.versions.chrome,
  node: process.versions.node,
  platform: process.platform,
  arch: process.arch,
  osRelease: `${os.type()} ${os.release()}`,
  windows: {},
  displays: [],
  windowOptions: {
    A: {autoHideMenuBar: true, titleBarStyle: 'hidden', titleBarOverlay: {color: '#00000000', symbolColor: '#7f858f', height: 40}, width: 1100, height: 760},
    B: {autoHideMenuBar: true, width: 900, height: 520},
    C: {autoHideMenuBar: false, titleBarStyle: 'hidden', titleBarOverlay: {color: '#00000000', symbolColor: '#7f858f', height: 40}, width: 1000, height: 600},
  },
  steps: [],
  lastSeq: 0,
};
const windows = {};
let tray = null;
let ready = false;

function save() {
  fs.writeFileSync(statePath, JSON.stringify(state, null, 2));
}
function note(name, data = {}) {
  state.steps.push({at: new Date().toISOString(), name, ...data});
  save();
}

app.setPath('userData', path.join(dir, 'user-data'));

function menuTemplate() {
  return [
    {
      label: '文件',
      submenu: [
        {label: '新建项目…', accelerator: 'CmdOrCtrl+Shift+N', click: () => {counters.newProject++; note('menu-click', {item: 'newProject'});}},
        {label: '打开项目…', accelerator: 'CmdOrCtrl+O', click: () => {counters.openProject++; note('menu-click', {item: 'openProject'});}},
        {label: '最近项目', submenu: [{label: 'probe-project-a'}, {label: 'probe-project-b'}]},
        {label: '欢迎窗口', click: () => {counters.welcome++; note('menu-click', {item: 'welcome'});}},
        {type: 'separator'},
        {label: '关闭项目', accelerator: 'CmdOrCtrl+W', click: () => {counters.closeProject++; note('menu-click', {item: 'closeProject'});}},
      ],
    },
    {
      label: '视图',
      submenu: [
        {role: 'reload', label: '重新加载'},
        {role: 'toggleDevTools', label: '切换开发者工具'},
        {type: 'separator'},
        {role: 'resetZoom'}, {role: 'zoomIn'}, {role: 'zoomOut'},
        {type: 'separator'}, {role: 'togglefullscreen'},
      ],
    },
    {role: 'windowMenu', label: '窗口'},
  ];
}

function win(label) {
  const target = windows[label];
  if (!target || target.isDestroyed()) throw new Error(`window ${label} is gone`);
  return target;
}

async function snapshot(label) {
  const target = win(label);
  const bounds = target.getBounds();
  const content = target.getContentBounds();
  let renderer = null;
  try {
    renderer = await target.webContents.executeJavaScript(
      '({iw: innerWidth, ih: innerHeight, dpr: devicePixelRatio, sx: screenX, sy: screenY, headerTop: (document.querySelector("header")||{getBoundingClientRect:()=>({top:null})}).getBoundingClientRect().top})');
  } catch (error) {
    renderer = {error: String((error && error.message) || error)};
  }
  return {
    label,
    isMenuBarVisible: target.isMenuBarVisible(),
    isMenuBarAutoHide: target.isMenuBarAutoHide(),
    isFocused: target.isFocused(),
    bounds,
    contentBounds: content,
    renderer,
    counters: {...counters},
  };
}

/** 用 desktopCapturer 抓真实屏幕（DPI 正确）：整屏 + 按 DIP 窗口矩形裁剪。 */
async function capture(label, name) {
  const target = win(label);
  const bounds = target.getBounds();
  const display = screen.getDisplayMatching(bounds);
  const physical = {width: Math.round(display.size.width * display.scaleFactor), height: Math.round(display.size.height * display.scaleFactor)};
  const sources = await desktopCapturer.getSources({types: ['screen'], thumbnailSize: physical});
  const source = sources.find(item => String(item.display_id) === String(display.id)) || sources[0];
  const full = source.thumbnail;
  const size = full.getSize();
  const k = size.width / display.bounds.width;
  const written = [];
  const fullPath = path.join(evidenceDir, `${name}-full.png`);
  fs.writeFileSync(fullPath, full.toPNG());
  written.push({file: path.basename(fullPath), size});
  const crop = {
    x: Math.max(0, Math.round((bounds.x - display.bounds.x) * k)),
    y: Math.max(0, Math.round((bounds.y - display.bounds.y) * k)),
    width: Math.min(size.width, Math.round(bounds.width * k)),
    height: Math.min(size.height, Math.round(bounds.height * k)),
  };
  if (crop.width > 0 && crop.height > 0) {
    const windowPath = path.join(evidenceDir, `${name}-window.png`);
    fs.writeFileSync(windowPath, full.crop(crop).toPNG());
    written.push({file: path.basename(windowPath), size: {width: crop.width, height: crop.height}, crop});
  }
  // 任务栏右下角（通知区域）单独裁一张，用于判断托盘图标是否真的可见
  const trayHeight = Math.round(56 * display.scaleFactor);
  const trayWidth = Math.round(620 * display.scaleFactor);
  const trayPath = path.join(evidenceDir, `${name}-tray-area.png`);
  fs.writeFileSync(trayPath, full.crop({
    x: Math.max(0, size.width - trayWidth),
    y: Math.max(0, size.height - trayHeight),
    width: Math.min(trayWidth, size.width),
    height: Math.min(trayHeight, size.height),
  }).toPNG());
  written.push({file: path.basename(trayPath)});
  return {display: {id: display.id, bounds: display.bounds, size: display.size, scaleFactor: display.scaleFactor, workArea: display.workArea}, image: size, k, written};
}

function createWindow(label, options, file) {
  const target = new BrowserWindow({
    ...options,
    show: true,
    backgroundColor: '#1c1f24',
    webPreferences: {contextIsolation: true, nodeIntegration: false},
  });
  target.on('close', () => note('window-close-requested', {label}));
  target.on('closed', () => note('window-closed', {label}));
  target.webContents.on('did-finish-load', () => {
    if (ready) {
      counters.reloads++;
      note('reload-observed', {label, url: target.webContents.getURL()});
    }
  });
  windows[label] = target;
  return target.loadFile(path.join(__dirname, file));
}

function poll() {
  setInterval(async () => {
    let cmd;
    try {
      cmd = JSON.parse(fs.readFileSync(cmdPath, 'utf8'));
    } catch {
      return;
    }
    if (!cmd || typeof cmd.seq !== 'number' || cmd.seq <= state.lastSeq) return;
    state.lastSeq = cmd.seq;
    let result;
    try {
      const label = cmd.label || 'A';
      if (cmd.cmd === 'snapshot') result = await snapshot(label);
      else if (cmd.cmd === 'removeMenu') {win(label).removeMenu(); result = {done: true};}
      else if (cmd.cmd === 'setMenuBarVisibility') {win(label).setMenuBarVisibility(Boolean(cmd.arg)); result = {done: true};}
      else if (cmd.cmd === 'setAutoHideMenuBar') {
        win(label).setAutoHideMenuBar(Boolean(cmd.arg));
        result = {done: true, isMenuBarVisible: win(label).isMenuBarVisible(), isMenuBarAutoHide: win(label).isMenuBarAutoHide()};
      } else if (cmd.cmd === 'clearMenu') {Menu.setApplicationMenu(null); result = {done: true};}
      else if (cmd.cmd === 'applyMenu') {
        win(label).setMenu(Menu.getApplicationMenu());
        result = {done: true, isMenuBarVisible: win(label).isMenuBarVisible(), isMenuBarAutoHide: win(label).isMenuBarAutoHide()};
      } else if (cmd.cmd === 'reapplyAppMenu') {
        // 复刻产品 refreshMenus() 的时序：窗口已经存在之后再重设 application menu
        Menu.setApplicationMenu(Menu.buildFromTemplate(menuTemplate()));
        result = {done: true, isMenuBarVisible: win(label).isMenuBarVisible(), isMenuBarAutoHide: win(label).isMenuBarAutoHide()};
      } else if (cmd.cmd === 'setMenuAfterCreate') {
        // 复刻「先建窗、后设菜单」：只把菜单挂到该窗口，不改 application menu
        Menu.setApplicationMenu(Menu.buildFromTemplate(menuTemplate()));
        result = {done: true, isMenuBarVisible: win(label).isMenuBarVisible(), isMenuBarAutoHide: win(label).isMenuBarAutoHide()};
      }
      else if (cmd.cmd === 'trayCreate') {
        tray?.destroy();
        tray = new Tray(nativeImage.createFromPath(cmd.arg));
        tray.setToolTip('DSH Project Desktop ALT-MENU PROBE');
        tray.setContextMenu(Menu.buildFromTemplate([
          {label: '新建项目…', click: () => {counters.newProject++; note('tray-click', {item: 'newProject'});}},
          {label: '打开项目…', click: () => {counters.openProject++; note('tray-click', {item: 'openProject'});}},
          {label: '最近项目', submenu: [{label: 'probe-project-a'}, {label: 'probe-project-b'}]},
          {type: 'separator'},
          {label: '欢迎窗口', click: () => {counters.welcome++; note('tray-click', {item: 'welcome'});}},
          {label: '显示应用', click: () => note('tray-click', {item: 'showApp'})},
          {type: 'separator'},
          {label: '检查更新…', click: () => note('tray-click', {item: 'updates'})},
          {role: 'quit', label: '退出'},
        ]));
        result = {done: true, bounds: tray.getBounds(), destroyed: tray.isDestroyed()};
      } else if (cmd.cmd === 'trayInfo') {
        result = tray && !tray.isDestroyed() ? {bounds: tray.getBounds()} : {error: 'no tray'};
      } else if (cmd.cmd === 'trayPopup') {
        if (!tray || tray.isDestroyed()) result = {error: 'no tray'};
        else {tray.popUpContextMenu(); result = {done: true, bounds: tray.getBounds()};}
      } else if (cmd.cmd === 'trayDestroy') {tray?.destroy(); tray = null; result = {done: true};}
      else if (cmd.cmd === 'capture') result = await capture(label, cmd.arg);
      else if (cmd.cmd === 'focus') {win(label).focus(); win(label).moveTop(); result = {done: true};}
      else if (cmd.cmd === 'mark') result = {done: true, label: cmd.arg ?? null};
      else if (cmd.cmd === 'quit') {note('quit'); save(); app.exit(0); return;}
      else result = {error: `unknown command: ${cmd.cmd}`};
    } catch (error) {
      result = {error: String((error && error.stack) || error)};
    }
    note('result', {seq: cmd.seq, cmd: cmd.cmd, label: cmd.label ?? 'A', arg: cmd.arg ?? null, result});
  }, 60);
}

app.on('window-all-closed', () => {note('window-all-closed');});

app.whenReady().then(async () => {
  Menu.setApplicationMenu(Menu.buildFromTemplate(menuTemplate()));
  state.displays = screen.getAllDisplays().map(d => ({id: d.id, bounds: d.bounds, size: d.size, scaleFactor: d.scaleFactor, workArea: d.workArea}));

  await createWindow('A', {
    width: 1100, height: 760, x: 60, y: 60,
    autoHideMenuBar: true,
    titleBarStyle: 'hidden',
    titleBarOverlay: {color: '#00000000', symbolColor: '#7f858f', height: 40},
  }, 'index.html');
  await createWindow('B', {
    width: 900, height: 520, x: 780, y: 140,
    autoHideMenuBar: true,
  }, 'index-b.html');
  // C: 与产品窗口同样的自定义标题栏，但一开始就不要 autoHideMenuBar
  await createWindow('C', {
    width: 1000, height: 600, x: 200, y: 220,
    autoHideMenuBar: false,
    titleBarStyle: 'hidden',
    titleBarOverlay: {color: '#00000000', symbolColor: '#7f858f', height: 40},
  }, 'index-c.html');

  for (const [label, target] of Object.entries(windows)) {
    const handle = target.getNativeWindowHandle();
    state.windows[label] = {
      hwnd: handle.readBigUInt64LE(0).toString(),
      options: label === 'A' ? state.windowOptions.A : (label === 'C' ? state.windowOptions.C : state.windowOptions.B),
    };
  }
  ready = true;
  note('ready', {windows: state.windows});
  poll();
}).catch(error => {
  note('fatal', {error: String((error && error.stack) || error)});
  app.exit(1);
});
