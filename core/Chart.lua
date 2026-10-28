local addonName, AUR = ...

if AUR.State and AUR.State.libraryIncompatible then return end

local AWL = ArcaneWizardLibrary
local Addon = AWL:GetAddon(addonName)
local L = AUR.Localization
local Chart = AUR.Modules.Chart
local Utils = AUR.Modules.Utils
local CurrencyMenu = AUR.Modules.CurrencyMenu
local WowToken = AUR.Modules.WowToken
local ChartData = AUR.CHART_DATA
local ChartConfig = AUR.UIConfig.Chart
local OverviewConfig = AUR.UIConfig.Overview

---@class AurariumChartWindow: ArcaneWizardLibraryWindowFrame
---@field inset ArcaneWizardLibraryInsetFrame
---@field footerCloseButton Button
---@field artwork Texture
local ChartFrame = nil

local PlotFrame = nil
local ScopeGroupFrame = nil
local CharacterDropdownFrame = nil
local CurrencyDropdownFrame = nil
local PeriodDropdownFrame = nil
local CharacterLabel = nil
local FirstInputFrame = nil
local LastInputFrame = nil
local ApplyButtonFrame = nil
local StatusText = nil
local CaptionText = nil
local CustomPanelFrame = nil
local CustomButtonFrame = nil
local SummaryTexts = {}
local selectedOwner = nil
local selectedCurrency = "gold"
local selectedCurrencyIcon = nil
local lastCharacterKey = nil
local selectedPeriod = ChartData.defaultPeriod
local history = nil
local points = nil
local rangeFirst = nil
local rangeLast = nil
local minimum = nil
local maximum = nil
local refreshPending = false
local ChartLines, AxisLabels, GridTextures = {}, {}, {}
local LineJoinTextures = {}

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
	local padding = math.max(
		(maximum - minimum) * ChartConfig.axisPadding,
		minimum == maximum and maximum * ChartConfig.flatAxisPadding or 0,
		1
	)

	local lower, upper = math.max(0, minimum - padding), maximum + padding
	local targetStep = math.max((upper - lower) / ChartConfig.gridSteps, 1)
	local magnitude = 10 ^ math.floor(math.log10(targetStep))
	local first, last = lower, upper

	for _, multiplier in ipairs(ChartConfig.axisStepMultipliers) do
		local step = magnitude * multiplier
		first = math.floor(lower / step) * step
		last = first + ChartConfig.gridSteps * step

		if step >= targetStep and last >= upper then
			break
		end
	end

	return first, last
end

function Chart:GetRange(config)
	local today = Utils:GetToday()
	local days = ChartData.days[config.period]

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
	if scope == "token" then
		return WowToken:IsSupported() and WowToken:GetHistory() or {}
	end
	if currencyKey == "token" then return {} end

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
	local index = 1
	local value = nil

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

