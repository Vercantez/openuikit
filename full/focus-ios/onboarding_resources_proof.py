#!/usr/bin/env python3
"""Deterministic, fail-closed Focus Onboarding/Widget resource proof.

The proof stages the complete pinned target-local asset catalogs, copies the
supported color catalogs byte for byte, rasterizes each PDF appearance at
1x/2x/3x, and creates original geometric substitutes for four SF Symbol names.
It emits a small explicit resource index for each target.  It does not invoke
actool and it does not claim that UIKit/SwiftUI can consume the bundles yet.
"""

from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal, ROUND_HALF_UP
import binascii
import ctypes
import errno
from functools import lru_cache
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import platform
import re
import stat
import struct
import subprocess
import sys
from typing import Any, Iterable
import zlib


FOCUS_COMMIT = "a2832521c1daa0c23419c73705ae043ed60c9791"
FOCUS_PREFIX = "focus-ios"
MANIFEST = {
    "path": "BlockzillaPackage/Package.swift",
    "size": 1975,
    "sha256": "2d29b769de137389f5613de6755211b255533375bf6003a2192f514e96899248",
}
SCALES = (1, 2, 3)
DPI_PER_SCALE = 72
SAFE_ENVIRONMENT = {
    "LANG": "C",
    "LC_ALL": "C",
    "PATH": "/usr/bin:/bin",
    "SOURCE_DATE_EPOCH": "0",
    "TZ": "UTC",
}
GIT_ENVIRONMENT = {
    **SAFE_ENVIRONMENT,
    "GIT_CONFIG_GLOBAL": os.devnull,
    "GIT_CONFIG_NOSYSTEM": "1",
    "GIT_NO_REPLACE_OBJECTS": "1",
    "GIT_OPTIONAL_LOCKS": "0",
}
NOFOLLOW = getattr(os, "O_NOFOLLOW", 0)
SHA256_RE = re.compile(r"[0-9a-f]{64}\Z")
COMMIT_RE = re.compile(r"[0-9a-f]{40}\Z")
DARWIN_ACL_TYPE_EXTENDED = 0x00000100


ONBOARDING_COLOR_FILES = [
    ("BlockzillaPackage/Sources/Onboarding/DesignSystem/Colors.xcassets/Contents.json", 63, "0fd49ba3c3585c709678e0046a821c3c60685ec7063720d30d3a3448be3a208b"),
    ("BlockzillaPackage/Sources/Onboarding/DesignSystem/Colors.xcassets/actionButton.colorset/Contents.json", 689, "4f89a7164eba864344821fedf16ff651a542b696220289967535a6e3811ae9f1"),
    ("BlockzillaPackage/Sources/Onboarding/DesignSystem/Colors.xcassets/secondOnboardingScreenBackground.colorset/Contents.json", 689, "732d93cf49fa1ed0d2f3a97bf79c7420833b7fc6026124c0704e6a1b2faf54e4"),
    ("BlockzillaPackage/Sources/Onboarding/DesignSystem/Colors.xcassets/secondOnboardingScreenBottomButton.colorset/Contents.json", 326, "86c7d9e63dfbd1ab09008ff392b8100f7c1914b58e8de99346d00a08c180a579"),
    ("BlockzillaPackage/Sources/Onboarding/DesignSystem/Colors.xcassets/secondOnboardingScreenText.colorset/Contents.json", 689, "fecf223ec5945953783e066a501fbe52601a5d1898748cb1cee9d89e2ea480af"),
]
ONBOARDING_IMAGE_FILES = [
    ("BlockzillaPackage/Sources/Onboarding/DesignSystem/Images.xcassets/Contents.json", 63, "0fd49ba3c3585c709678e0046a821c3c60685ec7063720d30d3a3448be3a208b"),
    ("BlockzillaPackage/Sources/Onboarding/DesignSystem/Images.xcassets/icon_background.imageset/Contents.json", 383, "01a9f5fb7f0717f820013c1ff82c89fcbf77f0952fa665c34ffd5a63538b0e90"),
    ("BlockzillaPackage/Sources/Onboarding/DesignSystem/Images.xcassets/icon_background.imageset/background_icon_dark.pdf", 2852, "659590ff0bfc50927743b27e28a25583bf46678ccb886b049b9f3f0a844f5c3c"),
    ("BlockzillaPackage/Sources/Onboarding/DesignSystem/Images.xcassets/icon_background.imageset/icon_onboarding_background.pdf", 6534, "4b692c91c4a07791c9dff2d126a0aa719b6d0889722b5425212ba062be1ff7ff"),
    ("BlockzillaPackage/Sources/Onboarding/DesignSystem/Images.xcassets/icon_close.imageset/Contents.json", 363, "6143715bb2f2f4abee1061203a3492f14f8d8d78fd6dcae86e47e20443b14e51"),
    ("BlockzillaPackage/Sources/Onboarding/DesignSystem/Images.xcassets/icon_close.imageset/icon_close.pdf", 15783951, "7b9a395c042caa6a672904996b47c3f39ec44ab73feeff15b36a52fba2b43ac0"),
    ("BlockzillaPackage/Sources/Onboarding/DesignSystem/Images.xcassets/icon_close.imageset/icon_close_light.pdf", 15783269, "823a5bbbc12991b832eea10f1bc131d383f7745ad4eeb63aabbd913f5fd20759"),
    ("BlockzillaPackage/Sources/Onboarding/DesignSystem/Images.xcassets/icon_hugging_focus.imageset/Contents.json", 231, "e038476d7b10572d42fc202000943cca7016cc2997d0ad0396d9eb552491224d"),
    ("BlockzillaPackage/Sources/Onboarding/DesignSystem/Images.xcassets/icon_hugging_focus.imageset/HuggingFocus.pdf", 123975, "0cea10117ec887aac52aa50c4e044b12124c817d19ef951497d0c2698de4e4bc"),
    ("BlockzillaPackage/Sources/Onboarding/DesignSystem/Images.xcassets/icon_logo.imageset/Contents.json", 159, "b4a48ee46b1087f15188dc0a4cdf065251008e51e44427b1bb94f0744085eb79"),
    ("BlockzillaPackage/Sources/Onboarding/DesignSystem/Images.xcassets/icon_logo.imageset/icon_logo.pdf", 71525, "7f8ea654a4d0ac064fb38027c16ae730b1f0561a031bb465b71997b0df4188b7"),
    ("BlockzillaPackage/Sources/Onboarding/DesignSystem/Images.xcassets/jiggle_mode_image.imageset/Contents.json", 160, "a228447d3cac984c73c61de2da481a0fb3f298e2dc44a18ec2947cd3f0275f0d"),
    ("BlockzillaPackage/Sources/Onboarding/DesignSystem/Images.xcassets/jiggle_mode_image.imageset/JiggleMode.pdf", 579470, "0dc9330222df238758512ed9aa5a6b8c6a9d69d3913382e67fad187d33f88929"),
]
WIDGET_FILES = [
    ("BlockzillaPackage/Sources/Widget/Media.xcassets/Contents.json", 63, "0fd49ba3c3585c709678e0046a821c3c60685ec7063720d30d3a3448be3a208b"),
    ("BlockzillaPackage/Sources/Widget/Media.xcassets/GradientFirst.colorset/Contents.json", 692, "75759bdc8a68e4694bda34486c47e347ab8af010ebb8de7372b0ca443c08186b"),
    ("BlockzillaPackage/Sources/Widget/Media.xcassets/GradientSecond.colorset/Contents.json", 692, "f71bc94e686809660d920da6f7804174097e038302a843c3533da45ceda44af2"),
    ("BlockzillaPackage/Sources/Widget/Media.xcassets/icon_logo.imageset/Contents.json", 159, "b4a48ee46b1087f15188dc0a4cdf065251008e51e44427b1bb94f0744085eb79"),
    ("BlockzillaPackage/Sources/Widget/Media.xcassets/icon_logo.imageset/icon_logo.pdf", 71525, "7f8ea654a4d0ac064fb38027c16ae730b1f0561a031bb465b71997b0df4188b7"),
]
LOOKUP_SOURCES = [
    ("BlockzillaPackage/Sources/Onboarding/DesignSystem/Color+AppColors.swift", 852, "d64850a384db3bfc2961cad6f7b1d9d3522f081fa19709462c11f41893615e81"),
    ("BlockzillaPackage/Sources/Onboarding/DesignSystem/Image+AppImages.swift", 806, "d6731252dc45289bc513b17cf1b4ba78e7c56b399e1b6a5942c8d1352b35ae54"),
    ("BlockzillaPackage/Sources/Widget/Assets.swift", 533, "efac8d1c98b562374e54eea7540b4201523db670a6353eff8f0a0273d294526e"),
]

CATALOGS = {
    "onboarding-colors": {
        "root": "BlockzillaPackage/Sources/Onboarding/DesignSystem/Colors.xcassets",
        "files": ONBOARDING_COLOR_FILES,
        "file_count": 5,
        "byte_count": 2456,
        "digest": "b2168510bd9d7b2325f9bfdde956a07475be6610259e29f5f8b43072cd8d6998",
    },
    "onboarding-images": {
        "root": "BlockzillaPackage/Sources/Onboarding/DesignSystem/Images.xcassets",
        "files": ONBOARDING_IMAGE_FILES,
        "file_count": 13,
        "byte_count": 32352935,
        "digest": "f2fcaa1fae4e8b71b4104cf5673b955df2711b8004d6a928861f5d86601bf0fd",
    },
    "widget-media": {
        "root": "BlockzillaPackage/Sources/Widget/Media.xcassets",
        "files": WIDGET_FILES,
        "file_count": 5,
        "byte_count": 73131,
        "digest": "cf65ea586b104d622bb50ec5f0c09a1dc11ec0f293d322776dbb6f698f880126",
    },
}

