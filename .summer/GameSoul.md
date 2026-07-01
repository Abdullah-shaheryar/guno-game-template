# GUNO — Game Soul

**One gun, four modes.** A 2D side-scrolling action-puzzle platformer where the same
weapon solves environmental puzzles AND fights enemies. Swap modes on the fly to reshape
the world.

## Modes
1. **Elemental** — Fire melts ice, Ice freezes water into platforms, Electric powers machines & stuns.
2. **Gravity** — rotate gravity 90°, walk walls/ceilings, drop enemies into hazards.
3. **Time** — rewind/fast-forward objects: rebuild bridges, age trees, undo attacks.
4. **Clone** — record your actions; a ghost clone replays them to help solve puzzles & fight.

## Pillar
Every mode must serve BOTH a puzzle and combat.

## Later layers
- Living Weapon: the gun evolves with playstyle.
- Music Combat: actions sync to rhythm; staying on-beat empowers you.

## Architecture
Modular **Gun + Mode components** (shared interface: enter/exit/fire/tick). World objects
opt into interactions via groups: `meltable`, `freezable_water`, `powered`, `temporal`,
`clone_solid`, `hazard`. Autoloads: `GravityManager`, `TimeService`, `CloneRecorder`.

Full spec: `docs/superpowers/specs/2026-06-30-guno-design.md`

## Art
2D only. Phase A = placeholder colored shapes. Phase B = generated 2D sprites (Summer image generation / Blender renders).

## Build status
- [x] M0 player skeleton (run/jump, camera, respawn)
- [x] M1 Elemental + Zone 1 (gun-mode framework, bullet, fire/ice/electric, walker enemy, 3 puzzles)
- [x] M2 Gravity + Zone 2 (GravityManager singleton, gravity-aware player/enemies, wall-walk, coyote/jump-buffer)
- [x] M3 Time + Zone 3 (time bolts, rewind bridge, fast-forward tree staircase, enemy time effects)
- [x] M4 Clone + Zone 4 (path-recording ghost, pressure plate + gate, clone clears enemies)
- [x] Debug warp (keys 1-4 jump to each zone)
- [x] M5 Hub + boss + HUD (hub portals, player health + contact damage, HP readout, shielded mode-combining boss with reflectable shots)
- [x] M6 art (hand-drawn cartoon): hero, walker, boss sprites + painterly background swapped in for placeholders
- [x] M6 audio: music loop (generated) + shoot/jump/hit/levelup SFX (free library); `Audio` autoload
- [x] #6 Music-Based Combat: `BeatClock` autoload (120 BPM); on-beat shots hit harder; HUD gold beat-flash
- [x] #5 Living Weapon: `WeaponProgress` autoload; modes level up with use (bigger Elemental shots, longer Clone), level-up banner + chime
- [x] Bug fix: bullets/time-bolts now set color in setup() (was defaulting in _ready before element known)

**ALL SIX original ideas now implemented** (Elemental, Time, Gravity, Clone, Living Weapon, Music Combat).

- [x] Player-feedback pass: sprites re-made in Blender (real alpha, no copyright); player sprite flip_h facing; ice wall now multi-hit (real obstacle, was 1-shot melt on default fire); self-made gradient background
- [x] Juice & polish pass (from a 5-lens needs-analysis): `Juice` autoload (trauma screen shake + hitstop + CPUParticles bursts); hit-flash on enemies/boss; particle bursts on bullet impact / enemy death / muzzle / player damage / pickups; boss death payoff
- [x] HUD overhaul (scenes/ui/hud.tscn): visual player health bar + boss health bar + 4-chip mode indicator + on-beat pulse ring
- [x] Flow screens: title (scenes/title.tscn) -> main; win screen on boss defeat; pause menu (Esc / R restart)
- [x] Interactive menu system (shared scenes/ui/menu_theme.tres): main_menu.tscn (BOOT scene — gradient sky/moon/stars/hills, bobbing hero, colored FIRE/GRAVITY/TIME/CLONE showcase, drifting sparkles, Play/How-to-Play/Quit buttons with hover-pop + keyboard nav, controls panel); styled resume panel (Resume/Restart/Main Menu/Quit); matching victory panel (Play Again/Main Menu). All rounded-purple themed buttons, mouse + keyboard.
- [x] Content: Flyer enemy (Blender-made flyer.png, floats+chases+all elements) placed in Zone 1 + boss arena; health pickups (scenes/world/pickup.tscn)
- [x] Playability & content pass (from a 4-lens fun/playability analysis):
  - Stakes: `GameStats` autoload (lives/shards/deaths); falling = free reposition, HP-death costs a life; **game-over screen** at 0 lives (Retry/Main Menu); stats reset on menu Play / Retry
  - Goals: **collectible shards** (scenes/world/shard.tscn ×14 via shards.tscn) + `♥ lives / ✦ shards` in the HUD
  - Onboarding: **tutorial hints** (hint_overlay.tscn fading label + hint_zone triggers in hub/zone1)
  - Content: **Turret enemy** (aims + fires, ice/electric disable it) placed in zones 2 & 3; **multi-phase boss** (summons flyer minions <60% hp, fires faster <30%)
  - Feel: gun **recoil** (Juice.punch camera kick), player **landing squash**
  - Settings: master **volume slider** on the main menu (Audio.set_master_volume via master bus)
