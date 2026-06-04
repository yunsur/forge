# CLAUDE.md

## Core Rule

This project uses the **competition workflow** as the primary engineering process.

Three modes exist:

1. **Competition Mode** — 3-role closed-loop (architect → developer → tester)
2. **Verification Mode** — post-competition security + cross-testing
3. **Fast Track** — skip planning, fix directly

## Competition Mode

### Roles

| Role | Responsibility | Key Tool |
|------|---------------|----------|
| **architect** | Requirements decomposition → Plan → Tasks (anchor document) | `specify plan`, `specify tasks` |
| **scaffold** | Build project skeleton (see `scaffold.md`) | framework CLIs, docker templates |
| **developer** | Implement tasks via TDD, one branch per task | `superpowers:test-driven-development` |
| **tester** | Verify each task immediately | `superpowers:verification-before-completion` |

### Flow

```
architect:  specify constitution → project constitution (optional, for team standards)
            specify plan → plan file (anchor)
            specify clarify → AI asks clarification questions (≤5 questions)
            specify tasks → tasks checklist (each with task-id + P0/P1/P2 priority)
                ↓
plan review: 🔵 user reviews plan and tasks against original requirements
            ├── confirmed → proceed to scaffold
            └── issues found → architect revises, re-present
                ↓
scaffold:   Build project skeleton (see scaffold.md)
            push to main (skeleton should be runnable)
            assign tasks to developer-1/2/3 by dependency
                ↓
parallel:   developers work in parallel (each on own branch feat/task-{id})
            ┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────────┐
            │ developer-1          │ │ developer-2          │ │ developer-3          │
            │ feat/task-1          │ │ feat/task-2          │ │ feat/task-3          │
            │ 1. read task + AC    │ │ 1. read task + AC    │ │ 1. read task + AC    │
            │ 2. write failing test│ │ 2. write failing test│ │ 2. write failing test│
            │ 3. implement (green) │ │ 3. implement (green) │ │ 3. implement (green) │
            │ 4. refactor if needed│ │ 4. refactor if needed│ │ 4. refactor if needed│
            │ 5. mark task complete│ │ 5. mark task complete│ │ 5. mark task complete│
            └──────┬───────────────┘ └──────┬───────────────┘ └──────┬───────────────┘
                   └──────── merge to main ────────┘
                ↓
MVP checkpoint: all P0 tasks complete → core flow demonstrable
            ├── yes → start demo preparation
            └── no → continue P0, P1/P2 based on time
                ↓
tester:     verify each completed task:
              1. scope check (no drift)
              2. functional check (tests pass)
              3. plan alignment (matches intent)
              4. quality check (conventions, edge cases)
                ↓
            proceed to next task / rework if failed
```

### Direct Development

For existing projects with skeleton already in place.

Trigger: user says "直接开发" or "继续开发"

Skips: architect, scaffold

Flow:

```
1. Claude reads tasks.md, shows numbered task list
2. User selects tasks by number (e.g. "4,5,6")
3. Claude outputs detailed design for each task
4. User confirms design (✅), adjusts (❌), or skips
5. Developers pull → checkout branch → implement
6. Run functional tests — must pass before PR
7. Submit PR
```

```
developer:  pull → checkout branch → implement selected tasks → PR
```