PDF_MAPPINGS = [
    ("Onboarding", "icon_background", "default", "BlockzillaPackage/Sources/Onboarding/DesignSystem/Images.xcassets/icon_background.imageset/icon_onboarding_background.pdf", [375.0, 810.0]),
    ("Onboarding", "icon_background", "dark", "BlockzillaPackage/Sources/Onboarding/DesignSystem/Images.xcassets/icon_background.imageset/background_icon_dark.pdf", [375.0, 810.0]),
    ("Onboarding", "icon_close", "default", "BlockzillaPackage/Sources/Onboarding/DesignSystem/Images.xcassets/icon_close.imageset/icon_close_light.pdf", [30.0, 30.0]),
    ("Onboarding", "icon_close", "dark", "BlockzillaPackage/Sources/Onboarding/DesignSystem/Images.xcassets/icon_close.imageset/icon_close.pdf", [30.0, 30.0]),
    ("Onboarding", "icon_hugging_focus", "default", "BlockzillaPackage/Sources/Onboarding/DesignSystem/Images.xcassets/icon_hugging_focus.imageset/HuggingFocus.pdf", [193.651, 300.0]),
    ("Onboarding", "icon_logo", "default", "BlockzillaPackage/Sources/Onboarding/DesignSystem/Images.xcassets/icon_logo.imageset/icon_logo.pdf", [145.094, 150.0]),
    ("Onboarding", "jiggle_mode_image", "default", "BlockzillaPackage/Sources/Onboarding/DesignSystem/Images.xcassets/jiggle_mode_image.imageset/JiggleMode.pdf", [261.0, 147.0]),
    ("Widget", "icon_logo", "default", "BlockzillaPackage/Sources/Widget/Media.xcassets/icon_logo.imageset/icon_logo.pdf", [145.094, 150.0]),
]

COLOR_MAPPINGS = {
    "Onboarding": {
        "catalog": "onboarding-colors",
        "names": ["actionButton", "secondOnboardingScreenBackground", "secondOnboardingScreenBottomButton", "secondOnboardingScreenText"],
    },
    "Widget": {"catalog": "widget-media", "names": ["GradientFirst", "GradientSecond"]},
}
SYMBOL_MAPPINGS = {
    "Onboarding": ["1.circle.fill", "2.circle.fill", "3.circle.fill"],
    "Widget": ["magnifyingglass"],
}
SYMBOL_OVERLAY_ALIASES = {
    "Onboarding": {
        "1.circle.fill": "step_one",
        "2.circle.fill": "step_two",
        "3.circle.fill": "step_three",
    },
    "Widget": {"magnifyingglass": "icon_magnifying_glass"},
}
LOOKUP_CONTRACT = {
    "Onboarding": {
        "colors": COLOR_MAPPINGS["Onboarding"]["names"],
        "images": ["icon_background", "icon_close", "icon_hugging_focus", "icon_logo", "jiggle_mode_image"],
        "symbols": SYMBOL_MAPPINGS["Onboarding"],
    },
    "Widget": {
        "colors": COLOR_MAPPINGS["Widget"]["names"],
        "images": ["icon_logo"],
        "symbols": SYMBOL_MAPPINGS["Widget"],
    },
}

RASTERIZER_PROFILES = [
    {
        "id": "homebrew-poppler-25.04.0-darwin-arm64",
        "system": "Darwin",
        "machine": "arm64",
        "path": "/opt/homebrew/Cellar/poppler/25.04.0/bin/pdftocairo",
        "size": 225664,
        "sha256": "963b05a5c78b2a8a32bbfb9a2a3c542a258dd7ec8e9b64d782a4d9848ed058c1",
        "version_sha256": "a78b264de5df5bd46533719094cbfc5bc61fcf339816d5c30d3cd67a036d72d5",
    },
    {
        "id": "ubuntu-noble-poppler-24.02.0-1ubuntu9.9-linux-aarch64",
        "system": "Linux",
        "machine": "aarch64",
        "path": "/usr/bin/pdftocairo",
        "size": 198904,
        "sha256": "dec6518985e0810a886ac53a3293f2d49cf292621874501ab0a821eff666e41f",
        "version_sha256": "334b226b04b408c69f0cdddd748b566360c34853bf5edddc7f0c808a4f67d559",
    },
]

# Independently reproduced byte-for-byte with Homebrew Poppler 25.04.0 on
# macOS/arm64 and Ubuntu Noble Poppler 24.02.0-1ubuntu9.9 on Linux/aarch64.
# Values are (byte count, SHA-256, pixel width, pixel height). Full decoded RGBA
# and alpha metrics are recomputed, audited, and transitively fixed by the file
# SHA-256 without making this reviewed table needlessly repetitive.
EXPECTED_PDF_OUTPUTS = {
    "Onboarding/icon_background/dark/1x": (16655, "3574155e662c0b41111af8abb3894ea2a8e70cc0ffc7159a7e91e5f8659ce42c", 375, 810),
    "Onboarding/icon_background/dark/2x": (62424, "8c41108f8fb18b5dc8bc7af8a682a90b9252479c5440696b437fe623aa599d87", 750, 1620),
    "Onboarding/icon_background/dark/3x": (144080, "e014859d3da1db60cc2beaeb47fc2ac65af55a621228d6c98a6e160d6bd38c20", 1125, 2430),
    "Onboarding/icon_background/default/1x": (2661, "4fd236935d280cd303212406e40974dc06f4edfc43f7f42570b8e0f8e0335a93", 375, 810),
    "Onboarding/icon_background/default/2x": (7553, "9ca45e41656b502088140215d2803980a32e2441248ad7ba16b5e8d078c3c54a", 750, 1620),
    "Onboarding/icon_background/default/3x": (16508, "10840a4aa860d00f81d026460f4f5f20b79abdc89990ada4291eed6c408bd317", 1125, 2430),
    "Onboarding/icon_close/dark/1x": (953, "0ad4478107e03ae957d27e7f289f33383ba020c19cf991fd0d0e112035a2ac09", 30, 30),
    "Onboarding/icon_close/dark/2x": (1747, "ca3f7f276c1ee79d56f8c7fd4e0fe91e01069e59d67d4d80d77a152c1dbf68d2", 60, 60),
    "Onboarding/icon_close/dark/3x": (2535, "0f0e8eb87af25c26ad70b6544357df27d336d21069cedb36c084e0c104873594", 90, 90),
    "Onboarding/icon_close/default/1x": (867, "b8e41d2147e533f7e91897d611accc40485aae6345c4baf7fb0fed8865abab52", 30, 30),
    "Onboarding/icon_close/default/2x": (1506, "5aee351253c7609c544408c1909f5ced2591935f5e5fded16961fd160cddbbaa", 60, 60),
    "Onboarding/icon_close/default/3x": (2174, "d0b0832698c1b7d54b95906a658e166dffba80463b712e45c20c3c960db1ee6f", 90, 90),
    "Onboarding/icon_hugging_focus/default/1x": (42303, "c1acdd1c9ee819dcbe4645906aef4042a31e9073e34aa88b7510091f746e2f69", 194, 300),
    "Onboarding/icon_hugging_focus/default/2x": (104637, "e05baa50d724a14691e8204ecd4ff290d9f1d7d9b6dcfb17920c3dece9d07ae2", 388, 600),
    "Onboarding/icon_hugging_focus/default/3x": (176613, "bfad78236f53600885dbe738c15d8ba26310bf2a23f8c825b799113c509d0965", 581, 900),
    "Onboarding/icon_logo/default/1x": (19130, "180d76a144c6e74324283e8bfb72d9d7bb32125fe57769e3403b0ca72b6ef415", 146, 150),
    "Onboarding/icon_logo/default/2x": (52496, "5acd6ff3214009dd583d37fead8eaada34d69049cb14202d18103c2d5f84dd7f", 291, 300),
    "Onboarding/icon_logo/default/3x": (91082, "cc0a1e50c01c13fd3315fbd14a89ebb521bedf9ebc21bf511c73e2e6c4305942", 436, 450),
    "Onboarding/jiggle_mode_image/default/1x": (38099, "5ed6eddfd91aea96aed2f9d3147dce77a8b7a8c8c13ec8f8cb09d20c176064bd", 261, 147),
    "Onboarding/jiggle_mode_image/default/2x": (129963, "2413282f3d90f52ddf989c5f9edf3847aa6930abbf87cb68dd29d81a0e95be1c", 522, 294),
    "Onboarding/jiggle_mode_image/default/3x": (262268, "2a9352b29a03d278ed0fb7be1aaaf96d65224d0839082323e2d3dd404316ae62", 783, 441),
    "Widget/icon_logo/default/1x": (19130, "180d76a144c6e74324283e8bfb72d9d7bb32125fe57769e3403b0ca72b6ef415", 146, 150),
    "Widget/icon_logo/default/2x": (52496, "5acd6ff3214009dd583d37fead8eaada34d69049cb14202d18103c2d5f84dd7f", 291, 300),
    "Widget/icon_logo/default/3x": (91082, "cc0a1e50c01c13fd3315fbd14a89ebb521bedf9ebc21bf511c73e2e6c4305942", 436, 450),
}
EXPECTED_SYMBOL_OUTPUTS = {
    "Onboarding/1.circle.fill/default/1x": (2409, "8b4b9a661d879a64a8e3fd92a9a5ea00ac4b8097c5577b174f1db8ffbc6120c0", 24, 24),
    "Onboarding/1.circle.fill/default/2x": (9345, "e7736ae4dc7afd77b011838c57d07cd39ba25e5a4680c33b72f5d4423ccae3fc", 48, 48),
    "Onboarding/1.circle.fill/default/3x": (20889, "f728524938e4404b2521daccee89f783b94a9d519378730667f3091c9b249876", 72, 72),
    "Onboarding/2.circle.fill/default/1x": (2409, "a5809e9af5455b2662c78fef69229288e8769340a5dee357a936233186ec2ab6", 24, 24),
    "Onboarding/2.circle.fill/default/2x": (9345, "7a4b24ad813346f098b35e2e2c206568364d213a1970aa62674c499b0f630a9b", 48, 48),
    "Onboarding/2.circle.fill/default/3x": (20889, "60e4df12a3e7e5fba3219d2409be6aefc8aafae73688a85d135c03bea7e969ff", 72, 72),
    "Onboarding/3.circle.fill/default/1x": (2409, "931c9eac1b4ff11343b098351f7b2b6d68920bd494bc1fb3809c874848f0f4bc", 24, 24),
    "Onboarding/3.circle.fill/default/2x": (9345, "faf21052f97e93b8b2d3c67a6d42dc65c4d5c5ae1ddf276a3154e6f716d4d0b4", 48, 48),
    "Onboarding/3.circle.fill/default/3x": (20889, "a35f04da5cae290c7257c96201fe0c89fca8b21e985a430672bd1545b633d96b", 72, 72),
    "Widget/magnifyingglass/default/1x": (2409, "ac28495c9ca12a541302d9a1ab9b7a2e19aa765c6e9f03cf0e55169fb5bd983e", 24, 24),
    "Widget/magnifyingglass/default/2x": (9345, "9077434adde7ac6ccb49842aa8cd76257e40e35db739592aa9c059a01f1cc33c", 48, 48),
    "Widget/magnifyingglass/default/3x": (20889, "b670deab128d1f3ae181f985448b8f423081f5c6c673a910e581087cffbbb066", 72, 72),
}


