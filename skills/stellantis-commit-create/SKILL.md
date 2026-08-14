---
name: stellantis-commit-create
description: 'Craft Git commit messages following the Conventional Commits specification, with a short imperative subject line, a blank line, and a wrapped multi-line body describing the details. Use when asked to write, curate, generate, or improve a commit message, to commit staged changes, or to clean up/squash commit messages to follow a consistent convention. DO NOT USE FOR reviewing code quality or generating pull request descriptions (those are separate concerns).'
argument-hint: 'Optionally: the staged/changed files or a description of the change to commit; otherwise the agent inspects the current git diff'
---

# Conventional Commit Message Curation

Act as a meticulous release engineer who writes commit messages that are consistent, machine-parsable, and useful to future readers of `git log`.

## When to Use

- The user asks to commit staged changes, write a commit message, or clean up/reword an existing commit message.
- The user wants every commit in the repo to follow Conventional Commits, or asks you to fix a message that doesn't.

Do not use this skill to judge whether the code change itself is correct or well-designed — that's a code review concern, not a commit-message concern.

## Phase 1: Gather Facts Before Writing

Never invent what changed. Before drafting a message:

- Inspect the actual diff (staged changes, or the range/commit specified by the user) rather than guessing from conversation context alone.
- Identify the true intent of the change: is it a new feature, a bug fix, a refactor, docs, tests, build/CI, or a revert? Multiple unrelated changes bundled together is a smell — flag it and suggest splitting into separate commits if the diff clearly mixes unrelated concerns.
- Note whether the change breaks backward compatibility. This determines whether a `!` and a `BREAKING CHANGE:` footer are required.

## Phase 2: Structure — Conventional Commits

Every commit message has three parts, in this order, separated by blank lines:

```
<type>[optional scope][!]: <short imperative summary>

<body: wrapped, multi-line explanation of what and why>

[optional footer(s)]
```

### Header (line 1)

- Format: `type(scope): summary` — scope is optional, omit its parentheses entirely if there is no meaningful scope.
- **Type** must be one of:
  | Type | Use for |
  | --- | --- |
  | `feat` | a new feature from the user's/consumer's perspective |
  | `fix` | a bug fix |
  | `docs` | documentation-only changes |
  | `style` | formatting, whitespace, missing semicolons — no code behavior change |
  | `refactor` | code change that neither fixes a bug nor adds a feature |
  | `perf` | a performance improvement |
  | `test` | adding or correcting tests |
  | `build` | build system or external dependency changes |
  | `ci` | CI configuration/scripts |
  | `chore` | maintenance work that doesn't fit any other type |
  | `revert` | reverts a previous commit |
- **Scope** (optional): a short noun naming the affected area/module, e.g. `feat(auth): ...`, `fix(parser): ...`. Omit if the change is repo-wide or scope would be noise.
- **Breaking change marker**: append `!` right after the type/scope, before the colon, if the change is backward-incompatible, e.g. `feat(api)!: remove deprecated endpoint`.
- **Summary**: imperative mood ("add", not "added"/"adds"), no capitalized first letter requirement beyond normal sentence case, no trailing period, ideally ≤ 72 characters, and specific enough to stand alone in a `git log --oneline` listing.

### Blank Line

- Exactly one blank line between the header and the body, and one blank line between the body and any footer(s). Never omit this even for a short body.

### Body (multi-line details)

- Explain **what changed and why**, not a restatement of the diff line-by-line. Assume the reader can see the diff; the body adds context the diff can't show (motivation, prior behavior, trade-offs, alternatives considered).
- Wrap lines at roughly 72 characters so the message reads well in terminal tools that don't soft-wrap.
- Use multiple short paragraphs or a bullet list when there are several distinct points — don't cram everything into one dense paragraph.
- If the change fixes an issue, reference it in the body or footer (e.g., `Fixes #123`), not the summary line.

### Footer(s) (optional, after another blank line)

- `BREAKING CHANGE: <description>` — required when `!` is used in the header; describe what breaks and, if possible, the migration path.
- Issue references: `Fixes #123`, `Closes #123`, `Refs #123`.
- Co-authorship or other trailers as the repo/user convention requires (e.g., `Co-authored-by: Name <email>`).

## Phase 3: Draft and Confirm

- Draft the full message (header + body + footers) and show it to the user before committing, unless the user has explicitly said to commit without confirmation.
- If the diff spans clearly unrelated concerns (e.g., a feature plus an unrelated formatting pass), point this out and suggest splitting rather than silently picking one type for everything.
- If the user's repo has an existing commit history convention that differs from standard Conventional Commits (different types, different scope style), match the existing convention instead of forcing the standard one — check recent `git log` history if unsure.

## Style Rules Summary

- One type, optional one scope, optional `!`, colon, space, imperative summary — no period at the end of the summary line.
- Blank line, then a wrapped multi-line body — never a single unbroken long line.
- Blank line, then footers only if needed (breaking changes, issue refs, trailers).
- Never combine the summary and body onto one line, and never skip the body for a non-trivial change just to save time.
