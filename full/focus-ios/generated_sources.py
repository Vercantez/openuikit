#!/usr/bin/env python3
"""Reproduce the two open-source generated Swift inputs for pinned Focus.

This is deliberately a fail-closed build tool, not a source stubber.  It
attests the Focus inputs, pins reviewed generator inputs, keeps all generated
outputs and mutable caches outside the pinned checkouts, and accepts output
only when its bytes match a reviewed cross-platform oracle.

``Metrics.swift`` is generated with two clocks controlled independently.  The
upstream build-date option is set to zero because the checked-in Xcode phase
otherwise embeds the wall clock.  The parser's expiration clock is frozen to
the pinned Focus commit date, preserving the enabled/disabled state that a
build of that revision had.  Both controls are required: ``build_date=0`` alone
does not stop the parser from consulting today's date for metric expiration.

``AppNimbus.swift`` is generated from a pinned, compatible Application Services
source candidate because the 125.0.20240302000149 nightly binary has expired
from Mozilla's artifact service.  The published ``rust-components-swift``
sources establish byte compatibility, but not the nightly's exact Application
Services revision: the relevant source trees are identical at several commits.

The localized ``Intents.intentdefinition`` input is attested here, but it is
not generated: Xcode 14.2's ``intentbuilderc`` is proprietary and has no Linux
build.  Treating a current-Xcode rendering as the historical output would not
be reproducible.
"""

from __future__ import annotations

import hashlib
from io import BytesIO
import os
from pathlib import Path, PurePosixPath
import plistlib
import stat
import subprocess
import sys
import tempfile
from typing import Mapping
import zipfile


FOCUS_COMMIT = "a2832521c1daa0c23419c73705ae043ed60c9791"
FOCUS_COMMIT_TIMESTAMP = "2024-03-05T08:22:23Z"
FOCUS_COMMIT_EPOCH = "1709626943"
FOCUS_INPUTS = {
    "Blockzilla.xcodeproj/project.pbxproj": "5a9c088023d20de3e41e6283ab4bde12338ae54da3f2a57b1e6743434b74e4ac",
    "Blockzilla.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved": "632a0df0276ba7828f456ae3964f158fb7115d05f175ddf637abdd7ab4a4633b",
    "Blockzilla/metrics.yaml": "47836b573e6b3aa9144786b85485cc75ff4520ce56ffdf410e427c3888f38cc8",
    "bin/sdk_generator.sh": "0c63cd8a40a5bc5d5bd58c9750bc0a9a59df80da779d3732affc6f078cffc15b",
    "nimbus.fml.yaml": "4a1b91a1a52ed744a5ce9765894f7d00275a2353fa1ecd22c4296717f0564f92",
    "bin/nimbus-fml-configuration.sh": "242b5dc2df195544dc561ad5010df2138fabe5dc55a185f375d72b027cec3251",
    "Blockzilla/Base.lproj/Intents.intentdefinition": "d73b6f7eb39cdf2c80af4e84fd737e8c2196ded95c4ff886d5e74e2e8ff413de",
}

# MPL-2.0, uploaded before the pinned Focus commit.  The Focus script's
# ``~=13.0`` range now resolves to 13.0.1, so relying on that range would drift.
GLEAN_PARSER_VERSION = "13.0.0"
GLEAN_PARSER_WHEEL_SHA256 = (
    "1c1e9d33fae3b804fc066ae6b2ae7ae8f4148cac1e5b248f2c1e2bfc2e3ae520"
)
GLEAN_PARSER_WHEEL_FILENAME = "glean_parser-13.0.0-py3-none-any.whl"
GLEAN_DEPENDENCY_LOCK_SHA256 = (
    "ce1581055ebfb3d91718484f5b5c222c6dd4b8b0cffba2a50d661e09dcc6ae75"
)
GLEAN_REFERENCE_DATE = "2024-03-05"
GLEAN_OUTPUT_SHA256 = "aea69809e642b25bebb82f392d82d8d6efca2227fc585cff8bf983e0fd3bea17"

# glean-parser's public translate API accepts the same options as its CLI, but
# its expiration checks call datetime.utcnow() and datetime.now() internally.
# Run a tiny driver from the hash-attested wheel in a fresh, hash-locked
# dependency environment so that both linting and parsing see the pinned
# revision's UTC date.  The accepted output hash below makes this deliberately
# fail closed if the upstream implementation changes.
GLEAN_DRIVER = r"""
import datetime
import sys
from pathlib import Path

package_root = Path(sys.argv[1]).resolve(strict=True)
sys.path.insert(0, str(package_root))

import glean_parser
from glean_parser import translate as translator
from glean_parser import util

try:
    Path(glean_parser.__file__).resolve(strict=True).relative_to(package_root)
except ValueError:
    raise SystemExit("glean_parser was not loaded from the attested wheel")

reference_date = datetime.date.fromisoformat(sys.argv[4])
real_datetime = datetime.datetime

class FrozenDateTime(real_datetime):
    @classmethod
    def utcnow(cls):
        return cls(
            reference_date.year,
            reference_date.month,
            reference_date.day,
        )

    @classmethod
    def now(cls, timezone=None):
        value = cls(
            reference_date.year,
            reference_date.month,
            reference_date.day,
        )
        if timezone is not None:
            return timezone.fromutc(value.replace(tzinfo=timezone))
        return value

util.datetime.datetime = FrozenDateTime
status = translator.translate(
    [Path(sys.argv[2])],
    "swift",
    Path(sys.argv[3]),
    {"glean_namespace": "Glean", "build_date": "0"},
    {},
)
if status not in (None, 0):
    raise SystemExit(status)
"""