class ProofError(RuntimeError):
    """The requested proof is outside the reviewed subject or claim boundary."""


@lru_cache(maxsize=1)
def _darwin_acl_functions() -> tuple[Any, Any]:
    libc = ctypes.CDLL(None, use_errno=True)
    acl_get_link = libc.acl_get_link_np
    acl_get_link.argtypes = (ctypes.c_char_p, ctypes.c_int)
    acl_get_link.restype = ctypes.c_void_p
    acl_free = libc.acl_free
    acl_free.argtypes = (ctypes.c_void_p,)
    acl_free.restype = ctypes.c_int
    return acl_get_link, acl_free


def _has_extended_acl(path: Path) -> bool:
    if sys.platform != "darwin":
        return False
    acl_get_link, acl_free = _darwin_acl_functions()
    ctypes.set_errno(0)
    acl = acl_get_link(os.fsencode(path), DARWIN_ACL_TYPE_EXTENDED)
    if not acl:
        error = ctypes.get_errno()
        if error == errno.ENOENT:
            return False
        raise ProofError(f"cannot inspect extended ACL for {path}: errno {error}")
    try:
        return True
    finally:
        if acl_free(acl) != 0:
            raise ProofError(f"cannot release extended ACL inspection for {path}")


@dataclass(frozen=True)
class CapturedFile:
    path: str
    data: bytes

    def record(self) -> dict[str, Any]:
        return {"path": self.path, "size": len(self.data), "sha256": sha256(self.data)}


@dataclass(frozen=True)
class FocusCapture:
    commit: str
    ignored_untracked_file_count: int
    ignored_untracked_state_sha256: str
    index_state_sha256: str
    status_sha256: str
    manifest: CapturedFile
    catalog_files: tuple[CapturedFile, ...]
    lookup_sources: tuple[CapturedFile, ...]

    def by_path(self) -> dict[str, CapturedFile]:
        return {item.path: item for item in (self.manifest, *self.catalog_files, *self.lookup_sources)}

    def identity(self) -> bytes:
        return canonical_json({
            "commit": self.commit,
            "ignored_untracked_file_count": self.ignored_untracked_file_count,
            "ignored_untracked_state_sha256": self.ignored_untracked_state_sha256,
            "index_state_sha256": self.index_state_sha256,
            "status_sha256": self.status_sha256,
            "manifest": self.manifest.record(),
            "catalog_files": [item.record() for item in self.catalog_files],
            "lookup_sources": [item.record() for item in self.lookup_sources],
        })


@dataclass(frozen=True)
class Rasterizer:
    profile: dict[str, Any]
    version: bytes
    loader_report: bytes

    def audit(self) -> dict[str, Any]:
        return {
            "profile": dict(self.profile),
            "version": self.version.decode("utf-8", errors="strict").splitlines(),
            "version_sha256": sha256(self.version),
            "loader_report": self.loader_report.decode("utf-8", errors="replace").splitlines(),
            "loader_report_sha256": sha256(self.loader_report),
            "loader_report_address_normalization": "Linux parenthesized ASLR load addresses replaced; remaining reported install names and paths preserved",
            "provenance_scope": {
                "dependency_bytes_hashed": False,
                "executable_bytes": "size and SHA-256 observed at each discovery",
                "install_name_report": "observed at each discovery; not a dependency-byte attestation",
                "path_continuously_attested_between_discoveries": False,
                "version_report": "SHA-256 observed at each discovery",
            },
            "environment": dict(SAFE_ENVIRONMENT),
        }


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def canonical_json(value: Any) -> bytes:
    return (json.dumps(value, indent=2, sort_keys=True) + "\n").encode("utf-8")


def file_record(path: Path, relative: str) -> dict[str, Any]:
    data = path.read_bytes()
    return {"path": relative, "size": len(data), "sha256": sha256(data)}


def records_digest(records: Iterable[tuple[str, bytes]]) -> str:
    aggregate = hashlib.sha256()
    for path, data in sorted(records, key=lambda item: item[0].encode("utf-8")):
        aggregate.update(path.encode("utf-8"))
        aggregate.update(b"\0")
        aggregate.update(str(len(data)).encode("ascii"))
        aggregate.update(b"\0")
        aggregate.update(sha256(data).encode("ascii"))
        aggregate.update(b"\n")
    return aggregate.hexdigest()


def _output_records_digest(output: Path, records: Iterable[dict[str, Any]]) -> str:
    return records_digest((record["path"], _read_regular_nofollow(output / record["path"])) for record in records)


def generator_runtime_audit() -> dict[str, Any]:
    script = Path(__file__).resolve(strict=True)
    interpreter = Path(sys.executable).resolve(strict=True)
    script_data = _read_regular_nofollow(script)
    interpreter_data = _read_regular_nofollow(interpreter)
    version = sys.version.encode("utf-8")
    return {
        "script": {"path": str(script), "size": len(script_data), "sha256": sha256(script_data)},
        "python": {
            "path": str(interpreter),
            "size": len(interpreter_data),
            "sha256": sha256(interpreter_data),
            "implementation": platform.python_implementation(),
            "version": sys.version.splitlines(),
            "version_sha256": sha256(version),
            "byteorder": sys.byteorder,
        },
        "png_inspection_zlib": {"compile_version": zlib.ZLIB_VERSION, "runtime_version": zlib.ZLIB_RUNTIME_VERSION},
        "symbol_encoder": "integer geometry + in-script RFC 1950/1951 stored-block encoder; zlib not used for output encoding",
    }


def _record(path: str, size: int, digest: str) -> dict[str, Any]:
    return {"path": path, "size": size, "sha256": digest}


def _mapping_record(item: tuple[str, str, str, str, list[float]]) -> dict[str, Any]:
    target, name, appearance, source, page_points = item
    return {"target": target, "name": name, "appearance": appearance, "source": source, "page_points": page_points}


def _reviewed_output_records(compact: dict[str, tuple[int, str, int, int]], *, symbols: bool) -> dict[str, dict[str, Any]]:
    records: dict[str, dict[str, Any]] = {}
    for key, (size, digest, width, height) in compact.items():
        target, name, appearance, scale_text = key.split("/")
        scale = int(scale_text.removesuffix("x"))
        path = _symbol_output_path(target, name, scale) if symbols else _pdf_output_path(target, name, appearance, scale)
        records[key] = {"path": path, "size": size, "sha256": digest, "width": width, "height": height}
    return records


def expected_policy() -> dict[str, Any]:
    catalogs: dict[str, Any] = {}
    for name, catalog in CATALOGS.items():
        catalogs[name] = {
            "root": catalog["root"],
            "file_count": catalog["file_count"],
            "byte_count": catalog["byte_count"],
            "source_digest": catalog["digest"],
            "files": [_record(*item) for item in catalog["files"]],
        }
    return {
        "schema": 1,
        "claims": {
            "actool_or_asset_car_emission": False,
            "apple_bundle_equivalence": False,
            "cross_host_reproducibility": "bounded-to-exact-reviewed-outputs-on-two-observed-front-end-profiles",
            "foundation_or_ui_framework_runtime_lookup": False,
            "current_openuikit_automatic_luminosity_image_selection": False,
            "current_openuikit_loose_image_layout": True,
            "current_openuikit_system_symbol_api": False,
            "linux_guest_link_or_run": False,
            "normalized_resource_bundle_and_lookup_index": True,
            "rasterizer_dependency_byte_identity": False,
            "rasterizer_path_immutability_during_rendering": False,
            "raw_color_catalogs_preserved": True,
        },
        "focus": {
            "commit": FOCUS_COMMIT,
            "worktree_prefix": FOCUS_PREFIX,
            "package_manifest": dict(MANIFEST),
            "pinned_manifest_resource_declaration": "raw-unhandled",
        },
        "catalogs": catalogs,
        "lookup_sources": [_record(*item) for item in LOOKUP_SOURCES],
        "lookup_contract": json.loads(json.dumps(LOOKUP_CONTRACT)),
        "normalization": {
            "dpi_per_scale": DPI_PER_SCALE,
            "scales": list(SCALES),
            "pdf_command_flags": ["-png", "-transp", "-singlefile", "-r", "<72*scale>"],
            "pdf_mappings": [_mapping_record(item) for item in PDF_MAPPINGS],
            "pdf_outputs": _reviewed_output_records(EXPECTED_PDF_OUTPUTS, symbols=False),
            "symbol_generator": {
                "kind": "original-integer-geometry-alpha-mask",
                "logical_size_points": [24, 24],
                "supersample": 8,
                "png_deflate": "RFC1951 stored blocks with fixed filter 0",
            },
            "symbol_mappings": json.loads(json.dumps(SYMBOL_MAPPINGS)),
            "symbol_overlay_aliases": json.loads(json.dumps(SYMBOL_OVERLAY_ALIASES)),
            "symbol_outputs": _reviewed_output_records(EXPECTED_SYMBOL_OUTPUTS, symbols=True),
        },
        "rasterizer_profiles": json.loads(json.dumps(RASTERIZER_PROFILES)),
        "bundle_layout": {
            "root": "bundles",
            "onboarding": "Focus_Onboarding.bundle",
            "widget": "Focus_Widget.bundle",
            "index": "resource-index.json",
            "lookup_semantics": "explicit-index-with-dark-to-default-appearance-fallback",
        },
    }


