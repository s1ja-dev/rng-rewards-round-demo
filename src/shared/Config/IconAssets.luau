--!strict
-- Icon image ids for the spin/round UI. Uploaded via the Roblox Open Cloud
-- Assets API (2026-07-08) from Game-Icon-Pack-v1.4-PNG and
-- Vector_UI_Pack_dobo_ui. Every consumer only sets an Image if the id is
-- non-empty, so an empty string here would just fall back to the current
-- flat-color placeholder.
--
-- NOTE: uploading with assetType="Decal" returns a Decal *wrapper* asset id
-- — that id does NOT work directly as an ImageLabel.Image source. The ids
-- below are already the resolved wrapper.Texture ids (see
-- combat-system-demo/src/shared/Config/IconAssets.luau for the full
-- writeup, and roblox-open-cloud-api-key memory for the resolution steps).
local IconAssets = {
	-- Game-Icon-Pack-v1.4-PNG/no-padding/256px/white/1-game/six-sided-dice.png
	-- (wrapper 128178477614713) — a plain white icon, tinted per-rarity via
	-- ImageColor3 in code rather than uploaded once per color.
	Dice = "rbxassetid://111865272571896",

	-- Vector_UI_Pack_dobo_ui/Cards/card_*.png — pre-colored rarity card
	-- frames, industry-standard color convention (white/green/blue/purple/
	-- gold for Common/Uncommon/Rare/Epic/Legendary).
	CardCommon = "rbxassetid://139792432884834", -- card_white.png (wrapper 81118835511385)
	CardUncommon = "rbxassetid://77918091443062", -- card_green.png (wrapper 137334866209370)
	CardRare = "rbxassetid://74089391203615", -- card_blue.png (wrapper 139099642483025)
	CardEpic = "rbxassetid://130977821582448", -- card_purple.png (wrapper 110182398156820)
	CardLegendary = "rbxassetid://102423877952062", -- card_yellow.png (wrapper 131806178965890)

	-- Round phase icons.
	-- Game-Icon-Pack-v1.4-PNG/no-padding/256px/white/9-media/clock.png
	PhaseIntermission = "rbxassetid://109450582245702", -- wrapper 93272820766342
	-- .../6-buildings/flag.png — round is "running", flag raised.
	PhaseInRound = "rbxassetid://83939147723808", -- wrapper 76264683794967
	-- .../6-buildings/flag-02.png — a visually distinct flag for "round over".
	PhaseEnded = "rbxassetid://109264642593880", -- wrapper 117563651095392

	-- Vector_UI_Pack_dobo_ui/ProgressBars/ — countdown bar. Track is a fixed
	-- dark background; Fill is a plain white bar tinted per phase via
	-- ImageColor3 (same pattern as Dice) and shrunk left-to-right-anchored
	-- as time runs out.
	ProgressTrack = "rbxassetid://135021304199540", -- progressBarBase_black.png (wrapper 111636673614985)
	ProgressFill = "rbxassetid://91859402349679", -- progressBar_white.png (wrapper 75117330795159)
}

return IconAssets
