"""Regression cases for documentation paths, anchors and Markdown validation."""

import importlib.util
from pathlib import Path
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location("check_docs", Path(__file__).resolve().parents[2] / "script/check_docs.py")
DOCS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(DOCS)


class DocumentationTests(unittest.TestCase):
    def check(self, files):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for name, text in files.items():
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(text)
            return DOCS.check_files(root, [root / name for name in files if name.endswith((".md", ".html"))])

    def test_nested_markdown_and_encoded_paths(self):
        self.assertEqual([], self.check({"packaging/dmg/README.md": "[A](../../docs/a%20guide.md#start)",
                                         "docs/a guide.md": "# Start\n"}))

    def test_missing_markdown_and_html_anchors(self):
        errors = self.check({"a.md": '[B](b.md#missing)\n<a href="b.html#missing">B</a>',
                             "b.md": "# Present\n", "b.html": '<h1 id="present">Title</h1>'})
        self.assertEqual(2, len(errors))
        self.assertTrue(all("missing anchor" in error for error in errors))

    def test_duplicate_headings_and_html_ids(self):
        self.assertEqual([], self.check({"a.md": '[B](#same-1)\n[ID](#explicit)\n# Same\n# Same\n<a id="explicit"></a>'}))

    def test_srcset_and_reference_definition_targets(self):
        errors = self.check({"a.md": '[Guide][guide]\n[guide]: missing.md\n<picture><source srcset="missing.png 1x, valid.png 2x"></picture>',
                             "valid.png": "fixture"})
        self.assertEqual(2, len(errors))
        self.assertTrue(all("broken link" in error for error in errors))

    def test_external_links_and_fenced_examples_are_ignored(self):
        self.assertEqual([], self.check({"a.md": '[Web](https://example.com)\n```md\n[Example](missing.md)\n```\n'}))

    def test_unclosed_fences_whitespace_and_escape_from_root_fail(self):
        errors = self.check({"a.md": '[Outside](../outside.md)\nline \n```sh\nunclosed\n'})
        self.assertTrue(any("trailing whitespace" in error for error in errors))
        self.assertTrue(any("unclosed code fence" in error for error in errors))
        self.assertTrue(any("broken link" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
