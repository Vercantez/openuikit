"""Tests for chain_census.py's own-file attribution — fixture-only."""
from __future__ import annotations

import os
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import chain_census  # noqa: E402


class OwnAttributionTests(unittest.TestCase):
    def test_file_behind_a_per_entry_symlink_is_own(self):
        # spm_app_chain's "generated" targets are a real directory whose
        # entries are symlinks into the upstream tree; a diagnostic's path
        # resolves into upstream, and must still count as the target's own.
        tmp = tempfile.mkdtemp(prefix="chain_census_")
        upstream = os.path.join(tmp, "corpus", "KsApi")
        os.makedirs(os.path.join(upstream, "models"))
        open(os.path.join(upstream, "models", "User.swift"), "w").write("")
        other = os.path.join(tmp, "corpus", "Other")
        os.makedirs(other)
        open(os.path.join(other, "O.swift"), "w").write("")
        own = os.path.join(tmp, "pkg", "Sources", "KsApi")
        os.makedirs(own)
        os.symlink(os.path.join(upstream, "models"), os.path.join(own, "models"))
        open(os.path.join(own, "Secrets.swift"), "w").write("")
        roots = [os.path.realpath(own), os.path.realpath(os.path.join(upstream, "models"))]
        self.assertTrue(chain_census.is_own(os.path.join(own, "models", "User.swift"), roots))
        self.assertTrue(chain_census.is_own(os.path.join(upstream, "models", "User.swift"), roots))
        self.assertTrue(chain_census.is_own(os.path.join(own, "Secrets.swift"), roots))
        self.assertFalse(chain_census.is_own(os.path.join(other, "O.swift"), roots))


if __name__ == "__main__":
    unittest.main()
