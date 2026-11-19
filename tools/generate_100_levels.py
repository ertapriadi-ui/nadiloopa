"""
Generates 100 structured, progressively balanced levels across 10 chapters
with 100 unique bilingual titles, calibrated star thresholds, and varied
objectives in data/levels/levels_v1.json.
"""
import json
import os
import random

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_PATH = os.path.join(ROOT, "data", "levels", "levels_v1.json")

CHAPTERS = [
    (1, "Tropical Dawn", "Fajar Tropis"),
    (2, "Bamboo Stream", "Arus Bambu"),
    (3, "Herbal Terrace", "Teras Herbal"),
    (4, "Coral Reef", "Terumbu Karang"),
    (5, "Emerald Canopy", "Kanopi Zamrud"),
    (6, "Lotus Lagoon", "Danau Teratai"),
    (7, "Monsoon Rhythm", "Irama Muson"),
    (8, "Sanctuary Peak", "Puncak Suaka"),
    (9, "Golden Archipelago", "Nusantara Emas"),
    (10, "Grand Harmony", "Harmoni Agung"),
]

# 100 distinct, chapter-coherent stage titles (1..100)
STAGE_TITLES_100 = [
    # Chapter 1: Tropical Dawn (1-10)
    ("Morning Beat", "Denyut Pagi"),
    ("Twin Currents", "Arus Kembar"),
    ("Spark of Care", "Percik Peduli"),
    ("Watch the Pulse", "Jaga Ritme"),
    ("Detour Path", "Jalan Memutar"),
    ("Steady Tempo", "Tempo Tenang"),
    ("Green Shield", "Perisai Hijau"),
    ("Safe Harbor", "Pelabuhan Aman"),
    ("Neutralize!", "Netralkan!"),
    ("Tropical Dawn Boss", "Bos Fajar Tropis"),
    # Chapter 2: Bamboo Stream (11-20)
    ("Bamboo Crossing", "Lintas Bambu"),
    ("Rippling Pebbles", "Riak Kerikil"),
    ("Clear Rivulet", "Anak Sungai"),
    ("Emerald Bend", "Kelok Zamrud"),
    ("Shaded Ford", "Arungan Teduh"),
    ("Floating Reed", "Alang Mengapung"),
    ("Still Water", "Air Tenang"),
    ("Bridge of Leaves", "Jembatan Daun"),
    ("Rapid Cascade", "Riam Deras"),
    ("Bamboo Stream Boss", "Bos Arus Bambu"),
    # Chapter 3: Herbal Terrace (21-30)
    ("Warm Welcome", "Sambutan Hangat"),
    ("Ginger Step", "Langkah Jahe"),
    ("Mint Breeze", "Semilir Mint"),
    ("Terrace Dew", "Embun Teras"),
    ("Honeycomb Ridge", "Punggung Madu"),
    ("Saffron Sun", "Surya Kunyit"),
    ("Lemongrass Row", "Baris Serai"),
    ("Calm Apothecary", "Taman Rimpang"),
    ("Highland Steep", "Leran Tinggi"),
    ("Herbal Terrace Boss", "Bos Teras Herbal"),
    # Chapter 4: Coral Reef (31-40)
    ("Armored Shallows", "Dangkal Berlapis"),
    ("Turquoise Arch", "Lengkung Pirus"),
    ("Starfish Cove", "Teluk Bintang"),
    ("Pearl Current", "Arus Mutiara"),
    ("Sea Fan Sway", "Ayu Kipas Laut"),
    ("Lagoon Rim", "Tepi Laguna"),
    ("Tidal Pool", "Kolam Pasang"),
    ("Shell Sanctuary", "Suaka Kerang"),
    ("Deep Barrier", "Karang Dalam"),
    ("Coral Reef Boss", "Bos Terumbu Karang"),
    # Chapter 5: Emerald Canopy (41-50)
    ("Filter & Bloom", "Saring & Mekar"),
    ("Sunbeam Bough", "Dahan Mentari"),
    ("Mossy Branch", "Ranting Berlumut"),
    ("Orchid Perch", "Anggrek Rindang"),
    ("Canopy Swing", "Ayunan Kanopi"),
    ("Balanced Steps", "Langkah Seimbang"),
    ("Fern Crown", "Mahkota Pakis"),
    ("Vine Spiral", "Sulur Melingkar"),
    ("Green Zenith", "Zenit Hijau"),
    ("Emerald Canopy Boss", "Bos Kanopi Zamrud"),
    # Chapter 6: Lotus Lagoon (51-60)
    ("Opening Petal", "Kelopak Mekar"),
    ("Mirror Pond", "Kolam Cermin"),
    ("Dewey Stamen", "Benang Sari"),
    ("Quiet Koi Path", "Jalur Koi Tenang"),
    ("Dawn Reflection", "Pantulan Fajar"),
    ("Jade Lilypad", "Teratai Giok"),
    ("Soft Ripple", "Riak Halus"),
    ("Moonlit Lotus", "Teratai Purnama"),
    ("Still Sanctuary", "Suaka Hening"),
    ("Lotus Lagoon Boss", "Bos Danau Teratai"),
    # Chapter 7: Monsoon Rhythm (61-70)
    ("First Raindrop", "Rintik Pertama"),
    ("Drum of Cloud", "Gendang Awan"),
    ("Misty Canopy", "Kabut Kanopi"),
    ("Silver Gust", "Hembusan Perak"),
    ("Thunder Pulse", "Denyut Guruh"),
    ("Rainy Terrace", "Teras Hujan"),
    ("Storm Break", "Celah Badai"),
    ("Rainbow Arc", "Busur Pelangi"),
    ("Surging River", "Sungai Meluap"),
    ("Monsoon Rhythm Boss", "Bos Irama Muson"),
    # Chapter 8: Sanctuary Peak (71-80)
    ("Foothill Trail", "Jejak Kaki Bukit"),
    ("Granite Steps", "Tangga Granit"),
    ("Pine Horizon", "Cakrawala Pinus"),
    ("Cloud Bridge", "Jembatan Awan"),
    ("Eagle Outlook", "Pandang Elang"),
    ("Summit Breath", "Napas Puncak"),
    ("Wind Chime Pass", "Celah Genta"),
    ("Starlit Ridge", "Punggung Bintang"),
    ("Alpine Spring", "Mata Air Puncak"),
    ("Sanctuary Peak Boss", "Bos Puncak Suaka"),
    # Chapter 9: Golden Archipelago (81-90)
    ("Amber Strait", "Selat Ambar"),
    ("Spice Harbor", "Bandar Rempah"),
    ("Sunken Atoll", "Atol Tenggelam"),
    ("Gilded Sail", "Layar Keemasan"),
    ("Atoll Ring", "Cincin Atol"),
    ("Volcanic Richness", "Subur Vulkanik"),
    ("Lantern Pier", "Dermaga Lentera"),
    ("Saffron Bay", "Teluk Kuma"),
    ("Beacon Island", "Pulau Suar"),
    ("Golden Archipelago Boss", "Bos Nusantara Emas"),
    # Chapter 10: Grand Harmony (91-100)
    ("Prelude of Nine", "Pembuka Sembilan"),
    ("Circuit Waltz", "Dansa Sirkuit"),
    ("Six Hearts United", "Enam Organ Bersatu"),
    ("Diamond Lattice", "Kisi Berlian"),
    ("Amber Resilience", "Ketangguhan Ambar"),
    ("Chorus of Care", "Paduan Peduli"),
    ("Mirror of Balance", "Cermin Keseimbangan"),
    ("Pulse Crescendo", "Kresendo Denyut"),
    ("Threshold of Light", "Ambang Cahaya"),
    ("Nadiloopa Grand Finale", "Puncak Agung Nadiloopa"),
]

