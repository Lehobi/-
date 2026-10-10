# Phase 1 refinement architecture

This is a Rojo-compatible, session-only Roblox game in development. The server owns gameplay state; the client requests two fixed actions and renders the state it receives. Map, eggs, animals, and UI are generated from original Luau and Roblox primitives. Sound cues reference files bundled with Roblox. There are no creator-uploaded mesh, audio, animation, or package dependencies at runtime, and no background music. The owner tested the previous core loop; the revised rendering, chases, audio, and interface still need a Studio run.

## Files and Roblox locations

```text
default.project.json                 Rojo DataModel mapping and place defaults
release/Steal-a-Goofy-Egg.rbxlx        Downloadable, checked-source Studio place
src/
  shared/                            ReplicatedStorage.GoofyEgg.Shared
    Config.luau                      Balance, zones, rarity odds, animal catalog
    Economy.luau                     Pure calculations, validation, weighted rewards
    AnimalFactory.luau               Original procedural animal and egg models
    ChaseRules.luau                  Pure rectangular arena bounds and clamping
    PetMotion.luau                   Seeded lawn routes sampled from server time
  server/                            ServerScriptService.GoofyEgg
    Main.server.luau                 Roblox lifecycle, interactions, simulation, remotes
    Session.luau                     One player's synchronous in-memory state
    World.luau                       Garden ranches, route walls, signs, nests, zones
  client/                            StarterPlayer.StarterPlayerScripts.GoofyEgg
    Main.client.luau                 State subscription, startup, local visual updates
    SoundEffects.luau                Local bundled interaction cues and voice cleanup
  ui/                                StarterGui.GoofyUI (cloned to PlayerGui)
    Hud.luau                         Responsive HUD, collection, shop, settings, reveals
tests/
  economy.spec.luau                   Pure economy and weighted-choice checks
  session.spec.luau                   Pure session transition and isolation checks
  chase.spec.luau                     Arena edges, invalid coordinates, speed balance
  pet_motion.spec.luau                Deterministic roaming, bounds, and continuity
scripts/
  bootstrap.py                       Pinned, checksum-verified tool installation
  check.py                           Static checks, pure tests, and place build
```

Rojo also declares `ReplicatedStorage.GoofyEgg.Remotes`. At server startup, `World.build` creates `Workspace.GoofyEggWorld`, including `Bases.Base_1` through `Base_5` and `Zones.Zone_turtle` / `Zone_rabbit`. The edit-mode place does not contain the generated terrain or HUD; they appear when play starts.

## One egg's trip

1. `Main.server` assigns the first unoccupied base and creates a `Session`. It positions the character at that base and applies the server's configured speed.
2. The egg's native ProximityPrompt fires. The server checks action frequency, guardian availability, a living character, movement budget, egg distance, speed level, existing carry, and free hatch capacity.
3. `Session:steal` records the zone ID. The server hides the zone egg, attaches a visual egg to the character, and sets that zone's guardian to chase this player. Other players cannot claim the same egg during that chase.
4. After a 0.45-second wake-up delay, the guardian advances toward the target on the server, bounded by the red rectangular territory. Crossing the perimeter ends the chase before another movement/catch check and marks the egg escaped; the player keeps carrying it home. A catch, death, character removal, movement rejection, or 60-second timeout while still pursued cancels only the current carried egg. Existing animals and cash remain.
5. At the owner's deposit pad, `Session:deposit` consumes the carry and schedules a hatch in the first free slot. Near the pad this happens automatically; the prompt and HUD deposit button are additional entry points into the same validated operation.
6. When the server clock reaches `readyAt`, the server draws two random numbers and calls `Session:finishHatch`. `Economy.rollAnimal` chooses a weighted rarity, then an animal within that rarity. Guardian species does not constrain hatch species.
7. The completed hatch is removed and its reward is applied in the same synchronous session mutation. The server refreshes the displayed collection and sends a reveal plus a state snapshot to that player.
8. Each whole elapsed second credits the sum of displayed animals' income. A speed upgrade spends the server's calculated price and increments the server's level.

## State and transaction boundaries

Each `Session` contains `baseId`, cash, speed level, one optional carried zone, an `escaped` flag, indexed pending hatches, owned animals, and discovered animal IDs. Sessions are held by the server's local `sessions` table, not replicated as writable gameplay objects. Player `leaderstats` and remote snapshots are displays derived from that state.

