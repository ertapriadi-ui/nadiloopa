---
project: ATHEROGUARD - Save the Flow
status: APPROVED 100-LEVEL DEVELOPMENT GOAL / NOT A SHIPPED PRODUCT
revision: 2.0
created: 2026-11-18
engine: Godot 4.x stable (verify locally; prefer 4.7.2 if available)
platform_priority: Android APK, then optional iOS
language_default: en
languages: [en, id]
genre: one-finger arcade defense + light roguelite
success_metric: independently validated average fun rating >= 9.0/10; not a promised outcome
---

# ATHEROGUARD - SAVE THE FLOW: GAME GOAL AND DESIGN DOCUMENT

## 0. READ THIS FIRST

This document is the canonical design goal for a new, separate original game. V2 expands the final campaign to 100 levels and adds animated human lifestyle risk events, inflammatory/oxidative threat waves, and automated endogenous antioxidant defenses. Read `LEVEL_ROADMAP_100.md`, `LEVEL_MANIFEST_100.json`, and `EVENTS_AND_DEFENSE_V2.md` as mandatory adjuncts. Do NOT modify or overwrite the existing Nadiloopa project in the parent Games Development folder. The commercial name is provisional; do not finalize its logo, publish under it, or claim trademark availability without clearance. The user wants the agent to turn this goal into an actual polished, installable Android game built with Godot, not a concept presentation.

Priority order: (1) intuitive and satisfying controls, (2) intrinsically fun Clean-Unload-Survive loop, (3) readable threats and fair decisions, (4) stability and actual APK, (5) high-fidelity original artwork/music/SFX, (6) levels, replayability, and polish, (7) optional medical facts. A feature that lowers clarity or fun must be simplified or removed. The 9/10 score is an empirical target requiring external player tests, not a grade an AI is authorized to award itself.

## 1. NORTH STAR

### Elevator pitch
You play as a friendly macrophage inside the inner wall of an artery. Clear dying cells, manage cholesterol cargo, and use efflux opportunities while the artery's lumen becomes increasingly threatened by plaque. Survive waves of cardiovascular risk pressure, build satisfying cleanup combos, choose upgrades, and keep blood flowing. Too much lipid cargo turns the macrophage into a foam cell. An obstructed artery ends the run.

### Emotional loop
- First 5 seconds: clear something and receive a delightful sound/visual response.
- First 15 seconds: understand movement and that the vessel is being protected.
- First 45 seconds: notice growing threats and begin making choices.
- First 60-90 seconds: complete a wave and choose a meaningful upgrade.
- Within 4-8 minutes: complete a run, narrowly escape defeat, or learn from a fair loss.
- After a run: want to try a different ability build or beat a score.

### Design pillars
1. ONE-FINGER FUN: drag to move, auto-collect within range; no virtual joystick plus attack buttons.
2. VISIBLE CONSEQUENCES: plaque growth changes artery geometry; soundscape intensifies with danger.
3. HERO WITH A TRADE-OFF: beneficial cleanup versus harmful excess lipid load.
4. COMBOS OVER GRIND: success produces visibly and audibly delightful chain reactions.
5. FAIR PRESSURE: escalating waves and telegraphed hazards, never arbitrary no-warning instant death.
6. MEDICALLY RESPONSIBLE FICTION: inspired by real mechanisms without pretending to simulate a patient's disease quantitatively.
7. ORIGINAL IP WITH AN INDONESIAN TOUCH: warm tropical palette and original music inspired by Indonesian acoustic textures, internationally readable.

### Scope boundaries
- Main game is arcade defense, NOT a match-3 or 7x12 grid puzzle.
- Gameplay is offline single-player for v1.
- There is no user medical data, patient record, diagnosis, medical-device integration, account requirement, in-app purchase, or ad in the first playable build.
- Education appears as optional short fact cards after a wave; never compulsory quizzes in the action loop.

## 2. GAMEPLAY LOOP

### Core action: CLEAN / UNLOAD / SURVIVE
- CLEAN: move the macrophage through the playable intima region, auto-engulf nearby apoptotic-cell debris. Rapid sequential clears build Clean Streak multiplier and Resolution Charge.
- UNLOAD: uptake of modified lipid deposits causes a fictional intracellular Lipid Load meter to rise. Move to an available Efflux Zone (an abstract representation of apoA-I / HDL-assisted cholesterol efflux), stay briefly, and unload cargo. A timed high-load unload awards Perfect Efflux.
- SURVIVE: ignored debris, accumulated lipid deposits, and inflammation enlarge the abstract Plaque Burden meter and visibly protrude plaque into the lumen. Keep effective Flow Integrity above zero until the wave ends. In later levels, also manage a telegraphed Plaque Stability threat.

