local addonName, AUR = ...

-- Library
local AWL = ArcaneWizardLibrary
local Addon = AWL:GetAddon(addonName)

-- Localization
local L = AUR.Localization

-- Current module
local Overview = AUR.Modules.Overview

-- Module imports
local Utils = AUR.Modules.Utils
local CurrencyMenu = AUR.Modules.CurrencyMenu
local OverviewData = AUR.OVERVIEW_DATA
local TabIndex = OverviewData.tabIndices

-- Variables
local selectedCharacterKey
local currentMonthOffset = {}
local selectedCurrency = {}
selectedCurrency[TabIndex.character] = "gold"
selectedCurrency[TabIndex.account] = "gold"
selectedCurrency[TabIndex.warband] = "w-2032"

--------------
--- Frames ---
--------------

local OverviewFrame
local OverviewScrollFrames = {}

-----------------------
--- Local Functions ---
-----------------------

local function GetYearMonthString(offset)
	local now = time()
	local year = tonumber(date("%Y", now))
	local month = tonumber(date("%m", now))

	month = month - offset

	while month < 1 do
		month = month + 12
		year = year - 1
	end

	while month > 12 do
		month = month - 12
		year = year + 1
	end

	return string.format("%04d-%02d", year, month)
end

local function FormatMonthText(prefix)
	local year, month = strsplit("-", prefix)

	if not month or not year then return prefix end

	local key = AUR.MONTH_KEYS[tonumber(month)]

	return string.format("%s %s", L[key], year)
end

local function FormatGold(copper)
	local gold = floor(copper / (100 * 100))
	local silver = floor((copper / 100) % 100)
	local copper = copper % 100

	return string.format("%s |T237618:0|t %02d |T237620:0|t %02d |T237617:0|t", BreakUpLargeNumbers(gold), silver, copper)
end

local function FormatGoldDiff(diff)
	local sign = diff > 0 and "+" or diff < 0 and "-" or "±"
	local absVal = math.abs(diff)

	return sign .. " " .. FormatGold(absVal)
end

local function FormatCurrency(val, selectedCurrency)
	local v = val or 0

	if selectedCurrency == "gold" then
		return FormatGold(v)
	else
		return BreakUpLargeNumbers(v)
	end
end

local function FormatCurrencyDiff(diff, selectedCurrency)
	local d = diff or 0

	if selectedCurrency == "gold" then
		return FormatGoldDiff(d)
	else
		local sign = (d > 0 and "+" or d == 0 and "±" or "")

		return sign .. BreakUpLargeNumbers(d)
	end
end

local function BuildGenericHistory(rawData, currencyKey)
	local entries = {}
	local lastValue = 0
	local dates = AUR.Data.dates
	local startIndex = nil

	for i, date in ipairs(dates) do
		local dayData = rawData[date] or {}
		local v = dayData[currencyKey]

		if v ~= nil then
			startIndex = i
			break
		end
	end

	if not startIndex then
		return entries
	end

	for i = startIndex, #dates do
		local date = dates[i]
		local dayData = rawData[date] or {}
		local value = dayData[currencyKey]

		if value == nil then
			value = lastValue
		end

		table.insert(entries, {date = date, value = value})
		lastValue = value
	end

	table.sort(entries, function(a,b) return a.date < b.date end)

	return entries
end

local function BuildGenericHistoryLookup(rawData, currencyKey)
	local entries = {}
	local lastValue = 0
	local dates = AUR.Data.dates
	local startIndex = nil

	for i, date in ipairs(dates) do
		local dayData = rawData[date] or {}
		local v = dayData[currencyKey]

		if v ~= nil then
			startIndex = i
			break
		end
	end

	if not startIndex then
		return entries
	end

	for i = startIndex, #dates do
		local date = dates[i]
		local dayData = rawData[date] or {}
		local value = dayData[currencyKey]

		if value == nil then
			value = lastValue
		end

		entries[date] = value
		lastValue = value
	end

	return entries
end

local function BuildCharacterHistory(characterKey, currencyKey)
	local entry = Utils:GetCharacterEntry(characterKey)

	return entry and BuildGenericHistory(entry.history, currencyKey) or {}
end

local function IsCurrentCharacter(characterKey)
	return characterKey ~= nil and characterKey == AWL.Utils:GetCharacterGUID()
end

