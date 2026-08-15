#!/usr/bin/env bash
# deploy.sh — install or update the loop-contract (with mandatory project-mcp-tools coupling)
# into a target project safely without destroying existing project state.
# Usage: ./deploy.sh /path/to/target/project
#
# File model (the two classes are never mixed):
#   SPEC files    — the contract itself (loop.md, run-loop.sh, compliance-rules.md).
#                   ALWAYS overwritten on deploy, so refining the contract and re-deploying
#                   propagates the new specification to every installed project.
#   CONTROL files — the stack-tree: docs/agent/stack-tree/index.md (root) plus the node
#                   markdowns created by sessions in that same flat folder. The root is
#                   bootstrapped once on first deploy from the embedded template below;
#                   NEVER modified afterwards, so re-deploying updates the specification
#                   without ever losing the project's accumulated task state.
#
# The CONTROL template lives inside this script (not in the loop-contract repo) on purpose:
# the loop-contract repo carries only the specification, and the stack-tree is born inside
# each target project, fully owned by it.
#
# Hard requirements:
#   - target project is a git repo with a README.md
#   - sibling project-mcp-tools repo exists at ../project-mcp-tools
#   - uv is installed
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  echo "usage: $0 /path/to/target/project" >&2
  exit 1
fi

if [[ ! -d "$TARGET" ]]; then
  echo "error: target directory does not exist: $TARGET" >&2
  exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"
if [[ "$TARGET" == "$SRC_DIR" ]]; then
  echo "error: refusing to deploy the contract onto itself." >&2
  exit 1
fi

echo "==> checking mandatory prerequisites"

if [[ ! -f "$TARGET/README.md" ]]; then
  echo "error: target project has no README.md (the contract's entry rules require it)." >&2
  exit 1
fi
if ! command -v uv >/dev/null 2>&1; then
  echo "error: 'uv' is not installed (required to run the project-mcp-tools MCP server)." >&2
  exit 1
fi

SIBLING_PMT="$(dirname "$TARGET")/project-mcp-tools"
if [[ ! -d "$SIBLING_PMT" ]]; then
  echo "error: project-mcp-tools not found at $SIBLING_PMT" >&2
  echo "       (deploy requires this sibling repo for the session_context_usage tool.)" >&2
  exit 1
fi

echo "==> updating specification (always overwritten)"

# 1. Core entry file and runner script
cp "$SRC_DIR/loop.md" "$TARGET/loop.md"
cp "$SRC_DIR/run-loop.sh" "$TARGET/run-loop.sh"
chmod +x "$TARGET/run-loop.sh"
echo "updated: loop.md, run-loop.sh"

# 2. Compliance rules
mkdir -p "$TARGET/docs/agent"
cp "$SRC_DIR/docs/agent/compliance-rules.md" "$TARGET/docs/agent/compliance-rules.md"
echo "updated: docs/agent/compliance-rules.md"

echo "==> bootstrapping the stack-tree root (first deploy only, never overwritten)"

# Bootstrap the stack-tree root from stdin. Existing control state is sacred:
# it holds the project's task tree and is never touched again.
bootstrap_control() {
  local path="$1"
  if [[ -f "$TARGET/$path" ]]; then
    echo "kept: $path (control state — preserved across deploys)"
    return
  fi
  mkdir -p "$(dirname "$TARGET/$path")"
  cat > "$TARGET/$path"
  echo "created: $path (stack-tree root template)"
}

# 3. Stack-tree root — the single control file of the contract
bootstrap_control docs/agent/stack-tree/index.md <<'EOF'
# Stack-Tree Root

The stack-tree is the contract's single persistent state: a flat folder of markdown nodes starting at this file. The hierarchy is carried by links, never by subfolders. Keep every node (including this one) under ~200 lines; if a node outgrows that, split its stack into a substack.

## Current path (breadcrumb)

- Level 0 (orchestrator): active here — no substack yet

## Session frame

- **Active Role:** orchestrator
- **Stack Depth:** 0
- **Active Mandate:** Main infinity loop orchestration
- **Target Artifact:** N/A

## Tasks (level 0)

- *(none yet — add the first level-0 tasks here)*

## Log

**<YYYY-MM-DD> — <short title>**

<one-line summary; link the node(s) touched>

## Substack routing

- *When a task needs decomposition, create a child node markdown (a sibling file in this folder), link it under Tasks above, and update the Current path.*
EOF

# 4. Wire the project-mcp-tools coupling
if [[ -e "$TARGET/project-mcp-tools" ]]; then
  echo "kept: existing project-mcp-tools entry"
else
  ln -s ../project-mcp-tools "$TARGET/project-mcp-tools"
  echo "linked: project-mcp-tools -> ../project-mcp-tools"
fi
# Convenience symlink for the CLI aliases (run-loop.sh's watchdog default)
if [[ -e "$TARGET/scripts" ]]; then
  echo "kept: existing scripts entry"
else
  ln -s project-mcp-tools/scripts "$TARGET/scripts"
  echo "linked: scripts -> project-mcp-tools/scripts"
fi

TARGET_NAME="$(basename "$TARGET")"
OCODE_JSON="$TARGET/opencode.json"
if [[ -f "$OCODE_JSON" ]]; then
  echo "kept: existing opencode.json"
else
  cat > "$OCODE_JSON" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "mcp": {
    "project-mcp-tools": {
      "type": "local",
      "command": ["uv", "--directory", "../project-mcp-tools", "run", "mcp-server", "--target-project", "../$TARGET_NAME"]
    }
  }
}
EOF
  echo "created: opencode.json (project-mcp-tools MCP registered)"
fi

echo "==> ensuring git repository"
if ! git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$TARGET" init -q
  echo "initialized: git repository"
fi

echo
echo "loop-contract successfully deployed/updated at: $TARGET"
echo "Specification updated; stack-tree control state preserved."
echo "To start the infinity loop, run: ./run-loop.sh"