- [x] Optimize & polish pass (from a verified gap audit):
  - Bugfix: Clone ghost now DAMAGES enemies (was silent queue_free that skipped boss victory); recording auto-cancels on teleport/death; one clone at a time; clones cleared on warp
  - Pillar restored: **Gravity now has boss combat use** — flipping gravity destabilizes the boss (shield drop + stun); boss **telegraphs** shots (red wind-up) and pulses electric-blue to signal its weakness
  - Polish: **scene-fade transitions** (Transitions autoload, all scene changes); **procedural player animation** (walk bob + lean, idle breathe, land squash); **per-element bullet trails**; mode-switch chime
  - Cleanup: removed debug `[1-4] warp` from shipped HUD; renamed shadowed vars (0 warnings); added **README.md** (architecture + how-to-extend + credits)
- [x] Animation + dynamics pass:
  - Procedural **squash-and-stretch** animation on the hero (walk bounce, air stretch, land squash, idle breathe) — code-based path (Blender MCP was offline)
  - Enemy animation: walker **waddle**, flyer **wing-flap** (scale-based)
  - "More interesting" gameplay: **moving platforms** (AnimatableBody2D, carries the player) + a **bounce pad** (launches away from gravity) in the boss arena (scenes/world/moving_platform, bounce_pad, dynamics.tscn)
- [x] Player-feedback fixes: **visible gun that rotates to the cursor** (Gun node has a gun graphic; flips upright when aiming left) + hero faces the aim; **portals now labeled** (ELEMENTAL/GRAVITY/TIME/CLONE/BOSS) with a pulsing "▲ Enter" prompt when you stand in one (they were confusing unlabeled "pillars"); **bigger walk animation** (bounce + step-sway)
- [x] Feedback round 2: re-rendered hero in Blender WITHOUT the baked gun (only the aiming gun shows now); bound Enter to `interact` (portals work with Enter, prompt "↑ / Enter"); added dark **underground** fill + camera zoom 1.3 + offset so the world fills the screen (was empty sky below ground); HUD status moved **top-center** + **[H] toggles HUD** (toggle_hud action)
- [x] Top-notch debug + optimize pass (multi-pass adversarial audit → 32/53 findings confirmed → all fixed, 0 errors/0 warnings, playtested):
  - Crash safety: null-check `current_scene` before add_child in boss (`_spawn_minion`/`_shoot`), turret (`_shoot`), and `gun_mode.spawn_into_world` (bullets/minions could crash mid scene-transition); guard duck-typed `secondary()`/`tick()` in gun.gd
  - Scene flow: `Transitions.change_scene/reload` now `await` the fade-in and force-unpause (defensive against a stalled fade / paused destination); title screen routes through Transitions for a consistent fade
  - Combat correctness: boss gravity-stun now has a 1s cooldown (was infinitely stunlockable by spamming Gravity); Clone ghost routes damage through `apply_element("clone")` so the boss **shield still gates it** (no cheesing) while still dying via `_die`→victory; Time-reflected boss shots now pass through world geometry to reach the boss (were despawning on walls); **Flyer is now gravity-aware** (re-orients hover/pursuit along the down vector) so Gravity mode affects it
  - Robustness: `Juice.hitstop` is overlap-safe and can't leave the game frozen (id-guarded restore, real-time timer); clone recording is explicitly cancelled on portal warp (+ a dissolve cue) instead of relying on a 250px heuristic; player respawn/reposition clears coyote+jump-buffer; moving platform drives world-space position
  - Perf: cached the player/gun refs (was `get_nodes_in_group` **every frame** in turret, flyer, hud, health_bar, mode_indicator) and the per-shot autoload lookups in gun.gd; HUD only rewrites its Label when text changes
  - **Bonus (audit missed):** `Juice` was overwriting `Camera2D.offset` every frame, erasing the (0,-60) framing offset — now it captures each camera's base offset and ADDS shake/recoil on top, so framing survives
  - Cleanup: named the magic numbers (`TELEPORT_THRESHOLD`, `INITIAL_BEAT_DELAY`, `GRAVITY_FLIP_CD`, `HOVER_DIST`)
