"""Behavioral checks for drop-folder roundtables; inference is replaced, not required."""
import asyncio
import hashlib
import importlib.util
import json
import io
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("roundtable_bridge", Path(__file__).parent / "roundtable/bridge.py")
bridge = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bridge)
TEST_SEATS = "Bearden,Prigogine,Russell,Hilarion"


class IntakeTests(unittest.TestCase):
    def test_laptop_cannot_run_inference(self):
        with patch.object(bridge.socket, "gethostname", return_value="RayMac.local"):
            with self.assertRaisesRegex(RuntimeError, "CloudcityMacMini-only"):
                bridge.verify_panel(Path("/nonexistent/convey"), bridge.SEATS)

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.source = self.root / "input.txt"
        self.source.write_text("A supplied document with an explicit source claim.\n")
        self.seen = []

    async def runner(self, command, events, timeout, on_turn):
        board = Path(command[command.index("--board") + 1]).read_text()
        self.seen.append(board)
        names = command[command.index("--seat") + 1].split(",")
        turns = int(command[command.index("--turns") + 1])
        items = [{"type": "turn", "name": name, "text": f"Reading {board[-30:]}", "seq": i}
                 for i, name in enumerate((names * turns)[:turns], 1)]
        items += [{"type": "end", "turns": turns}]
        with events.open("w") as out:
            for e in items:
                out.write(json.dumps(e) + "\n")
                out.flush()
                if e["type"] == "turn":
                    on_turn()
        return items

    def process(self, **kwargs):
        return asyncio.run(bridge.process(self.source, runner=self.runner,
                                          seats=TEST_SEATS, preflight=lambda *_: None, **kwargs))

    def test_full_source_long_document_and_tail_are_processed_without_truncation(self):
        text = "line of source evidence\n" * 1100 + "TAIL-MUST-REACH-THE-PANEL"
        self.source.write_text(text)
        state = self.process()
        self.assertEqual("".join(self.seen), text)
        self.assertEqual(state["status"], "complete")
        self.assertEqual(len(state["completed"]), len(bridge.sections(text)))
        result = bridge.output_paths(self.source)[0].read_text()
        self.assertIn("TAIL-MUST-REACH-THE-PANEL", result)
        self.assertIn("Prigogine", result)

    def test_full_installed_bench_gets_two_turns_per_person_including_rigel(self):
        names = "Bearden,Prigogine,Russell,Hilarion,Rigel,Aria,Orion,Vega,Lyra".split(",")
        with patch.object(bridge, "require_mini", return_value="cloudcitymacmini"), \
                patch.object(bridge, "prepare_roster", return_value=names):
            state = asyncio.run(bridge.process(self.source, runner=self.runner,
                                               preflight=lambda *_: None))
        self.assertEqual(state["seats"].split(","), names)
        self.assertEqual(state["turns_per_section"], 18)
        self.assertEqual(state["status"], "complete")
        text = bridge.output_paths(self.source)[0].read_text()
        for name in names:
            self.assertEqual(text.count(f"### {name}\n"), 2)

    def test_cli_keeps_all_seats_dynamic_for_each_new_document(self):
        called = []
        async def fake_process(source, **kwargs):
            called.append(kwargs)
            return {"status": "complete"}
        with patch.object(sys, "argv", ["aimeat-roundtable", "once", "--folder", str(self.root)]), \
                patch.object(bridge, "require_mini", return_value="cloudcitymacmini"), \
                patch.object(bridge, "prepare_roster", return_value=TEST_SEATS.split(",")), \
                patch.object(bridge, "candidates", return_value=[self.source]), \
                patch.object(bridge, "process", fake_process):
            self.assertEqual(bridge.main(), 0)
        self.assertEqual(called[0]["seats"], "all")
        self.assertEqual(called[0]["turns"], 0)

    def test_completed_job_does_not_repeat_or_rewrite_result_on_poll(self):
        self.process()
        result = bridge.output_paths(self.source)[0]
        before = result.stat().st_mtime_ns
        self.process()
        self.assertEqual(len(self.seen), 1)
        self.assertEqual(result.stat().st_mtime_ns, before)

    def test_changed_source_produces_separate_archived_result(self):
        first = self.process()
        self.source.write_text("A different revision")
        second = self.process()
        self.assertNotEqual(first["id"], second["id"])
        self.assertTrue((self.root / ".roundtable" / first["id"] / "transcript.md").exists())

    def test_missing_turns_cannot_be_reported_as_success(self):
        async def partial(command, events, timeout, on_turn):
            events.write_text(json.dumps({"type": "turn", "name": "Bearden", "text": "partial"}) + "\n")
            return [{"type": "end", "turns": 1}]
        state = asyncio.run(bridge.process(self.source, seats=TEST_SEATS, runner=partial, preflight=lambda *_: None))
        self.assertEqual(state["status"], "retrying")
        self.assertEqual(state["completed"], [])
        self.assertIn("incomplete", state["error"])

    def test_restart_skips_completed_sections(self):
        self.source.write_text("x" * 12001)
        calls = 0

        async def fail_second(*args):
            nonlocal calls
            calls += 1
            if calls == 2:
                raise RuntimeError("model temporarily unavailable")
            return await self.runner(*args)

        first = asyncio.run(bridge.process(self.source, seats=TEST_SEATS, runner=fail_second, preflight=lambda *_: None))
        self.assertEqual(first["completed"], [0])
        state = self.process(retry=True)
        self.assertEqual(state["status"], "complete")
        self.assertEqual(len(self.seen), 3)

    def test_edit_during_inference_keeps_old_result_out_of_current_source(self):
        async def change(*args):
            self.source.write_text("Changed while processing")
            return await self.runner(*args)
        state = asyncio.run(bridge.process(self.source, seats=TEST_SEATS, runner=change, preflight=lambda *_: None))
        self.assertEqual(state["status"], "complete")
        status = json.loads(bridge.output_paths(self.source)[1].read_text())
        self.assertNotEqual(status["status"], "complete")

    def test_intake_ignores_generated_sidecars_and_outputs(self):
        for name in ["paper.pdf.text.txt", "audio.transcript.txt", "input.txt.roundtable.md", ".hidden.txt"]:
            (self.root / name).write_text("do not enroll")
        self.assertEqual(bridge.candidates(self.root, 0), [self.source])

    def test_malformed_encoding_rejected_before_inference(self):
        self.source.write_bytes(b"\xff\xfe\x00")
        with self.assertRaises(UnicodeError):
            self.process()
        self.assertEqual(self.seen, [])

    def test_return_collector_files_only_matching_source_and_verified_result(self):
        returned = self.root / "returns/job"
        returned.mkdir(parents=True)
        markdown = "# Mini-generated result\n\nA grounded persona turn.\n"
        state = {"schema": bridge.SCHEMA, "id": "job", "source": self.source.name,
                 "sha256": hashlib.sha256(self.source.read_bytes()).hexdigest(),
                 "result_sha256": hashlib.sha256(markdown.encode()).hexdigest(), "created": 1}
        bridge.write_json(returned / "state.json", state)
        (returned / "transcript.md").write_text("partial sync")
        self.assertEqual(bridge.collect(self.root, returned.parent), 0)
        (returned / "transcript.md").write_text(markdown)
        self.assertEqual(bridge.collect(self.root, returned.parent), 1)
        self.assertEqual(bridge.collect(self.root, returned.parent), 0)
        self.assertEqual(bridge.output_paths(self.source)[0].read_text(), markdown)
        self.source.write_text("Edited source")
        state["created"] = 2
        bridge.write_json(returned / "state.json", state)
        self.assertEqual(bridge.collect(self.root, returned.parent), 0)

    def test_multiline_persona_prose_is_preserved_in_derived_roster(self):
        original = "name: sages\nparticipants:\n  - name: Prigogine\n    stance: >-\n      First statement.\n      Second statement.\n  - name: Hilarion\n    stance: A different voice\n"
        folded = bridge.fold_roster(original)
        self.assertIn("stance: First statement. Second statement.", folded)
        self.assertIn("stance: A different voice", folded)
        self.assertEqual(bridge.fold_roster(folded), folded)

    def test_subprocess_timeout_kills_process_group(self):
        events = self.root / "events.jsonl"
        with self.assertRaises(TimeoutError):
            asyncio.run(bridge.stream_section([sys.executable, "-c", "import time; time.sleep(20)"],
                                              events, 0.1, lambda: None))

    def test_worker_subprocess_uses_loopback_and_disables_ssh(self):
        code = "import json,os;print(json.dumps({'type':'meta','host':os.environ['FM_MLX_HOST'],'resolve':os.environ['FM_MLX_RESOLVE_IP'],'no_ssh':os.environ['FM_MLX_NO_SSH']}))"
        events = asyncio.run(bridge.stream_section([sys.executable, "-c", code],
                                                   self.root / "env.jsonl", 3, lambda: None))
        self.assertEqual(events[0]["host"], "http://127.0.0.1:8080")
        self.assertEqual(events[0]["resolve"], "127.0.0.1")
        self.assertEqual(events[0]["no_ssh"], "1")

    def test_served_model_matches_heartbeat_instead_of_selecting_another_model(self):
        response = io.BytesIO(json.dumps({"data": [{"id": "other"}, {"id": "already-served"}]}).encode())
        with patch.object(bridge.urllib.request, "urlopen", return_value=response), \
                patch.object(bridge, "read_json", return_value={"model": "already-served"}):
            self.assertEqual(bridge.running_mlx_model(), "already-served")


class BootInstallTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        spec = importlib.util.spec_from_file_location("roundtable_install", Path(__file__).parent / "roundtable/install.py")
        cls.install = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.install)

    def test_registry_service_stays_inside_systems_list(self):
        text = "machine:\n  name: cloudcity\nsystems:\n  - name: existing\nother:\n  keep: true\n"
        result = self.install.add_service(text)
        self.assertLess(result.index("name: aimeat-roundtable"), result.index("\nother:"))
        self.assertEqual(self.install.add_service(result), result)
        self.assertIn("name: existing", result)

    def test_old_convey_checkout_uses_the_verified_compatibility_snapshot(self):
        function = self.install.compatible_function("def cmd_roundtable(args):\n    return 0\n")
        self.assertIn("_rt_lore", function)
        self.assertIn("seated_by_name", function)
        self.assertEqual(function.count('"type": "error", "message": ev["msg"]'), 1)
        again = self.install.compatible_function(function)
        self.assertEqual(function[function.index("def cmd_roundtable"):], again)

    def test_boot_pane_insertion_is_idempotent_and_refuses_ambiguous_structure(self):
        original = "tell application \"iTerm\"\n" + self.install.ANCHOR
        result = self.install.add_pane(original)
        self.assertEqual(self.install.add_pane(result), result)
        with self.assertRaises(ValueError):
            self.install.add_pane("unrecognized boot structure")


if __name__ == "__main__":
    unittest.main()
