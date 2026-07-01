# Zones — the world & how it's assembled

The game world is **one continuous horizontal strip in absolute world coordinates**. `main.tscn`
instances each zone scene (at origin) plus baseline ground, the player, UI, and shared props.

## Layout (left → right, world X)

| Zone | Scene | Teaches | Entry X (portal `target`) |
|---|---|---|---|
| Hub | `hub.tscn` | — (5 portals) | player starts here (~ −1000) |
| 1 · Elemental | *in `main.tscn`* (GroundA/B, ice wall, water gap, power door) | fire/ice/electric | 200 |
| 2 · Gravity | `zone2.tscn` | gravity flip (+ stepping stones over the gap) | 3300 |
| 3 · Time | `zone3.tscn` | rewind/forward (bridge, tree) | 5300 |
| 4 · Clone | `zone4.tscn` | record/replay (plate + gate) | 7150 |
| Boss | `zone_boss.tscn` | combine everything | 9000 |

`background.tscn` (parallax, z −100) and `underground.tscn` (dark fill) frame it. The **hub portals**
warp to those entry X's; `debug_warp.gd` mirrors them on keys `1`–`4`.

## Level-design budget (must respect)

Player jump: `jump_velocity=620`, `gravity=1400`, `speed=300` ⇒ **~137px max climb, ~266px max gap.**
- Floors sit at **world y=660** (top surface y≈620); small platforms/ledges y≈560–620; ceilings/spikes y≈150–200.
- A gap wider than ~180px or a wall taller than ~130px **needs** stepping platforms or a mode crossing
  (freeze water / gravity-flip onto a ceiling / time-bridge). That's the puzzle — but always leave a fair path.

## Add a zone

1. `scenes/zones/zoneN.tscn`, `Node2D` root. Entry + exit floors as `StaticBody2D` (**layer 1 / mask 0**)
   with `Polygon2D` + `CollisionShape2D`. Add enemies/props as instances. Add an `ExitFlag` (no collision).
2. Instance it into `main.tscn`.
3. In `hub.tscn`, add a `Portal` with `target = Vector2(entry_x, 400)`, `label`, `tint`.
4. Optionally add a `DebugWarp` point. Full recipe: [../../docs/EXTENDING.md](../../docs/EXTENDING.md).

## Invariants & gotchas

- **Coordinates are absolute world-space**, not zone-relative (zones instance at origin). `Portal.target`
  is a raw world `Vector2` — if you ever offset a zone, adjust its portal target too.
- **Portal warp height `y=400`** is the canonical safe drop above `y=660` floors — don't warp into geometry.
- Keep floors at `y=660` for consistency; measure every gap/wall against the jump budget above.
- Boss arena is walled (LeftWall/RightWall) — it's **portal-entry only** by design.
- Pits deeper than `fall_distance` (1300px) below the last safe floor trigger a free reposition (no life lost).
