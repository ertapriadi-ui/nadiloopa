# AGENTS.md - ATHEROGUARD

## Mission
Build, test, polish and deliver **AtheroGuard - Save the Flow** as a real original Android arcade-defense game in **Godot 4.x Stable with GDScript**. The game must be playable by one-finger drag, feature a macrophage protecting an artery, and end with a genuine APK and editable source project. The name is a *working title* only.

## REQUIRED READING
Read `GAME_GOAL_AND_DESIGN.md` in full BEFORE implementing any gameplay or writing a production plan. It contains canonical rules, full product requirements, 20-level progression, medical and IP constraints, QA gates, and deliverables. Read `README.md` for file locations and scope. If a local code repository already exists, audit it first; do not overwrite user work.

## Definition of autonomous work
Do the actual work, not only a plan: inspect the machine, select a verified stable Godot version and matching templates, create an isolated repository, implement an interactive three-wave prototype, compile and test, iterate through a polished five-stage vertical slice, then 20 stages and an Android APK. Use the environment's available tools. Document unavailable tools and blockers rather than faking completion. Continue through the objective if possible; reserve requests for user action for truly unavoidable credentials, permissions, or device access.

## Non-negotiable product rules
- **Separate project:** do not modify Nadiloopa or existing files in the parent Games Development folder.
- **Core loop:** CLEAN apoptotic debris, UNLOAD cholesterol cargo at efflux zones, SURVIVE plaque progression and maintain fictional flow integrity.
- **One-finger control:** drag macrophage in playable intima region; auto-collect within radius. No attack buttons, no 7x12 board.
- **Biology:** macrophage efferocytosis can be protective; excess lipid uptake can yield a foam-cell penalty. LDL belongs in the artery-wall process, not eaten directly as normal bloodstream objects. HDL-related efflux is not a magical plaque cure. Acute plaque disruption/thrombosis is possible later without prior gradual total occlusion.
- **Fun goal:** 9/10 is an unverified target; independent player evaluation required before claiming it.
- **Design:** cute, original, premium 2D/2.5D art; visually changing plaque/lumen; dramatic but fair waves; original high-quality music and SFX; subtle Indonesian flavor.
- **Languages:** English default and Indonesian through Settings.
- **Privacy:** offline, no login, no medical data; no ads, IAP, or subscription in first playable release.
- **Quality:** stable responsive portrait UI, 60 FPS target on tested mid-range Android hardware, accessible contrast/motion options, never arbitrary unwinnable game states.
- **Deliver:** actual installable Android debug APK, complete Godot source and assets, screenshots, QA report with evidence, medical review, license/provenance list, and build README.

## Implementation priority
1. Audit toolchain, prepare repo and documented assumptions.
2. Implement a playable three-wave core with responsive drag, debris, modified lipid, efflux, cargo and plaque/flow meters.
3. Add Clean Streak, Perfect Efflux, foam-cell penalty, Resolution Wave and three-choice upgrade selection.
4. Make a polished five-stage vertical slice and measure fun/clarity before expensive scope expansion.
5. Extend to 20 genuinely distinct, winnable campaign levels and optionally Endless after quality gates.
6. Integrate final original graphics, animations, music, SFX, localization, settings and saves.
7. Build, install where possible, test, debug and export APK. Publish factual status of checks and unresolved issues.

## Verification rules
Never call a game complete because `project.godot` or an APK exists. Do not fabricate gameplay footage, tests, medical facts, 9/10 ratings, licensing, audio quality, or physical-device verification. Use automated deterministic simulation plus actual playable interaction tests whenever possible. Surface genuine blockers. Preserve and document reproducible build steps.

## Acceptance checklist
- [ ] Macrophage drag and auto-cleaning are satisfying and accurate.
- [ ] Lipid Load, Efflux, foam transformation and recovery are consistent.
- [ ] Plaque visibly progresses and Flow Collapse works; later acute threat is clearly telegraphed.
- [ ] Bonuses, combos, fair enemy waves and choice of upgrades are playable.
- [ ] 20 stages, progression, saves, restart, pause and both languages work.
- [ ] Final graphics are original/crisp; music/SFX audible, original or licensed, correctly mixed.
- [ ] Android APK exists, is package-validated and device-tested where hardware permits.
- [ ] Source, assets, screenshots, medical review, QA and license reports are present.
- [ ] 9/10 fun is claimed only if a legitimate independent playtest actually validates it.

**Start by reading `GAME_GOAL_AND_DESIGN.md`, then execute the product.**
