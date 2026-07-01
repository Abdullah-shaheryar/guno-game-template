# Enemies — hostiles, boss, and the clone

Every enemy shares one contract: it takes **element** hits and **time** hits, damages itself, and
dies juicy. There is no base class — the shared shape is a convention (copy a sibling).

## Files

| File | Role |
|---|---|
| `walker.gd/.tscn` | Ground patroller (`class_name Walker`). Gravity-aware; fire burns, ice freezes, electric stuns. |
| `flyer.gd/.tscn` | Hovering chaser. **Gravity-aware** (re-orients hover/pursuit along `down`). |
| `turret.gd/.tscn` | Stationary `StaticBody2D`; aims + fires a `boss_projectile` on an interval; ice/electric disable it. |
| `boss.gd/.tscn` | Mini-boss: **shielded until electric**, phases by HP, gravity-flip stuns it (with cooldown), time reflects its shots. |
| `boss_projectile.gd/.tscn` | Boss shot; damages player; a rewind (`apply_time` dir<0) reflects it to damage the boss. |
| `../clone/ghost.gd/.tscn` | The recorded clone. Replays a path; its `Hitbox` damages enemies via `apply_element("clone")`. |

## The enemy contract

```gdscript
func _ready():                       add_to_group("enemy")   # boss also add_to_group("boss")
func apply_element(element, bullet): # fire/ice/electric/clone; read bullet.damage only if "damage" in bullet
func apply_time(direction, _bolt):   # +1 = damage, -1 = special (reset/stun/reflect)
func _take_damage(amount):           # hp -= amount; flash; Juice.shake + Audio "hit"; hp<=0 -> _die()
func _die():                         # Juice.burst/shake/hitstop; queue_free()  (boss: signal victory first)
```

Contact damage: a `Touch`/`Hurt` `Area2D` (layer 0, mask 2) calls `player.take_damage(...)`.

## Add an enemy

Copy `walker.gd/.tscn` (ground) or `flyer.gd/.tscn` (air). Implement the contract above, keep the
body on **layer 3 (value 4) / mask 1** — so the player passes *through* it (contact damage via the
`Touch` area) instead of being physically blocked/launched — cache the player via a lazy group
lookup, use `Juice`/`Audio` for feedback. Full recipe: [../../docs/EXTENDING.md](../../docs/EXTENDING.md).

## Invariants & gotchas

- **Boss shield gates damage**: `apply_element("electric")` drops it for 4s; fire deals 2× while down;
  other elements and clone do **nothing** while shielded. Don't bypass.
- **Boss gravity-stun has a 1s cooldown** (`GRAVITY_FLIP_CD`) so rapid flips can't stunlock it.
- **Ghost routes through `apply_element("clone")`** (so the boss shield still applies) and only falls
  back to `_take_damage`; it never `queue_free`s an enemy directly.
- **Reflected boss shots pass through world geometry** (only `from_boss` shots die on `StaticBody2D`).
- Enemies **poll `GravityManager.down`** each physics frame (they don't subscribe) — a 1-frame desync is possible.
- `_take_damage` checks `hp <= 0.0` (not `< 0`); the burn-DoT loop calls `_die()` inline, so guard against double-death.
- Gravity-aware enemies must set `up_direction = -down` and compute patrol/hover along the gravity axis, not world-Y.
