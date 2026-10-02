# Recburn Whisper dependency repair

Verified 2026-10-02 at 13:03 EEST. The user's recording and flattened movie saved; subtitle generation failed while importing Whisper. Installed Numba 0.63.1 rejected installed NumPy 2.5.3 before transcription began.

Updated the Python interpreter used by `/opt/homebrew/bin/whisper`: Numba 0.63.1 → 0.67.0 and llvmlite 0.46.0 → 0.49.0. Kept NumPy 2.5.3 and openai-whisper 20250625. No recburn source changes.

Repair command (approved because it writes outside the workspace):

```sh
/opt/homebrew/bin/python3.14 -m pip install --only-binary=:all: --upgrade 'numba==0.67.0' --break-system-packages
```

Numba's official release notes document NumPy 2.5 support: https://numba.readthedocs.io/en/latest/release/0.67.0-notes.html

Verification: `whisper --help` exited 0; importing Whisper first (as its CLI does) followed by a Numba JIT sum returned 6; `pip check` reported no broken requirements. The real 10.16-second flattened recording transcribed using small.en, English, fp16 disabled, and two CPU threads, exiting 0 and writing `/private/tmp/recburn-numpy-check/2026-10-02-12-59-21-flat.srt`. Whisper decoded “Thank you.” Accuracy was not independently assessed. Subtitle burn-in was not rerun.

A diagnostic importing NumPy/Numba before Whisper aborted with duplicate OpenMP runtime initialization. Whisper's actual import order passed both compilation and real transcription. No unsafe OpenMP override was added.

The dropped-frame warning is a separate capture performance issue. The supplied log's app audio measurement of -inf indicates the measured system-audio track was silent; it is unrelated to the Python import failure.

## Installation and readiness checks

In `~/work/apple`, run `bin/recburn-install-deps --check` before recording to check the actual Whisper interpreter, CLI startup, ffmpeg, and Numba JIT compilation. To install/repair dependencies, run `bin/recburn-install-deps`; for Homebrew-managed Python, explicitly opt in with `bin/recburn-install-deps --break-system-packages`.

In `~/work/apple-rec`, the equivalent commands are `./install-deps.sh --check`, `./install-deps.sh`, and `./install-deps.sh --break-system-packages`. Both installers constrain Numba to `>=0.67,<0.68` and NumPy to `<2.6`, then verify the runtime. These constraints are the tested dependency family, not a guarantee that future upgrades cannot introduce other failures. An existing Whisper executable's absolute Python shebang is used so installation targets its interpreter. `RECBURN_PYTHON` can select another interpreter explicitly.

The English default model is `small.en` (`small` for other languages); transcription invokes the local `whisper` CLI directly. The older docs mentioning a `base` default or a whisp wrapper were stale.

Follow-up verification: both repo binaries transcribed the real recording and both installer checks passed. The Apple binary also exported a subtitled movie in five seconds with normal macOS framework access. An initial sandboxed AVFoundation export crashed with NSInvalidArgumentException; the approved unsandboxed retry succeeded. This was an export sandbox restriction in the test environment, not a remaining NumPy failure. No fresh screen recording was made.
