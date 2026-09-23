# Topline

A standalone status strip for World of Warcraft: Forever. No dependencies,
configuration screens, slash commands, or bundled libraries. Pedometer history
uses WoW's per-character SavedVariables.

## Installation

This folder is already installed in `_classic_beta_/Interface/AddOns/Topline`.
Enable **Topline** in the character selection AddOns list. If the newly created
addon does not appear, restart the client so it discovers the folder.

## Status items and layout

- Full-width, 20 UI-unit strip anchored to UIParent's top edge; generated dark
  leather and aged bronze moulding match the classic fantasy window frames.
  A small 256x32 TGA tiles horizontally. Leather and bronze rails use separate
  texture regions, keeping a two-unit top rail and three-unit bottom rail visible
  at the bar's thin height. Artwork uses a neutral white tint; a soft lower shadow
  finishes the edge. Native small font and muted
  pipe separators keep the text readable. See `Media/README.md` for asset provenance.
  It inherits UI scale and does not intercept mouse input.
- The layout helper reserves the strip's height plus two UI units of clearance
  by translating overlapping Blizzard buffs, debuffs, minimap, player, target,
  focus, and objective tracker frames below it. It preserves their relative
  anchors and leaves frames already below the strip alone. Changes wait until
  combat ends; Edit Mode is left alone until it closes. Re-anchoring, UI-scale,
  and layout events trigger a coalesced check, with no layout polling. UIParent
  itself and the world viewport are not resized. Changes are not saved into
  Blizzard's Edit Mode layouts.
- Zone/subzone events update the location label. Coordinates use `C_Map` every
  0.5 seconds; unchanged rounded values reuse the existing string. Missing map
  positions and the `(0, 0)` unavailable sentinel are omitted.
- XP counts actual changes from the session's starting XP, including the
  remaining XP in a level when it rolls over. Rates use all elapsed session time,
  including idle time. Estimates require 60 seconds and positive XP earned.
  XP events are sampled after dispatch so level-up APIs can settle; a five-second
  ticker refreshes the elapsed-time calculation. Zoning does not reset counters.
  Logging in or reloading the UI starts a new XP session; XP is not persisted.
- Max-level players show `XP: Max level`. Unavailable XP shows N/A. For a boost or
  an unobserved jump over several levels, intermediate XP requirements cannot
  be recovered from `UnitXPMax`; estimates remain N/A for that session rather
  than inventing XP. Normal consecutive level-ups keep the session running.
- Money uses grouped gold digits and distinct gold/silver/copper colors, updated
  on `PLAYER_MONEY`.
- Bags count occupied slots in the backpack and four normal equipped bags
  (indexes 0–4), including specialty bags in those slots. Reagent bags, keyrings,
  and all bank storage are excluded. Uses `BAG_UPDATE_DELAYED` and equipment events.
- Durability is total current / total maximum across equipped items with
  durability. Equipment, durability, and merchant-close events refresh it;
  characters with no durable equipment show N/A.
- `Moved today: 1,234 yd` is horizontal distance traveled today, sampled four
  times a second using `UnitPosition`, with start/stop movement events as well.
  Walking, running, swimming, and ordinary mounted travel count. This measures
  distance, not animation footsteps. Taxi and vehicle rides do not count.
  Loading screens, coordinate-space changes, long sampling gaps, and implausible
  jumps are excluded. Curved paths between samples can slightly undercount.
  Where world positions are unavailable (including some instances), actual
  movement speed provides an estimate instead. Tiny teleports cannot always be
  distinguished from ordinary movement. Today's distance survives logins and
  UI reloads. Days follow the computer's local calendar, rolling over at midnight
  even while standing still; a segment crossing midnight belongs to its sample's
  date. Each character has separate daily history and an all-time total.

The far right shows a local-time clock (`Local 6:46 PM`), refreshed every ten
seconds. A separate right-aligned text region reserves space for it even when the
left-side information grows. Providers can opt into that region with `side = "right"`.

## Pedometer persistence

`ToplineCharDB` is declared with `SavedVariablesPerCharacter`. WoW stores it in
that character's `WTF/Account/<account>/<realm>/<character>/SavedVariables/Topline.lua`.
The addon updates the in-memory table for each accepted movement sample; WoW
writes it on normal logout, exit, or UI reload. A client crash can lose progress
since the last save. Prior versions did not save travel and cannot be backfilled.