- [x] UI + fullscreen fix (feedback): set `display/window/stretch/mode=canvas_items` + `aspect=expand` so the game **fills the window to the corners** (was letterboxed with black bars). Rebuilt main_menu layout with **center anchors** — GUNO title + subtitle + a wider (360px) evenly-spaced button column all centered on one axis, hero balanced right, volume anchored bottom-left; widened hills so expansion never reveals a gap.
- [x] Gun + traversability fix (feedback): raised the Gun node (0,2)→(0,-6) so it sits in the hand (was showing hand above it). Measured every level gap/wall vs the player's real jump and fixed the impassable ones: **mobility buff** (jump 540→620 ≈137px, speed 260→300 ≈266px gap) so fair gaps are jumpable; **Zone 2** got 3 stepping-stone platforms across the 800px gravity gap; **Zone 3** MidFloor extended (300px gap → 200px) and the exit ledge lowered (150px climb → 90px); turret fire interval 1.9s→2.5s so traversal isn't a bullet-hell. Kept the ice-wall/power-door/gate as intended mechanic gates (still taller than jump). Verified: gun in-hand (zoom), stepping stones present, warp+move work, 0 errors.
- [x] Template documentation pass (make it easy-to-extend without touching runtime): mapped every compartment from real code, then authored a docs/ set — root **GUIDE.md** (architecture map, collision/group/autoload/duck-type conventions, golden invariants, verify-loop), **per-folder README guides** (scripts/managers, scripts/gun, scenes/player, scenes/enemies, scenes/world, scripts/ui, scenes/zones), **docs/ARCHITECTURE.md** (data-flow & lifecycles) and **docs/EXTENDING.md** (copy-paste recipes), filled **.summer/NOTES.md** (pointer + golden rules), linked from README. Additive only — 0 errors/0 warnings, game unchanged. (Docs use neutral, vendor-free wording throughout.)
- [x] Full optimize + polish pass (second layer, from a 6-lens audit → adversarially checked for value AND safety → 24 confirmed-safe changes; dropped 3 as harmful/pointless: per-bullet hitstop would stutter rapid-fire, big animation-constant refactor, invalid window/srgb):
  - Render: **2D MSAA** (`rendering/anti_aliasing/quality/msaa_2d=2`) smooths the all-polygon art; `default_clear_color` set to the bg tint (no startup flash)
  - Perf/consistency: cached autoloads that were still looked up per-event — bullet (BeatClock+Juice, the 10-20/sec hot path), walker/pickup/shard/bounce_pad (Juice/Audio/GameStats), elemental_mode (WeaponProgress) + gravity_mode (GravityManager) via `_on_enter`, player (Audio/Juice); health_bar only rewrites its Label when HP changes
  - Audio coverage (used existing sfx keys): boss-death victory sting, player-death, portal warp, gravity-flip confirm, jump-land thud; jump louder (-7→-5)
  - Game feel: player-hit hitstop (0.03), mode-switch shake+spark, on-beat power-shot audio stinger
  - Visual legibility: HUD status text outline; brighter beat-ring on/off-beat contrast; inactive mode chips less dim; portal label outline 6→8; button hover pure-white
  - Cleanup: deleted unused `hud_health.tscn` (zero references)
  - Verified: 0 errors/0 warnings, playtested (HUD outline + brighter chips + smooth edges visible).
