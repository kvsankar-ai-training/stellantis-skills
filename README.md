# Stellantis Skills

A collection of GitHub Copilot skills packaged for reuse across projects, plus a Windows-friendly installer.

## What's Here

| Skill | Description |
| --- | --- |
| [stellantis-srs-create](skills/stellantis-srs-create/SKILL.md) | Interviews the user about a rough product idea, then drafts a Leffingwell-style Software Requirements Specification (SRS) and a companion Acceptance Tests document, using slug-based identifiers throughout. |
| [stellantis-design-create](skills/stellantis-design-create/SKILL.md) | Turns requirements into a lean, HTML Software Design Document (SDD) with rendered component/sequence/deployment diagrams: key decisions (including the tech stack) captured as ADRs, the simplest design that solves the problem, UX mockups (user-flow diagrams and low-fidelity wireframes) for any system with a UI, whichever boundary contract(s) the system actually has (API/UI/CLI/library), a data schema only if the system owns persisted data, an explicit security posture, an observability & operability plan, performance/scalability NFRs as concrete SLOs, an error-handling & resilience strategy, a functional-core/imperative-shell architecture honoring SRP and loose coupling, component-level tests derived from ATs, and a design-to-requirements traceability matrix. Applies to any system kind — backend, frontend/UI, mobile, CLI, library, or full-stack — not backend-only. |
| [stellantis-plan-create](skills/stellantis-plan-create/SKILL.md) | Turns an SRS and SDD into a delivery plan expressed as scoped, dependency-ordered pull requests (~1000 LOC guideline each), with a Mermaid PR dependency graph, parallel-track/critical-path guidance, and per-PR demo steps and tests to run. |
| [stellantis-commit-create](skills/stellantis-commit-create/SKILL.md) | Crafts Git commit messages following the Conventional Commits specification, with a short imperative subject line, a blank line, and a wrapped multi-line body. |
| [stellantis-tdd-codegen](skills/stellantis-tdd-codegen/SKILL.md) | Implements a feature test-first using Red/Green/Refactor, delegating test-writing and implementation to two separate subagents so each stays blind to the other's work, then refactors for readability and adds further unit tests as the last step. |
| [stellantis-confluence-to-md](skills/stellantis-confluence-to-md/SKILL.md) | Downloads a Confluence page by URL and converts it to Markdown using token-based auth (Cloud API token or Server/DC PAT). Dependencies and `.env` are provisioned automatically at install time -- no per-project setup needed. |

## Installing Skills

Skills are installed into your user-level GitHub Copilot skills directory (`%USERPROFILE%\.copilot\skills\`), where Copilot in VS Code discovers them automatically.

For any skill that ships a `requirements.txt`, the installer also provisions a private Python virtual environment inside the installed skill folder and installs its dependencies, so there is nothing to `pip install` manually before first use. If a skill ships a `.env.example`, a `.env` is seeded from it on first install and preserved across re-installs/updates, so credentials are configured once, centrally, instead of per project.

Install everything in this repo:

```powershell
.\install.ps1
```

Install a single skill:

```powershell
.\install.ps1 -SkillName stellantis-srs-create
```

Uninstall a skill:

```powershell
.\install.ps1 -SkillName stellantis-srs-create -Uninstall
```

After installing, restart VS Code (or reload the window) so Copilot picks up the new/updated skill.

## Adding a New Skill

1. Create a new folder under `skills/<skill-name>/`.
2. Add a `SKILL.md` with YAML frontmatter (`name`, `description`, `argument-hint`) followed by the skill's instructions, matching the style of the existing skill(s) in this repo.
3. List the new skill in the table above.
4. Run `.\install.ps1 -SkillName <skill-name>` to install and test it locally.
