local addonName, AUR = ...

-- Library
local AWL = ArcaneWizardLibrary
local Addon = AWL:GetAddon(addonName)

-- Localization
local L = AUR.Localization

-- Current module
local Utils = AUR.Modules.Utils

-----------------------
--- Local Functions ---
-----------------------

local function PrintChatMessage(color, prefix, msg)
	DEFAULT_CHAT_FRAME:AddMessage(color:WrapTextInColorCode(prefix .. ": ") .. tostring(msg))
end

local function RemoveLegacyEntry(database, realm, name)
	if not database[realm] then return end

	database[realm][name] = nil
	if not next(database[realm]) then
		database[realm] = nil
	end
end

local function MigrateLegacyEntry(config)
	local realmData = config.legacy[config.realm]
	local legacyEntry = realmData and realmData[config.name]
	if legacyEntry then
		AWL.Utils:MergeMissingTableEntries(config.target[config.guid], legacyEntry)
		RemoveLegacyEntry(config.legacy, config.realm, config.name)
		return true
	end
	return false
end

local function GetCurrencyBalanceInfo(info)
	return {
		quantity = info.quantity,
		maxQuantity = not info.useTotalEarnedForMaxQty and info.maxQuantity or nil
	}
end

local function AddAvailableCurrencies(definitions, categories, keyPrefix)
	for _, definition in ipairs(definitions) do
		local currencyID = definition.id
		local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)

		if info and info.name and info.name ~= "" then
			local category = definition.category
			categories[category] = categories[category] or {}
			local entry = {
				id = currencyID,
				key = keyPrefix .. currencyID,
				name = info.name,
				iconFileID = info.iconFileID,
				info = GetCurrencyBalanceInfo(info),
				patch = definition.patch,
				isNew = definition.patch ~= nil and definition.patch == AWL.GAME_VERSION
			}
			table.insert(categories[category], entry)
			AUR.State.currencyByID[currencyID] = entry
		end
	end
end

local function GetPatchOrder(patch)
	if not patch then return 0 end
	local major, minor, revision = patch:match("^(%d+)%.(%d+)%.(%d+)$")
	return tonumber(major) * 10000 + tonumber(minor) * 100 + tonumber(revision)
end

------------------------
--- Module Functions ---
------------------------

function Utils:GetToday()
	return date("%Y-%m-%d")
end

function Utils:GetGold()
	return GetMoney()
end

function Utils:InitializeCurrencies()
	local currencies = { character = {}, warband = {} }
	AUR.State.currencies = currencies
	AUR.State.currencyByID = {}

	if not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then return end

	local gameType
	if AWL.GAME_TYPE_FOREVER then
		gameType = "FOREVER"
	elseif AWL.GAME_TYPE_RETAIL then
		gameType = "RETAIL"
	elseif AWL.GAME_TYPE_MISTS then
		gameType = "MISTS"
	elseif AWL.GAME_TYPE_TBC then
		gameType = "TBC"
	elseif AWL.GAME_TYPE_CLASSIC then
		gameType = "CLASSIC"
	end

	AddAvailableCurrencies(AUR.CURRENCIES[gameType] or {}, currencies.character, "c-")
	if gameType == "RETAIL" then
		AddAvailableCurrencies(AUR.WARBAND_CURRENCIES, currencies.warband, "w-")
	end

	for _, categories in pairs(currencies) do
		for category, entries in pairs(categories) do
			table.sort(entries, function(a, b)
				if AUR.CURRENCY_PATCH_CATEGORIES[category] and a.patch ~= b.patch then
					return GetPatchOrder(a.patch) < GetPatchOrder(b.patch)
				end
				return a.name < b.name
			end)
		end
	end
end

function Utils:RefreshCurrency(currencyID)
	local entry = AUR.State.currencyByID[currencyID]
	if not entry or not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then return end
	local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
	if not info or info.quantity == nil then return end
	entry.info = GetCurrencyBalanceInfo(info)
	return entry
end

function Utils:GetLatestBalances(ownerKey)
	AUR.State.latestBalances = AUR.State.latestBalances or {}
	if AUR.State.latestBalances[ownerKey] then return AUR.State.latestBalances[ownerKey] end

	local balances, latestDates = {}, {}
	for day, values in pairs(AUR.Data.balance[ownerKey] or {}) do
		for key, value in pairs(values) do
			if not latestDates[key] or day > latestDates[key] then
				balances[key], latestDates[key] = value, day
			end
		end
	end
	AUR.State.latestBalances[ownerKey] = balances
	return balances
end

function Utils:PrintMessage(msg)
	PrintChatMessage(NORMAL_FONT_COLOR, addonName, msg)
end

function Utils:PrintDebug(msg)
	if AUR.Settings.general["debug-mode"] then
		PrintChatMessage(ORANGE_FONT_COLOR, addonName .. " (Debug)", msg)
	end
end

