// Verify the repository-import flow on Windows without the multi-entry open case that
// hangs the shared check (see artifacts/windows-guide-hang.md). Same stubs as
// scripts/native-guide-checks.mjs checkRepositoryImport, same assertions in order up to
// the ambiguous case, then the import dialog, remembered directory and locale passes.
import electron from 'electron';
import assert from 'node:assert/strict';
import {appendFileSync, mkdirSync, writeFileSync} from 'node:fs';
import {join} from 'node:path';
import {repository} from '../src/desktop-adapter/paths.mjs';
import {createGuideWindow} from '../src/windows/guide-window.mjs';

const trace = 'D:\\dsh-project-desktop-development\\resources\\dsh-project-desktop\\.runtime\\diag-import-win.trace';
// File only: the background job's stdout pipe is not drained, and a failed write raises
// an uncaught EPIPE that blocks the Electron main process with a modal error dialog.
const note = message => {
  const line = `${new Date().toISOString()} ${message}\n`;
  try {appendFileSync(trace, line)} catch {}
};
const importManifest = 'schemaVersion: 1\nid: imported-1\nname: Imported\nresources:\n  - id: root\n    name: Imported\n    type: local\n    path: .\nmemory: []\n';
async function waitFor(window, expression) {
  return window.webContents.executeJavaScript(`new Promise((resolve, reject) => {
    const deadline = Date.now() + 8000;
    const check = () => {if (${expression}) return requestAnimationFrame(resolve);
      if (Date.now() > deadline) return reject(new Error(${JSON.stringify(expression)} + '\\n\\n' + document.body.innerText)); setTimeout(check, 50)}; check();
  })`);
}

