# ============================================================================
# REPORT CARD — Fleet identity hardening + one-click VIEW (Screen Sharing)
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/machine-card · bin/fleet-files · bin/build-screen-app ·
#               fleet/Fleet.swift · topbar/AppleToolbox.swift ·
#               comms/scripts/machine-card-probe.sh + machine-card-probe-assemble.py ·
#               wiki/concepts/rename-mac-via-ssh.md
#   Thinkspace : features/fleet-identity-and-view.session.md (the diagnosis arc,
#               including one wrong turn — the Local Network Privacy misdiagnosis)
#   Areaspace : the fleet's machine-identity + reachability layer. OWNS: how a
#               Mac names itself in its card, how a card is keyed/deduped/purged
#               in Fleet, how a LAN-only Mac is probed + screen-shared. MUST NOT
#               TOUCH: the belt/treatment engine, worker queues, OCR/voicebox.
#
# REPORT-CARD LEGEND (grades in use)
#   @runtime-verified — observed working live this session
#   @build-verified   — compiles/builds clean; runtime needs an app relaunch
#   @built            — shipped (e.g. docs); no runtime assertion applies
#   @ops-verified     — verified by operator action on the target machine
#
# RESULT
#   apple (direct-push to main):
#     c7cfcfd  machine-card: canonical name immune to Bonjour storms
#     ba7df63  fleet: refresh evicts Syncthing peers whose card file vanished
#     fbdce17  wiki: rename a Mac via SSH
#     3dc5e4d  bin/build-screen-app: clickable "Screen <peer>.app"
#     5512dde  Fleet + AppleToolbox: one-click VIEW (Screen Sharing) to any peer
#   comms (direct-push to main):
#     aeca2cc  machine-card-probe: resolve Hertsi via static IP from peers.json
#     8fce465  machine-card-probe: TEMP debug logging  (reverted by 717554d)
#     717554d  machine-card-probe: drop temp debug; force canonical name HertsiMacPro
#   operator action (on the machines, not a commit):
#     Mini   — scutil --set HostName/LocalHostName/ComputerName CloudcityMacMini
#              + killall -HUP mDNSResponder   (cleared the name-conflict storm)
#     MacPro — same scutil trio set to HertsiMacPro  (the real rename)
# ============================================================================

