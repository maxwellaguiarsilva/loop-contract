# loop.md — Multi-Session Work Contract

Single file governing the infinity loop: a fresh opencode session per iteration, one responsibility each, clean handoffs. Read it fully at session start; it is the only routing doc you need.

## Loop mindset

- One small task per session; there is no rush. A single chat session is never a deadline.
- If the context is polluted or the task grew, do not fail: write a small next task into the stack-tree, hand off, and end cleanly.
- Always split a problem into smaller problems. Never avoid a problem because it would deepen the resolution tree — depth is absorbed across sessions, never a reason to defer. All tasks always require decomposition, division, and conquest, without exception. whether it's analysis, planning, diagnosis, or anything else, break everything down as small as possible to make it easy.
- Creating tools (MCP, scripts, symlinks) is encouraged when it compounds progress.
- Violating a principle is not yet a failure; the discipline is cleaning up and handing off.

## Stack-tree

The stack-tree is the contract's single data structure and its only persistent state. Divide and conquer is **mandatory** and is executed through it.

- **Structure** — the tree is a single flat folder of markdown files: `docs/agent/stack-tree/index.md` is the root; every other node is one more markdown in the same folder. The hierarchy is purely logical, carried by links between the markdowns — never by subfolders. `depth` is a field in the node, not a path. There are no control registers beyond the tree. **Node file names are semantic and `lower-kebab-case`** (e.g. `slope-collision.md`, never codes or numbers like `0001.md`).
- **Levels & substacks** — each node holds a stack of tasks at its level. A task that needs decomposition gains a substack: a child node (a sibling markdown, linked from the parent) one level deeper. Descending into a child is a **push**; finishing a substack and returning to the parent is a **pop**. `depth` is the node's level in the tree — the divide-and-conquer metric. **A node must stay under ~200 lines; if it outgrows that, split its stack into a substack instead of growing the file.**
- **Compliance audit** — the loop runner audits every markdown under `docs/agent` (with `find -L`, following symlinks) before each session: nodes must stay under ~200 lines and `index.md` under ~150. On a violation it writes a `prompt.md` ordering the next session to reorganize the stack-tree so compliance is restored without losing any information — increasing the tree's logical depth by splitting oversized nodes into child substacks and moving overflow tasks down.
- **Active path** — exactly one node is active at a time. `docs/agent/stack-tree/index.md` keeps the current path (breadcrumb); the active node's markdown holds the session frame: Active Role, Stack Depth, Mandate, Target Artifact. A session reads only the nodes on the current path, never the whole tree. If `index.md` grows beyond 150 lines, it is time to clean it up, so schedule it for the next session.
- **One tree, all state** — the session frame, pending work, and debt are all just tasks in the tree: the active node holds the frame, pending nodes are the backlog, debt entries are tasks to fix later.
- **Empty backlog = delta analysis, run as its own substack.** When the to-do list is empty, the next task is to close the delta between the executed work and the intended final product described in the project docs and compliance rules. This is a first-class investigation, not a single-session chore: push a child node with a mapping/diagnosis mandate, work through it across sessions via the normal push/execute/pop flow, and pop it only when it resolves into concrete backlog tasks written to the tree. No code is edited and no commit is made in the analysis itself; work only starts once its resulting tasks reach `done`.
- **Commit gate** — a session commits only when it has moved a stack-tree node from pending to done. Every commit must reference the node it closes and stay small and focused (see Compliance). Do not commit from a session that holds no mandate or only produced analysis.
- **Use the contract, not the harness TODO** — planning, tracking, and handoffs are expressed only through the stack-tree. Do not use the TODO tools provided by the harness/`opencode`; they diverge from the tree and break the contract's single source of state.
- **Hard reset**: If you notice from the log in `index.md` that the model is performing several `idle reverify` or any type of `idle session` repeatedly and unproductively (more than 2x) and cannot find a new productive quality task, perform the following procedure.
    - Completely remove the stack-tree folder. `rm -rf docs/agent/stack-tree`.
    - Remove any file that exists with the intention of being something like `docs/agent/status.md`.
    - Move `docs/agent/requeriments.md` to the project root as `prompt.md` ( `mv "docs/agent/requeriments.md" prompt.md` )
    - Run the `git-reset-repository` command in the terminal.
    - Run the blind handoff without registering anything, let the model deal with the `prompt.md` in the next session.

## Session start (every iteration)

1. If `prompt.md` exists at the project root, this session is dedicated to intake — read it and run the procedure it indicates (a user request → "User prompt intake"; a contract-recovery prompt written by the loop runner → "Disaster recovery"), and nothing else.
2. Read `docs/agent/stack-tree/index.md` — the root; follow the current path to the active node and read its frame (Role, Depth, Mandate, Target Artifact).
3. Read this `loop.md` (attached by the loop runner).
4. As orchestrator with no active mandate: pick ONE pending task from the root or the active node.
5. Read project docs scoped, on demand only.
6. Update the tree — mark done, prune, or write the next task — before ending.

## User prompt intake

When `prompt.md` holds a **user request** (a new instruction from the user, not a contract-recovery prompt written by the loop runner), this dedicated session does only this:

1. **Enhance** — restate the request sharply: goal, scope, constraints, acceptance criteria. Resolve ambiguities before committing it to the tree.
2. **Internalize** — write the request into the stack-tree: add its tasks to `docs/agent/stack-tree/index.md`, decomposing into substack nodes as the request demands (divide and conquer).
3. **Remove** — delete `prompt.md`.

Once `prompt.md` is gone, the loop resumes the normal flow below.

## Disaster recovery (session overflow)

When `prompt.md` holds a **disaster-recovery prompt** written by the loop runner (its header says "Disaster recovery"), a previous session exhausted the 100k budget and was killed mid-flight by the loop runner (`run-loop`). This is a contract failure: the session tried to solve everything greedily instead of dividing and conquering through the stack-tree. Before you start, the runner ran a **disaster-recovery pipeline** over the raw overflow export (a separate file, `disaster-transcript.md`, held by the `TRANSCRIPT` variable in `run-loop`): one `opencode run` session summarized every task the failed session attempted, a second decomposed that work into small per-session tasks, the runner wrote the assembled summary+plan into `prompt.md`, deleted the pipeline's temporary files and the raw transcript, and ran `git-reset-repository` (commits the current state, resets the git history and re-pushes). So by the time you read it, the file is a small, already-decomposed handoff — not a ~100k transcript. This session has **one** objective:

1. Read `prompt.md` — the processed summary and decomposition plan of the overflowed session (see above).
2. Analyze it and register every task from the decomposition plan into the stack-tree: the smaller decomposition steps, the delegated responsibilities, the substack pushes that were skipped. The pipeline already did the divide-and-conquer thinking for you — do not second-guess it by diving back into the original problem; deepen the tree where the plan is still coarse.
3. Write those tasks into the stack-tree — internalize every pending concern as proper nodes/substacks so the work can continue across normal sessions. Do not try to redo the work in this session. If the problem is very complex, even the divide-and-conquer registration task itself may need to span multiple sessions. It all depends on the size of the problem that occurred in the session that violated this contract.
4. After a disaster recovery, your stack-tree must have gained at least one additional depth, with smaller tasks within it.
5. Delete `prompt.md` (remove the signal; it is a transient marker, not persistent state).
6. Hand off cleanly. The next session resumes the normal flow.

> The failure mode is greediness, so the cure is decomposition, not compensation. Register the tasks; never attempt to recover the work inline.

## Roles

| Role | Scope |
| --- | --- |
| orchestrator | Strategy, backlog, sequencing. Default. Delegates large or isolated work. |
| loop-explore | Read-only mapping/investigation. Never edits code. |
| loop-worker | Scoped implementation/diagnosis within a strict mandate. |

## Pipeline

Run the phase that matches the mandate; a session runs only the phases in scope and hands the rest off.

| Phase | Goal | Output |
| --- | --- | --- |
| Mapping | Map the area without changing it | Summary / mapping note |
| Diagnosis | Root cause of a bug/violation | Report with file:line |
| Analysis | Decide how to solve | Written decision |
| Implementation | Ship a scoped change | Code + tests + docs |
| Verification | Prove it works and complies | Pass/fail + evidence |
| Handoff | Leave a clean state | stack-tree updated |

## Delegation (push/pop)

A task that spans > 3 steps or multiple files, or that the session cannot finish inside budget, MUST be decomposed into a substack — this is the mandatory divide-and-conquer, executed through the stack-tree, never with in-session background agents:

1. **Push** — create a child node linked from the current node; set its frame (role, depth+1, mandate, target artifact); update the root's current path. End the session.
2. **Execute** — the child session follows the path, assumes the role, works strictly in scope, writes to the target artifact.
3. **Pop** — mark the child's work done, update the parent node, restore the parent frame, shorten the path. End the session.
4. **Resume** — the next session follows the path to the resumed frame and continues.

## Context hygiene

- Attach only what the task needs, on demand: check sizes (`du -hd1`), search with `git ls-files`/grep, read scoped regions (see global AGENTS.md). In the stack-tree, load only the current path.
- **Budget:** hard cap 100k tokens, wrap up at 70k. Measure with the `session_context_usage` tool (project-mcp-tools); never guess. At 70k finish the in-flight unit, record status in the tree, hand off. At 100k stop and hand off. The loop runner (`run-loop`) enforces the 100k cap from outside: it watches usage and, on overflow, kills the session, exports its transcript, and — through the disaster-recovery pipeline — writes a disaster-recovery prompt into `prompt.md`, triggering "Disaster recovery" on the next iteration.
- When the nodes on your path reach ~20k tokens, run a dedicated cleanup session: condense each node to one line, close resolved tasks, prune completed substacks.

## Compliance

Follow standard practice: DRY single source of truth, layered one-way dependencies, DI with no global state, fail fast without silent fallback, config externalization, consistent naming, no dead code, no secrets, small focused commits, docs ship with code.

Numbered rule IDs (R1.1, ...) may be referenced from stack-tree task nodes; see `docs/agent/compliance-rules.md` only when a numbered reference is needed.