### Player control
- Single-finger drag moves the character in a smooth 2D arena; calculate finger-to-character offset so the sprite is not covered by the finger.
- Character never leaves the intima play polygon. Use collision clamping and soft easing, not abrupt snapping.
- Pickup occurs automatically within readable range; no tap spam or combat button.
- Use optional haptic feedback only when supported and user-enabled; no critical reliance on haptics.
- Movement must remain precise at 30 FPS on older phones; target 60 FPS on reference hardware.

### Arena anatomy and visual geography
Use a longitudinal cutaway of an artery adapted to portrait orientation. The moving RBCs are in the LUMEN, not the intima. A thin ENDOTHELIAL boundary separates lumen from the playable INTIMA, where the macrophage, retained/modified lipids, and apoptotic debris appear. A plaque mass forms in the wall and protrudes toward the lumen, visibly narrowing the blood-flow channel. Actual anatomical sizes and the rate of progression are deliberately stylized and time-compressed for entertainment.

There must be no implication that macrophages physically swim around in the bloodstream collecting ordinary LDL or RBCs. Optional tips should clarify that macrophages work in the artery wall and that LDL retention/modification is important.

### State variables (fictional game units, not clinical measurements)
- `lipid_load` 0..100: current macrophage cargo. Default safe range 0-69; alert 70-89; critical >=90; overloaded at 100.
- `plaque_burden` 0..100: cumulative unresolved threat. Growth morphs the plaque. Not the same as real percent diameter stenosis.
- `flow_integrity` 0..100: player-facing survival meter, derived from burden and events. Reaches zero at Flow Collapse.
- `resolution_charge` 0..100: earned by successful efferocytosis and clean streaks. At threshold it triggers Resolution Wave.
- `combo_multiplier`, `wave_time`, `wave_index`, `remaining_risk_events`, `plaque_stability` (advanced only).

Keep state separated from rendering. Parameter values must be externalized and tuned through playtests; initial ranges are illustrative game rules, not medical probabilities.

### Object classes
**Positive/required objectives:**
- Apoptotic Debris: collectible through contact/near-contact, yields positive score and Resolution Charge.
- Efflux Zone: available periodically or granted by an upgrade; removes Lipid Load over a short, clear interaction window.
- Resolution Orb: rare earned reward after a clean streak; modestly stabilizes future threat, not a magical immediate cure.

**Risk objects:**
- Modified Lipid Deposit: optional but tactically relevant cleanup target; removing it raises intracellular Lipid Load.
- Neglected Debris: if ignored, transitions through visible warning into a local inflammatory penalty.
- Oxidative Stress Field: local zone effect making lipid handling more dangerous for a short interval, clearly telegraphed.

**Not direct enemies:** smoking, hypertension, elevated LDL, diabetes/hyperglycemia, and systemic inflammation appear as between-wave ENVIRONMENT MODIFIERS that affect spawn rates, load, and plaque progression. Do not make them sentient monsters the macrophage eats.

### Foam cell failure state
If `lipid_load` reaches 100, animate the macrophage swelling with lipid droplets into a foam-cell state. Apply a fair consequence: temporarily disable the unit, slightly increase plaque burden, spawn a replacement playable macrophage, and reset cargo. Do NOT force immediate game over from one mistake, and do NOT imply this is the exact process or reversibility of foam-cell biology. Display a clear warning at 70 and 90 before threshold.

### Cholesterol efflux mechanic
Efflux Zones represent the cellular cholesterol export process in a game-friendly way. They should have a clear visual magnet/target cue and short, predictable duration. Avoid presenting HDL as a magic molecule that dissolves pre-existing plaque instantly. Changing the player's internal cargo is the primary effect; broader plaque benefit is only a modest, separately tuned game abstraction.

