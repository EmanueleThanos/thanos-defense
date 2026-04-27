# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Thanos Defense** — Battle Cats-style tug-of-war tower defense game in Godot 4.6. Units march from left (player) or right (enemy), fight on contact, and push the frontline toward the enemy base.

## Running

- **Open in editor:** launch Godot Editor and open this directory, or `godot --path .`
- **Run project:** F5 in editor (main scene: `res://scenes/Menu.tscn`)
- **Run current scene:** F6 in editor

## Configuration

- **Engine:** Godot 4.6
- **Physics:** Jolt Physics (3D)
- **Renderer:** GL Compatibility (D3D12 on Windows via `rendering_device/driver.windows="d3d12"`)
- **Viewport:** 1280×720
- `project.godot` is best edited through the Godot Editor UI, not directly

## Conventions

- PascalCase for Node types and class names; snake_case for file names and variables/functions
- File encoding: UTF-8 (enforced by `.editorconfig`)
- `.godot/` is editor cache — do not commit it (already in `.gitignore`)

---

## Architecture

### Autoload

- **`GameManager`** (`scripts/game_manager.gd`) — single source of truth for all persistent state. Never duplicate state elsewhere.

### Scene flow

```
Menu.tscn
├── StageSelection.tscn  (story / legend / future chapter select)
│   ├── MapStory.tscn
│   ├── MapLegend.tscn   (procedural island with 3 temples)
│   └── MapFuture.tscn   (procedural space map, 5 stages)
├── Gacha.tscn
├── Equip.tscn
└── Upgrade.tscn         (visible only after completing legend stage 1)

Main.tscn  (battle)
└── UI.tscn (CanvasLayer, process_mode=ALWAYS)
```

---

## GameManager state

### Currencies
- `money: float` — battle money (€), resets each battle via `reset_battle()`
- `enemy_money: float` — enemy AI budget, same reset
- `mp: int` — persistent Meta Points earned by selling gacha duplicates
- Signals: `money_changed(float)`, `mp_changed(int)`, `tickets_changed(int)`

### Gacha / inventory
- `tickets: int` — gacha pull currency (start: 5)
- `owned_units: Array[int]` — unit IDs the player owns (start: [3])
- `active_deck: Array[int]` — units equipped for battle (start: [3])
- `unit_levels: Array[int]` — level per unit ID, index = unit_id (start: all 1)

### Permanent upgrades
- `production_level: int` (1–100) — money/s in battle: `15 + (485/98)*(level-1)`, level 100 = 1000 €/s
- `base_hp_level: int` (1–50) — player base HP: `1000 + 250*(level-1)`
- `max_units_level: int` (1–8) — deck slots: `2 + level` (3–10 different unit types in deck)
- Upgrade costs: units = `40*level` MP, production = `80*level` MP (level 99→100 costs much more), base HP = `60*level` MP, deck slots = `300*level` MP

### Stage progression
- `chapter_progress: Dictionary` — `{"legend": N, "future": N, "story": N}` where N = highest stage completed
- `current_chapter: String`, `current_stage: int` — set before entering battle via `start_stage()`
- `is_stage_unlocked(chapter, stage)` — true if stage==1 or stage <= progress+1
- `STAGE_DIFFICULTY` const — keyed as `"chapter_stage"` e.g. `"legend_1"`

### Stage difficulty
```
legend_1: enemy_hp=1000,  enemy_unit_level=1,  ticket_reward=1
legend_2: enemy_hp=1500,  enemy_unit_level=3,  ticket_reward=3
legend_3: enemy_hp=10666, enemy_unit_level=30, ticket_reward=12
```

### Key GameManager methods
- `draw_gacha() -> Dictionary` — single pull, deducts 1 ticket, returns `{unit_id, is_duplicate, color}`
- `draw_gacha_multi_preview(count) -> Array` — pulls N, deducts tickets, does NOT apply results yet; tracks within-pull duplicates via `seen` array
- `apply_gacha_results(results, sell_indices)` — applies kept cards (add/level-up), sells marked ones for MP
- `sell_gacha_duplicate(unit_id)` — adds `get_sell_price(unit_id)` MP
- `get_sell_price(unit_id) -> int` — `UNIT_COSTS[unit_id] * 0.4`
- `reward_win()` — adds ticket reward for current stage
- `complete_stage(chapter, stage)` — updates chapter_progress if new high
- `add_to_deck(unit_id)` — respects `get_max_units()` cap
- `get_stat_multiplier(unit_id) -> float` — `1.0 + 0.25*(level-1)` for player units
- `get_enemy_level_multiplier() -> float` — based on stage difficulty enemy_unit_level

---

## Units

### UNIT_STATS (index = unit_id)
| ID | Name     | Color            | Speed | HP  | Dmg | CD  | Range | Area |
|----|----------|------------------|-------|-----|-----|-----|-------|------|
| 0  | Guerrero | CORNFLOWER_BLUE  | 80    | 120 | 18  | 0.8 | 120   | no   |
| 1  | Rápido   | (0.88,0.28,0.18) | 140   | 60  | 32  | 0.6 | 60    | yes  |
| 2  | Tanque   | (0.22,0.65,0.30) | 50    | 500 | 30  | 3.0 | 70    | no   |
| 3  | Básico   | (0.8,0.8,0.8)    | 90    | 80  | 12  | 0.7 | 60    | no   |

