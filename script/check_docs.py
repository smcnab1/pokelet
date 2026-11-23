"""Lint tracked Markdown and check local Markdown/HTML links without the network."""

from collections import Counter
from html import unescape
from html.parser import HTMLParser
from pathlib import Path
import re
import subprocess
from urllib.parse import unquote, urlsplit


class HTMLReferences(HTMLParser):
    def __init__(self):
        super().__init__()
        self.references = []
        self.ids = set()

    def handle_starttag(self, tag, attributes):
        for name, value in attributes:
            if name in {"src", "href", "poster"} and value:
                self.references.append(value)
            if name == "srcset" and value:
                self.references.extend(item.strip().split()[0] for item in value.split(",") if item.strip())
            if name in {"id", "name"} and value:
                self.ids.add(value)


def markdown_content(text, source, errors):
    """Ignore fenced examples while checking fence closure and whitespace."""
    visible = []
    fence = None
    for number, line in enumerate(text.splitlines(), 1):
        if line.rstrip() != line and not line.endswith("  "):
            errors.append(f"{source}:{number}: trailing whitespace")
        marker = re.match(r"^\s{0,3}(`{3,}|~{3,})(.*)$", line)
        if marker:
            token, suffix = marker.groups()
            if fence is None:
                fence = token
            elif token[0] == fence[0] and len(token) >= len(fence) and not suffix.strip():
                fence = None
            continue
        if fence is None:
            visible.append(line)
    if fence:
        errors.append(f"{source}: unclosed code fence")
    return "\n".join(visible)


def anchors(text):
    counts = Counter()
    result = set()
    for heading in re.findall(r"^ {0,3}#{1,6}\s+(.+?)\s*#*\s*$", text, re.MULTILINE):
        heading = re.sub(r"!?\[([^\]]+)\]\([^)]*\)", r"\1", heading)
        heading = unescape(re.sub(r"<[^>]+>", "", heading)).lower()
        slug = re.sub(r"[^\w\- ]", "", heading).replace(" ", "-")
        result.add(slug if counts[slug] == 0 else f"{slug}-{counts[slug]}")
        counts[slug] += 1
    return result


def check_files(root, sources):
    root = root.resolve()
    errors = []
    documents = {}
    for source in sources:
        source = source.resolve()
        if not source.is_file():
            continue
        text = source.read_text()
        if source.suffix.lower() == ".md":
            text = markdown_content(text, source.relative_to(root), errors)
        page = HTMLReferences()
        page.feed(text)
        references = page.references
        ids = page.ids
        if source.suffix.lower() == ".md":
            ids |= anchors(text)
            # Inline links/images and reference-style link definitions.
            references += re.findall(r"\]\(<?([^\s)>]+)>?(?:\s+[^)]*)?\)", text)
            references += re.findall(r"^ {0,3}\[[^\]]+\]:\s*<?([^\s>]+)", text, re.MULTILINE)
        documents[source.resolve()] = (references, ids)

    for source, (references, _) in documents.items():
        for reference in references:
            url = urlsplit(unescape(reference))
            if url.scheme or url.netloc:
                continue
            target = (source.parent / unquote(url.path)).resolve() if url.path else source
            label = source.relative_to(root)
            if not target.is_relative_to(root) or not target.exists():
                errors.append(f"{label}: broken link {reference}")
            elif url.fragment and target in documents and unquote(url.fragment) not in documents[target][1]:
                errors.append(f"{label}: missing anchor {reference}")
    return errors


def main():
    root = Path(__file__).resolve().parents[1]
    paths = subprocess.check_output(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=root
    ).decode().split("\0")
    sources = sorted({root / path for path in paths if Path(path).suffix.lower() in {".md", ".html"}})
    errors = check_files(root, sources)
    if errors:
        raise SystemExit("\n".join(errors))
    print(f"Markdown and local documentation references passed ({len(sources)} files).")


if __name__ == "__main__":
    main()