### Combos / satisfying mastery
- Clean Streak: collect N apoptotic-debris units within a short combo window; increasingly musical feedback and score multiplier.
- Perfect Efflux: reach an efflux zone when cargo is high but before overload; award charge/score and a brief satisfying discharge visual.
- Resolution Wave: earned via effective cleanup, emits a short luminous sweep that resolves nearby loose debris and briefly slows new inflammation. Not a literal cellular event.
- Last-Second Rescue: restore fictional flow above a critical threshold before the wave ends; big celebration without invalidating clinical realism.
- Distinctive reactions are tactile, immediate, and optional to skip/reduce for accessibility. Never delay input with long animations.

### Fairness contract
Every penalty needs a visible cause; each risk wave provides enough time to react; at least one safe route to an efflux zone must exist; player must never be forced to pick up lipid solely because the only passage is blocked; no invisible hitboxes or no-warning total occlusion. Restart promptly after failure. Prefer recoverable mistakes to sudden unjust death. Use deterministic seeds for debugging.

## 3. WAVE AND SESSION STRUCTURE

### Session goals
- Normal wave: 60-90 seconds early, up to ~120 seconds later.
- Typical run: 4-8 minutes (wave + upgrade selection), with a satisfying short standalone first level.
- Tutorial should be diegetic and interactive rather than a multi-screen lecture.
- Campaign: 100 complete stages, each startable, winnable, restartable, and saved.
- Endless Survival: optional once campaign and stable build exist; increasing waves, saved personal best, no unavoidable escalation spikes.

### Initial onboarding
- 0-10 sec: point at debris, drag into it, get immediate sparkle/pop and positive text.
- 10-25 sec: a modified lipid appears and raises Cargo visibly; indicate this before/after pickup.
- 25-40 sec: introduce an Efflux Zone; first unload should be easy and satisfying.
- 40-60 sec: visible plaque starts to grow; player's action can slow the process.
- 60-90 sec: first wave completes and the upgrade choice appears.
No mandatory dialogue before touching the screen. One teaching concept per moment.

### Campaign progression / 100-level plan
- Final shipped objective is **100 independently playable, saved, restartable and QA-validated levels in 10 thematic chapters of 10**, not 20. See authoritative full stage-by-stage specification `LEVEL_ROADMAP_100.md` and planning data `LEVEL_MANIFEST_100.json`.
- Chapters: L1-10 First Defenders, L11-20 Lipid Frontier, L21-30 Sweet Pressure, L31-40 Smoke Signals, L41-50 Pressure Waves, L51-60 Inflammation Highway, L61-70 Cellular Shields, L71-80 Risk Stack, L81-90 Unstable Plaque, L91-100 Save the Flow.
- Each chapter finale is a visually distinct, fair multi-wave encounter. Use 7 reusable cinematic types for adult smoking, recurring large meals/mukbang, repeated sugary drinks, hypertension, inactivity, combined overload, and gradual positive change. Never force a lengthy animation every time an event repeats.
- Events modulate arena risks: retained/modifed lipoproteins and foam burden, ROS **fields**, cytokine **signaling fields**, monocyte recruitment and efferocytosis load. These are metaphors of ongoing biological processes, NOT instantaneous disease after a single behavior.
- Add automated, resource-limited endogenous antioxidant defense companions inspired by SOD, catalase and glutathione peroxidase; they complement the macrophage, not replace it or imply that antioxidant supplements prevent heart attacks.
- `TRIPLE_OVERLOAD` (first major event by L76): repeated eating + sugary drink + smoking montage leads to a telegraphed three-phase encounter: Lipid Pressure, Oxidative Pressure, Inflammatory Echo, then recovery.
- Every chapter must add a genuinely new player decision or objective, not only change spawn counts. Retain one-finger movement and clean/unload/survive as the first 60 seconds of play.
- Keep prototype 3-wave -> 5-polished-stage gate -> campaign increments to 20, 40, 60, 80, 100. The full 100 remain the FINAL target; failing fun gates means improve core gameplay, not lower scientific standards or claim completion early.

### Late-stage acute event
At L81+ (after the earlier concept has been introduced safely), introduce a stylized, strongly telegraphed Plaque Stability system. When a fictional stability threshold is exceeded, a plaque disruption event may lead to an acute thrombotic occlusion challenge. Players must respond to a readable impending event, not an arbitrary random instant loss. In medicine, acute thrombosis can follow plaque rupture or erosion without a prior gradual progression to total luminal obstruction; do not represent all ACS as slowly reaching 100% stenosis. Keep any game intervention metaphorical, not a treatment recommendation.