`steal`, `markEscaped`, `deposit`, `finishHatch`, `upgrade`, and `earn` do not yield. Roblox event handlers therefore cannot interleave halfway through those session mutations. A second deposit finds no carried egg; a second hatch completion finds no pending hatch. `markEscaped` affects only the currently carried zone and cannot repeat for the same egg. Depositing, losing an egg, or stealing a new one clears the flag. This protects duplicate grants **within one running server only**. It is not a persistence or cross-server transaction guarantee.

Snapshots copy hatch, animal, and discovery data. The client never receives direct mutable access to server session tables. Two players have independent sessions, while each zone guardian is shared world state.

The ranch holds at most eight earning animals, including duplicates. A stronger new animal replaces the lowest earner when full. A weaker or equal-value arrival does not displace an existing animal, but it still marks its species discovered. Income reflects the eight retained animals; the collection menu is a discovery record, not an unlimited earning inventory. Their client-side positions and poses never determine income.

## Remote contract

All paths below are under `ReplicatedStorage.GoofyEgg.Remotes`.

| Instance | Direction | Accepted data and role |
| --- | --- | --- |
| `Action` / RemoteEvent | Client → server | Exactly one string: `UpgradeSpeed` or `DepositEgg`. Extra arguments and invalid types are rejected. Unknown intents have no gameplay effect. |
| `GetState` / RemoteFunction | Client → server → client | No arguments. Returns that caller's snapshot, or nil if unavailable/rate limited. |
| `State` / RemoteEvent | Server → client | Authoritative cash, income, speed, base, carry/escaped, hatch, animal, discovery, and objective fields. |
| `Notice` / RemoteEvent | Server → client | Informational text, a presentation kind, and an optional fixed sound-cue name. |
| `Hatch` / RemoteEvent | Server → client | Server-chosen animal, rarity, income, whether retained, and optional replacement name. |

No request accepts a reward, price, target player, desired speed level, or cash amount. `State`, `Notice`, and `Hatch` have no economic server-side receive handler. Stealing is a validated server ProximityPrompt action, not an arbitrary `StealEgg` remote command.

## Security checks and limits

- Actions share a per-player 0.25-second server cooldown; state reads have a 0.5-second cooldown. Local UI throttling is only feedback and convenience.
- Stealing checks a 13-stud distance, the player's position inside the zone, and the zone's available state. Depositing checks the player's own pad within 14 studs. Character-alive and session checks apply to these actions.
- The physical speed-shop prompt requires the owner's base and proximity. The HUD speed button intentionally works anywhere for a living player; both use the same balance and maximum-level checks.
- Movement is checked on the server using horizontal displacement, configured speed, a 20% speed allowance, and at most eight studs of accumulated tolerance. Out-of-range height also resets a run. The server reapplies the configured WalkSpeed.
- Invalid movement clears the carried egg and returns the player to their base; it does not permanently punish them or remove their collection. Client-owned character movement and replication latency make this a conservative abuse check, not a complete anti-cheat. Studio latency, jumping, low-FPS, and respawn tests are required to tune false positives.
- Guardians are server-moved anchored procedural models inside unobstructed rectangular courts. `ChaseRules` checks finite coordinates and clamps targets/root positions to those courts. The visible red strips share the configured half-width/depth. A player's center exactly on an edge is still inside; it must pass the edge to escape. Roots stay bounded, though a large model's limbs can extend across a strip.
- Chase uses direct movement, a horizontal 4.5-stud catch radius, and a 60-second timeout while pursued; it does not use PathfindingService. Crossing outside is checked before a catch. Re-entering with the secured egg does not restart that chase. The returning guardian enters cooldown when it reaches home, then exposes a fresh egg. Adding collidable obstacles inside a court will require revisiting direct movement.

## World, lighting, and presentation

`World` builds five fenced lawn ranches with rear hatch decks/pergolas, three straw nests, a central deposit pad, a speed kiosk, and flowers. The guardian route has stone/timber side walls and an end wall. Distinct grass, stone, wood, and path materials replace the former white platforms. `default.project.json` controls lower exposure/ambient lighting, shadows, atmosphere, color correction, and a 7–48-stud camera zoom range. These settings need visual checks at low and high Roblox graphics levels; a source build cannot prove their rendered quality.

