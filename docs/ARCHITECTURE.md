# Phase 1 architecture

This is a Rojo-compatible, session-only Roblox prototype. The server owns gameplay state; the client requests two fixed actions and renders the state it receives. Map, eggs, animals, and UI are generated from original Luau and Roblox primitives. There are no external mesh, audio, animation, asset, or package dependencies at runtime, and no background music.

## Files and Roblox locations

```text
default.project.json                 Rojo DataModel mapping and place defaults
src/
  shared/                            ReplicatedStorage.GoofyEgg.Shared
    Config.luau                      Balance, zones, rarity odds, animal catalog
    Economy.luau                     Pure calculations, validation, weighted rewards
    AnimalFactory.luau               Original procedural animal and egg models
  server/                            ServerScriptService.GoofyEgg
    Main.server.luau                 Roblox lifecycle, interactions, simulation, remotes
    Session.luau                     One player's synchronous in-memory state
    World.luau                       Map, five bases, zones, prompts, displays
  client/                            StarterPlayer.StarterPlayerScripts.GoofyEgg
    Main.client.luau                 State subscription, startup, local visual updates
  ui/                                StarterGui.GoofyUI (cloned to PlayerGui)
    Hud.luau                         Responsive HUD, collection, shop, settings, reveals
tests/
  economy.spec.luau                   Pure economy and weighted-choice checks
  session.spec.luau                   Pure session transition and isolation checks
scripts/
  bootstrap.py                       Pinned, checksum-verified tool installation
  check.py                           Static checks, pure tests, and place build
```

Rojo also declares `ReplicatedStorage.GoofyEgg.Remotes`. At server startup, `World.build` creates `Workspace.GoofyEggWorld`, including `Bases.Base_1` through `Base_5` and `Zones.Zone_turtle` / `Zone_rabbit`. The edit-mode place does not contain the generated terrain or HUD; they appear when play starts.

## One egg's trip

1. `Main.server` assigns the first unoccupied base and creates a `Session`. It positions the character at that base and applies the server's configured speed.
2. The egg's native ProximityPrompt fires. The server checks action frequency, guardian availability, a living character, movement budget, egg distance, speed level, existing carry, and free hatch capacity.
3. `Session:steal` records the zone ID. The server hides the zone egg, attaches a visual egg to the character, and sets that zone's guardian to chase this player. Other players cannot claim the same egg during that chase.
4. The guardian advances toward the target on the server. A catch, death, character removal, movement rejection, or chase timeout cancels only the current carried egg. Existing animals and cash remain.
5. At the owner's deposit pad, `Session:deposit` consumes the carry and schedules a hatch in the first free slot. Near the pad this happens automatically; the prompt and HUD deposit button are additional entry points into the same validated operation.
6. When the server clock reaches `readyAt`, the server draws two random numbers and calls `Session:finishHatch`. `Economy.rollAnimal` chooses a weighted rarity, then an animal within that rarity. Guardian species does not constrain hatch species.
7. The completed hatch is removed and its reward is applied in the same synchronous session mutation. The server refreshes the displayed collection and sends a reveal plus a state snapshot to that player.
8. Each whole elapsed second credits the sum of displayed animals' income. A speed upgrade spends the server's calculated price and increments the server's level.

## State and transaction boundaries

Each `Session` contains `baseId`, cash, speed level, one optional carried zone, indexed pending hatches, owned animals, and discovered animal IDs. Sessions are held by the server's local `sessions` table, not replicated as writable gameplay objects. Player `leaderstats` and remote snapshots are displays derived from that state.

`steal`, `deposit`, `finishHatch`, `upgrade`, and `earn` do not yield. Roblox event handlers therefore cannot interleave halfway through those session mutations. A second deposit finds no carried egg; a second hatch completion finds no pending hatch. This protects duplicate grants **within one running server only**. It is not a persistence or cross-server transaction guarantee.

Snapshots copy hatch, animal, and discovery data. The client never receives direct mutable access to server session tables. Two players have independent sessions, while each zone guardian is shared world state.

The display holds at most eight animals, including duplicates. A stronger new animal replaces the lowest earner when full. A weaker or equal-value arrival does not displace an existing animal, but it still marks its species discovered. Income reflects the eight retained animals; the collection menu is a discovery record, not an unlimited earning inventory.