### Upgrades (choose ONE of THREE after designated waves)
- Sweep Radius: increases debris pickup radius moderately.
- Efficient Efflux: shortens unload duration or increases unload rate.
- Agile Pseudopodia: improves movement speed and responsiveness.
- Efferocytosis Chain: slightly extends combo timer / bonus charge.
- Endothelial Guard: temporarily reduces the next hazard increment.
- Resolution Reserve: conserves charge between waves or improves charge gain.
Each choice should be meaningful, visible, and balanced. Avoid a single always-correct upgrade. Log win rates by upgrade to identify overpowered options.

## 4. DIFFICULTY AND FUN TUNING

Difficulty should come from a small number of overlapping meaningful decisions, not faster spawns indefinitely. Dynamically adjust only within transparent, reproducible bounds. Prioritize three states: confident cleanup, mounting threat, and earned recovery. Add peaks and valleys, not a straight line of frustration.

Game tuning variables must live in data files: spawn intervals, hazard duration, warning lead time, efflux cooldown, recovery speed, foam-cell penalties, combo windows, upgrade stats, and plaque animation response. Every tutorial level should teach exactly one new rule.

Use A/B prototypes with matched art and levels:
- A: basic cleaning / survival only.
- B: cleaning + Lipid Load + Efflux.
Keep B only if playtests show better enjoyment and manageable learning burden.

Optional advanced challenge modes should never block the relaxed campaign. Include pause, restart, sound and motion controls. No streak pressure based on real-life daily logins.

## 5. PREMIUM ART AND ANIMATION

Art direction: original soft 2.5D cartoon cell-world, polished and warm, high-contrast gameplay silhouettes, no gore or realistic medical distress. A macrophage should be memorable through translucent jelly-like shape, flexible pseudopodia, expressive eyes, animated lipid droplets, and clear changing load state. Plaque growth should be an elegant morph with visibly decreasing lumen; RBCs stream within the lumen, not through the play zone. The endothelium should be visually distinguishable without adding distracting medical labels.

Visual references are research only; do not copy UI, game art, branding, screenshots, character expressions, or audio from other games. The final game needs original source art masters (SVG or suitable high-resolution layered files), sprite atlases, appropriate compression, and a documented asset-license trail. No final emoji/stock placeholders.

Portrait reference 1080x2400. Game arena occupies the greatest practical area (~70-80% when appropriate), while a compact top HUD displays Flow, Cargo, Wave, and score. The macrophage must remain visible under thumb interactions via offset and visual trail. Respect Android cutouts, insets, gestures, and short screens; use square pixel-independent hitboxes as appropriate rather than fixed-pixel coordinates.

Responsive screenshots: 720x1600, 1080x1920, 1080x2400, 1440x3200. Provide accessible non-color-only cues: shape patterns, text, symbols, contrast, motion settings. Provide optional reduce motion, no rapid repetitive flashes, minimal shake, large touch targets.

Animations: macrophage locomotion, squeeze/stretch, uptake, efflux release, foam transformation, clean streak, resolution wave, plaque progression, blood-flow speed changes, risk warning, near-loss, victory, retry. Input must never be blocked by gratuitously long animations.

## 6. ORIGINAL MUSIC AND PROFESSIONAL SOUND

Audio identity: polished contemporary warm arcade, rhythmic pulses with subtle *original* bamboo/marimba/percussion/gamelan-inspired timbres. Do not copy traditional recordings or copyrighted melodies. The Indonesian influence should feel organic, not stereotyped. All generated, purchased, or recorded assets must have commercial permissions documented.

Provide at least:
- Main menu track: warm, memorable, loopable.
- Gameplay base track: unobtrusive, seamless looping.
- Threat layer: intensity adds percussion/bass and crossfades as danger increases.
- Victory and game-over short cues.
- 18+ distinct polished SFX events (pickup, chain, efflux, cargo warning, foam transformation, plaque growth, risk warning, upgrade, UI, victory, defeat, etc.).

Audio buses: Master, Music, SFX, UI; volume sliders and saved state. No clipping or severe loudness swings, no silent dummy assets, no unverified audio placeholders. Confirm audio sounds in actual game; test interruption/pause/resume.

## 7. UI / LANGUAGE / ACCESSIBILITY

