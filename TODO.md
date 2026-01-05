


1) make game design document
2) prototype on just one mapp





# AI below here (Generated)

1. Game Design Document: Define the core loop, modes (Normal/Speed/Sneak/Free fight/Survivor), win/lose conditions, progression, and target platforms. Recommendation: keep it concise (2–4 pages) and include reference visuals and sample pacing for a 10–15 minute session.

2. Vertical Slice Prototype: Build one complete playable loop on a single map including movement, shooting, grappling, one enemy type, and victory/loss flow. Recommendation: use placeholder art and focus on feel and telemetry hooks.

3. Core Mechanics Polish: Iterate movement, dash, grapple physics, aiming and hit detection until controls feel tight. Recommendation: add simple tuning variables so designers can tweak speed, drag, and stun times at runtime.

4. Enemy Types & Balance: Implement base enemies (Normal, Speed, Tank, Range, Explode, Spawner) with clear roles and telegraphed behaviors. Recommendation: define counters (e.g., stun vs tank) and base HP/damage tables.

5. AI & Pathfinding: Create a robust AI state machine (idle, patrol, alert, combat, flee) and lightweight pathfinder for indoor maps. Recommendation: start with navigation grids or navmesh and profile CPU cost early.

6. Combat Feel & Feedback: Add hitstop, screen shake, particle FX, and sound cues for hits, kills and near-misses. Recommendation: aim for perceptible feedback within 100–200 ms of an event.

7. Level Design Tools: Build simple data-driven level formats or an editor to place spawn points, pickups, and lighting. Recommendation: design prototype JSON format before adding a full editor.

8. Procedural & Arena Modes: Implement procedural map generation for Free fight and Survivor modes with seeded randomness for reproducibility. Recommendation: expose seed input for testing and speedruns.

9. Powerups & Progression: Design temporary powerups (killstreak, lamps, loot boxes) and a lightweight progression/equipment system. Recommendation: keep progression optional — focus on temporary, explanatory powerups first.

10. Game Modes & Mode Rules: Flesh out rules and scoring for Speed (time), Sneak (detection), Free fight (clear rate), Survivor (wave scaling). Recommendation: create mode-specific UI mockups and test each mode separately.

11. UI / HUD / Menus: Implement clear HUD (health, ammo, timer, detection meter), pause/menu flow, and mode selection. Recommendation: prototyping wireframes first then iterate with playtests.

12. Audio & Music System: Compose or source adaptive music layers (exploration vs combat) and build SFX bank for weapons, footsteps, and ambience. Recommendation: use temporary tracks early to tune pacing.

13. Lighting & Visuals: Implement flashlight cone, bonfire lighting, and post-process effects to sell atmosphere. Recommendation: make flashlight intensity a tunable parameter for level design.

14. Save System & Leaderboards: Store player equipment, stats and top scores; implement local and optional online leaderboards. Recommendation: start with local persistence, add online later.

15. Analytics & Telemetry: Track runs, deaths, completion times, and mode-specific metrics to inform balance. Recommendation: add simple event hooks early (start/run end/death) before mass content.

16. Playtesting & Difficulty Tuning: Run internal playtests, iterate enemy stats, and define difficulty curves. Recommendation: use automated parameter sweeps and record replays for testers.

17. Performance & Optimization: Profile CPU/GPU, reduce allocations, and optimize physics/AI loops for target platforms. Recommendation: set performance budgets for low-end and target devices.

18. Controls & Accessibility: Add remappable controls, difficulty options, colorblind-friendly visuals, and input smoothing. Recommendation: include joystick and mouse/keyboard presets.

19. Build Pipeline & QA: Create CI build tasks, smoke tests, and platform packaging scripts. Recommendation: automate builds for the platforms you intend to support first.

20. Marketing & Launch Prep: Prepare trailer, store assets, community playtests, and a launch roadmap (beta → early access → 1.0). Recommendation: gather a small core of testers and start creating assets early.




