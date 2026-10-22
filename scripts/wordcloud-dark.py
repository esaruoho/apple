#!/usr/bin/env python3
"""Apply the shared black wordcloud canvas to installed generator copies.

REPORT-CARD >> features/aimeat-email-pdf.feature
Idempotent, surgical replacements; never regenerate an archive or run a model.
"""
from pathlib import Path


def dark(text):
    marker = '# REPORT-CARD >> ../apple/features/aimeat-email-pdf.feature'
    if marker not in text:
        lines = text.splitlines(keepends=True)
        lines.insert(1 if text.startswith('#!') else 0, marker+'\n')
        text = ''.join(lines)
    text = text.replace('background_color="white"', 'background_color="black"')
    text = text.replace('facecolor="white"', 'facecolor="black"')
    text = text.replace('ax.set_title(title, fontsize=14, pad=10)',
                        'ax.set_title(title, fontsize=14, pad=10, color="white")')
    text = text.replace('fig, ax = plt.subplots(figsize=(16, 9), dpi=100)',
                        'fig, ax = plt.subplots(figsize=(16, 9), dpi=100, facecolor="black")')
    return text


def apply(work):
    changed = []
    for path in (work/'convey/convey/actions/wordcloud-generator.py',
                 work/'merlib-dump/scripts/wordcloud-generator.py'):
        if not path.exists():
            continue
        before = path.read_text()
        after = dark(before)
        if 'background_color="black"' not in after or 'facecolor="black"' not in after:
            raise RuntimeError(f'Unrecognized wordcloud generator: {path}')
        if before != after:
            path.write_text(after)
            changed.append(str(path))
    return changed


if __name__ == '__main__':
    print('\n'.join(apply(Path.home()/'work')))