English is the default; Indonesian is selectable in Settings and persists. Translate all UI, tutorial prompts, objective strings, upgrades, pause/settings, failure causes, and optional medical cards. Proper internationalization resources; no hardcoded strings embedded in logic. Names should be pronounceable globally. Suggested menu: Play, Campaign, Endless (after unlocked), How to Play, Settings, Credits. HUD: Flow, Lipid Load, Resolution Charge, Score, Time/Wave, Pause. Clear iconography over dense text.

First play must be possible without registration, connection, long narrative or consent walls. If collecting analytics in later tests, obtain appropriate consent and follow platform privacy policy; prefer local debug telemetry during early prototypes.

## 8. GAME ECONOMY AND CONTENT

No ads, paid upgrades, energy timers, subscriptions, gacha, or coercive engagement for the first APK. Campaign rewards unlock cosmetic macrophage variants, optional concise science cards, and backgrounds. Performance should be based on skill and interesting choices. Daily challenges are optional after retention validation, never a milestone prerequisite.

## 9. TECHNICAL DESIGN - GODOT

Use an official stable Godot 4.x release matching installed export templates; verify version on target computer before changing files. GDScript with static typing where practical. Use a renderer appropriate for test devices and measure CPU/GPU performance. Develop an Android portrait game with mouse input parity for testing on desktop. Target 60 FPS normal play on representative mid-range Android devices; no gameplay hitch over 100ms in routine interactions.

Suggested project modules:
- `GameDirector`: finite state transitions MENU/TUTORIAL/WAVE/UPGRADE/PAUSED/WIN/LOSS.
- `ArteryModel`: simulation-only lumen and plaque state, no visual coupling.
- `MacrophageController`: finger-offset movement, pickup/feedback, foam state.
- `DebrisSpawner` and `RiskDirector`: deterministic spawns and telegraph rules.
- `CargoSystem`: lipid accumulation, warning, efflux timing.
- `EfferocytosisSystem`: debris clearance, combo, resolution charge.
- `PlaqueSystem`: burden and optional stability; links to graphic deformation.
- `UpgradeManager`: card selection and modifier application.
- `WaveDirector`, `CampaignManager`, `SaveManager`, `AudioManager`, `LocalizationManager`, `AccessibilitySettings`.
- `TelemetryAdapter`: optional local anonymized event logs; no medical data.
- `MedicalFactCatalog`: opt-in factual cards with source and review status.

Use data-driven `.tres`/`.res` or JSON configuration for level and tuning parameters; stable seeded RNG. Keep simulation tick separate from rendering; ensure no overlap/double-trigger when resolving pickups. Include recovery when game pauses or app is backgrounded. Use versioned local saves and backward compatibility for minor iterations. Never embed release signing secrets in source control.

Core automated tests: movement bounds, auto-collection, cargo thresholds, efflux cooldown, combo state, foam-state transition, plaque growth, fair warning timers, stability event, win/loss, level state machine, save/load, localization, render responsiveness, audio triggers. Simulate at least hundreds of reproducible runs across seeds and varied upgrade builds, investigate soft-locks.

## 10. ANDROID BUILD AND DISTRIBUTION

Deliver actual installable debug-signed Android APK with package name using a development identifier, e.g. `com.studio.atheroguard.dev` (not the final brand identifier). Suggested artifact path `build/android/atheroguard_debug.apk`; also supply editable Godot project and setup documentation. Verify Godot export templates, OpenJDK 17, Android SDK/platform tools, and output signing. Use the official Godot exporting-for-Android guide: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html .

If `adb` and a device/emulator are accessible: install, launch, finish the interactive tutorial and at least one actual wave, verify efflux, trigger overload, restart and save/load, check logcat, inspect screenshots/audio. If no device/emulator available, run headless/editor/build/package validation and explicitly mark physical-device QA as UNVERIFIED. Do not fabricate device tests. Build an AAB only as an additional future store artifact; APK remains mandatory for the user.

## 11. PRODUCTION PHASES AND DECISION GATES

**Gate 0 - Environment and IP:** audit existing Drive and local files; create isolated AtheroGuard project, verify Godot stable SDK, document working-title/IP risks. Deliver plan and source-control structure.

**Gate 1 - Fun prototype:** playable 3-wave game (1 macrophage, apoptotic debris, modified LDL, Efflux Zone, Flow, plaque visualization); stock prototype shapes allowed only temporarily. First working APK as soon as toolchain permits. Test whether control feels good before expanding art.

