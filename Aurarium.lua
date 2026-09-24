local addonName, AUR = ...

-- Library
local AWL = ArcaneWizardLibrary
local Addon = AWL:GetAddon(addonName)

-- Module imports
local GoldDisplay = AUR.Modules.GoldDisplay
local Options = AUR.Modules.Options
local Overview = AUR.Modules.Overview
local Utils = AUR.Modules.Utils

-- Variables
local isInitialized = false
local currencyRefreshPending = false

--------------
--- Frames ---
--------------

local AurariumFrame = CreateFrame("Frame", "Aurarium")

-----------------------
--- Local Functions ---
-----------------------

local function UpdateDateHistory(today)
	local dates = AUR.Data.dates

	for _, d in ipairs(dates) do
		if d == today then return end
	end

	table.insert(dates, today)
	table.sort(dates)
end

local function TrackGoldBalance(characterGUID, today)
	local characterHistory = AUR.Data.balance[characterGUID]
	AUR.Data.balance[characterGUID][today] = AUR.Data.balance[characterGUID][today] or {}

	local newGold = Utils:GetGold()
	AUR.State.gold = newGold
	local prevGold = 0
	local lastDate = nil

	for dateKey, dayData in pairs(characterHistory) do
		if dateKey < today and dayData["gold"] ~= nil and (not lastDate or dateKey > lastDate) then
			lastDate = dateKey
			prevGold = dayData["gold"]
		end
	end

	if newGold ~= prevGold then
		AUR.Data.balance[characterGUID][today]["gold"] = newGold
		return true
	else
		AUR.Data.balance[characterGUID][today]["gold"] = nil
		return false
	end
end

local function TrackCurrencyBalance(currency, characterGUID, today)
	local info = currency.info
	if not info or info.quantity == nil then return end
	local ownerKey = characterGUID
	if currency.key:sub(1, 2) == "w-" then
		if not AWL.GAME_TYPE_RETAIL then return end
		ownerKey = "Warband"
	end
	AUR.Data.balance[ownerKey] = AUR.Data.balance[ownerKey] or {}
	local history = AUR.Data.balance[ownerKey]
	local prevQty, lastDate = 0, nil
	for dateKey, dayData in pairs(history) do
		if dateKey < today and dayData[currency.key] ~= nil and (not lastDate or dateKey > lastDate) then
			lastDate, prevQty = dateKey, dayData[currency.key]
		end
	end
	if info.quantity ~= prevQty then
		history[today] = history[today] or {}
		history[today][currency.key] = info.quantity
	elseif history[today] then
		history[today][currency.key] = nil
	end
	if history[today] and not next(history[today]) then history[today] = nil end
	if AUR.State.latestBalances then AUR.State.latestBalances[ownerKey] = nil end
end

local function SaveBalance(update)
	if not isInitialized then return end
	if update.currencyID and not AUR.State.currencyByID[update.currencyID] then return end

	local characterGUID = AWL.Utils:GetCharacterGUID()
	local today = Utils:GetToday()

	if not AUR.Data.character[characterGUID] or not AUR.Data.balance[characterGUID] then
		if not Utils:InitializeDatabase() then return end
	end

	UpdateDateHistory(today)

	if update.gold then
		TrackGoldBalance(characterGUID, today)
		if AUR.State.latestBalances then AUR.State.latestBalances[characterGUID] = nil end
	end
	if update.currencyID then
		local currency = Utils:RefreshCurrency(update.currencyID)
		if currency then TrackCurrencyBalance(currency, characterGUID, today) end
	elseif update.currencies then
		for currencyID, entry in pairs(AUR.State.currencyByID) do
			local currency
			if update.useCache then currency = entry
			else currency = Utils:RefreshCurrency(currencyID) end
			if currency then TrackCurrencyBalance(currency, characterGUID, today) end
		end
	end

	if AUR.Data.balance[characterGUID][today] and not next(AUR.Data.balance[characterGUID][today]) then
		AUR.Data.balance[characterGUID][today] = nil
	end

	local warbandHistory = AUR.Data.balance["Warband"]
	if warbandHistory and warbandHistory[today] and not next(warbandHistory[today]) then
		AUR.Data.balance["Warband"][today] = nil
	end

	Utils:PrintDebug("Balance saved.")

	if update.gold and GoldDisplay and GoldDisplay.Refresh then
		GoldDisplay:Refresh()
	end
	if Overview.RefreshCurrencyMenus then Overview:RefreshCurrencyMenus() end
