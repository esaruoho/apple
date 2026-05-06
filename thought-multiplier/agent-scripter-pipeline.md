# Agent Scripter Pipeline — The Fork

## Pipeline Structure

The Fork is an Agent Scripter `TabScript` with parallel `ScriptStep` objects. Steps with no `{{step_id.output}}` dependencies run in parallel.

---

## Phase 1: Seed + Archive Only

```json
{
  "name": "Thought Multiplier — Archive",
  "description": "Capture seed from Seed Capture tab and write to local archive",
  "steps": [
    {
      "id": "read_seed",
      "action": "execute_javascript",
      "params": {
        "code": "const keys = []; for (let i = 0; i < localStorage.length; i++) { const k = localStorage.key(i); if (k.startsWith('ray-seed-')) keys.push(k); } const latest = keys.sort().reverse()[0]; return localStorage.getItem(latest);"
      }
    },
    {
      "id": "archive",
      "action": "execute_javascript",
      "params": {
        "code": "const seed = JSON.parse('{{read_seed.output}}'); const line = JSON.stringify(seed); const blob = new Blob([line + '\\n'], {type: 'application/jsonl'}); const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = 'thought-archive.jsonl'; a.click(); return 'archived: ' + seed.ts;"
      }
    }
  ]
}
```

---

## Phase 2: Seed + Archive + LLM

```json
{
  "name": "Thought Multiplier — Fork (2 branches)",
  "description": "Archive seed AND process through local Phi-4",
  "steps": [
    {
      "id": "read_seed",
      "action": "execute_javascript",
      "params": {
        "code": "const keys = []; for (let i = 0; i < localStorage.length; i++) { const k = localStorage.key(i); if (k.startsWith('ray-seed-')) keys.push(k); } const latest = keys.sort().reverse()[0]; return localStorage.getItem(latest);"
      }
    },
    {
      "id": "archive",
      "action": "execute_javascript",
      "depends_on": ["read_seed"],
      "params": {
        "code": "const seed = JSON.parse('{{read_seed.output}}'); localStorage.setItem('ray-archive-' + seed.ts, JSON.stringify(seed)); return 'archived';"
      }
    },
    {
      "id": "llm_process",
      "action": "local_inference",
      "depends_on": ["read_seed"],
      "params": {
        "model": "phi-4-mini",
        "prompt": "Expand and refine the following idea. Be concise but insightful. Preserve the original intent while strengthening the argument:\n\n{{read_seed.output}}"
      }
    },
    {
      "id": "store_rebound",
      "action": "execute_javascript",
      "depends_on": ["archive", "llm_process"],
      "params": {
        "code": "const seed = JSON.parse('{{read_seed.output}}'); const rebound = { archive: true, llm: { refined: '{{llm_process.output}}' } }; localStorage.setItem('ray-rebound-' + seed.ts, JSON.stringify(rebound)); return 'rebound stored';"
      }
    }
  ]
}
```

---

## Phase 3: Full Fork (5 branches)

```json
{
  "name": "Thought Multiplier — Full Fork",
  "description": "5-branch parallel radiation: archive, LLM, browser, email, graph",
  "steps": [
    {
      "id": "read_seed",
      "action": "execute_javascript",
      "params": {
        "code": "const keys = []; for (let i = 0; i < localStorage.length; i++) { const k = localStorage.key(i); if (k.startsWith('ray-seed-')) keys.push(k); } const latest = keys.sort().reverse()[0]; const data = localStorage.getItem(latest); return data;"
      }
    },
    {
      "id": "branch_archive",
      "action": "execute_javascript",
      "depends_on": ["read_seed"],
      "params": {
        "code": "const seed = JSON.parse('{{read_seed.output}}'); localStorage.setItem('ray-archive-' + seed.ts, JSON.stringify(seed)); return JSON.stringify({status: 'archived', ts: seed.ts});"
      }
    },
    {
      "id": "branch_llm",
      "action": "local_inference",
      "depends_on": ["read_seed"],
      "params": {
        "model": "phi-4-mini",
        "prompt": "Expand and refine the following idea. Be concise but insightful:\n\n{{read_seed.output}}"
      }
    },
    {
      "id": "branch_browser",
      "action": "activate_tab",
      "depends_on": ["read_seed"],
      "params": {
        "tab_pattern": "{{settings.cms_tab_pattern}}",
        "then": [
          { "action": "click_element", "selector": "{{settings.cms_editor_selector}}" },
          { "action": "press_key", "text": "{{read_seed.output}}" }
        ]
      }
    },
    {
      "id": "branch_email",
      "action": "activate_tab",
      "depends_on": ["read_seed"],
      "params": {
        "tab_pattern": "{{settings.email_tab_pattern}}",
        "then": [
          { "action": "click_element", "selector": "[aria-label='Compose']" },
          { "action": "press_key", "text": "{{read_seed.output}}" }
        ]
      }
    },
    {
      "id": "branch_graph",
      "action": "execute_javascript",
      "depends_on": ["read_seed"],
      "params": {
        "code": "window.dispatchEvent(new CustomEvent('seed-ready', { detail: JSON.parse('{{read_seed.output}}') })); return 'graph notified';"
      }
    },
    {
      "id": "store_rebound",
      "action": "execute_javascript",
      "depends_on": ["branch_archive", "branch_llm", "branch_browser", "branch_email", "branch_graph"],
      "params": {
        "code": "const seed = JSON.parse('{{read_seed.output}}'); const rebound = { archive: true, llm: { refined: '{{branch_llm.output}}' }, browser: { status: '{{branch_browser.output}}' }, email: { status: '{{branch_email.output}}' }, graph: { status: '{{branch_graph.output}}' } }; localStorage.setItem('ray-rebound-' + seed.ts, JSON.stringify(rebound)); window.dispatchEvent(new CustomEvent('rebound-complete')); return 'full rebound stored';"
      }
    }
  ]
}
```

---

## Settings (Configurable via Seed Capture Settings Panel)

| Setting | Key | Example |
|---------|-----|---------|
| CMS tab pattern | `settings.cms_tab_pattern` | `*notion.so*` or `*wordpress*` |
| CMS editor selector | `settings.cms_editor_selector` | `.notion-page-content` |
| Email tab pattern | `settings.email_tab_pattern` | `*mail.google.com*` |
| LLM prompt template | `settings.llm_prompt` | `"Expand this idea..."` |

---

## How Agent Scripter Parallelism Works

Steps that depend ONLY on `read_seed` (not on each other) run **in parallel**:

```
read_seed
    |
    +---> branch_archive  (parallel)
    +---> branch_llm      (parallel)
    +---> branch_browser   (parallel)
    +---> branch_email     (parallel)
    +---> branch_graph     (parallel)
    |
    v
store_rebound (waits for ALL branches)
```

This is Russell's P2: one seed, five simultaneous expressions.
