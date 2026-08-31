#!/usr/bin/env python3
"""Focused integration gates for the source-form asset index public API."""

from __future__ import annotations

import contextlib
import hashlib
import io
import json
import os
from pathlib import Path
import tempfile
import unittest

import xcassets_tool


class IndexCatalogsTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="xcassets-index-test.")
        self.root = Path(self.temporary.name)
        self.app = self.root / "App"
        self.app.mkdir()

    def tearDown(self) -> None:
        self.temporary.cleanup()

    @staticmethod
    def _catalog(root: Path, catalog_name: str, payload: bytes) -> Path:
        catalog = root / catalog_name
        imageset = catalog / "Shared.imageset"
        imageset.mkdir(parents=True)
        (catalog / "Contents.json").write_text(
            '{"info":{"author":"xcode","version":1}}\n', encoding="utf-8"
        )
        (imageset / "Contents.json").write_text(
            '{"images":[{"idiom":"universal","filename":"shared.png",'
            '"scale":"2x"}],"info":{"author":"xcode","version":1}}\n',
            encoding="utf-8",
        )
        (imageset / "shared.png").write_bytes(payload)
        return catalog

    def test_preserves_explicit_order_and_every_collision_payload(self) -> None:
        first = self._catalog(self.app, "First.xcassets", b"first")
        second = self._catalog(self.app, "Second.xcassets", b"second")
        output = self.root / "index"
        with contextlib.redirect_stdout(io.StringIO()):
            result = xcassets_tool.index_catalogs(
                [os.fspath(second), os.fspath(first)],
                os.fspath(self.app),
                os.fspath(output),
            )

        self.assertEqual(
            result["catalogs"], ["Second.xcassets", "First.xcassets"]
        )
        winner = result["assets"]["Shared"]["variants"][0]["payload"]
        loser = result["collisions"]["Shared"][0]["record"]["variants"][0][
            "payload"
        ]
        self.assertEqual(winner["sha256"], hashlib.sha256(b"second").hexdigest())
        self.assertEqual(loser["sha256"], hashlib.sha256(b"first").hexdigest())
        for record, expected in ((winner, b"second"), (loser, b"first")):
            self.assertEqual(
                (output / "Resources" / record["file"]).read_bytes(), expected
            )
        self.assertEqual(json.loads((output / "index.json").read_text()), result)

        with self.assertRaisesRegex(xcassets_tool.Refusal, "stale asset index"):
            xcassets_tool.index_catalogs(
                [os.fspath(first)], os.fspath(self.app), os.fspath(output)
            )

    def test_refuses_duplicate_escape_and_symlink_inputs(self) -> None:
        catalog = self._catalog(self.app, "Assets.xcassets", b"payload")
        with self.assertRaisesRegex(xcassets_tool.Refusal, "more than once"):
            xcassets_tool.index_catalogs(
                [os.fspath(catalog), os.fspath(catalog)],
                os.fspath(self.app),
                os.fspath(self.root / "duplicate"),
            )

        outside_root = self.root / "Outside"
        outside_root.mkdir()
        outside = self._catalog(outside_root, "Outside.xcassets", b"outside")
        with self.assertRaisesRegex(xcassets_tool.Refusal, "escapes"):
            xcassets_tool.index_catalogs(
                [os.fspath(outside)],
                os.fspath(self.app),
                os.fspath(self.root / "escape"),
            )

        link = catalog / "Shared.imageset/linked.png"
        os.symlink(catalog / "Shared.imageset/shared.png", link)
        with self.assertRaisesRegex(xcassets_tool.Refusal, "contains a symlink"):
            xcassets_tool.index_catalogs(
                [os.fspath(catalog)],
                os.fspath(self.app),
                os.fspath(self.root / "symlink"),
            )


if __name__ == "__main__":
    unittest.main()
