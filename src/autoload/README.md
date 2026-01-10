# autoload/
Singleton scripts registered in Project → Autoload.

## Typical Scripts:
- game_state.gd → track current game state
- audio_manager.gd → centralized music and sound control
- input_manager.gd → handles player input globally
- event_bus.gd → global signal dispatcher

## Tips:
- Use autoloads for systems that need to be globally accessible.
- Keep them decoupled from level-specific logic.