## Remote contract

All paths below are under `ReplicatedStorage.GoofyEgg.Remotes`.

| Instance | Direction | Accepted data and role |
| --- | --- | --- |
| `Action` / RemoteEvent | Client → server | Exactly one string: `UpgradeSpeed` or `DepositEgg`. Extra arguments and invalid types are rejected. Unknown intents have no gameplay effect. |
| `GetState` / RemoteFunction | Client → server → client | No arguments. Returns that caller's snapshot, or nil if unavailable/rate limited. |
| `State` / RemoteEvent | Server → client | Authoritative cash, income, speed, base, carry, hatch, animal, discovery, and objective fields. |
| `Notice` / RemoteEvent | Server → client | Informational text and a presentation kind. |
| `Hatch` / RemoteEvent | Server → client | Server-chosen animal, rarity, income, whether retained, and optional replacement name. |

No request accepts a reward, price, target player, desired speed level, or cash amount. `State`, `Notice`, and `Hatch` have no economic server-side receive handler. Stealing is a validated server ProximityPrompt action, not an arbitrary `StealEgg` remote command.

## Security checks and limits

- Actions share a per-player 0.25-second server cooldown; state reads have a 0.5-second cooldown. Local UI throttling is only feedback and convenience.
- Stealing checks a 13-stud distance and the zone's available state. Depositing checks the player's own pad within 14 studs. Character-alive and session checks apply to these actions.
- The physical speed-shop prompt requires the owner's base and proximity. The HUD speed button intentionally works anywhere for a living player; both use the same balance and maximum-level checks.
- Movement is checked on the server using horizontal displacement, configured speed, a 20% speed allowance, and at most eight studs of accumulated tolerance. Out-of-range height also resets a run. The server reapplies the configured WalkSpeed.
- Invalid movement clears the carried egg and returns the player to their base; it does not permanently punish them or remove their collection. Client-owned character movement and replication latency make this a conservative abuse check, not a complete anti-cheat. Studio latency, jumping, low-FPS, and respawn tests are required to tune false positives.
- Guardians are server-moved anchored procedural models on a broad open route. Their chase uses direct movement, a horizontal catch radius, and a 60-second timeout; it does not use PathfindingService. Adding obstacles or vertical terrain will require revisiting chase and catch behavior.

## Simulation and cleanup

The server checks motion, deposits, and guardians approximately every 0.1 seconds. Guardian movement caps a long frame's step to limit jumps. Income uses whole elapsed server seconds and hatch deadlines use `Workspace:GetServerTimeNow()`; a client countdown never decides when a reward is granted.

Client collection bobbing is capped at 20 Hz and restricted to nearby collection animals. It does not drive guardian gameplay. Countdown labels update locally from replicated server deadlines. Settings disable decorative effects or reduce motion.

Player departure ends targeting, removes carry visuals, disconnects that player's lifecycle/death connections, clears their displayed hatches and animals, frees the base, and removes rate/motion records. Shutdown disconnects global handlers and destroys the generated world. Client destruction disconnects its listeners, destroys the HUD, and restores animated display poses.

## Development and later phases

Run `python3 scripts/bootstrap.py`, then `python3 scripts/check.py` from the repository. Tools install under `.tools` by default; `GOOFY_TOOLS_DIR` can select another directory. The check script builds `build/Steal-a-Goofy-Egg.rbxlx`. See [Studio testing](STUDIO_TESTING.md) for the required engine checks. A successful source analysis or Rojo build does not demonstrate that Roblox gameplay works.

Phase 1 does not use DataStoreService, MarketplaceService, cloud credentials, API access, music, or real-money prompts. Leaving or restarting loses all session progress, including discovery and upgrades; the HUD states this explicitly.

Before later persistence and monetization, design schema versioning/migrations, session locking, bounded retries, `UpdateAsync` concurrency handling, recovery for interrupted hatches, and graceful shutdown/load-failure behavior. Developer products need durable receipt IDs and an idempotent grant ledger so retries across servers cannot duplicate a purchase. A receipt must only be acknowledged after its durable grant succeeds. Gamepasses need server ownership checks and fixed configurable IDs. Those systems are not implemented or implied by the current in-memory duplicate protection.
