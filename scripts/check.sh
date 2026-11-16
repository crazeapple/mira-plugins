#!/usr/bin/env bash
# mira-plugins 统一门禁——本地与 CI 同一入口，节：
#   1 插件 manifest 校验：sdd/.claude-plugin/plugin.json （--strict）
#   2 市场 manifest 校验：.claude-plugin/marketplace.json（--strict）
#   3 session-start hook 测试：运行 sdd/tests/test-session-start.sh
#   4 版本三点一致：plugin.json ↔ marketplace 条目 ↔ tmpl-registry schema
#   5 markdownlint：全仓 md（禁用 MD013 MD060——对中文不适用）
#   6 sdd: 引用完整性：全仓 md 中的逻辑地址与真实路径引用
#   7 模板形状守卫：sdd/templates/*.md 表格列数一致 + 无实例数据
# 依赖 node 与 npx
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
FAILURES=0

section() { echo; echo "── $1 ─────────────────────────────"; }
record() {
  if [ "$1" -eq 0 ]; then echo "  ✔ $2"; else echo "  ✘ $2"; FAILURES=$((FAILURES + 1)); fi
}

section "1. 插件 manifest 校验（--strict）"
out=$(claude plugin validate ./sdd --strict 2>&1)
rc=$?
record $rc "claude plugin validate ./sdd --strict"
if [ $rc -ne 0 ]; then printf '%s\n' "$out" | tail -5; fi

section "2. 市场 manifest 校验（--strict）"
out=$(claude plugin validate . --strict 2>&1)
rc=$?
record $rc "claude plugin validate . --strict"
if [ $rc -ne 0 ]; then printf '%s\n' "$out" | tail -5; fi

section "3. session-start 测试"
bash sdd/tests/test-session-start.sh || FAILURES=$((FAILURES + 1))

section "4. 版本三点一致"
bash sdd/tests/test-version-consistency.sh || FAILURES=$((FAILURES + 1))

section "5. markdownlint（禁用 MD013 MD060——对中文不适用）"
out=$(npx -y markdownlint-cli --disable MD013 MD060 -- "**/*.md" 2>&1)
rc=$?
record $rc "markdownlint 零 error"
if [ $rc -ne 0 ]; then printf '%s\n' "$out" | head -20; fi

section "6. sdd: 引用完整性"
node -e '
const fs = require("fs"), path = require("path");
const root = process.argv[1];
const files = [];
(function walk(d) {
  for (const e of fs.readdirSync(d, { withFileTypes: true })) {
    if (e.name === ".git" || e.name === "node_modules") continue;
    const p = path.join(d, e.name);
    if (e.isDirectory()) walk(p); else if (e.name.endsWith(".md")) files.push(p);
  }
})(root);
const dead = [];
const missing = (full, text, m) => {
  if (fs.existsSync(full)) return false;
  // 通配写法（如 tmpl-*.md）：末段被截断，查其父目录
  if (text[m.index + m[0].length] === "*") return !fs.existsSync(path.dirname(full));
  return true;
};
for (const f of files) {
  const text = fs.readFileSync(f, "utf8");
  const rel = path.relative(root, f);
  for (const m of text.matchAll(/sdd:(?:skills|templates|hooks|tests)(?:\/[A-Za-z0-9._\-]+)+/g)) {
    if (missing(path.join(root, "sdd", m[0].slice(4)), text, m)) dead.push(rel + "  " + m[0]);
  }
  for (const m of text.matchAll(/sdd\/(?:skills|templates|hooks|tests|\.claude-plugin)(?:\/[A-Za-z0-9._\-]+)+/g)) {
    if (missing(path.join(root, m[0]), text, m)) dead.push(rel + "  " + m[0]);
  }
}
if (dead.length) { console.error(dead.map(s => "    " + s).join("\n")); process.exit(1); }
' "$REPO"
record $? "逻辑地址与真实路径引用全部存在"

section "7. 模板形状守卫（表格列数一致 + 无实例数据）"
node -e '
const fs = require("fs"), path = require("path");
const dir = process.argv[1];
const inst = [/\d{4}-\d{2}-\d{2}/, /\[I-\d+\]/, /\[P-\d+\]/, /\bAM-\d+\b/, /\bP-\d{3}\b/];
const errs = [];
for (const f of fs.readdirSync(dir).filter(n => n.endsWith(".md")).sort()) {
  const full = path.join(dir, f);
  const lines = fs.readFileSync(full, "utf8").split("\n");
  lines.forEach((line, i) => {
    for (const re of inst) if (re.test(line)) errs.push(f + ":" + (i + 1) + "  实例数据: " + line.trim());
  });
  const cols = s => s.trim().replace(/^\|/, "").replace(/\|$/, "").split("|").length;
  for (let i = 0; i < lines.length; i++) {
    if (!lines[i].startsWith("|")) continue;
    if (i + 1 >= lines.length || !/^\|[\s:\-|]+\|$/.test(lines[i + 1])) continue;
    const nc = cols(lines[i]), ns = cols(lines[i + 1]);
    if (nc !== ns) errs.push(f + ":" + (i + 2) + "  表头 " + nc + " 列，分隔行 " + ns + " 列");
    for (let j = i + 2; j < lines.length && lines[j].startsWith("|"); j++) {
      const nd = cols(lines[j]);
      if (nd !== nc) errs.push(f + ":" + (j + 1) + "  数据行 " + nd + " 列，表头 " + nc + " 列");
    }
  }
}
if (errs.length) { console.error(errs.map(s => "    " + s).join("\n")); process.exit(1); }
' "$REPO/sdd/templates"
record $? "模板表格列数一致、无实例数据"

echo
if [ "$FAILURES" -eq 0 ]; then echo "ALL GATES OK"; exit 0; fi
echo "FAILED: $FAILURES 节未过"
exit 1
