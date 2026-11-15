"""Pure-logic tests for bin/notes-process (no Notes account needed)."""
import importlib.util, importlib.machinery
from pathlib import Path
p = Path(__file__).parent / 'bin' / 'notes-process'
spec = importlib.util.spec_from_loader('np', importlib.machinery.SourceFileLoader('np', str(p)))
np = importlib.util.module_from_spec(spec); spec.loader.exec_module(np)
O = np.OBJ

def test_reply_cannot_retrigger():
    assert np.tag_re('#process').search(np.sanitize('say #process again', '#process')) is None

def test_reply_markdown_ends_with_done_and_has_no_trigger():
    md = np.reply_markdown('Helsinki.', 'fmremote', '#done')
    assert md.rstrip().endswith('#done') and '**🤖 fmremote' in md and '#process' not in md

def test_no_set_body_anywhere():
    src = p.read_text()
    assert 'set body' not in src.lower().replace('`set body`', '')

def test_reply_title_flattens_thread():
    assert np.reply_title('Re: katsotaampa toimiiko tämä #process') == 'Re: katsotaampa toimiiko tämä'
    assert np.reply_title('Re: Re: x #process #done') == 'Re: x'

def test_ledger_unicode_separators():
    import tempfile, json
    with tempfile.TemporaryDirectory() as d:
        old = np.STATE
        np.STATE = Path(d)
        try:
            np.ledger_add({'key': 'one', 'title': 'a\u2028b\u2029c\x85d'})
            np.ledger_add({'key': 'two'})
            assert np.ledger() == {'one', 'two'}
        finally:
            np.STATE = old


def test_ledger_damage_preserved_and_append_recovers():
    import tempfile, json
    with tempfile.TemporaryDirectory() as d:
        old = np.STATE
        np.STATE = Path(d)
        try:
            p = np.STATE / 'ledger.jsonl'
            original = b'{"key":"good"}\nnot json\n[]\n{"key":null}\n{"key":"torn","title":"unfinished'
            p.write_bytes(original)
            assert np.ledger() == {'good', 'torn'}
            assert p.read_bytes() == original
            assert any(f.read_bytes() == original for f in np.STATE.glob('ledger.corrupt-*.bin'))
            np.ledger_add({'key': 'after'})
            assert np.ledger() == {'good', 'torn', 'after'}
            assert json.loads(p.read_bytes().split(b'\n')[-2])['key'] == 'after'
        finally:
            np.STATE = old


def test_watch_retries_failed_pass():
    import sys
    from unittest.mock import patch
    calls = []
    class StopTest(BaseException):
        pass
    def attempt(a):
        calls.append(a.watch)
        if len(calls) == 1:
            raise RuntimeError('temporary failure')
        raise StopTest()
    with patch.object(sys, 'argv', ['notes-process', '--watch', '10']), \
         patch.object(np, 'one_pass', side_effect=attempt), \
         patch.object(np.time, 'sleep') as sleep:
        try:
            np.main()
        except StopTest:
            pass
        assert calls == [10, 10]
        sleep.assert_called_once_with(10)


def test_full_source_and_vision_prompt_preserve_first_paragraph():
    src = 'The entire important first paragraph.\n\n#JohnKeely\n' + O
    prompt = np.notes_input.make_prompt(src, '#process', [dict(uti='public.png', state='ok', text='12 volts', labels='coil 0.7')])
    assert 'The entire important first paragraph.' in prompt
    assert '#JohnKeely' in prompt and '12 volts' in prompt and 'coil 0.7' in prompt


