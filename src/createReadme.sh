#!/usr/bin/env bash

create_readme () {
  mkdir -p "$1"
  echo -e "$2" > "$1/README.md"
}

create_readme core \
"# core/
Low-level, shared code used across the entire game.
Examples: constants, enums, math helpers, global utilities."

create_readme features \
"# features/
Gameplay features grouped by responsibility.
Each feature owns its scenes, scripts, and animations."

create_readme features/player \
"# player/
Player character logic, input handling, health, and animations."

create_readme features/zombies \
"# zombies/
All zombie enemies and variants.
Includes base zombie logic, AI, and specific zombie types."

create_readme features/zombies/ai \
"# zombie AI/
Zombie decision-making logic.
State machines, behavior trees, and AI states live here."

create_readme features/weapons \
"# weapons/
Player weapons and weapon logic.
Each weapon type has its own folder."

create_readme features/pickups \
"# pickups/
Collectible items such as ammo, health, or power-ups."

create_readme systems \
"# systems/
Game-wide systems used by multiple features.
Examples: combat, AI frameworks, spawning, saving."

create_readme ui \
"# ui/
User interface scenes and scripts.
HUD, menus, and reusable UI widgets."

create_readme assets \
"# assets/
Raw art, audio, and fonts.
No scripts or game logic should be placed here."

create_readme levels \
"# levels/
Game maps and environments.
Each level is typically a main scene."

create_readme data \
"# data/
Game balance and configuration data.
Resources (.tres) or JSON files for tuning."

create_readme autoload \
"# autoload/
Singletons registered in Godot's Autoload settings.
Examples: game state, audio manager, event bus."

create_readme addons \
"# addons/
Third-party or custom Godot plugins."

create_readme tests \
"# tests/
Automated or manual test scenes and scripts."

echo "Folder README files created ✔"

