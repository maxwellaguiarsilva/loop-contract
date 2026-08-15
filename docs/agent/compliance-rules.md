# Non-Negotiable Rules — Compliance Audit

This document defines the absolute, non-negotiable generic rules of the project. Every line of code, every asset, every configuration file, and every architectural decision must comply with these rules. Violation of any rule is a blocking defect.

These rules are intentionally **generic** — they apply to any project regardless of language, framework, or domain. If the project needs specific rules (domain constants, tech stack conventions, naming schemes), add them as new categories (R7+) or sub-rules (R1.4, R2.3, ...) using the numbering convention below. Do not remove or relax the generic rules.

---

## Rule Numbering Convention

Rules use a hierarchical numbering scheme: **R1, R2, R3** identify categories/types of rules, and **R1.1, R1.2, R1.3** identify individual rules within each category.

When a new rule is added to an existing category, it receives a new sub-number (e.g., R1.5). When a rule is removed, its sub-number is retired — remaining rules keep their sub-numbers. No renumbering is ever needed. When a new category is added, it receives the next available major number (e.g., R7).

References to rules should use the full hierarchical identifier (e.g., `R1.3`, `R5.2`) for precision. References to a whole category (e.g., `R2`) are acceptable when referring to all rules in that category.

---

## R1 — Architecture & Code Quality

### R1.1 — Single Source of Truth (DRY)
> `#drs`

**Every reusable concept must exist exactly once in the codebase.** No duplicated logic, no copy-pasted blocks, no two places defining the same value or behavior independently.

- Shared logic lives in a shared module/function/class referenced by all consumers.
- Shared constants, identifiers, and named references live in one canonical definition.
- When two implementations of the same concept diverge, consolidate them into one.

**Audit check:** Search for repeated literal blocks, near-identical functions, and values defined in more than one file. Each concept must resolve to exactly one definition.

---

### R1.2 — Layered / Component Architecture
> `#layers`

**The codebase must be organized into clear layers with explicit boundaries and one-way dependencies.** Generic/reusable infrastructure must not depend on domain-specific code.

- Generic layers (infrastructure, framework wrappers, platform primitives) stay domain-agnostic.
- Domain layers depend on generic layers, never the reverse.
- Each module has a single responsibility; dependencies are explicit, not transitive through globals.
- Any developer should be able to understand a layer without reading the whole codebase.

**Audit check:** Draw the dependency graph of modules. Any edge from a generic layer to a domain-specific one is a violation. Any module doing two unrelated jobs is a violation.

---

### R1.3 — No Globals, Mandatory Dependency Injection
> `#no-globals`

**No global variables or global mutable state outside what is natively provided by the language/platform runtime.**

- **Allowed:** runtime primitives (`window`, `document`, `process`, standard library).
- **Forbidden:** custom global variables, global singletons, global registries, module-level mutable state acting as implicit shared state.
- All dependencies must be **explicitly injected** into functions, classes, and modules.
- A dependency injection container or manual wiring at the composition root (entry point) is acceptable — global mutable state is not.

**Audit check:**
1. Search for assignments to runtime globals (e.g., `window.`, `process.`) beyond standard API usage. Any custom property is a violation.
2. Search for module-level `let`/`var` declarations that are mutated. If they represent shared state, it is a violation.
3. Verify every module receives its dependencies via parameters, not by importing a global singleton.

---

### R1.4 — Fail Fast, No Silent Fallback
> `#no-fallback`

**When requested data or a dependency is missing or invalid, throw a descriptive error — never silently fall back to a default, empty value, or null.**

- Data/config access must validate the requested key exists before returning.
- Missing keys throw errors naming the missing key and its source.
- No implicit fallback chains, no silent coercion of missing values to falsy sentinels.
- Validate inputs at boundaries; surface errors during development rather than as subtle runtime misbehavior.

**Audit check:** Search for `??`, `||`, `||=`, `??=`, ternary fallbacks, or silent `null`/`undefined` returns in data-access and config-reading code. Any such pattern is a violation unless the fallback is a deliberate, explicit business rule.

---

## R2 — Configuration & Externalization

### R2.1 — No Hardcoded Literals in Generic Code
> `#no-literals`

