const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('sanchoDesktop', {
  isDesktop: true,
  platform: process.platform,
  versions: {
    chrome: process.versions.chrome,
    electron: process.versions.electron
  },
  getSession() {
    return ipcRenderer.invoke('sancho:get-session');
  },
  setSession(payload) {
    return ipcRenderer.invoke('sancho:set-session', payload);
  },
  openExcelFile() {
    return ipcRenderer.invoke('sancho:open-excel-file');
  },
  openRulesJson() {
    return ipcRenderer.invoke('sancho:open-rules-json');
  },
  saveRulesJson(payload) {
    return ipcRenderer.invoke('sancho:save-rules-json', payload);
  },
  pickExportDirectory() {
    return ipcRenderer.invoke('sancho:pick-export-directory');
  },
  writeExportFile(payload) {
    return ipcRenderer.invoke('sancho:write-export-file', payload);
  }
});
