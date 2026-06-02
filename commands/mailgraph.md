---
description: Directed who-wrote-to-whom graph from a message base (BBS dump or RFC822 .eml), parsed straight from From:/To: headers. Renders an Apple-native SVG (--svg), subject threads (--threads), email-alias folding, JSON/DOT. Point it at any folder of messages. Deterministic, no LLM in the loop.
---

Build a mail/contacts graph from any folder of messages. Parses From:/To: headers directly — the addressing IS the edge.

```bash
/Users/esaruoho/work/apple/bin/mailgraph $ARGUMENTS
```

Examples:
- `/mailgraph --dir ~/Downloads/SomeBBS --svg /tmp/g.svg` then it opens
- `/mailgraph --dir <maildir> --threads` (subject-line threads)
- `/mailgraph --dir <maildir> --alias "billb@eskimo.com=Bill Beaty"`
