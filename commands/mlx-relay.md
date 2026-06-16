---
description: Relay an MLX discussion's answer to Claude, in the repo it was armed for — Claude grades how well MLX did, or implements the change. Talk-to-MLX-then-escalate-to-Claude. Usage `/mlx-relay <name> [--apply|--copy] [-n N|--all] [note]`.
allowed-tools: Bash
argument-hint: <name> [--apply | --copy | --critique] [-n N | --all] [note] · or --list
---

Run the apple-skill `mlx-relay` tool on `$ARGUMENTS`.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/mlx-relay $ARGUMENTS
```

Takes the last MLX answer(s) from the named `mlx <name>` discussion and hands the
exchange to Claude running in that discussion's repo:
- default **critique** — Claude reads the real code and grades MLX's answer
- `--apply` — Claude may edit files to implement it (git diff after)
- `--copy` — puts a Claude-ready prompt on the clipboard for a supervised paste

`--list` shows relayable discussions. The free local MLX brain drafts; Claude verifies or commits.