def _validate_relative(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value:
        raise ProofError(f"{label} must be a non-empty string")
    if "\\" in value or any(character in value for character in ("\0", "\n", "\r")):
        raise ProofError(f"{label} contains a forbidden character")
    path = PurePosixPath(value)
    if path.is_absolute() or path.as_posix() != value or any(part in ("", ".", "..") for part in path.parts):
        raise ProofError(f"{label} is not a normalized relative POSIX path: {value!r}")
    return value


def _validate_file_record(value: Any, label: str) -> None:
    if not isinstance(value, dict) or set(value) != {"path", "size", "sha256"}:
        raise ProofError(f"{label} is not an exact file record")
    _validate_relative(value["path"], f"{label}.path")
    if type(value["size"]) is not int or value["size"] < 0:
        raise ProofError(f"{label}.size must be a non-negative integer")
    if not isinstance(value["sha256"], str) or not SHA256_RE.fullmatch(value["sha256"]):
        raise ProofError(f"{label}.sha256 must be lowercase SHA-256")


def validate_policy(policy: Any) -> None:
    expected = expected_policy()
    if not isinstance(policy, dict) or policy != expected:
        raise ProofError("policy no longer equals the reviewed Focus resource policy")
    if type(policy["schema"]) is not int or policy["schema"] != 1:
        raise ProofError("policy schema changed")
    if not COMMIT_RE.fullmatch(policy["focus"]["commit"]):
        raise ProofError("Focus commit is not a full lowercase object id")
    _validate_file_record(policy["focus"]["package_manifest"], "focus.package_manifest")
    for catalog_name, catalog in policy["catalogs"].items():
        _validate_relative(catalog["root"], f"catalogs.{catalog_name}.root")
        for index, record in enumerate(catalog["files"]):
            _validate_file_record(record, f"catalogs.{catalog_name}.files[{index}]")
    for index, record in enumerate(policy["lookup_sources"]):
        _validate_file_record(record, f"lookup_sources[{index}]")
    if not EXPECTED_PDF_OUTPUTS or not EXPECTED_SYMBOL_OUTPUTS:
        raise ProofError("reviewed output hashes have not been populated")


def load_policy(path: Path) -> tuple[bytes, dict[str, Any]]:
    raw = path.read_bytes()
    try:
        policy = json.loads(raw)
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ProofError(f"policy is not canonical JSON: {error}") from error
    validate_policy(policy)
    if raw != canonical_json(policy):
        raise ProofError("policy JSON is not canonical")
    return raw, policy


def _run(command: list[str], *, cwd: Path | None = None, environment: dict[str, str] | None = None) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        command,
        cwd=cwd,
        env=environment or SAFE_ENVIRONMENT,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )


def _git(repo: Path, arguments: list[str]) -> bytes:
    result = _run(["/usr/bin/git", "-c", "core.fsmonitor=false", "-c", f"core.hooksPath={os.devnull}", "-C", str(repo), *arguments], environment=GIT_ENVIRONMENT)
    if result.returncode != 0:
        detail = result.stderr.decode("utf-8", errors="replace").strip()
        raise ProofError(f"git {' '.join(arguments)} failed: {detail}")
    return result.stdout


def _read_regular_nofollow(path: Path) -> bytes:
    descriptor = os.open(path, os.O_RDONLY | NOFOLLOW)
    try:
        metadata = os.fstat(descriptor)
        if not stat.S_ISREG(metadata.st_mode):
            raise ProofError(f"input is not a regular file: {path}")
        chunks: list[bytes] = []
        while True:
            chunk = os.read(descriptor, 1024 * 1024)
            if not chunk:
                break
            chunks.append(chunk)
        data = b"".join(chunks)
        if len(data) != metadata.st_size:
            raise ProofError(f"input size changed while reading: {path}")
        return data
    finally:
        os.close(descriptor)


def _filesystem_inventory(root: Path) -> list[str]:
    if root.is_symlink() or not root.is_dir():
        raise ProofError(f"catalog root is not a real directory: {root}")
    result: list[str] = []
    for current, directories, files in os.walk(root, followlinks=False):
        current_path = Path(current)
        for directory in directories:
            if (current_path / directory).is_symlink():
                raise ProofError(f"symlink in catalog inventory: {current_path / directory}")
        for filename in files:
            path = current_path / filename
            if path.is_symlink() or not path.is_file():
                raise ProofError(f"non-regular catalog entry: {path}")
            result.append(path.as_posix())
    return sorted(result, key=lambda item: item.encode("utf-8"))


def _capture_record(repo: Path, top: Path, expected: dict[str, Any]) -> CapturedFile:
    relative = expected["path"]
    live = _read_regular_nofollow(repo / relative)
    blob = _git(top, ["show", f"{FOCUS_COMMIT}:{FOCUS_PREFIX}/{relative}"])
    if live != blob:
        raise ProofError(f"worktree bytes differ from the pinned blob: {relative}")
    record = {"path": relative, "size": len(live), "sha256": sha256(live)}
    if record != expected:
        raise ProofError(f"pinned input bytes changed: {relative}")
    return CapturedFile(relative, live)


def capture_focus(repo: Path, policy: dict[str, Any]) -> FocusCapture:
    repo = repo.resolve(strict=True)
    top = Path(_git(repo, ["rev-parse", "--show-toplevel"]).decode("utf-8", errors="strict").strip()).resolve(strict=True)
    try:
        prefix = repo.relative_to(top).as_posix()
    except ValueError as error:
        raise ProofError("Focus worktree is outside its Git top level") from error
    if prefix != policy["focus"]["worktree_prefix"]:
        raise ProofError(f"Focus worktree prefix changed: {prefix!r}")
    commit = _git(top, ["rev-parse", "HEAD^{commit}"]).decode("ascii").strip()
    if commit != FOCUS_COMMIT:
        raise ProofError(f"Focus HEAD changed: {commit}")
    status = _git(top, ["status", "--porcelain=v1", "-z", "--untracked-files=all"])
    if status:
        raise ProofError("Focus worktree is not clean")
    ignored_untracked = _git(
        top,
        ["ls-files", "--others", "--ignored", "--exclude-standard", "-z"],
    )
    ignored_untracked_files = [record for record in ignored_untracked.split(b"\0") if record]
    if ignored_untracked_files:
        raise ProofError(
            f"Focus worktree contains {len(ignored_untracked_files)} ignored untracked file(s)"
        )
    index_state = _git(top, ["ls-files", "-v", "-z"])
    flagged = [record for record in index_state.split(b"\0") if record and not record.startswith(b"H ")]
    if flagged:
        raise ProofError("Focus index carries assume-unchanged or skip-worktree visibility flags")

    catalog_records: list[dict[str, Any]] = []
    for name in sorted(policy["catalogs"]):
        catalog = policy["catalogs"][name]
        expected_paths = sorted((repo / item["path"]).as_posix() for item in catalog["files"])
        actual_paths = _filesystem_inventory(repo / catalog["root"])
        if actual_paths != expected_paths:
            raise ProofError(f"catalog filesystem inventory changed: {name}")
        tree_prefix = f"{FOCUS_PREFIX}/{catalog['root']}"
        committed = _git(top, ["ls-tree", "-r", "--name-only", FOCUS_COMMIT, "--", tree_prefix]).decode("utf-8", errors="strict").splitlines()
        expected_committed = [f"{FOCUS_PREFIX}/{item['path']}" for item in catalog["files"]]
        if sorted(committed) != sorted(expected_committed):
            raise ProofError(f"catalog committed inventory changed: {name}")
        catalog_records.extend(catalog["files"])

    manifest = _capture_record(repo, top, policy["focus"]["package_manifest"])
    catalog_files = tuple(_capture_record(repo, top, item) for item in sorted(catalog_records, key=lambda item: item["path"]))
    lookup_sources = tuple(_capture_record(repo, top, item) for item in policy["lookup_sources"])
    return FocusCapture(
        commit,
        len(ignored_untracked_files),
        sha256(ignored_untracked),
        sha256(index_state),
        sha256(status),
        manifest,
        catalog_files,
        lookup_sources,
    )


def _resolve_new_output(raw: str, forbidden_roots: Iterable[Path] = ()) -> Path:
    requested = Path(raw).absolute()
    if requested.exists() or requested.is_symlink():
        raise ProofError(f"stale proof output is refused: {requested}")
    parent = requested.parent.resolve(strict=True)
    output = parent / requested.name
    if output.exists() or output.is_symlink():
        raise ProofError(f"stale proof output is refused: {output}")
    for raw_root in forbidden_roots:
        root = raw_root.resolve(strict=True)
        if output == root or output.is_relative_to(root):
            raise ProofError(f"proof output must be outside source and policy repositories: {output}")
    _verify_safe_output_parent(parent)
    output.mkdir(mode=0o700)
    return output


def _repository_top(path: Path) -> Path:
    value = _git(path, ["rev-parse", "--show-toplevel"]).decode("utf-8", errors="strict").strip()
    return Path(value).resolve(strict=True)


def _verify_safe_output_parent(parent: Path) -> None:
    effective_uid = os.geteuid()
    metadata = parent.stat()
    mode = stat.S_IMODE(metadata.st_mode)
    if metadata.st_uid != effective_uid or mode & 0o077:
        raise ProofError(
            "proof output parent must be owned by the current user and private mode 0700"
        )
    child = parent
    while True:
        if _has_extended_acl(child):
            raise ProofError(f"proof output ancestor carries an extended ACL: {child}")
        container = child.parent
        if container == child:
            break
        container_metadata = container.stat()
        container_mode = stat.S_IMODE(container_metadata.st_mode)
        if container_metadata.st_uid not in (0, effective_uid):
            raise ProofError(f"proof output ancestor has an untrusted owner: {container}")
        if container_mode & 0o022:
            sticky = bool(container_metadata.st_mode & stat.S_ISVTX)
            protected_child = child.stat().st_uid == effective_uid
            if not (sticky and protected_child):
                raise ProofError(
                    f"proof output ancestor permits cross-UID replacement: {container}"
                )
        child = container


def _write_exclusive(path: Path, data: bytes, label: str) -> None:
    path.parent.mkdir(mode=0o755, parents=True, exist_ok=True)
    try:
        descriptor = os.open(
            path,
            os.O_WRONLY | os.O_CREAT | os.O_EXCL | NOFOLLOW,
            0o644,
        )
    except OSError as error:
        raise ProofError(f"cannot create {label} {path}: {error}") from error
    try:
        view = memoryview(data)
        while view:
            written = os.write(descriptor, view)
            if written <= 0:
                raise ProofError(f"short write while creating {label}: {path}")
            view = view[written:]
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


