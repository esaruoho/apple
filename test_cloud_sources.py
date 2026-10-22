import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent/'shared'))
import cloud_source
import cloud_assets


class CloudSourceTests(unittest.TestCase):
    def test_readable_markdown_preserves_exact_items_and_scores(self):
        with tempfile.TemporaryDirectory() as tmp:
            image=Path(tmp)/'document.sentencecloud.png'
            items=[('A precise sentence with Ω and 2.5 watts.', 42.75), ('A second sentence.', 1)]
            md, raw=cloud_source.write_cloud_source(image, 'sentencecloud', items, {'width':3600})
            self.assertFalse(image.exists())  # source exists before any PNG is rendered
            self.assertIn(items[0][0], md.read_text())
            spec=cloud_source.read_spec(md)
            self.assertEqual(spec, cloud_source.read_spec(raw))
            self.assertEqual([(x['text'],x['weight']) for x in spec['items']], items)

    def test_tampered_render_input_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            md, _=cloud_source.write_cloud_source(Path(tmp)/'cloud.png','wordcloud',[('resonance',4)],{})
            md.write_text(md.read_text().replace('"weight": 4', '"weight": 99'))
            with self.assertRaisesRegex(ValueError,'checksum'):
                cloud_source.read_spec(md)

    def test_rendering_refuses_laptop(self):
        with patch.object(cloud_assets.socket,'gethostname',return_value='RayMac.local'):
            with self.assertRaisesRegex(RuntimeError,'Mini-only'):
                cloud_assets.generate(Path('/does/not/matter.txt'))

    def test_patches_are_idempotent_and_compile(self):
        loader=importlib.util.spec_from_file_location('sidecars','scripts/cloud-source-sidecars.py')
        module=importlib.util.module_from_spec(loader)
        loader.loader.exec_module(module)
        root=Path.home()/'work/convey/convey'
        for file, operation in [('actions/wordcloud-generator.py',module.word),
                                ('actions/sentencecloud-generator.py',module.sentence),
                                ('actions/video',module.video), ('cli.py',module.cli)]:
            text=(root/file).read_text()
            updated=operation(text)
            self.assertEqual(updated,operation(updated))
            compile(updated,file,'exec')
        for name in ('wordcloud','sentencecloud'):
            text=(root/'actions'/name).read_text()
            self.assertEqual(module.wrapper(text),module.wrapper(module.wrapper(text)))

    def test_email_html_renders_markdown_without_visible_markers(self):
        from test_mail_reply_attachment_fallback import agent
        html=agent.md_to_html('# Analysis\n\n**Measured input** and `watts`.\n\n- First finding\n- Second finding\n\n[Source](https://example.org/paper)\n\n| Quantity | Value |\n|---|---|\n| Input | 2 W |')
        for tag in ('<h1>','<strong>','<code>','<ul>','<table','href="https://example.org/paper"'):
            self.assertIn(tag,html)
        self.assertNotIn('**Measured input**',html)
        self.assertNotIn('# Analysis',html)


if __name__=='__main__':
    unittest.main()
