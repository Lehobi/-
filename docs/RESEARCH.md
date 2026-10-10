# Reference research and original design decisions

Research attempted on 2026-10-09. **The reference games could not be observed in this cloud environment.** No reference gameplay, UI screenshot, asset, probability table, purchase flow, or performance measurement was inspected. This document separates that limitation from the original design proposed for this prototype.

## Access evidence

| Destination attempted | Result | What this establishes |
| --- | --- | --- |
| [Roblox discovery search for Steal an Egg](https://www.roblox.com/discover/?Keyword=Steal%20an%20Egg) | HTTPS proxy CONNECT returned 403 Forbidden | The exact experience and its current mechanics could not be verified. |
| [Roblox games search API](https://games.roblox.com/v1/games/list?model.keyword=Steal%20an%20Egg) | HTTPS proxy CONNECT returned 403 Forbidden | No game listing or experience identifier was obtained. |
| [Steal a Brainrot comparison URL](https://www.roblox.com/games/109983668079237/Steal-a-Brainrot) | HTTPS proxy CONNECT returned 403 Forbidden | This candidate comparison page was not read; its current content was not verified. |
| [Google search](https://www.google.com/search?q=Roblox+Steal+an+Egg+turtle+rabbit) and [Bing search](https://www.bing.com/search?q=Roblox+Steal+an+Egg+turtle+rabbit) | HTTPS proxy CONNECT returned 403 Forbidden | No secondary gameplay reports were read. |

A network denial is not evidence about how a game works. Claims about those games' base counts, prices, exact rarity odds, interface layouts, retention metrics, or monetization would be speculation. No such claims are used as requirements. The user's supplied concept is the primary design source. All project Luau, procedural models, and interface code are original.

## Verified Roblox platform guidance

Roblox's public `Roblox/creator-docs` repository was accessible over verified HTTPS through `raw.githubusercontent.com`. These are platform references, **not** reference-game research:

- [Securing the client-server boundary](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/security/client-server-boundary.md): validate context, permissions, types, values, and frequency on the server. ProximityPrompt settings alone are not sufficient authorization. Critical interactions need distance, alive-state, cooldown, and ownership checks; movable interaction parts need careful network ownership.
- [Server-side detection](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/security/server-side-detection.md): the server decides outcomes, with validation and rate limits as the primary defenses. Conservative movement checks can reject impossible trips without permanently punishing a player on one uncertain signal.
- [Proximity prompts](https://github.com/Roblox/creator-docs/blob/main/content/en-us/ui/proximity-prompts.md): prompts support keyboard/gamepad controls and direct interaction on phones and tablets. Use them for egg and hatch-slot actions and still validate actions on the server.
- [Developer products](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/developer-products.md): official MarketplaceService purchase prompts and server-side `ProcessReceipt` handling are required. Purchases and durable receipt handling belong to a later phase, after persistence; the prototype does not sell random rewards.

## Proposed design, not observations of other games

| Topic | Original Phase 1 choice | Reason / assumption to test |
| --- | --- | --- |
| Core loop | Take one egg, escape its guardian, hatch at home, collect automatic income, buy speed. | A short first successful trip should teach all major actions. |
| Bases and spawning | Five assigned bases beside the start of one broad path; spawn in your own base. | Players can find home quickly and share a readable central space. |
| Zone progression | A slow turtle and a faster rabbit, with clearly different silhouettes and colors. | Turtle should be escapable at starting speed; rabbit should motivate upgrades. Exact timing needs Studio playtesting. |
| HUD hierarchy | Cash, income/sec, speed, carry state, and next objective first; hatch status and a cash upgrade action next. | Players should understand the current task while moving. Avoid covering touch movement/jump controls. |
| Economy | Animals generate fixed cash/sec automatically; increasing speed costs and a small starting balance. | First upgrades should arrive quickly, without a Robux prerequisite. Numeric balance is provisional. |
| Egg and animal collection | Guardian species and hatch species are separate concepts; server chooses from a centralized weighted pool. | A turtle egg can reveal a duck or frog. Existing animals survive a failed chase. |
| Rarity | Configurable, validated weights per zone; early zones exclude later top-tier rewards. | Verify weights total correctly and zero-weight outcomes never occur. Early rare animals can outperform later common animals. |
| Replayability | Visible collection growth, improving income, faster trips, and a clear next zone. | These are design hypotheses, not measured retention improvements. Avoid daily-pressure or paid-random mechanics. |
| Mobile / PC | Native movement and proximity controls, large buttons, concise text, responsive HUD, a wide route. | Test narrow screens, touch controls, readability, and multiplayer separately in Studio. |
| Monetization | No active purchases in Phase 1; later optional fixed benefits with official prompts. | Save/load and durable idempotent receipts must exist before paid products. No paid randomized rewards. |

## Research and validation still required

In Roblox Studio and the Roblox client, inspect the intended Steal an Egg experience after identifying its official URL. Record only publicly visible observations; do not extract protected assets or source. Compare the first five minutes, return-trip clarity, UI on a phone-sized screen, free progression, and purchase disclosures. Treat exact odds as unknown unless the creator publishes them. Test this prototype independently with two and five clients before describing its gameplay as working.

## Refinement research — 2026-10-10

The user tested the first place in Roblox Studio and reported that the core loop works without observed lag or bugs so far. Their supplied screenshots show this project's washed-out white floors, large floating text, sparse bases, small pets, and oversized HUD. This is evidence about **our first build**, not screenshots of another creator's game. The user requested bounded guardian chases, red territory lines, stronger progression, roaming pets, sound cues, walls along the central route, and a substantial visual/UI revision. Those concrete requests guide this refinement; the earlier Phase 1 design table above is retained as history.

The user then supplied the [intended reference experience share link](https://www.roblox.com/share?code=d02adc31bffdd14b843b470ba0edde61&type=ExperienceDetails&stamp=1791602574459). A normal HTTPS request to that exact link returned `Tunnel connection failed: 403 Forbidden` before any redirect or experience identifier could be read. Fresh requests to Roblox discovery, the games search API, and Google search returned the same proxy denial. No access-control workaround was used. The target experience's current visuals, chase logic, interface, sounds, and economy therefore remain **unobserved**; this release must not be described as a verified recreation or direct comparison. Its assets and implementation remain original.

### Platform references checked for this revision

These official Roblox sources were retrieved successfully over verified HTTPS from `raw.githubusercontent.com`:

- [Lighting API](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/Lighting.yaml): ambient and outdoor ambient affect scene brightness; exposure compensation biases the scene before tone mapping. Lower ambient illumination, controlled exposure, shadows, and distinct floor materials are supported ways to address the screenshots' washed-out appearance. A cloud build cannot establish the final rendered appearance on the user's graphics settings.
- [SurfaceGui API](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/SurfaceGui.yaml) and [BillboardGui API](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/BillboardGui.yaml): a billboard faces the camera; a surface GUI is attached to a part face. Use physical sign faces for stationary world labels, sensible world dimensions, `AlwaysOnTop = false`, and finite `MaxDistance`. Merely reducing a billboard's font does not fix camera-following text.
- [Sound API](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/Sound.yaml): `PlaybackSpeed` changes speed/pitch; `IsLoaded` and `Loaded` indicate readiness. `RollOffMaxDistance` limits spatial sounds parented to a part or attachment. Audio loading must not block gameplay, and a failed asset must not leave an indefinite wait or leaked instances.
- [SoundService API](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/SoundService.yaml): `PlayLocalSound` plays a client-only copy, preserving volume, time position, playback speed, and sound-group effects. `Looped` does not carry over. A local sound group permits a user-facing mute control without changing other players' audio.
- [Audio assets guide](https://github.com/Roblox/creator-docs/blob/main/content/en-us/audio/assets.md): Creator Store offers audio for use in experiences; imported audio requires rights and can require experience permissions. No unverified public audio IDs, other game's sounds, or invented permissions were added as research findings.

### Verified bundled sound options

[Roblox's archived default character sound script](https://github.com/Roblox/Core-Scripts/blob/master/PlayerScripts/StarterCharacterScripts/Sound.server.lua) explicitly references the following local engine sound paths. A [current public client-tracker copy of the character script](https://github.com/MaximumADHD/Roblox-Client-Tracker/blob/roblox/scripts/PlayerScripts/StarterPlayerScriptsCommon/RbxCharacterSounds.lua) and its [Studio file manifest](https://github.com/MaximumADHD/Roblox-Client-Tracker/blob/roblox/rbxManifest.txt) corroborate these filenames. The tracker is an **unofficial mirror**, not Roblox documentation; it establishes file-name evidence, not successful playback in this project.

| Verified local URI | Possible original cue treatment |
| --- | --- |
| `rbxasset://sounds/action_get_up.mp3` | Short pitch-varied positive interaction or upgrade cue. |
| `rbxasset://sounds/action_jump.mp3` | A light pickup or UI cue at restrained volume. |
| `rbxasset://sounds/action_jump_land.mp3` | Nest placement, crack, or failure punctuation. |
| `rbxasset://sounds/impact_water.mp3` | A softened pop/splash layer for the hatch reveal. |

These are engine-bundled references; the project does not redistribute the sound files. Combining short cues and varying pitch/timing can make hatch and interaction feedback audible without asking the beginner to upload assets. They are a basic feedback layer, not a custom soundtrack or proof of a polished final sound mix. The official script's license applies to that script; it does not establish a separate license to extract and redistribute the sound files. Audition the result in Studio and a published client before promising audio quality or universal asset availability.

The current mirrored manifest also lists `impact_explosion_03.mp3`, `volume_slider.ogg`, `oof.ogg`, and `ouch.ogg`, but those were not auditioned. Common internet examples `rbxasset://sounds/electronicpingshort.wav` and `rbxasset://sounds/switch.mp3` were **not** present in that manifest and could not be verified from the inspected official sources; do not rely on them as guaranteed bundled cues. A request to Roblox's official CDN manifest endpoint was denied by the proxy, so it did not provide independent current-package verification.

### Remaining reference comparison

When the provided experience can be opened, compare its public first five minutes with this revised build: path enclosure, contrast and sign scale, base activity, approach/escape timing at the first two guardians, visible territory cutoffs, HUD footprint on a phone, and the timing of hatch feedback. Record observations separately from design choices. The user has already supplied the target link; identifying an experience by guesswork or asking for the link again is unnecessary.
