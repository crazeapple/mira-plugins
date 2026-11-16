#!/usr/bin/env bash
# 校验插件版本一致：plugin.json ↔ marketplace.json 条目 ↔ tmpl-registry schema 行；CHANGELOG.md 有对应版本节
# （claude plugin validate 交叉核对前两者，模板 schema 行与 CHANGELOG 节是它的盲区——本测试补位）
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
if [ "$unique_count" -ne 1 ]; then
  echo "  [FAIL] 版本漂移（plugin.json / marketplace 条目 / 模板 schema）:"
  printf '%s\n' "$values" | sed 's/^/    /'
  echo "STATUS: FAILED"
  exit 1
fi

version=$(printf '%s\n' "$values" | head -1)
if grep -q "^## $version" "$REPO/CHANGELOG.md"; then
  echo "  [PASS] 版本三点一致: $version"
  echo "  [PASS] CHANGELOG 有版本节: ## $version"
else
  echo "  [FAIL] CHANGELOG.md 缺少版本节: ## $version"
  echo "STATUS: FAILED"
  exit 1
fi
echo "STATUS: PASSED"
exit 0
