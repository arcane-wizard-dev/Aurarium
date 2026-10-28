local _, AUR = ...

if AUR.State and AUR.State.libraryIncompatible then return end

AUR.Localization = setmetatable({}, {
	__index=function(self, key)
		rawset(self, key, key)

		geterrorhandler()("Aurarium (Debug): Missing entry for '" .. tostring(key) .. "'")

		return key
	end
})

local L = AUR.Localization

-- Options

L["options.general"] = "General Options"
L["options.general.date-format.name"] = "Date Format"
L["options.general.date-format.tooltip"] = "Sets the date format for all tables, charts, tooltips, and date fields."
L["options.general.minimap-button.name"] = "Minimap Button"
L["options.general.minimap-button.tooltip"] = "Shows the minimap button."
L["options.general.debug-mode.name"] = "Debug Mode"
L["options.general.debug-mode.tooltip"] = "Displays additional debug information in the chat."

L["options.currency-overview"] = "Gold and Currency Overview"
L["options.currency-overview.open-on-login.name"] = "Open Automatically"
L["options.currency-overview.open-on-login.tooltip"] = "Opens the Gold and Currency Overview automatically when a character logs in."

L["options.gold-display"] = "Gold Display"
L["options.gold-display.show.name"] = "Show Gold Display"
L["options.gold-display.show.tooltip"] = "Shows a small movable display with the current gold and today's change."
L["options.gold-display.show-border.name"] = "Show Border"
L["options.gold-display.show-border.tooltip"] = "Shows a border around the Gold Display."
L["options.gold-display.display-mode.name"] = "Displayed Coins"
L["options.gold-display.display-mode.tooltip"] = "Sets which coin values are shown in the Gold Display."

-- General

L["minimap-button.tooltip"] = "|cnLINK_FONT_COLOR:Left-click|r to open the Gold and Currency Overview.\n|cnLINK_FONT_COLOR:Right-click|r to open the options."

L["button.next"] = "Next"
L["button.prev"] = "Previous"

L["date-format.ymd"] = "YYYY-MM-DD"
L["date-format.mdy"] = "MM/DD/YYYY"
L["date-format.dmy"] = "DD.MM.YYYY"

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

L["chat.delete-character.deleted"] = "Character \"%s\" from realm \"%s\" has been deleted."
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

L["currency-overview.tab.character"] = "Character"
L["currency-overview.tab.account"] = "Account"
L["currency-overview.tab.warband"] = "Warband"

L["currency-overview.table.date"] = "Date"
L["currency-overview.table.amount"] = "Amount"
L["currency-overview.table.difference"] = "Difference"
L["currency-overview.table.no-entries"] = "No entries for this month."

L["currency-overview.menu.more"] = "More"
L["currency-overview.menu.hide-unchanged-entries"] = "Hide Unchanged Entries"
L["currency-overview.menu.delete-character"] = "Delete data for \"%s\"…"
L["currency-overview.menu.patch"] = "Patch %s"

L["currency-overview.delete-character.confirm"] = "Delete character \"%s\" from realm \"%s\" and all recorded data?"

-- Chart

L["chart.title"] = "Chart"
L["chart.scope"] = "View"
L["chart.currency"] = "Currency"

L["chart.period"] = "Period"
L["chart.period.7days"] = "Last 7 Days"
L["chart.period.30days"] = "Last 30 Days"
L["chart.period.90days"] = "Last 90 Days"
L["chart.period.month"] = "This Month"
L["chart.period.last-month"] = "Last Month"
L["chart.period.year"] = "This Year"
L["chart.period.all"] = "All Time"
L["chart.period.custom"] = "Custom Range"

L["chart.from"] = "From"
L["chart.to"] = "To"
L["chart.apply"] = "Apply"

L["chart.decimal-separator"] = "."
L["chart.unit.thousand"] = "k"
L["chart.unit.million"] = "M"

L["chart.error.date"] = "Enter a valid date (%s)."
L["chart.error.range"] = "The start cannot be after the end, and dates cannot be in the future."

L["chart.no-data"] = "No balance history is available yet for this currency in the selected period."
L["chart.no-currencies"] = "No currencies available."

L["chart.summary.start"] = "Start"
L["chart.summary.end"] = "End"
L["chart.summary.change"] = "Change"

L["chart.history-note"] = "The chart shows the last recorded balance for each day. Days without a new value show the previous balance. The chart starts with the first recorded value."

-- WoW Token

L["wow-token.title"] = "WoW Token"
L["wow-token.region"] = "Region"
L["wow-token.price"] = "Gold Price"
L["wow-token.no-data"] = "No WoW Token prices have been recorded for the selected period."
L["wow-token.history-note"] = "The chart shows the last WoW Token gold price recorded each day for the current game region. Prices are collected while a character is logged in. Days without a new price show the last recorded price. Recording starts with the first successful query."
