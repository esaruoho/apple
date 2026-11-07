#!/usr/bin/env python3
import importlib.machinery
import importlib.util
import json
import pathlib
import sys
import unittest
from unittest.mock import MagicMock, patch

def load_fm_submit():
    path = pathlib.Path(__file__).resolve().parent / "bin" / "fm-submit"
    loader = importlib.machinery.SourceFileLoader("fm_submit_under_test", str(path))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    mod = importlib.util.module_from_spec(spec)
    loader.exec_module(mod)
    sys.modules["fm_submit_under_test"] = mod
    return mod

fm_submit = load_fm_submit()

class FMSubmitRefusalAndNeutralizationTests(unittest.TestCase):
    def test_looks_refused_detects_standard_refusal_patterns(self):
        self.assertTrue(fm_submit.looks_refused("I'm sorry, I can't assist with that request."))
        self.assertTrue(fm_submit.looks_refused("I cannot help with this query."))
        self.assertTrue(fm_submit.looks_refused("I am unable to comply."))
        self.assertFalse(fm_submit.looks_refused("The primary model was developed by Apple in California."))

    def test_neutralize_candidates_handles_group_copular_generalization(self):
        prompt = "the Finnish people are really into kombucha"
        cands = fm_submit.neutralize_candidates(prompt)
        self.assertIn("Why is kombucha popular among Finnish people?", cands)
        self.assertIn("Tell me about Finnish kombucha.", cands)

    def test_neutralize_candidates_handles_plain_query_fallback(self):
        prompt = "Lenz's Law and rotating magnetic fields in Bedini motors"
        cands = fm_submit.neutralize_candidates(prompt)
        self.assertIn("Tell me about Lenz's Law rotating magnetic fields Bedini motors.", cands)


class FMSubmitExecutionTests(unittest.TestCase):
    @patch("sys.stdout")
    @patch("sys.stderr")
    @patch("fm_submit_under_test.save_local_note")
    @patch("fm_submit_under_test.save_to_knowledgebank")
    @patch("fm_submit_under_test.wait_for")
    @patch("fm_submit_under_test.submit")
    def test_happy_path_includes_model_name_in_stderr_metadata(self, mock_submit, mock_wait_for, mock_save_kb, mock_save_local, mock_stderr, mock_stdout):
        # Setup mocks
        mock_submit.return_value = pathlib.Path("/tmp/dummy_job.json")
        mock_save_kb.return_value = "~/.config/apple-bar/foundationmodels-knowledgebank.md"
        mock_save_local.return_value = "./20260922-164512-test-prompt.md"
        mock_wait_for.return_value = (
            {
                "ok": True,
                "out": "Here is your response.",
                "model_ms": 1200,
                "model": "Apple FoundationModels",
                "host": "cloudcitymacmini"
            },
            2.5
        )

        # Execute main via fm_submit's main function
        with patch.object(sys, "argv", ["fm-submit", "test prompt"]):
            rc = fm_submit.main()

        self.assertEqual(rc, 0)
        # Verify response text goes to stdout
        mock_stdout.write.assert_any_call("Here is your response.\n")
        
        # Verify save_to_knowledgebank was called
        mock_save_kb.assert_called_once_with("test prompt", "Here is your response.")
        # Verify save_local_note was called
        mock_save_local.assert_called_once_with("test prompt", "Here is your response.", "Apple FoundationModels")
        
        # Verify stderr contains the correct model name and path
        stderr_calls = [call[0][0] for call in mock_stderr.write.call_args_list]
        combined_stderr = "".join(stderr_calls)
        self.assertIn("Apple FoundationModels", combined_stderr)
        self.assertIn("model 1.2s", combined_stderr)
        self.assertIn("round-trip 2.5s", combined_stderr)
        self.assertIn("cloudcitymacmini", combined_stderr)
        self.assertIn("stored to ./20260922-164512-test-prompt.md", combined_stderr)
        self.assertIn("banked to ~/.config/apple-bar/foundationmodels-knowledgebank.md", combined_stderr)

    @patch("sys.stdout")
    @patch("sys.stderr")
    @patch("fm_submit_under_test.save_local_note")
    @patch("fm_submit_under_test.save_to_knowledgebank")
    @patch("fm_submit_under_test.wait_for")
    @patch("fm_submit_under_test.submit")
    def test_happy_path_falls_back_to_foundationmodels_when_not_provided(self, mock_submit, mock_wait_for, mock_save_kb, mock_save_local, mock_stderr, mock_stdout):
        # Setup mocks
        mock_submit.return_value = pathlib.Path("/tmp/dummy_job.json")
        mock_save_kb.return_value = "~/.config/apple-bar/foundationmodels-knowledgebank.md"
        mock_save_local.return_value = "./20260922-164512-test-fallback.md"
        mock_wait_for.return_value = (
            {
                "ok": True,
                "out": "Fallback response.",
                "model_ms": 800,
                "host": "local"
            },
            1.1
        )

        # Execute main
        with patch.object(sys, "argv", ["fm-submit", "test fallback"]):
            rc = fm_submit.main()

        self.assertEqual(rc, 0)
        # Verify save_to_knowledgebank was called
        mock_save_kb.assert_called_once_with("test fallback", "Fallback response.")
        # Verify save_local_note was called
        mock_save_local.assert_called_once_with("test fallback", "Fallback response.", "FoundationModels")
        
        # Verify stderr contains fallback "FoundationModels" and path
        stderr_calls = [call[0][0] for call in mock_stderr.write.call_args_list]
        combined_stderr = "".join(stderr_calls)
        self.assertIn("FoundationModels", combined_stderr)
        self.assertIn("model 0.8s", combined_stderr)
        self.assertIn("round-trip 1.1s", combined_stderr)
        self.assertIn("stored to ./20260922-164512-test-fallback.md", combined_stderr)
        self.assertIn("banked to ~/.config/apple-bar/foundationmodels-knowledgebank.md", combined_stderr)


if __name__ == "__main__":
    unittest.main()
