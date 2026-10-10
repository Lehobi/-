# Open and test the Phase 1 prototype

**Roblox Studio has not been run in this Linux cloud environment.** The code and generated place need the engine tests below before anyone describes gameplay, multiplayer, mobile support, or performance as verified. All Studio rows in the release checklist are pending until a tester records results.

## 1. Download and open the place

1. Open [`release/Steal-a-Goofy-Egg.rbxlx`](../release/Steal-a-Goofy-Egg.rbxlx) on GitHub. Click **Download raw file** (the download-arrow icon above the file) and save the `.rbxlx` file to your computer. Alternatively choose **Code → Download ZIP**, extract it, and open the file from the `release` folder. **No build tools or terminal are needed.**
2. Install [Roblox Studio](https://create.roblox.com/docs/studio/setup) on Windows or macOS and sign in to your Roblox account.
3. In Studio choose **File → Open from File…** and select `Steal-a-Goofy-Egg.rbxlx`. Some Studio versions label this **Open…**. Open the place file itself; do not paste it into a script. If it was saved with a `.txt` extension, download it again using GitHub's download button.
4. Open **Explorer**, **Properties**, and **Output** from Studio's View controls. The place can look empty in edit mode: its map, animals, prompts, and HUD are built when play starts.
5. Click **Play** or press **F5**. Allow the character and world to finish loading. Output should contain `Steal a Goofy Egg: Phase 1 initialized` and no red errors.
6. Click **Stop** or press **Shift+F5** before rebuilding, opening a replacement place, or synchronizing changed source. Runtime changes made while playing are not source edits and disappear when testing stops.

For developers rebuilding on Linux, run `python3 scripts/bootstrap.py` then `python3 scripts/check.py` in the repository. Tools install into `.tools`; set `GOOFY_TOOLS_DIR` to reuse another prepared directory. This produces `build/Steal-a-Goofy-Egg.rbxlx`. `python3 scripts/check.py --release` also refreshes the tracked GitHub download after all checks pass.

No Rojo Studio plugin is needed to open the built file. For ongoing live source editing, install the matching official Rojo plugin and run `rojo serve default.project.json` on the **same computer as Studio**, then connect the plugin to that local server. The cloud machine's localhost is not your desktop's localhost. Keep repository source as the source of truth and stop play before a new sync.

This prototype needs no API key, product ID, DataStore setting, or **Enable Studio Access to API Services** option. It has no save/load system: leaving, restarting play, or joining a different server resets cash, animals, discovery, and upgrades.

For a later published test place, use its Creator Dashboard configuration to set the maximum server size to **5**. This is usually under the experience's **Places → select the place → Configure → Access / Server Settings → Maximum Players**; Roblox changes these labels, so locate the place-level maximum-player field. The code assigns five bases and rejects an extra player; building a `.rbxlx` does not configure the dashboard. Publishing is a separate owner action and was not performed by the cloud task.

## 2. First single-player loop

Use WASD and the mouse on PC, the default thumbstick on touch devices, and the standard jump control. Approach an egg and **hold E**; on mobile hold its on-screen proximity prompt. Controller prompts use X.

| Action | Expected result |
| --- | --- |
| Join | Spawn in your assigned, named base. HUD shows $25, $0/sec, speed level 0, and empty hatch slots. Five bases exist. |
| Follow the wide path to Turtle Meadow | An egg and turtle are present; the egg prompt appears nearby. |
| Hold the steal prompt | One egg attaches to you, the world egg becomes unavailable, and the turtle chases you. The carry objective identifies your base. |
| Run home | The turtle is slower than starting movement on the open route. Reach your own glowing **BRING EGG HERE** pad. This timing is a design expectation requiring testing. |
| Enter the deposit area | The carried egg disappears and one hatch slot begins its countdown automatically. The nearby prompt / HUD deposit button are alternatives, not a second reward. |
| Wait for hatching | A turtle egg uses a 10-second deadline. Expect reveal on the next server economy tick after it expires. An animal appears and income rises. It need not be a turtle. |
| Observe cash for several seconds | Cash increases by the displayed income/sec each server second. The player list cash value agrees with the HUD after updates. |
| Buy speed | The initial upgrade costs $25 and changes level 0→1, WalkSpeed 16→18. Further prices increase. Clicking without enough cash changes neither level nor balance. |
| Reach level 4 | Rabbit Ridge unlocks at level 4 (WalkSpeed 24). Earlier steal attempts there are rejected. Its guardian is faster than the turtle; its hatch deadline is 18 seconds. |
| Open Collection, Shop, Settings | Collection shows discovered species. Shop offers cash speed upgrades, with no real Robux purchase. Reduced motion / visual effects settings affect presentation. No background music plays. |

Check each base's route home. Base distances differ, and passing one test from Base 1 does not prove that Base 5's return trip or visibility is fair.

## 3. Failure and repeated-action checks

- Steal an egg, then stop near its guardian and let it catch you. The egg should be lost, you should return home, and your previous cash, animals, and income should remain.
- Reset your character while carrying (Roblox menu → Reset Character). Verify the carried egg vanishes, the chase ends, and respawn uses your own base. Repeat a reset without carrying.
- Take too long on a trip: the chase has a 60-second limit. Verify the egg is reclaimed and your established collection survives.
- Deposit once, then repeatedly use the prompt / deposit button. There should be one pending hatch and one eventual reward, never repeated rewards for the same egg.
- Attempt another egg while already carrying. One character must never carry two eggs.
- After any chase ends, watch the guardian return home and then wait its cooldown (turtle 8 seconds, rabbit 10 seconds). Cooldown starts after the return finishes; the egg should then become available again.
- Use legitimate jumps, edges of the base rails, low frame rates, and Studio's available network-latency simulation. Record any unexpected movement reset; do not treat the presence of a movement check as proof it is tuned correctly.

There is no manual **drop egg** action in Phase 1. The loss paths to test are catch, death/reset, departure, timeout, and movement rejection.

## 4. Two-player, then five-player tests

Stop the solo session. In Studio's **Test** tab or newer **Test** menu, select **Server & Clients** (older versions: **Local Server**), choose **2 clients**, and start. Studio should open one server view and separate player views. Repeat the whole set with **5 clients** after the two-client checks pass. Menu labels vary by Studio version.

1. Confirm every client has a distinct base, spawn, and owner sign. Each client's cash and collection start independently.
2. Have both players approach one available egg and trigger nearly together. Only one receives it. The guardian targets the actual carrier, not the observer.
3. Have the carrier visit another player's deposit pad. The egg must remain carried; no hatch should appear in that other base. Return to the correct base to deposit.
4. Hatch or buy an upgrade on client A. Check client B's cash, speed, income, and discovery remain unchanged. Other clients should still see A's world animal and the guardian/egg state.
5. Run the turtle and rabbit chases at the same time after one player unlocks rabbit. Neither guardian should switch targets or produce duplicate zone eggs.
6. Close one player client during a chase and another while an egg is hatching. In the server view, their base becomes unclaimed, visuals clear, and the guardian returns normally.
7. If your Studio test controls provide **Add Client / Start Player**, join a replacement client to the same running local server. It should receive a freed base and fresh session state. If your Studio version cannot add a client to an existing session, mark this exact reassignment check pending and perform it in a private published test server later; restarting a whole session does not test reassignment.
8. Test all five players moving, hatching, opening menus, and buying upgrades at once. Confirm the server Output and every client Output remain free of errors. An optional sixth-client attempt should get the occupied-bases message rather than an overlapping base.

## 5. Hatch capacity, collection capacity, and odds

There are three hatch slots and eight earning animal spaces per player. Normal 10/18-second hatches often complete before enough return trips can fill all slots at once. The CLI session tests exercise capacity deterministically; use this isolated Studio setup to observe all three world slots together:

1. Start a fresh **local** test. In the **server** context Command Bar (not a client), run:

   ```lua
   local cfg = require(game.ReplicatedStorage.GoofyEgg.Shared.Config)
   for _, zone in cfg.zones do zone.hatchSeconds = 600 end
   ```

   This changes only the running server's module table. It delays **newly deposited** eggs to ten minutes; it does not change existing deadlines or the repository. Do not apply this tuning to a public server.
2. Perform three valid steal-and-return trips. Verify slots 1, 2, and 3 each show one egg and countdown. A fourth steal attempt must be rejected while all three remain occupied.
3. Watch the pending eggs complete at their separate deadlines, or use this interval for the performance soak below. Each should award once and free its slot.
4. Stop play to discard the temporary timing. Restart and verify ordinary 10/18-second hatch timing is restored.

After at least nine successful ordinary hatches, verify no more than eight animals earn income. A higher-income arrival replaces the weakest displayed animal; a weaker or equal arrival is still discovered but is not added to income. The reveal explains whether it was kept. Check displayed income against the sum of the retained animals. The pure tests cover specific stronger/weaker cases without relying on a lucky random draw.

Configured rarity chances are:

| Zone | Common | Uncommon | Rare | Epic | Legendary / Mythic / Secret |
| --- | ---: | ---: | ---: | ---: | ---: |
| Turtle Meadow | 78% | 20% | 2% | 0% | 0% |
| Rabbit Ridge | 52% | 32% | 14% | 2% | 0% |

The server chooses rarity first and then uniformly chooses an animal from that rarity. A few hand-played hatches cannot verify those percentages. CLI tests check exact boundaries, totals, and impossible outcomes; any empirical sample should record its sample count and sampling uncertainty. Never change an expected probability simply to make a small observed sample fit. Top-three rarity names are reserved configuration entries with zero chance and no Phase 1 animals.

## 6. Remote validation in your local test

These snippets are for the **client** context of Studio's Command Bar in this game's own local test. Open Command Bar from View or Studio's window controls, and confirm the context is the player/client rather than the server. Use Output to inspect results. Do not paste a server-only grant script into this section.

First obtain a snapshot:

```lua
local r = game.ReplicatedStorage.GoofyEgg.Remotes
local s = r.GetState:InvokeServer()
print(s and s.cash, s and s.speedLevel, s and s.carrying)
```

Wait at least 0.6 seconds between state reads; the server intentionally rate limits them.

| Local client probe | Expected outcome |
| --- | --- |
| `game.ReplicatedStorage.GoofyEgg.Remotes.Action:FireServer("GiveCash", 1000000)` | No grant. Unknown intent / extra arguments do not alter authoritative state. |
| `game.ReplicatedStorage.GoofyEgg.Remotes.Action:FireServer({action = "UpgradeSpeed"})` | Wrong type is ignored without a server error. |
| `game.ReplicatedStorage.GoofyEgg.Remotes.Action:FireServer("UpgradeSpeed", -999)` | Extra argument is rejected; no free upgrade. |
| `game.ReplicatedStorage.GoofyEgg.Remotes.Action:FireServer("DepositEgg")` while carrying far from your pad | No deposit or reward. The server checks your own base and distance. |
| `print(game.ReplicatedStorage.GoofyEgg.Remotes.GetState:InvokeServer("someone_else"))` | Returns nil; the caller cannot request another player's state. |
| `for i = 1, 30 do game.ReplicatedStorage.GoofyEgg.Remotes.Action:FireServer("UpgradeSpeed") end` | Burst is rate limited; no negative cash or unaffordable upgrades. A legitimate affordable request may still spend cash. |

Use a fresh local session without animals when comparing exact cash before/after a probe, or account for ordinary passive income. A valid `UpgradeSpeed` request is intentionally allowed away from the physical shop; that is not a distance-validation failure.

For an obvious movement-abuse probe, first carry an egg and then run in the client Command Bar:

```lua
local character = game.Players.LocalPlayer.Character
character:PivotTo(character:GetPivot() + Vector3.new(250, 0, 0))
```

Expect the server to clear the carried egg and return you home, without losing existing animals. Repeat with legitimate movement under simulated latency to check false positives. This single probe does not establish comprehensive exploit resistance. Native prompt spoofing and network-ownership attack paths need a separate targeted security review; there is no supported `fireproximityprompt` API to paste into ordinary Studio scripts.

## 7. Phone layouts and performance

Use Studio's **Device Emulator** (usually in Test) and choose a small phone. Test both portrait and landscape, then a tablet and desktop. The emulator checks layout and controls; an actual phone still needs a later performance pass.

- Confirm cash, speed, objective, countdown, and session-reset notice are readable; menus and their close buttons fit inside safe areas.
- Move and jump while approaching an egg. HUD buttons must not block the bottom-left movement thumbstick or bottom-right jump control. Hold the touch proximity prompt successfully.
- Open Collection, Shop, and Settings; scroll, close, and reopen. Check hatch reveals while moving and when a menu is already open. No tap should accidentally buy multiple upgrades.
- Enable reduced motion, then disable visual effects. Verify collection bobbing and decorative effects respond, with no change to income or hatch rewards.
- Run five clients for at least ten minutes with chases and hatching. Watch Output, frame time / FPS, memory, and network statistics. Use Studio's MicroProfiler for unexplained spikes. Record hardware, player count, graphics level, and before/after values; no numerical performance guarantee has been established.
- Repeatedly reset characters and join/leave clients. Check that carried eggs, base animals, connections, and HUD instances do not accumulate. At full display capacity the design caps earning animals at 40 across five bases, plus guardians and eggs.

## Release evidence checklist

Record the Studio version, date, tester, player count, device/emulation size, and Output errors for each engine run. Keep failures and unrun cases visible.

| Check | Evidence to retain | Current status |
| --- | --- | --- |
| Pinned tools, formatting, Luau compilation, Roblox-aware static analysis, pure tests, Rojo build | Complete `python3 scripts/check.py` output for the current commit | Run/record through the repository checker; these are not engine tests. |
| Single-player complete loop from every base | Results, elapsed first-trip / upgrade times, Output | **Pending Studio** |
| Catch, death, respawn, timeout, cooldown | Before/after cash, carry, animals; Output | **Pending Studio** |
| Two-player and five-player isolation / simultaneous steals | Per-client results, server/client Output | **Pending Studio** |
| Leave cleanup and same-server base reassignment | Departing/replacement client results | **Pending Studio** |
| Three hatch slots and best-eight capacity | Slot/reward counts and income checks | **Pending Studio** |
| Invalid remote payloads and movement checks | Before/after server snapshots and errors | **Pending Studio** |
| Portrait, landscape, tablet, and desktop HUD | Screen sizes and screenshots | **Pending Studio** |
| Five-client soak and real-device performance | Duration, device, frame time, memory, network notes | **Pending Studio** |
| Saves, gamepasses, products, durable receipts | Later-phase test plan | **Not implemented in Phase 1** |

Do not release this as a persistent or monetized game. Finish the Studio checks, fix observed engine bugs, and implement later-phase persistence and receipt safety before public release claims.