# MPL-2.0 Application Services source candidate and its exact Glean gitlink.
NIMBUS_APPSERVICES_COMMIT = "219ca78e2ce82d48cd5eed8b198b112b750c0925"
NIMBUS_GLEAN_SUBMODULE_COMMIT = "e8e842169a9a6e07ed21156e6204e2cb01a38139"
NIMBUS_RUST_TOOLCHAIN = "1.75.0"
NIMBUS_RUSTC_VERSION = "rustc 1.75.0 (82e1608df 2023-12-21)"
NIMBUS_CARGO_VERSION = "cargo 1.75.0 (1d8b05cdd 2023-11-20)"
NIMBUS_RUNTIME_TREE = "9ca840f31a3ff2dd84b0c79f0543f3b82d9fcf5e"
NIMBUS_GENERATOR_TREE = "580560dd62de048487d817992f9ccdc4b35f47a4"
NIMBUS_SOURCE_INPUTS = {
    ".cargo/config": "c57c5a46658916dc9a7c425d5b63a5e2fc74f8072f662fe7f1b9ab838501dd0b",
    "Cargo.lock": "ab861a7124b9f306e665b1973ca0b97a8362f1296423229bd8ab04afdb6f1cfc",
    "rust-toolchain.toml": "c80b7dc231ed9e9fa38aa8b749a6ebb9b4864319b9f9719bb2e1f37485936f3e",
    "components/support/nimbus-fml/Cargo.toml": "aae4ad195fe42799382d86192c4abbcaa63e1e9f3aacd193d99427713b822a0e",
}

# The Focus Package.resolved pin names this exact rust-components-swift commit
# and nightly tag.  Every published Nimbus Swift source in that package is
# attested below and compared byte-for-byte with the Application Services
# checkout before its generator is built.  This is a durable compatibility
# link from Focus's dependency to the pinned source candidate used in lieu of
# its expired nimbus-fml binary artifact; it cannot identify which of several
# commits with identical trees supplied the historical binary.
NIMBUS_PACKAGE_COMMIT = "c110d9f8204568ec3950c233cf48b8b40136d806"
NIMBUS_PACKAGE_TAG = "125.0.20240302000149"
NIMBUS_PACKAGE_INPUTS = {
    "Package.swift": "165251584a18ebc4600b6dd649af8e81a90261d0ac91d8389c42473151446ef6",
    "LICENSE": "1f256ecad192880510e84ad60474eab7589218784b9a50bc7ceee34c2b91f1d5",
    "swift-source/focus/Nimbus/ArgumentProcessor.swift": "8a21fc9245a21379847475f51dec22f036825f3cc2430ca358b06d4dfd32026e",
    "swift-source/focus/Nimbus/Bundle+.swift": "b33130b59e227f37c1473ae845f0318febeddbaedf80bb113be9974a268324da",
    "swift-source/focus/Nimbus/Collections+.swift": "586d56972a06dabfdc590f8d8ba9042c68d43b4145cb8a9083d32774922e57f3",
    "swift-source/focus/Nimbus/Dictionary+.swift": "b3a1ae5b5f88eb2a56441d4e826a3d5818829e045a408b9d6578f818cc7cab6f",
    "swift-source/focus/Nimbus/FeatureHolder.swift": "6f85cbc9bc1fa13d7290dbf2bdf15655d23040580370fa8f4a9fbb01d9d56a82",
    "swift-source/focus/Nimbus/FeatureInterface.swift": "66b857a073af30a3831c5ceaa80e15a01df8496eab65b8028a56b5539c8e2cb7",
    "swift-source/focus/Nimbus/FeatureManifestInterface.swift": "8bc95e2609d16e2fc347e494c06801c264f7fa3c3657bdd2f9812bfb367764bb",
    "swift-source/focus/Nimbus/FeatureVariables.swift": "462c143990d3cde168a151e16a085f5cee0b712490b0f852fd76c7555c87fdd1",
    "swift-source/focus/Nimbus/HardcodedNimbusFeatures.swift": "fa7f84819b99568b96512e502565fa1b7183d8f22eeb87fc0366539cb5442254",
    "swift-source/focus/Nimbus/Nimbus.swift": "0056a4c0f921888976cb69391665709beaaf96630ba7434b201bb828f2160d9d",
    "swift-source/focus/Nimbus/NimbusApi.swift": "6c643f92dd5e04eaad19106e86e4c3e1107b9ec12d8e80930b9fbaf4b0f75171",
    "swift-source/focus/Nimbus/NimbusBuilder.swift": "4595b8a00df55b3661c90a089c228761c7db58e471263becd68be7a252ee2acb",
    "swift-source/focus/Nimbus/NimbusCreate.swift": "c2f9afab9339e97a8f8cbfbbc45fbbfef9a22cd1273149d6c32af7acb1fdd425",
    "swift-source/focus/Nimbus/NimbusMessagingHelpers.swift": "07a657777fdf51b10f48fb74fed52794eb094da054b8c329b02f19cf66c75fe3",
    "swift-source/focus/Nimbus/Operation+.swift": "959603503c72667590f575167af5a3f078924bfd38ef97299905d4478db2a026",
    "swift-source/focus/Nimbus/Utils/Logger.swift": "761ed8f35b3766b26ce5b678c5e1608fb94ca615e7dc6e638e1260e893eb53aa",
    "swift-source/focus/Nimbus/Utils/Sysctl.swift": "e9aa61b85a12d7e714a42cfa38ed27335956eccf12edcc7e60cc241dde38db40",
    "swift-source/focus/Nimbus/Utils/Unreachable.swift": "071b18d0bdf2af784000a9c769606417de3a8b7599f830056505eed4084471ad",
    "swift-source/focus/Nimbus/Utils/Utils.swift": "325509825ef4242b9b183ced326d194c830041d12ac3d8ce1c067930c77d0d04",
}
NIMBUS_OUTPUT_SHA256 = {
    "developer": "62c7618de24c2e7273c8e48f54a05988fddff719d92400e262ed8770058f4bec",
    "beta": "9b25e56225081df34fbd982fde68e1e4d2904a7812899704bc38d51882074cdb",
    "release": "9b25e56225081df34fbd982fde68e1e4d2904a7812899704bc38d51882074cdb",
}

