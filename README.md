# Roblox Deathrun (CS2-Inspired Deathrun Game)

A complete, fully playable, multiplayer Roblox Deathrun game inspired by the classic **Deathrun game mode from Counter-Strike 2**, built with Roblox Luau, modular server architecture, and professional Rojo tooling.

---

## 🎮 Game Overview

The experience pits **Runners** against **Trap Controllers**:
- **Runners:** Navigate through an obstacle course filled with jumps, gaps, checkpoints, and 6 lethal traps. Their goal is to survive, dodge traps, and cross the Finish Line.
- **Trap Controllers:** Stationed in an elevated, glass-walled observation catwalk parallel to the course. They activate traps via on-screen control cards or physical 3D consoles to eliminate runners.
- **Dynamic Role Switch on Death:** When a runner is eliminated by a trap or falls into the killzone, they immediately switch to the **Trap Controller** side, respawn at the observation deck, and gain access to the Trap Control UI to activate traps against the remaining runners!

---

## 📁 Project Structure

```
roblox/
├── Deathrun.rbxl              # Standard binary Roblox Studio place file (Open directly in Studio)
├── Deathrun.rbxlx             # XML Roblox Studio place file (Git & diff-friendly)
├── default.project.json       # Rojo 7 project configuration
├── instruction.md             # Original specification and requirements
├── README.md                  # Comprehensive documentation & setup instructions
├── scripts/
│   └── build_full_place.luau  # Automated Lune builder for 3D map, lighting, & instances
├── tests/
│   └── test_deathrun.luau     # 74-assertion automated test suite for mechanics & integrity
└── src/
    ├── ReplicatedStorage/
    │   └── Shared/
    │       ├── Enums.luau         # PlayerState, RoundState, WinReason
    │       ├── GameConfig.luau    # Timers, points, coordinates, dev settings
    │       ├── TrapConfig.luau    # The 6 trap definitions, cooldowns, & active durations
    │       └── Types.luau         # Luau type definitions
    ├── ServerScriptService/
    │   ├── Main.server.luau       # Server entry point & service dependency wiring
    │   └── Services/
    │       ├── NetworkService.luau     # RemoteEvents & client-server communications
    │       ├── ScoringService.luau     # Leaderstats (Points, Wins, Kills) & anti-cheat
    │       ├── CheckpointService.luau  # Checkpoint touch triggers & progression
    │       ├── PlayerStateService.luau # State transitions, death-to-controller respawns
    │       ├── TrapService.luau        # Cooldowns, mutex locks, & 6 physical hazard tweens
    │       ├── RoundService.luau       # Centralized round lifecycle & win evaluation
    │       └── MapService.luau         # Procedural level construction & trigger wiring
    └── StarterPlayer/
        └── StarterPlayerScripts/
            ├── ClientMain.client.luau  # Client bootstrap & event dispatcher
            └── Controllers/
                ├── SoundController.luau        # Procedural audio & UI sound feedback
                ├── NotificationController.luau # Animated slide-in HUD announcements
                ├── TrapClientController.luau   # Keybinds (1-6), click debounces & cooldown sync
                └── UIController.luau           # Trap panel, round status, runner HUD & results
```

---

## ⚡ The 6 Functional Traps

All 6 traps implement real physical mechanisms, hazard hitboxes, warning cues, and server-authoritative cooldowns:

| Trap | Default Cooldown | Active Duration | Warning Duration | Keybind | Physical Mechanism |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Collapsing Bridge** | `8s` | `3s` | `0.5s` | `[1]` | Support pillars flash red; segmented bridge planks turn non-collidable (`CanCollide = false`) and transparent, dropping runners into the abyss. |
| **Swinging Hammer** | `6s` | `2s` | `0.4s` | `[2]` | Overhead gantry beacon ignites; massive pendulum hammer swings across the narrow walkway in a sinusoidal arc, dealing lethal damage and flinging runners off. |
| **Falling Ceiling** | `10s` | `3s` | `0.6s` | `[3]` | Red corridor strobes flash inside the covered tunnel; heavy spiked crusher ceiling slams down at high speed (0.25s), squashing runners, holds, and retracts. |
| **Moving Wall** | `7s` | `4s` | `0.5s` | `[4]` | Orange warning wall sign illuminates; a heavy hydraulic pusher wall rams across the full width of the catwalk, sweeping runners off the ledge. |
| **Rotating Platform** | `9s` | `5s` | `0.5s` | `[5]` | Edge beacons ignite purple; large platform spins rapidly and tilts 45° along its axis, throwing runners off into the chasm before smoothly releveling. |
| **Pitfall** | `12s` | `3s` | `0.5s` | `[6]` | Floor perimeter alerts flash; dual trapdoors (`HatchLeft` & `HatchRight`) snap open downward, exposing a bottomless pit below before snapping closed. |

---

