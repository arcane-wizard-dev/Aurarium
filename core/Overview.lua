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

-- Variables
local selectedCharacterKey
local currentMonthOffset = {}
local selectedCurrency = {}
selectedCurrency[1] = "gold"
selectedCurrency[2] = "gold"
selectedCurrency[3] = "w-2032"

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

local function ResizeScrollChild(scrollFrame, contentHeight)
	local width = math.max(scrollFrame:GetWidth(), 1)
	local height = math.max(scrollFrame:GetHeight(), contentHeight, 1)

	scrollFrame.scrollView:SetSize(width, height)
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
	header:SetPoint("TOP", 5, 70)
	header:SetText(FormatMonthText(filterPrefix))
	table.insert(scrollFrame.rows, {header})

	if #monthHistory == 0 then
		local noEntry = scrollFrame.scrollView:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		noEntry:SetPoint("TOP", 0, 0)
		noEntry:SetText(L["currency-overview.table.no-entries"])
		table.insert(scrollFrame.rows, {noEntry})

		ResizeScrollChild(scrollFrame, 20)

		scrollFrame.prevButton:SetEnabled(HasAnyDataBeforeMonth(displayHistory, filterPrefix))
		scrollFrame.nextButton:SetEnabled(HasAnyDataAfterMonth(displayHistory, filterPrefix))
		return
	end

	local offsetY = 0

	local headerDate = scrollFrame.scrollView:CreateFontString(nil,"OVERLAY", "GameFontNormal")
	headerDate:SetPoint("TOPLEFT", 5, offsetY)
	headerDate:SetText(L["currency-overview.table.date"])

	local headerAmount  = scrollFrame.scrollView:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerAmount:SetPoint("TOPLEFT", 80, offsetY)
	headerAmount:SetText(L["currency-overview.table.amount"])

	local headerDifference = scrollFrame.scrollView:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerDifference:SetPoint("TOPLEFT", 230, offsetY)
	headerDifference:SetText(L["currency-overview.table.difference"])

	table.insert(scrollFrame.rows, {headerDate, headerAmount, headerDifference})
	offsetY = offsetY - 20

	for i, entry in ipairs(monthHistory) do
		local background = CreateFrame("Frame", nil, scrollFrame.scrollView)
		background:SetSize(414, 20)
		background:SetPoint("TOPLEFT", scrollFrame.scrollView, "TOPLEFT", 0, offsetY)

		background.texture = background:CreateTexture(nil, "BACKGROUND")
		background.texture:SetAllPoints()
		background.texture:SetTexture(Addon:GetMediaPath("active-table-background.blp"))
		background.texture:SetAlpha(0)

		background:SetScript("OnEnter", function(self) self.texture:SetAlpha(0.3) end)
		background:SetScript("OnLeave", function(self) self.texture:SetAlpha(0) end)

		local dateStr = entry.date
		local currentValue = entry.value

		local prevValue = GetPreviousValueFromHistory(history, dateStr) or 0

		local rowDate = background:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		rowDate:SetPoint("LEFT", 5, 0)
		rowDate:SetText(entry.date)

		local rowAmount = background:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		rowAmount:SetPoint("LEFT", 80, 0)
		rowAmount:SetText(FormatCurrency(currentValue, selectedCurrency))

		local rowDifference = background:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		rowDifference:SetPoint("LEFT", 230, 0)

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
		offsetY = offsetY - 20
	end

	ResizeScrollChild(scrollFrame, math.abs(offsetY))

	scrollFrame.prevButton:SetEnabled(HasAnyDataBeforeMonth(displayHistory, filterPrefix))
	scrollFrame.nextButton:SetEnabled(HasAnyDataAfterMonth(displayHistory, filterPrefix))
end

local function UpdateCharacterOverview()
	SelectFallbackCharacter()

	local characterHistory = BuildCharacterHistory(selectedCharacterKey, selectedCurrency[1])
	UpdateOverview(selectedCurrency[1], currentMonthOffset[1], characterHistory, OverviewScrollFrames[1])

	if OverviewScrollFrames[1].actionsButton then
		OverviewScrollFrames[1].actionsButton:SetEnabled(selectedCharacterKey ~= nil)
	end
