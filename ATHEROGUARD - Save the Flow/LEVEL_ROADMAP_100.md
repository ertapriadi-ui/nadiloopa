---
project: ATHEROGUARD - Save the Flow
revision: 2.0
created: 2026-11-18
scope: 100 validated playable levels in 10 chapters
status: APPROVED PRODUCT GOAL / NOT IMPLEMENTED
linked_docs: [GAME_GOAL_AND_DESIGN.md, EVENTS_AND_DEFENSE_V2.md, AGENTS.md, README.md]
---

# 100-LEVEL CAMPAIGN ROADMAP (GOAL, NOT IMPLEMENTATION)

A designer-facing 100-stage specification. Implement exactly 100 individually selectable, restartable, playable, testable and winnable levels. No copy-paste filler where only numeric difficulty changes; new combinations, timings, geography, objectives, and scripted events must meaningfully vary.

## Level architecture

- TEN chapters of TEN levels; levels 10, 20, ... 100 are chapter finales.
- Each level 1-4 waves, approximately 45-120 seconds per wave; save progress between levels, not mid-pickup.
- The first level teaches movement and cleaning within seconds. A new mechanic must be introduced through safe playable context before difficulty rises.
- A short lifestyle-event cinematic runs only the first time an event type appears, on chapter boss levels, or when the player opts to replay it. Routine repeats use unobtrusive 1-2-second in-world HUD notification.
- Chapter finale has a memorable combination of known hazards, special audio variation and a clear win condition. Avoid unavoidable shock failure.
- Event sequence and spawn schedule are deterministic per seed and scenario. Simulators must be able to replay every encounter.
- Preserve 60 FPS target for reference Android hardware; support 30 FPS fallback as necessary.
- Do not interpret made-up plaque meters as clinical stenosis.

## 100 named stages

### Chapter 01 - First Defenders (L1-L10)

**Core focus:** Cleanup basics. **Dominant event family:** `none`.

| Level | Stage | Mechanic | Player-facing goal |
|---:|---|---|---|
| 001 | First Patrol | debris cleanup | Clear 8 apoptotic debris |
| 002 | Follow the Flow | movement control | Clear 10 debris without leaving zone |
| 003 | First Efflux | efflux station | Unload lipid cargo once |
| 004 | Rapid Cleanup | streak | Build a 4-clear streak |
| 005 | Protect the Boundary | endothelial safety | Prevent 3 threatened cells |
| 006 | Debris Drift | moving targets | Clear 12 drifting debris |
| 007 | Clean Corners | spatial routing | Clear 4 corners |
| 008 | Green Recovery | resolution charge | Activate Resolution Wave |
| 009 | Narrow Escape | recovery | Restore critical Flow Integrity |
| 010 | The First Surge | chapter challenge | Survive 3 cleanup waves |

### Chapter 02 - Lipid Frontier (L11-L20)

**Core focus:** LDL retention and foam-cell dilemma. **Dominant event family:** `high_ldl`.

| Level | Stage | Mechanic | Player-facing goal |
|---:|---|---|---|
| 011 | Lipid Landing | lipid exposure | Handle first modified lipid deposits |
| 012 | Cargo Control | lipid limit | Complete wave below critical cargo |
| 013 | ApoB Rush | retention surge | Handle high-LDL modifier |
| 014 | Efflux Route | path planning | Complete 2 efflux cycles |
| 015 | Greedy Macrophage | risk reward | Clean debris while avoiding overload |
| 016 | Foam Warning | foam hazard | Recover from 1 foam-cell warning |
| 017 | Blocked Passage | path hazards | Find safe path to efflux station |
| 018 | Countercurrent | mixed wave | Protect 2 debris clusters |
| 019 | Perfect Unload | precision timing | Perform 2 Perfect Efflux actions |
| 020 | Foam Cell Frenzy | chapter challenge | Survive 3 high-lipid waves |

### Chapter 03 - Sweet Pressure (L21-L30)

**Core focus:** repeated high sugar patterns and metabolic strain. **Dominant event family:** `sugar_surge`.

| Level | Stage | Mechanic | Player-facing goal |
|---:|---|---|---|
| 021 | Sweet Signal | event introduction | Survive first Sugar Surge |
| 022 | Sticky Traffic | spawn variation | Clean 14 debris in crowded arena |
| 023 | Metabolic Haze | field hazard | Keep Flow above safety threshold |
| 024 | Drinks on Repeat | repeat event | Survive 2 sugar episodes |
| 025 | Careful Collector | cargo management | Unload before Lipid Load reaches danger |
| 026 | Balance Break | positive counter-event | Use balanced-pattern support once |
| 027 | Signal Scatter | spatial hazard | Route around 3 stress fields |
| 028 | Rush and Recover | combo management | Trigger Resolution Wave after event |
| 029 | Pressure Stack | dual modifier | Survive combined sugar and LDL wave |
| 030 | Sugar Surge Finale | chapter challenge | Clear wave under mixed metabolic pressure |

