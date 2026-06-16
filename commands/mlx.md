---
description: Open a named, resumable Converse discussion with the Mini's MLX brain, armed with the skill governing the current folder. Renameable/saveable/resumable/⌘C-copyable. Usage `/mlx [name] [--fm|--list|--cwd DIR]`.
allowed-tools: Bash
argument-hint: [name] [--fm | --list | --cwd DIR]
---

Run the apple-skill `mlx` tool on `$ARGUMENTS`.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/mlx $ARGUMENTS
```

Opens a Converse discussion (MLX Qwen3-4B brain) armed with the cwd's governing
skill — `mlx <name>` to name/resume one. Talk to MLX for free, then `mlx-relay
<name>` to hand its answer to Claude for analysis or code changes.
