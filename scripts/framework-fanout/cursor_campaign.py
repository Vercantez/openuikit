#!/usr/bin/env python3
"""Launch and monitor a bounded Cursor Cloud framework-porting campaign.

This tool intentionally has no dotenv support.  CURSOR_API_KEY is accepted only
from the process environment, and neither the key nor raw API response bodies are
written to disk or printed.
"""

from __future__ import annotations

import argparse
import contextlib
import datetime as dt
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import tempfile
import time
from typing import Any, Iterator
import urllib.error
import urllib.parse
import urllib.request
import uuid


API_BASE = "https://api.cursor.com"
MODEL_ID = "grok-4.6"
MODEL_PARAMS = (
    {"id": "effort", "value": "high"},
    {"id": "fast", "value": "false"},
)
STATE_SCHEMA = "openuikit.cursor-framework-campaign-state.v1"
AGENT_NAMESPACE = uuid.UUID("52d658c7-78c5-4e96-bdd7-d72cf3aa824c")
MAX_CREATE_RATE = 12
ACTIVE_AGENT_STATUSES = frozenset({"ACTIVE"})
TERMINAL_RUN_STATUSES = frozenset({"FINISHED", "ERROR", "CANCELLED", "EXPIRED"})
UUID_RE = re.compile(
    r"^bc-[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"
)
SLUG_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


class CampaignError(RuntimeError):
    """A safe, user-facing campaign error."""


class ApiError(CampaignError):
    def __init__(self, status: int, code: str, message: str):
        self.status = status
        self.code = code
        super().__init__(f"Cursor API returned HTTP {status} ({code}): {message}")


def utc_now() -> dt.datetime:
    return dt.datetime.now(dt.timezone.utc)


def isoformat(value: dt.datetime | None = None) -> str:
    return (value or utc_now()).isoformat(timespec="seconds").replace("+00:00", "Z")


def parse_time(value: str) -> dt.datetime:
    try:
        parsed = dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except (TypeError, ValueError) as exc:
        raise CampaignError(f"invalid timestamp in campaign state: {value!r}") from exc
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=dt.timezone.utc)
    return parsed.astimezone(dt.timezone.utc)


def sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def json_digest(value: Any) -> str:
    encoded = json.dumps(value, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise CampaignError(message)


def require_string(value: Any, label: str, *, maximum: int | None = None) -> str:
    require(isinstance(value, str) and bool(value.strip()), f"{label} must be a non-empty string")
    result = value.strip()
    if maximum is not None:
        require(len(result) <= maximum, f"{label} must be at most {maximum} characters")
    return result


def require_integer(value: Any, label: str, *, minimum: int = 0) -> int:
    require(isinstance(value, int) and not isinstance(value, bool), f"{label} must be an integer")
    require(value >= minimum, f"{label} must be at least {minimum}")
    return value


def require_string_list(value: Any, label: str, *, nonempty: bool = False) -> list[str]:
    require(isinstance(value, list), f"{label} must be an array")
    if nonempty:
        require(bool(value), f"{label} must not be empty")
    result: list[str] = []
    for index, item in enumerate(value):
        result.append(require_string(item, f"{label}[{index}]"))
    require(len(result) == len(set(result)), f"{label} must not contain duplicates")
    return result


def safe_relative_path(value: Any, label: str) -> str:
    result = require_string(value, label)
    path = Path(result)
    require(not path.is_absolute(), f"{label} must be repository-relative")
    require(".." not in path.parts, f"{label} must not contain '..'")
    require(result not in {".", ""}, f"{label} must identify a file or directory")
    return path.as_posix()


def framework_order(framework: dict[str, Any]) -> tuple[int, str]:
    """Higher numeric priority launches first; slugs make ties deterministic."""

    return (-framework["priority"], framework["slug"])


def find_repo_root(start: Path) -> Path:
    for candidate in (start, *start.parents):
        if (candidate / ".git").exists():
            return candidate.resolve()
    raise CampaignError(f"could not find repository root above {start}")


def load_json(path: Path, label: str) -> Any:
    try:
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    except FileNotFoundError as exc:
        raise CampaignError(f"{label} does not exist: {path}") from exc
    except json.JSONDecodeError as exc:
        raise CampaignError(f"{label} is not valid JSON at line {exc.lineno}, column {exc.colno}") from exc


def normalize_manifest(path: Path) -> dict[str, Any]:
    raw = load_json(path, "campaign manifest")
    require(isinstance(raw, dict), "campaign manifest must be a JSON object")
    for key in ("schema", "campaign", "repository", "defaults", "frameworks"):
        require(key in raw, f"campaign manifest is missing top-level field {key!r}")

    schema_value = raw["schema"]
    if isinstance(schema_value, int) and not isinstance(schema_value, bool):
        require(schema_value == 1, "numeric campaign schema must be 1")
        schema: str | int = schema_value
    else:
        schema = require_string(schema_value, "schema")
    campaign = raw["campaign"]
    repository = raw["repository"]
    defaults = raw["defaults"]
    frameworks = raw["frameworks"]
    require(isinstance(campaign, dict), "campaign must be an object")
    require(isinstance(repository, dict), "repository must be an object")
    require(isinstance(defaults, dict), "defaults must be an object")
    require(isinstance(frameworks, list) and bool(frameworks), "frameworks must be a non-empty array")

    normalized_campaign = {
        "id": require_string(campaign.get("id"), "campaign.id"),
        "startingSha": require_string(campaign.get("startingSha"), "campaign.startingSha"),
        "activeBuildId": require_string(campaign.get("activeBuildId"), "campaign.activeBuildId"),
        "environmentMarker": require_string(
            campaign.get("environmentMarker"), "campaign.environmentMarker"
        ),
    }
    require(
        bool(re.fullmatch(r"[0-9a-fA-F]{40}", normalized_campaign["startingSha"])),
        "campaign.startingSha must be a full 40-character Git SHA",
    )

    repository_url = require_string(repository.get("url"), "repository.url")
    parsed_repo = urllib.parse.urlsplit(repository_url)
    require(
        parsed_repo.scheme == "https" and parsed_repo.netloc == "github.com" and not parsed_repo.query,
        "repository.url must be an https://github.com URL without a query string",
    )
    normalized_repository = {
        "url": repository_url.rstrip("/"),
        "startingRef": require_string(repository.get("startingRef"), "repository.startingRef"),
    }

    expected_default_keys = (
        "modelId",
        "effort",
        "fast",
        "maxActive",
        "createRatePerMinute",
        "maxRepairRuns",
        "timeoutMinutes",
        "autoCreatePR",
        "skipReviewerRequest",
    )
    for key in expected_default_keys:
        require(key in defaults, f"defaults is missing field {key!r}")
    require(defaults["modelId"] == MODEL_ID, f"defaults.modelId must be {MODEL_ID!r}")
    require(defaults["effort"] == "high", "defaults.effort must be 'high'")
    require(defaults["fast"] is False, "defaults.fast must be false")
    require(defaults["autoCreatePR"] is True, "defaults.autoCreatePR must be true")
    require(defaults["skipReviewerRequest"] is True, "defaults.skipReviewerRequest must be true")
    create_rate = require_integer(
        defaults["createRatePerMinute"], "defaults.createRatePerMinute", minimum=1
    )
    require(
        create_rate <= MAX_CREATE_RATE,
        f"defaults.createRatePerMinute must not exceed the safety cap of {MAX_CREATE_RATE}",
    )
    normalized_defaults = {
        "modelId": MODEL_ID,
        "effort": "high",
        "fast": False,
        "maxActive": require_integer(defaults["maxActive"], "defaults.maxActive", minimum=1),
        "createRatePerMinute": create_rate,
        "maxRepairRuns": require_integer(defaults["maxRepairRuns"], "defaults.maxRepairRuns"),
        "timeoutMinutes": require_integer(defaults["timeoutMinutes"], "defaults.timeoutMinutes", minimum=1),
        "autoCreatePR": True,
        "skipReviewerRequest": True,
    }

    normalized_frameworks: list[dict[str, Any]] = []
    seen_modules: set[str] = set()
    seen_slugs: set[str] = set()
    seen_names: set[str] = set()
    for index, framework in enumerate(frameworks):
        label = f"frameworks[{index}]"
        require(isinstance(framework, dict), f"{label} must be an object")
        for key in (
            "module",
            "slug",
            "lane",
            "priority",
            "agentName",
            "taskPath",
            "ownedPaths",
            "editablePaths",
            "immutableDigest",
            "gate",
            "expectedMarkers",
            "dependencies",
            "symbolCount",
            "risks",
        ):
            require(key in framework, f"{label} is missing field {key!r}")
        module = require_string(framework["module"], f"{label}.module")
        slug = require_string(framework["slug"], f"{label}.slug")
        require(bool(SLUG_RE.fullmatch(slug)), f"{label}.slug must be lowercase kebab-case")
        agent_name = require_string(framework["agentName"], f"{label}.agentName", maximum=100)
        require(module not in seen_modules, f"duplicate framework module {module!r}")
        require(slug not in seen_slugs, f"duplicate framework slug {slug!r}")
        require(agent_name not in seen_names, f"duplicate agentName {agent_name!r}")
        seen_modules.add(module)
        seen_slugs.add(slug)
        seen_names.add(agent_name)

        prompt = framework.get("prompt")
        if prompt is not None:
            prompt = require_string(prompt, f"{label}.prompt")
        immutable_digest = require_string(framework["immutableDigest"], f"{label}.immutableDigest")
        require(
            bool(re.fullmatch(r"(?:sha256:)?[0-9a-fA-F]{64}", immutable_digest)),
            f"{label}.immutableDigest must be a SHA-256 digest",
        )
        normalized_frameworks.append(
            {
                "module": module,
                "slug": slug,
                "lane": require_string(framework["lane"], f"{label}.lane"),
                "priority": require_integer(framework["priority"], f"{label}.priority"),
                "agentName": agent_name,
                "taskPath": safe_relative_path(framework["taskPath"], f"{label}.taskPath"),
                "ownedPaths": [
                    safe_relative_path(item, f"{label}.ownedPaths[{item_index}]")
                    for item_index, item in enumerate(
                        require_string_list(framework["ownedPaths"], f"{label}.ownedPaths", nonempty=True)
                    )
                ],
                "editablePaths": [
                    safe_relative_path(item, f"{label}.editablePaths[{item_index}]")
                    for item_index, item in enumerate(
                        require_string_list(
                            framework["editablePaths"], f"{label}.editablePaths", nonempty=True
                        )
                    )
                ],
                "immutableDigest": immutable_digest.lower(),
                "gate": require_string(framework["gate"], f"{label}.gate"),
                "expectedMarkers": require_string_list(
                    framework["expectedMarkers"], f"{label}.expectedMarkers", nonempty=True
                ),
                "dependencies": require_string_list(
                    framework["dependencies"], f"{label}.dependencies"
                ),
                "symbolCount": require_integer(framework["symbolCount"], f"{label}.symbolCount"),
                "risks": require_string_list(framework["risks"], f"{label}.risks"),
                "prompt": prompt,
            }
        )

    repo_root = find_repo_root(path.resolve().parent)
    for framework in normalized_frameworks:
        task = (repo_root / framework["taskPath"]).resolve()
        try:
            task.relative_to(repo_root)
        except ValueError as exc:
            raise CampaignError(
                f"taskPath escapes repository through a symlink: {framework['taskPath']}"
            ) from exc
        require(task.is_file(), f"taskPath does not exist: {framework['taskPath']}")

    return {
        "schema": schema,
        "campaign": normalized_campaign,
        "repository": normalized_repository,
        "defaults": normalized_defaults,
        "frameworks": sorted(normalized_frameworks, key=framework_order),
        "repoRoot": str(repo_root),
        "manifestPath": str(path.resolve()),
        "manifestDigest": json_digest(raw),
    }


def agent_id_for(manifest: dict[str, Any], framework: dict[str, Any]) -> str:
    identity = "\n".join(
        (
            "openuikit-cursor-framework-campaign-v1",
            manifest["repository"]["url"],
            manifest["campaign"]["id"],
            manifest["campaign"]["startingSha"].lower(),
            framework["slug"],
        )
    )
    return f"bc-{uuid.uuid5(AGENT_NAMESPACE, identity)}"


def format_list(values: list[str]) -> str:
    return "\n".join(f"  - {value}" for value in values) if values else "  - (none)"


def standard_prompt(manifest: dict[str, Any], framework: dict[str, Any]) -> str:
    if framework.get("prompt"):
        return framework["prompt"]
    campaign = manifest["campaign"]
    defaults = manifest["defaults"]
    return f"""Implement the {framework['module']} framework starting point for the OpenUIKit Linux platform.

Your authoritative task specification is `{framework['taskPath']}`. Read that file completely before editing and follow it exactly. This is an implementation run, not a planning-only run.

Campaign invariants:
  - campaign: {campaign['id']}
  - expected starting commit: {campaign['startingSha']}
  - expected active Cursor Build: {campaign['activeBuildId']}
  - required environment marker: {campaign['environmentMarker']}
  - framework: {framework['module']}
  - lane: {framework['lane']}
  - immutable input digest: {framework['immutableDigest']}
  - known symbol count: {framework['symbolCount']}
  - maximum repair passes: {defaults['maxRepairRuns']}
  - time budget: {defaults['timeoutMinutes']} minutes

Before making changes, verify `git rev-parse HEAD` is exactly the expected starting commit and run `.cursor/verify-cloud-environment.sh`. Stop and report the mismatch without editing if either the commit or required environment marker is wrong.

Owned paths:
{format_list(framework['ownedPaths'])}

Editable paths:
{format_list(framework['editablePaths'])}

Dependencies:
{format_list(framework['dependencies'])}

Known risks:
{format_list(framework['risks'])}

Stay strictly inside the editable paths. Never edit pinned headers, symbol graphs, .tbd inputs, provenance ledgers, acceptance programs, campaign files, or unrelated app/framework source. Do not weaken, replace, or skip the supplied gate. Do not fabricate successful Apple-only behavior: use an explicit fail-closed boundary where the task requires one.

Implement the strongest useful Linux starting point supported by the pinned corpus, then run this exact gate:

  {framework['gate']}

The final run output must include every expected marker:
{format_list(framework['expectedMarkers'])}

Commit all in-scope implementation and test changes on the Cursor-created branch. Do not merge. Summarize the public surface implemented, fail-closed boundaries, tests run, exact marker output, and any unresolved behavioral questions so central review can audit the pull request."""


def create_payload(manifest: dict[str, Any], framework: dict[str, Any]) -> dict[str, Any]:
    return {
        "agentId": agent_id_for(manifest, framework),
        "name": framework["agentName"],
        "prompt": {"text": standard_prompt(manifest, framework)},
        "model": {"id": MODEL_ID, "params": [dict(item) for item in MODEL_PARAMS]},
        "repos": [
            {
                "url": manifest["repository"]["url"],
                "startingRef": manifest["repository"]["startingRef"],
            }
        ],
        "workOnCurrentBranch": False,
        "autoCreatePR": True,
        "skipReviewerRequest": True,
        "mode": "agent",
    }


def initial_state(manifest: dict[str, Any]) -> dict[str, Any]:
    frameworks: dict[str, Any] = {}
    for framework in manifest["frameworks"]:
        frameworks[framework["slug"]] = {
            "module": framework["module"],
            "lane": framework["lane"],
            "priority": framework["priority"],
            "agentName": framework["agentName"],
            "agentId": agent_id_for(manifest, framework),
            "launchStatus": "PENDING",
            "agentStatus": None,
            "runId": None,
            "runStatus": None,
            "agentUrl": None,
            "branches": [],
        }
    return {
        "schema": STATE_SCHEMA,
        "campaign": {
            "id": manifest["campaign"]["id"],
            "startingSha": manifest["campaign"]["startingSha"],
            "activeBuildId": manifest["campaign"]["activeBuildId"],
            "environmentMarker": manifest["campaign"]["environmentMarker"],
            "manifestSha256": manifest["manifestDigest"],
        },
        "repository": dict(manifest["repository"]),
        "model": {"id": MODEL_ID, "effort": "high", "fast": False},
        "createdAt": isoformat(),
        "updatedAt": isoformat(),
        "createAttemptTimestamps": [],
        "frameworks": frameworks,
    }


def validate_and_merge_state(state: Any, manifest: dict[str, Any]) -> dict[str, Any]:
    require(isinstance(state, dict), "campaign state must be a JSON object")
    require(state.get("schema") == STATE_SCHEMA, f"campaign state schema must be {STATE_SCHEMA!r}")
    require(isinstance(state.get("campaign"), dict), "campaign state is missing campaign metadata")
    require(
        state["campaign"].get("id") == manifest["campaign"]["id"],
        "campaign state belongs to a different campaign",
    )
    require(
        state["campaign"].get("startingSha") == manifest["campaign"]["startingSha"],
        "campaign starting SHA changed; use a new campaign id/state file",
    )
    require(state.get("repository") == manifest["repository"], "campaign repository changed")
    require(
        state.get("model") == {"id": MODEL_ID, "effort": "high", "fast": False},
        "campaign state model selection is not the required Grok 4.6 configuration",
    )
    require(isinstance(state.get("frameworks"), dict), "campaign state frameworks must be an object")
    require(
        isinstance(state.get("createAttemptTimestamps"), list),
        "campaign state createAttemptTimestamps must be an array",
    )
    for timestamp in state["createAttemptTimestamps"]:
        require(isinstance(timestamp, str), "campaign state contains a non-string create timestamp")
        parse_time(timestamp)

    for framework in manifest["frameworks"]:
        expected = initial_state({**manifest, "frameworks": [framework]})["frameworks"][framework["slug"]]
        existing = state["frameworks"].get(framework["slug"])
        if existing is None:
            state["frameworks"][framework["slug"]] = expected
            continue
        require(isinstance(existing, dict), f"state for {framework['slug']} must be an object")
        for field in ("module", "lane", "priority", "agentName", "agentId"):
            require(
                existing.get(field) == expected[field],
                f"state identity mismatch for {framework['slug']}.{field}",
            )
        require(bool(UUID_RE.fullmatch(existing["agentId"])), f"invalid agent id for {framework['slug']}")

    manifest_slugs = {item["slug"] for item in manifest["frameworks"]}
    extra_slugs = set(state["frameworks"]) - manifest_slugs
    require(not extra_slugs, f"campaign state contains frameworks absent from manifest: {sorted(extra_slugs)}")
    state["campaign"]["manifestSha256"] = manifest["manifestDigest"]
    state["campaign"]["activeBuildId"] = manifest["campaign"]["activeBuildId"]
    state["campaign"]["environmentMarker"] = manifest["campaign"]["environmentMarker"]
    return state


def default_state_path(manifest_path: Path) -> Path:
    return manifest_path.with_name(f"{manifest_path.stem}.state.json")


def state_path_for(args: argparse.Namespace, manifest_path: Path) -> Path:
    return Path(args.state).expanduser().resolve() if args.state else default_state_path(manifest_path)


def load_or_initialize_state(path: Path, manifest: dict[str, Any]) -> dict[str, Any]:
    if path.exists():
        require(not path.is_symlink(), f"refusing to use symlink as campaign state: {path}")
        return validate_and_merge_state(load_json(path, "campaign state"), manifest)
    return initial_state(manifest)


def write_state_atomic(path: Path, state: dict[str, Any]) -> None:
    if path.exists():
        require(not path.is_symlink(), f"refusing to replace symlink campaign state: {path}")
    path.parent.mkdir(parents=True, exist_ok=True)
    state["updatedAt"] = isoformat()
    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    temporary_path = Path(temporary_name)
    try:
        os.fchmod(descriptor, 0o600)
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            json.dump(state, handle, indent=2, sort_keys=True)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary_path, path)
        directory_descriptor = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory_descriptor)
        finally:
            os.close(directory_descriptor)
    finally:
        if temporary_path.exists():
            temporary_path.unlink()