### Chapter 04 - Smoke Signals (L31-L40)

**Core focus:** smoke exposure and oxidative stress. **Dominant event family:** `smoking_storm`.

| Level | Stage | Mechanic | Player-facing goal |
|---:|---|---|---|
| 031 | First Puff Signal | cutscene and hazard | Survive first Smoking Storm |
| 032 | ROS Alert | oxidative field | Avoid 3 oxidative fields |
| 033 | Barrier Disturbance | endothelium | Protect vulnerable endothelial zones |
| 034 | Oxidized Lipids | modified lipid | Manage oxidation-enhanced cargo |
| 035 | Coughing Clouds | visibility fairness | Navigate clear telegraphed haze |
| 036 | Clear the Haze | defense pickup | Collect one endogenous defense orb |
| 037 | Twin Smoke Waves | event chaining | Survive 2 smoke events |
| 038 | Stress Corridor | movement challenge | Unload without entering hazard field |
| 039 | Countermeasure | support skill | Activate antioxidant support twice |
| 040 | Storm at the Wall | chapter challenge | Survive ROS and lipid-pressure boss wave |

### Chapter 05 - Pressure Waves (L41-L50)

**Core focus:** hypertension and wall stress. **Dominant event family:** `pressure_wave`.

| Level | Stage | Mechanic | Player-facing goal |
|---:|---|---|---|
| 041 | Pulse Pressure | risk introduction | Survive first pressure wave |
| 042 | Wall Tension | boundary defense | Protect 3 endothelial segments |
| 043 | Vessel Squeeze | arena shift | Navigate temporary safe-lane contraction |
| 044 | Backflow Strategy | movement | Reach efflux station with changing routes |
| 045 | Double Risk | event stack | Survive pressure plus high LDL |
| 046 | Patch the Gap | protective shield | Use Endothelial Guard twice |
| 047 | RBC Rush | visual speed | Keep cleanup rhythm during high flow |
| 048 | Stress Timing | dodge | Avoid three telegraphed wall-pressure pulses |
| 049 | Tension Release | recovery | Recover from near-fail without free reset |
| 050 | Pressure Front | chapter challenge | Defend against multi-stage wall-stress encounter |

### Chapter 06 - Inflammation Highway (L51-L60)

**Core focus:** cytokine signaling and monocyte recruitment. **Dominant event family:** `inflammation_wave`.

| Level | Stage | Mechanic | Player-facing goal |
|---:|---|---|---|
| 051 | Signals in the Wall | signal concept | Observe cytokine field, clear affected debris |
| 052 | Recruitment Call | monocytes | Limit accumulation of recruited monocytes |
| 053 | Amplifier Loop | spawner interplay | Interrupt 2 inflammatory amplifiers |
| 054 | Debris Backlog | efferocytosis | Clear 20 debris before secondary necrosis |
| 055 | Two Signals | field overlap | Navigate overlapping cytokine fields |
| 056 | Tidy Resolution | combo | Earn a high Resolution Charge score |
| 057 | No Easy Route | routing | Unload via alternate station |
| 058 | Storm and Signals | event stack | Handle ROS plus inflammation |
| 059 | The Necrotic Core | plaque burden | Keep fictional core below warning level |
| 060 | Cytokine Chorus | chapter challenge | Complete peak inflammatory multi-wave defense |

### Chapter 07 - Cellular Shields (L61-L70)

**Core focus:** endogenous antioxidant system partnerships. **Dominant event family:** `oxidative_overload`.

| Level | Stage | Mechanic | Player-facing goal |
|---:|---|---|---|
| 061 | Meet SOD | support unlock | Activate SOD Sentinel once |
| 062 | Catalase Circuit | support unlock | Activate Catalase Keeper once |
| 063 | Glutathione Guard | support unlock | Activate GPx Guardian once |
| 064 | Defense Budget | charge choices | Spend support charge once strategically |
| 065 | Timed Shield | cooldowns | Protect field before next ROS pulse |
| 066 | ROS Crossfire | hazard stack | Survive synchronized oxidative stress |
| 067 | False Safety | tradeoff | Do not assume support can replace cleanup |
| 068 | Cellular Relay | support synergy | Complete 2-part antioxidant relay |
| 069 | Overflow Warning | resource cap | Avoid wasting defense charges |
| 070 | Redox Resilience | chapter challenge | Survive oxidative boss with balanced supports |

### Chapter 08 - Risk Stack (L71-L80)

**Core focus:** repeated multi-habit exposure risk combos. **Dominant event family:** `triple_overload`.

