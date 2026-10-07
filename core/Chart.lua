local addonName, AUR = ...

local AWL = ArcaneWizardLibrary
local Addon = AWL:GetAddon(addonName)
local L = AUR.Localization
local Chart = AUR.Modules.Chart
local Utils = AUR.Modules.Utils
local CurrencyMenu = AUR.Modules.CurrencyMenu
local Data = AUR.CHART_DATA

local window, plot, scopeGroup, characterDropdown, currencyDropdown, periodDropdown
local firstInput, lastInput, applyButton, statusText, captionText, customPanel, customButton
local summaryValues = {}
local selectedOwner, selectedCurrency = nil, "gold"
local selectedCurrencyIcon
local lastCharacterKey
local selectedPeriod = Data.defaultPeriod
local history, points, rangeFirst, rangeLast, minimum, maximum
local refreshPending = false
local lines, axisLabels, gridLines = {}, {}, {}
local shortLines = {}

local function DateParts(value)
	local year, month, day = value:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")

	return tonumber(year), tonumber(month), tonumber(day)
end

local function Timestamp(value)
	local year, month, day = DateParts(value)

	return time({
		year = year,
		month = month,
		day = day,
		hour = 12,
		min = 0,
		sec = 0
	})
end

local function ShiftDate(value, days)
	return date("%Y-%m-%d", Timestamp(value) + days * 86400)
end

local function MonthDate(month)
	return date("%Y-%m-%d", time({
		year = math.floor(month / 12),
		month = month % 12 + 1,
		day = 1,
		hour = 12,
		min = 0,
		sec = 0
	}))
end

function Chart:ParseDate(value)
	if type(value) ~= "string" then
		return
	end

	local day, month, year = value:match("^(%d%d)%.(%d%d)%.(%d%d%d%d)$")

	if not year then
		month, day, year = value:match("^(%d%d)/(%d%d)/(%d%d%d%d)$")
	end

	if year then
		value = year .. "-" .. month .. "-" .. day
	end

	year, month, day = DateParts(value)

	if not year or year < 1970 or year > 9999 or month < 1 or month > 12 or day < 1 or day > 31 then
		return
	end

	local ok, stamp = pcall(Timestamp, value)

	if ok and stamp and date("%Y-%m-%d", stamp) == value then return value end
end

function Chart:FormatDate(value, short)
	return Utils:FormatDate(value, short)
end

function Chart:GetAxisBounds(minimum, maximum)
	local data = AUR.CHART_DATA
	local padding = math.max(
		(maximum - minimum) * data.axisPadding,
		minimum == maximum and maximum * data.flatAxisPadding or 0,
		1
	)

	local lower, upper = math.max(0, minimum - padding), maximum + padding
	local targetStep = math.max((upper - lower) / data.gridSteps, 1)
	local magnitude = 10 ^ math.floor(math.log10(targetStep))
	local first, last = lower, upper

	for _, multiplier in ipairs(data.axisStepMultipliers) do
		local step = magnitude * multiplier
		first = math.floor(lower / step) * step
		last = first + data.gridSteps * step

		if step >= targetStep and last >= upper then
			break
		end
	end

	return first, last
end

function Chart:GetRange(config)
	local today = Utils:GetToday()
	local days = AUR.CHART_DATA.days[config.period]

	if days then return ShiftDate(today, 1 - days), today end

	if config.period == "custom" then
		local first, last = self:ParseDate(config.first), self:ParseDate(config.last)

		if not first or not last then return nil, nil, "date" end

		if first > last or last > today then return nil, nil, "range" end

		return first, last
	elseif config.period == "month" then
		return today:sub(1, 7) .. "-01", today
	elseif config.period == "last-month" then
		local last = ShiftDate(today:sub(1, 7) .. "-01", -1)

		return last:sub(1, 7) .. "-01", last
	elseif config.period == "year" then
		return today:sub(1, 4) .. "-01-01", today
	elseif config.period == "all" then
		return config.history[1] and config.history[1].date or today, today
	end

	return ShiftDate(today, -29), today
end

