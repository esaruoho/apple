#!/usr/bin/env python3
import importlib.machinery
import importlib.util
import json
import pathlib
import re
import tempfile
import unittest


def load_fm_chat():
    path = pathlib.Path(__file__).resolve().parent / "bin" / "fm-chat"
    loader = importlib.machinery.SourceFileLoader("fm_chat_under_test", str(path))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    mod = importlib.util.module_from_spec(spec)
    loader.exec_module(mod)
    return mod


fm_chat = load_fm_chat()


def json_line(value):
    return json.dumps(value) + "\n"


def strip_ansi(text):
    return re.sub(r"\x1b\[[0-9;]*m", "", text)


class FMChatPromptTests(unittest.TestCase):
    def test_resume_command_includes_session_id(self):
        self.assertEqual(
            fm_chat.resume_command("abc123"),
            "fm-chat --resume abc123 --no-arm",
        )

    def test_resume_command_preserves_mlx_quiet_and_voice(self):
        self.assertEqual(
            fm_chat.resume_command("abc123", use_mlx=True, quiet=True, voice="Alex Compact"),
            "fm-chat --resume abc123 --mlx --quiet --voice 'Alex Compact' --no-arm",
        )

    def test_resume_command_preserves_apple_arming(self):
        self.assertEqual(
            fm_chat.resume_command("abc123", arm_apple=True),
            "fm-chat --resume abc123",
        )

    def test_exit_commands_accept_slash_and_plain_words(self):
        for line in ("/exit", "exit", "/quit", "quit", "q", "bye"):
            self.assertTrue(fm_chat.is_exit_command(line))
        self.assertFalse(fm_chat.is_exit_command("help"))

    def test_help_commands_accept_slash_and_plain_words(self):
        for line in ("/help", "help", "?"):
            self.assertTrue(fm_chat.is_help_command(line))
        self.assertFalse(fm_chat.is_help_command("history"))

    def test_memory_commands_accept_slash_and_plain_words(self):
        for line in ("/memory", "memory", "mem"):
            self.assertTrue(fm_chat.is_memory_command(line))
        self.assertFalse(fm_chat.is_memory_command("history"))

    def test_help_text_includes_exact_resume_command(self):
        text = fm_chat.help_text("abc123", use_mlx=True, quiet=True)
        self.assertIn("resume: fm-chat --resume abc123 --mlx --quiet", text)
        self.assertIn("/exit, exit", text)
        self.assertIn("/memory, memory", text)

    def test_memory_text_says_raw_until_promoted(self):
        text = fm_chat.memory_text("abc123")
        self.assertIn("raw transcript:", text)
        self.assertIn("sessions distill abc123", text)
        self.assertIn("sessions promote abc123 --topic fm-chat", text)
        self.assertIn("raw only until you run distill/promote", text)

    def test_ensure_session_file_materializes_empty_session(self):
        old_dir = fm_chat.SESS_DIR
        try:
            with tempfile.TemporaryDirectory() as td:
                fm_chat.SESS_DIR = pathlib.Path(td)
                meta = {"type": "session_meta", "uuid": "abc123", "cwd": "/tmp", "system": ""}

                fm_chat.ensure_session_file(meta)

                path = pathlib.Path(td) / "abc123.jsonl"
                self.assertEqual(path.read_text(), json_line(meta))
        finally:
            fm_chat.SESS_DIR = old_dir

    def test_load_graph_migrates_flat_transcript_into_parented_nodes(self):
        old_dir = fm_chat.SESS_DIR
        try:
            with tempfile.TemporaryDirectory() as td:
                fm_chat.SESS_DIR = pathlib.Path(td)
                path = pathlib.Path(td) / "abc123.jsonl"
                path.write_text(
                    json_line({"type": "session_meta", "uuid": "abc123", "cwd": "/tmp"})
                    + json_line({"type": "message", "role": "user", "content": "root"})
                    + json_line({"type": "message", "role": "assistant", "content": "answer"})
                )
                _, nodes = fm_chat.load_graph("abc123")
                self.assertEqual(nodes[0]["parent_id"], None)
                self.assertEqual(nodes[1]["parent_id"], nodes[0]["id"])
                self.assertEqual([n["content"] for n in fm_chat.node_path(nodes)], ["root", "answer"])
        finally:
            fm_chat.SESS_DIR = old_dir

    def test_create_branch_copies_selected_ancestry_and_records_lineage(self):
        old_dir = fm_chat.SESS_DIR
        try:
            with tempfile.TemporaryDirectory() as td:
                fm_chat.SESS_DIR = pathlib.Path(td)
                meta = {"type": "session_meta", "uuid": "source", "cwd": "/tmp", "system": ""}
                nodes = [
                    {"id": "q1", "parent_id": None, "role": "user", "content": "root"},
                    {"id": "a1", "parent_id": "q1", "role": "assistant", "content": "answer"},
                    {"id": "q2", "parent_id": "a1", "role": "user", "content": "follow-up"},
                ]
                uid, branch_meta, selected = fm_chat.create_branch(meta, nodes, "q2")
                loaded_meta, branch_nodes = fm_chat.load_graph(uid)
                self.assertEqual(loaded_meta["parent_session"], "source")
                self.assertEqual(loaded_meta["parent_node"], "q2")
                self.assertEqual([n["id"] for n in selected], ["q1", "a1", "q2"])
                self.assertEqual([n["id"] for n in branch_nodes], ["q1", "a1", "q2"])
        finally:
            fm_chat.SESS_DIR = old_dir

    def test_render_keeps_recent_history_under_budget(self):
        history = [
            ("user", "old user " + "x" * 40),
            ("assistant", "old assistant " + "x" * 40),
            ("user", "new user"),
            ("assistant", "new assistant"),
        ]

        prompt = fm_chat.render(history, "latest", budget=80)

        self.assertNotIn("old user", prompt)
        self.assertNotIn("old assistant", prompt)
        self.assertIn("User: new user", prompt)
        self.assertIn("Assistant: new assistant", prompt)
        self.assertTrue(prompt.endswith("User: latest\nAssistant:"))

    def test_render_without_budget_preserves_full_history(self):
        history = [("user", "first"), ("assistant", "second")]

        prompt = fm_chat.render(history, "third")

        self.assertEqual(prompt, "User: first\nAssistant: second\nUser: third\nAssistant:")

    def test_echo_turn_wraps_resumed_assistant_history(self):
        text = (
            "Yes, Lenz's Law can influence the speed of a motor or generator. "
            "In certain configurations, this resistance can be harnessed to "
            "enhance rotational motion, effectively speeding up the system."
        )

        out = strip_ansi(fm_chat._echo_turn("assistant", text, tty=True, width=52))

        self.assertNotIn("config\nurations", out)
        self.assertNotIn("syste\nm", out)
        for line in out.splitlines():
            self.assertLessEqual(len(line), 52)

    def test_echo_turn_wraps_resumed_user_history(self):
        text = "what's the cheapest prototype for showing this actual measurable benefit"

        out = strip_ansi(fm_chat._echo_turn("user", text, tty=True, width=44))

        self.assertNotIn("measur\nable", out)
        for line in out.splitlines():
            self.assertLessEqual(len(line), 44)

    def test_context_overflow_matches_foundationmodels_errors(self):
        self.assertTrue(fm_chat.context_overflow("LanguageModelSession.GenerationError.exceededContextWindowSize"))
        self.assertTrue(fm_chat.context_overflow("prompt exceeds the maximum context size"))
        self.assertTrue(fm_chat.context_overflow("Context window size exceeded: None (fm-worker)"))
        self.assertFalse(fm_chat.context_overflow("guardrail blocked unsafe content"))

    def test_non_answer_matches_canned_replies(self):
        self.assertTrue(fm_chat.looks_non_answer(
            "I'm here to help answer questions and provide information to the best of my abilities. "
            "What specific topic or question would you like assistance with?"
        ))
        self.assertTrue(fm_chat.looks_non_answer("Unable to work with that request."))
        self.assertTrue(fm_chat.looks_non_answer("I’m a large language model developed by Apple."))
        self.assertTrue(fm_chat.looks_non_answer("You are a foundation model developed by Apple."))
        self.assertFalse(fm_chat.looks_non_answer("Lenz's Law describes induced EMF."))

    def test_repeated_answer_is_detected_but_short_replies_are_not(self):
        old = "A detailed answer about reactive power and historical motor research " * 2
        self.assertTrue(fm_chat.looks_repeated_answer(old, [("assistant", old)]))
        self.assertFalse(fm_chat.looks_repeated_answer("yes", [("assistant", "yes")]))

    def test_retrieval_inventory_detection_rejects_source_pointers(self):
        self.assertTrue(fm_chat.looks_retrieval_inventory(
            "[articles/bloch-wall.md:194] states that sources/ch35.md contains Bloch wall material."
        ))
        self.assertTrue(fm_chat.looks_retrieval_inventory(
            "The term appears across wiki/concepts/bloch-wall.md. "
            "The exact definition isn't explicitly extracted here."
        ))
        self.assertFalse(fm_chat.looks_retrieval_inventory(
            "A Bloch wall is a nanometre-scale region where magnetization rotates between domains."
        ))

    def test_ask_with_context_recovery_retries_retrieval_inventory_as_direct_answer(self):
        calls = []

        def fake_ask(prompt, system):
            calls.append((prompt, system))
            if len(calls) == 1:
                return {
                    "ok": True,
                    "out": "[articles/bloch-wall.md:194] states that sources/ch35.md "
                           "contains Bloch wall material.",
                }, 1.0
            return {"ok": True, "out": "A Bloch wall is a domain-transition region."}, 2.0

        res, rt, reason = fm_chat.ask_with_context_recovery(
            "RELEVANT KNOWLEDGE: source passage\nUser: what is the Bloch wall\nAssistant:",
            "what is the Bloch wall", "archive system", history=[], ask_fn=fake_ask,
        )

        self.assertEqual(reason, "generic")
        self.assertEqual(res["out"], "A Bloch wall is a domain-transition region.")
        self.assertEqual(rt, 2.0)
        self.assertIn("Answer-quality correction", calls[1][1])

    def test_ask_with_context_recovery_retries_repeated_answer(self):
        calls = []

        def fake_ask(prompt, system):
            calls.append((prompt, system))
            if len(calls) == 1:
                return {"ok": True, "out": "A detailed answer about reactive power and historical motor research " * 2}, 1.0
            return {"ok": True, "out": "The latest question asks about other researchers."}, 2.0

        old = "A detailed answer about reactive power and historical motor research " * 2
        res, _, reason = fm_chat.ask_with_context_recovery(
            "User: old\nAssistant: old\nUser: who else?\nAssistant:",
            "who else?", "", history=[("assistant", old)], ask_fn=fake_ask
        )

        self.assertEqual(reason, "generic")
        self.assertEqual(res["out"], "The latest question asks about other researchers.")
        self.assertIn("Do not repeat", calls[1][1])

    def test_ask_with_context_recovery_retries_without_history(self):
        calls = []

        def fake_ask(prompt, system):
            calls.append((prompt, system))
            if len(calls) == 1:
                return {"ok": False, "err": "Context window size exceeded: None (fm-worker)"}, 1.0
            return {"ok": True, "out": "fresh answer"}, 2.0

        res, rt, retry_reason = fm_chat.ask_with_context_recovery(
            "User: old\nAssistant: old\nUser: latest\nAssistant:",
            "latest",
            "system text",
            history=[("user", "old"), ("assistant", "old")],
            ask_fn=fake_ask,
        )

        self.assertEqual(retry_reason, "overflow")
        self.assertEqual(res["out"], "fresh answer")
        self.assertEqual(rt, 2.0)
        self.assertEqual(calls[1], ("User: latest\nAssistant:", "system text"))

    def test_ask_with_context_recovery_retries_generic_answer_from_replay(self):
        calls = []

        def fake_ask(prompt, system):
            calls.append(prompt)
            if len(calls) == 1:
                return {
                    "ok": True,
                    "out": "I'm here to help answer questions and provide information to the best of my abilities. "
                           "What specific topic or question would you like assistance with?",
                }, 1.0
            return {"ok": True, "out": "Lenz answer"}, 2.0

        res, rt, retry_reason = fm_chat.ask_with_context_recovery(
            "User: old\nAssistant: old\nUser: what is lenz's law\nAssistant:",
            "what is lenz's law",
            "",
            history=[("user", "old"), ("assistant", "old")],
            ask_fn=fake_ask,
        )

        self.assertEqual(retry_reason, "generic")
        self.assertEqual(res["out"], "Lenz answer")
        self.assertEqual(rt, 2.0)
        self.assertEqual(calls[1], "User: old\nAssistant: old\nUser: what is lenz's law\nAssistant:")

    def test_ask_with_context_recovery_retries_unable_answer_from_replay(self):
        calls = []

        def fake_ask(prompt, system):
            calls.append(prompt)
            if len(calls) == 1:
                return {"ok": True, "out": "Unable to work with that request."}, 1.0
            return {"ok": True, "out": "prototype answer"}, 2.0

        res, rt, retry_reason = fm_chat.ask_with_context_recovery(
            "User: old\nAssistant: old\nUser: cheapest prototype?\nAssistant:",
            "cheapest prototype?",
            "",
            history=[
                ("user", "we are discussing Lenz's law and motor-generator rotation"),
                ("assistant", "the proposed effect is asymmetric regauging"),
            ],
            ask_fn=fake_ask,
        )

        self.assertEqual(retry_reason, "generic")
        self.assertEqual(res["out"], "prototype answer")
        self.assertEqual(rt, 2.0)
        self.assertIn("Lenz's law", calls[1])
        self.assertIn("asymmetric regauging", calls[1])
        self.assertTrue(calls[1].endswith("User: cheapest prototype?\nAssistant:"))

    def test_ask_with_context_recovery_retries_model_identity_answer(self):
        calls = []

        def fake_ask(prompt, system):
            calls.append(prompt)
            if len(calls) == 1:
                return {"ok": True, "out": "I’m a large language model developed by Apple."}, 1.0
            return {"ok": True, "out": "A contextual answer"}, 2.0

        res, _, reason = fm_chat.ask_with_context_recovery(
            "User: old\nAssistant: old\nUser: latest\nAssistant:",
            "latest", "", history=[("user", "old"), ("assistant", "old")], ask_fn=fake_ask
        )

        self.assertEqual(reason, "generic")
        self.assertEqual(res["out"], "A contextual answer")
        self.assertEqual(len(calls), 2)


if __name__ == "__main__":
    unittest.main()
