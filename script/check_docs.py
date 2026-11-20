"""Check local Markdown and landing-page references without accessing the network."""

from html.parser import HTMLParser
from pathlib import Path
import re
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
errors = []


class LandingPage(HTMLParser):
    def __init__(self):
        super().__init__()
        self.references = []
        self.ids = set()

    def handle_starttag(self, tag, attributes):
        for name, value in attributes:
            if name in {"src", "href"} and value:
                self.references.append(value)
            if name == "id" and value:
                self.ids.add(value)


def check(source, reference, ids=()):
    url = urlsplit(reference)
    if url.scheme or url.netloc:
        return
    if not url.path:
        if ids and url.fragment and url.fragment not in ids:
            errors.append(f"{source.relative_to(ROOT)}: missing anchor {reference}")
        return
    target = (source.parent / unquote(url.path)).resolve()
    if not target.is_relative_to(ROOT) or not target.exists():
        errors.append(f"{source.relative_to(ROOT)}: broken link {reference}")


for source in [*ROOT.glob("*.md"), *(ROOT / "docs").glob("*.md"), *(ROOT / ".github").glob("*.md")]:
    for reference in re.findall(r"\]\(([^\s)]+)", source.read_text()):
        check(source, reference)

for source in (ROOT / "docs/site").glob("*.html"):
    page = LandingPage()
    page.feed(source.read_text())
    for reference in page.references:
        check(source, reference, page.ids)

if errors:
    raise SystemExit("\n".join(errors))
print("Local documentation references passed.")
