# Claude Compatibility Instructions

This file exists for Claude-specific tooling that looks for `CLAUDE.md`.

The canonical project instructions live in [AGENTS.md](AGENTS.md). Use that file as the
source of truth for project rules, documentation requirements, architecture constraints,
and the context-loading order.

If a Claude workflow needs additional role-specific prompts, keep them under
`.claude/agents/`, but avoid duplicating general project policy there.
