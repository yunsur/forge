# CLAUDE.md

## Core Rule

This project uses the **competition workflow** as the primary engineering process.

Three modes exist:

1. **Competition Mode** — 3-role closed-loop (architect → developer → tester)
2. **Verification Mode** — post-competition security + cross-testing
3. **Fast Track** — skip planning, fix directly

## Competition Mode (比赛工作流)

### Roles

| Role | Responsibility | Key Tool |
|------|---------------|----------|
| **architect** | Plan → Tasks (anchor document) | `speckit plan`, `speckit tasks` |
| **scaffold** | Build project skeleton (frameworks, shared code) | framework CLIs, shared types |
| **developer** | Implement tasks via TDD | `superpowers:test-driven-development` |
| **tester** | Verify each task immediately | `superpowers:verification-before-completion` |

### Flow

```
architect:  speckit plan → plan file (anchor)
            speckit tasks → tasks checklist
                ↓
plan review: 🔵 用户对照原始需求逐项确认 plan 和 tasks
            ├── 确认 → 进入 scaffold
            └── 纠错 → architect 修正后重新确认
                ↓
scaffold:   后端框架初始化 + 前端框架初始化 + shared 代码
            push to main（骨架可运行）
            分配任务给 developer-1/2/3
                ↓
developer:  for each task:
              1. read task + acceptance criteria
              2. write failing test (TDD red)
              3. implement minimal code (TDD green)
              4. refactor if needed
              5. mark task complete
                ↓
tester:     verify each completed task:
              1. scope check (no drift)
              2. functional check (tests pass)
              3. plan alignment (matches intent)
              4. quality check (conventions, edge cases)
                ↓
            proceed to next task / rework if failed
```

### Direct Development (直接开发)

For existing projects with skeleton already in place.

Trigger: user says "直接开发" or "继续开发"

Skips: architect, scaffold

Flow:

```
1. Claude reads tasks.md, shows numbered task list
2. User selects tasks by number (e.g. "4,5,6")
3. Claude outputs detailed design for each task
4. User confirms design (✅), adjusts (❌), or skips (跳过)
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

### Anti-Drift Guarantees

1. **Human validates plan first** — architect produces plan, user reviews against real requirements before any code is written
2. **Plan is the anchor** — developer implements ONLY what the plan lists
3. **Tasks checklist** — speckit tasks output atomic, verifiable items; nothing outside the list gets done
4. **3-role loop** — architect plans, developer implements, tester verifies; drift is caught immediately

### Triggering

Say "比赛模式" or "competition mode" to activate.

When active:
- Use only architect, developer, tester roles
- Follow the closed-loop flow strictly
- No scope expansion without explicit user approval
- Each task verified before moving to the next

## Verification Mode (赛后验证)

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
  │  安全扫描     │   │  黑盒测试     │   │  全量测试     │
  └──────────────┘   └──────────────┘   └──────────────┘
         │                  │                  │
         └──────── 汇总 ────┴──────────────────┘
                    │
                    ├─ 无问题 → 发布
                    └─ 有问题 → 修复 → 重测
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
