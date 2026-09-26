# Topline

A standalone status strip for World of Warcraft: Forever. No dependencies,
configuration screens, slash commands, or bundled libraries. A right-click menu
controls which items are visible. Pedometer history
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
  It inherits UI scale. The bar and its transparent hover regions accept right-clicks for context menus.
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
  on `PLAYER_MONEY`. Its tooltip shows money gained, spent, and signed net change
  since the first readable balance this login/UI session. Starting wealth is not
  counted as income; zoning and duplicate events do not reset or double-count.
  These are observed balance increases/decreases, including trades/mail/transfers,
  not categorized transactions. Multiple transactions between readable updates
  may combine. Missing/restricted samples retain the last readable balance;
  the next valid balance contributes only its net difference. Login or `/reload`
  starts fresh counters; these session statistics are not saved. Right-click the
  money item and choose **Reset session** to clear gained/spent/net counters and
  use the current readable balance as a new baseline. XP and travel are unaffected.
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
  jumps are excluded. Restricted (secret) movement values pause sampling while
  preserving recorded totals; the next readable sample starts a fresh baseline.
  Travel during that gap cannot be counted. Curved paths between samples can slightly undercount.
  Where world positions are unavailable (including some instances), actual
  movement speed provides an estimate instead. Tiny teleports cannot always be
  distinguished from ordinary movement. Today's distance survives logins and
  UI reloads. Days follow the computer's local calendar, rolling over at midnight
  even while standing still; a segment crossing midnight belongs to its sample's
  date. Each character has separate daily history and an all-time total.

The right side shows FPS and latency before the local-time clock. Performance
refreshes every two seconds using `GetFramerate` and `GetNetStats`; the bar uses
the higher available home/world latency. Hover shows both latency values and FPS.
Normal values are muted gray; FPS below 60 is amber and below 30 is red. Latency
at 150 ms is amber and at 300 ms is red. Missing, invalid, or restricted values
show N/A independently, so one unavailable metric does not hide the other.

The far right shows a local-time clock (`Local 6:46 PM`), refreshed every ten
seconds. A separate right-aligned text region reserves space for it even when the
left-side information grows. Providers can opt into that region with `side = "right"`.

The mail item appears between performance and the clock only when the client
reports new mail, using a small letter icon and `Mail` label. Its tooltip lists
up to three recent senders when available. It follows `HasNewMail` and
`UPDATE_PENDING_MAIL`, with inbox/close events also refreshing the state; it does
not poll, scan mail contents, claim an unread count, or open the mailbox remotely.
Missing/restricted mail status hides the item. Empty providers consume no width,
separator, or hover area. Clearing mail follows the client's notification timing.

## Item visibility

Right-click any item or empty space on the strip, then open **Show/hide items**.
Checkboxes control each provider (FPS/latency share one item). **Restore defaults**
at the bottom of this submenu enables all items and clears saved visibility
overrides for this character, without resetting XP, money, or travel data. XP and money retain
their **Reset session** actions in the same menu. The strip remains available even
when everything is hidden, so right-click it to restore items. Enabling Mail still
shows it only when mail is waiting. Hidden items leave no separators or hover areas.

Hiding is a display preference: providers continue tracking in the background,
including XP, money, and movement, so showing them does not lose session history.
Choices default to all enabled and are saved per character in `ToplineSettingsDB`.
They rely on WoW loading SavedVariables; the Forever travel CVar workaround does
not back up these preferences. The beta's disk-loading bug can therefore reset
visibility choices if it drops SavedVariables.

## Item order

Right-click the strip, open **Reorder items**, select an item, and choose
**Move left** or **Move right**. Reopen the menu for additional moves. Use **Move to left group** or **Move to right group** in the same item submenu
to transfer it to the end of that group. FPS and latency remain one item. Hidden
items and conditional mail are included in the ordering list.

**Restore default order** resets positions and original left/right groups only. The visibility menu's
**Restore defaults** still resets visibility only. Neither resets tracking.
Order and group overrides are stored per character in `ToplineSettingsDB.itemOrder`
and `ToplineSettingsDB.itemSides` and share the
SavedVariables limitation described above. Newly added providers not in a saved
order follow the arranged items in their group's default order.

## Hover details

