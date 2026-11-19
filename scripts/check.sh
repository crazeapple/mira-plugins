#!/usr/bin/env bash
# mira-plugins 统一门禁——本地与 CI 同一入口，节：
#   1 JSON 可解析：.claude-plugin/marketplace.json / sdd/.claude-plugin/plugin.json / sdd/hooks/hooks.json
#   2 插件 manifest 校验：sdd/.claude-plugin/plugin.json （--strict）
#   3 市场 manifest 校验：.claude-plugin/marketplace.json（--strict）
#   4 session-start hook 测试：运行 sdd/tests/test-session-start.sh
#   5 版本一致：plugin.json ↔ marketplace 条目 ↔ tmpl-registry schema + CHANGELOG 对应节
#   6 markdownlint：全仓 md（禁用 MD013 MD060——对中文不适用）
#   7 sdd: 引用完整性：全仓 md（CHANGELOG 除外）中 sdd: 路径形指向存在 + 调用形为现行技能名
#   8 步骤引用完整性：sdd/skills 内「第 N(-M) 步」三形态的目标步骤号存在
#   9 模板形状守卫：sdd/templates/*.md 表格列数一致 + 无实例数据
# 依赖 node 与 npx
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
FAILURES=0

section() { echo; echo "── $1 ─────────────────────────────"; }
record() {
  if [ "$1" -eq 0 ]; then echo "  ✔ $2"; else echo "  ✘ $2"; FAILURES=$((FAILURES + 1)); fi
}

section "1. JSON 可解析"
node -e '
const fs = require("fs");
for (const f of [".claude-plugin/marketplace.json", "sdd/.claude-plugin/plugin.json", "sdd/hooks/hooks.json"]) {
  try { JSON.parse(fs.readFileSync(f, "utf8")); }
  catch (e) { console.error("    " + f + "  " + e.message); process.exit(1); }
}
'
record $? "marketplace / plugin / hooks 三个 JSON 可解析"

section "2. 插件 manifest 校验（--strict）"
out=$(claude plugin validate ./sdd --strict 2>&1)
rc=$?
record $rc "claude plugin validate ./sdd --strict"
if [ $rc -ne 0 ]; then printf '%s\n' "$out" | tail -5; fi

section "3. 市场 manifest 校验（--strict）"
out=$(claude plugin validate . --strict 2>&1)
rc=$?
record $rc "claude plugin validate . --strict"
if [ $rc -ne 0 ]; then printf '%s\n' "$out" | tail -5; fi

section "4. session-start 测试"
bash sdd/tests/test-session-start.sh || FAILURES=$((FAILURES + 1))

section "5. 版本一致"
bash sdd/tests/test-version-consistency.sh || FAILURES=$((FAILURES + 1))

section "6. markdownlint（禁用 MD013 MD060——对中文不适用）"
out=$(npx -y markdownlint-cli@0.50.0 --disable MD013 MD060 -- "**/*.md" 2>&1)
rc=$?
record $rc "markdownlint 零 error"
if [ $rc -ne 0 ]; then printf '%s\n' "$out" | head -20; fi

section "7. sdd: 引用完整性"
node -e '
const fs = require("fs"), path = require("path");
const root = process.argv[1];
const files = [];
(function walk(d) {
  for (const e of fs.readdirSync(d, { withFileTypes: true })) {
    if (e.name === ".git" || e.name === "node_modules") continue;
    if (e.name === "CHANGELOG.md" && d === root) continue; // 历史节不改史，不受现行有效性检查
    const p = path.join(d, e.name);
    if (e.isDirectory()) walk(p); else if (e.name.endsWith(".md")) files.push(p);
  }
})(root);
const skills = fs.readdirSync(path.join(root, "sdd", "skills"), { withFileTypes: true })
  .filter(e => e.isDirectory()).map(e => e.name);
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
  // 调用形：sdd:<技能名>（后不接 /）须为现行技能名
  for (const m of text.matchAll(/sdd:([A-Za-z][A-Za-z0-9\-]*)/g)) {
    if (text[m.index + m[0].length] === "/") continue;
    if (!skills.includes(m[1])) dead.push(rel + "  " + m[0] + "  （现行技能: " + skills.join(", ") + "）");
  }
}
if (dead.length) { console.error(dead.map(s => "    " + s).join("\n")); process.exit(1); }
' "$REPO"
record $? "路径形指向存在 + 调用形为现行技能名（CHANGELOG 除外）"

