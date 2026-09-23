# AGENTS.md

## Guidelines for AI coding agents working in this repo.
- Follow existing patterns for routes, events, and module structure.
- Avoid introducing new architectural patterns unless explicitly requested.
- Use clear, descriptive names for variables, functions, and events.
- Add comments to explain non-obvious code, but avoid over-commenting.
- Give me suggestion for a prompt of what to work/implement/polish on next.

## Git workflow

- After completing requested code changes, run the required tests and static checks.
- If validation passes, stage only the files changed for the current request.
- Commit those changes with a detailed commit message explaining what changed and why - make it useful for future reference.
- Do not push the current branch directly to its matching `origin` branch using regular Git unless asked.
- Do not use GitHub CLI, create pull requests, or create a new branch unless explicitly requested.
- Do not include unrelated pre-existing working-tree changes in the commit.
- Do not commit or push if validation fails; report the failure instead.
- If the user explicitly says not to commit or push, follow that instruction.