**Gate 2 - Signature mechanics:** Lipid Load->Foam Cell, Perfect Efflux, Clean Streak, Resolution Wave; wave upgrade selection; tune failure recovery. Run A/B basic-versus-signature prototype tests.

**Gate 3 - Vertical slice:** 5 polished stages, expressive macrophage, plaque morph, dynamic music layers, 18+ SFX, English+Indonesian, full menus, stable 60 FPS on test hardware. This is the critical stop/go decision for further spending.

**Gate 4 - 100-level campaign:** after the validated five-stage slice, ship authored chapter increments: 20, 40, 60, 80, then 100 tested levels. Implement cinematic `LifestyleEventDirector`, endogenous antioxidant supports and risk-combo boss encounters according to the V2 adjuncts. Maintain data-driven definitions, fair losses, save state and frame pacing.

**Gate 5 - Replay/polish:** Endless mode (only after core is good), cosmetic rewards, optional fact cards, accessibility, performance optimization and QA.

**Gate 6 - Deliverables:** actual APK, source, all original asset masters, sound files, instructions to build, screenshots, QA and known-issues report, evidence-based medical review and license inventory.

Do not proceed to large art production or the 100-level expansion if the first gameplay loop fails objective playtest. Fix it first.

## 12. SUCCESS METRICS AND 9/10 CLAIM POLICY

