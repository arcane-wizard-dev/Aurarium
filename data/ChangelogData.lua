local addonName, AUR = ...

if AUR.State and AUR.State.libraryIncompatible then return end

local version = C_AddOns.GetAddOnMetadata(addonName, "Version") or ""
local buildDate = C_AddOns.GetAddOnMetadata(addonName, "X-BuildDate") or ""

AUR.CHANGELOG = {
	notices = {
		"Migration of older character data will be removed at the end of 2026. Log in once with each character using an up-to-date version of Aurarium before then to preserve their gold and currency history."
	},
	-- BEGIN GENERATED CHANGELOG
	{
		version = version,
		date = buildDate ~= "" and buildDate or nil,
		entries = {
			"Added: TOC version for patch 12.1.7 [retail]",
			"Removed: TOC version for patch 12.1.0 [retail]"
		}
	},
	{
		version = "v2.39",
		date = "2026-10-28",
		entries = {
			"Added: Startup check for the minimum required Library revision",
			"Updated: deDE, enUS, ruRU localizations",
			"Updated: Addon description",
			"Adapted to the latest version of Arcane Wizard: Library to ensure full compatibility",
			"Minor code adjustments"
		}
	},
	{
		version = "v2.38",
		date = "2026-10-21",
		entries = {
			"Added: Table menu in the overview to hide unchanged entries",
			"Changed: Improved chart rendering and tooltips",
			"Adapted to the latest version of Arcane Wizard: Library to ensure full compatibility"
		}
	},
	{
		version = "v2.37",
		date = "2026-10-16",
		entries = {
			"Added: Daily WoW Token price history in the overview and chart [retail]",
			"Adapted to the latest version of Arcane Wizard: Library to ensure full compatibility",
			"Minor code adjustments"
		}
	},
	{
		version = "v2.36",
		date = "2026-10-14",
		entries = {
			"Fixed: Repeated error messages for missing translations"
		}
	},
	{
		version = "v2.35",
		date = "2026-10-12",
		entries = {
			"Refactoring of the addon structure and source code"
		}
	},
	{
		version = "v2.34",
		date = "2026-10-09",
		entries = {
			"Added: Chart - Visualize gold and currency balances over selectable date ranges",
			"Added: Configurable date format",
			"Minor code adjustments"
		}
	},
	{
		version = "v2.33",
		date = "2026-10-05",
		entries = {
			"Changed: Overview and Gold Display now use the native Blizzard UI appearance, with an optional border for the Gold Display",
			"Changed: Character data can now be deleted from the character selection menu",
			"Adapted to the latest version of Arcane Wizard: Library to ensure full compatibility"
		}
	},
	{
		version = "v2.32",
		date = "2026-10-03",
		entries = {
			"Updated: Logo"
		}
	},
	{
		version = "v2.31",
		date = "2026-09-27",
		entries = {
			"Added: Explicit New badge control per currency",
			"Changed: Mark currencies added in v2.30 as New",
			"Fixed: Show today's balance immediately after login or reload",
			"Minor code adjustments"
		}
	}
	-- END GENERATED CHANGELOG
}
