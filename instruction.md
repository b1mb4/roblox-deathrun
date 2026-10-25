# Task: Create a Complete Roblox Deathrun Game

You are an experienced Roblox game developer specializing in Roblox Studio, Luau scripting, multiplayer game architecture, game design, and user experience.

Your task is to create a complete, playable Roblox game inspired by the **Deathrun game mode from Counter-Strike 2**.

Do not merely describe how to build the game. Implement the actual game in the available Roblox Studio environment, create the necessary instances, scripts, UI, and gameplay systems, and test the result whenever possible.

If you have access to Roblox Studio through computer-use tools, interact with Studio directly. If you are working with project files instead, create a complete, organized Roblox project that can be imported or opened in Studio.

## 1. Core Gameplay

The game consists of two sides:

### Side A — Runners

Runners must reach the finish line by navigating a course filled with obstacles, traps, gaps, moving platforms, and other hazards.

Their objective is to survive and reach the finish.

Runners should be able to:
- Run, jump, and perform normal Roblox character movement.
- Navigate obstacle courses.
- Avoid traps activated by players on the opposite side.
- Observe environmental cues that help them anticipate certain traps.
- Reach checkpoints throughout the course.
- Win the round by reaching the finish line.
- Switch to the trap-controller side after dying.

### Side B — Trap Controllers

Trap controllers remain in a designated area beside or above the runner course.

They cannot directly kill runners using weapons. Instead, they activate traps by pressing designated buttons.

Examples of traps:
- A floor section that disappears.
- A collapsing bridge.
- A swinging hammer.
- A moving wall that pushes runners off the platform.
- A falling ceiling or crushing block.
- A rotating obstacle.
- A temporary laser barrier.
- A platform that tilts or moves.
- A trap that opens a pit.
- A trap that launches runners into the air.

Each button controls a specific trap or a specific trap activation mechanism.

Trap controllers should be able to see the course and understand what their buttons do.

When a runner dies, they should respawn on the trap-controller side and join the other players in activating traps against the remaining runners.

The gameplay should become more challenging for runners as more players join the controller side.

## 2. Team and Player State Management

Implement a robust multiplayer state system.

Each player must have a server-controlled state, such as:
- `Runner`
- `TrapController`
- `Spectator`, if needed
- `Lobby`, when a round is not active

Rules:
1. Players initially enter the lobby.
2. At the start of a round, assign players to the runner and trap-controller sides.
3. When a runner dies, switch their state to `TrapController`.
4. Respawn the eliminated runner at the trap-controller spawn point.
5. Prevent eliminated runners from returning to the runner course during the same round.
6. Trap controllers must never accidentally trigger traps while they are still runners or in the lobby.
7. When only one runner remains, continue the round until that player finishes, dies, or the round timer expires.
8. End the round when the win conditions are met.
9. Show the winner and round results.
10. Reset all traps and player states before the next round.

For very small servers, support a sensible minimum-player mode so the game can be tested with one or two players. Do not make the game impossible to test because a full server is unavailable.

Use a centralized server-authoritative round manager. Avoid creating multiple independent systems that can conflict over player teams, deaths, or respawns.

## 3. Trap Button System

Create an interactive control panel for trap controllers.

Each trap must have:
- A unique identifier.
- A name and description.
- A button in the control panel.
- A corresponding physical trap in the course.
- An activation function.
- A cooldown.
- An optional activation animation.
- A visual and audio indication when activated.
- A clear indication when the trap is on cooldown.

Example trap configuration:

- Trap ID: `CollapsingBridge`
- Display name: `Collapsing Bridge`
- Cooldown: 8 seconds
- Activation duration: 3 seconds
- Effect: Bridge sections temporarily disappear, potentially causing runners to fall.
- Reset behavior: All bridge sections return to their original positions.

Use configurable cooldown values rather than hardcoding cooldown logic separately into every button.

### Cooldown requirements

Implement the following behavior:

1. Each trap has its own cooldown.
2. A player cannot activate the same trap repeatedly while it is on cooldown.
3. Different traps can have independent cooldowns.
4. Add a short activation debounce to prevent duplicate requests caused by rapid clicking.
5. Validate cooldowns on the server, not only in the UI.
6. The UI must display the remaining cooldown, preferably as a countdown or progress indicator.
7. Disable or visually dim a button while its trap is unavailable.
8. Display a brief activation animation when a trap is successfully triggered.
9. Prevent unauthorized players from triggering traps by exploiting RemoteEvents.
10. Prevent a trap from being activated if the current round state does not allow it.
11. Ensure cooldown timers do not reset when a player respawns.
12. Handle multiple players attempting to activate the same trap simultaneously without allowing duplicate activations.

### Cooldown design

Use two separate concepts:

- **Trap cooldown:** Shared across all trap controllers. Once a trap is activated, nobody can activate that trap again until its cooldown expires.
- **Player input debounce:** A very short server-side protection against duplicate requests from one player.

For the initial version, use these configurable default cooldowns:

