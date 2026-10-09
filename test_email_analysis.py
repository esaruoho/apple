"""REPORT-CARD >> features/transcript-vault-email-analysis.feature"""
import importlib.machinery
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / 'shared'))
from email_analysis import prepare, delivered


def load_agent():
    loader = importlib.machinery.SourceFileLoader('mail_analysis_test_agent', str(ROOT / 'bin/freellmask-mail'))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


class EmailAnalysisTests(unittest.TestCase):
    def test_compose_failure_is_a_nonzero_process_exit(self):
        env = dict(os.environ, AGENTMAIL_API_KEY='test-key')
        run = subprocess.run([sys.executable, str(ROOT / 'bin/freellmask-mail'), 'compose',
                              '--to', 'reader@example.com', '--subject', 'Empty input',
                              '--text', '', '--no-legs'], env=env, capture_output=True,
                             text=True, timeout=10)
        self.assertEqual(run.returncode, 1)
        self.assertIn('nothing to answer', run.stdout)

    def test_exact_body_separate_receipt_and_retry_identity(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / 'talk.transcript.txt'
            source.write_text('The whole original transcript')
            text = '## Answer\n\n**Formatted** response.\n'
            args = dict(recipient='reader@example.com', subject='Talk', model='test-brain',
                        analyzed_text=source.read_text())
            receipt, meta = prepare(source, text, **args)
            self.assertEqual(receipt.with_suffix('.md').read_text(), text)
            self.assertEqual(meta['delivery'], 'pending')
            delivered(receipt, meta, response={'message_id': 'message-123'})
            again, state = prepare(source, text, **args)
            self.assertEqual(again, receipt)
            self.assertEqual(state['delivery'], 'sent')
            self.assertEqual(state['message_id'], 'message-123')
            other, _ = prepare(source, text + 'Another answer.', **args)
            self.assertNotEqual(other, receipt)
            self.assertEqual(receipt.with_suffix('.md').read_text(), text)

    def test_compose_persists_exact_payload_before_send_and_records_failure(self):
        agent = load_agent()
        for failure in (False, True):
            with self.subTest(failure=failure), tempfile.TemporaryDirectory() as tmp:
                source = Path(tmp) / 'talk.transcript.txt'
                source.write_text('Original words')
                sent = []

                def send(url, key, method, payload):
                    receipts = list(source.parent.glob('*.analysis.json'))
                    self.assertEqual(len(receipts), 1)
                    self.assertEqual(json.loads(receipts[0].read_text())['delivery'], 'pending')
                    self.assertEqual(receipts[0].with_suffix('.md').read_text(), payload['text'])
                    sent.append(payload['text'])
                    if failure:
                        raise OSError('provider unavailable')
                    return {'message_id': 'confirmed-id'}

                with patch.object(agent, 'am_key', return_value='test-key'), \
                     patch.object(agent, 'wiki_context', return_value=('', [])), \
                     patch.object(agent, 'fm_research', return_value=('## Answer\nA grounded answer.', 'test-model')), \
                     patch.object(agent, 'http', side_effect=send):
                    ok, _ = agent.compose_and_send('reader@example.com', 'Talk', source.read_text(),
                                                  archive_source=str(source), space_hint='plain', verbose=False)
                self.assertEqual(ok, not failure)
                receipt = next(source.parent.glob('*.analysis.json'))
                state = json.loads(receipt.read_text())
                self.assertEqual(state['delivery'], 'failed' if failure else 'sent')
                self.assertEqual(receipt.with_suffix('.md').read_text(), sent[0])
                self.assertEqual(state['model'], 'test-model')

    def test_save_failure_prevents_send(self):
        agent = load_agent()
        with patch.object(agent, 'am_key', return_value='test-key'), \
             patch.object(agent, 'wiki_context', return_value=('', [])), \
             patch.object(agent, 'fm_research', return_value=('## Answer\nA grounded answer.', 'test-model')), \
             patch.object(agent, 'http') as send:
            ok, info = agent.compose_and_send('reader@example.com', 'Talk', 'words',
                                             archive_source='/missing/source.txt', space_hint='plain', verbose=False)
        self.assertFalse(ok)
        self.assertIn('not sending', info)
        send.assert_not_called()


if __name__ == '__main__':
    unittest.main()
