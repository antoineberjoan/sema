# Vérifie que l'export du signe lit sa géométrie dans SignalPath.swift et refuse un SVG écrit à la main.
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))
import export_signe  # noqa: E402


class ExportSigneTests(unittest.TestCase):
    def test_geometry_is_read_from_the_swift_source(self):
        found = export_signe.geometry(export_signe.SIGNAL.read_text())
        self.assertEqual(found["viewBox"], "320")
        self.assertEqual(found["dotCenter"], ["216", "91"])
        self.assertEqual(found["artboard"], ["80", "170", "352", "240"])

    def test_colors_come_from_the_generated_primitives(self):
        colors = export_signe.palette(export_signe.PRIMITIVES.read_text())
        self.assertEqual(colors["ink800"], "#141414")
        self.assertEqual(colors["accent500"], "#1F6F73")

    def test_every_exported_file_is_a_complete_svg(self):
        for name, text in export_signe.files().items():
            self.assertTrue(text.startswith("<svg") and text.rstrip().endswith("</svg>"), name)
            self.assertIn("M120 368 C210 368 232 214 312 214 H392", text, name)

    def test_a_hand_edited_file_is_refused(self):
        target = export_signe.ROOT / "Resources/Brand/sema-logo.svg"
        original = target.read_text()
        try:
            target.write_text(original.replace("#1F6F73", "#123456"))
            self.assertEqual(export_signe.main(["--verifier"]), 1)
        finally:
            target.write_text(original)
        self.assertEqual(export_signe.main(["--verifier"]), 0)


if __name__ == "__main__":
    unittest.main()