| Trap | Cooldown | Active duration |
|---|---:|---:|
| Collapsing Bridge | 8 seconds | 3 seconds |
| Swinging Hammer | 6 seconds | 2 seconds |
| Falling Ceiling | 10 seconds | 3 seconds |
| Moving Wall | 7 seconds | 4 seconds |
| Rotating Platform | 9 seconds | 5 seconds |
| Pitfall | 12 seconds | 3 seconds |

These values should be easy to modify from a centralized trap configuration module.

If the same trap can affect multiple runners, activating it should affect all eligible runners in its designated area, rather than only the first player detected.

## 4. Control Panel UI

Create a polished Roblox interface for trap controllers.

The interface should include:
- A button for every available trap.
- Trap names and icons.
- Cooldown countdowns.
- Active/cooling-down states.
- A short description of each trap.
- An indication of which traps are currently available.
- A counter showing the number of remaining runners.
- Current round status and time remaining.

Make the UI readable on both desktop and mobile devices.

Use Roblox-supported UI components and Luau scripts. The UI must be functional, not merely decorative.

When a player becomes a runner, hide the trap-control panel. When they die and become a trap controller, display it.

Do not allow client-side UI state to determine whether a trap can actually be activated. The server is authoritative.

## 5. Map and Level Design

Build a complete initial map containing:

1. A lobby and waiting area.
2. A runner starting platform.
3. A clearly marked obstacle course.
4. A parallel or elevated trap-controller area.
5. Trap activation buttons or an equivalent interactive panel.
6. Checkpoints.
7. A finish platform.
8. A kill zone beneath the course.
9. Separate spawn points for runners and trap controllers.
10. Clear visual separation between the two sides.

The trap controllers should have a useful view of the course without being able to physically interfere with runners through unintended collisions.

The runner course should contain a mix of:
- Basic jumps.
- Narrow platforms.
- Gaps.
- Moving obstacles.
- Timed hazards.
- Trap-dependent sections.
- A final challenge near the finish.

Start with one polished, complete map rather than generating many unfinished maps.

Design the course so that runners have a reasonable opportunity to react to traps. Avoid making every obstacle unavoidable.

Use consistent materials, lighting, colors, signs, and visual effects. Make the environment look like an intentional multiplayer game rather than a collection of randomly placed parts.

## 6. Round System

Implement a complete round lifecycle:

1. Waiting for players.
2. Intermission countdown.
3. Player assignment.
4. Round start.
5. Active gameplay.
6. Runner elimination or finish detection.
7. Winner determination.
8. Results display.
9. Trap reset.
10. Player repositioning.
11. Next round.

Provide configurable values for:
- Minimum players.
- Intermission duration.
- Round duration.
- Maximum number of rounds, if applicable.
- Checkpoint behavior.
- Runner and controller spawn locations.

For testing, support a development configuration with short timers and relaxed player requirements. Make sure production settings can be restored easily.

The round manager must handle disconnects, character respawns, unexpected deaths, and players joining during an active round.

Do not allow a player joining mid-round to bypass the intended state system.

## 7. Scoring and Progression

Implement a simple, functional scoring system.

Possible rewards:
- Runners receive points for finishing.
- Trap controllers receive points when their traps contribute to runner eliminations.
- Players receive participation rewards.
- Add a small bonus for completing a round without leaving.

Prevent duplicate rewards for the same elimination or finish.

Do not award points simply because a trap was activated; reward successful gameplay outcomes where practical.

Use server-side validation for scoring.

If persistent data storage is implemented, use Roblox DataStoreService safely and handle failed requests. Persistent storage should not be required for the core game to function in Studio testing.

## 8. Technical Architecture

Use Roblox Luau and standard Roblox services.

Prefer a modular architecture with clearly separated responsibilities.

Suggested structure:

- `ReplicatedStorage`
  - `Remotes`
  - `Shared`
    - `TrapConfig`
    - `GameConfig`
    - Shared constants and types

- `ServerScriptService`
  - `Main.server.lua`
  - `Services`
    - `RoundService`
    - `PlayerStateService`
    - `TrapService`
    - `SpawnService`
    - `ScoringService`

- `StarterPlayer`
  - `StarterPlayerScripts`
    - Client-side UI and input handling, where appropriate

- `StarterGui`
  - `TrapControlGui`
  - `RoundStatusGui`
  - `ResultsGui`

- `Workspace`
  - `Map`
  - `RunnerCourse`
  - `TrapControllerArea`
  - `Traps`
  - `Spawns`
  - `Checkpoints`
  - `Finish`
  - `KillZone`

You may adjust this structure if your implementation tools or Roblox Studio workflow require it, but maintain clear separation of concerns.

Create missing folders and instances programmatically when appropriate.

Use RemoteEvents for client-to-server requests and server-to-client UI updates.

The client should request trap activation, while the server verifies permissions, cooldowns, round state, and trap validity before activating the trap.

