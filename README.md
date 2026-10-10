# Steal a Goofy Egg

An original Roblox **Phase 1 prototype** built with Luau and Rojo. Take an egg, escape its guardian, bring it home, hatch a goofy animal, earn cash, and upgrade your speed.

**Cloud checks pass; gameplay has not been tested in Roblox Studio.** This is a prototype for Studio testing, not a production release. Progress lasts only for the current server session. Leaving or stopping Play resets it. There is no background music, no external model/audio asset dependency, and no active Robux purchase flow.

## Open the game in Roblox Studio — easiest route

1. Install [Roblox Studio](https://create.roblox.com/) on Windows or macOS and sign in. Studio does not run in this Linux cloud environment.
2. Open the [ready-to-open Studio place on GitHub](release/Steal-a-Goofy-Egg.rbxlx), then click **Download raw file** (the download-arrow icon above the file). Save it as `Steal-a-Goofy-Egg.rbxlx`, not `.txt`. This file is committed in the repository; you do **not** need Python, Rojo, a plugin, or a terminal to try it. If GitHub shows XML text, use its download button rather than copying the text. You can also choose **Code → Download ZIP**, extract it, and find the file inside the `release` folder.
3. In Studio choose **File → Open from File…** and select that `.rbxlx` file. An empty-looking editor is expected: the map and UI are created when Play starts.
4. Choose **Play** (F5), not Run. Open **Output** from Studio's View/Window menu to check for errors.
5. Your avatar spawns at one of five bases. Walk along the broad path to **Turtle Meadow**. Hold **E** at the egg, or use the on-screen proximity prompt on a touch device. Run home before the guardian catches you.
6. Walk onto your own mint-colored deposit pad. The egg deposits automatically; the pad prompt and HUD deposit button also work nearby. Wait 10 seconds for it to hatch. Cash then arrives automatically each second.
7. Spend cash with the HUD speed button or your base's speed shop. **Rabbit Ridge unlocks at speed level 4**; its eggs take 18 seconds to hatch.
8. Stop Play before editing or opening a newer build. Follow [the Studio testing guide](docs/STUDIO_TESTING.md) before publishing anything.

No API key, DataStore setting, product ID, or external service is needed for Phase 1. Keep Studio API access disabled for this prototype.

## What's implemented

- Five assigned bases, spawn/respawn routing, a wide path, and two guardian zones.
- Single egg carrying, validated stealing, server-driven guardian chasing/return/cooldown, and catch recovery.
- Three hatch slots per player, synchronized countdowns, and server-selected weighted animal rewards.
- Seven original procedural animal designs with idle motion; four obtainable rarity tiers. Legendary, Mythic, and Secret are reserved in config and have no Phase 1 rewards.
- Fixed animal income, cash/speed leaderboard, 12 cash-funded speed levels, and centralized balancing.
- Eight active animals per player. When full, only a higher-income animal replaces the weakest; every discovered species enters the session collection. Lower-value duplicates do not reduce income.
- Responsive instance-built HUD, carrying objective, rarity reveals, collection and upgrade panels, effects/reduced-motion controls, and native mobile/PC movement and egg prompts.
- Server-owned economy, fixed-intent remotes, rate limits, distance/alive/base ownership checks, and a conservative movement budget. These need real latency and exploit testing in Studio.

A guardian protects its own zone egg. Only one player can take that egg at a time; other players wait until the guardian returns and the cooldown ends. Players do not steal already collected animals from each other.

## Development and build

Source is mapped by [`default.project.json`](default.project.json). Use the existing checkout; each cloud task is already isolated, so a separate Git worktree is unnecessary.

### In this Linux cloud workspace

Python 3 is the only bootstrap prerequisite. The installer pins official Rojo, Luau, StyLua, and luau-lsp releases and verifies SHA-256 hashes before installation. It never changes global packages.

```bash
cd /workspace/Steal-a-goofy-egg
python3 scripts/bootstrap.py
python3 scripts/check.py
```

Tools go into ignored `.tools/`. To reuse the tools prepared during cloud onboarding instead:

```bash
export GOOFY_TOOLS_DIR=/workspace/tooling/goofy-egg
python3 scripts/bootstrap.py
python3 scripts/check.py
```

Checks include StyLua, Luau compilation, Roblox-aware static analysis with a Rojo sourcemap, 25 economy/session tests, and a validated `.rbxlx` build. No Roblox gameplay simulator is implied. Generated outputs live in ignored `build/`. Maintainers can run `python3 scripts/check.py --release` to refresh the deliberately tracked `release/Steal-a-Goofy-Egg.rbxlx` after all checks pass. The `release` copy is the beginner-friendly GitHub download; source changes must be rebuilt to appear in it.

### On your own Windows or macOS computer

For the simplest start, use the provided `.rbxlx` file. To work from the Git repository, install **Rojo 7.7.1** for your operating system using [the official installation guide](https://rojo.space/docs/v7/getting-started/installation/). In a terminal in the repository folder:

```bash
rojo build default.project.json --output Steal-a-Goofy-Egg.rbxlx
```

Open the resulting file in Studio. For live source edits, install the official Rojo Studio plugin, run `rojo serve default.project.json` locally, and connect the plugin to that local server. Keep CLI/plugin major versions compatible. The cloud Rojo server is not exposed to your desktop; local sync runs on your own machine. There is no user-facing cloud web preview for this game.

## Configuration and next phases

Change names, colors, income, egg odds, zone difficulty, hatch times, and speed prices in [`src/shared/Config.luau`](src/shared/Config.luau). Probability weights total 100 per zone and are tested. Rabbit has better odds; a rare turtle-zone animal still earns more than a common rabbit-zone animal. Rewards are free gameplay outcomes, never paid randomized purchases.

**Phase 2 remaining:** durable save/load with session ownership and safe failure handling; more zones/animals; inventory management beyond the best-eight display; expanded progression, animations, and UI polish.

**Phase 3 remaining:** configurable official Gamepasses and Developer Products with placeholder IDs until created; durable idempotent receipt processing; convenience boosts; measured balancing/mobile performance; polished tutorial and release preparation. No purchase is prompted in this prototype. Optional sound effects remain unimplemented; music must stay absent.

Procedural animals are usable placeholders and need no uploaded meshes or animations. Professional custom art/animation and optional owned/licensed SFX may replace them later. Review [architecture](docs/ARCHITECTURE.md), [testing](docs/STUDIO_TESTING.md), and [research limitations and design assumptions](docs/RESEARCH.md).