section "8. 步骤引用完整性"
# 注意：本节只断言序号存在（悬空）；号在、指错步的错位裸号形态下不可机械判——重编号/删步后逐条核对引用指向，归评审
node -e '
const fs = require("fs"), path = require("path");
const root = path.join(process.argv[1], "sdd", "skills");
const errs = [];
const steps = f => {
  const set = new Set();
  for (const l of fs.readFileSync(f, "utf8").split("\n")) {
    const m = l.match(/^### (\d+)\. /);
    if (m) set.add(Number(m[1]));
  }
  return set;
};
const summary = set => {
  const ks = [...set].sort((a, b) => a - b);
  if (!ks.length) return "无编号标题";
  const parts = [];
  let s = ks[0], p = ks[0];
  for (const k of ks.slice(1)) {
    if (k === p + 1) { p = k; continue; }
    parts.push(s === p ? "" + s : s + "-" + p);
    s = p = k;
  }
  parts.push(s === p ? "" + s : s + "-" + p);
  return parts.join(", ");
};
const skillSteps = new Map(
  fs.readdirSync(root, { withFileTypes: true })
    .filter(e => e.isDirectory())
    .map(e => [e.name, steps(path.join(root, e.name, "SKILL.md"))])
);
const files = [];
(function walk(d) {
  for (const e of fs.readdirSync(d, { withFileTypes: true })) {
    const p = path.join(d, e.name);
    if (e.isDirectory()) walk(p); else if (e.name.endsWith(".md")) files.push(p);
  }
})(root);
const flag = (rel, no, ref, tgtName, tgt, lo, hi) => {
  if (hi < lo) { errs.push(rel + ":" + no + "  " + ref + " → 区间倒序"); return; }
  for (let n = lo; n <= hi; n++)
    if (!tgt.has(n)) errs.push(rel + ":" + no + "  " + ref + " → " + tgtName + " 无步骤 " + n + "（现有: " + summary(tgt) + "）");
};
for (const f of files) {
  const rel = path.relative(root, f);
  const skill = rel.split(path.sep)[0];
  const own = steps(f);
  fs.readFileSync(f, "utf8").split("\n").forEach((line, i) => {
    // 限定形最长匹配优先：整体消费，内层不再按裸形重解
    const spans = [];
    for (const m of line.matchAll(/(\w+ SKILL\.md|\w+ SKILL|SKILL\.md) ?第 ?(\d+)(?:-(\d+))? ?步/g)) {
      spans.push([m.index, m.index + m[0].length]);
      const q = m[1] === "SKILL.md" ? skill : m[1].replace(/ SKILL(\.md)?$/, "");
      if (!skillSteps.has(q)) { errs.push(rel + ":" + (i + 1) + "  " + m[0] + " → 未知技能 " + q); continue; }
      flag(rel, i + 1, m[0], q + "/SKILL.md", skillSteps.get(q), Number(m[2]), Number(m[3] ?? m[2]));
    }
    for (const m of line.matchAll(/第 ?(\d+)(?:-(\d+))? ?步/g)) {
      if (spans.some(([a, b]) => m.index >= a && m.index < b)) continue;
      if (!own.size) { errs.push(rel + ":" + (i + 1) + "  " + m[0] + " → 本文件无编号标题，裸引用指代不明（用 SKILL.md 第 N 步限定）"); continue; }
      flag(rel, i + 1, m[0], "本文件", own, Number(m[1]), Number(m[2] ?? m[1]));
    }
  });
}
if (errs.length) { console.error(errs.map(s => "    " + s).join("\n")); process.exit(1); }
' "$REPO"
record $? "三形态步骤引用的目标步骤号全部存在"

section "9. 模板形状守卫（表格列数一致 + 无实例数据）"
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