function Utils:OpenSettings()
	if not Addon:OpenCategory() then
		self:PrintDebug("In combat. The options menu cannot be opened.")
		return false
	end

	return true
end

function Utils:UpdateCharacterData(characterGUID, refreshMetadata)
	local name, realm = AWL.Utils:GetCharacterAndRealm()

	local migratedCharacter = MigrateLegacyEntry({
		legacy = Aurarium_DataCharacter, target = Aurarium_DataCharacter_v2,
		guid = characterGUID, name = name, realm = realm
	})
	local migratedBalance = MigrateLegacyEntry({
		legacy = Aurarium_DataBalance, target = Aurarium_DataBalance_v2,
		guid = characterGUID, name = name, realm = realm
	})

	if Aurarium_DataBalance.Warband then
		AWL.Utils:MergeMissingTableEntries(Aurarium_DataBalance_v2.Warband, Aurarium_DataBalance.Warband)
		Aurarium_DataBalance.Warband = nil
	end

	local metadata = AUR.Data.character[characterGUID]
	if refreshMetadata or migratedCharacter or migratedBalance then
		metadata.name = name
		metadata.realm = realm
		metadata.class = UnitClassBase("player")
		metadata.faction = UnitFactionGroup("player")
	end

	-- Only characters that have completed their first GUID-based login are visible.
	local entries = {}
	for guid, history in pairs(AUR.Data.balance) do
		if guid ~= "Warband" then
			local character = AUR.Data.character[guid] or {}
			entries[guid] = {
				key = guid, name = character.name or guid, realm = character.realm or "",
				metadata = character, history = history
			}
		end
	end
	AUR.State.characterEntries = entries
end

function Utils:GetCharacterEntry(characterKey)
	return AUR.State.characterEntries[characterKey]
end

function Utils:GetSortedCharacters()
	local characters = {}
	for _, entry in pairs(AUR.State.characterEntries) do
		table.insert(characters, entry)
	end
	table.sort(characters, function(a, b)
		if a.realm ~= b.realm then return a.realm < b.realm end
		if a.name ~= b.name then return a.name < b.name end
		return a.key < b.key
	end)
	return characters
end

function Utils:DeleteCharacterData(characterKey)
	if characterKey == AWL.Utils:GetCharacterGUID() then
		return false, "current-character"
	end
	local entry = self:GetCharacterEntry(characterKey)
	if not entry then return false, "not-found" end

	AUR.Data.balance[characterKey] = nil
	AUR.Data.character[characterKey] = nil
	AUR.State.characterEntries[characterKey] = nil
	if AUR.State.latestBalances then AUR.State.latestBalances[characterKey] = nil end
	return true
end

function Utils:InitializeDatabase(isLogin)
	local dbInit = Addon:InitializeOptions({
		databaseName = "Aurarium_Options_v5",
		defaults = AUR.OPTIONS_DEFAULTS,
		requireCharacterRealmKey = true,
		onOpenSettings = function() return self:OpenSettings() end
	})

	if not dbInit then
		return nil
	end

	local characterGUID = dbInit.characterGUID

	AUR.Settings.global = dbInit.global
	AUR.Settings.general = dbInit.settings["general"]
	AUR.Settings.currencyOverview = dbInit.settings["currency-overview"]
	AUR.Settings.goldDisplay = dbInit.settings["gold-display"]

	if not Aurarium_DataDates then
		Aurarium_DataDates = {}
	end

	if not Aurarium_DataCharacter then
		Aurarium_DataCharacter = {}
	end

	if not Aurarium_DataBalance then
		Aurarium_DataBalance = {}
	end

	if not Aurarium_DataCharacter_v2 then
		Aurarium_DataCharacter_v2 = {}
	end

	if not Aurarium_DataBalance_v2 then
		Aurarium_DataBalance_v2 = {}
	end

	AUR.Data.dates = Aurarium_DataDates
	AUR.Data.character = Aurarium_DataCharacter_v2
	AUR.Data.balance = Aurarium_DataBalance_v2
	AUR.State.latestBalances = {}

	local createdCharacter = not AUR.Data.character[characterGUID]
	AUR.Data.character[characterGUID] = AUR.Data.character[characterGUID] or {}
	AUR.Data.balance[characterGUID] = AUR.Data.balance[characterGUID] or {}

	if AWL.GAME_TYPE_RETAIL or Aurarium_DataBalance.Warband then
		AUR.Data.balance.Warband = AUR.Data.balance.Warband or {}
	end

	self:UpdateCharacterData(characterGUID, isLogin or createdCharacter)

	return dbInit
end

function Utils:InitializeMinimapButton()
	self.minimapButton = Addon:RegisterMinimapButton({
		db = AUR.Settings.general["minimap-button"],
		tooltip = L["minimap-button.tooltip"],
		onLeftClick = function()
			if AUR.Modules.Overview:IsShown() then
				AUR.Modules.Overview:Hide()
			else
				AUR.Modules.Overview:Show()
			end
		end
	})
end
