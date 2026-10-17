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
            ".agents/": "Procédures", ".claude/skills/": "Liens des skills", "AGENTS.md": "Instructions", "CLAUDE.md": "Import",
            "Sources/MarketCore/": "Cœur", "Sources/SemaMac/": "App", "docs/": "Documentation",
            "distribution/": "Release", "site/": "Site", ".env": "Configuration"
        }))
        self.write("AGENTS.md", "# Instructions\n")
        self.write("CLAUDE.md", "@AGENTS.md\n")
        self.write(".agents/skills/example/SKILL.md", "---\nname: example\ndescription: Procédure de test.\n---\n")
        (self.root / ".claude/skills").mkdir(parents=True)
        (self.root / ".claude/skills/example").symlink_to("../../.agents/skills/example")
        self.write("Sources/MarketCore/Series.swift", "// Décrit les observations économiques indépendantes de l’interface.\nimport Foundation\n")
        self.write("distribution/release.json", '{"version": "1"}')
        self.write("site/dist/download/release.json", '{"version": "1"}')
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
        for statement in ("import SwiftUI", "@preconcurrency import AppKit", "public import UserNotifications",
                          "import struct SwiftUI.Color", "import Foundation; import SwiftUI"):
            with self.subTest(statement=statement):
                self.write("Sources/MarketCore/Series.swift", "// Décrit une série indépendante des vues.\n" + statement + "\n")
                self.assertTrue(any("le cœur" in error for error in self.errors()))

    def test_comment_is_not_an_import(self):
        self.write("Sources/MarketCore/Series.swift", "// Ne pas écrire import SwiftUI ici.\nimport Foundation\n")
        self.assertEqual(self.errors(), [])

    def test_string_is_not_an_import(self):
        self.write("Sources/MarketCore/Series.swift", '// Décrit une instruction sous forme de texte.\nlet example = "import AppKit"\n')
        self.assertEqual(self.errors(), [])

    def test_multiline_literals_and_nested_comments_are_not_imports(self):
        for example in (
            'let example = """\nimport SwiftUI\n"""',
            'let example = ##"""\nUne citation : "texte"\nimport AppKit\n"""##',
            '/* Commentaire /* imbriqué */\nimport UserNotifications\n*/',
            'let example = "citation \\\" et /*"',
        ):
            with self.subTest(example=example):
                self.write("Sources/MarketCore/Series.swift", "// Décrit un exemple documentaire.\n" + example + "\nimport Foundation\n")
                self.assertEqual(self.errors(), [])

    def test_literal_comment_markers_cannot_hide_real_import(self):
        self.write("Sources/MarketCore/Series.swift", '// Décrit des marqueurs de texte.\nlet start = "/*"\nimport SwiftUI\nlet end = "*/"\n')
        self.assertTrue(any("le cœur" in error for error in self.errors()))

    def test_markdown_examples_are_not_links(self):
        examples = (
            '`[exemple](missing.md)`',
            '``un ` et [exemple](missing.md)``',
            '```markdown\n[exemple](missing.md)\n```',
            '~~~~markdown\n[exemple](missing.md)\n~~~~',
        )
        for example in examples:
            with self.subTest(example=example):
                self.write("docs/a.md", example + "\n[Contrat](../AGENTS.md)\n")
                self.assertEqual(self.errors(), [])
                self.write("docs/a.md", example + "\n[Contrat](absent.md)\n")
                errors = self.errors()
                self.assertEqual(len(errors), 1)
                self.assertIn("absent.md", errors[0])

    def test_markdown_link_paths_and_titles(self):
        self.write("docs/contrat source.md", "# Contrat\n")
        links = (
            '[Contrat](/AGENTS.md)',
            '[Contrat](../AGENTS.md "Instructions")',
            '[Contrat](contrat%20source.md)',
            '[Contrat](<contrat source.md> "Instructions")',
        )
        for link in links:
            with self.subTest(link=link):
                self.write("docs/a.md", link + "\n")
                self.assertEqual(self.errors(), [])
        self.write("docs/a.md", '[Contrat](<absent.md> "Instructions")\n')
        self.assertTrue(any("absent.md" in error for error in self.errors()))

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

    def test_deleted_release_manifest_is_rejected(self):
        paths = ("distribution/release.json", "site/dist/download/release.json")
        for path in paths:
            with self.subTest(path=path):
                (self.root / path).unlink()
                try:
                    self.assertTrue(any(path in error and "manquant" in error for error in self.errors()))
                    self.assertEqual(self.errors(staged=True), [])
                    self.git("add", "-u", path)
                    self.assertTrue(any(path in error and "manquant" in error for error in self.errors(staged=True)))
                finally:
                    self.write(path, '{"version": "1"}')
                    self.git("add", path)
        for path in paths:
            (self.root / path).unlink()
        self.assertEqual(sum("manquant" in error for error in self.errors()), 2)
        self.git("add", "-u")
        self.assertEqual(sum("manquant" in error for error in self.errors(staged=True)), 2)

    def test_deleted_agents_md_is_rejected(self):
        (self.root / "AGENTS.md").unlink()
        self.assertTrue(any("AGENTS.md" in error for error in self.errors()))
        self.assertEqual(self.errors(staged=True), [])
        self.git("add", "-u", "AGENTS.md")
        self.assertTrue(any("AGENTS.md" in error for error in self.errors(staged=True)))

    def test_invalid_json_and_skill(self):
        self.write("docs/data.json", "{")
        self.write(".agents/skills/example/SKILL.md", "---\nname: wrong\ndescription: Exemple\n---\n")
        errors = self.errors()
        self.assertTrue(any("JSON invalide" in error for error in errors))
        self.assertTrue(any("skill invalides" in error for error in errors))

    def test_claude_adapter_cannot_duplicate_rules(self):
        self.write("CLAUDE.md", "@AGENTS.md\nRègle divergente\n")
        self.assertTrue(any("importer uniquement" in error for error in self.errors()))

    def test_missing_skill_link_is_rejected(self):
        path = ".claude/skills/example"
        (self.root / path).unlink()
        self.assertTrue(any("lien symbolique requis" in error for error in self.errors()))
        self.assertEqual(self.errors(staged=True), [])
        self.git("add", "-u", path)
        self.assertTrue(any("lien symbolique requis" in error for error in self.errors(staged=True)))

    def test_wrong_skill_link_in_index_is_not_hidden_by_worktree_fix(self):
        path = self.root / ".claude/skills/example"
        path.unlink()
        path.symlink_to("../../.agents/skills/absent")
        self.assertTrue(any("lien symbolique requis" in error for error in self.errors()))
        self.git("add", ".claude/skills/example")
        path.unlink()
        path.symlink_to("../../.agents/skills/example")
        self.assertEqual(self.errors(), [])
        self.assertTrue(any("lien symbolique requis" in error for error in self.errors(staged=True)))

    def test_skill_copy_cannot_replace_link(self):
        (self.root / ".claude/skills/example").unlink()
        self.write(".claude/skills/example/SKILL.md", (self.root / ".agents/skills/example/SKILL.md").read_text())
        self.assertTrue(any("seuls les liens" in error for error in self.errors()))
        self.git("add", ".")
        self.assertTrue(any("seuls les liens" in error for error in self.errors(staged=True)))

    def test_plain_text_cannot_replace_skill_link(self):
        path = ".claude/skills/example"
        (self.root / path).unlink()
        self.write(path, "../../.agents/skills/example")
        self.assertTrue(any("lien symbolique requis" in error for error in self.errors()))
        self.git("add", path)
        self.assertTrue(any("lien symbolique requis" in error for error in self.errors(staged=True)))

    def test_orphan_skill_link_is_rejected(self):
        (self.root / ".claude/skills/obsolete").symlink_to("../../.agents/skills/example")
        self.assertTrue(any("obsolete" in error for error in self.errors()))
        self.git("add", ".")
        self.assertTrue(any("obsolete" in error for error in self.errors(staged=True)))

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

    def test_hardcoded_values_are_rejected(self):
        for line in (
            ".background(.clear, in: RoundedRectangle(cornerRadius: 12))",
            ".font(.system(size: 11, weight: .medium))",
            ".font(.system(size: focus ? 14 : 18))",
            ".font(.system(size: side * 0.4))",
            "withAnimation(.easeOut(duration: 0.2)) { open = true }",
            ".stroke(style: StrokeStyle(lineWidth: 2.3))",
            "let shape = RoundedRectangle(cornerRadius: 24)",
            ".padding(.horizontal, 26)",
            ".padding(compact ? 16 : 14)",
            "VStack(alignment: .leading, spacing: 10) {",
            "Spacer(minLength: 6)",
            ".frame(width: index == step ? 18 : 6, height: Layout.dot)",
            ".frame(minWidth: 230, maxWidth: .infinity)",
            ".background(Color.primary.opacity(0.035))",
            ".tracking(-0.6).lineLimit(2)",
            ".offset(y: reduceMotion ? 0 : 6)",
            ".listRowInsets(EdgeInsets(top: 2, leading: 10, bottom: 2, trailing: 10))",
            "if event.keyCode == 53 { close() }",
            "if [36, 76].contains(event.keyCode) { commit() }",
            "static let standard = Shortcut(key: kVK_ANSI_B)\nif event.keyCode == 53 { close() }",
        ):
            with self.subTest(line=line):
                self.write("Sources/SemaMac/Card.swift", "// Décrit un rendu de série.\n" + line + "\n")
                errors = self.errors()
                self.assertEqual(len(errors), 1)
                self.assertIn(f"Sources/SemaMac/Card.swift:{line.count(chr(10)) + 2} ", errors[0])

    def test_named_and_structural_values_are_accepted(self):
        for line in (
            "static let corner: CGFloat = 12",
            "private static let selection = Animation.snappy(duration: 0.18, extraBounce: 0)",
            ".background(.clear, in: RoundedRectangle(cornerRadius: Layout.corner))",
            ".stroke(style: StrokeStyle(lineWidth: 1))",
            "if Int(event.keyCode) == kVK_Escape { close() }",
            'let label = "size: 12, keyCode == 53"',
            "// cornerRadius: 12 reste un commentaire",
            "var size: CGFloat = 32",
            'static let standard = Self(\n    ribbon: Shortcut(keyCode: 11, key: "B"))',
            ".padding(SemaTheme.rowPadding).frame(width: 0, height: 0)",
            ".opacity(stage >= 2 ? 1 : 0)",
            ".frame(maxWidth: .infinity, minHeight: Self.emptyMinHeight)",
            ".lineLimit(1).minimumScaleFactor(Self.valueMinimumScale)",
            "let step = (upper - lower) / 2",
        ):
            with self.subTest(line=line):
                self.write("Sources/SemaMac/Card.swift", "// Décrit un rendu de série.\n" + line + "\n")
                self.assertEqual(self.errors(), [])

    def test_layout_values_are_checked_only_in_the_app(self):
        self.write("Sources/MarketCore/Series.swift", "// Décrit une série.\nlet window = Window(width: 300, spacing: 4)\n")
        self.assertEqual(self.errors(), [])

    def test_one_visible_type_per_file(self):
        for path, source in (
            ("Sources/MarketCore/Series.swift", "public struct Series {}\npublic enum SeriesUnit {}\n"),
            ("Sources/MarketCore/Series.swift", "public struct Observation {}\n"),
            ("Sources/MarketCore/Series+Format.swift", "extension Observation {}\n"),
            ("Sources/MarketCore/Format.swift", "extension Series {}\n"),
        ):
            with self.subTest(path=path, source=source):
                self.write(path, "// Décrit une série.\n" + source)
                self.assertTrue(any(path in error and "fichier" in error for error in self.errors()))
                (self.root / path).unlink()

    def test_private_helpers_and_extension_files_are_accepted(self):
        self.write("Sources/MarketCore/Series.swift",
                   "// Décrit une série.\n@MainActor\npublic struct Series<Value> {\n    struct Point {}\n}\nprivate enum Parser {}\nextension Series {}\n")
        self.write("Sources/MarketCore/Series+Format.swift", "// Formate une série.\nextension Series {}\n")
        self.assertEqual(self.errors(), [])

    def test_shadow_belongs_to_design_system(self):
        source = "// Décrit une surface flottante.\n.shadow(color: .black.opacity(shadow.opacity), radius: shadow.radius)\n"
        self.write("Sources/SemaMac/Features/Panel.swift", source)
        self.write("Sources/SemaMac/DesignSystem/Shadow.swift", source)
        self.write("Sources/SemaMac/Features/Card.swift", "// Décrit une carte.\n.shadow(.card)\n")
        errors = self.errors()
        self.assertEqual(len(errors), 1)
        self.assertIn("Features/Panel.swift:2 : ombre", errors[0])


if __name__ == "__main__":
    unittest.main()