end

local function UpdateAccountOverview()
	local accountHistory = BuildAccountHistory(selectedCurrency[2])
	UpdateOverview(selectedCurrency[2], currentMonthOffset[2], accountHistory, OverviewScrollFrames[2])
end

local function UpdateWarbandOverview()
	local warbandHistory = BuildWarbandHistory(selectedCurrency[3])
	UpdateOverview(selectedCurrency[3], currentMonthOffset[3], warbandHistory, OverviewScrollFrames[3])
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

	local characterDropdown = OverviewScrollFrames[1] and OverviewScrollFrames[1].characterDropdown
	if characterDropdown and characterDropdown.GenerateMenu then
		characterDropdown:GenerateMenu()
	end

	currentMonthOffset[1] = 0
	UpdateCharacterOverview()
	UpdateAccountOverview()

	if AWL.GAME_TYPE_MAINLINE then
		UpdateWarbandOverview()
	end

	Utils:PrintMessage(string.format(L["chat.delete-character.deleted"], entry.name, entry.realm))
end

local function ShowCharacterDeleteConfirm(characterKey)
	local entry = Utils:GetCharacterEntry(characterKey)
	if not entry then
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

local function CreateCurrencyDropdown(scrollFrame, background, index)
	local currencyDropdown = CreateFrame("DropdownButton", nil, scrollFrame, "WowStyle1DropdownTemplate")
	currencyDropdown:SetPoint("BOTTOMRIGHT", background, "TOPRIGHT", -5, 5)
	currencyDropdown:SetSize(200, 25)

	currencyDropdown:SetupMenu(function(self, root)
		local function IsSelected(value) return value == selectedCurrency[index] end
		local function SetSelected(value)
			selectedCurrency[index] = value
			currentMonthOffset[index] = 0
			if index == 1 then UpdateCharacterOverview()
			elseif index == 2 then UpdateAccountOverview()
			else UpdateWarbandOverview() end
		end

		if index == 1 or index == 2 then
			local goldButton = root:CreateRadio(L["currency-overview.category.gold"], IsSelected, SetSelected, "gold");
			goldButton:AddInitializer(function(button, description, menu)
				local rightTexture = button:AttachTexture()
				rightTexture:SetSize(16, 16)
				rightTexture:SetPoint("RIGHT")
				rightTexture:SetTexture(237618)
				local fontString = button.fontString
				fontString:SetPoint("RIGHT")
				return fontString:GetUnboundedStringWidth() + rightTexture:GetWidth() + 20, rightTexture:GetHeight() + 4
			end)

			if not AWL.GAME_TYPE_MAINLINE and not AWL.GAME_TYPE_MISTS then return end

			root:CreateDivider()

			for _, categoryKey in ipairs(AUR.CURRENCY_CATEGORY_ORDER) do
				if AUR.CHARACTER_CURRENCIES[categoryKey] then
					local categoryButton = root:CreateButton(L["currency-overview.category." .. categoryKey])
					if categoryKey == 'timerunning' then root:CreateDivider() end
					local sortedList = {}
					for _, currencyID in ipairs(AUR.CHARACTER_CURRENCIES[categoryKey]) do
						local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
						if info then table.insert(sortedList, {id = "c-" .. currencyID, name = info.name, iconFileID = info.iconFileID}) end
					end
					table.sort(sortedList, function(a, b) return a.name < b.name end)

					for _, entry in ipairs(sortedList) do
						local currencyButton = categoryButton:CreateRadio(entry.name, IsSelected, SetSelected, entry.id)
						currencyButton:AddInitializer(function(button, description, menu)
							local rightTexture = button:AttachTexture()
							rightTexture:SetSize(16, 16)
							rightTexture:SetPoint("RIGHT")
							rightTexture:SetTexture(entry.iconFileID)
							local fontString = button.fontString
							fontString:SetPoint("RIGHT")
							return fontString:GetUnboundedStringWidth() + rightTexture:GetWidth() + 20, rightTexture:GetHeight() + 4
						end)
					end
				end
			end
		elseif index == 3 and AWL.GAME_TYPE_MAINLINE then
			for _, categoryKey in ipairs(AUR.CURRENCY_CATEGORY_ORDER) do
				if AUR.WARBAND_CURRENCIES[categoryKey] then
					local categoryButton = root:CreateButton(L["currency-overview.category." .. categoryKey])
					local sortedList = {}
					for _, currencyID in ipairs(AUR.WARBAND_CURRENCIES[categoryKey]) do
						local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
						if info then table.insert(sortedList, {id = "w-" .. currencyID, name = info.name, iconFileID = info.iconFileID}) end
					end
					table.sort(sortedList, function(a, b) return a.name < b.name end)

					for _, entry in ipairs(sortedList) do
						local currencyButton = categoryButton:CreateRadio(entry.name, IsSelected, SetSelected, entry.id);
						currencyButton:AddInitializer(function(button, description, menu)
							local rightTexture = button:AttachTexture()
							rightTexture:SetSize(18, 18)
							rightTexture:SetPoint("RIGHT")
							rightTexture:SetTexture(entry.iconFileID)
							local fontString = button.fontString
							fontString:SetPoint("RIGHT")
							return fontString:GetUnboundedStringWidth() + rightTexture:GetWidth() + 20, rightTexture:GetHeight() + 4
						end)
					end
				end
			end
		end
	end)
	return currencyDropdown
