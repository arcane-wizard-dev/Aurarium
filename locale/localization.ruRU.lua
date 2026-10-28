local _, AUR = ...

if AUR.State and AUR.State.libraryIncompatible then return end

if GetLocale() ~= "ruRU" then return end

local L = AUR.Localization

-- Options

L["options.general"] = "Общие параметры"
L["options.general.date-format.name"] = "Формат даты"
L["options.general.date-format.tooltip"] = "Задаёт формат даты для всех таблиц, графиков, подсказок и полей ввода даты."
L["options.general.minimap-button.name"] = "Кнопка у мини-карты"
L["options.general.minimap-button.tooltip"] = "Показывает кнопку у мини-карты."
L["options.general.debug-mode.name"] = "Режим отладки"
L["options.general.debug-mode.tooltip"] = "Показывает дополнительную отладочную информацию в чате."

L["options.currency-overview"] = "Обзор золота и валюты"
L["options.currency-overview.open-on-login.name"] = "Открывать автоматически"
L["options.currency-overview.open-on-login.tooltip"] = "Автоматически открывает обзор золота и валюты при входе в игру."

L["options.gold-display"] = "Индикатор золота"
L["options.gold-display.show.name"] = "Показывать индикатор золота"
L["options.gold-display.show.tooltip"] = "Показывает небольшой перемещаемый индикатор с текущим золотом и изменением за сегодня."
L["options.gold-display.show-border.name"] = "Показывать рамку"
L["options.gold-display.show-border.tooltip"] = "Показывает рамку вокруг индикатора золота."
L["options.gold-display.display-mode.name"] = "Отображаемые монеты"
L["options.gold-display.display-mode.tooltip"] = "Определяет, какие монеты отображаются в индикаторе золота."

-- General

L["minimap-button.tooltip"] = "|cnLINK_FONT_COLOR:Щёлкните левой кнопкой мыши|r, чтобы открыть обзор золота и валюты.\n|cnLINK_FONT_COLOR:Щёлкните правой кнопкой мыши|r, чтобы открыть настройки."

L["button.next"] = "Вперёд"
L["button.prev"] = "Назад"

L["date-format.ymd"] = "ГГГГ-ММ-ДД"
L["date-format.mdy"] = "ММ/ДД/ГГГГ"
L["date-format.dmy"] = "ДД.ММ.ГГГГ"

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

L["chat.delete-character.deleted"] = "Персонаж «%s» на сервере «%s» удалён."
L["chat.delete-character.current-not-allowed"] = "Нельзя удалить текущего персонажа."

-- Currency Overview

L["currency-overview.category.gold"] = "Золото"
L["currency-overview.category.warband"] = "Валюты отряда"
L["currency-overview.category.character"] = "Валюты персонажа"
L["currency-overview.category.misc"] = "Разное"
L["currency-overview.category.pvp"] = "Игрок против игрока"
L["currency-overview.category.dungeonraid"] = "Подземелье и рейд"
L["currency-overview.category.delves"] = "Вылазки"
L["currency-overview.category.season"] = "Сезон"
L["currency-overview.category.timerunning"] = "Путешественники во времени"
L["currency-overview.category.profession"] = "Профессия"
L["currency-overview.category.tradeskills"] = "Профессии и ремёсла"

L["currency-overview.tab.character"] = "Персонаж"
L["currency-overview.tab.account"] = "Учётная запись"
L["currency-overview.tab.warband"] = "Отряд"

L["currency-overview.table.date"] = "Дата"
L["currency-overview.table.amount"] = "Количество"
L["currency-overview.table.difference"] = "Разница"
L["currency-overview.table.no-entries"] = "Нет записей за этот месяц."

L["currency-overview.menu.more"] = "Ещё"
L["currency-overview.menu.hide-unchanged-entries"] = "Скрывать записи без изменений"
L["currency-overview.menu.delete-character"] = "Удалить данные персонажа «%s»…"
L["currency-overview.menu.patch"] = "Обновление %s"

L["currency-overview.delete-character.confirm"] = "Удалить персонажа «%s» на сервере «%s» и все сохранённые данные?"

-- Chart

L["chart.title"] = "График"
L["chart.scope"] = "Режим"
L["chart.currency"] = "Валюта"

L["chart.period"] = "Период"
L["chart.period.7days"] = "Последние 7 дней"
L["chart.period.30days"] = "Последние 30 дней"
L["chart.period.90days"] = "Последние 90 дней"
L["chart.period.month"] = "Текущий месяц"
L["chart.period.last-month"] = "Прошлый месяц"
L["chart.period.year"] = "Текущий год"
L["chart.period.all"] = "Вся история"
L["chart.period.custom"] = "Выбрать даты"

L["chart.from"] = "С"
L["chart.to"] = "По"
L["chart.apply"] = "Применить"

L["chart.decimal-separator"] = ","
L["chart.unit.thousand"] = "k"
L["chart.unit.million"] = "M"

L["chart.error.date"] = "Введите корректную дату (%s)."
L["chart.error.range"] = "Начало не может быть позже конца; даты не могут быть в будущем."

L["chart.no-data"] = "За выбранный период пока нет истории изменения количества этой валюты."
L["chart.no-currencies"] = "Нет доступных валют."

L["chart.summary.start"] = "Начало"
L["chart.summary.end"] = "Конец"
L["chart.summary.change"] = "Изменение"

L["chart.history-note"] = "График показывает последнее зафиксированное количество за каждый день. В дни без нового значения отображается предыдущее количество. График начинается с первого зафиксированного значения."

-- WoW Token

L["wow-token.title"] = "Жетон WoW"
L["wow-token.region"] = "Регион"
L["wow-token.price"] = "Цена в золоте"
L["wow-token.no-data"] = "За выбранный период цены жетона WoW ещё не записаны."
L["wow-token.history-note"] = "График показывает последнюю записанную за каждый день цену жетона WoW в золоте для текущего игрового региона. Цены записываются, пока персонаж в игре. В дни без новой цены отображается последняя записанная цена. Запись начинается с первого успешного запроса."
