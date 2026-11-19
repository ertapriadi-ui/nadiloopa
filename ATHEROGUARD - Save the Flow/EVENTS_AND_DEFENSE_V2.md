---
project: ATHEROGUARD - Save the Flow
revision: 2.0
status: FEATURE DESIGN CONTRACT / NOT YET IMPLEMENTED
---

# LIFESTYLE EVENTS, MOLECULAR THREATS AND ANTIOXIDANT DEFENSE

This document defines the new 100-level campaign's distinctive animated event system. Read alongside `GAME_GOAL_AND_DESIGN.md` and `LEVEL_ROADMAP_100.md`. The player is a macrophage **in the arterial intima**; erythrocytes stay in the lumen. Blood LDL particles are not enemies freely swimming past the hero to be eaten in the bloodstream. Events are stylized, time-compressed story devices.

## 1. Emotional design and signature mechanic

**A quiet artery can suddenly become chaotic, but every escalation is visible and counterable.** A short cinematic shows a fictional person's repeated lifestyle context; the camera swoops into an artery. A 3-second prewarning cue announces `RISK COMBO`. Modified LDL, oxidative-stress fields, and inflammatory signaling increase together. Player still uses ONE FINGER to steer macrophage, while secondary antioxidant defenses automatically respond according to selected upgrade and charge/cooldown state.

Player loop: **CLEAN -> MANAGE LIPID -> EFFLUX -> CHOOSE DEFENSE -> SURVIVE WAVE -> UPGRADE**.

Gameplay will never be made explicitly addictive through manipulative punishment or deceptive scarcity. Challenge comes from readable decisions and satisfying recovery.

## 2. Human-life event animations: reusable cinematic library

**Visual format**: 2D/2.5D original character animation, 3-6 seconds on the FIRST occurrence, and 1-2-second diegetic banner for repeated event types. A first-time event should be skippable after its initial reveal; include `Skip Cinematics`, `Reduce Motion`, `Mute`, and `Replay Event` from chapter map. Events must never block urgent player input unexpectedly mid-wave: enter only during deterministic pauses or with transparent countdown. Use a small picture-in-picture overlay if a wave remains interactive.

| Event ID | Fictional human scene | Represented exposure | Gameplay change | Guardrail |
|---|---|---|---|---|
| SMOKING_STORM | Fictional adult smoking repeatedly across a time-lapse; smoke rolls into camera | Tobacco-related oxidative stress/endothelial dysfunction | +ROS field density, +oxLDL conversion pressure for limited waves | Never claim one cigarette instantly forms a plaque |
| FEAST_FREQUENCY | Fictional adult attending recurring oversized meals/mukbang montage | Repeated excess dietary pattern | Gradual lipid spawn/retention modifier and crowded routing | A single pizza/burger not a toxin; no body-shaming |
| SUGARY_DRINK_STACK | Repeated sugary soda/drink consumption as a montage | Long-term high-sugar dietary pattern, metabolic burden | In-game metabolic-pressure modifier that increases challenge over several waves | Soda does not transform instantly into LDL; no brand logos |
| PRESSURE_WAVE | Adult under repeated stress/lifestyle and hypertension icon over time | Hypertension/wall stress | Telegraphing endothelial wall pulses and local vulnerability | Chronic BP exposure, not a single stressed moment causing stenosis |
| SEDENTARY_STREAK | Time-lapse of prolonged inactivity | Long-term activity risk pattern | Lower passive recovery across multiple waves | No judgment of physical ability or appearance |
| TRIPLE_OVERLOAD | Montage of recurring large meals + sugary drinks + tobacco over a compressed period | Stacked risk factors | 3-stage wave: retained lipids -> oxidative field -> inflammatory recruitment | Not instantaneous clinical atherosclerosis |
| POSITIVE_SHIFT | Time-lapse of quitting tobacco, balanced meals, movement and appropriate lipid management | Gradual protective pattern | Reduce FUTURE spawn pressure, improve energy efficiency for later waves | Does not instantly erase established plaque |

Do not use real-world trademarks, protected cartoon characters, stock videos without commercial permission, or real recognizable people. Human characters must be neutral, diverse in appearance, non-stigmatizing and not shown as inherently ill because of size/appearance. Avoid portraying overweight bodies as a joke. Use fictional food cartons instead of specific soft-drink company labels.

## 3. Cinematic grammar and feedback

- Entry: 0.6s zoom to the person, 1.5-3s action montage, 0.6s camera dive toward artery, 1-2s warning glow, start controlled event.
- Audio: short original diegetic Foley (lighter click + cough without glamourizing tobacco, fizz/pop, plate clink); transition to distinctive danger cue; never excessively loud.
- Visual: high resolution original animated layers, scalable vectors or master sprites, proper safe areas, title labels in English and Indonesian.
- Surprise is permitted, hidden randomness is not: player sees 3-5 seconds of warning and possible response. Boss-level scenes can be 5-8 seconds but remain skippable on replays.
- Reuse a small number of excellent scenes + dynamic camera, props, time-lapse and palette variants. Prioritize 8 polished events over 100 low-quality cinematics.

