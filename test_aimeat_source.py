"""Substack text uses the existing AIMEAT pipeline, with one confirmed email."""
import json
from pathlib import Path
from tempfile import TemporaryDirectory
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch
from shared import aimeat_mail as m


class SourceMailTests(unittest.TestCase):
    def test_text_snapshots_deduplicate_and_preserve_all_unicode_ranges(self):
        with TemporaryDirectory() as temp, patch.object(m, 'mini'):
            queue = Path(temp)/'jobs'
            text = 'Ω'*400001+'TAIL'
            kw = dict(source_url='https://vinyasi.substack.com/p/example', title='Example', recipient='esa@example.org', queue=queue)
            first = m.enqueue_text(text, **kw)
            state = json.loads((first/'state.json').read_text())
            state['next_part'] = 1
            m.save(first/'state.json', state)
            self.assertEqual(m.enqueue_text(text, **kw), first)
            self.assertEqual(json.loads((first/'state.json').read_text())['next_part'], 1)
            files = [first/'workspace'/a['text'] for a in state['assets']]
            self.assertEqual(''.join(p.read_text() for p in files), text)
            self.assertTrue(all(p.stat().st_size < 1024*1024 for p in files))
            self.assertEqual(state['assets'][-1]['range'][1], len(text))
            self.assertNotEqual(m.enqueue_text(text+'new', **kw), first)

    def test_full_read_synthesis_panel_and_new_email_not_reply(self):
        with TemporaryDirectory() as temp, patch.object(m, 'mini'):
            root = Path(temp); queue = root/'jobs'; returns = root/'returns'
            text = 'Open reservoir and paired capacitor fields. '*300+'UNIQUE-SUBSTACK-TAIL'
            job = m.enqueue_text(text, source_url='https://vinyasi.substack.com/p/example', title='Example', recipient='esa@example.org', queue=queue)
            agent = SimpleNamespace(
                CHAPTER_SYSTEM='Read all', ACROSS_SYSTEM='Synthesize', md_to_html=lambda s: s,
                _fm_call=Mock(return_value=('Source-specific reading.', 'fixture')),
                _has_leak=lambda s: False, _is_reasoning_dump=lambda s: False,
                wiki_context=lambda s: ('archive', []), route_space=lambda *a: ('free-energy', 'source'),
                research_email_material=Mock(return_value=('Full final synthesis.', 'fixture')),
                _is_requeue=lambda s: False, send_inbox_reply=Mock())
            for _ in range(20):
                m.process_pending(agent, 'secret', queue, returns=returns)
                state=json.loads((job/'state.json').read_text())
                if state['status']=='roundtable': break
            self.assertEqual(state['status'], 'roundtable')
            self.assertEqual(state['next_part'], len(m.chunks(text)))
            self.assertIn('UNIQUE-SUBSTACK-TAIL', agent._fm_call.call_args_list[-1].args[0][-1]['content'])
            rt=root/'rt'; source=job/'workspace'/state['assets'][0]['text']
            transcript='Completed panel discussion of the actual source.'
            m.atomic(rt/'panel/transcript.md', transcript)
            m.save(rt/'panel/state.json', dict(status='complete', source=source.name,
                    sha256=m.sha(source.read_bytes()), result_sha256=m.sha(transcript.encode())))
            with patch.object(m,'ROUNDTABLE_RETURNS',rt), patch.object(m.cloud_assets,'generate', return_value=([],{})), patch.object(m,'send_source_email', return_value={'message_id':'sent-once'}) as send:
                for _ in range(3): m.process_pending(agent,'secret',queue,returns=returns)
                self.assertEqual(send.call_count,1)
                message,payload=send.call_args.args[2:]
                self.assertEqual(message['recipient'],'esa@example.org')
                self.assertIn('Full final synthesis.',payload['text'])
                self.assertIn(transcript,payload['text'])
                self.assertIn('source characters 0',payload['text'])
                self.assertIn('html',payload)
            agent.send_inbox_reply.assert_not_called()
            self.assertEqual(json.loads((job/'state.json').read_text())['status'],'complete')

    def test_ambiguous_source_send_is_attempted_once(self):
        with TemporaryDirectory() as temp, patch.object(m,'mini'):
            root=Path(temp);queue=root/'jobs'
            job=m.enqueue_text('Source',source_url='https://x.substack.com/p/example',title='Example',recipient='esa@example.org',queue=queue)
            state=json.loads((job/'state.json').read_text());state.update(status='ready-to-send',analysis='full.analysis.md',files=['full.analysis.md'])
            m.atomic(job/'workspace/full.analysis.md','Saved analysis');m.save(job/'state.json',state)
            with patch.object(m,'send_source_email',side_effect=TimeoutError('acceptance unknown')) as send:
                for _ in range(2):m.process_pending(SimpleNamespace(md_to_html=lambda s:s),'secret',queue,returns=root/'returns')
            self.assertEqual(send.call_count,1)
            self.assertEqual(json.loads((job/'state.json').read_text())['status'],'sending-unconfirmed')

    def test_sender_does_not_retry_post_on_timeout(self):
        agent=SimpleNamespace(AM_BASE='https://api.agentmail.to/v0',INBOX='cloudcity-llm@agentmail.to')
        with patch.object(m.urllib.request,'urlopen',side_effect=TimeoutError('unknown')) as send:
            with self.assertRaises(TimeoutError):m.send_source_email(agent,'secret',{'recipient':'esa@example.org','subject':'Title'},{'text':'Analysis'})
        self.assertEqual(send.call_count,1)
        request=send.call_args.args[0]
        self.assertEqual(json.loads(request.data)['to'],['esa@example.org'])

class StepDeadlineTests(unittest.TestCase):
    def test_gateway_generic_retry_cannot_swallow_step_deadline(self):
        with patch.object(m.signal, 'signal') as signal_handler, patch.object(m.signal, 'alarm'):
            with self.assertRaises(m.SourceStepTimeout):
                with m.bounded_source_step({'kind': m.TEXT_PIPELINE, 'status': 'synthesis'}):
                    handler = signal_handler.call_args_list[0].args[1]
                    try:
                        handler(None, None)
                    except Exception:
                        self.fail('Gateway retry swallowed the step deadline')


if __name__=='__main__':unittest.main()