Do not trust client-supplied player states, cooldown values, scores, or trap outcomes.

Use `CollectionService` tags or another reliable registration mechanism if it improves trap and checkpoint management.

Avoid unnecessary loops, excessive remote traffic, memory leaks, and connections that are never disconnected.

## 9. Trap Implementation Requirements

Implement real gameplay effects, not placeholder buttons.

Each trap must:
- Have a physical or otherwise clearly visible effect.
- Affect runners in the correct area.
- Avoid affecting trap controllers unless explicitly intended.
- Return to its original state after its activation duration.
- Clean up temporary objects, tweens, and connections.
- Recover correctly if a round ends while the trap is active.

Use reusable trap logic where practical, but preserve unique behavior for individual traps.

For example:
- A collapsing bridge temporarily disables or moves selected bridge sections.
- A swinging hammer moves through a defined path.
- A falling ceiling descends and then resets.
- A moving wall travels across the course.
- A rotating platform changes its orientation and returns to normal.
- A pitfall opens a section of the floor temporarily.

Avoid relying on client-only physics or client-only damage detection.

## 10. Security and Multiplayer Reliability

The game must be designed for real multiplayer servers.

Implement:
- Server-side state validation.
- Server-side cooldown enforcement.
- Server-side trap activation.
- Server-side finish detection.
- Server-side scoring.
- Protection against duplicate elimination events.
- Protection against repeated or forged RemoteEvent requests.
- Correct handling of player disconnects.
- Safe cleanup of active traps when rounds end.
- Reliable character death and respawn handling.

Do not use deprecated Roblox APIs when supported alternatives are available.

Avoid granting arbitrary network ownership of critical trap mechanisms to clients.

Keep important game state on the server and replicate only the information needed by clients.

## 11. Audio, Effects, and Feedback

Add suitable visual and audio feedback:
- Trap activation sounds.
- Trap warning indicators.
- Cooldown feedback.
- Runner checkpoint feedback.
- Finish-line effects.
- Elimination notification.
- Round start and end notifications.

Use only assets you can legally use and verify. If suitable asset IDs are unavailable, create the game so these assets can be configured later without breaking the core gameplay.

Do not use placeholder asset IDs that cause runtime errors.

## 12. Testing and Acceptance Criteria

Do not consider the task complete merely because scripts have been written.

Test the following scenarios in Roblox Studio whenever the available environment permits:

1. A player can join the lobby and enter a round.
2. A runner can move through the course.
3. A trap controller can activate a trap.
4. The trap produces its intended physical effect.
5. A trap cannot be activated again before its cooldown expires.
6. Different traps can be activated independently.
7. Two controllers cannot activate the same trap simultaneously.
8. A runner who dies is moved to the trap-controller side.
9. The eliminated runner can activate traps in subsequent gameplay.
10. Trap controllers cannot activate traps while assigned as runners.
11. A runner can finish the course and receive the appropriate reward.
12. The round ends correctly when its win conditions are satisfied.
13. All traps reset between rounds.
14. Players disconnecting mid-round do not break the round manager.
15. UI updates correctly when player states change.
16. Mobile and desktop UI layouts remain usable.
17. The game does not generate critical errors during normal gameplay.

Use Roblox Studio's multiplayer testing tools when possible.

If automated or interactive testing is unavailable, clearly distinguish verified functionality from untested functionality. Do not claim tests passed when they were not executed.

Fix all errors discovered during testing before declaring the task complete.

## 13. Implementation Workflow

Follow this order:

Phase 1: Inspect the available environment and determine how you can create or edit a Roblox experience.

Phase 2: Build the map, folders, spawn points, and basic player flow.

Phase 3: Implement the server-side round and player-state systems.

Phase 4: Implement the trap framework and cooldown logic.

Phase 5: Create the initial six functional traps.

Phase 6: Implement the control panel, round UI, and notifications.

Phase 7: Add scoring, checkpoints, finish detection, and reset behavior.

Phase 8: Test multiplayer interactions and fix discovered bugs.

Phase 9: Polish the map, effects, and UI.

Phase 10: Provide a concise implementation report.

Work incrementally. Verify that each major subsystem works before building additional systems on top of it.

Do not replace working systems with mock implementations merely to finish faster.

If something cannot be implemented because of environment limitations, explain the limitation and provide the most complete working alternative.

## 14. Final Deliverables

At the end, provide:

1. A complete playable Roblox experience or project files compatible with Roblox Studio.
2. All required Luau scripts and supporting modules.
3. The map and functional trap objects.
4. The functional trap-control UI.
5. A summary of the game architecture.
6. Instructions for running and testing the game.
7. A list of configurable settings, including cooldowns and round durations.
8. A list of features that were tested and their results.
9. Any remaining issues or unimplemented features.

**Final priority:** Deliver a working multiplayer Deathrun prototype with a reliable death-to-trap-controller transition, real trap mechanics, shared server-authoritative cooldowns, and a complete round loop. Build the foundation correctly before adding unnecessary complexity.
