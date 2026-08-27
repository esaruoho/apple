#!/usr/bin/env python3
import importlib.machinery
import importlib.util
import pathlib
import re
import unittest


def load_fm_render():
    path = pathlib.Path(__file__).resolve().parent / "bin" / "fm_render.py"
    loader = importlib.machinery.SourceFileLoader("fm_render_under_test", str(path))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    mod = importlib.util.module_from_spec(spec)
    loader.exec_module(mod)
    return mod


fm_render = load_fm_render()


def strip_ansi(text):
    return re.sub(r"\x1b\[[0-9;]*m", "", text)


class FMRenderWrapTests(unittest.TestCase):
    def test_format_reply_wraps_words_before_terminal_hard_wrap(self):
        answer = (
            "Yes, Lenz's Law can be applied to situations involving the increase "
            "of rotation without splitting words across terminal rows."
        )

        rendered = strip_ansi(fm_render.format_reply(answer, tty=True, width=42))

        self.assertNotIn("rota\ntion", rendered)
        self.assertNotIn("situat\nions", rendered)
        for line in rendered.splitlines():
            self.assertLessEqual(len(line), 42)

    def test_wrap_markdown_preserves_code_fence_contents(self):
        answer = "Before\n```text\naveryveryverylongunbrokenline\n```\nAfter"

        rendered = strip_ansi(fm_render.format_reply(answer, tty=True, width=42))

        self.assertIn("averyveryverylongunbrokenline", rendered)


if __name__ == "__main__":
    unittest.main()
