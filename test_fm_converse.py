#!/usr/bin/env python3
import importlib.machinery
import importlib.util
import pathlib
import sys
import tempfile
import unittest
from unittest.mock import MagicMock, patch


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

    def test_free_energy_identity_makes_skepticism_an_open_system_analysis(self):
        system = arm_apple.build_system("/Users/esaruoho/work/merlib-dump")

        self.assertIn("Do not automatically pivot to mainstream validation", system)
        self.assertIn("technical accounts on their own terms", system)
        self.assertIn("claimed system boundary", system)
        self.assertIn("Conservation of energy applies to open systems too", system)
        self.assertIn("what measurement, control, or energy balance", system)

    def test_arm_identity_version_invalidates_cached_instructions(self):
        self.assertGreater(fm_converse.ARM_IDENTITY_VERSION, 2)


class FMConverseCaptureTests(unittest.TestCase):
    def test_successful_turn_writes_livefile_pair(self):
        with tempfile.TemporaryDirectory() as tmp:
            old_sessions = fm_converse.SESSIONS
            fm_converse.SESSIONS = pathlib.Path(tmp) / "sessions"
            try:
                did_capture, session_dir = fm_converse._append_capture_turn(
                    key="unit session",
                    state={"cwd": tmp},
                    raw_prompt="hello",
                    user_turn="hello",
                    reply="hi there",
                    use_mlx=True,
                    filename=None,
                )
            finally:
                fm_converse.SESSIONS = old_sessions

            self.assertTrue(did_capture)
            livefile = session_dir / "livefile.jsonl"
            events = [
                __import__("json").loads(line)
                for line in livefile.read_text().splitlines()
            ]
            self.assertEqual([e["type"] for e in events],
                             ["session.created", "talk.heard", "agent.responded"])
            self.assertEqual(events[1]["body"], "hello")
            self.assertEqual(events[2]["body"], "hi there")
            self.assertEqual(events[1]["request_id"], events[2]["request_id"])

    def test_existing_converse_app_turn_is_not_duplicated(self):
        with tempfile.TemporaryDirectory() as tmp:
            old_sessions = fm_converse.SESSIONS
            fm_converse.SESSIONS = pathlib.Path(tmp) / "sessions"
            session_dir = fm_converse.SESSIONS / "live"
            session_dir.mkdir(parents=True)
            (session_dir / "livefile.jsonl").write_text(
                '{"id":"evt_000001","type":"talk.heard","body":"already here"}\n'
            )
            try:
                did_capture, returned_dir = fm_converse._append_capture_turn(
                    key="live",
                    state={"cwd": tmp},
                    raw_prompt="already here",
                    user_turn="already here",
                    reply="answer",
                    use_mlx=False,
                    filename=None,
                )
            finally:
                fm_converse.SESSIONS = old_sessions

            self.assertFalse(did_capture)
            self.assertEqual(returned_dir, session_dir)
            self.assertEqual(
                (session_dir / "livefile.jsonl").read_text().count("\n"),
                1,
            )

    def test_flubuild_turn_records_flubuild_agent_type(self):
        with tempfile.TemporaryDirectory() as tmp:
            old_sessions = fm_converse.SESSIONS
            fm_converse.SESSIONS = pathlib.Path(tmp) / "sessions"
            try:
                did_capture, session_dir = fm_converse._append_capture_turn(
                    key="remote",
                    state={"cwd": tmp},
                    raw_prompt="hello",
                    user_turn="hello",
                    reply="remote answer",
                    use_mlx=False,
                    filename=None,
                    use_flubuild=True,
                )
            finally:
                fm_converse.SESSIONS = old_sessions

            self.assertTrue(did_capture)
            events = [
                __import__("json").loads(line)
                for line in (session_dir / "livefile.jsonl").read_text().splitlines()
            ]
            self.assertEqual(events[1]["agent_type"], "flubuild")
            self.assertEqual(events[2]["agent_type"], "flubuild")
            self.assertEqual(events[1]["model"], fm_converse.FLUBUILD_MODEL)


class FMConverseOutputTests(unittest.TestCase):
    @patch("sys.stdout")
    @patch("sys.stderr")
    @patch("subprocess.run")
    def test_main_success_prints_captured_to_stderr(self, mock_run, mock_stderr, mock_stdout):
        import shutil
        with tempfile.TemporaryDirectory() as tmp:
            old_sessions = fm_converse.SESSIONS
            old_store = fm_converse.STORE
            
            fm_converse.SESSIONS = pathlib.Path(tmp) / "sessions"
            fm_converse.STORE = pathlib.Path(tmp) / "store"
            
            fm_converse.SESSIONS.mkdir(parents=True)
            fm_converse.STORE.mkdir(parents=True)
            
            # Create a mock session directory so current_session_key finds it
            session_dir = fm_converse.SESSIONS / "mock_session"
            session_dir.mkdir()
            
            # Mock subprocess.run for the fm-submit subprocess call
            mock_proc = MagicMock()
            mock_proc.returncode = 0
            mock_proc.stdout = "This is a model response."
            mock_proc.stderr = ""
            mock_run.return_value = mock_proc
            
            # Setup TTY mock so that it prints captured/pushed info to stderr
            mock_stdout.isatty.return_value = True
            
            try:
                with patch.object(sys, "argv", ["fm-converse", "hello context"]):
                    rc = fm_converse.main()
            finally:
                fm_converse.SESSIONS = old_sessions
                fm_converse.STORE = old_store

            self.assertEqual(rc, 0)
            
            # Check stderr outputs
            stderr_calls = [call[0][0] for call in mock_stderr.write.call_args_list]
            combined_stderr = "".join(stderr_calls)
            self.assertIn("captured to", combined_stderr)
            self.assertIn("/sessions/mock_session", combined_stderr)

    @patch("sys.stdout")
    @patch("sys.stderr")
    def test_main_flubuild_uses_remote_backend_and_captures(self, mock_stderr, mock_stdout):
        with tempfile.TemporaryDirectory() as tmp:
            old_sessions = fm_converse.SESSIONS
            old_store = fm_converse.STORE

            fm_converse.SESSIONS = pathlib.Path(tmp) / "sessions"
            fm_converse.STORE = pathlib.Path(tmp) / "store"
            fm_converse.SESSIONS.mkdir(parents=True)
            (fm_converse.SESSIONS / "remote_session").mkdir()

            mock_stdout.isatty.return_value = True

            try:
                with patch.object(sys, "argv", ["fm-converse", "--flubuild", "hello"]):
                    with patch.object(fm_converse, "call_flubuild",
                                      return_value=("flubuild response", None)) as mock_call:
                        rc = fm_converse.main()
            finally:
                fm_converse.SESSIONS = old_sessions
                fm_converse.STORE = old_store

            self.assertEqual(rc, 0)
            mock_call.assert_called_once()
            events = [
                __import__("json").loads(line)
                for line in (pathlib.Path(tmp) / "sessions" / "remote_session" / "livefile.jsonl").read_text().splitlines()
            ]
            self.assertEqual(events[-1]["body"], "flubuild response")
            self.assertEqual(events[-1]["agent_type"], "flubuild")


if __name__ == "__main__":
    unittest.main()
