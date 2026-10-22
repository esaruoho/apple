import hashlib
import json
from pathlib import Path
import tempfile
import types
import unittest
from unittest.mock import Mock, patch
from shared import aimeat_mail as mail


class EmailPDFTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.queue, self.folder, self.returns = [self.root/n for n in ('jobs', 'folder', 'returns')]
        self.folder.mkdir()
        self.message = {'message_id': '<one@host>', 'from': 'Esa <esa@example.org>',
                        'subject': 'Free energy PDF', 'text': 'Discuss this open system',
                        'attachments': [{'filename': '../../MRA.pdf', 'attachment_id': 'a'}]}
        self.guard = patch.object(mail, 'mini')
        self.guard.start()
        self.addCleanup(self.guard.stop)

    def test_owner_check_requires_exact_address(self):
        self.assertTrue(mail.eligible(self.message, {'esa@example.org'}))
        self.message['from'] = 'esa@example.org <stranger@host>'
        self.assertFalse(mail.eligible(self.message, {'esa@example.org'}))

    def test_urls_and_attachments_become_pdf_sources(self):
        self.message['text'] = 'https://example.org/paper.pdf?download=1 https://example.org/paper.pdf?download=1'
        self.assertEqual(len(mail.pdf_sources(self.message)), 2)

    def test_missing_attachment_fields_do_not_block_ordinary_owner_mail(self):
        self.assertEqual(mail.pdf_sources({'attachments': None, 'text': 'ordinary email'}), [])
        self.assertEqual(mail.pdf_sources({'attachments': [{'filename': None, 'content_type': None}]}), [])

    def test_enqueue_is_durable_and_deduplicated(self):
        first = mail.enqueue(self.message, self.queue)
        state = json.loads((first/'state.json').read_text())
        state['status'] = 'reading'
        mail.save(first/'state.json', state)
        self.assertEqual(first, mail.enqueue(self.message, self.queue))
        self.assertEqual(json.loads((first/'state.json').read_text())['status'], 'reading')
        self.assertEqual(json.loads((first/'email.json').read_text()), self.message)

    def test_full_text_split_has_no_part_cap_or_lost_tail(self):
        text = 'x' * 300001
        parts = mail.chunks(text)
        self.assertGreater(len(parts), 14)
        self.assertEqual(''.join(parts), text)
        self.assertLessEqual(max(map(len, parts)), 8000)

    def test_extractor_checks_all_page_numbers(self):
        pdf = self.folder/'x.pdf'
        mail.save(Path(str(pdf)+'.pages.json'), {'page_count': 25, 'pages': [
            {'number': i, 'method': 'embedded-text', 'text': f'page {i}'} for i in range(1, 26)]})
        with patch.object(mail.subprocess, 'run') as run:
            text, result = mail.extract_pdf(pdf)
        self.assertIn('page 25', text)
        self.assertNotIn('--pages', run.call_args.args[0])
        result['pages'].pop()
        mail.save(Path(str(pdf)+'.pages.json'), result)
        with patch.object(mail.subprocess, 'run'), self.assertRaisesRegex(RuntimeError, 'coverage'):
            mail.extract_pdf(pdf)

    def test_collector_retries_partial_sync_and_preserves_local_edits(self):
        directory = self.returns/'one'
        mail.atomic(directory/'x.pdf', b'original')
        mail.save(directory/'manifest.json', {'schema': 'aimeat-mail/1', 'files': [
            {'name': 'x.pdf', 'sha256': mail.sha(b'original')},
            {'name': '../escape', 'sha256': 'bad'}]})
        self.assertEqual(mail.collect(self.folder, self.returns), 1)
        self.assertEqual((self.folder/'x.pdf').read_bytes(), b'original')
        (self.folder/'x.pdf').write_bytes(b'local edit')
        mail.atomic(directory/'x.pdf', b'new')
        state = json.loads((directory/'manifest.json').read_text())
        state['files'][0]['sha256'] = mail.sha(b'new')
        mail.save(directory/'manifest.json', state)
        self.assertEqual(mail.collect(self.folder, self.returns), 0)
        self.assertEqual((self.folder/'x.pdf').read_bytes(), b'local edit')

    def test_ambiguous_send_is_never_automatically_repeated(self):
        job = mail.enqueue(self.message, self.queue)
        state = json.loads((job/'state.json').read_text())
        state.update(status='ready-to-send', analysis='a.analysis.md', files=['a.analysis.md'])
        mail.atomic(self.folder/'a.analysis.md', 'Full analysis')
        mail.save(job/'state.json', state)
        agent = types.SimpleNamespace(md_to_html=lambda s: s, send_inbox_reply=Mock(side_effect=TimeoutError('ambiguous')))
        for _ in range(2):
            mail.process_pending(agent, 'key', self.queue, self.folder, self.returns)
        self.assertEqual(agent.send_inbox_reply.call_count, 1)
        self.assertEqual(json.loads((job/'state.json').read_text())['status'], 'sending-unconfirmed')

    def test_original_is_published_even_if_extraction_fails(self):
        job = mail.enqueue(self.message, self.queue)
        agent = types.SimpleNamespace(MAX_ATT=200, _att_bytes=Mock(return_value=b'%PDF-original'))
        with patch.object(mail, 'extract_pdf', side_effect=RuntimeError('unreadable')):
            mail.process_pending(agent, 'key', self.queue, self.folder, self.returns)
        manifest = json.loads(next(self.returns.glob('*/manifest.json')).read_text())
        self.assertEqual(len(manifest['files']), 1)
        self.assertEqual(mail.collect(self.root/'laptop', self.returns), 1)

    def test_large_pdf_text_is_split_without_losing_characters(self):
        job = mail.enqueue(self.message, self.queue)
        text = 'Ω' * 600001
        coverage = {'page_count': 25, 'pages': [{'number': n, 'text': f'page {n}', 'method': 'embedded-text'} for n in range(1, 26)]}
        def extract(path):
            mail.save(Path(str(path)+'.pages.json'), coverage)
            return text, coverage
        agent = types.SimpleNamespace(MAX_ATT=200, _att_bytes=Mock(return_value=b'%PDF-original'))
        with patch.object(mail, 'extract_pdf', side_effect=extract):
            mail.process_pending(agent, 'key', self.queue, self.folder, self.returns)
        state = json.loads((job/'state.json').read_text())
        inputs = [self.folder/a['text'] for a in state['assets']]
        self.assertGreater(len(inputs), 1)
        self.assertEqual(''.join(p.read_text() for p in inputs), text)
        self.assertTrue(all(p.stat().st_size < 1024*1024 for p in inputs))
        self.assertEqual(state['assets'][-1]['range'][1], len(text))

    def test_processing_refuses_laptop(self):
        self.guard.stop()
        with patch.object(mail.socket, 'gethostname', return_value='RayMac.local'):
            with self.assertRaisesRegex(RuntimeError, 'Mini-only'):
                mail.process_pending(None, 'key', self.queue, self.folder, self.returns)

    def test_complete_job_reads_every_part_files_results_and_replies_once(self):
        job = mail.enqueue(self.message, self.queue)
        text = 'Open reservoir measurement. '*5000+'UNIQUE FINAL PAGE MARKER'
        coverage = {'page_count': 25, 'pages': [{'number': n, 'text': f'page {n}', 'method': 'embedded-text'} for n in range(1, 26)]}
        def extract(path):
            mail.save(Path(str(path)+'.pages.json'), coverage)
            return text, coverage
        agent = types.SimpleNamespace(
            MAX_ATT=1000, _att_bytes=Mock(return_value=b'%PDF-fixture'),
            _fm_call=Mock(return_value=('Claims and measurements: the open reservoir is identified.', 'test-model')),
            CHAPTER_SYSTEM='Read source', ACROSS_SYSTEM='Across parts',
            _has_leak=lambda s: False, _is_reasoning_dump=lambda s: False,
            wiki_context=lambda s: ('archive', []), route_space=lambda *args: ('free-energy', 'test'),
            research_email_material=Mock(return_value=('Final analysis of all section readings.', 'test-model')),
            _is_requeue=lambda s: False, md_to_html=lambda s: s, send_inbox_reply=Mock(return_value={'message_id': 'sent'}))
        with patch.object(mail, 'extract_pdf', side_effect=extract):
            for _ in range(30):
                mail.process_pending(agent, 'key', self.queue, self.folder, self.returns)
                state = json.loads((job/'state.json').read_text())
                if state['status'] == 'roundtable':
                    break
        self.assertEqual(state['status'], 'roundtable')
        self.assertEqual(state['next_part'], len(mail.chunks(text)))
        self.assertGreater(state['next_part'], 14)
        self.assertIn('UNIQUE FINAL PAGE MARKER', agent._fm_call.call_args_list[-1].args[0][-1]['content'])
        source = self.folder/state['assets'][0]['text']
        transcript = 'All nine participants discussed the source.'
        mail.atomic(Path(str(source)+'.roundtable.md'), transcript)
        mail.save(Path(str(source)+'.roundtable.json'), {'status': 'complete', 'sha256': mail.sha(source.read_bytes()), 'result_sha256': mail.sha(transcript.encode())})
        mail.atomic(source.with_suffix('.wordcloud.png'), b'png-fixture')
        for _ in range(3):
            mail.process_pending(agent, 'key', self.queue, self.folder, self.returns)
        self.assertEqual(agent.send_inbox_reply.call_count, 1)
        self.assertEqual(json.loads((job/'state.json').read_text())['status'], 'complete')
        laptop = self.root/'laptop'
        mail.collect(laptop, self.returns)
        self.assertIn('UNIQUE FINAL PAGE MARKER', (laptop/source.name).read_text())
        analysis = (laptop/state['analysis']).read_text()
        self.assertIn(transcript, analysis)
        self.assertIn('25 pages', analysis)


if __name__ == '__main__':
    unittest.main()