def stage_inputs(output: Path, capture: FocusCapture) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for item in (capture.manifest, *capture.catalog_files, *capture.lookup_sources):
        relative = f"inputs/{FOCUS_PREFIX}/{item.path}"
        destination = output / relative
        _write_exclusive(destination, item.data, "staged Focus resource input")
        records.append({"source_path": item.path, "stage_path": relative, "size": len(item.data), "sha256": sha256(item.data)})
    _seal_staged_inputs(output)
    return records


def _seal_staged_inputs(output: Path) -> None:
    root = output / "inputs"
    if root.is_symlink() or not root.is_dir():
        raise ProofError("staged input root is missing or unsafe")
    for current, directories, files in os.walk(root, topdown=False, followlinks=False):
        current_path = Path(current)
        for name in files:
            candidate = current_path / name
            if candidate.is_symlink() or not candidate.is_file():
                raise ProofError(f"staged input is not a regular file: {candidate}")
            candidate.chmod(0o444)
        for name in directories:
            candidate = current_path / name
            if candidate.is_symlink() or not candidate.is_dir():
                raise ProofError(f"staged input is not a directory: {candidate}")
            candidate.chmod(0o555)
    root.chmod(0o555)


def _verify_staged_input_isolation(output: Path) -> None:
    metadata = output.stat()
    if metadata.st_uid != os.geteuid() or stat.S_IMODE(metadata.st_mode) != 0o700:
        raise ProofError("resource proof output root is not private mode 0700")
    if _has_extended_acl(output):
        raise ProofError("resource proof output root carries an extended ACL")
    root = output / "inputs"
    for current, directories, files in os.walk(root, followlinks=False):
        current_path = Path(current)
        if _has_extended_acl(current_path):
            raise ProofError(f"staged input directory carries an extended ACL: {current_path}")
        if stat.S_IMODE(current_path.stat().st_mode) & 0o222:
            raise ProofError(f"staged input directory became writable: {current_path}")
        for name in (*directories, *files):
            candidate = current_path / name
            if candidate.is_symlink():
                raise ProofError(f"staged input tree contains a symlink: {candidate}")
            if _has_extended_acl(candidate):
                raise ProofError(f"staged input carries an extended ACL: {candidate}")
            if stat.S_IMODE(candidate.stat().st_mode) & 0o222:
                raise ProofError(f"staged input became writable: {candidate}")


def verify_staged_inputs(output: Path, capture: FocusCapture, records: list[dict[str, Any]]) -> None:
    _verify_staged_input_isolation(output)
    expected = capture.by_path()
    expected_stage_paths = {f"inputs/{FOCUS_PREFIX}/{path}" for path in expected}
    actual_paths = {
        path.relative_to(output).as_posix()
        for path in (output / "inputs").rglob("*")
        if path.is_file()
    }
    if actual_paths != expected_stage_paths:
        raise ProofError("staged input inventory changed")
    if {item["stage_path"] for item in records} != expected_stage_paths:
        raise ProofError("staged input audit inventory changed")
    for path, captured in expected.items():
        staged = _read_regular_nofollow(output / f"inputs/{FOCUS_PREFIX}/{path}")
        if staged != captured.data:
            raise ProofError(f"staged input bytes changed: {path}")


def _canonicalize_loader_report(report: bytes, system: str) -> bytes:
    if system == "Linux":
        # ldd launches the dynamic loader and prints ASLR-dependent mapping
        # addresses. They are observations of placement, not dependency
        # identity; preserve every name/path while making pre/post comparison
        # meaningful and deterministic.
        return re.sub(rb"\(0x[0-9A-Fa-f]+\)", b"(<load-address>)", report)
    return report


def _loader_report(executable: Path) -> bytes:
    if platform.system() == "Darwin":
        command = ["/usr/bin/otool", "-L", str(executable)]
    elif platform.system() == "Linux":
        command = ["/usr/bin/ldd", str(executable)]
    else:
        raise ProofError(f"unsupported loader-report platform: {platform.system()}")
    result = _run(command)
    if result.returncode != 0:
        raise ProofError(f"dynamic loader report failed: {result.stderr.decode(errors='replace')}")
    return _canonicalize_loader_report(result.stdout, platform.system())


def discover_rasterizer(policy: dict[str, Any]) -> Rasterizer:
    system = platform.system()
    machine = platform.machine()
    matches = [item for item in policy["rasterizer_profiles"] if item["system"] == system and item["machine"] == machine]
    if len(matches) != 1:
        raise ProofError(f"no unique reviewed rasterizer profile for {system}/{machine}")
    profile = matches[0]
    path = Path(profile["path"])
    data = _read_regular_nofollow(path)
    if len(data) != profile["size"] or sha256(data) != profile["sha256"]:
        raise ProofError(f"rasterizer executable identity changed: {path}")
    result = _run([str(path), "-v"])
    if result.returncode != 0 or result.stdout:
        raise ProofError("unexpected pdftocairo version command behavior")
    version = result.stderr
    if sha256(version) != profile["version_sha256"]:
        raise ProofError("rasterizer version identity changed")
    return Rasterizer(profile, version, _loader_report(path))


def _png_chunks(data: bytes) -> list[tuple[bytes, bytes]]:
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ProofError("output is not a PNG")
    chunks: list[tuple[bytes, bytes]] = []
    offset = 8
    while offset < len(data):
        if offset + 12 > len(data):
            raise ProofError("truncated PNG chunk")
        length = struct.unpack(">I", data[offset:offset + 4])[0]
        kind = data[offset + 4:offset + 8]
        end = offset + 12 + length
        if end > len(data):
            raise ProofError("truncated PNG payload")
        payload = data[offset + 8:offset + 8 + length]
        stored_crc = struct.unpack(">I", data[offset + 8 + length:end])[0]
        actual_crc = binascii.crc32(kind + payload) & 0xFFFFFFFF
        if stored_crc != actual_crc:
            raise ProofError(f"bad PNG CRC for {kind!r}")
        chunks.append((kind, payload))
        offset = end
        if kind == b"IEND":
            break
    if offset != len(data) or not chunks or chunks[-1][0] != b"IEND":
        raise ProofError("invalid PNG terminator")
    return chunks


def inspect_png(data: bytes) -> dict[str, Any]:
    chunks = _png_chunks(data)
    if chunks[0][0] != b"IHDR" or len(chunks[0][1]) != 13:
        raise ProofError("PNG lacks an exact IHDR")
    width, height, depth, color_type, compression, filtering, interlace = struct.unpack(">IIBBBBB", chunks[0][1])
    if not width or not height or (depth, color_type, compression, filtering, interlace) != (8, 6, 0, 0, 0):
        raise ProofError("PNG must be non-interlaced 8-bit RGBA")
    compressed = b"".join(payload for kind, payload in chunks if kind == b"IDAT")
    if not compressed:
        raise ProofError("PNG has no IDAT bytes")
    try:
        scanlines = zlib.decompress(compressed)
    except zlib.error as error:
        raise ProofError(f"invalid PNG deflate stream: {error}") from error
    stride = width * 4
    if len(scanlines) != (stride + 1) * height:
        raise ProofError("PNG decompressed size changed")
    rows: list[bytes] = []
    previous = bytes(stride)
    for row_index in range(height):
        start = row_index * (stride + 1)
        filter_kind = scanlines[start]
        encoded = scanlines[start + 1:start + 1 + stride]
        decoded = bytearray(stride)
        for index, value in enumerate(encoded):
            left = decoded[index - 4] if index >= 4 else 0
            above = previous[index]
            upper_left = previous[index - 4] if index >= 4 else 0
            if filter_kind == 0:
                predictor = 0
            elif filter_kind == 1:
                predictor = left
            elif filter_kind == 2:
                predictor = above
            elif filter_kind == 3:
                predictor = (left + above) // 2
            elif filter_kind == 4:
                estimate = left + above - upper_left
                distances = (abs(estimate - left), abs(estimate - above), abs(estimate - upper_left))
                predictor = (left, above, upper_left)[distances.index(min(distances))]
            else:
                raise ProofError(f"unsupported PNG row filter: {filter_kind}")
            decoded[index] = (value + predictor) & 0xFF
        previous = bytes(decoded)
        rows.append(previous)
    pixels = b"".join(rows)
    alpha = pixels[3::4]
    return {
        "size": len(data),
        "sha256": sha256(data),
        "width": width,
        "height": height,
        "bit_depth": depth,
        "color_type": "rgba",
        "pixel_sha256": sha256(pixels),
        "alpha": {
            "minimum": min(alpha),
            "maximum": max(alpha),
            "transparent_pixels": sum(value == 0 for value in alpha),
            "partial_pixels": sum(0 < value < 255 for value in alpha),
            "opaque_pixels": sum(value == 255 for value in alpha),
        },
        "chunks": [{"type": kind.decode("ascii"), "size": len(payload)} for kind, payload in chunks],
    }


def _png_expected_record(data: bytes, relative: str) -> dict[str, Any]:
    inspected = inspect_png(data)
    inspected.pop("chunks")
    return {"path": relative, **inspected}


def _reviewed_png_subset(record: dict[str, Any]) -> dict[str, Any]:
    return {key: record[key] for key in ("path", "size", "sha256", "width", "height")}


def _png_chunk(kind: bytes, payload: bytes) -> bytes:
    return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", binascii.crc32(kind + payload) & 0xFFFFFFFF)


def _stored_deflate(data: bytes) -> bytes:
    result = bytearray(b"\x78\x01")
    offset = 0
    while offset < len(data):
        block = data[offset:offset + 65535]
        offset += len(block)
        final = 1 if offset == len(data) else 0
        result.append(final)
        result.extend(struct.pack("<H", len(block)))
        result.extend(struct.pack("<H", 0xFFFF ^ len(block)))
        result.extend(block)
    if not data:
        result.extend(b"\x01\x00\x00\xff\xff")
    # RFC 1950 Adler-32, implemented here so encoder bytes do not depend on zlib.
    a = 1
    b = 0
    for value in data:
        a = (a + value) % 65521
        b = (b + a) % 65521
    result.extend(struct.pack(">I", (b << 16) | a))
    return bytes(result)