Hover any item for a native WoW tooltip below the strip. Right-click XP/hr and
choose **Reset session** to restart XP tracking from the current level/XP. This
clears its earned XP, elapsed time, and last-kill/gain estimates; rates warm up
again for 60 seconds and require new XP. Travel history is unaffected. The XP popup shows
session duration, session XP, current level progress, remaining and rested XP,
last kill XP, last observed XP gain, kills/gains to level, XP/hour, and time to
level. Kill estimates use localized named-kill chat formats; unidentified messages
leave the estimate unknown. XP totals still come exclusively from player XP
changes. Simultaneous awards can combine into one observed gain. No automatic
`/played` request is made, so lifetime played and full-level rates are not claimed.

Other tooltips show location, carried money, occupied/free slots per bag,
individual equipped-item durability, character travel history, and local/realm
time. Only the open tooltip refreshes once per second; leaving cancels its timer.
Invisible hover regions follow measured text and shrink/clipping behavior.

## Pedometer persistence

`ToplineCharDB` is declared with `SavedVariablesPerCharacter`. WoW stores it in
that character's `WTF/Account/<account>/<realm>/<character>/SavedVariables/Topline.lua`.
The addon updates the in-memory table for each accepted movement sample; WoW
writes it on normal logout, exit, or UI reload. A client crash can lose progress
since the last save. Prior versions did not save travel and cannot be backfilled.

### Forever beta reload workaround (0.3.4)

The 1.60.1 beta can write valid SavedVariables but fail to read them on the next
load. This can begin after a client restart even if reloads previously worked.
See the [client bug report and CVar reproduction](https://eu.forums.blizzard.com/en/blizzard/t/classic-forever-beta-savedvariables-are-written-on-logoutreload-but-not-loaded-back-%E2%80%93-every-addon-loses-its-settings/17983).
The persistence code was unchanged between Topline's initial commit and 0.3.3.

On Forever builds, Topline now mirrors its travel history in a private temporary
console variable keyed by character GUID. Writes are throttled to once per five
seconds of movement, with an unconditional final checkpoint at `PLAYER_LOGOUT`
(also fired by `/reload`). On login, daily/lifetime maxima merge the checkpoint
with SavedVariables without double counting or rolling back newer disk data.
No other addon or existing game-setting CVar is modified. The compact data is
parsed as numbers and dates; it is never executed as Lua.

This cache survives reloads/relogs **within one game launch only**. It cannot fix
the beta's cold-start disk-loading bug or recover earlier overwritten history.
The first reload after installing this version activates the cache; the old
running version cannot checkpoint retroactively. A full client restart still
depends on WoW restoring SavedVariables. Missing CVar APIs fall back to normal
storage; a rejected/truncated checkpoint prints one diagnostic. Extremely large
histories above 128 KiB also fall back to normal storage rather than being clipped.

Schema version 1 keeps `pedometer.days["YYYY-MM-DD"] = yards` and
`pedometer.totalYards`. Fractions are preserved in storage and only the display is
rounded down. Daily history is retained without pruning; idle days need no entry.
The bar shows today; its hover tooltip includes the session total, recorded lifetime
total, and up to seven previous travel days. No additional screen or command is needed.

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
`ReloadCache.lua` provides the Forever-only native reload checkpoint.
`Core.lua` owns registration, event dispatch, provider error isolation, and
coalesced redraws. `Bar.lua` owns presentation; `Tooltips.lua` owns hover regions and the shared tooltip; `Layout.lua` manages top-edge
clearance. Each file in `Modules/` registers
one provider through the private addon namespace supplied by WoW:

```lua
local _, Topline = ...
Topline:RegisterModule("Example", {
    order = 70,
    events = { "SOME_EVENT" },
    tooltip = function(self, tip) -- optional
        tip:AddLine("Example details")
        Topline:TooltipRow(tip, "Value", "More information")
    end,
    -- Return "" from update to hide this item and its separator.
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
They also simulate the beta dropping SavedVariables while native CVars survive,
including final logout flushes, stale/malformed checkpoints, and cold-start limits.
Hover checks cover lifecycle, live refresh, localized kill parsing, estimates,
clipping, and provider error isolation. Tests are not listed in the TOC and never load in game.

The implementation passed Lua 5.1 parsing and the offline harness. In-game
rendering and event timing still need confirmation: enable Topline, move between
subzones, earn XP/level up, change money/bags, repair equipment, and change UI
scale. This work did not launch or control WoW.