function Chart:GetHistory(scope, characterKey, currencyKey)
	local owners = {}

	if scope == "warband" then
		if not AWL.GAME_TYPE_RETAIL or currencyKey:sub(1, 2) ~= "w-" then return {} end
		owners[1] = {key = "Warband", history = AUR.Data.balance.Warband or {}}
	elseif currencyKey:sub(1, 2) == "w-" then
		return {}
	elseif scope == "account" then
		owners = Utils:GetSortedCharacters()
	else
		local entry = Utils:GetCharacterEntry(characterKey)

		if entry then
			owners[1] = entry
		end
	end

	local today, changes = Utils:GetToday(), {}
	local currentGUID = AWL.Utils:GetCharacterGUID()

	for _, owner in ipairs(owners) do
		local values, dates = {}, {}

		for day, data in pairs(owner.history) do
			if day <= today and type(data[currencyKey]) == "number" then
				values[day] = data[currencyKey]
			end
		end

		if owner.key == currentGUID or owner.key == "Warband" then
			if currencyKey == "gold" then
				if AUR.State.gold ~= nil then
					values[today] = AUR.State.gold
				end
			else
				local entry = AUR.State.currencyByID[tonumber(currencyKey:sub(3))]

				if entry and entry.key == currencyKey and entry.info and entry.info.quantity ~= nil then
					values[today] = entry.info.quantity
				end
			end
		elseif not next(values) then
			values[today] = 0
		end

		for day in pairs(values) do
			dates[#dates + 1] = day
		end

		table.sort(dates)

		local previous = 0

		for _, day in ipairs(dates) do
			changes[day] = (changes[day] or 0) + values[day] - previous
			previous = values[day]
		end
	end

	local dates, history, total = {}, {}, 0

	for day in pairs(changes) do
		dates[#dates + 1] = day
	end

	table.sort(dates)

	for _, day in ipairs(dates) do
		total = total + changes[day]
		history[#history + 1] = {date = day, value = total}
	end

	return history
end

function Chart:GetSeries(history, first, last)
	local series = {}

	if #history == 0 or history[1].date > last then return series end

	if #history == 1 and history[1].date == Utils:GetToday() and history[1].value == 0 then
		return series
	end

	local day = first < history[1].date and history[1].date or first
	local index, value = 1, nil

	while day <= last do
		while history[index] and history[index].date <= day do
			value = history[index].value
			index = index + 1
		end

		if value ~= nil then
			series[#series + 1] = {date = day, value = value}
		end

		day = ShiftDate(day, 1)
	end

	return series
end

function Chart:GetDayOffset(first, last)
	return math.floor((Timestamp(last) - Timestamp(first)) / 86400 + 0.5)
end

local function CalendarTicks(first, last, config)
	local year, month = DateParts(first)
	local nextMonth = (math.floor((year * 12 + month - 1) / config.step) + 1) * config.step
	local previous
	local days = Chart:GetDayOffset(first, last)
	local ticks = {first}

	while true do
		local day = MonthDate(nextMonth)

		if day >= last then
			break
		end

		if previous and Chart:GetDayOffset(previous, day) < config.minimumGap then return end

		local offset = Chart:GetDayOffset(first, day)

		if offset >= config.minimumGap and days - offset >= config.minimumGap then
			ticks[#ticks + 1] = day
		end

		previous = day
		nextMonth = nextMonth + config.step
	end

	ticks[#ticks + 1] = last

	return ticks
end

function Chart:GetDateTicks(first, last, limit)
	if first == last then return {first} end

	local days = self:GetDayOffset(first, last)
	local minimumGap = days / (math.max(2, math.floor(limit)) - 1)
	local ticks = {first}
	local data = AUR.CHART_DATA.dateAxis

	for _, step in ipairs(data.daySteps) do
		if step >= minimumGap then
			for offset = step, days - 1, step do
				if days - offset >= minimumGap then
					ticks[#ticks + 1] = ShiftDate(first, offset)
				end
			end

			ticks[#ticks + 1] = last

			return ticks
		end
	end

	for _, step in ipairs(data.monthSteps) do
		local calendar = CalendarTicks(first, last, {step = step, minimumGap = minimumGap})

		if calendar then return calendar end
	end

	return CalendarTicks(first, last, {step = 12 * math.ceil(minimumGap / 365), minimumGap = minimumGap})
end

function Chart:ReduceSeries(series, limit)
	limit = math.max(4, math.floor(limit))

	if #series <= limit then return series end

	local result = {series[1]}
	local buckets = math.floor((limit - 2) / 2)
	local width = (#series - 2) / buckets

	for bucket = 1, buckets do
		local first = 2 + math.floor((bucket - 1) * width)
		local last = 1 + math.floor(bucket * width)
		local low, high = first, first

		for i = first + 1, last do
			if series[i].value < series[low].value then
				low = i
			end

			if series[i].value > series[high].value then
				high = i
			end
		end

		if low > high then
			low, high = high, low
		end

		result[#result + 1] = series[low]

		if low ~= high then
			result[#result + 1] = series[high]
		end
	end

	result[#result + 1] = series[#series]

	return result
end

local function Scope()
	if selectedOwner == "account" or selectedOwner == "warband" then return selectedOwner end

	return "character"
end

local function FormatAmount(value)
	local sign = value < 0 and "-" or ""
	value = math.abs(value)

	if selectedCurrency == "gold" then
		return string.format(
			"%s%s |T237618:0|t %02d |T237620:0|t %02d |T237617:0|t",
			sign,
			BreakUpLargeNumbers(math.floor(value / 10000)),
			math.floor(value / 100) % 100,
			value % 100
		)
	end

	return sign .. BreakUpLargeNumbers(value) .. (selectedCurrencyIcon and " |T" .. selectedCurrencyIcon .. ":0|t" or "")
end

local function GetAxisFormat(value)
	for _, unit in ipairs(Data.axisUnits) do
		if value >= unit.value then
			local scaled = value / unit.value

			return unit.value, L[unit.label], scaled < 10 and 2 or scaled < 100 and 1 or 0
		end
	end

	return 1, "", 0
end

local function FormatAxis(value)
	if selectedCurrency == "gold" then
		value = value / 10000
	end

	local divisor, suffix, decimals = GetAxisFormat(value)
	local amount = string.format("%." .. decimals .. "f", value / divisor)

	if decimals > 0 then
		amount = amount:gsub("0+$", ""):gsub("%.$", "")
	end

	return amount:gsub("%.", L["chart.decimal-separator"]) .. suffix
end

local function GetReadableAxisBounds(lower, upper)
	local scale = selectedCurrency == "gold" and 10000 or 1
	lower, upper = lower / scale, upper / scale

	local divisor, _, decimals = GetAxisFormat(upper)
	local quantum = divisor / 10 ^ decimals

	while true do
		local first, last = Chart:GetAxisBounds(lower / quantum, upper / quantum)
		first, last = first * quantum, last * quantum
		divisor, _, decimals = GetAxisFormat(last)

		local nextQuantum = divisor / 10 ^ decimals

		if nextQuantum <= quantum then
			return first * scale, last * scale
		end

		quantum = nextQuantum
	end
end

local function CharacterOptions()
	local options = {}
	local previousRealm, children

	for _, entry in ipairs(Utils:GetSortedCharacters()) do
		if entry.realm ~= previousRealm then
			children, previousRealm = {}, entry.realm
			options[#options + 1] = {
				label = entry.realm ~= "" and entry.realm or L["currency-overview.tab.character"],
				children = children
			}
		end

		children[#children + 1] = {label = entry.name, value = entry.key}
	end

	return options
end

local function FindOption(options, value)
	for _, option in ipairs(options) do
		if option.value ~= nil and (value == nil or option.value == value) then return option end

		if option.children then
			local child = FindOption(option.children, value)

			if child then return child end
		end
	end
end

local function Label(parent, text)
	local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetText(text)
	label:SetJustifyH("LEFT")

	return label
end

local function DrawLine(config)
	local dx, dy = config.x2 - config.x1, config.y2 - config.y1
	local thickness = math.max(Data.lineThickness, config.pixel)

	if dx * dx + dy * dy <= (2 * thickness) ^ 2 then
		local texture = shortLines[config.index]

		if not texture then
			texture = plot:CreateTexture(nil, "ARTWORK")
			texture:SetColorTexture(unpack(Data.lineColor))
			shortLines[config.index] = texture
		end

		texture:ClearAllPoints()
		texture:SetPoint(
			"BOTTOMLEFT", plot, "BOTTOMLEFT",
			math.min(config.x1, config.x2) - thickness / 2,
			math.min(config.y1, config.y2) - thickness / 2
		)
		texture:SetSize(math.abs(dx) + thickness, math.abs(dy) + thickness)
		texture:Show()

		return
	end

	local line = lines[config.index]

	if not line then
		line = plot:CreateLine(nil, "ARTWORK")
		line:SetColorTexture(unpack(Data.lineColor))
		lines[config.index] = line
	end

	line:SetThickness(thickness)
	line:ClearAllPoints()
	line:SetStartPoint("BOTTOMLEFT", plot, config.x1, config.y1)
	line:SetEndPoint("BOTTOMLEFT", plot, config.x2, config.y2)
	line:Show()
end

local function DrawGridLine(config)
	local texture = gridLines[config.index]

	if not texture then
		texture = plot:CreateTexture(nil, "BACKGROUND")
		gridLines[config.index] = texture
	end

	local pixel = PixelUtil.GetPixelToUIUnitFactor() / plot:GetEffectiveScale()
	local left, bottom = plot:GetLeft(), plot:GetBottom()
	local x = math.floor((left + config.x) / pixel + 0.5) * pixel - left
	local y = math.floor((bottom + config.y) / pixel + 0.5) * pixel - bottom
	local right = math.floor((left + config.x + config.width) / pixel + 0.5) * pixel - left
	local top = math.floor((bottom + config.y + config.height) / pixel + 0.5) * pixel - bottom
	texture:ClearAllPoints()
	texture:SetPoint("BOTTOMLEFT", plot, "BOTTOMLEFT", x, y)
	texture:SetSize(math.max(pixel, right - x), math.max(pixel, top - y))
	texture:SetColorTexture(unpack(config.color))
	texture:Show()

	return x, y
end

local function Coordinates(point)
	local days = Chart:GetDayOffset(rangeFirst, rangeLast)
	local x = days > 0 and Chart:GetDayOffset(rangeFirst, point.date) / days * plot:GetWidth() or plot:GetWidth() / 2
	local y = (point.value - minimum) / (maximum - minimum) * plot:GetHeight()

	return x, y
end

local function ClearHover()
	plot.cursor:Hide()
	plot.hoverPoint:Hide()
	plot.hoverIndex = nil

	if GameTooltip:IsOwned(plot) then
		GameTooltip:Hide()
	end
end

local function UpdateHover()
	if not points or #points == 0 then
		return
	end

	local cursorX = GetCursorPosition()
	local x = cursorX / plot:GetEffectiveScale() - plot:GetLeft()
	local days = Chart:GetDayOffset(rangeFirst, rangeLast)
	local offset = math.floor(math.max(0, math.min(1, x / plot:GetWidth())) * days + 0.5)
	local index = offset - Chart:GetDayOffset(rangeFirst, points[1].date) + 1

	if index < 1 or index > #points then
		ClearHover()

		return
	end

	if plot.hoverIndex == index then
		return
	end

	plot.hoverIndex = index

	local point = points[index]
	local px, py = Coordinates(point)

	plot.cursor:ClearAllPoints()
	plot.cursor:SetPoint("BOTTOMLEFT", plot, "BOTTOMLEFT", px, 0)
	plot.cursor:SetSize(Data.gridThickness, plot:GetHeight())
	plot.cursor:Show()

	plot.hoverPoint:ClearAllPoints()
	plot.hoverPoint:SetPoint("CENTER", plot, "BOTTOMLEFT", px, py)
	plot.hoverPoint:Show()

	GameTooltip:SetOwner(plot, "ANCHOR_RIGHT")
	GameTooltip:SetText(Chart:FormatDate(point.date))
	GameTooltip:AddLine(FormatAmount(point.value), 1, 1, 1)
	GameTooltip:Show()
end

local function DrawChart()
	ClearHover()

	for _, line in pairs(lines) do
		line:Hide()
	end

	for _, line in pairs(shortLines) do
		line:Hide()
	end

	for _, line in ipairs(gridLines) do
		line:Hide()
	end

	for _, label in ipairs(axisLabels) do
		label:Hide()
	end

	plot.singlePoint:Hide()
	plot.empty:SetShown(not points or #points == 0)

	if not points or #points == 0 then
		for _, value in ipairs(summaryValues) do
			value:SetText("-")
			value:SetTextColor(unpack(Data.normalColor))
		end

		return
	end

	minimum, maximum = points[1].value, points[1].value

	for _, point in ipairs(points) do
		minimum, maximum = math.min(minimum, point.value), math.max(maximum, point.value)
	end

	minimum, maximum = GetReadableAxisBounds(minimum, maximum)

	local width, height = plot:GetWidth(), plot:GetHeight()
	local gridIndex = 0

	for i = 0, Data.gridSteps do
		local fraction = i / Data.gridSteps
		gridIndex = gridIndex + 1

		local _, y = DrawGridLine({
			index = gridIndex,
			x = 0,
			y = fraction * height,
			width = width,
			height = 0,
			color = i == 0 and Data.grid.axisColor or Data.grid.horizontalColor
		})
		gridIndex = gridIndex + 1
		DrawGridLine({
			index = gridIndex,
			x = -Data.grid.tickLength,
			y = fraction * height,
			width = Data.grid.tickLength,
			height = 0,
			color = Data.grid.axisColor
		})

		local label = axisLabels[i + 1]
		label:ClearAllPoints()
		label:SetPoint("RIGHT", plot, "BOTTOMLEFT", -Data.axisGap.x, y)
		label:SetText(FormatAxis(minimum + fraction * (maximum - minimum)))
		label:Show()
	end

	local days = Chart:GetDayOffset(rangeFirst, rangeLast)
	local shortDates = rangeFirst:sub(1, 4) == rangeLast:sub(1, 4)
	local sample = axisLabels[Data.gridSteps + 2]
	sample:SetText(Chart:FormatDate(rangeFirst, shortDates))

	local textWidth = sample:GetUnboundedStringWidth()
	sample:SetText(Chart:FormatDate(rangeLast, shortDates))
	textWidth = math.max(textWidth, sample:GetUnboundedStringWidth())

	local labelLimit = math.min(Data.dateAxis.maximumLabels, math.floor(width / (textWidth + Data.dateAxis.labelGap)) + 1)
	local ticks = Chart:GetDateTicks(rangeFirst, rangeLast, labelLimit)

	for i, day in ipairs(ticks) do
		local offset = Chart:GetDayOffset(rangeFirst, day)
		gridIndex = gridIndex + 1

		local x = DrawGridLine({
			index = gridIndex,
			x = days > 0 and offset / days * width or width / 2,
			y = 0,
			width = 0,
			height = height,
			color = Data.grid.verticalColor
		})

		local label = axisLabels[Data.gridSteps + 1 + i]
		label:ClearAllPoints()

		local anchor = "TOP"

		if #ticks > 1 then
			if i == 1 then
				anchor = "TOPLEFT"
			elseif i == #ticks then
				anchor = "TOPRIGHT"
			end
		end

		label:SetPoint(anchor, plot, "BOTTOMLEFT", x, -Data.axisGap.y)
		label:SetText(Chart:FormatDate(day, shortDates))
		label:Show()
	end

	DrawGridLine({
		index = gridIndex + 1,
		x = 0,
		y = 0,
		width = 0,
		height = height,
		color = Data.grid.axisColor
	})
	DrawGridLine({
		index = gridIndex + 2,
		x = 0,
		y = 0,
		width = width,
		height = 0,
		color = Data.grid.axisColor
	})

	local pixel = PixelUtil.GetPixelToUIUnitFactor() / plot:GetEffectiveScale()
	local firstX = Coordinates(points[1])
	local lastX = Coordinates(points[#points])
	local spacing = math.max(Data.pointSpacing, Data.pointSpacing * pixel)
	local pointLimit = math.min(Data.maxSegments, math.floor((lastX - firstX) / spacing) + 1)
	local reduced = Chart:ReduceSeries(points, pointLimit)

	for i = 2, #reduced do
		local x1, y1 = Coordinates(reduced[i - 1])
		local x2, y2 = Coordinates(reduced[i])
		DrawLine({
			index = i - 1,
			x1 = x1,
			y1 = y1,
			x2 = x2,
			y2 = y2,
			pixel = pixel
		})
	end

	if #points == 1 then
		local x, y = Coordinates(points[1])
		plot.singlePoint:ClearAllPoints()
		plot.singlePoint:SetPoint("CENTER", plot, "BOTTOMLEFT", x, y)
		plot.singlePoint:Show()
	end

	local first, last = points[1].value, points[#points].value
	local change = last - first
	summaryValues[1]:SetText(FormatAmount(first))
	summaryValues[2]:SetText(FormatAmount(last))
	summaryValues[3]:SetText((change > 0 and "+" or "") .. FormatAmount(change))
	summaryValues[3]:SetTextColor(unpack(
		change > 0 and Data.positiveColor or change < 0 and Data.errorColor or Data.normalColor
	))
end

function Chart:Refresh(rebuildHistory)
	if not window then
		return
	end

	if selectedOwner == "warband" and not AWL.GAME_TYPE_RETAIL
		or Scope() == "character" and not Utils:GetCharacterEntry(selectedOwner) then
		selectedOwner = AWL.Utils:GetCharacterGUID()

		if not Utils:GetCharacterEntry(selectedOwner) then
			selectedOwner = "account"
		end

		rebuildHistory = true
	end

	if Scope() == "character" then
		lastCharacterKey = selectedOwner
	elseif not lastCharacterKey or not Utils:GetCharacterEntry(lastCharacterKey) then
		local characters = Utils:GetSortedCharacters()
		lastCharacterKey = Utils:GetCharacterEntry(AWL.Utils:GetCharacterGUID()) and AWL.Utils:GetCharacterGUID()
			or characters[1] and characters[1].key
	end

	scopeGroup:SetValue(Scope())
	characterDropdown:SetValue(lastCharacterKey)
	characterDropdown:SetEnabled(Scope() == "character" and lastCharacterKey ~= nil)

	local options = CurrencyMenu:GetOptions(Scope())
	local option = FindOption(options, selectedCurrency) or FindOption(options)
	local nextCurrency = option and option.value
	selectedCurrencyIcon = option and option.icon

	if selectedCurrency ~= nextCurrency then
		selectedCurrency = nextCurrency
		rebuildHistory = true
	end

	currencyDropdown:SetOptions(options)
	currencyDropdown:SetValue(selectedCurrency)
	captionText:SetText(option and option.label .. " - " .. L["chart.period." .. selectedPeriod] or "")

	if rebuildHistory or not history then
		history = selectedCurrency and self:GetHistory(Scope(), selectedOwner, selectedCurrency) or {}
	end

	local errorKey
	rangeFirst, rangeLast, errorKey = self:GetRange({
		period = selectedPeriod,
		history = history,
		first = firstInput:GetText(),
		last = lastInput:GetText()
	})

	local custom = selectedPeriod == "custom"
	firstInput:SetEnabled(custom)
	lastInput:SetEnabled(custom)
	applyButton:SetEnabled(custom)
	customButton:SetEnabled(not custom)
	customPanel:SetShown(custom)

	if not rangeFirst then
		local message = L["chart.error." .. errorKey]

		if errorKey == "date" then
			message = string.format(message, Utils:GetDateFormatHint())
		end

		statusText:SetText(message)
		points = {}
	else
		statusText:SetText("")

		if not custom then
			firstInput:SetText(self:FormatDate(rangeFirst))
			lastInput:SetText(self:FormatDate(rangeLast))
		end

		points = self:GetSeries(history, rangeFirst, rangeLast)
	end

	DrawChart()
end

function Chart:RefreshDateFormat()
	if not window then return end

	for _, input in ipairs({firstInput, lastInput}) do
		local value = self:ParseDate(input:GetText())

		if value then
			input:SetText(self:FormatDate(value))
		end

		input:SetPlaceholder(Utils:GetDateFormatHint())
	end

	self:Refresh()
end

local function CreateSidebar(content)
	local sidebar = CreateFrame("Frame", nil, content)
	sidebar:SetWidth(Data.sidebar.width)
	sidebar:SetPoint("TOPLEFT", 0, 0)
	sidebar:SetPoint("BOTTOMLEFT", 0, 0)
	Label(sidebar, L["chart.scope"]):SetPoint("TOPLEFT", Data.margin, -Data.margin)

	local scopes = {
		{label = L["currency-overview.tab.character"], value = "character"},
		{label = L["currency-overview.tab.account"], value = "account"}
	}

	if AWL.GAME_TYPE_RETAIL then
		scopes[#scopes + 1] = {label = L["currency-overview.tab.warband"], value = "warband"}
	end

	scopeGroup = AWL.Controls:CreateOptionGroup({
		parent = sidebar,
		width = Data.sidebar.controlWidth,
		options = scopes,
		selectedValue = "character",
		onValueChanged = function(value)
			selectedOwner = value == "character" and (lastCharacterKey or AWL.Utils:GetCharacterGUID()) or value
			Chart:Refresh(true)
		end
	})
	scopeGroup:SetPoint("TOPLEFT", Data.margin, -Data.sidebar.scopeTop)

	characterDropdown = AWL.Controls:CreateDropdown({
		parent = sidebar,
		width = Data.sidebar.controlWidth,
		options = CharacterOptions,
		onValueChanged = function(value)
			selectedOwner = value
			Chart:Refresh(true)
		end
	})
	characterDropdown:SetDefaultText(L["currency-overview.tab.character"])
	characterDropdown:SetPoint("TOPLEFT", Data.margin, -Data.sidebar.characterTop)
	Label(sidebar, L["currency-overview.tab.character"]):SetPoint("BOTTOMLEFT", characterDropdown, "TOPLEFT", 0, Data.labelGap)

	currencyDropdown = AWL.Controls:CreateDropdown({
		parent = sidebar,
		width = Data.sidebar.controlWidth,
		options = {},
		onValueChanged = function(value)
			selectedCurrency = value
			Chart:Refresh(true)
			currencyDropdown:CloseMenu()
		end
	})
	currencyDropdown:SetupMenu(function(owner, root)
		CurrencyMenu:Populate(root, {
			scope = Scope(),
			characterKey = selectedOwner,
			options = owner.optionsSource,
			emptyText = owner.emptyText,
			isSelected = function(value) return owner:GetValue() == value end,
			onSelected = function(value)
				owner.onValueChanged(value, FindOption(owner.optionsSource, value), owner)
			end
		})
	end)
	currencyDropdown:SetDefaultText(L["chart.currency"])
	currencyDropdown:SetEmptyText(L["chart.no-currencies"])
	currencyDropdown:SetPoint("TOPLEFT", Data.margin, -Data.sidebar.currencyTop)
	Label(sidebar, L["chart.currency"]):SetPoint("BOTTOMLEFT", currencyDropdown, "TOPLEFT", 0, Data.labelGap)

	local periods = {}

	for _, period in ipairs(Data.periods) do
		periods[#periods + 1] = {label = L["chart.period." .. period], value = period}
	end

	periodDropdown = AWL.Controls:CreateDropdown({
		parent = sidebar,
		width = Data.sidebar.controlWidth,
		options = periods,
		selectedValue = selectedPeriod,
		onValueChanged = function(value)
			selectedPeriod = value
			Chart:Refresh()
		end
	})
	periodDropdown:SetPoint("TOPLEFT", Data.margin, -Data.sidebar.periodTop)
	Label(sidebar, L["chart.period"]):SetPoint("BOTTOMLEFT", periodDropdown, "TOPLEFT", 0, Data.labelGap)

	customButton = AWL.Controls:CreateButton({
		parent = sidebar,
		width = Data.sidebar.buttonWidth,
		label = L["chart.period.custom"],
		onClick = function()
			selectedPeriod = "custom"
			periodDropdown:SetValue(selectedPeriod)
			Chart:Refresh()
			firstInput:SetFocus()
		end
	})
	customButton:SetWidth(math.max(
		Data.sidebar.buttonWidth,
		customButton:GetFontString():GetUnboundedStringWidth() + Data.sidebar.buttonTextPadding
	))
	customButton:SetPoint("TOPLEFT", Data.margin, -Data.sidebar.customButtonTop)

	customPanel = CreateFrame("Frame", nil, sidebar)
	customPanel:SetSize(Data.sidebar.controlWidth, Data.sidebar.customPanelHeight)
	customPanel:SetPoint("TOPLEFT", Data.margin, -Data.sidebar.customPanelTop)

	local function ApplyRange()
		Chart:RefreshDateFormat()
	end

	firstInput = AWL.Controls:CreateInput({
		parent = customPanel,
		width = Data.sidebar.inputWidth,
		text = "",
		placeholder = Utils:GetDateFormatHint(),
		maxLetters = 10,
		onEnterPressed = ApplyRange
	})
	firstInput:SetPoint("TOPLEFT", Data.sidebar.inputLeft, -Data.sidebar.firstInputTop)
	Label(customPanel, L["chart.from"]):SetPoint("BOTTOMLEFT", firstInput, "TOPLEFT", -Data.sidebar.inputLeft, Data.labelGap)

	lastInput = AWL.Controls:CreateInput({
		parent = customPanel,
		width = Data.sidebar.inputWidth,
		text = "",
		placeholder = Utils:GetDateFormatHint(),
		maxLetters = 10,
		onEnterPressed = ApplyRange
	})
	lastInput:SetPoint("TOPLEFT", Data.sidebar.inputLeft, -Data.sidebar.lastInputTop)
	Label(customPanel, L["chart.to"]):SetPoint("BOTTOMLEFT", lastInput, "TOPLEFT", -Data.sidebar.inputLeft, Data.labelGap)

	applyButton = AWL.Controls:CreateButton({
		parent = customPanel,
		width = Data.sidebar.buttonWidth,
		label = L["chart.apply"],
		onClick = ApplyRange
	})
	applyButton:SetWidth(math.max(
		Data.sidebar.buttonWidth,
		applyButton:GetFontString():GetUnboundedStringWidth() + Data.sidebar.buttonTextPadding
	))
	applyButton:SetPoint("TOPLEFT", 0, -Data.sidebar.applyTop)

	statusText = Label(customPanel, "")
	statusText:SetTextColor(unpack(Data.errorColor))
	statusText:SetPoint("TOPLEFT", 0, -Data.sidebar.statusTop)
	statusText:SetWidth(Data.sidebar.controlWidth)
	statusText:SetWordWrap(true)
end

local function CreateSummary(parent)
	local width = (parent:GetWidth() - Data.summary.gap * (#Data.summary.keys - 1)) / #Data.summary.keys

	for index, key in ipairs(Data.summary.keys) do
		local panel = CreateFrame("Frame", nil, parent)
		panel:SetSize(width, Data.summary.height)
		panel:SetPoint("TOPLEFT", (index - 1) * (width + Data.summary.gap), -Data.summary.top)

		local label = Label(panel, L["chart.summary." .. key])
		label:SetPoint("TOP", 0, -Data.summary.labelTop)

		local value = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
		value:SetPoint("TOPLEFT", 0, -Data.summary.valueTop)
		value:SetPoint("TOPRIGHT", 0, -Data.summary.valueTop)
		value:SetHeight(Data.summary.valueHeight)
		value:SetJustifyH("CENTER")
		summaryValues[index] = value
	end
end

local function CreateWindow()
	local layout = Data.artwork
	local windowConfig = AWL.Utils:CopyTable(AUR.OVERVIEW_DATA.window)
	windowConfig.width = layout.width
	windowConfig.height = layout.height
	windowConfig.title = addonName .. " - " .. L["chart.title"] .. " (" .. L["chart.beta"] .. ")"

	window = AWL.Frames:CreateWindow(windowConfig)
	window:SetFrameStrata("HIGH")
	window.portrait:SetPoint("TOPLEFT", AUR.OVERVIEW_DATA.portrait.x, AUR.OVERVIEW_DATA.portrait.y)
	window.portrait:SetTexture(Addon:GetMediaPath("icon-round.tga"))
	window:SetScript("OnHide", function(self)
		self:StopMovingOrSizing()
	end)

	local insetConfig = AWL.Utils:CopyTable(AUR.OVERVIEW_DATA.inset)
	insetConfig.parent = window
	insetConfig.width = layout.artworkRight - layout.artworkLeft
	insetConfig.height = layout.artworkBottom - layout.artworkTop

	window.inset = AWL.Frames:CreateInset(insetConfig)
	window.inset:SetPoint("TOPLEFT", layout.artworkLeft, -layout.artworkTop)

	window.footerCloseButton = AWL.Controls:CreateButton({
		parent = window,
		width = Data.footer.buttonWidth,
		label = CLOSE,
		onClick = function()
			window:Hide()
		end
	})
	window.footerCloseButton:SetWidth(math.max(
		Data.footer.buttonWidth,
		window.footerCloseButton:GetFontString():GetUnboundedStringWidth() + Data.footer.buttonTextPadding
	))
	window.footerCloseButton:SetPoint("BOTTOMRIGHT", -Data.footer.right, Data.footer.bottom)

	local body = window.content
	body:ClearAllPoints()
	body:SetPoint("TOPLEFT", layout.bodyLeft, -layout.bodyTop)
	body:SetPoint("BOTTOMRIGHT", layout.bodyRight - layout.width, layout.height - layout.bodyBottom)

	window.artwork = body:CreateTexture(nil, "BACKGROUND")
	window.artwork:SetPoint("TOPLEFT", window, "TOPLEFT", layout.artworkLeft, -layout.artworkTop)
	window.artwork:SetPoint(
		"BOTTOMRIGHT", window, "BOTTOMRIGHT",
		layout.artworkRight - layout.width,
		layout.height - layout.artworkBottom
	)
	window.artwork:SetTexture(Addon:GetMediaPath(Data.window.texture))

	local textureScale = layout.textureScale / layout.textureSize
	window.artwork:SetTexCoord(
		layout.artworkLeft * textureScale,
		layout.artworkRight * textureScale,
		layout.artworkTop * textureScale,
		layout.artworkBottom * textureScale
	)

	CreateSidebar(body)

	local chartPanel = CreateFrame("Frame", nil, body)
	chartPanel:SetPoint("TOPLEFT", layout.chartLeft - layout.bodyLeft, 0)
	chartPanel:SetPoint("BOTTOMRIGHT", layout.chartRight - layout.bodyRight, 0)

	captionText = Label(chartPanel, "")
	captionText:SetFontObject("GameFontNormalLarge")
	captionText:SetPoint("TOPLEFT", 0, -Data.header.top)
	captionText:SetHeight(Data.header.height)
	captionText:SetWordWrap(false)

	CreateSummary(chartPanel)

	plot = CreateFrame("Frame", nil, chartPanel)
	plot:SetPoint("TOPLEFT", Data.plot.left, -Data.plot.top)
	plot:SetPoint("BOTTOMRIGHT", -Data.plot.right, Data.plot.bottom)

	plot.empty = Label(plot, L["chart.no-data"])
	plot.empty:SetPoint("LEFT", Data.margin, 0)
	plot.empty:SetPoint("RIGHT", -Data.margin, 0)
	plot.empty:SetJustifyH("CENTER")
	plot.empty:SetWordWrap(true)

	for i = 1, Data.gridSteps + 1 + Data.dateAxis.maximumLabels do
		axisLabels[i] = Label(chartPanel, "")
		axisLabels[i]:SetFontObject("GameFontHighlightSmall")
	end

	for _, key in ipairs({"singlePoint", "hoverPoint", "cursor"}) do
		plot[key] = plot:CreateTexture(nil, "OVERLAY")
		plot[key]:SetColorTexture(unpack(Data.lineColor))
		plot[key]:SetSize(Data.pointSize, Data.pointSize)
		plot[key]:Hide()
	end

	plot:EnableMouse(true)
	plot:SetScript("OnEnter", function(self)
		self:SetScript("OnUpdate", UpdateHover)
	end)

	local function StopHover(self)
		self:SetScript("OnUpdate", nil)
		ClearHover()
	end

	plot:SetScript("OnLeave", StopHover)
	plot:SetScript("OnHide", StopHover)

	local infoButton = CreateFrame("Button", nil, chartPanel, "UIPanelInfoButton")
	infoButton:SetSize(layout.infoSize, layout.infoSize)
	infoButton:SetPoint("TOPLEFT", layout.infoLeft - layout.chartLeft, layout.bodyTop - layout.infoTop)

	local betaBadge = CreateFrame("Frame", nil, chartPanel, "NewFeatureLabelTemplate")
	betaBadge.animateGlow = false
	betaBadge.Label:SetTextToFit(L["chart.beta-badge"])
	betaBadge.BGLabel:SetTextToFit(L["chart.beta-badge"])

	local badgeWidth = betaBadge:GetTextWidth()
	betaBadge:SetPoint("CENTER", infoButton, "LEFT", -Data.header.badgeGap - badgeWidth / 2, 0)
	betaBadge:Show()
	window.betaBadge = betaBadge
	captionText:SetPoint("TOPRIGHT", -layout.infoSize - badgeWidth - Data.header.badgeGap * 2, -Data.header.top)

	infoButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText(L["chart.title"])
		GameTooltip:AddLine(L["chart.history-note"], 1, 1, 1, true)
		GameTooltip:Show()
	end)

	local function HideInfoTooltip(self)
		if GameTooltip:IsOwned(self) then
			GameTooltip:Hide()
		end
	end

	infoButton:SetScript("OnLeave", HideInfoTooltip)
	infoButton:SetScript("OnHide", HideInfoTooltip)
end

function Chart:Show(config)
	config = config or {}

	if config.characterKey then
		lastCharacterKey = config.characterKey
	end

	if config.scope == "account" or config.scope == "warband" then
		selectedOwner = config.scope
	elseif config.characterKey then
		selectedOwner = config.characterKey
	end

	selectedOwner = selectedOwner or AWL.Utils:GetCharacterGUID()

	if config.currencyKey then
		selectedCurrency = config.currencyKey
	end

	if not window then
		CreateWindow()
	end

	window:Show()
	self:Refresh(true)
	window:Raise()
end

function Chart:IsShown()
	return window and window:IsShown()
end

function Chart:OnBalanceUpdated(update)
	if not self:IsShown() or refreshPending then
		return
	end

	if not update.currencies and Scope() == "character" and selectedOwner ~= AWL.Utils:GetCharacterGUID() then
		return
	end

	local affected = update.currencies or selectedCurrency == "gold" and update.gold
		or update.currencyID and selectedCurrency and tonumber(selectedCurrency:sub(3)) == update.currencyID
	if not affected then
		return
	end

	refreshPending = true
	C_Timer.After(0, function()
		refreshPending = false

		if Chart:IsShown() then
			Chart:Refresh(true)
		end
	end)
end
