# Stellantis Skills

A collection of GitHub Copilot skills packaged for reuse across projects, plus a Windows-friendly installer.

## What's Here

| Skill | Description |
| --- | --- |
| [stellantis-srs-create](skills/stellantis-srs-create/SKILL.md) | Interviews the user about a rough product idea, then drafts a Leffingwell-style Software Requirements Specification (SRS) and a companion Acceptance Tests document, using slug-based identifiers throughout. |

## Installing Skills

Skills are installed into your user-level GitHub Copilot skills directory (`%USERPROFILE%\.copilot\skills\`), where Copilot in VS Code discovers them automatically.

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
