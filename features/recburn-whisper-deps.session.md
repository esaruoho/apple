# Recburn Whisper dependency repair

Esa reported that recburn saved the recording and flattened video but subtitle generation failed: Numba 0.63.1 rejected NumPy 2.5.3. He then requested updating both ~/work/apple-rec and ~/work/apple so recburn works.

The approved repair updated Numba to 0.67.0 and llvmlite to 0.49.0, leaving NumPy unchanged. Real transcription passed. The installer now installs compatible versions together, chooses the existing Whisper script's interpreter, and checks CLI startup, ffmpeg, and JIT compilation before claiming readiness. --break-system-packages is an explicit opt-in for Homebrew-managed Python. Full installer mutation remains graded built; the installed dependency repair and --check path were exercised.

Verification: both installers passed --check; both repo binaries transcribed the user's real clip. Apple subtitle burn-in passed with normal macOS framework access after a sandboxed AVFoundation export crashed. No fresh screen capture was made; the supplied app-audio track was silent and frame drops were separate performance warnings. A NumPy/Numba-first diagnostic caused duplicate OpenMP initialization; the real Whisper import order passed without an unsafe override. The user approved updating apple-rec outside the workspace. The report-card machinery was installed there as required by the global report-card rule.

## How to get back

Transcript: `file:///Users/esaruoho/.codex/sessions/2026/10/02/rollout-2026-10-02T13-00-07-01a0fc0e-8c2f-71e3-abc7-08f34a4a411f.jsonl`. Session ID: `01a0fc0e-8c2f-71e3-abc7-08f34a4a411f`; resume: `codex --resume 01a0fc0e-8c2f-71e3-abc7-08f34a4a411f`. Verified transcript start: 2026-10-02T10:00:07.016Z (13:00:07 EEST). Bundled snapshot: [raw](recburn-whisper-deps.transcript.jsonl), [readable](recburn-whisper-deps.transcript.md). Repair timestamp verified: 2026-10-02 13:03:02 EEST. Card: [recburn-whisper-deps.feature](recburn-whisper-deps.feature). Repair evidence: [recburn-numpy-repair.md](../analysis/recburn-numpy-repair.md).
