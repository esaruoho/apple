import tempfile
import unittest
from pathlib import Path
import sys
from types import SimpleNamespace

sys.path.insert(0, str(Path(__file__).resolve().parent / 'shared'))

from PIL import Image

import shared.cloud_assets as cloud_assets
from shared.cloud_source import read_spec, write_cloud_source


class WordcloudFallbackTests(unittest.TestCase):
    def test_fallback_writes_black_png_and_readable_exact_render_source(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / 'article.txt'
            output = Path(directory) / 'article.wordcloud.png'
            source.write_text(
                'Coherent electrons at shock fronts create plasma clusters. '
                'Plasma clusters interact with coherent electrons and magnetic fields. '
                'Measurements report voltage, pressure, temperature, and power.'
            )

            cloud_assets.render_wordcloud_fallback(source, output)

            self.assertTrue(output.is_file())
            self.assertGreater(output.stat().st_size, 1000)
            with Image.open(output) as image:
                self.assertEqual(image.getpixel((0, 0)), (0, 0, 0))
            spec = read_spec(output.with_suffix('.source.md'))
            self.assertEqual(spec['kind'], 'wordcloud')
            self.assertEqual(spec['settings']['background'], '#000000')
            self.assertIn('plasma', {item['text'] for item in spec['items']})
            self.assertTrue(output.with_suffix('.render.json').is_file())

    def test_generate_uses_fallback_when_installed_convey_wordcloud_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / 'article.txt'
            source.write_text('coherent electrons form plasma clusters near shock fronts. '*30)

            original = cloud_assets.subprocess.run
            original_mini = cloud_assets.mini
            original_load = cloud_assets.load

            def fake_load(name):
                if name != 'video':
                    return original_load(name)

                def make_keyideas(folder, stem, **kwargs):
                    base = Path(folder) / (stem + '.keyideas.png')
                    Image.new('RGB', (16, 16), 'black').save(base)
                    write_cloud_source(base, 'ideacloud', [('plasma', 3)], {'width': 16, 'height': 16})
                    (Path(folder) / (stem + '.keyideas.md')).write_text('# Ideas\n')
                return SimpleNamespace(make_keyideas=make_keyideas)

            def fail_wordcloud(command, **kwargs):
                if len(command) > 1 and command[1] == 'wordcloud':
                    raise cloud_assets.subprocess.CalledProcessError(1, command)
                kind = command[1]
                output = Path(command[command.index('--out') + 1])
                Image.new('RGB', (16, 16), 'black').save(output)
                write_cloud_source(output, kind, [('plasma', 3)], {'width': 16, 'height': 16})
                return SimpleNamespace(returncode=0)

            cloud_assets.subprocess.run = fail_wordcloud
            cloud_assets.mini = lambda: None
            cloud_assets.load = fake_load
            try:
                files, errors = cloud_assets.generate(source)
            finally:
                cloud_assets.subprocess.run = original
                cloud_assets.mini = original_mini
                cloud_assets.load = original_load

            self.assertFalse(errors)
            self.assertIn('article.wordcloud.png', files)
            self.assertIn('article.wordcloud.source.md', files)
            self.assertIn('article.wordcloud.render.json', files)


if __name__ == '__main__':
    unittest.main()
