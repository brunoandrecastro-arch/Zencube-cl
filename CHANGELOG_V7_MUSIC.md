# ZenCube v7 — Music playback reliability

- Play the Zen Garden background track from explicit signed 16-bit PCM (16 kHz, mono), bypassing WAV resource import and codec handling.
- Keep all existing translations, cube rules, AI and UI intact.
- Raise music volume from -12 dB to -2 dB and rebalance soundtrack for phone speakers with soft higher-pitched bells.
- Loop using the exact sample count; audible preview invokes the same music stream.
- Include the `.pcm` asset in Android exports using `include_filter`.
- Add Godot headless music-stream playback state test and update Python static/audio verification.
- A headless test cannot confirm sound from actual Android speakers: test on a real handset.
