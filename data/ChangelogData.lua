local addonName, AUR = ...

local version = C_AddOns.GetAddOnMetadata(addonName, "Version") or ""
local buildDate = C_AddOns.GetAddOnMetadata(addonName, "X-BuildDate") or ""

AUR.CHANGELOG = {
	{
		version = version,
		date = buildDate ~= "" and buildDate or nil,
		entries = {
			"Added: Currency 'Arena Points' [burning crusade - classic anniversary edition]",
			"Added: Currency 'Honor Points' [burning crusade - classic anniversary edition] [mists of pandaria - classic]",
			"Added: Currency 'Conquest Points' [mists of pandaria - classic]",
			"Added: Currency 'Justice Points' [mists of pandaria - classic]",
			"Added: Currency 'Valor Points' [mists of pandaria - classic]",
			"Added: Currency 'Epicurean's Award' [retail]",
			"Added: Currency 'Ironpaw Token' [retail]",
			"Added: Currency 'Bronze Celebration Token' [retail]",
			"Added: Currency 'Spirit Shard' [retail]",
			"Added: Currency 'Restored Coffer Key' [retail]",
			"Added: Currency 'Untainted Mana-Crystals' [retail]",
			"Added: Currencies for the expansion 'Forever' [forever]",
			"Added: New badge after the names of currencies introduced in the current WoW patch",
			"Added: Currency balances and holding limits in dropdown menus",
			"Changed: Separate currency lists per game version; only the active list is checked at startup",
			"Changed: Display initial zero balances",
			"Changed: Group currencies from Legion onward by introduction patch in lists and dropdown menus [retail]",
			"Changed: Move delve currencies from Season to Delves [retail]",
			"Changed: Move Brawler's Gold from Battle for Azeroth to Legion [retail]",
			"Changed: Match currency categories to game data [mists of pandaria - classic]",
			"Updated: Compatibility with the beta client [forever]",
			"Updated: deDE localizations",
			"Removed: Currency 'Bronze' [retail]",
			"Removed: Currency 'Infinite Power' [retail]",
			"Removed: Currency 'Infinite Knowledge' [retail]",
			"Removed: Currency 'Luminous Dust' [retail]",
			"Adapted to the latest version of Arcane Wizard: Library to ensure full compatibility"
		}
	},
	{
		version = "v2.29",
		date = "2026-09-22",
		entries = {
			"Adapted to the latest version of Arcane Wizard: Library to ensure full compatibility",
			"Minor code adjustments"
		}
	},
	{
		version = "v2.28",
		date = "2026-09-18",
		entries = {
			"Added: Support for 'Forever'",
			"Changed: Character profiles and data are initialized centrally using GUIDs; existing gold and currency histories are migrated at login",
			"Changed: Addon initialization stops if the player identity is unavailable"
		}
	},
	{
		version = "v2.27",
		date = "2026-09-13",
		entries = {
			"Updated: GitHub links following the organization rename to 'arcane-wizard-dev'"
		}
	},
	{
		version = "v2.26",
		date = "2026-09-06",
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
	}
}
