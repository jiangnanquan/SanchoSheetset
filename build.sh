#!/bin/bash
set -e

VERSION="${1:-v1.0.0}"

echo "=== Excel 报表导出工具 - 一键发布 ==="
echo "版本: $VERSION"
echo ""

# 检查 gh 登录
if ! gh auth status &>/dev/null; then
  echo "请先登录: gh auth login"
  exit 1
fi

# 检查远程仓库
REPO_URL=$(git remote get-url origin 2>/dev/null || echo "")
if [ -z "$REPO_URL" ]; then
  echo "创建 GitHub 仓库..."
  gh repo create excel-export-tool --public --source=. --remote=origin --push
else
  echo "远程仓库: $REPO_URL"
fi

# 提交所有变更
if [ -n "$(git status --porcelain)" ]; then
  echo "提交变更..."
  git add -A
  git commit -m "release: $VERSION"
fi

# 推送代码
echo "推送代码..."
git push -u origin main

# 打 tag 触发构建
echo "创建 tag: $VERSION"
git tag -f "$VERSION" -m "Release $VERSION"
git push origin "$VERSION" --force

echo ""
echo "=== 完成 ==="
echo "GitHub Actions 正在构建，查看进度："
echo "  https://github.com/jiangnanquan/excel-export-tool/actions"
echo ""
echo "构建完成后，Release 页面下载安装包："
echo "  https://github.com/jiangnanquan/excel-export-tool/releases"
