// Only native blank/new-tab pages are refreshed. No website content is accessed.
let nativePort = null, refreshTimer = null, attempts = 0, sequence = null;
const isBlank = url => /^(?:(?:chrome|brave):\/\/(?:newtab|new-tab-page)\/?|about:blank)(?:[?#].*)?$/.test(url || '');
async function refreshBlankTabs() {
  for (const tab of await chrome.tabs.query({})) {
    if (Number.isInteger(tab.id) && !tab.pendingUrl && isBlank(tab.url)) {
      try { await chrome.tabs.reload(tab.id, {bypassCache:true}); } catch (_) {}
    }
  }
}
function connect() {
  if (nativePort) return;
  const port = chrome.runtime.connectNative('org.impasto.palette');
  nativePort = port;
  port.onMessage.addListener(message => {
    attempts = 0;
    if (message.type === 'ready') { sequence = message.sequence; return; }
    if (message.type !== 'palette' || message.sequence === sequence) return;
    sequence = message.sequence;
    clearTimeout(refreshTimer);
    refreshTimer = setTimeout(refreshBlankTabs, 220);
  });
  port.onDisconnect.addListener(() => {
    void chrome.runtime.lastError;
    nativePort = null;
    if (attempts < 4) setTimeout(connect, 1000 * 2 ** attempts++);
  });
  port.postMessage({operation:'watch'});
}
chrome.runtime.onStartup.addListener(connect);
chrome.runtime.onInstalled.addListener(connect);
connect();