Use when:
- Project skeleton already exists
- tasks.md has pending tasks (with #number IDs)
- Bug fixes or small feature additions
- Continuing work from a previous session

### Requirements Decomposition

When the input is a rough/brief competition prompt, architect must first decompose before planning.

Steps:

1. **Extract core objectives** — identify the main goal, user scenarios, and functional boundaries from the prompt
2. **Identify gaps** — list what the prompt doesn't specify but must be decided (data model, auth, scale, etc.)
3. **Ask user to confirm** — present the decomposition as structured questions; user confirms or overrides
4. **Output detailed requirements doc** — becomes the input for `specify plan`

Decomposition template:

| Dimension | Result |
|-----------|--------|
| Core features | ... |
| User roles | ... |
| Tech constraints | ... |
| Open questions | ... (pending user confirmation) |

Skip decomposition when:
- Requirements are already detailed and unambiguous
- User says "直接开发" or "fast track"

### Priority & Scope Control

Every task in `specify tasks` must carry a priority tag:

| Priority | Meaning | Rule |
|----------|---------|------|
| **P0** | Must-have, MVP core | Must complete before competition ends |
| **P1** | Should-have, important | Complete if time permits after P0 |
| **P2** | Nice-to-have, stretch | Only if P0+P1 are done |

When time is running out:

1. Drop P2 tasks immediately
2. Drop P1 tasks if less than 30% time remains
3. Focus all developers on remaining P0 tasks
4. If all P0 done, quick-win P1 tasks can be attempted

architect decides priority during task decomposition. User can override.

### Branching Strategy

One task = one branch. No exceptions.

```
main
 ├── feat/task-1   (developer-1)
 ├── feat/task-2   (developer-2)
 └── feat/task-3   (developer-3)
```

Rules:

- Branch name: `feat/task-{id}` where `{id}` is the task number from tasks checklist
- Developer checks out branch before starting, merges to main after tester verifies
- If two tasks conflict (shared file), architect must reorder or split the task
- Never commit directly to main during active development

Task ID format (from `specify tasks` output):

```
- [ ] #1 [P0] user registration API     → feat/task-1
- [ ] #2 [P0] login authentication      → feat/task-2
- [ ] #3 [P1] task list page            → feat/task-3
```

All roles reference tasks by `#{id}` — developer reads `#1`, tester verifies `#1`, architect reassigns `#1`. ID is the single source of truth across the pipeline.

### MVP Definition

MVP = all P0 tasks completed + core user flow works end-to-end.

MVP checkpoint triggers when:

- All P0 tasks are marked complete and verified by tester
- OR time reaches 70% of competition deadline (whichever comes first)

At MVP checkpoint:

1. **Freeze scope** — no new features, only bug fixes on P0 code
2. **Demo readiness check** — can the core flow be demonstrated?
3. **Decision point**:
   - Core flow works → start demo preparation
   - Core flow broken → all developers fix P0 bugs, drop everything else

### Parallel Scheduling

architect assigns tasks with dependency awareness:

1. **Independent tasks** — assign to different developers simultaneously
2. **Dependent tasks** — chain them: task-B starts only after task-A merges
3. **Conflict avoidance** — no two developers touch the same file in the same phase

Assignment output (architect produces after scaffold):

```
developer-1: task-1, task-4  (independent, parallel)
developer-2: task-2           (independent, parallel)
developer-3: task-3           (blocked by task-2, starts after merge)
```

If a developer finishes early, architect reassigns from the P1 queue.

### Fallback & Recovery

When something goes wrong:

| Situation | Action |
|-----------|--------|
| Task exceeds time limit (2x estimate) | Mark as blocked, skip, move to next P0 task |
| Developer branch has unresolvable conflict | Reassign task to different developer with fresh branch |
| All P0 tasks blocked | User decides: simplify scope or extend deadline |
| Test fails after merge | Revert merge, developer fixes on branch, re-submit |
| 50% time elapsed, no P0 complete | Emergency scope cut: keep only 1 core feature, rebuild focus |

Recovery principle: **never stop the pipeline**. If one task blocks, work around it. The goal is MVP, not perfection.

### Anti-Drift Guarantees

1. **Human validates plan first** — architect produces plan, user reviews against real requirements before any code is written
2. **Plan is the anchor** — developer implements ONLY what the plan lists
3. **Tasks checklist** — `specify tasks` output atomic, verifiable items; nothing outside the list gets done
4. **3-role loop** — architect plans, developer implements, tester verifies; drift is caught immediately

### Triggering

Say "比赛模式" or "competition mode" to activate.

When active:
- Use only architect, developer, tester roles
- Follow the closed-loop flow strictly
- No scope expansion without explicit user approval
- Each task verified before moving to the next

## Verification Mode

Post-competition verification for security and quality assurance.

### Roles

| Role | Responsibility | Focus |
|------|---------------|-------|
| **security** | Security vulnerability testing | Injection, auth, data safety, dependencies |
| **cross-tester** | Black-box cross-testing | Edge cases, integration, regression |

### Flow

```
After competition completes:
  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
  │   security   │   │ cross-tester │   │  auto-test   │
  │  security scan│  │  black-box   │   │  full suite  │
  └──────────────┘   └──────────────┘   └──────────────┘
         │                  │                  │
         └──────── merge ───┴──────────────────┘
                    │
                    ├─ no issues → release
                    └─ issues found → fix → re-test
```

### Triggering

Say "赛后验证" or "verification mode" to activate.

When active:
- Run security testing (dependency audit, vulnerability scan)
- Run cross-testing (black-box, edge cases, integration)
- Run full test suite (unit, integration, coverage)
- All issues must be fixed and re-tested before release

## Fast Track

For small, low-risk changes, skip planning entirely.

Qualifying changes:

- typo or wording fix
- config value adjustment
- single-line bug fix
- rename or formatting change
- adding or removing a simple dependency

How to use:

- The user says "fast track", "quick fix", "直接改", or "快速模式"
- Or the change is obviously trivial (1-3 lines, no logic change)

What is skipped:

- plan
- tasks

What is kept:

- inspect existing code before changing
- make minimal necessary changes
- verify the change works after applying

## Skills

Use skills only when relevant.

Default superpowers skills:

- test-driven-development
- systematic-debugging
- verification-before-completion
- requesting-code-review

If a listed skill is not available, skip it silently and proceed without it. Do not block work because a skill is missing. Apply the skill's intent manually if possible (e.g., if test-driven-development is unavailable, still follow TDD discipline yourself).

## Environment Configuration

All package sources: `~ai/config/env/sources.md`

## Engineering Rules

Before changing code:

1. inspect existing files
2. understand current conventions
3. make minimal necessary changes
4. preserve existing style
5. avoid broad rewrites

Before marking work complete:

1. run relevant tests if available
2. explain what was changed
3. list verification performed
4. list remaining risks if any

## Git Workflow Guardrails

- Work only on `feat/*` or `fix/*` branches.
- Never push directly to `main`; use MR only.
- Commit messages must follow Conventional Commits:
  `type(scope): subject`
- Do not push `WIP` commits to remote.
- Before push, run available checks in this order:
  lint + unit, then integration, then smoke.
- Auto-push/auto-commit is allowed only when all required checks pass and
  `FINAL_APPROVE=1` is set.

## Output Style

Be concise.
Be direct.
Prefer code, commands, diffs, and concrete file paths.
Do not over-explain obvious steps.
