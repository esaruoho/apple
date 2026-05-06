# Studio Prompts — Paste These Into Ray Studio

These are the exact prompts to paste into `chrome://ray-ui/studio/` to generate each Thought Multiplier app.

---

## 1. Seed Capture (Phase 1)

```
Build me a minimal text input app with a large textarea, a Send button, and a settings gear icon. Dark theme (#0a0a0f background, #7c6aef accent). When I press Send or Cmd+Enter, it stores the text in localStorage under `ray-seed-{ISO timestamp}` as JSON with fields: ts, seed, branches (object of enabled destinations), context_tabs (empty array). Then dispatch a custom event `seed-ready` on the window with the seed data as detail. Show a brief "Seed captured" flash notification. Below the input, show the 5 most recent seeds with relative timestamps, clickable to reload. The settings gear toggles a panel with 5 destination toggles: Archive (on by default), LLM Process, Browser/CMS, Email, Graph. Persist toggle state in localStorage under `thought-multiplier-branches`. Show total seed count in the header.
```

---

## 2. Rebound Dashboard (Phase 5)

```
Build me a dashboard app that reads seed data from localStorage (keys starting with `ray-seed-`) and shows the most recent seed with its rebound data. Dark theme (#0a0a0f background). Show: the original seed text in a card, then a 2-column grid of 5 branch cards (Archive green #4ade80, LLM pink #f472b6, Browser blue #60a5fa, Email amber #fbbf24, Graph purple #a78bfa). Each card has: branch name, status (Saved/Complete/Published/Sent/Updated or Pending), and the output text. Rebound data comes from localStorage under `ray-rebound-{timestamp}` as JSON with archive, llm, browser, email, graph fields. At the bottom, a "Next Seed" card with accent border shows a suggestion (from rebound.next_seed). Clicking it dispatches `navigate-to-seed` event. Auto-refresh every 3 seconds. Listen for `seed-ready` and `rebound-complete` custom events.
```

---

## 3. Graph Viewer (Phase 4)

```
Build me a thought pattern visualization app. Dark theme (#0a0a0f). Three view modes via toolbar buttons: Clusters (canvas graph), Timeline (vertical list), Words (tag cloud). Reads seeds from localStorage (keys `ray-seed-*`). Clusters view: canvas with colored dot nodes grouped by word-overlap similarity (Jaccard > 0.15). Timeline view: chronological list with colored dots and timestamps. Words view: word frequency cloud excluding stop words, sized by frequency. Show stats (seed count, cluster count) in the toolbar. Auto-refresh on `seed-ready` events. 6 cluster colors rotating: green, pink, blue, amber, purple, orange.
```

---

## 4. Seed Capture v2 — With LLM Side-by-Side (Phase 2 Update)

```
Update: after sending a seed, show a split view below the textarea. Left side: "Original" with the raw seed text. Right side: "Refined" with the LLM output (read from localStorage `ray-rebound-{ts}` field llm.refined). Highlight differences with a green left border. Add a "Copy Refined" button. If no LLM output yet, show "Processing..." with a subtle pulse animation. Poll localStorage every 2 seconds for the rebound data.
```
