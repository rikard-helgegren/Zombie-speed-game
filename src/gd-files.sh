#!/usr/bin/env bash

create_readme () {
  DIR="$1"
  CONTENT="$2"
  
  mkdir -p "$DIR"
  echo -e "$CONTENT" > "$DIR/README.md"
  echo "Created README in $DIR"
}

# =========================
# Core
# =========================
create_readme core \
"# core/
Contains low-level, shared code used across the entire game.

## Responsibilities:
- Constants, enums, and global definitions
- Math helpers and utility functions
- Game-wide configurations

## Tips:
- Keep logic here minimal and universal.
- Avoid putting level-specific or feature-specific code here.
"

# =========================
# Autoload
# =========================
create_readme autoload \
"# autoload/
Singleton scripts registered in Project → Autoload.

## Typical Scripts:
- game_state.gd → track current game state
- audio_manager.gd → centralized music and sound control
- input_manager.gd → handles player input globally
- event_bus.gd → global signal dispatcher

## Tips:
- Use autoloads for systems that need to be globally accessible.
- Keep them decoupled from level-specific logic.
"

# =========================
# Player
# =========================
create_readme features/player \
"# player/
Contains all player-related logic.

## Typical Scripts:
- player.gd → movement, collision, animation
- player_input.gd → input mapping and handling
- player_health.gd → health, damage, death

## Tips:
- Keep movement and health separate for clarity.
- Input handling should be modular to allow AI control if needed.
"

# =========================
# Zombies
# =========================
create_readme features/zombies \
"# zombies/
All zombie enemy logic.

## Structure:
- zombie_base.gd → common functionality for all zombies
- ai/ → AI controllers and state machine
  - states/ → individual behaviors (idle, patrol, hunt_player, attack, stunned)

## Tips:
- AI behavior should be separated from movement (base) for modularity.
- Specific zombie types can extend zombie_base.
- Configure spawn points in levels, not here.
"

create_readme features/zombies/ai \
"# ai/
High-level zombie AI controller scripts.

## Responsibilities:
- Choosing states for zombies
- Handling perception (sight, sound)
- Triggering state transitions

## Tips:
- Keep AI decision-making here; movement stays in zombie_base.
"

create_readme features/zombies/ai/states \
"# states/
Individual AI state scripts.

## Example States:
- idle.gd → zombie waiting
- patrol.gd → walking predefined path
- hunt_player.gd → chasing the player
- attack.gd → close-range attack
- stunned.gd → temporary incapacitation

## Tips:
- Use a State Machine to swap states dynamically.
- Keep states focused: one responsibility per script.
"

# =========================
# Weapons
# =========================
create_readme features/weapons \
"# weapons/
Player weapons logic.

## Structure:
- weapon_base.gd → shared functionality (damage, cooldown)
- pistol/, shotgun/, melee/ → specific weapon types

## Tips:
- Make weapons modular and data-driven.
- Avoid hardcoding values; use exported variables or resources.
"

# =========================
# Pickups
# =========================
create_readme features/pickups \
"# pickups/
Collectible items like health and ammo.

## Structure:
- pickup_base.gd → base logic
- health_pickup.gd → restores player health
- ammo_pickup.gd → restores ammo

## Tips:
- Use Area2D with signals for pickup detection.
- Keep logic minimal; levels handle placement.
"

# =========================
# Systems
# =========================
create_readme systems \
"# systems/
Shared systems used across multiple features.

## Examples:
- Combat → damage calculation, hit detection
- AI → State machine base classes
- Spawning → enemy or item spawners
- Save → game saving and loading

## Tips:
- Systems should be reusable and not tied to one feature.
- Keep state machine logic separate from actual entity scripts.
"

# =========================
# UI
# =========================
create_readme ui \
"# ui/
All user interface elements.

## Structure:
- hud/ → in-game HUD elements
- menus/ → main menu, pause menu, settings
- widgets/ → reusable UI elements like health bars

## Tips:
- Keep UI logic separate from game logic.
- Use CanvasLayer for HUD so it stays above the game world.
"

# =========================
# Levels
# =========================
create_readme levels \
"# levels/
Level scenes and scripts.

## Base Level (level_base):
- Shared logic for all levels
- Player spawning
- Camera setup
- HUD hookup
- Level start/end, win/lose conditions
- Zombie spawner hookup

## Specific Levels:
- TileMap and layout
- Props and decorations
- Unique spawn points and environmental hazards
- Level-specific events or cutscenes

## Tips:
- Keep level_base focused on rules of the game.
- Specific levels define content and layout only.
- Avoid hardcoding enemy AI or placement in base level.
"

# =========================
# Assets
# =========================
create_readme assets \
"# assets/
All raw art, audio, and fonts.

## Structure:
- art/ → characters, zombies, weapons, environment
- audio/ → music, SFX, zombie sounds
- fonts/ → in-game fonts

## Tips:
- Never put scripts here.
- Keep a consistent naming scheme for easy reference in Godot.
"

# =========================
# Addons
# =========================
create_readme addons \
"# addons/
Third-party or custom Godot plugins.

## Tips:
- Keep plugins self-contained.
- Avoid modifying core project logic here.
"

# =========================
# Tests
# =========================
create_readme tests \
"# tests/
Automated or manual test scripts.

## Examples:
- combat_tests.gd
- ai_tests.gd

## Tips:
- Keep tests separate from production code.
- Use tests to validate game mechanics and AI behaviors.
"

echo
echo "✅ All READMEs generated with detailed guidance!"
