#!/usr/bin/env python3
"""Surgical, idempotent installation of cloud source files into existing renderers.

REPORT-CARD >> features/cloud-source-markdown.feature
"""
from pathlib import Path
import shutil


WORD_HOOK = '''    # REPORT-CARD >> ../apple/features/cloud-source-markdown.feature
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from cloud_source import write_cloud_source
    write_cloud_source(out_png, "wordcloud", list(frequencies.items()),
                       {"width": 1600, "height": 900, "max_words": 200,
                        "background": "black", "title": title, "random_state": 42,
                        "relative_scaling": 0.5, "collocations": False, "prefer_horizontal": 0.85})
'''
SENTENCE_HOOK = '''    # REPORT-CARD >> ../apple/features/cloud-source-markdown.feature
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from cloud_source import write_cloud_source
    kind = "ideacloud" if any(s in Path(out_png).stem for s in ("keyideas", "ideacloud")) else "sentencecloud"
    write_cloud_source(out_png, kind, top, {"width": width, "background": "black"})
'''


def insert(text, old, new):
    if new in text:
        return text
    if text.count(old) != 1:
        raise ValueError('Cloud generator changed; refusing ambiguous patch: '+old[:70])
    return text.replace(old, new)


def word(text):
    anchor = '    wc = WordCloud(\n'
    if WORD_HOOK not in text:
        text = insert(text, anchor, WORD_HOOK+anchor)
    text = insert(text, '        max_words=200,\n', '        max_words=200,\n        random_state=42,\n')
    text = insert(text, '        if not tokens:\n', '        if path.name.endswith(".source.md"):\n            continue\n        if not tokens:\n')
    return text


def sentence(text):
    anchor = '    scale = width / 3600.0\n'
    if SENTENCE_HOOK not in text:
        text = insert(text, anchor, SENTENCE_HOOK+anchor)
    text = text.replace('_BG_TOP = (26, 28, 50)', '_BG_TOP = (0, 0, 0)')
    text = text.replace('_BG_BOTTOM = (10, 10, 16)', '_BG_BOTTOM = (0, 0, 0)')
    text = insert(text, '        if f.is_file() and f.suffix.lower() in (".txt", ".md", ".markdown", ".text"):',
                  '        if f.is_file() and not f.name.endswith(".source.md") and f.suffix.lower() in (".txt", ".md", ".markdown", ".text"):')
    return text


def cli(text):
    before = '    shutil.copyfile(corpus, out)\n'
    after = before+'''    # Preserve agent-readable rendering inputs before deleting temporary outputs.
    for sidecar in (".source.md", ".render.json"):
        shutil.copyfile(corpus.with_suffix(sidecar), out.with_suffix(sidecar))
'''
    text = insert(text, before, after)
    anchor = '        ext = f.suffix.lower()\n'
    begin = text.index('def _stage_text_folder(')
    end = text.index('\ndef _cloud_folder(', begin)
    part = text[begin:end]
    part = insert(part, anchor, '        if f.name.endswith(".source.md"):\n            continue\n'+anchor)
    return text[:begin]+part+text[end:]


def wrapper(text):
    anchor = 'cp "$src" "$OUT"\n'
    replacement = '''command cp "$src" "$OUT"
# Keep the exact rendering inputs when the temporary generator output is removed.
for sidecar in source.md render.json; do
  command cp "${src%.png}.$sidecar" "${OUT%.png}.$sidecar"
done
'''
    return insert(text, anchor, replacement)


def video(text):
    text = insert(text, 'def make_keyideas(downloads: Path, stem: str, *, dry: bool, top_n: int = 12) -> None:',
                  'def make_keyideas(downloads: Path, stem: str, *, dry: bool, top_n: int = 12, text_override=None, time_labels=True) -> None:')
    # Change only this function, preserving the surrounding video pipeline.
    begin = text.index('def make_keyideas(')
    end = text.find('\ndef ', begin+5)
    end = len(text) if end < 0 else end
    part = text[begin:end]
    part = part.replace('text = _transcript_text(downloads, stem)', 'text = text_override if text_override is not None else _transcript_text(downloads, stem)')
    part = part.replace('lines.append(f"- **[{mmss(start)}]** {sent.rstrip(\'.\').strip()}.")',
                        'lines.append((f"- **[{mmss(start)}]** " if time_labels else "- ") + sent.rstrip(".").strip() + ".")')
    part = part.replace('f"[{mmss(st)}]  {s.rstrip(\'.\').strip()}."',
                        '(f"[{mmss(st)}]  " if time_labels else "") + s.rstrip(".").strip() + "."')
    return text[:begin]+part+text[end:]


def apply(work, helper):
    patches = [('convey/convey/actions/wordcloud-generator.py', word),
               ('convey/convey/actions/sentencecloud-generator.py', sentence),
               ('convey/convey/actions/wordcloud', wrapper),
               ('convey/convey/actions/sentencecloud', wrapper),
               ('convey/convey/actions/video', video),
               ('convey/convey/cli.py', cli),
               ('merlib-dump/scripts/wordcloud-generator.py', word)]
    prepared = []
    for name, patch in patches:
        path = work/name
        if not path.exists():
            if name.startswith('merlib-dump/'):
                continue
            raise FileNotFoundError(path)
        before = path.read_text()
        after = patch(before)
        if name.endswith('.py') or name.endswith('/video'):
            compile(after, str(path), 'exec')
        prepared.append((path, before, after))
    for directory in (work/'convey/convey/actions', work/'merlib-dump/scripts'):
        if directory.exists():
            shutil.copy2(helper, directory/'cloud_source.py')
    changed = []
    for path, before, after in prepared:
        if before != after:
            path.write_text(after)
            changed.append(str(path))
    return changed


if __name__ == '__main__':
    print('\n'.join(apply(Path.home()/'work', Path(__file__).resolve().parents[1]/'shared/cloud_source.py')))
