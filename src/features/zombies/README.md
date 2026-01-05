# zombies/
All zombie enemy logic.

## Structure:
- zombie_base.gd → common functionality for all zombies
- ai/ → AI controllers and state machine
  - states/ → individual behaviors (idle, patrol, hunt_player, attack, stunned)

## Tips:
- AI behavior should be separated from movement (base) for modularity.
- Specific zombie types can extend zombie_base.
- Configure spawn points in levels, not here.

