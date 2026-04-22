# Issue Tracker — Agent Protocol

This document defines how AI agents work with issues in this project.
Read it whenever you are assigned an issue file.

---

## File Naming Convention

```
YYYYMMDD[-NN]-kebab-description.md
```

- `YYYYMMDD` — date the issue was created
- `-NN` — optional sequence number (use when multiple issues belong to the same feature or date batch, e.g. `01`, `02`)
- `kebab-description` — short, lowercase, hyphen-separated description

**Examples:**
```
20260324-add-bookmark-feature.md       # standalone issue
20260324-01-scrape-competition-list.md # part of a batch
20260324-02-cache-competitions.md
```

---

## Agent Contract

When you are assigned an issue:

1. **Read the issue file** as your primary task specification.
2. **Follow all rules in [AGENTS.md](../AGENTS.md)** — code quality, architecture, documentation, and tests.
3. **Reference the issue filename (no path) in every commit message** you make while working the issue. Add it as a trailer line after a blank line.

   ```
   feat(competitions): add bookmark toggle

   Issue: 20260324-01-add-bookmark-feature.md
   ```

   ```
   fix(data): handle null date in scraper

   Issue: 20260324-01-add-bookmark-feature.md
   ```

4. **When done:** move the issue file to `issues/done/`. Do this only when the work is complete and the completion condition stated in the issue is met — you judge this.

---

## Authoring Issues

Issues are plain Markdown files — just a prompt describing the task. No required frontmatter or metadata.

A good issue includes:
- **Feature summary** — a short, high-level description of the overall feature or area being worked on, so the agent understands the broader goal before reading the specifics
- **Scope** — a clear statement of what *this particular ticket* is responsible for, distinct from related issues in the same batch
- What to build or fix (the task)
- Acceptance criteria or a completion condition (so the agent knows when to close it)
- Any relevant context, constraints, or links to docs

Keep issues focused. One logical change per file.
