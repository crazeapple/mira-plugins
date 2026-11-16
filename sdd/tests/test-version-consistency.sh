#!/usr/bin/env bash
# 校验插件版本三点一致：plugin.json ↔ marketplace.json 条目 ↔ tmpl-registry schema 行
# （claude plugin validate 交叉核对前两者，模板 schema 行是它的盲区——本测试补位）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO="$(cd "$PLUGIN/.." && pwd)"

read_values() {
  node -e '
const fs = require("fs");
const [pluginJson, marketplaceJson, registryTpl] = process.argv.slice(1);
const manifest = JSON.parse(fs.readFileSync(pluginJson, "utf8"));
const entry = (JSON.parse(fs.readFileSync(marketplaceJson, "utf8")).plugins || [])
  .find(p => p.name === manifest.name);
if (!entry) { console.error("marketplace.json 缺少条目: " + manifest.name); process.exit(1); }
const m = fs.readFileSync(registryTpl, "utf8").match(/^schema:\s*(\S+)\s*$/m);
if (!m) { console.error("tmpl-registry.md 缺少 schema 行"); process.exit(1); }
console.log(manifest.version + "\n" + entry.version + "\n" + m[1]);
' "$PLUGIN/.claude-plugin/plugin.json" "$REPO/.claude-plugin/marketplace.json" "$PLUGIN/templates/tmpl-registry.md"
}

if ! values=$(read_values); then
  echo "STATUS: FAILED"
  echo "$values" | sed 's/^/  /'
  exit 1
fi

unique_count=$(printf '%s\n' "$values" | sort -u | wc -l | tr -d ' ')
if [ "$unique_count" -eq 1 ]; then
  echo "  [PASS] 版本三点一致: $(printf '%s\n' "$values" | head -1)"
  echo "STATUS: PASSED"
  exit 0
fi

echo "  [FAIL] 版本漂移（plugin.json / marketplace 条目 / 模板 schema）:"
printf '%s\n' "$values" | sed 's/^/    /'
echo "STATUS: FAILED"
exit 1
