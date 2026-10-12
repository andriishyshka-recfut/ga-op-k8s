#!/usr/bin/env python3
"""Check that every centrally managed Logstash pipeline matches a config pattern."""

from __future__ import annotations

import argparse
import base64
import fnmatch
import json
import os
import shlex
import ssl
import sys
import urllib.error
import urllib.request
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Fetch all centrally managed Logstash pipelines from Elasticsearch and "
            "check that each pipeline ID is covered by at least one config pattern."
        )
    )
    parser.add_argument(
        "configs",
        nargs="+",
        metavar="CONFIG",
        help='pipeline patterns separated by spaces or commas, e.g. "minion-* nr-*"',
    )
    parser.add_argument(
        "--url",
        default=os.environ.get("ELASTICSEARCH_URL"),
        help="Elasticsearch URL (or set ELASTICSEARCH_URL)",
    )
    parser.add_argument(
        "--username",
        default=os.environ.get("ELASTICSEARCH_USERNAME"),
        help="basic-auth username (or set ELASTICSEARCH_USERNAME)",
    )
    parser.add_argument(
        "--response-file",
        type=Path,
        help="read a saved Elasticsearch JSON response instead of calling the API",
    )
    parser.add_argument(
        "--ca-cert",
        type=Path,
        help="CA certificate; enables TLS verification (disabled by default)",
    )
    parser.add_argument(
        "--insecure",
        action="store_true",
        help=argparse.SUPPRESS,
    )
    return parser.parse_args()


def split_patterns(config: str) -> list[str]:
    """Accept both tfvars-style space lists and rendered YAML comma lists."""
    normalized = config.replace(",", " ").replace("[", " ").replace("]", " ")
    return [value.strip("'\"") for value in shlex.split(normalized) if value.strip("'\"")]


def ssl_context(args: argparse.Namespace) -> ssl.SSLContext:
    if args.ca_cert and not args.insecure:
        return ssl.create_default_context(cafile=str(args.ca_cert))
    return ssl._create_unverified_context()  # noqa: SLF001 - required for internal ES


def fetch_pipelines(args: argparse.Namespace) -> dict[str, object]:
    if args.response_file:
        try:
            response = json.loads(args.response_file.read_text())
        except (OSError, json.JSONDecodeError) as error:
            raise RuntimeError(f"cannot read {args.response_file}: {error}") from error
    else:
        if not args.url:
            raise RuntimeError("set --url or ELASTICSEARCH_URL")

        request = urllib.request.Request(
            f"{args.url.rstrip('/')}/_logstash/pipeline",
            headers={"Accept": "application/json"},
        )
        api_key = os.environ.get("ELASTIC_API_KEY")
        password = os.environ.get("ELASTICSEARCH_PASSWORD")
        if api_key:
            request.add_header("Authorization", f"ApiKey {api_key.removeprefix('ApiKey ')}")
        elif args.username and password is not None:
            token = base64.b64encode(f"{args.username}:{password}".encode()).decode()
            request.add_header("Authorization", f"Basic {token}")
        elif args.username or password is not None:
            raise RuntimeError(
                "basic auth requires ELASTICSEARCH_USERNAME and ELASTICSEARCH_PASSWORD"
            )

        try:
            with urllib.request.urlopen(
                request, context=ssl_context(args), timeout=30
            ) as http_response:
                response = json.load(http_response)
        except (urllib.error.URLError, json.JSONDecodeError) as error:
            raise RuntimeError(f"Elasticsearch request failed: {error}") from error

    if not isinstance(response, dict):
        raise RuntimeError("unexpected Elasticsearch response: expected a JSON object")
    return response


def main() -> int:
    args = parse_args()
    patterns_by_config = [split_patterns(config) for config in args.configs]
    if any(not patterns for patterns in patterns_by_config):
        print("error: every CONFIG must contain at least one pattern", file=sys.stderr)
        return 2

    try:
        pipeline_ids = sorted(fetch_pipelines(args))
    except RuntimeError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2

    missing: list[str] = []
    print(f"Found {len(pipeline_ids)} pipelines:")
    for pipeline_id in pipeline_ids:
        matched_configs = [
            number
            for number, patterns in enumerate(patterns_by_config, start=1)
            if any(fnmatch.fnmatchcase(pipeline_id, pattern) for pattern in patterns)
        ]
        if matched_configs:
            coverage = ", ".join(f"config {number}" for number in matched_configs)
            print(f"  OK       {pipeline_id} ({coverage})")
        else:
            missing.append(pipeline_id)
            print(f"  MISSING  {pipeline_id}")

    if missing:
        print(f"\n{len(missing)} pipeline(s) are not covered:")
        for pipeline_id in missing:
            print(f"  {pipeline_id}")
        return 1

    print("\nAll pipelines are covered by the supplied configs.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