### UNIT_COSTS (deploy cost in €): [75, 100, 150, 25]
### GACHA_POOL weights: Guerrero=40, Rápido=25, Tanque=10 (Básico not in pool — starting unit)

### Entity states: MOVING → ATTACKING → KNOCKBACK → MOVING
- Knockback triggers when damage >= 25% max HP (except Tanque, unit_type==2)
- Enemy AI uses units 0,1,2 with weighted random: weights [4,2,1]

---

## Unit visuals (`scripts/unit_visual.gd`)

Procedural Node2D drawing. Replaces the old ColorRect `$Visual` in `Entity.tscn`.

- `color: Color` — set by entity.gd from PLAYER_COLORS / ENEMY_COLORS
- `unit_type: int` — 0 = detailed soldier, others = simple colored rect
- `is_walking: bool` — controls walk cycle animation
- `play_attack()` — triggers muzzle flash + rifle recoil animation
- `play_knockback_visual()` — rifle floats away from hand (`_rifle_offset = 10`)
- `scale.x = -1.0` for enemy units (mirrors facing direction automatically)

**Soldier geometry** (coords relative to Node2D at feet, y negative = up):
- Feet: y=0, Legs: y=-5 to -28, Torso: y=-28 to -57, Neck: y=-57 to -63
- Head circle: center (0, -68) r=9, Helmet dome: (0, -72) r=7.5, Helmet brim: y=-65

**Known type inference issue:** `sin()` and `abs()` return Variant — always declare as `float`:
```gdscript
var w:   float = sin(_walk_phase)
var bob: float = abs(w) * 1.5
```

---

## Battle UI (`scripts/ui.gd`, `scenes/UI.tscn`)

- `CanvasLayer` with `process_mode = ALWAYS` so pause menu works while paused
- Bottom bar: spawn buttons (one per active_deck unit) + money label
- Spawn buttons: 90×95px, contain a `unit_visual.gd` Node2D (scale 0.72, feet at y=66) + key label + cost label
- **IMPORTANT:** `mouse_filter` is a Control property — do NOT set it on Node2D (unit_visual)
- Pause: ☰ PAUSA button top-left + ESC key → PauseOverlay with music/SFX sliders + CONTINUAR + RETIRADA
- RETIRADA requires confirmation → goes to StageSelection.tscn
- Volume: AudioServer buses named "Music" and "SFX"
- Battle money displayed as `"€ %d"`, spawn costs as `"€%d"`

---

## Gacha (`scripts/gacha_scene.gd`, `scenes/Gacha.tscn`)

- Single pull: x1 (always visible if tickets > 0)
- Multi pulls: x5 (visible ≥5), x12 (visible ≥12), x100 (visible ≥100)
- Multi pulls use `draw_gacha_multi_preview(count)` → `_show_interactive_grid(results)`
- Grid: 5 columns if ≤5 results, else 4 columns
- Cards are flippable: click → scale X tween 1→0, create new card, tween 0→1
  - Normal card: colored background, unit name + NEW or duplicate level
  - Flipped to sell: red background, shows sell price in MP
- "RECOGER TODO" button: calls `apply_gacha_results(_pending_results, _sell_set)`
- **IMPORTANT:** Do NOT name local variables `draw` — it shadows CanvasItem's `draw` signal. Use `result` instead.

---

## Maps

### MapLegend (`scripts/legend_map.gd`)
Procedural island: layered ocean → reef → beach → jungle polygons. 90 palm trees + 140 flowers filtered by ellipse check. Stone path with moss connecting 3 Mayan temple stages. Waterfall with pre-generated offsets (avoid RNG in `_draw()`). Stage buttons read `GameManager.is_stage_unlocked("legend", N)`.

### MapFuture (`scripts/future_map.gd`)
Procedural space scene: stars with color temperature, Milky Way band, nebulae, Earth with continents + atmosphere, Moon, ISS, asteroids, Mars, Jupiter, comet. Camera drag + clamp. All 5 stage buttons start disabled.

### MapStory (`scenes/MapStory.tscn`)
Placeholder, goes to Main.tscn.

---

## Equip menu (`scripts/equip_menu.gd`)

- Shows ONLY owned units (skip non-owned entirely — no grayed-out cards)
- Each card: 150×195 Button with unit_visual.gd sprite (scale 1.5, feet at y=158) + name/level/cost text
- Active deck units highlighted in yellow (modulate Color(1,1,0))
- Tapping a card adds/removes it from active_deck (respects get_max_units() cap)

---

## Upgrade menu (`scripts/upgrade_menu.gd`, `scenes/Upgrade.tscn`)

- Visible in Menu only after `chapter_progress["legend"] >= 1` (completing Pre-Leyenda)
- Sections: UNIDADES (per owned unit) and BASE (HP, Producción, Slots de mazo)
- Rebuilds dynamically on `mp_changed` signal
- "Slots de mazo" = different unit types you can equip (NOT units deployed in battle — battle always allows 500)

---

## Common pitfalls

- `sin()`, `abs()`, `randf()` etc. return Variant — always annotate with `: float`
- Knockback tilt uses `$Visual.rotation` — works on Node2D (not just Control)
- `modulate:a` tween works on Node2D via CanvasItem
- Pre-generate random values in `_ready()` with a fixed seed; never call `randf()` inside `_draw()`
- When adding Node2D as child of Control: position is relative to Control's top-left in viewport space; `mouse_filter` does NOT exist on Node2D
- `get_tree().paused = false` in `main.gd _ready()` to clear stale pause state from previous scene