local function SelectFallbackCharacter()
	if Utils:GetCharacterEntry(selectedCharacterKey) then
		return true
	end

	local currentGUID = AWL.Utils:GetCharacterGUID()

	if Utils:GetCharacterEntry(currentGUID) then
		selectedCharacterKey = currentGUID

		return true
	end

	local firstCharacter = Utils:GetSortedCharacters()[1]
	selectedCharacterKey = firstCharacter and firstCharacter.key or nil

	return selectedCharacterKey ~= nil
end

local function BuildWarbandHistory(currencyKey)
	return BuildGenericHistory(AUR.Data.balance["Warband"], currencyKey)
end

local function BuildAccountHistory(currencyKey)
	local dates = AUR.Data.dates
	local temp = {}
	local entries = {}

	for _, entry in ipairs(Utils:GetSortedCharacters()) do
		local characterHistory = BuildGenericHistoryLookup(entry.history, currencyKey)
		table.insert(temp, {characterHistory = characterHistory})
	end

	for _, date in ipairs(dates) do
		local value = 0
		local hasValue = false

		for _, characterHistory in ipairs(temp) do
			local c = characterHistory.characterHistory[date]

			if c then
				value = value + c
				hasValue = true
			end
		end

		if hasValue then
			table.insert(entries, {date = date, value = value})
		end
	end

	table.sort(entries, function(a,b) return a.date < b.date end)

	return entries
end

local function BuildMonthHistory(history, monthPrefix)
	local month = {}

	for _, e in ipairs(history) do
		if e.date:sub(1,7) == monthPrefix then
			table.insert(month, e)
		end
	end

	table.sort(month, function(a,b) return a.date > b.date end)

	return month
end

local function FilterUnchangedHistory(history)
	if not AUR.Settings.currencyOverview["hide-unchanged-entries"] then
		return history
	end

	local filtered = {}
	local previousValue = nil

	for i, entry in ipairs(history) do
		if i == 1 or entry.value ~= previousValue then
			table.insert(filtered, entry)
		end

		previousValue = entry.value
	end

	return filtered
end

local function HasAnyDataBeforeMonth(history, monthPrefix)
	if #history == 0 then
		return false
	end

	local firstMonthWithData = history[1].date:sub(1, 7)

	return firstMonthWithData < monthPrefix
end

