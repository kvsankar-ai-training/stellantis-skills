# AGENTS.md

Guidance for AI coding agents working in this repository.

## Repository Purpose

This repo packages GitHub Copilot **skills** (reusable domain-specific instruction sets) for installation into a user's local Copilot skills directory. It is not an application — there is no build, test, or runtime beyond a PowerShell installer.

## Structure

- `skills/<skill-name>/SKILL.md` — one folder per skill, each containing a single `SKILL.md` with YAML frontmatter (`name`, `description`, `argument-hint`) followed by Markdown instructions.
- `install.ps1` — Windows PowerShell script that copies skill folders from `skills/` into `%USERPROFILE%\.copilot\skills\`. Supports `-SkillName <name>` to target one skill and `-Uninstall` to remove.
- `README.md` — lists installed skills in a table and documents install/uninstall usage.

## Conventions

- Each `SKILL.md` frontmatter must include `name` (matching the folder name), a detailed `description` (used for skill discovery/matching — should state what the skill is for and explicitly what it's NOT for), and `argument-hint`.
- Skill instructions are written as direct guidance to an AI agent (second person, imperative), organized into clearly named phases/sections.
- Use tables for list-like data with multiple attributes; use Mermaid diagrams for workflow/traceability graphs where helpful.

## Adding or Editing a Skill

1. Create/edit `skills/<skill-name>/SKILL.md` — folder name and frontmatter `name` must match exactly.
2. Add or update the skill's row in the README's "What's Here" table, linking to its `SKILL.md`.
3. Test locally by running `.\install.ps1 -SkillName <skill-name>` to install into the user's Copilot skills directory, then reload/restart VS Code to verify Copilot picks it up.

## Testing Changes

There is no automated test suite. Validate changes by:
- Running `.\install.ps1` (or with `-SkillName`) and confirming it copies without error.
- Reviewing the SKILL.md renders correctly as Markdown and frontmatter is valid YAML.

## Commit Messages

Follow the [stellantis-commit-create](skills/stellantis-commit-create/SKILL.md) skill: Conventional Commits header (`type(scope): summary`), a blank line, then a wrapped multi-line body.