| Level | Stage | Mechanic | Player-facing goal |
|---:|---|---|---|
| 071 | Feast Frequency | meal pattern | Survive first repeated-overload montage |
| 072 | Cola Cascade | sweet beverage | Survive sugar drink sequence |
| 073 | Smoke Returns | smoking recurrence | Handle repeated smoking events |
| 074 | Two-Hit Combo | risk stack | Manage eating plus sugary drinks |
| 075 | Three-Hit Telegraph | warning | Recognize triple-event preview |
| 076 | Triple Overload | combo event | Survive full three-risk wave |
| 077 | Keep Your Head | critical routing | Reach efflux during overloaded field |
| 078 | Shields Under Fire | support balance | Use 2 different support types |
| 079 | Calm After the Storm | positive habits | Benefit from gradual risk reduction event |
| 080 | Stackbreaker | chapter challenge | Handle triple-event boss with no cheap insta-loss |

### Chapter 09 - Unstable Plaque (L81-L90)

**Core focus:** necrotic core and plaque stability. **Dominant event family:** `unstable_plaque`.

| Level | Stage | Mechanic | Player-facing goal |
|---:|---|---|---|
| 081 | Core Warning | necrotic core | Reduce uncollected debris backlog |
| 082 | Thin Cap | stability | Preserve cap stability during surge |
| 083 | Warning Signs | telegraph | React to predicted instability event |
| 084 | Erosion Route | advanced event | Avoid first announced erosion scenario |
| 085 | Rupture Drill | advanced event | Survive scripted rupture-prevention challenge |
| 086 | Inflamed Core | dual objective | Protect flow and stability |
| 087 | Risky Shortcut | strategy | Choose safety over bonus score |
| 088 | Thrombus Alarm | acute thrombosis | Respond to thrombus telegraph |
| 089 | Two Paths to Failure | dual lose modes | Complete stage without collapse or thrombosis |
| 090 | Capstone of Stability | chapter challenge | Defend vulnerable lesion through 3 phases |

### Chapter 10 - Save the Flow (L91-L100)

**Core focus:** all systems and mastery. **Dominant event family:** `grand_finale`.

| Level | Stage | Mechanic | Player-facing goal |
|---:|---|---|---|
| 091 | All Systems Go | full system | Survive mixed cleanup, cargo and defense |
| 092 | Steady Hands | precision | Maintain efficient efflux under stress |
| 093 | Return of the Storm | event remix | Survive smoking and ROS event remix |
| 094 | Sugar and Smoke | combined risk | Handle two risk modifiers cleanly |
| 095 | The Big Feast | overload event | Counter repeated-overload pattern |
| 096 | Cytokine Crossroads | signal storm | Protect intima while signals spread |
| 097 | Antioxidant Relay | support composition | Choose best two support upgrades |
| 098 | Near Occlusion | last-second defense | Recover from a telegraphed critical state |
| 099 | The Long Defense | endurance | Finish 4 diverse waves |
| 100 | Save the Flow | final boss | Defeat final 3-stage threat without total occlusion |


## Minimum authored content and QA expectations

1. **Every level** must define the immutable board/arena configuration or scripted spawner plan, risk events, timing, objective, allowed upgrades, failure/win state, visual cue, reward and target difficulty; initial `level_manifest.json` is a planning seed, NOT a shipping config until the actual waves and conditions are implemented.
2. Generate additional encounter variants by seed ONLY within manually designed parameter bands; no broken pathing or unavoidable failure.
3. Automated tests must confirm each of 100 levels starts, ends, can retry, saves advancement, triggers correct music/cinematics, and has at least one reachable success state in representative runs.
4. Run thousand-seed stress simulations globally and representative human/computer-control tests on each chapter; examine pass rates, time-to-fail, upgrade distribution, and difficulty spikes.
5. Maintain chapter-specific ambiance, enemy mixes, upgrade offers, and finale effects without 100 separate expensive video renders. Use a composable animation library.
6. Target 9/10 average enjoyment only after independent player testing. No scripted or AI self-score counts as evidence.
7. Do not let the long campaign delay delivery of a playable, device-tested Android build from early gates. The final campaign release requires all 100 stages working.

## Objective catalog for implementers

- `CLEAN_COUNT`: clear X apoptotic debris before time/move limit.
- `FLOW_SURVIVAL`: keep Flow Integrity above threshold until wave timer ends.
- `EFFLUX_COUNT`: complete N cargo unload cycles without foam failure.
- `COMBO_STREAK`: sustain cleanup chain for N units.
- `REGION_PROTECTION`: keep specified intima/endothelium zone intact.
- `EVENT_SURVIVAL`: survive a scripted risk event with telegraphed onset.
- `SUPPORT_COMBO`: use configured endogenous antioxidant defense ability appropriately.
- `STABILITY`: survive without plaque-cap stability failure in levels 81+.
- `BOSS_MULTIPHASE`: complete a chapter finale with sequential conditions.

Each level may combine up to TWO primary objectives in the first 50 levels and THREE in expert late levels, with a prominent readable HUD. Avoid compulsory medical quizzes.