INTENT_TOOLS_VERSION = "14.2"
INTENT_TOOLS_BUILD_VERSION = "14C18"


class GenerationError(RuntimeError):
    """A pin, input, toolchain, or generated output failed attestation."""


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _read_regular(path: Path, label: str) -> bytes:
    if path.is_symlink():
        raise GenerationError(f"{label} must not be a symlink: {path}")
    flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
    try:
        descriptor = os.open(path, flags)
    except OSError as exc:
        raise GenerationError(f"cannot open {label} {path}: {exc}") from exc
    try:
        before = os.fstat(descriptor)
        if not stat.S_ISREG(before.st_mode):
            raise GenerationError(f"{label} is not a regular file: {path}")
        chunks: list[bytes] = []
        while True:
            chunk = os.read(descriptor, 1024 * 1024)
            if not chunk:
                break
            chunks.append(chunk)
        after = os.fstat(descriptor)
        identity_before = (
            before.st_dev,
            before.st_ino,
            before.st_size,
            before.st_mtime_ns,
        )
        identity_after = (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns)
        if identity_before != identity_after:
            raise GenerationError(f"{label} changed while being read: {path}")
        return b"".join(chunks)
    finally:
        os.close(descriptor)


def _controlled_git_environment() -> dict[str, str]:
    """Remove ambient Git redirection/configuration from attestation commands."""

    environment = {
        name: value for name, value in os.environ.items() if not name.startswith("GIT_")
    }
    environment.update(
        {
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_NO_REPLACE_OBJECTS": "1",
            "GIT_OPTIONAL_LOCKS": "0",
            "LANG": "C",
            "LC_ALL": "C",
        }
    )
    return environment


def _git(repo: Path, *args: str) -> str:
    try:
        return subprocess.check_output(
            ["git", "-C", str(repo), *args],
            stderr=subprocess.STDOUT,
            env=_controlled_git_environment(),
            text=True,
        ).strip()
    except (OSError, subprocess.CalledProcessError) as exc:
        detail = getattr(exc, "output", "")
        raise GenerationError(
            f"git {' '.join(args)} failed in {repo}: {str(detail).strip()}"
        ) from exc


def _resolve_repository(path_arg: str, label: str) -> Path:
    path = Path(path_arg).expanduser()
    if path.is_symlink():
        raise GenerationError(f"{label} must not be a symlink: {path}")
    try:
        resolved = path.resolve(strict=True)
    except OSError as exc:
        raise GenerationError(f"cannot resolve {label} {path}: {exc}") from exc
    if not resolved.is_dir():
        raise GenerationError(f"{label} is not a directory: {resolved}")
    return resolved


def _reject_symlink_components(root: Path, relative: str, label: str) -> None:
    current = root
    for component in Path(relative).parts:
        current = current / component
        if not os.path.lexists(current):
            return
        try:
            mode = os.lstat(current).st_mode
        except OSError as exc:
            raise GenerationError(
                f"cannot inspect {label} path {current}: {exc}"
            ) from exc
        if stat.S_ISLNK(mode):
            raise GenerationError(f"{label} path must not contain symlinks: {current}")


def _verify_hashes(root: Path, expected: Mapping[str, str], label: str) -> None:
    for relative, expected_hash in expected.items():
        _reject_symlink_components(root, relative, label)
        path = root / relative
        actual_hash = sha256(_read_regular(path, f"{label} input"))
        if actual_hash != expected_hash:
            raise GenerationError(
                f"{label} input hash changed for {relative}: "
                f"expected {expected_hash}, got {actual_hash}"
            )


def verify_focus(repo_arg: str) -> Path:
    repo = _resolve_repository(repo_arg, "Focus repository")
    commit = _git(repo, "rev-parse", "--verify", "HEAD^{commit}")
    if commit != FOCUS_COMMIT:
        raise GenerationError(
            f"Focus pin changed: expected {FOCUS_COMMIT}, got {commit}"
        )
    commit_epoch = _git(repo, "show", "-s", "--format=%ct", "HEAD")
    if commit_epoch != FOCUS_COMMIT_EPOCH:
        raise GenerationError(
            "Focus commit timestamp changed: expected Unix time "
            f"{FOCUS_COMMIT_EPOCH}, got {commit_epoch}"
        )
    if not FOCUS_COMMIT_TIMESTAMP.startswith(GLEAN_REFERENCE_DATE + "T"):
        raise GenerationError("Glean expiration date is not the Focus commit date")
    _verify_hashes(repo, FOCUS_INPUTS, "Focus")

    intent_path = repo / "Blockzilla/Base.lproj/Intents.intentdefinition"
    try:
        intent = plistlib.loads(_read_regular(intent_path, "intent definition"))
    except Exception as exc:
        raise GenerationError(f"cannot parse intent definition: {exc}") from exc
    if intent.get("INIntentDefinitionToolsVersion") != INTENT_TOOLS_VERSION:
        raise GenerationError("intentbuilderc tools version changed")
    if intent.get("INIntentDefinitionToolsBuildVersion") != INTENT_TOOLS_BUILD_VERSION:
        raise GenerationError("intentbuilderc tools build version changed")
    return repo


