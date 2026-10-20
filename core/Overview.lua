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
local WowToken = AUR.Modules.WowToken
local OverviewConfig = AUR.UIConfig.Overview
local TabIndex = OverviewConfig.tabIndices

-- Variables
local selectedCharacterKey
local currentMonthOffset = {}
local selectedCurrency = {}
selectedCurrency[TabIndex.character] = "gold"
selectedCurrency[TabIndex.account] = "gold"
selectedCurrency[TabIndex.warband] = "w-2032"
selectedCurrency[TabIndex.token] = "token"

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
	elseif selectedCurrency == "token" then
		return string.format(OverviewConfig.tokenPriceFormat, BreakUpLargeNumbers(floor(v / 10000)))
	else
		return BreakUpLargeNumbers(v)
	end
end

local function FormatCurrencyDiff(diff, selectedCurrency)
	local d = diff or 0

	if selectedCurrency == "gold" then
		return FormatGoldDiff(d)
	elseif selectedCurrency == "token" then
		local sign = d > 0 and "+" or d < 0 and "-" or "±"

		return sign .. " " .. FormatCurrency(math.abs(d), selectedCurrency)
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
	if not AUR.Settings.currencyOverview["table-overview"]["hide-unchanged-entries"] then
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

local function CreateHistoryCell(parent, tableFrame, index)
	local x, width, align = tableFrame:GetColumnLayout(index)
	local cell = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	cell:SetPoint("LEFT", parent, "LEFT", x, 0)
	cell:SetWidth(width)
	cell:SetJustifyH(align)
	cell:SetWordWrap(false)

	return cell
end

local function UpdateOverview(config)
	local selectedCurrency = config.currency
	local currentMonthOffset = config.monthOffset
	local history = config.history
	local scrollFrame = config.tableFrame

	if #history == 0 and currentMonthOffset == 0 and selectedCurrency ~= "token" then
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
	header:SetPoint("TOP", scrollFrame.scrollFrame, "TOP", OverviewConfig.monthHeading.x, OverviewConfig.monthHeading.y)
	header:SetText(FormatMonthText(filterPrefix))
	table.insert(scrollFrame.rows, {header})

	scrollFrame:SetColumnText(2, L[selectedCurrency == "token" and "wow-token.price" or "currency-overview.table.amount"])

	if #monthHistory == 0 then
		local noEntry = scrollFrame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		noEntry:SetPoint("TOP", 0, 0)
		noEntry:SetText(L["currency-overview.table.no-entries"])
		table.insert(scrollFrame.rows, {noEntry})

		scrollFrame:SetContentHeight(OverviewConfig.history.rowHeight)

		scrollFrame.prevButton:SetEnabled(HasAnyDataBeforeMonth(displayHistory, filterPrefix))
		scrollFrame.nextButton:SetEnabled(HasAnyDataAfterMonth(displayHistory, filterPrefix))

		return
	end

	local offsetY = 0

	for i, entry in ipairs(monthHistory) do
		local background = CreateFrame("Frame", nil, scrollFrame.content)
		background:SetSize(scrollFrame:GetContentWidth(), OverviewConfig.history.rowHeight)
		background:SetPoint("TOPLEFT", scrollFrame.content, "TOPLEFT", 0, offsetY)

		background.texture = background:CreateTexture(nil, "BACKGROUND")
		background.texture:SetAllPoints()
		background.texture:SetTexture(OverviewConfig.history.highlightTexture)
		background.texture:SetAlpha(0)

		background:SetScript("OnEnter", function(self)
			self.texture:SetAlpha(OverviewConfig.history.hoverAlpha)
		end)

		background:SetScript("OnLeave", function(self)
			self.texture:SetAlpha(0)
		end)

		local dateStr = entry.date
		local currentValue = entry.value

		local prevValue = GetPreviousValueFromHistory(history, dateStr) or 0

		local rowDate = CreateHistoryCell(background, scrollFrame, 1)
		rowDate:SetText(Utils:FormatDate(entry.date))

		local rowAmount = CreateHistoryCell(background, scrollFrame, 2)
		rowAmount:SetText(FormatCurrency(currentValue, selectedCurrency))

		local rowDifference = CreateHistoryCell(background, scrollFrame, 3)

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
		offsetY = offsetY - OverviewConfig.history.rowHeight
	end

	scrollFrame:SetContentHeight(math.abs(offsetY))

	scrollFrame.prevButton:SetEnabled(HasAnyDataBeforeMonth(displayHistory, filterPrefix))
	scrollFrame.nextButton:SetEnabled(HasAnyDataAfterMonth(displayHistory, filterPrefix))
