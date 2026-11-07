"""The shared transport now owns fallback; test at its actual HTTP boundary."""
import json
import unittest
import urllib.error
from unittest.mock import patch
from shared import agentmail_send as sender
from shared.format_email import MailContent

class ReplyFallbackTests(unittest.TestCase):
    def setUp(self):
        self.requests=[];self.errors=[]
        class Response:
            status=200
            def __enter__(self):return self
            def __exit__(self,*args):pass
            def read(self):return b'{"message_id":"sent"}'
        def post(request,**kwargs):
            self.requests.append((request.full_url,json.loads(request.data)))
            if self.errors:raise self.errors.pop(0)
            return Response()
        mocking=patch('urllib.request.urlopen',post);mocking.start();self.addCleanup(mocking.stop)
    def send(self):
        return sender.reply_to_message('original',MailContent('Analysis',attachments=[{'filename':'source.pdf','content':'cGRm'}]),
                     key='test-key',inbox='test',bcc=['owner@example.com'])
    def test_size_rejection_preserves_analysis_thread_and_warning(self):
        self.errors=[urllib.error.HTTPError('u',413,'large',{},None)]
        self.assertEqual(self.send(),{'message_id':'sent'})
        self.assertEqual(len(self.requests),2)
        first,second=self.requests
        self.assertEqual(first[0],second[0]);self.assertNotIn('attachments',second[1])
        self.assertIn('Analysis',second[1]['text']);self.assertIn('source.pdf',second[1]['text'])
        self.assertTrue(second[1]['html'].endswith('</html>'))
        self.assertEqual(second[1]['bcc'],['owner@example.com'])
    def test_ambiguous_failures_never_retry(self):
        for error in (TimeoutError(),urllib.error.URLError('connection'),urllib.error.HTTPError('u',500,'bad',{},None)):
            with self.subTest(error=error):
                self.requests=[];self.errors=[error]
                with self.assertRaises(type(error)):self.send()
                self.assertEqual(len(self.requests),1)
    def test_fallback_is_bounded(self):
        self.errors=[urllib.error.HTTPError('u',413,'large',{},None)]*2
        with self.assertRaises(urllib.error.HTTPError):self.send()
        self.assertEqual(len(self.requests),2)
    def test_success_is_sent_once(self):
        self.assertEqual(self.send(),{'message_id':'sent'})
        self.assertEqual(len(self.requests),1)
