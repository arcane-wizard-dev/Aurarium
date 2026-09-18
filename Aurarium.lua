local addonName, AUR = ...

-- Library
local AWL = ArcaneWizardLibrary

-- Module imports
local GoldDisplay = AUR.Modules.GoldDisplay
local Options = AUR.Modules.Options
local Overview = AUR.Modules.Overview
local Utils = AUR.Modules.Utils

-- Variables
local isInitialized = false

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

local function TrackCharacterCurrencies(characterGUID, today)
	local characterHistory = AUR.Data.balance[characterGUID]
	local changed = false

	for _, currencies in pairs(AUR.CHARACTER_CURRENCIES) do
		for _, currencyID in ipairs(currencies) do
			local key = "c-" .. tostring(currencyID)
			local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)

			if info then
				local newQty = info.quantity
				local prevQty = 0
				local lastDate = nil

				for dateKey, dayData in pairs(characterHistory) do
					if dateKey < today and dayData[key] ~= nil and (not lastDate or dateKey > lastDate) then
						lastDate = dateKey
						prevQty = dayData[key]
					end
				end

				if newQty ~= prevQty then
					AUR.Data.balance[characterGUID][today][key] = newQty
					changed = true
				else
					AUR.Data.balance[characterGUID][today][key] = nil
				end
			end
		end
	end

	return changed
end

local function TrackWarbandCurrencies(today)
	local warbandHistory = AUR.Data.balance["Warband"]
	AUR.Data.balance["Warband"][today] = AUR.Data.balance["Warband"][today] or {}
	local changed = false

	for _, currencies in pairs(AUR.WARBAND_CURRENCIES) do
		for _, currencyID in ipairs(currencies) do
			local key = "w-" .. tostring(currencyID)
			local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
			local newQty = (info and info.quantity) or 0
			local prevQty = 0
			local lastDate = nil

			for dateKey, dayData in pairs(warbandHistory) do
				if dateKey < today and dayData[key] ~= nil and (not lastDate or dateKey > lastDate) then
					lastDate = dateKey
					prevQty = dayData[key]
				end
			end

			if newQty ~= prevQty then
				AUR.Data.balance["Warband"][today][key] = newQty
				changed = true
			else
				AUR.Data.balance["Warband"][today][key] = nil
			end
		end
	end

	return changed
end

local function SaveBalance()
	local characterGUID = AWL.Utils:GetCharacterGUID()
	local today = Utils:GetToday()

	if not AUR.Data.character[characterGUID] or not AUR.Data.balance[characterGUID] then
		if not Utils:InitializeDatabase() then return end
	end

	UpdateDateHistory(today)

	if AWL.GAME_TYPE_MISTS then
		local goldChanged = TrackGoldBalance(characterGUID, today)
		local charCurChanged = TrackCharacterCurrencies(characterGUID, today)

		if not (goldChanged or charCurChanged) then
			AUR.Data.balance[characterGUID][today] = nil
		end
	elseif AWL.GAME_TYPE_MAINLINE then
		local goldChanged = TrackGoldBalance(characterGUID, today)
		local charCurChanged = TrackCharacterCurrencies(characterGUID, today)
		local warbandChanged = TrackWarbandCurrencies(today)

		if not (goldChanged or charCurChanged) then
			AUR.Data.balance[characterGUID][today] = nil
		end

		if not warbandChanged then
			AUR.Data.balance["Warband"][today] = nil
		end
	else
		local goldChanged = TrackGoldBalance(characterGUID, today)

		if not goldChanged then
			AUR.Data.balance[characterGUID][today] = nil
		end
	end

	Utils:PrintDebug("Balance saved.")

	if GoldDisplay and GoldDisplay.Refresh then
		GoldDisplay:Refresh()
	end
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
		AWL:GetAddon(addonName):AbortInitialization(self)
		return
	end

	Utils:InitializeMinimapButton()
	Options:Initialize()
	GoldDisplay:Initialize()
	Overview:Initialize()

	Utils:OpenSettingsOnLoading()

	isInitialized = true

	Utils:PrintDebug(string.format(
		"InitializeDatabase: key=%s, createdProfile=%s, createdProfileKey=%s, activeProfile=%s",
		tostring(dbInit.characterGUID), tostring(dbInit.createdProfile), tostring(dbInit.createdProfileKey), tostring(dbInit.activeProfile)
	))
	Utils:PrintDebug("Addon fully loaded.")
end

function AurariumFrame:PLAYER_ENTERING_WORLD(_, isInitialLogin, isReloadingUi)
	Utils:PrintDebug(string.format(
		"Event 'PLAYER_ENTERING_WORLD' fired. Payload: isInitialLogin=%s, isReloadingUi=%s",
		tostring(isInitialLogin), tostring(isReloadingUi)
	))

	if (isInitialLogin or isReloadingUi) then
		C_Timer.After(5, function()
			SaveBalance()
		end)

		if AUR.Settings.currencyOverview["open-on-login"] then
			Overview:Show()
		end
	end
end

function AurariumFrame:PLAYER_MONEY(...)
	Utils:PrintDebug("Event 'PLAYER_MONEY' fired. No payload.")

	SaveBalance()
end

function AurariumFrame:CURRENCY_DISPLAY_UPDATE(_, currencyType, quantity, quantityChange, quantityGainSource, quantityLostSource)
	Utils:PrintDebug(string.format(
		"Event 'CURRENCY_DISPLAY_UPDATE' fired. Payload: currencyType=%s, quantity=%s, quantityChange=%s, quantityGainSource=%s, quantityLostSource=%s",
		tostring(currencyType), tostring(quantity), tostring(quantityChange), tostring(quantityGainSource), tostring(quantityLostSource)
	))

	SaveBalance()
end

AurariumFrame:RegisterEvent("ADDON_LOADED")
AurariumFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
AurariumFrame:RegisterEvent("PLAYER_MONEY")
AurariumFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
AurariumFrame:SetScript("OnEvent", AurariumFrame.OnEvent)

SLASH_Aurarium1, SLASH_Aurarium2 = '/aur', '/aurarium'

SlashCmdList["Aurarium"] = SlashCommand
