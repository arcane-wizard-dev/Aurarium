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
local OverviewData = AUR.OVERVIEW_DATA

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
	header:SetPoint("TOP", scrollFrame.scrollFrame, "TOP", 5, 70)
	header:SetText(FormatMonthText(filterPrefix))
	table.insert(scrollFrame.rows, {header})

	if #monthHistory == 0 then
		local noEntry = scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		noEntry:SetPoint("TOP", 0, 0)
		noEntry:SetText(L["currency-overview.table.no-entries"])
		table.insert(scrollFrame.rows, {noEntry})

		scrollFrame:SetContentHeight(20)

		scrollFrame.prevButton:SetEnabled(HasAnyDataBeforeMonth(displayHistory, filterPrefix))
		scrollFrame.nextButton:SetEnabled(HasAnyDataAfterMonth(displayHistory, filterPrefix))

		return
	end

	local offsetY = 0

	local headerDate = scrollFrame.content:CreateFontString(nil,"OVERLAY", "GameFontNormal")
	headerDate:SetPoint("TOPLEFT", 5, offsetY)
	headerDate:SetText(L["currency-overview.table.date"])

	local headerAmount  = scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerAmount:SetPoint("TOPLEFT", 80, offsetY)
	headerAmount:SetText(L["currency-overview.table.amount"])

	local headerDifference = scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerDifference:SetPoint("TOPLEFT", 230, offsetY)
	headerDifference:SetText(L["currency-overview.table.difference"])

	table.insert(scrollFrame.rows, {headerDate, headerAmount, headerDifference})
	offsetY = offsetY - 20

	for i, entry in ipairs(monthHistory) do
		local background = CreateFrame("Frame", nil, scrollFrame.content)
		background:SetSize(414, 20)
		background:SetPoint("TOPLEFT", scrollFrame.content, "TOPLEFT", 0, offsetY)

		background.texture = background:CreateTexture(nil, "BACKGROUND")
		background.texture:SetAllPoints()
		background.texture:SetTexture(Addon:GetMediaPath("overview/active-table-background.tga"))
		background.texture:SetAlpha(0)

		background:SetScript("OnEnter", function(self)
			self.texture:SetAlpha(0.3)
		end)

		background:SetScript("OnLeave", function(self)
			self.texture:SetAlpha(0)
		end)

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

	scrollFrame:SetContentHeight(math.abs(offsetY))

	scrollFrame.prevButton:SetEnabled(HasAnyDataBeforeMonth(displayHistory, filterPrefix))
	scrollFrame.nextButton:SetEnabled(HasAnyDataAfterMonth(displayHistory, filterPrefix))
end

local function UpdateCharacterOverview()
	SelectFallbackCharacter()

	local characterHistory = BuildCharacterHistory(selectedCharacterKey, selectedCurrency[1])
	UpdateOverview(selectedCurrency[1], currentMonthOffset[1], characterHistory, OverviewScrollFrames[1])
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

local function GetCharacterBalances(characterKey)
	local balances = {}

	for key, value in pairs(Utils:GetLatestBalances(characterKey)) do
		balances[key] = value
	end

	if IsCurrentCharacter(characterKey) then
		balances.gold = AUR.State.gold

		for _, entries in pairs(AUR.State.currencies.character) do
			for _, entry in ipairs(entries) do
				if entry.info and entry.info.quantity ~= nil then
					balances[entry.key] = entry.info.quantity
				end
			end
		end
	end

	return balances
end

local function GetDropdownBalances(index)
	if index == 3 then return {}, true end

	if index == 1 then
		local characterKey = selectedCharacterKey or AWL.Utils:GetCharacterGUID()
		if IsCurrentCharacter(characterKey) then return {gold = AUR.State.gold}, true end

		return Utils:GetLatestBalances(characterKey), false
	end

	local balances = {}

	for _, character in ipairs(Utils:GetSortedCharacters()) do
		for key, value in pairs(GetCharacterBalances(character.key)) do
			balances[key] = (balances[key] or 0) + value
		end
	end

	return balances, false
end

local function FormatDropdownAmount(quantity, info)
	if quantity == nil then return "-" end

	local amount = BreakUpLargeNumbers(quantity)

	if info and info.maxQuantity and info.maxQuantity > 0 then
		amount = amount .. "/" .. BreakUpLargeNumbers(info.maxQuantity)
	end

	return amount
end

local function InitializeCurrencyMenuButton(button, entry, text)
	local iconSize = entry.key:sub(1, 2) == "w-" and 18 or 16
	local icon, iconWidth, anchorPoint = button, 0, "RIGHT"

	if entry.key ~= "gold" then
		icon = button:AttachTexture()
		icon:SetSize(iconSize, iconSize)
		icon:SetPoint("RIGHT")
		icon:SetTexture(entry.iconFileID)
		iconWidth, anchorPoint = iconSize, "LEFT"
	end

	local amount = button:AttachFontString()
	amount:SetFontObject(button.fontString:GetFontObject())
	amount:SetTextColor(1, 1, 1)
	amount:SetPoint("RIGHT", icon, anchorPoint, -5, 0)
	amount:SetJustifyH("RIGHT")
	amount:SetText(text)
	local amountWidth = amount:GetUnboundedStringWidth()
	amount:SetWidth(amountWidth)

	local fontString = button.fontString
	local nameWidth = fontString:GetUnboundedStringWidth()
	fontString:SetWidth(nameWidth)
	local badgeWidth = 0

	if entry.isNew and MenuTemplates and MenuTemplates.AttachNewFeatureFrame then
		local badge = MenuTemplates.AttachNewFeatureFrame(button)
		local badgeTextWidth = badge:GetTextWidth()
		badgeWidth = badgeTextWidth + 16
		badge:SetPoint("CENTER", fontString, "RIGHT", badgeTextWidth / 2 + 8, 0)
	end

	return nameWidth + iconWidth + amountWidth + badgeWidth + 35, iconSize + 4
