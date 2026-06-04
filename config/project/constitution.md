# Constitution

比赛开始后填写。

## Tech Stack

### Frontend

- Framework: React
- Language: TypeScript
- Build Tool: Vite
- Package Manager: pnpm
- UI Library: Ant Design

### Backend

- Framework: FastAPI
- Language: Python
- Database: PostgreSQL
- Cache: Redis
- Package Manager: pip

### Infrastructure

- Deployment: Linux
- CI/CD:
- Monitoring:

### Dev Tools

- Test Framework: pytest (backend) / Vitest (frontend)
- Linter: ESLint (frontend) + Ruff (backend)
- Formatter: Prettier (frontend) + Ruff (backend)

### Constraints

- Node Version: v24.16.0
- Python Version: 3.11.6

## Architecture Rules

- Strictly follow RESTful API design conventions
- No business logic in Controller layer
- All database operations must go through Repository layer
- Separate concerns: Controller → Service → Repository

## Quality Standards

- Unit test coverage ≥ 80%
- All APIs must have error handling
- No hardcoded secrets or credentials
- Follow SOLID principles

## Coding Conventions

- Use meaningful variable and function names
- Keep functions small and focused
- Write comments for complex logic
- Follow language-specific style guides (PEP 8 for Python, ESLint for TypeScript)