def encode_rgba_png(width: int, height: int, pixels: bytes) -> bytes:
    if len(pixels) != width * height * 4:
        raise ProofError("RGBA encoder pixel count changed")
    rows = b"".join(b"\0" + pixels[row * width * 4:(row + 1) * width * 4] for row in range(height))
    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + _png_chunk(b"IHDR", header) + _png_chunk(b"sRGB", b"\0") + _png_chunk(b"IDAT", _stored_deflate(rows)) + _png_chunk(b"IEND", b"")


def _inside_circle_digit(symbol: str, x: int, y: int, unit: int) -> bool:
    # x/y are sample-center numerators with denominator 2*scale*supersample;
    # unit is scale*supersample, so all geometry remains integer-only.
    center = 24 * unit
    radius = 21 * unit
    dx = x - center
    dy = y - center
    if dx * dx + dy * dy > radius * radius:
        return False
    digit = symbol[0]
    segments = {
        "1": "bc",
        "2": "abged",
        "3": "abgcd",
    }[digit]
    # Transparent seven-segment numeral, deliberately original geometry rather
    # than copied SF Symbol outlines. Coordinates are in doubled point units.
    boxes = {
        "a": (17, 31, 12, 16),
        "b": (29, 33, 14, 24),
        "c": (29, 33, 24, 34),
        "d": (17, 31, 32, 36),
        "e": (15, 19, 24, 34),
        "g": (17, 31, 22, 26),
    }
    for segment in segments:
        left, right, top, bottom = boxes[segment]
        if left * unit <= x <= right * unit and top * unit <= y <= bottom * unit:
            return False
    return True


def _inside_magnifying_glass(x: int, y: int, unit: int) -> bool:
    center = 19 * unit
    dx = x - center
    dy = y - center
    distance = dx * dx + dy * dy
    outer = 16 * unit
    inner = 11 * unit
    ring = inner * inner <= distance <= outer * outer
    # Original 45-degree rectangular handle: 14.5...22 points along x+y,
    # with a 2.25-point width. Values use doubled point coordinates.
    diagonal = abs(x - y) <= 5 * unit
    along = 58 * unit <= x + y <= 86 * unit
    return ring or (diagonal and along)