**Values that vary per deployment or per domain must not be hardcoded in implementation code.** They live in configuration (files, env vars, or injected config objects).

This includes but is not limited to: domain-specific strings, colors/styles, numeric tunables (speeds, sizes, durations, limits), positions, identifiers, feature flags, and environment-specific paths.

**Audit check:** For every tunable or domain literal, trace it back to a config source. If it originates in implementation code, it is a violation.

---

### R2.2 — Single Source of Truth with Named References
> `#single-source-truth`

**Every shared configurable concept has exactly one canonical definition, and all consumers reference it by name — never by copying the raw value.**

- No two config files independently define the same value.
- Consumers reference a concept by a named key from its canonical config, not by the raw numeric/string value.
- Changing a value in one place must propagate everywhere automatically.

**Audit check:** For each named concept, verify exactly one canonical definition exists and all references use its name. Two independent definitions of the same value is a violation.

---

## R3 — Naming & Formatting Conventions

### R3.1 — Consistent Identifier Conventions
> `#naming`

**Naming must follow the conventions established in the project docs (or, absent that, the ecosystem's dominant convention) consistently.**

- JSON/data keys and file names use `lower-kebab-case` unless the project docs state otherwise.
- Code identifiers follow the language/framework convention; no mixing of styles within a module.
- No uppercase letters, underscores, or spaces where the convention forbids them.

**Audit check:** Scan config keys, file names, and code identifiers against the documented convention. Any deviation is a violation.

---

## R4 — Repository Hygiene

### R4.1 — No Secrets or Sensitive Data in Repository
> `#no-secrets`

**The repository must be clean enough to be made public at any time.**

- No API keys, tokens, passwords, or credentials.
- No personal information.
- No build artifacts, `node_modules`, or generated files.
- `.gitignore` must be comprehensive and verified.

**Audit check:** Review `.gitignore` coverage. Run `git ls-files` and inspect every tracked file for sensitive content. Imagine the repo going public in 5 minutes — would anything need to be scrubbed?

---

### R4.2 — No Dead Code
> `#no-dead-code`

**Every exported module, function, class, and asset must have a consumer or a documented reason to exist.**

- No unused exports, no orphaned files, no commented-out code blocks.
- Removing a feature removes its code and its documentation references.
- A module kept for future use is documented as such in a backlog/tech-debt register.

**Audit check:** Grep for exports with zero importers, orphaned files, and commented-out blocks. Each is a violation.

---

### R4.3 — Clean Git History Hygiene
> `#git-hygiene`

**Commits are small, focused, and self-describing.** Commit messages state what and why. Large unrelated changes are split into separate commits. No secrets ever enter the history.

---

## R5 — Documentation & Process

### R5.1 — Documentation Is Part of the Work
> `#docs-required`

**Every change that alters architecture, data shapes, config, or process must update the relevant docs in the same session.** Documentation is not a separate task — it ships with the code.

- The stack-tree (`stack-tree/index.md` and its nodes) records what was done in each session.
- Debt entries and pending work are registered as tasks in the stack-tree.

**Audit check:** A session that changed behavior but left the stack-tree unchanged is a violation of this rule.

---

## Audit Procedure

1. Run `git ls-files` to list all tracked files.
2. **R1.1 (DRY):** search for duplicated logic and values across the codebase. Every concept must resolve to one definition.
3. **R1.2 (Layers):** inspect the module dependency graph; generic modules must not import domain modules.
4. **R1.3 (No globals):** search for custom runtime-global assignments and module-level mutable state. Verify explicit DI.
5. **R1.4 (Fail fast):** search data/config access for silent fallback patterns (`??`, `||`, ternary). Verify missing data throws descriptive errors.
6. **R2.1 (No literals):** grep generic code for hardcoded tunables and domain literals; each must trace to config.
7. **R2.2 (Named references):** verify each shared concept has exactly one canonical definition referenced by name.
8. **R3.1 (Naming):** verify config keys and file names match the documented convention.
9. **R4.1 (Secrets):** scan `.gitignore` and all tracked files for sensitive content.
10. **R4.2 (Dead code):** grep for unused exports, orphaned files, commented-out blocks.
11. **R5.1 (Docs):** verify the session's changes updated the stack-tree as needed.
