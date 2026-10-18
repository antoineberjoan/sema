"""Teste les réponses du hook d’agent selon le client, l’événement et le fichier édité."""
import json
import pathlib
import shutil
import subprocess
import tempfile
import unittest


SCRIPTS = pathlib.Path(__file__).resolve().parents[1]
VIOLATION = "// Décrit une carte.\nlet shape = RoundedRectangle(cornerRadius: 12)\n"


class AgentHookTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = pathlib.Path(self.temp.name).resolve()
        subprocess.check_call(["git", "-C", str(self.root), "init", "--quiet"])
        self.write(".agents/structure.json", json.dumps({
            "AGENTS.md": "Instructions", "CLAUDE.md": "Import", ".agents/": "Procédures",
            "scripts/": "Outils", "Sources/": "Code", "distribution/": "Release", "site/": "Site",
        }))
        self.write("AGENTS.md", "# Instructions\n")
        self.write("CLAUDE.md", "@AGENTS.md\n")
        self.write("distribution/release.json", "{}")
        self.write("site/dist/download/release.json", "{}")
        self.write("Sources/SemaMac/Clean.swift", "// Décrit une vue conforme.\n")
        (self.root / "scripts").mkdir()
        for name in ("agent-hook.py", "guardrails.py"):
            shutil.copy(SCRIPTS / name, self.root / "scripts" / name)

    def write(self, path, text):
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text)

    def run_hook(self, payload):
        return subprocess.run(["python3", str(self.root / "scripts/agent-hook.py")], input=json.dumps(payload),
                              capture_output=True, text=True)

    def test_clean_repository_is_silent(self):
        result = self.run_hook({"hook_event_name": "Stop"})
        self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "", ""))

    def test_claude_edit_reports_only_the_edited_file(self):
        self.write("Sources/SemaMac/Card.swift", VIOLATION)
        self.write("Sources/SemaMac/Other.swift", VIOLATION)
        result = self.run_hook({"hook_event_name": "PostToolUse", "tool_input": {"file_path": str(self.root / "Sources/SemaMac/Card.swift")}})
        self.assertEqual(result.returncode, 2)
        self.assertIn("Sources/SemaMac/Card.swift:2", result.stderr)
        self.assertNotIn("Other.swift", result.stderr)
        clean = self.run_hook({"hook_event_name": "PostToolUse", "tool_input": {"file_path": str(self.root / "Sources/SemaMac/Clean.swift")}})
        self.assertEqual(clean.returncode, 0)

    def test_cursor_edit_adds_context(self):
        self.write("Sources/SemaMac/Card.swift", VIOLATION)
        result = self.run_hook({"hook_event_name": "postToolUse", "cursor_version": "3",
                                "tool_input": {"file_path": str(self.root / "Sources/SemaMac/Card.swift")}})
        self.assertEqual(result.returncode, 0)
        self.assertIn("Sources/SemaMac/Card.swift:2", json.loads(result.stdout)["additional_context"])

    def test_stop_blocks_once_then_lets_the_agent_report(self):
        self.write("Sources/SemaMac/Card.swift", VIOLATION)
        for payload in ({"hook_event_name": "Stop", "stop_hook_active": False},
                        {"hook_event_name": "stop", "cursor_version": "3", "loop_count": 0, "status": "completed"}):
            with self.subTest(payload=payload):
                result = self.run_hook(payload)
                self.assertEqual(result.returncode, 0)
                self.assertEqual(json.loads(result.stdout)["decision"], "block")
        for payload in ({"hook_event_name": "Stop", "stop_hook_active": True},
                        {"hook_event_name": "stop", "loop_count": 1},
                        {"hook_event_name": "stop", "loop_count": 0, "status": "aborted"}):
            with self.subTest(payload=payload):
                self.assertEqual(self.run_hook(payload).stdout, "")


if __name__ == "__main__":
    unittest.main()
