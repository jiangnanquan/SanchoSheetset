# SanchoSheetset

SanchoSheetset 是一个 Electron 桌面工具，用来把一个 Excel 工作簿按规则拆分成多个独立的 `.xlsx` 文件，适合日报、资金表、用途统计等固定报表场景。

## 当前能力

- 选择 Excel 文件并读取全部工作表
- 用多条规则组合导出不同工作簿
- 保留列宽、行高、合并单元格和样式
- 将公式导出为结果值，避免带出宏、外链和查询连接
- 导入、编辑、保存规则 JSON
- 记住上次使用的 Excel、规则草稿和导出文件夹
- 直接导出到本地目录，不再依赖浏览器下载和沙盒授权

## 运行方式

### 本地开发

```bash
npm install
npm start
```

### 本地打包

```bash
./build.sh local
```

### GitHub 发布

```bash
./build.sh release
```

推送 tag 后，GitHub Actions 会产出：

- Windows x64 安装包
- macOS Apple Silicon `.dmg`

## 技术栈

- Electron
- Electron Builder
- 原生文件对话框 + 本地文件系统读写
- ExcelJS

## 项目结构

- `package.json`: 应用和打包配置
- `electron/main.js`: 主进程、文件对话框和本地持久化
- `electron/preload.js`: 渲染层安全桥接
- `web/index.html`: 桌面应用界面和 Excel 导出逻辑
- `web/export-rules.example.json`: 规则示例
- `build/icons/`: 安装包图标
- `.github/workflows/build.yml`: Win/macOS 构建与 GitHub Release

## 开源说明

本项目按 MIT License 开源。

## 作者

甘泉 | 13857867800
