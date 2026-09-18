# Brainrot Stampede — project notes for Claude Code

This repo is a Roblox **Luau** game: Version 1 of "Brainrot Stampede," a
Rodeo Stampede–style endless runner reskinned into an original Brainrot
meme universe. Full design context and the "what's simplified and why"
writeup lives in `README.md` — read that first if you need the why behind
a decision, this file is about *doing* things with the project (running,
testing, iterating), assuming you have Roblox Studio + this repo on the
same machine.

## If you're driving Studio via its MCP server

1. Confirm the MCP connection is live (Studio → Assistant Settings → MCP
   Servers should show a connected client).
2. Get the code into a live place. Two ways:
   - **Rojo (preferred)**: `rojo serve` from repo root, then in Studio's
     Rojo plugin panel click Connect against `default.project.json`. Any
     edit to files under `src/` syncs live without re-copying anything.
   - **No Rojo**: paste each file from `src/` into the matching Explorer
     location per the tree in `README.md` → "Manual placement".
3. Press Play (or Play-Solo). Watch the Output window — that's your
   primary feedback channel; there's no automated test suite for gameplay
   feel, so treat manual playtesting + Output errors as the test suite.
4. Work through the playtest checklist in `README.md` ("Playtest checklist
   (Version 1 acceptance)") top to bottom. Stop and fix on the first
   Output error or broken step rather than pushing through — later steps
   usually depend on earlier ones (e.g. capture depends on jump working).
5. After any code fix, re-sync (Rojo does this automatically on save) and
   re-run from the *start* of the checklist, not just the step that broke.

## Where things live (quick map)

- `ReplicatedStorage/Modules/` — all game data tables (Brainrots, biomes,
  missions, economy/upgrade curves, rarity tiers) plus shared code used by
  both client and server (`Remotes.lua`, `BrainrotModelFactory.lua`).
- `ServerScriptService/Main.server.lua` — boots every service in
  `ServerScriptService/Services/` in dependency order. If something isn't
  initialized, this is where to check the wiring.
- `ServerScriptService/Services/` — one ModuleScript per system
  (PlayerDataService, EconomyService, RunManagerService, HabitatService,
  MissionService, BiomeService, AntiCheatService, BrainrotSpawner,
  MapBuilder). Anything that touches coins, captures, or saved profile
  data goes through here — never trust a value the client just sent.
- `StarterPlayer/StarterPlayerScripts/` — client-only world/gameplay
  logic: `BrainrotRidingController.lua` (the run loop), `TrackBuilder.lua`
  (endless track), `IslandBuilder.lua` (hub), `CameraController.lua`.
- `StarterGui/` — `Main.client.lua` is the client bootstrap that wires
  everything above to the UI modules (`HUD`, `MainMenu`, `CollectionUI`,
  `MissionUI`).

## Known architecture quirk to remember

The run track and Brainrot Island are built by **client-side** scripts
(`TrackBuilder`/`IslandBuilder`), so those parts never replicate to other
players or the server — each player effectively plays in a private
instance of the world. If you're testing multiplayer and don't see another
player's run/habitats, that's expected per current V1 design, not a bug.
See README → "Architecture & Simplifications" before "fixing" it.

## Reporting back

When you finish a playtest pass (clean or not), summarize: which
checklist steps passed, which failed and with what Output error/symptom,
and what you changed. If you push fixes, use the same
`claude/brainrot-stampede-game-pjnr33` branch unless told otherwise.
