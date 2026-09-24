local _, AUR = ...

if GetLocale() ~= "ruRU" then return end

local L = AUR.Localization

-- Options

L["options.general"] = "Общие параметры"
L["options.general.minimap-button.name"] = "Кнопка у мини-карты"
L["options.general.minimap-button.tooltip"] = "Если этот параметр включен, кнопка отображается у мини-карты."
L["options.general.debug-mode.name"] = "Режим отладки"
L["options.general.debug-mode.tooltip"] = "Если режим отладки включен, в чате отображается дополнительная информация."

L["options.currency-overview"] = "Обзор золота и валюты"
L["options.currency-overview.open-on-login.name"] = "Открывать автоматически"
L["options.currency-overview.open-on-login.tooltip"] = "Если этот параметр включен, обзор золота и валюты будет автоматически открываться при входе в игру."
L["options.currency-overview.hide-unchanged-entries.name"] = "Скрывать записи без изменений"
L["options.currency-overview.hide-unchanged-entries.tooltip"] = "Если этот параметр включен, дни без изменения баланса скрываются в обзорах персонажа, аккаунта и отряда."

L["options.gold-display"] = "Индикатор золота"
L["options.gold-display.show.name"] = "Показывать индикатор золота"
L["options.gold-display.show.tooltip"] = "Если этот параметр включен, небольшой перемещаемый индикатор показывает текущее золото и изменение за сегодня."
L["options.gold-display.display-mode.name"] = "Отображаемые монеты"
L["options.gold-display.display-mode.tooltip"] = "Определяет, какие монеты отображаются в индикаторе золота."

-- General

L["minimap-button.tooltip"] = "|cnLINK_FONT_COLOR:Щелкните левой кнопкой мыши|r, чтобы открыть обзор золота и валюты.\n|cnLINK_FONT_COLOR:Щелкните правой кнопкой мыши|r, чтобы открыть настройки."

L["button.next"] = "Вперёд"
L["button.prev"] = "Назад"

L["month.jan"] = "Январь"
L["month.feb"] = "Февраль"
L["month.mar"] = "Март"
L["month.apr"] = "Апрель"
L["month.may"] = "Май"
L["month.jun"] = "Июнь"
L["month.jul"] = "Июль"
L["month.aug"] = "Август"
L["month.sep"] = "Сентябрь"
L["month.oct"] = "Октябрь"
L["month.nov"] = "Ноябрь"
L["month.dec"] = "Декабрь"

-- Chat

L["chat.delete-character.deleted"] = "Персонаж '%s' на сервере '%s' удалён."
L["chat.delete-character.current-not-allowed"] = "Нельзя удалить персонажа, которым вы сейчас играете."

-- Currency Overview

L["currency-overview.category.gold"] = "Золото"
L["currency-overview.category.warband"] = "Валюты отряда"
L["currency-overview.category.character"] = "Валюты персонажа"
L["currency-overview.category.misc"] = "Разное"
L["currency-overview.category.pvp"] = "Игрок против игрока"
L["currency-overview.category.dungeonraid"] = "Подземелье и рейд"
L["currency-overview.category.delves"] = "Вылазки"
L["currency-overview.category.season"] = "Сезон"
L["currency-overview.category.timerunning"] = "Путешествие во времени"
L["currency-overview.category.profession"] = "Профессия"
L["currency-overview.category.tradeskills"] = "Профессии и ремесла"
L["currency-overview.category.classic"] = "Classic"
L["currency-overview.category.tbc"] = "Burning Crusade"
L["currency-overview.category.wotlk"] = "Гнев Короля-лича"
L["currency-overview.category.cata"] = "Катаклизм"
L["currency-overview.category.mop"] = "Пандария"
L["currency-overview.category.wod"] = "Дренор"
L["currency-overview.category.legion"] = "Легион"
L["currency-overview.category.bfa"] = "Битва за Азерот"
L["currency-overview.category.sl"] = "Темные Земли"
L["currency-overview.category.df"] = "Драконы"
L["currency-overview.category.tww"] = "Война Внутри"
L["currency-overview.category.mid"] = "Полночь"

L["currency-overview.tab.character"] = "Персонаж"
L["currency-overview.tab.account"] = "Аккаунт"
L["currency-overview.tab.warband"] = "Отряд"

L["currency-overview.table.date"] = "Дата"
L["currency-overview.table.amount"] = "Количество"
L["currency-overview.table.difference"] = "Разница"
L["currency-overview.table.no-entries"] = "Нет записей за этот месяц."
L["currency-overview.menu.delete-character"] = "Удалить персонажа"
L["currency-overview.menu.patch"] = "Обновление %s"
L["currency-overview.delete-character.confirm"] = "Удалить персонажа '%s' на сервере '%s' и все сохраненные данные?"
