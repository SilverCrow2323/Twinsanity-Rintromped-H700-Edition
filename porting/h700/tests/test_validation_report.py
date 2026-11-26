import sys
import tempfile
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "device"))
from validation_report import ReportError, build_report, inspect_evidence, markdown, verify_report
FIXTURES=Path(__file__).parent/"fixtures"/"h700-evidence"
class ValidationReportTests(unittest.TestCase):
    def test_builds_hash_linked_report(self):
        report=build_report(FIXTURES,"RG35XX H","muOS 2606.0_ANDROMEDA","abcdef0123456789")
        self.assertEqual(report["evidence"]["observed"]["sdl_result"],"PASS")
        self.assertEqual(report["evidence"]["observed"]["sdl_video_driver"],"mali")
        self.assertEqual(len(report["evidence"]["files"]["egl"]["sha256"]),64)
        self.assertIn("does not certify game rendering",markdown(report))
    def test_rejects_missing_evidence(self):
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(ReportError): inspect_evidence(Path(tmp))
    def test_rejects_sdl_warning_instead_of_pass(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            for path in FIXTURES.iterdir(): (root/path.name).write_bytes(path.read_bytes())
            sdl=root/"sdl-window-report.txt"
            sdl.write_text(sdl.read_text().replace("[RESULT] PASS:","[RESULT] WARN:"),encoding="utf-8")
            with self.assertRaises(ReportError): inspect_evidence(root)

    def test_verifies_unchanged_evidence_bundle(self):
        report=build_report(FIXTURES,"RG35XX H","muOS 2606.0_ANDROMEDA","abcdef0123456789")
        verify_report(report,FIXTURES)

    def test_rejects_modified_evidence_bundle(self):
        report=build_report(FIXTURES,"RG35XX H","muOS 2606.0_ANDROMEDA","abcdef0123456789")
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            for path in FIXTURES.iterdir(): (root/path.name).write_bytes(path.read_bytes())
            with (root/"sdl-window-report.txt").open("a",encoding="utf-8") as stream:
                stream.write("tampered\\n")
            with self.assertRaisesRegex(ReportError,"fingerprint mismatch"):
                verify_report(report,root)

    def test_rejects_symlinked_evidence_file(self):
        report=build_report(FIXTURES,"RG35XX H","muOS 2606.0_ANDROMEDA","abcdef0123456789")
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            for path in FIXTURES.iterdir():
                if path.name != "egl-gles-report.txt": (root/path.name).write_bytes(path.read_bytes())
            (root/"egl-gles-report.txt").symlink_to(FIXTURES/"egl-gles-report.txt")
            with self.assertRaisesRegex(ReportError,"unsafe evidence file"):
                verify_report(report,root)

    def test_rejects_invalid_commit(self):
        with self.assertRaises(ReportError): build_report(FIXTURES,"RG35XX H","muOS","not-a-commit")
if __name__=="__main__": unittest.main()