end

local function UpdateCharacterOverview()
	SelectFallbackCharacter()

	local characterHistory = BuildCharacterHistory(selectedCharacterKey, selectedCurrency[TabIndex.character])
	UpdateOverview({
		currency = selectedCurrency[TabIndex.character],
		monthOffset = currentMonthOffset[TabIndex.character],
		history = characterHistory,
		tableFrame = OverviewScrollFrames[TabIndex.character]
	})
end

local function UpdateAccountOverview()
	local accountHistory = BuildAccountHistory(selectedCurrency[TabIndex.account])
	UpdateOverview({
		currency = selectedCurrency[TabIndex.account],
		monthOffset = currentMonthOffset[TabIndex.account],
		history = accountHistory,
		tableFrame = OverviewScrollFrames[TabIndex.account]
	})
end

local function UpdateWarbandOverview()
	local warbandHistory = BuildWarbandHistory(selectedCurrency[TabIndex.warband])
	UpdateOverview({
		currency = selectedCurrency[TabIndex.warband],
		monthOffset = currentMonthOffset[TabIndex.warband],
		history = warbandHistory,
		tableFrame = OverviewScrollFrames[TabIndex.warband]
	})
end

local function UpdateTokenOverview()
	local scrollFrame = OverviewScrollFrames[TabIndex.token]
	if not scrollFrame then return end

	scrollFrame.regionDropdown:SetDefaultText(L["wow-token.region"] .. ": " .. WowToken:GetRegionName())
	UpdateOverview({
		currency = "token",
		monthOffset = currentMonthOffset[TabIndex.token],
		history = WowToken:GetHistory(),
		tableFrame = scrollFrame
	})
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
	currencyDropdown:SetPoint("BOTTOMRIGHT", background, "TOPRIGHT", -OverviewConfig.dropdown.offset.x, OverviewConfig.dropdown.offset.y)
	currencyDropdown:SetSize(OverviewConfig.dropdown.currencyWidth, OverviewConfig.dropdown.height)

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
			scope = OverviewConfig.tabs[tabIndex].id,
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
	characterDropdown:SetPoint("BOTTOMLEFT", background, "TOPLEFT", OverviewConfig.dropdown.offset.x, OverviewConfig.dropdown.offset.y)
	characterDropdown:SetSize(OverviewConfig.dropdown.characterWidth, OverviewConfig.dropdown.height)

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
				rightTexture:SetSize(OverviewConfig.menu.factionIconSize, OverviewConfig.menu.factionIconSize)
				rightTexture:SetPoint("RIGHT")

				if factionFileID == 0 then
					rightTexture:SetAtlas("Warfronts-BaseMapIcons-Empty-Barracks")
				else
					rightTexture:SetTexture(factionFileID)
				end

				local fontString = button.fontString
				fontString:SetPoint("RIGHT")
				fontString:SetTextColor(classColor:GetRGB())

				return fontString:GetUnboundedStringWidth() + rightTexture:GetWidth() + OverviewConfig.menu.characterWidthPadding,
					rightTexture:GetHeight() + OverviewConfig.menu.rowHeightPadding
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

local function PopulateSettingsMenu(_, root)
	root:CreateCheckbox(L["currency-overview.menu.hide-unchanged-entries"], function()
		return AUR.Settings.currencyOverview["table-overview"]["hide-unchanged-entries"]
	end, function()
		local settings = AUR.Settings.currencyOverview["table-overview"]
		settings["hide-unchanged-entries"] = not settings["hide-unchanged-entries"]
		Overview:Refresh()
	end)