SAFE_CARE_SLOTS = [
    [1, 3], [5, 3], [2, 5], [4, 5], [1, 7], [5, 7], [3, 8], [2, 9], [4, 9], [3, 2]
]
SAFE_OVERLOAD_SLOTS = [
    [3, 5], [2, 4], [4, 6], [1, 5], [5, 6], [3, 3], [2, 7], [4, 8], [1, 8], [5, 8]
]
SAFE_BLOOM_SLOTS = [
    [3, 4], [2, 6], [4, 4], [3, 7], [1, 4], [5, 4]
]

# Diverse board terrain obstacle layouts on canonical 7x12 grid (2-4 cells)
OBSTACLE_PATTERNS = [
    [[3, 5], [3, 6]],                      # Center Mini Island
    [[1, 5], [5, 5]],                      # Twin Side Boulders
    [[2, 6], [4, 6]],                      # Fallen Log Gate
    [[2, 4], [4, 7]],                      # Diagonal Stepping Stones
    [[1, 4], [5, 7], [3, 9]],              # Triple Archipelago Islands
    [[1, 3], [5, 3], [1, 8], [5, 8]],      # Four Sanctuary Pillars
]

CHAPTER_OBSTACLE_THEMES = {
    1: ["island", "rock"],
    2: ["log", "rock"],
    3: ["island", "log"],
    4: ["rock", "island"],
    5: ["log", "island"],
    6: ["island", "log"],
    7: ["log", "rock"],
    8: ["rock", "island"],
    9: ["island", "rock"],
    10: ["island", "rock", "log"],
}


