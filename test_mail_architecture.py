"""Guard migrated production callers against equivalent rendering/transport bypasses."""
from pathlib import Path
import unittest
from shared.mail_architecture_guard import check, violations
class ArchitectureTests(unittest.TestCase):
    def test_production_paths(self):
        self.assertEqual(check(Path(__file__).resolve().parent), [])
    def test_guard_detects_direct_transport(self):
        self.assertTrue(violations("def send_email():\n urllib.request.urlopen(request)", "fixture"))
    def test_guard_allows_canonical_content(self):
        self.assertEqual(violations("def receipt():\n return MailContent(text).payload()", "fixture"), [])