def test_sqlite_source_snapshot_keeps_first_line_and_reads_image():
    import sqlite3, gzip, tempfile
    def field(n, b):
        def vi(x):
            out = b''
            while x > 127:
                out += bytes([(x & 127) | 128]); x >>= 7
            return out + bytes([x])
        return vi(n * 8 + 2) + vi(len(b)) + b
    text = 'Full first paragraph\n' + O + '\n' + O
    blob = gzip.compress(field(2, field(3, field(2, text.encode()))))
    with sqlite3.connect(':memory:') as c, tempfile.TemporaryDirectory() as d:
        c.execute('create table ZICCLOUDSYNCINGOBJECT (Z_PK integer,ZTITLE1 text,ZMODIFICATIONDATE1 real,ZNOTEDATA integer,ZISPASSWORDPROTECTED integer,ZMARKEDFORDELETION integer,ZIDENTIFIER text,ZTYPEUTI text,ZMEDIA integer,ZNOTE integer,ZFILENAME text)')
        c.execute('create table ZICNOTEDATA (Z_PK integer,ZDATA blob)')
        c.execute('insert into ZICCLOUDSYNCINGOBJECT (Z_PK,ZTITLE1,ZMODIFICATIONDATE1,ZNOTEDATA) values(1,"Title",0,2)')
        c.execute('insert into ZICNOTEDATA values(2,?)', (blob,))
        c.execute('insert into ZICCLOUDSYNCINGOBJECT (Z_PK,ZNOTE,ZTYPEUTI,ZMEDIA,ZIDENTIFIER) values(3,1,"public.png",4,"image")')
        c.execute('insert into ZICCLOUDSYNCINGOBJECT (Z_PK,ZIDENTIFIER,ZFILENAME) values(4,"media","Image.png")')
        image = Path(d) / 'Accounts/account/Media/media/version/Image.png'
        image.parent.mkdir(parents=True); image.write_bytes(b'example')
        result = np.notes_input.snapshot(c, 'x-coredata://store/ICNote/p1', Path(d))
        assert result['text'].startswith('Full first paragraph')
        assert result['attachments'][0]['path'] == str(image)


def test_vision_logs_each_result_without_local_ocr():
    import tempfile, subprocess
    from unittest.mock import patch
    with tempfile.TemporaryDirectory() as d:
        root = Path(d); image = root / 'source.png'; image.write_bytes(b'fixture image')
        run = root / 'run'; run.mkdir()
        source = dict(attachments=[dict(id='i', uti='public.png', image=True, path=str(image))])
        with patch.dict(np.os.environ, {'NOTES_VISION_ON_MINI':'1'}), \
             patch.object(np.notes_input.subprocess, 'run', return_value=subprocess.CompletedProcess([],0,'recognized text','')) as call:
            results = np.notes_input.vision_images(source, run)
        assert call.call_count == 2
        assert results[0]['text'] == 'recognized text' and results[0]['sha256']
        assert (run / 'vision.json').exists() and (run / 'image-0.png').read_bytes() == b'fixture image'


def test_handle_archives_exact_input_and_visible_id():
    import tempfile, types, json, sys
    from unittest.mock import patch
    source = dict(note_id='x-coredata://store/ICNote/p1', title='T', text='Entire first paragraph.\nSecond paragraph.\n#process', age=100, attachments=[])
    occ = dict(key='tag:one',nid=source['note_id'],title='T',folder='Notes',kind='tag')
    a = types.SimpleNamespace(settle=5,tag='#process',dry_run=False,llm=sys.executable+' -c "print(12345)"',llm_timeout=10,samples=1,label='Test',done_tag='#done',reply_account='iCloud',reply_folder='Notes')
    with tempfile.TemporaryDirectory() as d, patch.object(np,'STATE',Path(d)), \
         patch.object(np,'db'), patch.object(np.notes_input,'snapshot',return_value=source), \
         patch.object(np,'linked_note',return_value='new-note') as deliver:
        np.handle(occ,a,set(),False)
        run = next((Path(d)/'runs').iterdir())
        request=json.loads((run/'model-001/request.json').read_text())
        assert request['stdin'] == (run/'prompt.txt').read_text()
        assert source['text'].split('\n')[0] in request['stdin']
        md=deliver.call_args[0][1]
        assert run.name in md and 'Entire first paragraph.' in md and 'Second paragraph.' in md
        assert json.loads((run/'status.json').read_text())['state']=='delivered'
        assert all(json.loads(row)['run_id']==run.name for row in (Path(d)/'ledger.jsonl').read_text().split('\n') if row)