local function HasAnyDataAfterMonth(history, monthPrefix)
	if #history == 0 then
		return false
	end

	local lastMonthWithData = history[#history].date:sub(1, 7)

	return lastMonthWithData > monthPrefix
end

local function GetPreviousValueFromHistory(history, currentDate)
	local lo, hi, idx = 1, #history, 0

	while lo <= hi do
		local mid = math.floor((lo + hi) / 2)

		if history[mid].date < currentDate then
			idx = mid
			lo = mid + 1
		else
			hi = mid - 1
		end
	end

	return idx > 0 and history[idx].value or nil
end

----------------------
--- Frame Functions ---
----------------------

local function UpdateOverview(selectedCurrency, currentMonthOffset, history, scrollFrame)
	if #history == 0 and currentMonthOffset == 0 then
		history = {{date = Utils:GetToday(), value = 0}}
	end

	local filterPrefix = GetYearMonthString(currentMonthOffset)
	local displayHistory = FilterUnchangedHistory(history)
	local monthHistory = BuildMonthHistory(displayHistory, filterPrefix)

	if scrollFrame.rows then
		for _, row in ipairs(scrollFrame.rows) do
			for _, element in ipairs(row) do
				element:Hide()
				element:SetParent(nil)
			end
		end
	end

	scrollFrame.rows = {}

	local header = scrollFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	header:SetPoint("TOP", scrollFrame.scrollFrame, "TOP", OverviewData.monthHeading.x, OverviewData.monthHeading.y)
	header:SetText(FormatMonthText(filterPrefix))
	table.insert(scrollFrame.rows, {header})

	if #monthHistory == 0 then
		local noEntry = scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		noEntry:SetPoint("TOP", 0, 0)
		noEntry:SetText(L["currency-overview.table.no-entries"])
		table.insert(scrollFrame.rows, {noEntry})

		scrollFrame:SetContentHeight(OverviewData.history.rowHeight)

		scrollFrame.prevButton:SetEnabled(HasAnyDataBeforeMonth(displayHistory, filterPrefix))
		scrollFrame.nextButton:SetEnabled(HasAnyDataAfterMonth(displayHistory, filterPrefix))

		return
	end

	local offsetY = 0

	local headerDate = scrollFrame.content:CreateFontString(nil,"OVERLAY", "GameFontNormal")
	headerDate:SetPoint("TOPLEFT", OverviewData.history.columns.date, offsetY)
	headerDate:SetText(L["currency-overview.table.date"])

	local headerAmount  = scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerAmount:SetPoint("TOPLEFT", OverviewData.history.columns.amount, offsetY)
	headerAmount:SetText(L["currency-overview.table.amount"])

	local headerDifference = scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerDifference:SetPoint("TOPLEFT", OverviewData.history.columns.difference, offsetY)
	headerDifference:SetText(L["currency-overview.table.difference"])

	table.insert(scrollFrame.rows, {headerDate, headerAmount, headerDifference})
	offsetY = offsetY - OverviewData.history.rowHeight

	for i, entry in ipairs(monthHistory) do
		local background = CreateFrame("Frame", nil, scrollFrame.content)
		background:SetSize(OverviewData.history.rowWidth, OverviewData.history.rowHeight)
		background:SetPoint("TOPLEFT", scrollFrame.content, "TOPLEFT", 0, offsetY)

		background.texture = background:CreateTexture(nil, "BACKGROUND")
		background.texture:SetAllPoints()
		background.texture:SetTexture(Addon:GetMediaPath("overview/active-table-background.tga"))
		background.texture:SetAlpha(0)

		background:SetScript("OnEnter", function(self)
			self.texture:SetAlpha(OverviewData.history.hoverAlpha)
		end)

		background:SetScript("OnLeave", function(self)
			self.texture:SetAlpha(0)
		end)

		local dateStr = entry.date
		local currentValue = entry.value

		local prevValue = GetPreviousValueFromHistory(history, dateStr) or 0

		local rowDate = background:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		rowDate:SetPoint("LEFT", OverviewData.history.columns.date, 0)
		rowDate:SetText(Utils:FormatDate(entry.date))

		local rowAmount = background:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		rowAmount:SetPoint("LEFT", OverviewData.history.columns.amount, 0)
		rowAmount:SetText(FormatCurrency(currentValue, selectedCurrency))

		local rowDifference = background:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		rowDifference:SetPoint("LEFT", OverviewData.history.columns.difference, 0)

		local firstDate = history[1].date

		if entry.date ~= firstDate then
			local diff = currentValue - prevValue
			rowDifference:SetText(FormatCurrencyDiff(diff, selectedCurrency))

			if diff > 0 then
				rowDifference:SetTextColor(0, 1, 0)
			elseif diff < 0 then
				rowDifference:SetTextColor(1, 0.2, 0.2)
			else
				rowDifference:SetTextColor(1, 1, 1)
			end
		else
			rowDifference:SetText("-")
			rowDifference:SetTextColor(1, 1, 1)
		end

		table.insert(scrollFrame.rows, {background, rowDate, rowAmount, rowDifference})
		offsetY = offsetY - OverviewData.history.rowHeight
	end

	scrollFrame:SetContentHeight(math.abs(offsetY))

	scrollFrame.prevButton:SetEnabled(HasAnyDataBeforeMonth(displayHistory, filterPrefix))
	scrollFrame.nextButton:SetEnabled(HasAnyDataAfterMonth(displayHistory, filterPrefix))
end

local function UpdateCharacterOverview()
	SelectFallbackCharacter()

	local characterHistory = BuildCharacterHistory(selectedCharacterKey, selectedCurrency[TabIndex.character])
	UpdateOverview(
		selectedCurrency[TabIndex.character],
		currentMonthOffset[TabIndex.character],
		characterHistory,
		OverviewScrollFrames[TabIndex.character]
	)
end

local function UpdateAccountOverview()
	local accountHistory = BuildAccountHistory(selectedCurrency[TabIndex.account])
	UpdateOverview(
		selectedCurrency[TabIndex.account],
		currentMonthOffset[TabIndex.account],
		accountHistory,
		OverviewScrollFrames[TabIndex.account]
	)
end

local function UpdateWarbandOverview()
	local warbandHistory = BuildWarbandHistory(selectedCurrency[TabIndex.warband])
	UpdateOverview(
		selectedCurrency[TabIndex.warband],
		currentMonthOffset[TabIndex.warband],
		warbandHistory,
		OverviewScrollFrames[TabIndex.warband]
	)
end

local function HandleCharacterDeleteConfirmed(characterKey)
	local entry = Utils:GetCharacterEntry(characterKey)
	if not entry then return end

	local removed, errorCode = Utils:DeleteCharacterData(characterKey)

	if not removed then
		if errorCode == "current-character" then
			Utils:PrintMessage(L["chat.delete-character.current-not-allowed"])
		end

		return
	end

	SelectFallbackCharacter()

	local characterDropdown = OverviewScrollFrames[TabIndex.character] and OverviewScrollFrames[TabIndex.character].characterDropdown

	if characterDropdown and characterDropdown.GenerateMenu then
		characterDropdown:GenerateMenu()
	end

	currentMonthOffset[TabIndex.character] = 0
	UpdateCharacterOverview()
	UpdateAccountOverview()

	if AUR.Modules.Chart:IsShown() then
		AUR.Modules.Chart:Refresh(true)
	end

	if AWL.GAME_TYPE_RETAIL then
		UpdateWarbandOverview()
	end

	Utils:PrintMessage(string.format(L["chat.delete-character.deleted"], entry.name, entry.realm))
end

local function ShowCharacterDeleteConfirm(characterKey)
	local entry = Utils:GetCharacterEntry(characterKey)
	if not entry or IsCurrentCharacter(characterKey) then
		return
	end

	if not AWL or not AWL.Dialogs or not AWL.Dialogs.ShowConfirmDialog then
		Utils:PrintDebug("ArcaneWizardLibrary dialog API is not available.")

		return
	end

	local confirmText = string.format(L["currency-overview.delete-character.confirm"], entry.name, entry.realm)

	AWL.Dialogs:ShowConfirmDialog(confirmText, function()
		HandleCharacterDeleteConfirmed(characterKey)
	end)
end

local function CreateCurrencyDropdown(scrollFrame, background, tabIndex)
	local currencyDropdown = CreateFrame("DropdownButton", nil, scrollFrame, "WowStyle1DropdownTemplate")
	currencyDropdown:SetPoint("BOTTOMRIGHT", background, "TOPRIGHT", -OverviewData.dropdown.offset, OverviewData.dropdown.offset)
	currencyDropdown:SetSize(OverviewData.dropdown.currencyWidth, OverviewData.dropdown.height)

	currencyDropdown:SetupMenu(function(self, root)
		local function IsSelected(value) return value == selectedCurrency[tabIndex] end

		local function SetSelected(value)
			selectedCurrency[tabIndex] = value
			currentMonthOffset[tabIndex] = 0

			if tabIndex == TabIndex.character then
				UpdateCharacterOverview()
			elseif tabIndex == TabIndex.account then
				UpdateAccountOverview()
			else
				UpdateWarbandOverview()
			end
		end

		CurrencyMenu:Populate(root, {
			scope = OverviewData.tabs[tabIndex].id,
			characterKey = selectedCharacterKey,
			isSelected = IsSelected,
			onSelected = SetSelected
		})
	end)

	scrollFrame.currencyDropdown = currencyDropdown

	return currencyDropdown
end

local function CreateCharacterDropdown(scrollFrame, background)
	local characterDropdown = CreateFrame("DropdownButton", nil, scrollFrame, "WowStyle1DropdownTemplate")
	characterDropdown:SetPoint("BOTTOMLEFT", background, "TOPLEFT", OverviewData.dropdown.offset, OverviewData.dropdown.offset)
	characterDropdown:SetSize(OverviewData.dropdown.characterWidth, OverviewData.dropdown.height)

	characterDropdown:SetupMenu(function(self, root)
		local function IsSelected(value)
			return value == selectedCharacterKey
		end

		local function SetSelected(value)
			selectedCharacterKey = value
			currentMonthOffset[TabIndex.character] = 0
			UpdateCharacterOverview()
		end

		local realmButton
		local lastRealm

		for _, entry in ipairs(Utils:GetSortedCharacters()) do
			if entry.realm ~= lastRealm then
				realmButton = root:CreateButton(entry.realm)
				lastRealm = entry.realm
			end

			local charButton = realmButton:CreateRadio(entry.name, IsSelected, SetSelected, entry.key)

			charButton:AddInitializer(function(button, description, menu)
				local factionFileID = 0
				local classColor = WHITE_FONT_COLOR

				if entry.metadata.class then
					local class = entry.metadata.class
					local faction = entry.metadata.faction

					if AWL.GAME_TYPE_RETAIL or AWL.GAME_TYPE_FOREVER then
						---@diagnostic disable-next-line: cast-local-type
						classColor = C_ClassColor.GetClassColor(class)
					else
						classColor = RAID_CLASS_COLORS[class]
					end

					if faction == "Alliance" then
						factionFileID = 136758
					elseif faction == "Horde" then
						factionFileID = 136759
					end
				end

				local rightTexture = button:AttachTexture()
				rightTexture:SetSize(OverviewData.menu.factionIconSize, OverviewData.menu.factionIconSize)
				rightTexture:SetPoint("RIGHT")

				if factionFileID == 0 then
					rightTexture:SetAtlas("Warfronts-BaseMapIcons-Empty-Barracks")
				else
					rightTexture:SetTexture(factionFileID)
				end

				local fontString = button.fontString
				fontString:SetPoint("RIGHT")
				fontString:SetTextColor(classColor:GetRGB())

				return fontString:GetUnboundedStringWidth() + rightTexture:GetWidth() + OverviewData.menu.characterWidthPadding,
					rightTexture:GetHeight() + OverviewData.menu.rowHeightPadding
			end)
		end

		local entry = Utils:GetCharacterEntry(selectedCharacterKey)

		if entry then
			root:CreateDivider()

			local deleteAction = root:CreateButton(string.format(L["currency-overview.menu.delete-character"], entry.name), function()
				ShowCharacterDeleteConfirm(entry.key)
			end)

			deleteAction:SetEnabled(not IsCurrentCharacter(entry.key))
		end
	end)

	return characterDropdown
end

local function CreateMoreMenu(tabs)
	local data = OverviewData.moreMenu
	local button = CreateFrame("DropdownButton", nil, OverviewFrame, "WowStyle1FilterDropdownTemplate")
	button.resizeToText = false
	button:SetPoint("TOPRIGHT", OverviewFrame, "TOPRIGHT", data.x, data.y)
	button:SetText(L["currency-overview.menu.more"])
	local width = math.max(data.minimumWidth, math.ceil(button.Text:GetUnboundedStringWidth()) + data.arrowSize + data.textInset * 2)
	button:SetSize(width, data.height)
	button.Text:ClearAllPoints()
	button.Text:SetPoint("LEFT", data.textInset, 0)
	button.Text:SetPoint("RIGHT", -data.textInset, 0)
	button.Text:SetJustifyH("CENTER")

	button:SetMenuAnchor(AnchorUtil.CreateAnchor("TOPLEFT", button, "TOPRIGHT", data.menuGap, 0))
	button:SetupMenu(function(_, root)
		local chartButton = root:CreateButton(L["chart.title"], function()
			local scope = tabs:GetSelectedTab()
			AUR.Modules.Chart:Show({
				scope = scope,
				characterKey = selectedCharacterKey,
				currencyKey = selectedCurrency[TabIndex[scope]]
			})
		end)
		chartButton:AddInitializer(function(menuButton)
			for index, height in ipairs(data.icon.barHeights) do
				local bar = menuButton:AttachTexture()
				bar:SetColorTexture(unpack(data.icon.color))
				bar:SetSize(data.icon.barWidth, height)
				bar:SetPoint("BOTTOMLEFT", menuButton, "LEFT", data.itemPadding + (index - 1) * (data.icon.barWidth + data.icon.barGap), -data.icon.size / 2)
			end

			local text = menuButton.fontString
			local textWidth = text:GetUnboundedStringWidth()
			text:ClearAllPoints()
			text:SetPoint("LEFT", data.itemPadding + data.icon.size + data.iconGap, 0)
			text:SetWidth(textWidth)

			return textWidth + data.icon.size + data.iconGap + data.itemPadding * 2, data.itemHeight
		end)
	end)
	button:HookScript("OnHide", function(self)
		self:CloseMenu()
	end)
	tabs:SetOnTabChanged(function()
		button:CloseMenu()
	end)
	OverviewFrame.moreMenu = button
end

local function InitializeFrames()
	local lastTabIndex = AWL.GAME_TYPE_RETAIL and TabIndex.warband or TabIndex.account
	local windowConfig = AWL.Utils:CopyTable(OverviewData.window)
	windowConfig.title = addonName
	OverviewFrame = AWL.Frames:CreateWindow(windowConfig)
	OverviewFrame:SetFrameStrata("HIGH")
	OverviewFrame.portrait:SetPoint("TOPLEFT", OverviewData.portrait.x, OverviewData.portrait.y)
	OverviewFrame.portrait:SetTexture(Addon:GetMediaPath("icon-round.tga"))

	local insetConfig = AWL.Utils:CopyTable(OverviewData.inset)
	insetConfig.parent = OverviewFrame
	local background = AWL.Frames:CreateInset(insetConfig)
	background:SetPoint("BOTTOM", OverviewFrame, "BOTTOM", 0, OverviewData.inset.bottom)
	local tabs = AWL.Frames:CreateTabGroup(OverviewFrame)

	for tabIndex = TabIndex.character, lastTabIndex do
		currentMonthOffset[tabIndex] = 0
		local tabData = OverviewData.tabs[tabIndex]
		local page = tabs:AddTab(tabData.id, L[tabData.label])
		page:ClearAllPoints()
		page:SetAllPoints(background)
		local scrollFrame = AWL.ScrollFrames:CreateScrollFrame({
			parent = page,
			width = OverviewData.inset.width,
			height = OverviewData.inset.height,
			backgroundAlpha = 0,
			showBorder = false,
			contentInsets = OverviewData.contentInsets
		})
		scrollFrame:SetAllPoints(page)
		scrollFrame:SetScrollStep(OverviewData.scrollStep)

		scrollFrame.nextButton = AWL.Controls:CreateButton({
			parent = scrollFrame,
			width = OverviewData.buttonWidth,
			label = L["button.next"],
			onClick = function()
				currentMonthOffset[tabIndex] = currentMonthOffset[tabIndex] - 1

				if tabIndex == TabIndex.character then
					UpdateCharacterOverview()
				elseif tabIndex == TabIndex.account then
					UpdateAccountOverview()
				else
					UpdateWarbandOverview()
				end
			end
		})

		scrollFrame.nextButton:SetPoint("TOPRIGHT", background, "BOTTOMRIGHT", -OverviewData.buttonOffset.x, OverviewData.buttonOffset.y)

		scrollFrame.prevButton = AWL.Controls:CreateButton({
			parent = scrollFrame,
			width = OverviewData.buttonWidth,
			label = L["button.prev"],
			onClick = function()
				currentMonthOffset[tabIndex] = currentMonthOffset[tabIndex] + 1

				if tabIndex == TabIndex.character then
					UpdateCharacterOverview()
				elseif tabIndex == TabIndex.account then
					UpdateAccountOverview()
				else
					UpdateWarbandOverview()
				end
			end
		})

		scrollFrame.prevButton:SetPoint("TOPLEFT", background, "BOTTOMLEFT", OverviewData.buttonOffset.x, OverviewData.buttonOffset.y)

		CreateCurrencyDropdown(scrollFrame, background, tabIndex)

		if tabIndex == TabIndex.character then
			local characterDropdown = CreateCharacterDropdown(scrollFrame, background)
			scrollFrame.characterDropdown = characterDropdown
		end

		OverviewScrollFrames[tabIndex] = scrollFrame
	end

	CreateMoreMenu(tabs)
end

------------------------
--- Module Functions ---
------------------------

function Overview:Initialize()
	selectedCharacterKey = AWL.Utils:GetCharacterGUID()
	InitializeFrames()
end

function Overview:Show()
	self:Refresh()
	OverviewFrame:Show()
end

function Overview:Hide()
	OverviewFrame:Hide()
end

function Overview:RefreshCurrencyMenus()
	for _, scrollFrame in ipairs(OverviewScrollFrames) do
		local dropdown = scrollFrame.currencyDropdown

		if dropdown and dropdown:IsMenuOpen() then
			dropdown:GenerateMenu()
		end
	end
end

function Overview:Refresh()
	if not OverviewFrame then return end

	UpdateCharacterOverview()
	UpdateAccountOverview()

	if AWL.GAME_TYPE_RETAIL then
		UpdateWarbandOverview()
	end
end

function Overview:IsShown()
	return OverviewFrame and OverviewFrame:IsShown()
end
