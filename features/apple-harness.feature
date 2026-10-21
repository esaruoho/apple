# =============================================================================
# WIKI PAGE / REPORT CARD: apple-harness — zero-token-first local ingestion engine
#
# WHAT THIS CARD SPAWNS:
#   codespace  — bin/apple-harness, bin/fmremote,
#                harness/lib/harness/{config,ledger,organs,reasoning,loop}.py,
#                harness/config.example.plist, harness/README.md
#   thinkspace — features/apple-harness.session.md
#   areaspace  — OWNS: the whitelabeled (Layer-1) harness engine — scan a pool,
#                extract with native Apple organs for zero LLM tokens, structure
#                (NER + NLEmbedding), decide via a bound reasoning organ with
#                majority vote, over an idempotent crash-only JSONL ledger.
#                MUST NOT TOUCH: CloudcityMacMini specifics, Syncthing paths,
#                convey, ~/work/cc/vault, or any 5TB-pool assumption — those are
#                the private instance (harken / ~/work/harken), not the engine.
#
# Report-card legend (grade tags, weakest -> strongest):
#   @designed @built @code-verified @build-verified @sim-verified
#   @runtime-verified @hw-verified   |   @untested @runtime-untested
#   @hw-untested @todo @partial   |   @stock (pre-existing, not ours)
#
# Innards linked back to this card (grep "apple-harness"):
#   bin/apple-harness        - CLI chassis: init / ingest / resume / status.
#   bin/fmremote             - remote Apple FM binding, wraps fm-submit -> Mini.
#   harness/lib/harness/capabilities.py - provider resolution; the no-download gate.
#   harness/lib/harness/ledger.py    - durable status ledger (source of truth).
#   harness/lib/harness/organs.py    - zero-token extract + NER + embed dispatch.
#   harness/lib/harness/reasoning.py - reasoning binding + majority vote-to-judge.
#   harness/lib/harness/loop.py      - Think->Act->Observe->Stop per asset.
#
# SESSION:      features/apple-harness.session.md
# RESULT:       Feature delivery pending commit (direct to main, no PR); card pending commit.
#
# WATCH: apple-harness fmremote Ledger seed commit run_asset extract tag_entities embed judge Config resolve describe CapabilityUnavailable local_preflight fleet_heartbeat
#
# RESULT-LOG >> (auto-maintained by the report-card hooks — newest below)
#   2026-10-21  direct-commit  touched: apple-harness extract embed
#   2026-10-21  direct-commit  touched: apple-harness fmremote extract embed describe
#   2026-10-21  direct-commit  touched: apple-harness fmremote extract embed judge Config resolve describe CapabilityUnavailable local_preflight fleet_heartbeat
#   2026-10-21  direct-commit  touched: apple-harness fmremote Ledger seed commit run_asset extract tag_entities embed judge Config
# =============================================================================

Feature: apple-harness — zero-token-first local ingestion engine
  As someone with a large, heterogeneous media pool,
  I want native Apple frameworks to extract and structure every asset for zero LLM tokens,
  So that the LLM is only ever handed entities and a tiny snippet, over a resumable ledger.

  @built @runtime-verified
  Scenario: Zero-token extraction, NER and embedding land an Obsidian Asset Note
    # cite: harness/lib/harness/loop.py run_asset; organs.py extract, tag_entities, embed
    Given a pool containing text assets with named entities
    When apple-harness ingests it with reasoning disabled
    Then each asset gets a 512-dim NLEmbedding vector in the embeds store
    And an Asset Note with YAML frontmatter listing its NER entities
    And the ledger row reaches status "analyzed" with zero tokens spent

  @built @runtime-verified
  Scenario: fmremote routes a prompt to the Mini and returns a clean answer
    # cite: bin/fmremote; harness/lib/harness/reasoning.py _ask
    Given local FoundationModels is unavailable (macOS 15.x)
    And the Mac Mini fm-worker is alive
    When fmremote submits a prompt
    Then the model answer is returned on stdout with all decoration on stderr

  @built @runtime-verified
  Scenario: Reasoning is majority-voted, never a single call
    # cite: harness/lib/harness/reasoning.py judge
    Given reasoning bound to fmremote with votes=3
    When apple-harness analyzes an asset's entities plus a tiny snippet
    Then it samples the model 3 times and records the majority tag-set and a k/N vote
    And a tie at the top is flagged as a flip-flop in the ledger errors

  @built @runtime-verified
  Scenario: Resume is idempotent
    # cite: bin/apple-harness resume; ledger.py pending, DONE
    Given a pool whose assets are all status "analyzed"
    When apple-harness resume runs
    Then it processes zero assets and leaves the ledger unchanged

  @built @code-verified @runtime-untested
  Scenario: The ledger survives a crash mid-write
    # cite: harness/lib/harness/ledger.py _load (tolerates a torn final line), commit (fsync)
    Given a ledger whose final line was torn by a crash during append
    When the ledger is reloaded
    Then the torn line is skipped and all prior rows load intact

  @built @runtime-untested
  Scenario: Image, PDF and audio modalities extract via capability resolution
    # cite: harness/lib/harness/capabilities.py resolve; organs.py extract
    Given a pool of images, PDFs and audio files under harken's config
    When harken ingests it
    Then images and PDFs extract via local vision-ocr (ocr:local)
    And audio transcribes on the Mini whisp belt (transcribe:fleet), never local
    And reasoning runs on the Mini (reason:fleet) because local fm needs macOS 26

  @built @runtime-verified
  Scenario: The harness never downloads a model to run locally
    # cite: harness/lib/harness/capabilities.py resolve (local_preflight gate)
    Given the whisp large-v3 model is NOT in the local cache
    And this machine is not macOS 26
    When the whitelabel config resolves transcribe and reason
    Then both resolve to UNAVAILABLE with an explicit error, downloading nothing
    When harken's fleet-bound config resolves them instead
    Then transcribe routes to the Mini whisp belt and reason to fmremote

  @built @runtime-verified
  Scenario: A down belt errors recoverably rather than falling back to local
    # cite: harness/lib/harness/loop.py run_asset; capabilities.py resolve
    Given the fm-worker heartbeat is briefly stale during heavy Mini load
    When an asset reaches the reason step
    Then the asset lands in status "error" (not a local download)
    And a later resume with the belt alive completes it to "analyzed"

  @built @runtime-verified
  Scenario: init writes an editable config from the whitelabeled example
    # cite: bin/apple-harness init; harness/config.example.plist
    Given no harness.plist in the working directory
    When apple-harness init runs
    Then it copies the whitelabeled example plist for the user to edit

  @built @runtime-verified
  Scenario: Oracle spaces project the ledger into per-entity folders
    # cite: harness/lib/harness/oracle.py build; bin/apple-harness oracle
    Given a pool whose analyzed assets carry NER entities
    When apple-harness oracle runs
    Then each entity gets oracle_spaces/<slug>/namespace.yaml with focus areas and connections
    And an index.md linking that entity's Asset Notes with Obsidian wikilinks

  @built @runtime-verified
  Scenario: A private instance (harken) overrides bindings without touching the engine
    # cite: harness/lib/harness/config.py _deep_merge; ~/work/harken/harken.plist
    Given a harken config binding reason to fmremote and transcribe to the Mini whisp belt
    When apple-harness runs with that config
    Then the engine routes to the fleet belts with no change to engine code
