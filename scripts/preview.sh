#!/usr/bin/env bash
# Preview drafts locally without changing production configuration.
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
HUGO=${HUGO_BIN:-hugo}
PORT=${PORT:-1313}

if ! command -v "$HUGO" >/dev/null 2>&1; then
  printf '找不到 Hugo。请安装 Hugo，或设置 HUGO_BIN=/path/to/hugo 再运行。\n' >&2
  exit 1
fi

WORK_DIR=$(mktemp -d /tmp/hugo-blog-preview.XXXXXX)
cat > "$WORK_DIR/preview.toml" <<CONFIG
resourceDir = "$WORK_DIR/resources"

# Do not load the live blog's comment widget on local draft previews.
[params.giscus]
repo = ""
CONFIG

printf '本地预览：http://localhost:%s/\n' "$PORT"
printf '临时构建目录：%s\n' "$WORK_DIR"
printf '包含草稿与未来日期文章；按 Ctrl+C 停止。\n'

exec "$HUGO" server \
  --source "$ROOT" \
  --config "$ROOT/config.toml,$WORK_DIR/preview.toml" \
  --bind 127.0.0.1 \
  --port "$PORT" \
  --baseURL "http://localhost:$PORT/" \
  --buildDrafts \
  --buildFuture \
  --disableFastRender \
  --noHTTPCache \
  --noBuildLock \
  --cacheDir "$WORK_DIR/cache" \
  --destination "$WORK_DIR/public"
