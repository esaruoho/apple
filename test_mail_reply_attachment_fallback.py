import importlib.machinery
import importlib.util
import unittest
import urllib.error
from unittest.mock import patch
loader=importlib.machinery.SourceFileLoader("mail_agent", "bin/freellmask-mail")
spec=importlib.util.spec_from_loader(loader.name,loader)
agent=importlib.util.module_from_spec(spec)
loader.exec_module(agent)

class ReplyFallbackTests(unittest.TestCase):
    def test_size_rejection_preserves_analysis_and_thread_without_attachments(self):
        reply={"text":"Analysis", "html":"<p>Analysis</p>", "attachments":[{"content":"large"}], "bcc":["owner@example.com"]}
        with patch.object(agent,"http",side_effect=[urllib.error.HTTPError("u",413,"large",{},None), {"message_id":"sent"}]) as send:
            self.assertEqual(agent.send_inbox_reply("key","original",reply),{"message_id":"sent"})
        self.assertEqual(send.call_count,2)
        first,second=[c.args for c in send.call_args_list]
        self.assertEqual(first[:3],second[:3])
        self.assertNotIn("attachments",second[3])
        self.assertIn("Analysis",second[3]["text"])
        self.assertEqual(second[3]["bcc"],reply["bcc"])
        self.assertIn("attachments",reply)

    def test_ambiguous_failures_never_retry(self):
        for error in (TimeoutError(),urllib.error.HTTPError("u",500,"error",{},None),urllib.error.URLError("connection")):
            with self.subTest(error=error), patch.object(agent,"http",side_effect=error) as send:
                with self.assertRaises(type(error)):agent.send_inbox_reply("key","original",{"attachments":[{}]})
                self.assertEqual(send.call_count,1)

    def test_no_attachments_cannot_use_size_fallback(self):
        with patch.object(agent,"http",side_effect=urllib.error.HTTPError("u",413,"large",{},None)) as send:
            with self.assertRaises(urllib.error.HTTPError):agent.send_inbox_reply("key","original",{"text":"large"})
            self.assertEqual(send.call_count,1)

    def test_success_is_sent_once(self):
        with patch.object(agent,"http",return_value={"message_id":"ok"}) as send:
            self.assertEqual(agent.send_inbox_reply("key","original",{"text":"fine"}),{"message_id":"ok"})
            self.assertEqual(send.call_count,1)
