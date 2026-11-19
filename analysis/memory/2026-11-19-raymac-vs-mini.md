# memhogs: RayMac vs Mini — 2026-11-19 21:41

RayMac (18 GB): memory is tight. 23% free, and swap is 29.0 of 29.7 GB full. Process memory adds up to 88 GB on an 18 GB machine, most of it compressed or swapped out. Safari content processes take 50.2 GB across 206 processes (tabs, plus Mail and other apps that use WebKit). Next come Sublime Text at 7.1 GB, WindowServer at 6.0 GB, 11 `claude` sessions at 4.5 GB, Finder at 1.9 GB and Mail at 1.7 GB. The 7.4 GB `mlx_w…` Python process from the earlier run is gone.

Mini (32 GB): healthy. 45% free; swap fell from 12.6 GB to 5.1 GB after the kills. AI model servers take about 13.4 GB: mlx_lm Qwen3-4B 7.4 GB (5.5 → 6.8 → 7.4 GB in 17 minutes, still growing), ollama 3.6 GB, mlx_vlm GLM-OCR 2.4 GB. Everything else is under 1.5 GB.

## Is 681 Safari tabs enough for 50 GB? Yes.
There are 681 tabs (433 + 248) and 206 WebContent processes; Safari runs tabs from the same site in one process. 50.2 GB ÷ 681 ≈ 74 MB per tab, an ordinary size for a modern web page. Process footprint also counts memory that is compressed or swapped out, which is how 50 GB "fits" in 18 GB of RAM: it is what fills the 29 GB swap. A background tab that has been discarded still has some memory charged to it.