def verify_appservices(repo_arg: str) -> Path:
    repo = _resolve_repository(repo_arg, "Application Services repository")
    commit = _git(repo, "rev-parse", "--verify", "HEAD^{commit}")
    if commit != NIMBUS_APPSERVICES_COMMIT:
        raise GenerationError(
            "Application Services pin changed: expected "
            f"{NIMBUS_APPSERVICES_COMMIT}, got {commit}"
        )
    dirty = _git(
        repo,
        "status",
        "--porcelain=v1",
        "--untracked-files=all",
        "--ignore-submodules=none",
    )
    if dirty:
        raise GenerationError(f"Application Services checkout is not clean:\n{dirty}")
    _verify_hashes(repo, NIMBUS_SOURCE_INPUTS, "Nimbus source")

    runtime_tree = _git(repo, "rev-parse", "HEAD:components/nimbus/ios/Nimbus")
    if runtime_tree != NIMBUS_RUNTIME_TREE:
        raise GenerationError(
            "Application Services Nimbus runtime tree changed: expected "
            f"{NIMBUS_RUNTIME_TREE}, got {runtime_tree}"
        )
    generator_tree = _git(repo, "rev-parse", "HEAD:components/support/nimbus-fml")
    if generator_tree != NIMBUS_GENERATOR_TREE:
        raise GenerationError(
            "Application Services Nimbus generator tree changed: expected "
            f"{NIMBUS_GENERATOR_TREE}, got {generator_tree}"
        )

    gitlink = _git(repo, "ls-tree", "HEAD", "components/external/glean").split()
    if len(gitlink) != 4 or gitlink[:2] != ["160000", "commit"]:
        raise GenerationError("Application Services Glean path is not a gitlink")
    if gitlink[2] != NIMBUS_GLEAN_SUBMODULE_COMMIT:
        raise GenerationError(
            "Application Services Glean gitlink changed: expected "
            f"{NIMBUS_GLEAN_SUBMODULE_COMMIT}, got {gitlink[2]}"
        )

    glean = repo / "components/external/glean"
    if glean.is_symlink() or not glean.is_dir():
        raise GenerationError(f"Glean submodule is absent or a symlink: {glean}")
    glean_commit = _git(glean, "rev-parse", "--verify", "HEAD^{commit}")
    if glean_commit != NIMBUS_GLEAN_SUBMODULE_COMMIT:
        raise GenerationError(
            f"Glean submodule pin changed: expected "
            f"{NIMBUS_GLEAN_SUBMODULE_COMMIT}, got {glean_commit}"
        )
    glean_dirty = _git(glean, "status", "--porcelain=v1", "--untracked-files=all")
    if glean_dirty:
        raise GenerationError(f"Glean submodule is not clean:\n{glean_dirty}")
    return repo


def verify_rust_components(repo_arg: str) -> Path:
    repo = _resolve_repository(repo_arg, "rust-components-swift repository")
    commit = _git(repo, "rev-parse", "--verify", "HEAD^{commit}")
    if commit != NIMBUS_PACKAGE_COMMIT:
        raise GenerationError(
            "rust-components-swift pin changed: expected "
            f"{NIMBUS_PACKAGE_COMMIT}, got {commit}"
        )
    tag = _git(repo, "describe", "--tags", "--exact-match", "HEAD")
    if tag != NIMBUS_PACKAGE_TAG:
        raise GenerationError(
            f"rust-components-swift tag changed: expected {NIMBUS_PACKAGE_TAG}, "
            f"got {tag}"
        )
    dirty = _git(repo, "status", "--porcelain=v1", "--untracked-files=all")
    if dirty:
        raise GenerationError(f"rust-components-swift checkout is not clean:\n{dirty}")
    _verify_hashes(repo, NIMBUS_PACKAGE_INPUTS, "rust-components-swift")
    return repo


def _verify_nimbus_source_mapping(rust_components: Path, appservices: Path) -> None:
    prefix = "swift-source/focus/Nimbus/"
    mapped = 0
    for relative in NIMBUS_PACKAGE_INPUTS:
        if not relative.startswith(prefix):
            continue
        suffix = relative.removeprefix(prefix)
        package_data = _read_regular(
            rust_components / relative, "rust-components-swift Nimbus source"
        )
        appservices_data = _read_regular(
            appservices / "components/nimbus/ios/Nimbus" / suffix,
            "Application Services Nimbus source",
        )
        if package_data != appservices_data:
            raise GenerationError(
                "Nimbus source mapping changed between rust-components-swift "
                f"and Application Services: {suffix}"
            )
        mapped += 1
    if mapped != 19:
        raise GenerationError(f"expected 19 mapped Nimbus Swift sources, got {mapped}")


