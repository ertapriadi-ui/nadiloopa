"""
NADILOOPA Original Music & SFX Generator (Zero External Dependencies)
Synthesizes warm Indonesian-inspired bamboo marimba / gamelan-timbre stereo WAV loops
and 17 distinct musical SFX events at 44,100 Hz 16-bit PCM.
"""
import math
import os
import random
import struct
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MUSIC_DIR = os.path.join(ROOT, "assets", "audio", "music")
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")
SR = 44100

for d in (MUSIC_DIR, SFX_DIR):
    os.makedirs(d, exist_ok=True)


def midi_to_hz(m):
    return 440.0 * (2.0 ** ((m - 69.0) / 12.0))


def write_stereo_wav(path, left, right, peak_target=0.82):
    n = min(len(left), len(right))
    mx = 1e-6
    for i in range(n):
        v = max(abs(left[i]), abs(right[i]))
        if v > mx:
            mx = v
    gain = min(1.0, peak_target / mx) if mx > peak_target else 1.0
    # Soft limiter + 16-bit quantization
    raw = bytearray(n * 4)
    idx = 0
    for i in range(n):
        ls = math.tanh(left[i] * gain)
        rs = math.tanh(right[i] * gain)
        li = max(-32767, min(32767, int(ls * 32767.0)))
        ri = max(-32767, min(32767, int(rs * 32767.0)))
        struct.pack_into("<hh", raw, idx, li, ri)
        idx += 4
    with wave.open(path, "wb") as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(bytes(raw))
    rms = math.sqrt(sum((left[i] * gain) ** 2 + (right[i] * gain) ** 2 for i in range(0, n, 8)) / (2 * (n // 8 + 1)))
    print(f"Wrote {os.path.basename(path)}: {n / SR:.2f}s, peak={min(1.0, mx * gain):.3f}, rms={rms:.3f}")


def add_bamboo_marimba(buf_l, buf_r, t0, freq, dur, amp=0.28, pan=0.0):
    """Original woody bamboo calung/marimba resonator with soft mallet transient."""
    i0 = int(t0 * SR)
    n = int(dur * SR)
    lg = amp * math.cos((pan + 1.0) * math.pi * 0.25)
    rg = amp * math.sin((pan + 1.0) * math.pi * 0.25)
    two_pi = 2.0 * math.pi
    for k in range(n):
        idx = i0 + k
        if idx >= len(buf_l):
            break
        t = k / SR
        attack = 1.0 - math.exp(-t / 0.004)
        env1 = math.exp(-t / (dur * 0.42))
        env2 = math.exp(-t / (dur * 0.14))
        env3 = math.exp(-t / 0.025)
        sig = (
            math.sin(two_pi * freq * t) * env1 * 0.72
            + math.sin(two_pi * freq * 2.0 * t + 0.3) * env2 * 0.24
            + math.sin(two_pi * freq * 3.98 * t) * env3 * 0.14
        ) * attack
        buf_l[idx] += sig * lg
        buf_r[idx] += sig * rg


def add_warm_pad(buf_l, buf_r, t0, freq, dur, amp=0.10, pan=0.0):
    i0 = int(t0 * SR)
    n = int(dur * SR)
    lg = amp * math.cos((pan + 1.0) * math.pi * 0.25)
    rg = amp * math.sin((pan + 1.0) * math.pi * 0.25)
    two_pi = 2.0 * math.pi
    fade = min(0.18, dur * 0.3)
    for k in range(n):
        idx = i0 + k
        if idx >= len(buf_l):
            break
        t = k / SR
        env = min(1.0, t / fade) * min(1.0, (dur - t) / fade)
        sig = (
            math.sin(two_pi * freq * t) * 0.65
            + math.sin(two_pi * freq * 2.0 * t) * 0.18
            + math.sin(two_pi * freq * 0.998 * t) * 0.17
        ) * env
        buf_l[idx] += sig * lg
        buf_r[idx] += sig * rg


def add_soft_kendang_tap(buf_l, buf_r, t0, f_start, f_end, dur=0.14, amp=0.22, pan=0.0, rng=None):
    """Organic hand-drum / bamboo tap texture."""
    i0 = int(t0 * SR)
    n = int(dur * SR)
    lg = amp * math.cos((pan + 1.0) * math.pi * 0.25)
    rg = amp * math.sin((pan + 1.0) * math.pi * 0.25)
    phase = 0.0
    for k in range(n):
        idx = i0 + k
        if idx >= len(buf_l):
            break
        t = k / SR
        u = t / dur
        f = f_end + (f_start - f_end) * math.exp(-u * 6.0)
        phase += 2.0 * math.pi * f / SR
        env = math.exp(-u * 5.2) * (1.0 - math.exp(-t / 0.003))
        noise = (rng.uniform(-1.0, 1.0) if rng else 0.0) * math.exp(-u * 14.0) * 0.18
        sig = (math.sin(phase) + noise) * env
        buf_l[idx] += sig * lg
        buf_r[idx] += sig * rg


def add_shaker_tick(buf_l, buf_r, t0, amp=0.05, pan=0.25, rng=None):
    i0 = int(t0 * SR)
    n = int(0.05 * SR)
    lg = amp * math.cos((pan + 1.0) * math.pi * 0.25)
    rg = amp * math.sin((pan + 1.0) * math.pi * 0.25)
    prev = 0.0
    for k in range(n):
        idx = i0 + k
        if idx >= len(buf_l):
            break
        t = k / SR
        env = math.exp(-t / 0.012) * (1.0 - math.exp(-t / 0.002))
        w = rng.uniform(-1.0, 1.0)
        hp = w - prev * 0.85
        prev = w
        sig = hp * env
        buf_l[idx] += sig * lg
        buf_r[idx] += sig * rg


def apply_loop_tail_wrap(buf_l, buf_r, total_len):
    """Wrap overflow tail past total_len back into the start for seamless looping."""
    extra = len(buf_l) - total_len
    for i in range(extra):
        buf_l[i % total_len] += buf_l[total_len + i]
        buf_r[i % total_len] += buf_r[total_len + i]
    return buf_l[:total_len], buf_r[:total_len]


def gen_bgm_menu():
    """Original Menu Theme: Warm, cheerful tropical bamboo marimba (108 BPM, 16 bars -> ~17.78s seamless loop)."""
    bpm = 108.0
    beat = 60.0 / bpm
    bars = 8
    total_dur = bars * 4 * beat
    total_n = int(round(total_dur * SR))
    pad_n = total_n + SR
    bl = [0.0] * pad_n
    br = [0.0] * pad_n
    rng = random.Random(101)

    # C major / Pelog-inspired warm pentatonic chords: Cmaj7 -> Am7 -> Fmaj7 -> G6
    chords = [
        [48, 55, 60, 64, 67],
        [45, 52, 60, 64, 67],
        [41, 48, 57, 60, 64],
        [43, 50, 55, 59, 64],
    ]
    melody_pattern = [
        [(0.0, 72), (0.5, 74), (1.0, 76), (2.0, 79), (2.5, 76), (3.0, 74), (3.5, 72)],
        [(0.0, 76), (1.0, 72), (1.5, 74), (2.0, 79), (3.0, 81), (3.5, 79)],
        [(0.0, 77), (0.5, 76), (1.0, 72), (2.0, 74), (2.5, 76), (3.0, 72)],
        [(0.0, 74), (0.5, 76), (1.0, 79), (2.0, 76), (2.5, 74), (3.0, 72)],
    ]

    for bar in range(bars):
        bt = bar * 4.0 * beat
        ch = chords[bar % len(chords)]
        # Warm soft bass + pad
        add_warm_pad(bl, br, bt, midi_to_hz(ch[0]), 4.0 * beat, amp=0.14, pan=-0.1)
        add_warm_pad(bl, br, bt, midi_to_hz(ch[2]), 4.0 * beat, amp=0.07, pan=0.15)
        add_warm_pad(bl, br, bt, midi_to_hz(ch[3]), 4.0 * beat, amp=0.06, pan=-0.15)

        # Gentle arpeggiated bamboo calung accompaniment
        for step in range(8):
            note = ch[1 + (step % 4)]
            pan = -0.35 if (step % 2 == 0) else 0.35
            add_bamboo_marimba(bl, br, bt + step * 0.5 * beat, midi_to_hz(note), 0.38, amp=0.14, pan=pan)

        # Cheerful lead melody
        mp = melody_pattern[bar % len(melody_pattern)]
        for offset, m in mp:
            m_use = m + (12 if bar >= 4 and offset in (2.0, 3.0) else 0)
            add_bamboo_marimba(bl, br, bt + offset * beat, midi_to_hz(m_use), 0.52, amp=0.22, pan=0.05)

        # Organic percussion
        add_soft_kendang_tap(bl, br, bt + 0.0 * beat, 130.0, 62.0, 0.16, 0.22, -0.05, rng)
        add_soft_kendang_tap(bl, br, bt + 1.5 * beat, 175.0, 88.0, 0.11, 0.13, 0.20, rng)
        add_soft_kendang_tap(bl, br, bt + 2.0 * beat, 135.0, 65.0, 0.15, 0.18, -0.05, rng)
        for s in range(8):
            if s % 2 == 1:
                add_shaker_tick(bl, br, bt + s * 0.5 * beat, amp=0.045, pan=0.3, rng=rng)

    bl, br = apply_loop_tail_wrap(bl, br, total_n)
    write_stereo_wav(os.path.join(MUSIC_DIR, "bgm_menu_tropika.wav"), bl, br, peak_target=0.76)


def gen_bgm_gameplay():
    """Original Gameplay Loop: Charming, low-fatigue, rhythmically engaging F-major pentatonic pulse (104 BPM, 16 bars)."""
    bpm = 104.0
    beat = 60.0 / bpm
    bars = 16
    total_dur = bars * 4 * beat
    total_n = int(round(total_dur * SR))
    pad_n = total_n + SR
    bl = [0.0] * pad_n
    br = [0.0] * pad_n
    rng = random.Random(202)

    # F major pentatonic: F, G, A, C, D (gentle warm puzzle groove)
    bass_prog = [41, 41, 45, 43, 41, 46, 48, 43]
    chords = [
        [53, 57, 60, 65],
        [53, 57, 62, 65],
        [57, 60, 64, 69],
        [55, 60, 62, 67],
    ]
    motifs = [
        [(0.0, 69), (1.0, 72), (1.5, 74), (2.5, 72), (3.0, 69)],
        [(0.0, 67), (0.5, 69), (1.5, 72), (2.0, 74), (3.0, 77)],
        [(0.0, 76), (1.0, 74), (2.0, 72), (2.5, 69), (3.5, 67)],
        [(0.0, 69), (1.0, 72), (2.0, 67), (3.0, 65)],
    ]

    for bar in range(bars):
        bt = bar * 4.0 * beat
        bnote = bass_prog[bar % len(bass_prog)]
        ch = chords[bar % len(chords)]

        add_warm_pad(bl, br, bt, midi_to_hz(bnote), 4.0 * beat, amp=0.12, pan=0.0)
        add_warm_pad(bl, br, bt, midi_to_hz(ch[1]), 4.0 * beat, amp=0.055, pan=-0.2)

        # Gentle interlocked marimba ostinato (low fatigue, no harsh highs)
        for step in range(8):
            if step in (0, 2, 3, 5, 6):
                n_idx = (step + bar) % len(ch)
                add_bamboo_marimba(bl, br, bt + step * 0.5 * beat, midi_to_hz(ch[n_idx]), 0.34, amp=0.13, pan=-0.28 if step % 2 == 0 else 0.28)

        # Light airy melody every 2nd/odd bar with gentle variation
        mt = motifs[bar % len(motifs)]
        for offset, m in mt:
            if bar >= 8 and offset == 0.0:
                add_bamboo_marimba(bl, br, bt + offset * beat, midi_to_hz(m + 12), 0.45, amp=0.11, pan=0.15)
            add_bamboo_marimba(bl, br, bt + offset * beat, midi_to_hz(m), 0.48, amp=0.16, pan=-0.10)

        # Soft heartbeat-inspired organic percussion groove (warm low kendang)
        add_soft_kendang_tap(bl, br, bt + 0.0 * beat, 118.0, 56.0, 0.15, 0.19, 0.0, rng)
        add_soft_kendang_tap(bl, br, bt + 0.75 * beat, 145.0, 75.0, 0.09, 0.09, 0.2, rng)
        add_soft_kendang_tap(bl, br, bt + 2.0 * beat, 120.0, 58.0, 0.14, 0.16, 0.0, rng)
        add_shaker_tick(bl, br, bt + 1.0 * beat, amp=0.032, pan=-0.35, rng=rng)
        add_shaker_tick(bl, br, bt + 3.0 * beat, amp=0.036, pan=0.35, rng=rng)

    bl, br = apply_loop_tail_wrap(bl, br, total_n)
    write_stereo_wav(os.path.join(MUSIC_DIR, "bgm_gameplay_nadi.wav"), bl, br, peak_target=0.68)


def gen_bgm_victory():
    """Original Victory Celebratory Theme (~6.8s bright tropical fanfare & sparkle)."""
    dur = 6.8
    total_n = int(dur * SR)
    bl = [0.0] * total_n
    br = [0.0] * total_n
    rng = random.Random(303)

    fanfare = [
        (0.00, 72, 0.35, 0.28, -0.2),
        (0.14, 76, 0.35, 0.28, 0.0),
        (0.28, 79, 0.35, 0.30, 0.2),
        (0.45, 84, 0.85, 0.36, 0.0),
        (0.75, 79, 0.35, 0.24, -0.25),
        (0.95, 84, 0.90, 0.35, 0.15),
        (1.30, 86, 0.40, 0.26, -0.15),
        (1.50, 88, 1.40, 0.38, 0.0),
    ]
    for t0, m, d, a, p in fanfare:
        add_bamboo_marimba(bl, br, t0, midi_to_hz(m), d, amp=a, pan=p)
        add_bamboo_marimba(bl, br, t0 + 0.01, midi_to_hz(m - 12), d, amp=a * 0.55, pan=-p)

    # Celebratory chord swell & sparkling arpeggio
    for m in (60, 64, 67, 72, 76):
        add_warm_pad(bl, br, 0.45, midi_to_hz(m), 5.6, amp=0.11, pan=0.0)

    arp = [72, 76, 79, 84, 88, 84, 79, 84, 88, 91, 96]
    for i, m in enumerate(arp):
        add_bamboo_marimba(bl, br, 2.1 + i * 0.22, midi_to_hz(m), 0.70, amp=0.20, pan=(i % 2 * 2 - 1) * 0.4)

    for beat_t in (0.0, 0.45, 0.95, 1.5, 2.2, 3.0):
        add_soft_kendang_tap(bl, br, beat_t, 160.0, 72.0, 0.14, 0.22, 0.0, rng)

    # Gentle fade-out at end
    fade_n = int(1.0 * SR)
    for i in range(fade_n):
        k = total_n - fade_n + i
        s = 1.0 - (i / fade_n)
        bl[k] *= s
        br[k] *= s

    write_stereo_wav(os.path.join(MUSIC_DIR, "bgm_victory_cerah.wav"), bl, br, peak_target=0.82)


def gen_bgm_boss_harmoni():
    """4th Original BGM: Energetic uplifting milestone / boss stage theme (118 BPM, 12 bars ~24.4s loop)."""
    bpm = 118.0
    beat = 60.0 / bpm
    bars = 12
    total_dur = bars * 4 * beat
    total_n = int(round(total_dur * SR))
    pad_n = total_n + SR
    bl = [0.0] * pad_n
    br = [0.0] * pad_n
    rng = random.Random(404)

    chords = [
        [43, 55, 59, 62, 67],
        [45, 57, 60, 64, 69],
        [41, 53, 57, 60, 65],
        [48, 60, 64, 67, 72],
    ]
    mel = [
        [(0.0, 74), (0.5, 76), (1.0, 79), (1.5, 81), (2.0, 79), (3.0, 74), (3.5, 76)],
        [(0.0, 77), (0.5, 76), (1.0, 74), (2.0, 79), (2.5, 81), (3.0, 84)],
        [(0.0, 81), (0.5, 79), (1.0, 76), (1.5, 74), (2.0, 76), (3.0, 72)],
        [(0.0, 74), (0.5, 79), (1.5, 84), (2.5, 83), (3.0, 81), (3.5, 79)],
    ]

    for bar in range(bars):
        bt = bar * 4.0 * beat
        ch = chords[bar % len(chords)]
        add_warm_pad(bl, br, bt, midi_to_hz(ch[0]), 4.0 * beat, amp=0.14, pan=0.0)
        add_warm_pad(bl, br, bt, midi_to_hz(ch[2]), 4.0 * beat, amp=0.06, pan=0.2)

        for step in range(8):
            note = ch[1 + (step % 4)]
            add_bamboo_marimba(bl, br, bt + step * 0.5 * beat, midi_to_hz(note), 0.30, amp=0.14, pan=-0.32 if step % 2 == 0 else 0.32)

        for off, m in mel[bar % len(mel)]:
            add_bamboo_marimba(bl, br, bt + off * beat, midi_to_hz(m), 0.42, amp=0.20, pan=0.08)

        add_soft_kendang_tap(bl, br, bt + 0.0 * beat, 138.0, 60.0, 0.14, 0.22, 0.0, rng)
        add_soft_kendang_tap(bl, br, bt + 1.0 * beat, 185.0, 92.0, 0.10, 0.14, -0.2, rng)
        add_soft_kendang_tap(bl, br, bt + 2.0 * beat, 142.0, 62.0, 0.14, 0.20, 0.0, rng)
        add_soft_kendang_tap(bl, br, bt + 3.0 * beat, 195.0, 96.0, 0.10, 0.15, 0.2, rng)
        for s in range(8):
            add_shaker_tick(bl, br, bt + s * 0.5 * beat, amp=0.04, pan=0.35 if s % 2 == 0 else -0.35, rng=rng)

    bl, br = apply_loop_tail_wrap(bl, br, total_n)
    write_stereo_wav(os.path.join(MUSIC_DIR, "bgm_boss_harmoni.wav"), bl, br, peak_target=0.72)


# --- 21 Distinct SFX Generators ---
def make_sfx(name, dur, render_fn, peak=0.80):
    n = int(dur * SR)
    bl = [0.0] * n
    br = [0.0] * n
    render_fn(bl, br, n)
    write_stereo_wav(os.path.join(SFX_DIR, f"{name}.wav"), bl, br, peak_target=peak)


def sfx_tone_sweep(bl, br, n, f0, f1, harm2=0.2, attack=0.004, decay=0.08, amp=0.6):
    phase = 0.0
    for i in range(n):
        t = i / SR
        u = i / max(1, n - 1)
        f = f0 + (f1 - f0) * u
        phase += 2.0 * math.pi * f / SR
        env = (1.0 - math.exp(-t / attack)) * math.exp(-t / decay)
        sig = (math.sin(phase) + math.sin(phase * 2.0) * harm2) * env * amp
        bl[i] += sig
        br[i] += sig


def generate_all_sfx():
    rng = random.Random(777)

    # 1. menu_button
    make_sfx("sfx_menu_button", 0.14, lambda l, r, n: (
        add_bamboo_marimba(l, r, 0.0, 680.0, 0.11, 0.55, 0.0),
        add_bamboo_marimba(l, r, 0.03, 920.0, 0.09, 0.35, 0.1)
    ))

    # 2. tile_select
    make_sfx("sfx_tile_select", 0.12, lambda l, r, n:
        add_bamboo_marimba(l, r, 0.0, midi_to_hz(72), 0.11, 0.60, 0.0)
    )

    # 3. chain_extend (clean neutral marimba pop; pitched dynamically in AudioManager)
    make_sfx("sfx_chain_extend", 0.13, lambda l, r, n:
        add_bamboo_marimba(l, r, 0.0, midi_to_hz(76), 0.12, 0.58, 0.0)
    )

    # 4. valid_release
    make_sfx("sfx_valid_release", 0.24, lambda l, r, n: (
        add_bamboo_marimba(l, r, 0.00, midi_to_hz(72), 0.16, 0.45, -0.2),
        add_bamboo_marimba(l, r, 0.05, midi_to_hz(79), 0.18, 0.50, 0.2)
    ))

    # 5. invalid_path
    make_sfx("sfx_invalid_path", 0.22, lambda l, r, n: (
        sfx_tone_sweep(l, r, n, 240.0, 145.0, harm2=0.35, attack=0.004, decay=0.07, amp=0.45),
        add_soft_kendang_tap(l, r, 0.02, 160.0, 90.0, 0.10, 0.25, 0.0, rng)
    ))

    # 6. match_small
    make_sfx("sfx_match_small", 0.34, lambda l, r, n: (
        add_bamboo_marimba(l, r, 0.00, midi_to_hz(74), 0.22, 0.46, -0.2),
        add_bamboo_marimba(l, r, 0.06, midi_to_hz(79), 0.24, 0.50, 0.2),
        add_bamboo_marimba(l, r, 0.12, midi_to_hz(84), 0.20, 0.42, 0.0)
    ))

    # 7. match_large
    make_sfx("sfx_match_large", 0.56, lambda l, r, n: (
        add_bamboo_marimba(l, r, 0.00, midi_to_hz(72), 0.28, 0.45, -0.35),
        add_bamboo_marimba(l, r, 0.05, midi_to_hz(76), 0.28, 0.45, 0.35),
        add_bamboo_marimba(l, r, 0.10, midi_to_hz(79), 0.30, 0.48, -0.2),
        add_bamboo_marimba(l, r, 0.16, midi_to_hz(84), 0.36, 0.52, 0.2),
        add_bamboo_marimba(l, r, 0.22, midi_to_hz(88), 0.32, 0.42, 0.0)
    ))

    # 8. endpoint_pulse
    def _pulse(l, r, n):
        sfx_tone_sweep(l, r, n, 220.0, 620.0, harm2=0.25, attack=0.005, decay=0.14, amp=0.50)
        add_bamboo_marimba(l, r, 0.04, midi_to_hz(84), 0.24, 0.40, 0.0)
    make_sfx("sfx_endpoint_pulse", 0.32, _pulse)

    # 9. shield_activate
    def _shield(l, r, n):
        for idx, m in enumerate((76, 80, 83, 88)):
            add_bamboo_marimba(l, r, idx * 0.05, midi_to_hz(m), 0.34, 0.45, (idx % 2 * 2 - 1) * 0.3)
        add_warm_pad(l, r, 0.0, midi_to_hz(64), 0.48, 0.24, 0.0)
    make_sfx("sfx_shield_activate", 0.52, _shield)

    # 10. shield_block
    def _block(l, r, n):
        add_soft_kendang_tap(l, r, 0.0, 340.0, 140.0, 0.16, 0.50, 0.0, rng)
        add_bamboo_marimba(l, r, 0.03, midi_to_hz(83), 0.28, 0.48, -0.25)
        add_bamboo_marimba(l, r, 0.08, midi_to_hz(88), 0.32, 0.52, 0.25)
    make_sfx("sfx_shield_block", 0.42, _block)

    # 11. hazard_warning
    def _warn(l, r, n):
        sfx_tone_sweep(l, r, n, 440.0, 390.0, harm2=0.45, attack=0.005, decay=0.09, amp=0.38)
        add_bamboo_marimba(l, r, 0.08, midi_to_hz(66), 0.14, 0.32, 0.0)
    make_sfx("sfx_hazard_warning", 0.24, _warn)

    # 12. hazard_trigger
    def _haz(l, r, n):
        add_soft_kendang_tap(l, r, 0.0, 210.0, 58.0, 0.26, 0.65, 0.0, rng)
        sfx_tone_sweep(l, r, n, 310.0, 105.0, harm2=0.55, attack=0.004, decay=0.14, amp=0.48)
    make_sfx("sfx_hazard_trigger", 0.36, _haz)

    # 13. tile_refill
    make_sfx("sfx_tile_refill", 0.20, lambda l, r, n: (
        add_soft_kendang_tap(l, r, 0.00, 260.0, 140.0, 0.08, 0.28, -0.2, rng),
        add_bamboo_marimba(l, r, 0.03, midi_to_hz(69), 0.12, 0.25, 0.1),
        add_bamboo_marimba(l, r, 0.07, midi_to_hz(74), 0.11, 0.22, -0.1)
    ))

    # 14. score_popup
    make_sfx("sfx_score_popup", 0.22, lambda l, r, n: (
        add_bamboo_marimba(l, r, 0.00, midi_to_hz(84), 0.15, 0.36, -0.15),
        add_bamboo_marimba(l, r, 0.05, midi_to_hz(91), 0.16, 0.40, 0.15)
    ))

    # 15. victory
    def _vic(l, r, n):
        for i, m in enumerate((72, 76, 79, 84, 88)):
            add_bamboo_marimba(l, r, i * 0.075, midi_to_hz(m), 0.45, 0.45, (i % 2 * 2 - 1) * 0.25)
    make_sfx("sfx_victory", 0.85, _vic)

    # 16. defeat
    def _def(l, r, n):
        for i, m in enumerate((67, 64, 60, 55)):
            add_bamboo_marimba(l, r, i * 0.13, midi_to_hz(m), 0.38, 0.42, (i % 2 * 2 - 1) * 0.15)
        add_warm_pad(l, r, 0.2, midi_to_hz(55), 0.65, 0.22, 0.0)
    make_sfx("sfx_defeat", 0.90, _def)

    # 17. level_transition
    def _trans(l, r, n):
        sfx_tone_sweep(l, r, n, 330.0, 660.0, harm2=0.15, attack=0.01, decay=0.16, amp=0.32)
        add_shaker_tick(l, r, 0.02, 0.12, -0.25, rng)
        add_shaker_tick(l, r, 0.09, 0.10, 0.25, rng)
    make_sfx("sfx_level_transition", 0.32, _trans)

    # 18. loop_form (Nadi Loop golden resonance)
    def _loop(l, r, n):
        for idx, m in enumerate((72, 76, 79, 84, 88, 91)):
            add_bamboo_marimba(l, r, idx * 0.035, midi_to_hz(m), 0.42, 0.44, (idx % 2 * 2 - 1) * 0.32)
        add_warm_pad(l, r, 0.0, midi_to_hz(72), 0.55, 0.25, 0.0)
    make_sfx("sfx_loop_form", 0.62, _loop)

    # 19. ability_cast (Botanical Tactical Ability chime)
    def _cast(l, r, n):
        sfx_tone_sweep(l, r, n, 440.0, 880.0, harm2=0.20, attack=0.006, decay=0.14, amp=0.35)
        for idx, m in enumerate((79, 84, 88)):
            add_bamboo_marimba(l, r, 0.04 + idx * 0.055, midi_to_hz(m), 0.28, 0.42, (idx - 1) * 0.25)
    make_sfx("sfx_ability_cast", 0.44, _cast)

    # 20. combo_banner (Celebratory 5+ combo shimmer)
    def _combo(l, r, n):
        for idx, m in enumerate((76, 81, 84, 88, 93)):
            add_bamboo_marimba(l, r, idx * 0.045, midi_to_hz(m), 0.30, 0.40, (idx % 2 * 2 - 1) * 0.25)
    make_sfx("sfx_combo_banner", 0.52, _combo)

    # 21. star_pop (Victory star reveal pop)
    make_sfx("sfx_star_pop", 0.24, lambda l, r, n: (
        add_bamboo_marimba(l, r, 0.00, midi_to_hz(84), 0.16, 0.48, -0.1),
        add_bamboo_marimba(l, r, 0.04, midi_to_hz(91), 0.18, 0.46, 0.1)
    ))


def main():
    gen_bgm_menu()
    gen_bgm_gameplay()
    gen_bgm_victory()
    gen_bgm_boss_harmoni()
    generate_all_sfx()


if __name__ == "__main__":
    main()