`9/10 fun` is a target that can ONLY be stated as achieved after testing with independent target-audience players (not only doctors or the creator's fans). Recommended method: 15-20 usability observations, 60-90 participants for comparative mechanic tests, then 100+ representative players for 1-10 enjoyment scoring and session recordings/telemetry with consent. Report mean, median, variance, survey wording, play duration, population, and limitations; do not selectively omit negative responses.

Proposed quality targets (hypotheses, not achieved metrics):
- >=85% understand movement + first objective without verbal coaching.
- >=80% finish first tutorial wave.
- Mean *reported* fun >=9.0/10 on representative test group; if confidence/variance is high, keep iterating instead of claiming success.
- >=65% of testers voluntarily start another wave/run when given a choice.
- >=99.5% crash-free sessions in measured test cohort.
- Real gameplay mostly at 60 FPS on a representative target device, with no repeatable stutters.
- For soft launch only: aspirational D1 >=35%, D7 >=12%, segmented by country/traffic source; do not claim achieved before measurement.

Be willing to reduce scope or remove complicated mechanics to improve these measured outcomes. An internal AI-estimated rating does not count as player validation.

## 13. ACCEPTANCE CRITERIA / DEFINITION OF DONE

A final `COMPLETE` statement is allowed only if:
1. All 100 levels are implemented, can be won or lost correctly, can be restarted, and persist progress.
2. Touch drag movement, cleaning, lipid cargo, efflux, foam state, combo, visible plaque growth, Flow Collapse and later plaque-stability conditions function.
3. First-run onboarding, English+Indonesian, visual accessibility, settings, menu and pause/retry work.
4. Final graphics and animations are original, cohesive, crisp at tested Android resolutions; no programmer placeholders remain in advertised final build.
5. Original or demonstrably licensed and audible music/SFX are integrated and professionally mixed.
6. Automated simulation/gameplay tests pass; QA identifies no unresolved critical blockers.
7. An actual installable Android APK is built and package validated, with installation/device-test status accurately reported.
8. Editable Godot project, assets, README/build instructions, screenshots, licenses and medical review are supplied.
9. Fun >=9/10 is only asserted separately IF independent playtesting really confirms it. Lack of such testing does not justify a false claim and should remain an outstanding validation gate.

If blocked, keep all completed work, identify exact blocker and next action; do not invent artifacts or passing tests.

## 14. SCIENCE / ETHICS CONSTRAINTS

Core factual distinctions:
- Macrophages clear dead cells through efferocytosis; impaired clearance contributes to necrotic core and plaque progression.
- Modified/retained apoB lipoproteins contribute to lipid accumulation and foam-cell formation, while cholesterol efflux pathways help regulate macrophage cargo.
- Risk factors including dyslipidemia, smoking, hypertension, hyperglycemia, and inflammation affect disease development; game waves are fictional metaphors, not predicted clinical outcomes.
- Acute coronary thrombosis can follow plaque rupture or erosion, sometimes without a long gradual approach to a 100%-blocked lumen.
- An individual macrophage cannot single-handedly reverse established human plaque in seconds; accelerated visuals, recovery boosts, and Resolution Wave are fictional game shorthand.

Never give medical advice as if game mechanics represented therapy; avoid clinical risk calculators, medication dosing, user health data, real patient profiles, real heart-rate claims, or implying a player's performance measures health. Add a short disclaimer in About/Science Cards. Have a clinician review all final medical text before publication. Do not use official Red Cross/Red Crescent protective emblems as game icons.

Scientific references for editorial grounding (research, not artwork licenses):
1. Adkar & Leeper, 'Efferocytosis in atherosclerosis', Nature Reviews Cardiology (2024): https://www.nature.com/articles/s41569-024-01037-7
2. 'Foam Cells in Atherosclerosis: Novel Insights Into Its Origins, Consequences, and Molecular Mechanisms' (2022): https://pmc.ncbi.nlm.nih.gov/articles/PMC9043520/
3. 'Mechanisms of continual efferocytosis by macrophages and its role in mitigating atherosclerosis' (2023): https://pmc.ncbi.nlm.nih.gov/articles/PMC9869949/
4. 'Acute coronary syndromes: mechanisms, challenges, and new opportunities' (European Heart Journal, 2025): https://pmc.ncbi.nlm.nih.gov/articles/PMC12314746/
5. 'Acute coronary syndrome with plaque erosion' (European Heart Journal, 2026): https://pubmed.ncbi.nlm.nih.gov/41384362/

## 15. EXPECTED FINAL PACKAGE

```
atheroguard/
  project.godot
  export_presets.cfg
  scenes/
  scripts/
  assets/art/  # original source masters and exported mobile sprites
  assets/audio/  # original/licensed music and SFX
  data/levels/
  data/translations/
  tests/
  screenshots/
  build/android/atheroguard_debug.apk
  README.md
  QA_REPORT.md
  MEDICAL_REVIEW.md
  ASSET_PROVENANCE.md
  CHANGELOG.md
```

Files in this Google Drive folder are the specifications. The real development project should live in a local version-controlled repository and may be synced back to this Drive project folder after production; do not mistake Drive documents for a Godot executable. Always reference the most recent approved spec and report changes clearly.

## 15A. V2 CONTENT AND QUALITY EXPANSION - 100 LEVELS

- **New required companion files:** `LEVEL_ROADMAP_100.md` (human level table), `LEVEL_MANIFEST_100.json` (planning, not implemented code), `EVENTS_AND_DEFENSE_V2.md` (cinematics, enemy semantics, 3-stage Risk Combo, endogenous support, science and QA).
- **Non-negotiable features:** 100 actually playable levels, at least 7 reusable human-event animation scenarios, risk combo (`TRIPLE_OVERLOAD`), visibly distinct ROS/cytokine/modified lipid mechanics, automated endogenous antioxidant defense, stage-specific objective design, at least 10 chapter finales and offline playable APK.
- **Content efficiency:** Do NOT produce 100 nearly identical static levels or 100 wasteful prerecorded human cutscene videos. Use original modular rigs, reusable cutscenes, data-driven wave timelines and carefully authored variation. Skip repeat cinematics, remain fair and responsive.
- **Scientific sanity:** one meal, soda or cigarette does not cause immediate visible human plaque. Lifestyle sequences are repeated-risk time lapses. LDL retained/modified in the wall, cytokines are signals, oxidative overload refers to excess ROS (not the total elimination of ROS), antioxidant ENZYMES are endogenous defenses. Supplement use is NOT proven to prevent cardiovascular events; never call pills a cure.
- **Production sequencing:** playable APK from Gate 1 when Android SDK available; validated 5-stage fun-first slice at Gate 3; content shipping checkpoints at 20/40/60/80/100. Final `COMPLETE` requires all 100 levels and original polished event scenes, not just an outline.

## 16. FINAL AGENT DIRECTIVE

READ all project files and implement the game end-to-end in Godot. Begin with the playable three-wave core immediately, test it, improve game feel, develop the 5-stage polished vertical slice, and continue toward 100 stages (in validated chapter increments) plus an installable APK when the quality gates are satisfied. Never stop at a design summary. Never claim fun 9/10 without independent test evidence. Do not claim device installation or audio validation without actual tests. Protect scientific accuracy, brand/IP safety, user data, and the existing Nadiloopa game.