end

local function CreateCharacterDropdown(scrollFrame, background)
	local characterDropdown = CreateFrame("DropdownButton", nil, scrollFrame, "WowStyle1DropdownTemplate")
	characterDropdown:SetPoint("BOTTOMLEFT", background, "TOPLEFT", 5, 5)
	characterDropdown:SetSize(125, 25)

	characterDropdown:SetupMenu(function(self, root)
		local function IsSelected(value)
			return value == selectedCharacterKey
		end
		local function SetSelected(value)
			selectedCharacterKey = value
			currentMonthOffset[1] = 0
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

					if AWL.GAME_TYPE_MAINLINE then
						---@diagnostic disable-next-line: cast-local-type
						classColor = C_ClassColor.GetClassColor(class)
					else
						classColor = RAID_CLASS_COLORS[class]
					end

					if faction == "Alliance" then factionFileID = 136758
					elseif faction == "Horde" then factionFileID = 136759 end
				end

				local rightTexture = button:AttachTexture()
				rightTexture:SetSize(18, 18)
				rightTexture:SetPoint("RIGHT")

				if factionFileID == 0 then
					rightTexture:SetAtlas("Warfronts-BaseMapIcons-Empty-Barracks")
				else
					rightTexture:SetTexture(factionFileID)
				end

				local fontString = button.fontString
				fontString:SetPoint("RIGHT")
				fontString:SetTextColor(classColor:GetRGB())

				return fontString:GetUnboundedStringWidth() + rightTexture:GetWidth() + 20, rightTexture:GetHeight() + 4
			end)
		end
	end)
	return characterDropdown
end

local function OpenCharacterActionsMenu(ownerButton)
	local characterKey = selectedCharacterKey
	local hasSelection = Utils:GetCharacterEntry(characterKey) ~= nil
	local isCurrentCharacter = IsCurrentCharacter(characterKey)

	if MenuUtil and MenuUtil.CreateContextMenu then
		MenuUtil.CreateContextMenu(ownerButton, function(_, root)
			local deleteAction = root:CreateButton(L["currency-overview.menu.delete-character"], function()
				if not hasSelection then
					return
				end

				if isCurrentCharacter then
					Utils:PrintMessage(L["chat.delete-character.current-not-allowed"])
					return
				end

				ShowCharacterDeleteConfirm(characterKey)
			end)

			if deleteAction and deleteAction.SetEnabled then
				deleteAction:SetEnabled(hasSelection and not isCurrentCharacter)
			end
		end)
		return
	end

	-- Fallback for game versions without the modern menu API.
	if hasSelection then
		if isCurrentCharacter then
			Utils:PrintMessage(L["chat.delete-character.current-not-allowed"])
			return
		end

		ShowCharacterDeleteConfirm(characterKey)
	end
