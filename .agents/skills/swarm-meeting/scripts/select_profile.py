#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from pathlib import Path


PROFILES_DIR = Path(__file__).resolve().parent.parent / "profiles"


def load_profile(name: str) -> dict:
    path = PROFILES_DIR / f"{name}.yaml"
    if not path.exists():
        raise SystemExit(f"unknown profile: {name}")
    return json.loads(path.read_text())


def all_profiles() -> list[tuple[str, dict]]:
    profiles = []
    for path in sorted(PROFILES_DIR.glob("*.yaml")):
        profiles.append((path.stem, json.loads(path.read_text())))
    return profiles


def recommend_profile(args: argparse.Namespace) -> tuple[str, list[str]]:
    scores = {name: 0 for name, _ in all_profiles()}
    reasons: list[str] = []
    topic = (args.topic or "").lower()

    if args.diversity == "high":
        scores["extreme-diversity"] += 3
        reasons.append("high diversity requested")
    elif args.diversity == "medium":
        scores["balanced"] += 1
        scores["architecture-debate"] += 1

    if args.risk == "high":
        scores["architecture-debate"] += 2
        scores["extreme-diversity"] += 1
        reasons.append("high architectural risk")
    elif args.risk == "low":
        scores["balanced"] += 1

    if args.delivery_pressure == "high":
        scores["balanced"] += 2
        reasons.append("high delivery pressure")
    elif args.delivery_pressure == "low":
        scores["architecture-debate"] += 1

    if args.context_cost == "high":
        scores["balanced"] += 2
        reasons.append("context efficiency is important")

    if any(word in topic for word in ["tree-sitter", "lsp", "semantic", "compiler", "platform"]):
        scores["architecture-debate"] += 2
        reasons.append("topic implies semantic or platform tradeoffs")

    if any(word in topic for word in ["mvp", "ship", "simple", "small"]):
        scores["balanced"] += 2
        reasons.append("topic implies MVP pressure")

    if any(word in topic for word in ["granary", "session", "context", "retrieval", "handoff"]):
        scores["extreme-diversity"] += 1
        scores["balanced"] += 1
        reasons.append("topic touches workflow and context-management concerns")

    winner = max(scores, key=lambda name: (scores[name], name == "balanced"))
    if not reasons:
        reasons.append("no strong bias detected; defaulting to the balanced profile")
    return winner, reasons


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Inspect or recommend swarm-meeting profiles.")
    parser.add_argument("--list", action="store_true", help="list available profiles")
    parser.add_argument("--show", metavar="PROFILE", help="print one profile as formatted JSON")
    parser.add_argument("--usage", action="store_true", help="print short invocation guidance")
    parser.add_argument("--examples", action="store_true", help="print prompt examples")
    parser.add_argument("--topic", help="meeting topic")
    parser.add_argument(
        "--delivery-pressure",
        choices=["low", "medium", "high"],
        default="medium",
        help="how hard the deadline is",
    )
    parser.add_argument(
        "--risk",
        choices=["low", "medium", "high"],
        default="medium",
        help="architectural or product risk level",
    )
    parser.add_argument(
        "--diversity",
        choices=["low", "medium", "high"],
        default="medium",
        help="how much disagreement the meeting should encourage",
    )
    parser.add_argument(
        "--context-cost",
        choices=["low", "medium", "high"],
        default="medium",
        help="how important context efficiency is",
    )
    return parser


def print_usage() -> None:
    print("Use the swarm-meeting skill.")
    print("Profile: balanced")
    print("Topic: <one-sentence decision topic>")
    print("Need: options, objections, and recommendation")
    print()
    print("Other profiles:")
    print("- architecture-debate")
    print("- extreme-diversity")
    print()
    print("Examples:")
    print("- Use the swarm-meeting skill. Topic: Decide the MVP for task-scoped context retrieval.")
    print("- Use swarm-meeting with profile: architecture-debate. Topic: Decide where Tree-sitter stops and LSP begins.")


def print_examples() -> None:
    print("Example 1")
    print("Use the swarm-meeting skill.")
    print("Topic: Design a Granary-centered task-scoped context retrieval system.")
    print("Need: practical architecture options, objections, and an MVP recommendation.")
    print()
    print("Example 2")
    print("Use the swarm-meeting skill.")
    print("Profile: architecture-debate")
    print("Topic: Decide how Tree-sitter and optional LSP should interact in context retrieval.")
    print("Need: boundaries, failure modes, and a phased implementation plan.")
    print()
    print("Example 3")
    print("Use the swarm-meeting skill.")
    print("Profile: extreme-diversity")
    print("Topic: Decide whether to prefer fresh task-scoped sessions over long-lived sessions with pruning.")
    print("Need: hard tradeoffs and one recommendation.")


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    if args.list:
        for name, profile in all_profiles():
            print(f"{name}: {profile['summary']}")
        return

    if args.usage:
        print_usage()
        return

    if args.examples:
        print_examples()
        return

    if args.show:
        print(json.dumps(load_profile(args.show), indent=2))
        return

    winner, reasons = recommend_profile(args)
    profile = load_profile(winner)
    print(f"recommended_profile: {winner}")
    print(f"summary: {profile['summary']}")
    print("reasons:")
    for reason in reasons:
        print(f"- {reason}")
    print("required_roles:")
    for role in profile["required_roles"]:
        print(f"- {role}")


if __name__ == "__main__":
    main()
