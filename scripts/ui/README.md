# UI — HUD, menus, screens, scene flow

Logic lives in `scripts/ui/`; the matching scenes/themes live in `scenes/ui/`. UI is **read-only on
game state** — it pulls from autoloads and groups; it never owns gameplay data.

## Files

**In-game HUD** (children of `scenes/ui/hud.tscn`, a `CanvasLayer` instanced in `main.tscn`):
| File | Shows |
|---|---|
| `hud.gd` | Gun `status_text()`, ♥ lives / ✦ shards, level-up banner, on-beat gold pulse, `[H]` toggle. |
| `health_bar.gd` | Fill + colour from `player.hp / player.max_hp` (group `player`). |
| `mode_indicator.gd` | Four chips; lights the active `gun.current` (group `gun`). |
| `beat_ring.gd` | Dot that swells/flashes on `BeatClock.pulse()`/`on_beat()`. |
| `hint_label.gd` | Transient centre-bottom hint; `show_hint(text)`; in group `hint_label`. |

**Menus & screens** (each its own scene; `menu_theme.tres` is the shared style):
| File | Role |
|---|---|
| `main_menu.gd` (`main_menu.tscn` = boot scene) | Play → `GameStats.reset()` + `Transitions.change_scene(main.tscn)`; volume slider; How-to panel. |
| `title.gd` | Optional splash; any key → `Transitions.change_scene(main.tscn)`. |
| `pause_menu.gd` | `Esc` toggles `get_tree().paused`; Resume/Restart/MainMenu/Quit. Skips pausing if `win_screen` showing. |
| `win_screen.gd` | Group `win_screen`; `show_win()` (called by boss death) pauses + shows victory. |
| `game_over.gd` | Group `game_over`; `show_over()` (called by player death at 0 lives) pauses + shows retry. |

## Scene flow

`main_menu.tscn` → `main.tscn` (HUD + gameplay) → **boss dies** → `win_screen.show_win()` · or
**lives hit 0** → `game_over.show_over()`. Restart/Retry → `Transitions.reload()`; MainMenu →
`Transitions.change_scene(...)`. All transitions fade (~0.35s each way) and unpause the tree.

## CanvasLayer ordering

HUD (default) < PauseMenu (40) < WinScreen (50) < GameOver (55) < Transitions (100).

## Add UI

- **HUD widget:** new script `extends CanvasItem` in `scripts/ui/`, read state via `/root/...` or a
  group in `_process`, add it under `hud.tscn`.
- **Screen:** new scene + `CanvasLayer` script, style with `menu_theme.tres`, drive via
  `Transitions` / `get_tree().paused`. Trigger it from gameplay through its group.

## Invariants & gotchas

- HUD reads `gun.status_text()` each frame; missing → falls back to `"GUNO"`.
- **`[H]` toggles HUD child visibility but is gated on `not get_tree().paused`** (can't hide it behind a menu).
- A screen that pauses (`get_tree().paused = true`) **must unpause before leaving**, or the next scene freezes
  (`Transitions` already handles this for its own changes).
- Button pops need `pivot_offset` set before the scale tween or they animate from the top-left corner.
