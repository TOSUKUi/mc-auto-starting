#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
PROFILES_DIR = ROOT / "profiles"
BINARY_SUFFIXES = {
    ".png",
    ".jpg",
    ".jpeg",
    ".gif",
    ".pdf",
    ".zip",
    ".gz",
    ".tar",
    ".jar",
    ".class",
    ".pyc",
}


def load_profile(name: str) -> dict:
    path = PROFILES_DIR / f"{name}.yaml"
    if not path.exists():
        raise SystemExit(f"unknown profile: {name}")
    return json.loads(path.read_text())


def classify_path(path: Path) -> str:
    lower = path.as_posix().lower()
    if any(part in lower for part in ["/test", "/tests", "_test.", ".spec.", ".test."]):
        return "tests"
    if any(part in lower for part in ["/docs", ".md", ".rst", ".adoc"]):
        return "docs"
    if any(part in lower for part in ["/config", "package.json", "pyproject.toml", "tsconfig", "dockerfile"]):
        return "config"
    if any(part in lower for part in ["/notes", "/adr", "/design"]):
        return "notes"
    return "code"


def preview_file(path: Path, preview_lines: int) -> list[str]:
    if path.suffix.lower() in BINARY_SUFFIXES:
        return [f"[binary or non-text preview skipped: {path.name}]"]

    text = path.read_text(errors="replace").splitlines()
    lines = []
    for index, line in enumerate(text[:preview_lines], start=1):
        lines.append(f"{index:>4}: {line}")
    if len(text) > preview_lines:
        lines.append("...")
    return lines or ["[empty file]"]


def preview_directory(path: Path, max_entries: int) -> list[str]:
    entries = []
    for entry in sorted(path.iterdir(), key=lambda item: item.name)[:max_entries]:
        kind = "dir" if entry.is_dir() else "file"
        entries.append(f"- {entry.name} ({kind})")
    return entries or ["- [empty directory]"]


def describe_path(raw_path: str, preview_lines: int) -> dict:
    path = Path(raw_path)
    if not path.exists():
        return {
            "path": raw_path,
            "kind": "missing",
            "bucket": "unknown",
            "preview": ["[path does not exist]"],
        }

    if path.is_dir():
        return {
            "path": str(path),
            "kind": "directory",
            "bucket": "container",
            "preview": preview_directory(path, preview_lines),
        }

    return {
        "path": str(path),
        "kind": "file",
        "bucket": classify_path(path),
        "preview": preview_file(path, preview_lines),
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Build a compact local research pack.")
    parser.add_argument("--profile", required=True, help="profile name without extension")
    parser.add_argument("--topic", required=True, help="topic for the pack")
    parser.add_argument("--question", action="append", default=[], help="decision or research question")
    parser.add_argument("--constraint", action="append", default=[], help="constraint to preserve")
    parser.add_argument("--path", action="append", default=[], help="local file or directory to include")
    parser.add_argument("--preview-lines", type=int, help="override preview line count")
    return parser


def main() -> None:
    args = build_parser().parse_args()
    profile = load_profile(args.profile)
    preview_lines = args.preview_lines or profile["preview_lines"]
    path_budget = profile["max_paths"]
    selected_paths = args.path[:path_budget]
    overflow_paths = args.path[path_budget:]
    artifacts = [describe_path(raw_path, preview_lines) for raw_path in selected_paths]

    print("# Research Pack")
    print()
    print(f"- Profile: `{args.profile}`")
    print(f"- Summary: {profile['summary']}")
    print(f"- Topic: {args.topic}")
    print()

    if args.question:
        print("## Questions")
        for item in args.question:
            print(f"- {item}")
        print()

    if args.constraint:
        print("## Constraints")
        for item in args.constraint:
            print(f"- {item}")
        print()

    print("## Known Facts")
    if artifacts:
        print(f"- {len(artifacts)} artifact(s) were selected using the `{args.profile}` profile.")
    else:
        print("- No artifacts were provided.")
    if overflow_paths:
        print(f"- {len(overflow_paths)} additional path(s) were omitted by the profile budget.")
    print()

    print("## Relevant Artifacts")
    if not artifacts:
        print("- [none]")
    for artifact in artifacts:
        print(f"- `{artifact['path']}` ({artifact['kind']}, bucket: {artifact['bucket']})")
    print()

    print("## Preview Snippets")
    if not artifacts:
        print("- [none]")
    for artifact in artifacts:
        print(f"### {artifact['path']}")
        for line in artifact["preview"]:
            print(line)
        print()

    print("## Unknowns")
    print("- Which of the omitted artifacts matter most, if any.")
    print("- Whether the current pack is sufficient for a decision or only for triage.")
    print("- What evidence is still missing from tests, docs, or runtime behavior.")
    print()

    print("## Suggested Next Reads")
    if overflow_paths:
        for path in overflow_paths[:5]:
            print(f"- {path}")
    else:
        print("- Read the smallest adjacent test or config file next if confidence is still low.")


if __name__ == "__main__":
    main()
