"""Tests for chain_census.py's own-vs-dependency attribution (no toolchain needed)."""
from __future__ import annotations

import os
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import chain_census  # noqa: E402


class OwnAttributionTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="chain_census_")
        corpus = os.path.join(self.tmp, "corpus")
        os.makedirs(os.path.join(corpus, "App/iOS"))
        os.makedirs(os.path.join(corpus, "Dep"))
        self.app_file = os.path.join(corpus, "App/iOS/Main.swift")
        self.dep_file = os.path.join(corpus, "Dep/D.swift")
        for f in (self.app_file, self.dep_file):
            open(f, "w").write("x\n")
        self.pkg = os.path.join(self.tmp, "pkg")
        # directory-symlink target (spm_app_chain `path`)
        os.makedirs(os.path.join(self.pkg, "Sources"))
        os.symlink(os.path.join(corpus, "Dep"), os.path.join(self.pkg, "Sources", "Dep"))
        # file-list target (spm_app_chain `files`): a real dir of per-file symlinks
        os.makedirs(os.path.join(self.pkg, "Sources", "App", "App/iOS"))
        self.linked = os.path.join(self.pkg, "Sources", "App", "App/iOS/Main.swift")
        os.symlink(self.app_file, self.linked)

    def test_directory_symlink_target(self):
        self.assertTrue(chain_census.is_own(os.path.join(self.pkg, "Sources/Dep/D.swift"), self.pkg, "Dep"))
        self.assertTrue(chain_census.is_own(self.dep_file, self.pkg, "Dep"))
        self.assertFalse(chain_census.is_own(self.dep_file, self.pkg, "App"))

    def test_file_list_target_reported_by_link_or_by_upstream_path(self):
        # the compiler may report the per-file symlink path or the resolved upstream path
        self.assertTrue(chain_census.is_own(self.linked, self.pkg, "App"))
        self.assertTrue(chain_census.is_own(self.app_file, self.pkg, "App"))
        self.assertFalse(chain_census.is_own(self.app_file, self.pkg, "Dep"))


class DiagnosticParseTests(unittest.TestCase):
    def test_clang_diagnostics_in_objc_targets_are_parsed(self):
        line = ("/p/Sources/X/include/A+B.h:11:1: error: unknown type name 'NS_ASSUME_NONNULL_BEGIN'")
        m = chain_census.DIAG.match(line)
        self.assertIsNotNone(m)
        self.assertEqual(m.group("kind"), "error")
        self.assertIsNotNone(chain_census.DIAG.match("/p/a b/C+D.m:21:42: error: no visible @interface"))
        self.assertIsNotNone(chain_census.DIAG.match("/p/x.swift:1:2: error: e"))


class ResumeTests(unittest.TestCase):
    def test_only_rows_of_the_same_spec_and_order_are_resumed(self):
        prev = {"spec": "/a/spec.json", "targets": [
            {"target": "A", "status": "passed"}, {"target": "B", "status": "failed"},
            {"target": "Statsig", "status": "passed"}]}
        self.assertEqual([r["target"] for r in chain_census.resumable(prev, "/a/spec.json", ["A", "B"], None)], ["A"])
        # another spec's out file (a shared scratch dir) contributes nothing
        self.assertEqual(chain_census.resumable(prev, "/b/other.json", ["A", "B", "Statsig"], None), [])
        # --only re-runs the named targets
        self.assertEqual(chain_census.resumable(prev, "/a/spec.json", ["A", "B"], ["A"]), [])


if __name__ == "__main__":
    unittest.main()
