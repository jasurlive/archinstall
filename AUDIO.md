# AUDIO.md: clear voice calls on the laptop mic and speakers

Notes on fixing **echo in Telegram video/voice calls** on the HP laptop
(Realtek ALC285, AMD Ryzen HD Audio) and how to tune the result.

## The problem

The built-in mic sits right next to the built-in speakers. The other person's
voice came out of the speakers, went back into the mic, and they heard
themselves echo. PipeWire had no echo cancellation, and Telegram's own wasn't
enough.

## The fix

Two PipeWire config files in `config/pipewire/pipewire.conf.d/`:

| File | What it does |
|---|---|
| `60-echo-cancel.conf` | WebRTC echo cancellation and noise suppression (`libpipewire-module-echo-cancel`) |
| `70-call-tuning.conf` | Voice EQ, compressor and limiter for the mic; voice EQ for the speakers |

Extra package needed: **`swh-plugins`** (compressor `sc4m` and lookahead
limiter). It's in `packages/pacman.txt`. `webrtc-audio-processing-1` comes with PipeWire.

### Signal chain

```
MIC:      laptop mic -> echo cancel + noise suppression -> EQ -> compressor -> limiter -> "HD VOICE"
SPEAKER:  apps -> "HD SPEAKER" (echo-cancel reference) -> voice EQ -> laptop speakers
```

### Devices you'll see

| Name | Use it? |
|---|---|
| **HD VOICE** | ✅ Mic for calls (default input) |
| **HD SPEAKER** | ✅ Output for calls (choose it in Telegram) |
| HD VOICE (internal, do not select) | ❌ Middle of the chain; skips the EQ and compressor |
| HD SPEAKER (internal EQ, do not select) | ❌ Bypasses echo cancellation, so echo comes back |
| Ryzen HD Audio Controller | Speakers: default output for music. Mic: raw, unprocessed |

## Setup after a fresh install

```bash
systemctl --user restart pipewire pipewire-pulse wireplumber

pactl set-default-source call-mic                                  # HD VOICE
pactl set-default-sink alsa_output.pci-0000_04_00.6.analog-stereo  # music: plain speakers
pactl set-sink-volume echo-cancel-sink 100%                        # HD SPEAKER at full, set call volume in Telegram
pactl set-sink-volume alsa_output.pci-0000_04_00.6.analog-stereo 100%
pactl set-source-volume alsa_input.pci-0000_04_00.6.analog-stereo 40%  # raw mic sensitivity
```

Then in **Telegram → Settings → Advanced → Call settings**:
**Output = HD SPEAKER**, **Input = HD VOICE**. Pick them by name, not "Default".

WirePlumber remembers defaults and volumes across reboots.

> **Another machine?** The configs name this laptop's hardware
> (`alsa_input/alsa_output.pci-0000_04_00.6.analog-stereo`). Run
> `pactl list short sources` / `pactl list short sinks` and change the
> `target.object` lines in both files to match.

## Why it's set up this way (lessons learned)

- **Music and calls use separate outputs.** The speaker EQ cuts bass below
  140 Hz and lowers the level by 2 dB, which is good for voices and bad for
  music. Music plays on the plain speakers; only Telegram uses HD SPEAKER.
  Pause music during calls, because echo cancel doesn't know about it.
- **HD SPEAKER is required.** Echo cancel needs an exact copy of what the
  speakers play. "Monitor mode" (no HD SPEAKER, using a copy of the output)
  was tried first and leaked echo in bursts.
- **WebRTC auto gain (AGC) is off.** It kept changing the hardware mic volume
  and boosted leftover echo between sentences. The compressor does that job instead.
- **Testing with two devices in the same room causes endless echo.** The
  laptop mic hears the phone speaker (and the other way round), and no echo
  canceller can fix that. Test from another room or with headphones on one side.
- **Don't stack volumes.** Keep the internal EQ and the Ryzen hardware output
  at 100%, and control volume with the HD SPEAKER / music slider.

## Tuning

### Live, no restart

```bash
pactl set-sink-volume echo-cancel-sink 80%                              # call speaker volume
pactl set-source-volume alsa_input.pci-0000_04_00.6.analog-stereo 40%   # raw mic sensitivity
```
Or use `pavucontrol`. Only change **HD SPEAKER** and the **Ryzen** devices.

### Mic sound (`70-call-tuning.conf`, "HD VOICE" section)

| Setting | Default | Effect |
|---|---|---|
| `"Makeup gain (dB)"` | 8.0 | How loud others hear you |
| `"Threshold level (dB)"` | -24.0 | Where leveling starts. Higher (-20) = less squashing, less background noise lifted |
| `"Ratio (1:n)"` | 3.0 | Leveling strength. 2 = gentle, 4 = strong |
| `name = pres` → `"Gain"` | 3.0 | Presence and clarity at 3 kHz. Too high = harsh |
| `name = box` → `"Gain"` | -3.0 | Laptop "boxiness" at 300 Hz |
| `name = hp` → `"Freq"` | 100.0 | Rumble cut. Raise to 120 for fan or desk noise |
| `"Limit (dB)"` | -1.0 | Hard ceiling. Loud moments never distort |

### Speaker sound (`70-call-tuning.conf`, "HD SPEAKER EQ" section)

| Setting | Default | Effect |
|---|---|---|
| `name = gain` → `"Mult"` | 0.8 | Level (0.8 = -2 dB headroom). 1.0 = louder, may distort |
| `name = voice` → `"Gain"` | 3.0 | Voice clarity at 2.5 kHz |
| `name = hp` → `"Freq"` | 140.0 | Bass cut. Lower = more bass, more distortion |
| `name = mud` → `"Gain"` | -2.5 | Muddiness at 400 Hz |

### Echo cancel (`60-echo-cancel.conf`)

`webrtc.noise_suppression = true|false`. Leave the rest alone.

### Apply changes

```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
```
Then restart Telegram. Change one value at a time, 1–2 dB per step. If a
typo breaks a file, the HD devices disappear; fix it and restart.

### Troubleshooting

- **Echo is back:** Telegram's output was probably reset to Default or the
  Ryzen device. Set it to HD SPEAKER again.
- **Check the mic chain is alive:** `pw-link -l | grep -A2 echo-cancel`
- **Errors:** `journalctl --user -u pipewire -b | grep -iE 'error|fail'`
- **Optional:** `sudo pacman -S rtkit` gives PipeWire realtime priority and
  steadier timing for echo cancel.

## Related: volume and brightness keys

`config/hypr/Scripts/accel-step.sh` is bound in `keybind.lua` with
`repeating = true`. A tap changes 1%. Holding speeds up: 1% → 2% after 0.4 s
→ 3% after 0.8 s → 5% after 1.4 s. Volume stops at 100%, and nothing keeps
changing after you let go. To tune it, edit the `held < …` lines in the
script, or `repeat_delay`/`repeat_rate` in `inputs.lua`.
