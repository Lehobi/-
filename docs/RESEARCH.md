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
