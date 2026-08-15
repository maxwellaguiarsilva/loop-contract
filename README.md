# loop-contract

A generic, self-contained **multi-session work contract** for `opencode`. It turns a project into an infinity-loop of isolated chat sessions: one responsibility per session, a single **stack-tree** that routes every task through push/pop delegation, strict context hygiene, and a shared pipeline that lets every session hand off cleanly to the next. The whole contract is **one file**, `loop.md`.

The contract is **model-agnostic** — it does not assume any specific LLM. The operating budget is a fixed, conservative envelope chosen to fit the models used — its single, adjustable source of truth is the **Context hygiene** section in `loop.md` — and session usage is measured with a real tool (`session_context_usage`), never guessed from the transcript.

It is also **portable** — no placeholders, no project-specific names, no assumptions about language, framework, or tooling. Copy it into any project and it works. The one coupled dependency is **`project-mcp-tools`**, which provides the `session_context_usage` tool; `deploy.sh` wires that coupling automatically (see below).

## What's inside

```
loop-contract/
├── loop.md                             # The entire contract (single entry point)
├── run-loop.sh                         # Generic runner script for the infinity loop
├── deploy.sh                           # Deployment & update script (SPEC + CONTROL, see below)
├── opencode.json                       # MCP config registering project-mcp-tools (coupled)
├── project-mcp-tools -> ../project-mcp-tools   # symlink to the coupled tool repo
└── docs/agent/
    └── compliance-rules.md             # Non-negotiable generic rules (R1–R5, numbered)
```

> The **stack-tree** — `docs/agent/stack-tree/index.md` (root) plus the node markdowns created by sessions — is **not shipped in this repo**. It is per-project state, bootstrapped once by `deploy.sh` inside the target project and owned by it from then on.

## How it works

To start the infinity loop, execute:

```bash
./run-loop.sh [model]
```

Each fresh session in the loop:

1. **Intake check** — if `prompt.md` exists at the project root, the session is dedicated to internalizing the user's request: it enhances the request, writes its tasks into the stack-tree (decomposing into substacks as needed), and removes `prompt.md`.
2. Reads `docs/agent/stack-tree/index.md` — the root — and follows the **current path** to the active node's frame (Active Role, Stack Depth, Mandate, Target Artifact). Only the nodes on the current path are loaded, never the whole tree.
3. Reads the compliance rules and the project docs scoped to the task, on demand.
4. Executes the active mandate (or picks **one** pending task from the tree if running as `orchestrator`).
5. Runs the pipeline phases for that item (mapping → diagnosis → analysis → implementation → verification).
6. Updates the stack-tree (mark done, prune, or write the next task) and hands off cleanly to the next loop iteration.

Large or isolated work is delegated by **push** onto the stack-tree: a child node one level deeper is created and linked from the current node, and the child session executes it as a visible top-level loop session. Completing the substack **pops** back to the parent. This is the mandatory divide-and-conquer mechanism — `depth` is the node's level in the tree.

## Coupled dependency: project-mcp-tools

The contract is coupled to **`project-mcp-tools`** (a sibling repo at `../project-mcp-tools` relative to the project root) for one tool: **`session_context_usage`**, which reads the current opencode session's real token usage (`context_used`, `context_percent`, model limit) straight from the opencode database.

- The budget rules (Context hygiene in `loop.md`) call this tool for usage measurement.
- `run-loop.sh` also uses it as an external watchdog: each session runs in the background while the runner polls token usage; on crossing the 100k cap it kills the session and exports its transcript to `loop-violation.md`, so the next iteration enters **disaster recovery** (see `loop.md`) and registers the unfinished work as stack-tree tasks instead of losing it.
- `opencode.json` in the project root registers it as a local MCP server. `deploy.sh` creates both the symlink and this config automatically.
- This coupling is the **only** non-generic part of the contract. Everything else is portable.

## Install into another project

Use the bundled helper script, which wires `project-mcp-tools` and copies/updates all contract files safely:

```bash
./deploy.sh /path/to/your/project
```

`deploy.sh` treats the deployed files as two distinct classes:

- **SPEC files** (the contract itself): `loop.md`, `run-loop.sh`, `docs/agent/compliance-rules.md`. These are **always overwritten** on every deploy, and stale spec files from older contract versions are removed. Refine the contract in this repo, then re-run `./deploy.sh <project>` to propagate the updated specification.
- **CONTROL files** (the stack-tree): `docs/agent/stack-tree/index.md` is bootstrapped **once** on the first deploy from a template embedded in `deploy.sh`, and **never modified afterwards**. Node markdowns are created by the sessions themselves. Re-deploying updates the specification without ever losing the project's accumulated task state.

### Prerequisites in the target project

- The project has a `README.md` (the contract's entry rules reference it for run commands).
- The project is a git repo.
- **`project-mcp-tools` exists as a sibling (`../project-mcp-tools`) and `uv` is installed** — required for the `session_context_usage` tool. `deploy.sh` fails if it is missing.

### Post-install checklist

1. Confirm `loop.md`, `run-loop.sh`, and `docs/agent/` are at the project root.
2. Open the bootstrapped `docs/agent/stack-tree/index.md` and add the first level-0 tasks, or leave the root as an empty register.
3. If the project needs domain-specific compliance rules, add them as new categories/sub-rules in `compliance-rules.md` (R6+, R1.x) — never remove the generic ones. Note these per-project edits live in the deployed copy; a re-deploy overwrites `compliance-rules.md` with the latest generic rules.
4. Start the loop: `./run-loop.sh`