## 4. Threat entities: gameplay metaphors, distinct behaviors

| Entity ID | Class | Arena behavior | Actual-science constraint |
|---|---|---|---|
| RETAINED_APOB | Lipoprotein exposure | Appears near intima boundary as precursor; not collected as ordinary blood LDL | ApoB lipoprotein retention is central to atherogenesis |
| MODIFIED_LDL | Lipid object | Collectible with risky Lipid Load increase; unmanaged increases plaque pressure | Modified lipid uptake can lead to foam-cell formation |
| ROS_STORM | Oxidative field, not sentient pathogen | Telegraphed area pulse, increases modification/lowers defense charge | ROS also have normal signaling roles; harmful EXCESS causes stress |
| CYTOKINE_SIGNAL | Signaling field, not a physical cell | Expanding signaling region recruits inflammatory objects and reduces efferocytosis efficiency | Cytokines are signaling molecules, not an enemy organism |
| MONOCYTE_RECRUIT | Cell NPC/spawn consequence | New monocytes arrive at endothelium and contribute to inflammation cycle | Monocyte recruitment can contribute to atherosclerosis |
| APOPTOTIC_DEBRIS | Cleanup objective | If not resolved, becomes threat after visible timer | Efferocytosis failure grows necrotic core |
| OXLDL_CLUSTER | Boss pressure | Larger wave of modified lipid deposits, never instantly fatal | Chronic plaque biology is compressed in the game |
| THROMBOTIC_CRISIS | Advanced boss event | Announced plaque rupture/erosion and thrombosis challenge (levels 81+) | Acute thrombosis possible without prior 100% gradual stenosis |

Avoid depicting all cytokines or all lipid molecules as evil. In the lore, risk objects are stylized representations of harmful ACCUMULATION/imbalance in context.

## 5. Antioxidant defense is an AUTOMATED secondary system

The player controls the macrophage only; do NOT add a second joystick or a tap-attack action. In the background, player earns a `Defense Charge` through cleanup and controlled efflux. Between waves player chooses one auto-defense ally/upgrade. On activation, the ally fires automatically in a small radius with cooldown, optionally activated by touching a visible orb using the SAME drag motion.

| Defender | Inspiration | In-game action | Unlock suggestion |
|---|---|---|---|
| SOD Sentinel | Superoxide dismutase (endogenous enzyme family) | Converts incoming `ROS_STORM` damage to a weaker, temporary oxidative-intermediate challenge; decreases Superoxide burden | Chapter 4 limited pickup, regular unlock L61 |
| Catalase Keeper | Catalase endogenous defense | Resolves that intermediate field in coordinated defense, reducing damage spikes | L62 |
| GPx Guardian | Glutathione peroxidase endogenous defense | Provides a short shield from peroxide-type stress, with cooldown | L63 |
| Endothelial Guard | Barrier/homeostasis | Reduces local endothelial vulnerability while active | From L45 |
| Resolution Support | Efferocytosis/resolution biology | Helps macrophage pick up debris or charge Resolution Wave; never erases plaque instantly | Earlier levels |

Biology caution: superoxide -> H2O2 -> water detox paths are simplified and not literal representations of every cellular compartment. ROS also contribute to physiological signaling; avoid framing their total absence as ideal. Do not label antioxidant dietary supplements as disease cures. Where science cards discuss food, emphasize overall dietary patterns. Pharmaceutical/lipid-lowering effects must be accurate and not misrepresented as magical instantaneous fixes.

**Game rules:** Each defense must have a charge cost, cooldown, clear area-of-effect preview, sound, and opportunity cost. Different threats should reward different builds. No mandatory chemical equations. The game HUD has at most 3 live meters: Flow Integrity, Macrophage Lipid Load, and Defense Charge (with plaque visual cue); the rest appears only when relevant.

## 6. Risk-wave design and combo boss

The strongest new event is `TRIPLE_OVERLOAD`, introduced at level 76. It is a **three-phase event**, not a single arbitrary large spawn:

1. **Exposure warning (3-5s):** stylized adult montage of repeated big meals, sugary drinks and smoking, plus an explicit `Risk Combo x3` banner. The player may skip the scene but never the upcoming warning.
2. **Phase A: Lipid Pressure (15-25s):** more retained/modified lipid deposits form near the endothelium; efflux route stays reachable.
3. **Phase B: Oxidative Pressure (15-25s):** ROS fields appear with safe corridors and periodic SOD/Catalase opportunity.
4. **Phase C: Inflammatory Echo (15-25s):** cytokine signaling areas expand; monocyte recruitment and debris buildup rise. A well-timed Resolution Wave breaks the immediate gameplay pressure without claiming that human plaque vanishes.
5. **Reward and recovery (10-15s):** modest breathing room, upgrade selection after wave, stronger positive audiovisual signal.

