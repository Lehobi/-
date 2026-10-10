# Steal a Goofy Egg

An original Roblox **Phase 1 game in development** built with Luau and Rojo. Take an egg, cross the red line to escape its guardian, bring it home, hatch a goofy animal, earn cash, and upgrade your speed.

**The owner tested the earlier build and reported that its core gameplay works. This refinement still needs a new Roblox Studio playtest.** It replaces the bright white test map with garden ranches, a walled guardian route, stationary signs, a smaller HUD, roaming pets, and basic interaction sounds. Progress lasts only for the current server session; leaving or stopping Play resets it. There is no background music, save/load system, or active Robux purchase flow.

## Open the game in Roblox Studio — easiest route

1. Install [Roblox Studio](https://create.roblox.com/) on Windows or macOS and sign in. Studio does not run in this Linux cloud environment.
2. Open the [ready-to-open Studio place on GitHub](release/Steal-a-Goofy-Egg.rbxlx), then click **Download raw file** (the download-arrow icon above the file). Save it as `Steal-a-Goofy-Egg.rbxlx`, not `.txt`. This file is committed in the repository; you do **not** need Python, Rojo, a plugin, or a terminal to try it. If GitHub shows XML text, use its download button rather than copying the text. You can also choose **Code → Download ZIP**, extract it, and find the file inside the `release` folder.
3. In Studio choose **File → Open from File…** and select that `.rbxlx` file. An empty-looking editor is expected: the map and UI are created when Play starts.
4. Choose **Play** (F5), not Run. Open **Output** from Studio's View/Window menu to check for errors.
5. Your avatar spawns in one of five fenced garden ranches. Follow the stone path into the walled route to **Turtle Meadow**. Hold **E** at the egg, or use the on-screen proximity prompt on a touch device. Immediately run back across the **red boundary line**. The guardian stays inside its garden; you keep the egg after escaping.
6. Return to your own ranch's central pad, beneath the **BRING YOUR EGG HERE** sign. The egg deposits automatically; the pad prompt and HUD deposit button also work nearby. Wait 10 seconds for it to hatch. Your animal roams the lawn and earns cash automatically each second.
7. Spend cash with the HUD speed button or your ranch's speed shop. You start with $25; the first upgrade costs **$50**. **Rabbit Ridge unlocks at speed level 6**; its eggs take 18 seconds to hatch.
8. Stop Play before editing or opening a newer build. Follow [the Studio testing guide](docs/STUDIO_TESTING.md) before publishing anything.

No API key, DataStore setting, product ID, or external service is needed for Phase 1. Keep Studio API access disabled for this prototype.

## What's new in this refinement

- Grass lawns, wood hatchery pergolas, flower planters, stone paths, lanterns, trees, and walls along the central guardian route; lower exposure, shadows, and atmospheric color replace the washed-out lighting.
- World lettering stays on physical sign faces and disappears at a distance. Animal name billboards and oversized floating instructions are gone; details live in Collection.
- Smaller cash/speed indicators, one short objective, context-sensitive action buttons, occupied-nest countdowns, and illustrated collection cards.
- Larger pets wander within their ranch lawn, pause, turn, and use species-specific foot, hop, wing, ear, and tail motion. They no longer stand on display circles.
- Faster guardians and visible red territory borders. Crossing out ends the chase **without losing the egg**; guardians never chase back to the ranches. Rabbit requires more upgrades.
- Short cues for stealing, escape, catching, depositing, hatching, upgrades, menus, and rejected actions, with a **Sound effects** toggle in Settings. These use Roblox-bundled sounds; no upload is needed. They are basic feedback cues, not custom animal recordings. No music plays.

The supplied reference-game link could not be opened from this cloud environment. These changes address the owner's playtest feedback and screenshots; they are not a verified recreation of that experience. See [research evidence](docs/RESEARCH.md#refinement-research--2026-10-10).

## Core gameplay

- Five assigned ranches, spawn/respawn routing, a central path, and two guardian zones.
- Single egg carrying, validated stealing, server-driven guardian chasing/return/cooldown, and catch recovery.
- Three hatch slots per player, synchronized countdowns, and server-selected weighted animal rewards.
- Seven original procedural animal designs with roaming and limb motion; four obtainable rarity tiers. Legendary, Mythic, and Secret are reserved in config and have no Phase 1 rewards.
- Fixed animal income, cash/speed leaderboard, 12 cash-funded speed levels, and centralized balancing.
- Eight active animals per player. When full, only a higher-income animal replaces the weakest; every discovered species enters the session collection. Lower-value duplicates do not reduce income.
- Responsive instance-built HUD, carrying/escaped objectives, rarity reveals, collection and upgrade panels, sound/effects/reduced-motion controls, and native mobile/PC movement and egg prompts. Device layouts still require Studio checks.
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

Checks include StyLua, Luau compilation, Roblox-aware static analysis with a Rojo sourcemap, pure logic test suites, and a validated `.rbxlx` build that embeds the checked source. No Roblox gameplay simulator is implied. Generated outputs live in ignored `build/`. Maintainers can run `python3 scripts/check.py --release` to refresh the deliberately tracked `release/Steal-a-Goofy-Egg.rbxlx` after all checks pass. The `release` copy is the beginner-friendly GitHub download; source changes must be rebuilt to appear in it.

### On your own Windows or macOS computer

For the simplest start, use the provided `.rbxlx` file. To work from the Git repository, install **Rojo 7.7.1** for your operating system using [the official installation guide](https://rojo.space/docs/v7/getting-started/installation/). In a terminal in the repository folder:

```bash
rojo build default.project.json --output Steal-a-Goofy-Egg.rbxlx
```

Open the resulting file in Studio. For live source edits, install the official Rojo Studio plugin, run `rojo serve default.project.json` locally, and connect the plugin to that local server. Keep CLI/plugin major versions compatible. The cloud Rojo server is not exposed to your desktop; local sync runs on your own machine. There is no user-facing cloud web preview for this game.

## Configuration and next phases

Change names, colors, income, egg odds, zone difficulty/boundaries, hatch times, sound volume, and speed prices in [`src/shared/Config.luau`](src/shared/Config.luau). The turtle runs at 19 studs/second, rabbit at 31; player speed starts at 16 and increases by 2 per level. The first upgrade costs $50, with a 1.65 price multiplier per level. Both guardians have a short wake-up delay so a prompt escape is possible; exact difficulty still needs playtesting. Probability weights total 100 per zone and are tested. Rabbit has better odds; a rare turtle-zone animal still earns more than a common rabbit-zone animal. Rewards are free gameplay outcomes, never paid randomized purchases.

**Phase 2 remaining:** durable save/load with session ownership and safe failure handling; more zones/animals; inventory management beyond the best-eight garden; continued progression, animation, and UI refinement from Studio playtests.

**Phase 3 remaining:** configurable official Gamepasses and Developer Products with placeholder IDs until created; durable idempotent receipt processing; convenience boosts; measured balancing/mobile performance; polished tutorial and release preparation. No purchase is prompted in this build. Custom sound design remains future work; music stays absent.

The original procedural animals need no uploaded meshes or animations. Custom art, animation, and owned/licensed SFX can refine them further. Review [architecture](docs/ARCHITECTURE.md), [testing](docs/STUDIO_TESTING.md), and [research limitations and design assumptions](docs/RESEARCH.md).
