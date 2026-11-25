local addonName, AUR = ...

if AUR.State and AUR.State.libraryIncompatible then return end

local version = C_AddOns.GetAddOnMetadata(addonName, "Version") or ""
local buildDate = C_AddOns.GetAddOnMetadata(addonName, "X-BuildDate") or ""

AUR.CHANGELOG = {
	notices = {},
	-- BEGIN GENERATED CHANGELOG
	{
		version = version,
		date = buildDate ~= "" and buildDate or nil,
		entries = {
			"Added: In-game help answers common questions and explains each chat command. Open it from the addon settings or type the addon's slash command followed by 'help'",
			"Updated: deDE, enUS, ruRU localizations",
			"Requires Arcane Wizard: Library revision 8 or later"
		}
	},
	{
		version = "v2.50",
		date = "2026-11-20",
		entries = {
			"Changed: Each character appears under its ruleset after its next login [forever]",
			"Removed: Automatic import of gold and currency history from the old data format",
			"Fixed: A missing realm name no longer prevents startup when the character's ruleset is available [forever]",
			"Requires Arcane Wizard: Library revision 7 or later"
		}
	},
	{
		version = "v2.49",
		date = "2026-11-17",
		entries = {
			"Added: A help command lists available slash commands, and unknown commands show a hint in chat",
			"Added: Alliance and Horde balance views in the overview and chart",
			"Added: Optional markers for the highest and lowest chart values",
			"Changed: The Gold & Currencies tab uses one menu to select a character, a faction, or the total",
			"Changed: Character names now include first and last names [forever]",
			"Changed: The chart's Category dropdown is disabled when Gold & Currencies is the only option [forever]",
			"Requires Arcane Wizard: Library revision 6 or later"
		}
	},
	{
		version = "v2.48",
		date = "2026-11-14",
		entries = {
			"Changed: Reduced repeated calculations when tracking gold and currencies and updating the gold display",
			"Changed: Reduced repeated sorting, calculations, and layout queries in character lists, currency overviews, charts, and WoW Token price history, and reused table rows when refreshing the overview",
			"Minor code adjustments"
		}
	},
	{
		version = "v2.47",
		date = "2026-11-10",
		entries = {
			"Changed: Reworked the options menu to prevent errors in Blizzard's settings and added a button to restore default values",
			"Removed: Addon options from Blizzard's settings search",
			"Requires Arcane Wizard: Library revision 5 or later"
		}
	},
	{
		version = "v2.46",
		date = "2026-11-08",
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
	}
	-- END GENERATED CHANGELOG
}
