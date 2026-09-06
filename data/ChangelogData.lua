local addonName, AUR = ...

local version = C_AddOns.GetAddOnMetadata(addonName, "Version") or ""
local buildDate = C_AddOns.GetAddOnMetadata(addonName, "X-BuildDate") or ""

AUR.CHANGELOG = {
	{
		version = version,
		date = buildDate ~= "" and buildDate or nil,
		entries = {
			"Added: TOC version for patch 12.1.5 [retail]"
		}
	},
	{
		version = "v2.25",
		date = "2026-08-30",
		entries = {
			"Minor code adjustments"
		}
	},
	{
		version = "v2.24",
		date = "2026-08-21",
		entries = {
			"Added: Gold Display - A small movable display with a gold border shows the current gold and today's change with selectable coin detail, adaptive width, and a clickable translucent Aurarium logo"
		}
	},
	{
		version = "v2.23",
		date = "2026-08-18",
		entries = {
			"Added: Changelog window available from the options menu",
			"Added: Changelog window available through the 'changelog' slash command",
			"Removed: Version notice chat messages",
			"Adapted to the latest version of Arcane Wizard: Library to ensure full compatibility"
		}
	},
	{
		version = "v2.22",
		date = "2026-08-14",
		entries = {
			"Added: Currencies for the patch 'Midnight - The Curse of Ula’tek' [retail]",
			"Removed: TOC version for patch 12.0.7 [retail]"
		}
	},
	{
		version = "v2.21",
		date = "2026-08-04",
		entries = {
			"Minor code adjustments"
		}
	},
	{
		version = "v2.20",
		date = "2026-07-28",
		entries = {
			"Added: TOC version for patch 1.15.9 [classic]",
			"Removed: TOC version for patch 1.15.8 [classic]",
			"Adapted to the latest version of Arcane Wizard: Library to ensure full compatibility"
		}
	},
	{
		version = "v2.19",
		date = "2026-07-18",
		entries = {
			"Minor code adjustments"
		}
	},
	{
		version = "v2.18",
		date = "2026-07-12",
		entries = {
			"Added: Wago project page buttona",
			"Removed: TOC version for patch 5.5.3 [mists of pandaria - classic]",
			"Removed: TOC version for patch 2.5.5 [burning crusade - classic anniversary edition]"
		}
	},
	{
		version = "v2.17",
		date = "2026-07-09",
		entries = {
			"Minor code adjustments"
		}
	}
}
