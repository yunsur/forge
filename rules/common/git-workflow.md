# Git Workflow

## Branches

- `main` — production-ready code, never push directly
- `feat/*` — new features
- `fix/*` — bug fixes
- `chore/*` — maintenance tasks

## Commits

Format: `type(scope): subject`

Types:
- `feat` — new feature
- `fix` — bug fix
- `docs` — documentation only
- `style` — formatting, no code change
- `refactor` — restructuring without behavior change
- `test` — adding or updating tests
- `chore` — build, CI, tooling

Examples:
```
feat(auth): add JWT token refresh
fix(api): handle null response from /users
docs(readme): update installation steps
```

Rules:
- Subject line under 72 characters
- Use imperative mood ("add" not "added")
- No period at the end
- Reference issues with `#123`

## Before Push

Run checks in this order:

1. Lint / format check
2. Unit tests
3. Integration tests (if available)

Do not push if any check fails.

## WIP

- Never push WIP commits to remote
- Use `git stash` or local commits for work in progress
- Squash WIP commits before pushing

## Pull Requests

- One feature/fix per PR
- Write descriptive PR description
- Link related issues
- Request review before merging
