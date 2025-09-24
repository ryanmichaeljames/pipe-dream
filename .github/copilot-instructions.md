# PipeDream – AI Assistant Guide

# Goal
- Deliver small, robust, and reviewable changes that run on PowerShell 5.1 and 7+.

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

## README
- Keep `README.md` simple and easy to read.
- Document the public functions and their usage.

## MCP

### Microsoft Docs MCP
- Use to search, fetch, and cite official Microsoft Dataverse documentation.
- Always consult when implementing new features, behaviors, or API calls that could be ambiguous