void electron.app.whenReady().then(async () => {
  const userData = process.env.DSH_PROJECT_DESKTOP_SMOKE_DATA;
  electron.app.setPath('userData', userData);
  electron.app.on('window-all-closed', () => {});
  const passed = [];
  const record = message => {passed.push(message); note('PASS ' + message)};
  try {
    const fixtures = join(userData, 'import-fixtures');
    const folder = join(fixtures, 'Folder Project'); mkdirSync(folder, {recursive: true});
    writeFileSync(join(folder, 'Folder Project.agent-project'), importManifest);
    const empty = join(fixtures, 'Empty Project'); mkdirSync(empty, {recursive: true});
    const destination = join(fixtures, 'Destination'); mkdirSync(destination, {recursive: true});
    const defaults = join(fixtures, 'Defaults'); mkdirSync(defaults, {recursive: true});
    const picked = join(fixtures, 'Picked'); mkdirSync(picked, {recursive: true});
    const opened = [], installed = [], picks = [];
    let options, released = false;
    const pool = {
      entries: new Map(),
      async start({id, name, url, branch}) {this.entries.set(id, {id, name, url, branch}); return {id, url, branch, status: 'cloning'}},
      async snapshot() {return [...this.entries.values()].map(entry => ({...entry,
        ...(released ? {status: 'completed', phase: 'checkout', percent: 100} : {status: 'cloning', phase: 'receiving', percent: 42})}))},
      async cancel(id) {this.entries.delete(id); return true},
      async remove(id) {this.entries.delete(id)},
      async retain() {},
      async authentication(value) {return value?.path === '/keys' ? {keys: []} : {requests: []}},
      async install(item, target) {const entry = this.entries.get(item.id); mkdirSync(target, {recursive: true});
        writeFileSync(join(target, `${entry.name}.agent-project`), importManifest); installed.push(target)},
      async dispose() {this.entries.clear()},
    };
    const launch = locale => createGuideWindow({...electron, dialog: {...electron.dialog,
      showOpenDialog: async (_window, value) => {options = value; return {canceled: false, filePaths: [picks.shift()]}}}},
      {repository, locale, hidden: true, recent: {list: () => []}, defaultDirectory: defaults,
        open: async target => {opened.push(target)}, createClonePool: async () => pool});
    const setDialogInput = (window, index, value) => window.webContents.executeJavaScript(
      `(() => {const input = document.querySelectorAll('[role=dialog] input')[${index}];
        Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set.call(input, ${JSON.stringify(value)});
        input.dispatchEvent(new Event('input', {bubbles: true}))})()`);
    const clickOpen = window => window.webContents.executeJavaScript(`document.querySelector('.actions button[data-guide-action=open]').click()`);
    const clickClone = window => window.webContents.executeJavaScript(`document.querySelector('.actions button[data-guide-action=clone]').click()`);
    const settled = promise => Promise.race([promise, new Promise((_, reject) => setTimeout(() => reject(new Error('Import did not open the project')), 15000))]);

    // 1. A folder with exactly one entry file opens like the file itself.
    picks.length = 0; picks.push(folder);
    let window = await launch('zh'); window.showInactive();
    await waitFor(window, "document.querySelector('.actions')");
    const folderOpened = new Promise(resolve => window.once('closed', resolve));
    await window.webContents.executeJavaScript(`window.projectGuide.invoke('open').then(() => undefined, error => error.message)`).catch(() => 'closed');
    await settled(folderOpened);
    assert.deepEqual(opened, [folder]);
    assert.deepEqual(options.properties, ['openFile', 'openDirectory']);
    record('unique-entry folder opens directly; the picker degrades to openFile+openDirectory');

    // 2. A folder without a project explains itself in the window's own language.
    picks.length = 0; picks.push(empty);
    window = await launch('zh'); window.showInactive();
    await waitFor(window, "document.querySelector('.actions')");
    await clickOpen(window);
    await waitFor(window, "document.querySelector('.error')?.textContent.includes('不是 agent-project 项目')");
    const emptyCopy = await window.webContents.executeJavaScript(`document.querySelector('.error').textContent`);
    note('empty folder copy: ' + emptyCopy);
    record('folder without a project reports 不是 agent-project 项目 in the window locale');
    window.destroy();
    await new Promise(resolve => setTimeout(resolve, 500));

    // 3. The import dialog validates, prefills the folder name and imports through the pool.
    picks.length = 0;
    window = await launch('zh'); window.showInactive();
    await waitFor(window, "document.querySelector('.actions')");
    const actionButtons = await window.webContents.executeJavaScript(
      `[...document.querySelectorAll('.actions button')].map(button => ({action: button.dataset.guideAction, text: button.textContent}))`);
    assert.deepEqual(actionButtons.map(item => item.action), ['clone', 'new', 'open']);
    assert.equal(actionButtons[0].text, '克隆仓库');
    await clickClone(window);
    await waitFor(window, "Boolean(document.querySelector('[role=dialog]'))");
    assert.match(await window.webContents.executeJavaScript(`document.querySelector('[role=dialog]').textContent`), /从 Git 仓库克隆项目/);
    assert.equal(await window.webContents.executeJavaScript(`document.querySelectorAll('[role=dialog] input')[2].value`), defaults);
    await window.webContents.executeJavaScript(`document.querySelector('[role=dialog] button[type=submit]').click()`);
    await waitFor(window, "Boolean(document.querySelector('[role=dialog] [role=alert]'))");
    record('empty import form reports its own validation error; destination starts at the window default');
    await setDialogInput(window, 0, 'https://github.com/example/imported-project.git');
    await setDialogInput(window, 2, destination);
    assert.equal(await window.webContents.executeJavaScript(`document.querySelectorAll('[role=dialog] input')[3].value`), 'imported-project');
    assert.match(await window.webContents.executeJavaScript(`document.querySelector('[role=dialog] .projectPathPreview').textContent`),
      new RegExp('imported-project$'));
    record('repository URL derives the folder name imported-project and previews the target path with the host separator');
    const imported = new Promise(resolve => window.once('closed', resolve));
    await window.webContents.executeJavaScript(`document.querySelector('[role=dialog] button[type=submit]').click()`).catch(() => {});
    await waitFor(window, "document.querySelector('.cloneProgress')?.textContent.includes('42%')");
    assert.match(await window.webContents.executeJavaScript(`document.querySelector('.cloneProgress').textContent`), /接收对象/);
    record('clone progress reports the plugin job phase (接收对象, 42%)');
    released = true;
    await settled(imported);
    assert.deepEqual(installed, [join(destination, 'imported-project')]);
    assert.equal(opened.at(-1), join(destination, 'imported-project', 'imported-project.agent-project'));
    record('a finished import installs <name>.agent-project under the chosen parent and opens it');

    // 4. The import directory survives the window.
    picks.length = 0; picks.push(picked);
    window = await launch('zh'); window.showInactive();
    await waitFor(window, "document.querySelector('.actions')");
    await clickClone(window);
    await waitFor(window, `Boolean(document.querySelector('[role=dialog]')) && document.querySelectorAll('[role=dialog] input')[2].value === ${JSON.stringify(destination)}`);
    record('a new dialog starts at the previous import destination');
    await window.webContents.executeJavaScript(`document.querySelector('[role=dialog] .projectPathControl button').click()`);
    await waitFor(window, `document.querySelectorAll('[role=dialog] input')[2].value === ${JSON.stringify(picked)}`);
    window.webContents.sendInputEvent({type: 'keyDown', keyCode: 'Escape'});
    window.webContents.sendInputEvent({type: 'keyUp', keyCode: 'Escape'});
    await waitFor(window, "!document.querySelector('[role=dialog]')");
    await clickClone(window);
    await waitFor(window, `Boolean(document.querySelector('[role=dialog]')) && document.querySelectorAll('[role=dialog] input')[2].value === ${JSON.stringify(picked)}`);
    assert.deepEqual(installed, [join(destination, 'imported-project')]);
    record('browsing a directory remembers it before any clone starts; Escape closes without importing');
    window.destroy();
    await new Promise(resolve => setTimeout(resolve, 500));

    // 5. English, dark theme, Escape and a narrow window behave like every other dialog.
    window = await launch('en'); window.showInactive();
    await waitFor(window, "document.querySelector('.actions')");
    electron.nativeTheme.themeSource = 'dark';
    await clickClone(window);
    await waitFor(window, "document.querySelector('[role=dialog]') && document.body.hasAttribute('data-ds-dark-theme')");
    assert.match(await window.webContents.executeJavaScript(`document.querySelector('[role=dialog]').textContent`), /Clone Project from Git Repository/);
    assert.equal(await window.webContents.executeJavaScript(`document.querySelectorAll('[role=dialog] input')[2].value`), picked);
    window.webContents.sendInputEvent({type: 'keyDown', keyCode: 'Escape'});
    window.webContents.sendInputEvent({type: 'keyUp', keyCode: 'Escape'});
    await waitFor(window, "!document.querySelector('[role=dialog]')");
    electron.nativeTheme.themeSource = 'light';
    await waitFor(window, "!document.body.hasAttribute('data-ds-dark-theme')");
    await clickClone(window);
    await waitFor(window, "Boolean(document.querySelector('[role=dialog]'))");
    window.setSize(420, 460);
    await waitFor(window, "innerWidth <= 420");
    assert.equal(await window.webContents.executeJavaScript(
      `document.querySelector('[role=dialog]').getBoundingClientRect().right <= innerWidth + 1 && document.documentElement.scrollWidth <= innerWidth + 1`), true);
    record('English copy, dark theme, Escape and a 420px window keep the dialog inside the viewport');
    window.destroy();

    const lastDirectories = join(userData, 'last-directories.json');
    note('last-directories.json: ' + (await import('node:fs')).readFileSync(lastDirectories, 'utf8').trim());
    writeFileSync(join(userData, 'windows-import-results.json'), JSON.stringify({ok: true, platform: process.platform, passed}, null, 2));
    note(`ALL PASSED (${passed.length})`);
  } catch (error) {
    note('FAILED after ' + passed.length + ' passes: ' + (error?.stack ?? error));
    process.exitCode = 1;
  } finally {
    note('exiting ' + (process.exitCode ?? 0));
    electron.app.exit(process.exitCode ?? 0);
  }
});
