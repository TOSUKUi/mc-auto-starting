#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
PROFILES_DIR = ROOT / "profiles"
PROMPTS_DIR = ROOT / "prompts"

ROLE_KEYWORDS = {
    "pragmatist": ["delivery", "roadmap", "deadline", "ship", "mvp"],
    "minimalist": ["simple", "mvp", "manual", "small", "cheap"],
    "maximalist": ["platform", "future", "scale", "foundation", "extensible"],
    "retrieval-architect": ["retrieval", "tree-sitter", "lsp", "semantic", "index", "search"],
    "granary-workflow-lead": ["granary", "workflow", "handoff", "session", "checkpoint", "cli"],
    "semantic-purist": ["semantic", "compiler", "lsp", "typed", "symbol", "precision"],
    "lightweight-contrarian": ["grep", "ripgrep", "diff", "simple", "lightweight"],
    "context-economist": ["token", "context", "budget", "prune", "fresh session", "pollution"],
    "workflow-conservative": ["tool", "workflow", "granary", "reuse", "migration"],
}


def load_json_yaml(path: Path) -> dict:
    return json.loads(path.read_text())


def load_profile(name: str) -> dict:
    path = PROFILES_DIR / f"{name}.yaml"
    if not path.exists():
        raise SystemExit(f"unknown profile: {name}")
    return load_json_yaml(path)


def summarize_prompt(role: str) -> str:
    path = PROMPTS_DIR / f"{role}.md"
    if not path.exists():
        raise SystemExit(f"missing role prompt: {role}")
    return path.read_text().strip()


def choose_optional_roles(profile: dict, signal_text: str) -> list[str]:
    scored: list[tuple[int, str]] = []
    for role in profile.get("optional_roles", []):
        score = 0
        for keyword in ROLE_KEYWORDS.get(role, []):
            if keyword in signal_text:
                score += 1
        scored.append((score, role))

    scored.sort(key=lambda item: (-item[0], item[1]))
    slots = max(profile["max_agents"] - len(profile["required_roles"]), 0)
    chosen = []
    for score, role in scored:
        if len(chosen) >= slots:
            break
        if score > 0 or len(chosen) < slots:
            chosen.append(role)
    return chosen


def build_roles(profile: dict, args: argparse.Namespace) -> list[str]:
    signal_parts = [args.topic, args.need]
    signal_parts.extend(args.artifact)
    signal_parts.extend(args.constraint)
    signal_text = " ".join(signal_parts).lower()

    roles = list(profile["required_roles"])
    for role in choose_optional_roles(profile, signal_text):
        if role not in roles:
            roles.append(role)

    for role in args.add_role:
        if role not in roles:
            roles.append(role)

    roles = [role for role in roles if role not in set(args.drop_role)]
    return roles


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Render a reusable swarm-meeting brief.")
    parser.add_argument("--profile", required=True, help="profile name without extension")
    parser.add_argument("--topic", required=True, help="meeting topic")
    parser.add_argument("--need", required=True, help="what the meeting must deliver")
    parser.add_argument("--artifact", action="append", default=[], help="artifact or source path")
    parser.add_argument("--constraint", action="append", default=[], help="constraint to enforce")
    parser.add_argument("--question", action="append", default=[], help="open question")
    parser.add_argument("--decision-owner", help="who will act on the recommendation")
    parser.add_argument("--add-role", action="append", default=[], help="force-include a role")
    parser.add_argument("--drop-role", action="append", default=[], help="force-remove a role")
    return parser


def main() -> None:
    args = build_parser().parse_args()
    profile = load_profile(args.profile)
    roles = build_roles(profile, args)

    print("# Swarm Meeting Brief")
    print()
    print(f"- Profile: `{args.profile}`")
    print(f"- Summary: {profile['summary']}")
    print(f"- Topic: {args.topic}")
    print(f"- Need: {args.need}")
    if args.decision_owner:
        print(f"- Decision owner: {args.decision_owner}")
    print(f"- Debate rounds: {profile['debate_rounds']}")
    print(f"- Objection round required: {profile['require_objection_round']}")
    print()

    if args.constraint:
        print("## Constraints")
        for item in args.constraint:
            print(f"- {item}")
        print()

    if args.artifact:
        print("## Artifacts")
        for item in args.artifact:
            print(f"- {item}")
        print()

    if args.question:
        print("## Open Questions")
        for item in args.question:
            print(f"- {item}")
        print()

    print("## Selected Roles")
    for role in roles:
        print(f"- {role}")
    print()

    print("## Role Cards")
    for role in roles:
        print(f"### {role}")
        print(summarize_prompt(role))
        print()

    print("## Output Contract")
    print("- Use a clear decision-oriented structure.")
    print("- Separate facts, inferences, objections, recommendation, and next actions.")
    print("- Keep role memos short and independent before synthesis.")


if __name__ == "__main__":
    main()