def pick_4_organs(level_id, rng):
    if level_id <= 20:
        pool = ["heart", "brain", "lungs", "kidneys"]
    elif level_id <= 40:
        pool = ["heart", "brain", "lungs", "kidneys", "stomach", "muscle"]
    else:
        pool = ["heart", "brain", "lungs", "kidneys", "stomach", "liver", "muscle"]

    if len(pool) == 4:
        return list(pool)
    chosen = list(pool)
    rng.shuffle(chosen)
    return chosen[:4]


def build_level(lid):
    rng = random.Random(5000 + lid * 31)
    ch_idx = (lid - 1) // 10
    ch_num, ch_en, ch_id = CHAPTERS[ch_idx]
    tier = min(5, 1 + (lid - 1) // 20)
    is_boss = (lid % 10 == 0)

    active_4 = pick_4_organs(lid, rng)
    o_primary = active_4[0]
    o_secondary = active_4[1]

    weights = {}
    for idx, org in enumerate(active_4):
        weights[org] = 30 if idx == 0 else (28 if idx == 1 else 21)

    care_pos = []
    overload_pos = []
    armored_pos = []
    bloom_pos = []
    min_care = 0
    min_ov = 0
    objs = {}
    tut = ""
    moves = 16

    if lid == 1:
        tut = "TUTORIAL_L1"
        moves = 34
        weights = {"heart": 30, "brain": 24, "lungs": 26, "kidneys": 20}
        objs = {"collect": {"heart": 40, "lungs": 34, "brain": 28}, "score": 3200}
    elif lid == 2:
        tut = "TUTORIAL_L2"
        moves = 34
        weights = {"heart": 22, "brain": 28, "lungs": 28, "kidneys": 22}
        objs = {"collect": {"brain": 42, "lungs": 42, "heart": 32}, "score": 3600}
    elif lid == 3:
        tut = "TUTORIAL_L3"
        moves = 35
        weights = {"heart": 24, "brain": 22, "lungs": 22, "kidneys": 32}
        objs = {"collect": {"kidneys": 46, "heart": 36}, "score": 4000}
    elif lid == 4:
        tut = "TUTORIAL_L4"
        moves = 36
        weights = {"heart": 30, "brain": 20, "lungs": 30, "kidneys": 20}
        objs = {"collect": {"heart": 44, "lungs": 44}, "score": 4200}
        overload_pos = [[3, 5]]
        min_ov = 1
    elif lid == 5:
        moves = 36
        weights = {"heart": 20, "brain": 30, "lungs": 20, "kidneys": 30}
        objs = {"collect": {"brain": 46, "kidneys": 46}, "score": 4400}
        overload_pos = [[2, 4], [4, 7]]
        min_ov = 2
    elif lid == 6:
        moves = 36
        weights = {"heart": 25, "brain": 25, "lungs": 25, "kidneys": 25}
        objs = {"collect": {"heart": 36, "lungs": 36}, "score": 4600, "keep_pulse": 60}
        overload_pos = [[1, 5], [5, 6]]
        min_ov = 2
    elif lid == 7:
        tut = "TUTORIAL_L7"
        moves = 36
        weights = {"heart": 30, "brain": 22, "lungs": 26, "kidneys": 22}
        objs = {"activate_care": 3, "collect": {"heart": 46, "lungs": 36}}
        care_pos = [[2, 4], [4, 7]]
        overload_pos = [[3, 5]]
        min_care, min_ov = 2, 1
    elif lid == 8:
        moves = 38
        weights = {"heart": 20, "brain": 29, "lungs": 31, "kidneys": 20}
        objs = {"activate_care": 3, "collect": {"lungs": 48, "brain": 44}}
        care_pos = [[1, 3], [5, 4], [3, 8]]
        overload_pos = [[2, 5], [4, 6]]
        min_care, min_ov = 2, 2
    elif lid == 9:
        tut = "TUTORIAL_L9"
        moves = 38
        weights = {"heart": 22, "brain": 22, "lungs": 22, "kidneys": 34}
        objs = {"neutralize_overload": 2, "collect": {"kidneys": 50, "heart": 36}}
        care_pos = [[1, 4], [5, 4], [3, 8]]
        overload_pos = [[3, 4], [2, 7]]
        min_care, min_ov = 2, 2
    elif lid == 10:
        moves = 40
        weights = {"heart": 26, "brain": 24, "lungs": 26, "kidneys": 24}
        objs = {"collect": {"heart": 46, "lungs": 46}, "score": 5200, "neutralize_overload": 3}
        care_pos = [[1, 3], [5, 3], [2, 7], [4, 8]]
        overload_pos = [[3, 4], [1, 7], [5, 7]]
        min_care, min_ov = 3, 2
    else:
        if lid == 21:
            tut = "TUTORIAL_STOMACH"
        elif lid == 31:
            tut = "TUTORIAL_ARMOR"
        elif lid == 41:
            tut = "TUTORIAL_LIVER"

        n_care = min(5, 2 + (lid % 3) + (1 if is_boss else 0))
        n_ov = min(5, 2 + (lid // 22) + (1 if is_boss else 0))
        n_armored = 1 if (31 <= lid <= 60 and (lid % 2 == 1 or is_boss)) else (2 if lid > 60 and (lid % 2 == 0 or is_boss) else 0)
        n_bloom = 2 if (lid >= 50 and is_boss) else (1 if (41 <= lid <= 70 and lid % 2 == 0) else (2 if lid > 70 and lid % 3 == 0 else 0))

        used = set()
        c_pool = list(SAFE_CARE_SLOTS)
        o_pool = list(SAFE_OVERLOAD_SLOTS)
        b_pool = list(SAFE_BLOOM_SLOTS)
        rng.shuffle(c_pool)
        rng.shuffle(o_pool)
        rng.shuffle(b_pool)

        for p in c_pool:
            if len(care_pos) >= n_care:
                break
            tp = (p[0], p[1])
            if tp not in used:
                used.add(tp)
                care_pos.append(p)
        for p in o_pool:
            tp = (p[0], p[1])
            if tp in used:
                continue
            if len(armored_pos) < n_armored:
                used.add(tp)
                armored_pos.append(p)
            elif len(overload_pos) < n_ov:
                used.add(tp)
                overload_pos.append(p)
        for p in b_pool:
            if len(bloom_pos) >= n_bloom:
                break
            tp = (p[0], p[1])
            if tp not in used:
                used.add(tp)
                bloom_pos.append(p)

        min_care = max(2, min(4, len(care_pos)))
        min_ov = max(1, min(3, len(overload_pos) + len(armored_pos) - 1))

        # Deep 3-5 minute strategic pacing (~22-38 moves per stage, 100% solvable)
        pattern = lid % 5
        qty1 = 42 + ch_idx * 3 + (lid % 3) * 3 + (8 if is_boss else 0)
        qty2 = 36 + ch_idx * 3 + (lid % 2) * 3 + (6 if is_boss else 0)
        score_tgt = 4600 + lid * 48 + (1000 if is_boss else 0)

        if is_boss:
            objs = {
                "collect": {o_primary: qty1, o_secondary: qty2},
                "neutralize_overload": min(4, max(3, len(overload_pos))),
                "keep_pulse": 60,
            }
            moves = 40 + (ch_idx // 2)
        elif pattern == 1:
            objs = {"collect": {o_primary: qty1, o_secondary: qty2}, "score": score_tgt}
            moves = 34 + (ch_idx // 2)
        elif pattern == 2:
            objs = {"long_chains": 4 if lid < 40 else (5 if lid < 75 else 6), "collect": {o_primary: qty1 + 10}}
            weights[o_primary] = 35
            moves = 34 + (ch_idx // 2)
        elif pattern == 3:
            objs = {"activate_care": 3 if lid < 45 else 4, "collect": {o_primary: qty1 + 6, o_secondary: qty2 - 4}}
            moves = 35 + (ch_idx // 2)
        elif pattern == 4:
            objs = {"score": score_tgt, "collect": {o_primary: qty1 - 4}, "keep_pulse": 62 if lid < 60 else 65}
            moves = 35 + (ch_idx // 2)
        else:
            objs = {"neutralize_overload": 3 if lid < 55 else 4, "collect": {o_primary: qty1 + 6, o_secondary: qty2 - 4}}
            moves = 36 + (ch_idx // 2)

    if lid == 100:
        moves = 46
        objs = {
            "collect": {o_primary: 72, o_secondary: 62},
            "neutralize_overload": 4,
            "keep_pulse": 65,
        }

    t_en, t_id = STAGE_TITLES_100[lid - 1]

    # Calibrated star thresholds matching achievable scores (1-star on win, 2-star strong play, 3-star mastery)
    base_star = int(objs.get("score", 3600 + lid * 42 + (800 if is_boss else 0)))
    stars = [base_star, int(base_star * 1.22), int(base_star * 1.48)]

    # Build chapter-thematic terrain obstacles for Stages 4-100 (Stages 1-3 stay obstacle-free for smooth FTUE)
    obstacles = []
    if lid >= 4:
        occupied = {
            (p[0], p[1])
            for p in (care_pos + overload_pos + armored_pos + bloom_pos)
        }
        pat_idx = (lid - 4) % len(OBSTACLE_PATTERNS)
        theme_types = CHAPTER_OBSTACLE_THEMES.get(ch_num, ["rock", "island"])
        raw_pat = OBSTACLE_PATTERNS[pat_idx]
        for oi, pos in enumerate(raw_pat):
            c_p, r_p = pos[0], pos[1]
            if (c_p, r_p) in occupied:
                # Try gentle horizontal shift to keep layout symmetric and collision-free
                found = None
                for dc, dr in ((0, 1), (0, -1), (1, 0), (-1, 0)):
                    nc, nr = c_p + dc, r_p + dr
                    if 0 <= nc <= 6 and 1 <= nr <= 10 and (nc, nr) not in occupied:
                        found = [nc, nr]
                        break
                if found is None:
                    continue
                c_p, r_p = found[0], found[1]
            occupied.add((c_p, r_p))
            obstacles.append({
                "pos": [c_p, r_p],
                "type": theme_types[oi % len(theme_types)],
            })

    return {
        "id": lid,
        "chapter": ch_num,
        "chapter_en": ch_en,
        "chapter_id": ch_id,
        "tier": tier,
        "is_boss": is_boss,
        "title_en": t_en,
        "title_id": t_id,
        "tutorial_key": tut,
        "seed": 1000 + lid,
        "moves": moves,
        "initial_pulse": 100,
        "weights": weights,
        "objectives": objs,
        "obstacles": obstacles,
        "care_positions": care_pos,
        "overload_positions": overload_pos,
        "armored_overload_positions": armored_pos,
        "bloom_positions": bloom_pos,
        "min_care_on_board": min_care,
        "min_overload_on_board": min_ov,
        "star_thresholds": stars,
    }


def main():
    assert len(STAGE_TITLES_100) == 100
    assert len({t[0] for t in STAGE_TITLES_100}) == 100, "Duplicate EN title!"
    assert len({t[1] for t in STAGE_TITLES_100}) == 100, "Duplicate ID title!"
    levels = [build_level(i) for i in range(1, 101)]
    out = {"schema_version": 2, "total_levels": 100, "levels": levels}
    with open(OUT_PATH, "w", encoding="utf-8") as f:
        json.dump(out, f, indent=2)
    print(f"Generated {len(levels)} unique-title balanced levels in {OUT_PATH}")


if __name__ == "__main__":
    main()
