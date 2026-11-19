# What is eating the CloudcityMacMini's memory — 2026-11-19 (via `bin/memhogs --host cloudcity`)

The Mini has 32 GB of RAM and has been up 63 days. Memory pressure is fine: 46% free. Swap is almost full, though: 12.6 of 14.3 GB used, so pages have been pushed out over the 63 days of uptime. Wired memory is 14.5 GB, mostly GPU/Metal memory held by the model servers.

| Footprint | What | Doing |
|---|---|---|
| 5.5–6.2 GB | `mlx_lm.server` (Python, .venv-mlx) | Qwen3-4B-Instruct-8bit LLM on :8080, up 18 h |
| 5.3 GB | WidgetRenderer_Activities | macOS Live Activities widget renderer, up 63 days. Its memory keeps growing (a leak) |
| 4.1 GB | Safari (+1.5 GB in 17 WebContent tabs) | open since 63 days |
| 3.6 GB | ollama runner | holds a vision model (qwen2.5vl or glm-ocr blob), up 15 h |
| 2.4 GB | `mlx_vlm.server` | GLM-OCR-bf16 on :8081 |
| 1.4 GB | WindowServer | normal |
| 1.0 GB | chronod | widget daemon, partner of WidgetRenderer |
| 0.9 GB | aimeat node | |
| 0.6 GB ×9 | convey Python workers | |
| 0.6 GB | syncthing | |

**Verdict:** about 12 GB goes to three local AI model servers (mlx_lm, mlx_vlm, ollama). The two OCR/vision ones partly do the same job. Another ~11 GB is cruft from 63 days of uptime: WidgetRenderer and chronod, plus Safari and its tabs.
**Cheap wins:** kill WidgetRenderer_Activities and chronod (launchd respawns them small): about 6 GB back. Quit Safari: about 5.5 GB. Use either ollama or mlx_vlm for OCR, not both: 2.4–3.6 GB. Restart the model servers only through Cloudcity-Boot.
