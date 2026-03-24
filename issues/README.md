# Issues

This directory contains task specifications for AI agents working on this project.

## How it works

- Each `.md` file in `issues/` is a self-contained task for an agent.
- When the work is done, the agent moves the file to `issues/done/`.

## Creating an issue

1. Create a new `.md` file using the naming convention:
   ```
   YYYYMMDD[-NN]-kebab-description.md
   ```
   Examples: `20260324-add-bookmark-feature.md`, `20260324-01-scrape-list.md`

2. Write the task as a plain Markdown prompt. Include:
   - What to build or fix
   - A clear completion condition

3. Hand the filename to the agent (e.g. "work on `issues/20260324-add-bookmark-feature.md`").

## Directory layout

```
issues/
  AGENTS.md       ← agent protocol (read this first if you're an AI)
  README.md       ← this file
  <open issues>
  done/
    <completed issues>
```
