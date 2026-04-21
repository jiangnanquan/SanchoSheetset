# Excel 报表导出工具

上传 Excel 文件（xlsx/xlsm），按规则拆分导出为多个干净的 xlsx。

- 保留原始格式（字体、颜色、边框、合并单元格、列宽、行高）
- 自动去除 VBA 宏、Power Query 连接、外部链接
- 公式固化为值，以显示为准
- 规则可自定义、可保存

## 使用方式

### 直接使用（无需安装）

双击 `index.html` 即可在浏览器中使用。

### 桌面应用

从 [Releases](../../releases) 下载对应平台安装包：

| 平台 | 文件 |
|------|------|
| Windows x64 | `.exe` (NSIS 安装包) |
| macOS (Apple Silicon) | `.dmg` |
| macOS (Intel) | `.dmg` |
| Linux | `.AppImage` / `.deb` |

## 构建

```bash
./build.sh
```

## 文件说明

| 文件 | 用途 |
|------|------|
| `index.html` | 主页面 |
| `exceljs.min.js` | ExcelJS 离线库 |
| `export-rules.json` | 导出规则配置 |

## 作者

甘泉 | 13857867800
