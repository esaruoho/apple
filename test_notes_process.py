"""Pure-logic tests for bin/notes-process (no Notes account needed)."""
import importlib.util, importlib.machinery
from pathlib import Path
p = Path(__file__).parent / 'bin' / 'notes-process'
spec = importlib.util.spec_from_loader('np', importlib.machinery.SourceFileLoader('np', str(p)))
np = importlib.util.module_from_spec(spec); spec.loader.exec_module(np)

def test_inline_line():
    assert np.find_triggers('T\nhello world #process\nother', '#process') == [('hello world #process', 'hello world')]

def test_bare_tag_sends_note_above_minus_title():
    assert np.find_triggers('Title\nline a\nline b\n#process', '#process') == [('#process', 'line a\nline b')]

def test_no_partial_tag_match():
    assert np.find_triggers('x #processed\ny #process-later', '#process') == []

def test_reply_cannot_retrigger():
    s = np.sanitize('say #process again', '#process')
    assert np.tag_re('#process').search(s) is None

def test_reply_html_escaped():
    assert '&lt;b&gt;' in np.reply_html('<b>x</b>', 'fm')

if __name__ == '__main__':
    for n, f in list(globals().items()):
        if n.startswith('test_'): f(); print('ok', n)