end

local function CreateCharacterActionsButton(scrollFrame, characterDropdown)
	local actionsButton = CreateFrame("Button", nil, scrollFrame, "UIPanelButtonTemplate")
	actionsButton:SetPoint("LEFT", characterDropdown, "RIGHT", 5, 0)
	actionsButton:SetSize(24, 22)
	actionsButton:SetText("")

	local icon = actionsButton:CreateTexture(nil, "ARTWORK")
	icon:SetPoint("CENTER")
	icon:SetSize(14, 14)
	icon:SetTexture(Addon:GetMediaPath("gear-icon.tga"))

	actionsButton:SetScript("OnClick", function(self)
		OpenCharacterActionsMenu(self)
	end)

	return actionsButton
end

local function SetupTabs(numTabs)
	local tabs = {}
	local tabTemplate = AWL.GAME_TYPE_MAINLINE and "PanelTabButtonTemplate" or "CharacterFrameTabButtonTemplate"

	for i = 1, numTabs do
		local tab = CreateFrame("Button", "Aurarium_OverviewTab" .. i, OverviewFrame, tabTemplate)
		tab:SetID(i)

		if i == 1 then tab:SetText(L["currency-overview.tab.character"])
		elseif i == 2 then tab:SetText(L["currency-overview.tab.account"])
		else tab:SetText(L["currency-overview.tab.warband"]) end

		tab:SetScript("OnClick", function(self)
			local id = self:GetID()

			if AWL.GAME_TYPE_MAINLINE then
				PanelTemplates_SetTab(OverviewFrame, id)
			end

			for j = 1, numTabs do
				if j == id then
					if not AWL.GAME_TYPE_MAINLINE then PanelTemplates_SelectTab(tabs[j]) end
					OverviewScrollFrames[j]:Show()
				else
					if not AWL.GAME_TYPE_MAINLINE then PanelTemplates_DeselectTab(tabs[j]) end
					OverviewScrollFrames[j]:Hide()
				end
			end
		end)
		tabs[i] = tab
	end

	if AWL.GAME_TYPE_MAINLINE then
		PanelTemplates_SetNumTabs(OverviewFrame, numTabs)
		tabs[1]:SetPoint("TOPLEFT", OverviewFrame, "BOTTOMLEFT", 10, 2)
		tabs[2]:SetPoint("LEFT", tabs[1], "RIGHT", -15, 0)
		if numTabs == 3 then tabs[3]:SetPoint("LEFT", tabs[2], "RIGHT", -15, 0) end
		PanelTemplates_SetTab(OverviewFrame, 1)
		for i = 1, numTabs do PanelTemplates_TabResize(tabs[i], 0) end
	else
		tabs[1]:SetPoint("TOPLEFT", OverviewFrame, "BOTTOMLEFT", 10, 2)
		tabs[2]:SetPoint("LEFT", tabs[1], "RIGHT", -15, 0)
		for i = 1, numTabs do
			PanelTemplates_TabResize(tabs[i], 0)
			if i == 1 then PanelTemplates_SelectTab(tabs[i]) else PanelTemplates_DeselectTab(tabs[i]) end
		end
	end
end

