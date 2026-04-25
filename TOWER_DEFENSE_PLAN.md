# Godot 4.6 Implementation Plan: "Tug-of-War" Tower Defense (Battle Cats Style)

**Target Agent:** Claude Code (or any AI coding assistant)
**Context:** Godot 4.6 project using GDScript. 2D Tug-of-War Tower Defense game.
**Goal:** Implement the foundational systems from scratch using placeholder graphics (ColorRect/Polygon2D) to establish core mechanics.

---

## Phase 1: Project Structure and Battlefield Setup

**Objective:** Set up the basic scene, camera, and the two opposing bases.

1.  **Directory Structure:**
    *   Create directories: `res://scenes/`, `res://scripts/`, `res://assets/`.
2.  **Main Scene (`res://scenes/Main.tscn`):**
    *   Create a `Node2D` named `Main`.
    *   Add a `Camera2D` (name: `Camera2D`). Set its position to the center of the play area.
    *   Add a `ColorRect` for the ground (e.g., green, spanning the bottom of the screen).
3.  **Base Setup:**
    *   Create a new scene: `res://scenes/Base.tscn` (Type: `Area2D`).
    *   Add a `ColorRect` (placeholder visual) and a `CollisionShape2D` (RectangleShape2D).
    *   Attach script: `res://scripts/base.gd`.
        *   **Variables:** `export var max_health: int = 1000`, `var current_health: int`, `export var is_player_base: bool = true`.
        *   **Functions:** `take_damage(amount: int)` (reduces health, emits signal `base_destroyed` if health <= 0).
4.  **Instance Bases in Main:**
    *   Instance two `Base` scenes in `Main.tscn`.
    *   Name one `PlayerBase` (set `is_player_base = true`, position on the left, color blue).
    *   Name the other `EnemyBase` (set `is_player_base = false`, position on the right, color red).

---

## Phase 2: The Entity Base Class

**Objective:** Create a unified system for both player units and enemy units since they share 90% of their logic.

1.  **Entity Scene (`res://scenes/Entity.tscn`):**
    *   Create an `Area2D` named `Entity`.
    *   Add a `ColorRect` (visual) and a `CollisionShape2D` (hitbox).
    *   Add an `Area2D` named `AttackRange` with a `CollisionShape2D` (for detecting targets).
    *   Add a `Timer` named `AttackCooldownTimer` (One Shot = true).
2.  **Entity Script (`res://scripts/entity.gd`):**
    *   **Exports:** `speed` (float), `max_health` (int), `damage` (int), `attack_cooldown` (float), `is_player_unit` (bool).
    *   **Variables:** `current_health` (int), `current_target` (Node2D), `state` (enum: MOVING, ATTACKING).
    *   **Movement Logic (`_physics_process`):** If `state == MOVING`, move along the X-axis (right if `is_player_unit`, left if `!is_player_unit`) using `position.x += speed * delta * direction`.
    *   **Target Detection:** Connect `AttackRange`'s `area_entered` and `area_exited` signals.
        *   If the entering area is an enemy `Entity` or enemy `Base`, set `state = ATTACKING` and start the `AttackCooldownTimer`.
    *   **Combat Logic:** When `AttackCooldownTimer` times out, call `take_damage()` on `current_target`. If target is dead/freed, set `state = MOVING`.
    *   **Health:** `take_damage(amount)` function. If `current_health <= 0`, `queue_free()`.

---

## Phase 3: Player Spawning & Economy

**Objective:** Allow the player to generate money and spawn units.

1.  **Game Manager (`res://scripts/game_manager.gd`):**
    *   Create as an Autoload (Singleton) named `GameManager`.
    *   **Variables:** `money: float = 0`, `money_generation_rate: float = 10.0`.
    *   **Logic:** `_process(delta)` adds `money_generation_rate * delta` to `money`.
2.  **UI Setup (`res://scenes/UI.tscn`):**
    *   Create a `CanvasLayer` named `UI`. Instance this in `Main.tscn`.
    *   Add a `Label` to display current `money`.
    *   Add a `Button` to spawn a basic unit.
3.  **Spawning Logic (`res://scripts/ui_manager.gd` attached to UI):**
    *   Connect the Button's `pressed` signal.
    *   Check if `GameManager.money >= unit_cost`.
    *   If yes, subtract cost, instance `Entity.tscn` (configured as player unit), set its global position to the `PlayerBase` spawn point, and add it to `Main`'s scene tree.

---

## Phase 4: Enemy Wave Manager

**Objective:** Automatically spawn enemies from the Enemy Base.

1.  **Wave Spawner Node:**
    *   Add a `Timer` to `Main.tscn` named `EnemySpawnTimer`. Set it to Autostart.
    *   In a script attached to `Main.tscn` (`res://scripts/main.gd`), connect the timer's `timeout` signal.
2.  **Enemy Spawning Logic:**
    *   On timeout, instance `Entity.tscn` (configured as an enemy unit: `is_player_unit = false`, different color, moves left).
    *   Set its position to the `EnemyBase` spawn point.
    *   Add it to the scene tree.

---

## Instructions for Execution (Claude Code)

1.  **Strictly adhere to Godot 4.6 syntax:** Use `@export`, `@onready`, `Signal` syntax (`signal_name.emit()`, `signal_name.connect()`).
2.  **Iterative Development:** Complete one phase entirely and verify its logic (e.g., units move and stop at each other) before moving to the next.
3.  **Signals over strict coupling:** Use signals for things like updating the UI or notifying when a base is destroyed.
4.  **Collision Layers/Masks:** Ensure proper setup so player units only detect enemy units/bases in their `AttackRange`, and vice versa. (e.g., Player Units on Layer 1, Enemy Units on Layer 2).