@contextlib.contextmanager
def campaign_lock(state_path: Path) -> Iterator[None]:
    state_path.parent.mkdir(parents=True, exist_ok=True)
    lock_path = state_path.with_name(f".{state_path.name}.lock")
    with lock_path.open("a", encoding="utf-8") as handle:
        fcntl.flock(handle.fileno(), fcntl.LOCK_EX)
        try:
            yield
        finally:
            fcntl.flock(handle.fileno(), fcntl.LOCK_UN)


def safe_message(value: Any, secret: str | None = None) -> str:
    result = str(value)
    if secret:
        result = result.replace(secret, "[REDACTED]")
    result = re.sub(r"(?i)(authorization\s*[:=]\s*)(?:bearer\s+)?\S+", r"\1[REDACTED]", result)
    return result[:1000]


class CursorApi:
    def __init__(self, key: str, *, timeout_seconds: int = 60):
        require(bool(key.strip()), "CURSOR_API_KEY is empty")
        self._key = key.strip()
        self._timeout = timeout_seconds

    @classmethod
    def from_environment(cls) -> "CursorApi":
        key = os.environ.get("CURSOR_API_KEY")
        require(key is not None, "CURSOR_API_KEY must be set in the process environment")
        return cls(key)

    def request(self, method: str, path: str, body: Any | None = None) -> Any:
        require(path.startswith("/v1/"), "internal error: only Cursor v1 endpoints are allowed")
        encoded: bytes | None = None
        headers = {
            "Accept": "application/json",
            "Authorization": f"Bearer {self._key}",
            "User-Agent": "OpenUIKit-Cursor-Framework-Campaign/1",
        }
        if body is not None:
            encoded = json.dumps(body, separators=(",", ":")).encode("utf-8")
            headers["Content-Type"] = "application/json"
        request = urllib.request.Request(
            f"{API_BASE}{path}", data=encoded, headers=headers, method=method
        )
        try:
            with urllib.request.urlopen(request, timeout=self._timeout) as response:
                response_body = response.read(4 * 1024 * 1024)
        except urllib.error.HTTPError as exc:
            raw = exc.read(1024 * 1024)
            code = "http_error"
            message = exc.reason or "request failed"
            try:
                parsed = json.loads(raw.decode("utf-8"))
                if isinstance(parsed, dict):
                    code = safe_message(parsed.get("code", code), self._key)
                    message = safe_message(parsed.get("message", message), self._key)
            except (UnicodeDecodeError, json.JSONDecodeError):
                pass
            raise ApiError(exc.code, code, message) from None
        except urllib.error.URLError as exc:
            raise CampaignError(
                f"Cursor API request failed: {safe_message(exc.reason, self._key)}"
            ) from None
        if not response_body:
            return {}
        try:
            return json.loads(response_body.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise CampaignError("Cursor API returned a non-JSON response") from exc

    def validate_required_model(self) -> None:
        validate_model_response(self.request("GET", "/v1/models"))

    def create_agent(self, payload: dict[str, Any]) -> dict[str, Any]:
        response = self.request("POST", "/v1/agents", payload)
        require(isinstance(response, dict), "create-agent response must be an object")
        return response

    def get_agent(self, agent_id: str) -> dict[str, Any]:
        require(bool(UUID_RE.fullmatch(agent_id)), f"invalid Cursor agent id: {agent_id!r}")
        response = self.request("GET", f"/v1/agents/{urllib.parse.quote(agent_id)}")
        require(isinstance(response, dict), "get-agent response must be an object")
        return response

    def get_run(self, agent_id: str, run_id: str) -> dict[str, Any]:
        require(run_id.startswith("run-"), f"invalid Cursor run id: {run_id!r}")
        response = self.request(
            "GET",
            f"/v1/agents/{urllib.parse.quote(agent_id)}/runs/{urllib.parse.quote(run_id)}",
        )
        require(isinstance(response, dict), "get-run response must be an object")
        return response

    def list_agents(self) -> list[dict[str, Any]]:
        items: list[dict[str, Any]] = []
        cursor: str | None = None
        for _ in range(100):
            query: dict[str, str] = {"limit": "100", "includeArchived": "false"}
            if cursor:
                query["cursor"] = cursor
            response = self.request("GET", f"/v1/agents?{urllib.parse.urlencode(query)}")
            require(isinstance(response, dict), "list-agents response must be an object")
            page = response.get("items")
            require(isinstance(page, list), "list-agents response is missing items")
            items.extend(item for item in page if isinstance(item, dict))
            cursor_value = response.get("nextCursor")
            if cursor_value is None:
                return items
            cursor = require_string(cursor_value, "list-agents nextCursor")
        raise CampaignError("list-agents pagination exceeded 100 pages")

    def archive_agent(self, agent_id: str) -> None:
        require(bool(UUID_RE.fullmatch(agent_id)), f"invalid Cursor agent id: {agent_id!r}")
        self.request("POST", f"/v1/agents/{urllib.parse.quote(agent_id)}/archive")


def values_for_parameter(parameter: dict[str, Any]) -> set[str]:
    values = parameter.get("values", [])
    if not isinstance(values, list):
        return set()
    result: set[str] = set()
    for item in values:
        value = item.get("value") if isinstance(item, dict) else item
        if isinstance(value, bool):
            result.add(str(value).lower())
        elif isinstance(value, (str, int, float)):
            result.add(str(value))
    return result


def validate_model_response(response: Any) -> None:
    require(isinstance(response, dict), "list-models response must be an object")
    items = response.get("items")
    require(isinstance(items, list), "list-models response is missing items")
    model = next(
        (item for item in items if isinstance(item, dict) and item.get("id") == MODEL_ID), None
    )
    require(model is not None, f"required Cursor model {MODEL_ID!r} is not available")
    expected = {item["id"]: item["value"] for item in MODEL_PARAMS}

    variants = model.get("variants")
    if isinstance(variants, list) and variants:
        for variant in variants:
            if not isinstance(variant, dict) or not isinstance(variant.get("params"), list):
                continue
            actual = {
                item.get("id"): str(item.get("value")).lower()
                for item in variant["params"]
                if isinstance(item, dict) and isinstance(item.get("id"), str)
            }
            if all(actual.get(key) == value for key, value in expected.items()):
                return

    definitions = model.get("parameters")
    if not isinstance(definitions, list):
        definitions = model.get("params")
    require(isinstance(definitions, list), f"{MODEL_ID} has no parameter metadata")
    by_id = {
        item.get("id"): item
        for item in definitions
        if isinstance(item, dict) and isinstance(item.get("id"), str)
    }
    for parameter_id, expected_value in expected.items():
        require(parameter_id in by_id, f"{MODEL_ID} does not advertise parameter {parameter_id!r}")
        require(
            expected_value in values_for_parameter(by_id[parameter_id]),
            f"{MODEL_ID} does not support {parameter_id}={expected_value}",
        )


def sanitized_url(value: Any) -> str | None:
    if not isinstance(value, str) or not value:
        return None
    parsed = urllib.parse.urlsplit(value)
    if parsed.scheme not in {"http", "https"} or not parsed.hostname:
        return None
    host = parsed.hostname
    if parsed.port:
        host = f"{host}:{parsed.port}"
    return urllib.parse.urlunsplit((parsed.scheme, host, parsed.path, "", ""))


def sanitized_branches(run: dict[str, Any]) -> list[dict[str, str]]:
    git = run.get("git")
    branches = git.get("branches") if isinstance(git, dict) else None
    if not isinstance(branches, list):
        return []
    result: list[dict[str, str]] = []
    for branch in branches:
        if not isinstance(branch, dict):
            continue
        clean: dict[str, str] = {}
        for key in ("repoUrl", "branch"):
            if isinstance(branch.get(key), str):
                clean[key] = branch[key][:500]
        pr_url = sanitized_url(branch.get("prUrl"))
        if pr_url:
            clean["prUrl"] = pr_url
        if clean:
            result.append(clean)
    return result


def update_entry_from_remote(
    api: CursorApi, entry: dict[str, Any], *, tolerate_missing: bool = False
) -> None:
    try:
        agent = api.get_agent(entry["agentId"])
    except ApiError as exc:
        if tolerate_missing and exc.status == 404:
            entry["launchStatus"] = "PENDING"
            entry["agentStatus"] = None
            entry["runId"] = None
            entry["runStatus"] = None
            return
        raise
    require(agent.get("id") == entry["agentId"], "Cursor returned a mismatched agent id")
    entry["launchStatus"] = "CREATED"
    entry["agentStatus"] = require_string(agent.get("status"), "agent.status")
    entry["agentUrl"] = sanitized_url(agent.get("url"))
    run_id = agent.get("latestRunId")
    if not isinstance(run_id, str) or not run_id:
        return
    run = api.get_run(entry["agentId"], run_id)
    require(run.get("id") == run_id, "Cursor returned a mismatched run id")
    entry["runId"] = run_id
    entry["runStatus"] = require_string(run.get("status"), "run.status")
    for field in ("createdAt", "updatedAt", "durationMs"):
        if isinstance(run.get(field), (str, int)):
            entry[f"run{field[0].upper()}{field[1:]}"] = run[field]
    entry["branches"] = sanitized_branches(run)
    result = run.get("result")
    if isinstance(result, str):
        entry["resultSha256"] = sha256_text(result)
        entry["resultBytes"] = len(result.encode("utf-8"))


def refresh_campaign(api: CursorApi, state: dict[str, Any], state_path: Path) -> None:
    for slug in sorted(state["frameworks"]):
        entry = state["frameworks"][slug]
        if entry.get("launchStatus") == "PENDING" and not entry.get("launchAttemptedAt"):
            continue
        update_entry_from_remote(api, entry, tolerate_missing=True)
        write_state_atomic(state_path, state)


def prune_create_attempts(state: dict[str, Any], now: dt.datetime) -> list[dt.datetime]:
    cutoff = now - dt.timedelta(seconds=60)
    recent = [parse_time(value) for value in state["createAttemptTimestamps"]]
    recent = sorted(value for value in recent if value > cutoff)
    state["createAttemptTimestamps"] = [isoformat(value) for value in recent]
    return recent


def wait_for_create_slot(state: dict[str, Any], rate: int, state_path: Path) -> None:
    while True:
        now = utc_now()
        recent = prune_create_attempts(state, now)
        if len(recent) < rate:
            return
        wait_seconds = max(0.0, (recent[0] + dt.timedelta(seconds=60.25) - now).total_seconds())
        if wait_seconds <= 0:
            continue
        print(f"rate-limit: waiting {wait_seconds:.1f}s before next create", flush=True)
        write_state_atomic(state_path, state)
        time.sleep(wait_seconds)


def record_create_attempt(state: dict[str, Any], entry: dict[str, Any], state_path: Path) -> None:
    now = isoformat()
    state["createAttemptTimestamps"].append(now)
    entry["launchAttemptedAt"] = now
    entry["launchStatus"] = "CREATING"
    write_state_atomic(state_path, state)


def adopt_create_response(entry: dict[str, Any], response: dict[str, Any]) -> None:
    agent = response.get("agent")
    run = response.get("run")
    require(isinstance(agent, dict), "create-agent response is missing agent")
    require(isinstance(run, dict), "create-agent response is missing run")
    require(agent.get("id") == entry["agentId"], "Cursor created an unexpected agent id")
    run_id = require_string(run.get("id"), "create-agent run.id")
    require(run_id.startswith("run-"), "Cursor returned an invalid run id")
    entry["launchStatus"] = "CREATED"
    entry["agentStatus"] = require_string(agent.get("status"), "create-agent agent.status")
    entry["runId"] = run_id
    entry["runStatus"] = require_string(run.get("status"), "create-agent run.status")
    entry["agentUrl"] = sanitized_url(agent.get("url"))
    entry["branches"] = []


def print_status(state: dict[str, Any]) -> None:
    entries = sorted(
        state["frameworks"].items(), key=lambda pair: (-pair[1]["priority"], pair[0])
    )
    counts: dict[str, int] = {}
    for _, entry in entries:
        key = entry.get("runStatus") or entry.get("agentStatus") or entry.get("launchStatus") or "UNKNOWN"
        counts[key] = counts.get(key, 0) + 1
    rendered_counts = " ".join(f"{key}={counts[key]}" for key in sorted(counts))
    print(f"campaign={state['campaign']['id']} total={len(entries)} {rendered_counts}".rstrip())
    print(f"{'PRIORITY':>8}  {'MODULE':<28}  {'AGENT':<10}  {'RUN':<10}  PR")
    for _, entry in entries:
        pr_urls = [branch["prUrl"] for branch in entry.get("branches", []) if branch.get("prUrl")]
        print(
            f"{entry['priority']:>8}  {entry['module'][:28]:<28}  "
            f"{str(entry.get('agentStatus') or '-')[:10]:<10}  "
            f"{str(entry.get('runStatus') or '-')[:10]:<10}  "
            f"{pr_urls[0] if pr_urls else '-'}"
        )


def command_dry_run(args: argparse.Namespace) -> int:
    manifest_path = Path(args.manifest).expanduser().resolve()
    manifest = normalize_manifest(manifest_path)
    rows = []
    for framework in manifest["frameworks"]:
        payload = create_payload(manifest, framework)
        rows.append(
            {
                "priority": framework["priority"],
                "module": framework["module"],
                "slug": framework["slug"],
                "agentId": payload["agentId"],
                "agentName": payload["name"],
                "promptBytes": len(payload["prompt"]["text"].encode("utf-8")),
                "promptSha256": sha256_text(payload["prompt"]["text"]),
                "taskPath": framework["taskPath"],
            }
        )
    summary = {
        "campaign": manifest["campaign"]["id"],
        "repository": manifest["repository"],
        "model": {"id": MODEL_ID, "effort": "high", "fast": False},
        "maxActive": manifest["defaults"]["maxActive"],
        "createRatePerMinute": manifest["defaults"]["createRatePerMinute"],
        "frameworks": rows,
    }
    if args.json:
        print(json.dumps(summary, indent=2, sort_keys=True))
    else:
        print(
            f"DRY_RUN campaign={summary['campaign']} frameworks={len(rows)} "
            f"maxActive={summary['maxActive']} createsPerMinute={summary['createRatePerMinute']}"
        )
        for row in rows:
            print(
                f"{row['priority']:>4} {row['module']:<28} {row['agentId']} "
                f"prompt={row['promptBytes']}B/{row['promptSha256'][:12]}"
            )
    return 0


def effective_max_active(args: argparse.Namespace, manifest: dict[str, Any]) -> int:
    configured = manifest["defaults"]["maxActive"]
    if args.max_active is None:
        return configured
    require(args.max_active >= 1, "--max-active must be at least 1")
    require(
        args.max_active <= configured,
        "--max-active may lower but not raise the audited manifest default",
    )
    return args.max_active


def command_launch(args: argparse.Namespace) -> int:
    manifest_path = Path(args.manifest).expanduser().resolve()
    manifest = normalize_manifest(manifest_path)
    state_path = state_path_for(args, manifest_path)
    max_active = effective_max_active(args, manifest)
    require(args.limit is None or args.limit >= 1, "--limit must be at least 1")
    require(args.poll_seconds >= 10, "--poll-seconds must be at least 10")
    api = CursorApi.from_environment()
    print(f"validating {MODEL_ID} effort=high fast=false availability...", flush=True)
    api.validate_required_model()

    with campaign_lock(state_path):
        state = load_or_initialize_state(state_path, manifest)
        write_state_atomic(state_path, state)
        launched_this_invocation = 0
        while True:
            refresh_campaign(api, state, state_path)
            pending = [
                framework
                for framework in manifest["frameworks"]
                if state["frameworks"][framework["slug"]].get("launchStatus") == "PENDING"
            ]
            if not pending:
                print("launch: every framework has a durable Cursor agent id")
                print_status(state)
                return 0
            if args.limit is not None and launched_this_invocation >= args.limit:
                print(f"launch: reached invocation limit={args.limit}")
                print_status(state)
                return 0

            all_agents = api.list_agents()
            active_count = sum(
                1 for item in all_agents if item.get("status") in ACTIVE_AGENT_STATUSES
            )
            capacity = max_active - active_count
            if capacity <= 0:
                if not args.watch:
                    print(
                        f"launch: no capacity (active={active_count}, maxActive={max_active}); "
                        "rerun later or use --watch"
                    )
                    print_status(state)
                    return 0
                print(
                    f"launch: active={active_count}/{max_active}; polling again in "
                    f"{args.poll_seconds}s",
                    flush=True,
                )
                write_state_atomic(state_path, state)
                time.sleep(args.poll_seconds)
                continue

            batch = pending[:capacity]
            if args.limit is not None:
                batch = batch[: args.limit - launched_this_invocation]
            for framework in batch:
                entry = state["frameworks"][framework["slug"]]
                wait_for_create_slot(
                    state,
                    manifest["defaults"]["createRatePerMinute"],
                    state_path,
                )
                record_create_attempt(state, entry, state_path)
                payload = create_payload(manifest, framework)
                try:
                    response = api.create_agent(payload)
                    adopt_create_response(entry, response)
                except ApiError as exc:
                    if exc.status != 409:
                        entry["launchStatus"] = "CREATE_ERROR"
                        entry["lastError"] = {"httpStatus": exc.status, "code": exc.code}
                        write_state_atomic(state_path, state)
                        raise
                    # A deterministic id makes an interrupted or repeated create recoverable.
                    update_entry_from_remote(api, entry)
                entry.pop("lastError", None)
                write_state_atomic(state_path, state)
                launched_this_invocation += 1
                print(
                    f"launched module={framework['module']} agent={entry['agentId']} "
                    f"run={entry.get('runId') or '-'}",
                    flush=True,
                )
            if not args.watch:
                print_status(state)
                return 0


def command_status(args: argparse.Namespace) -> int:
    manifest_path = Path(args.manifest).expanduser().resolve()
    manifest = normalize_manifest(manifest_path)
    state_path = state_path_for(args, manifest_path)
    api = CursorApi.from_environment()
    with campaign_lock(state_path):
        state = load_or_initialize_state(state_path, manifest)
        refresh_campaign(api, state, state_path)
        write_state_atomic(state_path, state)
        if args.json:
            print(json.dumps(state, indent=2, sort_keys=True))
        else:
            print_status(state)
    return 0


def command_archive_completed(args: argparse.Namespace) -> int:
    manifest_path = Path(args.manifest).expanduser().resolve()
    manifest = normalize_manifest(manifest_path)
    state_path = state_path_for(args, manifest_path)
    api = CursorApi.from_environment()
    archived = 0
    with campaign_lock(state_path):
        state = load_or_initialize_state(state_path, manifest)
        refresh_campaign(api, state, state_path)
        for framework in manifest["frameworks"]:
            entry = state["frameworks"][framework["slug"]]
            if entry.get("runStatus") != "FINISHED" or entry.get("agentStatus") == "ARCHIVED":
                continue
            api.archive_agent(entry["agentId"])
            entry["agentStatus"] = "ARCHIVED"
            entry["archivedAt"] = isoformat()
            write_state_atomic(state_path, state)
            archived += 1
            print(f"archived module={entry['module']} agent={entry['agentId']}")
        write_state_atomic(state_path, state)
        print(f"archive-completed: archived={archived}; permanent deletion is never used")
        if args.json:
            print(json.dumps(state, indent=2, sort_keys=True))
    return 0


def command_self_check(_: argparse.Namespace) -> int:
    synthetic_manifest = {
        "campaign": {
            "id": "self-check",
            "startingSha": "1" * 40,
            "activeBuildId": "build-self-check",
            "environmentMarker": "CURSOR_SWIFT_ENVIRONMENT_OK",
        },
        "repository": {
            "url": "https://github.com/example/openuikit",
            "startingRef": "self-check",
        },
        "defaults": {
            "modelId": MODEL_ID,
            "effort": "high",
            "fast": False,
            "maxActive": 4,
            "createRatePerMinute": 12,
            "maxRepairRuns": 2,
            "timeoutMinutes": 60,
            "autoCreatePR": True,
            "skipReviewerRequest": True,
        },
        "frameworks": [],
        "manifestDigest": "2" * 64,
    }
    framework = {
        "module": "SelfCheck",
        "slug": "self-check",
        "lane": "contract",
        "priority": 1,
        "agentName": "SelfCheck framework seed",
        "taskPath": "full/framework-fanout/tasks/self-check.md",
        "ownedPaths": ["full/self-check"],
        "editablePaths": ["full/self-check/Sources"],
        "immutableDigest": "3" * 64,
        "gate": "true",
        "expectedMarkers": ["SELF_CHECK_OK"],
        "dependencies": [],
        "symbolCount": 1,
        "risks": [],
        "prompt": None,
    }
    synthetic_manifest["frameworks"] = [framework]
    ordering_fixture = [
        {"priority": 70, "slug": "z-low"},
        {"priority": 100, "slug": "z-high"},
        {"priority": 100, "slug": "a-high"},
    ]
    require(
        [item["slug"] for item in sorted(ordering_fixture, key=framework_order)]
        == ["a-high", "z-high", "z-low"],
        "descending priority order check failed",
    )
    first_id = agent_id_for(synthetic_manifest, framework)
    second_id = agent_id_for(synthetic_manifest, framework)
    require(first_id == second_id and bool(UUID_RE.fullmatch(first_id)), "deterministic id check failed")
    payload = create_payload(synthetic_manifest, framework)
    require(payload["model"] == {"id": MODEL_ID, "params": list(MODEL_PARAMS)}, "model payload check failed")
    require(payload["workOnCurrentBranch"] is False, "branch isolation check failed")
    require(payload["autoCreatePR"] is True, "auto-PR check failed")
    require(payload["skipReviewerRequest"] is True, "reviewer check failed")
    validate_model_response(
        {
            "items": [
                {
                    "id": MODEL_ID,
                    "variants": [
                        {
                            "params": [
                                {"id": "effort", "value": "high"},
                                {"id": "fast", "value": "false"},
                            ]
                        }
                    ],
                }
            ]
        }
    )
    require(
        safe_message("Authorization: Bearer top-secret", "top-secret")
        == "Authorization: [REDACTED]",
        "secret redaction check failed",
    )
    with tempfile.TemporaryDirectory(prefix="cursor-campaign-self-check-") as temporary:
        state_path = Path(temporary) / "state.json"
        state = initial_state(synthetic_manifest)
        write_state_atomic(state_path, state)
        reloaded = load_json(state_path, "self-check state")
        require(reloaded["frameworks"]["self-check"]["agentId"] == first_id, "atomic state check failed")
        require((state_path.stat().st_mode & 0o077) == 0, "state file permissions check failed")
    print(
        "CURSOR_CAMPAIGN_SELF_CHECK_OK "
        "model=grok-4.6 effort=high fast=false deterministic-ids=ok atomic-state=ok redaction=ok"
    )
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Launch and collect a bounded OpenUIKit Cursor Cloud framework campaign.",
        epilog=(
            "Authentication is read only from CURSOR_API_KEY. State contains no prompts, "
            "results, credentials, or raw API responses. archive-completed is reversible; "
            "this tool has no permanent-delete operation."
        ),
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    dry_run = subparsers.add_parser(
        "dry-run", help="validate a manifest and show deterministic launch identities without network access"
    )
    dry_run.add_argument("manifest", help="campaign JSON manifest")
    dry_run.add_argument("--json", action="store_true", help="emit machine-readable JSON")
    dry_run.set_defaults(handler=command_dry_run)

    launch = subparsers.add_parser(
        "launch", help="create pending agents while enforcing concurrency and create-rate limits"
    )
    launch.add_argument("manifest", help="campaign JSON manifest")
    launch.add_argument("--state", help="state JSON path (default: MANIFEST_STEM.state.json)")
    launch.add_argument(
        "--max-active", type=int, help="lower the manifest's audited maximum active-agent count"
    )
    launch.add_argument("--limit", type=int, help="maximum creates during this invocation")
    launch.add_argument(
        "--watch", action="store_true", help="keep filling capacity until every framework is launched"
    )
    launch.add_argument(
        "--poll-seconds", type=int, default=30, help="watch-mode polling interval (minimum: 10)"
    )
    launch.set_defaults(handler=command_launch)

    status = subparsers.add_parser("status", help="refresh and report agent/run/PR status")
    status.add_argument("manifest", help="campaign JSON manifest")
    status.add_argument("--state", help="state JSON path (default: MANIFEST_STEM.state.json)")
    status.add_argument("--json", action="store_true", help="emit the redacted state JSON")
    status.set_defaults(handler=command_status)

    archive = subparsers.add_parser(
        "archive-completed", help="reversibly archive agents whose latest run finished"
    )
    archive.add_argument("manifest", help="campaign JSON manifest")
    archive.add_argument("--state", help="state JSON path (default: MANIFEST_STEM.state.json)")
    archive.add_argument("--json", action="store_true", help="also emit the redacted state JSON")
    archive.set_defaults(handler=command_archive_completed)

    self_check = subparsers.add_parser(
        "self-check", help="run deterministic offline safety and serialization checks"
    )
    self_check.set_defaults(handler=command_self_check)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        return int(args.handler(args))
    except KeyboardInterrupt:
        print("interrupted; the last atomic state checkpoint is intact", file=sys.stderr)
        return 130
    except CampaignError as exc:
        # No raw response bodies or request headers reach this boundary.
        print(f"error: {safe_message(exc)}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
