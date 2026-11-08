"""Pure-logic tests for bin/notes-process (no Notes account needed)."""
import importlib.util, importlib.machinery
from pathlib import Path
p = Path(__file__).parent / 'bin' / 'notes-process'
spec = importlib.util.spec_from_loader('np', importlib.machinery.SourceFileLoader('np', str(p)))
np = importlib.util.module_from_spec(spec); spec.loader.exec_module(np)
O = np.OBJ

def test_real_tag_object_line():
    # how Notes reports "hey i want you to tell me about electricity #process"
    plain = f'hey i want you to tell me about electricity {O}\n'
    assert np.prompts_for(plain, '#process', 'tag') == \
        [(f'hey i want you to tell me about electricity {O}', 'hey i want you to tell me about electricity')]

def test_plain_text_tag_line():
    assert np.prompts_for('T\nhello world #process\nother', '#process', 'text') == [('hello world #process', 'hello world')]

def test_bare_tag_sends_note_above_minus_title():
    assert np.prompts_for(f'Title\nline a\nline b\n{O}', '#process', 'tag') == [(O, 'line a\nline b')]

def test_no_partial_tag_match():
    assert np.prompts_for('x #processed\ny #process-later', '#process', 'text') == []

def test_reply_cannot_retrigger():
    assert np.tag_re('#process').search(np.sanitize('say #process again', '#process')) is None

def test_reply_markdown_ends_with_done_and_has_no_trigger():
    md = np.reply_markdown('Helsinki.', 'fmremote', '#done')
    assert md.rstrip().endswith('#done') and '**🤖 fmremote' in md and '#process' not in md

def test_no_set_body_anywhere():
    src = p.read_text()
    assert 'set body' not in src.lower().replace('`set body`', '')

if __name__ == '__main__':
    for n, f in list(globals().items()):
        if n.startswith('test_'): f(); print('ok', n)
