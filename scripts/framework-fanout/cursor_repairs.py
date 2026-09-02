#!/usr/bin/env python3
"""Launch audited follow-up runs on existing Cursor Cloud framework agents.

The repair manifest may contain prompts, but the durable state deliberately
stores only prompt hashes and byte counts. Authentication is read only from
``CURSOR_API_KEY``. A stable idempotency key is derived before every send so an
ambiguous retry cannot create a second repair run.
"""

from __future__ import annotations

import argparse
import contextlib
import datetime as dt
import fcntl
import hashlib
import importlib.metadata
import json
import os
from pathlib import Path
import re
import stat
import sys
import tempfile
import time
from typing import Any, Iterator, Sequence
import urllib.parse
import uuid

from cursor_campaign import (
    ACTIVE_AGENT_STATUSES,
    CursorApi,
    CampaignError,
    TERMINAL_RUN_STATUSES,
    sanitized_branches,
    validate_model_response,
)


MANIFEST_SCHEMA = "openuikit.cursor-framework-repair-manifest.v1"
STATE_SCHEMA = "openuikit.cursor-framework-repair-state.v1"
SDK_VERSION = "1.0.30"
MODEL_ID = "grok-4.6"
MODEL_PARAMS = (
    {"id": "effort", "value": "high"},
    {"id": "fast", "value": "false"},
)
STATE_IDENTITY_KEYS = (
    "module",
    "slug",
    "agentId",
    "expectedPrUrl",
    "expectedPriorHead",
    "promptSha256",
    "promptBytes",
    "idempotencyKey",
)
REPAIR_NAMESPACE = uuid.UUID("c36a3442-4db7-4e66-94f1-9a57b5e9afef")
AGENT_RE = re.compile(
    r"^bc-[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"
)
SHA_RE = re.compile(r"^[0-9a-f]{40}$")
ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{0,127}$")
SLUG_RE = re.compile(r"^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise CampaignError(message)


def string(value: Any, label: str, *, maximum: int = 500) -> str:
    require(isinstance(value, str), f"{label} must be a string")
    require(value == value.strip() and bool(value), f"{label} must be nonempty and unpadded")
    require("\x00" not in value and len(value.encode("utf-8")) <= maximum, f"invalid {label}")
    return value


def sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def now() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def normalize_pr_url(value: Any, label: str) -> str:
    url = string(value, label)
    parsed = urllib.parse.urlsplit(url)
    require(
        parsed.scheme == "https"
        and parsed.netloc == "github.com"
        and re.fullmatch(r"/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/pull/[1-9][0-9]*", parsed.path)
        and not parsed.query
        and not parsed.fragment,
        f"{label} must be a canonical GitHub pull-request URL",
    )
    return url


def normalize_manifest(path: Path) -> dict[str, Any]:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise CampaignError(f"cannot read repair manifest: {exc}") from exc
    require(isinstance(raw, dict), "repair manifest must be an object")
    require(set(raw) == {"schema", "campaign", "model", "repairs"}, "repair manifest keys differ")
    require(raw["schema"] == MANIFEST_SCHEMA, "repair manifest schema differs")

    campaign = raw["campaign"]
    require(isinstance(campaign, dict), "campaign must be an object")
    require(set(campaign) == {"id", "maxActive", "maxRuns"}, "campaign keys differ")
    campaign_id = string(campaign["id"], "campaign.id", maximum=128)
    require(bool(ID_RE.fullmatch(campaign_id)), "campaign.id has an invalid spelling")
    max_active = campaign["maxActive"]
    max_runs = campaign["maxRuns"]
    require(isinstance(max_active, int) and 1 <= max_active <= 24, "campaign.maxActive must be 1...24")
    require(isinstance(max_runs, int) and 1 <= max_runs <= 100, "campaign.maxRuns must be 1...100")

    model = raw["model"]
    require(
        model == {"id": MODEL_ID, "effort": "high", "fast": False},
        "repair model must be grok-4.6/high/fast=false",
    )
    repairs = raw["repairs"]
    require(isinstance(repairs, list) and 1 <= len(repairs) <= max_runs, "invalid repair list")

    normalized: list[dict[str, Any]] = []
    seen_agents: set[str] = set()
    seen_slugs: set[str] = set()
    for index, item in enumerate(repairs):
        label = f"repairs[{index}]"
        require(isinstance(item, dict), f"{label} must be an object")
        require(
            set(item)
            == {"module", "slug", "agentId", "expectedPrUrl", "expectedPriorHead", "prompt"},
            f"{label} keys differ",
        )
        module = string(item["module"], f"{label}.module", maximum=100)
        slug = string(item["slug"], f"{label}.slug", maximum=100)
        agent_id = string(item["agentId"], f"{label}.agentId", maximum=100)
        prompt = string(item["prompt"], f"{label}.prompt", maximum=30_000)
        prior_head = string(item["expectedPriorHead"], f"{label}.expectedPriorHead", maximum=40)
        require(bool(SLUG_RE.fullmatch(slug)), f"{label}.slug has an invalid spelling")
        require(bool(AGENT_RE.fullmatch(agent_id)), f"{label}.agentId is invalid")
        require(bool(SHA_RE.fullmatch(prior_head)), f"{label}.expectedPriorHead is invalid")
        require(agent_id not in seen_agents, f"duplicate repair agent: {agent_id}")
        require(slug not in seen_slugs, f"duplicate repair slug: {slug}")
        seen_agents.add(agent_id)
        seen_slugs.add(slug)
        prompt_sha = sha256_text(prompt)
        stable_key = str(
            uuid.uuid5(
                REPAIR_NAMESPACE,
                "\0".join((campaign_id, agent_id, prior_head, prompt_sha)),
            )
        )
        normalized.append(
            {
                "module": module,
                "slug": slug,
                "agentId": agent_id,
                "expectedPrUrl": normalize_pr_url(item["expectedPrUrl"], f"{label}.expectedPrUrl"),
                "expectedPriorHead": prior_head,
                "prompt": prompt,
                "promptSha256": prompt_sha,
                "promptBytes": len(prompt.encode("utf-8")),
                "idempotencyKey": stable_key,
            }
        )
    return {
        "schema": MANIFEST_SCHEMA,
        "campaign": {"id": campaign_id, "maxActive": max_active, "maxRuns": max_runs},
        "model": model,
        "repairs": normalized,
    }


def initial_state(manifest: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema": STATE_SCHEMA,
        "campaign": manifest["campaign"],
        "model": manifest["model"],
        "attemptTimestamps": [],
        "repairs": {
            item["slug"]: {
                key: item[key] for key in STATE_IDENTITY_KEYS
            }
            | {"launchStatus": "PENDING"}
            for item in manifest["repairs"]
        },
    }


def validate_state(state: Any, manifest: dict[str, Any]) -> dict[str, Any]:
    require(isinstance(state, dict), "repair state must be an object")
    require(state.get("schema") == STATE_SCHEMA, "repair state schema differs")
    require(state.get("campaign") == manifest["campaign"], "repair state campaign differs")
    require(state.get("model") == manifest["model"], "repair state model differs")
    require(isinstance(state.get("attemptTimestamps"), list), "repair attempts are missing")
    require(isinstance(state.get("repairs"), dict), "repair state entries are missing")
    expected = initial_state(manifest)["repairs"]
    require(set(state["repairs"]) == set(expected), "repair state slug set differs")
    for slug, identity in expected.items():
        entry = state["repairs"][slug]
        require(isinstance(entry, dict), f"repair state {slug} is not an object")
        for key in STATE_IDENTITY_KEYS:
            value = identity[key]
            require(entry.get(key) == value, f"repair state identity differs for {slug}.{key}")
    return state


def write_state(path: Path, state: dict[str, Any]) -> None:
    require(path.parent.exists() and path.parent.is_dir(), "repair state parent is missing")
    require(not path.is_symlink(), "repair state must not be a symlink")
    payload = (json.dumps(state, indent=2, sort_keys=True) + "\n").encode("utf-8")
    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary = Path(temporary_name)
    try:
        os.fchmod(descriptor, 0o600)
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(payload)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        with contextlib.suppress(FileNotFoundError):
            temporary.unlink()
    require(stat.S_IMODE(path.stat().st_mode) == 0o600, "repair state mode is not 0600")


@contextlib.contextmanager
def locked_state(path: Path) -> Iterator[None]:
    lock = path.with_name(f".{path.name}.lock")
    require(not lock.is_symlink(), "repair state lock must not be a symlink")
    descriptor = os.open(lock, os.O_RDWR | os.O_CREAT, 0o600)
    try:
        os.fchmod(descriptor, 0o600)
        fcntl.flock(descriptor, fcntl.LOCK_EX)
        yield
    finally:
        fcntl.flock(descriptor, fcntl.LOCK_UN)
        os.close(descriptor)


def load_state(path: Path, manifest: dict[str, Any]) -> dict[str, Any]:
    if not path.exists():
        return initial_state(manifest)
    require(path.is_file() and not path.is_symlink(), "repair state must be a regular file")
    try:
        state = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise CampaignError(f"cannot read repair state: {exc}") from exc
    return validate_state(state, manifest)


def entry_by_slug(manifest: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {item["slug"]: item for item in manifest["repairs"]}


def refresh(api: CursorApi, state: dict[str, Any]) -> None:
    for entry in state["repairs"].values():
        run_id = entry.get("runId")
        if not isinstance(run_id, str):
            continue
        agent = api.get_agent(entry["agentId"])
        entry["agentStatus"] = agent.get("status")
        run = api.get_run(entry["agentId"], run_id)
        entry["runStatus"] = run.get("status")
        entry["branches"] = sanitized_branches(run)
        if isinstance(run.get("result"), str):
            entry["resultSha256"] = sha256_text(run["result"])
            entry["resultBytes"] = len(run["result"].encode("utf-8"))


def print_status(state: dict[str, Any]) -> None:
    counts: dict[str, int] = {}
    for entry in state["repairs"].values():
        status_value = entry.get("runStatus") or entry.get("launchStatus") or "UNKNOWN"
        counts[status_value] = counts.get(status_value, 0) + 1
    rendered = " ".join(f"{key}={counts[key]}" for key in sorted(counts))
    print(f"repair-campaign={state['campaign']['id']} total={len(state['repairs'])} {rendered}")
    for entry in state["repairs"].values():
        print(
            f"  {entry['module']:<24} {entry.get('runStatus') or entry.get('launchStatus'):<10} "
            f"agent={entry['agentId']} run={entry.get('runId') or '-'}"
        )


def require_sdk() -> None:
    try:
        actual = importlib.metadata.version("cursor-sdk")
    except importlib.metadata.PackageNotFoundError as exc:
        raise CampaignError(f"cursor-sdk {SDK_VERSION} is required") from exc
    require(actual == SDK_VERSION, f"cursor-sdk version {actual}, expected {SDK_VERSION}")


def preflight_agent(api: CursorApi, item: dict[str, Any]) -> str:
    agent = api.get_agent(item["agentId"])
    require(agent.get("status") == "IDLE", f"{item['module']} agent is not IDLE")
    prior_run_id = agent.get("latestRunId")
    require(isinstance(prior_run_id, str) and prior_run_id.startswith("run-"), "latest run is missing")
    prior_run = api.get_run(item["agentId"], prior_run_id)
    require(prior_run.get("status") in TERMINAL_RUN_STATUSES, f"{item['module']} latest run is not terminal")
    urls = {branch.get("prUrl") for branch in sanitized_branches(prior_run)}
    require(item["expectedPrUrl"] in urls, f"{item['module']} latest run does not own expected PR")
    return prior_run_id


def recover_after_send_error(api: CursorApi, item: dict[str, Any], prior_run_id: str) -> str | None:
    with contextlib.suppress(Exception):
        agent = api.get_agent(item["agentId"])
        latest = agent.get("latestRunId")
        if isinstance(latest, str) and latest.startswith("run-") and latest != prior_run_id:
            return latest
    return None


def command_dry_run(args: argparse.Namespace) -> int:
    manifest = normalize_manifest(Path(args.manifest).resolve())
    print(
        f"REPAIR_DRY_RUN campaign={manifest['campaign']['id']} repairs={len(manifest['repairs'])} "
        "model=grok-4.6 effort=high fast=false"
    )
    for item in manifest["repairs"]:
        print(
            f"  {item['module']:<24} {item['agentId']} prompt={item['promptBytes']}B/"
            f"{item['promptSha256'][:12]} idempotency={item['idempotencyKey']}"
        )
    return 0


def command_status(args: argparse.Namespace) -> int:
    manifest = normalize_manifest(Path(args.manifest).resolve())
    state_path = Path(args.state).expanduser().resolve()
    api = CursorApi.from_environment()
    with locked_state(state_path):
        state = load_state(state_path, manifest)
        refresh(api, state)
        write_state(state_path, state)
        print_status(state)
    return 0


def command_launch(args: argparse.Namespace) -> int:
    manifest = normalize_manifest(Path(args.manifest).resolve())
    state_path = Path(args.state).expanduser().resolve()
    require(args.limit is None or args.limit >= 1, "--limit must be at least 1")
    require_sdk()
    from cursor_sdk import Agent, ModelParameterValue, ModelSelection, SendOptions

    api = CursorApi.from_environment()
    validate_model_response(api.request("GET", "/v1/models"))
    items = entry_by_slug(manifest)
    model = ModelSelection(
        id=MODEL_ID,
        params=[ModelParameterValue(id=value["id"], value=value["value"]) for value in MODEL_PARAMS],
    )

    with locked_state(state_path):
        state = load_state(state_path, manifest)
        refresh(api, state)
        write_state(state_path, state)
        active = sum(
            1 for agent in api.list_agents() if agent.get("status") in ACTIVE_AGENT_STATUSES
        )
        capacity = manifest["campaign"]["maxActive"] - active
        if capacity <= 0:
            print(f"repair launch: no capacity active={active}/{manifest['campaign']['maxActive']}")
            print_status(state)
            return 0
        pending = [
            entry
            for entry in state["repairs"].values()
            if entry.get("launchStatus") in {"PENDING", "SEND_ERROR"}
        ]
        if args.limit is not None:
            pending = pending[: args.limit]
        pending = pending[:capacity]
        for index, entry in enumerate(pending):
            item = items[entry["slug"]]
            prior_run_id = preflight_agent(api, item)
            entry["launchStatus"] = "SENDING"
            entry["attemptedAt"] = now()
            write_state(state_path, state)
            try:
                with Agent.resume(item["agentId"]) as agent:
                    run = agent.send(
                        item["prompt"],
                        SendOptions(
                            model=model,
                            mode="agent",
                            idempotency_key=item["idempotencyKey"],
                        ),
                    )
                    run_id = run.id
                    run_status = run.status
            except Exception as exc:
                recovered = recover_after_send_error(api, item, prior_run_id)
                if recovered is None:
                    entry["launchStatus"] = "SEND_ERROR"
                    entry["lastErrorType"] = type(exc).__name__[:100]
                    write_state(state_path, state)
                    raise CampaignError(
                        f"repair send failed for {item['module']} ({type(exc).__name__})"
                    ) from None
                run_id = recovered
                run_status = "RUNNING"
            require(isinstance(run_id, str) and run_id.startswith("run-"), "SDK returned invalid run id")
            entry["launchStatus"] = "SENT"
            entry["runId"] = run_id
            entry["runStatus"] = run_status or "RUNNING"
            entry["agentStatus"] = "ACTIVE"
            entry.pop("lastErrorType", None)
            write_state(state_path, state)
            print(f"repair launched module={item['module']} agent={item['agentId']} run={run_id}")
            if index + 1 < len(pending):
                time.sleep(3.1)
        print_status(state)
    return 0


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description="Launch audited Cursor follow-up repair runs.")
    commands = result.add_subparsers(dest="command", required=True)
    dry = commands.add_parser("dry-run")
    dry.add_argument("manifest")
    dry.set_defaults(handler=command_dry_run)
    launch = commands.add_parser("launch")
    launch.add_argument("manifest")
    launch.add_argument("--state", required=True)
    launch.add_argument("--limit", type=int)
    launch.set_defaults(handler=command_launch)
    status_command = commands.add_parser("status")
    status_command.add_argument("manifest")
    status_command.add_argument("--state", required=True)
    status_command.set_defaults(handler=command_status)
    return result


def main(argv: Sequence[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        return args.handler(args)
    except CampaignError as exc:
        print(f"cursor_repair: REFUSING -- {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