- [x] Copyright pass — **self-made audio**: replaced the free-library SFX + generated music.mp3 with 100% original audio synthesized in code (`scripts/managers/audio.gd`): oscillator/envelope DSP for shoot/jump/hit/levelup + a 120 BPM chiptune loop (matches BeatClock). Deleted all 5 audio files + .import (audio/ is now empty). Now the ONLY assets are self-made (Blender sprites, procedural bg, code audio, Godot's open font) — zero third-party licensing.
- [x] Third debug+optimize pass (focused, high-bar; 10 findings → 5 applied, 5 correctly rejected): applied — beat_ring BeatClock cache, boss player-ref cache (`_get_player`), Juice camera-fetch cached until stale, portal clone-loop `is_instance_valid` guard, divide-by-zero guards (`maxf(max_hp,1)`) in health_bar + boss. Rejected as false/intended — "turret/gun/portal fire during pause" (Godot already pauses PROCESS_MODE_PAUSABLE gameplay nodes; only menus are ALWAYS), "boss electric deals no damage" (intended — electric drops shield, fire/ice damage), "bounce pad = vs +=" (`=` gives consistent launch + cancels fall velocity). 0 errors/0 warnings.
- [x] Playtest-feedback round 3 (user played the whole game, detailed list):
  - **CRITICAL soft-lock**: standing on an enemy launched the player to the sky. Cause = CharacterBody2D-on-CharacterBody2D depenetration. Fix = moved enemy BODIES to collision **layer 3 (value 4)** so the player passes through them (contact damage still via the `Touch` area) — no ejection possible. Retargeted every dependent mask: bullet/time-bolt→5, boss-projectile→7, clone hitbox→4, hazard→6 (GUIDE.md collision table updated).
  - **Puzzle collisions**: ice-freeze / time-bridge / clone-gate now toggle collision via `set_deferred` (safe from the physics callback where a direct toggle was dropped — the "wall vanished but collision box stayed" gate bug).
  - **Discoverability**: added entry hint zones for Gravity/Time/Clone/Boss zones (they had none), each teaching its mechanic; boss shows a live "SHIELDED - hit with ELECTRIC" / "VULNERABLE - FIRE burns 2x" label (fire alone felt like it did nothing).
  - **Boss/combat**: reflected (Time-rewound) shots now damage ANY enemy — a deflected turret shot kills the turret, not just the boss; **boss-arena walls made VISIBLE** (were invisible collision).
  - **Clone looks like the player** now (cyan semi-transparent hero sprite).
  - **UI**: fixed How-To-Play text overflow (center-anchored panel + smaller font); dedicated gold **"✦ N" shard counter**; **"BEAT"** label under the beat ring.
  - Verified in-engine: 0 errors/0 warnings; playtested (How-To-Play fits, shard counter counts up, entry hints fire, gravity flip works, player never sky-locks). Enemy-collision & boss-shield confirmed by the definitive layer/label changes.
  - Deferred (bigger, self-made-art): real textures/sprites for portals/doors/props — needs a Blender pass.
- [x] Feedback round 4 (readability): **material tags** on the elemental obstacles — small labels showing what each is + the element to use ("ICE / melt: FIRE", "WATER / freeze: ICE", "POWER DOOR / zap: ELECTRIC"). **Per-mode gun colour**: the Gun recolours body+tip to the active mode (Gravity=purple, Time=teal, Clone=cyan) via `tip_color()`/`gun_color()` on each mode; **Elemental keeps the grey body but the tip ball shows the element** (fire=orange, ice=blue, electric=yellow). Verified in-engine: 0 errors, gun turns purple in Gravity + orange tip in fire, WATER tag renders.
- [ ] Remaining (larger): save/load + persistence, dedicated settings menu, gamepad/rebinding, modular level loader, more content/levels, Blender frame-based limb-swing walk cycle, checkpoints, scoring/combo. Deliberately deferred: particle-burst pooling (churn is trivial at this game's intensity; not worth the reuse-state bug risk)

Visual baseline verified via desktop screenshot: game renders, HUD works, hub/portals + background art all correct.

## Art (self-made, no copyright)
Characters are MODELLED + RENDERED IN BLENDER (cartoon look: low-poly primitives, Standard view transform,
Freestyle ink outline, orthographic side/front camera, render.film_transparent = true -> real RGBA alpha).
Files: res://art/hero.png (right-facing chibi), walker.png (angry critter), boss.png (crystal guardian).
Background = self-made in Godot (GradientTexture2D sky + Polygon2D moon/stars/hills in scenes/zones/background.tscn) — no image file.
Characters use Sprite2D; enemy/boss state feedback uses `modulate`. Player sprite flips via `flip_h` on facing.
The earlier generated images were REPLACED (user wants hand-made assets, no copyright). Bullets/platforms still shapes.
Audio is now 100% self-made: synthesized from scratch in scripts/managers/audio.gd (original DSP — chiptune SFX + a 120 BPM music loop). No audio files ship; nothing third-party to license.

## Mode controls
Q/E cycle modes (Elemental → Gravity → Time → Clone). Fire = LMB/J. Secondary = R.
- Elemental: R cycles fire/ice/electric.
- Gravity: aim + fire sets "down" to that cardinal.
- Time: R toggles rewind/forward; fire a temporal object.
- Clone: fire records a 4s path; a ghost replays it.

## Key conventions (so future modes stay consistent)
- Collision layers: world/enemies/interactables = layer 1; player = layer 2; bullets mask = 1 (never hit player).
- Interactable objects implement `apply_element(element: String, bullet)`; bullets duck-type call it.
- Gun modes extend `res://scripts/gun/gun_mode.gd` by PATH (no class_name) and are auto-collected by the Gun via duck typing (`has_method("fire")`).
- Inputs: move_left/right, jump, fire (LMB/J), cycle_mode_next (E) / prev (Q), mode_action (R).
