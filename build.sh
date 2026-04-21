#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

usage() {
  echo "用法:"
  echo "  ./build.sh local           本地编译当前平台"
  echo "  ./build.sh release [版本]  推送到 GitHub，触发全平台构建"
  echo ""
  echo "示例:"
  echo "  ./build.sh local"
  echo "  ./build.sh release v1.1.0"
}

# ========== 本地编译 ==========
build_local() {
  echo "=== 本地编译 ==="

  # 检查 cargo
  if ! command -v cargo &>/dev/null; then
    echo "需要安装 Rust: https://rustup.rs"
    exit 1
  fi

  # 检查 tauri-cli
  if ! cargo tauri --version &>/dev/null; then
    echo "安装 Tauri CLI..."
    cargo install tauri-cli --version "^2"
  fi

  echo "开始编译（首次约 5-8 分钟）..."
  cargo tauri build 2>&1

  # 找到产出文件
  echo ""
  echo "=== 编译完成 ==="
  echo "产出文件:"

  BUNDLE_DIR="src-tauri/target/release/bundle"
  if [ -d "$BUNDLE_DIR/dmg" ]; then
    ls -lh "$BUNDLE_DIR/dmg/"*.dmg 2>/dev/null && echo ""
  fi
  if [ -d "$BUNDLE_DIR/macos" ]; then
    ls -lhd "$BUNDLE_DIR/macos/"*.app 2>/dev/null && echo ""
  fi
  if [ -d "$BUNDLE_DIR/nsis" ]; then
    ls -lh "$BUNDLE_DIR/nsis/"*.exe 2>/dev/null && echo ""
  fi
  if [ -d "$BUNDLE_DIR/appimage" ]; then
    ls -lh "$BUNDLE_DIR/appimage/"*.AppImage 2>/dev/null && echo ""
  fi
  if [ -d "$BUNDLE_DIR/deb" ]; then
    ls -lh "$BUNDLE_DIR/deb/"*.deb 2>/dev/null && echo ""
  fi

  echo "也可以直接运行:"
  echo "  open $BUNDLE_DIR/macos/*.app"
}

# ========== 远程发布 ==========
build_release() {
  VERSION="${1:-v1.0.0}"
  echo "=== 远程发布 $VERSION ==="

  if ! gh auth status &>/dev/null; then
    echo "请先登录: gh auth login"
    exit 1
  fi

  REPO_URL=$(git remote get-url origin 2>/dev/null || echo "")
  if [ -z "$REPO_URL" ]; then
    echo "创建 GitHub 仓库..."
    gh repo create excel-export-tool --public --source=. --remote=origin --push
  fi

  if [ -n "$(git status --porcelain)" ]; then
    echo "提交变更..."
    git add -A
    git commit -m "release: $VERSION"
  fi

  echo "推送代码..."
  git push -u origin main

  echo "创建 tag: $VERSION"
  git tag -f "$VERSION" -m "Release $VERSION"
  git push origin "$VERSION" --force

  echo ""
  echo "=== 已触发 GitHub Actions ==="
  echo "进度: https://github.com/jiangnanquan/excel-export-tool/actions"
  echo "下载: https://github.com/jiangnanquan/excel-export-tool/releases"
}

# ========== 入口 ==========
case "${1:-}" in
  local)
    build_local
    ;;
  release)
    build_release "$2"
    ;;
  *)
    usage
    ;;
esac
