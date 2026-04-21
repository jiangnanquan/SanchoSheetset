#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

repo_slug_from_remote() {
  local remote_url
  remote_url=$(git remote get-url origin 2>/dev/null || echo "")
  if [ -z "$remote_url" ]; then
    return 1
  fi
  printf '%s\n' "$remote_url" | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##'
}

repo_slug_from_package() {
  node -e '
const pkg = require("./package.json");
const source = (pkg.repository && pkg.repository.url) || pkg.homepage || "";
const match = source.match(/github\.com[/:]([^/]+\/[^/.]+)/);
if (match) process.stdout.write(match[1]);
'
}

usage() {
  echo "用法:"
  echo "  ./build.sh local           本地编译当前平台"
  echo "  ./build.sh release [版本]  推送 GitHub 并触发 Win/macOS 构建"
  echo ""
  echo "示例:"
  echo "  ./build.sh local"
  echo "  ./build.sh release v1.1.0"
}

# ========== 本地编译 ==========
build_local() {
  echo "=== 本地编译 ==="

  if ! command -v npm &>/dev/null; then
    echo "需要先安装 Node.js / npm"
    exit 1
  fi

  if [ ! -d node_modules ]; then
    echo "安装 Electron 依赖..."
    npm install
  fi

  case "$(uname -s)" in
    Darwin)
      echo "开始构建 macOS 安装包..."
      npm run dist:mac
      ;;
    Linux)
      echo "当前脚本未启用 Linux 打包；如需扩展请补充目标。"
      exit 1
      ;;
    *)
      echo "开始构建 Windows 安装包..."
      npm run dist:win
      ;;
  esac

  # 找到产出文件
  echo ""
  echo "=== 编译完成 ==="
  echo "产出文件:"

  ls -lh release/* 2>/dev/null || true
}

# ========== 远程发布 ==========
build_release() {
  VERSION="${1:-v1.0.0}"
  echo "=== 远程发布 $VERSION ==="

  if ! gh auth status &>/dev/null; then
    echo "请先登录: gh auth login"
    exit 1
  fi

  TARGET_REPO_SLUG=$(repo_slug_from_package || echo "jiangnanquan/SanchoSheetset")
  CURRENT_REPO_SLUG=$(repo_slug_from_remote || echo "")

  if [ -z "$CURRENT_REPO_SLUG" ]; then
    echo "创建 GitHub 仓库: $TARGET_REPO_SLUG"
    gh repo create "$TARGET_REPO_SLUG" --public --source=. --remote=origin
    REPO_SLUG="$TARGET_REPO_SLUG"
  else
    if [ "$CURRENT_REPO_SLUG" != "$TARGET_REPO_SLUG" ]; then
      echo "origin 当前指向 $CURRENT_REPO_SLUG，发布前切换到 $TARGET_REPO_SLUG"
      if ! gh repo view "$TARGET_REPO_SLUG" &>/dev/null; then
        gh repo create "$TARGET_REPO_SLUG" --public
      fi
      git remote set-url origin "https://github.com/$TARGET_REPO_SLUG.git"
    fi
    REPO_SLUG="$TARGET_REPO_SLUG"
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
  echo "进度: https://github.com/$REPO_SLUG/actions"
  echo "下载: https://github.com/$REPO_SLUG/releases"
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
