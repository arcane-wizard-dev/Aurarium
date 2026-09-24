local _, AUR = ...

if GetLocale() ~= "deDE" then return end

local L = AUR.Localization

-- Options

L["options.general"] = "Allgemeine Einstellungen"
L["options.general.minimap-button.name"] = "Minimap-Button"
L["options.general.minimap-button.tooltip"] = "Bei Aktivierung wird der Minimap-Button angezeigt."
L["options.general.debug-mode.name"] = "Debugmodus"
L["options.general.debug-mode.tooltip"] = "Die Aktivierung des Debugmodus zeigt zusätzliche Informationen im Chat an."

L["options.currency-overview"] = "Gold- und Währungsübersicht"
L["options.currency-overview.open-on-login.name"] = "Automatisch öffnen"
L["options.currency-overview.open-on-login.tooltip"] = "Bei Aktivierung öffnet sich die Gold- und Währungsübersicht beim Login automatisch."
L["options.currency-overview.hide-unchanged-entries.name"] = "Unveränderte Einträge ausblenden"
L["options.currency-overview.hide-unchanged-entries.tooltip"] = "Bei Aktivierung werden Tage ohne Bestandsänderung in der Charakter-, Account- und Kriegsmeute-Übersicht ausgeblendet."

L["options.gold-display"] = "Goldanzeige"
L["options.gold-display.show.name"] = "Goldanzeige anzeigen"
L["options.gold-display.show.tooltip"] = "Bei Aktivierung zeigt eine kleine verschiebbare Anzeige den aktuellen Goldstand und die heutige Veränderung."
L["options.gold-display.display-mode.name"] = "Angezeigte Münzen"
L["options.gold-display.display-mode.tooltip"] = "Legt fest, welche Münzwerte in der Goldanzeige angezeigt werden."

-- General

L["minimap-button.tooltip"] = "|cnLINK_FONT_COLOR:Linksklick|r zum Öffnen der Gold- und Währungsübersicht.\n|cnLINK_FONT_COLOR:Rechtsklick|r zum Öffnen der Einstellungen."

L["button.next"] = "Weiter"
L["button.prev"] = "Zurück"

L["month.jan"] = "Januar"
L["month.feb"] = "Februar"
L["month.mar"] = "März"
L["month.apr"] = "April"
L["month.may"] = "Mai"
L["month.jun"] = "Juni"
L["month.jul"] = "Juli"
L["month.aug"] = "August"
L["month.sep"] = "September"
L["month.oct"] = "Oktober"
L["month.nov"] = "November"
L["month.dec"] = "Dezember"

-- Chat

L["chat.delete-character.deleted"] = "Charakter '%s' auf Realm '%s' wurde gelöscht."
L["chat.delete-character.current-not-allowed"] = "Der aktuell eingeloggte Charakter kann nicht gelöscht werden."

-- Currency Overview

L["currency-overview.category.gold"] = "Gold"
L["currency-overview.category.warband"] = "Kriegsmeutewährungen"
L["currency-overview.category.character"] = "Charakterwährungen"
L["currency-overview.category.misc"] = "Verschiedenes"
L["currency-overview.category.pvp"] = "Spieler gegen Spieler"
L["currency-overview.category.dungeonraid"] = "Dungeon und Schlachtzug"
L["currency-overview.category.delves"] = "Tiefen"
L["currency-overview.category.season"] = "Saison"
L["currency-overview.category.timerunning"] = "Zeitläufer"
L["currency-overview.category.profession"] = "Berufe"
L["currency-overview.category.tradeskills"] = "Berufe und Berufsfertigkeiten"
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

L["currency-overview.tab.character"] = "Charakter"
L["currency-overview.tab.account"] = "Account"
L["currency-overview.tab.warband"] = "Kriegsmeute"

L["currency-overview.table.date"] = "Datum"
L["currency-overview.table.amount"] = "Betrag"
L["currency-overview.table.difference"] = "Differenz"
L["currency-overview.table.no-entries"] = "Keine Einträge für diesen Monat."
L["currency-overview.menu.delete-character"] = "Charakter löschen"
L["currency-overview.menu.patch"] = "Patch %s"
L["currency-overview.delete-character.confirm"] = "Charakter '%s' auf Realm '%s' und alle erfassten Daten löschen?"
