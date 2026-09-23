// One question: after the multi-entry open closes the guide window, does
// webContents.executeJavaScript on that destroyed window ever settle?
import electron from 'electron';
import {appendFileSync, mkdirSync, writeFileSync} from 'node:fs';
import {join} from 'node:path';
import {repository} from '../src/desktop-adapter/paths.mjs';
import {createGuideWindow} from '../src/windows/guide-window.mjs';

const trace = 'D:\\dsh-project-desktop-development\\resources\\dsh-project-desktop\\.runtime\\diag-webcontents.trace';
const note = message => {
  const line = `${new Date().toISOString()} +${Math.round(process.uptime() * 1000)}ms ${message}\n`;
  try {appendFileSync(trace, line)} catch {}
};
process.on('uncaughtException', error => note('uncaughtException ' + (error?.stack ?? error)));
process.on('unhandledRejection', error => note('unhandledRejection ' + (error?.stack ?? error)));
const manifest = 'schemaVersion: 1\nid: imported-1\nname: Imported\nresources:\n  - id: root\n    name: Imported\n    type: local\n    path: .\nmemory: []\n';
const sleep = milliseconds => new Promise(resolve => setTimeout(resolve, milliseconds));

void electron.app.whenReady().then(async () => {
  const userData = process.env.DSH_PROJECT_DESKTOP_SMOKE_DATA;
  electron.app.setPath('userData', userData);
  electron.app.on('window-all-closed', () => {});
  setInterval(() => note(`heartbeat windows=${electron.BrowserWindow.getAllWindows().length}`), 2000);
  const fixtures = join(userData, 'import-fixtures');
  const multi = join(fixtures, 'Multi'); mkdirSync(multi, {recursive: true});
  writeFileSync(join(multi, 'One.agent-project'), manifest);
  writeFileSync(join(multi, 'Two.agent-project'), manifest);
  const picks = [multi, join(multi, 'One.agent-project')];
  const opened = [];
  try {
    const window = await createGuideWindow({...electron, dialog: {...electron.dialog,
      showOpenDialog: async () => ({canceled: false, filePaths: [picks.shift()]})}},
      {repository, locale: 'en', hidden: true, recent: {list: () => []}, defaultDirectory: fixtures,
        open: async target => {opened.push(target)}, createClonePool: async () => ({dispose: async () => {}})});
    const contents = window.webContents;
    window.showInactive();
    const closedEvent = new Promise(resolve => window.once('closed', resolve));
    await contents.executeJavaScript(`new Promise(resolve => {const check = () => document.querySelector('.actions') ? resolve() : setTimeout(check, 50); check()})`);
    note('actions rendered');
    await contents.executeJavaScript(`document.querySelector('.actions button[data-guide-action=open]').click()`);
    note('clicked 打开');
    const closed = await Promise.race([closedEvent.then(() => 'closed'), sleep(8000).then(() => 'NO-CLOSED-EVENT')]);
    note('window outcome: ' + closed + ' destroyed=' + window.isDestroyed() + ' contentsDestroyed=' + contents.isDestroyed());
    const probe = await Promise.race([
      contents.executeJavaScript(`1 + 1`).then(value => 'resolved:' + value, error => 'rejected:' + error.message),
      sleep(6000).then(() => 'HUNG: no reply in 6s'),
    ]);
    note('executeJavaScript on the closed window: ' + probe);
    const windowProbe = await Promise.race([
      contents.executeJavaScript(`document.title`).then(value => 'resolved:' + value, error => 'rejected:' + error.message),
      sleep(4000).then(() => 'HUNG'),
    ]);
    note('second probe: ' + windowProbe);
  } catch (error) {
    note('THREW ' + (error?.stack ?? error));
    process.exitCode = 1;
  } finally {
    note('exiting ' + (process.exitCode ?? 0));
    electron.app.exit(process.exitCode ?? 0);
  }
});