## 🚀 How to Run and Test the Game

### Option 1: Open Directly in Roblox Studio (Easiest)
1. Double-click or open **`Deathrun.rbxl`** (or `Deathrun.rbxlx`) in **Roblox Studio**.
2. Everything is pre-built into the place file:
   - The 3D map, Lobby, Spawns, Glass Catwalk, Obstacles, and all 6 Traps are immediately visible in the viewport.
   - All server scripts, client controllers, configs, and UI are mounted.
3. Click **Play** (or press `F5`):
   - You will spawn in the Lobby, intermission will count down, and the round starts!
   - **Solo Testing:** The game supports 1-player testing (`MinPlayersToStart = 1`). You are spawned as Runner, with a top-right **`🛠️ DEV TESTING PANEL`** allowing you to switch to Trap Controller with one click anytime, or walk up to the physical 3D console buttons on the glass catwalk to trigger traps!
4. **Multiplayer Studio Testing:**
   - In Roblox Studio, go to the **Test** tab -> **Simulation Mode: Local Server** -> Select **2 Players** -> Click **Start**.
   - Studio will launch 1 server window and 2 client windows.
   - 1 player will be assigned **Trap Controller** on the elevated catwalk with the full Trap Control UI, and 1 player will be assigned **Runner**.
   - When the runner dies, watch them instantly switch to the Trap Controller team and gain the trap control panel!

### Option 2: Live Sync via Rojo
If you want to edit code in your external editor (VSCode / Antigravity) and live-sync to Roblox Studio:
1. In this directory, run:
   ```bash
   rojo serve
   ```
2. In Roblox Studio, install and open the **Rojo Plugin** and click **Connect**.
3. Any edits in `src/` will sync live into Studio.

### Option 3: Rebuilding the Place File from Source
To rebuild the place files after editing code or map definitions:
```bash
rojo build default.project.json -o Deathrun.rbxlx
lune run scripts/build_full_place.luau
```

### Option 4: Running the Automated Test Suite
To run the automated Luau verification tests:
```bash
lune run tests/test_deathrun.luau
```
Output:
```
==================================================
  TEST SUITE COMPLETED: 74 PASSED, 0 FAILED
==================================================
```

---

## ⚙️ Configurable Settings

All settings are centralized in `src/ReplicatedStorage/Shared/GameConfig.luau` and `TrapConfig.luau`:

| Setting | Default Value | Location | Description |
| :--- | :--- | :--- | :--- |
| `MinPlayersToStart` | `1` | `GameConfig.luau` | Minimum players required to start round (1 allows instant solo testing). |
| `IntermissionDuration` | `10` | `GameConfig.luau` | Intermission countdown seconds between rounds. |
| `RoundDuration` | `120` | `GameConfig.luau` | Active round duration in seconds (2 minutes). |
| `ResultsDuration` | `7` | `GameConfig.luau` | Seconds to display victory screen before teleporting to lobby. |
| `PlayerInputDebounce`| `0.3` | `GameConfig.luau` | Server & client debounce to prevent button spamming. |
| `DeathRespawnDelay` | `2.0` | `GameConfig.luau` | Seconds after runner death before respawning as Trap Controller. |
| `Points.Finish` | `100` | `GameConfig.luau` | Points awarded for crossing finish line (+1 Win). |
| `Points.Checkpoint` | `25` | `GameConfig.luau` | Points awarded for reaching each checkpoint pad. |
| `Points.TrapKill` | `50` | `GameConfig.luau` | Points awarded to controller for eliminating a runner (+1 Kill). |
| `Points.Participation`| `10` | `GameConfig.luau` | Participation reward awarded on round end. |
| `DevMode` | `true` | `GameConfig.luau` | Enables the dev testing widget and role switch remote. |
| `Trap Cooldowns` | `6s - 12s` | `TrapConfig.luau` | Independent shared cooldown per trap. |
| `Trap Active Durations`| `2s - 5s` | `TrapConfig.luau` | Duration the physical hazard remains active. |

---

## 🛡️ Security & Multiplayer Architecture

1. **Server-Authoritative Trap Execution:**
   - The client UI only sends an activation request (`ActivateTrap` remote).
   - The server verifies: player state is `TrapController`, round state is `InProgress`, character is alive, input debounce is respected, and trap cooldown is not active.
   - Shared cooldown mutex prevents multiple controllers from triggering the same trap simultaneously.
2. **Safe Cleanup on Round Reset:**
   - Between rounds or if a round terminates early, `TrapService.ResetAllTraps()` cancels all active hazard threads and restores every part's pristine original CFrame, transparency, and collision properties.
3. **Robust Lifecycle & Disconnect Handling:**
   - Mid-round joins are assigned Spectator / Controller to prevent disrupting ongoing rounds.
   - Player leaves are reconciled; if the last runner disconnects, the round resolves cleanly with victory awarded to controllers.
