# Coding Style

## General Principles

1. **Clarity over cleverness** — write code that others can understand
2. **Minimal changes** — only modify what's necessary for the task
3. **Preserve conventions** — match the existing style in the project

## Naming

- Use descriptive names: `user_count` not `uc`
- Constants: `UPPER_SNAKE_CASE`
- Functions: `lower_snake_case` (Bash/Python) or `camelCase` (JS/TS)
- Files: match the language convention

## Structure

- One function = one responsibility
- Keep functions under 50 lines when possible
- Group related logic together
- Separate configuration from logic

## Comments

- Comment WHY, not WHAT
- Don't comment obvious code
- Use comments for complex logic or non-obvious decisions
- Keep comments up to date

## Error Handling

- Always handle errors explicitly
- Don't silently swallow errors
- Provide meaningful error messages
- Log errors with context

## Bash-Specific

- Always use `set -euo pipefail`
- Quote variables: `"$var"` not `$var`
- Use `[[ ]]` over `[ ]` for conditionals
- Prefer functions over inline scripts
- Use `local` for function variables
