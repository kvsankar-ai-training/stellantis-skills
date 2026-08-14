#!/usr/bin/env python3
"""Download a Confluence page by URL and convert it to a Markdown file.

Authentication is token-based only:
  - Confluence Cloud:            CONFLUENCE_EMAIL + CONFLUENCE_API_TOKEN (Basic auth)
  - Confluence Server/DataCenter: CONFLUENCE_PAT (Bearer auth)

No username/password login or HTML scraping is performed; content is fetched
via the official Confluence REST API in "storage" format and converted to
Markdown.
"""
from __future__ import annotations

import argparse
import os
import re
import sys
import urllib.parse
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

import requests
from bs4 import BeautifulSoup
from dotenv import load_dotenv
from markdownify import markdownify
from slugify import slugify


class ConfluenceError(RuntimeError):
    pass


@dataclass
class ConfluenceConfig:
    base_url: str
    email: Optional[str]
    api_token: Optional[str]
    pat: Optional[str]
    verify_ssl: bool
    ca_bundle: Optional[str]

    @classmethod
    def from_env(cls) -> "ConfluenceConfig":
        load_dotenv()

        base_url = os.getenv("CONFLUENCE_BASE_URL", "").rstrip("/")
        email = os.getenv("CONFLUENCE_EMAIL") or None
        api_token = os.getenv("CONFLUENCE_API_TOKEN") or None
        pat = os.getenv("CONFLUENCE_PAT") or None
        verify_ssl = os.getenv("CONFLUENCE_VERIFY_SSL", "true").strip().lower() != "false"
        ca_bundle = os.getenv("CONFLUENCE_CA_BUNDLE") or None

        if not base_url:
            raise ConfluenceError(
                "CONFLUENCE_BASE_URL is not set. Copy .env.example to .env and fill it in."
            )
        if not pat and not (email and api_token):
            raise ConfluenceError(
                "No credentials found. Set CONFLUENCE_PAT (Server/DC) or both "
                "CONFLUENCE_EMAIL and CONFLUENCE_API_TOKEN (Cloud) in your .env file."
            )
        return cls(base_url, email, api_token, pat, verify_ssl, ca_bundle)

    def auth(self):
        """Return the requests auth tuple, or None when using Bearer auth."""
        if self.pat:
            return None
        return (self.email, self.api_token)

    def headers(self) -> dict:
        if self.pat:
            return {"Authorization": f"Bearer {self.pat}", "Accept": "application/json"}
        return {"Accept": "application/json"}

    def verify(self):
        if self.ca_bundle:
            return self.ca_bundle
        return self.verify_ssl


def extract_page_id(page_url: str) -> Optional[str]:
    """Best-effort extraction of a numeric page id from a Confluence URL."""
    parsed = urllib.parse.urlparse(page_url)

    # e.g. .../pages/123456789/Some+Title  or  .../pages/123456789
    match = re.search(r"/pages/(\d+)", parsed.path)
    if match:
        return match.group(1)

    # e.g. .../viewpage.action?pageId=123456789
    query = urllib.parse.parse_qs(parsed.query)
    if "pageId" in query:
        return query["pageId"][0]

    return None


def extract_space_and_title(page_url: str) -> Optional[tuple[str, str]]:
    """Best-effort extraction of (space_key, title) from a pretty Confluence URL."""
    parsed = urllib.parse.urlparse(page_url)
    parts = [p for p in parsed.path.split("/") if p]

    if "spaces" in parts and "pages" in parts:
        space_idx = parts.index("spaces")
        pages_idx = parts.index("pages")
        if space_idx + 1 < len(parts) and pages_idx + 2 < len(parts):
            space_key = parts[space_idx + 1]
            raw_title = parts[pages_idx + 2]
            title = urllib.parse.unquote(raw_title).replace("+", " ")
            return space_key, title

    return None


def fetch_page_by_id(config: ConfluenceConfig, page_id: str) -> dict:
    url = f"{config.base_url}/rest/api/content/{page_id}"
    params = {"expand": "body.storage,version,space"}
    response = requests.get(
        url,
        params=params,
        auth=config.auth(),
        headers=config.headers(),
        verify=config.verify(),
        timeout=30,
    )
    _raise_for_status(response)
    return response.json()


def fetch_page_by_title(config: ConfluenceConfig, space_key: str, title: str) -> dict:
    url = f"{config.base_url}/rest/api/content"
    params = {
        "spaceKey": space_key,
        "title": title,
        "expand": "body.storage,version,space",
    }
    response = requests.get(
        url,
        params=params,
        auth=config.auth(),
        headers=config.headers(),
        verify=config.verify(),
        timeout=30,
    )
    _raise_for_status(response)
    results = response.json().get("results", [])
    if not results:
        raise ConfluenceError(f"No page found with title '{title}' in space '{space_key}'.")
    return results[0]


