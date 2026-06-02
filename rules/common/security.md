# Security Rules

## Mandatory Checks

Before any code is merged, verify:

1. No secrets in code (API keys, passwords, tokens)
2. All user input is validated and sanitized
3. Authentication is required on protected endpoints
4. Authorization checks are in place
5. Sensitive data is encrypted at rest and in transit

## Input Validation

- Validate ALL external input (user, API, file)
- Use allowlists over denylists
- Validate type, length, range, and format
- Reject invalid input early

## Authentication

- Use established libraries (don't roll your own crypto)
- Store passwords with bcrypt/argon2, never plaintext
- Implement token expiration and refresh
- Use HTTPS everywhere

## Authorization

- Apply principle of least privilege
- Check permissions on every request
- Don't expose internal IDs without authorization
- Validate ownership of resources

## Secrets Management

- Never commit secrets to version control
- Use environment variables or secret managers
- Rotate secrets regularly
- Audit secret access

## Dependencies

- Run `npm audit` / `pip audit` / `cargo audit` before release
- Update vulnerable dependencies
- Pin dependency versions
- Review new dependencies before adding

## Error Handling

- Don't expose internal errors to users
- Log errors with context (not secrets)
- Use generic error messages for auth failures
- Don't leak stack traces in production

## Common Vulnerabilities

Prevent:
- SQL injection (use parameterized queries)
- XSS (escape output, use CSP)
- CSRF (use tokens)
- Path traversal (validate file paths)
- Command injection (avoid shell execution with user input)
