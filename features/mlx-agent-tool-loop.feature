# =============================================================================
# REPORT CARD: mlx-agent-tool-loop — the on-device agentic TOOL-CALLING LOOP
#                                     (the WWDC26 thesis: model drives the verbs)
# Skin: CLI tool (claim = a task in → the Mini's MLX model reasons, CALLS convey/
#       apple verbs as tools, reads results, loops, then answers)
# Convention: ~/.claude/skills/report-card/SKILL.md
# SESSION >> features/mlx-agent-tool-loop.session.md
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/mlx_agent_core.py (shared loop + registry + sandbox),
#               bin/mlx-agent (Tailscale CLI over the core), bin/mlx-here (+--agent),
#               bin/fm-agent-service (Mini queue worker), bin/fm-agent-submit (client)
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
#   feature commit(s): fa003ff (bin/mlx-agent + mlx-here route + this card + .session)
#   PR: direct-push, no PR
#   files changed: bin/mlx-agent (new), bin/mlx-here (+--agent route),
#                  features/mlx-agent-tool-loop.feature (+ .session.md),
#                  bin/INDEX.md + features/INDEX.md (auto-regen by pre-commit)
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

  @built @hw-verified
  Scenario: a real task drives the belt end-to-end on the Mini
    Given Qwen3-4B-Instruct-2507-8bit is served at http://cloudcitymacmini:8080
    When `mlx-agent "<task>"` runs against a real folder
    Then the model emits real tool_calls, they execute, and it answers from the results
    # HW-VERIFIED 2026-06-16, two live runs against the Mini's Qwen3-4B:
    #  (1) search_notes("Foundation Models … NLEmbedding cache", ".") → answer citing the
    #      correct file convey-vs-apple-mlx-stack-and-embeddings.md.
    #  (2) MULTI-tool loop: list_dir(.) → read_file(spec) → answer. Proves the loop iterates
    #      on the model's own decisions, not a single call.
    # The server confirmed it honours the OpenAI `tools` param and returns proper tool_calls
    # (id + name + JSON arguments).

  @built @hw-verified
  Scenario: long files are paged (a bug the live run surfaced)
    Given read_file capped at 4000 bytes, run (2) answered "0 Open decisions" because the
          section lived past 4 KB in a long spec file
    When read_file gains an offset param + a "[truncated: N more bytes — offset=…]" hint
    Then paging to offset=8000 reaches the previously-unseen section
    # HW-VERIFIED 2026-06-16: corrected re-run — the model paged ITSELF, read_file
    # offset=8200 then offset=10400 (following the hint), and answered "4 Open
    # decisions" naming each, vs the pre-fix "0".

  @built @hw-verified
  Scenario: transient 502/503 reload windows are retried (a 2nd bug the live run surfaced)
    Given the Mini's mlx_lm.server 502s during model crash/reload windows
    When _post hits 500/502/503/504 or a connection error
    Then it retries with backoff (the same window convey graph analyze retries through)
    # Surfaced + fixed 2026-06-16. Long wedges still fail honestly with a clear message.

  @built @sim-verified
  Scenario: the queue twin runs the loop on the Mini (Comms/Syncthing path)
    Given the loop + tool registry are extracted to mlx_agent_core (shared, DRY)
    And bin/fm-agent-service drains fm-agent-inbox, runs core.run_loop ON THE MINI,
        streams the tool trace to <id>.partial.json, returns <id>.json via Syncthing
    And bin/fm-agent-submit drops a job + tails the trace
    Then `fm-agent-submit "<task>" --cwd <mini-path>` answers from the Mini's files
    # Self-verified locally 2026-06-16: core stubbed-loop test, real tools via core, sandbox
    # (ROOT), allowlist narrowing, fm-agent-submit --status. AGENT_ROOT tightened to ~/work.
    # Live-on-Mini PENDING: needs fm-agent-service deployed as a Cloudcity-Boot pane in
    # systems.yaml (NEVER nohup) + the chat model served with memory headroom.

  @built @hw-verified
  Scenario: the loop refuses an answer that cites an un-opened file (grounding enforcement)
    Given the model tries to finalise an answer citing a real file it never read_file'd
    When run_loop sees a cited-but-unopened existing file
    Then it re-prompts (up to 2x) to open + verify in the source, then accepts
    And a cited path that does NOT exist on disk is flagged "⚠ unverified citation"
    And search_notes surfaces the TOP FILES and tells the model to open one before citing
    # Verified 2026-06-17 (stubbed brain): cite-without-open → reprompt → read_file → accept;
    # fabricated path → flagged. Born from a live run where the 4B invented
    # wiki/concepts/nle-embedding-vs-fm.md (a file that does not exist).
    # LIVE 2026-06-17: with the lean system prompt (no more 502 crash), the Mini's
    # Qwen3-4B ran it clean: search_notes -> read_file -> read_file(offset=8000) ->
    # answered from a REAL file it opened (no fabrication, no ⚠).

  @built @sim-verified
  Scenario: the final answer is shown via the ONE shared presenter (DRY)
    Given a final answer and an interactive stdout
    Then it is rendered + spoken via fm_render.py --present (rich markdown + karaoke),
         never re-rolled here
    And when stdout is piped or --raw is set, the raw answer text is printed instead
