# Pure Gherkin test extracted from features/converse-to-obsidian.feature
# (report-card banner stripped; inline # cite: traceability kept)
# Regenerate: python3 print-card.py features/converse-to-obsidian.feature

Feature: converse-to-obsidian — linked Markdown views of Converse sessions
  As someone discussing a repo with Converse and FM/MLX,
  I want the discussion rendered as linked Markdown notes,
  So that a repo such as scaff can benefit from the conversation in an Obsidian-style graph.

  @built @runtime-verified
  Scenario: A named Converse session exports to linked Markdown
    # cite: bin/converse-to-obsidian resolve_session, turns_from_events, render_session_note, render_turn_note
    Given a Converse session name with talk.heard and agent.responded events
    When converse-to-obsidian exports it to an output directory
    Then it writes one session note and one note per turn
    And the session note links to each turn note with Obsidian wikilinks

  @built @runtime-verified
  Scenario: Existing fm-converse memory is usable before livefile turn logging lands
    # cite: bin/converse-to-obsidian turns_from_cache
    Given livefile.jsonl contains no model turn pairs
    When ~/.cache/fm-converse/<session>.json contains paired user and assistant turns
    Then the exporter renders those cached pairs as Obsidian turn notes
    And a repo export links the notes to the repo context

  @built @code-verified
  Scenario: Future livefile agent events take precedence over cache state
    # cite: bin/converse-to-obsidian turns_from_events and main
    Given livefile.jsonl contains request and response events with matching request_id
    When the exporter reads the session
    Then it uses the livefile event pairs instead of the fm-converse cache fallback

  @built @runtime-verified
  Scenario: The shared publisher updates Scaff and the Obsidian vault from one livefile
    # cite: bin/converse-publish publish_scaff, publish_vault
    # cite: bin/converse-to-obsidian render_session_note, render_turn_note
    Given a Converse session directory with livefile.jsonl
    When converse-publish runs for that session
    Then Scaff's ConverseInbox is refreshed through semantic-convey-file converse-push
    And the Obsidian-shaped vault receives linked session and turn notes
    And both views are derived from the same livefile source of truth

  @built @build-verified
  Scenario: Converse.app automatically calls the shared publisher after replies
    # cite: /Users/esaruoho/work/converse/main.swift publishCurrentSession
    Given Converse.app logs an agent response into livefile.jsonl
    When the reply path finishes
    Then Converse.app invokes bin/converse-publish for the current session
    And it no longer owns a Scaff-specific export path

  @built @runtime-verified
  Scenario: fm-converse automatically calls the shared publisher after captured turns
    # cite: bin/fm-converse _publish_capture_session
    Given fm-converse captures a successful turn into livefile.jsonl
    When the turn is saved
    Then it calls converse-publish so Scaff and the Obsidian vault both benefit

  @built @runtime-verified
  Scenario: Booting Converse.app automatically populates the vault after a model turn
    Given Converse.app starts or appends a model turn
    When converse-publish is available
    Then the corresponding Obsidian notes are refreshed without a manual export command
    And the source of truth remains livefile.jsonl rather than Markdown