function Chart:GetDateTicks(first, last, limit)
	if first == last then return {first} end

	local days = self:GetDayOffset(first, last)
	local steps = math.min(days, math.max(2, math.floor(limit)) - 1)
	local ticks = {}

	for i = 0, steps do
		ticks[#ticks + 1] = ShiftDate(first, math.floor(days * i / steps + 0.5))
	end

	return ticks
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
	if selectedOwner == "account" or selectedOwner == "warband" or selectedOwner == "token" then return selectedOwner end

	return "character"
end

local function FormatAmount(value)
	local sign = value < 0 and "-" or ""
	value = math.abs(value)

	if selectedCurrency == "token" then
		return sign .. string.format(OverviewConfig.tokenPriceFormat, BreakUpLargeNumbers(math.floor(value / 10000)))
	end

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
	for _, unit in ipairs(ChartConfig.axisUnits) do
		if value >= unit.value then
			local scaled = value / unit.value

			return unit.value, L[unit.label], scaled < 10 and 2 or scaled < 100 and 1 or 0
		end
	end

	return 1, "", 0
end

local function FormatAxis(value)
	if selectedCurrency == "gold" or selectedCurrency == "token" then
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
	local scale = (selectedCurrency == "gold" or selectedCurrency == "token") and 10000 or 1
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
	local previousRealm = nil
	local children = nil

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

local function CreateLineTexture(path)
	local texture = PlotFrame:CreateTexture(nil, "ARTWORK")
	texture:SetTexture(Addon:GetMediaPath(path), "CLAMP", "CLAMP", "LINEAR")
	texture:SetVertexColor(unpack(ChartConfig.lineColor))
	texture:SetBlendMode("BLEND")
	texture:SetSnapToPixelGrid(false)
	texture:SetTexelSnappingBias(0)

	return texture
end

local function DrawLine(config)
	local dx, dy = config.x2 - config.x1, config.y2 - config.y1
	local length = math.sqrt(dx * dx + dy * dy)

	if length == 0 then return end

	local radius = ChartConfig.lineThickness * config.pixel
	local halfLength, halfX, halfY = length / 2, dx / 2, dy / 2
	local normalX, normalY = -dy / length * radius, dx / length * radius
	local line = ChartLines[config.index]

	if not line then
		line = CreateLineTexture(ChartConfig.lineTexture)
		ChartLines[config.index] = line
	end

	line:ClearAllPoints()
	line:SetPoint("CENTER", PlotFrame, "BOTTOMLEFT", config.x1 + halfX, config.y1 + halfY)
	line:SetSize(length, radius * 2)
	line:SetVertexOffset(1, halfLength - halfX + normalX, -halfY + normalY - radius)
	line:SetVertexOffset(2, halfLength - halfX - normalX, -halfY - normalY + radius)
	line:SetVertexOffset(3, halfX + normalX - halfLength, halfY + normalY - radius)
	line:SetVertexOffset(4, halfX - normalX - halfLength, halfY - normalY + radius)
	line:Show()
end

local function DrawLineJoin(config)
	local join = LineJoinTextures[config.index]

	if not join then
		join = CreateLineTexture(ChartConfig.lineJoinTexture)
		LineJoinTextures[config.index] = join
	end

	local size = ChartConfig.lineThickness * config.pixel * 2
	join:ClearAllPoints()
	join:SetPoint("CENTER", PlotFrame, "BOTTOMLEFT", config.x, config.y)
	join:SetSize(size, size)
	join:Show()
end

local function DrawGridLine(config)
	local texture = GridTextures[config.index]

	if not texture then
		texture = PlotFrame:CreateTexture(nil, "BACKGROUND")
		GridTextures[config.index] = texture
	end

	local pixel = PixelUtil.GetPixelToUIUnitFactor() / PlotFrame:GetEffectiveScale()
	local left, bottom = PlotFrame:GetLeft(), PlotFrame:GetBottom()
	local x = math.floor((left + config.x) / pixel + 0.5) * pixel - left
	local y = math.floor((bottom + config.y) / pixel + 0.5) * pixel - bottom
	local right = math.floor((left + config.x + config.width) / pixel + 0.5) * pixel - left
	local top = math.floor((bottom + config.y + config.height) / pixel + 0.5) * pixel - bottom
	texture:ClearAllPoints()
	texture:SetPoint("BOTTOMLEFT", PlotFrame, "BOTTOMLEFT", x, y)
	texture:SetSize(math.max(pixel, right - x), math.max(pixel, top - y))
	texture:SetColorTexture(unpack(config.color))
	texture:SetDrawLayer("BACKGROUND", config.color == ChartConfig.grid.axisColor and 1 or 0)
	texture:Show()

	return x, y
end

local function Coordinates(point)
	local days = Chart:GetDayOffset(rangeFirst, rangeLast)
	local x = days > 0 and Chart:GetDayOffset(rangeFirst, point.date) / days * PlotFrame:GetWidth() or PlotFrame:GetWidth() / 2
	local y = (point.value - minimum) / (maximum - minimum) * PlotFrame:GetHeight()

	return x, y
end

local function ClearHover()
	PlotFrame.cursor:Hide()
	PlotFrame.hoverPoint:Hide()
	PlotFrame.hoverIndex = nil

	if GameTooltip:IsOwned(PlotFrame) then
		GameTooltip:Hide()
	end
end

local function UpdateHover()
	if not points or #points == 0 then
		return
	end

	local cursorX = GetCursorPosition()
	local x = cursorX / PlotFrame:GetEffectiveScale() - PlotFrame:GetLeft()
	local days = Chart:GetDayOffset(rangeFirst, rangeLast)
	local offset = math.floor(math.max(0, math.min(1, x / PlotFrame:GetWidth())) * days + 0.5)
	local index = offset - Chart:GetDayOffset(rangeFirst, points[1].date) + 1

	if index < 1 or index > #points then
		ClearHover()

		return
	end

	if PlotFrame.hoverIndex == index then
		return
	end

	PlotFrame.hoverIndex = index

	local point = points[index]
	local px, py = Coordinates(point)

	PlotFrame.cursor:ClearAllPoints()
	PlotFrame.cursor:SetPoint("BOTTOMLEFT", PlotFrame, "BOTTOMLEFT", px, 0)
	PlotFrame.cursor:SetSize(ChartConfig.gridThickness, PlotFrame:GetHeight())
	PlotFrame.cursor:Show()

	PlotFrame.hoverPoint:ClearAllPoints()
	PlotFrame.hoverPoint:SetPoint("CENTER", PlotFrame, "BOTTOMLEFT", px, py)
	PlotFrame.hoverPoint:Show()

	GameTooltip:SetOwner(PlotFrame, "ANCHOR_NONE")
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint("BOTTOMLEFT", PlotFrame.hoverPoint, "TOPRIGHT", ChartConfig.tooltipGap, ChartConfig.tooltipGap)
	GameTooltip:SetClampedToScreen(true)
	GameTooltip:SetText(
		Chart:FormatDate(point.date), ChartConfig.normalColor[1], ChartConfig.normalColor[2], ChartConfig.normalColor[3]
	)
	GameTooltip:AddLine(FormatAmount(point.value), 1, 1, 1)
	GameTooltip:Show()
end

local function DrawChart()
	ClearHover()

	for _, line in pairs(ChartLines) do
		line:Hide()
	end

	for _, line in pairs(LineJoinTextures) do
		line:Hide()
	end

	for _, line in ipairs(GridTextures) do
		line:Hide()
	end

	for _, label in ipairs(AxisLabels) do
		label:Hide()
	end

	PlotFrame.singlePoint:Hide()
	PlotFrame.empty:SetText(L[Scope() == "token" and "wow-token.no-data" or "chart.no-data"])
	PlotFrame.empty:SetShown(not points or #points == 0)

	if not points or #points == 0 then
		for _, value in ipairs(SummaryTexts) do
			value:SetText("-")
			value:SetTextColor(unpack(ChartConfig.normalColor))
		end

		return
	end

	minimum, maximum = points[1].value, points[1].value

	for _, point in ipairs(points) do
		minimum, maximum = math.min(minimum, point.value), math.max(maximum, point.value)
	end

	minimum, maximum = GetReadableAxisBounds(minimum, maximum)

	local width, height = PlotFrame:GetWidth(), PlotFrame:GetHeight()
	local gridIndex = 0

	for i = 0, ChartConfig.gridSteps do
		local fraction = i / ChartConfig.gridSteps
		gridIndex = gridIndex + 1

		local _, y = DrawGridLine({
			index = gridIndex,
			x = 0,
			y = fraction * height,
			width = width,
			height = 0,
			color = (i == 0 or i == ChartConfig.gridSteps) and ChartConfig.grid.axisColor or ChartConfig.grid.horizontalColor
		})
		gridIndex = gridIndex + 1
		DrawGridLine({
			index = gridIndex,
			x = -ChartConfig.grid.tickLength,
			y = fraction * height,
			width = ChartConfig.grid.tickLength,
			height = 0,
			color = ChartConfig.grid.axisColor
		})

		local label = AxisLabels[i + 1]
		label:ClearAllPoints()
		label:SetPoint("RIGHT", PlotFrame, "BOTTOMLEFT", -ChartConfig.axisGap.x, y)
		label:SetText(FormatAxis(minimum + fraction * (maximum - minimum)))
		label:Show()
	end

	local shortDates = rangeFirst:sub(1, 4) == rangeLast:sub(1, 4)
	local sample = AxisLabels[ChartConfig.gridSteps + 2]
	sample:SetText(Chart:FormatDate(rangeFirst, shortDates))

	local textWidth = sample:GetUnboundedStringWidth()
	sample:SetText(Chart:FormatDate(rangeLast, shortDates))
	textWidth = math.max(textWidth, sample:GetUnboundedStringWidth())

	local labelSpacing = 1.5 * textWidth + ChartConfig.dateAxis.labelGap
	local labelLimit = math.max(2, math.min(ChartConfig.dateAxis.maximumLabels, math.floor(width / labelSpacing) + 1))
	local ticks = Chart:GetDateTicks(rangeFirst, rangeLast, labelLimit)

	for i, day in ipairs(ticks) do
		gridIndex = gridIndex + 1
		local isEdge = #ticks > 1 and (i == 1 or i == #ticks)

		local x = DrawGridLine({
			index = gridIndex,
			x = #ticks > 1 and (i - 1) / (#ticks - 1) * width or width / 2,
			y = 0,
			width = 0,
			height = height,
			color = isEdge and ChartConfig.grid.axisColor or ChartConfig.grid.verticalColor
		})

		local label = AxisLabels[ChartConfig.gridSteps + 1 + i]
		label:ClearAllPoints()

		local anchor = "TOP"

		if #ticks > 1 then
			if i == 1 then
				anchor = "TOPLEFT"
			elseif i == #ticks then
				anchor = "TOPRIGHT"
			end
		end

		label:SetPoint(anchor, PlotFrame, "BOTTOMLEFT", x, -ChartConfig.axisGap.y)
		label:SetText(Chart:FormatDate(day, shortDates))
		label:Show()
	end

	if #ticks == 1 then
		for i = 0, 1 do
			DrawGridLine({
				index = gridIndex + i + 1,
				x = i * width,
				y = 0,
				width = 0,
				height = height,
				color = ChartConfig.grid.axisColor
			})
		end
	end

	local pixel = PixelUtil.GetPixelToUIUnitFactor() / PlotFrame:GetEffectiveScale()
	local firstX = Coordinates(points[1])
	local lastX = Coordinates(points[#points])
	local spacing = math.max(ChartConfig.pointSpacing, ChartConfig.pointSpacing * pixel)
	local pointLimit = math.min(ChartConfig.maxSegments, math.floor((lastX - firstX) / spacing) + 1)
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

	if #reduced > 1 then
		for i, point in ipairs(reduced) do
			local x, y = Coordinates(point)
			local needsJoin = i == 1 or i == #reduced

			if not needsJoin then
				local x1, y1 = Coordinates(reduced[i - 1])
				local x2, y2 = Coordinates(reduced[i + 1])
				needsJoin = math.abs((x - x1) * (y2 - y) - (y - y1) * (x2 - x)) > 0.000001
			end

			if needsJoin then
				DrawLineJoin({index = i, x = x, y = y, pixel = pixel})
			end
		end
	end

	if #points == 1 then
		local x, y = Coordinates(points[1])
		PlotFrame.singlePoint:ClearAllPoints()
		PlotFrame.singlePoint:SetPoint("CENTER", PlotFrame, "BOTTOMLEFT", x, y)
		PlotFrame.singlePoint:Show()
	end

	local first, last = points[1].value, points[#points].value
	local change = last - first
	SummaryTexts[1]:SetText(FormatAmount(first))
	SummaryTexts[2]:SetText(FormatAmount(last))
	SummaryTexts[3]:SetText((change > 0 and "+" or "") .. FormatAmount(change))
	SummaryTexts[3]:SetTextColor(unpack(
		change > 0 and ChartConfig.positiveColor or change < 0 and ChartConfig.errorColor or ChartConfig.normalColor
	))
end

local function CreateScopeGroup(sidebar)
	local scopes = {
		{label = L["currency-overview.tab.character"], value = "character"},
		{label = L["currency-overview.tab.account"], value = "account"}
	}

	if AWL.GAME_TYPE_RETAIL then
		scopes[#scopes + 1] = {label = L["currency-overview.tab.warband"], value = "warband"}
	end

	if WowToken:IsSupported() then
		scopes[#scopes + 1] = {label = L["wow-token.title"], value = "token"}
	end

	ScopeGroupFrame = AWL.Controls:CreateOptionGroup({
		parent = sidebar,
		width = ChartConfig.sidebar.controlWidth,
		options = scopes,
		selectedValue = "character",
		onValueChanged = function(value)
			selectedOwner = value == "character" and (lastCharacterKey or AWL.Utils:GetCharacterGUID()) or value
			Chart:Refresh(true)
		end
	})
	ScopeGroupFrame:SetPoint("TOPLEFT", ChartConfig.margin, -ChartConfig.sidebar.scopeTop)
end

function Chart:Refresh(rebuildHistory)
	if not ChartFrame then
		return
	end

	if selectedOwner == "warband" and not AWL.GAME_TYPE_RETAIL
		or selectedOwner == "token" and not WowToken:IsSupported()
		or Scope() == "character" and not Utils:GetCharacterEntry(selectedOwner)
	then
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

	if WowToken:IsSupported() and not ScopeGroupFrame.buttonsByValue.token then
		local sidebar = ScopeGroupFrame:GetParent()
		ScopeGroupFrame:Hide()
		CreateScopeGroup(sidebar)
	end

	ScopeGroupFrame:SetValue(Scope())
	local characterEnabled = Scope() == "character" and lastCharacterKey ~= nil
	CharacterLabel:SetText(L[Scope() == "token" and "wow-token.region" or "currency-overview.tab.character"])
	CharacterDropdownFrame:SetDefaultText(Scope() == "token" and L["wow-token.region"] .. ": " .. WowToken:GetRegionName() or "-")
	CharacterDropdownFrame:SetValue(characterEnabled and lastCharacterKey or nil)
	CharacterDropdownFrame:SetEnabled(characterEnabled)

	local options = CurrencyMenu:GetOptions(Scope())

	if Scope() == "token" then
		options = {{label = L["wow-token.title"], value = "token"}}
	end

	local option = FindOption(options, selectedCurrency) or FindOption(options)
	local nextCurrency = option and option.value
	selectedCurrencyIcon = option and option.icon

	if selectedCurrency ~= nextCurrency then
		selectedCurrency = nextCurrency
		rebuildHistory = true
	end

	CurrencyDropdownFrame:SetDefaultText(L[Scope() == "token" and "wow-token.title" or "chart.currency"])
	CurrencyDropdownFrame:SetOptions(options)
	CurrencyDropdownFrame:SetValue(selectedCurrency)
	CurrencyDropdownFrame:SetEnabled(Scope() ~= "token")
	local caption = option and option.label or ""

	if Scope() == "token" then
		caption = caption .. " (" .. WowToken:GetRegionName() .. ")"
	end

	CaptionText:SetText(option and caption .. " - " .. L["chart.period." .. selectedPeriod] or "")

	if rebuildHistory or not history then
		history = selectedCurrency and self:GetHistory(Scope(), selectedOwner, selectedCurrency) or {}
	end

	local errorKey = nil
	rangeFirst, rangeLast, errorKey = self:GetRange({
		period = selectedPeriod,
		history = history,
		first = FirstInputFrame:GetText(),
		last = LastInputFrame:GetText()
	})

	local custom = selectedPeriod == "custom"
	FirstInputFrame:SetEnabled(custom)
	LastInputFrame:SetEnabled(custom)
	ApplyButtonFrame:SetEnabled(custom)
	CustomButtonFrame:SetEnabled(not custom)
	CustomPanelFrame:SetShown(custom)

	if not rangeFirst then
		local message = L["chart.error." .. errorKey]

		if errorKey == "date" then
			message = string.format(message, Utils:GetDateFormatHint())
		end

		StatusText:SetText(message)
		points = {}
	else
		StatusText:SetText("")

		if not custom then
			FirstInputFrame:SetText(self:FormatDate(rangeFirst))
			LastInputFrame:SetText(self:FormatDate(rangeLast))
		end

		points = self:GetSeries(history, rangeFirst, rangeLast)
	end

	DrawChart()
end

function Chart:RefreshDateFormat()
	if not ChartFrame then return end

	for _, input in ipairs({FirstInputFrame, LastInputFrame}) do
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
	sidebar:SetWidth(ChartConfig.sidebar.width)
	sidebar:SetPoint("TOPLEFT", 0, 0)
	sidebar:SetPoint("BOTTOMLEFT", 0, 0)
	Label(sidebar, L["chart.scope"]):SetPoint("TOPLEFT", ChartConfig.margin, -ChartConfig.margin)

	CreateScopeGroup(sidebar)

	CharacterDropdownFrame = AWL.Controls:CreateDropdown({
		parent = sidebar,
		width = ChartConfig.sidebar.controlWidth,
		options = CharacterOptions,
		onValueChanged = function(value)
			selectedOwner = value
			Chart:Refresh(true)
		end
	})
	CharacterDropdownFrame:SetDefaultText(L["currency-overview.tab.character"])
	CharacterDropdownFrame:SetPoint("TOPLEFT", ChartConfig.margin, -ChartConfig.sidebar.characterTop)
	CharacterLabel = Label(sidebar, L["currency-overview.tab.character"])
	CharacterLabel:SetPoint("BOTTOMLEFT", CharacterDropdownFrame, "TOPLEFT", 0, ChartConfig.labelGap)

	CurrencyDropdownFrame = AWL.Controls:CreateDropdown({
		parent = sidebar,
		width = ChartConfig.sidebar.controlWidth,
		options = {},
		onValueChanged = function(value)
			selectedCurrency = value
			Chart:Refresh(true)
			CurrencyDropdownFrame:CloseMenu()
		end
	})
	CurrencyDropdownFrame:SetupMenu(function(owner, root)
		if Scope() == "token" then return end

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
	CurrencyDropdownFrame:SetDefaultText(L["chart.currency"])
	CurrencyDropdownFrame:SetEmptyText(L["chart.no-currencies"])
	CurrencyDropdownFrame:SetPoint("TOPLEFT", ChartConfig.margin, -ChartConfig.sidebar.currencyTop)
	Label(sidebar, L["chart.currency"]):SetPoint("BOTTOMLEFT", CurrencyDropdownFrame, "TOPLEFT", 0, ChartConfig.labelGap)

	local periods = {}

	for _, period in ipairs(ChartData.periods) do
		periods[#periods + 1] = {label = L["chart.period." .. period], value = period}
	end

	PeriodDropdownFrame = AWL.Controls:CreateDropdown({
		parent = sidebar,
		width = ChartConfig.sidebar.controlWidth,
		options = periods,
		selectedValue = selectedPeriod,
		onValueChanged = function(value)
			selectedPeriod = value
			Chart:Refresh()
		end
	})
	PeriodDropdownFrame:SetPoint("TOPLEFT", ChartConfig.margin, -ChartConfig.sidebar.periodTop)
	Label(sidebar, L["chart.period"]):SetPoint("BOTTOMLEFT", PeriodDropdownFrame, "TOPLEFT", 0, ChartConfig.labelGap)

	CustomButtonFrame = AWL.Controls:CreateButton({
		parent = sidebar,
		width = ChartConfig.sidebar.buttonWidth,
		label = L["chart.period.custom"],
		onClick = function()
			selectedPeriod = "custom"
			PeriodDropdownFrame:SetValue(selectedPeriod)
			Chart:Refresh()
			FirstInputFrame:SetFocus()
		end
	})
	CustomButtonFrame:SetWidth(math.max(
		ChartConfig.sidebar.buttonWidth,
		CustomButtonFrame:GetFontString():GetUnboundedStringWidth() + ChartConfig.sidebar.buttonTextPadding
	))
	CustomButtonFrame:SetPoint("TOPLEFT", ChartConfig.margin, -ChartConfig.sidebar.customButtonTop)

	CustomPanelFrame = CreateFrame("Frame", nil, sidebar)
	CustomPanelFrame:SetSize(ChartConfig.sidebar.controlWidth, ChartConfig.sidebar.customPanelHeight)
	CustomPanelFrame:SetPoint("TOPLEFT", ChartConfig.margin, -ChartConfig.sidebar.customPanelTop)

	local function ApplyRange()
		Chart:RefreshDateFormat()
	end

	FirstInputFrame = AWL.Controls:CreateInput({
		parent = CustomPanelFrame,
		width = ChartConfig.sidebar.inputWidth,
		text = "",
		placeholder = Utils:GetDateFormatHint(),
		maxLetters = 10,
		onEnterPressed = ApplyRange
	})
	FirstInputFrame:SetPoint("TOPLEFT", ChartConfig.sidebar.inputLeft, -ChartConfig.sidebar.firstInputTop)
	Label(CustomPanelFrame, L["chart.from"]):SetPoint("BOTTOMLEFT", FirstInputFrame, "TOPLEFT", -ChartConfig.sidebar.inputLeft, ChartConfig.labelGap)

	LastInputFrame = AWL.Controls:CreateInput({
		parent = CustomPanelFrame,
		width = ChartConfig.sidebar.inputWidth,
		text = "",
		placeholder = Utils:GetDateFormatHint(),
		maxLetters = 10,
		onEnterPressed = ApplyRange
	})
	LastInputFrame:SetPoint("TOPLEFT", ChartConfig.sidebar.inputLeft, -ChartConfig.sidebar.lastInputTop)
	Label(CustomPanelFrame, L["chart.to"]):SetPoint("BOTTOMLEFT", LastInputFrame, "TOPLEFT", -ChartConfig.sidebar.inputLeft, ChartConfig.labelGap)

	ApplyButtonFrame = AWL.Controls:CreateButton({
		parent = CustomPanelFrame,
		width = ChartConfig.sidebar.buttonWidth,
		label = L["chart.apply"],
		onClick = ApplyRange
	})
	ApplyButtonFrame:SetWidth(math.max(
		ChartConfig.sidebar.buttonWidth,
		ApplyButtonFrame:GetFontString():GetUnboundedStringWidth() + ChartConfig.sidebar.buttonTextPadding
	))
	ApplyButtonFrame:SetPoint("TOPLEFT", 0, -ChartConfig.sidebar.applyTop)

	StatusText = Label(CustomPanelFrame, "")
	StatusText:SetTextColor(unpack(ChartConfig.errorColor))
	StatusText:SetPoint("TOPLEFT", 0, -ChartConfig.sidebar.statusTop)
	StatusText:SetWidth(ChartConfig.sidebar.controlWidth)
	StatusText:SetWordWrap(true)
end

local function CreateSummary(parent)
	local width = (parent:GetWidth() - ChartConfig.summary.gap * (#ChartConfig.summary.keys - 1)) / #ChartConfig.summary.keys

	for index, key in ipairs(ChartConfig.summary.keys) do
		local panel = CreateFrame("Frame", nil, parent)
		panel:SetSize(width, ChartConfig.summary.height)
		panel:SetPoint("TOPLEFT", (index - 1) * (width + ChartConfig.summary.gap), -ChartConfig.summary.top)

		local label = Label(panel, L["chart.summary." .. key])
		label:SetPoint("TOP", 0, -ChartConfig.summary.labelTop)

		local value = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
		value:SetPoint("TOPLEFT", 0, -ChartConfig.summary.valueTop)
		value:SetPoint("TOPRIGHT", 0, -ChartConfig.summary.valueTop)
		value:SetHeight(ChartConfig.summary.valueHeight)
		value:SetJustifyH("CENTER")
		SummaryTexts[index] = value
	end
end

local function CreateWindow()
	local ArtworkConfig = ChartConfig.artwork
	local windowConfig = AWL.Utils:CopyTable(OverviewConfig.window)
	windowConfig.addonName = addonName
	windowConfig.width = ArtworkConfig.width
	windowConfig.height = ArtworkConfig.height
	windowConfig.title = addonName .. " - " .. L["chart.title"]

	ChartFrame = AWL.Frames:CreateWindow(windowConfig) --[[@as AurariumChartWindow]]
	ChartFrame:SetFrameStrata("HIGH")
	ChartFrame.portrait:SetPoint("TOPLEFT", OverviewConfig.portrait.x, OverviewConfig.portrait.y)
	ChartFrame.portrait:SetTexture(Addon:GetMediaPath("icon-round.tga"))
	ChartFrame:SetScript("OnHide", function(self)
		self:StopMovingOrSizing()
	end)

	local insetConfig = AWL.Utils:CopyTable(OverviewConfig.inset)
	insetConfig.parent = ChartFrame
	insetConfig.width = ArtworkConfig.artworkRight - ArtworkConfig.artworkLeft
	insetConfig.height = ArtworkConfig.height - ArtworkConfig.artworkTop - OverviewConfig.inset.bottom
	insetConfig.backgroundStyle = ChartConfig.inset.backgroundStyle

	ChartFrame.inset = AWL.Frames:CreateInset(insetConfig)
	ChartFrame.inset:SetPoint("TOPLEFT", ArtworkConfig.artworkLeft, -ArtworkConfig.artworkTop)

	ChartFrame.footerCloseButton = AWL.Controls:CreateButton({
		parent = ChartFrame,
		width = ChartConfig.footer.buttonWidth,
		label = CLOSE,
		onClick = function()
			ChartFrame:Hide()
		end
	})
	ChartFrame.footerCloseButton:SetWidth(math.max(
		ChartConfig.footer.buttonWidth,
		ChartFrame.footerCloseButton:GetFontString():GetUnboundedStringWidth() + ChartConfig.footer.buttonTextPadding
	))
	ChartFrame.footerCloseButton:SetPoint("TOPRIGHT", ChartFrame.inset, "BOTTOMRIGHT", -OverviewConfig.buttonOffset.x, OverviewConfig.buttonOffset.y)

	local body = ChartFrame.content
	body:ClearAllPoints()
	body:SetPoint("TOPLEFT", ArtworkConfig.bodyLeft, -ArtworkConfig.bodyTop)
	body:SetPoint("BOTTOMRIGHT", ArtworkConfig.bodyRight - ArtworkConfig.width, ArtworkConfig.height - ArtworkConfig.bodyBottom)

	ChartFrame.artwork = body:CreateTexture(nil, "BACKGROUND")
	ChartFrame.artwork:SetPoint("TOPLEFT", ChartFrame, "TOPLEFT", ArtworkConfig.artworkLeft, -ArtworkConfig.artworkTop)
	ChartFrame.artwork:SetPoint(
		"BOTTOMRIGHT", ChartFrame, "BOTTOMRIGHT",
		ArtworkConfig.artworkRight - ArtworkConfig.width,
		ArtworkConfig.height - ArtworkConfig.artworkBottom
	)
	ChartFrame.artwork:SetTexture(Addon:GetMediaPath(ChartConfig.window.texture))

	local textureScale = ArtworkConfig.textureScale / ArtworkConfig.textureSize
	ChartFrame.artwork:SetTexCoord(
		ArtworkConfig.artworkLeft * textureScale,
		ArtworkConfig.artworkRight * textureScale,
		ArtworkConfig.artworkTop * textureScale,
		ArtworkConfig.artworkBottom * textureScale
	)

	CreateSidebar(body)

	local chartPanel = CreateFrame("Frame", nil, body)
	chartPanel:SetPoint("TOPLEFT", ArtworkConfig.chartLeft - ArtworkConfig.bodyLeft, 0)
	chartPanel:SetPoint("BOTTOMRIGHT", ArtworkConfig.chartRight - ArtworkConfig.bodyRight, 0)

	CaptionText = Label(chartPanel, "")
	CaptionText:SetFontObject("GameFontNormalLarge")
	CaptionText:SetPoint("TOPLEFT", 0, -ChartConfig.header.top)
	CaptionText:SetHeight(ChartConfig.header.height)
	CaptionText:SetWordWrap(false)

	CreateSummary(chartPanel)

	PlotFrame = CreateFrame("Frame", nil, chartPanel)
	PlotFrame:SetPoint("TOPLEFT", ChartConfig.plot.left, -ChartConfig.plot.top)
	PlotFrame:SetPoint("BOTTOMRIGHT", -ChartConfig.plot.right, ChartConfig.plot.bottom)

	PlotFrame.empty = Label(PlotFrame, L["chart.no-data"])
	PlotFrame.empty:SetPoint("LEFT", ChartConfig.margin, 0)
	PlotFrame.empty:SetPoint("RIGHT", -ChartConfig.margin, 0)
	PlotFrame.empty:SetJustifyH("CENTER")
	PlotFrame.empty:SetWordWrap(true)

	for i = 1, ChartConfig.gridSteps + 1 + ChartConfig.dateAxis.maximumLabels do
		AxisLabels[i] = Label(chartPanel, "")
		AxisLabels[i]:SetFontObject("GameFontHighlightSmall")
	end

	for _, key in ipairs({"singlePoint", "hoverPoint", "cursor"}) do
		PlotFrame[key] = PlotFrame:CreateTexture(nil, "OVERLAY")
		PlotFrame[key]:SetColorTexture(unpack(ChartConfig.lineColor))
		PlotFrame[key]:SetSize(ChartConfig.pointSize, ChartConfig.pointSize)
		PlotFrame[key]:Hide()
	end

	PlotFrame:EnableMouse(true)
	PlotFrame:SetScript("OnEnter", function(self)
		self:SetScript("OnUpdate", UpdateHover)
	end)

	local function StopHover(self)
		self:SetScript("OnUpdate", nil)
		ClearHover()
	end

	PlotFrame:SetScript("OnLeave", StopHover)
	PlotFrame:SetScript("OnHide", StopHover)

	local infoButton = CreateFrame("Button", nil, chartPanel, "UIPanelInfoButton")
	infoButton:SetSize(ArtworkConfig.infoSize, ArtworkConfig.infoSize)
	infoButton:SetPoint("TOPLEFT", ArtworkConfig.infoLeft - ArtworkConfig.chartLeft, ArtworkConfig.bodyTop - ArtworkConfig.infoTop)

	CaptionText:SetPoint("TOPRIGHT", -ArtworkConfig.infoSize - ChartConfig.header.infoGap, -ChartConfig.header.top)

	infoButton:SetScript("OnEnter", function(self)
		local r, g, b = NORMAL_FONT_COLOR:GetRGB()
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText(L["chart.title"], unpack(ChartConfig.normalColor))
		GameTooltip:AddLine(L[Scope() == "token" and "wow-token.history-note" or "chart.history-note"], r, g, b, true)
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

	if config.scope == "account" or config.scope == "warband" or config.scope == "token" then
		selectedOwner = config.scope
	elseif config.characterKey then
		selectedOwner = config.characterKey
	end

	selectedOwner = selectedOwner or AWL.Utils:GetCharacterGUID()

	if config.currencyKey then
		selectedCurrency = config.currencyKey
	end

	if not ChartFrame then
		CreateWindow()
	end

	ChartFrame:Show()
	self:Refresh(true)
	ChartFrame:Raise()
end

function Chart:IsShown()
	return ChartFrame and ChartFrame:IsShown()
end

function Chart:OnBalanceUpdated(update)
	if not self:IsShown() or Scope() == "token" or refreshPending then
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

function Chart:OnTokenUpdated()
	if not self:IsShown() then return end

	if Scope() == "token" or not ScopeGroupFrame.buttonsByValue.token then
		self:Refresh(true)
	end
end