def generate_symbol_png(symbol: str, scale: int, supersample: int = 8) -> bytes:
    if symbol not in {"1.circle.fill", "2.circle.fill", "3.circle.fill", "magnifyingglass"}:
        raise ProofError(f"unsupported generated symbol: {symbol}")
    width = height = 24 * scale
    unit = scale * supersample
    sample_count = supersample * supersample
    pixels = bytearray()
    for pixel_y in range(height):
        for pixel_x in range(width):
            covered = 0
            for sample_y in range(supersample):
                y = 2 * (pixel_y * supersample + sample_y) + 1
                for sample_x in range(supersample):
                    x = 2 * (pixel_x * supersample + sample_x) + 1
                    inside = _inside_magnifying_glass(x, y, unit) if symbol == "magnifyingglass" else _inside_circle_digit(symbol, x, y, unit)
                    covered += int(inside)
            alpha = (covered * 255 + sample_count // 2) // sample_count
            pixels.extend((255, 255, 255, alpha))
    return encode_rgba_png(width, height, bytes(pixels))


def _appearance(entry: dict[str, Any]) -> str:
    appearances = entry.get("appearances")
    if appearances is None:
        return "default"
    if appearances == [{"appearance": "luminosity", "value": "dark"}]:
        return "dark"
    raise ProofError(f"unsupported catalog appearance: {appearances!r}")


def _validate_info(document: dict[str, Any]) -> None:
    if document.get("info") != {"author": "xcode", "version": 1}:
        raise ProofError("catalog info metadata changed")


def parse_color_catalog(capture: FocusCapture, catalog_name: str, expected_names: list[str]) -> dict[str, Any]:
    catalog = CATALOGS[catalog_name]
    by_path = capture.by_path()
    root_path = catalog["root"]
    root = json.loads(by_path[f"{root_path}/Contents.json"].data)
    _validate_info(root)
    colors: dict[str, Any] = {}
    for name in expected_names:
        path = f"{root_path}/{name}.colorset/Contents.json"
        if path not in by_path:
            raise ProofError(f"missing expected color set: {name}")
        document = json.loads(by_path[path].data)
        if set(document) != {"colors", "info"}:
            raise ProofError(f"unsupported color-set keys for {name}")
        _validate_info(document)
        appearances: dict[str, Any] = {}
        for entry in document["colors"]:
            if set(entry) not in ({"idiom", "color"}, {"idiom", "color", "appearances"}) or entry["idiom"] != "universal":
                raise ProofError(f"unsupported color entry for {name}")
            appearance = _appearance(entry)
            color = entry["color"]
            if set(color) != {"color-space", "components"} or color["color-space"] != "srgb":
                raise ProofError(f"unsupported color space for {name}")
            components = color["components"]
            if set(components) != {"red", "green", "blue", "alpha"}:
                raise ProofError(f"unsupported color components for {name}")
            rgba8: list[int] = []
            for channel in ("red", "green", "blue", "alpha"):
                raw = components[channel]
                if not isinstance(raw, str):
                    raise ProofError(f"non-string color component for {name}")
                if raw.startswith("0x"):
                    value = int(raw[2:], 16)
                else:
                    decimal = Decimal(raw)
                    if decimal < 0 or decimal > 1:
                        raise ProofError(f"out-of-range color component for {name}")
                    value = int((decimal * 255).quantize(Decimal("1"), rounding=ROUND_HALF_UP))
                if not 0 <= value <= 255:
                    raise ProofError(f"out-of-range color component for {name}")
                rgba8.append(value)
            if appearance in appearances:
                raise ProofError(f"duplicate color appearance for {name}: {appearance}")
            appearances[appearance] = {"source_components": components, "rgba8": rgba8, "source_path": path}
        if "default" not in appearances or set(appearances) - {"default", "dark"}:
            raise ProofError(f"unsupported color appearance set for {name}")
        colors[name] = appearances
    discovered = {
        Path(item.path).parent.name.removesuffix(".colorset")
        for item in capture.catalog_files
        if item.path.startswith(root_path + "/") and item.path.endswith(".colorset/Contents.json")
    }
    if discovered != set(expected_names):
        raise ProofError(f"color-set inventory changed for {catalog_name}")
    return colors


def verify_lookup_sources(capture: FocusCapture) -> None:
    sources = {item.path: item.data.decode("utf-8", errors="strict") for item in capture.lookup_sources}
    onboarding_color = sources[LOOKUP_SOURCES[0][0]]
    onboarding_image = sources[LOOKUP_SOURCES[1][0]]
    widget = sources[LOOKUP_SOURCES[2][0]]
    actual = {
        "Onboarding": {
            "colors": sorted(re.findall(r'UIColor\(named: "([^"]+)", in: Bundle\.module', onboarding_color)),
            "images": sorted(re.findall(r'Image\("([^"]+)", bundle:', onboarding_image)),
            "symbols": sorted(re.findall(r'Image\(systemName: "([^"]+)"\)', onboarding_image)),
        },
        "Widget": {
            "colors": sorted(re.findall(r'Color\("([^"]+)", bundle:', widget)),
            "images": sorted(re.findall(r'Image\("([^"]+)", bundle:', widget)),
            "symbols": sorted(re.findall(r'Image\(systemName: "([^"]+)"\)', widget)),
        },
    }
    expected = {
        target: {kind: sorted(names) for kind, names in kinds.items()}
        for target, kinds in LOOKUP_CONTRACT.items()
    }
    if actual != expected:
        raise ProofError(f"shipping resource lookup contract changed: {actual!r}")


def verify_image_catalog_mappings(capture: FocusCapture) -> None:
    by_path = capture.by_path()
    roots = {
        "Onboarding": CATALOGS["onboarding-images"]["root"],
        "Widget": CATALOGS["widget-media"]["root"],
    }
    expected_sets: dict[str, dict[str, list[tuple[str, str]]]] = {target: {} for target in roots}
    for target, name, appearance, source_path, _ in PDF_MAPPINGS:
        if not source_path.startswith(roots[target] + "/"):
            raise ProofError(f"PDF mapping escaped its target catalog: {source_path}")
        expected_sets[target].setdefault(name, []).append((Path(source_path).name, appearance))
    for target, root in roots.items():
        discovered = {
            Path(item.path).parent.name.removesuffix(".imageset")
            for item in capture.catalog_files
            if item.path.startswith(root + "/") and item.path.endswith(".imageset/Contents.json")
        }
        if discovered != set(expected_sets[target]):
            raise ProofError(f"image-set inventory changed for {target}")
        for name, expected_entries in expected_sets[target].items():
            document_path = f"{root}/{name}.imageset/Contents.json"
            document = json.loads(by_path[document_path].data)
            if set(document) not in ({"images", "info"}, {"images", "info", "properties"}):
                raise ProofError(f"unsupported image-set keys for {target}/{name}")
            _validate_info(document)
            if "properties" in document and document["properties"] != {"preserves-vector-representation": True}:
                raise ProofError(f"unsupported image-set properties for {target}/{name}")
            actual_entries: list[tuple[str, str]] = []
            for entry in document["images"]:
                if set(entry) not in ({"filename", "idiom"}, {"filename", "idiom", "appearances"}) or entry["idiom"] != "universal":
                    raise ProofError(f"unsupported image entry for {target}/{name}")
                actual_entries.append((entry["filename"], _appearance(entry)))
            if sorted(actual_entries) != sorted(expected_entries):
                raise ProofError(f"image appearance mapping changed for {target}/{name}")


def _bundle_name(target: str) -> str:
    return f"Focus_{target}.bundle"


def _pdf_output_path(target: str, name: str, appearance: str, scale: int) -> str:
    return f"bundles/{_bundle_name(target)}/images/{name}/{appearance}@{scale}x.png"


def _symbol_output_path(target: str, name: str, scale: int) -> str:
    return f"bundles/{_bundle_name(target)}/symbols/{name}/default@{scale}x.png"


def _output_key(target: str, name: str, appearance: str, scale: int) -> str:
    return f"{target}/{name}/{appearance}/{scale}x"


def copy_color_catalogs(output: Path, capture: FocusCapture) -> list[dict[str, Any]]:
    by_path = capture.by_path()
    copies: list[dict[str, Any]] = []
    for target, mapping in COLOR_MAPPINGS.items():
        catalog = CATALOGS[mapping["catalog"]]
        root = catalog["root"]
        selected = [f"{root}/Contents.json", *(f"{root}/{name}.colorset/Contents.json" for name in mapping["names"])]
        catalog_leaf = Path(root).name
        for source_path in selected:
            relative_inside = Path(source_path).relative_to(root).as_posix()
            # OpenUIKit's current UIColor(named:in:compatibleWith:) searches
            # these exact raw catalog roots, so keep the catalog at bundle root.
            destination_relative = f"bundles/{_bundle_name(target)}/{catalog_leaf}/{relative_inside}"
            destination = output / destination_relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            _write_exclusive(destination, by_path[source_path].data, "raw color catalog copy")
            copies.append({"target": target, "source_path": source_path, **file_record(destination, destination_relative)})
    return copies


def rasterize_pdfs(output: Path, capture: FocusCapture, rasterizer: Rasterizer, policy: dict[str, Any]) -> tuple[list[dict[str, Any]], list[list[str]]]:
    by_path = capture.by_path()
    records: list[dict[str, Any]] = []
    commands: list[list[str]] = []
    scratch = output / "work" / "pdftocairo"
    scratch.mkdir(parents=True)
    for target, name, appearance, source_path, _page_points in PDF_MAPPINGS:
        staged_source = output / f"inputs/{FOCUS_PREFIX}/{source_path}"
        for scale in SCALES:
            key = _output_key(target, name, appearance, scale)
            expected = policy["normalization"]["pdf_outputs"].get(key)
            if expected is None:
                raise ProofError(f"missing reviewed PDF output record: {key}")
            prefix = scratch / f"render-{len(commands):02d}"
            command = [rasterizer.profile["path"], "-png", "-transp", "-singlefile", "-r", str(DPI_PER_SCALE * scale), str(staged_source), str(prefix)]
            result = _run(command)
            commands.append(command)
            if result.returncode != 0 or result.stdout or result.stderr:
                detail = (result.stdout + result.stderr).decode("utf-8", errors="replace")
                raise ProofError(f"pdftocairo failed or emitted diagnostics for {key}: {detail}")
            candidate = Path(str(prefix) + ".png")
            if not candidate.is_file():
                raise ProofError(f"pdftocairo did not emit the expected PNG for {key}")
            destination_relative = _pdf_output_path(target, name, appearance, scale)
            destination = output / destination_relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            data = _read_regular_nofollow(candidate)
            actual = _png_expected_record(data, destination_relative)
            if _reviewed_png_subset(actual) != expected:
                raise ProofError(f"raster output differs from reviewed bytes or pixels: {key}")
            _write_exclusive(destination, data, "reviewed rasterized PDF output")
            record = dict(actual)
            record.update({"target": target, "name": name, "appearance": appearance, "scale": scale, "source_path": source_path})
            record["png_chunks"] = inspect_png(data)["chunks"]
            records.append(record)
            if _read_regular_nofollow(staged_source) != by_path[source_path].data:
                raise ProofError(f"staged PDF input changed during rasterization: {source_path}")
    return records, commands


def generate_symbols(output: Path, policy: dict[str, Any]) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for target, names in SYMBOL_MAPPINGS.items():
        for name in names:
            for scale in SCALES:
                key = _output_key(target, name, "default", scale)
                expected = policy["normalization"]["symbol_outputs"].get(key)
                if expected is None:
                    raise ProofError(f"missing reviewed symbol output record: {key}")
                relative = _symbol_output_path(target, name, scale)
                data = generate_symbol_png(name, scale)
                actual = _png_expected_record(data, relative)
                if _reviewed_png_subset(actual) != expected:
                    raise ProofError(f"generated symbol differs from reviewed geometry: {key}")
                destination = output / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                _write_exclusive(destination, data, "generated symbol output")
                record = dict(actual)
                record.update({"target": target, "name": name, "appearance": "default", "scale": scale, "origin": "original-geometric-replacement"})
                record["png_chunks"] = inspect_png(data)["chunks"]
                records.append(record)
    return records


def write_loose_image_aliases(output: Path, pdf_records: list[dict[str, Any]], symbol_records: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Materialize the flat names understood by current OpenUIKit UIImage.

    Default image appearances use the shipping logical name. Dark appearances
    use an explicit `.dark.png` request spelling; OpenUIKit does not select
    luminosity automatically. System-symbol substitutes use stable overlay
    aliases because dotted SF Symbol names are not valid extensionless lookup
    names in the current loader and shipping code calls Image(systemName:).
    """
    aliases: list[dict[str, Any]] = []
    for record in pdf_records:
        target = record["target"]
        name = record["name"]
        appearance = record["appearance"]
        scale = record["scale"]
        if appearance == "default":
            base = name
            request_name = name
        elif appearance == "dark":
            base = f"{name}.dark"
            request_name = f"{name}.dark.png"
        else:
            raise ProofError(f"unsupported loose image appearance: {appearance}")
        suffix = "" if scale == 1 else f"@{scale}x"
        relative = f"bundles/{_bundle_name(target)}/{base}{suffix}.png"
        source = output / record["path"]
        destination = output / relative
        _write_exclusive(
            destination, _read_regular_nofollow(source), "loose catalog-image alias",
        )
        aliases.append({
            "target": target,
            "kind": "catalog-image",
            "logical_name": name,
            "appearance": appearance,
            "scale": scale,
            "openuikit_request_name": request_name,
            "canonical_path": record["path"],
            **file_record(destination, relative),
        })
    for record in symbol_records:
        target = record["target"]
        symbol = record["name"]
        alias = SYMBOL_OVERLAY_ALIASES[target][symbol]
        scale = record["scale"]
        suffix = "" if scale == 1 else f"@{scale}x"
        relative = f"bundles/{_bundle_name(target)}/{alias}{suffix}.png"
        source = output / record["path"]
        destination = output / relative
        _write_exclusive(
            destination, _read_regular_nofollow(source), "loose system-symbol alias",
        )
        aliases.append({
            "target": target,
            "kind": "system-symbol-replacement",
            "system_symbol_name": symbol,
            "overlay_alias": alias,
            "appearance": "default",
            "scale": scale,
            "openuikit_request_name": alias,
            "canonical_path": record["path"],
            **file_record(destination, relative),
        })
    return aliases


def _index_variant(record: dict[str, Any], bundle_root: str) -> dict[str, Any]:
    relative = Path(record["path"]).relative_to(bundle_root).as_posix()
    return {
        "path": relative,
        "size": record["size"],
        "sha256": record["sha256"],
        "width": record["width"],
        "height": record["height"],
        "pixel_sha256": record["pixel_sha256"],
        "alpha": record["alpha"],
    }


def write_indexes(output: Path, colors: dict[str, dict[str, Any]], pdf_records: list[dict[str, Any]], symbol_records: list[dict[str, Any]], color_copies: list[dict[str, Any]], loose_aliases: list[dict[str, Any]]) -> list[dict[str, Any]]:
    index_records: list[dict[str, Any]] = []
    for target in ("Onboarding", "Widget"):
        bundle_relative = f"bundles/{_bundle_name(target)}"
        images: dict[str, Any] = {}
        for record in pdf_records:
            if record["target"] != target:
                continue
            appearances = images.setdefault(record["name"], {}).setdefault("appearances", {})
            variants = appearances.setdefault(record["appearance"], {})
            variants[f"{record['scale']}x"] = _index_variant(record, bundle_relative)
        symbols: dict[str, Any] = {}
        for record in symbol_records:
            if record["target"] != target:
                continue
            variants = symbols.setdefault(record["name"], {}).setdefault("appearances", {}).setdefault("default", {})
            variants[f"{record['scale']}x"] = _index_variant(record, bundle_relative)
        raw_catalogs = []
        for record in color_copies:
            if record["target"] == target:
                raw_catalogs.append({
                    "path": Path(record["path"]).relative_to(bundle_relative).as_posix(),
                    "source_path": record["source_path"],
                    "size": record["size"],
                    "sha256": record["sha256"],
                })
        index = {
            "schema": 1,
            "format": "open-resource-index-v1",
            "target": target,
            "source_commit": FOCUS_COMMIT,
            "appearance_fallback": {"dark": "default"},
            "colors": colors[target],
            "images": images,
            "symbols": symbols,
            "raw_color_catalog_files": sorted(raw_catalogs, key=lambda item: item["path"]),
            "loose_image_aliases": [
                {
                    key: value for key, value in record.items()
                    if key not in {"target"}
                }
                for record in loose_aliases if record["target"] == target
            ],
            "runtime_loader_status": {
                "raw_colors": "directly consumable by current OpenUIKit named-color subset",
                "default_loose_images": "directly consumable by current OpenUIKit named-image subset",
                "dark_loose_images": "manual/overlay selection required; no automatic luminosity selection",
                "system_symbol_replacements": "overlay aliases required; shipping Image(systemName:) is not wired",
                "explicit_index": "proof-only; no Foundation/UIKit/SwiftUI index loader implemented",
            },
        }
        relative = f"{bundle_relative}/resource-index.json"
        path = output / relative
        _write_exclusive(path, canonical_json(index), "resource index")
        index_records.append(file_record(path, relative))
    return index_records


def load_index(output: Path, target: str) -> dict[str, Any]:
    path = output / f"bundles/{_bundle_name(target)}/resource-index.json"
    document = json.loads(path.read_bytes())
    if document.get("schema") != 1 or document.get("target") != target:
        raise ProofError("resource index identity changed")
    return document


def resolve_indexed_resource(output: Path, target: str, kind: str, name: str, appearance: str = "default", scale: int = 1) -> Path:
    if kind not in {"images", "symbols"} or appearance not in {"default", "dark"} or scale not in SCALES:
        raise ProofError("unsupported indexed lookup request")
    index = load_index(output, target)
    try:
        appearances = index[kind][name]["appearances"]
    except KeyError as error:
        raise ProofError(f"unknown indexed {kind} resource: {name}") from error
    selected = appearance if appearance in appearances else index["appearance_fallback"].get(appearance)
    if selected not in appearances:
        raise ProofError(f"no indexed appearance for {kind}/{name}/{appearance}")
    try:
        record = appearances[selected][f"{scale}x"]
    except KeyError as error:
        raise ProofError(f"no indexed scale for {kind}/{name}/{appearance}/{scale}x") from error
    bundle = output / f"bundles/{_bundle_name(target)}"
    path = (bundle / _validate_relative(record["path"], "indexed resource path")).resolve(strict=True)
    if not path.is_relative_to(bundle.resolve(strict=True)):
        raise ProofError("indexed resource escaped its bundle")
    data = _read_regular_nofollow(path)
    if len(data) != record["size"] or sha256(data) != record["sha256"]:
        raise ProofError("indexed resource bytes changed")
    return path


def verify_bundle_outputs(output: Path, pdf_records: list[dict[str, Any]], symbol_records: list[dict[str, Any]], color_copies: list[dict[str, Any]], loose_aliases: list[dict[str, Any]], index_records: list[dict[str, Any]]) -> None:
    expected_paths = {item["path"] for item in (*pdf_records, *symbol_records, *color_copies, *loose_aliases, *index_records)}
    actual_paths = {
        path.relative_to(output).as_posix()
        for path in (output / "bundles").rglob("*")
        if path.is_file()
    }
    if actual_paths != expected_paths:
        raise ProofError("normalized bundle output inventory changed")
    for record in (*pdf_records, *symbol_records, *color_copies, *loose_aliases, *index_records):
        data = _read_regular_nofollow(output / record["path"])
        if len(data) != record["size"] or sha256(data) != record["sha256"]:
            raise ProofError(f"normalized bundle bytes changed: {record['path']}")
    for target, contract in LOOKUP_CONTRACT.items():
        index = load_index(output, target)
        if set(index["colors"]) != set(contract["colors"]):
            raise ProofError(f"indexed color names changed for {target}")
        if set(index["images"]) != set(contract["images"]):
            raise ProofError(f"indexed image names changed for {target}")
        if set(index["symbols"]) != set(contract["symbols"]):
            raise ProofError(f"indexed symbol names changed for {target}")
        for name in contract["images"]:
            for appearance in ("default", "dark"):
                for scale in SCALES:
                    resolve_indexed_resource(output, target, "images", name, appearance, scale)
        for name in contract["symbols"]:
            for appearance in ("default", "dark"):
                for scale in SCALES:
                    resolve_indexed_resource(output, target, "symbols", name, appearance, scale)
        target_aliases = [record for record in loose_aliases if record["target"] == target]
        expected_alias_count = 3 * len(contract["images"]) + 3 * len(contract["symbols"])
        dark_names = {
            mapping[1] for mapping in PDF_MAPPINGS
            if mapping[0] == target and mapping[2] == "dark"
        }
        expected_alias_count += 3 * len(dark_names)
        if len(target_aliases) != expected_alias_count:
            raise ProofError(f"loose alias inventory changed for {target}")


def prove(focus_repo: str, policy_path: str, output_path: str) -> dict[str, Any]:
    focus_path = Path(focus_repo).resolve(strict=True)
    policy_file = Path(policy_path).resolve(strict=True)
    policy_raw, policy = load_policy(policy_file)
    initial_runtime = generator_runtime_audit()
    # Capture before any output mutation, then forbid generated output beneath
    # either the subject repository or the repository owning the reviewed
    # policy/script. This prevents a successful proof from dirtying a source
    # checkout with tens of megabytes of staged assets.
    initial_capture = capture_focus(focus_path, policy)
    forbidden_roots = (_repository_top(focus_path), _repository_top(policy_file.parent))
    output = _resolve_new_output(output_path, forbidden_roots)
    verify_lookup_sources(initial_capture)
    verify_image_catalog_mappings(initial_capture)
    staged_records = stage_inputs(output, initial_capture)
    verify_staged_inputs(output, initial_capture, staged_records)
    initial_tool = discover_rasterizer(policy)

    colors = {
        target: parse_color_catalog(initial_capture, mapping["catalog"], mapping["names"])
        for target, mapping in COLOR_MAPPINGS.items()
    }
    color_copies = copy_color_catalogs(output, initial_capture)
    pdf_records, commands = rasterize_pdfs(output, initial_capture, initial_tool, policy)
    symbol_records = generate_symbols(output, policy)
    loose_aliases = write_loose_image_aliases(output, pdf_records, symbol_records)
    index_records = write_indexes(output, colors, pdf_records, symbol_records, color_copies, loose_aliases)

    verify_staged_inputs(output, initial_capture, staged_records)
    verify_bundle_outputs(output, pdf_records, symbol_records, color_copies, loose_aliases, index_records)
    final_capture = capture_focus(focus_path, policy)
    if final_capture.identity() != initial_capture.identity():
        raise ProofError("Focus inputs changed during resource normalization")
    final_tool = discover_rasterizer(policy)
    if final_tool != initial_tool:
        raise ProofError("observed rasterizer discovery record changed during resource normalization")
    if _read_regular_nofollow(policy_file) != policy_raw:
        raise ProofError("resource proof policy changed during normalization")
    final_runtime = generator_runtime_audit()
    if final_runtime != initial_runtime:
        raise ProofError("resource proof generator or Python runtime changed during normalization")

    audit = {
        "schema": 1,
        "claims": dict(policy["claims"]),
        "policy": {"path": str(policy_file), "size": len(policy_raw), "sha256": sha256(policy_raw)},
        "focus": {
            "commit": initial_capture.commit,
            "ignored_untracked_file_count": initial_capture.ignored_untracked_file_count,
            "ignored_untracked_state_sha256": initial_capture.ignored_untracked_state_sha256,
            "index_state_sha256": initial_capture.index_state_sha256,
            "status_sha256": initial_capture.status_sha256,
            "manifest": initial_capture.manifest.record(),
            "catalog_file_count": len(initial_capture.catalog_files),
            "catalog_byte_count": sum(len(item.data) for item in initial_capture.catalog_files),
            "lookup_sources": [item.record() for item in initial_capture.lookup_sources],
            "shipping_source_edits": [],
        },
        "staged_inputs": staged_records,
        "rasterizer": initial_tool.audit(),
        "generator_runtime": initial_runtime,
        "rasterizer_invocations": commands,
        "raw_color_catalog_copies": color_copies,
        "pdf_outputs": pdf_records,
        "original_symbol_outputs": symbol_records,
        "current_openuikit_loose_aliases": loose_aliases,
        "resource_indexes": index_records,
        "normalization_summary": {
            "pdf": {"count": len(pdf_records), "byte_count": sum(item["size"] for item in pdf_records), "digest": _output_records_digest(output, pdf_records)},
            "original_symbols": {"count": len(symbol_records), "byte_count": sum(item["size"] for item in symbol_records), "digest": _output_records_digest(output, symbol_records)},
            "openuikit_loose_aliases": {"count": len(loose_aliases), "byte_count": sum(item["size"] for item in loose_aliases), "digest": _output_records_digest(output, loose_aliases)},
            "raw_color_catalog_copies": {"count": len(color_copies), "byte_count": sum(item["size"] for item in color_copies), "digest": _output_records_digest(output, color_copies)},
        },
        "lookup_contract": json.loads(json.dumps(LOOKUP_CONTRACT)),
    }
    audit_path = output / "onboarding-resources-audit.json"
    _write_exclusive(audit_path, canonical_json(audit), "resource proof audit")
    return audit


def _candidate_outputs(focus_repo: str, output_path: str) -> dict[str, Any]:
    """Developer-only helper used to derive reviewed constants before release."""
    policy = expected_policy()
    focus_path = Path(focus_repo).resolve(strict=True)
    capture = capture_focus(focus_path, {**policy, "normalization": {**policy["normalization"], "pdf_outputs": {}, "symbol_outputs": {}}})
    output = _resolve_new_output(output_path, (_repository_top(focus_path), _repository_top(Path(__file__).resolve().parent)))
    stage_inputs(output, capture)
    rasterizer = discover_rasterizer(policy)
    pdf: dict[str, Any] = {}
    scratch = output / "work"
    scratch.mkdir()
    for index, (target, name, appearance, source_path, _) in enumerate(PDF_MAPPINGS):
        for scale in SCALES:
            prefix = scratch / f"r-{index}-{scale}"
            command = [rasterizer.profile["path"], "-png", "-transp", "-singlefile", "-r", str(DPI_PER_SCALE * scale), str(output / f"inputs/{FOCUS_PREFIX}/{source_path}"), str(prefix)]
            result = _run(command)
            if result.returncode or result.stdout or result.stderr:
                raise ProofError(f"candidate render failed: {command!r} {result.stdout + result.stderr!r}")
            relative = _pdf_output_path(target, name, appearance, scale)
            pdf[_output_key(target, name, appearance, scale)] = _png_expected_record(Path(str(prefix) + ".png").read_bytes(), relative)
    symbols: dict[str, Any] = {}
    for target, names in SYMBOL_MAPPINGS.items():
        for name in names:
            for scale in SCALES:
                relative = _symbol_output_path(target, name, scale)
                symbols[_output_key(target, name, "default", scale)] = _png_expected_record(generate_symbol_png(name, scale), relative)
    result = {"pdf": pdf, "symbols": symbols, "rasterizer": rasterizer.audit()}
    _write_exclusive(
        output / "candidate-output-records.json",
        canonical_json(result),
        "candidate output records",
    )
    return result


def main(arguments: list[str]) -> int:
    if len(arguments) == 5 and arguments[1] == "prove":
        audit = prove(arguments[2], arguments[3], arguments[4])
        print(canonical_json(audit).decode("utf-8"), end="")
        return 0
    if len(arguments) == 4 and arguments[1] == "candidate-outputs":
        result = _candidate_outputs(arguments[2], arguments[3])
        print(canonical_json(result).decode("utf-8"), end="")
        return 0
    print(f"usage: {arguments[0]} prove FOCUS_REPO POLICY_JSON NEW_OUTPUT", file=sys.stderr)
    return 2


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv))
    except ProofError as error:
        print(f"resource proof refused: {error}", file=sys.stderr)
        raise SystemExit(1)
