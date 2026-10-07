local _, AUR = ...

AUR.Localization = setmetatable({},{
	__index=function(self,key)
		geterrorhandler()("Aurarium (Debug): Missing entry for '" .. tostring(key) .. "'")

		return key
	end
})

local L = AUR.Localization

L["currency-overview.menu.more"] = "More"

L["chart.title"] = "Chart"
L["chart.beta"] = "Beta Version"
L["chart.beta-badge"] = "BETA"
L["chart.scope"] = "View"
L["chart.currency"] = "Currency"
L["chart.period"] = "Period"
L["chart.period.7days"] = "Last 7 Days"
L["chart.period.30days"] = "Last 30 Days"
L["chart.period.90days"] = "Last 90 Days"
L["chart.period.month"] = "This Month"
L["chart.period.last-month"] = "Last Month"
L["chart.period.year"] = "This Year"
L["chart.period.all"] = "All History"
L["chart.period.custom"] = "Custom Range"
L["chart.from"] = "From"
L["chart.to"] = "To"
L["chart.apply"] = "Apply"
L["date-format.ymd"] = "YYYY-MM-DD"
L["date-format.mdy"] = "MM/DD/YYYY"
L["date-format.dmy"] = "DD.MM.YYYY"
L["chart.decimal-separator"] = "."
L["chart.unit.thousand"] = "k"
L["chart.unit.million"] = "M"
L["chart.error.date"] = "Enter a valid date (%s)."
L["chart.error.range"] = "The start must precede the end; dates cannot be in the future."
L["chart.no-data"] = "No balance history is available yet for this currency in the selected period."
L["chart.no-currencies"] = "No currencies available."
L["chart.summary.start"] = "Start"
L["chart.summary.end"] = "End"
L["chart.summary.change"] = "Change"
L["chart.history-note"] = "The chart shows the last recorded balance for each day. Days without a new value show the previous balance. The chart starts with the first recorded value."

-- Options

L["options.general"] = "General Options"
L["options.general.date-format.name"] = "Date Format"
L["options.general.date-format.tooltip"] = "Choose the date format for all tables, charts, tooltips, and date fields."
L["options.general.minimap-button.name"] = "Minimap Button"
L["options.general.minimap-button.tooltip"] = "When this is enabled, the minimap button is displayed."
L["options.general.debug-mode.name"] = "Debug Mode"
L["options.general.debug-mode.tooltip"] = "Enabling the debug mode displays additional information in the chat."

L["options.currency-overview"] = "Gold and Currency Overview"
L["options.currency-overview.open-on-login.name"] = "Open Automatically"
L["options.currency-overview.open-on-login.tooltip"] = "When this is enabled, the gold and currency overview opens automatically when logging in."
L["options.currency-overview.hide-unchanged-entries.name"] = "Hide Unchanged Entries"
L["options.currency-overview.hide-unchanged-entries.tooltip"] = "When this is enabled, days without a balance change are hidden in the character, account, and warband overviews."

L["options.gold-display"] = "Gold Display"
L["options.gold-display.show.name"] = "Show Gold Display"
L["options.gold-display.show.tooltip"] = "When this is enabled, a small movable display shows the current gold and today's change."
L["options.gold-display.show-border.name"] = "Show Border"
L["options.gold-display.show-border.tooltip"] = "Shows a border around the Gold Display."
L["options.gold-display.display-mode.name"] = "Displayed Coins"
L["options.gold-display.display-mode.tooltip"] = "Determines which coin values are shown in the gold display."

-- General

L["minimap-button.tooltip"] = "|cnLINK_FONT_COLOR:Left-click|r to open the gold and currency overview.\n|cnLINK_FONT_COLOR:Right-click|r to open the options."

L["button.next"] = "Next"
L["button.prev"] = "Previous"

L["month.jan"] = "January"
L["month.feb"] = "February"
L["month.mar"] = "March"
L["month.apr"] = "April"
L["month.may"] = "May"
L["month.jun"] = "June"
L["month.jul"] = "July"
L["month.aug"] = "August"
L["month.sep"] = "September"
L["month.oct"] = "October"
L["month.nov"] = "November"
L["month.dec"] = "December"

-- Chat

L["chat.delete-character.deleted"] = "Character '%s' from realm '%s' has been deleted."
L["chat.delete-character.current-not-allowed"] = "The currently logged-in character cannot be deleted."

-- Currency Overview

L["currency-overview.category.gold"] = "Gold"
L["currency-overview.category.warband"] = "Warband Currencies"
L["currency-overview.category.character"] = "Character Currencies"
L["currency-overview.category.misc"] = "Miscellaneous"
L["currency-overview.category.pvp"] = "Player vs. Player"
L["currency-overview.category.dungeonraid"] = "Dungeon and Raid"
L["currency-overview.category.delves"] = "Delves"
L["currency-overview.category.season"] = "Season"
L["currency-overview.category.timerunning"] = "Timerunning"
L["currency-overview.category.profession"] = "Profession"
L["currency-overview.category.tradeskills"] = "Professions & Tradeskills"
L["currency-overview.category.classic"] = "Classic"
L["currency-overview.category.tbc"] = "Burning Crusade"
L["currency-overview.category.wotlk"] = "Wrath of the Lich King"
L["currency-overview.category.cata"] = "Cataclysm"
L["currency-overview.category.mop"] = "Mists of Pandaria"
L["currency-overview.category.wod"] = "Warlords of Draenor"
L["currency-overview.category.legion"] = "Legion"
L["currency-overview.category.bfa"] = "Battle for Azeroth"
L["currency-overview.category.sl"] = "Shadowlands"
L["currency-overview.category.df"] = "Dragonflight"
L["currency-overview.category.tww"] = "The War Within"
L["currency-overview.category.mid"] = "Midnight"

L["currency-overview.tab.character"] = "Character"
L["currency-overview.tab.account"] = "Account"
L["currency-overview.tab.warband"] = "Warband"

L["currency-overview.table.date"] = "Date"
L["currency-overview.table.amount"] = "Amount"
L["currency-overview.table.difference"] = "Difference"
L["currency-overview.table.no-entries"] = "No entries for this month."
L["currency-overview.menu.delete-character"] = "Delete data for '%s'…"
L["currency-overview.menu.patch"] = "Patch %s"
L["currency-overview.delete-character.confirm"] = "Delete character '%s' from realm '%s' and all recorded data?"
