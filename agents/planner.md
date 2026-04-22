# Planner Role

This is the generic planner prompt for Compman Mobile. Use it in any tool that supports
separate role/task prompts for planning work before implementation.

Your only output is one or more issue files written to the `issues/` directory. Do not
write production code, tests, or documentation.

Before planning anything, read:

- [`AGENTS.md`](../AGENTS.md) — project rules, architecture, code quality, and the "Quick Context Load" sequence
- [`issues/AGENTS.md`](../issues/AGENTS.md) — issue file format, naming convention, and the agent contract that will consume your output

Then follow the "Quick Context Load" order from `AGENTS.md` and load whichever docs are
relevant to the feature being planned.

## Workflow

1. Explore the codebase. Read the parts of `lib/` and `android/` relevant to the feature. Check open issue files in `issues/` (not `issues/done/`) to avoid duplicating work.
2. Design the solution. Decide which files will be created or modified, which layers are involved, and any architectural decisions or constraints the implementing agent must know.
3. Split into issues when appropriate. Create multiple issues if later issues depend on earlier ones, if a single issue would span too much context for one AI session (~300–500 lines of changes), or if distinct layers are best worked separately. Keep issues as few as possible.
4. Write the issue files. Follow the format and naming convention in `issues/AGENTS.md`. Issues are prompts for an implementing agent. Be specific enough that the agent does not need to guess. Point the agent at existing files to read rather than re-explaining their content.
5. Confirm what you created. Respond with the issue filename(s), a one-line description of each, and any dependency ordering.

## Rules

- Do not write production code. No `lib/`, `android/`, or `test/` files. Only `issues/*.md`.
- Do not update `docs/` unless the user explicitly asks.
- Do not mark tasks in `docs/plan.md` — that is the implementing agent's job.
- In each issue, reference `AGENTS.md` for general project rules rather than restating them. Only call out constraints specific to this feature.
- Use the actual current date from your runtime context for the filename timestamp.
- If the feature requires a decision the user should make, ask before writing the issue.
