# Hermetic Workflow — Proposed Improvements

## Problems We're Solving

The current workflow designs before it discovers. The Architect writes governance from a prose description, so agents build against assumed schemas, not real ones. Errors compound silently until the Frontend Validator catches them — or doesn't. First-shot quality suffers.

---

## Changes

### 1. Add a Scout Phase (before Architect)

**What:** A constrained pre-flight agent that reads actual source files and produces `workflow/data-contract.md`.

**Why:** For any data-driven app, the Architect cannot design correctly without knowing the real schema. Scout eliminates guesswork before it propagates.

**Scout produces:**
- Real field names and data shapes from sampled source files
- Explicit formulas for any key calculations (costs, token sums, aggregations)
- Gotchas found in the data (nesting, edge cases, missing fields)

**Architect reads this before writing anything.**

Scout only runs when there are data sources to inspect. Static or purely UI projects skip it.

---

### 2. Structured Spec Input (user-side)

**What:** A lightweight prompt template the user fills before running the workflow.

**Why:** Narrative descriptions force the Architect to infer. Structured input gives it contracts.

**Template sections:**
- What it does (one paragraph)
- Data sources (file paths, API endpoints, or sample payload)
- Key views and what each one must show
- Key calculations that must be correct
- What "done" looks like, stated as observable facts

---

### 3. ASCII Wireframes Per Page (Architect output)

**What:** The Architect draws a simple ASCII interface for every screen before any code is written.

**Why:** Removes ambiguity about layout, hierarchy, and what data appears where. The Coder has a visual contract, not just a description. Proven to reduce UI misinterpretation.

**Format:** one block per page, drawn inline in `CLAUDE.md` or a dedicated `workflow/wireframes.md`.

---

### 4. Acceptance Criteria in Every Task

**What:** Each task in `tasks.md` includes a "Done when:" line with observable, checkable conditions.

**Why:** Currently the Reviewer only checks compilation and tests. It cannot verify business correctness without explicit criteria. Wrong token calculations can pass a green test suite.

**Example:**
```
- [ ] Session detail view
  Done when: sub-agents appear as nested entries, each message shows token cost, tool calls are listed per message
```

---

### 5. Early Smoke Validation After First UI Task

**What:** Frontend Validator runs once after the first UI-producing task, not only at the end.

**Why:** Structural rendering failures (React hydration, missing CSS, broken routing) discovered late mean subsequent tasks are built on broken foundations. An early check catches these while the surface area is still small.

---

### 6. Redefine the Reviewer's Job

**What:** The Reviewer stops re-running tests and becomes a **git diff integrity auditor**.

**Why:** Confirming tests pass is redundant — the Coder wouldn't commit if they didn't. The only thing the Reviewer can catch that the Coder can't self-report is cheating.

**What the Reviewer actually checks:**
- Did the Coder modify any test files?
- If yes, do those changes look like weakening — removed assertions, loosened expectations, skipped tests, hardcoded values to force a pass?

The Reviewer reads the diff between the Test Maker's commit and the Coder's commit and makes a judgment call: legitimate fix or gaming the tests. This is a task LLMs are actually good at — reading a diff and inferring intent.

This makes the Reviewer non-redundant and meaningfully independent.

---

## What Stays the Same

The core loop (Planner → Test Maker → Coder → Reviewer) is solid. The sentinel pattern, retry logic, hooks, and state file communication are not touched. These changes are additive: one new agent, one new template, two new output conventions.

---

## Updated Flow (abbreviated)

```
User fills spec template
  └─ Scout (if data sources exist) → data-contract.md
      └─ Architect → CLAUDE.md + wireframes.md + tasks.md (with acceptance criteria)
          └─ Task loop (unchanged, but Reviewer checks acceptance criteria)
              └─ Smoke validation after first UI task
                  └─ Full frontend validation at end (existing)
```