def _run(
    command: list[str],
    *,
    cwd: Path | None = None,
    env: Mapping[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(
            command,
            cwd=cwd,
            env=dict(env) if env is not None else None,
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        output = getattr(exc, "stdout", "") or getattr(exc, "output", "") or ""
        raise GenerationError(
            f"command failed: {' '.join(command)}\n{str(output).strip()}"
        ) from exc


def _new_output_path(output_arg: str, forbidden_roots: tuple[Path, ...] = ()) -> Path:
    requested = Path(os.path.abspath(Path(output_arg).expanduser()))
    if os.path.lexists(requested):
        raise GenerationError(f"refusing to overwrite existing output: {requested}")
    output = requested.resolve(strict=False)
    if any(_is_within(output, root) for root in forbidden_roots):
        raise GenerationError(
            "generated output must be outside the pinned source checkouts"
        )
    if os.path.lexists(output):
        raise GenerationError(f"refusing to overwrite existing output: {output}")
    try:
        output.parent.mkdir(parents=True, exist_ok=True)
        output = output.parent.resolve(strict=True) / output.name
    except OSError as exc:
        raise GenerationError(f"cannot create output directory: {exc}") from exc
    return output


def _is_within(path: Path, directory: Path) -> bool:
    try:
        path.relative_to(directory)
    except ValueError:
        return False
    return True


def _write_new(path: Path, data: bytes) -> None:
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    try:
        descriptor = os.open(path, flags, 0o600)
    except OSError as exc:
        raise GenerationError(f"cannot create output {path}: {exc}") from exc
    try:
        view = memoryview(data)
        while view:
            written = os.write(descriptor, view)
            if written == 0:
                raise OSError("zero-byte write")
            view = view[written:]
    except OSError as exc:
        try:
            path.unlink()
        except OSError:
            pass
        raise GenerationError(f"cannot write output {path}: {exc}") from exc
    finally:
        os.close(descriptor)


def _accept_generated(path: Path, expected_hash: str, label: str) -> bytes:
    data = _read_regular(path, label)
    actual_hash = sha256(data)
    if actual_hash != expected_hash:
        raise GenerationError(
            f"{label} hash changed: expected {expected_hash}, got {actual_hash}"
        )
    return data


def _extract_attested_glean_wheel(wheel_arg: str, destination: Path) -> None:
    wheel_path = Path(wheel_arg).expanduser()
    wheel_data = _read_regular(wheel_path, "glean-parser wheel")
    actual_hash = sha256(wheel_data)
    if actual_hash != GLEAN_PARSER_WHEEL_SHA256:
        raise GenerationError(
            "glean-parser wheel hash changed: expected "
            f"{GLEAN_PARSER_WHEEL_SHA256}, got {actual_hash}"
        )

    try:
        archive = zipfile.ZipFile(BytesIO(wheel_data))
    except zipfile.BadZipFile as exc:
        raise GenerationError(
            f"glean-parser wheel is not a ZIP archive: {exc}"
        ) from exc
    with archive:
        for info in archive.infolist():
            relative = PurePosixPath(info.filename)
            if (
                not relative.parts
                or relative.is_absolute()
                or ".." in relative.parts
                or "\\" in info.filename
            ):
                raise GenerationError(
                    f"unsafe path in glean-parser wheel: {info.filename!r}"
                )
            mode = info.external_attr >> 16
            file_type = stat.S_IFMT(mode)
            if file_type and file_type not in (stat.S_IFREG, stat.S_IFDIR):
                raise GenerationError(
                    f"non-regular member in glean-parser wheel: {info.filename!r}"
                )
            output = destination.joinpath(*relative.parts)
            if info.is_dir():
                output.mkdir(parents=True, exist_ok=True)
                continue
            output.parent.mkdir(parents=True, exist_ok=True)
            _write_new(output, archive.read(info))

    metadata = destination / (f"glean_parser-{GLEAN_PARSER_VERSION}.dist-info/METADATA")
    metadata_text = _read_regular(metadata, "glean-parser wheel metadata").decode(
        "utf-8"
    )
    if f"\nName: glean-parser\n" not in "\n" + metadata_text:
        raise GenerationError("glean-parser wheel package name changed")
    if f"\nVersion: {GLEAN_PARSER_VERSION}\n" not in "\n" + metadata_text:
        raise GenerationError("glean-parser wheel version changed")


def _prepare_isolated_glean_python(
    python_executable: str, wheelhouse_arg: str, temp_dir: Path
) -> tuple[Path, Path]:
    wheelhouse = _resolve_repository(wheelhouse_arg, "Glean wheelhouse")
    wheel = wheelhouse / GLEAN_PARSER_WHEEL_FILENAME
    wheel_hash = sha256(_read_regular(wheel, "glean-parser wheel"))
    if wheel_hash != GLEAN_PARSER_WHEEL_SHA256:
        raise GenerationError(
            "glean-parser wheel hash changed: expected "
            f"{GLEAN_PARSER_WHEEL_SHA256}, got {wheel_hash}"
        )

    lock = Path(__file__).resolve().with_name("glean_dependencies.lock")
    lock_data = _read_regular(lock, "Glean dependency lock")
    lock_hash = sha256(lock_data)
    if lock_hash != GLEAN_DEPENDENCY_LOCK_SHA256:
        raise GenerationError(
            "Glean dependency lock hash changed: expected "
            f"{GLEAN_DEPENDENCY_LOCK_SHA256}, got {lock_hash}"
        )
    attested_lock = temp_dir / "glean_dependencies.lock"
    _write_new(attested_lock, lock_data)

    runtime = _run(
        [
            python_executable,
            "-I",
            "-c",
            "import platform, sys; "
            "print(platform.python_implementation(), "
            "f'{sys.version_info.major}.{sys.version_info.minor}')",
        ]
    ).stdout.strip()
    if runtime != "CPython 3.11":
        raise GenerationError(
            f"unsupported Glean Python runtime: expected CPython 3.11, got {runtime}"
        )

    environment = os.environ.copy()
    for name in tuple(environment):
        if name.startswith("PIP_") or name in ("PYTHONHOME", "PYTHONPATH"):
            environment.pop(name)
    environment["PYTHONNOUSERSITE"] = "1"

    venv = temp_dir / "venv"
    _run(
        [python_executable, "-I", "-m", "venv", str(venv)],
        env=environment,
    )
    isolated_python = venv / "bin/python"
    if not isolated_python.exists():
        raise GenerationError(
            f"isolated Glean Python was not created: {isolated_python}"
        )
    _run(
        [
            str(isolated_python),
            "-I",
            "-m",
            "pip",
            "--isolated",
            "--disable-pip-version-check",
            "install",
            "--no-index",
            "--only-binary=:all:",
            "--no-deps",
            "--require-hashes",
            "--find-links",
            str(wheelhouse),
            "-r",
            str(attested_lock),
        ],
        env=environment,
    )
    return isolated_python, wheel


def generate_glean(
    focus_arg: str,
    python_executable: str,
    wheelhouse_arg: str,
    output_arg: str,
) -> Path:
    focus = verify_focus(focus_arg)
    output = _new_output_path(output_arg, (focus,))

    with tempfile.TemporaryDirectory(
        prefix="focus-glean-generated.", dir=output.parent
    ) as temp:
        temp_dir = Path(temp)
        package_root = temp_dir / "wheel"
        package_root.mkdir()
        generated_dir = temp_dir / "generated"
        generated_dir.mkdir()
        isolated_python, wheel = _prepare_isolated_glean_python(
            python_executable, wheelhouse_arg, temp_dir
        )
        _extract_attested_glean_wheel(str(wheel), package_root)
        _run(
            [
                str(isolated_python),
                "-I",
                "-c",
                GLEAN_DRIVER,
                str(package_root),
                str(focus / "Blockzilla/metrics.yaml"),
                str(generated_dir),
                GLEAN_REFERENCE_DATE,
            ]
        )
        generated = sorted(generated_dir.iterdir(), key=lambda path: path.name)
        if [path.name for path in generated] != ["Metrics.swift"]:
            raise GenerationError(
                "glean-parser output set changed: "
                f"{[path.name for path in generated]}"
            )
        # The generator reads the pinned manifest through the Focus checkout.
        # Re-attest after execution so a concurrent or tool-induced mutation
        # cannot be accepted merely because it happened after the first check.
        if verify_focus(str(focus)) != focus:
            raise GenerationError("Focus repository identity changed during generation")
        data = _accept_generated(
            generated[0], GLEAN_OUTPUT_SHA256, "generated Metrics.swift"
        )
    _write_new(output, data)
    return output


def _verify_rust_toolchain(environment: Mapping[str, str]) -> None:
    rustc = _run(
        ["rustc", f"+{NIMBUS_RUST_TOOLCHAIN}", "--version"], env=environment
    ).stdout.strip()
    cargo = _run(
        ["cargo", f"+{NIMBUS_RUST_TOOLCHAIN}", "--version"], env=environment
    ).stdout.strip()
    if rustc != NIMBUS_RUSTC_VERSION:
        raise GenerationError(f"unexpected Rust compiler: {rustc.strip()}")
    if cargo != NIMBUS_CARGO_VERSION:
        raise GenerationError(f"unexpected Cargo: {cargo.strip()}")


def _reject_external_cargo_configuration(appservices: Path) -> None:
    """Refuse Cargo configuration above the attested repository root."""

    current = appservices.parent
    while True:
        for name in ("config", "config.toml"):
            candidate = current / ".cargo" / name
            if os.path.lexists(candidate):
                raise GenerationError(
                    "external Cargo configuration would affect the Nimbus build: "
                    f"{candidate}"
                )
        if current == current.parent:
            break
        current = current.parent


def _is_ambient_build_override(name: str) -> bool:
    if name.startswith(
        (
            "CARGO_",
            "GIT_",
            "PKG_CONFIG_",
            "SCCACHE_",
            "CCACHE_",
            "VCPKG_",
        )
    ):
        return True
    if name in {
        "AR",
        "BASH_ENV",
        "BINDGEN_EXTRA_CLANG_ARGS",
        "CC",
        "CFLAGS",
        "CLANG_PATH",
        "CPATH",
        "CPPFLAGS",
        "CPLUS_INCLUDE_PATH",
        "C_INCLUDE_PATH",
        "CXX",
        "CXXFLAGS",
        "DEVELOPER_DIR",
        "DYLD_LIBRARY_PATH",
        "ENV",
        "LD",
        "LDFLAGS",
        "LD_LIBRARY_PATH",
        "LIBCLANG_PATH",
        "LIBRARY_PATH",
        "LLVM_CONFIG_PATH",
        "MACOSX_DEPLOYMENT_TARGET",
        "MAKEFLAGS",
        "NUM_JOBS",
        "OBJCOPY",
        "OBJC_INCLUDE_PATH",
        "OBJDUMP",
        "PKG_CONFIG_PATH",
        "PKG_CONFIG",
        "PROTOC",
        "PROTOC_INCLUDE",
        "PYTHONHOME",
        "PYTHONPATH",
        "RUSTC",
        "RUSTC_WRAPPER",
        "RUSTC_WORKSPACE_WRAPPER",
        "RUSTDOC",
        "RUSTDOCFLAGS",
        "RUSTFLAGS",
        "RUSTUP_DIST_SERVER",
        "RUSTUP_TOOLCHAIN",
        "RUSTUP_UPDATE_ROOT",
        "STRIP",
        "SDKROOT",
        "SHELLOPTS",
    }:
        return True
    upper_name = name.upper()
    return upper_name.startswith(
        (
            "AR_",
            "BINDGEN_EXTRA_CLANG_ARGS_",
            "CC_",
            "CFLAGS_",
            "CPPFLAGS_",
            "CXX_",
            "CXXFLAGS_",
            "DYLD_",
            "LD_",
            "OPENSSL_",
        )
    ) or upper_name.endswith(
        (
            "_AR",
            "_CC",
            "_CFLAGS",
            "_CPPFLAGS",
            "_CXX",
            "_CXXFLAGS",
            "_LD",
            "_OBJCOPY",
            "_OBJDUMP",
            "_RANLIB",
            "_STRIP",
        )
    )


def _private_cargo_environment(cargo_home: Path) -> dict[str, str]:
    """Return a deterministic Cargo environment with a fresh private cache."""

    environment = {
        name: value
        for name, value in os.environ.items()
        if not _is_ambient_build_override(name)
    }
    environment.update(
        {
            "CARGO_HOME": str(cargo_home),
            "CARGO_INCREMENTAL": "0",
            "CARGO_NET_GIT_FETCH_WITH_CLI": "false",
            "CARGO_TERM_COLOR": "never",
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_CONFIG_NOSYSTEM": "1",
            "LANG": "C",
            "LC_ALL": "C",
            "PYTHONNOUSERSITE": "1",
            "SOURCE_DATE_EPOCH": FOCUS_COMMIT_EPOCH,
            "TZ": "UTC",
        }
    )
    return environment


def _create_cargo_target_directory(
    target_dir_arg: str, forbidden_roots: tuple[Path, ...]
) -> Path:
    requested = Path(os.path.abspath(Path(target_dir_arg).expanduser()))
    if os.path.lexists(requested):
        raise GenerationError(
            f"Cargo target directory must be a new, tool-owned path: {requested}"
        )
    try:
        parent = requested.parent.resolve(strict=True)
    except OSError as exc:
        raise GenerationError(
            f"Cargo target parent must already exist: {requested.parent}: {exc}"
        ) from exc
    if not parent.is_dir():
        raise GenerationError(f"Cargo target parent is not a directory: {parent}")
    target_dir = parent / requested.name
    if target_dir == Path(target_dir.anchor):
        raise GenerationError("refusing a filesystem root as Cargo target directory")
    if any(
        _is_within(target_dir, root) or _is_within(root, target_dir)
        for root in forbidden_roots
    ):
        raise GenerationError(
            "Cargo target directory must be disjoint from pinned source checkouts"
        )
    try:
        os.mkdir(target_dir, 0o700)
    except OSError as exc:
        raise GenerationError(
            f"cannot create exclusive Cargo target directory {target_dir}: {exc}"
        ) from exc
    resolved = target_dir.resolve(strict=True)
    if resolved != target_dir:
        raise GenerationError(f"Cargo target directory was redirected: {target_dir}")
    return resolved


def generate_nimbus(
    focus_arg: str,
    rust_components_arg: str,
    appservices_arg: str,
    target_dir_arg: str,
    channel: str,
    output_arg: str,
) -> Path:
    if channel not in NIMBUS_OUTPUT_SHA256:
        raise GenerationError(
            f"unsupported Nimbus channel {channel!r}; expected one of "
            f"{sorted(NIMBUS_OUTPUT_SHA256)}"
        )
    focus = verify_focus(focus_arg)
    rust_components = verify_rust_components(rust_components_arg)
    appservices = verify_appservices(appservices_arg)
    _verify_nimbus_source_mapping(rust_components, appservices)
    output = _new_output_path(output_arg, (focus, rust_components, appservices))
    target_dir = _create_cargo_target_directory(
        target_dir_arg, (focus, rust_components, appservices)
    )
    cargo_home = target_dir / "cargo-home"
    try:
        os.mkdir(cargo_home, 0o700)
    except OSError as exc:
        raise GenerationError(
            f"cannot create private Cargo home {cargo_home}: {exc}"
        ) from exc
    _reject_external_cargo_configuration(appservices)
    environment = _private_cargo_environment(cargo_home)
    _verify_rust_toolchain(environment)

    # This is the sole intentional Cargo dependency-fetch boundary.  Cargo
    # fetches only dependencies selected by the attested lock file into the new
    # private Cargo home.  The compilation below disables Cargo resolution and
    # downloads; this is not an OS-level network sandbox for build scripts.
    _run(
        [
            "cargo",
            f"+{NIMBUS_RUST_TOOLCHAIN}",
            "fetch",
            "--locked",
        ],
        cwd=appservices,
        env=environment,
    )
    _reject_external_cargo_configuration(appservices)
    offline_environment = dict(environment)
    offline_environment["CARGO_NET_OFFLINE"] = "true"
    _run(
        [
            "cargo",
            f"+{NIMBUS_RUST_TOOLCHAIN}",
            "build",
            "--release",
            "--frozen",
            "-p",
            "nimbus-fml",
            "--target-dir",
            str(target_dir),
        ],
        cwd=appservices,
        env=offline_environment,
    )

    # Building executes dependency build scripts.  Re-attest every subject
    # before running the resulting generator.
    if verify_focus(str(focus)) != focus:
        raise GenerationError("Focus repository identity changed during generation")
    if verify_rust_components(str(rust_components)) != rust_components:
        raise GenerationError(
            "rust-components-swift repository identity changed during generation"
        )
    if verify_appservices(str(appservices)) != appservices:
        raise GenerationError(
            "Application Services repository identity changed during generation"
        )
    _verify_nimbus_source_mapping(rust_components, appservices)
    _reject_external_cargo_configuration(appservices)

    executable = target_dir / "release/nimbus-fml"
    _read_regular(executable, "nimbus-fml executable")
    if not os.access(executable, os.X_OK):
        raise GenerationError(f"nimbus-fml is not executable: {executable}")
    generator_environment = dict(offline_environment)
    generator_environment["MOZ_APPSERVICES_MODULE"] = "FocusAppServices"
    manifest = focus / "nimbus.fml.yaml"

    with tempfile.TemporaryDirectory(
        prefix="focus-nimbus-generated.", dir=output.parent
    ) as temp:
        temp_dir = Path(temp)
        cache = temp_dir / "cache"
        generated_dir = temp_dir / "generated"
        cache.mkdir()
        generated_dir.mkdir()
        _run(
            [str(executable), "validate", "--cache-dir", str(cache), str(manifest)],
            cwd=focus,
            env=generator_environment,
        )
        _run(
            [
                str(executable),
                "generate",
                "--channel",
                channel,
                "--language",
                "swift",
                "--cache-dir",
                str(cache),
                str(manifest),
                str(generated_dir),
            ],
            cwd=focus,
            env=generator_environment,
        )
        generated = sorted(generated_dir.iterdir(), key=lambda path: path.name)
        if [path.name for path in generated] != ["AppNimbus.swift"]:
            raise GenerationError(
                f"nimbus-fml output set changed: {[path.name for path in generated]}"
            )
        # Nimbus reads Focus and executes code compiled from Application
        # Services.  A final bracket verifies all pinned inputs still match.
        if verify_focus(str(focus)) != focus:
            raise GenerationError("Focus repository identity changed during generation")
        if verify_rust_components(str(rust_components)) != rust_components:
            raise GenerationError(
                "rust-components-swift repository identity changed during generation"
            )
        if verify_appservices(str(appservices)) != appservices:
            raise GenerationError(
                "Application Services repository identity changed during generation"
            )
        _verify_nimbus_source_mapping(rust_components, appservices)
        _reject_external_cargo_configuration(appservices)
        data = _accept_generated(
            generated[0],
            NIMBUS_OUTPUT_SHA256[channel],
            f"generated AppNimbus.swift ({channel})",
        )
    _write_new(output, data)
    return output


def _print_attestation() -> None:
    print("INPUT ATTESTATION ONLY; GENERATED-SOURCE SET IS NOT COMPLETE")
    print(f"Focus commit: {FOCUS_COMMIT}")
    print(
        f"Glean: glean-parser {GLEAN_PARSER_VERSION}, "
        f"wheel sha256={GLEAN_PARSER_WHEEL_SHA256}, "
        f"dependency lock sha256={GLEAN_DEPENDENCY_LOCK_SHA256}, "
        f"expiration date={GLEAN_REFERENCE_DATE}, output sha256={GLEAN_OUTPUT_SHA256}"
    )
    print(
        f"Nimbus: rust-components-swift {NIMBUS_PACKAGE_COMMIT} "
        f"({NIMBUS_PACKAGE_TAG}), compatible application-services candidate "
        f"{NIMBUS_APPSERVICES_COMMIT}, "
        f"Glean submodule {NIMBUS_GLEAN_SUBMODULE_COMMIT}, "
        f"Rust {NIMBUS_RUST_TOOLCHAIN}"
    )
    print(
        "INCOMPLETE - Intents: input attested; generation blocked on proprietary "
        f"intentbuilderc {INTENT_TOOLS_VERSION} ({INTENT_TOOLS_BUILD_VERSION})"
    )


def main(argv: list[str]) -> int:
    usage = (
        f"usage:\n"
        f"  {argv[0]} verify-inputs FOCUS_REPO\n"
        f"  {argv[0]} readiness FOCUS_REPO\n"
        f"  {argv[0]} glean FOCUS_REPO PYTHON GLEAN_WHEELHOUSE OUTPUT_SWIFT\n"
        f"  {argv[0]} nimbus FOCUS_REPO RUST_COMPONENTS_REPO APPSERVICES_REPO "
        "CARGO_TARGET_DIR CHANNEL OUTPUT_SWIFT"
    )
    try:
        if len(argv) == 3 and argv[1] == "verify-inputs":
            verify_focus(argv[2])
            _print_attestation()
        elif len(argv) == 3 and argv[1] == "readiness":
            verify_focus(argv[2])
            raise GenerationError(
                "generated-source set is incomplete: pinned Xcode 14.2 "
                "intentbuilderc output has not been reproduced"
            )
        elif len(argv) == 6 and argv[1] == "glean":
            output = generate_glean(argv[2], argv[3], argv[4], argv[5])
            print(f"generated {output} sha256={GLEAN_OUTPUT_SHA256}")
        elif len(argv) == 8 and argv[1] == "nimbus":
            output = generate_nimbus(
                argv[2], argv[3], argv[4], argv[5], argv[6], argv[7]
            )
            print(f"generated {output} sha256={NIMBUS_OUTPUT_SHA256[argv[6]]}")
        else:
            print(usage, file=sys.stderr)
            return 2
    except GenerationError as exc:
        print(f"REFUSED: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
