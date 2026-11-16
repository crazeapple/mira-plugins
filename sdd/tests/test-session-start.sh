#!/usr/bin/env bash
# 校验 sdd session-start：3 种 harness 的 JSON 输出形状 + 空 PATH 防御
# + hooks.json 注册形状 + 插件根寻址注入。机制蓝本：superpowers tests/hooks/test-session-start.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN="$(cd "$SCRIPT_DIR/.." && pwd)"

FAILURES=0
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

# 组装临时插件结构（用真插件文件 + fixture 元技能）
STAGE="$TEST_ROOT/plugin"
mkdir -p "$STAGE/hooks" "$STAGE/skills/bootstrap"
cp "$PLUGIN/hooks/session-start" "$STAGE/hooks/session-start"
cp "$PLUGIN/hooks/hooks.json" "$STAGE/hooks/hooks.json"
cat > "$STAGE/skills/bootstrap/SKILL.md" <<'EOF'
---
name: bootstrap
description: bootstrap fixture for sdd tests
---
# Fixture
probe marker for sdd hook tests
EOF

# ── 断言 1：hooks.json 注册形状（matcher + shell:bash + CLAUDE_PLUGIN_ROOT）──
if node -e '
const hooks = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
const entry = hooks.hooks.SessionStart[0];
if (entry.matcher !== "startup|clear|compact") {
  console.error("bad matcher: " + JSON.stringify(entry.matcher)); process.exit(1);
}
const h = entry.hooks[0];
if (h.shell !== "bash") { console.error("shell must be bash"); process.exit(1); }
if (!h.command.includes("${CLAUDE_PLUGIN_ROOT}/hooks/session-start")) {
  console.error("command must reference ${CLAUDE_PLUGIN_ROOT}/hooks/session-start"); process.exit(1);
}
' "$STAGE/hooks/hooks.json"; then
  pass "hooks.json: matcher startup|clear|compact + shell:bash + CLAUDE_PLUGIN_ROOT"
else
  fail "hooks.json: matcher startup|clear|compact + shell:bash + CLAUDE_PLUGIN_ROOT"
fi

# ── JSON 形状断言器（3 种形状 + 互斥）──
check_output() {
  local desc="$1" shape="$2"; shift 2
  local output
  if ! output="$(env -i PATH="${PATH:-}" HOME="$TEST_ROOT/home" "$@" 2>&1)"; then
    fail "$desc"; echo "    hook exited non-zero:"; echo "$output" | sed 's/^/      /'; return
  fi
  if printf '%s' "$output" | SHAPE="$shape" EXPECT_ROOT="$STAGE" node -e '
const fs = require("fs");
let payload;
try { payload = JSON.parse(fs.readFileSync(0, "utf8")); }
catch (e) { console.error("invalid JSON: " + e.message); process.exit(1); }
const has = (o, k) => Object.prototype.hasOwnProperty.call(o, k);
const shape = process.env.SHAPE;
let ctx;
if (shape === "nested") {
  if (!has(payload, "hookSpecificOutput")) { console.error("missing hookSpecificOutput"); process.exit(1); }
  if (has(payload, "additional_context") || has(payload, "additionalContext")) {
    console.error("nested output leaked a top-level context field (double-injection risk)"); process.exit(1);
  }
  if (payload.hookSpecificOutput.hookEventName !== "SessionStart") {
    console.error("bad hookEventName"); process.exit(1);
  }
  ctx = payload.hookSpecificOutput.additionalContext;
} else if (shape === "cursor") {
  if (has(payload, "hookSpecificOutput") || has(payload, "additionalContext")) {
    console.error("cursor output must contain only additional_context"); process.exit(1);
  }
  ctx = payload.additional_context;
} else {
  if (has(payload, "hookSpecificOutput") || has(payload, "additional_context")) {
    console.error("sdk output must contain only additionalContext"); process.exit(1);
  }
  ctx = payload.additionalContext;
}
if (typeof ctx !== "string" || ctx.trim() === "") { console.error("empty context"); process.exit(1); }
if (!ctx.includes("bootstrap")) { console.error("context missing bootstrap skill content"); process.exit(1); }
if (!ctx.includes("EXTREMELY_IMPORTANT")) { console.error("context missing EXTREMELY_IMPORTANT wrapper"); process.exit(1); }
if (!ctx.includes(process.env.EXPECT_ROOT)) { console.error("context missing plugin root path (sdd: addressing)"); process.exit(1); }
'; then
    pass "$desc"
  else
    fail "$desc"; echo "$output" | sed 's/^/      /'
  fi
}

# ── 断言 2-5：三种分支 + 空 PATH ──
check_output "Claude Code 分支：nested hookSpecificOutput.additionalContext" nested \
  CLAUDE_PLUGIN_ROOT="$STAGE" bash "$STAGE/hooks/session-start"

check_output "Cursor 分支：仅顶层 additional_context" cursor \
  CURSOR_PLUGIN_ROOT="$STAGE" CLAUDE_PLUGIN_ROOT="$STAGE" bash "$STAGE/hooks/session-start"

check_output "Copilot/SDK 分支：仅顶层 additionalContext" sdk \
  COPILOT_CLI=1 CLAUDE_PLUGIN_ROOT="$STAGE" bash "$STAGE/hooks/session-start"

# 空 PATH 防御（anthropics/claude-code#43127）
bash_bin="$(command -v bash)"
check_output "空 PATH 下仍输出 nested additionalContext" nested \
  PATH="" CLAUDE_PLUGIN_ROOT="$STAGE" "$bash_bin" "$STAGE/hooks/session-start"

# ── 断言 6：真插件文件一致性（SKILL_REL ↔ 目录 ↔ frontmatter 三处一致）──
if grep -q 'SKILL_REL:-skills/bootstrap/SKILL.md' "$PLUGIN/hooks/session-start" \
   && [ -f "$PLUGIN/skills/bootstrap/SKILL.md" ] \
   && head -5 "$PLUGIN/skills/bootstrap/SKILL.md" | grep -q '^name: bootstrap$'; then
  pass "SKILL_REL ↔ skills/bootstrap/ ↔ frontmatter name 三处一致"
else
  fail "SKILL_REL ↔ skills/bootstrap/ ↔ frontmatter name 三处一致"
fi

if [[ "$FAILURES" -gt 0 ]]; then
  echo "STATUS: FAILED ($FAILURES failure(s))"
  exit 1
fi
echo "STATUS: PASSED"
