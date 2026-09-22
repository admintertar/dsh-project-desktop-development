/**
 * Read the live renderer DOM of the dev shell over CDP (one-off diagnostic, not product code).
 * Usage: node inspect-sidebar-dom.mjs [port] [expressionName]
 */
const port = process.argv[2] ?? '9333';
const which = process.argv[3] ?? 'sidebar';

const EXPRESSIONS = {
  sidebar: `JSON.stringify([...document.querySelectorAll('.dshDesktopUpstreamSidebar, .dshDesktopUpstreamSidebar *')].slice(0, 30).map(element => ({
    tag: element.tagName,
    cls: String(element.className || ''),
    text: (element.textContent || '').replace(/\\s+/g, ' ').trim().slice(0, 48),
  })))`,
  computed: `JSON.stringify({
    titlebar: (() => {const el = document.querySelector('.dshShellTitlebar'); if (!el) return null; const style = getComputedStyle(el); return {height: style.height, background: style.backgroundColor, paddingRight: style.paddingRight};})(),
    sidebarTop: (() => {const el = document.querySelector('.dshDesktopUpstreamSidebar'); if (!el) return null; const style = getComputedStyle(el); return {paddingTop: style.paddingTop, height: style.height};})(),
    material: document.body.dataset.dshDesktopMaterial,
    mode: document.body.dataset.dshDesktopMode,
  })`,
};

const list = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
console.log('--- targets ---');
for (const target of list) console.log(`${target.type} | ${target.title} | ${target.url.slice(0, 90)}`);
const page = list.find(target => target.type === 'page' && target.url.startsWith('http'));
if (!page) { console.error('no page target'); process.exit(1) }

const socket = new WebSocket(page.webSocketDebuggerUrl);
await new Promise((resolve, reject) => {
  socket.addEventListener('open', resolve, {once: true});
  socket.addEventListener('error', reject, {once: true});
});
let nextId = 1;
function send(method, params) {
  const id = nextId++;
  return new Promise((resolve, reject) => {
    const onMessage = event => {
      const message = JSON.parse(event.data);
      if (message.id !== id) return;
      socket.removeEventListener('message', onMessage);
      if (message.error) reject(new Error(JSON.stringify(message.error)));
      else resolve(message.result);
    };
    socket.addEventListener('message', onMessage);
    socket.send(JSON.stringify({id, method, params}));
  });
}
const result = await send('Runtime.evaluate', {expression: EXPRESSIONS[which], returnByValue: true, awaitPromise: true});
console.log(`--- ${which} ---`);
console.log(typeof result.result.value === 'string' ? JSON.stringify(JSON.parse(result.result.value), null, 2) : JSON.stringify(result.result, null, 2));
socket.close();
