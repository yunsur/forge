---
name: security-review
description: Comprehensive security review for code changes
license: MIT
compatibility:
  claude: ">=1.0.0"
  codex: ">=1.0.0"
---

# Security Review

Perform a comprehensive security review of code changes.

## When to Use

- Before merging a pull request
- After implementing authentication/authorization features
- When handling sensitive data (PII, credentials, tokens)
- Before production deployment

## Review Checklist

### 1. Secrets & Credentials

Check for:

- Hardcoded passwords, API keys, tokens
- Secrets in version control
- Credentials in logs or error messages
- Missing `.gitignore` entries for sensitive files

```
Grep for: password, api_key, secret, token, AWS_, PRIVATE KEY
```

### 2. Input Validation

Check for:

- Unvalidated user input
- Missing sanitization
- SQL injection vectors (string concatenation in queries)
- XSS vectors (unescaped output)
- Command injection (shell execution with user input)
- Path traversal (user-controlled file paths)

### 3. Authentication & Authorization

Check for:

- Missing auth checks on protected endpoints
- Weak password requirements
- Insecure session management
- Missing rate limiting on auth endpoints
- JWT issues (weak algorithms, no expiration)

### 4. Data Protection

Check for:

- Sensitive data in logs
- Unencrypted storage
- Missing HTTPS enforcement
- CORS misconfigurations
- Insecure cookie settings

### 5. Dependencies

Check for:

- Known vulnerabilities (`npm audit`, `pip audit`, `cargo audit`)
- Outdated dependencies
- Unnecessary dependencies
- Supply chain risks

### 6. Error Handling

Check for:

- Stack traces exposed to users
- Verbose error messages leaking internals
- Missing error logging
- Silent failure modes

## Severity Levels

| Level | Description | Action |
|-------|-------------|--------|
| **Critical** | Immediate exploitation risk | Block merge, fix now |
| **High** | Exploitable with effort | Fix before release |
| **Medium** | Requires specific conditions | Fix soon |
| **Low** | Defense-in-depth improvement | Track for later |

## Output Format

```markdown
## Security Review

### Findings

| # | Severity | Category | File | Description |
|---|----------|----------|------|-------------|
| 1 | High | Input Validation | api/users.ts:42 | SQL injection via string concat |

### Critical Issues
- [list any critical findings]

### Recommendations
- [list improvements]

### Verdict
- [APPROVED / CHANGES_REQUESTED / BLOCKED]
```

## Rules

- Be specific: show the exact line and vulnerability
- Provide fix suggestions, not just warnings
- Don't auto-fix security issues (report them)
- Flag issues even if they were "out of scope"
- Critical/High findings block the merge
