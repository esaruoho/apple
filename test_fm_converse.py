#!/usr/bin/env python3
import importlib.machinery
import importlib.util
import pathlib
import unittest


def load_module(name, filename):
    path = pathlib.Path(__file__).resolve().parent / "bin" / filename
    loader = importlib.machinery.SourceFileLoader(name, str(path))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


arm_apple = load_module("arm_apple_under_test", "arm_apple.py")
fm_converse = load_module("fm_converse_under_test", "fm-converse")


class FMConverseArmingTests(unittest.TestCase):
    def test_cached_system_turn_reactivates_free_energy_retrieval(self):
        active = fm_converse.activate_armed_skill(
            arm_apple, "/Users/esaruoho/work/merlib-dump")

        self.assertEqual(active["name"], "free-energy")
        self.assertIn("merlib-dump", str(active["corpus"][0]))

    def test_free_energy_identity_does_not_require_unsolicited_debunking(self):
        system = arm_apple.build_system("/Users/esaruoho/work/merlib-dump")

        self.assertIn("Do not automatically pivot to mainstream validation", system)
        self.assertIn("technical accounts on their own terms", system)

    def test_arm_identity_version_invalidates_cached_instructions(self):
        self.assertGreater(fm_converse.ARM_IDENTITY_VERSION, 1)


if __name__ == "__main__":
    unittest.main()