end

local function CreateMoreMenu(tabs)
	local MoreMenuConfig = OverviewConfig.moreMenu
	local button = CreateFrame("DropdownButton", nil, OverviewFrame, "WowStyle1FilterDropdownTemplate")
	button.resizeToText = false
	button:SetPoint("TOPRIGHT", OverviewFrame, "TOPRIGHT", MoreMenuConfig.x, MoreMenuConfig.y)
	button:SetText(L["currency-overview.menu.more"])
	local width = math.max(MoreMenuConfig.minimumWidth, math.ceil(button.Text:GetUnboundedStringWidth()) + MoreMenuConfig.arrowSize + MoreMenuConfig.textInset * 2)
	button:SetSize(width, MoreMenuConfig.height)
	button.Text:ClearAllPoints()
	button.Text:SetPoint("LEFT", MoreMenuConfig.textInset, 0)
	button.Text:SetPoint("RIGHT", -MoreMenuConfig.textInset, 0)
	button.Text:SetJustifyH("CENTER")

	button:SetMenuAnchor(AnchorUtil.CreateAnchor("TOPLEFT", button, "TOPRIGHT", MoreMenuConfig.menuGap, 0))
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
			local icon = menuButton:AttachTexture()
			icon:SetTexture(MoreMenuConfig.icon.texture)
			icon:SetVertexColor(unpack(MoreMenuConfig.icon.color))
			icon:SetSize(MoreMenuConfig.icon.size, MoreMenuConfig.icon.size)
			icon:SetPoint("LEFT", MoreMenuConfig.itemPadding, 0)

			local text = menuButton.fontString
			local textWidth = text:GetUnboundedStringWidth()
			text:ClearAllPoints()
			text:SetPoint("LEFT", MoreMenuConfig.itemPadding + MoreMenuConfig.icon.size + MoreMenuConfig.iconGap, MoreMenuConfig.itemTextOffsetY)
			text:SetWidth(textWidth)

			return textWidth + MoreMenuConfig.icon.size + MoreMenuConfig.iconGap + MoreMenuConfig.itemPadding * 2, MoreMenuConfig.itemHeight
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