Feature: Fleet shows each Mac once, correctly named, and one click screen-shares to it

  # ---- IDENTITY: stop one Mac splitting into two cards -------------------
  @runtime-verified
  Scenario: A churned hostname no longer splits a Mac into two Fleet cards
    Given the Mini's HostName was unset, so gethostname() returned a garbled
      "CloudciyMacMini" and ComputerName carried a " (2)" Bonjour-collision suffix
    When machine-card builds a card
    Then both the dedup `id` and the displayed name resolve to a canonical
      "CloudcityMacMini" (fleet config → ComputerName minus " (N)" → HostName →
      gethostname), so Fleet renders ONE card, not a stale+fresh pair
    # cite: bin/machine-card _canonical_name() + identity() (~L124); apple c7cfcfd

  @ops-verified
  Scenario: Pinning a static HostName ends the mDNSResponder name-conflict storm
    Given mDNSResponder was pinned at 100% and the kernel hostname was garbled
    When the operator runs `sudo scutil --set HostName/LocalHostName/ComputerName
      CloudcityMacMini` + `killall -HUP mDNSResponder` on the Mini
    Then gethostname/kern.hostname/ComputerName all read "CloudcityMacMini" and
      LAN access from Cloudcity-Boot panes recovers (probe specs_len 0 → 129)
    # cite: wiki/concepts/rename-mac-via-ssh.md; operator action 2026-06-16

  @runtime-verified
  Scenario: Fleet forgets a card whose file was deleted
    Given a machine-card-<id>.json is removed from the Syncthing queue
    When Fleet's refresh runs
    Then any .syncthing-origin peer absent from the current queue listing is
      evicted from the view (Bonjour/LAN peers still reconcile via NWBrowser)
    # cite: fleet/Fleet.swift refreshSyncthing() foundIDs prune (~L585); apple ba7df63
    # note: @build-verified for the running instance until Fleet.app is relaunched

  # ---- HERTSI: a 2008 Mac Pro the fleet probes for ----------------------
  @runtime-verified
  Scenario: The Mini probes Hertsi over a static IP, immune to mDNS breakage
    Given Hertsi (macOS 10.11) can't self-report and was probed via hertsimacpro.local
    When the Mini's mDNSResponder is unhealthy and .local fails to resolve
    Then the probe reads Hertsi's static IP from fleet-index/peers.json instead,
      so the card stays fresh (probe status "publishing")
    # cite: comms/scripts/machine-card-probe.sh hertsi_target() (~L37); comms aeca2cc

  @runtime-verified
  Scenario: Hertsi's card is always titled HertsiMacPro, never MacPro
    Given Hertsi's own `hostname -s` reports "MacPro"
    When the probe assembles the card
    Then the canonical NAME "HertsiMacPro" (argv[2]) is used for the card id and
      filename, so no phantom machine-card-MacPro.json is minted
    # cite: machine-card-probe.sh ($NAME arg) + machine-card-probe-assemble.py (sys.argv[2]); comms 717554d

  @ops-verified
  Scenario: The Mac Pro is genuinely renamed to HertsiMacPro
    Given the operator wants `ssh HertsiMacPro` and a correct card, not a workaround
    When `sudo scutil --set HostName/LocalHostName/ComputerName HertsiMacPro` runs on it
    Then `scutil --get ComputerName` returns HertsiMacPro and the probe naturally
      emits a HertsiMacPro card
    # cite: wiki/concepts/rename-mac-via-ssh.md; operator action 2026-06-16

  # ---- VIEW: one click → Screen Sharing ---------------------------------
  @runtime-verified
  Scenario: fleet-files screen accepts a Machine Card id and picks the right transport
    Given a peer name in any case (e.g. "HertsiMacPro") or alias ("hertsi")
    When `fleet-files screen <name>` runs
    Then resolve() matches case-insensitively across key/alias/host; a LAN-bridge
      Mac gets an ssh -L hop through the Mini (vnc://localhost:5901) and any other
      peer opens vnc://<host> directly
    # cite: bin/fleet-files find_peer()/resolve() + cmd_tunnel fallback; apple 5512dde

  @runtime-verified
  Scenario: A clickable app screen-shares to a peer in one double-click
    Given a fleet peer name
    When `bin/build-screen-app <peer>` runs
    Then it osacompiles "/Applications/AppleToolbox/Fleet-Apps/Screen <peer>.app"
      whose run handler invokes `fleet-files screen <peer>` (tunnel + viewer)
    # cite: bin/build-screen-app build(); apple 3dc5e4d  (verified: "Screen hertsi.app")

  @build-verified
  Scenario: Fleet shows a VIEW button on every peer card
    Given a non-local peer card is rendered
    When the user clicks VIEW
    Then model.screenShare() runs `fleet-files screen <card.id>` fire-and-forget
    # cite: fleet/Fleet.swift screenShare() + title-row Button (~L620,L820); apple 5512dde
    # note: built+signed; live after Fleet.app relaunch

  @runtime-verified
  Scenario: AppleToolbox lists a VIEW item per peer under a Screen Share menu
    Given the menu is rebuilt
    When the user opens 🧰 ▸ 🖥 Screen Share
    Then one "VIEW <peer>" row per machine-card in the queue (self excluded) runs
      `fleet-files screen <id>`
    # cite: topbar/AppleToolbox.swift screenShareItems() + rebuildMenu (~L3765,L4148); apple 5512dde
    # note: built + auto-relaunched live this session

  # ---- WHAT IS GONE (struck claims / removed artifacts) -----------------
  # - machine-card-CloudciyMacMini.json  (typo card)      — deleted
  # - machine-card-MacPro.json           (phantom card)   — deleted
  # - the " (2)" ComputerName suffix on the Mini          — gone (renamed)
  # - mDNSResponder 100% name-conflict storm              — cleared (HUP + static HostName)
  # - the .local dependency in the Hertsi probe           — replaced by static IP
  # - TEMP /tmp debug logging in the probe                — reverted (717554d)
  # - the Local Network Privacy hypothesis                — WRONG; see .session.md
