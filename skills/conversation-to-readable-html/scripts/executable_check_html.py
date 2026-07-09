#!/usr/bin/env python3
"""Validate a single-file readable HTML report."""

from __future__ import annotations

import argparse
import re
import sys
from html.parser import HTMLParser
from pathlib import Path


class ReportHTMLParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.tags: list[str] = []
        self.attrs: list[tuple[str, dict[str, str | None]]] = []
        self.text_parts: list[str] = []
        self.heading_levels: list[int] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attr_dict = dict(attrs)
        self.tags.append(tag)
        self.attrs.append((tag, attr_dict))
        if re.fullmatch(r"h[1-6]", tag):
            self.heading_levels.append(int(tag[1]))

    def handle_data(self, data: str) -> None:
        if data.strip():
            self.text_parts.append(data.strip())


def has_meta(attrs: list[tuple[str, dict[str, str | None]]], **expected: str) -> bool:
    for tag, attr in attrs:
        if tag != "meta":
            continue
        if all(attr.get(key, "").lower() == value.lower() for key, value in expected.items()):
            return True
    return False


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate a self-contained readable HTML report.")
    parser.add_argument("html_file", type=Path)
    args = parser.parse_args()

    path = args.html_file
    if not path.exists():
        print(f"error: file not found: {path}", file=sys.stderr)
        return 2
    if path.suffix.lower() not in {".html", ".htm"}:
        print(f"error: expected .html or .htm file: {path}", file=sys.stderr)
        return 2

    raw = path.read_text(encoding="utf-8")
    lower = raw.lower()
    html = ReportHTMLParser()
    html.feed(raw)

    errors: list[str] = []
    warnings: list[str] = []

    if not lower.lstrip().startswith("<!doctype html>"):
        errors.append("missing <!doctype html> at the beginning")
    if "<style" not in lower:
        errors.append("missing inline <style> block")
    if not has_meta(html.attrs, charset="utf-8"):
        errors.append("missing <meta charset=\"utf-8\">")

    viewport_ok = any(
        tag == "meta" and attr.get("name", "").lower() == "viewport"
        for tag, attr in html.attrs
    )
    if not viewport_ok:
        errors.append("missing responsive viewport meta tag")

    if "h1" not in html.tags:
        errors.append("missing <h1>")
    if "main" not in html.tags:
        warnings.append("missing <main>; use it for the document body")

    external_patterns = [
        r"<script\b[^>]*\bsrc=",
        r"<link\b[^>]*\brel=[\"']?stylesheet",
        r"https?://",
        r"//cdn\.",
    ]
    for pattern in external_patterns:
        if re.search(pattern, raw, flags=re.IGNORECASE):
            errors.append(f"external dependency or remote URL detected: {pattern}")

    text = "\n".join(html.text_parts)
    orientation_terms = [
        "これは何の話か",
        "what this is about",
        "overview",
        "概要",
    ]
    if not any(term.lower() in text.lower() for term in orientation_terms):
        warnings.append("no obvious orientation section found")

    conclusion_terms = ["結論", "conclusion"]
    if not any(term.lower() in text.lower() for term in conclusion_terms):
        warnings.append("no obvious conclusion section found")

    action_terms = ["次にやること", "next action", "next actions", "todo", "TODO"]
    if not any(term.lower() in text.lower() for term in action_terms):
        warnings.append("no obvious next-action section found")

    if errors:
        for item in errors:
            print(f"error: {item}", file=sys.stderr)
    for item in warnings:
        print(f"warning: {item}", file=sys.stderr)

    if errors:
        return 1

    print(f"ok: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