Schema version 1 keeps `pedometer.days["YYYY-MM-DD"] = yards` and
`pedometer.totalYards`. Fractions are preserved in storage and only the display is
rounded down. Daily history is retained without pruning; idle days need no entry.
The bar shows today only. Historical records and the all-time total are ready for
a later history view, with no additional screen or command in this version.

Text can shrink from 12 to 10 UI units to fit smaller windows. Extremely narrow
windows or long zone names can still truncate the line; it never wraps.

## Client evidence

Inspected locally on 2026-09-23:

- `_classic_beta_/WowB.exe` reports **1.60.1.69977**; the installation `.build.info`
  identifies that build as `wow_classic_beta`.
- Installed `Leatrix_Plus/Leatrix_Plus.toc` and
  `DBM-Party-Forever/DBM-Party-Forever.toc` specify **Interface 16001**.
- `Leatrix_Maps/Leatrix_Maps.lua` uses `C_Map.GetBestMapForUnit`,
  `C_Map.GetPlayerMapPosition`, and the returned position's `x`/`y` fields.
- `Syndicator/Core/Constants.lua` explicitly identifies Forever and lists
  `Enum.BagIndex` inventory bags; `Syndicator/Tracking/BagCache.lua` uses
  `C_Container.GetContainerNumSlots`. NovaInstanceTracker uses the namespaced
  free-slot function, `UnitXP`, `UnitXPMax`, and `GetMaxPlayerLevel`.
- The installed executable contains the names of the C-backed APIs, frame/font
  methods, timer methods, and update events used here. This is static evidence,
  not a claim that the addon has been exercised in a running WoW client.
- The Anniversary reference's `Titan/TitanConfig.lua:566` states that automatic
  frame adjustment was removed in July 2026 after Classic received Edit Mode.
  Topline's small layout helper is independent of Titan. The Forever UI source
  confirms the [buff/debuff frames](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_BuffFrame/BuffFrame.xml)
  and [Edit Mode exit callback](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_EditMode/Shared/EditModeManager.lua).
  Installed Leatrix Plus uses `UnitPosition`; the executable also contains
  `GetUnitSpeed`, movement events, and combat-lockdown APIs used here.

## Extending

`Storage.lua` owns character history and daily date handling. It initializes on
first use at login, after WoW has loaded SavedVariables.
`Core.lua` owns registration, event dispatch, provider error isolation, and
coalesced redraws. `Bar.lua` owns presentation; `Layout.lua` manages top-edge
clearance. Each file in `Modules/` registers
one provider through the private addon namespace supplied by WoW:

```lua
local _, Topline = ...
Topline:RegisterModule("Example", {
    order = 70,
    events = { "SOME_EVENT" },
    -- interval = 5, -- optional, only when events are insufficient
    update = function(self, event, ...)
        return "Example: value" -- nil leaves the previous text intact
    end,
})
```

Add its file after the core and bar in `Topline.toc`. Providers receive
`INITIALIZE`, `PLAYER_ENTERING_WORLD`, their declared events, and `TICK` if they
declare an interval. Failures affect only that provider and print one diagnostic
per provider per session. No addon-wide per-frame `OnUpdate` is used.

## Validation

Run `lua tests/run.lua` from this folder with Lua 5.1. The standalone harness
loads the real TOC in order and mocks WoW frames, events, timers, and data. It
checks XP rollover/event ordering, session continuity, missing APIs, error
isolation/recovery, bag scope, weighted durability, formatting, and scale updates.
It also tests movement totals, transport/teleport rejection, speed fallback, and
layout drift, relative anchors, re-anchoring, combat, and Edit Mode handling.
Persistence checks cover same-day reloads, separate characters, live midnight
rollover, retained history, fractional yards, and malformed saved data.
Tests are not listed in the TOC and never load in game.

The implementation passed Lua 5.1 parsing and the offline harness. In-game
rendering and event timing still need confirmation: enable Topline, move between
subzones, earn XP/level up, change money/bags, repair equipment, and change UI
scale. This work did not launch or control WoW.
