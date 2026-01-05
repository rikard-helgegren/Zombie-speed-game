# Zombie Speed Shooter

**Genre:** 2D Top-Down Shooter / Survival

**Purpose:** Sneak around, with the sound of zombies around you and when detected, have a fun speedy shooting combat, where you feel awesome as the game character.

* **Platform:** PC (Windows/Linux/Mac) &  Web
* **Target Audience:** Casual Main game, with replayability of a speed run.

* **Game Pillars**

  * **Story Mode** Explorative, Sneaky, Easy
  * **Speed Mode** Intence, powerfull, Swift, X-times enemies


**One-sentence pitch:**

A 2D zombie shooter where you causiously explore a infested town, and turn it to a speed run challange whence the town is fully explored. 

## 2. Core Gameplay Loop 

1. Spawn into new map
2. Explore path to continue
3. Fight Zombies in the way
4. Kill all to unlock path forward 
4. Complete map for uppgrades

* What is fun every 10 seconds?
  Sneak and kill zombies
* What changes every 5 minutes?
  Map and player progression
---

## 3. Player Mechanics

### Controls

* Movement: WASD / Controller stick
* Aim: Mouse / Right stick
* Shoot: Left Click of Space / RT
* Reload: Right Click or 'R' / 'X'
* Dash: Shift / RB
* Hook: 'E' / 'Y' 

### Player Stats

* Health
* Movement speed
* Damage
* Fire rate
* Reload speed

### Abilities 

* 'Carbin rope' (Speed Mode)
* Temporary buffs (Speed mode)

---

## 4. Combat System

### Weapons

Pistol & Knife is only wepon in story mode

| Weapon  | Damage | Fire Rate |
| ------- | ------ | --------- |
| Knife   | High   | High      |
| Pistol  | Low    | Medium    |
| Shotgun | High   | Low       |
| SMG     | Low    | High      |
| Sniper  | High   | Low       |


### Shooting Model

* Hitscan
* Bullet spread (shotgun, SMG)
* Recoil (only in story mode?)

---

## 5. Enemies

| Name    | HP     | Speed   | Damage | Special |
| ------- | ------ | ------- | ------ | ------- |
| Normal  |  Low   | Medium  | Medium | None    |
| Tank    |  High  | Low     | High   | None    |


### AI Behavior

* Pathfinding (A* / Navigation2D)
* Chase player
* Spawn logic (fixed position)

---

## 6. Progression & Difficulty

* Permanent upgrades after each map

* Fixed spawning spot of zombies in story mode, additional in speed are randomely placed based on a seed to be the same each time.

* Difficulty scaling:
  * More enemies
  * Stronger enemies

---

## 7. Level / Map Design

* Map size: (2-5 min playthrough)
* Room size: mainly 1/2 Screen to 2 Screen size)
* Handcrafted

---

## 8. UI / UX

* Health bar
* Ammo counter
* Pause menu
* Game Over screen

---

## 9. Art Direction

* Visual style: Animated, high resolution
* Camera zoom level: ??
* Color palette: ??
* Zombie type visual clarity 

---

## 10. Audio Design

* Weapon sounds
* Zombie sounds
* Feedback sounds (hit, kill, No ammo)

Sneak mode:
* Player Walking sound
* Ambient music

Fight mode:
* Alert music

---

## 11. MVP 

**MVP Example:**

* One map
* One player
* One zombie type

Complete, upgarde, and replay with more zombies.

---

## 12. Open Questions / Future Ideas


* Story mode
* Generated map (seed)
* Generated monster positions (seed)