def test_model_failure_keeps_input_and_error():
    import tempfile, sys, json
    with tempfile.TemporaryDirectory() as d:
        run=Path(d)
        try:
            np.call_llm(sys.executable+' -c "raise SystemExit(2)"','full input',10,audit_dir=run)
        except RuntimeError:
            pass
        else:
            raise AssertionError('failure must be reported')
        assert (run/'model-001/prompt.txt').read_text()=='full input'
        assert json.loads((run/'model-001/response.json').read_text())['returncode']==2


def test_brain_records_full_backend_messages():
    import tempfile, runpy, types, sys, io, json
    from unittest.mock import patch
    module=types.ModuleType('convey.brain_routes')
    module.FLUBUILD_MODEL='test-model'
    module.call_flubuild=lambda messages, **kw: ('answer','test-route')
    prompt='First paragraph.\n' + 'body ' * 1500
    with tempfile.TemporaryDirectory() as d, \
         patch.dict(sys.modules, {'convey.brain_routes':module}), \
         patch.dict(np.os.environ, {'NOTES_PROCESS_AUDIT_DIR':d}), \
         patch.object(sys,'argv',['notes-brain']), patch.object(sys,'stdin',io.StringIO(prompt)):
        try:
            runpy.run_path(str(p.parent/'notes-brain'),run_name='__main__')
        except SystemExit as e:
            assert e.code==0
        rec=json.loads((Path(d)/'backend-flubuild-request.json').read_text())
        assert rec['messages']==[{'role':'user','content':prompt.strip()}]
        assert json.loads((Path(d)/'backend-flubuild-response.json').read_text())['text']=='answer'


def test_delivery_failure_has_id_and_is_not_retried():
    import tempfile, types, sys, json
    from unittest.mock import patch
    source=dict(note_id='x-coredata://store/ICNote/p1',title='T',text='Full text',age=100,attachments=[])
    occ=dict(key='tag:one',nid=source['note_id'],title='T',folder='Notes',kind='tag')
    a=types.SimpleNamespace(settle=5,tag='#process',dry_run=False,llm=sys.executable+' -c "print(12345)"',llm_timeout=10,samples=1,label='Test',done_tag='#done',reply_account='iCloud',reply_folder='Notes')
    with tempfile.TemporaryDirectory() as d, patch.object(np,'STATE',Path(d)), \
         patch.object(np,'db'),patch.object(np.notes_input,'snapshot',return_value=source), \
         patch.object(np,'linked_note',side_effect=RuntimeError('Connection is invalid')) as deliver:
        seen=set()
        try:np.handle(occ,a,seen,False)
        except RuntimeError:pass
        run=next((Path(d)/'runs').iterdir())
        assert json.loads((run/'status.json').read_text())['state']=='delivery_uncertain'
        assert run.name in (run/'reply.md').read_text()
        np.handle(occ,a,seen,False)
        assert deliver.call_count==1


def test_once_reports_failed_pass_and_defaults_to_no_forced_refresh():
    import tempfile,sys
    from unittest.mock import patch
    with tempfile.TemporaryDirectory() as d,patch.object(np,'STATE',Path(d)), \
         patch.object(sys,'argv',['notes-process','--once']),patch.object(np,'ledger',return_value=set()), \
         patch.object(np,'find_occurrences',return_value=[{'key':'x'}]), \
         patch.object(np,'heal_notes') as heal,patch.object(np,'shortcut_installed',return_value=False), \
         patch.object(np,'handle',side_effect=RuntimeError('write failed')):
        try:np.main()
        except SystemExit as e:assert e.code==1
        else:raise AssertionError('one-shot failure must return nonzero')
        heal.assert_called_once_with()


if __name__ == '__main__':
    for n, f in list(globals().items()):
        if n.startswith('test_'): f(); print('ok', n)
