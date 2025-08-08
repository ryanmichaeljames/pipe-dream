# PipeDream – AI assistant guide (high level)

Goal: small, robust, and reviewable changes that work on PowerShell 5.1 and 7+.

## Scope
- PowerShell module for Dataverse Web API
- Public surface: auth + GET/POST/PATCH/DELETE helpers
- Tests: unit (mocked) and optional smoke (real env), kept simple

## Principles
- Stable contracts: return structured results for success/failure; avoid throwing for routine API errors
- Cross-version friendly: avoid runtime/type assumptions; favor simple, portable patterns
- Security by default: no secret logging; minimal necessary information in traces
- Composability: small, focused changes; explicit inputs/outputs
- Agent-friendly: clear intent, minimal coupling, predictable behavior

## Approach
- Start with a tiny spec: inputs, outputs, success criteria, and error modes
- Design for failure first (network, API, content/format issues)
- Keep diffs small and self-contained; one topic per change
- Add/update a unit test with mocks before changing code

## Testing philosophy
- Unit tests mock external calls; verify behavior not implementation
- Smoke tests are parameterized and optional; never include secrets in code or logs
- Keep test names descriptive and focused

## Documentation via Microsoft Docs MCP
- Ground changes in official docs
- Use the MCP to search, fetch, and cite relevant Dataverse documentation
- Include links in PRs where behavior is non-obvious

## GitHub MCP
- Use the GitHub MCP to log issues if needed. Ask before using it.

## PR checklist (lightweight)
- [ ] Purpose and scope stated in the PR description
- [ ] Public behavior documented (help/README as needed)
- [ ] Backwards compatibility considered or migration noted
- [ ] Unit tests added/updated; CI green
- [ ] No secrets committed or logged
- [ ] Relevant Microsoft Docs links included

Keep it high level: patterns and intent here; add implementation details and examples in follow-up docs when needed.