local function CreateOverviewPage(tabs, tabIndex)
	currentMonthOffset[tabIndex] = 0
	local TabConfig = OverviewConfig.tabs[tabIndex]
	local page = tabs:AddTab(TabConfig.id, L[TabConfig.label])
	page:ClearAllPoints()
	page:SetSize(OverviewConfig.inset.width, OverviewConfig.inset.height)
	page:SetPoint("BOTTOM", OverviewFrame, "BOTTOM", 0, OverviewConfig.inset.bottom)

	local columns = AWL.Utils:CopyTable(OverviewConfig.history.columns)

	for _, column in ipairs(columns) do
		column.text = L[column.text]
	end

	---@class AurariumOverviewTable: ArcaneWizardLibraryTable
	---@field nextButton Button
	---@field prevButton Button
	---@field regionDropdown? ArcaneWizardLibraryDropdown
	---@field characterDropdown? ArcaneWizardLibraryDropdown
	local scrollFrame = AWL.Tables:CreateTable({
		parent = page,
		width = OverviewConfig.inset.width,
		height = OverviewConfig.inset.height,
		backgroundStyle = OverviewConfig.inset.backgroundStyle,
		backgroundAlpha = OverviewConfig.inset.backgroundAlpha,
		columns = columns,
		settingsMenu = PopulateSettingsMenu
	})
	scrollFrame:SetAllPoints(page)
	scrollFrame:SetScrollStep(OverviewConfig.scrollStep)

	scrollFrame.nextButton = AWL.Controls:CreateButton({
		parent = scrollFrame,
		width = OverviewConfig.buttonWidth,
		label = L["button.next"],
		onClick = function()
			currentMonthOffset[tabIndex] = currentMonthOffset[tabIndex] - 1

			if tabIndex == TabIndex.character then
				UpdateCharacterOverview()
			elseif tabIndex == TabIndex.account then
				UpdateAccountOverview()
			elseif tabIndex == TabIndex.warband then
				UpdateWarbandOverview()
			else
				UpdateTokenOverview()
			end
		end
	})

	scrollFrame.nextButton:SetPoint("TOPRIGHT", page, "BOTTOMRIGHT", -OverviewConfig.buttonOffset.x, OverviewConfig.buttonOffset.y)

	scrollFrame.prevButton = AWL.Controls:CreateButton({
		parent = scrollFrame,
		width = OverviewConfig.buttonWidth,
		label = L["button.prev"],
		onClick = function()
			currentMonthOffset[tabIndex] = currentMonthOffset[tabIndex] + 1

			if tabIndex == TabIndex.character then
				UpdateCharacterOverview()
			elseif tabIndex == TabIndex.account then
				UpdateAccountOverview()
			elseif tabIndex == TabIndex.warband then
				UpdateWarbandOverview()
			else
				UpdateTokenOverview()
			end
		end
	})

	scrollFrame.prevButton:SetPoint("TOPLEFT", page, "BOTTOMLEFT", OverviewConfig.buttonOffset.x, OverviewConfig.buttonOffset.y)

	if tabIndex ~= TabIndex.token then
		CreateCurrencyDropdown(scrollFrame, page, tabIndex)
	else
		local dropdown = AWL.Controls:CreateDropdown({
			parent = scrollFrame,
			width = OverviewConfig.dropdown.characterWidth,
			options = {}
		})
		dropdown:SetHeight(OverviewConfig.dropdown.height)
		dropdown:SetPoint("BOTTOMLEFT", page, "TOPLEFT", OverviewConfig.dropdown.offset.x, OverviewConfig.dropdown.offset.y)
		dropdown:SetDefaultText(L["wow-token.region"] .. ": " .. WowToken:GetRegionName())
		dropdown:SetEnabled(false)
		scrollFrame.regionDropdown = dropdown
	end

	if tabIndex == TabIndex.character then
		local characterDropdown = CreateCharacterDropdown(scrollFrame, page)
		scrollFrame.characterDropdown = characterDropdown
	end

	OverviewScrollFrames[tabIndex] = scrollFrame
end

local function InitializeFrames()
	local lastTabIndex = AWL.GAME_TYPE_RETAIL and TabIndex.warband or TabIndex.account
	local windowConfig = AWL.Utils:CopyTable(OverviewConfig.window)
	windowConfig.addonName = addonName
	windowConfig.title = addonName
	OverviewFrame = AWL.Frames:CreateWindow(windowConfig)
	OverviewFrame:SetFrameStrata("HIGH")
	OverviewFrame.portrait:SetPoint("TOPLEFT", OverviewConfig.portrait.x, OverviewConfig.portrait.y)
	OverviewFrame.portrait:SetTexture(Addon:GetMediaPath("icon-round.tga"))

	local tabs = AWL.Frames:CreateTabGroup(OverviewFrame)

	for tabIndex = TabIndex.character, lastTabIndex do
		CreateOverviewPage(tabs, tabIndex)
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
	WowToken:RequestPrice()
end

function Overview:Hide()
	OverviewFrame:Hide()
end

function Overview:RefreshCurrencyMenus()
	for _, scrollFrame in pairs(OverviewScrollFrames) do
		local dropdown = scrollFrame.currencyDropdown

		if dropdown and dropdown:IsMenuOpen() then
			dropdown:GenerateMenu()
		end
	end
end

function Overview:RefreshToken(force)
	if not OverviewFrame or not WowToken:IsSupported() then return end

	if not OverviewScrollFrames[TabIndex.token] then
		CreateOverviewPage(OverviewFrame.tabGroup, TabIndex.token)
	end

	if force or self:IsShown() then
		UpdateTokenOverview()
	end
end

function Overview:Refresh()
	if not OverviewFrame then return end

	UpdateCharacterOverview()
	UpdateAccountOverview()

	if AWL.GAME_TYPE_RETAIL then
		UpdateWarbandOverview()
	end

	self:RefreshToken(true)
end

function Overview:IsShown()
	return OverviewFrame and OverviewFrame:IsShown()
end