No sudden 100% plaque conversion. Danger can become severe, but losses must be telegraphed; objective can be achieved through multiple valid upgrade builds. The 100-stage campaign has several remixes, with final level 100 combining learned rules.

## 7. Positive-event design

- `QUIT_SMOKING`: future oxidative-field rate reduction after a time-lapse.
- `BALANCED_PATTERN`: future lipid burden modifier reduction; not a single superfood remedy.
- `MOVE_MORE`: gradual mobility/recovery resource bonus.
- `LDL_MANAGEMENT`: reduces future apoB/modified lipid wave rate; educational content must not advise a specific person's medication.
- `STRESS_REST`: future pacing/calm bonus only, not a clinical treatment.

Player earns these via between-level chapter decisions, optional earned upgrades or storyline milestones. They are **not** replacements for care, and no health question is required to play.

## 8. Godot implementation contract

- `LifestyleEventDirector`: data-driven trigger by level, timer and wave; controls animation, warning, localized title, and modifier stack. No uninterruptible cinematics during combat.
- `HumanEventScene`: original reusable cutscene scenes with skin/prop/environment variants, no game brands.
- `ThreatSpawner`: composes ROS field, modified lipids, cytokine signals, and monocyte recruitment based on deterministic weights.
- `AntioxidantDefenseSystem`: auto-defense companions, charge meter, cooldowns, synergy rules, friendly VFX.
- `RiskStackSystem`: caps total modifier strength and ensures recovery windows and safe efflux path.
- `ArtLayerController`: separates human-life vignette from arterial/intima gameplay layers; 1080x2400 portrait reference with responsive safe-area HUD.
- `EventAudioConductor`: crossfades base gameplay, action Foley, and intensifying event layers without clipping or abrupt restart.

Use single source of truth for state. No inter-module hidden mutation during paused cinematics. All event data must live in resources/JSON with schema validation and seed replay. Save game progress and settings; do not upload personal data. Human scene can be replayed separately from menu.

## 9. Performance and content budget

Original production targets: minimum 7 distinctive human-life/event animation templates plus varied visual treatment, 100 distinct playable levels, 10 chapter finale encounters, 3 or more original music motifs (menu, base gameplay, crisis) with adaptive layers, 25+ effective SFX cues, 8+ reusable enemy/effect types, 5+ auto-defense/upgrade types and English/Indonesian localized content. Production is conditional on fun gates, but 100 levels remain the desired final shipping scope.

No mandatory 100 hand-rendered cutscene videos. Prefer composable sprite rigs, keyframe animation and reusable props to keep the APK size and workload sane. Aim at 60 FPS on reference mid-range Android; scale particle counts and offscreen rendering. Export real debug APK early. Never invent QA or ratings.

## 10. Required tests

- Risk events spawn only with prewarning; no accidental second event during pause/skip.
- SMOKING_STORM affects oxidative stress; SUGAR_SURGE affects game metabolic risk; FEAST_FREQUENCY affects lipid pressure as metaphor.
- `TRIPLE_OVERLOAD` runs all phases in correct order with a safe route available at all times.
- CYTOKINE_SIGNAL applies zone effects and is not wrongly implemented as an edible monster.
- SOD/Catalase/GPx responses have functioning interaction/cooldown and cannot create infinite loops or disable all threats.
- All 100 level definitions can be loaded and have at least one solvable representative seed; manual test each finale, automation all stages.
- Animation frame pacing, sound mix, localized copy and disabled-motion preference function across Android viewports.
- APK is installable if accessible emulator/device exists, with accurate untested-device disclosures.

## 11. Clinical review source links (reference only)

- Atherosclerosis overview (Merck Manual, updated Oct 2026): https://www.merckmanuals.com/professional/cardiovascular-disorders/arteriosclerosis/atherosclerosis
- Adkar & Leeper, efferocytosis review: https://www.nature.com/articles/s41569-024-01037-7
- Oxidative stress and atherosclerosis (2026): https://pmc.ncbi.nlm.nih.gov/articles/PMC13746002/
- AHA/ACC chronic coronary disease guideline: https://www.jacc.org/doi/10.1016/j.jacc.2023.04.003
- NIH NCCIH antioxidant supplement evidence: https://www.nccih.nih.gov/health/antioxidant-supplements-what-you-need-to-know
- Inflammatory signaling and foam cells (review): https://pubmed.ncbi.nlm.nih.gov/39528464/