local function InitializeFrames()
	local numTabs = AWL.GAME_TYPE_MAINLINE and 3 or 2
	local insetTemplate = AWL.GAME_TYPE_MAINLINE and "InsetFrameTemplate4" or "InsetFrameTemplate"

	OverviewFrame = CreateFrame("Frame", "Aurarium_OverviewFrame", UIParent, "PortraitFrameTemplate")
	OverviewFrame:SetPoint("CENTER")
	OverviewFrame:SetSize(470, 560)
	OverviewFrame:SetFrameStrata("HIGH")
	OverviewFrame:SetMovable(true)
	OverviewFrame:EnableMouse(true)
	OverviewFrame:RegisterForDrag("LeftButton")
	OverviewFrame:SetScript("OnDragStart", OverviewFrame.StartMoving)
	OverviewFrame:SetScript("OnDragStop", OverviewFrame.StopMovingOrSizing)
	OverviewFrame:SetTitle(addonName)
	OverviewFrame:Hide()
	tinsert(UISpecialFrames, OverviewFrame:GetName())

	local portrait = OverviewFrame:GetPortrait()
	portrait:SetPoint('TOPLEFT', -5, 8)
	portrait:SetTexture(Addon:GetMediaPath("icon-round.blp"))

	local background = CreateFrame("Frame", nil, OverviewFrame, insetTemplate)
	background:SetSize(454, 430)
	background:SetPoint("BOTTOM", OverviewFrame, "BOTTOM", 0, 37)

	if AWL.GAME_TYPE_MAINLINE then
		background.texture = background:CreateTexture(nil, "BACKGROUND")
		background.texture:SetAllPoints(background)
		background.texture:SetPoint("CENTER")
		background.texture:SetAtlas("character-panel-background", true)
	end

	for i = 1, numTabs do
		currentMonthOffset[i] = 0

		local scrollFrame = CreateFrame("ScrollFrame", nil, background, "Aurarium_OverviewScrollFrameTemplate")
		scrollFrame:SetPoint("TOPLEFT", background, "TOPLEFT", 10, -15)
		scrollFrame:SetPoint("BOTTOMRIGHT", background, "BOTTOMRIGHT", -25, 15)
		scrollFrame:EnableMouseWheel(true)
		scrollFrame:SetScript("OnMouseWheel", function(self, delta)
			local newValue = math.max(0, math.min(self:GetVerticalScroll() - delta * 20, self:GetVerticalScrollRange()))
			self:SetVerticalScroll(newValue)
		end)

		if i ~= 1 then scrollFrame:Hide() end

		scrollFrame.scrollView = CreateFrame("Frame")
		scrollFrame.scrollView:SetSize(1, 1)
		scrollFrame:SetScrollChild(scrollFrame.scrollView)

		scrollFrame.nextButton = CreateFrame("Button", nil, scrollFrame, "UIPanelButtonTemplate")
		scrollFrame.nextButton:SetPoint("TOPRIGHT", background, "BOTTOMRIGHT", -5, -5)
		scrollFrame.nextButton:SetSize(100, 22)
		scrollFrame.nextButton:SetText(L["button.next"])
		scrollFrame.nextButton:SetScript("OnClick", function()
			currentMonthOffset[i] = currentMonthOffset[i] - 1
			if i == 1 then UpdateCharacterOverview()
			elseif i == 2 then UpdateAccountOverview()
			else UpdateWarbandOverview() end
		end)

		scrollFrame.prevButton = CreateFrame("Button", nil, scrollFrame, "UIPanelButtonTemplate")
		scrollFrame.prevButton:SetPoint("TOPLEFT", background, "BOTTOMLEFT", 5, -5)
		scrollFrame.prevButton:SetSize(100, 22)
		scrollFrame.prevButton:SetText(L["button.prev"])
		scrollFrame.prevButton:SetScript("OnClick", function()
			currentMonthOffset[i] = currentMonthOffset[i] + 1
			if i == 1 then UpdateCharacterOverview()
			elseif i == 2 then UpdateAccountOverview()
			else UpdateWarbandOverview() end
		end)

		CreateCurrencyDropdown(scrollFrame, background, i)
		if i == 1 then
			local characterDropdown = CreateCharacterDropdown(scrollFrame, background)
			scrollFrame.characterDropdown = characterDropdown
			scrollFrame.actionsButton = CreateCharacterActionsButton(scrollFrame, characterDropdown)
		end

		OverviewScrollFrames[i] = scrollFrame
	end

	SetupTabs(numTabs)
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

function Overview:Refresh()
	if not OverviewFrame then return end

	UpdateCharacterOverview()
	UpdateAccountOverview()

	if AWL.GAME_TYPE_MAINLINE then
		UpdateWarbandOverview()
	end
end

function Overview:IsShown()
	return OverviewFrame and OverviewFrame:IsShown()
end
