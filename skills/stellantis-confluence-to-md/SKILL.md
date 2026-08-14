---
name: stellantis-confluence-to-md
description: 'Download a single Confluence page by URL and convert it to a clean Markdown (.md) file using token-based authentication (Confluence Cloud API token or Server/Data Center Personal Access Token) via the official REST API -- never username/password login or HTML scraping. USE FOR: "convert this Confluence page to markdown", "download this Confluence link as .md", "export Confluence page", or any request to turn a Confluence URL into a local Markdown file. Handles Confluence storage-format quirks: code-block macros, diagram macros (drawio/plantuml/gliffy), table-of-contents macros, and @mention user-id resolution, so the output does not contain leaked macro parameters or raw diagram payloads. DO NOT USE FOR bulk/space-wide exports, Jira issues, or general web scraping.'
argument-hint: 'A Confluence page URL to convert, and optionally an output directory (defaults to the current directory)'
---

# Confluence Page → Markdown Converter

Act as an engineer setting up and running a small, self-contained Python CLI tool that fetches one Confluence page via the REST API and converts it to a Markdown file.

## Authentication Policy (Non-Negotiable)

This skill **only** supports token-based authentication:

- **Confluence Cloud**: an email address + an API token (Basic auth).
- **Confluence Server / Data Center**: a Personal Access Token (PAT), sent as a Bearer token.

Never prompt the user for their Confluence password, never scrape the rendered web page's HTML/DOM, and never store credentials anywhere except the single `.env` file described below (which must stay untracked by git).

## How This Skill Is Provisioned (No Per-Project Setup)

Installing this skill via the repo's `install.ps1` already does all one-time setup:

- The script, `requirements.txt`, and `.env.example` are copied to `%USERPROFILE%\.copilot\skills\stellantis-confluence-to-md\`.
- A private virtual environment is created at `%USERPROFILE%\.copilot\skills\stellantis-confluence-to-md\.venv\` with all dependencies pre-installed.
- `.env` is seeded from `.env.example` on first install, and preserved across re-installs/updates.

This means the tool is ready to run from **any** workspace immediately after install — do not copy the script into the current project, and do not run `pip install` per project. Always invoke the tool from its installed location:

```powershell
& "$env:USERPROFILE\.copilot\skills\stellantis-confluence-to-md\.venv\Scripts\python.exe" "$env:USERPROFILE\.copilot\skills\stellantis-confluence-to-md\confluence_to_md.py" "<confluence-page-url>" -o "<output-dir-in-current-project>"
```

Use an output directory inside the user's current project (e.g. `output`) so the resulting `.md` lands where they're working, even though the script and its dependencies live centrally.

## Phase 1: One-Time Credential Setup (Per User, Not Per Project)

If `%USERPROFILE%\.copilot\skills\stellantis-confluence-to-md\.env` still has placeholder values (check `CONFLUENCE_BASE_URL` for `your-domain.atlassian.net`, or empty token fields), walk the user through it once:

1. Tell the user to create a token, based on their Confluence type:

   **Confluence Cloud** (URL looks like `https://<company>.atlassian.net/wiki/...`):
   - Go to https://id.atlassian.com/manage-profile/security/api-tokens
   - Click **Create API token**, give it a label (e.g. "confluence-md-export"), and copy the generated token immediately (it's shown only once).
   - This token is used together with the user's Atlassian account **email address**.

   **Confluence Server / Data Center** (self-hosted, custom domain):
   - Go to the user's Confluence profile → **Personal Access Tokens** (usually under `<base-url>/plugins/personalaccesstokens/usertokens.action`).
   - Click **Create token**, set an expiry, and copy the generated token immediately.
   - This token is used alone (no email needed) as a Bearer token.

2. Edit `%USERPROFILE%\.copilot\skills\stellantis-confluence-to-md\.env` and fill in:
   - `CONFLUENCE_BASE_URL` — e.g. `https://your-domain.atlassian.net/wiki` (Cloud) or `https://confluence.your-company.com` (Server/DC). **This must not be left as the placeholder** — a wrong/placeholder base URL causes silent 401 errors.
   - For Cloud: `CONFLUENCE_EMAIL` + `CONFLUENCE_API_TOKEN`. Leave `CONFLUENCE_PAT` empty.
   - For Server/DC: `CONFLUENCE_PAT`. Leave `CONFLUENCE_EMAIL`/`CONFLUENCE_API_TOKEN` empty.
   - `CONFLUENCE_VERIFY_SSL` / `CONFLUENCE_CA_BUNDLE` only if the corporate Confluence instance uses a self-signed or internal CA certificate.
3. This file lives outside any git repository (`%USERPROFILE%\.copilot\skills\...`), so there is nothing to `.gitignore` — it is set once and reused across every project.

## Phase 2: Running the Converter

Run the command shown above with the target URL and an output directory in the current project. Notes:

- The URL can be either the "pretty" form (`.../wiki/spaces/KEY/pages/123456/Page+Title`) or a legacy `viewpage.action?pageId=123456` link — the script extracts the page id (or falls back to space key + title lookup) automatically.
- Output file is written as `<output-dir>/<slugified-page-title>.md`.
- If the command fails with `Authentication failed (401)`, check: (a) the token hasn't expired/been revoked, (b) `CONFLUENCE_BASE_URL` is the real domain and not left as the `.env.example` placeholder, (c) Cloud vs Server/DC auth mode matches the instance type.
- If `.venv\Scripts\python.exe` doesn't exist, the venv provisioning step in `install.ps1` didn't run or failed (e.g. `python` wasn't on PATH at install time) — re-run `install.ps1 -SkillName stellantis-confluence-to-md` after installing Python, or fall back to `pip install -r requirements.txt` inside the installed skill folder manually.

## Design Notes (Why the Converter Works This Way)

Confluence's "storage format" HTML uses custom macro tags (`<ac:structured-macro>`, `<ac:parameter>`, `<ac:link>`/`<ri:user>`) that a naive HTML-to-Markdown pass does not understand — it just concatenates their text nodes. The bundled script preprocesses the storage HTML with BeautifulSoup before handing it to `markdownify`:

- `code` macros → real fenced Markdown code blocks (language preserved when set).
- `toc` / `change-history` macros → removed (they render no useful text).
- `drawio` / `plantumlcloud` / `gliffy` diagram macros → replaced with a `[Diagram: <filename> — view in Confluence for the rendered image]` placeholder, since the embedded diagram payload can't be rendered as text.
- `ri:user` account-id mentions (e.g. Owner/Reviewer fields) → resolved to real display names via the Confluence `/rest/api/user` endpoint.
- Underscore-escaping is disabled so identifiers like `sp_error_retry_event` aren't mangled into `sp\_error\_retry\_event`.

If the user reports other garbled sections in future runs, inspect the raw storage HTML (fetch the page with `expand=body.storage` and save it) to find the offending macro name, then extend `preprocess_storage_html()` with a case for it rather than guessing.

## Troubleshooting Checklist

- **401 Unauthorized**: bad/placeholder base URL, expired token, or wrong auth mode for the instance type.
- **403 Forbidden**: token is valid but the account lacks view permission on that page/space.
- **404 Not Found**: page id wrong, or space key/title lookup failed (title must match exactly, spaces preserved).
- **SSL errors on corporate networks**: set `CONFLUENCE_CA_BUNDLE` to a local `.pem` file rather than disabling `CONFLUENCE_VERIFY_SSL`.
- **Leaked macro text in output**: a macro type not yet handled by `preprocess_storage_html()` — add a case for it.
