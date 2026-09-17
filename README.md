# Brainrot Stampede — Version 1 (Roblox)

A Rodeo Stampede–style endless runner reskinned into an original Brainrot
meme universe: ride a Brainrot, steer, jump onto nearby Brainrots, tame
undiscovered ones, dodge/smash obstacles, survive rage, bank coins, and
grow **Brainrot Island** — your habitat hub — between runs.

This repo is a complete, playable Roblox **Luau** codebase for **Version 1**
of the design doc: Brainrot Plains, 8 Brainrots, the full ride/jump/capture/
rage/crash loop, 8 habitats with upgrades, a Collection menu, 5 missions,
DataStore saving, and mobile + PC controls.

## Quick start (recommended: Rojo)

1. Install the [Rojo](https://rojo.space) plugin in Roblox Studio and the
   `rojo` CLI (`cargo install rojo` or via [Aftman](https://github.com/LPGhatguy/aftman)).
2. Create a new, empty Roblox place (any template — the game builds its own
   spawn platform at runtime, see `MapBuilder.lua`).
3. From this repo's root: `rojo serve`.
4. In Studio, open the Rojo plugin panel and click **Connect**.
5. Press **Play** (or **Play (Here)**) in Studio. Enable **Team Create** /
   API access for `DataStoreService` to persist saves (Studio auto-mocks
   DataStores locally, which is fine for testing).

`default.project.json` maps `src/` 1:1 onto `ReplicatedStorage`,
`ServerScriptService`, `StarterPlayer.StarterPlayerScripts` and
`StarterGui` — Rojo's filename suffixes (`.server.lua`, `.client.lua`,
plain `.lua`) already encode the correct instance type (`Script`,
`LocalScript`, `ModuleScript`), so no manual class changes are needed.

## Manual placement (no Rojo)

If you'd rather copy/paste files directly into Studio's Explorer, create
this exact hierarchy and paste each file's contents into an instance of the
matching class:

```
ReplicatedStorage
└── Modules                          (Folder)
    ├── RarityData            (ModuleScript)
    ├── BrainrotData          (ModuleScript)
    ├── BiomeData             (ModuleScript)
    ├── MissionData           (ModuleScript)
    ├── EconomyData           (ModuleScript)
    ├── UpgradeData           (ModuleScript)
    ├── Remotes               (ModuleScript)
    ├── BrainrotModelFactory  (ModuleScript)
    └── UI                            (Folder)
        └── UIStyle           (ModuleScript)

ServerScriptService
├── Main                      (Script)         -- from Main.server.lua
└── Services                          (Folder)
    ├── PlayerDataService     (ModuleScript)
    ├── EconomyService        (ModuleScript)
    ├── AntiCheatService      (ModuleScript)
    ├── BrainrotSpawner       (ModuleScript)
    ├── RunManagerService     (ModuleScript)
    ├── HabitatService        (ModuleScript)
    ├── MissionService        (ModuleScript)
    ├── BiomeService          (ModuleScript)
    └── MapBuilder            (ModuleScript)

StarterPlayer
└── StarterPlayerScripts
    ├── CameraController          (ModuleScript)
    ├── BrainrotRidingController  (ModuleScript)
    ├── TrackBuilder              (ModuleScript)
    └── IslandBuilder             (ModuleScript)

StarterGui
├── Main               (LocalScript)   -- from Main.client.lua
├── HUD                (ModuleScript)
├── MainMenu           (ModuleScript)
├── CollectionUI       (ModuleScript)
└── MissionUI          (ModuleScript)
```

`Remotes.lua` creates every `RemoteEvent`/`RemoteFunction` at runtime under
`ReplicatedStorage.Remotes` the first time it's required — you don't need to
hand-create any Remote instances.

## What's actually in Version 1

**8 Brainrots** (Brainrot Plains): Tralalero Dude, Espresso Goblin, Banana
Sigma, Croco Bro, Cappuccino Kid, WiFi Pigeon, Spaghetti Warrior, Microwave
Monkey — each with a distinct speed/handling/rage-timer/special ability
(`ReplicatedStorage/Modules/BrainrotData.lua`).

**8 habitats** on Brainrot Island (Tralalero Beach, Goblin Espresso Den,
Sigma Gym, Crocodilo Swamp, Cappuccino Cafe, Pigeon Rooftop, Spaghetti
Kitchen, Monkey Internet Cafe), each upgradeable 7 levels with visually
tiered platforms (wood → concrete → marble → gold neon).

**5 missions**: ride 5 different Brainrots in a run, travel 2,000 studs,
capture a new Brainrot, chain 10 jumps without crashing, collect 500 coins
(`ReplicatedStorage/Modules/MissionData.lua` — the pool has more for later
versions to rotate through).

**Full loop**: spawn → menu → start run → steer/jump/tame/dodge/smash →
rage → crash → run summary → back on Island → captured Brainrot appears in
its habitat → upgrade it → play again. Coins, captures, mission progress
and habitat levels all save via `DataStoreService`.

## Architecture & simplifications (read this before extending)

This is a from-scratch, asset-free delivery (no imported meshes/animations/
audio), so a few deliberate simplifications keep it fully playable without
external art. They're the first things to swap out for a real production:

- **Procedural Brainrots.** `BrainrotModelFactory.lua` builds every Brainrot
  from primitive Parts (ball torso/head, block legs) with a cheap bob/tilt/
  jitter animation loop instead of a skinned rig. Swap `Create()`/`Animate()`
  for real meshes + AnimationTracks per Brainrot without touching any other
  system.
- **Client-rendered private world.** The endless track (`TrackBuilder.lua`)
  and Brainrot Island (`IslandBuilder.lua`) are built from a `LocalScript`
  context, so Roblox never replicates those parts to the server or other
  clients — each player effectively runs and collects in their own private
  instance of the world. This is what makes an endless on-rails runner and a
  per-player habitat display cheap to build without a full multiplayer
  physics/visibility system. The tradeoff: players don't currently *see*
  each other running or walking the Island. A true shared-world Version 2+
  would move track/Island ownership to the server and stream per-player
  collection state via a player-scoped container instead.
- **Client-simulated movement, server-clamped economy.** `BrainrotRidingController.lua`
  owns the moment-to-moment feel (steering, speed, jump detection) so
  controls feel instant. It streams distance deltas to
  `RunManagerService` every 0.25s; `AntiCheatService.ClampDistanceDelta`
  caps every delta to what the ridden Brainrot could plausibly cover, and
  captures are re-validated server-side against elapsed mount time before
  any coins, collection entries or mission progress are written. No
  currency- or progression-affecting value is ever trusted verbatim from
  the client.
- **Continuous 3-lane-ish steering**, not a fixed 3-lane snap: the rider's
  X position is continuous (`STEER_BASE_SPEED`/`Handling` control how fast
  it responds), while obstacles/Brainrot spawns snap to 3 lane columns for
  readability. Jump range is measured in studs, not lane indices.
- **Shop / Daily Reward / Gamepasses / Settings** are Version 2 scope per
  the design doc's own version plan. Their Main Menu buttons exist and open
  a "coming soon" notice (`MainMenu:ShowComingSoon`) rather than being
  missing entirely.
- **No copyrighted or imported audio/textures** — sound hooks are left as
  clearly-named `Special`/`DiscoveryAnim` ids in `BrainrotData.lua` for a
  sound designer to wire up real `Sound` instances against.

## Playtest checklist (Version 1 acceptance)

- [x] Spawn on Brainrot Island, see the menu, dismiss it
- [x] Walk around the Island (normal Roblox character controls)
- [x] Press PLAY (or touch the glowing Start Run portal)
- [x] Ride the starting Brainrot (Tralalero Dude), steer with A/D or the
      on-screen arrows
- [x] Jump onto a nearby Brainrot (Space / JUMP button)
- [x] Stand on an undiscovered Brainrot long enough to capture it — see the
      "NEW BRAINROT DISCOVERED!" popup
- [x] Earn coins from distance + captures (top-right HUD)
- [x] Crash into an obstacle or let rage time out
- [x] See the run summary, return to the Island
- [x] See the newly captured Brainrot standing in its habitat
- [x] Upgrade that habitat via its `ProximityPrompt` (spends coins)
- [x] Open the Collection menu and see captured vs. `???` silhouette cards
- [x] Open Missions and see progress bars / claim a completed mission
- [x] Rejoin the game and confirm coins/captures/habitat levels persisted

## Roadmap (Versions 2–4)

`BiomeData.lua` already lists all 8 zones (with unlock requirements) and
`BiomeService.lua` evaluates them — only Zone 1 has `Implemented = true`
and real geometry. To add a zone: flip its flag, add its Brainrots to
`BrainrotData.lua`, and give `TrackBuilder`/`IslandBuilder` a per-zone theme
(ground colors, obstacle set). `MissionData.Pool` already has extra mission
templates beyond the 5 active ones for a future daily-rotation system.
Gamepasses/dev products/prestige/leaderboards/random events/boss fights are
scoped in the design doc for Versions 2–3 and intentionally not stubbed
here beyond the Shop/Daily menu placeholders, to keep Version 1 focused and
fully working end-to-end.
