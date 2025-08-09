# PipeDream – AI Assistant Guide

**Goal:** Deliver small, robust, and reviewable changes that run on PowerShell 5.1 and 7+.

## Scope
- PowerShell module for the Dataverse Web API.
- Public surface: auth + GET/POST/PATCH/DELETE helpers.
- Tests: unit (mocked) and optional smoke (real env), kept simple.

## Principles
1. **Stable contracts** – Return structured results for success/failure; no throwing for normal API errors.
2. **Cross-version friendly** – Avoid PS-specific quirks; use portable patterns.
3. **Secure by default** – No secret logging; minimal info in traces.
4. **Composability** – Small, focused changes; explicit inputs/outputs.
5. **Agent-friendly** – Clear intent, minimal coupling, predictable behavior.

## Approach
- Write a tiny spec for each change (inputs, outputs, success criteria, error modes).
- Design for failure first (network, API, format issues).
- Keep changes small and self-contained (one topic per PR).
- Add/update a unit test before changing code.

## Testing
- **Unit tests:** mock external calls; verify behavior, not implementation.
- **Smoke tests:** optional; parameterized; never commit secrets.
- Use descriptive, focused test names.

## Documentation
- Base changes on official Microsoft Dataverse docs.
- Link to docs in PRs when behavior isn’t obvious.

## MCP

### Microsoft Docs MCP
- Use to search, fetch, and cite **official Microsoft Dataverse documentation**.
- Always consult when implementing new features, behaviors, or API calls that could be ambiguous.
- Include direct links to the relevant docs in PR descriptions when behavior is non-obvious or follows specific API constraints.

### GitHub MCP
- Use to:
  - Create or update GitHub issues for new tasks or bugs.
  - Comment on PRs or link related issues.
  - Fetch existing issue/PR details when reviewing or continuing work.
