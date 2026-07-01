# Architecture — data flow & lifecycles

How the pieces actually talk at runtime. Pair this with [../GUIDE.md](../GUIDE.md) (the conventions)
and the per-folder guides. Everything below is the *real* wiring, not aspiration.

## The three channels (recap)

1. **Autoloads** (`/root/Name`) — global services, fetched with `get_node_or_null` + null-check.
2. **Groups** — the only global registry (`player`, `enemy`, `boss`, `clone`, `gun`, …).
3. **Duck-typed methods** — `if x.has_method("apply_element"): x.apply_element(...)`.

No compartment holds a hard reference into another. That's what makes parts swappable.

## Firing → hitting the world

```
Input "fire"
  └─ Gun._process()  →  modes[current].fire(aim_dir(), muzzle.global_position)
        ├─ ElementalMode → spawn_bullet("fire"|"ice"|"electric", …)   → Bullet
        ├─ TimeMode      → spawn TimeBolt(direction, aim)             → TimeBolt
        ├─ GravityMode   → GravityManager.set_down(aim)   (no projectile)
        └─ CloneMode     → begins recording (see below)
  └─ Gun also: Audio.play("shoot") · WeaponProgress.register_use(mode_key) · Juice.burst+punch
                · if BeatClock.on_beat(): Juice.shake  (on-beat = power shot)

Bullet._on_hit(node):    if node.has_method("apply_element"): node.apply_element(element, self); queue_free()
TimeBolt._on_hit(node):  if node.has_method("apply_time"):    node.apply_time(direction, self);  queue_free()
```

The bullet doesn't know what it hit; the target decides what an element/time hit *means*. That's the
whole extensibility story — a new interactable just implements the method.

## Gun-mode lifecycle

```
Gun._ready():   for child with fire()+activate() → modes.append(child); child.gun = self; child.deactivate()
                modes[0].activate()
Q / E:          _switch(±1) → old.deactivate() (→ _on_exit) → new.activate() (→ _on_enter)
Every frame:    modes[current].tick(delta)      # e.g. CloneMode records the path here
```

## Gravity flip (Gravity mode)

```
GravityMode.fire(aim) → GravityManager.set_down(aim)   # snaps to nearest cardinal
GravityManager emits gravity_changed(down)
  ├─ Player._on_gravity_changed → up_direction = -down; rotation follows
  ├─ Boss._on_gravity_flip      → drop shield + stun (1s cooldown)  ← Gravity's combat use
  └─ Walker/Flyer poll GravityManager.down each physics frame (no subscription)
```

## Clone mode (record → replay)

```
fire()            → start recording (RECORD_TIME + level*1.5 s)
tick(delta)       → append player.global_position each frame;
                    if a 1-frame jump > 250px (warp/respawn) → cancel_recording()
timer expires     → spawn Ghost, hand it the path (_active_clone, one at a time)
Ghost._process    → replay positions; its Hitbox → enemy.apply_element("clone")
Portal warp       → Gun.cancel_clone() + free all clones
```

## Music / Living-Weapon feedback

```
BeatClock (120 BPM) → on_beat()/pulse() → HUD gold flash, beat ring, on-beat power shots
WeaponProgress.register_use(key) → may emit leveled_up(key, lvl) → HUD banner + Audio "levelup"
                                   modes read level(key) to scale their effect
```

## Damage & scene flow

```
Enemy Touch area → player.take_damage(n)  (0.8s invuln)
player.hp <= 0   → GameStats.lose_life() → alive? respawn() : group("game_over").show_over()
Boss._die()      → group("win_screen").show_win()   (+ reveals the "victory" flag)
show_win/show_over → get_tree().paused = true
Menu button      → get_tree().paused = false → Transitions.change_scene()/reload()  (fade + unpause)
```

## Node lifetime & ownership

- **Autoloads** live for the whole process (never freed by scene changes).
- **Projectiles / bursts / ghosts** are spawned into `get_tree().current_scene` (always null-checked)
  and free themselves.
- **Zones** are static children of `main.tscn`; the world is one scene, not streamed.

## Collision matrix

See the table in [../GUIDE.md](../GUIDE.md#1-collision-layers--masks). One-liner: **layer 1 = world +
enemies**, **layer 2 = player**, **projectiles = layer 0 sensors** (the boss shot is the one exception,
on layer 1 so a time bolt can reflect it).
