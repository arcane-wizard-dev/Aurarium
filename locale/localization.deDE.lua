local _, AUR = ...

if AUR.State and AUR.State.libraryIncompatible then return end

if GetLocale() ~= "deDE" then return end

local L = AUR.Localization

-- Options

L["options.general"] = "Allgemeine Einstellungen"
L["options.general.date-format.name"] = "Datumsformat"
L["options.general.date-format.tooltip"] = "Legt das Datumsformat für alle Tabellen, Diagramme, Tooltips und Datumsfelder fest."
L["options.general.minimap-button.name"] = "Minimap-Button"
L["options.general.minimap-button.tooltip"] = "Zeigt den Minimap-Button an."
L["options.general.debug-mode.name"] = "Debugmodus"
L["options.general.debug-mode.tooltip"] = "Zeigt zusätzliche Debuginformationen im Chat an."

L["options.currency-overview"] = "Gold- und Währungsübersicht"
L["options.currency-overview.open-on-login.name"] = "Automatisch öffnen"
L["options.currency-overview.open-on-login.tooltip"] = "Öffnet die Gold- und Währungsübersicht beim Einloggen automatisch."

L["options.gold-display"] = "Goldanzeige"
L["options.gold-display.show.name"] = "Goldanzeige einblenden"
L["options.gold-display.show.tooltip"] = "Zeigt eine kleine verschiebbare Anzeige mit dem aktuellen Goldstand und der heutigen Veränderung."
L["options.gold-display.show-border.name"] = "Rahmen anzeigen"
L["options.gold-display.show-border.tooltip"] = "Zeigt einen Rahmen um die Goldanzeige an."
L["options.gold-display.display-mode.name"] = "Angezeigte Münzen"
L["options.gold-display.display-mode.tooltip"] = "Legt fest, welche Münzwerte in der Goldanzeige angezeigt werden."

-- General

L["minimap-button.tooltip"] = "|cnLINK_FONT_COLOR:Linksklick|r zum Öffnen der Gold- und Währungsübersicht.\n|cnLINK_FONT_COLOR:Rechtsklick|r zum Öffnen der Einstellungen."

L["button.next"] = "Weiter"
L["button.prev"] = "Zurück"

L["date-format.ymd"] = "JJJJ-MM-TT"
L["date-format.mdy"] = "MM/TT/JJJJ"
L["date-format.dmy"] = "TT.MM.JJJJ"

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

L["chat.delete-character.deleted"] = "Charakter „%s“ auf Realm „%s“ wurde gelöscht."
L["chat.delete-character.current-not-allowed"] = "Der aktuell eingeloggte Charakter kann nicht gelöscht werden."

-- Currency Overview

L["currency-overview.category.gold"] = "Gold"
L["currency-overview.category.warband"] = "Kriegsmeutenwährungen"
L["currency-overview.category.character"] = "Charakterwährungen"
L["currency-overview.category.misc"] = "Verschiedenes"
L["currency-overview.category.pvp"] = "Spieler gegen Spieler"
L["currency-overview.category.dungeonraid"] = "Dungeon und Schlachtzug"
L["currency-overview.category.delves"] = "Tiefen"
L["currency-overview.category.season"] = "Saison"
L["currency-overview.category.timerunning"] = "Zeitläufer"
L["currency-overview.category.profession"] = "Beruf"
L["currency-overview.category.tradeskills"] = "Berufe und Berufsfertigkeiten"

L["currency-overview.tab.character"] = "Charakter"
L["currency-overview.tab.account"] = "Account"
L["currency-overview.tab.warband"] = "Kriegsmeute"

L["currency-overview.table.date"] = "Datum"
L["currency-overview.table.amount"] = "Betrag"
L["currency-overview.table.difference"] = "Differenz"
L["currency-overview.table.no-entries"] = "Keine Einträge für diesen Monat."

L["currency-overview.menu.more"] = "Mehr"
L["currency-overview.menu.hide-unchanged-entries"] = "Unveränderte Einträge ausblenden"
L["currency-overview.menu.delete-character"] = "Daten von „%s“ löschen …"
L["currency-overview.menu.patch"] = "Patch %s"

L["currency-overview.delete-character.confirm"] = "Charakter „%s“ auf Realm „%s“ und alle erfassten Daten löschen?"

-- Chart

L["chart.title"] = "Diagramm"
L["chart.scope"] = "Ansicht"
L["chart.currency"] = "Währung"

L["chart.period"] = "Zeitraum"
L["chart.period.7days"] = "Letzte 7 Tage"
L["chart.period.30days"] = "Letzte 30 Tage"
L["chart.period.90days"] = "Letzte 90 Tage"
L["chart.period.month"] = "Dieser Monat"
L["chart.period.last-month"] = "Letzter Monat"
L["chart.period.year"] = "Dieses Jahr"
L["chart.period.all"] = "Gesamter Verlauf"
L["chart.period.custom"] = "Eigener Zeitraum"

L["chart.from"] = "Von"
L["chart.to"] = "Bis"
L["chart.apply"] = "Übernehmen"

L["chart.decimal-separator"] = ","
L["chart.unit.thousand"] = "k"
L["chart.unit.million"] = "M"

L["chart.error.date"] = "Bitte ein gültiges Datum eingeben (%s)."
L["chart.error.range"] = "„Von“ darf nicht nach „Bis“ liegen, und kein Datum darf in der Zukunft liegen."

L["chart.no-data"] = "Für diese Währung ist im gewählten Zeitraum noch kein Verlauf vorhanden."
L["chart.no-currencies"] = "Keine Währungen verfügbar."

L["chart.summary.start"] = "Anfang"
L["chart.summary.end"] = "Ende"
L["chart.summary.change"] = "Änderung"

L["chart.history-note"] = "Das Diagramm zeigt den zuletzt erfassten Bestand pro Tag. Für Tage ohne neuen Wert wird der vorherige Bestand angezeigt. Der Verlauf beginnt mit dem ersten erfassten Wert."

-- WoW Token

L["wow-token.title"] = "WoW-Marke"
L["wow-token.region"] = "Region"
L["wow-token.price"] = "Goldpreis"
L["wow-token.no-data"] = "Für den gewählten Zeitraum wurden noch keine Preise der WoW-Marke aufgezeichnet."
L["wow-token.history-note"] = "Das Diagramm zeigt den zuletzt pro Tag aufgezeichneten Goldpreis der WoW-Marke für die aktuelle Spielregion. Preise werden erfasst, während ein Charakter eingeloggt ist. An Tagen ohne neuen Preis wird der zuletzt erfasste Preis angezeigt. Die Aufzeichnung beginnt mit der ersten erfolgreichen Abfrage."
