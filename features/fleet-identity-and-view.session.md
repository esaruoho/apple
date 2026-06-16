# Session — Fleet identity hardening + one-click VIEW

Spawning conversation for [`fleet-identity-and-view.feature`](fleet-identity-and-view.feature). Faithful, not flattering.

## How to get back
- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/a4498127-286b-4422-92e5-30822b8120a1.jsonl`
- Session ID: `a4498127-286b-4422-92e5-30822b8120a1` (identified by content, not guessed — 66 hits on "CloudciyMacMini"/"build-screen-app"/"two CloudcityMacMinis" vs 1 in the next-best transcript)
- Resume: `claude --resume a4498127-286b-4422-92e5-30822b8120a1`
- Window: 2026-06-16 07:51:13Z → 17:44:23Z (UTC) = 10:51 → 20:44 EEST
- Carded: 2026-06-16

## The arc (requests → results)

1. **"Why does Fleet show two CloudcityMacMinis?"** Diagnosed: the Mini's `HostName` was unset (a macOS 26 upgrade reset it), so `gethostname()` fell back to a Bonjour-derived name, collided into `ComputerName = "CloudcityMacMini (2)"`, and garbled to `CloudciyMacMini` (the "t" dropped). Fleet keys peers by `card.id`, so the typo minted a second card. → Hardened `machine-card` to a canonical name; deleted the typo card. (c7cfcfd)

2. **"Still two after I rebooted Fleet."** Right — Fleet is just a viewer; the split was in the data. Also asked why MacPro showed "Syncthing stale" with a working LAN link: explained card-freshness ≠ reachability — the Mini *probes* Hertsi, and the probe used `.local`, which the storm broke. → Probe switched to the static IP from peers.json. (aeca2cc)

3. **"I don't want to see (2) — just CloudcityMacMini."** The "(2)" is the real `ComputerName`. Gave the `scutil --set` trio; **operator ran it** → all names clean, storm cleared, probe started publishing.

4. **WRONG TURN — Local Network Privacy.** When the pane's probe got `No route to host` to Hertsi while my SSH session reached it, I diagnosed macOS 26 **Local Network Privacy** blocking the iTerm pane. The operator corrected me: *iTerm already had the grant.* The real cause was the mDNSResponder storm destabilising the network stack — fixed by the static-HostName pin + HUP. Logged honestly in memory `feedback_mini_mdns_storm_breaks_lan_from_panes`. **Lesson:** check mDNSResponder CPU before blaming TCC; verify a privacy grant is actually missing before asserting it.

5. **"Rename MacPro → HertsiMacPro via SSH, and document it."** The Mac Pro's own hostname was `MacPro`. Operator renamed it to `HertsiMacPro` over SSH; I documented the technique (the three scutil names) in `wiki/concepts/rename-mac-via-ssh.md`. (fbdce17) Also fixed the probe to force the canonical NAME so no `MacPro` phantom card is minted. (717554d)

6. **"I want vnc://HertsiMacPro by clicking a file."** A `.vncloc` can't work (LAN-only Mac reachable only after the tunnel). → `bin/build-screen-app` mints `Screen <peer>.app` that runs `fleet-files screen <peer>`. (3dc5e4d)

7. **"MacPro stays after Refresh."** Found a real Fleet bug: `refreshSyncthing()` only added/updated, never purged. → Fixed to evict cards whose files vanished. (ba7df63)

8. **"AppleToolbox + Fleet should both have a VIEW button."** → VIEW button on every Fleet peer card; 🖥 Screen Share menu in AppleToolbox; `fleet-files` made case-insensitive + given a direct-vnc fallback so one action covers bridge and direct peers. (5512dde)

## Side effects / housekeeping surfaced
- Repeated auto-regen push races (documented failure mode) — resolved each via stash → rebase → push → pop; one generated-`wiki/INDEX.md` conflict resolved by taking a side (it regenerates on commit).
- Heavy concurrent multi-session WIP (filee, mlx-agent) churned the working tree; parked in stashes, nothing lost. One `wip-view2` pop was correctly refused (would clobber another session's untracked file) and left in the stash.
- Early fumbles writing the pakettibot file-bridge command without an absolute `cd` (caught, corrected) before switching to the durable repo-puller path.

## Memories written
- `feedback_machine_card_canonical_name` — Fleet keys on id, displays computer_name; canonicalise both.
- `feedback_mini_mdns_storm_breaks_lan_from_panes` — the corrected diagnosis (mDNS storm, not Local Network TCC).