World signs use physical boards with `SurfaceGui`, `AlwaysOnTop = false`, and finite visibility distances of roughly 35–65 studs. They stay fixed in world space, can be occluded, and scale with distance. There are no camera-facing animal or world-label billboards. Animal names, rarity, income, and owned counts are shown in the Collection panel instead. Hatch countdown boards are fixed behind the nests.

The HUD uses small wallet/speed indicators, a short mission line, occupied-nest chips, and one contextual upgrade/deposit action. Collection cards have original instance-built animal illustrations. Layout responds to viewport size and Roblox safe insets, with 44-pixel navigation/action targets; device-emulator and real-device usability checks remain required. Settings expose sound effects, reduced motion, and visual effects, and disclose session resets.

Current difficulty values live in `Config`: turtle speed 19, rabbit speed 31, player speed `16 + 2 × level`, rabbit unlock level 6, and upgrade price starting at $50 with 1.65 growth. The player starts with $25 and must earn before the first upgrade. The wake delay and escape distance are part of the balance; compare actual escape times in Studio before treating these values as settled.

## Simulation and cleanup

The server checks motion, deposits, and guardians approximately every 0.1 seconds. Guardian movement caps a long frame's step to limit jumps. Income uses whole elapsed server seconds and hatch deadlines use `Workspace:GetServerTimeNow()`; a client countdown never decides when a reward is granted.

Each pet has replicated species, lawn bounds, and a stable base/slot seed. `PetMotion` derives a deterministic loop with pauses and smooth travel; clients sample it from `Workspace:GetServerTimeNow()` instead of sending movement remotes. Pets wander within the central lawn and face their next waypoint. This is decorative roaming, not collision-aware autonomous AI: pets can overlap one another and do not follow players.

Client world animation is capped at 20 Hz and limited to pets/guardians within 160 studs of the camera. Cached part rest poses provide foot steps, paired frog/rabbit hops, bird waddles, wings, ears, and tails without accumulated transform drift. Guardian roots remain server-owned; clients only pose their parts. Reduced motion disables the limb/bob effects and reveal tween while retaining calm pet roaming; turning visual effects off also pauses decorative pet travel. Countdown labels update locally four times per second from replicated server deadlines.

`SoundEffects` plays brief local cues under SoundService for menus, steal, escape, catch, deposit, upgrade, rejection, and hatch. It references four Roblox-bundled sound files, uses a configurable master volume, limits simultaneous voices to six, rate-limits repeated cues, and destroys voices after short lifetimes. Preloading is protected and asynchronous, so audio failure never blocks joining. The Settings toggle controls these game cues; native Roblox character sounds are separate. No looping sound or music track is created. Audio availability and the actual mix still require Studio/client listening tests.

Player departure ends targeting, removes carry visuals, disconnects that player's lifecycle/death connections, clears their hatches and animals, frees the base, and removes rate/motion records. Shutdown disconnects global handlers and destroys the generated world. Client destruction disconnects listeners, destroys the HUD and sound folder, cancels queued audio generations, and restores animated rest poses.

## Development and later phases

Run `python3 scripts/bootstrap.py`, then `python3 scripts/check.py` from the repository. Tools install under `.tools` by default; `GOOFY_TOOLS_DIR` can select another directory. The check script builds `build/Steal-a-Goofy-Egg.rbxlx`; add `--release` to refresh the tracked `release/Steal-a-Goofy-Egg.rbxlx` download. See [Studio testing](STUDIO_TESTING.md) for the required engine checks. A successful source analysis or Rojo build does not demonstrate that Roblox gameplay works.

Phase 1 does not use DataStoreService, MarketplaceService, cloud credentials, API access, music, or real-money prompts. Leaving or restarting loses all session progress, including discovery, upgrades, and presentation settings; the welcome notice and Settings panel disclose this.

Before later persistence and monetization, design schema versioning/migrations, session locking, bounded retries, `UpdateAsync` concurrency handling, recovery for interrupted hatches, and graceful shutdown/load-failure behavior. Developer products need durable receipt IDs and an idempotent grant ledger so retries across servers cannot duplicate a purchase. A receipt must only be acknowledged after its durable grant succeeds. Gamepasses need server ownership checks and fixed configurable IDs. Those systems are not implemented or implied by the current in-memory duplicate protection.

Client rig setup waits for the complete expected part count, species, scale, and authored rest-pose attributes. Delayed replicated pieces are retried; animation never caches a partial model. Model watchers and pending entries are removed with the model. Guardian pivots are inset by the model footprint, keeping the silhouette inside the red boundary.
