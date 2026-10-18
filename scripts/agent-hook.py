#!/usr/bin/env python3
"""Renvoie à l’agent les refus des garde-fous sur le fichier qu’il édite et sur tout le dépôt avant la fin de son tour."""
import json
import pathlib
import sys

import guardrails


def main():
    payload = json.loads(sys.stdin.read() or "{}")
    root = pathlib.Path(__file__).resolve().parents[1]
    is_stop = payload.get("hook_event_name", "").lower() == "stop"
    # Claude signale une relance déjà demandée, Cursor la compte : une seule relance, puis l’agent expose le blocage.
    if is_stop and (payload.get("stop_hook_active") or payload.get("loop_count") or payload.get("status") == "aborted"):
        return 0
    errors = guardrails.check(guardrails.Snapshot(root))
    edited = (payload.get("tool_input") or {}).get("file_path") or payload.get("file_path")
    if not is_stop and edited:
        path = pathlib.Path(edited).resolve()
        if path.is_relative_to(root):
            prefix = path.relative_to(root).as_posix()
            errors = [error for error in errors if error.startswith((prefix + " ", prefix + ":"))]
    if not errors:
        return 0
    report = "Garde-fous :\n" + "\n".join("- " + error for error in errors)
    if is_stop:
        print(json.dumps({"decision": "block", "reason": report}, ensure_ascii=False))
    elif "cursor_version" in payload:
        print(json.dumps({"additional_context": report}, ensure_ascii=False))
    else:
        print(report, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
