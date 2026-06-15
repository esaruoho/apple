# =============================================================================
# REPORT CARD: mlx-agent-tool-loop — the on-device agentic TOOL-CALLING LOOP
#                                     (the WWDC26 thesis: model drives the verbs)
# Skin: CLI tool (claim = a task in → the Mini's MLX model reasons, CALLS convey/
#       apple verbs as tools, reads results, loops, then answers)
# Convention: ~/.claude/skills/report-card/SKILL.md
# SESSION >> features/mlx-agent-tool-loop.session.md
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/mlx-agent (the loop + tool registry + sandbox),
#               bin/mlx-here (+--agent/--tools route)
#   Thinkspace: the .session.md — the /last30days finding that Apple's official
#               WWDC26 stack has ONE primitive Convey lacked (the tool-calling
#               loop), and the decision to adopt it since both halves (a tool-
#               calling server + a verb catalog) already existed
#   Areaspace : OWNS the agentic loop (post → tool_calls → execute → repeat) and
#               the SAFE tool registry (read-only/idempotent convey+apple verbs,
#               argv-array exec, $HOME sandbox, bounded output). Does NOT own the
#               MLX transport (mlx_lm.server / FM_MLX_HOST), the skill arming
#               (arm_apple.build_system), the reply presenter (fm_render.py), nor
#               the verbs themselves (convey molecule/ask, vault-grep, vision-ocr,
#               folder-memory, tag) — it consumes all of them.
#
# RESULT
#   feature commit(s): <pending — same motion as the build>
#   PR: direct-push, no PR
#   files changed: bin/mlx-agent (new), bin/mlx-here (+--agent route),
#                  features/mlx-agent-tool-loop.feature (+ .session.md)
# =============================================================================

Feature: The on-device agentic tool-calling loop on the Mini's MLX brain
  As Esa, I want the local MLX model to DRIVE the convey conveyor belt — decide to
  search my notes, open a file's molecule, OCR an image — instead of me wiring each
  step, so Convey becomes "a CLI the on-device model drives" (the WWDC26 session 232
  thesis), not just "a CLI a human drives". Both halves already existed: the MLX-LM
  Server speaks the OpenAI tool-calling protocol, and convey has a verb catalog;
  this wires them into a loop.

  Background:
    Given the Mini serves a tool-calling chat model (Qwen3-4B) at FM_MLX_HOST
    And bin/mlx-agent registers SAFE read-only convey+apple verbs as OpenAI tools
    And arm_apple.build_system arms the governing skill of the folder as the system prompt

  @built @sim-verified
  Scenario: the loop executes a tool then returns a final answer
    Given a stubbed server that returns one tool_call then a final message
    When run_loop runs the task
    Then the tool is executed, its result is appended as a role:tool message
    And the next turn's plain content is returned as the final answer
    # Verified locally 2026-06-15: stubbed _post, list_dir tool, final "Done…" returned.

  @built @hw-verified
  Scenario: the SAFE tool registry runs the real verbs read-only
    Given the eight registered tools (list_dir, read_file, search_notes, molecule,
          ask_file, vision_ocr, folder_memory, tag_find)
    When the model calls search_notes("NLEmbedding cache", ".")
    Then bin/vault-grep runs the on-device NLEmbedding cosine search and returns
         scored passages with file paths
    # Verified locally 2026-06-15: search_notes → "0.469  INDEX.md:105 …" real output.

  @built @hw-verified
  Scenario: the sandbox refuses paths outside $HOME
    Given a tool call read_file("/etc/hosts")
    When the tool executes
    Then it is refused with "outside /Users/esaruoho" and no bytes are read
    # Verified locally 2026-06-15: "[refused: /private/etc/hosts is outside /Users/esaruoho]".

  @built @hw-verified
  Scenario: --dry-run lists the registry and mlx-here --agent routes here
    When `mlx-agent --dry-run` runs
    Then it prints the 8 tools and the FM_MLX_HOST endpoint
    And `mlx-here --agent <task>` execs bin/mlx-agent --cwd "$PWD"
    # Verified 2026-06-15: both printed the 8-tool registry.

  @built @untested
  Scenario: a real task drives the belt end-to-end on the Mini
    Given the Qwen3-4B chat model is actually served at FM_MLX_HOST
    When `mlx-agent "what is <file> about and what does it relate to?"` runs
    Then the model calls search_notes / molecule / read_file as needed and answers
    # PENDING hardware verification: on 2026-06-15 the Mini's :8080 was serving
    # TTS + GLM-OCR models, not the Qwen3-4B chat model, so the live agentic loop
    # could not be exercised. Re-run once the chat model is served (set FM_MLX_HOST
    # / FM_MLX_MODEL to the chat endpoint). NOT claiming hw-verified until then.

  @built @sim-verified
  Scenario: the final answer is shown via the ONE shared presenter (DRY)
    Given a final answer and an interactive stdout
    Then it is rendered + spoken via fm_render.py --present (rich markdown + karaoke),
         never re-rolled here
    And when stdout is piped or --raw is set, the raw answer text is printed instead
