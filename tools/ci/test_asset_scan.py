"""Host tests for the Twinsanity release asset scanner.

These tests validate scanner logic only; they do not execute the game or qualify hardware.
"""
import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("asset_scan", ROOT / "tools/ci/asset_scan.py")
ASSET_SCAN = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ASSET_SCAN)


class AssetScanTests(unittest.TestCase):
    def test_detects_mips_elf_but_not_aarch64_release_binary(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "probe.bin"
            mips = bytearray(64)
            mips[:4] = b"\\x7fELF"
            mips[4:6] = b"\\x01\\x01"
            mips[18:20] = (8).to_bytes(2, "little")
            path.write_bytes(mips)
            self.assertEqual(ASSET_SCAN.magic_of(str(path)), "ELF/IRX executable")

            aarch64 = bytearray(mips)
            aarch64[18:20] = (183).to_bytes(2, "little")
            path.write_bytes(aarch64)
            self.assertEqual(ASSET_SCAN.magic_of(str(path)), "")

    def test_detects_iso9660_magic_at_the_volume_descriptor_offset(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "opaque.data"
            data = bytearray(65536)
            data[0x8001:0x8006] = b"CD001"
            path.write_bytes(data)
            self.assertEqual(ASSET_SCAN.magic_of(str(path)), "ISO9660 disc image")

    def test_engine_is_excluded_by_default_but_game_tree_is_scanned(self):
        self.assertTrue(ASSET_SCAN.excluded("engine", False))
        self.assertFalse(ASSET_SCAN.excluded("engine", True))
        self.assertFalse(ASSET_SCAN.excluded("game", False))

    def test_only_named_livearea_images_receive_the_small_asset_exception(self):
        self.assertTrue(ASSET_SCAN.LIVEAREA_RE.match("sce_sys/icon0.png"))
        self.assertTrue(ASSET_SCAN.LIVEAREA_RE.match("sce_sys/livearea/contents/bg.png"))
        self.assertFalse(ASSET_SCAN.LIVEAREA_RE.match("sce_sys/unreviewed.png"))


if __name__ == "__main__":
    unittest.main()
