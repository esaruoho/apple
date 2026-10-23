"""One renderer; screenshot regression and lossless source attachments."""
import base64
from html.parser import HTMLParser
from pathlib import Path
import unittest
from shared import format_email as f

POLARIZATION = r'\mathbf{P} = \epsilon_0 \left( \chi^{(1)} \mathbf{E} + \chi^{(2)} \mathbf{E}\mathbf{E} + \chi^{(3)} \mathbf{E}\mathbf{E}\mathbf{E} + ... \right)'
PHASE = r'\mathbf{k}_c = \mathbf{k}_1 + \mathbf{k}_2 - \mathbf{k}_s'
EXAMPLE = 'The nonlinear polarization \\( \\mathbf{P} \\):\n\\[\n'+POLARIZATION+'\n\\]\nDFWM is third-order (\\( \\chi^{(3)} \\)).\n\\[\n'+PHASE+'\n\\]\n'


class RendererTests(unittest.TestCase):
    def test_screenshot_backslash_delimiters_and_multiline_equations(self):
        output = f.md_to_html(EXAMPLE)
        self.assertIn('χ<sup>(3)</sup>', output)
        self.assertIn('ε<sub>0</sub>', output)
        self.assertIn('<b>k</b><sub>c</sub>', output)
        self.assertNotIn(r'\mathbf', output.split('aria-label=')[0])
        self.assertEqual(output.count('class="aimeat-math"'), 4)
        self.assertNotIn('AIMEATMATH', output)

    def test_both_dollar_forms_and_nested_fraction(self):
        output = f.md_to_html(r'$E_s^*$ and $$\frac{\chi^{(3)}}{\sqrt{\epsilon_0}}$$')
        self.assertIn('E<sub>s</sub><sup>*</sup>', output)
        self.assertIn('χ<sup>(3)</sup>', output)
        self.assertIn('√', output)
        self.assertNotIn('<em>', output)

    def test_code_fences_inline_code_and_currency_are_not_math(self):
        source = '```latex\n'+EXAMPLE+'```\nCode `$x^2$` and prices $5 and $10.\n'
        output = f.md_to_html(source)
        self.assertNotIn('class="aimeat-math"', output)
        self.assertIn('$x^2$', output)
        self.assertIn('$5 and $10', output)

    def test_unknown_or_malformed_tex_is_preserved_not_stripped(self):
        for expression in (r'\futurecommand{Q}', r'\frac{1}{2'):
            output = f.md_to_html('\\[\n'+expression+'\n\\]')
            self.assertIn('Unrendered LaTeX preserved:', output)
            self.assertIn(expression, output)

    def test_html_is_escaped_in_formula(self):
        output = f.md_to_html(r'\(<img src=x onerror=alert(1)>\)')
        self.assertNotIn('<img', output)
        self.assertIn('&lt;img', output)

    def test_source_mime_and_attachments_preserve_original_exactly(self):
        payload = f.email_payload(EXAMPLE, title='Test', filename='original')
        self.assertEqual(payload['text'], EXAMPLE)
        attachments = {a['filename']: base64.b64decode(a['content']).decode() for a in payload['attachments']}
        self.assertEqual(attachments['original.md'], EXAMPLE)
        self.assertIn(POLARIZATION, attachments['original.tex'])
        self.assertIn(PHASE, attachments['original.tex'])
        self.assertLess(attachments['original.tex'].index(POLARIZATION), attachments['original.tex'].index(PHASE))

    def test_markup_around_math_and_math_underscores_survive(self):
        output = f.md_to_html(r'1. **Pump:** \(\mathbf{E}_1\) and \(\mathbf{E}_s\).')
        self.assertIn('<ol ', output)
        self.assertIn('<strong ', output)
        self.assertIn('<b>E</b><sub>1</sub>', output)
        self.assertIn('<b>E</b><sub>s</sub>', output)

if __name__ == '__main__': unittest.main()
