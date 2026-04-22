const path = require('path');
const fs = require('fs/promises');
const { app, BrowserWindow, dialog, ipcMain, shell } = require('electron');

const APP_TITLE = 'SanchoSheetset - Excel 报表导出工具';
const DEFAULT_SESSION = {
  lastExcelPath: '',
  lastExcelName: '',
  lastRulesPath: '',
  lastRulesName: '',
  lastRulesText: '',
  lastExportDir: '',
  activeRulePresetId: '',
  rulePresets: []
};

function getSessionFilePath() {
  return path.join(app.getPath('userData'), 'sancho-session.json');
}

async function readSession() {
  try {
    const text = await fs.readFile(getSessionFilePath(), 'utf8');
    const data = JSON.parse(text);
    const next = { ...DEFAULT_SESSION, ...(data && typeof data === 'object' ? data : {}) };
    if (!Array.isArray(next.rulePresets)) next.rulePresets = [];
    if (typeof next.activeRulePresetId !== 'string') next.activeRulePresetId = '';
    return next;
  } catch (error) {
    return { ...DEFAULT_SESSION };
  }
}

async function writeSession(patch) {
  const current = await readSession();
  const next = {
    ...current,
    ...(patch && typeof patch === 'object' ? patch : {})
  };
  await fs.mkdir(path.dirname(getSessionFilePath()), { recursive: true });
  await fs.writeFile(getSessionFilePath(), JSON.stringify(next, null, 2), 'utf8');
  return next;
}

async function pathExists(targetPath) {
  if (!targetPath) return false;
  try {
    await fs.access(targetPath);
    return true;
  } catch (error) {
    return false;
  }
}

async function buildSessionPayload() {
  const session = await readSession();
  const payload = {
    ...session,
    excelData: null,
    rulesText: session.lastRulesText || '',
    warnings: []
  };

  if (session.lastExcelPath) {
    try {
      const data = await fs.readFile(session.lastExcelPath);
      payload.excelData = Uint8Array.from(data);
    } catch (error) {
      payload.warnings.push('上次的 Excel 文件不存在或无法读取，已跳过自动恢复。');
    }
  }

  if (!payload.rulesText && session.lastRulesPath) {
    try {
      payload.rulesText = await fs.readFile(session.lastRulesPath, 'utf8');
    } catch (error) {
      if (session.lastRulesText) {
        payload.warnings.push('上次的规则 JSON 无法读取，已改用应用内保存的规则草稿。');
      } else {
        payload.warnings.push('上次的规则 JSON 不存在或无法读取。');
      }
    }
  }

  if (session.lastExportDir && !(await pathExists(session.lastExportDir))) {
    payload.warnings.push('上次的导出文件夹不存在，导出前请重新选择。');
    payload.lastExportDir = '';
  }

  return payload;
}

ipcMain.handle('sancho:get-session', async () => {
  return buildSessionPayload();
});

ipcMain.handle('sancho:set-session', async (_event, payload) => {
  return writeSession(payload);
});

ipcMain.handle('sancho:open-rules-json', async () => {
  const result = await dialog.showOpenDialog({
    title: '选择导出规则 JSON',
    properties: ['openFile'],
    filters: [{ name: 'JSON 文件', extensions: ['json'] }]
  });
  if (result.canceled || !result.filePaths[0]) return { canceled: true };

  const filePath = result.filePaths[0];
  const text = await fs.readFile(filePath, 'utf8');
  await writeSession({
    lastRulesPath: filePath,
    lastRulesName: path.basename(filePath),
    lastRulesText: text
  });
  return {
    canceled: false,
    name: path.basename(filePath),
    path: filePath,
    text
  };
});

ipcMain.handle('sancho:open-excel-file', async () => {
  const result = await dialog.showOpenDialog({
    title: '选择 Excel 文件',
    properties: ['openFile'],
    filters: [{ name: 'Excel 文件', extensions: ['xlsx', 'xlsm', 'xls'] }]
  });
  if (result.canceled || !result.filePaths[0]) return { canceled: true };

  const filePath = result.filePaths[0];
  const data = await fs.readFile(filePath);
  await writeSession({
    lastExcelPath: filePath,
    lastExcelName: path.basename(filePath)
  });
  return {
    canceled: false,
    name: path.basename(filePath),
    path: filePath,
    data: Uint8Array.from(data)
  };
});

ipcMain.handle('sancho:save-rules-json', async (_event, payload) => {
  const result = await dialog.showSaveDialog({
    title: '保存导出规则',
    defaultPath: payload && payload.defaultName ? payload.defaultName : 'SanchoSheetset-导出规则.json',
    filters: [{ name: 'JSON 文件', extensions: ['json'] }]
  });
  if (result.canceled || !result.filePath) return { canceled: true };

  const text = payload && payload.text ? payload.text : '[]';
  await fs.writeFile(result.filePath, text, 'utf8');
  await writeSession({
    lastRulesPath: result.filePath,
    lastRulesName: path.basename(result.filePath),
    lastRulesText: text
  });
  return {
    canceled: false,
    name: path.basename(result.filePath),
    path: result.filePath
  };
});

ipcMain.handle('sancho:pick-export-directory', async () => {
  const result = await dialog.showOpenDialog({
    title: '选择导出文件夹',
    properties: ['openDirectory', 'createDirectory']
  });
  if (result.canceled || !result.filePaths[0]) return { canceled: true };

  await writeSession({
    lastExportDir: result.filePaths[0]
  });
  return {
    canceled: false,
    path: result.filePaths[0],
    name: path.basename(result.filePaths[0])
  };
});

ipcMain.handle('sancho:write-export-file', async (_event, payload) => {
  if (!payload || !payload.dirPath || !payload.filename) {
    throw new Error('Missing export file parameters');
  }

  const filePath = path.join(payload.dirPath, payload.filename);
  const buffer = Buffer.from(payload.data);
  await fs.mkdir(payload.dirPath, { recursive: true });
  await fs.writeFile(filePath, buffer);

  return {
    path: filePath,
    name: path.basename(filePath)
  };
});

function createWindow() {
  const win = new BrowserWindow({
    title: APP_TITLE,
    width: 1180,
    height: 780,
    minWidth: 980,
    minHeight: 680,
    autoHideMenuBar: true,
    backgroundColor: '#f0f2f5',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
    }
  });

  win.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });

  win.loadFile(path.join(__dirname, '..', 'web', 'index.html'));
}

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
