import os
import unittest
from unittest.mock import patch
from test_mail_reply_attachment_fallback import agent

class MaterialEditorTests(unittest.TestCase):
    def complete(self):
        return '\n\n'.join('## '+h+'\nSubstantive source discussion.' for h in ['Thought about it','Answer']+agent.MATERIAL_HEADINGS+agent.TONE_HEADINGS)

    def test_free_energy_documents_enable_full_existing_editor(self):
        with patch.dict(os.environ,{'FREE_ENERGY_LENS_VOICES':'1'}), patch.object(agent,'fm_research',return_value=(self.complete(),'model')) as model:
            result=agent.research_email_material('q','thread','pdf text',space='free-energy',wiki_ctx='retrieved',tries=4,honour_tries=True)
        self.assertFalse(agent._is_requeue(result[0]))
        self.assertEqual(model.call_args.kwargs['viewpoint'],agent.VIEWPOINT)
        self.assertTrue(model.call_args.kwargs['material'])
        self.assertEqual(model.call_args.kwargs['wiki_ctx'],'retrieved')
        self.assertTrue(model.call_args.kwargs['honour_tries'])

    def test_each_missing_voice_blocks_delivery(self):
        for heading in agent.TONE_HEADINGS+agent.MATERIAL_HEADINGS:
            with self.subTest(heading=heading),patch.dict(os.environ,{'FREE_ENERGY_LENS_VOICES':'1'}),patch.object(agent,'fm_research',return_value=(self.complete().replace('## '+heading+'\n',''), 'model')):
                answer,_=agent.research_email_material('q','','pdf',space='free-energy')
                self.assertTrue(agent._is_requeue(answer))
                self.assertIn(heading,answer)

    def test_plain_documents_keep_their_own_space(self):
        with patch.object(agent,'fm_research',return_value=('Plain answer','model')) as model:
            answer,_=agent.research_email_material('q','','text',space='apple')
        self.assertEqual(answer,'Plain answer')
        self.assertEqual(model.call_args.kwargs['viewpoint'],'')
