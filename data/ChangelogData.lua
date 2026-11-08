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
			"Fixed: Characters with an unknown class now appear in white in the character menu",
			"Fixed: The Character and Account tabs now return to the current month after a character is deleted",
			"Minor code adjustments"
		}
	},
	{
		version = "v2.45",
		date = "2026-11-06",
		entries = {
			"Changed: The Basic debug level now shows important messages, while Advanced also includes technical details",
			"Updated: deDE, enUS, ruRU localizations"
		}
	},
	{
		version = "v2.44",
		date = "2026-11-05",
		entries = {
			"Changed: Debug messages are now converted and formatted only when debug mode is enabled",
			"Requires Arcane Wizard: Library revision 4 or later"
		}
	},
	{
		version = "v2.43",
		date = "2026-11-03",
		entries = {
			"Changed: The debug mode option now combines an enable checkbox with a Basic or Advanced level selector",
			"Updated: deDE, enUS, ruRU localizations",
			"Minor code adjustments"
		}
	},
	{
		version = "v2.42",
		date = "2026-11-01",
		entries = {
			"Changed: The TOC no longer restricts loading by game type",
			"Requires Arcane Wizard: Library revision 3 or later",
			"Minor code adjustments"
		}
	},
	{
		version = "v2.41",
		date = "2026-11-01",
		entries = {
			"Added: Currency 'Bound Silver' [retail]",
			"Changed: Clarified labels in the options menu",
			"Changed: Limited loading to Retail, Forever, Classic, and Talebound",
			"Updated: deDE, enUS, ruRU localizations",
			"Minor code adjustments"
		}
	},
	{
		version = "v2.40",
		date = "2026-10-29",
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
	}
	-- END GENERATED CHANGELOG
}