end

local function SlashCommand(msg)
	if not isInitialized then return end

	local command = strtrim(msg or "")

	if command == "" then
		Utils:OpenSettings()
	elseif command == "changelog" then
		AWL.Frames:OpenChangelog(addonName, AUR.CHANGELOG)
	elseif command == "overview" then
		Overview:Show()
	else
		Utils:PrintDebug("These arguments are not accepted.")
	end
end

------------------------
--- Public Functions ---
------------------------

function AurariumFrame:OnEvent(event, ...)
	self[event](self, event, ...)
end

function AurariumFrame:ADDON_LOADED(_, addOnName)
	if addOnName ~= addonName or isInitialized then return end

	local dbInit = Utils:InitializeDatabase(true)

	if not dbInit then
		Addon:AbortInitialization(self)
		return
	end

	Utils:InitializeCurrencies()
	AUR.State.gold = Utils:GetGold()
	Utils:InitializeMinimapButton()
	Options:Initialize()
	GoldDisplay:Initialize()
	Overview:Initialize()

	Addon:OpenSettingsOnLoading()

	isInitialized = true

	Utils:PrintDebug(string.format(
		"InitializeDatabase: key=%s, createdProfile=%s, createdProfileKey=%s, cleanedOptions=%s, activeProfile=%s",
		tostring(dbInit.characterGUID), tostring(dbInit.createdProfile), tostring(dbInit.createdProfileKey), tostring(dbInit.cleanedOptions), tostring(dbInit.activeProfile)
	))
	Utils:PrintDebug("Addon fully loaded.")
end

function AurariumFrame:PLAYER_ENTERING_WORLD(_, isInitialLogin, isReloadingUi)
	Utils:PrintDebug(string.format(
		"Event 'PLAYER_ENTERING_WORLD' fired. Payload: isInitialLogin=%s, isReloadingUi=%s",
		tostring(isInitialLogin), tostring(isReloadingUi)
	))

	if isInitialized and (isInitialLogin or isReloadingUi) then
		C_Timer.After(5, function()
			-- Currency data can become available after ADDON_LOADED.
			Utils:InitializeCurrencies()
			SaveBalance({gold = true, currencies = true, useCache = true})
		end)

		if AUR.Settings.currencyOverview["open-on-login"] then
			Overview:Show()
		end
	end
end

function AurariumFrame:PLAYER_MONEY(...)
	Utils:PrintDebug("Event 'PLAYER_MONEY' fired. No payload.")

	SaveBalance({gold = true})
end

function AurariumFrame:CURRENCY_DISPLAY_UPDATE(_, currencyType, quantity, quantityChange, quantityGainSource, quantityLostSource)
	Utils:PrintDebug(string.format(
		"Event 'CURRENCY_DISPLAY_UPDATE' fired. Payload: currencyType=%s, quantity=%s, quantityChange=%s, quantityGainSource=%s, quantityLostSource=%s",
		tostring(currencyType), tostring(quantity), tostring(quantityChange), tostring(quantityGainSource), tostring(quantityLostSource)
	))

	if not isInitialized or currencyRefreshPending then return end
	if currencyType and currencyType > 0 then
		SaveBalance({currencyID = currencyType})
	else
		-- Coalesce broad notifications into one refresh on the next frame.
		currencyRefreshPending = true
		C_Timer.After(0, function()
			currencyRefreshPending = false
			SaveBalance({currencies = true})
		end)
	end
end

AurariumFrame:RegisterEvent("ADDON_LOADED")
AurariumFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
AurariumFrame:RegisterEvent("PLAYER_MONEY")
AurariumFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
AurariumFrame:SetScript("OnEvent", AurariumFrame.OnEvent)

SLASH_Aurarium1, SLASH_Aurarium2 = '/aur', '/aurarium'

SlashCmdList["Aurarium"] = SlashCommand