end

local function CreateCurrencyDropdown(scrollFrame, background, index)
	local currencyDropdown = CreateFrame("DropdownButton", nil, scrollFrame, "WowStyle1DropdownTemplate")
	currencyDropdown:SetPoint("BOTTOMRIGHT", background, "TOPRIGHT", -5, 5)
	currencyDropdown:SetSize(200, 25)

	currencyDropdown:SetupMenu(function(self, root)
		local balances, live = GetDropdownBalances(index)

		local function IsSelected(value) return value == selectedCurrency[index] end

		local function SetSelected(value)
			selectedCurrency[index] = value
			currentMonthOffset[index] = 0

			if index == 1 then
				UpdateCharacterOverview()
			elseif index == 2 then
				UpdateAccountOverview()
			else
				UpdateWarbandOverview()
			end
		end

		if index == 1 or index == 2 then
			root:CreateRadio(L["currency-overview.category.gold"], IsSelected, SetSelected, "gold")
		end

		local categories = index == 3 and AUR.State.currencies.warband or AUR.State.currencies.character
		if not next(categories) then return end

		if index ~= 3 then
			root:CreateDivider()
		end

		local hasCategory, dividerPending = false, false

		for _, categoryKey in ipairs(AUR.CURRENCY_CATEGORY_ORDER) do
			if categoryKey == false then
				dividerPending = hasCategory
			end

			local entries = categories[categoryKey]

			if entries then
				if dividerPending then
					root:CreateDivider()
					dividerPending = false
				end

				local categoryButton = root:CreateButton(L["currency-overview.category." .. categoryKey])
				hasCategory = true
				local previousPatch

				for _, entry in ipairs(entries) do
					if AUR.CURRENCY_PATCH_CATEGORIES[categoryKey] and entry.patch and entry.patch ~= previousPatch then
						if previousPatch then
							categoryButton:CreateDivider()
						end

						categoryButton:CreateTitle(string.format(L["currency-overview.menu.patch"], entry.patch))
						previousPatch = entry.patch
					end

					local currencyButton = categoryButton:CreateRadio(entry.name, IsSelected, SetSelected, entry.key)
					local info = live and entry.info or nil
					---@type number|nil
					local quantity = balances[entry.key] or 0

					if live then
						quantity = info and info.quantity
					end

					local amount = FormatDropdownAmount(quantity, info)

					currencyButton:AddInitializer(function(button)
						return InitializeCurrencyMenuButton(button, entry, amount)
					end)
				end
			end
		end
	end)

	scrollFrame.currencyDropdown = currencyDropdown

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

local function InitializeFrames()
	local numTabs = AWL.GAME_TYPE_RETAIL and 3 or 2
	local windowConfig = AWL.Utils:CopyTable(OverviewData.window)
	windowConfig.title = addonName
	OverviewFrame = AWL.Frames:CreateWindow(windowConfig)
	OverviewFrame:SetFrameStrata("HIGH")
	OverviewFrame.portrait:SetPoint("TOPLEFT", -5, 8)
	OverviewFrame.portrait:SetTexture(Addon:GetMediaPath("icon-round.tga"))

	local insetConfig = AWL.Utils:CopyTable(OverviewData.inset)
	insetConfig.parent = OverviewFrame
	local background = AWL.Frames:CreateInset(insetConfig)
	background:SetPoint("BOTTOM", OverviewFrame, "BOTTOM", 0, OverviewData.inset.bottom)
	local tabs = AWL.Frames:CreateTabGroup(OverviewFrame)

	for i = 1, numTabs do
		currentMonthOffset[i] = 0
		local tabData = OverviewData.tabs[i]
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
				currentMonthOffset[i] = currentMonthOffset[i] - 1

				if i == 1 then
					UpdateCharacterOverview()
				elseif i == 2 then
					UpdateAccountOverview()
				else
					UpdateWarbandOverview()
				end
			end
		})

		scrollFrame.nextButton:SetPoint("TOPRIGHT", background, "BOTTOMRIGHT", -5, -5)

		scrollFrame.prevButton = AWL.Controls:CreateButton({
			parent = scrollFrame,
			width = OverviewData.buttonWidth,
			label = L["button.prev"],
			onClick = function()
				currentMonthOffset[i] = currentMonthOffset[i] + 1

				if i == 1 then
					UpdateCharacterOverview()
				elseif i == 2 then
					UpdateAccountOverview()
				else
					UpdateWarbandOverview()
				end
			end
		})

		scrollFrame.prevButton:SetPoint("TOPLEFT", background, "BOTTOMLEFT", 5, -5)

		CreateCurrencyDropdown(scrollFrame, background, i)

		if i == 1 then
			local characterDropdown = CreateCharacterDropdown(scrollFrame, background)
			scrollFrame.characterDropdown = characterDropdown
		end

		OverviewScrollFrames[i] = scrollFrame
	end
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
