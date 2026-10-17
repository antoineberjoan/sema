"""Teste les refus utiles et la lecture de l’index indépendamment des corrections non indexées."""
import importlib.util
import json
import pathlib
import subprocess
import tempfile
import unittest


MODULE_PATH = pathlib.Path(__file__).resolve().parents[1] / "guardrails.py"
SPEC = importlib.util.spec_from_file_location("guardrails", MODULE_PATH)
guardrails = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(guardrails)


class GuardrailsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = pathlib.Path(self.temp.name)
        self.git("init", "--quiet")
        self.write(".agents/structure.json", json.dumps({
            ".agents/": "Procédures", "AGENTS.md": "Instructions", "CLAUDE.md": "Import",
            "Sources/MarketCore/": "Cœur", "docs/": "Documentation",
            "distribution/": "Release", "site/": "Site", ".env": "Configuration"
        }))
        self.write("AGENTS.md", "# Instructions\n")
        self.write("CLAUDE.md", "@AGENTS.md\n")
        self.write("Sources/MarketCore/Series.swift", "// Décrit les observations économiques indépendantes de l’interface.\nimport Foundation\n")
        self.git("add", ".")

    def git(self, *args):
        return subprocess.check_output(["git", "-C", str(self.root), *args], stderr=subprocess.STDOUT)

    def write(self, path, text):
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text)

    def errors(self, staged=False):
        return guardrails.check(guardrails.Snapshot(self.root, staged=staged))

    def test_valid_repository(self):
        self.assertEqual(self.errors(), [])
        self.assertEqual(self.errors(staged=True), [])

    def test_staged_error_is_not_hidden_by_worktree_fix(self):
        self.write("Sources/MarketCore/Series.swift", "import Foundation\n")
        self.git("add", ".")
        self.write("Sources/MarketCore/Series.swift", "// Décrit une série économique et ses observations.\nimport Foundation\n")
        self.assertEqual(self.errors(), [])
        self.assertTrue(any("description" in error for error in self.errors(staged=True)))

    def test_untracked_files_are_checked_only_in_worktree(self):
        self.write("scratch.txt", "essai")
        self.assertTrue(any("sans responsabilité" in error for error in self.errors()))
        self.assertEqual(self.errors(staged=True), [])

    def test_deleted_target_breaks_link_in_index(self):
        self.write("docs/a.md", "[Contrat](b.md)\n")
        self.write("docs/b.md", "# Contrat\n")
        self.git("add", ".")
        self.git("rm", "-f", "docs/b.md")
        self.assertTrue(any("lien local" in error for error in self.errors(staged=True)))

    def test_forbidden_import_variants(self):
        for statement in ("import SwiftUI", "@preconcurrency import AppKit", "public import UserNotifications", "import struct SwiftUI.Color"):
            with self.subTest(statement=statement):
                self.write("Sources/MarketCore/Series.swift", "// Décrit une série indépendante des vues.\n" + statement + "\n")
                self.assertTrue(any("le cœur" in error for error in self.errors()))

    def test_comment_is_not_an_import(self):
        self.write("Sources/MarketCore/Series.swift", "// Ne pas écrire import SwiftUI ici.\nimport Foundation\n")
        self.assertEqual(self.errors(), [])

    def test_string_is_not_an_import(self):
        self.write("Sources/MarketCore/Series.swift", '// Décrit une instruction sous forme de texte.\nlet example = "import AppKit"\n')
        self.assertEqual(self.errors(), [])

    def test_conflict_and_secret_file(self):
        self.write("docs/a.md", "<<<<<<< HEAD\nconflit\n=======\nautre\n>>>>>>> branche\n")
        self.write(".env", "EXAMPLE=fixture\n")
        errors = self.errors()
        self.assertTrue(any("conflit Git" in error for error in errors))
        self.assertTrue(any("secrets" in error for error in errors))

    def test_release_mirror_drift(self):
        self.write("distribution/release.json", '{"version": "1"}')
        self.write("site/dist/download/release.json", '{"version": "2"}')
        self.assertTrue(any("manifeste canonique" in error for error in self.errors()))

    def test_invalid_json_and_skill(self):
        self.write("docs/data.json", "{")
        self.write(".agents/skills/example/SKILL.md", "---\nname: wrong\ndescription: Exemple\n---\n")
        errors = self.errors()
        self.assertTrue(any("JSON invalide" in error for error in errors))
        self.assertTrue(any("skill invalides" in error for error in errors))

    def test_claude_adapter_cannot_duplicate_rules(self):
        self.write("CLAUDE.md", "@AGENTS.md\nRègle divergente\n")
        self.assertTrue(any("importer uniquement" in error for error in self.errors()))

    def test_required_directives_can_precede_header(self):
        for source in (
            "#!/bin/sh\n# Vérifie les contenus indexés.\nset -eu\n",
            "// swift-tools-version: 6.0\n// Déclare les cibles du package.\nimport PackageDescription\n",
            "<!doctype html>\n<!-- Présente le produit et son téléchargement. -->\n<html>\n",
            '"use strict";\n/* Pilote les états du téléchargement. */\n',
        ):
            with self.subTest(source=source):
                self.assertTrue(guardrails.has_header(source))
        self.assertFalse(guardrails.has_header("#!/bin/sh\nset -eu\n"))


if __name__ == "__main__":
    unittest.main()