def _raise_for_status(response: requests.Response) -> None:
    if response.status_code == 401:
        raise ConfluenceError("Authentication failed (401). Check your token/PAT and email.")
    if response.status_code == 403:
        raise ConfluenceError("Access denied (403). Your account may lack permission for this page.")
    if response.status_code == 404:
        raise ConfluenceError("Page not found (404). Check the URL / page id.")
    if not response.ok:
        raise ConfluenceError(f"Request failed: {response.status_code} {response.text[:500]}")


def resolve_user_display_names(config: ConfluenceConfig, html: str) -> dict:
    """Look up display names for ri:user account-id mentions found in the storage HTML."""
    account_ids = set(re.findall(r'ri:account-id="([^"]+)"', html))
    display_names: dict = {}
    for account_id in account_ids:
        try:
            response = requests.get(
                f"{config.base_url}/rest/api/user",
                params={"accountId": account_id},
                auth=config.auth(),
                headers=config.headers(),
                verify=config.verify(),
                timeout=15,
            )
            if response.ok:
                display_names[account_id] = response.json().get("displayName", account_id)
        except requests.RequestException:
            pass
    return display_names


def preprocess_storage_html(html: str, user_display_names: dict) -> str:
    """Rewrite Confluence-specific markup into plain HTML that markdownify understands.

    Without this, markdownify treats <ac:structured-macro>/<ac:parameter> tags as unknown
    elements and just concatenates their text, which leaks macro parameters (e.g. code-block
    width/wrap flags) and huge diagram payloads into the output.
    """
    soup = BeautifulSoup(html, "html.parser")

    for user_link in soup.find_all("ri:user"):
        account_id = user_link.get("ri:account-id", "")
        user_link.replace_with(user_display_names.get(account_id, "Unknown user"))

    for macro in soup.find_all("ac:structured-macro"):
        name = macro.get("ac:name", "")

        if name == "code":
            language_param = macro.find("ac:parameter", {"ac:name": "language"})
            language = language_param.get_text() if language_param else ""
            body = macro.find("ac:plain-text-body")
            code_text = body.get_text() if body else ""

            pre_tag = soup.new_tag("pre")
            code_tag = soup.new_tag("code")
            if language:
                code_tag["class"] = f"language-{language}"
            code_tag.string = code_text
            pre_tag.append(code_tag)
            macro.replace_with(pre_tag)

        elif name in ("toc", "change-history"):
            macro.decompose()

        elif name in ("plantumlcloud", "drawio", "gliffy"):
            filename_param = macro.find("ac:parameter", {"ac:name": "filename"})
            filename = filename_param.get_text() if filename_param else "diagram"
            placeholder = soup.new_tag("p")
            placeholder.string = f"[Diagram: {filename} \u2014 view in Confluence for the rendered image]"
            macro.replace_with(placeholder)

        else:
            # Unknown macro: keep any rendered body text, drop the raw parameters.
            body = macro.find("ac:rich-text-body") or macro.find("ac:plain-text-body")
            if body:
                macro.replace_with(body)
            else:
                macro.decompose()

    return str(soup)


def convert_to_markdown(config: ConfluenceConfig, page: dict) -> str:
    html = page["body"]["storage"]["value"]
    user_display_names = resolve_user_display_names(config, html)
    cleaned_html = preprocess_storage_html(html, user_display_names)
    markdown = markdownify(cleaned_html, heading_style="ATX", escape_underscores=False)
    return re.sub(r"\n{3,}", "\n\n", markdown).strip() + "\n"


def build_output_path(page: dict, output_dir: Path) -> Path:
    title = page.get("title", "confluence-page")
    filename = f"{slugify(title)}.md"
    return output_dir / filename


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("url", help="Full URL of the Confluence page to download.")
    parser.add_argument(
        "-o", "--output-dir", default=".", help="Directory to write the .md file to (default: current dir)."
    )
    args = parser.parse_args()

    try:
        config = ConfluenceConfig.from_env()

        page_id = extract_page_id(args.url)
        if page_id:
            page = fetch_page_by_id(config, page_id)
        else:
            space_and_title = extract_space_and_title(args.url)
            if not space_and_title:
                raise ConfluenceError(
                    "Could not parse a page id or space/title from the URL. "
                    "Expected formats like '.../pages/123456/Title' or '.../spaces/KEY/pages/123456/Title'."
                )
            page = fetch_page_by_title(config, *space_and_title)

        markdown = convert_to_markdown(config, page)

        output_dir = Path(args.output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)
        output_path = build_output_path(page, output_dir)
        output_path.write_text(markdown, encoding="utf-8")

        print(f"Saved: {output_path}")
        return 0

    except ConfluenceError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1
    except requests.RequestException as exc:
        print(f"Network error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
