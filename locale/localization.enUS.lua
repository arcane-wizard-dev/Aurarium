local _, AUR = ...

AUR.Localization = setmetatable({},{__index=function(self,key)
	geterrorhandler()("Aurarium (Debug): Missing entry for '" .. tostring(key) .. "'")
	return key
end})

local L = AUR.Localization

-- Options

L["options.general"] = "General Options"
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
L["currency-overview.menu.delete-character"] = "Delete Character"
L["currency-overview.menu.patch"] = "Patch %s"
L["currency-overview.delete-character.confirm"] = "Delete character '%s' from realm '%s' and all recorded data?"
